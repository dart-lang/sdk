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

/// Map from offsets of directives and declarations to the objects the define.
///
/// This is used to connect parsing of the [OutlineBuilder], where the objects
/// are created, with the [DietListener], where the objects are looked up.
class OffsetMap {
  final Uri uri;
  final Map<int, DeclarationFragment> _declarations = {};
  final Map<int, FieldFragment> _fields = {};
  final Map<int, PrimaryConstructorFragment> _primaryConstructors = {};
  final Map<int, ConstructorFragment> _constructors = {};
  final Map<int, FactoryFragment> _factoryFragments = {};
  final Map<int, GetterFragment> _getters = {};
  final Map<int, SetterFragment> _setters = {};
  final Map<int, MethodFragment> _methods = {};
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
    _declarations[identifier.nameOffset] = fragment;
  }

  DeclarationBuilder lookupNamedDeclaration(Identifier identifier) {
    return _checkBuilder(_declarations[identifier.nameOffset]?.builder,
        identifier.name, identifier.nameOffset);
  }

  void registerUnnamedDeclaration(
      Token beginToken, DeclarationFragment fragment) {
    _declarations[beginToken.charOffset] = fragment;
  }

  DeclarationBuilder lookupUnnamedDeclaration(Token beginToken) {
    return _checkBuilder(_declarations[beginToken.charOffset]?.builder,
        '<unnamed-declaration>', beginToken.charOffset);
  }

  void registerField(Identifier identifier, FieldFragment fragment) {
    _fields[identifier.nameOffset] = fragment;
  }

  FieldFragment lookupField(Identifier identifier) {
    return _checkFragment(
        _fields[identifier.nameOffset], identifier.name, identifier.nameOffset);
  }

  void registerPrimaryConstructor(
      Token beginToken, PrimaryConstructorFragment fragment) {
    _primaryConstructors[beginToken.charOffset] = fragment;
  }

  FunctionFragment lookupPrimaryConstructor(Token beginToken) {
    return _checkFragment(_primaryConstructors[beginToken.charOffset],
        '<primary-constructor>', beginToken.charOffset);
  }

  void registerConstructorFragment(
      Identifier identifier, ConstructorFragment fragment) {
    _constructors[identifier.nameOffset] = fragment;
  }

  void registerFactoryFragment(
      Identifier identifier, FactoryFragment fragment) {
    _factoryFragments[identifier.nameOffset] = fragment;
  }

  FunctionFragment lookupConstructor(Identifier identifier) {
    FunctionFragment? fragment = _constructors[identifier.nameOffset];
    fragment ??= _factoryFragments[identifier.nameOffset];
    return _checkFragment(fragment, identifier.name, identifier.nameOffset);
  }

  void registerGetter(Identifier identifier, GetterFragment fragment) {
    _getters[identifier.nameOffset] = fragment;
  }

  void registerSetter(Identifier identifier, SetterFragment fragment) {
    _setters[identifier.nameOffset] = fragment;
  }

  void registerMethod(Identifier identifier, MethodFragment fragment) {
    _methods[identifier.nameOffset] = fragment;
  }

  FunctionFragment lookupGetter(Identifier identifier) {
    return _checkFragment(_getters[identifier.nameOffset], identifier.name,
        identifier.nameOffset);
  }

  FunctionFragment lookupSetter(Identifier identifier) {
    return _checkFragment(_setters[identifier.nameOffset], identifier.name,
        identifier.nameOffset);
  }

  FunctionFragment lookupMethod(Identifier identifier) {
    return _checkFragment(_methods[identifier.nameOffset], identifier.name,
        identifier.nameOffset);
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
      unexpected("$uri", "${declaration.fileUri}", declaration.fileOffset,
          declaration.fileUri);
    }
    return declaration;
  }

  T _checkFragment<T>(T? fragment, String name, int fileOffset) {
    if (fragment == null) {
      internalProblem(
          templateInternalProblemNotFound.withArguments(name), fileOffset, uri);
    }
    return fragment;
  }
}
