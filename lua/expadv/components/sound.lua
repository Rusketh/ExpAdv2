/* --- --------------------------------------------------------------------------------
	@: Sound Component
	@: Author: Ripmax
   --- */

local Component = EXPADV.AddComponent("sound", true)

Component.Author = "Ripmax"
Component.Description = "Allows for sound to be played."

Component:CreateSetting("maximumsounds", 10)

function Component:OnRegisterContext(Context) Context.Data.Sound = {} Context.Data.SoundCount = 0 end

function Component:OnUnregisterContext(Context) if(Context.Data.Sound) then for k, v in pairs(Context.Data.Sound) do v:Stop() end end end

local function stopSound(Context, Index, Fade)
	if(!Context.Data.Sound[Index]) then return end
	
	local sound = Context.Data.Sound[Index]
	if(Fade > 0) then
		sound:FadeOut(Fade)
		timer.Simple(Fade, function() stopSound(Context, Index, 0) end)
	else
		sound:Stop()
		if(type(Index) == "number") then Index = math.floor(Index) end
		Context.Data.Sound[Index] = nil
	end
	
	Context.Data.SoundCount = Context.Data.SoundCount - 1
end

EXPADV.GAME_SOUNDS = EXPADV.GAME_SOUNDS or {}

local function playSound(Context, Ent, Duration, Index, Fade, File)
	if(!Ent || !IsValid(Ent)) then Ent = Context.entity end
	local maxsounds = Component:ReadSetting("maximumsounds", 10)
	
	if(File:match("[\"?]")) then return end
	File = string.Trim(File)
	File = File:gsub("\\", "/")
	if(type(Index) == "number") then Index = math.floor(Index) end
	
	if(Context.Data.SoundCount >= maxsounds) then return end
	
	if(Context.Data.Sound[Index]) then stopSound(Context, Index, 0) end
	
	local newSound = CreateSound(Ent, File)

	EXPADV.GAME_SOUNDS[#EXPADV.GAME_SOUNDS+1] = newSound

	Context.Data.Sound[Index] = newSound

	newSound:Play()

	Context.Data.SoundCount = Context.Data.SoundCount + 1
	
	if(Duration == 0 and Fade == 0) then return end
	timer.Create("EA2Gate-" .. Context.entity:EntIndex() .. ";STOPSound_" .. Index, Duration, 0, function() stopSound(Context, Index, Fade) end)
	
end

EXPADV.SharedOperators()

Component:AddVMFunction("soundPlay", "n,n,s", "", function(Context, Trace, Index, Duration, File) playSound(Context, Context.entity, math.abs(Duration), math.abs(Index), 0, File) end)
Component:AddVMFunction("soundPlay", "e:n,n,s", "", function(Context, Trace, Ent, Index, Duration, File) playSound(Context, Ent, math.abs(Duration), math.abs(Index), 0, File) end)
Component:AddVMFunction("soundPlay", "n,n,n,s", "", function(Context, Trace, Index, Duration, Fade, File) playSound(Context, Context.entity, math.abs(Duration), math.abs(Index), math.abs(Fade), File) end)
Component:AddVMFunction("soundPlay", "e:n,n,n,s", "", function(Context, Trace, Ent, Index, Duration, Fade, File) playSound(Context, Ent, math.abs(Duration), math.abs(Index), math.abs(Fade), File) end)
Component:AddFunctionHelper("soundPlay", "n,n,s", "Play a sound from the chip.")
Component:AddFunctionHelper("soundPlay", "e:n,n,s", "Play a sound from the given entity.")
Component:AddFunctionHelper("soundPlay", "n,n,n,s", "Play a sound from the chip, specifying a fade duration.")
Component:AddFunctionHelper("soundPlay", "e:n,n,n,s", "Play a sound from the given entity, specifying a fade duration.")

Component:AddVMFunction("soundStop", "n", "", function(Context, Trace, Index) stopSound(Context, Index, 0) end)
Component:AddVMFunction("soundStop", "n,n", "", function(Context, Trace, Index, Fade) stopSound(Context, Index, math.abs(Fade)) end)
Component:AddFunctionHelper("soundStop", "n", "Stop the sound of the given index.")
Component:AddFunctionHelper("soundStop", "n,n", "Stop the sound of the given index, specifying a fade duration.")

Component:AddVMFunction("soundVolume", "n,n", "", function(Context, Trace, Index, Volume) if(Context.Data.Sound[Index]) then Context.Data.Sound[Index]:ChangeVolume(math.Clamp(math.abs(Volume), 0, 1), 0) end end)
Component:AddVMFunction("soundVolume", "n,n,n", "", function(Context, Trace, Index, Volume, Fade) if(Context.Data.Sound[Index]) then Context.Data.Sound[Index]:ChangeVolume(math.Clamp(math.abs(Volume), 0, 1), math.abs(Fade)) end end)
Component:AddFunctionHelper("soundVolume", "n,n", "Sets the volume of the given sound, 0-1")
Component:AddFunctionHelper("soundVolume", "n,n,n", "Sets the volume of the given sound, 0-1, specifying a fade duration.")

Component:AddVMFunction("soundPitch", "n,n", "", function(Context, Trace, Index, Pitch) if(Context.Data.Sound[Index]) then Context.Data.Sound[Index]:ChangePitch(math.Clamp(math.abs(Pitch), 0, 255), 0) end end)
Component:AddVMFunction("soundPitch", "n,n,n", "", function(Context, Trace, Index, Pitch, Fade) if(Context.Data.Sound[Index]) then Context.Data.Sound[Index]:ChangePitch(math.Clamp(math.abs(Pitch), 0, 255), math.abs(Fade)) end end)
Component:AddFunctionHelper("soundPitch", "n,n", "Sets the pitch of the given sound, 0-255")
Component:AddFunctionHelper("soundPitch", "n,n,n", "Sets the pitch of the given sound, 0-255, specifying a fade duration.")

Component:AddInlineFunction("soundDuration", "s", "n", "$SoundDuration(@value 1)")
Component:AddFunctionHelper("soundDuration", "s", "Returns the duration of the given sound.")

Component:AddVMFunction("soundStopAll", "", "", function(Context, Trace) for k, v in pairs(Context.Data.Sound) do v:Stop() timer.Remove("EA2Gate-" .. Context.entity:EntIndex() .. ";STOPSound_" .. k) Context.Data.SoundCount = 0 end end)
Component:AddFunctionHelper("soundStopAll", "", "Stops all sounds from the chip.")

/* --- --------------------------------------------------------------------------------
	@: ClientSide Sound
	@: Author: Rusketh
   --- */

EXPADV.ClientOperators()

local SoundObject = Component:AddClass( "audio", "ac" )

SoundObject:AddPreparedOperator( "=", "n,ac", "", "Context.Memory[@value 1] = @value 2" )

SoundObject:MakeClientOnly( )

SoundObject:DefaultAsLua( nil )

Component:AddInlineOperator( "is", "ac", "b", "IsValid(@value 1)" )
Component:AddInlineOperator( "not", "ac", "b", "!IsValid(@value 1)" )


/* --- --------------------------------------------------------------------------------
	@: Methods
   --- */

Component:AddInlineFunction( "isValid", "ac:", "b", "IsValid(@value 1)" )
Component:AddFunctionHelper( "isValid", "ac:", "Returns true is the audio channel is valid." )

Component:AddPreparedFunction( "hasStopped", "ac:", "b", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end]], 
"(@value 1:GetState( ) == $GMOD_CHANNEL_STOPPED)" )
Component:AddFunctionHelper( "hasStopped", "ac:", "Returns true is the audio channel has stopped." )

Component:AddPreparedFunction( "isPlaying", "ac:", "b", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end]], 
"(@value 1:GetState( ) == $GMOD_CHANNEL_PLAYING)" )
Component:AddFunctionHelper( "isPlaying", "ac:", "Returns true is the audio channel is playing." )

Component:AddPreparedFunction( "isPaused", "ac:", "b", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end]], 
"(@value 1:GetState( ) == $GMOD_CHANNEL_PAUSED)" )
Component:AddFunctionHelper( "isPaused", "ac:", "Returns true is the audio channel is paused." )

Component:AddPreparedFunction( "hasStalled", "ac:", "b", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end]], 
"(@value 1:GetState( ) == $GMOD_CHANNEL_STALLED)" )
Component:AddFunctionHelper( "hasStalled", "ac:", "Returns true is the audio channel has stalled." )

Component:AddPreparedFunction( "enableLooping", "ac:b", "", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end
@value 1:EnableLooping( @value 2)]] )
Component:AddFunctionHelper( "enableLooping", "ac:b", "Enables or disables looping of audio channel, requires noblock flag." )

Component:AddPreparedFunction( "fft", "ac:n", "ar", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end
@define array = { }
@value 1:FFT( @array, @value 2)
@array.__type = "n"]], "@array" )
Component:AddFunctionHelper( "fft", "ac:n", "Returns the FFT table of the sound channel. This is what used to make visualization for the played sound." )

Component:AddPreparedFunction( "get3DCone", "ac:", "a", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end]],
		"Angle(@value 1:Get3DCone( ))" )
Component:AddFunctionHelper( "get3DCone", "ac:", "Returns 3D cone of the sound channel, ang(The angle of the inside projection cone in degrees, The angle of the outside projection cone in degrees. The delta-volume outside the outer projection cone). " )

Component:AddPreparedFunction( "getMax3DFadeDistance", "ac:", "n", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end
	@define min, max = @value 1:Get3DFadeDistance( )]], "@max" )
Component:AddFunctionHelper( "getMax3DFadeDistance", "ac:", "The channel's volume is at maximum when the listener is within this distance." )

Component:AddPreparedFunction( "getMin3DFadeDistance", "ac:", "n", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end
	@define min, max = @value 1:Get3DFadeDistance( )]], "@min" )
Component:AddFunctionHelper( "getMin3DFadeDistance", "ac:", "The channel's volume stops decreasing when the listener is beyond this distance." )

Component:AddPreparedFunction( "getBitsPerSample", "ac:", "n", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end]], "@value 1:GetBitsPerSample( )" )
Component:AddFunctionHelper( "getBitsPerSample", "ac:", "Number of bits per sample, or 0 if unknown." )

Component:AddPreparedFunction( "getURL", "ac:", "s", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end]], "@value 1:GetURL( )" )
Component:AddFunctionHelper( "getURL", "ac:", "Gets the url or path of the sound." )

Component:AddPreparedFunction( "getLength", "ac:", "n", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end]],	"@value 1:GetLength( )" )
Component:AddFunctionHelper( "getLength", "ac:", "Returns the length of sound played by the sound channel." )

Component:AddPreparedFunction( "getPlaybackRate", "ac:", "n", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end]],	"@value 1:GetPlaybackRate( )" )
Component:AddFunctionHelper( "getPlaybackRate", "ac:", "Returns the playback rate of the sound channel." )

Component:AddPreparedFunction( "getPos", "ac:", "v", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end]], "(@value 1:GetPos( ) or Vector(0,0,0))" )
Component:AddFunctionHelper( "getPos", "ac:", "Returns positionmof the sound." )

Component:AddPreparedFunction( "getSamplingRate", "ac:", "n", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end]], "@value 1:GetSamplingRate( )" )
Component:AddFunctionHelper( "getSamplingRate", "ac:", "Returns the sample rate of the sound." )

Component:AddPreparedFunction( "getTime", "ac:", "n", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end]], "@value 1:GetTime( )" )
Component:AddFunctionHelper( "getTime", "ac:", "Returns the current time of the sound channel." )

Component:AddPreparedFunction( "getVolume", "ac:", "n", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end]], "(@value 1:GetVolume( ) * 100)" )
Component:AddFunctionHelper( "getVolume", "ac:", "Returns the current volume of the sound channel." )

Component:AddPreparedFunction( "is3D", "ac:", "b", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end]], "@value 1:Is3D( )" )
Component:AddFunctionHelper( "is3D", "ac:", "Returns if the sound channel is in 3D mode or not." )

Component:AddPreparedFunction( "isBlockStreamed", "ac:", "b", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end]], "@value 1:IsBlockStreamed( )" )
Component:AddFunctionHelper( "isBlockStreamed", "ac:", "Returns whether the audio stream is block streamed or not." )

Component:AddPreparedFunction( "isLooping", "ac:", "b", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end]], "@value 1:IsLooping( )" )
Component:AddFunctionHelper( "isLooping", "ac:", "Returns whether the audio stream is looping or not." )

-- Component:AddPreparedFunction( "isOnline", "ac:", "b", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end]], "@value 1:IsOnline( )" )
-- Component:AddFunctionHelper( "isOnline", "ac:", "Returns whether the audio stream is streamed online or not." )

Component:AddPreparedFunction( "pause", "ac:", "b", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end
@value 1:Pause( )]] )
Component:AddFunctionHelper( "pause", "ac:", "Pauses the stream." )

Component:AddPreparedFunction( "play", "ac:", "b", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end
@value 1:Play( )]] )
Component:AddFunctionHelper( "play", "ac:", "Starts playing the stream." )

Component:AddPreparedFunction( "stop", "ac:", "b", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end
@value 1:Stop( )]] )
Component:AddFunctionHelper( "stop", "ac:", "Stops playing the stream." )

Component:AddPreparedFunction( "set3DFadeDistance", "ac:n,n", "", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end
@value 1:Set3DFadeDistance(@value 2, @value 3)]] )
Component:AddFunctionHelper( "set3DFadeDistance", "ac:n,n", "Sets minamum and maximum 3D fade distances of a sound channel." )

Component:AddPreparedFunction( "set3DCone", "ac:n,n,n", "", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end
@value 1:Set3DCone(@value 2, @value 3, @value 4)]] )
Component:AddFunctionHelper( "set3DCone", "ac:n,n,n", "Sets 3D cone of the sound channel." )

Component:AddPreparedFunction( "setPlaybackRate", "ac:n", "", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end
@value 1:SetPlaybackRate(@value 2)]] )
Component:AddFunctionHelper( "setPlaybackRate", "ac:n", "Sets 3D cone of the sound channel." )

Component:AddPreparedFunction( "setPos", "ac:v,v", "", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end
@value 1:SetPos(@value 2, @value 3)]] )
EXPADV.AddFunctionAlias( "setPos", "ac:v" )
Component:AddFunctionHelper( "setPos", "ac:v,v", "Sets position of sound channel in case the sound channel has a 3d option set, with optional direction." )

Component:AddPreparedFunction( "setTime", "ac:n", "", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end
@value 1:SetTime(@value 2)]] )
Component:AddFunctionHelper( "setTime", "ac:n", "Sets the sound channel to specified time ( Rewind to that position of the song ). Does not work on online radio streams. Your sound must have 'noblock' parameter for this to work." )

Component:AddPreparedFunction( "setVolume", "ac:n", "", [[if !IsValid( @value 1) then Context:Throw( @trace, "audio channel", "Recieved invalid audio channel." ) end
@value 1:SetVolume(@value 2 * 0.01)]] )
Component:AddFunctionHelper( "setVolume", "ac:n", "Sets the volume of a sound channel" )

Component:AddInlineFunction( "canPlayFromURL", "", "b", [[EXPADV.CanAccessFeature(Context.entity, "PlayURL")]] )
Component:AddFunctionHelper( "canPlayFromURL", "", "Returns true if this entity can play audio from url." )


if CLIENT then
	hook.Add( "Expadv.RegisterContext", "expadv.sound", function( Context )
		Context.Data.Audio = { }
		Context.Data.AudioCount = 0
	end )

	hook.Add( "Expadv.UnregisterContext", "expadv.sound", function( Context )
		if (Context.Data.AudioCount or 0) <= 0 then return end
		
		for _, Channel in pairs( Context.Data.Audio ) do
			if IsValid( Channel ) then Channel:Stop( ) end
		end
	end )
end

/* --- --------------------------------------------------------------------------------
	@: Sound from URL
	@: Author: Rusketh
   --- */

EXPADV.ClientOperators()

EXPADV.URL_SOUNDS = EXPADV.URL_SOUNDS or {}

Component:AddVMFunction( "playURL", "s,s,d,d", "", 
	function( Context, Trace, URL, Flags, Sucess, Fail )
		if !IsValid(Context.entity) or !EXPADV.CanAccessFeature(Context.entity, "PlayURL") then return end

		sound.PlayURL( URL, Flags,
			function( Channel, Er_ID, Er_Name ) 
				if IsValid( Channel ) then
					EXPADV.URL_SOUNDS[#EXPADV.URL_SOUNDS+1] = Channel

					if !IsValid(Context.entity) then
						Channel:Stop()
						return
					end

					Context.Data.AudioCount = Context.Data.AudioCount + 1
					Context.Data.Audio[Context.Data.AudioCount] = Channel
					Context:Execute( "PlayURL", Sucess, { Channel, "_ac" } )
				elseif Fail then
					Context:Execute( "PlayURL", Fail, { Er_ID, "n" }, { Er_Name, "s" } )
				end
			end )
	end )

EXPADV.AddFunctionAlias( "playURL", "s,s,d" )

Component:AddFunctionHelper( "playURL", "s,s,d,d", "Plays sound from 1st string URL with 2st string mode, executes 1st delegate with audio on success else 2nd delegate.")
Component:AddFunctionHelper( "playURL", "s,s,d", "Plays sound from 1st string URL with 2st string mode executes the delegate with audio on success.")


/* -----------------------------------------------------------------------------------
	@: Hooks
   --- */

EXPADV.ClientEvents( )
Component:AddEvent( "enablePlayURL", "", "" )
Component:AddEvent( "disablePlayURL", "", "" )

/* -----------------------------------------------------------------------------------
	@: Features.
   --- */

Component:AddFeature( "PlayURL", "Stream audio via url feeds.", "tek/icons/iconsound.png" )

if CLIENT then

	local function DisableSounds( Entity )
		Entity:CallEvent( "disablePlayURL" )

		local Context = Entity.Context
		if !Context or (Context.Data.AudioCount or 0) <= 0 then return end

		for _, Channel in pairs( Context.Data.Audio ) do
			if IsValid( Channel ) then Channel:Stop( ) end
		end

		Context.Data.Audio = { }
		Context.Data.AudioCount = 0
	end

	function Component:OnChangeFeatureAccess(Entity, Feature, Value)
		if Feature ~= "PlayURL" then return end
		
		if Value then
			Entity:CallEvent( "enablePlayURL" )
		else
			DisableSounds( Entity )
		end
	end

	hook.Add( "Expadv.UnregisterContext", "expadv.soundurl", function( Context )
		DisableSounds(Context.entity)
	end )

	concommand.Add("expadv_stopsound", function()
		local new = {}

		for _, Sound in pairs(EXPADV.URL_SOUNDS) do
			if IsValid(Sound) then
				Sound:Stop()
				new[#new+1] = Sound
			end
		end

		EXPADV.URL_SOUNDS = new

		for _, Sound in pairs(EXPADV.GAME_SOUNDS) do
			Sound:Stop()
		end

		EXPADV.GAME_SOUNDS = {}

		MsgN("Sounds stopped.")
	end)
end
