
class HTMLHeadElementJS extends HTMLElementJS implements HTMLHeadElement native "*HTMLHeadElement" {

  String get profile() native "return this.profile;";

  void set profile(String value) native "this.profile = value;";
}
