var _docStruct = __autodoc_parse_file("C:/Users/browe/documents/GitHub/GMAutoDoc/GMAutoDoc/scripts/scr_docTest/scr_docTest.gml");
var _docBuffer = buffer_create(0, buffer_grow, 1);
buffer_write(_docBuffer, buffer_text, _docStruct.markdown);
buffer_save(_docBuffer, string("C:/Users/browe/Desktop/{0}.md", _docStruct.title));
buffer_delete(_docBuffer);

