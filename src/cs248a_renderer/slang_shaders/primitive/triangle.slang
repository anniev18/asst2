implementing "../primitive.slang";
import math;

public struct Triangle : IBoundingBox, IRayCastable
{
    public float3[3] vertices;
    public float3[3] normals;
    public float2[3] uvs;
    public float3[3] colors;
    public uint materialId;
    public uint offset;

    public BoundingBox boundingBox()
    {
        return BoundingBox(float3(0.0), float3(0.0));
    }

    /* Returns the average color of the triangle. */
    public float3 averageColor()
    {
        return (this.colors[0] + this.colors[1] + this.colors[2]) / 3.0;
    }

    /**
     * Calculates the barycentric coordinates of a point on the triangle.
     * @param p The point on the triangle to calculate the barycentric coordinates for.
     * @return The barycentric coordinates of the point.
     */
    public float3 calculateBarycentricCoord(float3 p)
    {
        const float EPSILON = 1e-6;
        float u = 0.0;
        float v = 0.0;
        float w = 0.0;

        // TODO: Student implementation starts here.
        float3 v0 = vertices[0];
        float3 v1 = vertices[1];
        float3 v2 = vertices[2];

        float3 e1 = v1 - v0;
        float3 e2 = v2 - v1;
        float3 e3 = v0 - v2;

        float3 n = cross(e1, e2);
        float area = length(n) / 2.0;
        if (area < EPSILON)
        {
            // degenerate triangle
            return float3(1.0 / 3.0);
        }
        float3 c1 = p - v0;
        float3 c2 = p - v1;
        float3 c3 = p - v2;
        float area1 = length(cross(e1, c1)) / 2.0;
        float area2 = length(cross(e2, c2)) / 2.0;
        float area3 = length(cross(e3, c3)) / 2.0;

        u = area2 / area;
        v = area3 / area;
        w = area1 / area;

        // TODO: Student implementation ends here.

        return float3(u, v, w);
    }

    public float2 getUV(float3 barycentricCoord)
    {
        float2 uv = float2(0.0);

        float u = barycentricCoord.x;
        float v = barycentricCoord.y;
        float w = barycentricCoord.z;
        uv = u * this.uvs[0] + v * this.uvs[1] + w * this.uvs[2];
        
        return uv;
    }

    public float3 getColor(float3 barycentricCoord)
    {
        float u = barycentricCoord.x;
        float v = barycentricCoord.y;
        float w = barycentricCoord.z;
        float3 color = u * this.colors[0] + v * this.colors[1] + w * this.colors[2];
        return color;
    }

    public float3 getNormal(float3 barycentricCoord)
    {
        float u = barycentricCoord.x;
        float v = barycentricCoord.y;
        float w = barycentricCoord.z;
        float3 normal = u * this.normals[0] + v * this.normals[1] + w * this.normals[2];
        return normalize(normal);
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

        // find intersection with triangle plane
        float3 v0 = vertices[0];
        float3 v1 = vertices[1];
        float3 v2 = vertices[2];

        float3 e1 = v1 - v0;
        float3 e2 = v2 - v1;
        float3 e3 = v0 - v2;

        float3 n = cross(e1, e2);
        float t = (dot(n, v0) - dot(n, o)) / dot(n, d);

        if (t < trange.x || t > trange.y)
        {
            return Optional<RayHitResult>();
        }

        float3 x = o + t * d;

        // inside-outside test
        float3 c1 = x - v0;
        float3 c2 = x - v1;
        float3 c3 = x - v2;

        float L1 = dot(cross(e1, c1), n);
        float L2 = dot(cross(e2, c2), n);
        float L3 = dot(cross(e3, c3), n);

        if (L1 < 0 || L2 < 0 || L3 < 0)
        {
            return Optional<RayHitResult>();
        }

        RayHitResult result;
        result.t = t;
        result.normal = normalize(n);
        return Optional<RayHitResult>(result);

        // TODO: Student implementation ends here.
    }

    public uint getMaterialId()
    {
        return this.materialId + this.offset;
    }
}
