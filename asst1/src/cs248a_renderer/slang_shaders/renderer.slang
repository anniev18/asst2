import math;
import texture;
import material;
import model;
import primitive;

public struct RendererUniform
{
    // Camera parameters.
    public Camera camera;
    // Ambient color, used when no ray hits a primitive
    public float4 ambientColor;
    // Ray samples per pixel
    public uint sqrtSpp;
    // Primitives.
    public StructuredBuffer<Triangle> triangleBuf;
    public uint triangleCount;
    public SharedTexture3DBuffer<float4> volumeTexBuf;
    public StructuredBuffer<Volume> volumeBuf;
    public uint volumeCount;
    public SDFBuffer sdfBuf;
    // Acceleration structure.
    public bool useBVH;
    public BVH<Triangle> bvh;

    public bool renderDepth;
    public bool renderNormal;
}

static uint MAX_STEPS = 100;
static float EPSILON = 1e-6;

/**
 * Sample the scene at the given uv coordinate.
 * @param uv The normalized uv coordinate from (0, 0) in the bottom-left to (1, 1) in the top-right.
 * @param uniforms The renderer uniform containing camera, sampling, and scene information.
 * @return The color of the ray sample at the given uv coordinate.
 */
public float4 sample(float2 uv, RendererUniform uniforms)
{
    // We generate a camera ray for the given uv coordinate.
    // You need to implement the `generateRay` function in `Camera` struct in `src/cs248a_renderer/slang_shaders/model/camera.slang`
    
    Ray ray = uniforms.camera.generateRay(uv);
    
    RayHitResult result;

    // // TODO: Student implementation starts here.
    // float closestT = float.maxValue;
    // bool hitRay = false; 
    // Triangle closestTriangle;


    // for (uint i = 0; i < uniforms.triangleCount; i++) {
    //     Triangle triangle = uniforms.triangleBuf[i];
    //     Optional<RayHitResult> hitResult = triangle.hit(ray);
        
    //     if (hitResult.hasValue)
    //     {
    //         RayHitResult resultVal = hitResult.value;
    //         hitRay = true;
    //         if (resultVal.t < closestT) {
    //             closestT = resultVal.t; 
    //             closestTriangle = triangle;
    //             result = resultVal;
    //         }
    //     }    

    // }
    // if (!hitRay) {
    //     return uniforms.ambientColor;
    // } 
    // Ray ray = uniforms.camera.generateRay(uv);
    
    // RayHitResult result;

    // // TODO: Student implementation starts here.
    float closestT = float.maxValue;
    bool hitRay = false; 
    Volume closestVolume;


    for (uint i = 0; i < uniforms.volumeCount; i++) {
        Volume volume = uniforms.volumeBuf[i];
        Optional<RayHitResult> hitResult = volume.hit(ray, uniforms.volumeTexBuf);
        
        if (hitResult.hasValue)
        {
            RayHitResult resultVal = hitResult.value;
            hitRay = true;
            if (resultVal.t < closestT) {
                closestT = resultVal.t; 
                closestVolume = volume;
                result = resultVal;
            }
        }    

    }
    if (!hitRay) {
        return uniforms.ambientColor;
    } 


    // Ray ray = uniforms.camera.generateRay(uv);
    // RayHitResult result;

    // float3 rOrigin = ray.origin;
    // float3 rDirection = ray.direction;

    // float t = 0.0;
    // float3 normal; 

    // float minSDFDist = float.maxValue;
    // Tuple<float, float3> sdfDist;

    // // we are within the max steps and still in range
    // while (MAX_STEPS > 0 && ray.tRange.y > ray.tRange.x)
    // {
    //     // A Tuple containing the minimum signed distance and the normal of the closest SDF primitive.
    //     sdfDist = uniforms.sdfBuf.sample(rOrigin);
    //     minSDFDist = sdfDist._0;

    //     // have we hit something?
    //     if (minSDFDist <= EPSILON) {
    //         t = ray.tRange.x;
    //         normal = sdfDist._1;
    //         break;
    //     }

    //     // move along the ray by sdf distance
    //     rOrigin += minSDFDist * rDirection;
    //     ray.tRange.x += minSDFDist;
    //     MAX_STEPS -= 1;
   
    // }

    // // if we hit something, fill in result
    // if (minSDFDist <= EPSILON) {
    //     result.t = t;
    //     result.normal = normal;
    // } else {
    //     return uniforms.ambientColor;
    // }   

    // TODO: Student implementation ends here.

    if (uniforms.renderDepth)
    {
        // Map depth to [0, 1] range for visualization
        return float4(float3(result.t), 1.0);
    }

    if (uniforms.renderNormal)
    {
        // Map normal from [-1, 1] to [0, 1] range for visualization
        return float4(result.normal * 0.5 + 0.5, 1.0);
    }

    // Once you have the intersection result, use the following code to shade (calculate color) for the ray.
    // The shading function needs the camera ray and the intersection result.
    SimpleMaterial simpleMaterial;
    float3 color = simpleMaterial.shade(ray, result);
    return float4(color, 1.0);
}

/**
 * The entry point of the renderer.
 * @param tid The 2D coordinate of the current thread. Ranges from (0, 0) to (canvasSize.x - 1, canvasSize.y - 1).
 * @param uniforms The renderer uniform containing camera, sampling, and scene information.
 * @return The color of the pixel at the given thread coordinate.
 */
public float4 render(uint2 tid, RendererUniform uniforms)
{
    // TODO: Student implementation starts here.
    float4 colorSum = float4(0.0, 0.0, 0.0, 0.0);

    for (uint i = 0; i < uniforms.sqrtSpp; i++) {
        for (uint j = 0; j < uniforms.sqrtSpp; j++) {
            float offsetX = (i + 0.5) / uniforms.sqrtSpp;
            float offsetY = (j + 0.5) / uniforms.sqrtSpp;

            float2 uv = (float2(tid) + float2(offsetX, offsetY)) / float2(uniforms.camera.canvasSize);
            colorSum += sample(uv, uniforms);
        }
    }
    float totalSamples = float(uniforms.sqrtSpp * uniforms.sqrtSpp);
    
    return colorSum / totalSamples;
    
    // Basic version: no supersampling.
    // float2 uv = (float2(tid) + 0.5) / float2(uniforms.camera.canvasSize);
    // return sample(uv, uniforms);

    // TODO: Student implementation ends here.
}
