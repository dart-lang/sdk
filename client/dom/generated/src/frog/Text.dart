
class TextJS extends CharacterDataJS implements Text native "*Text" {

  String get wholeText() native "return this.wholeText;";

  TextJS replaceWholeText(String content) native;

  TextJS splitText(int offset) native;
}
