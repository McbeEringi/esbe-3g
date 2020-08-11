#include "ShaderConstants.fxh"
#include "util.fxh"

struct PS_Input
{
	float4 position : SV_Position;

#ifndef BYPASS_PIXEL_SHADER
	lpfloat4 color : COLOR;
	snorm float2 uv0 : TEXCOORD_0_FB_MSAA;
	snorm float2 uv1 : TEXCOORD_1_FB_MSAA;
#endif

#ifdef FOG
	float4 fogColor : FOG_COLOR;
#endif
};

struct PS_Output
{
	float4 color : SV_Target;
};

float aces(float x){
	//https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
	return saturate((x*(2.51*x+.03))/(x*(2.43*x+.59)+.14));
}
float3 aces3(float3 x){return float3(aces(x.x),aces(x.y),aces(x.z));}
float3 tone(float3 col,float4 gs){
	float lum = dot(col,float3(.299,.587,.114));//http://poynton.ca/notes/colour_and_gamma/ColorFAQ.html#RTFToC11
	col = aces3((col-lum)*gs.a+lum)/aces(2.);
	return pow(col,1./gs.rgb);
}
float sat(float3 col){//https://qiita.com/akebi_mh/items/3377666c26071a4284ee
	float v=max(max(col.r,col.g),col.b);
	return v>0.?(v-min(min(col.r,col.g),col.b))/v:0.;
}

ROOT_SIGNATURE
void main(in PS_Input PSInput, out PS_Output PSOutput)
{
#ifdef BYPASS_PIXEL_SHADER
	PSOutput.color = float4(0.0f, 0.0f, 0.0f, 0.0f);
	return;
#else

#if USE_TEXEL_AA
	float4 diffuse = texture2D_AA(TEXTURE_0, TextureSampler0, PSInput.uv0 );
#else
	float4 diffuse = TEXTURE_0.Sample(TextureSampler0, PSInput.uv0);
#endif

#ifdef SEASONS_FAR
	diffuse.a = 1.0f;
#endif

#if USE_ALPHA_TEST
	#ifdef ALPHA_TO_COVERAGE
		#define ALPHA_THRESHOLD 0.05
	#else
		#define ALPHA_THRESHOLD 0.5
	#endif
	if(diffuse.a < ALPHA_THRESHOLD)
		discard;
#endif

#if defined(BLEND)
	diffuse.a *= PSInput.color.a;
#endif

#if !defined(ALWAYS_LIT)
	diffuse = diffuse * TEXTURE_1.Sample(TextureSampler1, PSInput.uv1);
#endif

#ifndef SEASONS
	#if !USE_ALPHA_TEST && !defined(BLEND)
		diffuse.a = PSInput.color.a;
	#endif

	diffuse.rgb *= PSInput.color.rgb;
#else
	float2 uv = PSInput.color.xy;
	diffuse.rgb *= lerp(1.0f, TEXTURE_2.Sample(TextureSampler2, uv).rgb*2.0f, PSInput.color.b);
	diffuse.rgb *= PSInput.color.aaa;
	diffuse.a = 1.0f;
#endif

//=*=*= ESBE_3G start =*=*=//

//datas
float2 sun = smoothstep(float2(.865,.5),float2(.875,1.),PSInput.uv1.yy);
float weather = smoothstep(.7,.96,FOG_CONTROL.y);
float2 daylight = float2(TEXTURE_1.Sample(TextureSampler1,float2(0.,1.)).r,TEXTURE_1.Sample(TextureSampler1,float2(.5,0.)).r);
daylight = float2(smoothstep(daylight.y-.2,daylight.y+.2,daylight.x));daylight.x*=weather;
float nv = step(TEXTURE_1.Sample(TextureSampler1,float2(0,0)).r,.5);
float dusk = min(smoothstep(.3,.5,daylight.y),smoothstep(1.,.8,daylight.y));
float4 ambient = lerp(//float4(gamma.rgb,saturation)
		float4(1.,.97,.9,1.15),//indoor
	lerp(lerp(
		float4(.9,.93,1.,1.),//night
		float4(1.15,1.17,1.1,1.2),//day
	daylight.y),
		float4(1.4,1.,.7,.8),//dusk
	dusk),sun.y*nv);
	if(FOG_COLOR.a<.001)ambient = float4(FOG_COLOR.rgb*.6+.4,.8);

//tonemap
diffuse.rgb = tone(diffuse.rgb,ambient);

//light_sorce
float lum = dot(diffuse.rgb,float3(.299,.587,.114));
diffuse.rgb += max(PSInput.uv1.x-.5,0.)*(1.-lum*lum)*lerp(1.,.3,daylight.x*sun.y)*float3(1.0,0.65,0.3);

//shadow
float ao = 1.;
if(PSInput.color.r==PSInput.color.g && PSInput.color.g==PSInput.color.b)ao = smoothstep(.48*daylight.y,.52*daylight.y,PSInput.color.g);
diffuse.rgb *= 1.-lerp(.5,0.,min(sun.x,ao))*(1.-PSInput.uv1.x);

//=*=*=  ESBE_3G end  =*=*=//

#ifdef FOG
	diffuse.rgb = lerp( diffuse.rgb, PSInput.fogColor.rgb, PSInput.fogColor.a );
#endif

	PSOutput.color = diffuse;

#ifdef VR_MODE
	// On Rift, the transition from 0 brightness to the lowest 8 bit value is abrupt, so clamp to
	// the lowest 8 bit value.
	PSOutput.color = max(PSOutput.color, 1 / 255.0f);
#endif

#endif // BYPASS_PIXEL_SHADER
}
