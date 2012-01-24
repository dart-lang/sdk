
class TouchEventJS extends UIEventJS implements TouchEvent native "*TouchEvent" {

  bool get altKey() native "return this.altKey;";

  TouchListJS get changedTouches() native "return this.changedTouches;";

  bool get ctrlKey() native "return this.ctrlKey;";

  bool get metaKey() native "return this.metaKey;";

  bool get shiftKey() native "return this.shiftKey;";

  TouchListJS get targetTouches() native "return this.targetTouches;";

  TouchListJS get touches() native "return this.touches;";

  void initTouchEvent(TouchListJS touches, TouchListJS targetTouches, TouchListJS changedTouches, String type, DOMWindowJS view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}
