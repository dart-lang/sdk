
class MouseEvent extends UIEvent native "*MouseEvent" {

  bool altKey;

  int button;

  int clientX;

  int clientY;

  bool ctrlKey;

  Clipboard dataTransfer;

  Node fromElement;

  bool metaKey;

  int offsetX;

  int offsetY;

  EventTarget relatedTarget;

  int screenX;

  int screenY;

  bool shiftKey;

  Node toElement;

  int x;

  int y;

  void initMouseEvent(String type, bool canBubble, bool cancelable, DOMWindow view, int detail, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, int button, EventTarget relatedTarget) native;
}
