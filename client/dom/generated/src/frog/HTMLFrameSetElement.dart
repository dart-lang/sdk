
class HTMLFrameSetElementJs extends HTMLElementJs implements HTMLFrameSetElement native "*HTMLFrameSetElement" {

  String get cols() native "return this.cols;";

  void set cols(String value) native "this.cols = value;";

  String get rows() native "return this.rows;";

  void set rows(String value) native "this.rows = value;";
}
