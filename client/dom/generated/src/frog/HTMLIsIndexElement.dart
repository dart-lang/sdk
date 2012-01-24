
class HTMLIsIndexElementJS extends HTMLInputElementJS implements HTMLIsIndexElement native "*HTMLIsIndexElement" {

  HTMLFormElementJS get form() native "return this.form;";

  String get prompt() native "return this.prompt;";

  void set prompt(String value) native "this.prompt = value;";
}
