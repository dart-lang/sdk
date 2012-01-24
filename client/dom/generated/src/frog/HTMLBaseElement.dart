
class HTMLBaseElementJs extends HTMLElementJs implements HTMLBaseElement native "*HTMLBaseElement" {

  String get href() native "return this.href;";

  void set href(String value) native "this.href = value;";

  String get target() native "return this.target;";

  void set target(String value) native "this.target = value;";
}
