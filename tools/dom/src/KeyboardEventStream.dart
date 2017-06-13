// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

/**
 * Internal class that does the actual calculations to determine keyCode and
 * charCode for keydown, keypress, and keyup events for all browsers.
 */
class _KeyboardEventHandler extends EventStreamProvider<KeyEvent> {
  // This code inspired by Closure's KeyHandling library.
  // http://closure-library.googlecode.com/svn/docs/closure_goog_events_keyhandler.js.source.html

  /**
   * The set of keys that have been pressed down without seeing their
   * corresponding keyup event.
   */
  final List<KeyEvent> _keyDownList = <KeyEvent>[];

  /** The type of KeyEvent we are tracking (keyup, keydown, keypress). */
  final String _type;

  /** The element we are watching for events to happen on. */
  final EventTarget _target;

  // The distance to shift from upper case alphabet Roman letters to lower case.
  static final int _ROMAN_ALPHABET_OFFSET = "a".codeUnits[0] - "A".codeUnits[0];

  /** Custom Stream (Controller) to produce KeyEvents for the stream. */
  _CustomKeyEventStreamImpl _stream;

  static const _EVENT_TYPE = 'KeyEvent';

  /**
   * An enumeration of key identifiers currently part of the W3C draft for DOM3
   * and their mappings to keyCodes.
   * http://www.w3.org/TR/DOM-Level-3-Events/keyset.html#KeySet-Set
   */
  static const Map<String, int> _keyIdentifier = const {
    'Up': KeyCode.UP,
    'Down': KeyCode.DOWN,
    'Left': KeyCode.LEFT,
    'Right': KeyCode.RIGHT,
    'Enter': KeyCode.ENTER,
    'F1': KeyCode.F1,
    'F2': KeyCode.F2,
    'F3': KeyCode.F3,
    'F4': KeyCode.F4,
    'F5': KeyCode.F5,
    'F6': KeyCode.F6,
    'F7': KeyCode.F7,
    'F8': KeyCode.F8,
    'F9': KeyCode.F9,
    'F10': KeyCode.F10,
    'F11': KeyCode.F11,
    'F12': KeyCode.F12,
    'U+007F': KeyCode.DELETE,
    'Home': KeyCode.HOME,
    'End': KeyCode.END,
    'PageUp': KeyCode.PAGE_UP,
    'PageDown': KeyCode.PAGE_DOWN,
    'Insert': KeyCode.INSERT
  };

  /** Return a stream for KeyEvents for the specified target. */
  // Note: this actually functions like a factory constructor.
  CustomStream<KeyEvent> forTarget(EventTarget e, {bool useCapture: false}) {
    var handler =
        new _KeyboardEventHandler.initializeAllEventListeners(_type, e);
    return handler._stream;
  }

  /**
   * General constructor, performs basic initialization for our improved
   * KeyboardEvent controller.
   */
  _KeyboardEventHandler(this._type)
      : _stream = new _CustomKeyEventStreamImpl('event'),
        _target = null,
        super(_EVENT_TYPE);

  /**
   * Hook up all event listeners under the covers so we can estimate keycodes
   * and charcodes when they are not provided.
   */
  _KeyboardEventHandler.initializeAllEventListeners(this._type, this._target)
      : super(_EVENT_TYPE) {
    Element.keyDownEvent
        .forTarget(_target, useCapture: true)
        .listen(processKeyDown);
    Element.keyPressEvent
        .forTarget(_target, useCapture: true)
        .listen(processKeyPress);
    Element.keyUpEvent
        .forTarget(_target, useCapture: true)
        .listen(processKeyUp);
    _stream = new _CustomKeyEventStreamImpl(_type);
  }

  /** Determine if caps lock is one of the currently depressed keys. */
  bool get _capsLockOn =>
      _keyDownList.any((var element) => element.keyCode == KeyCode.CAPS_LOCK);

  /**
   * Given the previously recorded keydown key codes, see if we can determine
   * the keycode of this keypress [event]. (Generally browsers only provide
   * charCode information for keypress events, but with a little
   * reverse-engineering, we can also determine the keyCode.) Returns
   * KeyCode.UNKNOWN if the keycode could not be determined.
   */
  int _determineKeyCodeForKeypress(KeyboardEvent event) {
    // Note: This function is a work in progress. We'll expand this function
    // once we get more information about other keyboards.
    for (var prevEvent in _keyDownList) {
      if (prevEvent._shadowCharCode == event.charCode) {
        return prevEvent.keyCode;
      }
      if ((event.shiftKey || _capsLockOn) &&
          event.charCode >= "A".codeUnits[0] &&
          event.charCode <= "Z".codeUnits[0] &&
          event.charCode + _ROMAN_ALPHABET_OFFSET ==
              prevEvent._shadowCharCode) {
        return prevEvent.keyCode;
      }
    }
    return KeyCode.UNKNOWN;
  }

  /**
   * Given the character code returned from a keyDown [event], try to ascertain
   * and return the corresponding charCode for the character that was pressed.
   * This information is not shown to the user, but used to help polyfill
   * keypress events.
   */
  int _findCharCodeKeyDown(KeyboardEvent event) {
    if (event.location == 3) {
      // Numpad keys.
      switch (event.keyCode) {
        case KeyCode.NUM_ZERO:
          // Even though this function returns _charCodes_, for some cases the
          // KeyCode == the charCode we want, in which case we use the keycode
          // constant for readability.
          return KeyCode.ZERO;
        case KeyCode.NUM_ONE:
          return KeyCode.ONE;
        case KeyCode.NUM_TWO:
          return KeyCode.TWO;
        case KeyCode.NUM_THREE:
          return KeyCode.THREE;
        case KeyCode.NUM_FOUR:
          return KeyCode.FOUR;
        case KeyCode.NUM_FIVE:
          return KeyCode.FIVE;
        case KeyCode.NUM_SIX:
          return KeyCode.SIX;
        case KeyCode.NUM_SEVEN:
          return KeyCode.SEVEN;
        case KeyCode.NUM_EIGHT:
          return KeyCode.EIGHT;
        case KeyCode.NUM_NINE:
          return KeyCode.NINE;
        case KeyCode.NUM_MULTIPLY:
          return 42; // Char code for *
        case KeyCode.NUM_PLUS:
          return 43; // +
        case KeyCode.NUM_MINUS:
          return 45; // -
        case KeyCode.NUM_PERIOD:
          return 46; // .
        case KeyCode.NUM_DIVISION:
          return 47; // /
      }
    } else if (event.keyCode >= 65 && event.keyCode <= 90) {
      // Set the "char code" for key down as the lower case letter. Again, this
      // will not show up for the user, but will be helpful in estimating
      // keyCode locations and other information during the keyPress event.
      return event.keyCode + _ROMAN_ALPHABET_OFFSET;
    }
    switch (event.keyCode) {
      case KeyCode.SEMICOLON:
        return KeyCode.FF_SEMICOLON;
      case KeyCode.EQUALS:
        return KeyCode.FF_EQUALS;
      case KeyCode.COMMA:
        return 44; // Ascii value for ,
      case KeyCode.DASH:
        return 45; // -
      case KeyCode.PERIOD:
        return 46; // .
      case KeyCode.SLASH:
        return 47; // /
      case KeyCode.APOSTROPHE:
        return 96; // `
      case KeyCode.OPEN_SQUARE_BRACKET:
        return 91; // [
      case KeyCode.BACKSLASH:
        return 92; // \
      case KeyCode.CLOSE_SQUARE_BRACKET:
        return 93; // ]
      case KeyCode.SINGLE_QUOTE:
        return 39; // '
    }
    return event.keyCode;
  }

  /**
   * Returns true if the key fires a keypress event in the current browser.
   */
  bool _firesKeyPressEvent(KeyEvent event) {
    if (!Device.isIE && !Device.isWebKit) {
      return true;
    }

    if (Device.userAgent.contains('Mac') && event.altKey) {
      return KeyCode.isCharacterKey(event.keyCode);
    }

    // Alt but not AltGr which is represented as Alt+Ctrl.
    if (event.altKey && !event.ctrlKey) {
      return false;
    }

    // Saves Ctrl or Alt + key for IE and WebKit, which won't fire keypress.
    if (!event.shiftKey &&
        (_keyDownList.last.keyCode == KeyCode.CTRL ||
            _keyDownList.last.keyCode == KeyCode.ALT ||
            Device.userAgent.contains('Mac') &&
                _keyDownList.last.keyCode == KeyCode.META)) {
      return false;
    }

    // Some keys with Ctrl/Shift do not issue keypress in WebKit.
    if (Device.isWebKit &&
        event.ctrlKey &&
        event.shiftKey &&
        (event.keyCode == KeyCode.BACKSLASH ||
            event.keyCode == KeyCode.OPEN_SQUARE_BRACKET ||
            event.keyCode == KeyCode.CLOSE_SQUARE_BRACKET ||
            event.keyCode == KeyCode.TILDE ||
            event.keyCode == KeyCode.SEMICOLON ||
            event.keyCode == KeyCode.DASH ||
            event.keyCode == KeyCode.EQUALS ||
            event.keyCode == KeyCode.COMMA ||
            event.keyCode == KeyCode.PERIOD ||
            event.keyCode == KeyCode.SLASH ||
            event.keyCode == KeyCode.APOSTROPHE ||
            event.keyCode == KeyCode.SINGLE_QUOTE)) {
      return false;
    }

    switch (event.keyCode) {
      case KeyCode.ENTER:
        // IE9 does not fire keypress on ENTER.
        return !Device.isIE;
      case KeyCode.ESC:
        return !Device.isWebKit;
    }

    return KeyCode.isCharacterKey(event.keyCode);
  }

  /**
   * Normalize the keycodes to the IE KeyCodes (this is what Chrome, IE, and
   * Opera all use).
   */
  int _normalizeKeyCodes(KeyboardEvent event) {
    // Note: This may change once we get input about non-US keyboards.
    if (Device.isFirefox) {
      switch (event.keyCode) {
        case KeyCode.FF_EQUALS:
          return KeyCode.EQUALS;
        case KeyCode.FF_SEMICOLON:
          return KeyCode.SEMICOLON;
        case KeyCode.MAC_FF_META:
          return KeyCode.META;
        case KeyCode.WIN_KEY_FF_LINUX:
          return KeyCode.WIN_KEY;
      }
    }
    return event.keyCode;
  }

  /** Handle keydown events. */
  void processKeyDown(KeyboardEvent e) {
    // Ctrl-Tab and Alt-Tab can cause the focus to be moved to another window
    // before we've caught a key-up event.  If the last-key was one of these
    // we reset the state.
    if (_keyDownList.length > 0 &&
        (_keyDownList.last.keyCode == KeyCode.CTRL && !e.ctrlKey ||
            _keyDownList.last.keyCode == KeyCode.ALT && !e.altKey ||
            Device.userAgent.contains('Mac') &&
                _keyDownList.last.keyCode == KeyCode.META &&
                !e.metaKey)) {
      _keyDownList.clear();
    }

    var event = new KeyEvent.wrap(e);
    event._shadowKeyCode = _normalizeKeyCodes(event);
    // Technically a "keydown" event doesn't have a charCode. This is
    // calculated nonetheless to provide us with more information in giving
    // as much information as possible on keypress about keycode and also
    // charCode.
    event._shadowCharCode = _findCharCodeKeyDown(event);
    if (_keyDownList.length > 0 &&
        event.keyCode != _keyDownList.last.keyCode &&
        !_firesKeyPressEvent(event)) {
      // Some browsers have quirks not firing keypress events where all other
      // browsers do. This makes them more consistent.
      processKeyPress(e);
    }
    _keyDownList.add(event);
    _stream.add(event);
  }

  /** Handle keypress events. */
  void processKeyPress(KeyboardEvent event) {
    var e = new KeyEvent.wrap(event);
    // IE reports the character code in the keyCode field for keypress events.
    // There are two exceptions however, Enter and Escape.
    if (Device.isIE) {
      if (e.keyCode == KeyCode.ENTER || e.keyCode == KeyCode.ESC) {
        e._shadowCharCode = 0;
      } else {
        e._shadowCharCode = e.keyCode;
      }
    } else if (Device.isOpera) {
      // Opera reports the character code in the keyCode field.
      e._shadowCharCode = KeyCode.isCharacterKey(e.keyCode) ? e.keyCode : 0;
    }
    // Now we guestimate about what the keycode is that was actually
    // pressed, given previous keydown information.
    e._shadowKeyCode = _determineKeyCodeForKeypress(e);

    // Correct the key value for certain browser-specific quirks.
    if (e._shadowKeyIdentifier != null &&
        _keyIdentifier.containsKey(e._shadowKeyIdentifier)) {
      // This is needed for Safari Windows because it currently doesn't give a
      // keyCode/which for non printable keys.
      e._shadowKeyCode = _keyIdentifier[e._shadowKeyIdentifier];
    }
    e._shadowAltKey = _keyDownList.any((var element) => element.altKey);
    _stream.add(e);
  }

  /** Handle keyup events. */
  void processKeyUp(KeyboardEvent event) {
    var e = new KeyEvent.wrap(event);
    KeyboardEvent toRemove = null;
    for (var key in _keyDownList) {
      if (key.keyCode == e.keyCode) {
        toRemove = key;
      }
    }
    if (toRemove != null) {
      _keyDownList.removeWhere((element) => element == toRemove);
    } else if (_keyDownList.length > 0) {
      // This happens when we've reached some international keyboard case we
      // haven't accounted for or we haven't correctly eliminated all browser
      // inconsistencies. Filing bugs on when this is reached is welcome!
      _keyDownList.removeLast();
    }
    _stream.add(e);
  }
}

/**
 * Records KeyboardEvents that occur on a particular element, and provides a
 * stream of outgoing KeyEvents with cross-browser consistent keyCode and
 * charCode values despite the fact that a multitude of browsers that have
 * varying keyboard default behavior.
 *
 * Example usage:
 *
 *     KeyboardEventStream.onKeyDown(document.body).listen(
 *         keydownHandlerTest);
 *
 * This class is very much a work in progress, and we'd love to get information
 * on how we can make this class work with as many international keyboards as
 * possible. Bugs welcome!
 */
class KeyboardEventStream {
  /** Named constructor to produce a stream for onKeyPress events. */
  static CustomStream<KeyEvent> onKeyPress(EventTarget target) =>
      new _KeyboardEventHandler('keypress').forTarget(target);

  /** Named constructor to produce a stream for onKeyUp events. */
  static CustomStream<KeyEvent> onKeyUp(EventTarget target) =>
      new _KeyboardEventHandler('keyup').forTarget(target);

  /** Named constructor to produce a stream for onKeyDown events. */
  static CustomStream<KeyEvent> onKeyDown(EventTarget target) =>
      new _KeyboardEventHandler('keydown').forTarget(target);
}
