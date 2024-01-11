if (requestsCompleted >= (array_length(global.__tomeFileArray) + 9)){
	instance_destroy();
	//discord_log_console("Destroyed");
	__tomeTrace("All docs generated!");
	
	if (time_source_exists(global.__tomeInitTimeSource)){
		time_source_destroy(global.__tomeInitTimeSource);
		//DoLater(30, discord_log_console, "Time source Destroyed");
	}
}