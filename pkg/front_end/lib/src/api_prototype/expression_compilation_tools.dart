// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart'
    show
        Class,
        DartType,
        DynamicType,
        InterfaceType,
        Library,
        NamedType,
        Nullability,
        RecordType,
        TypeParameter;
import 'package:kernel/library_index.dart' show LibraryIndex;

import 'incremental_kernel_generator.dart' show isLegalIdentifier;
import 'lowering_predicates.dart' show isExtensionThisName;

// Coverage-ignore(suite): Not run.
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

// Coverage-ignore(suite): Not run.
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

// Coverage-ignore(suite): Not run.
List<ParsedType> parseDefinitionTypes(List<String> definitionTypes) {
  List<ParsedType> result = [];
  int i = 0;
  List<ParsedType> argumentReceivers = [];
  while (i < definitionTypes.length) {
    String uriOrSpecialString = definitionTypes[i];
    if (uriOrSpecialString == "null") {
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
    } else if (uriOrSpecialString == "record") {
      // Record.
      // We expect at least 4 elements: "record", nullability, num fields,
      // num positional fields.
      if (i + 4 > definitionTypes.length) throw "invalid input";
      int nullability = int.parse(definitionTypes[i + 1]);
      int numFields = int.parse(definitionTypes[i + 2]);
      int numPositionalFields = int.parse(definitionTypes[i + 3]);
      i += 4;

      List<String?> fieldNames = new List<String?>.filled(numFields, null);
      for (int j = numPositionalFields; j < numFields; j++) {
        fieldNames[j] = definitionTypes[i++];
      }

      ParsedType type = new ParsedType.record(nullability, fieldNames);
      if (argumentReceivers.isEmpty) {
        result.add(type);
      } else {
        argumentReceivers.removeLast().arguments!.add(type);
      }
      for (int j = 0; j < numFields; j++) {
        argumentReceivers.add(type);
      }
    } else {
      // We expect at least 4 elements: Uri, class name, nullability,
      // number of type arguments.
      if (i + 4 > definitionTypes.length) throw "invalid input";
      String className = definitionTypes[i + 1];
      int nullability = int.parse(definitionTypes[i + 2]);
      int typeArgumentsCount = int.parse(definitionTypes[i + 3]);
      ParsedType type =
          new ParsedType.interface(uriOrSpecialString, className, nullability);
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

enum ParsedTypeKind {
  Null,
  Interface,
  Record,
}

// Coverage-ignore(suite): Not run.
class ParsedType {
  final ParsedTypeKind type;
  final String? uri;
  final String? className;
  final int? nullability;
  final List<ParsedType>? arguments;
  final List<String?>? recordFieldNames;

  ParsedType.interface(this.uri, this.className, this.nullability)
      : type = ParsedTypeKind.Interface,
        arguments = [],
        recordFieldNames = null;

  ParsedType.record(this.nullability, this.recordFieldNames)
      : type = ParsedTypeKind.Record,
        uri = null,
        className = null,
        arguments = [];

  ParsedType.nullType()
      : type = ParsedTypeKind.Null,
        uri = null,
        className = null,
        nullability = null,
        arguments = null,
        recordFieldNames = null;

  @override
  bool operator ==(Object other) {
    if (other is! ParsedType) return false;
    if (type != other.type) return false;
    if (uri != other.uri) return false;
    if (className != other.className) return false;
    if (nullability != other.nullability) return false;
    if (arguments?.length != other.arguments?.length) return false;
    if (arguments != null) {
      for (int i = 0; i < arguments!.length; i++) {
        if (arguments![i] != other.arguments![i]) return false;
      }
    }
    if (recordFieldNames?.length != other.recordFieldNames?.length) {
      return false;
    }
    if (recordFieldNames != null) {
      for (int i = 0; i < recordFieldNames!.length; i++) {
        if (recordFieldNames![i] != other.recordFieldNames![i]) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    if (type == ParsedTypeKind.Null) return 0;
    int hash = 0x3fffffff & uri.hashCode;
    hash = 0x3fffffff & (hash * 31 + (hash ^ className.hashCode));
    hash = 0x3fffffff & (hash * 31 + (hash ^ nullability.hashCode));
    for (ParsedType argument in arguments!) {
      hash = 0x3fffffff & (hash * 31 + (hash ^ argument.hashCode));
    }
    if (recordFieldNames != null) {
      for (String? name in recordFieldNames!) {
        hash = 0x3fffffff & (hash * 31 + (hash ^ name.hashCode));
      }
    }
    return hash;
  }

  @override
  String toString() {
    switch (type) {
      case ParsedTypeKind.Null:
        return "null-type";
      case ParsedTypeKind.Interface:
        return "Record[$recordFieldNames] ($nullability) ($arguments)";
      case ParsedTypeKind.Record:
        if (arguments?.isEmpty ?? true) {
          return "$uri[$className] ($nullability)";
        }
        return "$uri[$className] ($nullability) <$arguments>";
    }
  }

  DartType createDartType(LibraryIndex libraryIndex) {
    switch (type) {
      case ParsedTypeKind.Null:
        return new DynamicType();
      case ParsedTypeKind.Record:
        List<DartType> positional = [];
        List<NamedType> named = [];
        for (int i = 0; i < arguments!.length; i++) {
          String? name = recordFieldNames![i];
          DartType type = arguments![i].createDartType(libraryIndex);
          if (name == null) {
            positional.add(type);
          } else {
            named.add(new NamedType(name, type));
          }
        }
        return new RecordType(positional, named, _getDartNullability());
      case ParsedTypeKind.Interface:
        Class? classNode = libraryIndex.tryGetClass(uri!, className!);
        if (classNode == null) return new DynamicType();

        return new InterfaceType(
            classNode,
            _getDartNullability(),
            arguments
                ?.map((e) => e.createDartType(libraryIndex))
                .toList(growable: false));
    }
  }

  Nullability _getDartNullability() {
    if (type == ParsedTypeKind.Null) throw "No nullability on the null type";
    if (nullability == 0) return Nullability.nullable;
    if (nullability == 1) return Nullability.nonNullable;
    if (nullability == 2) return Nullability.legacy;
    throw "Unknown nullability";
  }
}

// Coverage-ignore(suite): Not run.
Set<String> collectParsedTypeUris(List<ParsedType> parsedTypes) {
  Set<String> result = {};
  List<ParsedType> workList = new List.from(parsedTypes);
  while (workList.isNotEmpty) {
    ParsedType type = workList.removeLast();
    if (type.arguments != null) workList.addAll(type.arguments!);
    switch (type.type) {
      case ParsedTypeKind.Null:
      case ParsedTypeKind.Record:
        continue;
      case ParsedTypeKind.Interface:
        result.add(type.uri!);
    }
  }
  return result;
}
