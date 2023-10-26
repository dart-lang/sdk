// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generates the type tables used by DartFuzz.
//
// Usage:
//   dart gen_type_table.dart > dartfuzz_type_table.dart
//
// Reformat:
//   tools/sdks/dart-sdk/bin/dart format \
//   runtime/tools/dartfuzz/dartfuzz_type_table.dart
//
// Then send out modified dartfuzz_type_table.dart for review together
// with a modified dartfuzz.dart that increases the version.

import 'dart:io';
import 'dart:math';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:args/args.dart';

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
    <String, Map<String, List<String>>>{};

// Map type to a list of assignment operators with a set of the
// assignable right hand side types.
Map<String, Map<String, Set<String>>> assignOps =
    <String, Map<String, Set<String>>>{};

// Map type to a list of binary operators with set of the respective
// types for the first and second operand.
Map<String, Map<String, Set<List<String>>>> binOps =
    <String, Map<String, Set<List<String>>>>{};

// Map type to a list of available unary operators.
Map<String, Set<String>> uniOps = <String, Set<String>>{};

//
// Type grouping.
//

// All Set<E> types: SET_INT, SET_STRING, etc.
Set<String> setTypes = <String>{};

// All Map<K, V> types: MAP_INT_STRING, MAP_DOUBLE_BOOL, etc.
Set<String> mapTypes = <String>{};

// All List<E> types: LIST_INT, LIST_STRING, etc.
Set<String> listTypes = <String>{};

// All floating point types: DOUBLE, SET_DOUBLE, MAP_X_DOUBLE, etc.
Set<String> fpTypes = <String>{};

// All iterable types: Set types + List types.
// These can be used in for(x in <iterable type>),
// therefore Map is not included.
Set<String> iterableTypes1 = <String>{};

// All trivially indexable types: Map types and List types.
// Elements of these can be written and read by [], unlike Set
// which uses getElementAt to access individual elements
Set<String> indexableTypes = <String>{};

// Complex types: Collection types instantiated with nested argument
// e.g Map<List<>, >.
Set<String> complexTypes = <String>{};

//
// Type relations.
//

// Map type to the resulting type when subscripted.
// Example: List<String> subscripts to String.
Map<String, String> subscriptsTo = <String, String>{};

// Map type to a Set of types that contain it as an element.
// Example: String is element of List<String> and Map<int, String>
Map<String, Set<String>> elementOf = <String, Set<String>>{};

// Map type to a Set of types that contain it as an indexable element.
// Same as element of, but without Set types.
Map<String, Set<String>> indexableElementOf = <String, Set<String>>{};

// Map type to type required as index.
// Example: List<String> is indexed by int,
// Map<String, double> indexed by String.
Map<String, String> indexedBy = <String, String>{};

//
// Interface relationships.
//

// Map Interface type to Set of types that implement it.
// Example: interface num is implemented by int and double.
Map<String, Set<String>> interfaceRels = <String, Set<String>>{};

// Convert analyzer's displayName to constant name used by dartfuzz.
// Example: Set<int, String> -> SET_INT_STRING
String getConstName(String displayName) {
  var constName = displayName;
  constName = constName.replaceAll('<', '_');
  constName = constName.replaceAll('>', '');
  constName = constName.replaceAll(', ', '_');
  constName = constName.toUpperCase();
  return constName;
}

String typeConstName(DartType tp) => getConstName(tp.asCode);

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

// Returns true if any of the parameters in the list fails the
// filter criteria.
bool shouldFilterParameterList(List<String> parameters,
    {bool fp = true, bool flatTp = false}) {
  for (var parameter in parameters) {
    if (shouldFilterType(parameter, fp: fp, flatTp: flatTp)) {
      return true;
    }
  }
  return false;
}

// Filter a set of a list of parameters according to their type.
// A parameter list is only retained if all of the contained parameters
// pass the filter criteria.
Set<List<String>> filterParameterList(Set<List<String>> parameterList,
    {bool fp = true, bool flatTp = false}) {
  var filteredParams = <List<String>>{};
  for (var parameters in parameterList) {
    if (!shouldFilterParameterList(parameters, fp: fp, flatTp: flatTp)) {
      filteredParams.add(parameters);
    }
  }
  return filteredParams;
}

// Filter a set of parameters according to their type.
Set<String> filterParameterSet(Set<String> parameterSet,
    {bool fp = true, bool flatTp = false}) {
  var filteredParams = <String>{};
  for (var parameter in parameterSet) {
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
  var filteredOps = <String, Set<List<String>>>{};
  operators.forEach((op, parameterList) {
    var filteredParams =
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
  var filteredOps = <String, List<String>>{};
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
  var filteredOps = <String, Set<String>>{};
  operators.forEach((op, parameterSet) {
    var filteredParams =
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
  var filteredTypes = <String, Map<String, Set<List<String>>>>{};
  types.forEach((baseType, ops) {
    if (shouldFilterType(baseType, fp: fp, flatTp: flatTp)) {
      return;
    }
    var filteredOps = filterOperatorMapSetList(ops, fp: fp, flatTp: flatTp);
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
  final subclass = !fp || flatTp;
  final prefix = "${subclass ? "DartType." : ""}";
  print('  static const Map<DartType, Map<String, '
      'Set<List<DartType>>>> $name = {');
  var filteredTypes = filterTypesMap4(types, fp: fp, flatTp: flatTp);
  for (var baseType in filteredTypes.keys.toList()..sort()) {
    var ops = filteredTypes[baseType]!;
    print('    $prefix$baseType: {');
    for (var op in ops.keys.toList()..sort()) {
      var paramTypeL = ops[op]!;
      print("      '$op': {");
      for (var paramTypes in paramTypeL) {
        stdout.write('          [');
        for (var paramType in paramTypes) {
          stdout.write('$prefix$paramType, ');
        }
        print('],');
      }
      print('        },');
    }
    print('    },');
  }
  print('  };');
}

// Filter map of type to map of operators as used for assignment operators.
Map<String, Map<String, Set<String>>> filterTypesMap3Set(
    Map<String, Map<String, Set<String>>> types,
    {bool fp = true,
    bool flatTp = false}) {
  var filteredTypes = <String, Map<String, Set<String>>>{};
  types.forEach((baseType, ops) {
    if (shouldFilterType(baseType, fp: fp, flatTp: flatTp)) {
      return;
    }
    var filteredOps = filterOperatorMapSet(ops, fp: fp, flatTp: flatTp);
    if (filteredOps.isNotEmpty) {
      filteredTypes[baseType] = filteredOps;
    }
  });
  return filteredTypes;
}

// Print map of type to map of operators as used for assignment operators.
void printTypeMap3Set(String name, Map<String, Map<String, Set<String>>> types,
    {bool fp = true, bool flatTp = false}) {
  final subclass = !fp || flatTp;
  final prefix = "${subclass ? "DartType." : ""}";
  print(
      '  static const Map<DartType, ' 'Map<String, Set<DartType>>> $name = {');

  var filteredTypes = filterTypesMap3Set(types, fp: fp, flatTp: flatTp);
  for (var baseType in filteredTypes.keys.toList()..sort()) {
    var ops = filteredTypes[baseType]!;
    print('    $prefix$baseType: {');
    for (var op in ops.keys.toList()) {
      var paramTypes = ops[op]!;
      stdout.write("      '$op': {");
      for (var paramType in paramTypes.toList()..sort()) {
        stdout.write('$prefix$paramType, ');
      }
      print('}, ');
    }
    print('    },');
  }
  print('  };');
}

// Filter map of type to map of operators as used for constructors.
Map<String, Map<String, List<String>>> filterTypesMap3(
    Map<String, Map<String, List<String>>> types,
    {bool fp = true,
    bool flatTp = false}) {
  var filteredTypes = <String, Map<String, List<String>>>{};
  types.forEach((baseType, ops) {
    if (shouldFilterType(baseType, fp: fp, flatTp: flatTp)) {
      return;
    }
    var filteredOps = filterOperatorMapList(ops, fp: fp, flatTp: flatTp);
    if (filteredOps.isNotEmpty) {
      filteredTypes[baseType] = filteredOps;
    }
  });
  return filteredTypes;
}

// Print map of type to map of operators as used for constructors.
void printTypeMap3(String name, Map<String, Map<String, List<String>>> types,
    {bool fp = true, bool flatTp = false}) {
  final subclass = !fp || flatTp;
  final prefix = "${subclass ? "DartType." : ""}";
  print(
      '  static const Map<DartType, Map<String, ' 'List<DartType>>> $name = {');
  var filteredTypes = filterTypesMap3(types, fp: fp, flatTp: flatTp);
  for (var baseType in filteredTypes.keys.toList()..sort()) {
    var ops = filteredTypes[baseType]!;
    print('    $prefix$baseType: {');
    for (var op in ops.keys.toList()..sort()) {
      var paramTypes = ops[op]!;
      stdout.write("      '$op': [");
      for (var paramType in paramTypes.toList()) {
        stdout.write('$prefix$paramType, ');
      }
      print('], ');
    }
    print('    },');
  }
  print('  };');
}

// Filter map of type collection name to set of types.
Map<String, Set<String>> filterTypesMap2(Map<String, Set<String>> types,
    {bool fp = true, bool flatTp = false}) {
  var filteredTypes = <String, Set<String>>{};
  types.forEach((baseType, parameterSet) {
    if (shouldFilterType(baseType, fp: fp, flatTp: flatTp)) {
      return;
    }
    var filteredParams =
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
  final subclass = !fp || flatTp;
  final prefix = "${subclass ? "DartType." : ""}";
  print('  static const Map<DartType, Set<DartType>> $name = {');
  var filteredTypes = filterTypesMap2(types, fp: fp, flatTp: flatTp);
  for (var baseType in filteredTypes.keys.toList()..sort()) {
    var paramTypes = filteredTypes[baseType]!;
    stdout.write('    $prefix$baseType: { ');
    for (var paramType in paramTypes.toList()..sort()) {
      stdout.write('$prefix$paramType, ');
    }
    print('},');
  }
  print('  };');
}

// Filter map of type to type.
Map<String, String> filterTypesMap1(Map<String, String> types,
    {bool fp = true, bool flatTp = false}) {
  var filteredTypes = <String, String>{};
  types.forEach((baseType, paramType) {
    if (shouldFilterType(baseType, fp: fp, flatTp: flatTp)) {
      return;
    }
    if (shouldFilterType(paramType, fp: fp, flatTp: flatTp)) {
      return;
    }
    filteredTypes[baseType] = paramType;
  });
  return filteredTypes;
}

// Print map of type to type.
void printTypeMap1(String name, Map<String, String> types,
    {bool fp = true, bool flatTp = false}) {
  final subclass = !fp || flatTp;
  final prefix = "${subclass ? "DartType." : ""}";
  print('  static const Map<DartType, DartType> $name = {');
  var filteredTypes = filterTypesMap1(types, fp: fp, flatTp: flatTp);
  for (var baseType in filteredTypes.keys.toList()..sort()) {
    var paramType = filteredTypes[baseType]!;
    print('    $prefix$baseType: $prefix$paramType, ');
  }
  print('  };');
}

// Filter set of types.
Set<String> filterTypesSet(Set<String> choices,
    {bool fp = true, bool flatTp = false}) {
  var filteredTypes = <String>{};
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
  final subclass = !fp || flatTp;
  final prefix = "${subclass ? "DartType." : ""}";
  stdout.write('  static const Set<DartType> $name = {');
  for (var typName in filterTypesSet(types, fp: fp, flatTp: flatTp).toList()
    ..sort()) {
    stdout.write('$prefix$typName, ');
    stdout.write('$prefix${typName}_NULLABLE, ');
  }
  print('};');
}

// Filter map to type to set of operators as used for unitary operators.
Map<String, Set<String>> filterTypeMapSet(Map<String, Set<String>> types,
    {bool fp = true, bool flatTp = false}) {
  var filteredTypes = <String, Set<String>>{};
  types.forEach((baseType, params) {
    if (shouldFilterType(baseType, fp: fp, flatTp: flatTp)) {
      return;
    }
    filteredTypes[baseType] = params;
  });
  return filteredTypes;
}

// Print map to type to set of operators as used for unitary operators.
void printTypeMapSet(String name, Map<String, Set<String>> types,
    {bool fp = true, bool flatTp = false}) {
  final subclass = !fp || flatTp;
  final prefix = "${subclass ? "DartType." : ""}";
  print('  static const Map<DartType, Set<String>> $name = {');
  var filteredTypes = filterTypeMapSet(types, fp: fp, flatTp: flatTp);
  for (var baseType in filteredTypes.keys.toList()..sort()) {
    var paramTypes = filteredTypes[baseType]!.toList()..sort();
    print('    $prefix$baseType: {' + paramTypes.join(', ') + '},');
  }
  print('  };');
}

// Print all generated and collected types, operators and type collections.
void printTypeTable(Set<InterfaceType> allTypes,
    {bool fp = true, bool flatTp = false}) {
  final subclass = !fp || flatTp;
  if (!subclass) {
    print('''
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: annotate_overrides
// ignore_for_file: unused_element
// ignore_for_file: unused_field

/// Class that represents some common Dart types.
///
/// NOTE: this code has been generated automatically.
///''');
  }

  var className = 'DartType${fp ? "" : "NoFp"}${flatTp ? "FlatTp" : ""}';

  print('class $className'
      '${subclass ? " extends DartType" : ""} {');
  print('  final String name;');
  print('  final bool isNullable;');
  if (!subclass) {
    print('  const DartType._withName(this.name, this.isNullable);');
    print('''
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
  }''');
  } else {
    print('  const $className'
        '._withName(this.name, this.isNullable) : super._withName(name, isNullable);');
  }

  print('''
  const $className() : name = "!", isNullable = false;

  String get dartName { return name + (isNullable ? "?" : ""); }
  String toString() { return "DartType(\$dartName)"; }

  static bool isListType(DartType tp) {
    return DartType._listTypes.contains(tp.toNonNullable());
  }

  static bool isSetType(DartType tp) {
    return DartType._setTypes.contains(tp.toNonNullable());
  }

  static bool isMapType(DartType tp) {
    return DartType._mapTypes.contains(tp.toNonNullable());
  }

  static bool isCollectionType(DartType tp) {
    return DartType._collectionTypes.contains(tp.toNonNullable());
  }

  static bool isGrowableType(DartType tp) {
    return DartType._growableTypes.contains(tp.toNonNullable());
  }

  static bool isComplexType(DartType tp) {
    return DartType._complexTypes.contains(tp.toNonNullable());
  }

  DartType toNullable() {
    if (isNullable) {
      return this;
    }
    for (var tp in _allTypes) {
      if (tp.isNullable && tp.name == name) return tp;
    }
    throw 'Fail toNullable \$name \$isNullable';
  }

  DartType toNonNullable() {
    if (!isNullable) {
      return this;
    }
    for (var tp in _allTypes) {
      if (!tp.isNullable && tp.name == name) return tp;
    }
    throw 'Fail toNonNullable \$name \$isNullable';
  }

  bool isInterfaceOfType(DartType tp, DartType iTp) {
    tp = tp.toNonNullable();
    iTp = iTp.toNonNullable();
    return _interfaceRels.containsKey(iTp) && _interfaceRels[iTp]!.contains(tp);
  }

  Set<DartType> get mapTypes {
    return _mapTypes;
  }

  bool isSpecializable(DartType tp) {
    return _interfaceRels.containsKey(tp.toNonNullable());
  }

  Set<DartType> interfaces(DartType tp) {
    tp = tp.toNonNullable();
    if (_interfaceRels.containsKey(tp)) {
      return _interfaceRels[tp]!;
    }
    throw "NotFound";
  }

  DartType indexType(DartType tp) {
    tp = tp.toNonNullable();
    if (_indexedBy.containsKey(tp)) {
      return _indexedBy[tp]!;
    }
    throw "NotFound";
  }

  Set<DartType> indexableElementTypes(DartType tp) {
    if (_indexableElementOf.containsKey(tp)) {
      return _indexableElementOf[tp]!;
    }
    throw "NotFound";
  }

  bool isIndexableElementType(DartType tp) {
    return _indexableElementOf.containsKey(tp);
  }

  DartType elementType(DartType tp) {
    tp = tp.toNonNullable();
    if (_subscriptsTo.containsKey(tp)) {
      return _subscriptsTo[tp]!;
    }
    throw "NotFound";
  }

  Set<DartType> get iterableTypes1 {
    return _iterableTypes1;
  }

  Set<String> uniOps(DartType tp) {
    if (_uniOps.containsKey(tp)) {
      return _uniOps[tp]!;
    }
    return <String>{};
  }

  Set<String> binOps(DartType tp) {
    if (_binOps.containsKey(tp)) {
      return _binOps[tp]!.keys.toSet();
    }
    return <String>{};
  }

  Set<List<DartType>> binOpParameters(DartType tp, String op) {
    if (_binOps.containsKey(tp) &&
        _binOps[tp]!.containsKey(op)) {
      return _binOps[tp]![op]!;
    }
    throw "NotFound";
  }

  Set<String> assignOps(DartType tp) {
    if (_assignOps.containsKey(tp)) {
      return _assignOps[tp]!.keys.toSet();
    }
    return <String>{};
  }

  Set<DartType> assignOpRhs(DartType tp, String op) {
    if (_assignOps.containsKey(tp) &&
        _assignOps[tp]!.containsKey(op)) {
      return _assignOps[tp]![op]!;
    }
    return <DartType>{};
  }

  bool hasConstructor(DartType tp) {
    tp = tp.toNonNullable();
    return _constructors.containsKey(tp);
  }

  Set<String> constructors(DartType tp) {
    tp = tp.toNonNullable();
    if (_constructors.containsKey(tp)) {
      return _constructors[tp]!.keys.toSet();
    }
    return <String>{};
  }

  List<DartType> constructorParameters(DartType tp, String constructor) {
    tp = tp.toNonNullable();
    if (_constructors.containsKey(tp) &&
        _constructors[tp]!.containsKey(constructor)) {
      return _constructors[tp]![constructor]!;
    }
    throw "NotFound";
  }

  Set<DartType> get allTypes {
    return _allTypes;
  }

''');

  print("  static const VOID = DartType._withName('void', false);");
  print("  static const VOID_NULLABLE = VOID;");
  var instTypes = <String>{};

  // Generate one static DartType instance for all instantiable types.
  // TODO (felih): maybe add void type?
  allTypes.forEach((baseType) {
    var constName = typeConstName(baseType);
    instTypes.add(constName);
    if (!subclass) {
      print('  static const $constName = '
          "DartType._withName('${baseType.asCode}', false);");
      print('  static const ${constName}_NULLABLE = '
          "DartType._withName('${baseType.asCode}', true);");
    }
  });

  if (!subclass) {
    // Generate one static DartType instance for all non instantiable types.
    // These are required to resolve interface relations, but should not be
    // used directly to generate dart programs.
    print('');
    print('  // NON INSTANTIABLE' '');
    interfaceRels.keys.forEach((constName) {
      if (instTypes.contains(constName)) return;
      print('  static const $constName = '
          "DartType._withName('__$constName', false);");
      print('  static const ${constName}_NULLABLE = '
          "DartType._withName('__$constName', true);");
    });
  }

  // Generate a list of all instantiable types.
  print('');
  print('''
  // All types extracted from analyzer.
  static const _allTypes = {''');
  filterTypesSet(instTypes, fp: fp, flatTp: flatTp).forEach((constName) {
    print("    ${subclass ? "DartType." : ""}$constName,");
    print("    ${subclass ? "DartType." : ""}${constName}_NULLABLE,");
  });
  print('  };');

  print('');
  print('''
  // All List<E> types: LIST_INT, LIST_STRING, etc.''');
  printTypeSet('_listTypes', listTypes, fp: fp, flatTp: flatTp);

  print('');
  print('''
  // All Set types: SET_INT, SET_STRING, etc.''');
  printTypeSet('_setTypes', setTypes, fp: fp, flatTp: flatTp);

  print('');
  print('''
  // All Map<K, V> types: MAP_INT_STRING, MAP_DOUBLE_BOOL, etc.''');
  printTypeSet('_mapTypes', mapTypes, fp: fp, flatTp: flatTp);

  print('');
  print('''
  // All collection types: list, map and set types.''');
  printTypeSet('_collectionTypes', {...listTypes, ...setTypes, ...mapTypes},
      fp: fp, flatTp: flatTp);

  print('');
  print('''
  // All growable types: list, map, set and string types.''');
  printTypeSet(
      '_growableTypes', {...listTypes, ...setTypes, ...mapTypes, 'STRING'},
      fp: fp, flatTp: flatTp);

  if (!subclass) {
    print('');
    print(
        '  // All floating point types: DOUBLE, SET_DOUBLE, MAP_X_DOUBLE, etc.');
    printTypeSet('_fpTypes', fpTypes);
  }

  print('');
  print('''
  // All trivially indexable types: Map types and List types.
  // Elements of these can be written and read by [], unlike Set
  // which uses getElementAt to access individual elements.''');
  printTypeSet('_indexableTypes', indexableTypes, fp: fp, flatTp: flatTp);

  print('');
  print('''
  // Map type to the resulting type when subscripted.
  // Example: List<String> subscripts to String.''');
  printTypeMap1('_subscriptsTo', subscriptsTo, fp: fp, flatTp: flatTp);

  print('');
  print('''
  // Map type to type required as index.
  // Example: List<String> is indexed by int,
  // Map<String, double> indexed by String.''');
  printTypeMap1('_indexedBy', indexedBy, fp: fp, flatTp: flatTp);

  print('');
  print('''
  // Map type to a Set of types that contain it as an element.
  // Example: String is element of List<String> and Map<int, String>''');
  printTypeMap2('_elementOf', elementOf, fp: fp, flatTp: flatTp);

  print('');
  print('''
  // Map type to a Set of types that contain it as an indexable element.
  // Same as element of, but without Set types.''');
  printTypeMap2('_indexableElementOf', indexableElementOf,
      fp: fp, flatTp: flatTp);

  print('');
  print('''
  // All iterable types: Set types + List types.
  // These can be used in for(x in <iterable type>),
  // therefore Map is not included.''');
  printTypeSet('_iterableTypes1', iterableTypes1, fp: fp, flatTp: flatTp);

  if (!subclass) {
    print('');
    print('''
  // Complex types: Collection types instantiated with nested argument
  // e.g Map<List<>, >.''');
    printTypeSet('_complexTypes', complexTypes);
  }

  print('');
  print('''
  // Map Interface type to Set of types that implement it.
  // Example: interface num is implemented by int and double.''');
  printTypeMap2('_interfaceRels', interfaceRels, fp: fp, flatTp: flatTp);

  print('');
  print('''
  // Map type to a list of constructors names with a list of constructor
  // parameter types.''');
  printTypeMap3('_constructors', constructors, fp: fp, flatTp: flatTp);

  print('');
  print('''
  // Map type to a list of binary operators with set of the respective
  // types for the first and second operand.''');
  printTypeMap4('_binOps', binOps, fp: fp, flatTp: flatTp);

  print('');
  print('''
  // Map type to a list of available unary operators.''');
  printTypeMapSet('_uniOps', uniOps, fp: fp, flatTp: flatTp);

  print('');
  print('''
  // Map type to a list of assignment operators with a set of the
  // assignable right hand side types.''');
  printTypeMap3Set('_assignOps', assignOps, fp: fp, flatTp: flatTp);

  print('}');
  print('');
}

// Returns true if type can be set and get via [].
bool isIndexable(InterfaceType tp) {
  var isIndexable = false;
  for (var method in tp.methods) {
    if (method.name == '[]') {
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
          interfaceRels[iTypName]!.contains(typName));
}

// Filter operator parameters so that the more specific types are discarded if
// the respective interface type is already in the list.
// This is required not only to give each parameter type equal probability but
// also so that dartfuzz can efficiently filter floating point types from the
// interface relations.
Set<List<String>> filterOperator(Set<List<String>> op) {
  var newOp = <List<String>>{};
  if (op.length < 2) return op;
  for (var params1 in op) {
    var keep = false;
    for (var params2 in op) {
      for (var k = 0; k < params1.length; ++k) {
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

// See comment on filterOperator.
void filterOperators(Set<InterfaceType> allTypes) {
  for (var tp in allTypes) {
    var typName = typeConstName(tp);
    if (!binOps.containsKey(typName)) continue;
    for (var op in binOps[typName]!.keys) {
      binOps[typName]![op] = filterOperator(binOps[typName]![op]!);
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
  if (((tp.element.name == 'Float32x4') && (method.name == '/')) ||
      ((tp.element.name == 'Float64x2') && (method.name == '/'))) {
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
  for (var method in tp.methods) {
    // If the method is manually excluded, skip it.
    if (isExcludedMethod(tp, method)) continue;

    // Detect whether tp can be parsed from a literal (dartfuzz.dart can
    // already handle that).
    // This is usually indicated by the presence of the static constructor
    // 'castFrom' or 'parse'.
    if (method.isStatic &&
        (method.name == 'castFrom' || method.name == 'parse')) {
      fromLiteral.add(typeConstName(tp));
    }
    // Hack: dartfuzz.dart already handles subscripts, therefore we exclude
    // them from the generated type table.
    if (method.name.startsWith('[]')) continue;
    if (method.isOperator) {
      // TODO (felih): Include support for type 'dynamic'.
      var skip = false;
      for (var p in method.parameters) {
        if (typeConstName(p.type) == 'DYNAMIC') {
          skip = true;
          break;
        }
      }
      if (skip) continue;
      if (method.parameters.length == 1) {
        // Get binary operators.

        var retTypName = typeConstName(method.returnType);
        if (method.returnType.nullabilitySuffix != NullabilitySuffix.none) {
          retTypName += '_NULLABLE';
        }
        binOps[retTypName] ??= <String, Set<List<String>>>{};
        binOps[retTypName]![method.name] ??= <List<String>>{};

        var rhsTypName = typeConstName(method.parameters[0].type);
        if (method.parameters[0].type.nullabilitySuffix !=
            NullabilitySuffix.none) {
          rhsTypName += '_NULLABLE';
        }

        // TODO (felih): no hashing for List<String> ?
        // if i remove this test i will get duplicates even though it is a Set.
        var present = false;
        for (var o in binOps[retTypName]![method.name]!) {
          if (o[0] == typName && o[1] == rhsTypName) {
            present = true;
            break;
          }
        }
        if (!present) {
          binOps[retTypName]![method.name]!.add([typName, rhsTypName]);
        }

        // Add some assignment operators corresponding to the binary operators.
        // Example: for '+' add '+='.
        // Bool types have to be filtered because boolean binary operators
        // can not be used to derive assignment operators in this way, e.g.
        // <= is not a valid assignment operator for bool types.
        if (retTypName != 'BOOL') {
          assignOps[retTypName] ??= <String, Set<String>>{};
          var ao = method.name + '=';
          assignOps[retTypName]![ao] ??= <String>{};
          assignOps[retTypName]![ao]!.add(rhsTypName);
        }
      } else {
        // Get unary operators.
        uniOps[typName] ??= <String>{};
        var uo = method.name;
        // Hack: remove unary from operator so that the operator name can be
        // used directly for source code generation.
        if (uo.startsWith('unary')) uo = '-';
        uniOps[typName]!.add('\'$uo\'');
      }
    }
  }
}

bool typesEqualModuloNullability(DartType a, DartType b) {
  // The analyzer's DartType doesn't provide conversions to change nullability.
  // Comparing by name isn't correct in general, but it works for the core
  // libraries because there are no simple name conflicts.
  return a.asCode == b.asCode;
}

// Extract all binary and unary operators for all types.
void getOperators(Set<InterfaceType> allTypes) {
  // Set of types that can be constructed directly from literals and do
  // not need special constructors (e.g. List<int> = [1, 2] as opposed to
  // Int8List int8list = Int8List.fromList([1, 2]) ).
  var fromLiteral = <String>{};

  // getOperatorsForTyp uses a heuristic to detect which types can be
  // constructed from a literal, but the heuristic misses the String type
  // so we have to add it manually.
  fromLiteral.add('STRING');
  // Get binary, unary and assignment operators.
  for (var tp in allTypes) {
    var typName = typeConstName(tp);
    // Manually add basic assignment operators which each type supports.
    assignOps[typName] ??= <String, Set<String>>{};
    assignOps[typName]!['='] = {typName};
    getOperatorsForTyp(typName, tp, fromLiteral);

    var typNameNullable = typName + "_NULLABLE";
    assignOps[typNameNullable] ??= <String, Set<String>>{};
    assignOps[typNameNullable]!['='] = {typName, typNameNullable};
    assignOps[typNameNullable]!['??='] = {typName, typNameNullable};
  }

  // Add some static ops not extractable from dart:core/typed_data.
  for (var typName in binOps.keys.toList()) {
    if (typName.endsWith("_NULLABLE")) continue;

    var typNameNullable = typName + "_NULLABLE";
    binOps[typNameNullable] ??= <String, Set<List<String>>>{};
    binOps[typNameNullable]!['??'] = {
      [typNameNullable, typName],
      [typNameNullable, typNameNullable],
    };

    binOps[typName] ??= <String, Set<List<String>>>{};
    binOps[typName]!['??'] = {
      [typNameNullable, typName],
    };
  }
  binOps['BOOL'] ??= <String, Set<List<String>>>{};
  binOps['BOOL']!['&&'] = {
    ['BOOL', 'BOOL'],
  };
  binOps['BOOL']!['||'] = {
    ['BOOL', 'BOOL'],
  };
  uniOps['BOOL'] ??= <String>{};
  uniOps['BOOL']!.add('\'!\'');

  // Get constructors.
  for (var tp in allTypes) {
    var typName = typeConstName(tp);
    // Skip types that are constructable from a literal.
    if (fromLiteral.contains(typName)) {
      continue;
    }
    for (var constructor in tp.constructors) {
      if (shouldFilterConstructor(tp, constructor)) continue;
      var params = <String>[];
      var canConstruct = true;
      for (var p in constructor.parameters) {
        var tstr = typeConstName(p.type);
        if (tstr == 'DYNAMIC' || tstr == 'OBJECT') {
          tstr = 'INT';
        } else if (!allTypes
            .any((a) => typesEqualModuloNullability(a, p.type))) {
          // Exclude constructors that have an unsupported parameter type.
          canConstruct = false;
          break;
        }
        // Only add positional required parameters.
        // TODO (felih): include named and optional parameters.
        if (!p.isNamed) params.add(tstr);
      }
      if (!canConstruct) continue;

      constructors[typName] ??= <String, List<String>>{};
      constructors[typName]![constructor.name] = params;
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
  if ((tp.element.name == 'Float32x4') && (cons.name == 'fromInt32x4Bits')) {
    return true;
  }
  return false;
}

// Analyze types to extract element and subscript relations
// as well as precision type attributes.
void analyzeTypes(Set<InterfaceType> allTypes) {
  // Extract basic floating point types.
  for (var tp in allTypes) {
    if (tp.asCode.contains('Float') ||
        tp.asCode.contains('float') ||
        tp.asCode.contains('double') ||
        tp.asCode.contains('Double')) {
      fpTypes.add(typeConstName(tp));
    }
  }

  // Analyze all types to extract information useful for dart code generation.
  for (var tp in allTypes) {
    final typName = typeConstName(tp);

    // Find topmost interface type, e.g. List<int> is interface for Int8List.
    var iTyp = tp;
    while (iTyp.typeArguments.isEmpty && iTyp.interfaces.isNotEmpty) {
      iTyp = tp.interfaces[0];
    }

    // Group current type with their respective type group.
    if (iTyp.name == 'Set') setTypes.add(typName);
    if (iTyp.name == 'List') listTypes.add(typName);
    if (iTyp.name == 'Map') mapTypes.add(typName);

    if (iTyp.typeArguments.length == 1) {
      // Analyze Array, List and Set types.
      var argName = typeConstName(iTyp.typeArguments[0]);
      subscriptsTo[typName] = argName;
      elementOf[argName] ??= <String>{};
      elementOf[argName]!.add(typName);
      if (isIndexable(iTyp)) {
        indexableElementOf[argName] ??= <String>{};
        indexableElementOf[argName]!.add(typName);
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
        var argName0 = typeConstName(iTyp.typeArguments[0]);
        var argName1 = typeConstName(iTyp.typeArguments[1]);
        subscriptsTo[typName] = argName1;
        elementOf[argName1] ??= <String>{};
        elementOf[argName1]!.add(typName);
        indexableElementOf[argName1] ??= <String>{};
        indexableElementOf[argName1]!.add(typName);
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
        (tp.typeArguments[0].name == 'E' || tp.typeArguments[0].name == 'T')) {
      pTypes1.add(tp);
    } else if (tp.typeArguments.length == 2 &&
        tp.typeArguments[0].name == 'K' &&
        tp.typeArguments[1].name == 'V') {
      pTypes2.add(tp);
    } else {
      iTypes.add(tp);
    }
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
  var newITypes = <InterfaceType>{};

  // Calculate the total number of new types if all combinations were used.
  int nNew = pTypes1.length * iTypes.length +
      pTypes2.length * iTypes.length * iTypes.length;
  // Calculate how many generated types have to be skipped in order to stay
  // under the maximum number set for generating new types (maxNew).
  double step = maxNew / nNew.toDouble();
  double cntr = 0.0;

  // Instantiate List and Set types.
  pTypes1.forEach((pType) {
    iTypes.forEach((iType) {
      cntr += step;
      if (cntr >= 1.0) {
        cntr -= 1.0;
      } else {
        return;
      }
      InterfaceType ptx = pType.element.instantiate(
        typeArguments: [iType],
        nullabilitySuffix: NullabilitySuffix.star,
      );
      newITypes.add(ptx);
      if (iType.typeArguments.isNotEmpty) {
        complexTypes.add(typeConstName(ptx));
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
          return;
        }
        InterfaceType ptx = pType.element.instantiate(
          typeArguments: [iType1, iType2],
          nullabilitySuffix: NullabilitySuffix.star,
        );
        newITypes.add(ptx);
        if (iType1.typeArguments.isNotEmpty ||
            iType2.typeArguments.isNotEmpty) {
          complexTypes.add(typeConstName(ptx));
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
  var pTypes1 = <InterfaceType>{};
  // Types with two parameters (Map).
  var pTypes2 = <InterfaceType>{};
  // Types with no parameters or parameters of which have already been
  // instantiated.
  var iTypes = <InterfaceType>{};
  // Fill type sets with respective parameter types.
  getParameterizedTypes(allTypes, pTypes1, pTypes2, iTypes);

  // Filter the list of zero parameter types to exclude
  // complex types like Int8List.
  var filteredITypes = <InterfaceType>{};
  for (var iType in iTypes) {
    if (iTypeFilter.contains(iType.element.name)) {
      filteredITypes.add(iType);
    }
  }

  // Instantiate types with one or two free parameters.
  // Concatenate the newly instantiated types with the previous set of
  // instantiated or zero parameter types to be used as input for the next
  // round or instantiation.
  // Each iteration constructs more nested types like
  // Map<Map<int, int>, List<int>>.
  for (var i = 0; i < depth + 1; ++i) {
    double mn = max(1.0, maxNew / (depth + 1.0));
    filteredITypes = filteredITypes
        .union(instantiatePTypes(pTypes1, pTypes2, filteredITypes, maxNew: mn));
  }

  return iTypes.union(filteredITypes);
}

// Heuristic of which types to include:
// count the number of operators and
// check if the type can be constructed from a literal.
int countOperators(InterfaceElement ce) {
  var no = 0;
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
    for (var ci in ce.interfaces) {
      no += countOperators(ci.element);
    }
  });
  return no;
}

// Analyze typed_data and core libraries to extract data types.
Future<void> getDataTypes(Set<InterfaceType> allTypes, String? dartTop) async {
  final session = GenUtil.createAnalysisSession(dartTop);

  // Visit libraries for type table generation.
  await visitLibraryAtUri(session, 'dart:typed_data', allTypes);
  await visitLibraryAtUri(session, 'dart:core', allTypes);
}

Future<void> visitLibraryAtUri(
    AnalysisSession session, String uri, Set<InterfaceType> allTypes) async {
  var libPath = session.uriConverter.uriToPath(Uri.parse(uri));
  var result = await session.getResolvedLibrary(libPath!);
  if (result is ResolvedLibraryResult) {
    visitLibrary(result.element, allTypes);
  } else {
    throw StateError('Unable to resolve "$uri"');
  }
}

void visitLibrary(LibraryElement library, Set<InterfaceType> allTypes) {
  // This uses the element model to traverse the code. The element model
  // represents the semantic structure of the code. A library consists of
  // one or more compilation units.
  for (var unit in library.units) {
    visitCompilationUnit(unit, allTypes);
  }
}

void visitCompilationUnit(
    CompilationUnitElement unit, Set<InterfaceType> allTypes) {
  // Each compilation unit contains elements for all of the top-level
  // declarations in a single file, such as variables, functions, and
  // classes. Note that `types` only returns classes. You can use
  // `mixins` to visit mixins, `enums` to visit enum, `functionTypeAliases`
  // to visit typedefs, etc.
  for (var classElement in unit.classes) {
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
          (classElement.name == 'Iterator') ||
          (classElement.name == 'Stopwatch') ||
          (classElement.name == 'Finalizer') ||
          (classElement.name == 'Enum') ||
          (classElement.name == 'Record') ||
          (classElement.name == 'OutOfMemoryError')) {
        continue;
      }
      allTypes.add(classElement.thisType);
    }
  }
}

// Get all interface implemented by type.
Set<String> getInterfaces(InterfaceType tp) {
  var iTypes = <String>{};
  for (var iTyp in tp.interfaces) {
    var ifTypName = typeConstName(iTyp);
    iTypes.add(ifTypName);
    iTypes = iTypes.union(getInterfaces(iTyp));
  }
  return iTypes;
}

// Get interface and inheritance relationships for all types.
void getInterfaceRels(Set<InterfaceType> allTypes) {
  for (var tp in allTypes) {
    var typName = typeConstName(tp);
    for (var ifTypName in getInterfaces(tp)) {
      interfaceRels[ifTypName] ??= <String>{};
      interfaceRels[ifTypName]!.add(typName);
      if (ifTypName.contains('ITERABLE')) {
        iterableTypes1.add(typName);
      }
    }
    for (var it in tp.element.allSupertypes) {
      var ifTypName = typeConstName(it);
      interfaceRels[ifTypName] ??= <String>{};
      interfaceRels[ifTypName]!.add(typName);
    }
  }
  // If interface can be instantiated,
  // add it to the relation list so that we can
  // do tp1 = oneof(interfaceRels[tp2]) in dartfuzz with a chance of
  // tp1 == tp1.
  for (var tp in allTypes) {
    var typName = typeConstName(tp);
    if (interfaceRels.containsKey(typName)) {
      interfaceRels[typName]!.add(typName);
    }
  }
}

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('dart-top', help: 'explicit value for \$DART_TOP')
    ..addOption('depth',
        help: 'Nesting depth, e.g. List<String> is depth 0, '
            'List<List<String>>'
            'is depth 1. Remark: dart type tables grow '
            'exponentially with this, '
            'therefore types with higher nesting '
            'depth are partially filtered.',
        defaultsTo: '1');
  ArgResults results;
  try {
    results = parser.parse(arguments);
  } catch (e) {
    print('Usage: dart gen_type_table.dart [OPTIONS]\n${parser.usage}\n$e');
    exitCode = 255;
    return;
  }
  var depth = int.parse(results['depth']);
  var allTypes = <InterfaceType>{};
  // Filter types to instantiate parameterized types with, this excludes
  // complex types like Int8List (might be added later).
  var iTypeFilter = <String>{'int', 'bool', 'double', 'String'};
  // Extract basic types from dart::core and dart::typed_data.
  await getDataTypes(allTypes, results['dart-top']);
  // Instantiate parameterized types like List<E>.
  allTypes = instantiateAllTypes(allTypes, iTypeFilter, depth, maxNew: 10000.0);
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
}
