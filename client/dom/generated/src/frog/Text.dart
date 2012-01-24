
class TextJs extends CharacterDataJs implements Text native "*Text" {

  String get wholeText() native "return this.wholeText;";

  TextJs replaceWholeText(String content) native;

  TextJs splitText(int offset) native;
}
