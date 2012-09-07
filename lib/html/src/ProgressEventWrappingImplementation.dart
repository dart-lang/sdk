// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ProgressEventWrappingImplementation extends EventWrappingImplementation implements ProgressEvent {
  ProgressEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory ProgressEventWrappingImplementation(String type, int loaded,
      [bool canBubble = true, bool cancelable = true,
      bool lengthComputable = false, int total = 0]) {
    final e = dom.document.createEvent("ProgressEvent");
    e.initProgressEvent(type, canBubble, cancelable, lengthComputable, loaded,
        total);
    return LevelDom.wrapProgressEvent(e);
  }

  bool get lengthComputable => _ptr.lengthComputable;

  int get loaded => _ptr.loaded;

  int get total => _ptr.total;
}
