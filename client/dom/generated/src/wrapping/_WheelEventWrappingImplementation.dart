// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WheelEventWrappingImplementation extends _UIEventWrappingImplementation implements WheelEvent {
  _WheelEventWrappingImplementation() : super() {}

  static create__WheelEventWrappingImplementation() native {
    return new _WheelEventWrappingImplementation();
  }

  bool get altKey() { return _get__WheelEvent_altKey(this); }
  static bool _get__WheelEvent_altKey(var _this) native;

  int get clientX() { return _get__WheelEvent_clientX(this); }
  static int _get__WheelEvent_clientX(var _this) native;

  int get clientY() { return _get__WheelEvent_clientY(this); }
  static int _get__WheelEvent_clientY(var _this) native;

  bool get ctrlKey() { return _get__WheelEvent_ctrlKey(this); }
  static bool _get__WheelEvent_ctrlKey(var _this) native;

  bool get metaKey() { return _get__WheelEvent_metaKey(this); }
  static bool _get__WheelEvent_metaKey(var _this) native;

  int get offsetX() { return _get__WheelEvent_offsetX(this); }
  static int _get__WheelEvent_offsetX(var _this) native;

  int get offsetY() { return _get__WheelEvent_offsetY(this); }
  static int _get__WheelEvent_offsetY(var _this) native;

  int get screenX() { return _get__WheelEvent_screenX(this); }
  static int _get__WheelEvent_screenX(var _this) native;

  int get screenY() { return _get__WheelEvent_screenY(this); }
  static int _get__WheelEvent_screenY(var _this) native;

  bool get shiftKey() { return _get__WheelEvent_shiftKey(this); }
  static bool _get__WheelEvent_shiftKey(var _this) native;

  int get wheelDelta() { return _get__WheelEvent_wheelDelta(this); }
  static int _get__WheelEvent_wheelDelta(var _this) native;

  int get wheelDeltaX() { return _get__WheelEvent_wheelDeltaX(this); }
  static int _get__WheelEvent_wheelDeltaX(var _this) native;

  int get wheelDeltaY() { return _get__WheelEvent_wheelDeltaY(this); }
  static int _get__WheelEvent_wheelDeltaY(var _this) native;

  int get x() { return _get__WheelEvent_x(this); }
  static int _get__WheelEvent_x(var _this) native;

  int get y() { return _get__WheelEvent_y(this); }
  static int _get__WheelEvent_y(var _this) native;

  void initWheelEvent(int wheelDeltaX = null, int wheelDeltaY = null, DOMWindow view = null, int screenX = null, int screenY = null, int clientX = null, int clientY = null, bool ctrlKey = null, bool altKey = null, bool shiftKey = null, bool metaKey = null) {
    if (wheelDeltaX === null) {
      if (wheelDeltaY === null) {
        if (view === null) {
          if (screenX === null) {
            if (screenY === null) {
              if (clientX === null) {
                if (clientY === null) {
                  if (ctrlKey === null) {
                    if (altKey === null) {
                      if (shiftKey === null) {
                        if (metaKey === null) {
                          _initWheelEvent(this);
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
      if (wheelDeltaY === null) {
        if (view === null) {
          if (screenX === null) {
            if (screenY === null) {
              if (clientX === null) {
                if (clientY === null) {
                  if (ctrlKey === null) {
                    if (altKey === null) {
                      if (shiftKey === null) {
                        if (metaKey === null) {
                          _initWheelEvent_2(this, wheelDeltaX);
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
        if (view === null) {
          if (screenX === null) {
            if (screenY === null) {
              if (clientX === null) {
                if (clientY === null) {
                  if (ctrlKey === null) {
                    if (altKey === null) {
                      if (shiftKey === null) {
                        if (metaKey === null) {
                          _initWheelEvent_3(this, wheelDeltaX, wheelDeltaY);
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
          if (screenX === null) {
            if (screenY === null) {
              if (clientX === null) {
                if (clientY === null) {
                  if (ctrlKey === null) {
                    if (altKey === null) {
                      if (shiftKey === null) {
                        if (metaKey === null) {
                          _initWheelEvent_4(this, wheelDeltaX, wheelDeltaY, view);
                          return;
                        }
                      }
                    }
                  }
                }
              }
            }
          } else {
            if (screenY === null) {
              if (clientX === null) {
                if (clientY === null) {
                  if (ctrlKey === null) {
                    if (altKey === null) {
                      if (shiftKey === null) {
                        if (metaKey === null) {
                          _initWheelEvent_5(this, wheelDeltaX, wheelDeltaY, view, screenX);
                          return;
                        }
                      }
                    }
                  }
                }
              }
            } else {
              if (clientX === null) {
                if (clientY === null) {
                  if (ctrlKey === null) {
                    if (altKey === null) {
                      if (shiftKey === null) {
                        if (metaKey === null) {
                          _initWheelEvent_6(this, wheelDeltaX, wheelDeltaY, view, screenX, screenY);
                          return;
                        }
                      }
                    }
                  }
                }
              } else {
                if (clientY === null) {
                  if (ctrlKey === null) {
                    if (altKey === null) {
                      if (shiftKey === null) {
                        if (metaKey === null) {
                          _initWheelEvent_7(this, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX);
                          return;
                        }
                      }
                    }
                  }
                } else {
                  if (ctrlKey === null) {
                    if (altKey === null) {
                      if (shiftKey === null) {
                        if (metaKey === null) {
                          _initWheelEvent_8(this, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX, clientY);
                          return;
                        }
                      }
                    }
                  } else {
                    if (altKey === null) {
                      if (shiftKey === null) {
                        if (metaKey === null) {
                          _initWheelEvent_9(this, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX, clientY, ctrlKey);
                          return;
                        }
                      }
                    } else {
                      if (shiftKey === null) {
                        if (metaKey === null) {
                          _initWheelEvent_10(this, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX, clientY, ctrlKey, altKey);
                          return;
                        }
                      } else {
                        if (metaKey === null) {
                          _initWheelEvent_11(this, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey);
                          return;
                        } else {
                          _initWheelEvent_12(this, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey);
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
  static void _initWheelEvent(receiver) native;
  static void _initWheelEvent_2(receiver, wheelDeltaX) native;
  static void _initWheelEvent_3(receiver, wheelDeltaX, wheelDeltaY) native;
  static void _initWheelEvent_4(receiver, wheelDeltaX, wheelDeltaY, view) native;
  static void _initWheelEvent_5(receiver, wheelDeltaX, wheelDeltaY, view, screenX) native;
  static void _initWheelEvent_6(receiver, wheelDeltaX, wheelDeltaY, view, screenX, screenY) native;
  static void _initWheelEvent_7(receiver, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX) native;
  static void _initWheelEvent_8(receiver, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX, clientY) native;
  static void _initWheelEvent_9(receiver, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX, clientY, ctrlKey) native;
  static void _initWheelEvent_10(receiver, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX, clientY, ctrlKey, altKey) native;
  static void _initWheelEvent_11(receiver, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey) native;
  static void _initWheelEvent_12(receiver, wheelDeltaX, wheelDeltaY, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey) native;

  String get typeName() { return "WheelEvent"; }
}
