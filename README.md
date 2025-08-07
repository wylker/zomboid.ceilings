# Ceilings Mod for Project Zomboid B42

Build ceilings at the z+1 level above your character! This mod integrates with Project Zomboid's new B42 building system to enable ceiling construction with support constraints.

## Features

- **Ceiling Construction**: Build ceilings one level above your current position
- **Realistic Validation**: Ceilings require proper structural support (walls or adjacent floors)
- **Visual Feedback**: Ghost preview shows where ceilings can be built along with ground ghost for reduced eyeball damage
- **Extensible System**: Easy for modders to add their own ceiling pieces
- **Stands Alone**: Comes out-of-the-box with a metal and a wooden ceiling entity

## How It Works

The mod uses a multi-hook approach to intercept and modify the building system:

### 1. Entity Detection (`ISBuildPanelClientHook.lua`)
- Detects ceiling entities by checking for `ceiling` tag in recipes
- Flags detected entities with `isCeilingBuild = true`
- Stores z-level information for other hooks
- Detected entities are run through custom rendering for building ghost + guide sprite

### 2. Building Action (`ISBuildActionClientHook.lua`)
- Intercepts build commands for ceiling entities
- Redirects construction to z+1 level
- Ensures ceiling is built at correct elevation

### 3. Server Validation (`BuildCeilingServer.lua`)
- Validates ceiling placement with structural requirements
- Checks for proper support (walls or adjacent floors)
- Handles ceiling creation and integration

## Current Status

**Working Features:**
- Ceiling detection via recipe tags
- Building at z+1 level
- Correct validation logic with structural requirements
- Ghosts have mirrored validation state

**Known Limitations:**
- Ceilings built will sometimes not render correctly (appear/disappear) from the player perspective without leaving the area or re-loading the save.

## Validation Rules

Ceilings can be built when:
1. **Adjacent ceiling floor exists** - in any direction at the same level
2. **Wall directly below** - any wall (WallN or WallW) at ground level (z-1)
3. **West-facing wall support** - WallW at x+1,z-1 reaches west to provide support
4. **North-facing wall support** - WallN at y+1,z-1 reaches north to provide support

## For Modders: Adding Your Own Ceiling Pieces

To make your building pieces work with the ceiling system, add these components to your entity scripts:

### 1. Add Ceiling Tag to CraftRecipe
```
component CraftRecipe
{
    tags = ceiling,  // <- This tag enables ceiling detection
    // ... rest of your recipe
}
```

### 2. Add Validation and Creation Hooks to SpriteConfig
```
component SpriteConfig
{
    OnIsValid = BuildRecipeCode.ceiling.OnIsValid,  // <- Ceiling validation
    OnCreate  = BuildRecipeCode.ceiling.OnCreate,   // <- Ceiling creation
    // ... rest of your sprite config
}
```

### Complete Example

Here's a complete entity script for a custom ceiling:

```
module Base
{
    entity MyCustomCeiling
    {
        component SpriteConfig
        {
            isThumpable     = false,
            OnIsValid       = BuildRecipeCode.ceiling.OnIsValid,
            OnCreate        = BuildRecipeCode.ceiling.OnCreate,
            
            face W
            {
                layer
                {
                    row = your_sprite_here,
                }
            }
        }
        
        component CraftRecipe
        {
            tags            = ceiling,  // <- Essential for detection!
            time            = 150,
            category        = Ceilings,
            SkillRequired   = Woodwork:3,
            xpAward         = Woodwork:30,
            inputs
            {
                // Your required materials
            }
        }
    }
}
```

That's it! Your ceiling piece will automatically:
- Be detected by the mod
- Build at z+1 level
- Use proper validation rules
- Show correct ghost preview

## Technical Details

### Hook Priority
The mod uses a careful hook sequence:
1. `ISBuildPanel` detects ceiling entities first
2. `ISBuildAction` handles actual building when clicked
3. Server validation runs when needed

### Compatibility
- Works with any entity using the ceiling tag system
- Doesn't interfere with vanilla building
- Compatible with other building mods

## Support

For issues or questions:
- Check console logs if ceiling detection isn't working
- Ensure your entities have the correct `tags = ceiling` property
- Post a new issue here

## Version History

- **v1.10**: Fixed ghost sprite to mirror IsValid status of build sprite - thanks Alex for pointing me in the right direction
- **v1.00**: Initial release with working ceiling system
- Full z+1 building support
- Extensible tag-based detection

## To-Do
- Sync vanilla floor "ghost" with ceiling "ghost" for OnValid checks
