Adding new entities that can utilize this ceiling building method is easy, simply set your SpriteConfig as follows:

			type            = Ceiling,
            isThumpable     = false,
            OnIsValid       = BuildRecipeCode.ceiling.OnIsValid,
			OnCreate        = BuildRecipeCode.ceiling.OnCreate,
			
			...rest of config...
			
			
