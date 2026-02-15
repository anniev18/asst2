implementing "../renderer.slang";

import math;
import texture;

public static uint MAX_STEPS = 1024;
public static float EPSILON = 1e-6;

public static float STEP_SIZE = 0.01;
public static float DENSITY_SCALE = 5.0;

/**
 * Perform ray marching through the volume and accumulate color.
 * @param uv The normalized uv coordinate from (0, 0) in the bottom-left to (1, 1) in the top-right.
 * @param uniforms The renderer uniform containing camera, sampling, and scene information.
 * @param tMax The maximum t value for ray marching (usually the nearest primitive intersection t).
 * @param primColor The color of the nearest primitive intersection.
 * @return The accumulated color after ray marching through the volume.
 */
public float4 volumeSample(float2 uv, RendererUniform uniforms, float tMax, float4 primColor)
{
    // TODO: Student implementation starts here.
    Ray ray = uniforms.camera.generateRay(uv);
    ray.tRange.y = min(ray.tRange.y, tMax);
    Ray localRay = ray.transform(uniforms.volume.invModelMatrix);
    return accumulateColor<1024>(
        localRay,
        uniforms.volume.bound,
        MAX_STEPS,
        STEP_SIZE,
        DENSITY_SCALE,
        primColor,
        uniforms.volume.tex);
    
    // TODO: Student implementation ends here.
}

/**
 * Backward pass for volumetric ray marching at a single uv.
 * @param uv The normalized uv coordinate from (0, 0) in the bottom-left to (1, 1) in the top-right.
 * @param uniforms The renderer uniform containing camera, sampling, and scene information.
 * @param outGrad The output gradient w.r.t. the sampled color.
 */
public void volumeSampleBwd(float2 uv, RendererUniform uniforms, float4 outGrad)
{
    // TODO: Student implementation starts here.

    // TODO: Student implementation ends here.
}

/**
 * Ray march through the volume and accumulate color.
 * @param ray The ray in local space.
 * @param volumeBound The bounding box of the volume in local space.
 * @param maxSteps The maximum number of marching steps.
 * @param stepSize The size of each marching step.
 * @param densityScale The scale factor for the volume density (alpha channel).
 * @param backgroundColor The background color behind the volume
                          (this can be the ambient color if there's no primitive behind the volume, or the color of the primitive hit if there's one).
 * @param data The 3D texture storing the volume data (rgba).
 * @return The accumulated color after ray marching through the volume.
 */
[Differentiable]
public float4 accumulateColor<let N : uint>(
    no_diff Ray ray,
    no_diff BoundingBox volumeBound,
    no_diff uint maxSteps,
    no_diff float stepSize,
    no_diff float densityScale,
    no_diff float4 backgroundColor,
    DiffTexture3D<float, 4> data)
{
    // TODO: Student implementation starts here.
    float2 hitRange = volumeBound.hit(ray);
    float tMin = max(hitRange.x, ray.tRange.x);
    float tMax = min(hitRange.y, ray.tRange.y);
    if (tMin > tMax)
        return backgroundColor;

    float3 rayOrigin = ray.origin;
    float3 rayDirection = ray.direction;
    float3 boundMin = volumeBound.pMin;
    float3 boundSize = volumeBound.size();

    float3 accumColor = float3(0.0);
    float accumAlpha = 0.0;
    float transmittance = 1.0;
    float t = tMin;

    [ForceUnroll]
    for (uint i = 0; i < N; i++)
    {
        if (i >= maxSteps || t > tMax || transmittance < EPSILON)
            break;

        float3 samplePoint = rayOrigin + t * rayDirection;
        float3 uvw = (samplePoint - boundMin) / boundSize;
        uvw = saturate(uvw);
        float4 sampleColor = sampleTrilinear(data, uvw);

        float density = max(sampleColor.a, 0.0);
        float alpha = saturate(density * densityScale * stepSize);
        float weight = transmittance * alpha;
        accumColor += weight * sampleColor.rgb;
        accumAlpha += weight;
        transmittance *= (1.0 - alpha);

        if (transmittance < EPSILON)
            break;
        t = t + stepSize;
    }

    accumColor += transmittance * backgroundColor.rgb;
    accumAlpha += transmittance * backgroundColor.a;
    return float4(accumColor, accumAlpha);
    // TODO: Student implementation ends here.
}
