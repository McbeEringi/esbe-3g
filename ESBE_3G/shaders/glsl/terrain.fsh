// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.

#include "fragmentVersionCentroid.h"
#ifdef GL_FRAGMENT_PRECISION_HIGH
	#define HM highp
#else
	#define HM mediump
#endif
#if __VERSION__ >= 300
	#ifndef BYPASS_PIXEL_SHADER
		#if defined(TEXEL_AA) && defined(TEXEL_AA_FEATURE)
			_centroid in highp vec2 uv0;
			_centroid in highp vec2 uv1;
		#else
			_centroid in vec2 uv0;
			_centroid in vec2 uv1;
		#endif
	#endif
	#ifdef FANCY
		#define USE_NORMAL
	#endif
#else
	#ifndef BYPASS_PIXEL_SHADER
		varying vec2 uv0;
		varying vec2 uv1;
	#endif
#endif
varying vec4 color;
#ifdef FOG
varying vec4 fogColor;
#endif
varying HM vec3 cPos;
varying HM vec3 wPos;
varying float wf;

#include "uniformShaderConstants.h"
#include "util.h"
#include "snoise.h"
uniform vec2 FOG_CONTROL;
uniform vec4 FOG_COLOR;
uniform HM float TOTAL_REAL_WORLD_TIME;
LAYOUT_BINDING(0) uniform sampler2D TEXTURE_0;
LAYOUT_BINDING(1) uniform sampler2D TEXTURE_1;
LAYOUT_BINDING(2) uniform sampler2D TEXTURE_2;

#define saturate(x) clamp(x,0.,1.)
float aces(float x){
	//https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
	return clamp((x*(2.51*x+.03))/(x*(2.43*x+.59)+.14),0.,1.);
}
vec3 aces3(vec3 x){return vec3(aces(x.x),aces(x.y),aces(x.z));}
vec3 tone(vec3 col,vec4 gs){
	float lum = dot(col,vec3(.299,.587,.114));//http://poynton.ca/notes/colour_and_gamma/ColorFAQ.html#RTFToC11
	col = aces3((col-lum)*gs.a+lum)/aces(2.);
	return pow(col,1./gs.rgb);
}
float sat(vec3 col){//https://qiita.com/akebi_mh/items/3377666c26071a4284ee
	float v=max(max(col.r,col.g),col.b);
	return v>0.?(v-min(min(col.r,col.g),col.b))/v:0.;
}

void main(){
#ifdef BYPASS_PIXEL_SHADER
	gl_FragColor = vec4(0, 0, 0, 0);
	return;
#else

#if USE_TEXEL_AA
	vec4 diffuse = texture2D_AA(TEXTURE_0, uv0);
#else
	vec4 diffuse = texture2D(TEXTURE_0, uv0);
#endif

#ifdef SEASONS_FAR
	diffuse.a = 1.0;
#endif

#if USE_ALPHA_TEST
	#ifdef ALPHA_TO_COVERAGE
	#define ALPHA_THRESHOLD 0.05
	#else
	#define ALPHA_THRESHOLD 0.5
	#endif
	if(diffuse.a < ALPHA_THRESHOLD)
		discard;
#endif

vec4 inColor = color;

#if defined(BLEND)
	diffuse.a *= inColor.a;
#endif

vec4 tex1 = texture2D( TEXTURE_1, uv1 );
#if !defined(ALWAYS_LIT)
	diffuse *= tex1;
#endif

#ifndef SEASONS
	#if !USE_ALPHA_TEST && !defined(BLEND)
		diffuse.a = inColor.a;
	#endif

	diffuse.rgb *= inColor.rgb;
#else
	vec2 uv = inColor.xy;
	diffuse.rgb *= mix(vec3(1.0,1.0,1.0), texture2D( TEXTURE_2, uv).rgb*2.0, inColor.b);
	diffuse.rgb *= inColor.aaa;
	diffuse.a = 1.0;
#endif

//=*=*= ESBE_3G start =*=*=//

//datas
HM float time = TOTAL_REAL_WORLD_TIME;
vec2 sun = smoothstep(vec2(.865,.5),vec2(.875,1.),uv1.yy);
float weather = smoothstep(.7,.96,FOG_CONTROL.y);
float br = texture2D(TEXTURE_1,vec2(.5,0.)).r;
vec2 daylight = texture2D(TEXTURE_1,vec2(0.,1.)).rr;daylight=smoothstep(br-.2,br+.2,daylight);daylight.x*=weather;
float nv = step(texture2D(TEXTURE_1,vec2(0)).r,.5);
float dusk = min(smoothstep(.3,.5,daylight.y),smoothstep(1.,.8,daylight.y));
vec4 ambient = mix(//vec4(gamma.rgb,saturation)
		vec4(1.,.97,.9,1.15),//indoor
	mix(
		vec4(.74,.89,.91,.9),//rain
	mix(mix(
		vec4(.9,.93,1.,1.),//night
		vec4(1.15,1.17,1.1,1.2),//day
	daylight.y),
		vec4(1.4,1.,.7,.8),//dusk
	dusk),weather),sun.y*nv);
	if(FOG_COLOR.a<.001)ambient = vec4(FOG_COLOR.rgb*.6+.4,.8);

//tonemap
diffuse.rgb = tone(diffuse.rgb,ambient);

//light_sorce
float lum = dot(diffuse.rgb,vec3(.299,.587,.114));
diffuse.rgb += max(uv1.x-.5,0.)*(1.-lum*lum)*mix(1.,.3,daylight.x*sun.y)*vec3(1.0,0.65,0.3);

//shadow
float ao = 1.;
if(inColor.r==inColor.g && inColor.g==inColor.b)ao = smoothstep(.48*daylight.y,.52*daylight.y,inColor.g);
diffuse.rgb *= 1.-mix(.5,0.,min(sun.x,ao))*(1.-uv1.x)*daylight.x;

//water
if(wf>.5){
	#ifdef USE_NORMAL
		HM vec3 N = normalize(cross(dFdx(cPos),dFdy(cPos)));
	#endif
	HM vec2 grid = (cPos.xz-time)*mat2(1,-.5,.5,.5); grid+=sin(grid.yx*vec2(3.14,1.57)+time*4.)*.1;
	vec3 T = normalize(abs(wPos));float omsin = 1.-T.y;
	vec4 water = mix(diffuse,mix(tex1,FOG_COLOR,sun.y),.02+.98*
			#ifdef USE_NORMAL
				pow(1.-dot(normalize(-wPos),N),5.)
			#else
				omsin*omsin*omsin*omsin*omsin
			#endif
			);//fresnel
	vec2 skp = (wPos.xz*.4-(fract(grid*.625)-.5)*T.xz*omsin*omsin);
	water.rgb = mix(water.rgb,tex1.rgb,saturate(snoise(normalize(skp)*3.+time*.02)*.5+.5)*omsin);
	#ifdef FANCY
		water.rgb = mix(water.rgb,mix(tex1.rgb,FOG_COLOR.rgb,length(T.xz)*.7),smoothstep(-.5,1.,snoise(skp/abs(wPos.y)-vec2(time*.02,0)))*T.y*sun.y);
	#endif
	vec3 Ts = normalize(vec3(abs(skp.x),wPos.y,skp.y));
	float sunT = mix(-.1,.4,saturate(daylight.y*1.5-.5));
	water = mix(water,vec4(FOG_COLOR.rgb*.5+.8,.9),smoothstep(.97,1.,dot(vec2(cos(sunT),-sin(sunT)),Ts.xy))*smoothstep(.5,1.,normalize(FOG_COLOR.rgb).r)*sun.y);//sun
	diffuse = mix(diffuse,water,length(T.xz)*.5+.5);
}

//=*=*=  ESBE_3G end  =*=*=//

#ifdef FOG
	diffuse.rgb = mix( diffuse.rgb, fogColor.rgb, fogColor.a );
#endif

//#define DEBUG
#ifdef DEBUG
	vec2 subdisp = gl_FragCoord.xy/1024.;
	if(subdisp.x<1. && subdisp.y<1.){
		vec3 subback = texture2D(TEXTURE_1,subdisp).rgb;
		#define sdif(X,W,Y,C) if(subdisp.x>X && subdisp.x<=X+W && subdisp.y<=Y)subback.rgb=C;
		sdif(.1,.1,daylight.x,vec3(1))sdif(.2,.1,dusk,vec3(1,.5,0))
		diffuse = mix(diffuse,vec4(subback,1),.8);
		vec3 tone = tone(subdisp.xxx,ambient);
		if(subdisp.y<=tone.r+.005 && subdisp.y>=tone.r-.005)diffuse.rgb=vec3(1,0,0);
		if(subdisp.y<=tone.g+.005 && subdisp.y>=tone.g-.005)diffuse.rgb=vec3(0,1,0);
		if(subdisp.y<=tone.b+.005 && subdisp.y>=tone.b-.005)diffuse.rgb=vec3(0,0,1);
	}
#endif

	gl_FragColor = diffuse;

#endif // BYPASS_PIXEL_SHADER
}
