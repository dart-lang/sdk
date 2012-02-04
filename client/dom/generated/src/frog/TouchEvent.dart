
class _TouchEventJs extends _UIEventJs implements TouchEvent native "*TouchEvent" {

  final bool altKey;

  final _TouchListJs changedTouches;

  final bool ctrlKey;

  final bool metaKey;

  final bool shiftKey;

  final _TouchListJs targetTouches;

  final _TouchListJs touches;

  void initTouchEvent(_TouchListJs touches, _TouchListJs targetTouches, _TouchListJs changedTouches, String type, _DOMWindowJs view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}
