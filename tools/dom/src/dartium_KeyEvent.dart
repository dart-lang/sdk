/**
 * A custom KeyboardEvent that attempts to eliminate cross-browser
 * inconsistencies, and also provide both keyCode and charCode information
 * for all key events (when such information can be determined).
 *
 * KeyEvent tries to provide a higher level, more polished keyboard event
 * information on top of the "raw" [KeyboardEvent].
 *
 * This class is very much a work in progress, and we'd love to get information
 * on how we can make this class work with as many international keyboards as
 * possible. Bugs welcome!
 */
class KeyEvent extends _WrappedEvent implements KeyboardEvent {
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
  int get _realKeyCode => _parent.keyCode;

  /** Accessor to the underlying charCode value is the parent event. */
  int get _realCharCode => _parent.charCode;

  /** Accessor to the underlying altKey value is the parent event. */
  bool get _realAltKey => _parent.altKey;

  /** Construct a KeyEvent with [parent] as the event we're emulating. */
  KeyEvent(KeyboardEvent parent): super(parent) {
    _parent = parent;
    _shadowAltKey = _realAltKey;
    _shadowCharCode = _realCharCode;
    _shadowKeyCode = _realKeyCode;
  }

  /** Accessor to provide a stream of KeyEvents on the desired target. */
  static EventStreamProvider<KeyEvent> keyDownEvent =
    new _KeyboardEventHandler('keydown');
  /** Accessor to provide a stream of KeyEvents on the desired target. */
  static EventStreamProvider<KeyEvent> keyUpEvent =
    new _KeyboardEventHandler('keyup');
  /** Accessor to provide a stream of KeyEvents on the desired target. */
  static EventStreamProvider<KeyEvent> keyPressEvent =
    new _KeyboardEventHandler('keypress');

  /** True if the altGraphKey is pressed during this event. */
  bool get altGraphKey => _parent.altGraphKey;
  /** True if the ctrl key is pressed during this event. */
  bool get ctrlKey => _parent.ctrlKey;
  int get detail => _parent.detail;
  /**
   * Accessor to the part of the keyboard that the key was pressed from (one of
   * KeyLocation.STANDARD, KeyLocation.RIGHT, KeyLocation.LEFT,
   * KeyLocation.NUMPAD, KeyLocation.MOBILE, KeyLocation.JOYSTICK).
   */
  int get keyLocation => _parent.keyLocation;
  Point get layer => _parent.layer;
  /** True if the Meta (or Mac command) key is pressed during this event. */
  bool get metaKey => _parent.metaKey;
  Point get page => _parent.page;
  /** True if the shift key was pressed during this event. */
  bool get shiftKey => _parent.shiftKey;
  Window get view => _parent.view;
  void $dom_initUIEvent(String type, bool canBubble, bool cancelable,
      Window view, int detail) {
    throw new UnsupportedError("Cannot initialize a UI Event from a KeyEvent.");
  }
  String get _shadowKeyIdentifier => _parent.$dom_keyIdentifier;

  int get $dom_charCode => charCode;
  int get $dom_keyCode => keyCode;
  String get $dom_keyIdentifier {
    throw new UnsupportedError("keyIdentifier is unsupported.");
  }
  void $dom_initKeyboardEvent(String type, bool canBubble, bool cancelable,
      Window view, String keyIdentifier, int keyLocation, bool ctrlKey,
      bool altKey, bool shiftKey, bool metaKey,
      bool altGraphKey) {
    throw new UnsupportedError(
        "Cannot initialize a KeyboardEvent from a KeyEvent.");
  }
}
