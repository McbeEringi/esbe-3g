// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.

#include "vertexVersionCentroid.h"
#ifdef GL_FRAGMENT_PRECISION_HIGH
	#define HM highp
#else
	#define HM mediump
#endif
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
	varying vec4 fogColor;
#endif
varying HM vec3 cPos;
varying HM vec3 wPos;
varying float wf;

#include "uniformWorldConstants.h"
#include "uniformPerFrameConstants.h"
#include "uniformShaderConstants.h"
#include "uniformRenderChunkConstants.h"
uniform highp float TOTAL_REAL_WORLD_TIME;

attribute POS4 POSITION;
attribute vec4 COLOR;
attribute vec2 TEXCOORD_0;
attribute vec2 TEXCOORD_1;

const float rA = 1.0;
const float rB = 1.0;
const vec3 UNIT_Y = vec3(0,1,0);
const float DIST_DESATURATION = 56.0 / 255.0; //WARNING this value is also hardcoded in the water color, don'tchange

#ifdef FANCY
highp float gwav(highp float x,highp float r,highp float l){//http://marupeke296.com/Shader_No5_PeakWave.html
	const highp float pi=3.1415926535;
	highp float a = l/pi/2.;highp float b = r*l/pi/4.;
	highp float T = x/a;
	for(int i=0;i<3;i++)T=T-(a*T-b*sin(T)-x)/(a-b*cos(T));
	return r*l*cos(T)/pi/4.;
}
#endif

void main(){
wf=0.;
POS4 worldPos;
#ifndef BYPASS_PIXEL_SHADER
	uv0 = TEXCOORD_0;
	uv1 = TEXCOORD_1;
	color = COLOR;
#endif
#ifdef AS_ENTITY_RENDERER
	POS4 pos = WORLDVIEWPROJ * POSITION;
	worldPos = pos;
#else
	worldPos.xyz = (POSITION.xyz * CHUNK_ORIGIN_AND_SCALE.w) + CHUNK_ORIGIN_AND_SCALE.xyz;
	worldPos.w = 1.0;
	#ifndef SEASONS
		if(.05<color.a&&color.a<.95)
			#ifdef FANCY
				worldPos.y+=gwav(POSITION.x+POSITION.z-TOTAL_REAL_WORLD_TIME*2.,mix(.2,1.,uv1.y),4.)*fract(POSITION.y)*.2;
			#else
				float wwav =sin((POSITION.x+POSITION.z-TOTAL_REAL_WORLD_TIME*2.)*1.57)*.5+.5;
				worldPos.y+=(wwav*wwav-.5)*fract(POSITION.y)*.07;
			#endif
	#endif
	// Transform to view space before projection instead of all at once to avoid floating point errors
	// Not required for entities because they are already offset by camera translation before rendering
	// World position here is calculated above and can get huge
	POS4 pos = WORLDVIEW * worldPos;
	pos = PROJ * pos;
#endif
gl_Position = pos;
cPos = POSITION.xyz;
wPos = worldPos.xyz;

///// find distance from the camera
float cameraDepth = length(-worldPos.xyz);

///// apply fog
#ifdef FOG
	float len = cameraDepth / RENDER_DISTANCE;
	#ifdef ALLOW_FADE
		len += RENDER_CHUNK_FOG_ALPHA;
	#endif
	fogColor.rgb = FOG_COLOR.rgb;
	fogColor.a = clamp((len - FOG_CONTROL.x) / (FOG_CONTROL.y - FOG_CONTROL.x), 0.0, 1.0);
#endif

///// blended layer (mostly water) magic
#ifndef SEASONS
	if(.05<color.a&&color.a<.95) {
		wf=1.;
		color.a = mix(color.a,1.,clamp(cameraDepth/FAR_CHUNKS_DISTANCE,0.,1.));
	}
#endif

#ifndef BYPASS_PIXEL_SHADER
	#ifndef FOG
		// If the FOG_COLOR isn't used, the reflection on NVN fails to compute the correct size of the constant buffer as the uniform will also be gone from the reflection data
		color.rgb += FOG_COLOR.rgb * 0.000001;
	#endif
#endif
}
