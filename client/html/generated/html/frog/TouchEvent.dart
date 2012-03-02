
class _TouchEventImpl extends _UIEventImpl implements TouchEvent native "*TouchEvent" {

  final bool altKey;

  final _TouchListImpl changedTouches;

  final bool ctrlKey;

  final bool metaKey;

  final bool shiftKey;

  final _TouchListImpl targetTouches;

  final _TouchListImpl touches;

  void initTouchEvent(_TouchListImpl touches, _TouchListImpl targetTouches, _TouchListImpl changedTouches, String type, _WindowImpl view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}
