// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Opt out of Null Safety:
// @dart = 2.6

import 'null_safe_library.dart';

/// Performs the type test [value] is [T] in a legacy library.
///
/// NOTE: The [T] here is in a legacy library and will become `T*` which might
/// be normalized away depending on the value of `T`.
bool legacyIs<T>(Object value) => value is T;

/// Performs the type test [value] is [T] in a null safe library.
///
/// NOTE: The [T] here is in a legacy library and will become `T*` which might
/// be normalized away depending on the value of `T`.
bool nullSafeIsLegacy<T>(Object value) => nullSafeIs<T>(value);
