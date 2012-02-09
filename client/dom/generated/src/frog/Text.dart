
class _TextJs extends _CharacterDataJs implements Text native "*Text" {

  final String wholeText;

  _TextJs replaceWholeText(String content) native;

  _TextJs splitText(int offset) native;
}
