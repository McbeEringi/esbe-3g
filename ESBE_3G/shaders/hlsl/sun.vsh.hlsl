#include "ShaderConstants.fxh"
struct VS_Input
{
    float3 position : POSITION;
    float2 uv : TEXCOORD_0;
#ifdef INSTANCEDSTEREO
	uint instanceID : SV_InstanceID;
#endif
};
struct PS_Input
{
    float4 position : SV_Position;
    float2 uv : TEXCOORD_0;
    float2 rpos : Rotated_Position;
    float2 pos : Position;
#ifdef GEOMETRY_INSTANCEDSTEREO
	uint instanceID : SV_InstanceID;
#endif
#ifdef VERTEXSHADER_INSTANCEDSTEREO
	uint renTarget_id : SV_RenderTargetArrayIndex;
#endif
};

ROOT_SIGNATURE
void main(in VS_Input VSInput, out PS_Input PSInput)
{
float4 p=float4(VSInput.position,1)*float2(10.,1.).xyxy;
#ifdef INSTANCEDSTEREO
	PSInput.position=mul(WORLDVIEWPROJ_STEREO[VSInput.instanceID],p);
#else
	PSInput.position=mul(WORLDVIEWPROJ,p);
#endif
PSInput.uv=VSInput.uv;
PSInput.rpos=mul(float2x2(.6,-.8,.8,.6),p.xz);
PSInput.pos=p.xz;

#ifdef GEOMETRY_INSTANCEDSTEREO
	PSInput.instanceID=VSInput.instanceID;
#endif 
#ifdef VERTEXSHADER_INSTANCEDSTEREO
	PSInput.renTarget_id=VSInput.instanceID;
#endif

}