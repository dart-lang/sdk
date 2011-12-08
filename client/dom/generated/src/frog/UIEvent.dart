
class UIEvent extends Event native "UIEvent" {

  int charCode;

  int detail;

  int keyCode;

  int layerX;

  int layerY;

  int pageX;

  int pageY;

  DOMWindow view;

  int which;

  void initUIEvent(String type, bool canBubble, bool cancelable, DOMWindow view, int detail) native;
}
