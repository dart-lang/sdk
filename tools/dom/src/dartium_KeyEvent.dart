/**
 * A custom KeyboardEvent that attempts to eliminate cross-browser
 * inconsistencies, and also provide both keyCode and charCode information
 * for all key events (when such information can be determined).
 *
 * KeyEvent tries to provide a higher level, more polished keyboard event
 * information on top of the "raw" [KeyboardEvent].
 *
 * The mechanics of using KeyEvents is a little different from the underlying
 * [KeyboardEvent]. To use KeyEvents, you need to create a stream and then add
 * KeyEvents to the stream, rather than using the [EventTarget.dispatchEvent].
 * Here's an example usage:
 *
 *     // Initialize a stream for the KeyEvents:
 *     var stream = KeyEvent.keyPressEvent.forTarget(document.body);
 *     // Start listening to the stream of KeyEvents.
 *     stream.listen((keyEvent) =>
 *         window.console.log('KeyPress event detected ${keyEvent.charCode}'));
 *     ...
 *     // Add a new KeyEvent of someone pressing the 'A' key to the stream so
 *     // listeners can know a KeyEvent happened.
 *     stream.add(new KeyEvent('keypress', keyCode: 65, charCode: 97));
 *
 * This class is very much a work in progress, and we'd love to get information
 * on how we can make this class work with as many international keyboards as
 * possible. Bugs welcome!
 */
part of html;

@Experimental()
class KeyEvent extends _WrappedEvent implements KeyboardEvent {
  /** Needed because KeyboardEvent is implements.
   */
  /** The parent KeyboardEvent that this KeyEvent is wrapping and "fixing". */
  KeyboardEvent _parent;

  /** The "fixed" value of whether the alt key is being pressed. */
  bool _shadowAltKey;

  /** Calculated value of what the estimated charCode is for this event. */
  int _shadowCharCode;

  /** Calculated value of what the estimated keyCode is for this event. */
  int _shadowKeyCode;

  /** Calculated value of what the estimated keyCode is for this event. */
  int get keyCode => _shadowKeyCode;

  /** Calculated value of what the estimated charCode is for this event. */
  int get charCode => this.type == 'keypress' ? _shadowCharCode : 0;

  /** Calculated value of whether the alt key is pressed is for this event. */
  bool get altKey => _shadowAltKey;

  /** Calculated value of what the estimated keyCode is for this event. */
  int get which => keyCode;

  /** Accessor to the underlying keyCode value is the parent event. */
  int get _realKeyCode => _parent.keyCode;

  /** Accessor to the underlying charCode value is the parent event. */
  int get _realCharCode => _parent.charCode;

  /** Accessor to the underlying altKey value is the parent event. */
  bool get _realAltKey => _parent.altKey;

  /** Shadows on top of the parent's currentTarget. */
  EventTarget _currentTarget;

  final InputDeviceCapabilities sourceCapabilities;

  /** Construct a KeyEvent with [parent] as the event we're emulating. */
  KeyEvent.wrap(KeyboardEvent parent) : super(parent) {
    _parent = parent;
    _shadowAltKey = _realAltKey;
    _shadowCharCode = _realCharCode;
    _shadowKeyCode = _realKeyCode;
    _currentTarget =
        _parent.currentTarget == null ? window : _parent.currentTarget;
  }

  /** Programmatically create a new KeyEvent (and KeyboardEvent). */
  factory KeyEvent(String type,
      {Window view,
      bool canBubble: true,
      bool cancelable: true,
      int keyCode: 0,
      int charCode: 0,
      int keyLocation: 1,
      bool ctrlKey: false,
      bool altKey: false,
      bool shiftKey: false,
      bool metaKey: false,
      EventTarget currentTarget}) {
    var parent = new KeyboardEvent(type,
        view: view,
        canBubble: canBubble,
        cancelable: cancelable,
        keyLocation: keyLocation,
        ctrlKey: ctrlKey,
        altKey: altKey,
        shiftKey: shiftKey,
        metaKey: metaKey);
    var keyEvent = new KeyEvent.wrap(parent);
    keyEvent._shadowAltKey = altKey;
    keyEvent._shadowCharCode = charCode;
    keyEvent._shadowKeyCode = keyCode;
    keyEvent._currentTarget = currentTarget == null ? window : currentTarget;
    return keyEvent;
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

  /** The currently registered target for this event. */
  EventTarget get currentTarget => _currentTarget;

  /** True if the ctrl key is pressed during this event. */
  bool get ctrlKey => _parent.ctrlKey;
  int get detail => _parent.detail;
  /**
   * Accessor to the part of the keyboard that the key was pressed from (one of
   * KeyLocation.STANDARD, KeyLocation.RIGHT, KeyLocation.LEFT,
   * KeyLocation.NUMPAD, KeyLocation.MOBILE, KeyLocation.JOYSTICK).
   */
  int get keyLocation => _parent.keyLocation;
  /** True if the Meta (or Mac command) key is pressed during this event. */
  bool get metaKey => _parent.metaKey;
  /** True if the shift key was pressed during this event. */
  bool get shiftKey => _parent.shiftKey;
  Window get view => _parent.view;
  void _initUIEvent(
      String type, bool canBubble, bool cancelable, Window view, int detail) {
    throw new UnsupportedError("Cannot initialize a UI Event from a KeyEvent.");
  }

  String get _shadowKeyIdentifier => _parent._keyIdentifier;

  int get _charCode => charCode;
  int get _keyCode => keyCode;
  int get _which => which;
  String get _keyIdentifier {
    throw new UnsupportedError("keyIdentifier is unsupported.");
  }

  void _initKeyboardEvent(
      String type,
      bool canBubble,
      bool cancelable,
      Window view,
      String keyIdentifier,
      int keyLocation,
      bool ctrlKey,
      bool altKey,
      bool shiftKey,
      bool metaKey) {
    throw new UnsupportedError(
        "Cannot initialize a KeyboardEvent from a KeyEvent.");
  }

  @Experimental() // untriaged
  bool getModifierState(String keyArgument) => throw new UnimplementedError();
  @Experimental() // untriaged
  int get location => throw new UnimplementedError();
  @Experimental() // untriaged
  bool get repeat => throw new UnimplementedError();
  dynamic get _get_view => throw new UnimplementedError();
}
