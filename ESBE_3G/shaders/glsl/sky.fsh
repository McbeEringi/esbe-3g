// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.
#ifdef GL_FRAGMENT_PRECISION_HIGH
	#define HM highp
#else
	#define HM mediump
#endif
#include "fragmentVersionSimple.h"
varying float fog;
varying HM vec2 pos;
uniform HM float TOTAL_REAL_WORLD_TIME;
uniform vec4 FOG_COLOR;
uniform vec2 FOG_CONTROL;
uniform vec4 CURRENT_COLOR;
#include "snoise.h"

HM float clmap(HM vec2 p){
	HM vec2 t=vec2(-TOTAL_REAL_WORLD_TIME,0);
	return dot(vec3(snoise(p*4.+t*.01),snoise(p*16.+t*.1),snoise(p*60.+t*.1)),vec3(1.,.1,.027));
}
void main(){

float day = smoothstep(0.15,0.25,FOG_COLOR.g);
float weather = smoothstep(0.8,1.0,FOG_CONTROL.y);
float dusk = clamp(FOG_COLOR.r-FOG_COLOR.g,0.,.5)*2.;
bool uw = FOG_CONTROL.x==0.;
float l=length(pos);

vec4 col=mix(CURRENT_COLOR,FOG_COLOR,smoothstep(.1,.5,l));
col=mix(col,vec4(dot(col,vec4(1))*.3),smoothstep(.3,.9,clmap(pos))*smoothstep(.6,.3,l));
gl_FragColor=mix(col,FOG_COLOR,fog);

}
