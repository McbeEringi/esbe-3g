#ifndef VNOISE_H
#define VNOISE_H
HM float hash12(HM vec2 p){HM vec3 p3=fract(mod(p.xyx,8.)*.1031);p3+=dot(p3,p3.yzx+33.33);return fract((p3.x+p3.y)*p3.z)*2.-1.;}//https://www.shadertoy.com/view/4djSRW
HM float snoise(HM vec2 v){HM vec2 p=v*2.;return mix(mix(hash12(floor(p)),hash12(floor(p+vec2(1,0))),smoothstep(0.,1.,fract(p.x))),mix(hash12(floor(p+vec2(0,1))),hash12(floor(p+1.)),smoothstep(0.,1.,fract(p.x))),smoothstep(0.,1.,fract(p.y)));}
#endif
