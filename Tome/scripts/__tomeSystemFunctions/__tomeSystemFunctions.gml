//Non-userfacing functions/macros used to make the system work
#macro __TOME_CAN_RUN (TOME_ENABLED && (GM_build_type == "run") && ((os_type == os_windows) || (os_type == os_macosx) || (os_type == os_linux)))

#region __tome_http_request(endpoint, requestMethod, [callback], [callbackMetadata], [additionalHeaders])

/// @func __tome_http_request(endpoint, requestMethod, [callback], [callbackMetadata], [additionalHeaders])
/// @desc Sends an http request to the GitHub API using the standard application/json content type
/// @param {string} endpoint The endpoint to complete the request url
/// @param {string} requestMethod The type of http request being sent such as "GET", "POST", "PATCH", or "DELETE"
/// @param {struct} requestBody The struct containing the data for the request body. Use -1 when sending no body.
/// @param {function} callback The function to execute when a response to the request is received
/// @param {any} callbackMetadata Additional data to pass into the callback function
/// @param {struct} additionalHeaders Optional additional headers to include in the request
function __tome_http_request(_endpoint, _requestMethod, _requestBody, _callback = -1, _callbackMetadata = -1, _additionalHeaders = -1){
    // Prepare the url and headers
    var _baseUrl = "https://api.github.com/" + _endpoint;
    var _headers = ds_map_create();
    ds_map_add(_headers, "Content-Type", "application/json");
	
	// Use the token defined in the config unless TOME_USE_EXTERNAL_TOKEN is true
	var _authToken = TOME_GITHUB_AUTH_TOKEN;
	
	if (TOME_USE_EXTERNAL_TOKEN){
		var _tokenBuffer = buffer_load(TOME_EXTERNAL_TOKEN_PATH);		
		
		if (_tokenBuffer == -1){
			__tomeTrace("Cannot find local token file, check that the path specified by TOME_LOCAL_REPO_PATH is correct.");
			buffer_delete(_tokenBuffer);
			exit;
		}
		
		try {
			_authToken = string_replace_all(buffer_read(_tokenBuffer, buffer_text), "\\", "/");
		}catch(_readError){
			__tomeTrace("Cannot read local token file, make sure your token file is a text file with nothing but the token in it.");
			exit;			
		}
		
		buffer_delete(_tokenBuffer);
	}
	
    ds_map_add(_headers, "Authorization", "token " + _authToken);

    // Add any additional headers
    if (_additionalHeaders != -1){
        var _headerNames = ds_map_keys_to_array(_additionalHeaders);
        var _i = 0;
        repeat(array_length(_headerNames)){
            var _currentHeaderName = _headerNames[_i];
            ds_map_add(_headers, _currentHeaderName, _additionalHeaders[? _currentHeaderName]);
            _i++;
        }
    }

    // Send the HTTP request
    var _bodyJson = (_requestBody != -1) ? json_stringify(_requestBody) : "";
    var _requestId = http_request(_baseUrl, _requestMethod, _headers, _bodyJson);

    // Handle the response callback
    if (_callback != -1) {
        __tome_http_add_request_to_sent(_requestId, _callback, _callbackMetadata);
    }

    // Cleanup
    ds_map_destroy(_headers);
}

#endregion

#region __tome_http_response_parse()

/// @desc Parses the async_load map in a HTTP async event into a struct or array. Used in callback execution
/// @return struct or array
function __tome_http_response_parse(){
	return json_parse(json_encode(async_load));	
}

#endregion

#region __tome_http_response_result()

/// @desc Parses the async_load map's "result" key in a HTTP async event which is typically the data you will be working with
/// @return {Struct | array}
function __tome_http_response_result(){
	var _dataStruct = json_parse(json_encode(async_load));
	
	if (variable_struct_exists(_dataStruct, "result")){
		try{
			return json_parse(_dataStruct.result);	
		}catch(_error){
			return _dataStruct.result;	
		}
	}else{
		return {};	
	}
}

#endregion

#region __tome_http_add_request_to_sent(requestId,[callback])

/// @func __tome_http_add_request_to_sent(requestId,[callback])
/// @desc Adds a new http request to the requestCallbacks array in the Tome controller object
/// @param {real} requestId The id returned by http_request() 
/// @param {function} callback Optional callback function to execute when a response to the request is received
/// @param {function} callbackMetadata Optional additional data to pass into the callback function
function __tome_http_add_request_to_sent(_requestId, _callback = -1, _callbackMetadata = -1){
	var _request = new __tomeHttpRequest(_requestId, _callback, _callbackMetadata);
	array_push(__tomeController.requestCallbacks, _request);
}

#endregion

#region __tome_http_update_file(filePath, fileContent)

/// @desc Updates the given file in the doc repo with the given file contents
/// @param {string} filePath The path of the file within the repo
/// @param {string} fileContents The file contents of the file being sent
function __tome_http_update_file(_filePath, _fileContent){
	var _encodedFileContent = base64_encode(_fileContent);

	var _onDiskSha = __tome_generate_file_sha(_fileContent);
	
	// Callback function to handle the response
	var  _sendFileUpdateRequest = function(_response, _metadata) {    
		var _fileSha = "";
		
		var _responseIsBlank = true;
		
		if (is_struct(_response)){
			_responseIsBlank = variable_struct_names_count(_response) < 1
		}
		
		if (_response[$ "message"] != "Not Found" && !_responseIsBlank) {
	        __tomeTrace(string("File exists: {0} SHA: {1}", _metadata.__filePath, _response.sha), true);
			_fileSha = _response.sha;
	    } else {
	        __tomeTrace(string("File: `{0}` does not exist. Creating new file.", _metadata.__filePath), true);
	    }
			
		//Update/Create the file
		var _endpoint = "repos/" + TOME_GITHUB_USERNAME + "/" + TOME_GITHUB_REPO_NAME + "/contents/" + _metadata.__filePath + "?ref=" + TOME_GITHUB_REPO_BRANCH;;

		// Build the request body
		var _requestBody = {
			message: string("Update {0}", _metadata.__filePath),
			content: _metadata.__fileContent,
		};
			
		//If the file already exists, add its sha to the request body
		if (_fileSha != ""){
			_requestBody[$ "sha"] = _fileSha;	
		}
				
		var _responseCallback = function(_response, _metadata){
			var _fileCommited = _response[$ "commit"] != undefined;
			__tomeController.requestsCompleted++;

			if (_fileCommited){
				__tomeTrace(_metadata.__filePath + " commited!", true);	
			}else{
				__tomeTrace(_metadata.__filePath + " could NOT commit!", true);
				//discord_log_console(_metadata.__filePath + " could NOT commit!");
			}
		}
		
		if (_metadata.__onDiskSha != _fileSha){
			__tome_http_request(_endpoint, "PUT", _requestBody,  _responseCallback, {__filePath: _metadata.__filePath});
		}else{
			__tomeTrace(string("File: `{0}` not changed. No need to commit.", _metadata.__filePath), true);
		}
	}
	
	__tome_http_get_file_info(_filePath, _sendFileUpdateRequest, {__filePath: _filePath, __fileContent: _encodedFileContent, __onDiskSha: _onDiskSha});		
}

#endregion

#region __tome_http_get_file_info(authToken, owner, repo, filePath, [branch], [callback])

/// @func __tome_http_get_file_info(authToken, owner, repo, filePath, [branch], [callback])
/// @desc Returns info about a file in a repo (like whether or not it exists, and it's SHA if it does)
/// @param {string} filePath The path to the file in question
/// @param {function} [callback] The function to execute when a response is received
/// @param {any} [callbackMetadata] Additional data to pass into the callback function
function __tome_http_get_file_info(_filePath,  _callback = -1, _callbackMetadata = -1) {
    var _endpoint = "repos/" + TOME_GITHUB_USERNAME + "/" + TOME_GITHUB_REPO_NAME + "/contents/" + _filePath + "?ref=" + TOME_GITHUB_REPO_BRANCH;
    __tome_http_request(_endpoint, "GET", -1, _callback, _callbackMetadata);
}

#endregion

#region __tomeHttpRequest(id, callback = -1, callBackMetaData = -1) *constructor*

/// @desc Created for each new http request made by tome 
/// @param {real} id number returned by http_request()
/// @param {function} callback A function to execute once a response is received from the request
function __tomeHttpRequest(_id, _callback = -1, _callBackMetaData = -1) constructor {
	__requestId = _id;
	__callback = _callback;
	__callbackMetadata = _callBackMetaData;
}

#endregion

function __tome_local_update_file(_filePath, _fileContent){
	var _fullFilePath = TOME_LOCAL_REPO_PATH + _filePath;
	var _fileBuffer;
	
	if (is_string(_fileContent)){
		_fileBuffer = buffer_create(0, buffer_grow, 1);
	
		buffer_write(_fileBuffer, buffer_text, _fileContent);
	}else{
		_fileBuffer = _fileContent;	
	}
	buffer_save(_fileBuffer, _fullFilePath);
	buffer_delete(_fileBuffer);
	
	__tomeTrace("Local repo file updated: " + _filePath);
	__tomeController.requestsCompleted++;
}

#region __tomeTrace(text)

/// @Desc Outputs a message to the console prefixed with "Tome:"
/// @param {string} text The message to display in the console
/// @param {string} [verboseOnly] Whether the message should only be displayed if `TOME_VERBOSE` is enabled or not
function __tomeTrace(_text, _verboseOnly = false){
	if (_verboseOnly && TOME_VERBOSE){
		show_debug_message("Tome: " + string(_text));	
	}
	
	if (!_verboseOnly){
		show_debug_message("Tome: " + string(_text));			
	}
}

#endregion

#region __tome_generate_docs()

/// @func __tome_generate_docs()
/// @desc Parses all files added via `tome_add_` functions and generates documentions for the files.  
///              Then it adds them to the repo path specified with the macro `TOME_REPO_PATH`
function __tome_generate_docs(){
	
	// Check for duplicate files, because someone may accidentally add files multiple times.
	
	for (var _fileIndex = 0; _fileIndex < array_length(global.__tomeSlugArray); _fileIndex++){
		for (var _checkIndex = _fileIndex; _checkIndex < array_length(global.__tomeSlugArray); _checkIndex++){
			if (_checkIndex != _fileIndex){
				if (global.__tomeSlugArray[_checkIndex] == global.__tomeSlugArray[_fileIndex]){
					array_delete(global.__tomeSlugArray, _checkIndex, 1);
					_checkIndex--;	
				}
			}
		}
	}
	
	for (var _fileIndex = 0; _fileIndex < array_length(global.__tomeFileArray); _fileIndex++){
		for (var _checkIndex = _fileIndex; _checkIndex < array_length(global.__tomeFileArray); _checkIndex++){
			if (_checkIndex != _fileIndex){
				if (global.__tomeFileArray[_checkIndex] == global.__tomeFileArray[_fileIndex]){
					array_delete(global.__tomeFileArray, _checkIndex, 1);
					_checkIndex--;	
				}
			}
		}
	}
	
	var _slugIndex = 0;
	repeat (array_length(global.__tomeSlugArray)){
		__tome_parse_markdown_slugs(global.__tomeSlugArray[_slugIndex]);
		_slugIndex++;	
	}
	
	//Holds category/title pairs
	var _categories = {
		none: []	
	}
	
	//Create queue for updating the repo files
	var _updateRate = (TOME_LOCAL_REPO_MODE) ? 1 : 60;
	
	var _fileUpdateQueue = new __tome_funcQueue(_updateRate);
	
	var _updateFunction = (TOME_LOCAL_REPO_MODE) ? __tome_local_update_file : __tome_http_update_file;
	
	//Add basic docsify files
	var configFileContents = __tome_file_text_read_all(__tome_file_project_get_directory() +  "datafiles/Tome/config.js");
	_fileUpdateQueue.addFunction(_updateFunction, [TOME_GITHUB_REPO_DOC_DIRECTORY + "config.js", configFileContents]);
	
	var _indexFileContents = __tome_file_text_read_all(__tome_file_project_get_directory() +  "datafiles/Tome/index.html");
	_fileUpdateQueue.addFunction(_updateFunction, [TOME_GITHUB_REPO_DOC_DIRECTORY + "index.html", _indexFileContents]);
	
	var _codeThemeFileContents = __tome_file_text_read_all(__tome_file_project_get_directory() +  "datafiles/Tome/assets/codeTheme.css");
	_fileUpdateQueue.addFunction(_updateFunction, [TOME_GITHUB_REPO_DOC_DIRECTORY + "assets/codeTheme.css", _codeThemeFileContents]);
	
	var _customThemeFileContents = __tome_file_text_read_all(__tome_file_project_get_directory() +  "datafiles/Tome/assets/customTheme.css");
	_fileUpdateQueue.addFunction(_updateFunction, [TOME_GITHUB_REPO_DOC_DIRECTORY + "assets/customTheme.css", _customThemeFileContents]);
	
	var _iconFileContents = __tome_file_bin_read_all(__tome_file_project_get_directory() +  "datafiles/Tome/assets/docsIcon.png");
	_fileUpdateQueue.addFunction(_updateFunction, [TOME_GITHUB_REPO_DOC_DIRECTORY + "assets/docsIcon.png", _iconFileContents]);
	
	_fileUpdateQueue.addFunction(_updateFunction, [TOME_GITHUB_REPO_DOC_DIRECTORY + ".nojekyll", ""]);

	//Update homepage 
	_fileUpdateQueue.addFunction(_updateFunction, [__tome_file_get_final_doc_path() + "README.md", global.__tomeHomepage]);

	var _i = 0;
	var _functionCallDelay = 15;
	var _categoriesNames = array_create(0);
	
	//Parse each file and add it to the repo
	repeat (array_length(global.__tomeFileArray)){
		//Parse file and get results
		var _currentPath = global.__tomeFileArray[_i];
		var _fileExtension = __tome_file_get_extension(_currentPath);
		var _docStruct = _fileExtension == "gml" ? __tome_parse_script(_currentPath) : __tome_parse_markdown(_currentPath);
		
		//Push the docs to the repo
		var _fullFilePath =  string("{0}{1}.md", __tome_file_get_final_doc_path(), string_replace_all(_docStruct.title, " ", "-"))
		_fileUpdateQueue.addFunction(_updateFunction, [_fullFilePath, _docStruct.markdown]);
		
		//Add this file's category to the _categories struct
		if (_docStruct.category == ""){
			array_push(_categories.none, _docStruct.title);
		}else{
			if (variable_struct_exists(_categories, _docStruct.category)){
				array_push(_categories[$ _docStruct.category], _docStruct.title);
			}else{
				array_push(_categoriesNames, _docStruct.category);
				_categories[$ _docStruct.category] = [_docStruct.title];
			}
		}
		
		_i++;
	}
	
	//Sidebar
	
	//Add additional items to the sidebar
	_i = 0;

	repeat(array_length(global.__tomeAdditionalSidebarItemsArray)){
		var _currentSidebarItem = global.__tomeAdditionalSidebarItemsArray[_i];

		//Add this file's category to the _categories struct
		if (_currentSidebarItem.category == ""){
			array_push(_categories.none, _currentSidebarItem.title);
		}else{
			if (variable_struct_exists(_categories, _currentSidebarItem.category)){
				array_push(_categories[$ _currentSidebarItem.category], {title: _currentSidebarItem.title, link: _currentSidebarItem.link});
			}else{
				array_push(_categoriesNames, _currentSidebarItem.category);
				_categories[$ _currentSidebarItem.category] = [{title: _currentSidebarItem.title, link: _currentSidebarItem.link}];
			}
		}
		
		_i++;
	}
	
	var _sideBarMarkdownString = "";
	_sideBarMarkdownString += "-    [Home](README)\n\n---\n\n"
	
	
	var _a = 0;
	
	repeat(array_length(_categoriesNames)){
		var _currentCategory = _categoriesNames[_a];
		
		if (_currentCategory != "none"){
			_sideBarMarkdownString += string("**{0}**\n\n", _currentCategory);			
		}
		
		var _b = 0; 
		var _categoryArrayLength = array_length(_categories[$ _currentCategory]);
		
		repeat(_categoryArrayLength){
			var _currentCategoryArray = _categories[$ _currentCategory];
			
			if (is_struct(_currentCategoryArray[_b])){
				var _currentPageTitle = _currentCategoryArray[_b].title;
				var _currentPageLink = _currentCategoryArray[_b].link;
				_sideBarMarkdownString += string("-    [{0}]({1})\n", _currentPageTitle, _currentPageLink);
			
				if (_b == (_categoryArrayLength - 1)){
					_sideBarMarkdownString += "\n---\n\n";	
				}
			}else{
				var _currentPageTitle = _currentCategoryArray[_b];
				var _currentPageFileName = string_replace_all( _currentPageTitle, " ", "-");
				_sideBarMarkdownString += string("-    [{0}]({1})\n", _currentPageTitle, _currentPageFileName);
			
				if (_b == (_categoryArrayLength - 1)){
					_sideBarMarkdownString += "\n---\n\n";	
				}
			}
			_b++;
		}
		
		_a++;
	}

	//Navbar links
	var _navbarMarkdownString = "";

	_i = 0;

	repeat(array_length(global.__tomeNavbarItemsArray)){
		var _currentNavbarItem = global.__tomeNavbarItemsArray[_i];
		_navbarMarkdownString += string("-    [{0}]({1})\n", _currentNavbarItem.name, _currentNavbarItem.link);
		_i++;
	}
		
	_fileUpdateQueue.addFunction(_updateFunction, [__tome_file_get_final_doc_path() + "_navbar.md", _navbarMarkdownString]);
	_fileUpdateQueue.addFunction(_updateFunction, [__tome_file_get_final_doc_path() + "_sidebar.md", _sideBarMarkdownString]);
	_fileUpdateQueue.start();
}

#endregion

#region __tome_parse_script(filepath)
/// @desc Parses a GML file and generates markdown documentation.
/// @param {string} filepath Path to the GML file.
/// @returns {struct} Struct containing the markdown text, title, and category
function __tome_parse_script(_filepath) {
    var _file = file_text_open_read(_filepath);
	var _markdown = "";
	var _category = "";
	var _title = "";
	
    if (_file == -1) {
        __tomeTrace("Failed to open file: " + _filepath);
		return {
			markdown: _markdown,
			category: _category,
			title: _title
		};
    }
	
	var _textBoxStarted = false;
	var _inTextBlock = false;
	var _descStarted = false;
	var _inDesc = false;
	var _constructorStarted = false;
	var _inConstructor = false;
	var _funcStarted = false;
	var _inFunc = false;
	var _foundReturn = false;
	var _tableStarted = false;
	var _inTable = false;
	var _codeBlockStarted = false;
	var _inCodeBlock = false;
	var _ignoring = false;

    //Loop through each line of the text file
	while (!file_text_eof(_file)) {
		var _lineString = file_text_readln(_file);
		
		/// Added removal of #region tags as the line may not always begin with "///" but may begin with "#region ///"
		if (string_starts_with(string_trim_start(_lineString), "#region")){
			_lineString = string_replace(_lineString, "#region", "");
		}
		
		
		//If the line has text to parse, it will start with "///"
		if (string_starts_with(string_trim_start(_lineString), "///")){
			_lineString = string_replace(_lineString, "///", "");
			
			// Right now I only care about indention if it's a code block or text block
			if (!_inCodeBlock && !_inTextBlock){
				_lineString = string_trim(_lineString);	
			}

			if (_inDesc){
				_lineString = __tome_string_trim_starting_whitespace(_lineString, 2);
			}
			
			//If the line contains a tag 
			if (string_count("@", _lineString) > 0){
				_lineString = string_trim(_lineString);
				
				//var _splitString = string_split_ext(_lineString, [" ", "	"]);
				var _splitString = __tome_string_split_spaces_tabs(_lineString);
				var _tagType = _splitString[0];
				var _tagContent = string_trim(string_replace(_lineString, _tagType, ""));
				
				if (_tagType == "@ignore"){
					_ignoring = _tagContent == "true" || _tagContent == "True" || _tagContent == "TRUE";
				}
				
				if (!_ignoring){
					switch(_tagType){
						case "@title":
							_markdown += "# " + _tagContent + "\n";		
							_title = _tagContent;
							_inTextBlock = false;
						break;
					
						case "@function":
						case "@func":
							_tableStarted = false;
							_inTable = false;
							_foundReturn = false;
							_markdown += string("\n## `{0}`", _tagContent);		
							_inTextBlock = false;
						
							if (_inConstructor){
								_markdown += " (*constructor*)";		
							}else{
								_markdown += " → {rv}";	
							}
						
							_markdown += "\n";
						
							_inFunc = true;
						break;
					
						case "@method":
							if (_inConstructor){
								_markdown += "\n**Methods**";	
								_inConstructor = false;
							}
						
							_markdown += string("\n### `.{0}` → {rv}\n" , _tagContent);		
							_inTextBlock = false;
							_tableStarted = false;
							_inTable = false;
							_inFunc = true;
						break;
						
						case "@slug":
						case "@insert":
							for (var _slugIndex = 0; _slugIndex < array_length(__tomeController.slugs); _slugIndex++){
								if (_tagContent == __tomeController.slugs[_slugIndex][0]){
									_markdown +=  "\n" + __tomeController.slugs[_slugIndex][1] + "\n";
								}
							}			
						break;
						
						case "@constructor":
							_inConstructor = true;
							_tableStarted = false;
						break;
				
						case "@desc":
						case "@description":
							if (_inFunc){
								_markdown += _tagContent + "\n";			
								_inDesc = true;
							}
						
							_tableStarted = false;
							_inTable = false;
						break; 
					
						case "@text":
							_markdown += "\n" + _tagContent + "\n";			
							_inTextBlock = true;
							_inCodeBlock = false;
							_tableStarted = false;
							_inDesc = false;
							_inTable = false;
							_tableStarted = false;
						break;
					
					
						case "@code":
						case "@example":
							_markdown += "```gml\n";			
							_inCodeBlock = true;
							_tableStarted = false;
							_inTextBlock = false;
							_inTable = false;
						break;
					
						case "@param":
						case "@parameter":
						case "@arg":
						case "@argument":
							if (_inFunc){
								if (!_tableStarted){
									_markdown += "\n| Parameter | Datatype  | Purpose |\n";
									_markdown += "|-----------|-----------|---------|\n";				
									_tableStarted = true;
									_inTable = true;
								}
						
								_inDesc = false;
								_inTextBlock = false;
						
								var _paramDataTypeUntrimed = _splitString[1];
								var _paramDataType = string_delete(_paramDataTypeUntrimed, 1, 1);
								_paramDataType = string_delete(_paramDataType, string_pos("}", _paramDataType), 1);
								var _paramName = _splitString[2];
								var _paramInfo = string_replace(_tagContent, _splitString[1], "");
								_paramInfo = string_replace(_paramInfo, _splitString[2], "");
								_paramInfo = string_trim(_paramInfo);
						
								_markdown += string("|`{0}` |{1} |{2} |\n", _paramName, _paramDataType, _paramInfo);
							}
						break;
					
						case "@returns":
						case "@return":
							if (_inFunc){
								_foundReturn = true;
								var _returnInfo = string_replace(_tagContent, _splitString[1], "");
								_returnInfo = string_trim(_returnInfo);	
						
								var _returnDataTypeUntrimed = _splitString[1];
								var _returnDataType = string_delete(_returnDataTypeUntrimed, 1, 1);
								_returnDataType = string_delete(_returnDataType, string_pos("}", _returnDataType), 1);
								_returnDataType = __tome_parse_data_type(_returnDataType);
						
								var _returnStyle = (_returnDataType == "undefined") ?  "`{0}`" : "*{0}*" ;
						
								_markdown = string_replace(_markdown, "{rv}", string(_returnStyle, _returnDataType));
						
								if (_returnInfo != ""){
									_markdown += string("\n**Returns:** {0}\n", _returnInfo);
								}
							
								_inTable = false;
							}
						break;
					
						case "@category":
							_category = _tagContent;
						break;
					}
				}
			}else{
				//If there is no tag but we are in a function, description, or text block, add the line to the markdown
				if (_inTextBlock){
					_markdown += _lineString;	
				}
				
				if (_inDesc){
					_markdown += _lineString + "\n";	
				}
				
				if (_inCodeBlock){
					_markdown += _lineString;	
				}
				
				if (_inTable){
					_markdown += "\n";	
				}
			}
		}else{
			if (!_foundReturn){
				_markdown = string_replace(_markdown, "{rv}", "`undefined`");		
			}
			
			if (_inCodeBlock){
				_markdown += "```\n";	
			}
			
			if (_inTable){
				_markdown += "\n";	
			}
			
			_inCodeBlock = false;
			_inFunc = false;	
			_inTextBlock = false;
			_inDesc = false;
		}
    }

    file_text_close(_file);
    return {
		markdown: _markdown,
		category: _category,
		title: _title
	}
}

#endregion

#region __tome_parse_markdown(_filePath)
/// @desc Parses a markdown file and returns a struct containing the markdown text, title, and category. Unlike the script parser, this function only parses the tags @title and @category, all other text is just added to the markdown.
/// @param {string} _filePath The path to the file
/// @returns {struct} Struct containing the markdown text, title, and category
function __tome_parse_markdown(_filePath){
	var _file = file_text_open_read(_filePath);
	var _markdown = "";
	var _category = "";
	var _title = "";
	var _titleFound = false;
	var _categoryFound = false;
	
	if (_file == -1) {
		__tomeTrace("Failed to open file: " + _filePath);
		return {
			markdown: _markdown,
			category: _category,
			title: _title
		};
	}
	
	while (!file_text_eof(_file)) {
		var _lineStringUntrimmed = file_text_readln(_file);
		
		if (string_starts_with(_lineStringUntrimmed, "///")){
			var _lineString = string_trim(_lineStringUntrimmed);
			_lineString = string_replace(_lineStringUntrimmed, "///", "");
			
			if (string_count("@", _lineString) > 0){
				var _splitString = string_split_ext(_lineString, [" ", "	"]);
				var _tagType = _splitString[1];
				var _tagContent = string_trim(string_replace(_lineString, _tagType, ""));
			
				switch(_tagType){
					case "@title":
						if (!_titleFound){
							_markdown += "# " + _tagContent + "\n";		
							_title = _tagContent;
							_titleFound = true;
						}else{
							_markdown += _lineStringUntrimmed;		
						}
					break;
					
					case "@category":
						if (!_categoryFound){
							_category = _tagContent;
						}else{
							_markdown += _lineStringUntrimmed;	
						}
					break;
					
					case "@slug":
					case "@insert":
						for (var _slugIndex = 0; _slugIndex < array_length(__tomeController.slugs); _slugIndex++){
							if (_tagContent == __tomeController.slugs[_slugIndex][0]){
								_markdown +=  "\n" + __tomeController.slugs[_slugIndex][1] + "\n";
							}
						}			
					break;
					
					default:
						_markdown += _lineStringUntrimmed;	
					break;
				}
			}else{
				_markdown += _lineStringUntrimmed;		
			}
		}else{
			_markdown += _lineStringUntrimmed;	
		}
	}
	
	file_text_close(_file);
	return {
		markdown: _markdown,
		category: _category,
		title: _title
	}
}

#endregion

#region __tome_parse_markdown_slugs(_filePath)
/// @desc Parses a markdown file and returns a struct containing the markdown text, title, and category. Unlike the script parser, this function only parses the tags @title and @category, all other text is just added to the markdown.
/// @param {string} _filePath The path to the file
/// @returns {null}
function __tome_parse_markdown_slugs(_filePath){
	var _file = file_text_open_read(_filePath);
	var _inSlug = false;
	var _markdown = "";
	var _slugName = "";

	if (_file == -1) {
		__tomeTrace("Failed to open file: " + _filePath);
	}else{
		while (!file_text_eof(_file)) {
			var _lineStringUntrimmed = file_text_readln(_file);
		
			if (string_starts_with(_lineStringUntrimmed, "///")){
				var _lineString = string_trim(_lineStringUntrimmed);
				_lineString = string_replace(_lineStringUntrimmed, "///", "");
			
				if (string_count("@", _lineString) > 0){
					var _splitString = string_split_ext(_lineString, [" ", "	"]);
					var _tagType = _splitString[1];
					var _tagContent = string_trim(string_replace(_lineString, _tagType, ""));
			
					switch(_tagType){
						case "@slug":
						case "@insert":
							if (_inSlug){
								if (_markdown != ""){
									array_push(__tomeController.slugs, [_slugName, _markdown]);	
								}
							}
						
							_inSlug = true;
						
							_slugName = _tagContent;
							_markdown = "";
						
						
							var _slugIndex = 0;
							repeat(array_length(__tomeController.slugs)){
								if (_slugName == __tomeController.slugs[_slugIndex][0]){
									_inSlug = false;
									break;
								}
								_slugIndex++;
							}
						break;
						
						case "@ignore":
							_markdown += _tagContent + "\n";
						break;
					
						default:
							_markdown += _lineStringUntrimmed;
						break;
					}
				}else{
					_markdown += _lineStringUntrimmed;		
				}
			}else{
				_markdown += _lineStringUntrimmed;	
			}
		}
		
		if (_inSlug){
			if (_markdown != ""){
				array_push(__tomeController.slugs, [_slugName, _markdown]);	
			}
		}
	}
}

#endregion

#region __tome_file_project_get_directory()

/// @func __tome_file_project_get_directory()
/// @desc If the game is ran from the IDE, this will return the file path to the game's project file with the ending "/"
function __tome_file_project_get_directory(){
	var _originalPath = filename_dir(GM_project_filename) + "\\";
	var _fixedPath = string_replace_all(_originalPath, "\\", "/");
	
	return string_trim(_fixedPath);
}

function __tome_parse_data_type(_dataTypeString){
	return string_replace_all(_dataTypeString, "|", " <span style=\"color: red;\"> *or* </span> ");	
}

#endregion

#region __tome_file_get_final_doc_path()

/// @desc Gets the actual filepath within the repo where the .md files will be pushed
function  __tome_file_get_final_doc_path() { 
	return TOME_GITHUB_REPO_DOC_DIRECTORY + global.__tomeLatestDocVersion + "/";
}

#endregion

#region __tome_file_get_extension(_filePath)

/// @desc Returns the file extension of the given file path
/// @param {string} _filePath The path to the file
/// @return {string} The file extension
function __tome_file_get_extension(_filePath){
	var _splitPath = string_split(_filePath, ".");
	return _splitPath[array_length(_splitPath) - 1];
}

#endregion

#region __tome_file_text_read_all(_filePath)

/// @desc Loads a text file and reads its entire contents as a string
/// @param {string} filePath The path to the text file to read
function __tome_file_text_read_all(_filePath){
	var fileBuffer = buffer_load(_filePath);
	var _fileContents = buffer_read(fileBuffer, buffer_string);
	buffer_delete(fileBuffer);
	return _fileContents;
}

#endregion

#region __tome_file_bin_read_all(_filePath)

/// @desc Loads a binary file
/// @param {string} filePath The path to the binary file to read
function __tome_file_bin_read_all(_filePath){
	var fileBuffer = buffer_load(_filePath);
	return fileBuffer;
}

#endregion

#region __tome_file_update_config(_propertyName, _propertyValue)

/// @desc Updates the config file with the given property name and value
/// @param {string} propertyName The name of the property to update
/// @param {any} propertyValue The value to set the property to
function __tome_file_update_config(_propertyName, _propertyValue){
	var _configFileContents = __tome_file_text_read_all(__tome_file_project_get_directory() +  "datafiles/Tome/config.js");
	// Remove the extra JS crap so we can parse it as JSON
	// This is dirty af and is a terrible solution but it works
	_configFileContents = string_replace(_configFileContents, "const config = ", "");
	_configFileContents = string_replace_all(_configFileContents, ";", "");
	_configFileContents = string_replace_all(_configFileContents, "\r", "\n");
	_configFileContents = string_replace_all(_configFileContents, "\n\n", "\n");
	_configFileContents = string_replace_all(_configFileContents, "name", "\"name\"");
	_configFileContents = string_replace_all(_configFileContents, "description", "\"description\"");
	_configFileContents = string_replace_all(_configFileContents, "latestVersion", "\"latestVersion\"");
	_configFileContents = string_replace_all(_configFileContents, "otherVersions", "\"otherVersions\"");
	_configFileContents = string_replace_all(_configFileContents, "favicon", "\"favicon\"");
	_configFileContents = string_replace_all(_configFileContents, "themeColor", "\"themeColor\"");
	var _configStruct = json_parse(_configFileContents);
	
	//If the latest version is being updated, add the old version name to the otherVersions property
	if (_propertyName == "latestVersion"){
		if (_configStruct.latestVersion != _propertyValue){
			array_push(_configStruct.otherVersions, _configStruct.latestVersion);	
		}
	}
	
	_configStruct[$ _propertyName] = _propertyValue;
	
	//Now that the config is updated, let's convert it back into JS
	var _updatedJson = json_stringify(_configStruct);
	_updatedJson = string_replace_all(_updatedJson, "\"name\"", "    name");
	_updatedJson = string_replace_all(_updatedJson, "\"description\"", "    description");
	_updatedJson = string_replace_all(_updatedJson, "\"latestVersion\"", "    latestVersion");
	_updatedJson = string_replace_all(_updatedJson, "\"otherVersions\"", "    otherVersions");
	_updatedJson = string_replace_all(_updatedJson, "\"favicon\"", "    favicon");
	_updatedJson = string_replace_all(_updatedJson, "\"themeColor\"", "    themeColor");
	_updatedJson = string_replace_all(_updatedJson, ",  ", ",\n");
	_updatedJson = string_replace_all(_updatedJson, "}", ",\n}");
	_updatedJson = string_replace_all(_updatedJson, "{", "{\n");
	_updatedJson = string_replace_all(_updatedJson, "\\/", "/");
	var _finalConfig = "const config = " + _updatedJson + ";";
	var _fileBuffer = buffer_create(0, buffer_grow, 1);
	//sdbm(_finalConfig);
	buffer_write(_fileBuffer, buffer_text, _finalConfig);
	buffer_save(_fileBuffer, __tome_file_project_get_directory() +  "datafiles/Tome/config.js");
	buffer_delete(_fileBuffer);
}

#endregion

#region __tome_string_trim_starting_whitespace(_string, _maxNumberOfWhitespace)

/// @desc Trims the starting whitespace of a string leaving a given amount of it 
/// @param {string} string The string to trim
/// @param {real} maxNumberOfWhitespace The maximum number of whitespace characters to leave
function __tome_string_trim_starting_whitespace(_string, _maxNumberOfWhitespace){
	var _stringInfoStruct = {
		startingWhitespaceCount: 0,
		startingWhitespaceEnded: false,
		positionOfFirstNonWhitespaceCharacter: 0,
		checkCurrentCharForWhitespace: function(_character, _position){
			if (!startingWhitespaceEnded){
				if (_character == " "){
					startingWhitespaceCount++;	
				}else{
					startingWhitespaceEnded = true;		
					positionOfFirstNonWhitespaceCharacter = _position;
				}
			}
		}	
	}
	
	string_foreach(_string, _stringInfoStruct.checkCurrentCharForWhitespace)	
	
	return string_copy(_string, clamp(_stringInfoStruct.positionOfFirstNonWhitespaceCharacter - _maxNumberOfWhitespace, 1, string_length(_string)), string_length(_string));
}

#endregion

#region __tome_generate_file_sha(_content)

/// @desc generates the file's on disk sha (in git format) to be used to compaire to remote sha.
/// @param {string} content The file's on disk content.
/// @returns {real} sha the sha of the content
function __tome_generate_file_sha(_content){
	//Tome only uses blob objects, If this changes in the future, this function will need to be adjusted.
	
	var _byteLength = string_byte_length(_content);
	var _header = "blob " + string(_byteLength);

	var _shaBuffer = buffer_create(4096, buffer_grow, 1);
	
	buffer_seek(_shaBuffer, buffer_seek_start, 0);
	
	buffer_write(_shaBuffer, buffer_string, _header);
	buffer_write(_shaBuffer, buffer_text, _content);
	buffer_resize(_shaBuffer, buffer_tell(_shaBuffer));
	
	var _sha = buffer_sha1(_shaBuffer, 0, buffer_get_size(_shaBuffer));
	buffer_delete(_shaBuffer);
	
	return _sha
}
#endregion

#region __tome_string_split_spaces_tabs(_string)

/// @desc Splits up words separated by any number of spaces or tabs
/// @param {string} string The string to split
function __tome_string_split_spaces_tabs(_string) {
    var _len = string_length(_string);
    var _words = [];
    var _word = "";
    var _index = 0;

    for (var i = 1; i <= _len; i++) {
        var c = string_char_at(_string, i);
        if (c != " " && c != "\t") {
            _word += c;
        } else {
            if (string_length(_word) > 0) {
                _words[_index] = _word;
                _index += 1;
                _word = "";
            }
            // Continue if the character is a space or tab
        }
    }

    // Add the last word if it's not empty
    if (string_length(_word) > 0) {
        _words[_index] = _word;
    }

    return _words;
}

#endregion
