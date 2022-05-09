// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart'
    show isLegalIdentifier;

import 'package:front_end/src/api_prototype/lowering_predicates.dart'
    show isExtensionThisName;

import 'package:kernel/ast.dart'
    show
        Class,
        DartType,
        DynamicType,
        InterfaceType,
        Library,
        Nullability,
        TypeParameter;

import 'package:kernel/library_index.dart' show LibraryIndex;

Map<String, DartType>? createDefinitionsWithTypes(
    Iterable<Library>? knownLibraries,
    List<String> definitionTypes,
    List<String> definitions) {
  if (knownLibraries == null) {
    return null;
  }

  List<ParsedType> definitionTypesParsed =
      parseDefinitionTypes(definitionTypes);
  if (definitionTypesParsed.length != definitions.length) {
    return null;
  }

  Set<String> libraryUris = collectParsedTypeUris(definitionTypesParsed);
  LibraryIndex libraryIndex =
      new LibraryIndex.fromLibraries(knownLibraries, libraryUris);

  Map<String, DartType> completeDefinitions = {};
  for (int i = 0; i < definitions.length; i++) {
    String name = definitions[i];
    if (isLegalIdentifier(name) || (i == 0 && isExtensionThisName(name))) {
      ParsedType type = definitionTypesParsed[i];
      DartType dartType = type.createDartType(libraryIndex);
      completeDefinitions[name] = dartType;
    }
  }
  return completeDefinitions;
}

List<TypeParameter>? createTypeParametersWithBounds(
    Iterable<Library>? knownLibraries,
    List<String> typeBounds,
    List<String> typeDefaults,
    List<String> typeDefinitions) {
  if (knownLibraries == null) {
    return null;
  }

  List<ParsedType> typeBoundsParsed = parseDefinitionTypes(typeBounds);
  if (typeBoundsParsed.length != typeDefinitions.length) {
    return null;
  }
  List<ParsedType> typeDefaultsParsed = parseDefinitionTypes(typeDefaults);
  if (typeDefaultsParsed.length != typeDefinitions.length) {
    return null;
  }

  Set<String> libraryUris = collectParsedTypeUris(typeBoundsParsed)
    ..addAll(collectParsedTypeUris(typeDefaultsParsed));
  LibraryIndex libraryIndex =
      new LibraryIndex.fromLibraries(knownLibraries, libraryUris);

  List<TypeParameter> typeParameters = [];
  for (int i = 0; i < typeDefinitions.length; i++) {
    String name = typeDefinitions[i];
    if (!isLegalIdentifier(name)) continue;
    ParsedType bound = typeBoundsParsed[i];
    DartType dartTypeBound = bound.createDartType(libraryIndex);
    ParsedType defaultType = typeDefaultsParsed[i];
    DartType dartTypeDefaultType = defaultType.createDartType(libraryIndex);
    typeParameters
        .add(new TypeParameter(name, dartTypeBound, dartTypeDefaultType));
  }
  return typeParameters;
}

List<ParsedType> parseDefinitionTypes(List<String> definitionTypes) {
  List<ParsedType> result = [];
  int i = 0;
  List<ParsedType> argumentReceivers = [];
  while (i < definitionTypes.length) {
    String uriOrNullString = definitionTypes[i];
    if (uriOrNullString == "null") {
      if (argumentReceivers.isEmpty) {
        result.add(new ParsedType.nullType());
      } else {
        argumentReceivers
            .removeLast()
            .arguments!
            .add(new ParsedType.nullType());
      }
      i++;
      continue;
    } else {
      // We expect at least 4 elements: Uri, class name, nullability,
      // number of type arguments.
      if (i + 4 > definitionTypes.length) throw "invalid input";
      String className = definitionTypes[i + 1];
      int nullability = int.parse(definitionTypes[i + 2]);
      int typeArgumentsCount = int.parse(definitionTypes[i + 3]);
      ParsedType type = new ParsedType(uriOrNullString, className, nullability);
      if (argumentReceivers.isEmpty) {
        result.add(type);
      } else {
        argumentReceivers.removeLast().arguments!.add(type);
      }
      for (int j = 0; j < typeArgumentsCount; j++) {
        argumentReceivers.add(type);
      }
      i += 4;
    }
  }
  if (argumentReceivers.isNotEmpty) {
    throw "Nesting error on input $definitionTypes";
  }
  return result;
}

class ParsedType {
  final String? uri;
  final String? className;
  final int? nullability;
  final List<ParsedType>? arguments;

  bool get isNullType => uri == null;

  ParsedType(this.uri, this.className, this.nullability) : arguments = [];

  ParsedType.nullType()
      : uri = null,
        className = null,
        nullability = null,
        arguments = null;

  @override
  bool operator ==(Object other) {
    if (other is! ParsedType) return false;
    if (uri != other.uri) return false;
    if (className != other.className) return false;
    if (nullability != other.nullability) return false;
    if (arguments?.length != other.arguments?.length) return false;
    if (arguments != null) {
      for (int i = 0; i < arguments!.length; i++) {
        if (arguments![i] != other.arguments![i]) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    if (isNullType) return 0;
    int hash = 0x3fffffff & uri.hashCode;
    hash = 0x3fffffff & (hash * 31 + (hash ^ className.hashCode));
    hash = 0x3fffffff & (hash * 31 + (hash ^ nullability.hashCode));
    for (ParsedType argument in arguments!) {
      hash = 0x3fffffff & (hash * 31 + (hash ^ argument.hashCode));
    }
    return hash;
  }

  @override
  String toString() {
    if (isNullType) return "null-type";
    return "$uri[$className] ($nullability) <$arguments>";
  }

  DartType createDartType(LibraryIndex libraryIndex) {
    if (isNullType) return new DynamicType();
    Class? classNode = libraryIndex.tryGetClass(uri!, className!);
    if (classNode == null) return new DynamicType();

    return new InterfaceType(
        classNode,
        _getDartNullability(),
        arguments
            ?.map((e) => e.createDartType(libraryIndex))
            .toList(growable: false));
  }

  Nullability _getDartNullability() {
    if (isNullType) throw "No nullability on the null type";
    if (nullability == 0) return Nullability.nullable;
    if (nullability == 1) return Nullability.nonNullable;
    if (nullability == 2) return Nullability.legacy;
    throw "Unknown nullability";
  }
}

Set<String> collectParsedTypeUris(List<ParsedType> parsedTypes) {
  Set<String> result = {};
  List<ParsedType> workList = new List.from(parsedTypes);
  while (workList.isNotEmpty) {
    ParsedType type = workList.removeLast();
    if (type.isNullType) continue;
    result.add(type.uri!);
    workList.addAll(type.arguments!);
  }
  return result;
}
