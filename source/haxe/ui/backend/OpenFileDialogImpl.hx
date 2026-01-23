package haxe.ui.backend;

#if android
import haxe.ui.containers.dialogs.Dialogs.SelectedFileInfo;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;

// Android stub - FileReferenceList is not available on mobile
// Extends OpenFileDialogBase to maintain API compatibility
class OpenFileDialogImpl extends OpenFileDialogBase
{
	public function new()
	{
		super();
	}
	
	override public function show():Void
	{
		// File dialogs are not supported on Android - immediately cancel
		dialogCancelled();
	}
}
#end
