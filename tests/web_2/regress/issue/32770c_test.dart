// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong

// Regression test for issue 32770.

import 'dart:async' show Future;

A<J> futureToA<T, J>(Future<T> future, [J wrapValue(T value)]) {
  return new A<J>(
    (void resolveFn(J value), void rejectFn(error)) {
      future.then((value) {
        dynamic wrapped;
        if (wrapValue != null) {
          wrapped = wrapValue(value);
        } else if (value != null) {
          wrapped = value;
        }
        resolveFn(wrapped);
      }).catchError((error) {
        rejectFn(error);
      });
    },
  );
}

class A<X> {
  var x;

  A(this.x);
}

main() {
  print(futureToA);
}
