// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main(List<String> args) {
  const foos = const [
    Foo('same_1', 'diff1_1', 'same_2', 'same_3', 'diff2_1'),
    Foo('same_1', 'diff1_2', 'same_2', 'same_3', 'diff2_2'),
    Foo('same_1', 'diff1_3', 'same_2', 'same_3', 'diff2_3'),
  ];
  final newFoos = [new Foo('same_1', 'diff1_4', 'same_2', 'same_3', 'diff2_4')];
  for (final foo in [...foos, ...newFoos]) {
    print(foo.usedFieldWithSameValue);
    print(foo.usedFieldWithDifferentValues);
  }
}

class Foo {
  final String usedFieldWithSameValue;
  final String usedFieldWithDifferentValues;
  final String unusedFieldWithSameValue;
  @pragma('vm:entry-point')
  final String unusedFieldWithSameValueAndEntryPoint;
  final String unusedFieldWithDifferentValues;

  const Foo(
    this.usedFieldWithSameValue,
    this.usedFieldWithDifferentValues,
    this.unusedFieldWithSameValue,
    this.unusedFieldWithSameValueAndEntryPoint,
    this.unusedFieldWithDifferentValues,
  );
}
