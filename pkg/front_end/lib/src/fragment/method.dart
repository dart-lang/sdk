// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class MethodFragment implements Fragment, FunctionFragment {
  @override
  final String name;

  final Uri fileUri;
  final int startOffset;
  final int nameOffset;
  final int formalsOffset;
  final int endOffset;
  final bool isTopLevel;
  final List<MetadataBuilder>? metadata;
  final Modifiers modifiers;

  /// The declared return type of this method.
  ///
  /// If the return type was omitted, this is an [InferableTypeBuilder].
  final TypeBuilder returnType;

  /// The name space for the type parameters available on this method.
  ///
  /// Initially this contains only the [declaredTypeParameters], but for
  /// extension and extension type instance method this will include type
  /// parameters cloned from the extension or extension type, respectively.
  final NominalParameterNameSpace typeParameterNameSpace;

  /// The declared type parameters on this method.
  final List<TypeParameterFragment>? declaredTypeParameters;

  /// The scope in which the method is declared.
  ///
  /// This is the scope used for resolving the [metadata].
  final LookupScope enclosingScope;

  /// The scope that introduces type parameters on this method.
  ///
  /// This is based on [typeParameterNameSpace] and initially this contains only
  /// the [declaredTypeParameters], but for extension and extension type
  /// instance methods this will include type parameters cloned from the
  /// extension or extension type, respectively.
  final LookupScope typeParameterScope;

  /// The declared formals on this method.
  final List<FormalParameterBuilder>? declaredFormals;

  final bool isOperator;
  final AsyncMarker asyncModifier;
  final String? nativeMethodName;

  final DeclarationFragment? enclosingDeclaration;
  final LibraryFragment enclosingCompilationUnit;

  SourceMethodBuilder? _builder;

  MethodFragmentDeclaration? _declaration;

  @override
  late final UriOffsetLength uriOffset = new UriOffsetLength(
    fileUri,
    nameOffset,
    name.length,
  );

  MethodFragment({
    required this.name,
    required this.fileUri,
    required this.startOffset,
    required this.nameOffset,
    required this.formalsOffset,
    required this.endOffset,
    required this.isTopLevel,
    required this.metadata,
    required this.modifiers,
    required this.returnType,
    required this.declaredTypeParameters,
    required this.typeParameterNameSpace,
    required this.enclosingScope,
    required this.typeParameterScope,
    required this.declaredFormals,
    required this.isOperator,
    required this.asyncModifier,
    required this.nativeMethodName,
    required this.enclosingDeclaration,
    required this.enclosingCompilationUnit,
  });

  @override
  SourceMethodBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceMethodBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  MethodFragmentDeclaration get declaration {
    assert(
      _declaration != null,
      "Declaration has not been computed for $this.",
    );
    return _declaration!;
  }

  void set declaration(MethodFragmentDeclaration value) {
    assert(
      _declaration == null,
      "Declaration has already been computed for $this.",
    );
    _declaration = value;
  }

  @override
  FunctionBodyBuildingContext createFunctionBodyBuildingContext() {
    return new _MethodBodyBuildingContext(this);
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$nameOffset)';
}

class _MethodBodyBuildingContext implements FunctionBodyBuildingContext {
  MethodFragment _fragment;

  _MethodBodyBuildingContext(this._fragment);

  @override
  InferenceDataForTesting? get inferenceDataForTesting => _fragment
      .builder
      .dataForTesting
      // Coverage-ignore(suite): Not run.
      ?.inferenceData;

  @override
  MemberKind get memberKind => _fragment.isTopLevel
      ? MemberKind.TopLevelMethod
      : (_fragment.modifiers.isStatic
            ? MemberKind.StaticMethod
            : MemberKind.NonStaticMethod);

  @override
  bool get shouldBuild => true;

  @override
  List<TypeParameter>? get thisTypeParameters =>
      _fragment.declaration.thisTypeParameters;

  @override
  VariableDeclaration? get thisVariable => _fragment.declaration.thisVariable;

  @override
  ExtensionScope get extensionScope {
    return _fragment.enclosingCompilationUnit.extensionScope;
  }

  @override
  LookupScope get typeParameterScope {
    return _fragment.typeParameterScope;
  }

  @override
  LocalScope get formalParameterScope {
    return _fragment.declaration.createFormalParameterScope(typeParameterScope);
  }

  @override
  BodyBuilderContext createBodyBuilderContext() {
    return _fragment.declaration.createBodyBuilderContext(_fragment.builder);
  }
}
