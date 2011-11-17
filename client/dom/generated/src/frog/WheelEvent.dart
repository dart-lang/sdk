
class WheelEvent extends UIEvent native "WheelEvent" {

  bool altKey;

  int clientX;

  int clientY;

  bool ctrlKey;

  bool metaKey;

  int offsetX;

  int offsetY;

  int screenX;

  int screenY;

  bool shiftKey;

  bool webkitDirectionInvertedFromDevice;

  int wheelDelta;

  int wheelDeltaX;

  int wheelDeltaY;

  int x;

  int y;

  void initWebKitWheelEvent(int wheelDeltaX, int wheelDeltaY, DOMWindow view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}
