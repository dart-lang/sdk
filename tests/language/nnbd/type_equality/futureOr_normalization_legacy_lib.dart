// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Opt out of Null Safety:
// @dart = 2.6

import 'futureOr_normalization_null_safe_lib.dart' as nullSafe;

Type extractType<T>() => T;
Type nonNullableFutureOrOfLegacyObject() =>
    nullSafe.nonNullableFutureOrOf<Object>();

final object = extractType<Object>();
