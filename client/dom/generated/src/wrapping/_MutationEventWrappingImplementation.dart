// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MutationEventWrappingImplementation extends _EventWrappingImplementation implements MutationEvent {
  _MutationEventWrappingImplementation() : super() {}

  static create__MutationEventWrappingImplementation() native {
    return new _MutationEventWrappingImplementation();
  }

  int get attrChange() { return _get__MutationEvent_attrChange(this); }
  static int _get__MutationEvent_attrChange(var _this) native;

  String get attrName() { return _get__MutationEvent_attrName(this); }
  static String _get__MutationEvent_attrName(var _this) native;

  String get newValue() { return _get__MutationEvent_newValue(this); }
  static String _get__MutationEvent_newValue(var _this) native;

  String get prevValue() { return _get__MutationEvent_prevValue(this); }
  static String _get__MutationEvent_prevValue(var _this) native;

  Node get relatedNode() { return _get__MutationEvent_relatedNode(this); }
  static Node _get__MutationEvent_relatedNode(var _this) native;

  void initMutationEvent(String type = null, bool canBubble = null, bool cancelable = null, Node relatedNode = null, String prevValue = null, String newValue = null, String attrName = null, int attrChange = null) {
    if (type === null) {
      if (canBubble === null) {
        if (cancelable === null) {
          if (relatedNode === null) {
            if (prevValue === null) {
              if (newValue === null) {
                if (attrName === null) {
                  if (attrChange === null) {
                    _initMutationEvent(this);
                    return;
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
          if (relatedNode === null) {
            if (prevValue === null) {
              if (newValue === null) {
                if (attrName === null) {
                  if (attrChange === null) {
                    _initMutationEvent_2(this, type);
                    return;
                  }
                }
              }
            }
          }
        }
      } else {
        if (cancelable === null) {
          if (relatedNode === null) {
            if (prevValue === null) {
              if (newValue === null) {
                if (attrName === null) {
                  if (attrChange === null) {
                    _initMutationEvent_3(this, type, canBubble);
                    return;
                  }
                }
              }
            }
          }
        } else {
          if (relatedNode === null) {
            if (prevValue === null) {
              if (newValue === null) {
                if (attrName === null) {
                  if (attrChange === null) {
                    _initMutationEvent_4(this, type, canBubble, cancelable);
                    return;
                  }
                }
              }
            }
          } else {
            if (prevValue === null) {
              if (newValue === null) {
                if (attrName === null) {
                  if (attrChange === null) {
                    _initMutationEvent_5(this, type, canBubble, cancelable, relatedNode);
                    return;
                  }
                }
              }
            } else {
              if (newValue === null) {
                if (attrName === null) {
                  if (attrChange === null) {
                    _initMutationEvent_6(this, type, canBubble, cancelable, relatedNode, prevValue);
                    return;
                  }
                }
              } else {
                if (attrName === null) {
                  if (attrChange === null) {
                    _initMutationEvent_7(this, type, canBubble, cancelable, relatedNode, prevValue, newValue);
                    return;
                  }
                } else {
                  if (attrChange === null) {
                    _initMutationEvent_8(this, type, canBubble, cancelable, relatedNode, prevValue, newValue, attrName);
                    return;
                  } else {
                    _initMutationEvent_9(this, type, canBubble, cancelable, relatedNode, prevValue, newValue, attrName, attrChange);
                    return;
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
  static void _initMutationEvent(receiver) native;
  static void _initMutationEvent_2(receiver, type) native;
  static void _initMutationEvent_3(receiver, type, canBubble) native;
  static void _initMutationEvent_4(receiver, type, canBubble, cancelable) native;
  static void _initMutationEvent_5(receiver, type, canBubble, cancelable, relatedNode) native;
  static void _initMutationEvent_6(receiver, type, canBubble, cancelable, relatedNode, prevValue) native;
  static void _initMutationEvent_7(receiver, type, canBubble, cancelable, relatedNode, prevValue, newValue) native;
  static void _initMutationEvent_8(receiver, type, canBubble, cancelable, relatedNode, prevValue, newValue, attrName) native;
  static void _initMutationEvent_9(receiver, type, canBubble, cancelable, relatedNode, prevValue, newValue, attrName, attrChange) native;

  String get typeName() { return "MutationEvent"; }
}
