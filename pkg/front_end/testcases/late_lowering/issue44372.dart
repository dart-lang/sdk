// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main(List<String> args) {
  late int Function() recursiveInitLocal;
  late final int local = recursiveInitLocal();

  bool doRecursiveInitLocal = true;
  recursiveInitLocal = () {
    print('Executing initializer');
    if (doRecursiveInitLocal) {
      doRecursiveInitLocal = false;
      print('Trigger recursive initialization');
      int val = local;
      print('Final local has value $val');
      print('Returning 4 from initializer');
      return 4;
    }
    print('Returning 3 from initializer');
    return 3;
  };

  throws(() {
    int val = local;
    print('Final local has value $val');
  }, "Read local");
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

throws(f(), String message) {
  dynamic value;
  try {
    value = f();
  } on LateInitializationError catch (e) {
    print(e);
    return;
  }
  throw '$message: $value';
}
