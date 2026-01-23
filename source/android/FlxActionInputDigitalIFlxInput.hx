package android;

import flixel.input.actions.FlxActionInputDigital;
import flixel.input.IFlxInput;
import flixel.input.FlxInput;
import flixel.input.actions.FlxAction;

class FlxActionInputDigitalIFlxInput extends FlxActionInputDigital
{
	var input:IFlxInput;
	
	public function new(Input:IFlxInput, Trigger:FlxInputState)
	{
		super(0, Trigger);
		input = Input;
	}
	
	override public function check(Action:FlxAction):Bool
	{
		return switch (trigger)
		{
			case PRESSED: input.pressed;
			case JUST_PRESSED: input.justPressed;
			case RELEASED: input.released;
			case JUST_RELEASED: input.justReleased;
		}
	}
}
