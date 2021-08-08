// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.
#ifdef GL_FRAGMENT_PRECISION_HIGH
	#define HM highp
#else
	#define HM mediump
#endif
#include "fragmentVersionCentroid.h"
#include "snoise.h"
#if __VERSION__ >420
	#define LAYOUT_BINDING(x) layout(binding = x)
#else
	#define LAYOUT_BINDING(x)
#endif
LAYOUT_BINDING(0) uniform sampler2D TEXTURE_0;
uniform vec2 FOG_CONTROL;
uniform vec4 CURRENT_COLOR;
_centroid varying HM vec2 uv;
varying HM vec2 rpos;
varying HM vec2 pos;
void main(){

vec4 col=texture2D(TEXTURE_0,vec2(0));
if(col.r*col.a<.05){//DEFAULT
	if(max(abs(pos.x),abs(pos.y))>.5)discard;
	vec2 uv_=mix(vec2(floor(uv.x*4.)*.25+.125,floor(uv.y*2.)*.5+.25),vec2(.5),step(.5,texture2D(TEXTURE_0,vec2(.5)).r));
	uv_=(uv-uv_)*10.+uv_;
	col=
	#if !defined(TEXEL_AA) || !defined(TEXEL_AA_FEATURE)
		texture2D(TEXTURE_0,uv_);
	#else
		texture2D_AA(TEXTURE_0,uv_);
	#endif
}else{//ESBE_3G
	float l=length(rpos);
	float weather=smoothstep(.3,.8,FOG_CONTROL.x);
	if(col.r>.95)
		col=vec4(max(cos(min(l*12.,1.58)),(.5-l*.7)));
	else{
		float mp=(floor(uv.x*4.)*.25+step(uv.y,.5))*3.1415926536;//[0~2pi]
		float r=.13;
		vec3 n=normalize(vec3(rpos,sqrt(r*r-l*l)));
		vec2 np=vec2(-atan(n.x,n.z),asin(n.y))*.6366197724;// 2/pi [-1~1]
		col=vec4(cos(min(l*2.,1.58))*sin(mp*.5)*.6);
		col=mix(
			col,
			texture2D(TEXTURE_0,np*.5+.5)*.6+.4,
			smoothstep(-.3,.5,dot(-vec3(sin(mp),0.,cos(mp)),n))*smoothstep(r,r*.9,l)
		);
	}
	col*=vec4(1.,.95,.81,1);
}
gl_FragColor=col*CURRENT_COLOR;

}
