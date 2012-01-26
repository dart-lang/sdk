
class MouseEventJs extends UIEventJs implements MouseEvent native "*MouseEvent" {

  bool get altKey() native "return this.altKey;";

  int get button() native "return this.button;";

  int get clientX() native "return this.clientX;";

  int get clientY() native "return this.clientY;";

  bool get ctrlKey() native "return this.ctrlKey;";

  ClipboardJs get dataTransfer() native "return this.dataTransfer;";

  NodeJs get fromElement() native "return this.fromElement;";

  bool get metaKey() native "return this.metaKey;";

  int get offsetX() native "return this.offsetX;";

  int get offsetY() native "return this.offsetY;";

  EventTargetJs get relatedTarget() native "return this.relatedTarget;";

  int get screenX() native "return this.screenX;";

  int get screenY() native "return this.screenY;";

  bool get shiftKey() native "return this.shiftKey;";

  NodeJs get toElement() native "return this.toElement;";

  int get webkitMovementX() native "return this.webkitMovementX;";

  int get webkitMovementY() native "return this.webkitMovementY;";

  int get x() native "return this.x;";

  int get y() native "return this.y;";

  void initMouseEvent(String type, bool canBubble, bool cancelable, DOMWindowJs view, int detail, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey, int button, EventTargetJs relatedTarget) native;
}
