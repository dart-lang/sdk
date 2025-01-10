// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/language/mixin_declaration/mixin_declaration_syntax_test.dart

abstract class A { }
class B implements A { }
// With C defined everything is fine.
// Without C defined "null" is returned from buildSupertype and it's not added.
//class C extends A { }
abstract class I { }
abstract class J { }
mixin MAiBC on A implements B, C { }
mixin MBCiIJ on B, C implements I, J { }
class CAaMAiBC = A with MAiBC;
class CAaMAiBCaMBCiIJ_2 extends CAaMAiBC with MBCiIJ {}
