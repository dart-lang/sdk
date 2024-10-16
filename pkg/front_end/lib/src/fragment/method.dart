// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class MethodFragment implements Fragment {
  final String name;
  final Uri fileUri;
  final int startCharOffset;
  final int charOffset;
  final int charOpenParenOffset;
  final int charEndOffset;
  final List<MetadataBuilder>? metadata;
  final Modifiers modifiers;
  final TypeBuilder returnType;
  final List<NominalVariableBuilder>? typeParameters;
  final List<FormalParameterBuilder>? formals;
  final ProcedureKind kind;
  final AsyncMarker asyncModifier;
  final String? nativeMethodName;

  SourceProcedureBuilder? _builder;

  MethodFragment(
      {required this.name,
      required this.fileUri,
      required this.startCharOffset,
      required this.charOffset,
      required this.charOpenParenOffset,
      required this.charEndOffset,
      required this.metadata,
      required this.modifiers,
      required this.returnType,
      required this.typeParameters,
      required this.formals,
      required this.kind,
      required this.asyncModifier,
      required this.nativeMethodName});

  @override
  SourceProcedureBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceProcedureBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$charOffset)';
}
