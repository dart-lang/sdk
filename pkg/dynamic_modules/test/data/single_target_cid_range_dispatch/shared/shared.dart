// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Base {
  String createElement();
}

class Base1 extends Base {
  @override
  String createElement() => 'Element1';
}

class Base2 extends Base {
  @override
  String createElement() => 'Element2';
}
