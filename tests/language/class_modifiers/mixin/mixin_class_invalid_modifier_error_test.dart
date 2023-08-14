// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when applying any other modifier to mixin classes other than base.

final mixin class A {}
// [error column 1, length 5]
// [analyzer] SYNTACTIC_ERROR.FINAL_MIXIN_CLASS
// [cfe] A mixin class can't be declared 'final'.

interface mixin class B {}
// [error column 1, length 9]
// [analyzer] SYNTACTIC_ERROR.INTERFACE_MIXIN_CLASS
// [cfe] A mixin class can't be declared 'interface'.

sealed mixin class C {}
// [error column 1, length 6]
// [analyzer] SYNTACTIC_ERROR.SEALED_MIXIN_CLASS
// [cfe] A mixin class can't be declared 'sealed'.
