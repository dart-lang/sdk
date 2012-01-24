
class HTMLOListElementJS extends HTMLElementJS implements HTMLOListElement native "*HTMLOListElement" {

  bool get compact() native "return this.compact;";

  void set compact(bool value) native "this.compact = value;";

  bool get reversed() native "return this.reversed;";

  void set reversed(bool value) native "this.reversed = value;";

  int get start() native "return this.start;";

  void set start(int value) native "this.start = value;";

  String get type() native "return this.type;";

  void set type(String value) native "this.type = value;";
}
