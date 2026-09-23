// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

abstract class Base {
  String copyWith({int? a});
  String foo([int? a]);
}

class Sub1a extends Base {
  @override
  String copyWith({int? a}) => 'Sub1a($a)';

  @override
  String foo([int? a]) => 'Sub1a($a)';
}

class Sub1b extends Base {
  @override
  String copyWith({int? a}) => 'Sub1b($a)';

  @override
  String foo([int? a]) => 'Sub1b($a)';
}

abstract class Sub2 extends Base {
  @override
  String copyWith({int? a, int? b});

  @override
  String foo([int? a, int? b]);
}

class Sub2a extends Sub2 {
  @override
  String copyWith({int? a, int? b}) => 'Sub2a($a, $b)';

  @override
  String foo([int? a, int? b]) => 'Sub2a($a, $b)';
}

class Sub2b extends Sub2 {
  @override
  String copyWith({int? a, int? b}) => 'Sub2b($a, $b)';

  @override
  String foo([int? a, int? b]) => 'Sub2b($a, $b)';
}

void main() {
  final Base s1 = int.parse('1') == 1 ? Sub1a() : Sub1b();
  Expect.equals('Sub1a(1)', s1.copyWith(a: int.parse('1')));
  Expect.equals('Sub1a(1)', s1.foo(int.parse('1')));

  final Sub2 s2 = int.parse('1') == 1 ? Sub2a() : Sub2b();
  Expect.equals(
    'Sub2a(1, 42)',
    s2.copyWith(a: int.parse('1'), b: int.parse('42')),
  );
  Expect.equals('Sub2a(1, 42)', s2.foo(int.parse('1'), int.parse('42')));
}
