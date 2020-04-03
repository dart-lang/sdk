// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'legacy_library.dart';

/// Performs the type test [value] is [T] in a null safe library.
bool nullSafeIs<T>(Object? value) => value is T;

/// Performs the type test [value] is `T?` in a legacy library.
bool legacyIsNullable<T>(Object? value) => legacyIs<T?>(value);
