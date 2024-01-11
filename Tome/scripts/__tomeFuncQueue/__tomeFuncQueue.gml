// If you found yourself here, go check out TabularElf's function_execute gist!
// https://gist.github.com/tabularelf/7b82e4b95588a811620ab4924a2bd54b

/// @param {real} timeInterval The number of frames between function calls
function __tome_funcQueue(_timeInterval) constructor {
	__timeInterval = _timeInterval;
	__timeSourceId = -1;
	__functions = [];
	
	/// @desc Adds a function to the queue
	/// @param {function} function The function to execute
	/// @param {array} arguments An array of arguments to pass into the function
	addFunction = function(_function, _arguments){
		var _functionStruct = {
			__function: _function,
			__arguments: _arguments
		};
		
		array_push(__functions, _functionStruct);	
	}
	
	/// @desc Starts the queue executing functions
	start = function(){
		__started = true;
		__timeSourceId = time_source_create(time_source_global, __timeInterval, time_source_units_frames, function(___functions){
			if (array_length(___functions) > 0){
				__tome_function_execute(___functions[0].__function, ___functions[0].__arguments);
				array_delete(___functions, 0, 1);
			}
		}, [__functions], -1);
		
		time_source_start(__timeSourceId);
	}
	
	/// @desc Stops the execution of functions in the queue
	stop = function(){
		if (time_source_exists(__timeSourceId)){
			time_source_destroy(__timeSourceId);
			__timeSourceId = -1;
		}
	}
}

/// @func __tome_function_execute( function/method, [arguments_in_array])
/// @desc Executes a runtime function, gml function or method, respecting method rules.
/// @param function/method
/// @param [arguments_in_array]
function __tome_function_execute(_funcMethod, _argsArray) {
	var _func = _funcMethod;
	var _args = !is_array(_argsArray) ? undefined : _argsArray;
	var _length = !is_array(_args) ? 0 : array_length(_args);
	
	switch(_length) {
		case 0: return _func();
		case 1: return _func(_args[0]);
		case 2: return _func(_args[0], _args[1]);
		case 3: return _func(_args[0], _args[1], _args[2]);
		case 4: return _func(_args[0], _args[1], _args[2], _args[3]);
		case 5: return _func(_args[0], _args[1], _args[2], _args[3], _args[4]);
		case 6: return _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5]);
		case 7: return _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6]);
		case 8: return _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7]);
		case 9: return _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8]);
		case 10: return _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8], _args[9]);
		case 11: return _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8], _args[9], _args[10]);
		case 12: return _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8], _args[9], _args[10], _args[11]);
		case 13: return _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8], _args[9], _args[10], _args[11], _args[12]);
		case 14: return _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8], _args[9], _args[10], _args[11], _args[12], _args[13]);
		case 15: return _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8], _args[9], _args[10], _args[11], _args[12], _args[13], _args[14]);
		case 16: return _func(_args[0], _args[1], _args[2], _args[3], _args[4], _args[5], _args[6], _args[7], _args[8], _args[9], _args[10], _args[11], _args[12], _args[13], _args[14], _args[15]);
		
		default: 
		// We'll call this only if we're executing more than necessary.
		var _self = self;
		
		if is_method(_func) {
			_self = method_get_self(_func);
			
			// We'll go back to self if it's undefined.
			if (_self == undefined) {
				_self = self;	
			}
			_func = method_get_index(_func);
		}
		
		// Use this switch statement to check against if it matches one of two infinite argument built in functions.
		switch(_func) {
			case array_insert: _func = __tome_func_array_insert; break;
			case ds_list_add: _func = __tome_func_ds_list_add; break;
			case array_push: _func = __tome_func_array_push; break;
		}
		
		with(_self) {
			return script_execute_ext(_func, _args);
		}
	}
}

function __tome_func_array_insert(_array) {
	var _length = argument_count-2;
	var _index = argument[1]-1;
	var _i = 1;
	array_copy(_array,_index+_length, _array, _index, _length);
	repeat(_length) {
		_array[@  ++_index] = argument[++_i];
	}
}

function __tome_func_ds_list_add(_list) {
	var _length = argument_count-1;
	var _i = 0;
	repeat(_length) {
		ds_list_add(_list, argument[++_i]);
	}
}

function __tome_func_array_push(_array) {
	var _length = argument_count-1;
	var _i = 0;
	repeat(_length) {
		array_push(_array, argument[++_i]);
	}
}