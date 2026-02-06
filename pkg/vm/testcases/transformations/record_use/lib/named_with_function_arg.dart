// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main(List<String> arguments) {
  final a = A();

  a.foo(s: 'hello-world', (event) => print(event));
}

class A {}

extension Ext on A {
  @RecordUse()
  void foo(Function f, {required String s}) {}
}
