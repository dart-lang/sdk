// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TouchEventWrappingImplementation extends _UIEventWrappingImplementation implements TouchEvent {
  _TouchEventWrappingImplementation() : super() {}

  static create__TouchEventWrappingImplementation() native {
    return new _TouchEventWrappingImplementation();
  }

  bool get altKey() { return _get__TouchEvent_altKey(this); }
  static bool _get__TouchEvent_altKey(var _this) native;

  TouchList get changedTouches() { return _get__TouchEvent_changedTouches(this); }
  static TouchList _get__TouchEvent_changedTouches(var _this) native;

  bool get ctrlKey() { return _get__TouchEvent_ctrlKey(this); }
  static bool _get__TouchEvent_ctrlKey(var _this) native;

  bool get metaKey() { return _get__TouchEvent_metaKey(this); }
  static bool _get__TouchEvent_metaKey(var _this) native;

  bool get shiftKey() { return _get__TouchEvent_shiftKey(this); }
  static bool _get__TouchEvent_shiftKey(var _this) native;

  TouchList get targetTouches() { return _get__TouchEvent_targetTouches(this); }
  static TouchList _get__TouchEvent_targetTouches(var _this) native;

  TouchList get touches() { return _get__TouchEvent_touches(this); }
  static TouchList _get__TouchEvent_touches(var _this) native;

  void initTouchEvent(TouchList touches = null, TouchList targetTouches = null, TouchList changedTouches = null, String type = null, DOMWindow view = null, int screenX = null, int screenY = null, int clientX = null, int clientY = null, bool ctrlKey = null, bool altKey = null, bool shiftKey = null, bool metaKey = null) {
    if (touches === null) {
      if (targetTouches === null) {
        if (changedTouches === null) {
          if (type === null) {
            if (view === null) {
              if (screenX === null) {
                if (screenY === null) {
                  if (clientX === null) {
                    if (clientY === null) {
                      if (ctrlKey === null) {
                        if (altKey === null) {
                          if (shiftKey === null) {
                            if (metaKey === null) {
                              _initTouchEvent(this);
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
      }
    } else {
      if (targetTouches === null) {
        if (changedTouches === null) {
          if (type === null) {
            if (view === null) {
              if (screenX === null) {
                if (screenY === null) {
                  if (clientX === null) {
                    if (clientY === null) {
                      if (ctrlKey === null) {
                        if (altKey === null) {
                          if (shiftKey === null) {
                            if (metaKey === null) {
                              _initTouchEvent_2(this, touches);
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
      } else {
        if (changedTouches === null) {
          if (type === null) {
            if (view === null) {
              if (screenX === null) {
                if (screenY === null) {
                  if (clientX === null) {
                    if (clientY === null) {
                      if (ctrlKey === null) {
                        if (altKey === null) {
                          if (shiftKey === null) {
                            if (metaKey === null) {
                              _initTouchEvent_3(this, touches, targetTouches);
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
          if (type === null) {
            if (view === null) {
              if (screenX === null) {
                if (screenY === null) {
                  if (clientX === null) {
                    if (clientY === null) {
                      if (ctrlKey === null) {
                        if (altKey === null) {
                          if (shiftKey === null) {
                            if (metaKey === null) {
                              _initTouchEvent_4(this, touches, targetTouches, changedTouches);
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
                              _initTouchEvent_5(this, touches, targetTouches, changedTouches, type);
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
                              _initTouchEvent_6(this, touches, targetTouches, changedTouches, type, view);
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
                              _initTouchEvent_7(this, touches, targetTouches, changedTouches, type, view, screenX);
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
                              _initTouchEvent_8(this, touches, targetTouches, changedTouches, type, view, screenX, screenY);
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
                              _initTouchEvent_9(this, touches, targetTouches, changedTouches, type, view, screenX, screenY, clientX);
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
                              _initTouchEvent_10(this, touches, targetTouches, changedTouches, type, view, screenX, screenY, clientX, clientY);
                              return;
                            }
                          }
                        }
                      } else {
                        if (altKey === null) {
                          if (shiftKey === null) {
                            if (metaKey === null) {
                              _initTouchEvent_11(this, touches, targetTouches, changedTouches, type, view, screenX, screenY, clientX, clientY, ctrlKey);
                              return;
                            }
                          }
                        } else {
                          if (shiftKey === null) {
                            if (metaKey === null) {
                              _initTouchEvent_12(this, touches, targetTouches, changedTouches, type, view, screenX, screenY, clientX, clientY, ctrlKey, altKey);
                              return;
                            }
                          } else {
                            if (metaKey === null) {
                              _initTouchEvent_13(this, touches, targetTouches, changedTouches, type, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey);
                              return;
                            } else {
                              _initTouchEvent_14(this, touches, targetTouches, changedTouches, type, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey);
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
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initTouchEvent(receiver) native;
  static void _initTouchEvent_2(receiver, touches) native;
  static void _initTouchEvent_3(receiver, touches, targetTouches) native;
  static void _initTouchEvent_4(receiver, touches, targetTouches, changedTouches) native;
  static void _initTouchEvent_5(receiver, touches, targetTouches, changedTouches, type) native;
  static void _initTouchEvent_6(receiver, touches, targetTouches, changedTouches, type, view) native;
  static void _initTouchEvent_7(receiver, touches, targetTouches, changedTouches, type, view, screenX) native;
  static void _initTouchEvent_8(receiver, touches, targetTouches, changedTouches, type, view, screenX, screenY) native;
  static void _initTouchEvent_9(receiver, touches, targetTouches, changedTouches, type, view, screenX, screenY, clientX) native;
  static void _initTouchEvent_10(receiver, touches, targetTouches, changedTouches, type, view, screenX, screenY, clientX, clientY) native;
  static void _initTouchEvent_11(receiver, touches, targetTouches, changedTouches, type, view, screenX, screenY, clientX, clientY, ctrlKey) native;
  static void _initTouchEvent_12(receiver, touches, targetTouches, changedTouches, type, view, screenX, screenY, clientX, clientY, ctrlKey, altKey) native;
  static void _initTouchEvent_13(receiver, touches, targetTouches, changedTouches, type, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey) native;
  static void _initTouchEvent_14(receiver, touches, targetTouches, changedTouches, type, view, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey) native;

  String get typeName() { return "TouchEvent"; }
}
