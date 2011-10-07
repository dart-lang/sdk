// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class HashChangeEventWrappingImplementation extends EventWrappingImplementation implements HashChangeEvent {
  HashChangeEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get newURL() { return _ptr.newURL; }

  String get oldURL() { return _ptr.oldURL; }

  void initHashChangeEvent(String type, bool canBubble, bool cancelable, String oldURL, String newURL) {
    _ptr.initHashChangeEvent(type, canBubble, cancelable, oldURL, newURL);
    return;
  }
}
