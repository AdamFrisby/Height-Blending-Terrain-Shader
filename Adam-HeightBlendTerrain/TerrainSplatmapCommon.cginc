// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

// Modifications:
/*
Copyright (c) 2017 Adam Frisby

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#ifndef TERRAIN_SPLATMAP_COMMON_CGINC_INCLUDED
#define TERRAIN_SPLATMAP_COMMON_CGINC_INCLUDED

struct Input
{
    float2 uv_Splat0 : TEXCOORD0;
    float2 uv_Splat1 : TEXCOORD1;
    float2 uv_Splat2 : TEXCOORD2;
    float2 uv_Splat3 : TEXCOORD3;
    float2 tc_Control : TEXCOORD4;  // Not prefixing '_Contorl' with 'uv' allows a tighter packing of interpolators, which is necessary to support directional lightmap.
    UNITY_FOG_COORDS(5)
};

sampler2D _Control;
float4 _Control_ST;
sampler2D _Splat0,_Splat1,_Splat2,_Splat3;

#ifdef _TERRAIN_NORMAL_MAP
    sampler2D _Normal0, _Normal1, _Normal2, _Normal3;
#endif

void SplatmapVert(inout appdata_full v, out Input data)
{
    UNITY_INITIALIZE_OUTPUT(Input, data);
    data.tc_Control = TRANSFORM_TEX(v.texcoord, _Control);  // Need to manually transform uv here, as we choose not to use 'uv' prefix for this texcoord.
    float4 pos = UnityObjectToClipPos(v.vertex);
    UNITY_TRANSFER_FOG(data, pos);

#ifdef _TERRAIN_NORMAL_MAP
    v.tangent.xyz = cross(v.normal, float3(0,0,1));
    v.tangent.w = -1;
#endif
}

#ifdef TERRAIN_STANDARD_SHADER
void SplatmapMix(Input IN, half4 defaultAlpha, out half4 splat_control, out half weight, out fixed4 mixedDiffuse, inout fixed3 mixedNormal)
#else
void SplatmapMix(Input IN, out half4 splat_control, out half weight, out fixed4 mixedDiffuse, inout fixed3 mixedNormal)
#endif
{
    splat_control = tex2D(_Control, IN.tc_Control);
    weight = dot(splat_control, half4(1,1,1,1));

    #if !defined(SHADER_API_MOBILE) && defined(TERRAIN_SPLAT_ADDPASS)
        clip(weight == 0.0f ? -1 : 1);
    #endif

    // Normalize weights before lighting and restore weights in final modifier functions so that the overal
    // lighting result can be correctly weighted.
    splat_control /= (weight + 1e-3f);

    mixedDiffuse = 0.0f;



	half4 t0 = tex2D(_Splat0, IN.uv_Splat0);
	half4 t1 = tex2D(_Splat1, IN.uv_Splat1);
	half4 t2 = tex2D(_Splat2, IN.uv_Splat2);
	half4 t3 = tex2D(_Splat3, IN.uv_Splat3);

	splat_control = saturate(normalize(pow(saturate(float4(
		(t0.a + 0.01) * splat_control.r,
		(t1.a + 0.01) * splat_control.g,
		(t2.a + 0.01) * splat_control.b,
		(t3.a + 0.01) * splat_control.a
	)), 4)));

    #ifdef _TERRAIN_NORMAL_MAP
        fixed4 nrm = 0.0f;
        nrm += splat_control.r * tex2D(_Normal0, IN.uv_Splat0);
        nrm += splat_control.g * tex2D(_Normal1, IN.uv_Splat1);
        nrm += splat_control.b * tex2D(_Normal2, IN.uv_Splat2);
        nrm += splat_control.a * tex2D(_Normal3, IN.uv_Splat3);
        mixedNormal = UnpackNormal(nrm);
    #endif
	
    #ifdef TERRAIN_STANDARD_SHADER	
        mixedDiffuse += splat_control.r * t0 * half4(1.0, 1.0, 1.0, defaultAlpha.r);
        mixedDiffuse += splat_control.g * t1 * half4(1.0, 1.0, 1.0, defaultAlpha.g);
        mixedDiffuse += splat_control.b * t2 * half4(1.0, 1.0, 1.0, defaultAlpha.b);
        mixedDiffuse += splat_control.a * t3 * half4(1.0, 1.0, 1.0, defaultAlpha.a);
    #else
        mixedDiffuse += splat_control.r * t0;
        mixedDiffuse += splat_control.g * t1;
        mixedDiffuse += splat_control.b * t2;
        mixedDiffuse += splat_control.a * t3;
    #endif


}

#ifndef TERRAIN_SURFACE_OUTPUT
    #define TERRAIN_SURFACE_OUTPUT SurfaceOutput
#endif

void SplatmapFinalColor(Input IN, TERRAIN_SURFACE_OUTPUT o, inout fixed4 color)
{
    color *= o.Alpha;
    #ifdef TERRAIN_SPLAT_ADDPASS
        UNITY_APPLY_FOG_COLOR(IN.fogCoord, color, fixed4(0,0,0,0));
    #else
        UNITY_APPLY_FOG(IN.fogCoord, color);
    #endif
}

void SplatmapFinalPrepass(Input IN, TERRAIN_SURFACE_OUTPUT o, inout fixed4 normalSpec)
{
    normalSpec *= o.Alpha;
}

void SplatmapFinalGBuffer(Input IN, TERRAIN_SURFACE_OUTPUT o, inout half4 outGBuffer0, inout half4 outGBuffer1, inout half4 outGBuffer2, inout half4 emission)
{
    UnityStandardDataApplyWeightToGbuffer(outGBuffer0, outGBuffer1, outGBuffer2, o.Alpha);
    emission *= o.Alpha;
}

#endif // TERRAIN_SPLATMAP_COMMON_CGINC_INCLUDED
