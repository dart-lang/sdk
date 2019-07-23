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

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';

// Class to represent a library method by name and prototype representation.
class DartLib {
  final String name;
  final String proto;
  const DartLib(this.name, this.proto);
}

// Lists of recognized methods, organized by return type.
var boolTable = List<DartLib>();
var intTable = List<DartLib>();
var doubleTable = List<DartLib>();
var stringTable = List<DartLib>();
var listTable = List<DartLib>();
var setTable = List<DartLib>();
var mapTable = List<DartLib>();

main() async {
  // Set paths. Note that for this particular use case, packageRoot can be
  // any directory. Here, we set it to the top of the SDK development, and
  // derive the required sdkPath from there.
  String packageRoot = Platform.environment['DART_TOP'];
  if (packageRoot == null) {
    throw new StateError('No environment variable DART_TOP');
  }
  String sdkPath = '$packageRoot/tools/sdks/dart-sdk';

  // This does most of the hard work of getting the analyzer configured
  // correctly. Typically the included paths are the files and directories
  // that need to be analyzed, but the SDK is always available, so it isn't
  // really important for this particular use case. We use the implementation
  // class in order to pass in the sdkPath directly.
  PhysicalResourceProvider provider = PhysicalResourceProvider.INSTANCE;
  AnalysisContextCollection collection = new AnalysisContextCollectionImpl(
      includedPaths: <String>[packageRoot],
      resourceProvider: provider,
      sdkPath: sdkPath);
  AnalysisSession session = collection.contexts[0].currentSession;

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
  dumpTable('boolLibs', boolTable);
  dumpTable('intLibs', intTable);
  dumpTable('doubleLibs', doubleTable);
  dumpTable('stringLibs', stringTable);
  dumpTable('listLibs', listTable);
  dumpTable('setLibs', setTable);
  dumpTable('mapLibs', mapTable);
  dumpFooter();
}

visitLibraryAtUri(AnalysisSession session, String uri) async {
  String libPath = session.uriConverter.uriToPath(Uri.parse(uri));
  ResolvedLibraryResult result = await session.getResolvedLibrary(libPath);
  if (result.state != ResultState.VALID) {
    throw new StateError('Unable to resolve "$uri"');
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
  if (classElement.name == 'ProcessInfo' || classElement.name == 'Platform') {
    return;
  }
  // Every class element contains elements for the members, viz. `methods` visits
  // methods, `fields` visits fields, `accessors` visits getters and setters, etc.
  // There are also accessors to get the superclass, mixins, interfaces, type
  // parameters, etc.
  for (ConstructorElement constructor in classElement.constructors) {
    if (constructor.isPublic &&
        constructor.isFactory &&
        !constructor.name.isEmpty) {
      addToTable(
          typeString(classElement.type),
          '${classElement.name}.${constructor.name}',
          protoString(null, constructor.parameters));
    }
  }
  for (MethodElement method in classElement.methods) {
    if (method.isPublic && !method.isOperator) {
      if (method.isStatic) {
        addToTable(
            typeString(method.returnType),
            '${classElement.name}.${method.name}',
            protoString(null, method.parameters));
      } else {
        addToTable(typeString(method.returnType), method.name,
            protoString(classElement.type, method.parameters));
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
            '${typeString(classElement.type)}v');
      }
    }
  }
}

// Types are represented by an instance of `DartType`. For classes, the type
// will be an instance of `InterfaceType`, which will provide access to the
// defining (class) element, as well as any type arguments.
String typeString(DartType type) {
  if (type.isDartCoreBool) {
    return 'B';
  } else if (type.isDartCoreInt) {
    return 'I';
  } else if (type.isDartCoreDouble) {
    return 'D';
  } else if (type.isDartCoreString) {
    return 'S';
  }
  // Supertypes or type parameters are specialized in a consistent manner.
  // TODO(ajcbik): inspect type structure semantically, not by display name
  //               and unify DartFuzz's DartType with analyzer DartType.
  switch (type.displayName) {
    case 'E':
      return 'I';
    case 'num':
      return 'D';
    case 'List<E>':
    case 'List<Object>':
    case 'List<dynamic>':
    case 'List<int>':
    case 'List':
      return 'L';
    case 'Set<E>':
    case 'Set<Object>':
    case 'Set<dynamic>':
    case 'Set<int>':
    case 'Set':
      return 'X';
    case 'Map<K, V>':
    case 'Map<dynamic, dynamic>':
    case 'Map<int, String>':
    case 'Map':
      return 'M';
  }
  return '?';
}

String protoString(DartType receiver, List<ParameterElement> parameters) {
  var proto = receiver == null ? 'V' : typeString(receiver);
  // Construct prototype for non-named parameters.
  for (ParameterElement parameter in parameters) {
    if (!parameter.isNamed) {
      proto += typeString(parameter.type);
    }
  }
  // Use 'void' for an empty parameter list.
  return proto.length == 1 ? proto + 'V' : proto;
}

List<DartLib> getTable(String ret) {
  switch (ret) {
    case 'B':
      return boolTable;
    case 'I':
      return intTable;
    case 'D':
      return doubleTable;
    case 'S':
      return stringTable;
    case 'L':
      return listTable;
    case 'X':
      return setTable;
    case 'M':
      return mapTable;
  }
}

void addToTable(String ret, String name, String proto) {
  // If any of the type representations contains a question
  // mark, this means that DartFuzz' type system cannot
  // deal with such an expression yet. So drop the entry.
  if (ret.contains('?') || proto.contains('?')) {
    return;
  }
  // Avoid some obvious false divergences.
  if (name == 'pid' ||
      name == 'hashCode' ||
      name == 'Platform.executable' ||
      name == 'Platform.resolvedExecutable') {
    return;
  }
  // Restrict parameters for a few hardcoded cases,
  // for example, to avoid excessive runtime or memory
  // allocation in the generated fuzzing program.
  if (name == 'padLeft' || name == 'padRight') {
    proto = proto.replaceFirst('IS', 'is');
  } else if (name == 'List.filled') {
    proto = proto.replaceFirst('I', 'i');
  }
  // Add to table.
  getTable(ret).add(DartLib(name, proto));
}

void dumpHeader() {
  print("""
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
///
/// NOTE: this code has been generated automatically.
///
class DartLib {
  final String name;
  final String proto;
  const DartLib(this.name, this.proto);
""");
}

void dumpTable(String identifier, List<DartLib> table) {
  print('  static const $identifier = [');
  table.forEach((t) => print('    DartLib(\'${t.name}\', \'${t.proto}\'),'));
  print('  ];');
}

void dumpFooter() {
  print('}');
}
