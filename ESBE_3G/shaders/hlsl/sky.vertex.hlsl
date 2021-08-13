//huge thanks to @MCH_YamaRin
#include "ShaderConstants.fxh"
struct VS_Input{
	float3 position : POSITION;
	float4 color : COLOR;
	#ifdef INSTANCEDSTEREO
		uint instanceID : SV_InstanceID;
	#endif
};
struct PS_Input{
	float4 position : SV_Position;
	float4 color : COLOR;
	float fog : Fog_Position;
	float2 pos : Position;
	#ifdef GEOMETRY_INSTANCEDSTEREO
		uint instanceID : SV_InstanceID;
	#endif
	#ifdef VERTEXSHADER_INSTANCEDSTEREO
		uint renTarget_id : SV_RenderTargetArrayIndex;
	#endif
};
ROOT_SIGNATURE
void main(in VS_Input VSInput, out PS_Input PSInput){

float4 p=float4(VSInput.position,1);
p.y-=length(p.xz)*.2;
PSInput.pos=VSInput.position.xz;
PSInput.fog=VSInput.color.r;

#ifdef INSTANCEDSTEREO
	PSInput.position=mul(WORLDVIEWPROJ_STEREO[VSInput.instanceID],p);
#else
	PSInput.position=mul(WORLDVIEWPROJ,p);
#endif
#ifdef GEOMETRY_INSTANCEDSTEREO
	PSInput.instanceID=VSInput.instanceID;
#endif
#ifdef VERTEXSHADER_INSTANCEDSTEREO
	PSInput.renTarget_id=VSInput.instanceID;
#endif

}
