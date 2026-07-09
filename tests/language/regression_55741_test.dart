// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

final kTrue = int.parse('1') == 1;

void main() {
  final base = kTrue ? Base<String>('a') : 1;
  final baseNullable = kTrue ? Base<String?>('a') : 1;
  final sub = kTrue ? Sub<String>('a') : 1;
  final subNullable = kTrue ? Sub<String?>('a') : 1;

  Expect.isTrue(base is Base<String>, 'is Base<String>');
  Expect.isTrue(base is Base<String?>, 'is Base<String?>');
  Expect.isTrue(baseNullable is! Base<String>, 'is! Base<String>');
  Expect.isTrue(baseNullable is Base<String?>, 'is Base<String?>');
  Expect.isTrue(sub is Sub<String>, 'is Sub<String>');
  Expect.isTrue(sub is Sub<String?>, 'is Sub<String?>');
  Expect.isTrue(subNullable is! Sub<String>, 'is! Sub<String>');
  Expect.isTrue(subNullable is Sub<String?>, 'is Sub<String?>');
  Expect.isTrue(sub is! Base<String>, 'is! Base<String>');
  Expect.isTrue(sub is Base<String?>, 'is Base<String?>');
  Expect.isTrue(subNullable is! Base<String>, 'is! Base<String>');
  Expect.isTrue(subNullable is Base<String?>, 'is Base<String?>');
}

class Base<T> {
  Base(this.data);
  final T data;
}

class Sub<T> extends Base<T?> {
  Sub(super.data);
}
