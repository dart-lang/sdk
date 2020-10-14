// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

late int topLevelField;
late final finalTopLevelField;

class Class<T extends Object> {
  late int instanceField;
  late final finalInstanceField;
  late T instanceTypeVariable;
  late final T finalInstanceTypeVariable;

  static late int staticField;
  static late final staticFinalField;
}

method<T extends Object>(bool b, int i, T t) {
  late int local;
  late final finalLocal;
  late T localTypeVariable;
  late final T finalLocalTypeVariable;

  if (b) {
    // Ensure assignments below are not definitely assigned.
    local = i;
    finalLocal = i;
    localTypeVariable = t;
    finalLocalTypeVariable = t;

    expect(i, local);
    expect(i, finalLocal);
    expect(t, localTypeVariable);
    expect(t, finalLocalTypeVariable);
  }

  throws(() => finalLocal = i);
  throws(() => finalLocalTypeVariable = t);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

throws(void Function() f) {
  try {
    f();
  } catch (_) {
    return;
  }
  throw 'Missing exception';
}
