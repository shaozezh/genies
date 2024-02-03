// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//	============================================================
//	Name:		AtlasShader
//	Author: 	Joen Joensen (@UnLogick)
//	============================================================
// This shader renders the atlas texture and outputs a new texture for
// every time that an asset is added to the scene

Shader "UMA/AtlasShaderNew" {
	Properties{
		_Color("Main Color", Color) = (1,1,1,1)
		_AdditiveColor("Additive Color", Color) = (0,0,0,0)
		_MainTex("Base Texture", 2D) = "white" {}
		_ExtraTex("mask", 2D) = "white" {}
	}

		SubShader{
			Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
			Fog { Mode Off }
			Lighting Off

		// First pass: renders opaque portions of the atlas
		Pass
		{
			Tags { "LightMode" = "Vertex" }
			// One OneMinusSrcAlpha: pre-multiplied transparency
			// pre-renders transparent portions 
			// One One: additive blend
			// additively renders output on top of previous color, either base or color of previous overlay layer
			BlendOp Add, Add
			Blend One OneMinusSrcAlpha, One One
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			float4 _Color;
			float4 _AdditiveColor;
			sampler2D _MainTex;
			sampler2D _ExtraTex;

			struct v2f {
				float4  pos : SV_POSITION;
				float2  uv : TEXCOORD0;
			};

			float4 _MainTex_ST;

			v2f vert(appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}

			half4 frag(v2f i) : COLOR
			{
				// Color is proportional to mask opacity/alpha
				half4 texcol = tex2D(_MainTex, i.uv) * _Color + _AdditiveColor;
				half4 maskcol = tex2D(_ExtraTex, i.uv);
				return texcol * maskcol.a;

			}
			ENDCG
		}

		// Second pass: renders transparent portions of the atlas
		Pass
		{
				// Add the inverse of the output color's alpha into the current destination,
				// which is the output of the previous pass
				// this can also be described as a 'soft additive' blend
				Blend OneMinusDstAlpha One
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"

				float4 _Color;
				float4 _AdditiveColor;
				sampler2D _MainTex;
				sampler2D _ExtraTex;

				struct v2f {
					float4  pos : SV_POSITION;
					float2  uv : TEXCOORD0;
				};

				float4 _MainTex_ST;

				v2f vert(appdata_base v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
					return o;
				}

				half4 frag(v2f i) : COLOR
				{
					// Renders all transparent materials
					// by outputting the texture color proportional to the inverse of the mask
					half4 texcol = tex2D(_MainTex, i.uv) * _Color + _AdditiveColor;
					half4 maskcol = tex2D(_ExtraTex, i.uv);
					float value = 1 - maskcol.a;
					return texcol * value;
				}
				ENDCG
			}
	}

		Fallback "Transparent/VertexLit"
}