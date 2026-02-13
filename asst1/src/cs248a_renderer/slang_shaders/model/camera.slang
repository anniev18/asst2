implementing "../model.slang";
import math;

public struct Camera
{
    // The inverse view matrix of the camera (matrix transform from view space to world space).
    public float4x4 invViewMatrix;
    // The canvas size of the target image in pixels.
    public uint2 canvasSize;
    // The focal length of the camera in pixels (distance between the pinhole and the image plane).
    public float focalLength;

    /**
     * Generate a camera ray given a normalized uv coordinate on canvas.
     * @param uv The normalized uv coordinate from (0, 0) in the bottom-left to (1, 1) in the top-right.
     * @return The generated Ray. Before you start working the transform section, generate ray as if the camera is at origin looking towards negative z direction.
     * After you finish the transform section, you should transform the ray from view space to world space using the inverse view matrix.
     */
    public Ray generateRay(float2 uv)
    {
        // TODO: Student implementation starts here.
        // centering uv coordinate so that (0,0) is in the center
        float3 direction;
        direction.x = (uv.x - 0.5) * canvasSize.x;
        direction.y = (uv.y - 0.5) * canvasSize.y;
        direction.z = -focalLength;
        // normalize the direction vector
        direction = normalize(direction);

        float3 origin = float3 (0.0, 0.0, 0.0);
        // rotate but don't translate
        direction = normalize(mul(invViewMatrix, float4(direction, 0.0)).xyz);
        // rotate and translate it
        origin = mul(invViewMatrix, float4(origin, 1.0)).xyz;
        
        return Ray(origin, direction, float2(0.0, float.maxValue));

        // TODO: Student implementation ends here.
    }
}
