// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TimeRangesWrappingImplementation extends DOMWrapperBase implements TimeRanges {
  TimeRangesWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  num end(int index) {
    return _ptr.end(index);
  }

  num start(int index) {
    return _ptr.start(index);
  }

  String get typeName() { return "TimeRanges"; }
}
