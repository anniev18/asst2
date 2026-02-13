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
        uint3 maxCoord = tex.size - uint3(1);
        float3 clampedUVW = saturate(uvw);
        uint3 voxelCoord = uint3(clampedUVW * float3(maxCoord));

        return getBufferValue(tex, voxelCoord);

        // TODO: Student implementation ends here.
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
        uint3 maxCoord = tex.size - uint3(1);
        float3 xyz = saturate(uvw) * float3(maxCoord);
        int3 base = int3(floor(xyz));
        int3 next = min(base + int3(1), int3(maxCoord));
        float3 f = xyz - float3(base);

        // get 8 nearest points
        T first = getBufferValue(tex, uint3(base));
        T second = getBufferValue(tex, uint3(next.x, base.y, base.z));
        T third = getBufferValue(tex, uint3(base.x, next.y, base.z));
        T fourth = getBufferValue(tex, uint3(next.x, next.y, base.z));

        T fifth = getBufferValue(tex, uint3(base.x, base.y, next.z));
        T sixth = getBufferValue(tex, uint3(next.x, base.y, next.z));
        T seventh = getBufferValue(tex, uint3(base.x, next.y, next.z));
        T eigth = getBufferValue(tex, uint3(next));

        // trilinear interpolation
        T c00 = first + (second - first) * T(f.x);
        T c10 = third + (fourth - third) * T(f.x);
        T c01 = fifth + (sixth - fifth) * T(f.x);
        T c11 = seventh + (eigth - seventh) * T(f.x);

        T c0 = c00 + (c10 - c00) * T(f.y);
        T c1 = c01 + (c11 - c01) * T(f.y);

        return c0 + (c1 - c0) * T(f.z);

        // TODO: Student implementation ends here.
    }
}

public struct SharedTexture3D
{
    public uint3 size;
    public uint offset;
}
