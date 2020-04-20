// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Opt out of NNBD:
// @dart = 2.6

/// A legacy library of helper methods to construct types and values containing
/// legacy (star *) types.

typedef fnTypeWithLegacyObjectBound = void Function<T extends Object>();
typedef fnTypeWithLegacyIntBound = void Function<T extends int>();
typedef fnTypeWithLegacyStringLegacyObjectBounds = void
    Function<T extends String, S extends Object>();

void fnWithLegacyObjectBound<T extends Object>() => null;
void fnWithLegacyIntBound<T extends int>() => null;
void fnWithLegacyStringLegacyObjectBounds<T extends String,
        S extends Object>() =>
    null;
