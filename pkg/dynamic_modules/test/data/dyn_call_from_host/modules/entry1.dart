// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class D1 {
  String method1() => '10';
  String method2() => '20';
}

class D2 {
  String method3() => '30';
  String method4() => '40';
  String method5() => '50';
}

@pragma('dyn-module:entry-point')
Object? dynamicModuleEntrypoint() {
  return [D1(), D2()];
}
