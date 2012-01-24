
class HTMLIsIndexElementJs extends HTMLInputElementJs implements HTMLIsIndexElement native "*HTMLIsIndexElement" {

  HTMLFormElementJs get form() native "return this.form;";

  String get prompt() native "return this.prompt;";

  void set prompt(String value) native "this.prompt = value;";
}
