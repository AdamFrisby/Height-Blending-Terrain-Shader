# Height-Blending-Terrain-Shader
A simple height blending terrain shader for Unity3D. This shader still compiles to SM3 (unlike most more sophisticated height shaders).

![alt text](https://raw.githubusercontent.com/AdamFrisby/Height-Blending-Terrain-Shader/master/Terrain-Heightblend-Shader.jpg)

This shader built for the Sine Space virtual world - but you can use it too. 
If you're interested in building content in a shared MMO environment usung Unity, check us out at http://developer.space

## To Use:
Add a height channel to your terrain textures, stored in the 'Alpha'. Terrain will be blended according to the normal blend, multiplied by these alpha values, producing better more crisp surface transitions - especially on grass and sand textures.

Feel free to tear apart, the main modifications from the Unity default 'Standard Terrain' shader are in SplatmapMix() declared in TerrainSplatmapCommon.cginc
