// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MouseEventWrappingImplementation extends _UIEventWrappingImplementation implements MouseEvent {
  _MouseEventWrappingImplementation() : super() {}

  static create__MouseEventWrappingImplementation() native {
    return new _MouseEventWrappingImplementation();
  }

  bool get altKey() { return _get__MouseEvent_altKey(this); }
  static bool _get__MouseEvent_altKey(var _this) native;

  int get button() { return _get__MouseEvent_button(this); }
  static int _get__MouseEvent_button(var _this) native;

  int get clientX() { return _get__MouseEvent_clientX(this); }
  static int _get__MouseEvent_clientX(var _this) native;

  int get clientY() { return _get__MouseEvent_clientY(this); }
  static int _get__MouseEvent_clientY(var _this) native;

  bool get ctrlKey() { return _get__MouseEvent_ctrlKey(this); }
  static bool _get__MouseEvent_ctrlKey(var _this) native;

  Node get fromElement() { return _get__MouseEvent_fromElement(this); }
  static Node _get__MouseEvent_fromElement(var _this) native;

  bool get metaKey() { return _get__MouseEvent_metaKey(this); }
  static bool _get__MouseEvent_metaKey(var _this) native;

  int get offsetX() { return _get__MouseEvent_offsetX(this); }
  static int _get__MouseEvent_offsetX(var _this) native;

  int get offsetY() { return _get__MouseEvent_offsetY(this); }
  static int _get__MouseEvent_offsetY(var _this) native;

  EventTarget get relatedTarget() { return _get__MouseEvent_relatedTarget(this); }
  static EventTarget _get__MouseEvent_relatedTarget(var _this) native;

  int get screenX() { return _get__MouseEvent_screenX(this); }
  static int _get__MouseEvent_screenX(var _this) native;

  int get screenY() { return _get__MouseEvent_screenY(this); }
  static int _get__MouseEvent_screenY(var _this) native;

  bool get shiftKey() { return _get__MouseEvent_shiftKey(this); }
  static bool _get__MouseEvent_shiftKey(var _this) native;

  Node get toElement() { return _get__MouseEvent_toElement(this); }
  static Node _get__MouseEvent_toElement(var _this) native;

  int get x() { return _get__MouseEvent_x(this); }
  static int _get__MouseEvent_x(var _this) native;

  int get y() { return _get__MouseEvent_y(this); }
  static int _get__MouseEvent_y(var _this) native;

  void initMouseEvent([String type = null, bool canBubble = null, bool cancelable = null, DOMWindow view = null, int detail = null, int screenX = null, int screenY = null, int clientX = null, int clientY = null, bool ctrlKey = null, bool altKey = null, bool shiftKey = null, bool metaKey = null, int button = null, EventTarget relatedTarget = null]) {
    if (type === null) {
      if (canBubble === null) {
        if (cancelable === null) {
          if (view === null) {
            if (detail === null) {
              if (screenX === null) {
                if (screenY === null) {
                  if (clientX === null) {
                    if (clientY === null) {
                      if (ctrlKey === null) {
                        if (altKey === null) {
                          if (shiftKey === null) {
                            if (metaKey === null) {
                              if (button === null) {
                                if (relatedTarget === null) {
                                  _initMouseEvent(this);
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
      }
    } else {
      if (canBubble === null) {
        if (cancelable === null) {
          if (view === null) {
            if (detail === null) {
              if (screenX === null) {
                if (screenY === null) {
                  if (clientX === null) {
                    if (clientY === null) {
                      if (ctrlKey === null) {
                        if (altKey === null) {
                          if (shiftKey === null) {
                            if (metaKey === null) {
                              if (button === null) {
                                if (relatedTarget === null) {
                                  _initMouseEvent_2(this, type);
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
      } else {
        if (cancelable === null) {
          if (view === null) {
            if (detail === null) {
              if (screenX === null) {
                if (screenY === null) {
                  if (clientX === null) {
                    if (clientY === null) {
                      if (ctrlKey === null) {
                        if (altKey === null) {
                          if (shiftKey === null) {
                            if (metaKey === null) {
                              if (button === null) {
                                if (relatedTarget === null) {
                                  _initMouseEvent_3(this, type, canBubble);
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
          if (view === null) {
            if (detail === null) {
              if (screenX === null) {
                if (screenY === null) {
                  if (clientX === null) {
                    if (clientY === null) {
                      if (ctrlKey === null) {
                        if (altKey === null) {
                          if (shiftKey === null) {
                            if (metaKey === null) {
                              if (button === null) {
                                if (relatedTarget === null) {
                                  _initMouseEvent_4(this, type, canBubble, cancelable);
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
            if (detail === null) {
              if (screenX === null) {
                if (screenY === null) {
                  if (clientX === null) {
                    if (clientY === null) {
                      if (ctrlKey === null) {
                        if (altKey === null) {
                          if (shiftKey === null) {
                            if (metaKey === null) {
                              if (button === null) {
                                if (relatedTarget === null) {
                                  _initMouseEvent_5(this, type, canBubble, cancelable, view);
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
              if (screenX === null) {
                if (screenY === null) {
                  if (clientX === null) {
                    if (clientY === null) {
                      if (ctrlKey === null) {
                        if (altKey === null) {
                          if (shiftKey === null) {
                            if (metaKey === null) {
                              if (button === null) {
                                if (relatedTarget === null) {
                                  _initMouseEvent_6(this, type, canBubble, cancelable, view, detail);
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
                if (screenY === null) {
                  if (clientX === null) {
                    if (clientY === null) {
                      if (ctrlKey === null) {
                        if (altKey === null) {
                          if (shiftKey === null) {
                            if (metaKey === null) {
                              if (button === null) {
                                if (relatedTarget === null) {
                                  _initMouseEvent_7(this, type, canBubble, cancelable, view, detail, screenX);
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
                  if (clientX === null) {
                    if (clientY === null) {
                      if (ctrlKey === null) {
                        if (altKey === null) {
                          if (shiftKey === null) {
                            if (metaKey === null) {
                              if (button === null) {
                                if (relatedTarget === null) {
                                  _initMouseEvent_8(this, type, canBubble, cancelable, view, detail, screenX, screenY);
                                  return;
                                }
                              }
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
                              if (button === null) {
                                if (relatedTarget === null) {
                                  _initMouseEvent_9(this, type, canBubble, cancelable, view, detail, screenX, screenY, clientX);
                                  return;
                                }
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
                              if (button === null) {
                                if (relatedTarget === null) {
                                  _initMouseEvent_10(this, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY);
                                  return;
                                }
                              }
                            }
                          }
                        }
                      } else {
                        if (altKey === null) {
                          if (shiftKey === null) {
                            if (metaKey === null) {
                              if (button === null) {
                                if (relatedTarget === null) {
                                  _initMouseEvent_11(this, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey);
                                  return;
                                }
                              }
                            }
                          }
                        } else {
                          if (shiftKey === null) {
                            if (metaKey === null) {
                              if (button === null) {
                                if (relatedTarget === null) {
                                  _initMouseEvent_12(this, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey);
                                  return;
                                }
                              }
                            }
                          } else {
                            if (metaKey === null) {
                              if (button === null) {
                                if (relatedTarget === null) {
                                  _initMouseEvent_13(this, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey);
                                  return;
                                }
                              }
                            } else {
                              if (button === null) {
                                if (relatedTarget === null) {
                                  _initMouseEvent_14(this, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey);
                                  return;
                                }
                              } else {
                                if (relatedTarget === null) {
                                  _initMouseEvent_15(this, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button);
                                  return;
                                } else {
                                  _initMouseEvent_16(this, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget);
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
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initMouseEvent(receiver) native;
  static void _initMouseEvent_2(receiver, type) native;
  static void _initMouseEvent_3(receiver, type, canBubble) native;
  static void _initMouseEvent_4(receiver, type, canBubble, cancelable) native;
  static void _initMouseEvent_5(receiver, type, canBubble, cancelable, view) native;
  static void _initMouseEvent_6(receiver, type, canBubble, cancelable, view, detail) native;
  static void _initMouseEvent_7(receiver, type, canBubble, cancelable, view, detail, screenX) native;
  static void _initMouseEvent_8(receiver, type, canBubble, cancelable, view, detail, screenX, screenY) native;
  static void _initMouseEvent_9(receiver, type, canBubble, cancelable, view, detail, screenX, screenY, clientX) native;
  static void _initMouseEvent_10(receiver, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY) native;
  static void _initMouseEvent_11(receiver, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey) native;
  static void _initMouseEvent_12(receiver, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey) native;
  static void _initMouseEvent_13(receiver, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey) native;
  static void _initMouseEvent_14(receiver, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey) native;
  static void _initMouseEvent_15(receiver, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button) native;
  static void _initMouseEvent_16(receiver, type, canBubble, cancelable, view, detail, screenX, screenY, clientX, clientY, ctrlKey, altKey, shiftKey, metaKey, button, relatedTarget) native;

  String get typeName() { return "MouseEvent"; }
}
