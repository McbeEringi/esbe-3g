#ifndef PNOISE_H
#define PNOISE_H
HM vec2 hash22(HM vec2 p){
	HM vec3 p3=fract(vec3(p.xyx)*vec3(.1031,.1030,.0973));
	p3+=dot(p3,p3.yzx+33.33);
	return fract((p3.xx+p3.yz)*p3.zy)*2.-1.;
}
HM float pnoise(HM vec2 p,HM float a,HM float oda){
	HM vec2 fl=floor(p);
	HM vec2 fr=fract(p);
	HM vec2 sfr=fr*fr*fr*(fr*(fr*6.-15.)+10.);
	return mix(
		mix(dot(hash22(fract((fl+vec2(0,0))*oda)*a),fr-vec2(0,0)),
				dot(hash22(fract((fl+vec2(1,0))*oda)*a),fr-vec2(1,0)),sfr.x),
		mix(dot(hash22(fract((fl+vec2(0,1))*oda)*a),fr-vec2(0,1)),
				dot(hash22(fract((fl+vec2(1,1))*oda)*a),fr-vec2(1,1)),sfr.x),sfr.y);
}
#endif
