#ifndef SNOISE_H
#define SNOISE_H
//https://github.com/ashima/webgl-noise/blob/master/src/noise2D.glsl

highp vec3 mod289(highp vec3 x) {return x-floor(x*(1./289.))*289.;}
highp vec2 mod289(highp vec2 x) {return x-floor(x*(1./289.))*289.;}
highp vec3 permute(highp vec3 x) {return mod289(x*(x*34.+1.));}
highp float snoise(highp vec2 v) {
	const highp vec4 C=vec4(.211324865405187,.366025403784439,-.577350269189626,.024390243902439);
		//vec4((3.0-sqrt(3.0))/6.0,0.5*(sqrt(3.0)-1.0),-1.0+2.0*C.x,1.0/41.0)
	highp vec2 i=floor(v+dot(v,C.yy));highp vec2 x0=v-i+dot(i,C.xx);highp vec2 i1=x0.x>x0.y?vec2(1.,0.):vec2(0.,1.);highp vec4 x12=x0.xyxy+C.xxzz;x12.xy-=i1;
	i=mod289(i);highp vec3 p=permute(permute(i.y+vec3(0.,i1.y,1.))+i.x+vec3(0.,i1.x,1.));
	highp vec3 m=max(0.5-vec3(dot(x0,x0),dot(x12.xy,x12.xy),dot(x12.zw,x12.zw)),0.);m=m*m;m=m*m;
	highp vec3 x=2.*fract(p*C.www)-1.;highp vec3 h=abs(x)-.5;highp vec3 ox=round(x);highp vec3 a0=x-ox;
	m*=inversesqrt(a0*a0+h*h);highp vec3 g;g.x=a0.x*x0.x+h.x*x0.y;g.yz=a0.yz*x12.xz+h.yz*x12.yw;
	return 100.*dot(m,g);//[-1.0~1.0]
}

#endif
