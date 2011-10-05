// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ProgressEventWrappingImplementation extends EventWrappingImplementation implements ProgressEvent {
  ProgressEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get lengthComputable() { return _ptr.lengthComputable; }

  int get loaded() { return _ptr.loaded; }

  int get total() { return _ptr.total; }

  void initProgressEvent(String typeArg, bool canBubbleArg, bool cancelableArg, bool lengthComputableArg, int loadedArg, int totalArg) {
    _ptr.initProgressEvent(typeArg, canBubbleArg, cancelableArg, lengthComputableArg, loadedArg, totalArg);
    return;
  }

  String get typeName() { return "ProgressEvent"; }
}
