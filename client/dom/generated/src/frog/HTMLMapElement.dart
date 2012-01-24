
class HTMLMapElementJs extends HTMLElementJs implements HTMLMapElement native "*HTMLMapElement" {

  HTMLCollectionJs get areas() native "return this.areas;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";
}
