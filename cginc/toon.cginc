#pragma once
//shading properties
float _ShadeRange;
float _ShadeSoftness;
float _ShadeMax;
float _ShadeMin;
float _ShadePivot;

//input expected should be between 0 and 1.
float ApplyProceduralToonRamp(float d) {
	float e = d - _ShadePivot; //-.5,.5
	if (_ShadeSoftness > 0) {
		e *= 1 / _ShadeSoftness;
		e += _ShadePivot;
		e = saturate(e); //0 to 1.
	}
	else {
		e = saturate(floor(e + 1));//0 or 1.
	}

#if UNITY_PASS_FORWARDADD
	//forward add needs a baseline of 0. No range is applied.
	e += _ShadePivot;
#else
	//Range only makes sense in the base pass.
	e *= _ShadeRange;
	e += 1 - _ShadeRange;
#endif

	return e;
}

/*
	The inputs on this should not be normalize, because for something with
	spherical harmonics, it will be destroyed. If need be, normalize
	before passing to this method.
*/
float ToonDot(float3 direction, float3 normal, float attenuation)
{
	//the (,1) has to be done to get a proper value. Because we only want the directional brightness, we need to equate it assuming an intensity of 1. Giving us a value of 0 to 2.
	float d = dot(float4(direction, 1), float4(normal, 1)); //0 to 2.
	d /= 2; //0 to 1
	d = saturate(d);

	d *= attenuation;
	float brightness = ApplyProceduralToonRamp(d);

	brightness = min(_ShadeMax, brightness);//just to help prevent overdrive.
	return brightness;
}

float4 applyCut(float4 color) {
	if (color.a <= _TCut) {
		color = -1;
	}
	return color;
}