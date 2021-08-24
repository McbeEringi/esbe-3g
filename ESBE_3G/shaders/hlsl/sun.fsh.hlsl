//huge thanks to @MCH_YamaRin
#include "ShaderConstants.fxh"
#include "util.fxh"
struct PS_Input{
	float4 position : SV_Position;
	float2 uv : TEXCOORD_0_FB_MSAA;
	float2 rpos : rpos;
	float2 pos : pos;
};
struct PS_Output{
	float4 color : SV_Target;
};
float4 tex0(float2 uv_){
	#if !defined(TEXEL_AA) || !defined(TEXEL_AA_FEATURE) || (VERSION<0xa000)
		return TEXTURE_0.Sample(TextureSampler0,uv_);
	#else
		return texture2D_AA(TEXTURE_0,TextureSampler0,uv_);
	#endif
}
ROOT_SIGNATURE
void main(in PS_Input PSInput, out PS_Output PSOutput){

float4 col=TEXTURE_0.Sample(TextureSampler0,0.);

//DEFAULT
float2 uv_=lerp(float2(floor(PSInput.uv.x*4.)*.25+.125,floor(PSInput.uv.y*2.)*.5+.25),.5,step(.5,TEXTURE_0.Sample(TextureSampler0,.5).r));
uv_=(PSInput.uv-uv_)*10.+uv_;

//ESBE_3G
float l=length(PSInput.rpos);
float mp=(floor(PSInput.uv.x*4.)*.25+step(PSInput.uv.y,.5))*3.1415926536;//[0~2pi]
float r=.13;
float3 n=normalize(float3(PSInput.rpos,sqrt(r*r-l*l)));
float2 np=float2(-atan2(n.x,n.z),asin(n.y))*.6366197724;// 2/pi [-1~1]
//float weather=smoothstep(.3,.8,FOG_CONTROL.x);

col=lerp(
	lerp(tex0(uv_),0.,step(.5,max(abs(PSInput.pos.x),abs(PSInput.pos.y)))),
	lerp(
		lerp(
			cos(min(l*2.,1.58))*sin(mp*.5)*.6,
			tex0(np*.5+.5)*.6+.4,
			smoothstep(-.3,.5,dot(-float3(sin(mp),0.,cos(mp)),n))*smoothstep(r,r*.9,l)
		),
		max(cos(min(l*12.,1.58)),(.5-l*.7)),
		step(.95,col.r)
	)*float4(1.,.95,.81,1),
	step(.05,col.r*col.a)
);

PSOutput.color=col*CURRENT_COLOR;

}
