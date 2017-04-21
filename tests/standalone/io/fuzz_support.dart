// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fuzz_support;

import 'package:expect/expect.dart';
import 'dart:async';
import 'dart:io';

const typeMapping = const {
  'null': null,
  'int': 0,
  'bigint': 18446744073709551617,
  'String': 'a',
  'FileMode': FileMode.READ,
  'num': 0.50,
  'List<int>': const [1, 2, 3],
  'Map<String, int>': const {"a": 23}
};

typePermutations(int argCount) {
  var result = [];
  if (argCount == 2) {
    typeMapping.forEach((k, v) {
      typeMapping.forEach((k2, v2) {
        result.add([v, v2]);
      });
    });
  } else {
    Expect.isTrue(argCount == 3);
    typeMapping.forEach((k, v) {
      typeMapping.forEach((k2, v2) {
        typeMapping.forEach((k3, v3) {
          result.add([v, v2, v3]);
        });
      });
    });
  }
  return result;
}

// Perform sync operation and ignore all exceptions.
doItSync(Function f) {
  try {
    f();
  } catch (e) {}
}

// Perform async operation and transform the future for the operation
// into a future that never fails by treating errors as normal
// completion.
Future doItAsync(void f()) {
  // Ignore value and errors.
  return new Future.delayed(Duration.ZERO, f)
      .catchError((_) {})
      .then((_) => true);
}
