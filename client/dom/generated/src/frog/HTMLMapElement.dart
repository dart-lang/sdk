
class HTMLMapElementJS extends HTMLElementJS implements HTMLMapElement native "*HTMLMapElement" {

  HTMLCollectionJS get areas() native "return this.areas;";

  String get name() native "return this.name;";

  void set name(String value) native "this.name = value;";
}
