#ifndef SNOISE_H
#define SNOISE_H
//https://github.com/ashima/webgl-noise/blob/master/src/noise2D.glsl
float3 mod289(float3 x){return x-floor(x*(1./289.))*289.;}
float2 mod289(float2 x){return x-floor(x*(1./289.))*289.;}
float3 permute(float3 x){return mod289(x*(x*34.+1.));}
float snoise(float2 v){
	static const float4 C=float4(.211324865405187,.366025403784439,-.577350269189626,.024390243902439);
		//float4((3.0-sqrt(3.0))/6.0,0.5*(sqrt(3.0)-1.0),-1.0+2.0*C.x,1.0/41.0)
	float2 i=floor(v+dot(v,C.yy));float2 x0=v-i+dot(i,C.xx);float2 i1=x0.x>x0.y?float2(1.,0.):float2(0.,1.);float4 x12=x0.xyxy+C.xxzz;x12.xy-=i1;
	i=mod289(i);float3 p=permute(permute(i.y+float3(0.,i1.y,1.))+i.x+float3(0.,i1.x,1.));
	float3 m=max(.5-float3(dot(x0,x0),dot(x12.xy,x12.xy),dot(x12.zw,x12.zw)),0.);m=m*m;m=m*m;
	float3 x=2.*frac(p*C.www)-1.;float3 h=abs(x)-.5;float3 ox=round(x);float3 a0=x-ox;
	m*=rsqrt(a0*a0+h*h);float3 g;g.x=a0.x*x0.x+h.x*x0.y;g.yz=a0.yz*x12.xz+h.yz*x12.yw;
	return 100.*dot(m,g);//[-1.0~1.0]
}
#endif
