// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.
#ifdef GL_FRAGMENT_PRECISION_HIGH
	#define HM highp
#else
	#define HM mediump
#endif
#include "vertexVersionCentroid.h"
#if __VERSION__ >= 300
	#ifndef BYPASS_PIXEL_SHADER
		_centroid out vec2 uv0;
		_centroid out vec2 uv1;
	#endif
#else
	#ifndef BYPASS_PIXEL_SHADER
		varying vec2 uv0;
		varying vec2 uv1;
	#endif
#endif

#ifndef BYPASS_PIXEL_SHADER
	varying vec4 color;
#endif

#ifdef FOG
	varying float fog;
#endif

varying float block;
varying HM vec3 wpos;
varying HM vec3 cpos;

#include "uniformWorldConstants.h"
#include "uniformPerFrameConstants.h"
#include "uniformRenderChunkConstants.h"
uniform highp float TOTAL_REAL_WORLD_TIME;

attribute POS4 POSITION;
attribute vec4 COLOR;
attribute vec2 TEXCOORD_0;
attribute vec2 TEXCOORD_1;

highp float hash11(highp float p){p=fract(p*.1031);p*=p+33.33;return fract((p+p)*p);}
highp float random(highp float p){
	p=p*.3+TOTAL_REAL_WORLD_TIME;
	return mix(hash11(floor(p)),hash11(ceil(p)),smoothstep(0.,1.,fract(p)))*2.;
}

void main(){
POS4 worldPos;
block=0.;
#ifndef BYPASS_PIXEL_SHADER
	uv0=TEXCOORD_0;
	uv1=TEXCOORD_1;
	color=COLOR;
#endif
// wave
POS3 p=fract(POSITION.xyz*.0625)*16.;
vec3 frp=fract(POSITION.xyz);
float wav=sin(TOTAL_REAL_WORLD_TIME*3.5-dot(p,vec3(2,1.5,1)));
float rand=
#ifdef FANCY
	random(dot(p,vec3(1)));
#else
	1.;
#endif
float sun=mix(.5,1.,smoothstep(0.,.5,uv1.y));
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

// water
#ifndef SEASONS
	if(color.a<.95 && color.a>.05)block=1.;
#endif

#ifdef AS_ENTITY_RENDERER
	POS4 pos=WORLDVIEWPROJ*POSITION;
	worldPos=pos;
#else
	worldPos=vec4(POSITION.xyz*CHUNK_ORIGIN_AND_SCALE.w+CHUNK_ORIGIN_AND_SCALE.xyz,1);
	float camDist=1.;
	#ifdef BLEND
		camDist=clamp(length(-worldPos.xyz)/FAR_CHUNKS_DISTANCE,0.,1.);
		color.a=mix(color.a,1.,camDist);
		if(abs(frp.x-.5)==.125 && frp.z==0.)worldPos.x+=wav*.05*rand;
		else if(abs(frp.z-.5)==.125 && frp.x==0.)worldPos.z+=wav*.05*rand;
	#endif
	if(block==1.)worldPos.y+=wav*.05*fract(POSITION.y)*rand*sun*(1.-camDist);
	POS4 pos=WORLDVIEW*worldPos;
	pos=PROJ*pos;
	#ifdef ALPHA_TEST
		if((max(max(color.r,color.g),color.b)-min(min(color.r,color.g),color.b)>.01&&frp.y!=.015625)||
			(frp.y==.9375&&(frp.x==0.||frp.z==0.))||
			((frp.y==0.||frp.y>.6)&&(fract(frp.x*16.)!=0. && fract(frp.z*16.)!=0.)))pos.x+=wav*.016*rand*sun*PROJ[0].x;
	#endif
#endif
gl_Position=pos;
wpos=worldPos.xyz;
cpos=POSITION.xyz;

#ifdef FOG
	float len=length(-worldPos.xyz)/RENDER_DISTANCE;
	#ifdef ALLOW_FADE
		len+=RENDER_CHUNK_FOG_ALPHA;
	#endif
	fog=clamp((len-FOG_CONTROL.x)/(FOG_CONTROL.y-FOG_CONTROL.x),0.,1.);
	if(nether>.5)gl_Position.xy+=wav*fog*.15*(rand*.5+.5)*nether;
	else if(uw>.5)gl_Position.x+=wav*fog*.1*rand*uw;
#endif

#ifndef BYPASS_PIXEL_SHADER
	#ifndef FOG
		// If the FOG_COLOR isn't used, the reflection on NVN fails to compute the correct size of the constant buffer as the uniform will also be gone from the reflection data
		color.rgb+=FOG_COLOR.rgb*.000001;
	#endif
#endif
}
