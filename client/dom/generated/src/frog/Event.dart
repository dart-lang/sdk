
class Event native "*Event" {

  static final int AT_TARGET = 2;

  static final int BLUR = 8192;

  static final int BUBBLING_PHASE = 3;

  static final int CAPTURING_PHASE = 1;

  static final int CHANGE = 32768;

  static final int CLICK = 64;

  static final int DBLCLICK = 128;

  static final int DRAGDROP = 2048;

  static final int FOCUS = 4096;

  static final int KEYDOWN = 256;

  static final int KEYPRESS = 1024;

  static final int KEYUP = 512;

  static final int MOUSEDOWN = 1;

  static final int MOUSEDRAG = 32;

  static final int MOUSEMOVE = 16;

  static final int MOUSEOUT = 8;

  static final int MOUSEOVER = 4;

  static final int MOUSEUP = 2;

  static final int SELECT = 16384;

  bool get bubbles() native "return this.bubbles;";

  bool get cancelBubble() native "return this.cancelBubble;";

  void set cancelBubble(bool value) native "this.cancelBubble = value;";

  bool get cancelable() native "return this.cancelable;";

  Clipboard get clipboardData() native "return this.clipboardData;";

  EventTarget get currentTarget() native "return this.currentTarget;";

  bool get defaultPrevented() native "return this.defaultPrevented;";

  int get eventPhase() native "return this.eventPhase;";

  bool get returnValue() native "return this.returnValue;";

  void set returnValue(bool value) native "this.returnValue = value;";

  EventTarget get srcElement() native "return this.srcElement;";

  EventTarget get target() native "return this.target;";

  int get timeStamp() native "return this.timeStamp;";

  String get type() native "return this.type;";

  void initEvent(String eventTypeArg, bool canBubbleArg, bool cancelableArg) native;

  void preventDefault() native;

  void stopImmediatePropagation() native;

  void stopPropagation() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
