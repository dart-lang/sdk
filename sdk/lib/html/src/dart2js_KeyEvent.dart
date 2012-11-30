/**
 * A custom KeyboardEvent that attempts to eliminate cross-browser
 * inconsistencies, and also provide both keyCode and charCode information
 * for all key events (when such information can be determined).
 *
 * This class is very much a work in progress, and we'd love to get information
 * on how we can make this class work with as many international keyboards as
 * possible. Bugs welcome!
 */
class KeyEvent implements KeyboardEvent {
  /** The parent KeyboardEvent that this KeyEvent is wrapping and "fixing". */
  KeyboardEvent _parent;

  /** The "fixed" value of whether the alt key is being pressed. */
  bool _shadowAltKey;

  /** Caculated value of what the estimated charCode is for this event. */
  int _shadowCharCode;

  /** Caculated value of what the estimated keyCode is for this event. */
  int _shadowKeyCode;

  /** Caculated value of what the estimated keyCode is for this event. */
  int get keyCode => _shadowKeyCode;

  /** Caculated value of what the estimated charCode is for this event. */
  int get charCode => this.type == 'keypress' ? _shadowCharCode : 0;

  /** Caculated value of whether the alt key is pressed is for this event. */
  bool get altKey => _shadowAltKey;

  /** Caculated value of what the estimated keyCode is for this event. */
  int get which => keyCode;

  /** Accessor to the underlying keyCode value is the parent event. */
  int get _realKeyCode => JS('int', '#.keyCode', _parent);
  
  /** Accessor to the underlying charCode value is the parent event. */
  int get _realCharCode => JS('int', '#.charCode', _parent);

  /** Accessor to the underlying altKey value is the parent event. */
  bool get _realAltKey => JS('int', '#.altKey', _parent);

  /** Construct a KeyEvent with [parent] as event we're emulating. */
  KeyEvent(KeyboardEvent parent) {
    _parent = parent;
    _shadowAltKey = _realAltKey;
    _shadowCharCode = _realCharCode;
    _shadowKeyCode = _realKeyCode;
  }

  /** True if the altGraphKey is pressed during this event. */
  bool get altGraphKey => _parent.altGraphKey;
  bool get bubbles => _parent.bubbles;
  /** True if this event can be cancelled. */
  bool get cancelable => _parent.cancelable;
  bool get cancelBubble => _parent.cancelBubble;
  set cancelBubble(bool cancel) => _parent = cancel;  
  /** Accessor to the clipboardData available for this event. */
  Clipboard get clipboardData => _parent.clipboardData;
  /** True if the ctrl key is pressed during this event. */
  bool get ctrlKey => _parent.ctrlKey;
  /** Accessor to the target this event is listening to for changes. */
  EventTarget get currentTarget => _parent.currentTarget;
  bool get defaultPrevented => _parent.defaultPrevented;
  int get detail => _parent.detail;
  int get eventPhase => _parent.eventPhase;
  /**
   * Accessor to the part of the keyboard that the key was pressed from (one of
   * KeyLocation.STANDARD, KeyLocation.RIGHT, KeyLocation.LEFT,
   * KeyLocation.NUMPAD, KeyLocation.MOBILE, KeyLocation.JOYSTICK).
   */
  int get keyLocation => _parent.keyLocation;
  int get layerX => _parent.layerX;
  int get layerY => _parent.layerY;
  /** True if the Meta (or Mac command) key is pressed during this event. */
  bool get metaKey => _parent.metaKey;
  int get pageX => _parent.pageX;
  int get pageY => _parent.pageY;
  bool get returnValue => _parent.returnValue;
  set returnValue(bool value) => _parent = value;  
  /** True if the shift key was pressed during this event. */
  bool get shiftKey => _parent.shiftKey;
  int get timeStamp => _parent.timeStamp;
  /**
   * The type of key event that occurred. One of "keydown", "keyup", or
   * "keypress".
   */
  String get type => _parent.type;
  Window get view => _parent.view;
  void preventDefault() => _parent.preventDefault();
  void stopImmediatePropagation() => _parent.stopImmediatePropagation();
  void stopPropagation() => _parent.stopPropagation();
  void $dom_initUIEvent(String type, bool canBubble, bool cancelable,
      LocalWindow view, int detail) {
    throw new UnsupportedError("Cannot initialize a UI Event from a KeyEvent.");
  }
  void $dom_initEvent(String eventTypeArg, bool canBubbleArg,
      bool cancelableArg) {
    throw new UnsupportedError("Cannot initialize an Event from a KeyEvent.");
  }
  String get _shadowKeyIdentifier => JS('String', '#.keyIdentifier', _parent);
}
