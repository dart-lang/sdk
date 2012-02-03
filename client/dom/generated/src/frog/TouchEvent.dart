
class _TouchEventJs extends _UIEventJs implements TouchEvent native "*TouchEvent" {

  bool get altKey() native "return this.altKey;";

  _TouchListJs get changedTouches() native "return this.changedTouches;";

  bool get ctrlKey() native "return this.ctrlKey;";

  bool get metaKey() native "return this.metaKey;";

  bool get shiftKey() native "return this.shiftKey;";

  _TouchListJs get targetTouches() native "return this.targetTouches;";

  _TouchListJs get touches() native "return this.touches;";

  void initTouchEvent(_TouchListJs touches, _TouchListJs targetTouches, _TouchListJs changedTouches, String type, _DOMWindowJs view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}
