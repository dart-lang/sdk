
class TouchListJs extends DOMTypeJs implements TouchList native "*TouchList" {

  int get length() native "return this.length;";

  TouchJs operator[](int index) native;

  void operator[]=(int index, TouchJs value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  TouchJs item(int index) native;
}
