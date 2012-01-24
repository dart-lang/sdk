
class TouchEventJs extends UIEventJs implements TouchEvent native "*TouchEvent" {

  bool get altKey() native "return this.altKey;";

  TouchListJs get changedTouches() native "return this.changedTouches;";

  bool get ctrlKey() native "return this.ctrlKey;";

  bool get metaKey() native "return this.metaKey;";

  bool get shiftKey() native "return this.shiftKey;";

  TouchListJs get targetTouches() native "return this.targetTouches;";

  TouchListJs get touches() native "return this.touches;";

  void initTouchEvent(TouchListJs touches, TouchListJs targetTouches, TouchListJs changedTouches, String type, DOMWindowJs view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}
