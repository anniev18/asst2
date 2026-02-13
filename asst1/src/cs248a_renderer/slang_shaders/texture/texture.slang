implementing "../texture.slang";

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

        // scale back into tex coords
        float3 scaled_coords = float3(tex.size) * uvw;
        uint3 vox_coord = uint3(floor(scaled_coords));

        return getBufferValue(tex, vox_coord);

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

        // scale back into tex coords
        float3 scaled = float3(tex.size) * uvw;
        uint3 base = uint3(floor(scaled));

        float3 f = scaled - float3(base);

        // get 8 nearest points
        T first = getBufferValue(tex, base + uint3(0, 0, 0));
        T second = getBufferValue(tex, base + uint3(1, 0, 0));
        T third = getBufferValue(tex, base + uint3(0, 1, 0));
        T fourth = getBufferValue(tex, base + uint3(1, 1, 0));

        T fifth = getBufferValue(tex, base + uint3(0, 0, 1));
        T sixth = getBufferValue(tex, base + uint3(1, 0, 1));
        T seventh = getBufferValue(tex, base + uint3(0, 1, 1));
        T eigth = getBufferValue(tex, base + uint3(1, 1, 1));

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

