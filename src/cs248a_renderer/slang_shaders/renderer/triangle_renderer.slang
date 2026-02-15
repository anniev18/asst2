implementing "../renderer.slang";


float3 simpleShade(float3 rayDir, float3 normal, float3 albedo)
{
    float NdotL = max(dot(normalize(normal), normalize(-rayDir)), 0.0);
    return albedo * NdotL;
}

public struct RayMeshSampleResult
{
    public float t;
    public float3 normal;
    public float4 color;
}

public struct RayMeshIntersectionResult
{
    public RayHitResult closestHit;
    public Triangle hitTriangle;
}

public Optional<RayMeshSampleResult> meshSample(float2 uv, RendererUniform uniforms)
{
    // We generate a camera ray for the given uv coordinate.
    // You need to implement the `generateRay` function in `Camera` struct in `src/cs248a_renderer/slang_shaders/model/camera.slang`
    Ray ray = uniforms.camera.generateRay(uv);
    RayHitResult result;

    Optional<RayMeshSampleResult> allResult;
    // Ray mesh intersection test.
    Optional<RayMeshIntersectionResult> rayMeshIntersectionResult = rayMeshIntersection(ray, uniforms);
    if (rayMeshIntersectionResult.hasValue)
    {
        RayHitResult result = rayMeshIntersectionResult.value.closestHit;
        float3 hitPoint = ray.origin + result.t * ray.direction;
        float3 barycentricCoord = rayMeshIntersectionResult.value.hitTriangle.calculateBarycentricCoord(hitPoint);
        float3 normal = result.normal;
        float2 tex_uv = rayMeshIntersectionResult.value.hitTriangle.getUV(barycentricCoord);
        float4 color = shadeTriangle(uv, uniforms, rayMeshIntersectionResult.value.hitTriangle, ray, tex_uv, normal, barycentricCoord);
        allResult = Optional<RayMeshSampleResult>(RayMeshSampleResult(result.t, normal, color));
    }

    return allResult;
}

public Optional<RayMeshIntersectionResult> rayMeshIntersection(Ray ray, RendererUniform uniforms)
{
    Optional<RayHitResult> result = Optional<RayHitResult>();

    // IMPORTANT CHANGE: We need to store the hit triangle.
    Optional<RayMeshIntersectionResult> allResult = Optional<RayMeshIntersectionResult>();
    Optional<Triangle> hitTriangle = Optional<Triangle>();
    // IMPORTANT CHANGE: We need to store the hit triangle.

    // TODO: Student implementation starts here.
    float closestT = float.maxValue;

    bool shouldRunBruteForce = true;
    if (uniforms.useBVH)
    {
        Optional<BVH<Triangle>.HitResult> bvhResult = uniforms.bvh.hit(ray);
        if (bvhResult.hasValue)
        {
            result = Optional<RayHitResult>(bvhResult.value.rayHitResult);
            hitTriangle = Optional<Triangle>(bvhResult.value.primitive);
            shouldRunBruteForce = false;
        }
    }

    if (shouldRunBruteForce)
    {
        for (uint i = 0; i < uniforms.triangleCount; i++)
        {
            Triangle triangle = uniforms.triangleBuf[i];
            Optional<RayHitResult> hitResult = triangle.hit(ray);
            if (hitResult.hasValue && hitResult.value.t < closestT)
            {
                closestT = hitResult.value.t;
                result = Optional<RayHitResult>(hitResult.value);
                hitTriangle = Optional<Triangle>(triangle);
            }
        }
    }

    // TODO: Student implementation ends here.

    if (result.hasValue && hitTriangle.hasValue)
    {
        allResult = Optional<RayMeshIntersectionResult>(RayMeshIntersectionResult(result.value, hitTriangle.value));
    }

    return allResult;
}

// Compute the level of the texture at the hit point.
// @param uv: The uv coordinates of the hit point.
// @param uniforms: The renderer uniforms.
// @param triangle: The triangle that was hit.
// @param tex_uv: The uv coordinates of the texture at the hit point.
// @return: The level of the texture at the hit point.
public float getLevel(float2 uv, RendererUniform uniforms, Triangle triangle, float2 tex_uv)
{
    float level = 0.0;

    //TODO: Student implementation starts here.
    // uint materialId = triangle.materialId + triangle.offset;
    // PhysicsBasedMaterial material = uniforms.physicsBasedMaterialBuf[materialId];
    // if (!material.albedo.useTexture || material.albedo.totalLevels == 0)
    //     return 0.0;

    // float2 pixelStep = 1.0 / float2(uniforms.camera.canvasSize);

    // float2 uvPx = clamp(uv + float2(pixelStep.x, 0.0), float2(0.0), float2(1.0));
    // float2 uvMx = clamp(uv - float2(pixelStep.x, 0.0), float2(0.0), float2(1.0));
    // float2 uvPy = clamp(uv + float2(0.0, pixelStep.y), float2(0.0), float2(1.0));
    // float2 uvMy = clamp(uv - float2(0.0, pixelStep.y), float2(0.0), float2(1.0));

    // float2 texUvPx = tex_uv;
    // float2 texUvMx = tex_uv;
    // float2 texUvPy = tex_uv;
    // float2 texUvMy = tex_uv;

    // Ray rayPx = uniforms.camera.generateRay(uvPx);
    // Ray rayMx = uniforms.camera.generateRay(uvMx);
    // Ray rayPy = uniforms.camera.generateRay(uvPy);
    // Ray rayMy = uniforms.camera.generateRay(uvMy);

    // Optional<RayHitResult> hitPx = triangle.hit(rayPx);
    // if (hitPx.hasValue)
    // {
    //     float3 p = rayPx.origin + hitPx.value.t * rayPx.direction;
    //     texUvPx = triangle.getUV(triangle.calculateBarycentricCoord(p));
    // }
    // Optional<RayHitResult> hitMx = triangle.hit(rayMx);
    // if (hitMx.hasValue)
    // {
    //     float3 p = rayMx.origin + hitMx.value.t * rayMx.direction;
    //     texUvMx = triangle.getUV(triangle.calculateBarycentricCoord(p));
    // }
    // Optional<RayHitResult> hitPy = triangle.hit(rayPy);
    // if (hitPy.hasValue)
    // {
    //     float3 p = rayPy.origin + hitPy.value.t * rayPy.direction;
    //     texUvPy = triangle.getUV(triangle.calculateBarycentricCoord(p));
    // }
    // Optional<RayHitResult> hitMy = triangle.hit(rayMy);
    // if (hitMy.hasValue)
    // {
    //     float3 p = rayMy.origin + hitMy.value.t * rayMy.direction;
    //     texUvMy = triangle.getUV(triangle.calculateBarycentricCoord(p));
    // }

    // float2 duvdx = (texUvPx - texUvMx) * 0.5;
    // float2 duvdy = (texUvPy - texUvMy) * 0.5;

    // float2 texSize = float2(material.albedo.mipmap[0].size);
    // float rho = max(length(duvdx * texSize), length(duvdy * texSize));
    // level = log2(max(rho, 1e-8));
    uint materialId = triangle.materialId + triangle.offset;
    PhysicsBasedMaterial material = uniforms.physicsBasedMaterialBuf[materialId];

    float2 pixelStep = 1.0 / float2(uniforms.camera.canvasSize);

    float2 offsets[4] = {
        float2(pixelStep.x, 0.0),   // +x
        float2(-pixelStep.x, 0.0),  // -x
        float2(0.0, pixelStep.y),   // +y
        float2(0.0, -pixelStep.y)   // -y
    };

    float2 texUv[4];
    bool valid[4];

    for (int i = 0; i < 4; ++i)
    {
        float2 shiftedUV = clamp(uv + offsets[i], 0.0, 1.0);
        Ray ray = uniforms.camera.generateRay(shiftedUV);

        Optional<RayMeshIntersectionResult> neighborHit = rayMeshIntersection(ray, uniforms);

        if (neighborHit.hasValue)
        {
            RayHitResult hit = neighborHit.value.closestHit;
            Triangle hitTri = neighborHit.value.hitTriangle;
            float3 p = ray.origin + hit.t * ray.direction;
            texUv[i] = hitTri.getUV(hitTri.calculateBarycentricCoord(p));

            valid[i] = true;
        }
        else
        {
            texUv[i] = tex_uv;   // safe fallback
            valid[i] = false;
        }
    }

    float2 duvdx = float2(0.0);
    float2 duvdy = float2(0.0);

    // Only compute derivative if BOTH sides are valid
    if (valid[0] && valid[1])
        duvdx = (texUv[0] - texUv[1]) * 0.5;

    if (valid[2] && valid[3])
        duvdy = (texUv[2] - texUv[3]) * 0.5;

    float2 texSize = float2(material.albedo.mipmap[0].size);

    float rhoX = length(duvdx * texSize);
    float rhoY = length(duvdy * texSize);

    float rho = max(rhoX, rhoY);

    // Clamp to prevent spikes
    float maxDim = max(texSize.x, texSize.y);
    rho = clamp(rho, 1e-8, maxDim);

    level = log2(rho);




    // TODO: Student implementation ends here.

    return max(level, 0.0);
}

public float4 shadeTriangle(float2 uv, RendererUniform uniforms, Triangle triangle, Ray ray, float2 tex_uv, float3 normal, float3 barycentricCoord)
{
    if (uniforms.visualizeBarycentricCoords)
    {
        return float4(barycentricCoord, 1.0);
    }
    if (uniforms.visualizeTexUV)
    {
        return float4(tex_uv, 0.0, 1.0);
    }
    // Get the level of detail of the texture at the hit point.
    float level = getLevel(uv, uniforms, triangle, tex_uv);
    uint discreteLevel = uint(level);

    // Sample albedo from the material at the hit point.
    uint materialId = triangle.materialId + triangle.offset;
    PhysicsBasedMaterial physicsBasedMaterial = uniforms.physicsBasedMaterialBuf[materialId];
    PhysicsBasedParameters parameters = sampleMaterial(physicsBasedMaterial, uniforms.physicsBasedMaterialTextureBuf, tex_uv, level, uniforms.visualizeLevelOfDetail);
    float3 albedo = parameters.albedo;

    if (uniforms.visualizeLevelOfDetail || uniforms.visualizeAlbedo)
    {
        return float4(float3(albedo), 1.0);
    }

    // Shade the triangle.
    float3 color = simpleShade(ray.direction, normal, albedo);
    return float4(color, 1.0);
}
