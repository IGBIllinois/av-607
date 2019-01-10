PROGRAM_NAME='Room 607'
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
(* REV HISTORY:                                            *)
(***********************************************************)

(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE
(*System number changed to 3 so that the MVP would not conect*)
(*to the system in Room 612/614*)
dvAudia1 = 5001:1:3	//Biamp Nexia CS		(A)<--Ref on DWG
dvProjA  = 5001:2:3	//Proxima C450 Right side as looking at Screen (B)
dvProjB  = 5001:3:3	//Proxima C450 Left side as looking at Screen (C)
dvMatrix = 5001:4:3	//Extron Crosspoint 450 Plus Matrix Switcher
dvTp     = 10006:1:3	//MVP8400 Touchpanel	
Relay = 5001:8:3	//Relay used for Power Strip
(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT
integer nLeft = 1	//Used for selecting Left Proj
integer nRight = 2	//Used for selecting Right Proj
integer nCam = 1
integer nVCR = 2
integer nPC = 3
integer PowerRelay = 1
TL1 = 1
integer nRgbPortBtn[]=	//For selecting the RGB floor jacks
{
    50,51,52,53		//Currently only the first one is used.
}
INTEGER nSrcSelects[] = 
{
    91,	//612 Camera
    93	//Laptop
}
integer nBtnDest[] = 
{
    1,	//Left Proj
    2,	//Right Proj
    3	//Both Projectors
    
}

integer nProjAdvance[] =
{
    101,	//Left Projector PC
    102,	//Left Projector Aux
    103,	//Left Projector Overflow Presentation
    104,	//Left Projector Overflow Camera
    105,	//Left Projector Power Off
    106,	//Right Projector PC
    107,	//Right Projector Aux
    108,	//Right Projector Overflow Presentation
    109,	//Right Projector Overflow Camera
    110		//Right Projector Power Off

}
integer nBtnPwrOff[] = 
{
    4	//This is the YES button.
}

integer MxVinPC = 1
integer MxVinAux = 2
integer MxVinCam = 3
integer MxVin607Pres = 4
integer MxVin607Cam = 5

integer MxVoutLProj = 1
integer MxVoutRProj = 2
integer MxVoutEchoPres = 3
integer MxVoutEchoCam = 4

integer MxAoutPC = 1
integer MxAoutAux = 2

Char MxModeBoth[] = '!'
Char MxModeVideo[] = '&'
Char MxModeAudio[] = '$'
(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

integer nCurrentSource
integer RightProjPwrStatus
integer LeftProjPwrStatus
integer nTimeBlock
integer TimeArray[61]
integer Count
INTEGER RUN1
INTEGER RUN2
PROJ_POWER1
PROJ_POWER2
PROJ_BUFFER1[10]
PROJ_BUFFER2[10]
char MATRIX_BUFFER[32]
INTEGER DISPLAY

widechar InStr[3]
widechar OutStr[2]
widechar Signal[7]
(***********************************************************)
(*               LATCHING DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_LATCHING

(***********************************************************)
(*       MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW           *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)
INCLUDE 'AMX_ArrayLib.axi'
INCLUDE 'nAMX_QUEUE.axi'
INCLUDE 'Biamp_Audia.axi'
INCLUDE 'UnicodeLib.axi'

DEFINE_CALL 'Proj Power'(integer Proj_Num, char Proj_Control[10]) //Projector Control Sub.
{
    SELECT
    {
	ACTIVE(Proj_Num = 1):			//left_proj
	{
	    SELECT
	    {
		ACTIVE(Proj_Control = 'PON'):
		{
		    SEND_STRING dvProjA,"'PWR ON',$0D"
		    WAIT 25
		    {
			RUN1 = 1
		    }
		}
		ACTIVE(Proj_Control = 'POF'):
		{
		    SEND_STRING dvProjA,"'PWR OFF',$0D"
		    WAIT 25 {
			RUN1 = 0
		    }
		}
	    }
	}
	ACTIVE(Proj_Num = 2):			//right
	{
	    SELECT
	    {
		ACTIVE(Proj_Control = 'PON'):
		{
		    SEND_STRING dvProjB,"'PWR ON',$0D"
		    WAIT 25 {
			RUN2 = 1
		    }
		}
		ACTIVE(Proj_Control = 'POF'):
		{
		    SEND_STRING dvProjB,"'PWR OFF',$0D"
		    WAIT 25 {
			RUN2 = 0
		    }
		}
	    }
	}
	
    }
}

DEFINE_CALL 'Matrix Tie'(integer MxIn, integer MxOut, Char MxAV[])
{
    InStr = CH_TO_WC(FORMAT('%01d*',MxIn))
    OutStr = CH_TO_WC(FORMAT('%01u',MxOut))
    Signal = WC_CONCAT_STRING(InStr,WC_CONCAT_STRING(OutStr,CH_TO_WC(MxAV)))
    
    SEND_STRING 0, "'Tieing ',MxIn,' to ',MxOut"
    SEND_STRING dvMatrix,WC_TO_CH(Signal)
}

DEFINE_CALL 'System Off'
{
    Call 'Proj Power'(1,'POF')
    Call 'Proj Power'(2,'POF')
    
    off[Relay,PowerRelay]
    AUDIA_SetVolumeFn (1, AUDIA_VOL_MUTE)
    AUDIA_MatchVolumeLvl (2,1)      // Example: If this was a stereo pair
    AUDIA_MatchVolumeLvl (3,1)      // Example: If this was a stereo pair
    RightProjPwrStatus = 0
    LeftProjPwrStatus = 0
    
}

DEFINE_CALL 'AUDIO_MUTE'(integer audio_channel) {
    IF(uAudiaVol[audio_channel].nMute)
	{
          AUDIA_SetVolumeFn (audio_channel, AUDIA_VOL_MUTE_OFF)
	}
        ELSE
	{
          AUDIA_SetVolumeFn (audio_channel, AUDIA_VOL_MUTE)
	}


}
DEFINE_CALL 'AUDIO_UP'(integer audio_channel) {
    IF(uAudiaVol[audio_channel].nMute)
	{
          AUDIA_SetVolumeFn (audio_channel, AUDIA_VOL_MUTE_OFF)
	}
        ELSE
	{
          AUDIA_SetVolumeFn (audio_channel, AUDIA_VOL_UP)
	}
}

DEFINE_CALL 'AUDIO_DOWN'(integer audio_channel) {
    IF(uAudiaVol[audio_channel].nMute)
	{
          AUDIA_SetVolumeFn (audio_channel, AUDIA_VOL_MUTE_OFF)
	}
        ELSE
	{
          AUDIA_SetVolumeFn (audio_channel, AUDIA_VOL_DOWN)
	}
}
DEFINE_CALL 'MUTE_STATE_CHANGE' (integer audio_channel, integer button_channel) {
    IF(uAudiaVol[audio_channel].nMute){
	MATRIX_BUFFER = "'^TXT-',ITOA(button_channel),',1&2,UNMUTE'"
	SEND_COMMAND dvTp,MATRIX_BUFFER
	SEND_COMMAND dvTp,"'^FON-',ITOA(button_channel),',1&2,37'" // 10 pt font
	SEND_COMMAND dvTp,"'^BCF-',ITOA(button_channel),',1&2,VeryDarkRed'"
    } ELSE {
	MATRIX_BUFFER = "'^TXT-',ITOA(button_channel),',1&2,MUTE'"
	SEND_COMMAND dvTp,MATRIX_BUFFER
	SEND_COMMAND dvTp,"'^FON-',ITOA(button_channel),',1&2,36'" // 12 pt font
	SEND_COMMAND dvTp,"'^BCF-',ITOA(button_channel),',1&2,Grey8'"
    }
}

DEFINE_CALL 'AUDIO_START' {
	    send_string dvAudia1,"'SET 2 INPMUTE 11 1 0',10" // 614 Computer L
	    send_string dvAudia1,"'SET 2 INPMUTE 11 2 0',10" // 614 Coimputer R
	    
	    send_string dvAudia1,"'SET 2 INPMUTE 11 3 0',10" // 612 Computer L
	    send_string dvAudia1,"'SET 2 INPMUTE 11 4 0',10" // 612 Computer R
	    
	    send_string dvAudia1,"'SET 2 INPMUTE 11 5 0',10" // 612 Computer L
	    send_string dvAudia1,"'SET 2 INPMUTE 11 6 0',10" // 612 Computer R
	    
	    AUDIA_SetVolumeFn(19,AUDIA_VOL_MUTE) // Mute 612 Audio by default
	    
	    AUDIA_SetVolumeFn (1, AUDIA_VOL_MUTE_OFF)
	    AUDIA_MatchVolumeLvl (2,1)      // Example: If this was a stereo pair
	    AUDIA_MatchVolumeLvl (3,1)      // Example: If this was a stereo pair
	    
	    Call'Matrix Tie'(MxVinPC,MxAoutPC,MxModeAudio)
	    Call'Matrix Tie'(MxVinAux,MxAoutAux,MxModeAudio)
	    
	    CALL'Matrix Tie'(MxVinPC,MxVoutEchoPres,MxModeVideo)
	    Call'Matrix Tie'(MxVinCam,MxVoutEchoCam,MxModeVideo)
}
(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START
RightProjPwrStatus = 0
LeftProjPwrStatus = 0
FOR (COUNT=0 ; COUNT<70 ; COUNT++)
{
    TimeArray[Count] = 1000
}
TIMELINE_CREATE(TL1, TimeArray, 61, TIMELINE_RELATIVE, TIMELINE_REPEAT) 

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT
DATA_EVENT[dvAudia1]	
{
    Online:
    {
	SEND_COMMAND dvAudia1,"'SET BAUD 38400,8,N,1'"
	Wait 10
	{
	    (*-- Biamp Parms (Lvl,Dev,VolCmd,MuteCmd,Min,Max) ---------*)
	    AUDIA_AssignVolumeParms (1, dvAUDIA1, 'SET 2 OUTLVL 12 1 ', 'SET 2 OUTMUTE 12 1 ', 0, 1120)
	    AUDIA_AssignVolumeParms (2, dvAUDIA1, 'SET 2 OUTLVL 12 2 ', 'SET 2 OUTMUTE 12 2 ', 0, 1120)
	    AUDIA_AssignVolumeParms (3, dvAUDIA1, 'SET 2 OUTLVL 12 6 ', 'SET 2 OUTMUTE 12 6 ', 0, 1120)
	    
	    AUDIA_AssignVolumeParms (10, dvAUDIA1, 'SET 2 FDRLVL 10 1 ', 'SET 2 FDRMUTE 10 1 ', 820, 1120)
	    AUDIA_AssignVolumeParms (17, dvAUDIA1, 'SET 2 FDRLVL 17 1 ', 'SET 2 FDRMUTE 17 1 ', 820, 1120)
	    AUDIA_AssignVolumeParms (18, dvAUDIA1, 'SET 2 FDRLVL 18 1 ', 'SET 2 FDRMUTE 18 1 ', 820, 1120)
	    AUDIA_AssignVolumeParms (19, dvAUDIA1, 'SET 2 FDRLVL 19 1 ', 'SET 2 FDRMUTE 19 1 ', 820, 1120)
	    AUDIA_AssignVolumeParms (20, dvAUDIA1, 'SET 2 FDRLVL 20 1 ', 'SET 2 FDRMUTE 20 1 ', 820, 1120)
	}
    }
}
DATA_EVENT[dvMatrix]
{
    STRING:
    {
	MATRIX_BUFFER = DATA.TEXT
    }
}
(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
DATA_EVENT[dvProjA]
{
    Online:
    {
	SEND_COMMAND data.device,"'SET BAUD 9600,8,N,1'" //Baud Rate of the Proj
	PROJ_POWER1 = 0
	
    }
     STRING:
    {
             
        LOCAL_VAR X
        PROJ_BUFFER1 = DATA.TEXT
        X = LENGTH_STRING(PROJ_BUFFER1)
        IF(X > 2)
        {
            SELECT
            {
                ACTIVE (MID_STRING(PROJ_BUFFER1,5,1) = '0'):PROJ_POWER1 = 0 //OFF
                ACTIVE (MID_STRING(PROJ_BUFFER1,5,1) = '1'):PROJ_POWER1 = 1 //ON
	    }
            SET_LENGTH_STRING(PROJ_BUFFER1,0)
            PROJ_BUFFER1 = '' 
	}
    }
}
DATA_EVENT[dvProjB]
{
    Online:
    {
	SEND_COMMAND data.device,"'SET BAUD 9600,8,N,1'" //Baud Rate of the Proj
	PROJ_POWER2 = 0
    }
     STRING:
    {
             
        LOCAL_VAR X
        PROJ_BUFFER2 = DATA.TEXT
        X = LENGTH_STRING(PROJ_BUFFER2)
        IF(X > 2)
        {
            SELECT
            {
                ACTIVE (MID_STRING(PROJ_BUFFER2,5,1) = '0'):PROJ_POWER2 = 0 //OFF
                ACTIVE (MID_STRING(PROJ_BUFFER2,5,1) = '1'):PROJ_POWER2 = 1 //ON
	    }
            SET_LENGTH_STRING(PROJ_BUFFER2,0)
            PROJ_BUFFER2 = '' 
	}
    }
}

BUTTON_EVENT[dvTp,nProjAdvance]
{
    Push:
    {
        switch (get_last(nProjAdvance))
        {
            Case 1: //Left Projector PC
            {
                Call 'Proj Power'(nLeft,'PON')
		Call 'Matrix Tie'(MxVinPC,MxVoutLProj,MxModeVideo)
            }
            Case 2: //Left Projector Aux
            {
                Call 'Proj Power'(nLeft,'PON')
		Call 'Matrix Tie'(MxVinAux,MxVoutLProj,MxModeVideo)
            }
            Case 3: //Left Projector Overflow Presentation
            {
                Call 'Proj Power'(nLeft,'PON')
		Call 'Matrix Tie'(MxVin607Pres,MxVoutLProj,MxModeVideo)
            }
            Case 4: //Left Projector Overflow Camera
            {
                Call 'Proj Power'(nLeft,'PON')
		Call 'Matrix Tie'(MxVin607Cam,MxVoutLProj,MxModeVideo)
            }
	    Case 5: //Left Projector Power Off
	    {
		Call 'Proj Power'(nLeft,'POF')
	    }
	    Case 6: //Right Projector PC
	    {
		Call 'Proj Power'(nRight,'PON')
		Call 'Matrix Tie'(MxVinPC,MxVoutRProj,MxModeVideo)
		Call 'Matrix Tie'(MxVinPC,MxVoutEchoPres,MxModeVideo)
	    }
	    Case 7: //Right Projector Aux
            {
                Call 'Proj Power'(nRight,'PON')
		Call 'Matrix Tie'(MxVinAux,MxVoutRProj,MxModeVideo)
		Call 'Matrix Tie'(MxVinAux,MxVoutEchoPres,MxModeVideo)
            }
            Case 8: //Right Projector Overflow Presentation
            {
                Call 'Proj Power'(nRight,'PON')
		Call 'Matrix Tie'(MxVin607Pres,MxVoutRProj,MxModeVideo)
            }
            Case 9: //Right Projector Overflow Camera
            {
                Call 'Proj Power'(nRight,'PON')
		Call 'Matrix Tie'(MxVin607Cam,MxVoutRProj,MxModeVideo)
            }
	    Case 10: //Right Projector Power Off
	    {
		Call 'Proj Power'(nRight,'POF')
	    }
        }
    }
}

BUTTON_EVENT[dvTp,nBtnPwrOff]
{
    Push:
    {
	Call 'System Off'
    }
}

BUTTON_EVENT[dvTp,204]        // Mic Vol Up
{
    PUSH :
    { 
	STACK_VAR INTEGER audio_channel 
	audio_channel = 10
	Call 'AUDIO_UP'(audio_channel)
	SEND_LEVEL dvTp,1,AUDIA_GetBgLvl(audio_channel)
	Call 'MUTE_STATE_CHANGE'(audio_channel,206)
    }
}
BUTTON_EVENT[dvTp,205]        // Mic Vol Down
{
    PUSH :
    { 
	STACK_VAR INTEGER audio_channel 
	audio_channel = 10
	Call 'AUDIO_DOWN'(audio_channel)
	SEND_LEVEL dvTp,1,AUDIA_GetBgLvl(audio_channel)
	Call 'MUTE_STATE_CHANGE'(audio_channel,206)
    }
}
BUTTON_EVENT[dvTp,206]        // Mic Vol Mute
{
    PUSH :
    { 
	STACK_VAR INTEGER audio_channel 
	audio_channel = 10
	Call 'AUDIO_MUTE'(audio_channel)
	SEND_LEVEL dvTp,1,AUDIA_GetBgLvl(audio_channel)
	Call 'MUTE_STATE_CHANGE'(audio_channel,206)
    }
}

BUTTON_EVENT[dvTp,214]        // Master Vol Up
{
    PUSH :
    { 
	STACK_VAR INTEGER audio_channel 
	audio_channel = 20
	Call 'AUDIO_UP'(audio_channel)
	SEND_LEVEL dvTp,2,AUDIA_GetBgLvl(audio_channel)
	Call 'MUTE_STATE_CHANGE'(audio_channel,216)
    }
}
BUTTON_EVENT[dvTp,215]        // Master Vol Down
{
    PUSH :
    { 
	STACK_VAR INTEGER audio_channel 
	audio_channel = 20
	Call 'AUDIO_DOWN'(audio_channel)
	SEND_LEVEL dvTp,2,AUDIA_GetBgLvl(audio_channel)
	Call 'MUTE_STATE_CHANGE'(audio_channel,216)
    }
}
BUTTON_EVENT[dvTp,216]        // Master Vol Mute
{
    PUSH :
    { 
	STACK_VAR INTEGER audio_channel 
	audio_channel = 20
	Call 'AUDIO_MUTE'(audio_channel)
	SEND_LEVEL dvTp,2,AUDIA_GetBgLvl(audio_channel)
	Call 'MUTE_STATE_CHANGE'(audio_channel,216)
    }
}

BUTTON_EVENT[dvTp,224]        // PC Vol Up
{
    PUSH :
    { 
	STACK_VAR INTEGER audio_channel 
	audio_channel = 17
	Call 'AUDIO_UP'(audio_channel)
	SEND_LEVEL dvTp,3,AUDIA_GetBgLvl(audio_channel)
	Call 'MUTE_STATE_CHANGE'(audio_channel,226)
    }
}
BUTTON_EVENT[dvTp,225]        // PC Vol Down
{
    PUSH :
    { 
	STACK_VAR INTEGER audio_channel 
	audio_channel = 17
	Call 'AUDIO_DOWN'(audio_channel)
	SEND_LEVEL dvTp,3,AUDIA_GetBgLvl(audio_channel)
	Call 'MUTE_STATE_CHANGE'(audio_channel,226)
    }
}
BUTTON_EVENT[dvTp,226]        // PC Vol Mute
{
    PUSH :
    { 
	STACK_VAR INTEGER audio_channel 
	audio_channel = 17
	Call 'AUDIO_MUTE'(audio_channel)
	SEND_LEVEL dvTp,3,AUDIA_GetBgLvl(audio_channel)
	Call 'MUTE_STATE_CHANGE'(audio_channel,226)
    }
}

BUTTON_EVENT[dvTp,234]        // Aux Vol Up
{
    PUSH :
    { 
	STACK_VAR INTEGER audio_channel 
	audio_channel = 18
	Call 'AUDIO_UP'(audio_channel)
	SEND_LEVEL dvTp,4,AUDIA_GetBgLvl(audio_channel)
	Call 'MUTE_STATE_CHANGE'(audio_channel,236)
    }
}
BUTTON_EVENT[dvTp,235]        // Aux Vol Down
{
    PUSH :
    { 
	STACK_VAR INTEGER audio_channel 
	audio_channel = 18
	Call 'AUDIO_DOWN'(audio_channel)
	SEND_LEVEL dvTp,4,AUDIA_GetBgLvl(audio_channel)
	Call 'MUTE_STATE_CHANGE'(audio_channel,236)
    }
}
BUTTON_EVENT[dvTp,236]        // Aux Vol Mute
{
    PUSH :
    { 
	STACK_VAR INTEGER audio_channel 
	audio_channel = 18
	Call 'AUDIO_MUTE'(audio_channel)
	SEND_LEVEL dvTp,4,AUDIA_GetBgLvl(audio_channel)
	Call 'MUTE_STATE_CHANGE'(audio_channel,236)
    }
}

BUTTON_EVENT[dvTp,244]        // 612 Vol Up
{
    PUSH :
    { 
	STACK_VAR INTEGER audio_channel 
	audio_channel = 19
	Call 'AUDIO_UP'(audio_channel)
	SEND_LEVEL dvTp,5,AUDIA_GetBgLvl(audio_channel)
	Call 'MUTE_STATE_CHANGE'(audio_channel,246)
    }
}
BUTTON_EVENT[dvTp,245]        // 612 Vol Down
{
    PUSH :
    { 
	STACK_VAR INTEGER audio_channel 
	audio_channel = 19
	Call 'AUDIO_DOWN'(audio_channel)
	SEND_LEVEL dvTp,5,AUDIA_GetBgLvl(audio_channel)
	Call 'MUTE_STATE_CHANGE'(audio_channel,246)
    }
}
BUTTON_EVENT[dvTp,246]        // 612 Vol Mute
{
    PUSH :
    { 
	STACK_VAR INTEGER audio_channel 
	audio_channel = 19
	Call 'AUDIO_MUTE'(audio_channel)
	SEND_LEVEL dvTp,5,AUDIA_GetBgLvl(audio_channel)
	Call 'MUTE_STATE_CHANGE'(audio_channel,246)
    }
}

BUTTON_EVENT[dvTp,8]        //This is on the Splash page. Basically a big translucent button.
{
    Push:
    {
        On[Relay,PowerRelay]
	Call 'AUDIO_START'
	Call 'MUTE_STATE_CHANGE'(10,206)
	Call 'MUTE_STATE_CHANGE'(20,216)
	Call 'MUTE_STATE_CHANGE'(17,226)
	Call 'MUTE_STATE_CHANGE'(18,236)
	Call 'MUTE_STATE_CHANGE'(19,246)
    }
}
BUTTON_EVENT[dvTp,6]	//Stop the Shutdown sequence.
{
    Push:
    {
	TIMELINE_KILL(Tl1)
	SEND_COMMAND dvTp,"'PPOF-Shutdown Warning'"
    }
}
DEFINE_PROGRAM
If((time_to_hour(time) = 22)&&(time_to_minute(time) = 00)&&(nTimeBlock = 0))
{
    send_string 0:1:0,"'the time is ',time,13,10"
    nTimeBlock = 1		//Keeps this from running over and over for the whole minute.
    TIMELINE_CREATE(TL1, TimeArray, 61, TIMELINE_RELATIVE, TIMELINE_ONCE) 
    wait 620			//Need to wait until the minute is over.
	nTimeBlock = 0	
}

SEND_LEVEL dvTp,1,AUDIA_GetBgLvl(10)
SEND_LEVEL dvTp,3,AUDIA_GetBgLvl(17)
SEND_LEVEL dvTp,4,AUDIA_GetBgLvl(18)
SEND_LEVEL dvTp,5,AUDIA_GetBgLvl(19)
SEND_LEVEL dvTp,2,AUDIA_GetBgLvl(20)

//[dvTp,214] = (uAudiaVol[1].nVolRamp = AUDIA_VOL_UP)
//[dvTp,215] = (uAudiaVol[1].nVolRamp = AUDIA_VOL_DOWN)
//[dvTp,216] = (uAudiaVol[1].nMute)

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)

