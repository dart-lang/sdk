// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

method(void Function() f) {
  f();
}

method2(FutureOr<void> Function() f) {
  f();
}

test() {
  method(() {
    return 42; // error
  });
  method2(() {
    return 42; // ok
  });
}

main() {}
