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

HM float amap(HM vec2 p){return dot(vec2(snoise(p),snoise(p*4.+vec2(TOTAL_REAL_WORLD_TIME*.02,16))),vec2(.8,.3));}
HM float cmap(HM vec2 p){
	HM vec2 t=vec2(-TOTAL_REAL_WORLD_TIME,64);
	return dot(vec3(snoise(p*4.+t*.01),snoise(p*16.+t*.1),snoise(p*60.+t*.1)),vec3(1,.1,.027));
}
void main(){

float day=smoothstep(0.15,0.25,FOG_COLOR.g);
float weather=smoothstep(0.8,1.0,FOG_CONTROL.y);
float dusk=clamp(FOG_COLOR.r-FOG_COLOR.g,0.,.5)*2.;
//bool uw=FOG_CONTROL.x==0.;
float l=length(pos);
float aflag=(1.-day)*weather;

vec4 col=vec4(mix(
	CURRENT_COLOR.rgb+mix(mix(vec3(0,0,.1),vec3(-.1,0,.1),day),vec3(.5),dusk*.5)*weather,//top
	FOG_COLOR.rgb+mix(mix(vec3(0,.1,.2),vec3(.2,.1,-.05),day),vec3(.7),dusk*.5)*weather,//horizon
smoothstep(.1,.5,l)),1);
//AURORA
if(aflag>0.){
	vec2 apos=vec2(pos.x+TOTAL_REAL_WORLD_TIME*.004,pos.y*10.);apos.y+=sin(pos.x*20.-TOTAL_REAL_WORLD_TIME*.1)*.1;
	vec3 acol=mix(
		vec3(0.,.8,.4),//col1
		vec3(.4,.2,.8),//col2
	sin(apos.x+apos.y+TOTAL_REAL_WORLD_TIME*.01)*.5+.5);
	col.rgb+=acol*smoothstep(.5,1.,amap(apos))*smoothstep(.5,0.,l)*aflag;
}
//CLOUDS
vec3 ccol=mix(mix(vec3(.2),//night rain
	vec3(.8),//day rain
	day),mix(mix(vec3(.1,.18,.38),//night
	vec3(.97,.96,.90),//day
	day),vec3(.97,.72,.38),//dusk
	dusk),weather);
col.rgb=mix(col.rgb,ccol,smoothstep(mix(-.6,.3,weather),.9,cmap(pos))*smoothstep(.6,.3,l));

gl_FragColor=mix(col,FOG_COLOR,fog);

}
