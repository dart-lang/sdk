// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class ConstructorFragment implements Fragment {
  final String name;
  final Uri fileUri;
  final int startCharOffset;
  final int charOffset;
  final int charOpenParenOffset;
  final int charEndOffset;
  final Modifiers modifiers;
  final List<MetadataBuilder>? metadata;
  final OmittedTypeBuilder returnType;
  final List<NominalVariableBuilder>? typeParameters;
  final List<FormalParameterBuilder>? formals;
  final String? nativeMethodName;
  final bool forAbstractClassOrMixin;
  Token? _beginInitializers;

  AbstractSourceConstructorBuilder? _builder;

  ConstructorFragment(
      {required this.name,
      required this.fileUri,
      required this.startCharOffset,
      required this.charOffset,
      required this.charOpenParenOffset,
      required this.charEndOffset,
      required this.modifiers,
      required this.metadata,
      required this.returnType,
      required this.typeParameters,
      required this.formals,
      required this.nativeMethodName,
      required this.forAbstractClassOrMixin,
      required Token? beginInitializers})
      : _beginInitializers = beginInitializers;

  Token? get beginInitializers {
    Token? result = _beginInitializers;
    // Ensure that we don't hold onto the token.
    _beginInitializers = null;
    return result;
  }

  @override
  AbstractSourceConstructorBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(AbstractSourceConstructorBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$charOffset)';
}
