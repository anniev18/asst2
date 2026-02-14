implementing "../primitive.slang";
import math;
import texture;

// The size of each marching step.
static float STEP_SIZE = 0.005;
// The density threshold to consider a hit.
static float DENSITY_THRESHOLD = 0.25;
// The delta used for finite difference normal estimation.
static float FINITE_DIFF_DELTA = 0.001;

public struct Volume
{
    public BoundingBox bound;
    public SharedTexture3D tex;
    public float4x4 modelMatrix;
    public float4x4 invModelMatrix;

    /**
     * Test ray-volume bounding box intersection.
     * @param ray The ray to test against the volume.
     * @param volumeTexBuf The texture buffer contains all the volumetrically represented models in the scene .
     * @return An Optional containing RayHitResult if the ray hits the volume, otherwise an empty Optional.
     */
    public Optional<RayHitResult> hit(Ray ray, SharedTexture3DBuffer<float4> volumeTexBuf)
    {
        float2 t_hit = this.bound.hit(ray);
        if (t_hit.x < 0.0 && t_hit.y < 0.0)
            return Optional<RayHitResult>();

        float t = max(t_hit.x, ray.tRange.x);
        float t_end = min(t_hit.y, ray.tRange.y);

        float3 p = ray.origin + t * ray.direction;
        float3 localP = mul(invModelMatrix, float4(p, 1)).xyz;
        float3 uvw = getUVW(localP);
        float prev = volumeTexBuf.trilinearSample(tex, uvw).w;

        t += STEP_SIZE;

        while (t < t_end)
        {
            p = ray.origin + t * ray.direction;
            localP = mul(invModelMatrix, float4(p, 1)).xyz;
            uvw = getUVW(localP);
            float d = volumeTexBuf.trilinearSample(tex, uvw).w; 

            if (prev < DENSITY_THRESHOLD && d >= DENSITY_THRESHOLD)
            {
                float3 e = float3(FINITE_DIFF_DELTA, 0, 0);
                float dx = volumeTexBuf.trilinearSample(tex, getUVW(localP + e)).w -
                           volumeTexBuf.trilinearSample(tex, getUVW(localP - e)).w;
                e = float3(0, FINITE_DIFF_DELTA, 0);
                float dy = volumeTexBuf.trilinearSample(tex, getUVW(localP + e)).w -
                           volumeTexBuf.trilinearSample(tex, getUVW(localP - e)).w;
                e = float3(0, 0, FINITE_DIFF_DELTA);
                float dz = volumeTexBuf.trilinearSample(tex, getUVW(localP + e)).w -
                           volumeTexBuf.trilinearSample(tex, getUVW(localP - e)).w;

                float3 n_local = -float3(dx, dy, dz);
                float3 n_world = normalize(mul(float3x3(
                                                   modelMatrix[0].xyz,
                                                   modelMatrix[1].xyz,
                                                   modelMatrix[2].xyz
            ), n_local));

                RayHitResult r;
                r.t = t;
                r.normal = n_world;
                return Optional<RayHitResult>(r);
            }

            prev = d;
            t += STEP_SIZE;
        }
        return Optional<RayHitResult>();
        


}
    /**
     * Get the uvw coordinates of a point in local space.
     * @param p The point in world space.
     * @return The uvw coordinates in [0, 1].
     */
    public float3 getUVW(float3 p)
    {
        // Compute uvw coordinates in [0, 1].
        float3 minBound = this.bound.pMin;
        float3 maxBound = this.bound.pMax;
        return (p - minBound) / (maxBound - minBound);
    }
};
