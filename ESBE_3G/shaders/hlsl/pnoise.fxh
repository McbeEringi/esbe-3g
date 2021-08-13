//huge thanks to @MCH_YamaRin
#ifndef PNOISE_H
#define PNOISE_H
float2 hash22(float2 p){
	float3 p3=frac(float3(p.xyx)*float3(.1031,.1030,.0973));
	p3+=dot(p3,p3.yzx+33.33);
	return frac((p3.xx+p3.yz)*p3.zy)*2.-1.;
}
float pnoise(float2 p,float a,float oda){
	float2 fl=floor(p);
	float2 fr=frac(p);
	float2 sfr=fr*fr*fr*(fr*(fr*6.-15.)+10.);
	return lerp(
		lerp(dot(hash22(frac((fl+float2(0,0))*oda)*a),fr-float2(0,0)),
				dot(hash22(frac((fl+float2(1,0))*oda)*a),fr-float2(1,0)),sfr.x),
		lerp(dot(hash22(frac((fl+float2(0,1))*oda)*a),fr-float2(0,1)),
				dot(hash22(frac((fl+float2(1,1))*oda)*a),fr-float2(1,1)),sfr.x),sfr.y);
}
#endif
