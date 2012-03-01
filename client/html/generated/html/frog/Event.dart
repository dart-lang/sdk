
class _EventImpl implements Event native "*Event" {

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

  final bool bubbles;

  bool cancelBubble;

  final bool cancelable;

  final _ClipboardImpl clipboardData;

  _EventTargetImpl get currentTarget() => _FixHtmlDocumentReference(_currentTarget);

  _EventTargetImpl get _currentTarget() native "return this.currentTarget;";

  final bool defaultPrevented;

  final int eventPhase;

  bool returnValue;

  _EventTargetImpl get srcElement() => _FixHtmlDocumentReference(_srcElement);

  _EventTargetImpl get _srcElement() native "return this.srcElement;";

  _EventTargetImpl get target() => _FixHtmlDocumentReference(_target);

  _EventTargetImpl get _target() native "return this.target;";

  final int timeStamp;

  final String type;

  void _initEvent(String eventTypeArg, bool canBubbleArg, bool cancelableArg) native "this.initEvent(eventTypeArg, canBubbleArg, cancelableArg);";

  void preventDefault() native;

  void stopImmediatePropagation() native;

  void stopPropagation() native;
}
