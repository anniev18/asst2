implementing "../primitive.slang";
import math;

public struct Triangle : IRayCastable
{
    public float3[3] vertices;
    public float3[3] normals;
    public float2[3] uvs;
    public float3[3] colors;
    public uint materialId;

    /* Returns the average color of the triangle. */
    public float3 averageColor()
    {
        return (this.colors[0] + this.colors[1] + this.colors[2]) / 3.0;
    }

    /**
     * Test ray-triangle intersection.
     * @param ray The ray to test against the triangle.
     * @return An Optional containing RayHitResult if the ray hits the triangle, otherwise an empty Optional.
     */
    public Optional<RayHitResult> hit(Ray ray)
    {
        // TODO: Student implementation starts here.
        float3 o = ray.origin;
        float3 d = ray.direction;
        float2 trange = ray.tRange;
        // need to do ray-triangle intersection test

        // 1.) find point of intersection x of ray with plane (if it exists)
        // compute the plane normal 
        float3 v0 = vertices[0];
        float3 v1 = vertices[1];
        float3 v2 = vertices[2];

        float3 e1 = v1 - v0;
        float3 e2 = v2 - v1;
        float3 e3 = v0 - v2;

        
        // plane normal
        float3 n = cross(e1, e2);

        float t = (dot(n, v0) - dot(n,o)) / dot(n, d); 

        if (t < trange.x || t > trange.y) {
            // out of range
            return Optional<RayHitResult>();
        }

        // plug back into ray equation 
        float3 x = o + t*d;

        // 2.) Determine if x is inside the triangle
        float3 c1 = x - v0;
        float3 c2 = x - v1;
        float3 c3 = x - v2;
        
        float L1 = dot(cross(e1, c1), n);
        float L2 = dot(cross(e2, c2), n);
        float L3 = dot(cross(e3, c3), n);


        if (L1 < 0 || L2 < 0 || L3 < 0) {
            // outside the triangle
            return Optional<RayHitResult>(); 
        };

        // hit confirmed
        RayHitResult result;
        result.t = t;
        result.normal = normalize(n); // simple average

        return Optional<RayHitResult>(result);
        // TODO: Student implementation ends here.
    }
}
