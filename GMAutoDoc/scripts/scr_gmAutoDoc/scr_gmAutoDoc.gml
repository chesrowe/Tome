#macro AUTO_DOC_REPO_PATH "" //Path to the repo hosting the docs

global.__autodocFileArray = [];

/**
 * Parses a GML file and generates markdown documentation.
 * 
 * @param {string} filepath Path to the GML file.
 * @returns {struct} Struct containing the markdown text, title, and category
 */
function __autodoc_parse_file(filepath) {
    var _file = file_text_open_read(filepath);
	var _markdown = "";
	
    if (_file == -1) {
        show_message("Failed to open file: " + filepath);
		return {};
    }
	
	var _inTextBlock = false;
	var _inDesc = false;
	var _inConstructor = false;
	var _category = "";
	var _title = "";

    //Loop through each line of the text file
	while (!file_text_eof(_file)) {
		var _lineString = string_trim(file_text_readln(_file));
		//show_message(_lineString);
		
		//If the line has text to parse, it will start with "///"
		if (string_starts_with(_lineString, "///")){
			_lineString = string_replace(_lineString, "///", "");
			//If the line contains a tag 
			if (string_count("@", _lineString) > 0){
				var _splitString = string_split(_lineString, " ");
				var _tagType = _splitString[1];
				var _tagContent = string_trim(string_replace(_lineString, _tagType, ""));
			
				switch(_tagType){
					case "@title":
						_markdown += "# " + _tagContent + "\n";		
						_title = _tagContent;
						_inTextBlock = false;
					break;
					
					case "@function":
					case "@func":
						_markdown += string("\n## `{0}`", _tagContent);		
						_inTextBlock = false;
						
						if (_inConstructor){
							_markdown += " (*constructor*)";		
						}else{
							_markdown += " → {rv}";	
						}
						
						_markdown += "\n";
					break;
					
					case "@method":
						if (_inConstructor){
							_markdown += "\n**Methods**\n";	
							_inConstructor = false;
						}
						
						_markdown += string("### `.{0}` → {rv}\n" , _tagContent);		
						_inTextBlock = false;
					break;
					
					case "@constructor":
						_inConstructor = true;
					break;
				
					case "@desc":
						_markdown += _tagContent + "\n";			
						_inTextBlock = true;
						_inDesc = true;
					break; 
					
					case "@text":
						_markdown += _tagContent + "\n";			
						_inTextBlock = true;
					break;
					
					case "@param":
						if (_inDesc){
							_markdown += "| Parameter | Datatype  | Purpose |\n";
							_markdown += "|-----------|-----------|---------|\n";				
						}
						
						_inDesc = false;
						_inTextBlock = false;
						
						var _paramDataTypeUntrimed = _splitString[2];
						var _paramDataType = string_delete(_paramDataTypeUntrimed, 1, 1);
						_paramDataType = string_delete(_paramDataType, string_pos("}", _paramDataType), 1);
						var _paramName = _splitString[3];
						var _paramInfo = string_replace(_tagContent, _splitString[2], "");
						_paramInfo = string_replace(_paramInfo, _splitString[3], "");
						_paramInfo = string_trim(_paramInfo);
						
						_markdown += string("|`{0}` |{1} |{2} |\n", _paramName, _paramDataType, _paramInfo);
						_markdown = string_replace(_markdown, "{rv}", string("*{0}*", _paramDataType));
					break;
					
					case "@return":
						var _returnInfo = string_replace(_tagContent, _splitString[2], "");
						_returnInfo = string_trim(_returnInfo);	
						_markdown += string("\n**Returns:** {0}\n", _returnInfo);
					break;
					
					case "@category":
						_category = _splitString[1];
					break;
				}
			}else if (_inTextBlock){
				_markdown += string_trim(_lineString) + "\n";				
			}
		}	
    }

    file_text_close(_file);
    return {
		markdown: _markdown,
		category: _category,
		title: _title
	}
}
