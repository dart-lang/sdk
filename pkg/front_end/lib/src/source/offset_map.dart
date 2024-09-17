// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:front_end/src/source/type_parameter_scope_builder.dart';
import 'package:kernel/ast.dart';

import '../base/export.dart';
import '../base/identifiers.dart';
import '../base/import.dart';
import '../base/problems.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../codes/cfe_codes.dart';
import '../fragment/fragment.dart';
import 'source_field_builder.dart';
import 'source_function_builder.dart';

/// Map from offsets of directives and declarations to the objects the define.
///
/// This is used to connect parsing of the [OutlineBuilder], where the objects
/// are created, with the [DietListener], where the objects are looked up.
class OffsetMap {
  final Uri uri;
  final Map<int, DeclarationFragment> _declarationFragments = {};
  final Map<int, FieldFragment> _fields = {};
  final Map<int, SourceFunctionBuilder> _constructors = {};
  final Map<int, ConstructorFragment> _constructorFragments = {};
  final Map<int, MethodFragment> _procedures = {};
  final Map<int, LibraryPart> _parts = {};
  final Map<int, Import> _imports = {};
  final Map<int, Export> _exports = {};

  OffsetMap(this.uri);

  void registerImport(Token importKeyword, Import import) {
    assert(importKeyword.lexeme == 'import',
        "Invalid token for import: $importKeyword.");
    _imports[importKeyword.charOffset] = import;
  }

  Import lookupImport(Token importKeyword) {
    assert(importKeyword.lexeme == 'import',
        "Invalid token for import: $importKeyword.");
    return _checkDirective(_imports[importKeyword.charOffset], '<import>',
        importKeyword.charOffset);
  }

  void registerExport(Token exportKeyword, Export export) {
    assert(exportKeyword.lexeme == 'export',
        "Invalid token for export: $exportKeyword.");
    _exports[exportKeyword.charOffset] = export;
  }

  Export lookupExport(Token exportKeyword) {
    assert(exportKeyword.lexeme == 'export',
        "Invalid token for export: $exportKeyword.");
    return _checkDirective(_exports[exportKeyword.charOffset], '<export>',
        exportKeyword.charOffset);
  }

  void registerPart(Token partKeyword, LibraryPart part) {
    assert(
        partKeyword.lexeme == 'part', "Invalid token for part: $partKeyword.");
    _parts[partKeyword.charOffset] = part;
  }

  LibraryPart lookupPart(Token partKeyword) {
    assert(
        partKeyword.lexeme == 'part', "Invalid token for part: $partKeyword.");
    return _checkDirective(
        _parts[partKeyword.charOffset], '<part>', partKeyword.charOffset);
  }

  void registerNamedDeclarationFragment(
      Identifier identifier, DeclarationFragment fragment) {
    _declarationFragments[identifier.nameOffset] = fragment;
  }

  DeclarationBuilder lookupNamedDeclaration(Identifier identifier) {
    return _checkBuilder(_declarationFragments[identifier.nameOffset]?.builder,
        identifier.name, identifier.nameOffset);
  }

  void registerUnnamedDeclaration(
      Token beginToken, DeclarationFragment fragment) {
    _declarationFragments[beginToken.charOffset] = fragment;
  }

  DeclarationBuilder lookupUnnamedDeclaration(Token beginToken) {
    return _checkBuilder(_declarationFragments[beginToken.charOffset]?.builder,
        '<unnamed-declaration>', beginToken.charOffset);
  }

  void registerField(Identifier identifier, FieldFragment fragment) {
    _fields[identifier.nameOffset] = fragment;
  }

  SourceFieldBuilder lookupField(Identifier identifier) {
    return _checkBuilder(_fields[identifier.nameOffset]?.builder,
        identifier.name, identifier.nameOffset);
  }

  void registerPrimaryConstructor(
      Token beginToken, ConstructorFragment builder) {
    _constructorFragments[beginToken.charOffset] = builder;
  }

  SourceFunctionBuilder lookupPrimaryConstructor(Token beginToken) {
    return _checkBuilder(_constructorFragments[beginToken.charOffset]?.builder,
        '<primary-constructor>', beginToken.charOffset);
  }

  void registerConstructor(
      Identifier identifier, SourceFunctionBuilder builder) {
    _constructors[identifier.nameOffset] = builder;
  }

  void registerConstructorFragment(
      Identifier identifier, ConstructorFragment fragment) {
    _constructorFragments[identifier.nameOffset] = fragment;
  }

  SourceFunctionBuilder lookupConstructor(Identifier identifier) {
    return _checkBuilder(
        _constructors[identifier.nameOffset] ??
            _constructorFragments[identifier.nameOffset]?.builder,
        identifier.name,
        identifier.nameOffset);
  }

  void registerProcedure(Identifier identifier, MethodFragment fragment) {
    _procedures[identifier.nameOffset] = fragment;
  }

  SourceFunctionBuilder lookupProcedure(Identifier identifier) {
    return _checkBuilder(_procedures[identifier.nameOffset]?.builder,
        identifier.name, identifier.nameOffset);
  }

  T _checkDirective<T>(T? directive, String name, int charOffset) {
    if (directive == null) {
      internalProblem(
          templateInternalProblemNotFound.withArguments(name), charOffset, uri);
    }
    return directive;
  }

  T _checkBuilder<T extends Builder>(
      T? declaration, String name, int charOffset) {
    if (declaration == null) {
      internalProblem(
          templateInternalProblemNotFound.withArguments(name), charOffset, uri);
    }
    if (uri != declaration.fileUri) {
      unexpected("$uri", "${declaration.fileUri}", declaration.charOffset,
          declaration.fileUri);
    }
    return declaration;
  }
}
