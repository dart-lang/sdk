// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.io.location_provider;

import 'code_output.dart' show CodeOutputListener;

import 'package:kernel/ast.dart' show Location, Source;

/// Interface for providing line/column information.
abstract class LocationProvider {
  /// Translates the zero-based character [offset] (from the beginning of a
  /// file) to a [Location].
  Location getLocation(int offset);
}

/// [CodeOutputListener] that collects line information.
class LocationCollector extends CodeOutputListener implements LocationProvider {
  int length = 0;
  List<int> lineStarts = <int>[0];

  void _collect(String text) {
    int index = 0;
    while (index < text.length) {
      // Unix uses '\n' and Windows uses '\r\n', so this algorithm works for
      // both platforms.
      index = text.indexOf('\n', index) + 1;
      if (index <= 0) break;
      lineStarts.add(length + index);
    }
    length += text.length;
  }

  @override
  void onText(String text) {
    _collect(text);
  }

  @override
  Location getLocation(int offset) {
    RangeError.checkValueInInterval(offset, 0, length, 'offset');
    return new Source(lineStarts, null).getLocation(null, offset);
  }

  @override
  void onDone(int length) {
    lineStarts.add(length + 1);
    this.length = length;
  }

  String toString() {
    return 'lineStarts=$lineStarts,length=$length';
  }
}
