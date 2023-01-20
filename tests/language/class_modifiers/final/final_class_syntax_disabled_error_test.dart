// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Make sure errors are emitted when trying to use final classes without
// the `class-modifiers` experiment enabled.

final class FinalClass {}
// [error column 1, length 5]
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'class-modifiers' language feature to be enabled.

mixin M {}
final class FinalClassTypeAlias = Object with M;
// [error column 1, length 5]
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'class-modifiers' language feature to be enabled.

final mixin FinalMixin {}
// [error column 1, length 5]
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'class-modifiers' language feature to be enabled.
