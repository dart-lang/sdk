// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart Language Specification, Section "Mixin Declaration":
// "Let M_I be the interface that would be defined by the class declaration
//    abstract class N<...> implements T_1, ..., T_n, I_1, ..., I_k { ... }
//  ...
//  It is a compile-time error for the mixin M if this N class
//  declaration would cause a compile-time error."
//
// Dart Language Specification, Section "Superinterfaces":
// "It is a compile-time error if two elements in the type list of
//  the implements clause of a class C specifies the same type T."

class A {}

mixin M on A implements A {}
//    ^
// [cfe] 'A' can't be used in both 'extends' and 'implements' clauses.
//                      ^
// [analyzer] COMPILE_TIME_ERROR.IMPLEMENTS_SUPER_CLASS_CONSTRAINT
