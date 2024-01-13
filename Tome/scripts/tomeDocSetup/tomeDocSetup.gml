#region System(don't mess with these)

global.__tomeFileArray = [];
global.__tomeAdditionalSidebarItemsArray = [];
global.__tomeHomepage = "";
global.__tomeLatestDocVersion = "Current-Version";
global.__tomeNavbarItemsArray = [];

#endregion

/*
	Add all the files you wish to be parsed here!
	                                              */
tome_add_note("nte_settingUp");
tome_add_script(__tome);
tome_add_note("nte_advancedUse");
tome_add_note("nte_configuration");

tome_set_homepage_from_note("nte_homepage");

tome_add_navbar_link("Releases", "https://github.com/chesrowe/Tome/releases");
tome_add_navbar_link("Report a bug", "https://github.com/chesrowe/Tome/issues");

tome_set_site_description("Tome is a documentation generator for GameMaker Studio LTS+. Its designed to be easy to use, and easy to integrate into your workflow. Its also open source, so you can contribute to it if you want to!");
tome_set_site_name("Tome");
tome_set_site_latest_version("Tome");
tome_set_site_theme_color("#11DD11");