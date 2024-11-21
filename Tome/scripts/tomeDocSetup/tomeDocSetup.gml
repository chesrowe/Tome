#region System(don't mess with these)

global.__tomeFileArray = [];
global.__tomeAdditionalSidebarItemsArray = [];
global.__tomeHomepage = "Homepage";
global.__tomeLatestDocVersion = "Current-Version";
global.__tomeNavbarItemsArray = [];

#endregion

/*
	Add all the files you wish to be parsed here!
	                                              */										  
tome_set_site_description("Documentation for the Tome library");
tome_set_site_name("Tome");
tome_set_site_latest_version("11-20-2024");
tome_set_site_older_versions(["03-06-2024", "02-16-2024", "02-15-2024", "Beta-1"]);
tome_set_site_theme_color("#11DD11");

tome_set_homepage_from_note("nte_homepage");
tome_add_script("__tome");
tome_add_note("nte_settingUp");
tome_add_note("nte_configuration");
tome_add_note("nte_exampleSite");
tome_add_note("nte_formattingScripts");
tome_add_note("nte_advancedUse");