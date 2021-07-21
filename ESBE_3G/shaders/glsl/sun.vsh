// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.
#ifdef GL_FRAGMENT_PRECISION_HIGH
	#define HM highp
#else
	#define HM mediump
#endif
#include "vertexVersionCentroidUV.h"
attribute POS4 POSITION;
attribute vec2 TEXCOORD_0;
uniform MAT4 WORLDVIEWPROJ;
uniform MAT4 WORLDVIEW;
varying HM vec2 rpos;
varying HM vec2 pos;
void main(){

POS4 p=POSITION*vec2(10.,1.).xyxy;
gl_Position=WORLDVIEWPROJ*p;
uv=TEXCOORD_0;
rpos=mat2(.8,.6,-.6,.8)*p.xz;
pos=p.xz;
//lf=vec4(p.xz,(WORLDVIEW*p).xy);

}
