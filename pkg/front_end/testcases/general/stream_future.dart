// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

class Class {}

dynamic returnDynamic() => new Class();

Class returnClass() => new Class();

Future<dynamic> returnFutureDynamic() async => new Class();

Future<Class> returnFutureClass() async => new Class();

Stream<FutureOr<Class>> error() async* {
  yield returnFutureDynamic();
}

Stream<FutureOr<Class>> stream() async* {
  yield returnDynamic();
  yield returnClass();
  yield returnFutureClass();
}

main() async {
  await for (FutureOr<Class> cls in stream()) {
    print(cls);
  }
}
