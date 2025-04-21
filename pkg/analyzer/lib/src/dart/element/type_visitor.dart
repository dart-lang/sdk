// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/summary2/function_type_builder.dart';
import 'package:analyzer/src/summary2/named_type_builder.dart';
import 'package:analyzer/src/summary2/record_type_builder.dart';

/// Visitors that implement this interface can be used to visit partially
/// inferred types, during type inference.
abstract class InferenceTypeVisitor<R> {
  R visitUnknownInferredType(UnknownInferredType type);
}

/// Visitors that implement this interface can be used to visit partially
/// inferred types, during type inference.
abstract class InferenceTypeVisitor1<R, A> {
  R visitUnknownInferredType(UnknownInferredType type, A argument);
}

/// Visitors that implement this interface can be used to visit partially
/// built types, during linking element model.
abstract class LinkingTypeVisitor<R> {
  R visitFunctionTypeBuilder(FunctionTypeBuilder type);

  R visitNamedTypeBuilder(NamedTypeBuilder type);

  R visitRecordTypeBuilder(RecordTypeBuilder type);
}

/// Recursively visits a DartType tree until any visit method returns `false`.
class RecursiveTypeVisitor extends UnifyingTypeVisitor<bool> {
  final bool includeTypeAliasArguments;

  /// If [includeTypeAliasArguments], also visits type arguments of
  /// [InstantiatedTypeAliasElement]s associated with types.
  RecursiveTypeVisitor({required this.includeTypeAliasArguments});

  /// Visit each item in the list until one returns `false`, in which case, this
  /// will also return `false`.
  bool visitChildren(Iterable<DartType> types) =>
      types.every((type) => type.accept(this));

  @override
  bool visitDartType(DartType type) {
    visitChildren(_maybeTypeAliasArguments(type));
    return true;
  }

  @override
  bool visitFunctionType(FunctionType type) {
    return visitChildren([
      ..._maybeTypeAliasArguments(type),
      type.returnType,
      ...type.typeParameters
          .map((typeParameter) => typeParameter.bound)
          .where((type) => type != null)
          .map((type) => type!),
      ...type.formalParameters.map((formalParameter) => formalParameter.type),
    ]);
  }

  @override
  bool visitInterfaceType(InterfaceType type) {
    return visitChildren([
      ..._maybeTypeAliasArguments(type),
      ...type.typeArguments,
    ]);
  }

  @override
  bool visitRecordType(covariant RecordTypeImpl type) {
    return visitChildren([
      ..._maybeTypeAliasArguments(type),
      ...type.positionalFields.map((field) => field.type),
      ...type.namedFields.map((field) => field.type),
    ]);
  }

  @override
  bool visitTypeParameterType(TypeParameterType type) {
    visitChildren(_maybeTypeAliasArguments(type));
    // TODO(scheglov): Should we visit the bound here?
    return true;
  }

  List<DartType> _maybeTypeAliasArguments(DartType type) {
    if (includeTypeAliasArguments) {
      if (type.alias case var alias?) {
        return alias.typeArguments;
      }
    }
    return const [];
  }
}
