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
@Experimental()
class KeyEvent extends _WrappedEvent implements KeyboardEvent {
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
  int get _realKeyCode => JS('int', '#.keyCode', _parent);

  /** Accessor to the underlying charCode value is the parent event. */
  int get _realCharCode => JS('int', '#.charCode', _parent);

  /** Accessor to the underlying altKey value is the parent event. */
  bool get _realAltKey => JS('bool', '#.altKey', _parent);

  /** Shadows on top of the parent's currentTarget. */
  EventTarget _currentTarget;

  final InputDeviceCapabilities sourceCapabilities;

  /**
   * The value we want to use for this object's dispatch. Created here so it is
   * only invoked once.
   */
  static final _keyboardEventDispatchRecord = _makeRecord();

  /** Helper to statically create the dispatch record. */
  static _makeRecord() {
    var interceptor = JS_INTERCEPTOR_CONSTANT(KeyboardEvent);
    return makeLeafDispatchRecord(interceptor);
  }

  /** Construct a KeyEvent with [parent] as the event we're emulating. */
  KeyEvent.wrap(KeyboardEvent parent) : super(parent) {
    _parent = parent;
    _shadowAltKey = _realAltKey;
    _shadowCharCode = _realCharCode;
    _shadowKeyCode = _realKeyCode;
    _currentTarget = _parent.currentTarget;
  }

  /** Programmatically create a new KeyEvent (and KeyboardEvent). */
  factory KeyEvent(String type,
      {Window view,
      bool canBubble: true,
      bool cancelable: true,
      int keyCode: 0,
      int charCode: 0,
      int location: 1,
      bool ctrlKey: false,
      bool altKey: false,
      bool shiftKey: false,
      bool metaKey: false,
      EventTarget currentTarget}) {
    if (view == null) {
      view = window;
    }

    var eventObj;
    // In these two branches we create an underlying native KeyboardEvent, but
    // we set it with our specified values. Because we are doing custom setting
    // of certain values (charCode/keyCode, etc) only in this class (as opposed
    // to KeyboardEvent) and the way we set these custom values depends on the
    // type of underlying JS object, we do all the construction for the
    // underlying KeyboardEvent here.
    if (canUseDispatchEvent) {
      // Currently works in everything but Internet Explorer.
      eventObj = new Event.eventType('Event', type,
          canBubble: canBubble, cancelable: cancelable);

      JS('void', '#.keyCode = #', eventObj, keyCode);
      JS('void', '#.which = #', eventObj, keyCode);
      JS('void', '#.charCode = #', eventObj, charCode);

      JS('void', '#.location = #', eventObj, location);
      JS('void', '#.ctrlKey = #', eventObj, ctrlKey);
      JS('void', '#.altKey = #', eventObj, altKey);
      JS('void', '#.shiftKey = #', eventObj, shiftKey);
      JS('void', '#.metaKey = #', eventObj, metaKey);
    } else {
      // Currently this works on everything but Safari. Safari throws an
      // "Attempting to change access mechanism for an unconfigurable property"
      // TypeError when trying to do the Object.defineProperty hack, so we avoid
      // this branch if possible.
      // Also, if we want this branch to work in FF, we also need to modify
      // _initKeyboardEvent to also take charCode and keyCode values to
      // initialize initKeyEvent.

      eventObj = new Event.eventType('KeyboardEvent', type,
          canBubble: canBubble, cancelable: cancelable);

      // Chromium Hack
      JS(
          'void',
          "Object.defineProperty(#, 'keyCode', {"
          "  get : function() { return this.keyCodeVal; } })",
          eventObj);
      JS(
          'void',
          "Object.defineProperty(#, 'which', {"
          "  get : function() { return this.keyCodeVal; } })",
          eventObj);
      JS(
          'void',
          "Object.defineProperty(#, 'charCode', {"
          "  get : function() { return this.charCodeVal; } })",
          eventObj);

      var keyIdentifier = _convertToHexString(charCode, keyCode);
      eventObj._initKeyboardEvent(type, canBubble, cancelable, view,
          keyIdentifier, location, ctrlKey, altKey, shiftKey, metaKey);
      JS('void', '#.keyCodeVal = #', eventObj, keyCode);
      JS('void', '#.charCodeVal = #', eventObj, charCode);
    }
    // Tell dart2js that it smells like a KeyboardEvent!
    setDispatchProperty(eventObj, _keyboardEventDispatchRecord);

    var keyEvent = new KeyEvent.wrap(eventObj);
    if (keyEvent._currentTarget == null) {
      keyEvent._currentTarget = currentTarget == null ? window : currentTarget;
    }
    return keyEvent;
  }

  // Currently known to work on all browsers but IE.
  static bool get canUseDispatchEvent => JS(
      'bool',
      '(typeof document.body.dispatchEvent == "function")'
      '&& document.body.dispatchEvent.length > 0');

  /** The currently registered target for this event. */
  EventTarget get currentTarget => _currentTarget;

  // This is an experimental method to be sure.
  static String _convertToHexString(int charCode, int keyCode) {
    if (charCode != -1) {
      var hex = charCode.toRadixString(16); // Convert to hexadecimal.
      StringBuffer sb = new StringBuffer('U+');
      for (int i = 0; i < 4 - hex.length; i++) sb.write('0');
      sb.write(hex);
      return sb.toString();
    } else {
      return KeyCode._convertKeyCodeToKeyName(keyCode);
    }
  }

  // TODO(efortuna): If KeyEvent is sufficiently successful that we want to make
  // it the default keyboard event handling, move these methods over to Element.
  /** Accessor to provide a stream of KeyEvents on the desired target. */
  static EventStreamProvider<KeyEvent> keyDownEvent =
      new _KeyboardEventHandler('keydown');
  /** Accessor to provide a stream of KeyEvents on the desired target. */
  static EventStreamProvider<KeyEvent> keyUpEvent =
      new _KeyboardEventHandler('keyup');
  /** Accessor to provide a stream of KeyEvents on the desired target. */
  static EventStreamProvider<KeyEvent> keyPressEvent =
      new _KeyboardEventHandler('keypress');

  String get code => _parent.code;
  /** True if the ctrl key is pressed during this event. */
  bool get ctrlKey => _parent.ctrlKey;
  int get detail => _parent.detail;
  String get key => _parent.key;
  /**
   * Accessor to the part of the keyboard that the key was pressed from (one of
   * KeyLocation.STANDARD, KeyLocation.RIGHT, KeyLocation.LEFT,
   * KeyLocation.NUMPAD, KeyLocation.MOBILE, KeyLocation.JOYSTICK).
   */
  int get location => _parent.location;
  /** True if the Meta (or Mac command) key is pressed during this event. */
  bool get metaKey => _parent.metaKey;
  /** True if the shift key was pressed during this event. */
  bool get shiftKey => _parent.shiftKey;
  Window get view => _parent.view;
  void _initUIEvent(
      String type, bool canBubble, bool cancelable, Window view, int detail) {
    throw new UnsupportedError("Cannot initialize a UI Event from a KeyEvent.");
  }

  String get _shadowKeyIdentifier => JS('String', '#.keyIdentifier', _parent);

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
      int location,
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
  bool get repeat => throw new UnimplementedError();
  dynamic get _get_view => throw new UnimplementedError();
}
