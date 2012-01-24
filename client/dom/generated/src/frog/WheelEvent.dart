
class WheelEventJS extends UIEventJS implements WheelEvent native "*WheelEvent" {

  bool get altKey() native "return this.altKey;";

  int get clientX() native "return this.clientX;";

  int get clientY() native "return this.clientY;";

  bool get ctrlKey() native "return this.ctrlKey;";

  bool get metaKey() native "return this.metaKey;";

  int get offsetX() native "return this.offsetX;";

  int get offsetY() native "return this.offsetY;";

  int get screenX() native "return this.screenX;";

  int get screenY() native "return this.screenY;";

  bool get shiftKey() native "return this.shiftKey;";

  bool get webkitDirectionInvertedFromDevice() native "return this.webkitDirectionInvertedFromDevice;";

  int get wheelDelta() native "return this.wheelDelta;";

  int get wheelDeltaX() native "return this.wheelDeltaX;";

  int get wheelDeltaY() native "return this.wheelDeltaY;";

  int get x() native "return this.x;";

  int get y() native "return this.y;";

  void initWebKitWheelEvent(int wheelDeltaX, int wheelDeltaY, DOMWindowJS view, int screenX, int screenY, int clientX, int clientY, bool ctrlKey, bool altKey, bool shiftKey, bool metaKey) native;
}
