package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import shaders.RGBPalette;

/**
 * Compatibility-focused StrumNote implementation.
 *
 * This keeps the fields and methods that the rest of the project expects
 * while avoiding the constructor/type crashes that showed up with extra-key
 * editor lanes.
 */
class StrumNote extends FlxSprite
{
	// Kept dynamic on purpose:
	// the project uses RGB shader helpers in different ways across states.
	public var rgbShader:Dynamic = null;

	public var resetAnim:Float = 0;
	public var noteData:Int = 0;
	public var direction:Float = 0;

	public var downScroll:Bool = false;
	public var mustPress:Bool = false;
	public var player:Int = 0;

	public var useRGBShader:Bool = false;
	public var sustainReduce:Bool = true;

	// Used by options/editor code.
	public var texture:String = "noteSkins/square";

	// Basic layout helpers.
	public var baseX:Float = 0;
	public var baseY:Float = 0;
	public var laneSpacing:Float = 112;

	public function new(x:Float = 0, y:Float = 0, noteData:Int = 0, player:Int = 0)
	{
		super(x, y);

		this.noteData = noteData;
		this.player = player;
		this.ID = noteData;

		antialiasing = ClientPrefs.data.antialiasing;
		scrollFactor.set();
		solid = false;

		// Keep the shader setup soft-failing so constructor code never hard-crashes.
		try
		{
			rgbShader = cast new RGBPalette();
			shader = cast rgbShader;
			useRGBShader = true;
		}
		catch(e:Dynamic)
		{
			rgbShader = null;
			useRGBShader = false;
			shader = null;
		}

		reloadNote();
		playerPosition();
		playAnim("static", true);
	}

	inline function laneName(index:Int):String
	{
		switch (FlxMath.wrap(index, 0, 3))
		{
			case 0: return "left";
			case 1: return "down";
			case 2: return "up";
			default: return "right";
		}
	}

	inline function safeMakeFallback():Void
	{
		try
		{
			makeGraphic(64, 64, FlxColor.WHITE);
		}
		catch(e:Dynamic)
		{
			// Ignore graphics failures; the object still exists.
		}
	}

	public function reloadNote():Void
	{
		var loaded:Bool = false;

		try
		{
			var atlas:Dynamic = Paths.getSparrowAtlas(texture);
			if(atlas != null)
			{
				frames = atlas;
				loaded = true;
			}
		}
		catch(e:Dynamic)
		{
			loaded = false;
		}

		if(!loaded)
			safeMakeFallback();

		setupAnimations();
	}

	function setupAnimations():Void
	{
		if(animation == null)
			return;

		try
		{
			animation.destroyAnimations();

			var lane:String = laneName(noteData);
			animation.addByPrefix("static", "arrow" + lane.toUpperCase(), 24, false);
			animation.addByPrefix("pressed", lane + " press", 24, false);
			animation.addByPrefix("confirm", lane + " confirm", 24, false);
		}
		catch(e:Dynamic)
		{
			// Leave the fallback graphic in place.
		}
	}

	public function playAnim(name:String, ?force:Bool = false):Void
	{
		if(animation != null)
		{
			try
			{
				if(animation.getByName(name) != null)
					animation.play(name, force);
			}
			catch(e:Dynamic)
			{
			}
		}

		if(name == "static")
		{
			resetAnim = 0;
			angle = 0;
		}
	}

	public function changeNoteData(data:Int):Void
	{
		noteData = data;
		ID = data;
		setupAnimations();
	}

	/**
	 * Repositions the receptor for the current side/lane.
	 * This is intentionally simple and safe, because the editor may call it
	 * before all assets or note skins are fully loaded.
	 */
	public function playerPosition():Void
	{
		var sideOffset:Float = mustPress ? 0 : FlxG.width * 0.5;
		var playerOffset:Float = (player > 0) ? FlxG.width * 0.5 : 0;

		baseX = sideOffset + playerOffset;
		baseY = downScroll ? (FlxG.height - 150) : 50;

		x = baseX + (noteData * laneSpacing);
		y = baseY;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if(resetAnim > 0)
		{
			resetAnim -= elapsed;
			if(resetAnim <= 0)
				playAnim("static", true);
		}
	}
}
