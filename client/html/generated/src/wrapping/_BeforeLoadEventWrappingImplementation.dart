// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class BeforeLoadEventWrappingImplementation extends EventWrappingImplementation implements BeforeLoadEvent {
  BeforeLoadEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get url() { return _ptr.url; }

  void initBeforeLoadEvent(String type, bool canBubble, bool cancelable, String url) {
    _ptr.initBeforeLoadEvent(type, canBubble, cancelable, url);
    return;
  }

  String get typeName() { return "BeforeLoadEvent"; }
}
