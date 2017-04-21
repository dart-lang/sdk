// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.procedure_builder;

// Note: we're deliberately using AsyncMarker and ProcedureKind from kernel
// outside the kernel-specific builders. This is simpler than creating
// additional enums.
import 'package:kernel/ast.dart' show AsyncMarker, ProcedureKind;

import 'builder.dart'
    show
        Builder,
        FormalParameterBuilder,
        LibraryBuilder,
        MemberBuilder,
        MetadataBuilder,
        Scope,
        TypeBuilder,
        TypeVariableBuilder;

abstract class ProcedureBuilder<T extends TypeBuilder> extends MemberBuilder {
  final List<MetadataBuilder> metadata;

  final int modifiers;

  final T returnType;

  final String name;

  final List<TypeVariableBuilder> typeVariables;

  final List<FormalParameterBuilder> formals;

  ProcedureBuilder(
      this.metadata,
      this.modifiers,
      this.returnType,
      this.name,
      this.typeVariables,
      this.formals,
      LibraryBuilder compilationUnit,
      int charOffset)
      : super(compilationUnit, charOffset);

  AsyncMarker get asyncModifier;

  ProcedureKind get kind;

  bool get isConstructor => false;

  bool get isRegularMethod => identical(ProcedureKind.Method, kind);

  bool get isGetter => identical(ProcedureKind.Getter, kind);

  bool get isSetter => identical(ProcedureKind.Setter, kind);

  bool get isOperator => identical(ProcedureKind.Operator, kind);

  bool get isFactory => identical(ProcedureKind.Factory, kind);

  void set body(covariant statement);

  /// This is the formal parameter scope as specified in the Dart Programming
  /// Language Specifiction, 4th ed, section 9.2.
  Scope computeFormalParameterScope(Scope parent) {
    if (formals == null) return parent;
    Map<String, Builder> local = <String, Builder>{};
    for (FormalParameterBuilder formal in formals) {
      if (!isConstructor || !formal.hasThis) {
        local[formal.name] = formal;
      }
    }
    return new Scope(local, null, parent, isModifiable: false);
  }

  /// This scope doesn't correspond to any scope specified in the Dart
  /// Programming Language Specifiction, 4th ed. It's an unspecified extension
  /// to support generic methods.
  Scope computeTypeParameterScope(Scope parent) {
    if (typeVariables == null) return parent;
    Map<String, Builder> local = <String, Builder>{};
    for (TypeVariableBuilder variable in typeVariables) {
      local[variable.name] = variable;
    }
    return new Scope(local, null, parent, isModifiable: false);
  }
}
