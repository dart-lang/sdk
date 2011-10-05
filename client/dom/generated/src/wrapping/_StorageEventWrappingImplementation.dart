// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _StorageEventWrappingImplementation extends _EventWrappingImplementation implements StorageEvent {
  _StorageEventWrappingImplementation() : super() {}

  static create__StorageEventWrappingImplementation() native {
    return new _StorageEventWrappingImplementation();
  }

  String get key() { return _get__StorageEvent_key(this); }
  static String _get__StorageEvent_key(var _this) native;

  String get newValue() { return _get__StorageEvent_newValue(this); }
  static String _get__StorageEvent_newValue(var _this) native;

  String get oldValue() { return _get__StorageEvent_oldValue(this); }
  static String _get__StorageEvent_oldValue(var _this) native;

  Storage get storageArea() { return _get__StorageEvent_storageArea(this); }
  static Storage _get__StorageEvent_storageArea(var _this) native;

  String get url() { return _get__StorageEvent_url(this); }
  static String _get__StorageEvent_url(var _this) native;

  void initStorageEvent([String typeArg = null, bool canBubbleArg = null, bool cancelableArg = null, String keyArg = null, String oldValueArg = null, String newValueArg = null, String urlArg = null, Storage storageAreaArg = null]) {
    if (typeArg === null) {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (keyArg === null) {
            if (oldValueArg === null) {
              if (newValueArg === null) {
                if (urlArg === null) {
                  if (storageAreaArg === null) {
                    _initStorageEvent(this);
                    return;
                  }
                }
              }
            }
          }
        }
      }
    } else {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (keyArg === null) {
            if (oldValueArg === null) {
              if (newValueArg === null) {
                if (urlArg === null) {
                  if (storageAreaArg === null) {
                    _initStorageEvent_2(this, typeArg);
                    return;
                  }
                }
              }
            }
          }
        }
      } else {
        if (cancelableArg === null) {
          if (keyArg === null) {
            if (oldValueArg === null) {
              if (newValueArg === null) {
                if (urlArg === null) {
                  if (storageAreaArg === null) {
                    _initStorageEvent_3(this, typeArg, canBubbleArg);
                    return;
                  }
                }
              }
            }
          }
        } else {
          if (keyArg === null) {
            if (oldValueArg === null) {
              if (newValueArg === null) {
                if (urlArg === null) {
                  if (storageAreaArg === null) {
                    _initStorageEvent_4(this, typeArg, canBubbleArg, cancelableArg);
                    return;
                  }
                }
              }
            }
          } else {
            if (oldValueArg === null) {
              if (newValueArg === null) {
                if (urlArg === null) {
                  if (storageAreaArg === null) {
                    _initStorageEvent_5(this, typeArg, canBubbleArg, cancelableArg, keyArg);
                    return;
                  }
                }
              }
            } else {
              if (newValueArg === null) {
                if (urlArg === null) {
                  if (storageAreaArg === null) {
                    _initStorageEvent_6(this, typeArg, canBubbleArg, cancelableArg, keyArg, oldValueArg);
                    return;
                  }
                }
              } else {
                if (urlArg === null) {
                  if (storageAreaArg === null) {
                    _initStorageEvent_7(this, typeArg, canBubbleArg, cancelableArg, keyArg, oldValueArg, newValueArg);
                    return;
                  }
                } else {
                  if (storageAreaArg === null) {
                    _initStorageEvent_8(this, typeArg, canBubbleArg, cancelableArg, keyArg, oldValueArg, newValueArg, urlArg);
                    return;
                  } else {
                    _initStorageEvent_9(this, typeArg, canBubbleArg, cancelableArg, keyArg, oldValueArg, newValueArg, urlArg, storageAreaArg);
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
  static void _initStorageEvent(receiver) native;
  static void _initStorageEvent_2(receiver, typeArg) native;
  static void _initStorageEvent_3(receiver, typeArg, canBubbleArg) native;
  static void _initStorageEvent_4(receiver, typeArg, canBubbleArg, cancelableArg) native;
  static void _initStorageEvent_5(receiver, typeArg, canBubbleArg, cancelableArg, keyArg) native;
  static void _initStorageEvent_6(receiver, typeArg, canBubbleArg, cancelableArg, keyArg, oldValueArg) native;
  static void _initStorageEvent_7(receiver, typeArg, canBubbleArg, cancelableArg, keyArg, oldValueArg, newValueArg) native;
  static void _initStorageEvent_8(receiver, typeArg, canBubbleArg, cancelableArg, keyArg, oldValueArg, newValueArg, urlArg) native;
  static void _initStorageEvent_9(receiver, typeArg, canBubbleArg, cancelableArg, keyArg, oldValueArg, newValueArg, urlArg, storageAreaArg) native;

  String get typeName() { return "StorageEvent"; }
}
