// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class FieldFragment implements Fragment {
  @override
  final String name;

  final Uri fileUri;

  final int nameOffset;

  final int endOffset;

  Token? _initializerToken;
  Token? _constInitializerToken;

  final List<MetadataBuilder>? metadata;

  final TypeBuilder type;

  final bool isTopLevel;
  final Modifiers modifiers;

  final LookupScope enclosingScope;

  final DeclarationFragment? enclosingDeclaration;
  final LibraryFragment enclosingCompilationUnit;

  SourcePropertyBuilder? _builder;
  FieldFragmentDeclaration? _declaration;

  @override
  late final UriOffsetLength uriOffset = new UriOffsetLength(
    fileUri,
    nameOffset,
    name.length,
  );

  FieldFragment({
    required this.name,
    required this.fileUri,
    required this.nameOffset,
    required this.endOffset,
    required Token? initializerToken,
    required Token? constInitializerToken,
    required this.metadata,
    required this.type,
    required this.isTopLevel,
    required this.modifiers,
    required this.enclosingScope,
    required this.enclosingDeclaration,
    required this.enclosingCompilationUnit,
  }) : _initializerToken = initializerToken,
       _constInitializerToken = constInitializerToken;

  @override
  SourcePropertyBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourcePropertyBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  /// Returns the token for the initializer of this field, if any. This is the
  /// same as [initializerToken] but is used to signal that the initializer
  /// needs to be computed for outline expressions.
  ///
  /// This can only be called once and will hand over the responsibility of
  /// the token to the caller.
  Token? takeConstInitializerToken() {
    Token? result = _constInitializerToken;
    // Ensure that we don't hold onto the token.
    _constInitializerToken = null;
    return result;
  }

  FieldFragmentDeclaration get declaration {
    assert(
      _declaration != null,
      "Declaration has not been computed for $this.",
    );
    return _declaration!;
  }

  void set declaration(FieldFragmentDeclaration value) {
    assert(
      _declaration == null,
      "Declaration has already been computed for $this.",
    );
    _declaration = value;
  }

  bool get hasSetter {
    if (modifiers.isConst) {
      return false;
    } else if (modifiers.isFinal) {
      if (modifiers.isLate) {
        return !modifiers.hasInitializer;
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  /// Returns the token for the initializer of this field, if any.
  ///
  /// This can only be called once and will hand over the responsibility of
  /// the token to the caller.
  Token? takeInitializerToken() {
    Token? result = _initializerToken;
    // Ensure that we don't hold on to the token.
    _initializerToken = null;
    return result;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$nameOffset)';
}
