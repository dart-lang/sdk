// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class HashChangeEventWrappingImplementation extends EventWrappingImplementation implements HashChangeEvent {
  HashChangeEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory HashChangeEventWrappingImplementation(String type, String oldURL,
      String newURL, [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("HashChangeEvent");
    e.initHashChangeEvent(type, canBubble, cancelable, oldURL, newURL);
    return LevelDom.wrapHashChangeEvent(e);
  }

  String get newURL() => _ptr.newURL;

  String get oldURL() => _ptr.oldURL;
}
