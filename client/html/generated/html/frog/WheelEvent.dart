
class _WheelEventImpl extends _UIEventImpl implements WheelEvent native "*WheelEvent" {

  final bool altKey;

  final int clientX;

  final int clientY;

  final bool ctrlKey;

  final bool metaKey;

  final int offsetX;

  final int offsetY;

  final int screenX;

  final int screenY;

  final bool shiftKey;

  final bool webkitDirectionInvertedFromDevice;

  final int wheelDelta;

  final int wheelDeltaX;

  final int wheelDeltaY;

  final int x;

  final int y;

  void initWebKitWheelEvent(int wheelDeltaX, int wheelDeltaY, _WindowImpl view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}
