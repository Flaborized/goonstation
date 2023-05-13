/obj/item/pocketwatch
	name = "T-MO Watch"
	desc = "A high-tech pocketwatch with an electronic ink display. Hooked into the station's monitoring systems, it can provide personnel with important financial information instantly from far away, and also tell the time with a faux-analog display. Time is money!"
	icon = 'icons/obj/objects.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	icon_state = "watch_closed"
	item_state = "pocketwatch"
	force = 0
	throwforce = 0
	w_class = W_CLASS_SMALL
	object_flags = NO_GHOSTCRITTER
	inventory_counter_enabled = TRUE
	var/current_clock_mode = "Time Keeping"
	var/hour_minute_divider = ":" //used to make the colon in the time blink like a clock display
	var/display_type = "clock" //used to show analog or screen displays on sprite
	var/text_to_display

	var/steps_taken = 0
	var/counting_steps = FALSE //true when in hands or pockets

	var/currently_timing = FALSE //used for timer mode
	var/timer_time = 0
	var/last_tick

	var/bell_counter = 0
	var/image/alert_overlay

	var/list/clock_modes = list("Time Keeping",
	"Total Station Budget Monitor",
	"Payroll Budget Monitor",
	"Cargo Budget Monitor",
	"Research Budget Monitor",
	"Total PTL Net Income",
	"Step Counter",
	"Timer")

	New()
		processing_items.Add(src)
		create_inventory_counter()
		if(istype(loc, /mob/)) //start counting steps if we spawn in the HoP's pocket!!
			start_counting_steps(loc)
		..()

	proc/format_time_text(var/timeValue as num)
		var/seconds = round((timeValue / 10) % 60)
		var/minutes = round(((timeValue / 10) - seconds) / 60)
		if (minutes < 10)
			minutes = "0[minutes]"
		if (seconds < 10)
			seconds = "0[seconds]"
		return "[minutes]:[seconds]"

	proc/start_counting_steps(mob/user)
		if(!counting_steps)
			RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(move_callback))
			counting_steps = TRUE

	proc/stop_counting_steps(mob/user)
		if(!counting_steps)
			UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
			counting_steps = FALSE

	proc/the_bell_has_been_rung()
		if(!alert_overlay)
			src.alert_overlay = image(src.icon)
			src.alert_overlay.appearance_flags = PIXEL_SCALE | RESET_COLOR | RESET_ALPHA
		src.alert_overlay.icon_state = "watch_alert_on"
		src.UpdateOverlays(src.alert_overlay, "alert")
		SPAWN(1 SECONDS)
			src.alert_overlay.icon_state = "watch_alert_off"
			src.UpdateOverlays(src.alert_overlay, "alert")

	dropped(mob/user)
		icon_state = "watch_closed"
		flick("watch_close_animation_[display_type]", src)
		if (isturf(src.loc))
			stop_counting_steps(user)
		..()

	attack_hand(mob/user)
		icon_state = "watch_open_[display_type]"
		flick("watch_open_animation_[display_type]", src)
		start_counting_steps(user)
		process()
		..()

	attack_self(mob/user as mob)
		var/new_mode = tgui_input_list(usr, "What mode should the watch be set to?", "Watch Mode", clock_modes)
		if (new_mode)
			if(new_mode == "Timer")
				last_tick = null
				timer_time = 0
			current_clock_mode = new_mode
			if(current_clock_mode == "Time Keeping" || "Timer")
				display_type = "clock"
			else
				display_type = "screen"
			icon_state = "watch_open_[display_type]"
			update_clock()

	move_callback(var/mob/living/M)
		if (src.loc == M)
			steps_taken += 1
			if(current_clock_mode == "Step Counter")
				update_clock()
		else
			stop_counting_steps(M)

	proc/update_clock()

		switch(current_clock_mode)
			if("Time Keeping")
				if(hour_minute_divider == ":")
					hour_minute_divider = " "
				else
					hour_minute_divider = ":"
				var/hour_display = text2num(time2text(TIME, "hh"))
				var/minute_display
				if(text2num(time2text(TIME, "mm")) < 10)
					minute_display = "0[text2num(time2text(TIME, "mm"))]" //to avoid the time being "12:3" ever
				else
					minute_display = text2num(time2text(TIME, "mm"))
				text_to_display = "[hour_display] [hour_minute_divider] [minute_display]"

			if("Total Station Budget Monitor")
				text_to_display = wagesystem.station_budget + wagesystem.research_budget + wagesystem.shipping_budget

			if("Payroll Budget Monitor")
				text_to_display = wagesystem.station_budget

			if("Cargo Budget Monitor")
				text_to_display = wagesystem.shipping_budget

			if("Research Budget Monitor")
				text_to_display = wagesystem.research_budget

			if("Total PTL Net Income")
				var/total_PTL_money = 0
				for(var/obj/machinery/power/pt_laser/PTL in machine_registry[MACHINES_POWER])
					total_PTL_money += PTL.lifetime_earnings
				text_to_display = total_PTL_money

			if("Step Counter")
				text_to_display = steps_taken

			if("Timer")
				if (src.last_tick)
					timer_time += TIME - src.last_tick
				src.last_tick = TIME
				text_to_display = format_time_text(timer_time)

		src.inventory_counter.update_text(text_to_display)


	process()
		update_clock()
		..()

