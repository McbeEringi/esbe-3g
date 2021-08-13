//huge thanks to @MCH_YamaRin
#include "ShaderConstants.fxh"
struct PS_Input{
	float4 position : SV_Position;
	float4 color : COLOR;
};
struct PS_Output{
	float4 color : SV_Target;
};
ROOT_SIGNATURE
void main(in PS_Input PSInput, out PS_Output PSOutput){PSOutput.color.rgb=float4(CURRENT_COLOR.rgb*abs(sin(TOTAL_REAL_WORLD_TIME*PSInput.color.a)),PSInput.color.a);}
