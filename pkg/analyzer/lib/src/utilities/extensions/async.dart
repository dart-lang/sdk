// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

extension ListOfCompleterExtension<T> on Iterable<Completer<T>> {
  void completeAll([T? value]) {
    for (var completer in this) {
      completer.complete(value);
    }
  }

  void completeErrorAll(Object value) {
    for (var completer in this) {
      completer.completeError(value);
    }
  }
}
