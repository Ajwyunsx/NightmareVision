package android;

#if desktop
import backend.Discord.DiscordClient;
#end

import flash.text.TextField;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import lime.utils.Assets;

import flixel.FlxSubState;

import flash.text.TextField;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;

import haxe.Json;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;

import funkin.data.Controls;
import funkin.states.options.BaseOptionsMenu;
import funkin.states.options.Option;

import openfl.Lib;

using StringTools;

class HitboxSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Hitbox Settings';
		rpcTitle = 'Hitbox Settings Menu';
		
		var option:Option = new Option('Hitbox Opacity',
			'Changes opacity', 'hitboxalpha', 'float', 0.2);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);
		
		super();
	}
}
