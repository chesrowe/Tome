var _docString = doc_generate("C:/Users/madma/OneDrive/Documents/GameMakerStudio2/gm-autoDoc/scripts/scr_docTest/scr_docTest.gml");
var _docBuffer = buffer_create(0, buffer_grow, 1);
show_message(_docString);
buffer_write(_docBuffer, buffer_text, _docString);
buffer_save(_docBuffer, "C:/Users/madma/OneDrive/Desktop/docTest.md");
buffer_delete(_docBuffer);