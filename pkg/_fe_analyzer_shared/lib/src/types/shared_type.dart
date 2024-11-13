// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../type_inference/nullability_suffix.dart';

/// Common interface for data structures used by the implementations to
/// represent the type `dynamic`.
abstract interface class SharedDynamicTypeStructure<
        TypeStructure extends SharedTypeStructure<TypeStructure>>
    implements SharedTypeStructure<TypeStructure> {}

/// Common interface for data structures used by the implementations to
/// represent function types.
abstract interface class SharedFunctionTypeStructure<
    TypeStructure extends SharedTypeStructure<TypeStructure>,
    TypeParameterStructure extends SharedTypeParameterStructure<TypeStructure>,
    FunctionParameterStructure extends SharedNamedFunctionParameterStructure<
        TypeStructure>> implements SharedTypeStructure<TypeStructure> {
  /// All the positional parameter types, starting with the required ones, and
  /// followed by the optional ones.
  List<TypeStructure> get positionalParameterTypes;

  /// The number of elements of [positionalParameterTypes] that are required
  /// parameters.
  int get requiredPositionalParameterCount;

  /// The return type.
  TypeStructure get returnType;

  /// All the named parameters, sorted by name.
  List<FunctionParameterStructure> get sortedNamedParameters;

  /// The type parameters of the function type.
  List<TypeParameterStructure> get typeFormals;
}

/// Common interface for data structures used by the implementations to
/// represent a type resulting from a compile-time error.
///
/// The implementations may choose to suppress further errors that arise from
/// the use of this type.
abstract interface class SharedInvalidTypeStructure<
        TypeStructure extends SharedTypeStructure<TypeStructure>>
    implements SharedTypeStructure<TypeStructure> {}

/// Common interface for data structures used by the implementations to
/// represent a named parameter of a function type.
abstract interface class SharedNamedFunctionParameterStructure<
    TypeStructure extends SharedTypeStructure<TypeStructure>> {
  /// Whether this named parameter is required.
  bool get isRequired;

  /// The name of the parameter.
  String get name;

  /// The type of the parameter.
  TypeStructure get type;
}

/// Common interface for data structures used by the implementations to
/// represent a name/type pair.
abstract interface class SharedNamedTypeStructure<
    TypeStructure extends SharedTypeStructure<TypeStructure>> {
  String get name;
  TypeStructure get type;
}

/// Common interface for data structures used by the implementations to
/// represent a record type.
abstract interface class SharedRecordTypeStructure<
        TypeStructure extends SharedTypeStructure<TypeStructure>>
    implements SharedTypeStructure<TypeStructure> {
  /// All the named fields, sorted by name.
  List<SharedNamedTypeStructure<TypeStructure>> get sortedNamedTypes;

  List<TypeStructure> get positionalTypes;
}

/// Common interface for data structures used by the implementations to
/// represent a generic type parameter.
abstract interface class SharedTypeParameterStructure<
    TypeStructure extends SharedTypeStructure<TypeStructure>> {
  /// The name of the type parameter, for display to the user.
  String get displayName;

  /// The bound of the type parameter.
  TypeStructure? get bound;
}

/// Common interface for data structures used by the implementations to
/// represent a type.
abstract interface class SharedTypeStructure<
    TypeStructure extends SharedTypeStructure<TypeStructure>> {
  /// If this type ends in a suffix (`?` or `*`), the suffix it ends with;
  /// otherwise [NullabilitySuffix.none].
  NullabilitySuffix get nullabilitySuffix;

  /// Return the presentation of this type as it should appear when presented to
  /// users in contexts such as error messages.
  ///
  /// Clients should not depend on the content of the returned value as it will
  /// be changed if doing so would improve the UX.
  String getDisplayString();

  bool isStructurallyEqualTo(SharedTypeStructure<TypeStructure> other);
}

/// Common interface for data structures used by the implementations to
/// represent the unknown type schema (`_`).
///
/// Note below that there is no `SharedUnknownTypeView`, only
/// [SharedUnknownTypeSchemaView], since we want to restrict
/// [SharedUnknownTypeStructure] from appearing in type views.
abstract interface class SharedUnknownTypeStructure<
        TypeStructure extends SharedTypeStructure<TypeStructure>>
    implements SharedTypeStructure<TypeStructure> {}

/// Common interface for data structures used by the implementations to
/// represent the type `void`.
abstract interface class SharedVoidTypeStructure<
        TypeStructure extends SharedTypeStructure<TypeStructure>>
    implements SharedTypeStructure<TypeStructure> {}

extension type SharedDynamicTypeSchemaView<
            TypeStructure extends SharedTypeStructure<TypeStructure>>(
        SharedDynamicTypeStructure<TypeStructure> _typeStructure)
    implements SharedTypeSchemaView<TypeStructure> {}

extension type SharedDynamicTypeView<
            TypeStructure extends SharedTypeStructure<TypeStructure>>(
        SharedDynamicTypeStructure<TypeStructure> _typeStructure)
    implements SharedTypeView<TypeStructure> {}

extension type SharedInvalidTypeSchemaView<
            TypeStructure extends SharedTypeStructure<TypeStructure>>(
        SharedInvalidTypeStructure<TypeStructure> _typeStructure)
    implements SharedTypeSchemaView<TypeStructure> {}

extension type SharedInvalidTypeView<
            TypeStructure extends SharedTypeStructure<TypeStructure>>(
        SharedInvalidTypeStructure<TypeStructure> _typeStructure)
    implements SharedTypeView<TypeStructure> {}

extension type SharedNamedTypeSchemaView<
        TypeStructure extends SharedTypeStructure<TypeStructure>>(
    SharedNamedTypeStructure<TypeStructure> _typeStructure) implements Object {}

extension type SharedNamedTypeView<
            TypeStructure extends SharedTypeStructure<TypeStructure>>(
        SharedNamedTypeStructure<TypeStructure> _namedTypeStructure)
    implements Object {
  String get name => _namedTypeStructure.name;

  SharedTypeView<TypeStructure> get type =>
      new SharedTypeView(_namedTypeStructure.type);
}

extension type SharedRecordTypeSchemaView<
            TypeStructure extends SharedTypeStructure<TypeStructure>>(
        SharedRecordTypeStructure<TypeStructure> _typeStructure)
    implements SharedTypeSchemaView<TypeStructure> {
  List<SharedNamedTypeSchemaView<TypeStructure>> get namedTypes {
    return _typeStructure.sortedNamedTypes
        as List<SharedNamedTypeSchemaView<TypeStructure>>;
  }

  List<SharedTypeSchemaView<TypeStructure>> get positionalTypes {
    return _typeStructure.positionalTypes
        as List<SharedTypeSchemaView<TypeStructure>>;
  }
}

extension type SharedRecordTypeView<
            TypeStructure extends SharedTypeStructure<TypeStructure>>(
        SharedRecordTypeStructure<TypeStructure> _typeStructure)
    implements SharedTypeView<TypeStructure> {
  List<SharedNamedTypeView<TypeStructure>> get namedTypes {
    return _typeStructure.sortedNamedTypes
        as List<SharedNamedTypeView<TypeStructure>>;
  }

  List<SharedTypeView<TypeStructure>> get positionalTypes {
    return _typeStructure.positionalTypes
        as List<SharedTypeView<TypeStructure>>;
  }
}

extension type SharedTypeSchemaView<
        TypeStructure extends SharedTypeStructure<TypeStructure>>(
    SharedTypeStructure<TypeStructure> _typeStructure) implements Object {
  NullabilitySuffix get nullabilitySuffix => _typeStructure.nullabilitySuffix;

  String getDisplayString() => _typeStructure.getDisplayString();

  TypeStructure unwrapTypeSchemaView() => _typeStructure as TypeStructure;
}

extension type SharedTypeView<
        TypeStructure extends SharedTypeStructure<TypeStructure>>(
    SharedTypeStructure<TypeStructure> _typeStructure) implements Object {
  NullabilitySuffix get nullabilitySuffix => _typeStructure.nullabilitySuffix;

  String getDisplayString() => _typeStructure.getDisplayString();

  TypeStructure unwrapTypeView() => _typeStructure as TypeStructure;
}

/// Note that there is no `SharedUnknownTypeView`, only
/// [SharedUnknownTypeSchemaView], since we want to restrict
/// [SharedUnknownTypeStructure] from appearing in type views and allow it to
/// appear only in type schema views.
extension type SharedUnknownTypeSchemaView<
            TypeStructure extends SharedTypeStructure<TypeStructure>>(
        SharedUnknownTypeStructure<TypeStructure> _typeStructure)
    implements SharedTypeSchemaView<TypeStructure> {}

extension type SharedVoidTypeSchemaView<
            TypeStructure extends SharedTypeStructure<TypeStructure>>(
        SharedVoidTypeStructure<TypeStructure> _typeStructure)
    implements SharedTypeSchemaView<TypeStructure> {}

extension type SharedVoidTypeView<
            TypeStructure extends SharedTypeStructure<TypeStructure>>(
        SharedVoidTypeStructure<TypeStructure> _typeStructure)
    implements SharedTypeView<TypeStructure> {}

/// Extension methods of [SharedTypeStructureExtension] are intended to avoid
/// explicit null-testing on types before wrapping them into [SharedTypeView] or
/// [SharedTypeSchemaView].
///
/// Consider the following code:
///     DartType? type = e.foo();
///     return type == null ? null : SharedTypeView(type);
///
/// In the example above we want to wrap the result of the evaluation of
/// `e.foo()` in `SharedTypeView` if it's not null. For that we need to store it
/// into a variable to enable promotion in the ternary operator that will
/// perform the wrapping.
///
/// This code can be rewritten in a more concise way using
/// [SharedTypeStructureExtension] as follows:
///     return e.foo()?.wrapSharedTypeView();
extension SharedTypeStructureExtension<
        TypeStructure extends SharedTypeStructure<TypeStructure>>
    on SharedTypeStructure<TypeStructure> {
  SharedTypeSchemaView<TypeStructure> wrapSharedTypeSchemaView() {
    return new SharedTypeSchemaView(this);
  }

  SharedTypeView<TypeStructure> wrapSharedTypeView() {
    return new SharedTypeView(this);
  }
}

extension SharedTypeStructureMapEntryExtension<
    TypeStructure extends SharedTypeStructure<TypeStructure>> on ({
  SharedTypeStructure<TypeStructure> keyType,
  SharedTypeStructure<TypeStructure> valueType
}) {
  ({
    SharedTypeView<TypeStructure> keyType,
    SharedTypeView<TypeStructure> valueType
  }) wrapSharedTypeMapEntryView() {
    return (
      keyType: new SharedTypeView(this.keyType),
      valueType: new SharedTypeView(this.valueType)
    );
  }

  ({
    SharedTypeSchemaView<TypeStructure> keyType,
    SharedTypeSchemaView<TypeStructure> valueType
  }) wrapSharedTypeSchemaMapEntryView() {
    return (
      keyType: new SharedTypeSchemaView(this.keyType),
      valueType: new SharedTypeSchemaView(this.valueType)
    );
  }
}
