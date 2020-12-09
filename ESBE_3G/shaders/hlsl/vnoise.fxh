#ifndef VNOISE_H
#define VNOISE_H
float hash12(float2 p){float3 p3=frac(mod(p.xyx,8.)*.1031);p3+=dot(p3,p3.yzx+33.33);return frac((p3.x+p3.y)*p3.z)*2.-1.;}//https://www.shadertoy.com/view/4djSRW
float snoise(float2 v){float2 p=v*2.;return lerp(lerp(hash12(floor(p)),hash12(floor(p+float2(1,0))),smoothstep(0.,1.,frac(p.x))),lerp(hash12(floor(p+float2(0,1))),hash12(floor(p+1.)),smoothstep(0.,1.,frac(p.x))),smoothstep(0.,1.,frac(p.y)));}
#endif
