#include "ShaderConstants.fxh"

struct PS_Input{
	float4 position : SV_Position;
	float3 pos : pos;
};

struct PS_Output{
	float4 color : SV_Target;
};

ROOT_SIGNATURE
void main(in PS_Input PSInput, out PS_Output PSOutput){
	PSOutput.color = lerp(FOG_COLOR,CURRENT_COLOR,smoothstep(-.05,.05,PSInput.pos.y));
}
