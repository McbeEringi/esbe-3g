//huge thanks to @MCH_YamaRin
#include "ShaderConstants.fxh"
#include "util.fxh"
#include "snoise.fxh"
#include "pnoise.fxh"

struct PS_Input{
	float4 position : SV_Position;
	#ifndef BYPASS_PIXEL_SHADER
		lpfloat4 color : COLOR;
		snorm float2 uv0 : TEXCOORD_0_FB_MSAA;
		snorm float2 uv1 : TEXCOORD_1_FB_MSAA;
	#endif
	#ifdef FOG
		float fog : fog;
	#endif
	float block : block;
	float3 cpos : cpos;
	float3 wpos : wpos;
};
struct PS_Output{
	float4 color : SV_Target;
};
#ifdef FANCY
	#define USE_NORMAL
#endif

#define linearstep(a,b,x) saturate((x-a)/(b-a))
bool is(float x,float a){return a-.01<x&&x<a+.01;}
float pow5(float x){return x*x*x*x*x;}
//https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
float3 aces(float3 x){return saturate((x*(2.51*x+.03))/(x*(2.43*x+.59)+.14));}
float3 tone(float3 col, float4 gs){
	col=pow(col,1./gs.rgb);
	float lum=dot(col,float3(.298912,.586611,.114478));
	col=aces((col-lum)*gs.a+lum);
	return col/aces(1.7);//exposure
}
float cmap(float2 p){
	float2 t=float2(-TOTAL_REAL_WORLD_TIME,64);
	return dot(float2(snoise(p*4.+t*.01),snoise(p*16.+t*.1)),float2(1,.1));
}
float4 water(float3 cpos,float3 wpos,float4 col,float weather,float uw,float sun,float day,float3 n){
	float t=TOTAL_REAL_WORLD_TIME;
	float2 p=cpos.xz+smoothstep(0.,8.,abs(cpos.y-8.))*.5;p.x*=2.;
	float h=pnoise(p+t*float2(-.8,.8),16.,.0625)+pnoise(p*1.25+t*float2(-.8,-1.6),20.,.05);
	float cost=dot(normalize(-wpos),n);
	float4 col_=col*lerp(1.,lerp(1.4,1.6,uw),pow(1.-abs(h)*.5,lerp(1.5,2.5,uw)));
	if(!bool(uw)){
		float3 rpos=reflect(wpos,n);
		float2 spos=(rpos.xz+h*rpos.xz/max(rpos.y,1.)*1.5)*pow(abs(rpos.y),-.8);//*sign(rpos.y);
		float2 srad=normalize(float2(length(spos),1));
		float4 scol=lerp(lerp(float4(FOG_COLOR.rgb,1),col,srad.y),float4((lerp(.2,1.,day)+FOG_COLOR.rgb)*.5,1),smoothstep(lerp(-.6,.3,weather),.9,cmap(spos*.04))*step(0.,rpos.y));
		#ifdef USE_NORMAL
			scol.a=lerp(0.,scol.a,step(0.,cost));//ScreenSpaceNormalCalc fix
		#endif
		col_=lerp(col_,lerp(scol,col,clamp(cost,.0,.7)),sun);
	}
	return col_;
}

ROOT_SIGNATURE
void main(in PS_Input PSInput, out PS_Output PSOutput){
#ifdef BYPASS_PIXEL_SHADER
	PSOutput.color=0.;
	return;
#else

//=*=*=
float3 n=
#ifdef USE_NORMAL
	normalize(cross(ddx(-PSInput.cpos),ddy(PSInput.cpos)));
#else
	float3(0,1,0);
#endif
float day=linearstep(TEXTURE_1.Sample(TextureSampler1,float2(0,0)).r*3.6,1.,TEXTURE_1.Sample(TextureSampler1,float2(0,1)).r);
float2 sun=smoothstep(float2(.5,.865),float2(1.,.875),PSInput.uv1.yy);
float ao=linearstep(.2,.8,day);
ao=lerp(1.,smoothstep(lerp(.6,.48,ao),lerp(.7,.52,ao),PSInput.color.g),step(max(max(PSInput.color.r,PSInput.color.g),PSInput.color.b)-min(min(PSInput.color.r,PSInput.color.g),PSInput.color.b),0.));
float dusk=min(smoothstep(0.2,0.4,day),smoothstep(0.8,0.6,day));
float weather=
#ifdef FOG
	smoothstep(.3,.7,FOG_CONTROL.x);
#else
	1.;
#endif
float uw=
#ifdef FOG
	step(FOG_CONTROL.x,0.);
#else
	0.;
#endif
float nether=
#ifdef FOG
	FOG_CONTROL.x/FOG_CONTROL.y;nether=step(.1,nether)-step(.12,nether);
#else
	0.;
#endif
float dayw=day*weather;
float4 ambient=
	lerp(lerp(float4(1.,.98,0.96,1.1),//indoor
	lerp(float4(.8,.86,.9,.95),//rain
	lerp(lerp(float4(.86,.8,.9,1.),//night
	float4(1.13,1.12,1.1,1.2),//noon
	day),float4(1.1,.8,.5,.9),//dusk
	dusk),weather),sun.x),float4((FOG_COLOR.rgb+2.)*.4,1),//from fog
	max(uw,nether));
float2 uv1_=float2(max(PSInput.uv1.x-sun.x*dayw,0.),PSInput.uv1.y);
//=*=*=

#if USE_TEXEL_AA
	float4 diffuse=texture2D_AA(TEXTURE_0,TextureSampler0,PSInput.uv0);
#else
	float4 diffuse=TEXTURE_0.Sample(TextureSampler0,PSInput.uv0);
#endif

#ifdef SEASONS_FAR
	diffuse.a=1.;
#endif

#if USE_ALPHA_TEST
	if(diffuse.a<
	#ifdef ALPHA_TO_COVERAGE
		.05
	#else
		.5
	#endif
	)discard;
#endif

float4 inColor=PSInput.color;

#ifdef BLEND
	diffuse.a*=inColor.a;
#endif

#ifndef ALWAYS_LIT
	diffuse*=TEXTURE_1.Sample(TextureSampler1,uv1_);
#endif

#ifndef SEASONS
	#if !USE_ALPHA_TEST && !defined(BLEND)
		diffuse.a=inColor.a;
	#endif
	diffuse.rgb*=inColor.rgb;
#else
	float2 uv=inColor.xy;
	diffuse.rgb*=lerp(1.,TEXTURE_2.Sample(TextureSampler2,uv).rgb*2.,inColor.b);
	diffuse.rgb*=inColor.aaa;
	diffuse.a=1.;
#endif

//=*=*=
diffuse.rgb*=lerp(.5,1.,min(min(sun.y,ao)+max(uv1_.x*uv1_.x-sun.y,0.)+(1.-dayw)*.8,1.));//shadow
if(is(PSInput.block,1.)||uw>.5)diffuse=water(PSInput.cpos,PSInput.wpos,diffuse,weather,uw,sun.x,day,n);//water
#ifdef USE_NORMAL
	else if(uw<.5)diffuse.rgb=lerp(diffuse.rgb,ambient.rgb,(1.-weather)*smoothstep(-.7,1.,n.y)*pow5(1.-dot(normalize(-PSInput.wpos),n))*sun.x*day*(pnoise(PSInput.cpos.xz,16.,.0625)*.2+.8));//wet
	diffuse.rgb*=lerp(1.,lerp(dot(n,float3(0.,.8,.6))*.4+.6,max(dot(n,float3(.9,.44,0.)),dot(n,float3(-.9,.44,0.)))*1.3+.2,dusk),sun.x*min(1.25-uv1_.x,1.)*dayw);//flatShading
#endif
diffuse.rgb+=uv1_.x*uv1_.x*float3(1,.67,.39)*.1*(1.-sun.x);//light
diffuse.rgb=tone(diffuse.rgb,ambient);//tonemap
//=*=*=

#ifdef FOG
	diffuse.rgb=lerp(diffuse.rgb,FOG_COLOR.rgb,PSInput.fog);
#endif

PSOutput.color=diffuse;
#ifdef VR_MODE
	PSOutput.color=max(PSOutput.color,1/255.);
#endif

#endif
}
