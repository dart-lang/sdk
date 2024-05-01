// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Common interface for data structures used by the implementations to
/// represent a name/type pair.
abstract interface class SharedNamedType<Type extends SharedType> {
  String get name;
  Type get type;
}

/// Common interface for data structures used by the implementations to
/// represent a record type.
abstract interface class SharedRecordType<Type extends SharedType>
    implements SharedType {
  Iterable<SharedNamedType<Type>> get namedTypes;

  Iterable<Type> get positionalTypes;
}

/// Common interface for data structures used by the implementations to
/// represent a type.
abstract interface class SharedType {
  bool isStructurallyEqualTo(SharedType other);
}

/// Common interface for data structures used by the implementations to
/// represent the unknown type schema (`_`).
abstract interface class SharedUnknownType implements SharedType {}
