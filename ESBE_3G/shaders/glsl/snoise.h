#ifndef SNOISE_H
#define SNOISE_H
// (C) Ashima Arts and Stefan Gustavson MIT License
// https://github.com/ashima/webgl-noise
HM vec3 mod289(HM vec3 x){return x-floor(x*(1./289.))*289.;}
HM vec2 mod289(HM vec2 x){return x-floor(x*(1./289.))*289.;}
HM vec3 permute(HM vec3 x){return mod289(x*(x*34.+1.));}
HM float snoise(HM vec2 v){
	const HM vec4 C=vec4(
		.211324865405187, //(3.-sqrt(3.))/6.
		.366025403784439, //.5*(sqrt(3.)-1.)
		-.577350269189626,//-1.+2.*C.x
		.024390243902439);//1./41.
	HM vec2 i=floor(v+dot(v,C.yy));
	HM vec2 x0=v-i+dot(i,C.xx);
	HM vec2 i1=x0.x>x0.y?vec2(1,0):vec2(0,1);
	HM vec4 x12=x0.xyxy+C.xxzz;
	x12.xy-=i1;

	i=mod289(i);
	HM vec3 p=permute(permute(i.y+vec3(0,i1.y,1))+i.x+vec3(0,i1.x,1));
	HM vec3 m=max(.5-vec3(dot(x0,x0),dot(x12.xy,x12.xy),dot(x12.zw,x12.zw)),0.);
	m=m*m;m=m*m;

	HM vec3 x=2.*fract(p*C.www)-1.;
	HM vec3 h=abs(x)-.5;
	HM vec3 ox=round(x);
	HM vec3 a0=x-ox;

	m*=inversesqrt(a0*a0+h*h);
	HM vec3 g;
	g.x=a0.x*x0.x+h.x*x0.y;
	g.yz=a0.yz*x12.xz+h.yz*x12.yw;
	return 100.*dot(m,g);//[-1.0~1.0]
}
#endif
