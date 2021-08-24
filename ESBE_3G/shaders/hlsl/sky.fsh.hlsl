//huge thanks to @MCH_YamaRin
#include "ShaderConstants.fxh"
#include "snoise.fxh"

struct PS_Input{
	float4 position : SV_Position;
	float4 color : COLOR;
	float fog : Fog_Position;
	float2 pos : Position;
};
struct PS_Output{
	float4 color : SV_Target;
};

float amap(float2 p){return dot(float2(snoise(p),snoise(p*4.+float2(TOTAL_REAL_WORLD_TIME*.02,16))),float2(.8,.3));}
float cmap(float2 p){
	float2 t=float2(-TOTAL_REAL_WORLD_TIME,64);
	return dot(float3(snoise(p*4.+t*.01),snoise(p*16.+t*.1),snoise(p*60.+t*.1)),float3(1,.1,.027));
}

ROOT_SIGNATURE
void main(in PS_Input PSInput, out PS_Output PSOutput){

float day=smoothstep(0.15,0.25,FOG_COLOR.g);
float weather=smoothstep(.3,.7,FOG_CONTROL.x);
float dusk=clamp(FOG_COLOR.r-FOG_COLOR.g,0.,.5)*2.;
//bool uw=FOG_CONTROL.x==0.;
float l=length(PSInput.pos);
float aflag=(1.-day)*weather;

float4 col=float4(lerp(
	CURRENT_COLOR.rgb+lerp(lerp(float3(0,0,.1),float3(-.1,0,.1),day),.5,dusk*.5)*weather,//top
	FOG_COLOR.rgb+lerp(lerp(float3(0,.1,.2),float3(.2,.1,-.05),day),.7,dusk*.5)*weather,//horizon
smoothstep(.1,.5,l)),1);
//AURORA
if(aflag>0.){
	float2 apos=float2(PSInput.pos.x+TOTAL_REAL_WORLD_TIME*.004,PSInput.pos.y*10.);apos.y+=sin(PSInput.pos.x*20.-TOTAL_REAL_WORLD_TIME*.1)*.1;
	float3 acol=lerp(
		float3(0.,.8,.4),//col1
		float3(.4,.2,.8),//col2
	sin(dot(apos,1.)+TOTAL_REAL_WORLD_TIME*.01)*.5+.5);
	col.rgb+=acol*smoothstep(.5,1.,amap(apos))*smoothstep(.5,0.,l)*aflag;
}
//CLOUDS
float3 ccol=lerp(lerp(.2,//night rain
	.8,//day rain
	day),lerp(lerp(float3(.1,.18,.38),//night
	float3(.97,.96,.90),//day
	day),float3(.97,.72,.38),//dusk
	dusk),weather);
col.rgb=lerp(col.rgb,ccol,smoothstep(lerp(-.6,.3,weather),.9,cmap(PSInput.pos))*smoothstep(.6,.3,l));

PSOutput.color=lerp(col,FOG_COLOR,PSInput.fog);

}
