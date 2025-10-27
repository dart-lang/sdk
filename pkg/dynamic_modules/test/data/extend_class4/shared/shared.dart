// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Base {
  String get _privateGetter => 'Base._privateGetter';

  String publicMethod(Object other) {
    return other is Base ? other._privateGetter : "";
  }
}

class C1 extends Base {}

class C2 extends Base {
  @override
  String get _privateGetter => 'C2._privateGetter';
}
