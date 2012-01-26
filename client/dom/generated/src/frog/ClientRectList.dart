
class ClientRectListJs extends DOMTypeJs implements ClientRectList native "*ClientRectList" {

  int get length() native "return this.length;";

  ClientRectJs item(int index) native;
}
