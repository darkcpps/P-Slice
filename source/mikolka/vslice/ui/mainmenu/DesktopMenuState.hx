package mikolka.vslice.ui.mainmenu;

import mikolka.vslice.freeplay.FreeplayState;
import options.OptionsState;
import flixel.FlxBasic;
import flixel.effects.FlxFlicker;
import mikolka.vslice.ui.title.TitleState;
#if !LEGACY_PSYCH
#if MODS_ALLOWED
import states.ModsMenuState;
#end
import states.AchievementsMenuState;
import states.CreditsState;
import states.editors.MasterEditorMenu;
#else
import editors.MasterEditorMenu;
#end
import mikolka.compatibility.VsliceOptions;
import flixel.FlxObject;

@:access(mikolka.vslice.ui.MainMenuState)
class DesktopMenuState extends FlxBasic
{
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		#if !switch 'donate', #end
		'options'
	];

	public static var curSelected:Int = 0;
	public static var windowScaled:Bool = false;

	var selectedSomethin:Bool = false;
	var menuItems:FlxTypedGroup<FlxSprite>;
	var camFollow:FlxObject;
	var animTimer:Float = 0;

	var host:MainMenuState;

	public function new(host:MainMenuState)
	{
		super();
		this.host = host;
		host.add(this);

		#if desktop
		if (!windowScaled)
		{
			windowScaled = true;
			var screenWidth = openfl.Lib.current.stage.window.display.currentMode.width;
			var screenHeight = openfl.Lib.current.stage.window.display.currentMode.height;

			var startW = openfl.Lib.current.stage.window.width;
			var startH = openfl.Lib.current.stage.window.height;
			var targetW = Main.game.width;
			var targetH = Main.game.height;

			// Smoothly scale from 1x1 to default resolution
			flixel.tweens.FlxTween.num(0, 1, 1.2, {ease: flixel.tweens.FlxEase.elasticOut}, function(v:Float)
			{
				var newWidth = Std.int(startW + (targetW - startW) * v);
				var newHeight = Std.int(startH + (targetH - startH) * v);

				if (newWidth > 0 && newHeight > 0)
				{
					openfl.Lib.current.stage.window.width = newWidth;
					openfl.Lib.current.stage.window.height = newHeight;
					openfl.Lib.current.stage.window.x = Std.int((screenWidth - newWidth) / 2);
					openfl.Lib.current.stage.window.y = Std.int((screenHeight - newHeight) / 2);
				}
			});
		}
		#end

		// Cool background settings
		host.bg.scrollFactor.set(0, 0.17);
		host.bg.updateHitbox();
		host.bg.screenCenter();

		host.magenta.scrollFactor.set(0, 0.17);
		host.magenta.updateHitbox();
		host.magenta.screenCenter();

		camFollow = new FlxObject(0, 0, 1, 1);
		host.add(camFollow);

		menuItems = new FlxTypedGroup<FlxSprite>();
		host.add(menuItems);

		// Layout settings
		var startY:Float = 100;
		var spacingY:Float = 160; // Good spacing for vertical list

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite = new FlxSprite(0, 0);
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.antialiasing = VsliceOptions.ANTIALIASING;

			// Center and position
			menuItem.updateHitbox();
			menuItem.screenCenter(X);
			menuItem.y = startY + (i * spacingY);
			menuItem.scrollFactor.set(0, 1); // Allow vertical scrolling

			menuItems.add(menuItem);

			// Smooth entry animation
			var startX:Float = menuItem.x;
			menuItem.x = (i % 2 == 0) ? -1000 : FlxG.width + 1000;
			menuItem.alpha = 0;

			FlxTween.tween(menuItem, {x: startX, alpha: 1}, 0.6, {
				ease: FlxEase.expoOut,
				startDelay: i * 0.1
			});
		}

		FlxG.camera.follow(camFollow, null, 0.15);
		changeItem();
	}

	override function update(elapsed:Float)
	{
		animTimer += elapsed;

		// Update menu items position and effects
		for (i in 0...menuItems.members.length)
		{
			var item = menuItems.members[i];

			if (i == curSelected)
			{
				// Selected: Pulse and Center
				var pulse:Float = 1.0 + Math.sin(animTimer * 4) * 0.05;
				item.scale.set(pulse, pulse);
				item.screenCenter(X);
			}
			else
			{
				// Non-selected: Smaller and slightly bobbing
				item.scale.set(0.8, 0.8);

				// Idle float effect
				var targetY:Float = (100 + (i * 160)) + Math.sin(animTimer * 2 + i) * 5;
				item.y = FlxMath.lerp(item.y, targetY, elapsed * 6);
				item.screenCenter(X);
			}
		}

		if (!selectedSomethin)
		{
			// Keyboard Navigation
			if (host.controls.UI_UP_P)
				changeItem(-1);

			if (host.controls.UI_DOWN_P)
				changeItem(1);

			if (host.controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (host.controls.ACCEPT)
			{
				selectItem();
			}

			// Debug key
			if (#if LEGACY_PSYCH FlxG.keys.anyJustPressed(ClientPrefs.keyBinds.get('debug_1')
				.filter(s -> s != -1)) #else host.controls.justPressed('debug_1') #end)
			{
				selectedSomethin = true;
				FlxTransitionableState.skipNextTransIn = false;
				FlxTransitionableState.skipNextTransOut = false;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
		}

		// Subtle background color shift
		if (host.bg != null)
		{
			var hue:Float = (animTimer * 10) % 360;
			host.bg.color = FlxColor.fromHSB(hue, 0.2, 1.0);
		}

		super.update(elapsed);
	}

	function selectItem()
	{
		if (selectedSomethin)
			return; // Prevent double selection

		FlxG.sound.play(Paths.sound('confirmMenu'));
		FlxTransitionableState.skipNextTransIn = false;
		FlxTransitionableState.skipNextTransOut = false;

		if (optionShit[curSelected] == 'donate')
		{
			CoolUtil.browserLoad('https://needlejuicerecords.com/pages/friday-night-funkin');
		}
		else
		{
			selectedSomethin = true;

			if (VsliceOptions.FLASHBANG)
				FlxFlicker.flicker(host.magenta, 1.1, 0.15, false);

			// Screen shake
			FlxG.camera.shake(0.003, 0.15);

			FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, false, false, function(flick:FlxFlicker)
			{
				switch (optionShit[curSelected])
				{
					case 'story_mode':
						MusicBeatState.switchState(new StoryMenuState());
					case 'freeplay':
						{
							host.persistentDraw = true;
							host.persistentUpdate = false;
							FlxTransitionableState.skipNextTransIn = true;
							FlxTransitionableState.skipNextTransOut = true;

							host.openSubState(new FreeplayState());
							host.subStateOpened.addOnce(state ->
							{
								for (i in 0...menuItems.members.length)
								{
									menuItems.members[i].revive();
									menuItems.members[i].alpha = 1;
									menuItems.members[i].visible = true;
									selectedSomethin = false;
								}
								changeItem(0, true);
							});
						}

					#if MODS_ALLOWED
					case 'mods':
						MusicBeatState.switchState(new ModsMenuState());
					#end

					#if ACHIEVEMENTS_ALLOWED
					case 'awards':
						MusicBeatState.switchState(new AchievementsMenuState());
					#end

					case 'credits':
						MusicBeatState.switchState(new CreditsState());
					case 'options':
						host.goToOptions();
				}
			});

			// Scatter non-selected items away
			for (i in 0...menuItems.members.length)
			{
				if (i == curSelected)
					continue;

				// Tween to sides
				var targetX:Float = (i % 2 == 0) ? -500 : FlxG.width + 500;
				FlxTween.tween(menuItems.members[i], {alpha: 0, x: targetX}, 0.4, {
					ease: FlxEase.backIn,
					onComplete: function(twn:FlxTween)
					{
						menuItems.members[i].kill();
					}
				});
			}
		}
	}

	function changeItem(huh:Int = 0, silent:Bool = false)
	{
		if (huh != 0 && !silent)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		menuItems.members[curSelected].animation.play('idle');

		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.members[curSelected].animation.play('selected');
		menuItems.members[curSelected].centerOffsets();

		// Camera tracking
		var targetY:Float = menuItems.members[curSelected].getGraphicMidpoint().y;
		camFollow.setPosition(FlxG.width / 2, targetY);
	}
}
