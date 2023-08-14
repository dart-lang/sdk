// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart = 2.19

// Make sure errors are emitted when trying to use base classes without
// the `class-modifiers` experiment enabled.

base class BaseClass {}
// [error column 1, length 4]
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'class-modifiers' language feature is disabled for this library.

mixin M {}
base class BaseClassTypeAlias = Object with M;
// [error column 1, length 4]
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'class-modifiers' language feature is disabled for this library.

base mixin BaseMixin {}
// [error column 1, length 4]
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'class-modifiers' language feature is disabled for this library.
