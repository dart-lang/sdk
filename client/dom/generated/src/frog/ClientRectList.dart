
class _ClientRectListJs extends _DOMTypeJs implements ClientRectList native "*ClientRectList" {

  int get length() native "return this.length;";

  _ClientRectJs item(int index) native;
}
