// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/language/mixin_declaration/mixin_declaration_syntax_test.dart

abstract class A { }
class B implements A { }
abstract class I { }
abstract class J { }
// Function is ignored when adding implemented types.
mixin MAiBC on A implements B, Function { }
mixin MBCiIJ on B, Function implements I, J { }
class CAaMAiBC = A with MAiBC;
class CAaMAiBCaMBCiIJ_2 extends CAaMAiBC with MBCiIJ {}
