
class TouchEvent extends UIEvent native "*TouchEvent" {

  bool get altKey() native "return this.altKey;";

  TouchList get changedTouches() native "return this.changedTouches;";

  bool get ctrlKey() native "return this.ctrlKey;";

  bool get metaKey() native "return this.metaKey;";

  bool get shiftKey() native "return this.shiftKey;";

  TouchList get targetTouches() native "return this.targetTouches;";

  TouchList get touches() native "return this.touches;";

  void initTouchEvent(TouchList touches, TouchList targetTouches, TouchList changedTouches, String type, DOMWindow view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}
