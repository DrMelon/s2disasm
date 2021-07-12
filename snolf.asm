; Standalone Snolf Module
; S2 ver (s2disasm naming convention)
; Hopefully this is nice and readable for the curious peeps.

; -- Snolf Main Function
SnolfMain:
	tst.b (Control_Locked).w ; Ensure that the controls are not locked (e.g, Snolf is in a cutscene.)
	bne.w	SkipSnolf ; If they are locked, skip Snolf logic.

    ; Accumulator & Flag logic.
	move.w 	#0,(SNOLF_Just_Swung).w ; Reset the Just_Swung flag.
	addi.w, #1,(SNOLF_Accumulator).w ; Begin incrementing the accumulator timer.
	cmpi.w, #512,(SNOLF_Accumulator).w ; Reset the accumulator timer if it exceeds 512.
	blo.s +
	move.w, #0,(SNOLF_Accumulator).w
+
	; Input Checking - is the player holding the A button to reset the shot?
	btst #button_A,(Ctrl_1_Held).w
	beq.s SnolfResetUnpressed ; If they are not holding the button, skip the following logic.
	
    ; Make the Reset Timer tick down.
	subi.w, #1,(SNOLF_Reset_Timer).w
	; Has the timer hit zero yet?
	cmpi.w, #1,(SNOLF_Reset_Timer).w
	bhi.s + ; If it hasn't, skip the following logic. 
	; If it has, Reset Snolf's position, then return here, continuing to the reset-unpressed logic.
	jsr	SnolfResetBall
	jmp SnolfResetUnpressed 
+
	jmp SnolfCheckForSwing


SnolfResetBall:
    ; Set Snolf's X and Y positions to the Shot Position.
    ; This moves him back to where the last shot was taken.
    move.w (SNOLF_Shot_PosX).w,d0
	move.w	d0,x_pos(a0)
	move.w	(SNOLF_Shot_PosY).w,d0
    move.w  d0,y_pos(a0)

    ; Stop Snolf's Velocity & Inertia/Groundspeed. This stops him moving away after a reset.
	move.w	#0,x_vel(a0)
	move.w	#0,y_vel(a0)
	move.w	#0,inertia(a0)

    ; Play a cool and funky noise when we teleport back!
	move.w	#SndID_Teleport,d0 
	jsr	(PlaySound).l

	rts

SnolfResetUnpressed:
    ; This code runs when either the A button is not pressed in SnolfMain or the reset logic has just run.
    ; All it does is reset the reset timer to 1.5 seconds (90 frames @ 60fps)
	move.w	#90,(SNOLF_Reset_Timer).w
	jmp SnolfCheckForSwing

SnolfCheckForSwing:
    ; Check to see if A, B, or C have been pressed.
	move.b 	(Ctrl_1_Press).w,d0 
	andi.b	#button_B|button_A|button_C,d0 
	bne.w	SnolfSwingPressed ; If they have been pressed, jump to the logic that handles a press.

SnolfSwingNotPressed:
    ; This runs when no swing button is pressed. 
	btst	#0,(SNOLF_StateFlag).w ; Which state are we in? Bit 0 of the state flag tells us if we have begun a swing or not.
	beq.w	SkipSnolf ; If we have not begun a swing yet, skip the following logic,
	move.w	x_pos(a0),(SNOLF_Shot_PosX).w ; Store Snolf's current world position (so that we can reset later.)
	move.w	y_pos(a0),(SNOLF_Shot_PosY).w
	move.w	(SNOLF_Accumulator).w,d0 ; Calculate the Sine of our accumulator timer so that we can get that smooth side-to-side / up-and-down motion.
	jsr		(CalcSine).l ; The CalcSine function puts the Sine into d0 and the Cosine into d1. This is important!
	btst	#1,(SNOLF_StateFlag).w ; Bit 1 of the state flag tells us if we are doing the horizontal or the vertical part of the swing.
	bne.s	SnolfVerticalSwing ; Skip to the vertical part of the swing logic if we're in that stage.

SnolfHorizontalSwing:
	; Put the calculated Sine value (shifted left by 4 bits / multiplied by 16)
    ; into the Meter X position. This affects both where the meter is drawn, and how hard the swing is left/right.
	asl.w  	#4,d0
	move.w	d0,(SNOLF_Meter_X).w
	jmp 	SkipSnolf	; Jump to the end of the Snolf logic; we don't want to go into the vertical stage straight from here.

SnolfVerticalSwing:
	; The vertical swing is a little different.
    ; The CalcSine function puts the Cosine of the calculation into d1, and then we add 255 to it to offset it.
    ; That's how the vertical shot meter only goes up; it doesn't let you aim downwards.
	addi.w	#255,d1
	asl.w	#3,d1
	neg.w	d1 ; We negate the meter position here, because otherwise it moves down instead of up.
	move.w	d1,(SNOLF_Meter_Y).w
	jmp		SkipSnolf

; The Skip function is simple. We just pretend like nothing happened and back out of the subroutine pointer.
SkipSnolf:
	rts

SnolfSwingPressed:
    ; If you pressed a button during the main button check, this is where you end up.
	move.w	inertia(a0),d0 ; We can't start a swing if Snolf is moving along the ground...
	cmpi.w  #1,(SNOLF_Force_Allow).w ; ... with the exception that if either the Force_Allow or Force_Next variables are set, we can!
	beq.s SnolfStartSwing
	cmpi.w  #1,(SNOLF_Force_Next).w
	beq.s SnolfStartSwing
	cmpi.w  #$0040,d0 ; This is the threshold speed at which you can start a swing - it's not a completely zero speed, which is why small slopes work.
	bhi.s	SnolfSwingNotPressed ; We just say you didn't press a button even if you did when the speed is too high.

SnolfStartSwing:
    ; First, test to see if we're already in swing mode.
	btst	#0,(SNOLF_StateFlag).w
	bne.w	SnolfAdvanceSwing
    ; We're just starting a fresh new swing.
	bclr	#1,(SNOLF_StateFlag).w ; Clear Horizontal/Vertical swing mode.
	move.w  #0,(SNOLF_Meter_X).w ; Set the strength meters to zero.
	move.w  #0,(SNOLF_Meter_Y).w 
	bset	#0,(SNOLF_StateFlag).w ; Engage swing mode!

	; We reset the accumulator here so that whenever you swing, the meter starts from a neutral position.
	move.w	#0,(SNOLF_Accumulator).w

    ; But if the player is facing left, we actually want to add 127 to it - to move the meter a quarter through its cycle.
    ; That puts it in the neutral position heading left!
	btst	#0,status(a0)
	beq.w	SnolfSkipAccumLeft
	move.w	#127,(SNOLF_Accumulator).w

SnolfSkipAccumLeft:
	; Since we're beginning a swing, we want to spawn the "Pip".
    ; The "pip" is the bit of the meter that moves around.
    bsr.w	SingleObjLoad
	move.b	#ObjID_SnolfMeterPip,id(a1) ; Load the Pip object.

	; We also want to spawn the "Meter". This is the part of the meter
    ; that does *not* move around.
    bsr.w	SingleObjLoad
	move.b	#ObjID_SnolfMeterH,id(a1) ; Load the Meter object.

    ; Play a sound effect to confirm the player's action.
	move.w	#SndID_Blip,d0
	jsr	(PlaySound).l
	jmp 	SnolfSwingNotPressed

SnolfAdvanceSwing:
	;If we're already in a swing, we want to advance it from the horizontal stage to the vertical stage
    ;Or, if we're in the vertical stage, we wanna launch that Snolfball!!
	btst	#1,(SNOLF_StateFlag).w
	bne.s	SnolfSwing ; Launch!

    ; Play a sound to confirm the player's action.
	move.w	#SndID_Blip,d0 
	jsr	(PlaySound).l
	
    ; We reset the accumulator again for the vertical stage. 
    ; It's reset to 127 as that's the bottom-most point of the cycle, so it rises up.
	move.w	#127,(SNOLF_Accumulator).w 

	; We set the Vertical state flag bit.
    ; Note: this is where we'd spawn a vertical meter sprite if we had those.
	bset	#1,(SNOLF_StateFlag).w
	jmp 	SnolfSwingNotPressed

SnolfSwing:
    ; This is the real meat & potatoes right here - the bit where Snolf is launched skywards!
	bclr	#0,(SNOLF_StateFlag).w ; We clear the swing status. We're no longer swinging anymore!
	move.w  #0,(SNOLF_Force_Next).w ; If the Force_Next flag was set, we clear it, as it is only temporary.

	; Set Snolf's X and Y velocity to be the meter's given strength.
	move.w	(SNOLF_Meter_Y).w,y_vel(a0)
	move.w	(SNOLF_Meter_X).w,x_vel(a0)

    ; We also force Snolf's inertia value up. This has a knock-on effect that helps the game understand that he's moving fast, and 
    ; releases him from certain platforms etc.
	move.w	#$400,inertia(a0)

    ; We force Snolf into a "jumping" state. Again, helping the game understand that he should now be airborne.
	bset	#1,status(a0)

    ; Reset horizontal/vertical mode.
	bclr	#1,(SNOLF_StateFlag).w

	; Add a swing to the swing counter!
	addi.w	#1,(SNOLF_Swings_Taken).w

    ; Set the just-swung flag.
	move.w 	#1,(SNOLF_Just_Swung).w

	; Play a cool launching soundeffect.
    move.w	#SndID_SpindashRelease,d0
	jsr	(PlaySound).l

    ; Tell the HUD it needs to update the count.
    ; It doesn't update every frame, because it would be a waste of processing time to keep rendering the same number when it hasn't changed.
	ori.b 	#1,(Update_HUD_rings).w

    ; End our snolfing journey.
	jmp		SnolfSwingNotPressed


; --------------- Additional helper routines.
; Horizontal Bouncing Subroutine; this is used whenever Snolf collides with a wall! 
; It's what gives him his rubbery, bouncy ball energy.
SnolfBounceHoriz:
	neg.w	x_vel(a0); Negate the X velocity,
	asr.w	#1,x_vel(a0); and half it! 
SnolfBounceHorizEnd:
    rts