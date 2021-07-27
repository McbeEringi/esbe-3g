// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.
#include "vertexVersionCentroid.h"
attribute POS4 POSITION;
attribute vec2 TEXCOORD_0;
uniform MAT4 WORLDVIEWPROJ;
uniform MAT4 WORLDVIEW;
_centroid varying vec2 uv;
varying vec2 rpos;
varying vec2 pos;
void main(){

POS4 p=POSITION*vec2(10.,1.).xyxy;
gl_Position=WORLDVIEWPROJ*p;
uv=TEXCOORD_0;
rpos=mat2(.6,-.8,.8,.6)*p.xz;
pos=p.xz;

}
