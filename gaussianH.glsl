
number blurSize = 1.0/512.0;
vec4 effect(vec4 color, Image texture, vec2 vTexCoord, vec2 pixel_coords)
{
	vec4 sum = vec4(0.0);
	// blur in x (horizontal
	// take nine samples, with the distance blurSize between them
	sum += texture2D(texture, vec2(vTexCoord.x - 4.0*blurSize, vTexCoord.y)) * 0.05;
	sum += texture2D(texture, vec2(vTexCoord.x - 3.0*blurSize, vTexCoord.y)) * 0.09;
	sum += texture2D(texture, vec2(vTexCoord.x - 2.0*blurSize, vTexCoord.y)) * 0.12;
	sum += texture2D(texture, vec2(vTexCoord.x - blurSize, vTexCoord.y)) * 0.15;
	sum += texture2D(texture, vec2(vTexCoord.x, vTexCoord.y)) * 0.16;
	sum += texture2D(texture, vec2(vTexCoord.x + blurSize, vTexCoord.y)) * 0.15;
	sum += texture2D(texture, vec2(vTexCoord.x + 2.0*blurSize, vTexCoord.y)) * 0.12;
	sum += texture2D(texture, vec2(vTexCoord.x + 3.0*blurSize, vTexCoord.y)) * 0.09;
	sum += texture2D(texture, vec2(vTexCoord.x + 4.0*blurSize, vTexCoord.y)) * 0.05;
	
	return sum;
}
