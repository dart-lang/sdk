
class HTMLIsIndexElement extends HTMLInputElement native "*HTMLIsIndexElement" {

  HTMLFormElement get form() native "return this.form;";

  String get prompt() native "return this.prompt;";

  void set prompt(String value) native "this.prompt = value;";
}
