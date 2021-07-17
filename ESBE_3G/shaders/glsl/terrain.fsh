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
	#ifndef BYPASS_PIXEL_SHADER
		#if defined(TEXEL_AA) && defined(TEXEL_AA_FEATURE)
			_centroid in highp vec2 uv0;
			_centroid in highp vec2 uv1;
		#else
			_centroid in vec2 uv0;
			_centroid in vec2 uv1;
		#endif
	#endif
#else
	#ifndef BYPASS_PIXEL_SHADER
		varying vec2 uv0;
		varying vec2 uv1;
	#endif
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

#define linearstep(a,b,x) clamp((x-a)/(b-a),0.,1.)
//https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 aces(vec3 x){return clamp((x*(2.51*x+.03))/(x*(2.43*x+.59)+.14),0.,1.);}
vec3 tone(vec3 col, vec4 gs){
	col=pow(col,1./gs.rgb);
	float lum=dot(col,vec3(.298912,.586611,.114478));
	col=aces((col-lum)*gs.a+lum);
	return col/aces(vec3(1.7));//exposure
}
bool is(float x,float a){return a-.05<x&&x<a+.05;}

void main(){
#ifdef BYPASS_PIXEL_SHADER
	gl_FragColor=vec4(0);
	return;
#else

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
#ifdef USE_NORMAL
	vec3 n=normalize(cross(dFdx(cpos),dFdy(cpos)));
#endif
float day=linearstep(texture2D(TEXTURE_1,vec2(0)).r*3.6,1.,texture2D(TEXTURE_1,vec2(0,1)).r);
vec2 sun=vec2(smoothstep(.5,1.,uv1.y),smoothstep(.865,.875,uv1.y));
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

diffuse.rgb*=mix(.5,1.,min(sun.y+max(uv1.x*uv1.x-sun.y,0.)+(1.-dayw)*.8,1.));
// if(is(block,1.)||uw>.5){
// 	#ifdef USE_NORMAL
// 		float w_r=1.-dot(normalize(-wpos),n);
// 		diffuse.a=mix(diffuse.a,1.,.02+.98*w_r*w_r*w_r*w_r*w_r);
// 	#endif
// }
#ifdef USE_NORMAL
	diffuse.rgb*=mix(1.,
		mix(
			dot(n,vec3(0.,.8,.6))*.4+.6,
			max(dot(n,vec3(.9,.44,0.)),dot(n,vec3(-.9,.44,0.)))*1.3+.2,
		dusk),
	sun.x*min(1.25-uv1.x,1.)*dayw);
#endif
diffuse.rgb+=uv1.x*uv1.x*vec3(1,.67,.39)*.1*(1.-sun.x);
diffuse.rgb=tone(diffuse.rgb,ambient);
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
