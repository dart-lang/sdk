// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A null safe library of helper methods to construct types and values
/// containing non-nullable and nullable (question ?) types.

typedef fnTypeWithNonNullObjectBound = void Function<T extends Object>();
typedef fnTypeWithNullableObjectBound = void Function<T extends Object?>();
typedef fnTypeWithNonNullIntBound = void Function<T extends int>();
typedef fnTypeWithNullableIntBound = void Function<T extends int?>();
typedef fnTypeWithNonNullableStringNullableObjectBounds = void
    Function<T extends String, S extends Object?>();
typedef fnTypeWithNeverBound = void Function<T extends Never>();

void fnWithNonNullObjectBound<T extends Object>() => null;
void fnWithNullableObjectBound<T extends Object?>() => null;
void fnWithNonNullIntBound<T extends int>() => null;
void fnWithNullableIntBound<T extends int?>() => null;
void fnWithNonNullableStringNullableObjectBounds<T extends String,
        S extends Object?>() =>
    null;
void fnWithNullBound<T extends Null>() => null;
