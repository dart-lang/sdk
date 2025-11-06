// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Foo { e1, e2, e3 }

enum Bar {
  e1('E1'),
  e2('E2');

  final String str;
  const Bar(this.str);

  @override
  String toString() => str;
}

@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() => [
  Foo.e2,
  Foo.values[0].index,
  Foo.values[2].toString(),
  Bar.e1,
];
