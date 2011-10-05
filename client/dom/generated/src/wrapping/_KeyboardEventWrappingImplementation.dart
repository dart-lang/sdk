// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _KeyboardEventWrappingImplementation extends _UIEventWrappingImplementation implements KeyboardEvent {
  _KeyboardEventWrappingImplementation() : super() {}

  static create__KeyboardEventWrappingImplementation() native {
    return new _KeyboardEventWrappingImplementation();
  }

  bool get altGraphKey() { return _get__KeyboardEvent_altGraphKey(this); }
  static bool _get__KeyboardEvent_altGraphKey(var _this) native;

  bool get altKey() { return _get__KeyboardEvent_altKey(this); }
  static bool _get__KeyboardEvent_altKey(var _this) native;

  bool get ctrlKey() { return _get__KeyboardEvent_ctrlKey(this); }
  static bool _get__KeyboardEvent_ctrlKey(var _this) native;

  String get keyIdentifier() { return _get__KeyboardEvent_keyIdentifier(this); }
  static String _get__KeyboardEvent_keyIdentifier(var _this) native;

  int get keyLocation() { return _get__KeyboardEvent_keyLocation(this); }
  static int _get__KeyboardEvent_keyLocation(var _this) native;

  bool get metaKey() { return _get__KeyboardEvent_metaKey(this); }
  static bool _get__KeyboardEvent_metaKey(var _this) native;

  bool get shiftKey() { return _get__KeyboardEvent_shiftKey(this); }
  static bool _get__KeyboardEvent_shiftKey(var _this) native;

  bool getModifierState(String keyIdentifierArg = null) {
    if (keyIdentifierArg === null) {
      return _getModifierState(this);
    } else {
      return _getModifierState_2(this, keyIdentifierArg);
    }
  }
  static bool _getModifierState(receiver) native;
  static bool _getModifierState_2(receiver, keyIdentifierArg) native;

  void initKeyboardEvent(String type = null, bool canBubble = null, bool cancelable = null, DOMWindow view = null, String keyIdentifier = null, int keyLocation = null, bool ctrlKey = null, bool altKey = null, bool shiftKey = null, bool metaKey = null, bool altGraphKey = null) {
    if (type === null) {
      if (canBubble === null) {
        if (cancelable === null) {
          if (view === null) {
            if (keyIdentifier === null) {
              if (keyLocation === null) {
                if (ctrlKey === null) {
                  if (altKey === null) {
                    if (shiftKey === null) {
                      if (metaKey === null) {
                        if (altGraphKey === null) {
                          _initKeyboardEvent(this);
                          return;
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    } else {
      if (canBubble === null) {
        if (cancelable === null) {
          if (view === null) {
            if (keyIdentifier === null) {
              if (keyLocation === null) {
                if (ctrlKey === null) {
                  if (altKey === null) {
                    if (shiftKey === null) {
                      if (metaKey === null) {
                        if (altGraphKey === null) {
                          _initKeyboardEvent_2(this, type);
                          return;
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      } else {
        if (cancelable === null) {
          if (view === null) {
            if (keyIdentifier === null) {
              if (keyLocation === null) {
                if (ctrlKey === null) {
                  if (altKey === null) {
                    if (shiftKey === null) {
                      if (metaKey === null) {
                        if (altGraphKey === null) {
                          _initKeyboardEvent_3(this, type, canBubble);
                          return;
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        } else {
          if (view === null) {
            if (keyIdentifier === null) {
              if (keyLocation === null) {
                if (ctrlKey === null) {
                  if (altKey === null) {
                    if (shiftKey === null) {
                      if (metaKey === null) {
                        if (altGraphKey === null) {
                          _initKeyboardEvent_4(this, type, canBubble, cancelable);
                          return;
                        }
                      }
                    }
                  }
                }
              }
            }
          } else {
            if (keyIdentifier === null) {
              if (keyLocation === null) {
                if (ctrlKey === null) {
                  if (altKey === null) {
                    if (shiftKey === null) {
                      if (metaKey === null) {
                        if (altGraphKey === null) {
                          _initKeyboardEvent_5(this, type, canBubble, cancelable, view);
                          return;
                        }
                      }
                    }
                  }
                }
              }
            } else {
              if (keyLocation === null) {
                if (ctrlKey === null) {
                  if (altKey === null) {
                    if (shiftKey === null) {
                      if (metaKey === null) {
                        if (altGraphKey === null) {
                          _initKeyboardEvent_6(this, type, canBubble, cancelable, view, keyIdentifier);
                          return;
                        }
                      }
                    }
                  }
                }
              } else {
                if (ctrlKey === null) {
                  if (altKey === null) {
                    if (shiftKey === null) {
                      if (metaKey === null) {
                        if (altGraphKey === null) {
                          _initKeyboardEvent_7(this, type, canBubble, cancelable, view, keyIdentifier, keyLocation);
                          return;
                        }
                      }
                    }
                  }
                } else {
                  if (altKey === null) {
                    if (shiftKey === null) {
                      if (metaKey === null) {
                        if (altGraphKey === null) {
                          _initKeyboardEvent_8(this, type, canBubble, cancelable, view, keyIdentifier, keyLocation, ctrlKey);
                          return;
                        }
                      }
                    }
                  } else {
                    if (shiftKey === null) {
                      if (metaKey === null) {
                        if (altGraphKey === null) {
                          _initKeyboardEvent_9(this, type, canBubble, cancelable, view, keyIdentifier, keyLocation, ctrlKey, altKey);
                          return;
                        }
                      }
                    } else {
                      if (metaKey === null) {
                        if (altGraphKey === null) {
                          _initKeyboardEvent_10(this, type, canBubble, cancelable, view, keyIdentifier, keyLocation, ctrlKey, altKey, shiftKey);
                          return;
                        }
                      } else {
                        if (altGraphKey === null) {
                          _initKeyboardEvent_11(this, type, canBubble, cancelable, view, keyIdentifier, keyLocation, ctrlKey, altKey, shiftKey, metaKey);
                          return;
                        } else {
                          _initKeyboardEvent_12(this, type, canBubble, cancelable, view, keyIdentifier, keyLocation, ctrlKey, altKey, shiftKey, metaKey, altGraphKey);
                          return;
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initKeyboardEvent(receiver) native;
  static void _initKeyboardEvent_2(receiver, type) native;
  static void _initKeyboardEvent_3(receiver, type, canBubble) native;
  static void _initKeyboardEvent_4(receiver, type, canBubble, cancelable) native;
  static void _initKeyboardEvent_5(receiver, type, canBubble, cancelable, view) native;
  static void _initKeyboardEvent_6(receiver, type, canBubble, cancelable, view, keyIdentifier) native;
  static void _initKeyboardEvent_7(receiver, type, canBubble, cancelable, view, keyIdentifier, keyLocation) native;
  static void _initKeyboardEvent_8(receiver, type, canBubble, cancelable, view, keyIdentifier, keyLocation, ctrlKey) native;
  static void _initKeyboardEvent_9(receiver, type, canBubble, cancelable, view, keyIdentifier, keyLocation, ctrlKey, altKey) native;
  static void _initKeyboardEvent_10(receiver, type, canBubble, cancelable, view, keyIdentifier, keyLocation, ctrlKey, altKey, shiftKey) native;
  static void _initKeyboardEvent_11(receiver, type, canBubble, cancelable, view, keyIdentifier, keyLocation, ctrlKey, altKey, shiftKey, metaKey) native;
  static void _initKeyboardEvent_12(receiver, type, canBubble, cancelable, view, keyIdentifier, keyLocation, ctrlKey, altKey, shiftKey, metaKey, altGraphKey) native;

  String get typeName() { return "KeyboardEvent"; }
}
