#include "ShaderConstants.fxh"

struct PS_Input{
	float4 position : SV_Position;
	float fog : fog;
	float3 pos : pos;
};

struct PS_Output{
	float4 color : SV_Target;
};

ROOT_SIGNATURE
void main(in PS_Input PSInput, out PS_Output PSOutput){
	PSOutput.color = lerp(CURRENT_COLOR,FOG_COLOR,PSInput.fog);
}
