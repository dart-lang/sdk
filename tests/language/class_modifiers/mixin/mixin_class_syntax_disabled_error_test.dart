// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Make sure errors are emitted when trying to use mixin classes without
// the `class-modifiers` experiment enabled.

mixin class MixinClass {}
// [error column 1, length 5]
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'class-modifiers' language feature to be enabled.

abstract mixin class AbstractMixinClass {}
//       ^^^^^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'class-modifiers' language feature to be enabled.

mixin M {}
mixin class NamedMixinClassApplication = Object with M;
// [error column 1, length 5]
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'class-modifiers' language feature to be enabled.