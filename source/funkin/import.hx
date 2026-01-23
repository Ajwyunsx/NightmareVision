package funkin;

#if !macro
import flixel.util.FlxDestroyUtil;

import extensions.flixel.FlxCameraEx;
import extensions.flixel.FlxSoundEx;

import funkin.backend.MusicBeatState;
import funkin.backend.MusicBeatSubstate;
import funkin.scripting.ScriptConstants;
import funkin.audio.FunkinSound;
import funkin.backend.Logger;
import funkin.utils.*;

#if android
import android.backend.*;

import android.*;

import flixel.input.actions.FlxActionInput;

import android.FlxTouchPad;
import android.flixel.*;
#end

using haxe.io.Path;
#end
