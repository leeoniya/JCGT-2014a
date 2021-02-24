// -----------------------------------------------------------------------------
// Copyright (c) 2013 Nicolas P. Rougier. All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 
// THIS SOFTWARE IS PROVIDED BY NICOLAS P. ROUGIER ''AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
// EVENT SHALL NICOLAS P. ROUGIER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 
// The views and conclusions contained in the software and documentation are
// those of the authors and should not be interpreted as representing official
// policies, either expressed or implied, of Nicolas P. Rougier.
// -----------------------------------------------------------------------------

// Uniforms
// ------------------------------------
uniform mat4      u_model, u_view, u_projection;
uniform sampler2D u_uniforms;
uniform vec3      u_uniforms_shape;

// Attributes
// ------------------------------------
attribute vec2 a_position;
attribute vec4 a_tangents;
attribute vec2 a_segment;
attribute vec2 a_angles;
attribute vec2 a_texcoord;
attribute float a_index;

// Varying
// ------------------------------------
varying vec4  v_color;
varying vec2  v_segment;
varying vec2  v_linecaps;
varying float v_length;
varying float v_linejoin;
varying float v_linewidth;
varying float v_antialias;
varying float v_closed;
void main()
{

    // ------------------------------------------------------- Get uniforms ---
    float rows = u_uniforms_shape.x;
    float cols = u_uniforms_shape.y;
    float count= u_uniforms_shape.z;
    float index = a_index;
    int index_x = int(mod(index, (floor(cols/(count/4.0))))) * int(count/4.0);
    int index_y = int(floor(index / (floor(cols/(count/4.0)))));
    float size_x = cols - 1.0;
    float size_y = rows - 1.0;
    float ty = 0.0; 
    if (size_y > 0.0)
        ty = float(index_y)/size_y;

    int i = index_x;
    vec4 _uniform;

    // Get fg_color(4)
    v_color = texture2D(u_uniforms, vec2(float(i++)/size_x,ty));

    // Get translate(2), scale(1), rotate(1)
    _uniform = texture2D(u_uniforms, vec2(float(i++)/size_x,ty));
    vec2  translate = _uniform.xy;
    float scale     = _uniform.z;
    float theta     = _uniform.w;

    // Get linewidth(1), antialias(1), linecaps(2)
    _uniform = texture2D(u_uniforms, vec2(float(i++)/size_x,ty));
    v_linewidth = _uniform.x;
    v_antialias = _uniform.y;

    bool closed = (v_closed > 0.0);

    // ------------------------------------------------------------------------


    // Attributes to varyings
    v_segment = a_segment * scale;

    // Thickness below 1 pixel are represented using a 1 pixel thickness
    // and a modified alpha
    v_color.a = min(v_linewidth, v_color.a);
    v_linewidth = max(v_linewidth, 1.0);


    // If color is fully transparent we just will discard the fragment anyway
    if( v_color.a <= 0.0 )
    {
        gl_Position = vec4(0.0,0.0,0.0,1.0);
        return;
    }

    // This is the actual half width of the line
    // float w = ceil(1.25*v_antialias+v_linewidth)/2.0;
    float w = v_linewidth/2.0;

    vec2 position = a_position*scale;
    vec2 t1 = normalize(a_tangents.xy);
    vec2 t2 = normalize(a_tangents.zw);
    float u = a_texcoord.x;
    float v = a_texcoord.y;
    vec2 o1 = vec2( +t1.y, -t1.x);
    vec2 o2 = vec2( +t2.y, -t2.x);


    // This is a join
    // ----------------------------------------------------------------
    if( t1 != t2 ) {
        float angle  = atan (t1.x*t2.y-t1.y*t2.x, t1.x*t2.x+t1.y*t2.y);
        vec2 t  = normalize(t1+t2);
        vec2 o  = vec2( + t.y, - t.x);
        position.xy += v * w * o / cos(angle/2.0);

    // This is a line start or end (t1 == t2)
    // ------------------------------------------------------------------------
    } else {
        position += v * w * o1;
        if( u == -1.0 ) {
            u = v_segment.x - w;
            position -=  w * t1;
        } else {
            u = v_segment.y + w;
            position +=  w * t2;
        }
    }

    // Rotation
    float c = cos(theta);
    float s = sin(theta);
    position.xy = vec2( c*position.x - s*position.y,
                        s*position.x + c*position.y );
    // Translation
    position += translate;

    gl_Position = (u_projection*(u_view*u_model))*vec4(position,0.0,1.0);
}
