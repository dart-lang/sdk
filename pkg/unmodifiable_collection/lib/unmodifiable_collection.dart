// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library used to introduce unmodifiable wrappers for collections.
 *
 * This functionality has been moved to the `collection` library.
 *
 * Please replace the import of this library with:
 *
 *     import "package:collection/wrappers.dart";
 *
 * and change dependencies to match.
 */
@deprecated
library unmodifiable_collection;

export "package:collection/wrappers.dart"
    show UnmodifiableListView,
         UnmodifiableSetView,
         UnmodifiableMapView,
         NonGrowableListView;
