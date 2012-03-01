
class _TextImpl extends _CharacterDataImpl implements Text native "*Text" {

  final String wholeText;

  _TextImpl replaceWholeText(String content) native;

  _TextImpl splitText(int offset) native;
}
