
class HTMLDListElementJS extends HTMLElementJS implements HTMLDListElement native "*HTMLDListElement" {

  bool get compact() native "return this.compact;";

  void set compact(bool value) native "this.compact = value;";
}
