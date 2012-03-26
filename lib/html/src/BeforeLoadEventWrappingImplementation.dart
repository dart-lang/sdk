// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class BeforeLoadEventWrappingImplementation extends EventWrappingImplementation implements BeforeLoadEvent {
  BeforeLoadEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory BeforeLoadEventWrappingImplementation(String type, String url,
      [bool canBubble = true, bool cancelable = true]) {
    final e = dom.document.createEvent("BeforeLoadEvent");
    e.initBeforeLoadEvent(type, canBubble, cancelable, url);
    return LevelDom.wrapBeforeLoadEvent(e);
  }

  String get url() => _ptr.url;
}
