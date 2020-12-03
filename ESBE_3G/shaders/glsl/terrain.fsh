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
varying float block;

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
	col = aces3((col-lum)*gs.a+lum)*1.2;// /aces(1.1);
	return pow(col,1./gs.rgb);
}
float satur(vec3 col){//https://qiita.com/akebi_mh/items/3377666c26071a4284ee
	float v=max(max(col.r,col.g),col.b);
	return v>0.?(v-min(min(col.r,col.g),col.b))/v:0.;
}
float pow5(float x){return x*x*x*x*x;}
HM vec2 noise(HM vec2 p){return vec2(snoise(p),snoise(p+16.));}

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

vec2 sun = smoothstep(vec2(.855,.4),vec2(.875,1.),uv1.yy);
float weather = smoothstep(.7,.96,FOG_CONTROL.y);
float br = texture2D(TEXTURE_1,vec2(.5,0.)).r;
vec2 daylight = texture2D(TEXTURE_1,vec2(0.,1.)).rr;daylight=smoothstep(br-.2,br+.2,daylight);daylight.x*=weather;
vec2 fuv1 = vec2(uv1.x-smoothstep(.2,1.,daylight.y)*(weather*.9+.1)*mix(sun.y,sun.x,smoothstep(.8,1.,daylight.y)*.8),uv1.y);
vec4 tex1 = texture2D( TEXTURE_1, fuv1 );
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
float nv = step(texture2D(TEXTURE_1,vec2(0)).r,.5);
float dusk = min(smoothstep(.1,.4,daylight.y),smoothstep(1.,.8,daylight.y));
float uw = step(FOG_CONTROL.x,0.);
float nether = FOG_CONTROL.x/FOG_CONTROL.y;nether=step(.1,nether)-step(.12,nether);
float sat = satur(diffuse.rgb);
vec4 ambient = mix(//vec4(gamma.rgb,saturation)
		vec4(1.,.97,.9,1.15),//indoor
	mix(
		vec4(.54,.72,.9,.9),//rain
	mix(mix(
		vec4(.45,.59,.9,1.),//night
		vec4(1.15,1.17,1.1,1.2),//day
	daylight.y),
		vec4(1.4,.9,.5,.8),//dusk
	dusk),weather),sun.y*nv);
	if(uw+nether>.5)ambient = vec4(FOG_COLOR.rgb*.6+.4,.8);
#ifdef USE_NORMAL
	HM vec3 N = normalize(cross(dFdx(cPos),dFdy(cPos)));
	float dotN = dot(normalize(-wPos),N);
#endif

//tonemap
diffuse.rgb = tone(diffuse.rgb,ambient);

//light_sorce
float lum = dot(diffuse.rgb,vec3(.299,.587,.114));
diffuse.rgb += max(fuv1.x-.5,0.)*(1.-lum*lum)*mix(1.,.3,daylight.x*sun.y)*vec3(1.0,0.65,0.3);

//shadow
float ao = 1.;
if(inColor.r==inColor.g && inColor.g==inColor.b)ao = smoothstep(.48*daylight.y,.52*daylight.y,inColor.g);
float Nl =
	#ifdef USE_NORMAL
		mix(1.,smoothstep(-.7+dusk,1.,dot(normalize(vec3(dusk*6.,4,3)),vec3(abs(N.x),N.yz))),sun.y);
	#else
		1.;
	#endif
diffuse.rgb *= 1.-mix(.5,0.,min(min(sun.x,ao),Nl))*(1.-max(0.,fuv1.x-sun.y*.7))*daylight.x;

//water
if(.5<block && block<1.5){
	HM vec2 grid = (cPos.xz+smoothstep(0.,8.,abs(cPos.y-8.))*.5-time)*mat2(1,-.5,.5,.5);
	vec2 wav = sin(grid.yx*vec2(3.14,1.57)+time*4.)*.1; grid+=wav;
	vec3 T = normalize(abs(wPos));float omsin = 1.-T.y;
	vec4 water = mix(diffuse,vec4(mix(tex1.rgb,FOG_COLOR.rgb,sun.y),1),.02+.98*pow5(
			#ifdef USE_NORMAL
				1.-dotN
			#else
				omsin
			#endif
			));//fresnel
	vec2 skp = (wPos.xz*.4-(fract(grid*.625)-.5)*T.xz*omsin*omsin);
	#ifdef FANCY
		water = mix(water,vec4(mix(tex1.rgb,FOG_COLOR.rgb,length(T.xz)*.7),1),smoothstep(-.5,1.,snoise(skp/abs(wPos.y)-vec2(time*.02,0)+wav*.07))*T.y*sun.y);//c_ref
	#endif
	water.rgb = mix(water.rgb,tex1.rgb,saturate(snoise(normalize(skp)*3.+time*.02)*.5+.5)*omsin);//t_ref
	vec3 Ts = normalize(vec3(abs(skp.x),wPos.y,skp.y));
	float sunT = mix(-.1,.4,saturate(daylight.y*1.5-.5));
	water = mix(water,vec4(FOG_COLOR.rgb*.5+.8,.9),smoothstep(.97,1.,dot(vec2(cos(sunT),-sin(sunT)),Ts.xy))*smoothstep(.5,1.,normalize(FOG_COLOR.rgb).r)*sun.y);//sun
	diffuse = mix(diffuse,water,(length(T.xz)*.5+.5)*smoothstep(0.,1.,length(wPos)));
#if !defined(ALPHA_TEST) && defined(USE_NORMAL)
}else if(uw<.5)diffuse.rgb=mix(diffuse.rgb,ambient.rgb,(1.-weather)*smoothstep(-.7,1.,N.y)*pow5(1.-dotN)*sun.y*tex1.g*(snoise(cPos.xz)*.2+.8));
#else
}
#endif

//gate
#if defined(BLEND) && defined(USE_NORMAL)
	vec2 gate = vec2(cPos.x+cPos.z,cPos.y);
	if(1.5<block && block<2.5)diffuse=mix(diffuse,mix(vec4(.2,0,1,.5),vec4(1,.5,1,1),(snoise(gate+snoise(gate+time*.1)-time*.1)*.5+.5)*(dotN*-.5+1.)),.7);
	else if(2.5<block && diffuse.a>.5 && sat<.2)diffuse.rgb=mix((FOG_COLOR.rgb+tex1.rgb)*.5,diffuse.rgb,dotN*.9+.1);
#endif

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
