/// @title Primary functions
/// @category API Reference
/// @text Below are the functions you'll use to set up your docs and generate them. 

/// @func tome_add_script(script, slugs)
/// @desc adds a script to be parsed as a page to your site
/// @slug docs-add-script
/// @param {string} scriptName The name off the script to add
/// @param {string} slugs The name of any notes that will be used for adding slugs.
function tome_add_script(_scriptName){
	var _filePath = __tome_file_project_get_directory() + string("scripts/{0}/{0}.gml", _scriptName);
	array_push(global.__tomeFileArray, _filePath);
	
	for (var i = 1; i < argument_count; i++){
		_filePath = __tome_file_project_get_directory() + string("notes/{0}/{0}.txt", argument[i]);
		array_push(global.__tomeSlugArray, _filePath);		
	}
}

/// @text ?> When using `tome_add_note()`, only the tags @title and @category are parsed. The rest of the text is displayed as-is.

/// @func tome_add_note(noteName)
/// @desc Adds a note to be parsed as a page to your site
/// @param {string} noteName The note to add
/// @param {string} slugs The name of any notes that will be used for adding slugs.
function tome_add_note(_noteName){
	var _filePath = __tome_file_project_get_directory() + string("notes/{0}/{0}.txt", _noteName, _noteName);
	array_push(global.__tomeFileArray, _filePath);
	
	for (var i = 1; i < argument_count; i++){
		_filePath = __tome_file_project_get_directory() + string("notes/{0}/{0}.txt", argument[i]);
		array_push(global.__tomeSlugArray, _filePath);		
	}
}

/// @text ?> When adding a file, if you want Tome to parse the jsdoc tags @func, @desc, @param, and @return, the file must have the extension `.gml`.

/// @func tome_add_file(filePath)
/// @desc adds a file to be parsed when the docs are generated
/// @param {string} filePath The file to add
function tome_add_file(_filePath){
	array_push(global.__tomeFileArray, _filePath);
}

/// @func tome_set_homepage_from_file(filePath)
/// @desc Sets the homepage of your site to be the contents of a file (.txt, or .md)
/// @param {string} filePath The file to use as the homepage
function tome_set_homepage_from_file(_filePath){
	var _homePageParseStruct = __tome_parse_markdown(_filePath);
	global.__tomeHomepage = _homePageParseStruct.markdown;
}

/// @func tome_set_homepage_from_note(noteName)
/// @desc sets the homepage of your site to be the contents of the note
/// @param {string} noteName The note to use as the homepage
function tome_set_homepage_from_note(_noteName){
	var _homePageParseStruct = __tome_parse_markdown(__tome_file_project_get_directory() + string("notes/{0}/{0}.txt", _noteName, _noteName));
	global.__tomeHomepage = _homePageParseStruct.markdown;
}

/// @func tome_add_to_sidebar(name, link, category)
/// @desc Adds an item to the sidebar of your site
/// @param {string} name The name of the item
/// @param {string} link The link to the item
/// @param {string} category The category of the item
function tome_add_to_sidebar(_name, _link, _category){
	var _sidebarItem = {
		title: _name,
		link: _link,
		category: _category
	}
	array_push(global.__tomeAdditionalSidebarItemsArray, _sidebarItem);
}

/// @func tome_set_site_name(name)
/// @desc Sets the name of your site
/// @param {string} name The name of the site
function tome_set_site_name(_name){
	__tome_file_update_config("name", _name);
}

/// @func tome_set_site_description(desc)
/// @desc Sets the description of your site
/// @param {string} desc The description of the site
function tome_set_site_description(_desc){
	__tome_file_update_config("description", _desc);
}

/// @func tome_set_site_theme_color(color)
/// @desc Sets the theme color of your site
/// @param {string} color The theme color of the site
function tome_set_site_theme_color(_color){
	__tome_file_update_config("themeColor", _color);
}

/// @text >? Version names currently cannot contain spaces! 

/// @func tome_set_site_latest_version(versionName)
/// @desc Sets the latest version of the docs. The version
/// @param {string} versionName The latest version of the docs
function tome_set_site_latest_version(_versionName){
	var _fixedVersionName = string_replace_all(_versionName, " ", "-");
	global.__tomeLatestDocVersion = _fixedVersionName;
	__tome_file_update_config("latestVersion", _fixedVersionName);
}

/// @func tome_set_site_older_versions(versions)
/// @desc Specifically set what older versions of your docs you want to show on the site's version selector
/// @param {array<string>} versions An array of older versions names to display in the version selector
function tome_set_site_older_versions(_versions){
	__tome_file_update_config("otherVersions", _versions);	
}

/// @func tome_add_navbar_link(name, link)
/// @desc Adds a link to the navbar
/// @param {string} name The name of the link
/// @param {string} link The link to the link
function tome_add_navbar_link(_name, _link){
	var _navbarItem = {
		name: _name,
		link: _link
	}
	array_push(global.__tomeNavbarItemsArray, _navbarItem);
}








