include( "expadv/core.lua" )


if CLIENT then
	include( "expadv/wikibuilder.lua" )
	return
end

AddCSLuaFile( )
AddCSLuaFile( "expadv/wikibuilder.lua" )

AddCSLuaFile( "expadv/context.lua" )
AddCSLuaFile( "expadv/core.lua" )
AddCSLuaFile( "expadv/components.lua" )
AddCSLuaFile( "expadv/classes.lua" )
AddCSLuaFile( "expadv/operators.lua" )
AddCSLuaFile( "expadv/events.lua" )
AddCSLuaFile( "expadv/directives.lua" )
AddCSLuaFile( "expadv/cppi.lua" )
AddCSLuaFile( "expadv/context.lua" )

AddCSLuaFile( "expadv/compiler/main.lua" )
AddCSLuaFile( "expadv/compiler/tokenizer.lua" )
AddCSLuaFile( "expadv/compiler/parser.lua" )
AddCSLuaFile( "expadv/compiler/instructions.lua" )

AddCSLuaFile( "expadv/api/gcompute.lua" )

AddCSLuaFile( "includes/modules/von.lua" )
AddCSLuaFile( "includes/modules/vnet.lua" )
AddCSLuaFile( "includes/modules/vector2.lua" )
AddCSLuaFile( "includes/modules/matrix2.lua" )
AddCSLuaFile( "includes/modules/quaternion.lua" )

AddCSLuaFile( "expadv/editor/ea_button.lua" )
AddCSLuaFile( "expadv/editor/ea_filemenu.lua" )
AddCSLuaFile( "expadv/editor/ea_closebutton.lua" )
AddCSLuaFile( "expadv/editor/ea_editor.lua" )
AddCSLuaFile( "expadv/editor/ea_editorpanel.lua" )
AddCSLuaFile( "expadv/editor/ea_filenode.lua" )
AddCSLuaFile( "expadv/editor/ea_frame.lua" )
AddCSLuaFile( "expadv/editor/ea_hscrollbar.lua" )
AddCSLuaFile( "expadv/editor/ea_imagebutton.lua" )
AddCSLuaFile( "expadv/editor/ea_toolbar.lua" )
AddCSLuaFile( "expadv/editor/syntaxer.lua" )
AddCSLuaFile( "expadv/editor/pastebin.lua" )
AddCSLuaFile( "expadv/editor/ea_search.lua" )
AddCSLuaFile( "expadv/editor/ea_codecompletion.lua" )

AddCSLuaFile( "expadv/editor.lua" )
AddCSLuaFile( "expadv/editor/shared.lua" )
AddCSLuaFile( "expadv/editor/manual.lua" )

resource.AddWorkshop( "323792126" )
