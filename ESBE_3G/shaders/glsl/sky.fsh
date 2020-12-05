// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.

#if __VERSION__ >= 300
	#define varying in
	#define texture2D texture
	out vec4 FragColor;
	#define gl_FragColor FragColor
#endif
#ifdef GL_FRAGMENT_PRECISION_HIGH
	#define HM highp
#else
	#define HM mediump
#endif
uniform vec4 FOG_COLOR;
uniform vec4 CURRENT_COLOR;
varying HM vec3 pos;
void main(){
	gl_FragColor = mix(FOG_COLOR,CURRENT_COLOR,smoothstep(-.05,.05,pos.y));
}
