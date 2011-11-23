
class TouchEvent extends UIEvent native "*TouchEvent" {

  bool altKey;

  TouchList changedTouches;

  bool ctrlKey;

  bool metaKey;

  bool shiftKey;

  TouchList targetTouches;

  TouchList touches;

  void initTouchEvent(TouchList touches, TouchList targetTouches, TouchList changedTouches, String type, DOMWindow view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}
