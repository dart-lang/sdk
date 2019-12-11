// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Generates the API tables used by DartFuzz. Automatically generating these
// tables is less error-prone than generating such tables by hand. Furthermore,
// it simplifies regenerating the table when the libraries change.
//
// Usage:
//   dart gen_api_table.dart > dartfuzz_api_table.dart
//
// Then send out modified dartfuzz_api_table.dart for review together
// with a modified dartfuzz.dart that increases the version.

import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import 'gen_util.dart';

// Class to represent a library method by name and prototype representation.
class DartLib {
  final String name;
  final String proto;
  const DartLib(this.name, this.proto);
}

// Lists of recognized methods, organized by return type.
var voidTable = <DartLib>[];
var boolTable = <DartLib>[];
var intTable = <DartLib>[];
var doubleTable = <DartLib>[];
var stringTable = <DartLib>[];
var listTable = <DartLib>[];
var setTable = <DartLib>[];
var mapTable = <DartLib>[];
var int8ListTable = <DartLib>[];
var int16ListTable = <DartLib>[];
var int32ListTable = <DartLib>[];
var int32x4Table = <DartLib>[];
var int32x4ListTable = <DartLib>[];
var int64ListTable = <DartLib>[];
var float32ListTable = <DartLib>[];
var float32x4ListTable = <DartLib>[];
var float32x4Table = <DartLib>[];
var float64ListTable = <DartLib>[];
var float64x2Table = <DartLib>[];
var float64x2ListTable = <DartLib>[];
var uint8ClampedListTable = <DartLib>[];
var uint8ListTable = <DartLib>[];
var uint16ListTable = <DartLib>[];
var uint32ListTable = <DartLib>[];
var uint64ListTable = <DartLib>[];

const voidEncoding = 'V';
const boolEncoding = 'B';
const intEncoding = 'I';
const doubleEncoding = 'D';
const stringEncoding = 'S';
const listEncoding = 'L';
const setEncoding = 'X';
const mapEncoding = 'M';
const int8ListEncoding = 'A';
const int16ListEncoding = 'C';
const int32ListEncoding = 'E';
const int32x4Encoding = 'F';
const int32x4ListEncoding = 'G';
const int64ListEncoding = 'H';
const float32ListEncoding = 'J';
const float32x4Encoding = 'K';
const float32x4ListEncoding = 'N';
const float64ListEncoding = 'O';
const float64x2Encoding = 'P';
const float64x2ListEncoding = 'Q';
const uint8ClampedListEncoding = 'R';
const uint8ListEncoding = 'T';
const uint16ListEncoding = 'U';
const uint32ListEncoding = 'W';
const uint64ListEncoding = 'Y';

final voidLibs = 'voidLibs';
final boolLibs = 'boolLibs';
final intLibs = 'intLibs';
final doubleLibs = 'doubleLibs';
final stringLibs = 'stringLibs';
final listLibs = 'listLibs';
final setLibs = 'setLibs';
final mapLibs = 'mapLibs';
final int8ListLibs = 'int8ListLibs';
final int16ListLibs = 'int16ListLibs';
final int32ListLibs = 'int32ListLibs';
final int32x4Libs = 'int32x4Libs';
final int32x4ListLibs = 'int32x4ListLibs';
final int64ListLibs = 'int64ListLibs';
final float32ListLibs = 'float32ListLibs';
final float32x4Libs = 'float32x4Libs';
final float32x4ListLibs = 'float32x4ListLibs';
final float64ListLibs = 'float64ListLibs';
final float64x2Libs = 'float64x2Libs';
final float64x2ListLibs = 'float64x2ListLibs';
final uint8ClampedListLibs = 'uint8ClampedListLibs';
final uint8ListLibs = 'uint8ListLibs';
final uint16ListLibs = 'uint16ListLibs';
final uint32ListLibs = 'uint32ListLibs';
final uint64ListLibs = 'uint64ListLibs';

final stringToType = {
  voidEncoding: 'DartType.VOID',
  boolEncoding: 'DartType.BOOL',
  intEncoding: 'DartType.INT',
  doubleEncoding: 'DartType.DOUBLE',
  stringEncoding: 'DartType.STRING',
  listEncoding: 'DartType.LIST_INT',
  setEncoding: 'DartType.SET_INT',
  mapEncoding: 'DartType.MAP_INT_STRING',
  int8ListEncoding: 'DartType.INT8LIST',
  int16ListEncoding: 'DartType.INT16LIST',
  int32ListEncoding: 'DartType.INT32LIST',
  //  int32x4Encoding: 'DartType.INT32X4',
  int32x4ListEncoding: 'DartType.INT32X4LIST',
  int64ListEncoding: 'DartType.INT64LIST',
  float32ListEncoding: 'DartType.FLOAT32LIST',
  float32x4Encoding: 'DartType.FLOAT32X4',
  float32x4ListEncoding: 'DartType.FLOAT32X4LIST',
  float64ListEncoding: 'DartType.FLOAT64LIST',
  float64x2Encoding: 'DartType.FLOAT64X2',
  float64x2ListEncoding: 'DartType.FLOAT64X2LIST',
  uint8ClampedListEncoding: 'DartType.UINT8CLAMPEDLIST',
  uint8ListEncoding: 'DartType.UINT8LIST',
  uint16ListEncoding: 'DartType.UINT16LIST',
  uint32ListEncoding: 'DartType.UINT32LIST',
  uint64ListEncoding: 'DartType.UINT64LIST'
};

final typeToLibraryMethods = {
  'DartType.VOID': voidLibs,
  'DartType.BOOL': boolLibs,
  'DartType.INT': intLibs,
  'DartType.DOUBLE': doubleLibs,
  'DartType.STRING': stringLibs,
  'DartType.LIST_INT': listLibs,
  'DartType.SET_INT': setLibs,
  'DartType.MAP_INT_STRING': mapLibs,
  'DartType.INT8LIST': int8ListLibs,
  'DartType.INT16LIST': int16ListLibs,
  'DartType.INT32LIST': int32ListLibs,
  //  'DartType.INT32X4': int32x4Libs,
  'DartType.INT32X4LIST': int32x4ListLibs,
  'DartType.INT64LIST': int64ListLibs,
  'DartType.FLOAT32LIST': float32ListLibs,
  'DartType.FLOAT32X4': float32x4Libs,
  'DartType.FLOAT32X4LIST': float32x4ListLibs,
  'DartType.FLOAT64LIST': float64ListLibs,
  'DartType.FLOAT64X2': float64x2Libs,
  'DartType.FLOAT64X2LIST': float64x2ListLibs,
  'DartType.UINT8CLAMPEDLIST': uint8ClampedListLibs,
  'DartType.UINT8LIST': uint8ListLibs,
  'DartType.UINT16LIST': uint16ListLibs,
  'DartType.UINT32LIST': uint32ListLibs,
  'DartType.UINT64LIST': uint64ListLibs
};

final typedDataFloatTypes = [
  float32ListEncoding,
  float32x4Encoding,
  float32x4ListEncoding,
  float64ListEncoding,
  float64x2Encoding,
  float64x2ListEncoding
];

main() async {
  final AnalysisSession session = GenUtil.createAnalysisSession();

  // Visit libraries for table generation.
  await visitLibraryAtUri(session, 'dart:async');
  await visitLibraryAtUri(session, 'dart:cli');
  await visitLibraryAtUri(session, 'dart:collection');
  await visitLibraryAtUri(session, 'dart:convert');
  await visitLibraryAtUri(session, 'dart:core');
  await visitLibraryAtUri(session, 'dart:io');
  await visitLibraryAtUri(session, 'dart:isolate');
  await visitLibraryAtUri(session, 'dart:math');
  await visitLibraryAtUri(session, 'dart:typed_data');

  // Generate the tables in a stand-alone Dart class.
  dumpHeader();
  dumpStringToTypeMap();
  dumpTypeToLibraryMethodMap();
  dumpTypedDataFloatTypes();
  dumpTable(voidLibs, voidTable);
  dumpTable(boolLibs, boolTable);
  dumpTable(intLibs, intTable);
  dumpTable(doubleLibs, doubleTable);
  dumpTable(stringLibs, stringTable);
  dumpTable(listLibs, listTable);
  dumpTable(setLibs, setTable);
  dumpTable(mapLibs, mapTable);
  dumpTable(int8ListLibs, int8ListTable);
  dumpTable(int16ListLibs, int16ListTable);
  dumpTable(int32ListLibs, int32ListTable);
  //  dumpTable(int32x4Libs, int32x4Table);
  dumpTable(int32x4ListLibs, int32x4ListTable);
  dumpTable(int64ListLibs, int64ListTable);
  dumpTable(float32ListLibs, float32ListTable);
  dumpTable(float32x4Libs, float32x4Table);
  dumpTable(float32x4ListLibs, float32x4ListTable);
  dumpTable(float64ListLibs, float64ListTable);
  dumpTable(float64x2Libs, float64x2Table);
  dumpTable(float64x2ListLibs, float64x2ListTable);
  dumpTable(uint8ClampedListLibs, uint8ClampedListTable);
  dumpTable(uint8ListLibs, uint8ListTable);
  dumpTable(uint16ListLibs, uint16ListTable);
  dumpTable(uint32ListLibs, uint32ListTable);
  dumpTable(uint64ListLibs, uint64ListTable);
  dumpFooter();
}

visitLibraryAtUri(AnalysisSession session, String uri) async {
  final String libPath = session.uriConverter.uriToPath(Uri.parse(uri));
  ResolvedLibraryResult result = await session.getResolvedLibrary(libPath);
  if (result.state != ResultState.VALID) {
    throw StateError('Unable to resolve "$uri"');
  }
  visitLibrary(result.element);
}

visitLibrary(LibraryElement library) async {
  // This uses the element model to traverse the code. The element model
  // represents the semantic structure of the code. A library consists of
  // one or more compilation units.
  for (CompilationUnitElement unit in library.units) {
    visitCompilationUnit(unit);
  }
}

visitCompilationUnit(CompilationUnitElement unit) {
  // Each compilation unit contains elements for all of the top-level
  // declarations in a single file, such as variables, functions, and
  // classes. Note that `types` only returns classes. You can use
  // `mixins` to visit mixins, `enums` to visit enum, `functionTypeAliases`
  // to visit typedefs, etc.
  for (TopLevelVariableElement variable in unit.topLevelVariables) {
    if (variable.isPublic) {
      addToTable(typeString(variable.type), variable.name, 'Vv');
    }
  }
  for (FunctionElement function in unit.functions) {
    if (function.isPublic && !function.isOperator) {
      addToTable(typeString(function.returnType), function.name,
          protoString(null, function.parameters));
    }
  }
  for (ClassElement classElement in unit.types) {
    if (classElement.isPublic) {
      visitClass(classElement);
    }
  }
}

void visitClass(ClassElement classElement) {
  // Classes that cause too many false divergences.
  if (classElement.name == 'ProcessInfo' ||
      classElement.name == 'Platform' ||
      classElement.name.startsWith('FileSystem')) {
    return;
  }
  // Every class element contains elements for the members, viz. `methods` visits
  // methods, `fields` visits fields, `accessors` visits getters and setters, etc.
  // There are also accessors to get the superclass, mixins, interfaces, type
  // parameters, etc.
  for (ConstructorElement constructor in classElement.constructors) {
    if (constructor.isPublic &&
        constructor.isFactory &&
        constructor.name.isNotEmpty) {
      addToTable(
          typeString(classElement.thisType),
          '${classString(classElement)}.${constructor.name}',
          protoString(null, constructor.parameters));
    }
  }
  for (MethodElement method in classElement.methods) {
    if (method.isPublic && !method.isOperator) {
      if (method.isStatic) {
        addToTable(
            typeString(method.returnType),
            '${classString(classElement)}.${method.name}',
            protoString(null, method.parameters));
      } else {
        addToTable(typeString(method.returnType), method.name,
            protoString(classElement.thisType, method.parameters));
      }
    }
  }
  for (PropertyAccessorElement accessor in classElement.accessors) {
    if (accessor.isPublic && accessor.isGetter) {
      var variable = accessor.variable;
      if (accessor.isStatic) {
        addToTable(typeString(variable.type),
            '${classElement.name}.${variable.name}', 'Vv');
      } else {
        addToTable(typeString(variable.type), variable.name,
            '${typeString(classElement.thisType)}v');
      }
    }
  }
}

// Function that returns the explicit class name.
String classString(ClassElement classElement) {
  switch (typeString(classElement.thisType)) {
    case setEncoding:
      return 'Set<int>';
    case listEncoding:
      return 'List<int>';
    case mapEncoding:
      return 'Map<int, String>';
    default:
      return classElement.name;
  }
}

// Types are represented by an instance of `DartType`. For classes, the type
// will be an instance of `InterfaceType`, which will provide access to the
// defining (class) element, as well as any type arguments.
String typeString(DartType type) {
  if (type.isDartCoreBool) {
    return boolEncoding;
  } else if (type.isDartCoreInt) {
    return intEncoding;
  } else if (type.isDartCoreDouble) {
    return doubleEncoding;
  } else if (type.isDartCoreString) {
    return stringEncoding;
  }
  // Supertypes or type parameters are specialized in a consistent manner.
  // TODO(ajcbik): inspect type structure semantically, not by display name
  //               and unify DartFuzz's DartType with analyzer DartType.
  switch (type.displayName) {
    case 'void':
      return voidEncoding;
    case 'E':
      return intEncoding;
    case 'num':
      return doubleEncoding;
    case 'List<E>':
    case 'List<Object>':
    case 'List<dynamic>':
    case 'List<int>':
    case 'List':
      return listEncoding;
    case 'Set<E>':
    case 'Set<Object>':
    case 'Set<dynamic>':
    case 'Set<int>':
    case 'Set':
      return setEncoding;
    case 'Map<K, V>':
    case 'Map<dynamic, dynamic>':
    case 'Map<int, String>':
    case 'Map':
      return mapEncoding;
    // TypedData types.
    case 'Int8List':
      return int8ListEncoding;
    case 'Int16List':
      return int16ListEncoding;
    case 'Int32List':
      return int32ListEncoding;
    // TODO(fizaaluthra): Re-enable Int32x4 after we fix
    // https://github.com/dart-lang/sdk/issues/39520
    // case 'Int32x4':
    //   return int32x4Encoding;
    case 'Int32x4List':
      return int32x4ListEncoding;
    case 'Int64List':
      return int64ListEncoding;
    case 'Float32List':
      return float32ListEncoding;
    case 'Float32x4':
      return float32x4Encoding;
    case 'Float32x4List':
      return float32x4ListEncoding;
    case 'Float64List':
      return float64ListEncoding;
    case 'Float64x2':
      return float64x2Encoding;
    case 'Float64x2List':
      return float64x2ListEncoding;
    case 'Uint8ClampedList':
      return uint8ClampedListEncoding;
    case 'Uint8List':
      return uint8ListEncoding;
    case 'Uint16List':
      return uint16ListEncoding;
    case 'Uint32List':
      return uint32ListEncoding;
    case 'Uint64List':
      return uint64ListEncoding;
  }
  return '?';
}

String protoString(DartType receiver, List<ParameterElement> parameters) {
  var proto = receiver == null ? voidEncoding : typeString(receiver);
  // Construct prototype for non-named parameters.
  for (ParameterElement parameter in parameters) {
    if (!parameter.isNamed) {
      proto += typeString(parameter.type);
    }
  }
  // Use 'void' for an empty parameter list.
  return proto.length == 1 ? proto + voidEncoding : proto;
}

List<DartLib> getTable(String ret) {
  switch (ret) {
    case voidEncoding:
      return voidTable;
    case boolEncoding:
      return boolTable;
    case intEncoding:
      return intTable;
    case doubleEncoding:
      return doubleTable;
    case stringEncoding:
      return stringTable;
    case listEncoding:
      return listTable;
    case setEncoding:
      return setTable;
    case mapEncoding:
      return mapTable;
    // TypedData types.
    case int8ListEncoding:
      return int8ListTable;
    case int16ListEncoding:
      return int16ListTable;
    case int32ListEncoding:
      return int32ListTable;
    case int32x4Encoding:
      return int32x4Table;
    case int32x4ListEncoding:
      return int32x4ListTable;
    case int64ListEncoding:
      return int64ListTable;
    case float32ListEncoding:
      return float32ListTable;
    case float32x4Encoding:
      return float32x4Table;
    case float32x4ListEncoding:
      return float32x4ListTable;
    case float64ListEncoding:
      return float64ListTable;
    case float64x2Encoding:
      return float64x2Table;
    case float64x2ListEncoding:
      return float64x2ListTable;
    case uint8ClampedListEncoding:
      return uint8ClampedListTable;
    case uint8ListEncoding:
      return uint8ListTable;
    case uint16ListEncoding:
      return uint16ListTable;
    case uint32ListEncoding:
      return uint32ListTable;
    case uint64ListEncoding:
      return uint64ListTable;
    default:
      throw ArgumentError('Invalid ret value: $ret');
  }
}

void addToTable(String ret, String name, String proto) {
  // If any of the type representations contains a question
  // mark, this means that DartFuzz' type system cannot
  // deal with such an expression yet. So drop the entry.
  if (ret.contains('?') || proto.contains('?')) {
    return;
  }
  // Avoid the exit function and other functions that give false divergences.
  if (name == 'exit' ||
      name == 'pid' ||
      name == 'hashCode' ||
      name == 'exitCode' ||
      // TODO(fizaaluthra): Enable reciprocal and reciprocalSqrt after we resolve
      // https://github.com/dart-lang/sdk/issues/39551
      name == 'reciprocal' ||
      name == 'reciprocalSqrt') {
    return;
  }
  // Restrict parameters for a few hardcoded cases,
  // for example, to avoid excessive runtime or memory
  // allocation in the generated fuzzing program.
  if (name == 'padLeft' || name == 'padRight') {
    proto = proto.replaceFirst('IS', 'is');
  } else if (name == 'List<int>.filled') {
    proto = proto.replaceFirst(intEncoding, 'i');
  }
  // Add to table.
  getTable(ret).add(DartLib(name, proto));
}

void dumpHeader() {
  print("""
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import \"dartfuzz_type_table.dart\";

/// Class that represents Dart library methods.
///
/// The invididual lists are organized by return type.
/// The proto string has the following format:
///    +-------> receiver type (V denotes none)
///    |+------> param1 type  (V denotes none, v denotes getter)
///    ||+-----> param2 type
///    |||+----> ..
///    ||||
///   'TTTT..'
/// where:
///   V void
///   v void (special)
///   B bool
///   I int
///   i int (small)
///   D double
///   S String
///   s String (small)
///   L List<int>
///   X Set<int>
///   M Map<int, String>
///   A Int8List
///   C Int16List
///   E Int32List
///   F Int32x4
///   G Int32x4List
///   H Int64List
///   J Float32List
///   K Float32x4
///   N Float32x4List
///   O Float64List
///   P Float64x2
///   Q Float64x2List
///   R uint8ClampedList
///   T uint8List
///   U uint16List
///   W uint32List
///   Y uint64List
/// NOTE: this code has been generated automatically.
///
class DartLib {
  final String name;
  final String proto;
  const DartLib(this.name, this.proto);
""");
}

void dumpStringToTypeMap() {
  print('  static const stringToType = {');
  for (var key in stringToType.keys) {
    print('    \'${key}\': ${stringToType[key]},');
  }
  print('  };');
}

void dumpTypeToLibraryMethodMap() {
  print('  static final typeToLibraryMethods = {');
  for (var key in typeToLibraryMethods.keys) {
    print('    ${key}: ${typeToLibraryMethods[key]},');
  }
  print('  };');
}

void dumpTypedDataFloatTypes() {
  print('  static const typedDataFloatTypes = [');
  for (var type in typedDataFloatTypes) {
    print('    \'${type}\',');
  }
  print('  ];');
}

void dumpTable(String identifier, List<DartLib> table) {
  print('  static const $identifier = [');
  table.sort((a, b) => a.name.compareTo(b.name));
  table.forEach((t) => print('    DartLib(\'${t.name}\', \'${t.proto}\'),'));
  print('  ];');
}

void dumpFooter() {
  print('}');
}
