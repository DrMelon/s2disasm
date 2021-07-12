SNOLF_Meter_X: ds.b 2 			;2 bytes for x and y swing strength positions
SNOLF_Meter_Y: ds.b 2 			;
SNOLF_Swings_Taken: ds.b 2		; you'd be suprised how quickly swings build up. 255 aint gonna cut it!
SNOLF_StateFlag: ds.b 2		; 2 bytes, could be one, but padding needs to align anyway; bit 0 = snolf strike mode on/off, bit 1 = snolf strike mode X/Y, bit 2 = snolf mode override, bit 3 = is snolf mode cheat on
SNOLF_Shot_PosX: ds.b 2 			; 2 bytes; snolf bar position stuff
SNOLF_Shot_PosY: ds.b 2 			; 2 bytes
SNOLF_Reset_Timer: ds.b 2		; 2 bytes; timer for button-press to reset shot
SNOLF_Accumulator: ds.b 2		; 2 bytes - to be used instead of timer_frames for snolfing.
SNOLF_Swings_Total: ds.b 2		; 2 bytes - swing total over whole game. hopefully nobody takes more than 65535 swings...
SNOLF_Just_Swung: ds.b 2 	; 2 bytes - did we just swing? (could be 1 byte.)
SNOLF_Force_Allow: ds.b 2		; 2 bytes - force allow swings. for autoscroll sections or other difficult areas.
SNOLF_Force_Next: ds.b 2		; 2 bytes - same as snolf force allow, but only for 1 swing - good for strange obstacles like waterslides
SNOLF_Bounce_Flag: ds.b 2       ; 2 bytes - bounce bitfield for Snolf. Bit 0 is bouncing off/on (0 on, 1 off), Bit 1 is horizontal off/on, Bit 2 is vertical off/on