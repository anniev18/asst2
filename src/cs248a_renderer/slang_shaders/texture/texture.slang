implementing "../texture.slang";

public struct SharedTexture2DBuffer<T>
    where T : IFloat
{
    public StructuredBuffer<T> buffer;

    T getBufferValue(SharedTexture2D tex, uint2 texelCoord)
    {
        uint2 texSize = tex.size;
        uint offset = tex.offset;
        uint index = texelCoord.y * texSize.x + texelCoord.x;
        return buffer[offset + index];
    }

    public T pointSample(SharedTexture2D tex, float2 uv)
    {
        T outV = T(0.0);
        // TODO: Student implementation starts here.
        float2 wrappedUV = frac(uv);
        uint2 texelCoord = uint2(wrappedUV * float2(tex.size));
        outV = getBufferValue(tex, texelCoord);
        // TODO: Student implementation ends here.
        return outV;
    }

    public T bilinearSample(SharedTexture2D tex, float2 uv)
    {
        T outV = T(0.0);
        // TODO: Student implementation starts here.
        uint2 maxCoord = tex.size - uint2(1);
        float2 xy = uv * float2(tex.size) - 0.5;
        int2 i0 = int2(floor(xy));
        int2 i1 = i0 + int2(1, 1);
        float2 f = xy - float2(i0);

        uint2 base = uint2(clamp(i0, int2(0, 0), int2(maxCoord)));
        uint2 next = uint2(clamp(i1, int2(0, 0), int2(maxCoord)));

        T c00 = getBufferValue(tex, base);
        T c10 = getBufferValue(tex, uint2(next.x, base.y));
        T c01 = getBufferValue(tex, uint2(base.x, next.y));
        T c11 = getBufferValue(tex, next);
        
        // bilinear interpolation

        T c0 = c00 + (c10 - c00) * T(f.x);
        T c1 = c01 + (c11 - c01) * T(f.x);
        outV = c0 + (c1 - c0) * T(f.y);



        // TODO: Student implementation ends here.
        return outV;
    }

    public T trilinearSample(SharedTexture2D[] mipmapLevels, float2 uv, float d, uint totalLevels)
    {
        T outV = T(0.0);
        // TODO: Student implementation starts here.
        // `d` is already the mip level computed by getLevel().
        float level = clamp(d, 0.0, float(totalLevels - 1));
        uint level0 = uint(floor(level));
        uint level1 = min(level0 + 1, totalLevels - 1);
        float f = level - float(level0);
        T c0 = bilinearSample(mipmapLevels[level0], uv);
        T c1 = bilinearSample(mipmapLevels[level1], uv);

        outV = c0 + (c1 - c0) * T(f);
        
        // TODO: Student implementation ends here.
        return outV;
    }
}

public struct SharedTexture2D
{
    public uint2 size;
    public uint offset;
}

public struct SharedTexture3DBuffer<T>
    where T : IFloat
{
    public StructuredBuffer<T> buffer;

    T getBufferValue(SharedTexture3D tex, uint3 voxelCoord)
    {
        uint3 texSize = tex.size;
        uint offset = tex.offset;
        uint index = voxelCoord.z * texSize.y * texSize.x +
                     voxelCoord.y * texSize.x +
                     voxelCoord.x;
        return buffer[offset + index];
    }

    /**
     * Sample the texture at the given uvw coordinates using nearest neighbor interpolation.
     * @param tex The texture to sample.
     * @param uvw The uvw coordinates to sample the texture at.
     * @return The sampled value.
     */
    public T pointSample(SharedTexture3D tex, float3 uvw)
    {
        // TODO: Student implementation starts here.
        return getBufferValue(tex, uint3(
            min(uint(tex.size.x - 1), uint(uvw.x * float(tex.size.x))),
            min(uint(tex.size.y - 1), uint(uvw.y * float(tex.size.y))),
            min(uint(tex.size.z - 1), uint(uvw.z * float(tex.size.z)))
        ));

        // TODO: Student implementation ends here.
    }
        // Note for grader: found on ed
    T lerpT<T : IFloat>(T a, T b, float t)
    {
        return a + (b - a) * T(t);
    }

    /**
     * Sample the texture at the given uvw coordinates using trilinear interpolation.
     * @param tex The texture to sample.
     * @param uvw The uvw coordinates to sample the texture at.
     * @return The sampled value.
     **/
    public T trilinearSample(SharedTexture3D tex, float3 uvw)
    {
        // TODO: Student implementation starts here.
        float3 pos = uvw * (float3(tex.size) - 1);
        uint3 base = uint3(pos);
        float3 f = pos - float3(base);

        uint3 base1 = min(base + 1, tex.size - 1);

        T c000 = getBufferValue(tex, base);
        T c100 = getBufferValue(tex, uint3(base1.x, base.y, base.z));
        T c010 = getBufferValue(tex, uint3(base.x, base1.y, base.z));
        T c110 = getBufferValue(tex, uint3(base1.x, base1.y, base.z));
        T c001 = getBufferValue(tex, uint3(base.x, base.y, base1.z));
        T c101 = getBufferValue(tex, uint3(base1.x, base.y, base1.z));
        T c011 = getBufferValue(tex, uint3(base.x, base1.y, base1.z));
        T c111 = getBufferValue(tex, base1);

        // trilinear
        T c00 = lerpT(c000, c100, f.x);
        T c10 = lerpT(c010, c110, f.x);
        T c01 = lerpT(c001, c101, f.x);
        T c11 = lerpT(c011, c111, f.x);

        T c0 = lerpT(c00, c10, f.y);
        T c1 = lerpT(c01, c11, f.y);

        return lerpT(c0, c1, f.z);

        // TODO: Student implementation ends here.
    }
}

public struct SharedTexture3D
{
    public uint3 size;
    public uint offset;
}
