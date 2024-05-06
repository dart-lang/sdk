// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper';

/// Always returns `true`. This getter is opaque until SSA and is a counterpart
/// to [opaqueFalse].
@pragma('dart2js:prefer-inline')
bool get opaqueTrue => JS_TRUE();

/// Always returns `false`. This getter is opaque until SSA, so code guarded by
/// [opaqueFalse] will not be optimized away until late in the compilation
/// pipeline.
@pragma('dart2js:prefer-inline')
bool get opaqueFalse => JS_FALSE();
