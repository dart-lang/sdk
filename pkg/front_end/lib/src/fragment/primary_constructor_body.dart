// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class PrimaryConstructorBodyFragment implements Fragment, FunctionFragment {
  static const String nameSentinel = '_primary-constructor-body_';

  final Uri fileUri;
  final int thisOffset;
  final List<MetadataBuilder>? metadata;

  /// The scope in which the constructor body is declared.
  ///
  /// This is the scope used for resolving the [metadata].
  final LookupScope enclosingScope;

  final DeclarationFragment enclosingDeclaration;
  final LibraryFragment enclosingCompilationUnit;

  /// Whether this primary constructor body declaration was declared with a
  /// constructor body.
  ///
  /// For instance
  ///
  ///   class C1() {
  ///     this {}
  ///   }
  ///
  /// as opposed to
  ///
  ///   class C2() {
  ///     this;
  ///   }
  ///
  final bool hasBody;

  /// The offset of the constructor body.
  final int bodyOffset;

  PrimaryConstructorFragment? _primaryConstructorFragment;

  SourceConstructorBuilder? _builder;

  PrimaryConstructorBodyFragment({
    required this.fileUri,
    required this.thisOffset,
    required this.metadata,
    required this.enclosingScope,
    required this.enclosingDeclaration,
    required this.enclosingCompilationUnit,
    required this.hasBody,
    required this.bodyOffset,
  });

  @override
  late final UriOffsetLength uriOffset = new UriOffsetLength(
    fileUri,
    thisOffset,
    4,
  );

  @override
  SourceConstructorBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceConstructorBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  void registerPrimaryConstructorFragment(
    ProblemReporting problemReporting,
    PrimaryConstructorFragment primaryConstructorFragment,
  ) {
    _primaryConstructorFragment = primaryConstructorFragment;
    if (primaryConstructorFragment.modifiers.isConst && hasBody) {
      problemReporting.addProblem(
        diag.constConstructorWithBody,
        bodyOffset,
        noLength,
        fileUri,
      );
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get name => nameSentinel;

  @override
  FunctionBodyBuildingContext? createFunctionBodyBuildingContext() {
    if (_primaryConstructorFragment == null) {
      // This primary constructor body has no corresponding primary constructor,
      // so we skip building the body.
      return null;
    }
    return new _PrimaryConstructorBodyBuildingContext(
      _primaryConstructorFragment!,
      shouldFinishFunction: true,
    );
  }
}
