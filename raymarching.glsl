float sdPlane( vec3 p, vec3 n, float h )
{
  n = normalize(n);
  // n must be normalized
  return dot(p,n) + h;
}

float sdBoxFrame( vec3 p, vec3 b, float e )
{
       p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdGuy(in vec3 p, float r, float insideRadius)
{
    float t = fract(iTime/1.0f);
    float y = 10.5*t*(1.0f-t);
    vec3 center = vec3(0.0, y + r + insideRadius, 0.0);
    
    return length(p - center) - r;
}

float sdSphere(in vec3 p, float r)
{
    float sphereDistance =  length(p) - r;
    return sphereDistance;
}

float map(in vec3 p)
{
    float sphereRadiusInside = 0.5f;
    float sphereDistanceBounce = sdGuy(p, 0.25f, sphereRadiusInside);
    float sphereDistanceInside = sdSphere(p, sphereRadiusInside);
    float boxDistance1 = sdBoxFrame(p, vec3(1.8), 0.1);
    float boxDistance2 = sdBoxFrame(p, vec3(1.0), 0.1);
    
    float boxDistance = min(boxDistance1, boxDistance2);
    
    float planeDistanceBelow = sdPlane(p, vec3(0.0, 1.0, 0.0), 1.8);
    float planeDistanceFar = sdPlane(p, vec3(0.0, 0.0, -1.0), 6.5);
    
    float planeDistance = min(planeDistanceFar, planeDistanceBelow);
    
    return min(min(boxDistance, min(sphereDistanceInside, sphereDistanceBounce)), planeDistance);
}

vec3 calcNormal( in vec3 p ) 
{
    const float eps = 0.0001; 
    const vec2 h = vec2(eps,0);
    return normalize( vec3(map(p+h.xyy) - map(p-h.xyy),
                           map(p+h.yxy) - map(p-h.yxy),
                           map(p+h.yyx) - map(p-h.yyx) ) );
}

float castRay(in vec3 ro, in vec3 rd)
{
    float limit = 50.0f;
    float t = 0.0f;
    for (int i = 0; i < 100; ++i)
    {
        // Ray march to the next step
        vec3 pos = ro + t*rd;
        
        float h = map(pos);
        
        if (h < 0.001f)
        {
            // Hit
            break;
        }
        if (t > limit)
        {
            // No hit
            break;
        }
                        
        // Accumulate the distance to the next point
        t += h;      
    }
    
    if (t > limit)
    {
        t = 0.0;
    }
    
    return t;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float aspect = iResolution.x / iResolution.y;
    float an = iTime/2.0;
    
    // Normalized pixel coordinates (from -1 to 1)
    vec2 uv = (fragCoord/iResolution.xy)*2.0f - 1.0f;
    //vec2 uv = (2.0f*fragCoord - iResolution.xy) / iResolution.y;
    uv.x *= aspect;
        
    // Camera
    float distance = 6.0;
    vec3 ro = vec3(cos(an)*distance, 2.0f, sin(an)*distance);
    //vec3 ro = vec3(0.0, .3f, -6.0);
    
    vec3 ta = vec3(0.0, 0.0, 0.0);
    
    // UVN
    vec3 n = normalize(ta - ro);
    vec3 u = normalize(cross(n, vec3(0.0, 1.0, 0.0)));
    vec3 v = normalize(cross(u, n));
        
    vec3 rd = normalize(uv.x*u + uv.y*v + 1.5*n);
              
    vec3 color = vec3(0.65f, 0.75f, 0.98f) - 0.97f*rd.y;
    
    float t = castRay(ro, rd);
    
    if (t > 0.0f)
    {
        vec3 pos = ro + t*rd;
        vec3 normal = calcNormal(pos);
        
        vec3 sunDir = normalize(vec3(0.0, 0.2, -1.0));
        float sunShadow = step(castRay(pos + normal*0.001, sunDir), 0.0);
        float sunDif = clamp(dot(normal, sunDir), 0.0, 1.0);
        float skyDif = clamp(0.5 + 0.5*dot(normal, vec3(0.0f, 1.0f, 0.0f)), 0.0f, 1.0f);
        
        color = sunDif * sunShadow * vec3(1.0, 0.5, 0.4);
        color += skyDif * 1.0*vec3(0.2, 0.2, 0.2);
    }
    
    // Gamma correction
    color = pow(color, vec3(0.4545));

    // Output to screen
    fragColor = vec4(color, 1.0);
}
