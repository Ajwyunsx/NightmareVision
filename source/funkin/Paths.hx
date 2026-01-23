package funkin;

import haxe.io.Path;
import haxe.Json;

import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import openfl.media.Sound;

import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;

#if sys
import sys.FileSystem;
#end

/**
 * Primary class used to simplify retrieving and finding assets.
 */
class Paths
{
	#if ASSET_REDIRECT
	public static inline final trail = #if macos '../../../../../../../' #else '../../../../' #end;
	#end
	
	/**
	 * Primary asset directory
	 */
	public static inline final CORE_DIRECTORY = #if ASSET_REDIRECT trail + 'assets/game' #else 'assets' #end;
	
	/**
	 * Mod directory
	 */
	public static inline final MODS_DIRECTORY = #if ASSET_REDIRECT trail + 'content' #elseif MODS_ALLOWED 'content' #else 'assets/mods' #end;
	
	/**
	 * Embedded assets directory (for Android compatibility)
	 */
	public static inline final EMBEDS_DIRECTORY = #if ASSET_REDIRECT trail + 'assets/embeds' #else 'assets' #end;
	
	/**
	 * Default font used by the game for most things.
	 * 
	 * Can be changed
	 */
	public static var DEFAULT_FONT:String = 'vcr.ttf';
	
	/**
	 * Current mod directory - aliased from Mods.currentModDirectory for convenience
	 */
	public static var currentModDirectory(get, set):Null<String>;
	
	static function get_currentModDirectory():Null<String>
	{
		return Mods.currentModDirectory;
	}
	
	static function set_currentModDirectory(value:Null<String>):Null<String>
	{
		return Mods.currentModDirectory = value;
	}
	
	@:allow(funkin.backend.FunkinCache)
	static var tempAtlasFramesCache:Map<String, FlxAtlasFrames> = []; // maybe instead of this make a txt cache ?
	
	/**
	 * Current asset mod directory (for embedded mod-like folders in assets/game/)
	 */
	public static var currentAssetMod:Null<String> = null;
	
	/**
	 * Primary function used for pathing. In order it will check:
	 * 1. Primary Mod Directory (content/)
	 * 2. Embedded asset mods (assets/game/crossed_out/ or assets/embeds/)
	 * 3. Embedded assets directory (assets/embeds/)
	 * 4. Core assets directory (assets/game/ or assets/)
	 *
	 * @param file The Path to the file. extension included.
	 * @param parentFolder Parent folder to the file
	 * @param checkMods If true, will search through Mod directories
	 * @return The path to the file.
	 */
	public static function getPath(file:String, ?parentFolder:String, checkMods:Bool = false):String
	{
		if (parentFolder != null) file = '$parentFolder/$file';
		
		if (checkMods)
		{
			final modPath:String = modFolders(file);
			
			#if MODS_ALLOWED
			if (FileSystem.exists(modPath)) return modPath;
			#else
			if (FunkinAssets.exists(modPath)) return modPath;
			#end
		}
		
		if (currentAssetMod != null && currentAssetMod.length > 0)
		{
			var actualModName = findAssetModWithCase(currentAssetMod);
			if (actualModName == null) actualModName = currentAssetMod;
			
			final assetModPath = getAssetModFilePath(actualModName, file);
			if (FunkinAssets.exists(assetModPath) || FunkinAssets.isDirectory(assetModPath)) return assetModPath;
		}
		
		#if ASSET_REDIRECT
		final embedPath = '$EMBEDS_DIRECTORY/$file';
		if (FunkinAssets.exists(embedPath) || FunkinAssets.isDirectory(embedPath)) return embedPath;
		#else
		for (assetMod in getAssetMods())
		{
			final assetModPath = '$CORE_DIRECTORY/$assetMod/$file';
			if (FunkinAssets.exists(assetModPath) || FunkinAssets.isDirectory(assetModPath)) return assetModPath;
		}
		#end
		
		return getCorePath(file);
	}
	
	/**
	 * Gets the file path within an asset mod (case-insensitive mod name)
	 * @param modName The asset mod name (e.g., "crossed_out")
	 * @param file The file path within the mod
	 * @return Full path to the file
	 */
	public static function getAssetModFilePath(modName:String, file:String):String
	{
		var actualName = findAssetModWithCase(modName);
		if (actualName != null) modName = actualName;
		
		#if ASSET_REDIRECT
		var embedsPath = '$EMBEDS_DIRECTORY/$modName/$file';
		if (FunkinAssets.exists(embedsPath)) return embedsPath;
		#end
		
		return '$CORE_DIRECTORY/$modName/$file';
	}
	
	/**
	 * Inserts the primary asset path to the given file path
	 */
	public static inline function getCorePath(file:String = ''):String
	{
		return '$CORE_DIRECTORY/$file';
	}
	
	/**
	 * Searches for a .txt file within the `data` directory.
	 */
	public static inline function txt(key:String, ?parentFolder:String, checkMods:Bool = true):String
	{
		return getPath('data/$key.txt', parentFolder, checkMods);
	}
	
	/**
	 * Searches for a .xml file within the `data` directory.
	 */
	public static inline function xml(key:String, ?parentFolder:String, checkMods:Bool = true):String
	{
		return getPath('data/$key.xml', parentFolder, checkMods);
	}
	
	/**
	 * Searches for a .json file within the `songs` directory.
	 */
	public static inline function json(key:String, ?parentFolder:String, checkMods:Bool = true):String
	{
		return getPath('songs/$key.json', parentFolder, checkMods);
	}
	
	public static inline function noteskin(key:String, ?parentFolder:String, checkMods:Bool = true):String
	{
		var path = getPath('data/noteskins/$key.json', parentFolder, checkMods);
		if (!FunkinAssets.exists(path, TEXT)) path = getPath('noteskins/$key.json', parentFolder, checkMods);
		
		return path;
	}
	
	/**
	 * Searches for a .frag file within the `shaders` directory.
	 */
	public static inline function fragment(key:String, checkMods:Bool = true):String
	{
		return getPath('shaders/$key.frag', null, checkMods);
	}
	
	/**
	 * Searches for a .vert file within the `shaders` directory.
	 */
	public static inline function vertex(key:String, checkMods:Bool = true):String
	{
		return getPath('shaders/$key.vert', null, checkMods);
	}
	
	/**
	 * Searches for a video file wihin the `videos` directory.
	 * 
	 * Automatically will attempt to append .mp4 and .mov extensions.
	 */
	public static function video(key:String, checkMods:Bool = true):String
	{
		return findFileWithExts('videos/$key', ['mp4', 'mov'], null, checkMods);
	}
	
	public static function textureAtlas(key:String, ?parentFolder:String, checkMods:Bool = true):String
	{
		return getPath('images/$key', parentFolder, checkMods);
	}
	
	/**
	 * Searches for a file within the `sounds` directory and caches a `Sound` instance.
	 * 
	 * Automatically will attempt to append .ogg and .wav extensions.
	 */
	public static function sound(key:String, ?parentFolder:String, checkMods:Bool = true):Sound
	{
		var file:String = findFileWithExts('sounds/$key', ['ogg', 'wav'], parentFolder, checkMods);
		if (FunkinAssets.exists(file, SOUND)) return FunkinAssets.getSound(file);
		
		file = findFileWithExts('sound/$key', ['ogg', 'wav'], parentFolder, checkMods);
		if (FunkinAssets.exists(file, SOUND)) return FunkinAssets.getSound(file);
		
		file = findFileWithExts(key, ['ogg', 'wav'], parentFolder, checkMods);
		if (FunkinAssets.exists(file, SOUND)) return FunkinAssets.getSound(file);
		
		return FunkinAssets.getSound(file);
	}
	
	public static inline function soundRandom(key:String, min:Int = 0, max:Int = 0, ?parentFolder:String, checkMods:Bool = true):Sound
	{
		return sound(key + FlxG.random.int(min, max), parentFolder, checkMods);
	}
	
	/**
	 * Searches for a file within the `music` directory and caches a `Sound` instance.
	 * 
	 * Automatically will attempt to append .ogg and .wav extensions.
	 */
	public static inline function music(key:String, ?parentFolder:String, checkMods:Bool = true):Sound
	{
		final key = findFileWithExts('music/$key', ['ogg', 'wav'], parentFolder, checkMods);
		
		return FunkinAssets.getSound(key);
	}
	
	public static inline function trackswap(song:String, ?postFix:String, checkMods:Bool = true):Null<Sound>
	{
		var name = sanitize(song);
		
		var songKey:String = '$name/Track';
		if (FunkinAssets.isDirectory(getPath('songs/$name/audio', null, checkMods))) songKey = '$name/audio/Voices';
		
		if (postFix != null) songKey += '-$postFix';
		
		songKey = findFileWithExts('songs/$songKey', ['ogg', 'wav'], null, checkMods);
		
		if (ClientPrefs.streamedMusic) return FunkinAssets.getVorbisSound(songKey);
		
		return FunkinAssets.getSoundUnsafe(songKey);
	}
	
	public static inline function voices(song:String, ?postFix:String, checkMods:Bool = true):Null<Sound>
	{
		var name = sanitize(song);
		
		var songKey:String = '$name/Voices';
		if (FunkinAssets.isDirectory(getPath('songs/$name/audio', null, checkMods))) songKey = '$name/audio/Voices';
		
		if (postFix != null) songKey += '-$postFix';
		
		songKey = findFileWithExts('songs/$songKey', ['ogg', 'wav'], null, checkMods);
		
		if (ClientPrefs.streamedMusic) return FunkinAssets.getVorbisSound(songKey);
		
		return FunkinAssets.getSoundUnsafe(songKey);
	}
	
	public static inline function inst(song:String, ?postFix:String, checkMods:Bool = true):Null<openfl.media.Sound>
	{
		var name = sanitize(song);
		
		var songKey:String = '$name/Inst';
		if (FunkinAssets.isDirectory(getPath('songs/$name/audio', null, checkMods))) songKey = '$name/audio/Inst';
		
		if (postFix != null) songKey += '-$postFix';
		
		songKey = findFileWithExts('songs/$songKey', ['ogg', 'wav'], null, checkMods);
		
		if (ClientPrefs.streamedMusic) return FunkinAssets.getVorbisSound(songKey) ?? FunkinAssets.getSound(songKey);
		
		return FunkinAssets.getSound(songKey);
	}
	
	/**
	 * Searches for a file within the `images` directory and caches a `FlxGraphic` instance.
	 */
	public static inline function image(key:String, ?parentFolder:String, allowGPU:Bool = true, checkMods:Bool = true):FlxGraphic
	{
		return FunkinAssets.getGraphic(getPath('images/$key.png', parentFolder, checkMods), true, allowGPU);
	}
	
	/**
	 * Searches for a font file wihin the `fonts` directory.
	 * 
	 * Automatically will attempt to append .ttf and .otf extensions.
	 */
	public static inline function font(key:String, checkMods:Bool = true):String
	{
		return findFileWithExts('fonts/$key', ['ttf', 'otf'], null, checkMods);
	}
	
	public static function findFileWithExts(key:String, exts:Array<String>, ?parentFolder:String, checkMods:Bool = true):String
	{
		for (ext in exts)
		{
			final joined = getPath('$key.$ext', parentFolder, checkMods);
			if (FunkinAssets.exists(joined)) return joined;
		}
		
		return getPath(key, parentFolder, checkMods); // assuming u mightve added a ext already
	}
	
	/**
	 * Attemps to get the text from a file. 
	 * 
	 * Will return a empty string if the file could not be found.
	 */
	public static function getTextFromFile(key:String, ?parentFolder:String, checkMods:Bool = true):String
	{
		key = getPath(key, parentFolder, checkMods);
		
		return FunkinAssets.exists(key) ? FunkinAssets.getContent(key) : '';
	}
	
	/**
	 * Convenience function to check if a file exists. handles getPath for you
	 */
	public static inline function fileExists(key:String, ?parentFolder:String, checkMods:Bool = true):Bool
	{
		return FunkinAssets.exists(getPath(key, parentFolder, checkMods));
	}
	
	public static inline function getMultiAtlas(keys:Array<String>, ?parentFolder:String, allowGPU:Bool = true, checkMods:Bool = true):FlxAtlasFrames // from psych
	{
		if (keys.length == 0) return null;
		
		final firstKey:Null<String> = keys.shift()?.trim();
		
		var frames = getAtlasFrames(firstKey, parentFolder, allowGPU, checkMods);
		
		if (keys.length != 0)
		{
			final originalCollection = frames;
			frames = new FlxAtlasFrames(originalCollection.parent);
			frames.addAtlas(originalCollection, true);
			for (i in keys)
			{
				final newFrames = getAtlasFrames(i.trim(), parentFolder, allowGPU, checkMods);
				if (newFrames != null)
				{
					frames.addAtlas(newFrames, false);
				}
			}
		}
		return frames;
	}
	
	/**
	 * Retrieves atlas frames from either `Sparrow` or `Packer` 
	 * 
	 * `Sparrow` has priority.
	 */
	public static inline function getAtlasFrames(key:String, ?parentFolder:String, allowGPU:Bool = true, checkMods:Bool = true):FlxAtlasFrames
	{
		final directPath = getPath('images/$key.png', parentFolder, checkMods).withoutExtension();
		
		final tempFrames = tempAtlasFramesCache.get(directPath);
		if (tempFrames != null)
		{
			return tempFrames;
		}
		
		final xmlPath = getPath('images/$key.xml', parentFolder, checkMods);
		final txtPath = getPath('images/$key.txt', parentFolder, checkMods);
		
		final graphic = image(key, parentFolder, allowGPU, checkMods);
		
		// sparrow
		if (FunkinAssets.exists(xmlPath))
		{
			// until flixel does null safety
			@:nullSafety(Off)
			{
				final frames = FlxAtlasFrames.fromSparrow(graphic, FunkinAssets.exists(xmlPath) ? FunkinAssets.getContent(xmlPath) : null);
				if (frames != null) tempAtlasFramesCache.set(directPath, frames);
				return frames;
			}
		}
		
		@:nullSafety(Off) // until flixel does null safety
		{
			final frames = FlxAtlasFrames.fromSpriteSheetPacker(graphic, FunkinAssets.exists(txtPath) ? FunkinAssets.getContent(txtPath) : null);
			if (frames != null) tempAtlasFramesCache.set(directPath, frames);
			return frames;
		}
	}
	
	public static inline function getSparrowAtlas(key:String, ?parentFolder:String, ?allowGPU:Bool = true, checkMods:Bool = true):FlxAtlasFrames
	{
		final directPath = getPath('images/$key.png', parentFolder, checkMods).withoutExtension();
		final tempFrames = tempAtlasFramesCache.get(directPath);
		if (tempFrames != null)
		{
			return tempFrames;
		}
		
		final xmlPath = getPath('images/$key.xml', parentFolder, checkMods);
		@:nullSafety(Off) // until flixel does null safety
		{
			final frames = FlxAtlasFrames.fromSparrow(image(key, parentFolder, allowGPU, checkMods), FunkinAssets.exists(xmlPath) ? FunkinAssets.getContent(xmlPath) : null);
			if (frames != null) tempAtlasFramesCache.set(directPath, frames);
			return frames;
		}
	}
	
	public static inline function getPackerAtlas(key:String, ?parentFolder:String, ?allowGPU:Bool = true, checkMods:Bool = true)
	{
		final directPath = getPath('images/$key.png', parentFolder, checkMods).withoutExtension();
		final tempFrames = tempAtlasFramesCache.get(directPath);
		if (tempFrames != null)
		{
			return tempFrames;
		}
		
		final txtPath = getPath('images/$key.txt', parentFolder, checkMods);
		@:nullSafety(Off) // until flixel does null safety
		{
			final frames = FlxAtlasFrames.fromSpriteSheetPacker(image(key, parentFolder, allowGPU, checkMods), FunkinAssets.exists(txtPath) ? FunkinAssets.getContent(txtPath) : null);
			if (frames != null) tempAtlasFramesCache.set(directPath, frames);
			return frames;
		}
	}
	
	/**
	 * Removes all non alpha numeric chars and replaces spaces with `-` to lower in a given String.
	 * 
	 * Example: My Song Path! == my-song-path
	 */
	public static inline function sanitize(path:String):String
	{
		return ~/[^- a-zA-Z0-9..\/]+\//g.replace(path, '').replace(' ', '-').trim().toLowerCase();
	}
	
	/**
	 * Lists all files found within a given directory
	 *
	 * if `checkMods`, they will be loaded in order of
	 *
	 * `content/globalMods/`, `content/`, `content/currentMod/`, then asset mods.
	 */
	public static function listAllFilesInDirectory(directory:String, checkMods:Bool = true) // based of psychs Mods.directoriesWithFile
	{
		var folders:Array<String> = [];
		var files:Array<String> = [];
		
		if (FunkinAssets.exists(getCorePath(directory)) || FunkinAssets.isDirectory(getCorePath(directory))) folders.push(getCorePath(directory));
		
		#if MODS_ALLOWED
		if (checkMods)
		{
			for (mod in Mods.globalMods)
			{
				final folder = mods('$mod/$directory');
				if (FileSystem.exists(folder) && !folders.contains(folder)) folders.push(folder);
			}
			
			final folder = mods(directory);
			if (FileSystem.exists(folder) && !folders.contains(folder)) folders.push(folder);
			
			if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			{
				final folder = mods('${Mods.currentModDirectory}/$directory');
				if (FileSystem.exists(folder) && !folders.contains(folder)) folders.push(folder);
			}
		}
		#end
		
		if (currentAssetMod != null && currentAssetMod.length > 0)
		{
			var assetModDir = getAssetModFilePath(currentAssetMod, directory);
			if (FunkinAssets.isDirectory(assetModDir) && !folders.contains(assetModDir))
			{
				folders.push(assetModDir);
			}
		}
		
		#if ASSET_REDIRECT
		var embedsDir = '$EMBEDS_DIRECTORY/$directory';
		if (FunkinAssets.isDirectory(embedsDir) && !folders.contains(embedsDir))
		{
			folders.push(embedsDir);
		}
		#else
		for (assetMod in getAssetMods())
		{
			var assetModDir = '$CORE_DIRECTORY/$assetMod/$directory';
			if (FunkinAssets.isDirectory(assetModDir) && !folders.contains(assetModDir))
			{
				folders.push(assetModDir);
			}
		}
		#end
		
		for (folder in folders)
		{
			for (file in FunkinAssets.readDirectory(folder))
			{
				final path = Path.join([folder, file]);
				if (!files.contains(path)) files.push(path);
			}
		}
		
		return files;
	}
	
	/**
	 * Inserts the mod asset path to the given file path
	 */
	public static inline function mods(key:String = ''):String
	{
		#if MODS_ALLOWED
		return #if android android.StorageUtil.getExternalStorageDirectory() + #else Sys.getCwd() + #end '$MODS_DIRECTORY/' + key;
		#else
		return '$MODS_DIRECTORY/' + key;
		#end
	}
	
	/**
	 * Searches the primary loaded mod path and general mod path for a given file
	 */
	public static function modFolders(key:String):String
	{
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			final fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			#if MODS_ALLOWED
			if (FileSystem.exists(fileToCheck)) return fileToCheck;
			#else
			if (FunkinAssets.exists(fileToCheck)) return fileToCheck;
			#end
		}
		
		for (mod in Mods.globalMods)
		{
			final fileToCheck:String = mods(mod + '/' + key);
			#if MODS_ALLOWED
			if (FileSystem.exists(fileToCheck)) return fileToCheck;
			#else
			if (FunkinAssets.exists(fileToCheck)) return fileToCheck;
			#end
		}
		return mods(key);
	}
	
	/**
	 * Returns the preload path for assets (used primarily for Android compatibility)
	 * @param key Optional path to append
	 * @return The preload path
	 */
	public static inline function getPreloadPath(key:String = ''):String
	{
		return 'assets/$key';
	}
	
	/**
	 * Gets all global mods - aliased from Mods.globalMods for convenience
	 * @return Array of global mod names
	 */
	public static inline function getGlobalMods():Array<String>
	{
		#if MODS_ALLOWED
		return Mods.globalMods;
		#else
		return [];
		#end
	}
	
	/**
	 * Reads a directory and returns all file/folder names.
	 * Works on both sys filesystem and embedded assets (Android compatible).
	 * @param directory The directory path to read
	 * @return Array of file/folder names in the directory
	 */
	public static function readDirectory(directory:String):Array<String>
	{
		return FunkinAssets.readDirectory(directory);
	}
	
	/**
	 * Gets mod-like directories from the assets folder.
	 * @return Array of asset mod directory names
	 */
	public static function getAssetMods():Array<String>
	{
		var list:Array<String> = [];
		
		for (knownMod in Mods.knownAssetMods)
		{
			var potentialCorePath = '$CORE_DIRECTORY/$knownMod';
			#if ASSET_REDIRECT
			var potentialEmbedsPath = '$EMBEDS_DIRECTORY/$knownMod';
			if (FunkinAssets.isDirectory(potentialEmbedsPath) || FunkinAssets.isDirectory(potentialCorePath))
			{
				if (!list.contains(knownMod)) list.push(knownMod);
			}
			#else
			if (FunkinAssets.isDirectory(potentialCorePath))
			{
				if (!list.contains(knownMod)) list.push(knownMod);
			}
			#end
		}
		
		var coreFiles = FunkinAssets.readDirectory(CORE_DIRECTORY);
		for (folder in coreFiles)
		{
			if (!Mods.ignoreModFolders.contains(folder.toLowerCase()))
			{
				var potentialModPath = '$CORE_DIRECTORY/$folder';
				if (FunkinAssets.isDirectory(potentialModPath))
				{
					var alreadyExists = false;
					for (existing in list)
					{
						if (existing.toLowerCase() == folder.toLowerCase())
						{
							alreadyExists = true;
							break;
						}
					}
					if (!alreadyExists) list.push(folder);
				}
			}
		}
		
		#if ASSET_REDIRECT
		var embedsFiles = FunkinAssets.readDirectory(EMBEDS_DIRECTORY);
		for (folder in embedsFiles)
		{
			if (!Mods.ignoreModFolders.contains(folder.toLowerCase()))
			{
				var potentialModPath = '$EMBEDS_DIRECTORY/$folder';
				if (FunkinAssets.isDirectory(potentialModPath))
				{
					var alreadyExists = false;
					for (existing in list)
					{
						if (existing.toLowerCase() == folder.toLowerCase())
						{
							alreadyExists = true;
							break;
						}
					}
					if (!alreadyExists) list.push(folder);
				}
			}
		}
		#end
		
		return list;
	}
	
	/**
	 * Gets the path to an asset mod folder (case-insensitive)
	 * @param modName The name of the asset mod
	 * @return The full path to the mod folder
	 */
	public static function getAssetModPath(modName:String):String
	{
		var actualName = findAssetModWithCase(modName);
		if (actualName != null) modName = actualName;
		
		#if ASSET_REDIRECT
		var embedsPath = '$EMBEDS_DIRECTORY/$modName';
		if (FunkinAssets.isDirectory(embedsPath)) return embedsPath;
		#end
		
		return '$CORE_DIRECTORY/$modName';
	}
	
	/**
	 * Finds an asset mod folder with case-insensitive matching
	 * @param modName The mod name to find (any case)
	 * @return The actual folder name with correct case, or null if not found
	 */
	public static function findAssetModWithCase(modName:String):Null<String>
	{
		var lowerName = modName.toLowerCase();
		
		for (known in Mods.knownAssetMods)
		{
			if (known.toLowerCase() == lowerName) return known;
		}
		
		for (mod in getAssetMods())
		{
			if (mod.toLowerCase() == lowerName) return mod;
		}
		
		return null;
	}
}
