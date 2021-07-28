// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.
#ifdef GL_FRAGMENT_PRECISION_HIGH
	#define HM highp
#else
	#define HM mediump
#endif
#include "fragmentVersionCentroid.h"
#if __VERSION__ >= 300
	#ifdef FANCY
		#define USE_NORMAL
	#endif
#endif

#ifndef BYPASS_PIXEL_SHADER
	_centroid varying HM vec2 uv0;
	_centroid varying HM vec2 uv1;
#endif
varying vec4 color;

#ifdef FOG
	varying float fog;
#endif

varying float block;
varying HM vec3 wpos;
varying HM vec3 cpos;

#include "util.h"
LAYOUT_BINDING(0) uniform sampler2D TEXTURE_0;
LAYOUT_BINDING(1) uniform sampler2D TEXTURE_1;
LAYOUT_BINDING(2) uniform sampler2D TEXTURE_2;
uniform vec4 FOG_COLOR;
uniform vec2 FOG_CONTROL;
uniform HM float TOTAL_REAL_WORLD_TIME;
#include "snoise.h"
#include "pnoise.h"

#define linearstep(a,b,x) clamp((x-a)/(b-a),0.,1.)
bool is(float x,float a){return a-.01<x&&x<a+.01;}
float pow5(float x){return x*x*x*x*x;}
//https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 aces(vec3 x){return clamp((x*(2.51*x+.03))/(x*(2.43*x+.59)+.14),0.,1.);}
vec3 tone(vec3 col, vec4 gs){
	col=pow(col,1./gs.rgb);
	float lum=dot(col,vec3(.298912,.586611,.114478));
	col=aces((col-lum)*gs.a+lum);
	return col/aces(vec3(1.7));//exposure
}
HM float cmap(HM vec2 p){
	HM vec2 t=vec2(-TOTAL_REAL_WORLD_TIME,64);
	return dot(vec2(snoise(p*4.+t*.01),snoise(p*16.+t*.1)),vec2(1,.1));
}
HM vec4 water(HM vec4 col,float weather,float uw,float sun,float day,HM vec3 n){
	HM float t=TOTAL_REAL_WORLD_TIME;
	HM vec2 p=cpos.xz+smoothstep(0.,8.,abs(cpos.y-8.))*.5;p.x*=2.;
	float h=pnoise(p+t*vec2(-.8,.8),16.,.0625)+pnoise(p*1.25+t*vec2(-.8,-1.6),20.,.05);
	float cost=dot(normalize(-wpos),n);
	vec4 col_=col*mix(1.,mix(1.4,1.6,uw),pow(1.-abs(h)*.5,mix(1.5,2.5,uw)));
	if(!bool(uw)){
		HM vec3 rpos=reflect(wpos,n);
		HM vec2 spos=(rpos.xz+h*rpos.xz/max(rpos.y,1.)*1.5)/rpos.y;
		HM vec2 srad=normalize(vec2(length(spos),1));
		vec4 scol=mix(mix(vec4(FOG_COLOR.rgb,1),col,srad.y),vec4((vec3(mix(.2,1.,day))+FOG_COLOR.rgb)*.5,1),smoothstep(mix(-.6,.3,weather),.9,cmap(spos*.04))*step(0.,rpos.y));
		#ifdef USE_NORMAL
			scol.a=mix(0.,scol.a,step(0.,cost));//ScreenSpaceNormalCalc fix
		#endif
		col_=mix(col_,mix(scol,col,clamp(cost,.0,.7)),sun);
	}
	return col_;
}

void main(){
#ifdef BYPASS_PIXEL_SHADER
	gl_FragColor=vec4(0);
	return;
#else

//=*=*=
vec3 n=
#ifdef USE_NORMAL
	normalize(cross(dFdx(cpos),dFdy(cpos)));
#else
	vec3(0,1,0);
#endif
float day=linearstep(texture2D(TEXTURE_1,vec2(0)).r*3.6,1.,texture2D(TEXTURE_1,vec2(0,1)).r);
vec2 sun=smoothstep(vec2(.5,.865),vec2(1.,.875),uv1.yy);
float dusk=min(smoothstep(0.2,0.4,day),smoothstep(0.8,0.6,day));
float weather=
#ifdef FOG
	smoothstep(.3,.8,FOG_CONTROL.x);//.7,.96,FOG_CONTROL.y);
#else
	1.;
#endif
float uw=
#ifdef FOG
	step(FOG_CONTROL.x,0.);
#else
	0.;
#endif
float nether=
#ifdef FOG
	FOG_CONTROL.x/FOG_CONTROL.y;nether=step(.1,nether)-step(.12,nether);
#else
	0.;
#endif
float dayw=day*weather;
vec4 ambient=
	mix(mix(vec4(1.,.98,0.96,1.1),//indoor
	mix(vec4(.8,.86,.9,.95),//rain
	mix(mix(vec4(.86,.8,.9,1.),//night
	vec4(1.13,1.12,1.1,1.2),//noon
	day),vec4(1.1,.8,.5,.9),//dusk
	dusk),weather),sun.x),vec4((FOG_COLOR.rgb+2.)*.4,1),//from fog
	max(uw,nether));
//=*=*=

#if USE_TEXEL_AA
	vec4 diffuse=texture2D_AA(TEXTURE_0,uv0);
#else
	vec4 diffuse=texture2D(TEXTURE_0,uv0);
#endif

#ifdef SEASONS_FAR
	diffuse.a=1.;
#endif

#if USE_ALPHA_TEST
	if(diffuse.a<
	#ifdef ALPHA_TO_COVERAGE
		.05
	#else
		.5
	#endif
	)discard;
#endif

vec4 inColor=color;

#ifdef BLEND
	diffuse.a*=inColor.a;
#endif

#ifndef ALWAYS_LIT
	diffuse*=texture2D(TEXTURE_1,uv1);
#endif

#ifndef SEASONS
	#if !USE_ALPHA_TEST && !defined(BLEND)
		diffuse.a=inColor.a;
	#endif
	diffuse.rgb*=inColor.rgb;
#else
	vec2 uv=inColor.xy;
	diffuse.rgb*=mix(vec3(1),texture2D(TEXTURE_2,uv).rgb*2.,inColor.b);
	diffuse.rgb*=inColor.aaa;
	diffuse.a=1.;
#endif

//=*=*=
diffuse.rgb*=mix(.5,1.,min(sun.y+max(uv1.x*uv1.x-sun.y,0.)+(1.-dayw)*.8,1.));//shadow
if(is(block,1.)||uw>.5)diffuse=water(diffuse,weather,uw,sun.x,day,n);//water
#ifdef USE_NORMAL
	else if(uw<.5)diffuse.rgb=mix(diffuse.rgb,ambient.rgb,(1.-weather)*smoothstep(-.7,1.,n.y)*pow5(1.-dot(normalize(-wpos),n))*sun.x*day*(pnoise(cpos.xz,16.,.0625)*.2+.8));//wet
	diffuse.rgb*=mix(1.,mix(dot(n,vec3(0.,.8,.6))*.4+.6,max(dot(n,vec3(.9,.44,0.)),dot(n,vec3(-.9,.44,0.)))*1.3+.2,dusk),sun.x*min(1.25-uv1.x,1.)*dayw);//flatShading
#endif
diffuse.rgb+=uv1.x*uv1.x*vec3(1,.67,.39)*.1*(1.-sun.x);//light
diffuse.rgb=tone(diffuse.rgb,ambient);//tonemap
//=*=*=

#ifdef FOG
	diffuse.rgb=mix(diffuse.rgb,FOG_COLOR.rgb,fog);
#endif

//#define DEBUG
#ifdef DEBUG
	HM vec2 subdisp = gl_FragCoord.xy/512.;
	if(subdisp.x<1. && subdisp.y<1.){
		vec3 subback=vec3(1);
		#define sdif(S,E,Y,C) if(subdisp.x>S && subdisp.x<=E && subdisp.y<=Y)subback.rgb=C;
		sdif(0.,.1,day,vec3(.5))
		sdif(.2,.3,FOG_CONTROL.x,vec3(.5))
		sdif(.3,.4,FOG_CONTROL.y,vec3(.5))
		diffuse=mix(diffuse,vec4(subback,1),.5);
		vec3 tm=tone(subdisp.xxx,ambient);
		if(subdisp.y<=tm.r+.005 && subdisp.y>=tm.r-.005)diffuse.rgb=vec3(1,0,0);
		if(subdisp.y<=tm.g+.005 && subdisp.y>=tm.g-.005)diffuse.rgb=vec3(0,1,0);
		if(subdisp.y<=tm.b+.005 && subdisp.y>=tm.b-.005)diffuse.rgb=vec3(0,0,1);
	}
#endif

gl_FragColor=diffuse;

#endif
}
