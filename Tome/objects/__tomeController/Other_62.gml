// Execute request callbacks for HTTP requests sent 
var _callbackArraySize = array_length(requestCallbacks);
var _markForDeletionArray = [];
var _requestResponseId = async_load[? "id"];

if (_callbackArraySize > 0){
	//Loop through all of the requests and see which one is receving the response
	var _i = 0;
	
	repeat(_callbackArraySize){
		var _currentRequest = requestCallbacks[_i];
		
		if (_currentRequest.__requestId == _requestResponseId){
			var _requestResponse = __tome_http_response_parse();
			var _requestResponseResult =  __tome_http_response_result();
			var _responseIsError = _requestResponseResult == "";
			
			//Check the HTTP status code and act accordingly
			if (variable_struct_exists(_requestResponse, "http_status")){
				switch (_requestResponse.http_status){
					//Authorization failure 
					case 401:
						_responseIsError = true;
						__tomeTrace("Check that the infomation you provided in tomeConfig is correct.");
					break;
					
				}
			}
			
			if (typeof(_currentRequest.__callback) == "method" && !_responseIsError){		
				//If the response is not an error, execute the callback for that request	
				_currentRequest.__callback(_requestResponseResult, _currentRequest.__callbackMetadata);		
			}else if (_responseIsError){
				__tomeTrace("An error has occurred!");
			}
			
			array_push(_markForDeletionArray, _i);
			break;
		}
		
		_i++;
	}
		
	_i = 0;
		
	repeat(array_length(_markForDeletionArray)){
		array_delete(requestCallbacks, _markForDeletionArray[_i], 1);
		_i++;	
	}
}