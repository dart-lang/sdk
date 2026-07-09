// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart = 2.19

// Make sure errors are emitted when trying to use interface classes without
// the `class-modifiers` experiment enabled.

interface class InterfaceClass {}
// [error column 1, length 9]
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'class-modifiers' language feature is disabled for this library.

mixin M {}
interface class InterfaceClassTypeAlias = Object with M;
// [error column 1, length 9]
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'class-modifiers' language feature is disabled for this library.
