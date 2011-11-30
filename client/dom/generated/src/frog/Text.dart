
class Text extends CharacterData native "*Text" {

  String wholeText;

  Text replaceWholeText(String content) native;

  Text splitText(int offset) native;
}
