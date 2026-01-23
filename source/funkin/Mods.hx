package funkin;

import grig.audio.SampleRate;

import openfl.utils.Assets;

import lime.graphics.Image;

import haxe.Json;

import funkin.states.transitions.*;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

// modified from modern psych
// much love okay

typedef ModMeta =
{
	var name:String;
	var global:Bool;
	var description:String;
	
	var ?discordClientID:String;
	var ?windowTitle:String;
	var ?iconFile:String;
	
	var ?defaultTransition:String;
	var ?stateRedirects:RedirectableStates;
	
	// make sure to include .ttf or .otf!!!!
	var ?defaultFont:String;
}

typedef RedirectableStates =
{
	var ?TitleState:String;
	var ?MainMenuState:String;
	var ?StoryMenuState:String;
	var ?FreeplayState:String;
	var ?CreditsState:String;
	var ?OptionsState:String;
}

typedef ModsList =
{
	enabled:Array<String>,
	disabled:Array<String>,
	all:Array<String>
}

class Mods
{
	/**
	 * The current primary loaded mod
	 */
	public static var currentModDirectory:Null<String> = '';
	
	public static var currentMod:Null<ModMeta> = null;
	
	public static final ignoreModFolders:Array<String> = [
		'characters',
		'events',
		'notetypes',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'noteskins',
	];
	
	/**
	 * Known asset mod folders that should always be checked.
	 * These are embedded mod-like folders in assets/game/ or assets/embeds/.
	 */
	public static final knownAssetMods:Array<String> = [
		'crossed_out',
	];
	
	/**
	 * makes `modsList.txt` in the case it doesnt exist
	 */
	static function ensureModsListExists()
	{
		#if sys
		if (!FileSystem.exists('modsList.txt'))
		{
			File.saveContent('modsList.txt', '');
		}
		#end
	}
	
	public static var globalMods:Array<String> = [];
	
	/**
	 * Refreshes all globally loaded mods
	 */
	public static inline function pushGlobalMods():Array<String>
	{
		globalMods = [];
		for (mod in parseList().enabled)
		{
			var pack = getPack(mod);
			if (pack != null && pack.global) globalMods.push(mod);
		}
		
		return globalMods;
	}
	
	public static inline function getModDirectories():Array<String>
	{
		var list:Array<String> = [];
		var modsFolder:String = Paths.mods();
		#if MODS_ALLOWED
		if (FileSystem.exists(modsFolder))
		{
			for (folder in FileSystem.readDirectory(modsFolder))
			{
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (FileSystem.isDirectory(path)
					&& !ignoreModFolders.contains(folder.toLowerCase())
					&& !list.contains(folder)) list.push(folder);
			}
		}
		#else
		if (FunkinAssets.exists(modsFolder))
		{
			for (folder in FunkinAssets.readDirectory(modsFolder))
			{
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (FunkinAssets.isDirectory(path)
					&& !ignoreModFolders.contains(folder.toLowerCase())
					&& !list.contains(folder)) list.push(folder);
			}
		}
		#end
		return list;
	}
	
	public static inline function mergeAllTextsNamed(path:String, ?defaultDirectory:String = null, allowDuplicates:Bool = false)
	{
		if (defaultDirectory == null) defaultDirectory = Paths.getCorePath();
		defaultDirectory = defaultDirectory.trim();
		if (!defaultDirectory.endsWith('/')) defaultDirectory += '/';
		if (!defaultDirectory.startsWith('assets/')) defaultDirectory = 'assets/$defaultDirectory';
		
		var mergedList:Array<String> = [];
		var paths:Array<String> = directoriesWithFile(defaultDirectory, path);
		
		var defaultPath:String = defaultDirectory + path;
		if (paths.contains(defaultPath))
		{
			paths.remove(defaultPath);
			paths.insert(0, defaultPath);
		}
		
		for (file in paths)
		{
			var list:Array<String> = CoolUtil.coolTextFile(file);
			for (value in list)
				if ((allowDuplicates || !mergedList.contains(value)) && value.length > 0) mergedList.push(value);
		}
		return mergedList;
	}
	
	public static inline function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true)
	{
		var foldersToCheck:Array<String> = [];
		if (FunkinAssets.exists(path + fileToFind)) foldersToCheck.push(path + fileToFind);
		
		if (mods)
		{
			// Global mods first
			for (mod in globalMods)
			{
				var folder:String = Paths.mods(mod + '/' + fileToFind);
				#if MODS_ALLOWED
				if (FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
				#else
				if (FunkinAssets.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
				#end
			}
			
			// Main mods folder
			var folder:String = Paths.mods(fileToFind);
			#if MODS_ALLOWED
			if (FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
			#else
			if (FunkinAssets.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
			#end
			
			// Current mod folder
			if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			{
				var folder:String = Paths.mods(Mods.currentModDirectory + '/' + fileToFind);
				#if MODS_ALLOWED
				if (FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
				#else
				if (FunkinAssets.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
				#end
			}
		}
		return foldersToCheck;
	}
	
	public static function getPack(?folder:String):ModMeta
	{
		if (folder == null) folder = Mods.currentModDirectory;
		
		var path = Paths.mods(folder + '/meta.json');
		#if MODS_ALLOWED
		if (FileSystem.exists(path))
		{
			try
			{
				final json = FunkinAssets.getContent(path);
				if (json != null && json.length > 0) return Json.parse(json);
			}
			catch (e) {}
		}
		#else
		if (FunkinAssets.exists(path))
		{
			try
			{
				final json = FunkinAssets.getContent(path);
				if (json != null && json.length > 0) return Json.parse(json);
			}
			catch (e) {}
		}
		#end
		return null;
	}
	
	public static inline function parseList():ModsList
	{
		updateModList();
		var list:ModsList = {enabled: [], disabled: [], all: []};
		
		#if sys
		if (FileSystem.exists('modsList.txt'))
		{
			for (mod in CoolUtil.coolTextFile('modsList.txt'))
			{
				if (mod.trim().length < 1) continue;
				
				var dat = mod.split("|");
				list.all.push(dat[0]);
				if (dat[1] == "1") list.enabled.push(dat[0]);
				else list.disabled.push(dat[0]);
			}
		}
		#end
		return list;
	}
	
	public static function getListAsArray(?top:String = ''):Array<{folder:String, enabled:Bool}>
	{
		var list:Array<{folder:String, enabled:Bool}> = [];
		var added:Array<String> = [];
		if (top == null || top == '') top = currentModDirectory;
		
		if (top.length >= 1)
		{
			#if MODS_ALLOWED
			if (FileSystem.exists(Paths.mods(top)) && FileSystem.isDirectory(Paths.mods(top)) && !added.contains(top))
			#else
			if (FunkinAssets.exists(Paths.mods(top)) && FunkinAssets.isDirectory(Paths.mods(top)) && !added.contains(top))
			#end
			{
				added.push(top);
				list.push({folder: top, enabled: true});
			}
		}
		
		#if sys
		if (FileSystem.exists('modsList.txt'))
		{
			for (mod in CoolUtil.coolTextFile('modsList.txt'))
			{
				var dat:Array<String> = mod.split("|");
				var folder:String = dat[0];
				
				#if MODS_ALLOWED
				var exists = FileSystem.exists(Paths.mods(folder)) && FileSystem.isDirectory(Paths.mods(folder));
				#else
				var exists = FunkinAssets.exists(Paths.mods(folder)) && FunkinAssets.isDirectory(Paths.mods(folder));
				#end
				
				if (folder.trim().length > 0 && exists && !added.contains(folder) && folder != top)
				{
					added.push(folder);
					list.push({folder: folder, enabled: (dat[1] == "1")});
				}
			}
		}
		#end
		
		// Scan for folders that aren't on modsList.txt yet
		for (folder in getModDirectories())
		{
			#if MODS_ALLOWED
			var exists = FileSystem.exists(Paths.mods(folder)) && FileSystem.isDirectory(Paths.mods(folder));
			#else
			var exists = FunkinAssets.exists(Paths.mods(folder)) && FunkinAssets.isDirectory(Paths.mods(folder));
			#end
			
			if (folder.trim().length > 0 && exists && !ignoreModFolders.contains(folder.toLowerCase()) && !added.contains(folder) && folder != top)
			{
				added.push(folder);
				list.push({folder: folder, enabled: true});
			}
		}
		
		return list;
	}
	
	public static function updateModList(top:String = '')
	{
		#if sys
		ensureModsListExists();
		// Find all that are already ordered
		var list = getListAsArray();
		
		var fileStr:String = '';
		for (values in list)
		{
			if (fileStr.length > 0) fileStr += '\n';
			fileStr += values.folder + '|' + (values.enabled ? '1' : '0');
		}
		File.saveContent('modsList.txt', fileStr);
		#end
	}
	
	public static function loadTopMod()
	{
		currentModDirectory = '';
		var list:Array<String> = Mods.parseList().enabled;
		if (list != null && list[0] != null) Mods.currentModDirectory = list[0];
		currentMod = loadTopModConfig();
	}
	
	public static function loadTopModConfig():Null<ModMeta>
	{
		var pack = getPack();
		if (pack == null) return null;
		
		funkin.utils.WindowUtil.setTitle(pack.windowTitle ?? 'Friday Night Funkin');
		
		inline function resetIcon()
		{
			final path = Paths.getPath('images/branding/icon/icon64.png', null, true);
			FlxG.stage.window.setIcon(Image.fromBytes(FunkinAssets.getBytes(path)));
		}
		
		if (pack.iconFile != null)
		{
			final path = Paths.getPath('images/${pack.iconFile}.png', null, true);
			if (FunkinAssets.exists(path)) FlxG.stage.window.setIcon(Image.fromBytes(FunkinAssets.getBytes(path)));
			else
			{
				resetIcon();
				Logger.log('Could not find Icon ${pack.iconFile}', ERROR);
			}
		}
		else resetIcon();
		
		if (pack.defaultTransition != null)
		{
			switch (pack.defaultTransition)
			{
				case 'base', 'swipe':
					final trans = SwipeTransition;
					MusicBeatState.transitionInState = trans;
					MusicBeatState.transitionOutState = trans;
				case 'fade':
					final trans = FadeTransition;
					MusicBeatState.transitionInState = trans;
					MusicBeatState.transitionOutState = trans;
				default:
					ScriptedTransition.setTransition(pack.defaultTransition);
			}
		}
		else
		{
			final trans = SwipeTransition;
			MusicBeatState.transitionInState = trans;
			MusicBeatState.transitionOutState = trans;
		}
		
		if (pack.discordClientID != null) funkin.api.DiscordClient.rpcId = pack.discordClientID;
		else funkin.api.DiscordClient.rpcId = DiscordClient.NMV_ID;
		
		if (pack.defaultFont != null)
		{
			if (FunkinAssets.exists(Paths.font(pack.defaultFont))) Paths.DEFAULT_FONT = Paths.font(pack.defaultFont);
			else
			{
				Paths.DEFAULT_FONT = Paths.font('vcr.ttf');
				Logger.log('Issue with loading ${Paths.font(pack.defaultFont)}, does it exist?', ERROR);
			}
		}
		else Paths.DEFAULT_FONT = Paths.font('vcr.ttf');
		
		return pack;
	}
	
	public static function isStateRedirected(nextState:flixel.FlxState):Bool
	{
		final stateName = Type.getClassName(Type.getClass(nextState)).split('.').pop();
		if (currentMod == null || currentMod.stateRedirects == null) return false;
		
		var retVal = false;
		switch (stateName)
		{
			case 'TitleState':
				retVal = currentMod.stateRedirects.TitleState != null;
			case 'MainMenuState':
				retVal = currentMod.stateRedirects.MainMenuState != null;
			case 'StoryMenuState':
				retVal = currentMod.stateRedirects.StoryMenuState != null;
			case 'FreeplayState':
				retVal = currentMod.stateRedirects.FreeplayState != null;
			case 'CreditsState':
				retVal = currentMod.stateRedirects.CreditsState != null;
			case 'OptionsState':
				retVal = currentMod.stateRedirects.OptionsState != null;
			case 'ScriptedState':
				retVal = false;
		}
		return retVal;
	}
	
	public static function getRedirect(nextState:flixel.FlxState):Null<String>
	{
		final stateName = Type.getClassName(Type.getClass(nextState)).split('.').pop();
		if (currentMod == null || currentMod.stateRedirects == null) return null;
		
		var retVal = null;
		switch (stateName)
		{
			case 'TitleState':
				retVal = currentMod.stateRedirects.TitleState;
			case 'MainMenuState':
				retVal = currentMod.stateRedirects.MainMenuState;
			case 'StoryMenuState':
				retVal = currentMod.stateRedirects.StoryMenuState;
			case 'FreeplayState':
				retVal = currentMod.stateRedirects.FreeplayState;
			case 'CreditsState':
				retVal = currentMod.stateRedirects.CreditsState;
			case 'OptionsState':
				retVal = currentMod.stateRedirects.OptionsState;
		}
		return retVal;
	}
	
	public static function getModIcon(?mod:String):String
	{
		if (mod == null || mod.length < 1) mod = currentModDirectory;
		var retVal = 'branding/icon/fallback';
		var pack = getPack(mod);
		if (pack != null && pack.iconFile != null) retVal = pack.iconFile;
		return retVal;
	}
	
	public static function getModName(?mod:String):String
	{
		if (mod == null || mod.length < 1) mod = currentModDirectory;
		var retVal = mod;
		var pack = getPack(mod);
		if (pack != null && pack.name != null) retVal = pack.name;
		return retVal;
	}
	
	public static function getModFont(?mod:String):String
	{
		if (mod == null || mod.length < 1) mod = currentModDirectory;
		var retVal = Paths.font('vcr.ttf');
		var pack = getPack(mod);
		if (pack != null && pack.defaultFont != null) retVal = Paths.font(pack.defaultFont);
		return retVal;
	}
}
