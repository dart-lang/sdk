
class HTMLDirectoryElementJS extends HTMLElementJS implements HTMLDirectoryElement native "*HTMLDirectoryElement" {

  bool get compact() native "return this.compact;";

  void set compact(bool value) native "this.compact = value;";
}
