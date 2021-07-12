; Snolf Object Code

; Meter "Pip"; this is the part of the meter that moves around.
ObjSnolfMeterPip:
    ; Here we load up the routine pointer.
    ; It's like a pointer to a function, which allows the meter to update, render, etc. like a game object in other engines.
    ; We first point to the "_Init" function, where we load sprite graphics and create a sprite object.
    ; The code pointed to by routine is executed by the main game loop as it iterates over instantiated objects.
	moveq	#0,d0
	move.b	routine(a0),d0
	move.w	ObjSnolfMeterPip_Index(pc, d0.w),d1
	jmp		ObjSnolfMeterPip_Index(pc,d1.w)

; This is the table of routines available. 
ObjSnolfMeterPip_Index: dc.w ObjSnolfMeterPip_Init-ObjSnolfMeterPip_Index; 0
	dc.w ObjSnolfMeterPip_Main-ObjSnolfMeterPip_Index; 2

ObjSnolfMeterPip_Init:
    ; On initialisation, we set the function pointer to point at index #2, the "_Main" function.
	addq.b	#2,routine(a0)
    ; Load the sprite mappings for the Ring sprite art tiles.
    move.l	#Obj25_MapUnc_12382,mappings(a0)
    ; Load the art from the Nemesis-compressed ring art.
    ; Set up its palette to use the first palette line (where the "main" palette is, which contains sonic, tails, and ring colours.)
	move.w	#make_art_tile(ArtTile_ArtNem_Ring,1,0),art_tile(a0)
    ; This is only used in Sonic 2; it fixes up the art for splitscreen. May be unused
	bsr.w	Adjust2PArtPointer
    ; Set the 3rd bit of the render_flags to instruct this sprite it's rendering with world coordinate (as opposed to screenspace)
	move.b	#4,render_flags(a0)
    ; Set the priority of the sprite; we want it in front of the player.
	move.w	#$80,priority(a0)
    ; Tell the game how big the sprite is. 8px.
	move.b	#8,width_pixels(a0)

ObjSnolfMeterPip_Main:
	; The pip's main function is responsible for updating the sprite's position
    ; so that it helps the player visualise the strength of their shot.
    ; It's also responsible for cleaning up the sprites and deleting them after launching Snolf.

	btst	#0,(SNOLF_StateFlag).w ; Check to see if we're in swing mode.
	beq.w	DeleteObject		; If we've left swing mode, we delete this object.
    move.w	(SNOLF_Shot_PosX).w,x_pos(a0) ; Set the X and Y position of the sprite to the shot origin position.
	move.w	(SNOLF_Shot_PosY).w,y_pos(a0)
	btst 	#1,(SNOLF_StateFlag).w ; Next, see if we're in Horizontal or Vertical mode.
	bne.s	ObjSnolfMeterPip_MoveYMode ; If we're in Vertical Mode, we adujst the position offset differently.

; Otherwise, we do the Horizontal Mode logic.
	subi.w	#32,y_pos(a0) ; We subtract 32 pixels from the y position to put it slightly above Snolf. 
	move.w	(SNOLF_Meter_X).w,d3 ; Now we copy the horizontal shot strength to offset the sprite's position.
	asr.w	#6, d3; The shot strength number is of course, way too big, so we bit-shift it down to scale the number down.
	add.w	d3,x_pos(a0) ; And we add it as an offset to the X position.
	jmp ObjSnolfMeterPip_MainMode

ObjSnolfMeterPip_MoveYMode:
	subi.w	#16,y_pos(a0) ; Move the pip's origin above Snolf a little.
	move.w	(SNOLF_Meter_Y).w,d3 ; Now we copy the vertical shot strength to offset the sprite, again.
	asr.w	#6, d3 ; The shot strength value is too big, and we bit shift it down to scale the number down. 
	add.w	d3,y_pos(a0) ; And add it as an offset to the Y position.

; Render the sprite.
ObjSnolfMeterPip_MainMode:
	bra.w	DisplaySprite
	rts


;-----------------------------------
; This is the part of the Meter that is stationary.
ObjSnolfMeter:
    ; Here we load up the routine pointer.
    ; It's like a pointer to a function, which allows the meter to update, render, etc. like a game object in other engines.
    ; We first point to the "_Init" function, where we load sprite graphics and create a sprite object.
    ; The code pointed to by routine is executed by the main game loop as it iterates over instantiated objects.
	moveq	#0,d0
	move.b	routine(a0),d0
	move.w	ObjSnolfMeter_Index(pc, d0.w),d1
	jmp		ObjSnolfMeter_Index(pc,d1.w)

ObjSnolfMeter_Index: dc.w ObjSnolfMeter_Init-ObjSnolfMeter_Index; 0
	dc.w ObjSnolfMeter_Main-ObjSnolfMeter_Index; 2

ObjSnolfMeter_Init:
    ; On initialisation, we set the function pointer to point at index #2, the "_Main" function.
	addq.b	#2,routine(a0)
    ; Load the sprite mappings for the Ring sprite art tiles.
    move.l	#Obj25_MapUnc_12382,mappings(a0)
    ; Load the art from the Nemesis-compressed ring art.
    ; Set up its palette to use the first palette line (where the "main" palette is, which contains sonic, tails, and ring colours.)
	move.w	#make_art_tile(ArtTile_ArtNem_Ring,1,0),art_tile(a0)
    ; This is only used in Sonic 2; it fixes up the art for splitscreen. May be unused
	bsr.w	Adjust2PArtPointer
    ; Set the 3rd bit of the render_flags to instruct this sprite it's rendering with world coordinate (as opposed to screenspace)
	move.b	#4,render_flags(a0)
    ; Set the priority of the sprite; we want it in front of the player.
	move.w	#$80,priority(a0)
    ; Tell the game how big the sprite is. 8px.
	move.b	#8,width_pixels(a0)


ObjSnolfMeter_Main:
	; The main function of the Meter renders the sprite at the shot position, with a little offset.
    ; It also deletes the object if we are no longer in swing mode.
	btst	#0,(SNOLF_StateFlag).w ;Check and see if we've left swing mode by launching Snolf.
	beq.w	DeleteObject		; Delete the sprite, if so.
    move.w	(SNOLF_Shot_PosX).w,x_pos(a0) ; Set the X and Y position of the sprite to the shot origin position.
	move.w	(SNOLF_Shot_PosY).w,y_pos(a0)
	btst 	#1,(SNOLF_StateFlag).w ; Check and see if we're in the Vertical Mode yet.
	bne.w	ObjSnolfMeterYMode		; If we are, we modify the offset differently.

	; Horizontal Offset
	subi.w	#32,y_pos(a0) ; Offset the sprite.
	jmp ObjSnolfMeterDisplay

ObjSnolfMeterYMode:
	subi.w	#16,y_pos(a0) ; Offset the sprite.

ObjSnolfMeterDisplay:
    bra.w   DisplaySprite
    rts