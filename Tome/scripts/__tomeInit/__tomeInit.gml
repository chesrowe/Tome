//Create the tome controller object to start tome generating
if (__TOME_CAN_RUN){
	global.__tomeInitTimeSource = time_source_create(time_source_global, 1, time_source_units_frames, __tome_init, [], 1);

	function __tome_init(){
		instance_create_depth(0, 0, 0, __tomeController);	
	}

	time_source_start(global.__tomeInitTimeSource);
}