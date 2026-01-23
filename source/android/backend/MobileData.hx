package android.backend;

import haxe.ds.Map;
import haxe.Json;
import haxe.io.Path;

import openfl.utils.Assets;

import flixel.util.FlxSave;
import flixel.FlxG;

import funkin.FunkinAssets;
import funkin.data.SaveCompat;

class MobileData
{
	public static var actionModes:Map<String, MobileButtonsData> = new Map();
	public static var dpadModes:Map<String, MobileButtonsData> = new Map();
	
	public static var mode(get, set):Int;
	public static var forcedMode:Null<Int>;
	public static var save:FlxSave;
	
	public static function init()
	{
		// 使用独立的 FlxSave 对象，避免依赖 FlxG.save 的初始化状态
		save = new FlxSave();
		save.bind('MobileControls', CoolUtil.getSavePath());
		
		readDirectory(Paths.getPreloadPath('moblie/DPadModes'), dpadModes);
		readDirectory(Paths.getPreloadPath('moblie/ActionModes'), actionModes);
		#if MODS_ALLOWED
		for (folder in directoriesWithFile(Paths.getPreloadPath(), 'moblie'))
		{
			readDirectory(Path.join([folder, 'DPadModes']), dpadModes);
			readDirectory(Path.join([folder, 'ActionModes']), actionModes);
		}
		#end
	}
	
	public static function setMobilePadCustom(mobilePad:FlxTouchPad):Void
	{
		if (save == null) return;
		
		if (save.data.buttons == null)
		{
			save.data.buttons = new Array();
			for (buttons in mobilePad)
				save.data.buttons.push(FlxPoint.get(buttons.x, buttons.y));
		}
		else
		{
			var tempCount:Int = 0;
			for (buttons in mobilePad)
			{
				save.data.buttons[tempCount] = FlxPoint.get(buttons.x, buttons.y);
				tempCount++;
			}
		}
		
		save.flush();
	}
	
	public static function getMobilePadCustom(mobilePad:FlxTouchPad):FlxTouchPad
	{
		if (save == null) return mobilePad;
		
		var tempCount:Int = 0;
		
		if (save.data.buttons == null) return mobilePad;
		
		for (buttons in mobilePad)
		{
			if (save.data.buttons[tempCount] != null)
			{
				buttons.x = save.data.buttons[tempCount].x;
				buttons.y = save.data.buttons[tempCount].y;
			}
			tempCount++;
		}
		
		return mobilePad;
	}
	
	static function readDirectory(folder:String, map:Dynamic)
	{
		folder = folder.contains(':') ? folder.split(':')[1] : folder;
		trace('MobileData.readDirectory called with folder: ' + folder);
		
		var files:Array<String> = [];
		files = FunkinAssets.readDirectory(folder);
		
		if (files.length == 0)
		{
			trace('FunkinAssets.readDirectory returned empty. Using hardcoded fallback.');
			var isDPad = folder.indexOf('DPadModes') != -1;
			files = isDPad ? [
				"CHART_EDITOR.json", "DIALOGUE_PORTRAIT.json", "DUO.json", "FULL.json", "LEFT_FULL.json",
				"LEFT_RIGHT.json", "MENU_CHARACTER.json", "PAUSE.json", "RIGHT_FULL.json", "UP_DOWN.json", "UP_LEFT_RIGHT.json"
			] : [
				"A.json", "A_B.json", "A_B_C.json", "A_B_C_D_V_X_Y_Z.json", "A_B_C_X_Y_Z.json", "A_B_E.json", "A_B_E_C_M.json",
				"A_B_X_Y.json", "B.json", "B_C.json", "B_E.json", "B_X_Y.json", "CHARACTER_EDITOR.json", "CHART_EDITOR.json",
				"CHART_EDITOR_NEW.json", "DIALOGUE_PORTRAIT.json", "E.json", "MENU_CHARACTER.json", "OptionsC.json", "P.json",
				"SELECTOR_0.6.3.json", "SELECTOR_1.0.json", "SELECTOR_EXTENDED.json"
				];
		}
		
		trace('Files obtained: ' + files);
		
		for (file in files)
		{
			var fileWithNoLib:String = file.contains(':') ? file.split(':')[1] : file;
			if (Path.extension(fileWithNoLib) == 'json')
			{
				file = Path.join([folder, Path.withoutDirectory(file)]);
				var str:String = null;
				
				if (FunkinAssets.exists(file))
				{
					try
					{
						str = FunkinAssets.getContent(file);
					}
					catch (e:Dynamic)
					{
						trace('Error reading file: ' + file + ' - ' + e);
						continue;
					}
				}
				else
				{
					trace('File does not exist: ' + file);
					continue;
				}
				
				if (str != null && str.length > 0)
				{
					var json:MobileButtonsData = cast Json.parse(str);
					var mapKey:String = Path.withoutDirectory(Path.withoutExtension(fileWithNoLib));
					map.set(mapKey, json);
				}
			}
		}
	}
	
	static function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true)
	{
		var foldersToCheck:Array<String> = [];
		#if sys
		if (FileSystem.exists(path + fileToFind))
		#end
		foldersToCheck.push(path + fileToFind);
		
		#if MODS_ALLOWED
		if (mods)
		{
			// Global mods first
			for (mod in Paths.getGlobalMods())
			{
				var folder:String = Paths.mods(mod + '/' + fileToFind);
				if (FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
			}
			
			// Then "PsychEngine/mods/" main folder
			var folder:String = Paths.mods(fileToFind);
			if (FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(Paths.mods(fileToFind));
			
			// And lastly, the loaded mod's folder
			if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			{
				var folder:String = Paths.mods(Paths.currentModDirectory + '/' + fileToFind);
				if (FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
			}
		}
		#end
		return foldersToCheck;
	}
	
	static function set_mode(mode:Int = 3)
	{
		if (save != null)
		{
			save.data.mobileControlsMode = mode;
			save.flush();
		}
		return mode;
	}
	
	static function get_mode():Int
	{
		if (forcedMode != null) return forcedMode;
		
		if (save == null) return 3;
		
		if (save.data.mobileControlsMode == null)
		{
			save.data.mobileControlsMode = 3;
			save.flush();
		}
		
		return save.data.mobileControlsMode;
	}
}

typedef MobileButtonsData =
{
	buttons:Array<ButtonsData>
}

typedef ButtonsData =
{
	button:String, // what MobileButton should be used, must be a valid MobileButton var from MobilePad as a string.
	graphic:String, // the graphic of the button, usually can be located in the MobilePad xml .
	x:Float, // the button's X position on screen.
	y:Float, // the button's Y position on screen.
	color:String, // the button color, default color is white.
	bg:String // the button background for TouchPad, default background is `bg`.
}
