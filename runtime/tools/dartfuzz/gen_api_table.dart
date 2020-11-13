// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

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

// Enum for different restrictions on parameters for library methods.
// none - No restriction on the corresponding parameter.
// small - Corresponding parameter should be a small value.
// This enum has an equivalent enum in the generated Dartfuzz API table.
enum Restriction { none, small }

// Class that represents Dart library methods.
//
// Proto is a list (of Strings that represent DartTypes) whose first element is
// the DartType of the receiver (DartType.VOID if none). The remaining elements
// are DartTypes of the parameters. The second element is DartType.VOID if there
// are no parameters.
// This class has an equivalent class in the generated Dartfuzz API table.
class DartLib {
  final String name;
  final List<String> proto;
  final List<Restriction> restrictions;
  final bool isMethod;
  const DartLib(this.name, this.proto, this.restrictions, this.isMethod);
}

// Constants for strings corresponding to the DartType.
const abstractClassInstantiationErrorEncoding =
    'DartType.ABSTRACTCLASSINSTANTIATIONERROR';
const argumentErrorEncoding = 'DartType.ARGUMENTERROR';
const assertionErrorEncoding = 'DartType.ERROR';
const boolEncoding = 'DartType.BOOL';
const byteDataEncoding = 'DartType.BYTEDATA';
const castErrorEncoding = 'DartType.CASTERROR';
const concurrentModificationErrorEncoding =
    'DartType.CONCURRENTMODIFICATIONERROR';
const cyclicInitializationErrorEncoding = 'DartType.CYCLICINITIALIZATIONERROR';
const deprecatedEncoding = 'DartType.DEPRECATED';
const doubleEncoding = 'DartType.DOUBLE';
const endianEncoding = 'DartType.ENDIAN';
const errorEncoding = 'DartType.ERROR';
const exceptionEncoding = 'DartType.EXCEPTION';
const expandoDoubleEncoding = 'DartType.EXPANDO_DOUBLE';
const expandoIntEncoding = 'DartType.EXPANDO_INT';
const fallThroughErrorEncoding = 'DartType.FALLTHROUGHERROR';
const float32ListEncoding = 'DartType.FLOAT32LIST';
const float32x4Encoding = 'DartType.FLOAT32X4';
const float32x4ListEncoding = 'DartType.FLOAT32X4LIST';
const float64ListEncoding = 'DartType.FLOAT64LIST';
const float64x2Encoding = 'DartType.FLOAT64X2';
const float64x2ListEncoding = 'DartType.FLOAT64X2LIST';
const formatExceptionEncoding = 'DartType.FORMATEXCEPTION';
const indexErrorEncoding = 'DartType.INDEXERROR';
const int16ListEncoding = 'DartType.INT16LIST';
const int32ListEncoding = 'DartType.INT32LIST';
const int32x4Encoding = 'DartType.INT32X4';
const int32x4ListEncoding = 'DartType.INT32X4LIST';
const int64ListEncoding = 'DartType.INT64LIST';
const int8ListEncoding = 'DartType.INT8LIST';
const intEncoding = 'DartType.INT';
const integerDivisionByZeroExceptionEncoding =
    'DartType.INTEGERDIVISIONBYZEROEXCEPTION';
const listIntEncoding = 'DartType.LIST_INT';
const mapEntryIntStringEncoding = 'DartType.MAPENTRY_INT_STRING';
const mapIntStringEncoding = 'DartType.MAP_INT_STRING';
const nullEncoding = 'DartType.NULL';
const nullThrownErrorEncoding = 'DartType.NULLTHROWNERROR';
const numEncoding = 'DartType.NUM';
const provisionalEncoding = 'DartType.PROVISIONAL';
const rangeErrorEncoding = 'DartType.RANGEERROR';
const regExpEncoding = 'DartType.REGEXP';
const runeIteratorEncoding = 'DartType.RUNEITERATOR';
const runesEncoding = 'DartType.RUNES';
const setIntEncoding = 'DartType.SET_INT';
const stackOverflowErrorEncoding = 'DartType.STACKOVERFLOWERROR';
const stateErrorEncoding = 'DartType.STATEERROR';
const stringBufferEncoding = 'DartType.STRINGBUFFER';
const stringEncoding = 'DartType.STRING';
const symbolEncoding = 'DartType.SYMBOL';
const typeErrorEncoding = 'DartType.TYPEERROR';
const uint16ListEncoding = 'DartType.UINT16LIST';
const uint32ListEncoding = 'DartType.UINT32LIST';
const uint64ListEncoding = 'DartType.UINT64LIST';
const uint8ClampedListEncoding = 'DartType.UINT8CLAMPEDLIST';
const uint8ListEncoding = 'DartType.UINT8LIST';
const unimplementedErrorEncoding = 'DartType.UNIMPLEMENTEDERROR';
const unsupportedErrorEncoding = 'DartType.UNSUPPORTEDERROR';
const voidEncoding = 'DartType.VOID';

// Constants for the library methods lists' names in dart_api_table.dart.
final abstractClassInstantiationErrorLibs =
    'abstractClassInstantiationErrorLibs';
final argumentErrorLibs = 'argumentErrorLibs';
final assertionErrorLibs = 'assertionErrorLibs';
final boolLibs = 'boolLibs';
final byteDataLibs = 'byteDataLibs';
final castErrorLibs = 'castErrorLibs';
final concurrentModificationErrorLibs = 'concurrentModificationErrorLibs';
final cyclicInitializationErrorLibs = 'cyclicInitializationErrorLibs';
final deprecatedLibs = 'deprecatedLibs';
final doubleLibs = 'doubleLibs';
final endianLibs = 'endianLibs';
final errorLibs = 'errorLibs';
final exceptionLibs = 'exceptionLibs';
final expandoDoubleLibs = 'expandoDoubleLibs';
final expandoIntLibs = 'expandoIntLibs';
final fallThroughErrorLibs = 'fallThroughErrorLibs';
final float32ListLibs = 'float32ListLibs';
final float32x4Libs = 'float32x4Libs';
final float32x4ListLibs = 'float32x4ListLibs';
final float64ListLibs = 'float64ListLibs';
final float64x2Libs = 'float64x2Libs';
final float64x2ListLibs = 'float64x2ListLibs';
final formatExceptionLibs = 'formatExceptionLibs';
final indexErrorLibs = 'indexErrorLibs';
final int16ListLibs = 'int16ListLibs';
final int32ListLibs = 'int32ListLibs';
final int32x4Libs = 'int32x4Libs';
final int32x4ListLibs = 'int32x4ListLibs';
final int64ListLibs = 'int64ListLibs';
final int8ListLibs = 'int8ListLibs';
final intLibs = 'intLibs';
final integerDivisionByZeroExceptionLibs = 'integerDivisionByZeroExceptionLibs';
final listLibs = 'listLibs';
final mapEntryIntStringLibs = 'mapEntryIntStringLibs';
final mapLibs = 'mapLibs';
final nullLibs = 'nullLibs';
final nullThrownErrorLibs = 'nullThrownErrorLibs';
final numLibs = 'numLibs';
final provisionalLibs = 'provisionalLibs';
final rangeErrorLibs = 'rangeErrorLibs';
final regExpLibs = 'regExpLibs';
final runeIteratorLibs = 'runeIteratorLibs';
final runesLibs = 'runesLibs';
final setLibs = 'setLibs';
final stackOverflowErrorLibs = 'stackOverflowErrorLibs';
final stateErrorLibs = 'stateErrorLibs';
final stringBufferLibs = 'stringBufferLibs';
final stringLibs = 'stringLibs';
final symbolLibs = 'symbolLibs';
final typeErrorLibs = 'typeErrorLibs';
final uint16ListLibs = 'uint16ListLibs';
final uint32ListLibs = 'uint32ListLibs';
final uint64ListLibs = 'uint64ListLibs';
final uint8ClampedListLibs = 'uint8ClampedListLibs';
final uint8ListLibs = 'uint8ListLibs';
final unimplementedErrorLibs = 'unimplementedErrorLibs';
final unsupportedErrorLibs = 'unsupportedErrorLibs';
final voidLibs = 'voidLibs';

// Map from the DartType (string) to the name of the library methods list.
final Map<String, String> typeToLibraryMethodsListName = {
  abstractClassInstantiationErrorEncoding: abstractClassInstantiationErrorLibs,
  argumentErrorEncoding: argumentErrorLibs,
  assertionErrorEncoding: assertionErrorLibs,
  boolEncoding: boolLibs,
  byteDataEncoding: byteDataLibs,
  castErrorEncoding: castErrorLibs,
  concurrentModificationErrorEncoding: concurrentModificationErrorLibs,
  cyclicInitializationErrorEncoding: cyclicInitializationErrorLibs,
  deprecatedEncoding: deprecatedLibs,
  doubleEncoding: doubleLibs,
  endianEncoding: endianLibs,
  errorEncoding: errorLibs,
  exceptionEncoding: exceptionLibs,
  expandoDoubleEncoding: expandoDoubleLibs,
  expandoIntEncoding: expandoIntLibs,
  fallThroughErrorEncoding: fallThroughErrorLibs,
  float32ListEncoding: float32ListLibs,
  float32x4Encoding: float32x4Libs,
  float32x4ListEncoding: float32x4ListLibs,
  float64ListEncoding: float64ListLibs,
  float64x2Encoding: float64x2Libs,
  float64x2ListEncoding: float64x2ListLibs,
  formatExceptionEncoding: formatExceptionLibs,
  indexErrorEncoding: indexErrorLibs,
  int16ListEncoding: int16ListLibs,
  int32ListEncoding: int32ListLibs,
  int32x4Encoding: int32x4Libs,
  int32x4ListEncoding: int32x4ListLibs,
  int64ListEncoding: int64ListLibs,
  int8ListEncoding: int8ListLibs,
  intEncoding: intLibs,
  integerDivisionByZeroExceptionEncoding: integerDivisionByZeroExceptionLibs,
  listIntEncoding: listLibs,
  mapEntryIntStringEncoding: mapEntryIntStringLibs,
  mapIntStringEncoding: mapLibs,
  nullEncoding: nullLibs,
  nullThrownErrorEncoding: nullThrownErrorLibs,
  numEncoding: numLibs,
  provisionalEncoding: provisionalLibs,
  rangeErrorEncoding: rangeErrorLibs,
  regExpEncoding: regExpLibs,
  runeIteratorEncoding: runeIteratorLibs,
  runesEncoding: runesLibs,
  setIntEncoding: setLibs,
  stackOverflowErrorEncoding: stackOverflowErrorLibs,
  stateErrorEncoding: stateErrorLibs,
  stringBufferEncoding: stringBufferLibs,
  stringEncoding: stringLibs,
  stringEncoding: stringLibs,
  symbolEncoding: symbolLibs,
  typeErrorEncoding: typeErrorLibs,
  uint16ListEncoding: uint16ListLibs,
  uint32ListEncoding: uint32ListLibs,
  uint64ListEncoding: uint64ListLibs,
  uint8ClampedListEncoding: uint8ClampedListLibs,
  uint8ListEncoding: uint8ListLibs,
  unimplementedErrorEncoding: unimplementedErrorLibs,
  unsupportedErrorEncoding: unsupportedErrorLibs,
  voidEncoding: voidLibs
};

// Map from return type encoding to list of recognized methods with that
// return type.
final Map<String, List<DartLib>> typeToLibraryMethodsList = {
  abstractClassInstantiationErrorEncoding: <DartLib>[],
  argumentErrorEncoding: <DartLib>[],
  assertionErrorEncoding: <DartLib>[],
  boolEncoding: <DartLib>[],
  byteDataEncoding: <DartLib>[],
  castErrorEncoding: <DartLib>[],
  concurrentModificationErrorEncoding: <DartLib>[],
  cyclicInitializationErrorEncoding: <DartLib>[],
  deprecatedEncoding: <DartLib>[],
  doubleEncoding: <DartLib>[],
  endianEncoding: <DartLib>[],
  errorEncoding: <DartLib>[],
  exceptionEncoding: <DartLib>[],
  expandoDoubleEncoding: <DartLib>[],
  expandoIntEncoding: <DartLib>[],
  fallThroughErrorEncoding: <DartLib>[],
  float32ListEncoding: <DartLib>[],
  float32x4Encoding: <DartLib>[],
  float32x4ListEncoding: <DartLib>[],
  float64ListEncoding: <DartLib>[],
  float64x2Encoding: <DartLib>[],
  float64x2ListEncoding: <DartLib>[],
  formatExceptionEncoding: <DartLib>[],
  indexErrorEncoding: <DartLib>[],
  int16ListEncoding: <DartLib>[],
  int32ListEncoding: <DartLib>[],
  int32x4Encoding: <DartLib>[],
  int32x4ListEncoding: <DartLib>[],
  int64ListEncoding: <DartLib>[],
  int8ListEncoding: <DartLib>[],
  intEncoding: <DartLib>[],
  integerDivisionByZeroExceptionEncoding: <DartLib>[],
  listIntEncoding: <DartLib>[],
  mapEntryIntStringEncoding: <DartLib>[],
  mapIntStringEncoding: <DartLib>[],
  nullEncoding: <DartLib>[],
  nullThrownErrorEncoding: <DartLib>[],
  numEncoding: <DartLib>[],
  provisionalEncoding: <DartLib>[],
  rangeErrorEncoding: <DartLib>[],
  regExpEncoding: <DartLib>[],
  runeIteratorEncoding: <DartLib>[],
  runesEncoding: <DartLib>[],
  setIntEncoding: <DartLib>[],
  stackOverflowErrorEncoding: <DartLib>[],
  stateErrorEncoding: <DartLib>[],
  stringBufferEncoding: <DartLib>[],
  stringEncoding: <DartLib>[],
  symbolEncoding: <DartLib>[],
  typeErrorEncoding: <DartLib>[],
  uint16ListEncoding: <DartLib>[],
  uint32ListEncoding: <DartLib>[],
  uint64ListEncoding: <DartLib>[],
  uint8ClampedListEncoding: <DartLib>[],
  uint8ListEncoding: <DartLib>[],
  unimplementedErrorEncoding: <DartLib>[],
  unsupportedErrorEncoding: <DartLib>[],
  voidEncoding: <DartLib>[]
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
  dumpTypeToLibraryMethodMap();
  dumpTypedDataFloatTypes();
  for (var key in typeToLibraryMethodsList.keys.toList()..sort()) {
    if (typeToLibraryMethodsList[key].isNotEmpty) {
      // Only output library methods lists that are non-empty.
      dumpTable(
          typeToLibraryMethodsListName[key], typeToLibraryMethodsList[key]);
    }
  }
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
      addToTable(typeString(variable.type), variable.name,
          [voidEncoding, voidEncoding],
          isMethod: false);
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
        addToTable(
            typeString(variable.type),
            '${classElement.name}.${variable.name}',
            [voidEncoding, voidEncoding],
            isMethod: false);
      } else {
        addToTable(typeString(variable.type), variable.name,
            [typeString(classElement.thisType), voidEncoding],
            isMethod: false);
      }
    }
  }
}

// Function that returns the explicit class name.
String classString(ClassElement classElement) {
  switch (typeString(classElement.thisType)) {
    case setIntEncoding:
      return 'Set<int>';
    case listIntEncoding:
      return 'List<int>';
    case mapIntStringEncoding:
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
    case 'AbstractClassInstantiationError':
      return abstractClassInstantiationErrorEncoding;
    case 'ArgumentError':
      return argumentErrorEncoding;
    case 'AssertionError':
      return assertionErrorEncoding;
    case 'CastError':
      return castErrorEncoding;
    case 'ConcurrentModificationError':
      return concurrentModificationErrorEncoding;
    case 'CyclicInitializationError':
      return cyclicInitializationErrorEncoding;
    case 'Deprecated':
      return deprecatedEncoding;
    case 'E':
      return intEncoding;
    case 'Endian':
      return endianEncoding;
    case 'Error':
      return errorEncoding;
    case 'Exception':
      return exceptionEncoding;
    case 'Expando<double>':
      return expandoDoubleEncoding;
    case 'Expando<int>':
      return expandoIntEncoding;
    case 'FallThroughError':
      return fallThroughErrorEncoding;
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
    case 'FormatException':
      return formatExceptionEncoding;
    case 'IndexError':
      return indexErrorEncoding;
    case 'Int16List':
      return int16ListEncoding;
    case 'Int32List':
      return int32ListEncoding;
    case 'Int32x4':
      return int32x4Encoding;
    case 'Int32x4List':
      return int32x4ListEncoding;
    case 'Int64List':
      return int64ListEncoding;
    case 'Int8List':
      return int8ListEncoding;
    case 'IntegerDivisionByZeroException':
      return integerDivisionByZeroExceptionEncoding;
    case 'List':
    case 'List<E>':
    case 'List<Object>':
    case 'List<dynamic>':
    case 'List<int>':
      return listIntEncoding;
    case 'Map':
    case 'Map<K, V>':
    case 'Map<dynamic, dynamic>':
    case 'Map<int, String>':
      return mapIntStringEncoding;
    case 'MapEntry':
    case 'MapEntry<K, V>':
    case 'MapEntry<dynamic, dynamic>':
    case 'MapEntry<int, String>':
      return mapEntryIntStringEncoding;
    case 'Null':
      return nullEncoding;
    case 'NullThrownError':
      return nullThrownErrorEncoding;
    case 'Provisional':
      return provisionalEncoding;
    case 'RangeError':
      return rangeErrorEncoding;
    case 'RegExp':
      return regExpEncoding;
    case 'RuneIterator':
      return runeIteratorEncoding;
    case 'Runes':
      return runesEncoding;
    case 'Set':
    case 'Set<E>':
    case 'Set<Object>':
    case 'Set<dynamic>':
    case 'Set<int>':
      return setIntEncoding;
    case 'StackOverflowError':
      return stackOverflowErrorEncoding;
    case 'StateError':
      return stateErrorEncoding;
    case 'StringBuffer':
      return stringBufferEncoding;
    case 'Symbol':
      return symbolEncoding;
    case 'TypeError':
      return typeErrorEncoding;
    case 'Uint16List':
      return uint16ListEncoding;
    case 'Uint32List':
      return uint32ListEncoding;
    case 'Uint64List':
      return uint64ListEncoding;
    case 'Uint8ClampedList':
      return uint8ClampedListEncoding;
    case 'Uint8List':
      return uint8ListEncoding;
    case 'UnimplementedError':
      return unimplementedErrorEncoding;
    case 'UnsupportedError':
      return unsupportedErrorEncoding;
    case 'num':
      return doubleEncoding;
    case 'void':
      return voidEncoding;
  }
  return '?';
}

List<String> protoString(DartType receiver, List<ParameterElement> parameters) {
  final proto = [receiver == null ? voidEncoding : typeString(receiver)];
  // Construct prototype for non-named parameters.
  for (ParameterElement parameter in parameters) {
    if (!parameter.isNamed) {
      proto.add(typeString(parameter.type));
    }
  }
  // Use 'void' for an empty parameter list.
  proto.length == 1 ? proto.add(voidEncoding) : proto;
  return proto;
}

List<DartLib> getTable(String ret) => typeToLibraryMethodsList.containsKey(ret)
    ? typeToLibraryMethodsList[ret]
    : throw ArgumentError('Invalid ret value: $ret');

void addToTable(String ret, String name, List<String> proto,
    {bool isMethod = true}) {
  // If any of the type representations contains a question
  // mark, this means that DartFuzz' type system cannot
  // deal with such an expression yet. So drop the entry.
  if (ret.contains('?') || proto.contains('?')) {
    return;
  }
  // Avoid the exit function and other functions that give false divergences.
  // Note: to prevent certain constructors from being emitted, update the
  // exclude list in `shouldFilterConstructor` in gen_type_table.dart and
  // regenerate the type table.
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

  List<Restriction> restrictions;
  // Restrict parameters for a few hardcoded cases,
  // for example, to avoid excessive runtime or memory
  // allocation in the generated fuzzing program.
  if (name == 'padLeft' || name == 'padRight') {
    for (int i = 0; i < proto.length - 1; ++i) {
      if (proto[i] == intEncoding && proto[i + 1] == stringEncoding) {
        restrictions = List<Restriction>.filled(proto.length, Restriction.none);
        restrictions[i] = Restriction.small;
        restrictions[i + 1] = Restriction.small;
        break;
      }
    }
  } else if (name == 'List<int>.filled') {
    for (int i = 0; i < proto.length; ++i) {
      if (proto[i] == intEncoding) {
        restrictions = List<Restriction>.filled(proto.length, Restriction.none);
        restrictions[i] = Restriction.small;
        break;
      }
    }
  }
  // Add to table.
  getTable(ret).add(DartLib(name, proto, restrictions, isMethod));
}

void dumpHeader() {
  print("""
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/// NOTE: this code has been generated automatically.

import \"dartfuzz_type_table.dart\";

/// Enum for different restrictions on parameters for library methods.
/// none - No restriction on the corresponding parameter.
/// small - Corresponding parameter should be a small value.
enum Restriction {
  none,
  small
}

/// Class that represents Dart library methods.
///
/// The invididual lists are organized by return type.
/// Proto is a list of DartTypes whose first element is the type of the
/// DartType of the receiver (DartType.VOID if none). The remaining elements are
/// DartTypes of the parameters. The second element is DartType.VOID if there
/// are no parameters.
class DartLib {
  final String name;
  final List<DartType> proto;
  final List<Restriction> restrictions;
  final bool isMethod;
  const DartLib(this.name, this.proto, this.isMethod,
  {this.restrictions});
  Restriction getRestriction(int paramIndex) => (restrictions == null) ?
  Restriction.none : restrictions[paramIndex];
""");
}

void dumpTypeToLibraryMethodMap() {
  print('  static final typeToLibraryMethods = {');
  for (var key in typeToLibraryMethodsListName.keys.toList()..sort()) {
    if (typeToLibraryMethodsList[key].isNotEmpty) {
      // Only output a mapping from type to library methods list name for those
      // types that have a non-empty library methods list.
      print('    ${key}: ${typeToLibraryMethodsListName[key]},');
    }
  }
  print('  };');
}

void dumpTypedDataFloatTypes() {
  print('  static const typedDataFloatTypes = [');
  for (var type in typedDataFloatTypes) {
    print('    ${type},');
  }
  print('  ];');
}

void dumpTable(String identifier, List<DartLib> table) {
  print('  static const $identifier = [');
  table.sort((a, b) => (a.name.compareTo(b.name) == 0)
      ? a.proto.join().compareTo(b.proto.join())
      : a.name.compareTo(b.name));
  table.forEach(
      (t) => print('    DartLib(\'${t.name}\', ${t.proto}, ${t.isMethod}'
          '${t.restrictions == null ? "" : ", "
              "restrictions: ${t.restrictions}"}),'));
  print('  ];');
}

void dumpFooter() {
  print('}');
}
