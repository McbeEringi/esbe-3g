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
uniform vec4 FOG_COLOR;
uniform vec4 CURRENT_COLOR;
void main(){

gl_FragColor=mix(CURRENT_COLOR,FOG_COLOR,fog);

}
