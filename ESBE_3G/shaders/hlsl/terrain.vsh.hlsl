#include "ShaderConstants.fxh"

struct VS_Input {
	float3 position : POSITION;
	float4 color : COLOR;
	float2 uv0 : TEXCOORD_0;
	float2 uv1 : TEXCOORD_1;
#ifdef INSTANCEDSTEREO
	uint instanceID : SV_InstanceID;
#endif
};


struct PS_Input {
	float4 position : SV_Position;

#ifndef BYPASS_PIXEL_SHADER
	lpfloat4 color : COLOR;
	snorm float2 uv0 : TEXCOORD_0_FB_MSAA;
	snorm float2 uv1 : TEXCOORD_1_FB_MSAA;
#endif

#ifdef FOG
	float fog : Fog_Position;
#endif

float block : Block_Type;
float3 cpos : Chunked_Position;
float3 wpos : Camera_Position;
#ifdef GEOMETRY_INSTANCEDSTEREO
	uint instanceID : SV_InstanceID;
#endif
#ifdef VERTEXSHADER_INSTANCEDSTEREO
	uint renTarget_id : SV_RenderTargetArrayIndex;
#endif
};

float hash11(float p){p=frac(p*.1031);p*=p+33.33;return frac((p+p)*p);}
float random(float p){
	p=p*.3+TOTAL_REAL_WORLD_TIME;
	return lerp(hash11(floor(p)),hash11(ceil(p)),smoothstep(0.,1.,frac(p)))*2.;
}

ROOT_SIGNATURE
void main(in VS_Input VSInput, out PS_Input PSInput)
{
PSInput.block=0.;
#ifndef BYPASS_PIXEL_SHADER
	PSInput.uv0=VSInput.uv0;
	PSInput.uv1=VSInput.uv1;
	PSInput.color=VSInput.color;
#endif
// wave
float3 p=frac(VSInput.position*.0625)*16.;
float3 frp=frac(VSInput.position);
float wav=sin(TOTAL_REAL_WORLD_TIME*3.5-dot(p,float3(2,1.5,1)));
float rand=
#ifdef FANCY
	random(dot(p,1.));
#else
	1.;
#endif
float sun=lerp(.5,1.,smoothstep(0.,.5,VSInput.uv1.y));
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

// water
#ifndef SEASONS
	if(VSInput.color.a<.95 && VSInput.color.a>.05)PSInput.block=1.;
#endif

#ifdef AS_ENTITY_RENDERER
	#ifdef INSTANCEDSTEREO
		PSInput.position=mul(WORLDVIEWPROJ_STEREO[VSInput.instanceID],float4(VSInput.position,1));
	#else
		PSInput.position=mul(WORLDVIEWPROJ,float4(VSInput.position,1));
	#endif
		float3 worldPos=PSInput.position;
#else
	float3 worldPos=(VSInput.position.xyz*CHUNK_ORIGIN_AND_SCALE.w)+CHUNK_ORIGIN_AND_SCALE.xyz;
	float camDist=1.;
	#ifdef BLEND
		camDist=saturate(length(-worldPos.xyz)/FAR_CHUNKS_DISTANCE);
		PSInput.color.a=lerp(VSInput.color.a,1.,camDist);
		if(abs(frp.x-.5)==.125 && frp.z==0.)worldPos.x+=wav*.05*rand;
		else if(abs(frp.z-.5)==.125 && frp.x==0.)worldPos.z+=wav*.05*rand;
	#endif
	if(PSInput.block==1.)worldPos.y+=wav*.05*frac(VSInput.position.y)*rand*sun*(1.-camDist);
	#ifdef INSTANCEDSTEREO
		PSInput.position=mul(WORLDVIEW_STEREO[VSInput.instanceID],float4(worldPos,1));
		PSInput.position=mul(PROJ_STEREO[VSInput.instanceID],PSInput.position);
	#else
		PSInput.position=mul(WORLDVIEW,float4(worldPos,1));
		PSInput.position=mul(PROJ,PSInput.position);
	#endif
	#ifdef ALPHA_TEST
		float2 hgd=abs(frac(frp.xz*16.)-.5);
		if((max(max(VSInput.color.r,VSInput.color.g),VSInput.color.b)-min(min(VSInput.color.r,VSInput.color.g),VSInput.color.b)>.01&&frp.y!=.015625)||
			(frp.y==.9375&&(frp.x==0.||frp.z==0.))||
			((frp.y==0.||frp.y>.6)&&hgd.x<.48&&hgd.y<.48))PSInput.position.x+=wav*.016*rand*sun*PROJ[0].x;
	#endif

#endif
PSInput.cpos=VSInput.position;
PSInput.wpos=worldPos;
#ifdef GEOMETRY_INSTANCEDSTEREO
		PSInput.instanceID = VSInput.instanceID;
#endif 
#ifdef VERTEXSHADER_INSTANCEDSTEREO
		PSInput.renTarget_id = VSInput.instanceID;
#endif

#ifdef FOG
	float len=length(-worldPos.xyz)/RENDER_DISTANCE;
#ifdef ALLOW_FADE
	len+=RENDER_CHUNK_FOG_ALPHA;
#endif
	PSInput.fog=saturate((len-FOG_CONTROL.x)/(FOG_CONTROL.y-FOG_CONTROL.x));
	if(nether>.5)PSInput.position.xy+=wav*PSInput.fog*.15*(rand*.5+.5)*nether;
	else if(uw>.5)PSInput.position.x+=wav*PSInput.fog*.1*rand*uw;
#endif

#ifndef BYPASS_PIXEL_SHADER
	#ifndef FOG
		// If the FOG_COLOR isn't used, the reflection on NVN fails to compute the correct size of the constant buffer as the uniform will also be gone from the reflection data
		PSInput.color.rgb+=FOG_COLOR.rgb*.000001;
	#endif
#endif
}
