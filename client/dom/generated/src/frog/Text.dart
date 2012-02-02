
class _TextJs extends _CharacterDataJs implements Text native "*Text" {

  String get wholeText() native "return this.wholeText;";

  _TextJs replaceWholeText(String content) native;

  _TextJs splitText(int offset) native;
}
