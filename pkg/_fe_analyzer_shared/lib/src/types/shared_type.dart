// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../type_inference/nullability_suffix.dart';

/// Common interface for data structures used by the implementations to
/// represent the type `dynamic`.
abstract interface class SharedDynamicType<Type extends SharedType<Type>>
    implements SharedType<Type> {}

/// Common interface for data structures used by the implementations to
/// represent a type resulting from a compile-time error.
///
/// The implementations may choose to suppress further errors that arise from
/// the use of this type.
abstract interface class SharedInvalidType<Type extends SharedType<Type>>
    implements SharedType<Type> {}

/// Common interface for data structures used by the implementations to
/// represent a name/type pair.
abstract interface class SharedNamedType<Type extends SharedType<Type>> {
  String get name;
  Type get type;
}

/// Common interface for data structures used by the implementations to
/// represent a record type.
abstract interface class SharedRecordType<Type extends SharedType<Type>>
    implements SharedType<Type> {
  List<SharedNamedType<Type>> get namedTypes;

  List<Type> get positionalTypes;
}

/// Common interface for data structures used by the implementations to
/// represent a type.
abstract interface class SharedType<Type extends SharedType<Type>> {
  /// If this type ends in a suffix (`?` or `*`), the suffix it ends with;
  /// otherwise [NullabilitySuffix.none].
  NullabilitySuffix get nullabilitySuffix;

  /// Return the presentation of this type as it should appear when presented
  /// to users in contexts such as error messages.
  ///
  /// Clients should not depend on the content of the returned value as it will
  /// be changed if doing so would improve the UX.
  String getDisplayString();

  bool isStructurallyEqualTo(SharedType<Type> other);
}

/// Common interface for data structures used by the implementations to
/// represent the unknown type schema (`_`).
abstract interface class SharedUnknownType<Type extends SharedType<Type>>
    implements SharedType<Type> {}

/// Common interface for data structures used by the implementations to
/// represent the type `void`.
abstract interface class SharedVoidType<Type extends SharedType<Type>>
    implements SharedType<Type> {}
