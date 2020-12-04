// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Generates the type tables used by DartFuzz.
//
// Usage:
//   dart gen_type_table.dart > dartfuzz_type_table.dart
//
// Reformat:
//   tools/sdks/dart-sdk/bin/dartfmt -w \
//   runtime/tools/dartfuzz/dartfuzz_type_table.dart
//
// Then send out modified dartfuzz_type_table.dart for review together
// with a modified dartfuzz.dart that increases the version.

import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import 'gen_util.dart';

// Minimum number of operators that are required for a type to be included in
// the type table.
final int operatorCountThreshold = 2;

//
// Operators and functions.
//

// Map type to a list of constructors names with a list of constructor
// parameter types.
Map<String, Map<String, List<String>>> constructors =
    new Map<String, Map<String, List<String>>>();

// Map type to a list of assignment operators with a set of the
// assignable right hand side types.
Map<String, Map<String, Set<String>>> assignOps =
    new Map<String, Map<String, Set<String>>>();

// Map type to a list of binary operators with set of the respective
// types for the first and second operand.
Map<String, Map<String, Set<List<String>>>> binOps =
    new Map<String, Map<String, Set<List<String>>>>();

// Map type to a list of available unary operators.
Map<String, Set<String>> uniOps = new Map<String, Set<String>>();

//
// Type grouping.
//

// All Set<E> types: SET_INT, SET_STRING, etc.
Set<String> setTypes = new Set<String>();

// All Map<K, V> types: MAP_INT_STRING, MAP_DOUBLE_BOOL, etc.
Set<String> mapTypes = new Set<String>();

// All List<E> types: LIST_INT, LIST_STRING, etc.
Set<String> listTypes = new Set<String>();

// All floating point types: DOUBLE, SET_DOUBLE, MAP_X_DOUBLE, etc.
Set<String> fpTypes = new Set<String>();

// All iterable types: Set types + List types.
// These can be used in for(x in <iterable type>),
// therefore Map is not included.
Set<String> iterableTypes1 = new Set<String>();

// All trivially indexable types: Map types and List types.
// Elements of these can be written and read by [], unlike Set
// which uses getElementAt to access individual elements
Set<String> indexableTypes = new Set<String>();

// Complex types: Collection types instantiated with nested argument
// e.g Map<List<>, >.
Set<String> complexTypes = new Set<String>();

//
// Type relations.
//

// Map type to the resulting type when subscripted.
// Example: List<String> subscripts to String.
Map<String, String> subscriptsTo = new Map<String, String>();

// Map type to a Set of types that contain it as an element.
// Example: String is element of List<String> and Map<int, String>
Map<String, Set<String>> elementOf = new Map<String, Set<String>>();

// Map type to a Set of types that contain it as an indexable element.
// Same as element of, but without Set types.
Map<String, Set<String>> indexableElementOf = new Map<String, Set<String>>();

// Map type to type required as index.
// Example: List<String> is indexed by int,
// Map<String, double> indexed by String.
Map<String, String> indexedBy = new Map<String, String>();

//
// Interface relationships.
//

// Map Interface type to Set of types that implement it.
// Example: interface num is implemented by int and double.
Map<String, Set<String>> interfaceRels = new Map<String, Set<String>>();

// Convert analyzer's displayName to constant name used by dartfuzz.
// Example: Set<int, String> -> SET_INT_STRING
String getConstName(String displayName) {
  String constName = displayName;
  constName = constName.replaceAll('<', '_');
  constName = constName.replaceAll('>', '');
  constName = constName.replaceAll(', ', '_');
  constName = constName.toUpperCase();
  return constName;
}

// Returns true if the given type fails the filter criteria.
bool shouldFilterType(String typName, {bool fp = true, bool flatTp = false}) {
  if (!fp && fpTypes.contains(typName)) {
    return true;
  }
  if (flatTp && complexTypes.contains(typName)) {
    return true;
  }
  return false;
}

// Returns true if any of the paramters in the list fails the
// filter criteria.
bool shouldFilterParameterList(List<String> parameters,
    {bool fp = true, bool flatTp = false}) {
  for (String parameter in parameters) {
    if (shouldFilterType(parameter, fp: fp, flatTp: flatTp)) {
      return true;
    }
  }
  return false;
}

// Filter a set of a list of parameters according to their type.
// A paramter list is only retained if all of the contained paramters
// pass the filter criteria.
Set<List<String>> filterParameterList(Set<List<String>> parameterList,
    {bool fp = true, bool flatTp = false}) {
  Set<List<String>> filteredParams = <List<String>>{};
  for (List<String> parameters in parameterList) {
    if (!shouldFilterParameterList(parameters, fp: fp, flatTp: flatTp)) {
      filteredParams.add(parameters);
    }
  }
  return filteredParams;
}

// Filter a set of parameters according to their type.
Set<String> filterParameterSet(Set<String> parameterSet,
    {bool fp = true, bool flatTp = false}) {
  Set<String> filteredParams = <String>{};
  for (String parameter in parameterSet) {
    if (!shouldFilterType(parameter, fp: fp, flatTp: flatTp)) {
      filteredParams.add(parameter);
    }
  }
  return filteredParams;
}

// Filter map of operators to a set of a list of parameter types
// as used for binary operators.
Map<String, Set<List<String>>> filterOperatorMapSetList(
    Map<String, Set<List<String>>> operators,
    {bool fp = true,
    bool flatTp = false}) {
  Map<String, Set<List<String>>> filteredOps = <String, Set<List<String>>>{};
  operators.forEach((op, parameterList) {
    Set<List<String>> filteredParams =
        filterParameterList(parameterList, fp: fp, flatTp: flatTp);
    if (filteredParams.isNotEmpty) {
      filteredOps[op] = filteredParams;
    }
  });
  return filteredOps;
}

// Filter map of operators to a List of parameter types as used for
// constructors.
Map<String, List<String>> filterOperatorMapList(
    Map<String, List<String>> operators,
    {bool fp = true,
    bool flatTp = false}) {
  Map<String, List<String>> filteredOps = <String, List<String>>{};
  operators.forEach((op, parameterList) {
    if (!shouldFilterParameterList(parameterList, fp: fp, flatTp: flatTp)) {
      filteredOps[op] = parameterList;
    }
  });
  return filteredOps;
}

// Filter map of operators to a set of rhs types as used for assignment
// operators.
Map<String, Set<String>> filterOperatorMapSet(
    Map<String, Set<String>> operators,
    {bool fp = true,
    bool flatTp = false}) {
  Map<String, Set<String>> filteredOps = <String, Set<String>>{};
  operators.forEach((op, parameterSet) {
    Set<String> filteredParams =
        filterParameterSet(parameterSet, fp: fp, flatTp: flatTp);
    if (filteredParams.isNotEmpty) {
      filteredOps[op] = filteredParams;
    }
  });
  return filteredOps;
}

// Filter map of type to map of operators as used for binary operators.
Map<String, Map<String, Set<List<String>>>> filterTypesMap4(
    Map<String, Map<String, Set<List<String>>>> types,
    {bool fp = true,
    bool flatTp = false}) {
  Map<String, Map<String, Set<List<String>>>> filteredTypes =
      <String, Map<String, Set<List<String>>>>{};
  types.forEach((baseType, ops) {
    if (shouldFilterType(baseType, fp: fp, flatTp: flatTp)) {
      return true;
    }
    Map<String, Set<List<String>>> filteredOps =
        filterOperatorMapSetList(ops, fp: fp, flatTp: flatTp);
    if (filteredOps.isNotEmpty) {
      filteredTypes[baseType] = filteredOps;
    }
  });
  return filteredTypes;
}

// Print map of type to map of operators as used for binary operators.
void printTypeMap4(
    String name, Map<String, Map<String, Set<List<String>>>> types,
    {bool fp = true, bool flatTp = false}) {
  final bool subclass = !fp || flatTp;
  final String prefix = "${subclass ? "DartType." : ""}";
  print("  static const Map<DartType, Map<String, " +
      "Set<List<DartType>>>> ${name} = {");
  Map<String, Map<String, Set<List<String>>>> filteredTypes =
      filterTypesMap4(types, fp: fp, flatTp: flatTp);
  for (var baseType in filteredTypes.keys.toList()..sort()) {
    var ops = filteredTypes[baseType];
    print("    ${prefix}${baseType}: {");
    for (var op in ops.keys.toList()..sort()) {
      var paramTypeL = ops[op];
      print("      '${op}': {");
      for (var paramTypes in paramTypeL) {
        stdout.write("          [");
        for (String paramType in paramTypes) {
          stdout.write("${prefix}${paramType}, ");
        }
        print("],");
      }
      print("        },");
    }
    print("    },");
  }
  print("  };");
}

// Filter map of type to map of operators as used for assignment operators.
Map<String, Map<String, Set<String>>> filterTypesMap3Set(
    Map<String, Map<String, Set<String>>> types,
    {bool fp = true,
    bool flatTp = false}) {
  Map<String, Map<String, Set<String>>> filteredTypes =
      <String, Map<String, Set<String>>>{};
  types.forEach((baseType, ops) {
    if (shouldFilterType(baseType, fp: fp, flatTp: flatTp)) {
      return true;
    }
    Map<String, Set<String>> filteredOps =
        filterOperatorMapSet(ops, fp: fp, flatTp: flatTp);
    if (filteredOps.isNotEmpty) {
      filteredTypes[baseType] = filteredOps;
    }
  });
  return filteredTypes;
}

// Print map of type to map of operators as used for assignment operators.
void printTypeMap3Set(String name, Map<String, Map<String, Set<String>>> types,
    {bool fp = true, bool flatTp = false}) {
  final bool subclass = !fp || flatTp;
  final String prefix = "${subclass ? "DartType." : ""}";
  print("  static const Map<DartType, " +
      "Map<String, Set<DartType>>> ${name} = {");

  Map<String, Map<String, Set<String>>> filteredTypes =
      filterTypesMap3Set(types, fp: fp, flatTp: flatTp);
  for (var baseType in filteredTypes.keys.toList()..sort()) {
    var ops = filteredTypes[baseType];
    print("    ${prefix}${baseType}: {");
    for (var op in ops.keys.toList()) {
      var paramTypes = ops[op];
      stdout.write("      '${op}': {");
      for (String paramType in paramTypes.toList()..sort()) {
        stdout.write("${prefix}${paramType}, ");
      }
      print("}, ");
    }
    print("    },");
  }
  print("  };");
}

// Filter map of type to map of operators as used for constructors.
Map<String, Map<String, List<String>>> filterTypesMap3(
    Map<String, Map<String, List<String>>> types,
    {bool fp = true,
    bool flatTp = false}) {
  Map<String, Map<String, List<String>>> filteredTypes =
      <String, Map<String, List<String>>>{};
  types.forEach((baseType, ops) {
    if (shouldFilterType(baseType, fp: fp, flatTp: flatTp)) {
      return true;
    }
    Map<String, List<String>> filteredOps =
        filterOperatorMapList(ops, fp: fp, flatTp: flatTp);
    if (filteredOps.isNotEmpty) {
      filteredTypes[baseType] = filteredOps;
    }
  });
  return filteredTypes;
}

// Print map of type to map of operators as used for constructors.
void printTypeMap3(String name, Map<String, Map<String, List<String>>> types,
    {bool fp = true, bool flatTp = false}) {
  final bool subclass = !fp || flatTp;
  final String prefix = "${subclass ? "DartType." : ""}";
  print("  static const Map<DartType, Map<String, " +
      "List<DartType>>> ${name} = {");
  var filteredTypes = filterTypesMap3(types, fp: fp, flatTp: flatTp);
  for (var baseType in filteredTypes.keys.toList()..sort()) {
    var ops = filteredTypes[baseType];
    print("    ${prefix}${baseType}: {");
    for (var op in ops.keys.toList()..sort()) {
      var paramTypes = ops[op];
      stdout.write("      '${op}': [");
      for (String paramType in paramTypes.toList()) {
        stdout.write("${prefix}${paramType}, ");
      }
      print("], ");
    }
    print("    },");
  }
  print("  };");
}

// Filter map of type collection name to set of types.
Map<String, Set<String>> filterTypesMap2(Map<String, Set<String>> types,
    {bool fp = true, bool flatTp = false}) {
  Map<String, Set<String>> filteredTypes = <String, Set<String>>{};
  types.forEach((baseType, parameterSet) {
    if (shouldFilterType(baseType, fp: fp, flatTp: flatTp)) {
      return true;
    }
    Set<String> filteredParams =
        filterParameterSet(parameterSet, fp: fp, flatTp: flatTp);
    if (filteredParams.isNotEmpty) {
      filteredTypes[baseType] = filteredParams;
    }
  });
  return filteredTypes;
}

// Print map of type collection name to set of types.
void printTypeMap2(String name, Map<String, Set<String>> types,
    {bool fp = true, bool flatTp = false}) {
  final bool subclass = !fp || flatTp;
  final String prefix = "${subclass ? "DartType." : ""}";
  print("  static const Map<DartType, Set<DartType>> ${name} = {");
  var filteredTypes = filterTypesMap2(types, fp: fp, flatTp: flatTp);
  for (var baseType in filteredTypes.keys.toList()..sort()) {
    var paramTypes = filteredTypes[baseType];
    stdout.write("    ${prefix}${baseType}: { ");
    for (String paramType in paramTypes.toList()..sort()) {
      stdout.write("${prefix}${paramType}, ");
    }
    print("},");
  }
  print("  };");
}

// Filter map of type to type.
Map<String, String> filterTypesMap1(Map<String, String> types,
    {bool fp = true, bool flatTp = false}) {
  Map<String, String> filteredTypes = <String, String>{};
  types.forEach((baseType, paramType) {
    if (shouldFilterType(baseType, fp: fp, flatTp: flatTp)) {
      return true;
    }
    if (shouldFilterType(paramType, fp: fp, flatTp: flatTp)) {
      return true;
    }
    filteredTypes[baseType] = paramType;
  });
  return filteredTypes;
}

// Print map of type to type.
void printTypeMap1(String name, Map<String, String> types,
    {bool fp = true, bool flatTp = false}) {
  final bool subclass = !fp || flatTp;
  final String prefix = "${subclass ? "DartType." : ""}";
  print("  static const Map<DartType, DartType> ${name} = {");
  var filteredTypes = filterTypesMap1(types, fp: fp, flatTp: flatTp);
  for (var baseType in filteredTypes.keys.toList()..sort()) {
    var paramType = filteredTypes[baseType];
    print("    ${prefix}"
        "${baseType}: ${prefix}${paramType}, ");
  }
  print("  };");
}

// Filter set of types.
Set<String> filterTypesSet(Set<String> choices,
    {bool fp = true, bool flatTp = false}) {
  Set<String> filteredTypes = {};
  filteredTypes.addAll(choices);
  if (!fp) {
    filteredTypes = filteredTypes.difference(fpTypes);
  }
  if (flatTp) {
    filteredTypes = filteredTypes.difference(complexTypes);
  }
  return filteredTypes;
}

// Print set of types.
void printTypeSet(String name, Set<String> types,
    {bool fp = true, bool flatTp = false}) {
  final bool subclass = !fp || flatTp;
  final String prefix = "${subclass ? "DartType." : ""}";
  stdout.write("  static const Set<DartType> ${name} = {");
  for (String typName in filterTypesSet(types, fp: fp, flatTp: flatTp).toList()
    ..sort()) {
    stdout.write("${prefix}$typName, ");
  }
  print("};");
}

// Filter map to type to set of operators as used for unitary operators.
Map<String, Set<String>> filterTypeMapSet(Map<String, Set<String>> types,
    {bool fp = true, bool flatTp = false}) {
  Map<String, Set<String>> filteredTypes = <String, Set<String>>{};
  types.forEach((baseType, params) {
    if (shouldFilterType(baseType, fp: fp, flatTp: flatTp)) {
      return true;
    }
    filteredTypes[baseType] = params;
  });
  return filteredTypes;
}

// Print map to type to set of operators as used for unitary operators.
void printTypeMapSet(String name, Map<String, Set<String>> types,
    {bool fp = true, bool flatTp = false}) {
  final bool subclass = !fp || flatTp;
  final String prefix = "${subclass ? "DartType." : ""}";
  print("  static const Map<DartType, Set<String>> $name = {");
  var filteredTypes = filterTypeMapSet(types, fp: fp, flatTp: flatTp);
  for (var baseType in filteredTypes.keys.toList()..sort()) {
    var paramTypes = filteredTypes[baseType].toList()..sort();
    print("    ${prefix}${baseType}: {" + paramTypes.join(", ") + "},");
  }
  print("  };");
}

// Print all generated and collected types, operators and type collections.
void printTypeTable(Set<InterfaceType> allTypes,
    {bool fp = true, bool flatTp = false}) {
  final bool subclass = !fp || flatTp;
  if (!subclass) {
    print("""
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/// Class that represents some common Dart types.
///
/// NOTE: this code has been generated automatically.
///""");
  }

  String className = 'DartType${fp ? "" : "NoFp"}${flatTp ? "FlatTp" : ""}';

  print('class $className'
      '${subclass ? " extends DartType" : ""} {');
  print("  final String name;");
  if (!subclass) {
    print("  const DartType._withName(this.name);");
    print("""
  factory $className.fromDartConfig(
      {bool enableFp = false, bool disableNesting =
    false}) {
    if (enableFp && !disableNesting) {
      return DartType();
    } else if (!enableFp && !disableNesting) {
      return DartTypeNoFp();
    } else if (enableFp && disableNesting) {
      return DartTypeFlatTp();
    } else {
      return DartTypeNoFpFlatTp();
    }
  }""");
  } else {
    print('  const $className'
        '._withName(this.name) : super._withName(name);');
  }

  print("""
  const $className() : name = null;
  static bool isListType(DartType tp) {
    return DartType._listTypes.contains(tp);
  }

  static bool isMapType(DartType tp) {
    return DartType._mapTypes.contains(tp);
  }

  static bool isCollectionType(DartType tp) {
    return DartType._collectionTypes.contains(tp);
  }

  static bool isGrowableType(DartType tp) {
    return DartType._growableTypes.contains(tp);
  }

  static bool isComplexType(DartType tp) {
    return DartType._complexTypes.contains(tp);
  }

  bool isInterfaceOfType(DartType tp, DartType iTp) {
    return _interfaceRels.containsKey(iTp) && _interfaceRels[iTp].contains(tp);
  }

  Set<DartType> get mapTypes {
    return _mapTypes;
  }

  bool isSpecializable(DartType tp) {
    return _interfaceRels.containsKey(tp);
  }

  Set<DartType> interfaces(DartType tp) {
    if (_interfaceRels.containsKey(tp)) {
      return _interfaceRels[tp];
    }
    return null;
  }

  DartType indexType(DartType tp) {
    if (_indexedBy.containsKey(tp)) {
      return _indexedBy[tp];
    }
    return null;
  }

  Set<DartType> indexableElementTypes(DartType tp) {
    if (_indexableElementOf.containsKey(tp)) {
      return _indexableElementOf[tp];
    }
    return null;
  }

  bool isIndexableElementType(DartType tp) {
    return _indexableElementOf.containsKey(tp);
  }

  DartType elementType(DartType tp) {
    if (_subscriptsTo.containsKey(tp)) {
      return _subscriptsTo[tp];
    }
    return null;
  }

  Set<DartType> get iterableTypes1 {
    return _iterableTypes1;
  }

  Set<String> uniOps(DartType tp) {
    if (_uniOps.containsKey(tp)) {
      return _uniOps[tp];
    }
    return <String>{};
  }

  Set<String> binOps(DartType tp) {
    if (_binOps.containsKey(tp)) {
      return _binOps[tp].keys.toSet();
    }
    return <String>{};
  }

  Set<List<DartType>> binOpParameters(DartType tp, String op) {
    if (_binOps.containsKey(tp) &&
        _binOps[tp].containsKey(op)) {
      return _binOps[tp][op];
    }
    return null;
  }

  Set<String> assignOps(DartType tp) {
    if (_assignOps.containsKey(tp)) {
      return _assignOps[tp].keys.toSet();
    }
    return <String>{};
  }

  Set<DartType> assignOpRhs(DartType tp, String op) {
    if (_assignOps.containsKey(tp) &&
        _assignOps[tp].containsKey(op)) {
      return _assignOps[tp][op];
    }
    return <DartType>{};
  }

  bool hasConstructor(DartType tp) {
    return _constructors.containsKey(tp);
  }

  Set<String> constructors(DartType tp) {
    if (_constructors.containsKey(tp)) {
      return _constructors[tp].keys.toSet();
    }
    return <String>{};
  }

  List<DartType> constructorParameters(DartType tp, String constructor) {
    if (_constructors.containsKey(tp) &&
        _constructors[tp].containsKey(constructor)) {
      return _constructors[tp][constructor];
    }
    return null;
  }

  Set<DartType> get allTypes {
    return _allTypes;
  }

""");

  print("  static const VOID = const " + "DartType._withName(\"void\");");
  Set<String> instTypes = {};

  // Generate one static DartType instance for all instantiable types.
  // TODO (felih): maybe add void type?
  allTypes.forEach((baseType) {
    String constName = getConstName(baseType.displayName);
    instTypes.add(constName);
    if (!subclass) {
      print("  static const ${constName} = const " +
          "DartType._withName(\"${baseType.displayName}\");");
    }
  });

  if (!subclass) {
    // Generate one static DartType instance for all non instantiable types.
    // These are required to resolve interface relations, but should not be
    // used directly to generate dart programs.
    print("");
    print("  // NON INSTANTIABLE" "");
    interfaceRels.keys.forEach((constName) {
      if (instTypes.contains(constName)) return true;
      print("  static const ${constName} = const " +
          "DartType._withName(\"__${constName}\");");
    });
  }

  // Generate a list of all instantiable types.
  print("");
  print("""
  // All types extracted from analyzer.
  static const _allTypes = {""");
  filterTypesSet(instTypes, fp: fp, flatTp: flatTp).forEach((constName) {
    print("    ${subclass ? "DartType." : ""}${constName},");
  });
  print("  };");

  print("");
  print("""
  // All List<E> types: LIST_INT, LIST_STRING, etc.""");
  printTypeSet("_listTypes", listTypes, fp: fp, flatTp: flatTp);

  print("");
  print("""
  // All Set types: SET_INT, SET_STRING, etc.""");
  printTypeSet("_setTypes", setTypes, fp: fp, flatTp: flatTp);

  print("");
  print("""
  // All Map<K, V> types: MAP_INT_STRING, MAP_DOUBLE_BOOL, etc.""");
  printTypeSet("_mapTypes", mapTypes, fp: fp, flatTp: flatTp);

  print("");
  print("""
  // All collection types: list, map and set types.""");
  printTypeSet("_collectionTypes", {...listTypes, ...setTypes, ...mapTypes},
      fp: fp, flatTp: flatTp);

  print("");
  print("""
  // All growable types: list, map, set and string types.""");
  printTypeSet(
      "_growableTypes", {...listTypes, ...setTypes, ...mapTypes, 'STRING'},
      fp: fp, flatTp: flatTp);

  if (!subclass) {
    print("");
    print(
        "  // All floating point types: DOUBLE, SET_DOUBLE, MAP_X_DOUBLE, etc.");
    printTypeSet("_fpTypes", fpTypes);
  }

  print("");
  print("""
  // All trivially indexable types: Map types and List types.
  // Elements of these can be written and read by [], unlike Set
  // which uses getElementAt to access individual elements.""");
  printTypeSet("_indexableTypes", indexableTypes, fp: fp, flatTp: flatTp);

  print("");
  print("""
  // Map type to the resulting type when subscripted.
  // Example: List<String> subscripts to String.""");
  printTypeMap1("_subscriptsTo", subscriptsTo, fp: fp, flatTp: flatTp);

  print("");
  print("""
  // Map type to type required as index.
  // Example: List<String> is indexed by int,
  // Map<String, double> indexed by String.""");
  printTypeMap1("_indexedBy", indexedBy, fp: fp, flatTp: flatTp);

  print("");
  print("""
  // Map type to a Set of types that contain it as an element.
  // Example: String is element of List<String> and Map<int, String>""");
  printTypeMap2("_elementOf", elementOf, fp: fp, flatTp: flatTp);

  print("");
  print("""
  // Map type to a Set of types that contain it as an indexable element.
  // Same as element of, but without Set types.""");
  printTypeMap2("_indexableElementOf", indexableElementOf,
      fp: fp, flatTp: flatTp);

  print("");
  print("""
  // All iterable types: Set types + List types.
  // These can be used in for(x in <iterable type>),
  // therefore Map is not included.""");
  printTypeSet("_iterableTypes1", iterableTypes1, fp: fp, flatTp: flatTp);

  if (!subclass) {
    print("");
    print("""
  // Complex types: Collection types instantiated with nested argument
  // e.g Map<List<>, >.""");
    printTypeSet("_complexTypes", complexTypes);
  }

  print("");
  print("""
  // Map Interface type to Set of types that implement it.
  // Example: interface num is implemented by int and double.""");
  printTypeMap2("_interfaceRels", interfaceRels, fp: fp, flatTp: flatTp);

  print("");
  print("""
  // Map type to a list of constructors names with a list of constructor
  // parameter types.""");
  printTypeMap3("_constructors", constructors, fp: fp, flatTp: flatTp);

  print("");
  print("""
  // Map type to a list of binary operators with set of the respective
  // types for the first and second operand.""");
  printTypeMap4("_binOps", binOps, fp: fp, flatTp: flatTp);

  print("");
  print("""
  // Map type to a list of available unary operators.""");
  printTypeMapSet("_uniOps", uniOps, fp: fp, flatTp: flatTp);

  print("");
  print("""
  // Map type to a list of assignment operators with a set of the
  // assignable right hand side types.""");
  printTypeMap3Set("_assignOps", assignOps, fp: fp, flatTp: flatTp);

  print("}");
  print("");
}

// Returns true if type can be set and get via [].
bool isIndexable(InterfaceType tp) {
  bool isIndexable = false;
  for (var method in tp.methods) {
    if (method.name == "[]") {
      isIndexable = true;
      break;
    }
  }
  return isIndexable;
}

// Returns true if iTypeName == typeName or if
// iTypeName is an interface type that is implemented by typeName.
// List<int> is interface of Int8List
bool isInterfaceOf(String iTypName, String typName) {
  return iTypName == typName ||
      (interfaceRels.containsKey(iTypName) &&
          interfaceRels[iTypName].contains(typName));
}

// Filter operator parameters so that the more specific types are discarded if
// the respective interface type is already in the list.
// This is required not only to give each parameter type equal probability but
// also so that dartfuzz can efficiently filter floating point types from the
// interface relations.
Set<List<String>> filterOperator(Set<List<String>> op) {
  Set<List<String>> newOp = new Set<List<String>>();
  if (op.length < 2) return op;
  for (List<String> params1 in op) {
    bool keep = false;
    for (List<String> params2 in op) {
      for (int k = 0; k < params1.length; ++k) {
        if (!isInterfaceOf(params2[k], params1[k])) {
          keep = true;
          break;
        }
      }
      if (keep) break;
    }
    if (keep) {
      newOp.add(params1);
    }
  }
  return newOp;
}

// See comment on filterOpterator.
void filterOperators(Set<InterfaceType> allTypes) {
  for (InterfaceType tp in allTypes) {
    String typName = getConstName(tp.displayName);
    if (!binOps.containsKey(typName)) continue;
    for (String op in binOps[typName].keys) {
      binOps[typName][op] = filterOperator(binOps[typName][op]);
    }
  }
}

// Filters methods based on a manually maintained exclude list.
//
// Excluded methods should be associated with an issue number so they can be
// re-enabled after the issue is resolved.
bool isExcludedMethod(InterfaceType tp, MethodElement method) {
  // TODO(bkonyi): Enable operator / for these types after we resolve
  // https://github.com/dart-lang/sdk/issues/39890
  if (((tp.displayName == 'Float32x4') && (method.name == '/')) ||
      ((tp.displayName == 'Float64x2') && (method.name == '/'))) {
    return true;
  }
  return false;
}

// Extract all binary and unary operators for tp.
// Operators are stored by return type in the following way:
// return type: { operator: { parameter types } }
// Example: bool: { == : { [int, int], [double, double] }}
//          int: {'~', '-'},
// Does not recurse into interfaces and superclasses of tp.
void getOperatorsForTyp(String typName, InterfaceType tp, fromLiteral) {
  for (MethodElement method in tp.methods) {
    // If the method is manually excluded, skip it.
    if (isExcludedMethod(tp, method)) continue;

    // Detect whether tp can be parsed from a literal (dartfuzz.dart can
    // already handle that).
    // This is usually indicated by the presence of the static constructor
    // 'castFrom' or 'parse'.
    if (method.isStatic &&
        (method.name == 'castFrom' || method.name == 'parse')) {
      fromLiteral.add(getConstName(tp.displayName));
    }
    // Hack: dartfuzz.dart already handles subscripts, therefore we exclude
    // them from the generated type table.
    if (method.name.startsWith('[]')) continue;
    if (method.isOperator) {
      // TODO (felih): Include support for type 'dynamic'.
      bool skip = false;
      for (var p in method.parameters) {
        if (getConstName(p.type.displayName) == 'DYNAMIC') {
          skip = true;
          break;
        }
      }
      if (skip) continue;
      if (method.parameters.length == 1) {
        // Get binary operators.

        String retTypName = getConstName(method.returnType.displayName);
        binOps[retTypName] ??= new Map<String, Set<List<String>>>();
        binOps[retTypName][method.name] ??= new Set<List<String>>();

        String rhsTypName = getConstName(method.parameters[0].type.displayName);

        // TODO (felih): no hashing for List<String> ?
        // if i remove this test i will get duplicates even though it is a Set.
        bool present = false;
        for (List<String> o in binOps[retTypName][method.name]) {
          if (o[0] == typName && o[1] == rhsTypName) {
            present = true;
            break;
          }
        }
        if (!present)
          binOps[retTypName][method.name].add([typName, rhsTypName]);

        // Add some assignment operators corresponding to the binary operators.
        // Example: for '+' add '+='.
        // Bool types have to be filtered because boolean binary operators
        // can not be used to derive assignment operators in this way, e.g.
        // <= is not a valid assignment operator for bool types.
        if (retTypName != 'BOOL') {
          assignOps[retTypName] ??= new Map<String, Set<String>>();
          String ao = method.name + '=';
          assignOps[retTypName][ao] ??= new Set<String>();
          assignOps[retTypName][ao].add(rhsTypName);
        }
      } else {
        // Get unary operators.
        uniOps[typName] ??= new Set<String>();
        String uo = method.name;
        // Hack: remove unary from operator so that the operator name can be
        // used directly for source code generation.
        if (uo.startsWith('unary')) uo = '-';
        uniOps[typName].add('\'$uo\'');
      }
    }
  }
}

// Extract all binary and unary operators for all types.
void getOperators(Set<InterfaceType> allTypes) {
  // Set of types that can be constructed directly from literals and do
  // not need special constructors (e.g. List<int> = [1, 2] as opposed to
  // Int8List int8list = Int8List.fromList([1, 2]) ).
  Set<String> fromLiteral = new Set<String>();

  // getOperatorsForTyp uses a heuristic to detect which types can be
  // constructed from a literal, but the heuristic misses the String type
  // so we have to add it manually.
  fromLiteral.add('STRING');
  // Get binary, unary and assignment operators.
  for (InterfaceType tp in allTypes) {
    String typName = getConstName(tp.displayName);
    // Manually add basic assignment operators which each type supports.
    assignOps[typName] ??= new Map<String, Set<String>>();
    assignOps[typName]['='] = {typName};
    assignOps[typName]['??='] = {typName};
    getOperatorsForTyp(typName, tp, fromLiteral);
  }

  // Add some static ops not extractable from dart:core/typed_data.
  for (String typName in binOps.keys) {
    binOps[typName] ??= new Map<String, Set<List<String>>>();
    binOps[typName]['??'] = {
      [typName, typName],
    };
  }
  binOps['BOOL'] ??= new Map<String, Set<List<String>>>();
  binOps['BOOL']['&&'] = {
    ['BOOL', 'BOOL'],
  };
  binOps['BOOL']['||'] = {
    ['BOOL', 'BOOL'],
  };
  uniOps['BOOL'] ??= new Set<String>();
  uniOps['BOOL'].add('\'!\'');

  // Get constructors.
  for (InterfaceType tp in allTypes) {
    String typName = getConstName(tp.displayName);
    // Skip types that are constructable from a literal.
    if (fromLiteral.contains(typName)) {
      continue;
    }
    for (ConstructorElement constructor in tp.constructors) {
      if (shouldFilterConstructor(tp, constructor)) continue;
      List<String> params = new List<String>();
      bool canConstruct = true;
      for (var p in constructor.parameters) {
        String tstr = getConstName(p.type.displayName);
        if (tstr == "DYNAMIC" || tstr == "OBJECT") {
          tstr = "INT";
        } else if (!allTypes.contains(p.type)) {
          // Exclude constructors that have an unsupported parameter type.
          canConstruct = false;
          break;
        }
        // Only add positional required parameters.
        // TODO (felih): include named and optional parameters.
        if (!p.isNamed) params.add(tstr);
      }
      if (!canConstruct) continue;

      constructors[typName] ??= new Map<String, List<String>>();
      constructors[typName][constructor.name] = params;
    }
  }
  // Removed redundant specialized parameter types.
  // E.g. if num is already contained remove bool and int.
  filterOperators(allTypes);
}

bool shouldFilterConstructor(InterfaceType tp, ConstructorElement cons) {
  // Filter private constructors.
  if (cons.name.startsWith('_')) {
    return true;
  }
  // Constructor exclude list
  // TODO(bkonyi): Enable Float32x4.fromInt32x4Bits after we resolve
  // https://github.com/dart-lang/sdk/issues/39890
  if ((tp.displayName == 'Float32x4') && (cons.name == 'fromInt32x4Bits')) {
    return true;
  }
  return false;
}

// Analyze types to extract element and subscript relations
// as well as precision type attributes.
void analyzeTypes(Set<InterfaceType> allTypes) {
  // Extract basic floating point types.
  for (InterfaceType tp in allTypes) {
    if (tp.displayName.contains('Float') ||
        tp.displayName.contains('float') ||
        tp.displayName.contains('double') ||
        tp.displayName.contains('Double'))
      fpTypes.add(getConstName(tp.displayName));
  }

  // Analyze all types to extract information useful for dart code generation.
  for (InterfaceType tp in allTypes) {
    final typName = getConstName(tp.displayName);

    // Find topmost interface type, e.g. List<int> is interface for Int8List.
    InterfaceType iTyp = tp;
    while (iTyp.typeArguments.isEmpty && !iTyp.interfaces.isEmpty) {
      iTyp = tp.interfaces[0];
    }

    // Group current type with their respective type group.
    if (iTyp.name == "Set") setTypes.add(typName);
    if (iTyp.name == "List") listTypes.add(typName);
    if (iTyp.name == "Map") mapTypes.add(typName);

    if (iTyp.typeArguments.length == 1) {
      // Analyze Array, List and Set types.
      String argName = getConstName(iTyp.typeArguments[0].displayName);
      subscriptsTo[typName] = argName;
      elementOf[argName] ??= new Set<String>();
      elementOf[argName].add(typName);
      if (isIndexable(iTyp)) {
        indexableElementOf[argName] ??= new Set<String>();
        indexableElementOf[argName].add(typName);
        indexedBy[typName] = 'INT';
        indexableTypes.add(typName);
      }
      // Check if type is floating point precision.
      if (fpTypes.contains(typName) || fpTypes.contains(argName)) {
        fpTypes.add(typName);
      }
    } else if (iTyp.typeArguments.length == 2) {
      if (isIndexable(iTyp)) {
        // Analyze Map and MapEntry types.
        String argName0 = getConstName(iTyp.typeArguments[0].displayName);
        String argName1 = getConstName(iTyp.typeArguments[1].displayName);
        subscriptsTo[typName] = argName1;
        elementOf[argName1] ??= new Set<String>();
        elementOf[argName1].add(typName);
        indexableElementOf[argName1] ??= new Set<String>();
        indexableElementOf[argName1].add(typName);
        indexedBy[typName] = argName0;
        indexableTypes.add(typName);
        // Check if type is floating point precision.
        if (fpTypes.contains(typName) ||
            fpTypes.contains(argName0) ||
            fpTypes.contains(argName1)) {
          fpTypes.add(typName);
        }
      }
    }
  }
}

// Split types into sets of types with none, one and two parameters
// respectively.
void getParameterizedTypes(
    Set<InterfaceType> allTypes, // Set of all types.
    Set<InterfaceType> pTypes1, // Out: types with one parameter e.g. List.
    Set<InterfaceType> pTypes2, // Out: types with two parameters e.g. Map.
    Set<InterfaceType> iTypes) {
  // Out: types with no parameters.
  for (var tp in allTypes) {
    if (tp.typeArguments.length == 1 &&
        (tp.typeArguments[0].name == 'E' || tp.typeArguments[0].name == 'T'))
      pTypes1.add(tp);
    else if (tp.typeArguments.length == 2 &&
        tp.typeArguments[0].name == 'K' &&
        tp.typeArguments[1].name == 'V')
      pTypes2.add(tp);
    else
      iTypes.add(tp);
  }
}

// Generate new types by instantiating types with one and two parameters
// with the types having no parameters (or the parameters of which have
// already been instantiated).
// There will be no more then maxNew types generated.
Set<InterfaceType> instantiatePTypes(
    Set<InterfaceType> pTypes1, // Types with one parameter.
    Set<InterfaceType> pTypes2, // Types with two parameters.
    Set<InterfaceType> iTypes, // Types with no parameters.
    {double maxNew = 10000.0}) {
  // Maximum number of newly generated types.
  Set<InterfaceType> newITypes = new Set<InterfaceType>();

  // Calculate the total number of new types if all combinations were used.
  int nNew = pTypes1.length * iTypes.length +
      pTypes2.length * iTypes.length * iTypes.length;
  // Calculate how many generated types have to be skipped in order to stay
  // under the maximum number set for generating new types (maxNew).
  double step = maxNew / nNew;
  double cntr = 0.0;

  // Instantiate List and Set types.
  pTypes1.forEach((pType) {
    iTypes.forEach((iType) {
      cntr += step;
      if (cntr >= 1.0) {
        cntr -= 1.0;
      } else {
        return true;
      }
      ParameterizedType ptx = pType.element.instantiate(
        typeArguments: [iType],
        nullabilitySuffix: NullabilitySuffix.star,
      );
      newITypes.add(ptx);
      if (iType.typeArguments.length >= 1) {
        complexTypes.add(getConstName(ptx.displayName));
      }
    });
  });

  // Instantiate Map types.
  pTypes2.forEach((pType) {
    iTypes.forEach((iType1) {
      iTypes.forEach((iType2) {
        cntr += step;
        if (cntr >= 1.0) {
          cntr -= 1.0;
        } else {
          return true;
        }
        ParameterizedType ptx = pType.element.instantiate(
          typeArguments: [iType1, iType2],
          nullabilitySuffix: NullabilitySuffix.star,
        );
        newITypes.add(ptx);
        if (iType1.typeArguments.length >= 1 ||
            iType2.typeArguments.length >= 1) {
          complexTypes.add(getConstName(ptx.displayName));
        }
      });
    });
  });

  // Add instantiated types to the set of types with no free parameters.
  return iTypes.union(newITypes);
}

Set<InterfaceType> instantiateAllTypes(
    Set<InterfaceType> allTypes, Set<String> iTypeFilter, int depth,
    {double maxNew = 10000.0}) {
  // Types with one parameter (List, Set).
  Set<InterfaceType> pTypes1 = new Set<InterfaceType>();
  // Types with two parameters (Map).
  Set<InterfaceType> pTypes2 = new Set<InterfaceType>();
  // Types with no parameters or parameters of which have already been
  // instantiated.
  Set<InterfaceType> iTypes = new Set<InterfaceType>();
  // Fill type sets with respective parameter types.
  getParameterizedTypes(allTypes, pTypes1, pTypes2, iTypes);

  // Filter the list of zero parameter types to exclude
  // complex types like Int8List.
  Set<InterfaceType> filteredITypes = {};
  for (var iType in iTypes) {
    if (iTypeFilter.contains(iType.displayName)) {
      filteredITypes.add(iType);
    }
  }

  // Instantiate types with one or two free parameters.
  // Concatenate the newly instantiated types with the previous set of
  // instantiated or zero parameter types to be used as input for the next
  // round or instantiation.
  // Each iteration constructs more nested types like
  // Map<Map<int, int>, List<int>>.
  for (int i = 0; i < depth + 1; ++i) {
    double mn = max(1, maxNew / (depth + 1));
    filteredITypes = filteredITypes
        .union(instantiatePTypes(pTypes1, pTypes2, filteredITypes, maxNew: mn));
  }

  return iTypes.union(filteredITypes);
}

// Heuristic of which types to include:
// count the number of operators and
// check if the type can be constructed from a literal.
int countOperators(ClassElement ce) {
  int no = 0;
  ce.methods.forEach((method) {
    if (method.isOperator) {
      no++;
    }
    // Detect whether type can be parsed from a literal (dartfuzz.dart can
    // already handle that).
    // This is usually indicated by the presence of the static constructor
    // 'castFrom' or 'parse'.
    if (method.isStatic &&
        (method.name == 'castFrom' || method.name == 'parse')) {
      no += 100;
    }
    for (InterfaceType ci in ce.interfaces) {
      no += countOperators(ci.element);
    }
  });
  return no;
}

// Analyze typed_data and core libraries to extract data types.
void getDataTypes(Set<InterfaceType> allTypes, String dartTop) async {
  final AnalysisSession session = GenUtil.createAnalysisSession(dartTop);

  // Visit libraries for type table generation.
  await visitLibraryAtUri(session, 'dart:typed_data', allTypes);
  await visitLibraryAtUri(session, 'dart:core', allTypes);
}

visitLibraryAtUri(
    AnalysisSession session, String uri, Set<InterfaceType> allTypes) async {
  String libPath = session.uriConverter.uriToPath(Uri.parse(uri));
  ResolvedLibraryResult result = await session.getResolvedLibrary(libPath);
  if (result.state != ResultState.VALID) {
    throw new StateError('Unable to resolve "$uri"');
  }
  visitLibrary(result.element, allTypes);
}

visitLibrary(LibraryElement library, Set<InterfaceType> allTypes) async {
  // This uses the element model to traverse the code. The element model
  // represents the semantic structure of the code. A library consists of
  // one or more compilation units.
  for (CompilationUnitElement unit in library.units) {
    visitCompilationUnit(unit, allTypes);
  }
}

visitCompilationUnit(CompilationUnitElement unit, Set<InterfaceType> allTypes) {
  // Each compilation unit contains elements for all of the top-level
  // declarations in a single file, such as variables, functions, and
  // classes. Note that `types` only returns classes. You can use
  // `mixins` to visit mixins, `enums` to visit enum, `functionTypeAliases`
  // to visit typedefs, etc.
  for (ClassElement classElement in unit.types) {
    if (classElement.isPublic) {
      // Hack: Filter out some difficult types, abstract types and types that
      // have methods with abstract type parameters.
      // TODO (felih): include filtered types.
      if (classElement.name.startsWith('Unmodifiable') ||
          classElement.name.startsWith('Iterable') ||
          classElement.name.startsWith('BigInt') ||
          classElement.name.startsWith('DateTime') ||
          classElement.name.startsWith('Uri') ||
          (classElement.name == 'Function') ||
          (classElement.name == 'Object') ||
          (classElement.name == 'Match') ||
          (classElement.name == 'RegExpMatch') ||
          (classElement.name == 'pragma') ||
          (classElement.name == 'LateInitializationError') ||
          (classElement.name == 'ByteBuffer') ||
          (classElement.name == 'TypedData') ||
          (classElement.name == 'Sink') ||
          (classElement.name == 'Pattern') ||
          (classElement.name == 'StackTrace') ||
          (classElement.name == 'StringSink') ||
          (classElement.name == 'Type') ||
          (classElement.name == 'Pattern') ||
          (classElement.name == 'Invocation') ||
          (classElement.name == 'StackTrace') ||
          (classElement.name == 'NoSuchMethodError') ||
          (classElement.name == 'Comparable') ||
          (classElement.name == 'BidirectionalIterator') ||
          (classElement.name == 'Iterator') ||
          (classElement.name == 'Stopwatch') ||
          (classElement.name == 'OutOfMemoryError')) {
        continue;
      }
      allTypes.add(classElement.thisType);
    }
  }
}

// Get all interface implemented by type.
Set<String> getInterfaces(InterfaceType tp) {
  Set<String> iTypes = new Set<String>();
  for (InterfaceType iTyp in tp.interfaces) {
    String ifTypName = getConstName(iTyp.displayName);
    iTypes.add(ifTypName);
    iTypes = iTypes.union(getInterfaces(iTyp));
  }
  return iTypes;
}

// Get interface and inheritance relationships for all types.
void getInterfaceRels(Set<InterfaceType> allTypes) {
  for (InterfaceType tp in allTypes) {
    String typName = getConstName(tp.displayName);
    for (String ifTypName in getInterfaces(tp)) {
      interfaceRels[ifTypName] ??= new Set<String>();
      interfaceRels[ifTypName].add(typName);
      if (ifTypName.contains('ITERABLE')) {
        iterableTypes1.add(typName);
      }
    }
    for (InterfaceType it in tp.element.allSupertypes) {
      String ifTypName = getConstName(it.displayName);
      interfaceRels[ifTypName] ??= new Set<String>();
      interfaceRels[ifTypName].add(typName);
    }
  }
  // If interface can be instantiated,
  // add it to the relation list so that we can
  // do tp1 = oneof(interfaceRels[tp2]) in dartfuzz with a chance of
  // tp1 == tp1.
  for (InterfaceType tp in allTypes) {
    String typName = getConstName(tp.displayName);
    if (interfaceRels.containsKey(typName)) {
      interfaceRels[typName].add(typName);
    }
  }
}

main(List<String> arguments) async {
  final parser = new ArgParser()
    ..addOption('dart-top', help: 'explicit value for \$DART_TOP')
    ..addOption('depth',
        help: 'Nesting depth, e.g. List<String> is depth 0, ' +
            'List<List<String>>' +
            'is depth 1. Remark: dart type tables grow ' +
            'exponentially with this, ' +
            'therefore types with higher nesting ' +
            'depth are partially filtered.',
        defaultsTo: '1');
  try {
    final results = parser.parse(arguments);
    int depth = int.parse(results['depth']);
    Set<InterfaceType> allTypes = new Set<InterfaceType>();
    // Filter types to instantiate parameterized types with, this excludes
    // complex types like Int8List (might be added later).
    Set<String> iTypeFilter = {'int', 'bool', 'double', 'String'};
    // Extract basic types from dart::core and dart::typed_data.
    await getDataTypes(allTypes, results['dart-top']);
    // Instantiate parameterized types like List<E>.
    allTypes =
        instantiateAllTypes(allTypes, iTypeFilter, depth, maxNew: 10000.0);
    // Extract interface Relations between types.
    getInterfaceRels(allTypes);
    // Extract operators from instantiated types.
    getOperators(allTypes);
    // Analyze instantiated types to get elementof/subscript and floating point
    // information.
    analyzeTypes(allTypes);
    // Print everything.
    printTypeTable(allTypes);
    printTypeTable(allTypes, fp: false);
    printTypeTable(allTypes, flatTp: true);
    printTypeTable(allTypes, fp: false, flatTp: true);
  } catch (e) {
    print('Usage: dart gen_type_table.dart [OPTIONS]\n${parser.usage}\n$e');
    exitCode = 255;
  }
}
