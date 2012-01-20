
class Text extends CharacterData native "*Text" {

  String get wholeText() native "return this.wholeText;";

  Text replaceWholeText(String content) native;

  Text splitText(int offset) native;
}
