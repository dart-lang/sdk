// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

// By convention:
//
//   T: generic type of typedef.
//   A: generic type of returned function.
//   B: generic type of function.
//
// Example:
//    typedef F<T>: Function<A> Function<B>();
//
// We only use: Function, List, int (and function types).
// We import 'dart:core' directly and with prefix 'core'.

abstract class Printable {
  /// Builds a descriptive string that can be used as an identifier.
  ///
  /// The string is mainly used for disambiguation, and not for its readability.
  void writeIdentifier(StringBuffer buffer);
}

abstract class TypeLike implements Printable {
  /// Prints `this` as valid Dart code for a Type.
  void writeType(StringBuffer buffer);

  /// Whether this instance uses T in some way.
  bool get usesT;
}

/// Provides a unique integer for every parameter in a function.
int parameterNameCounter = 0;

/// Whether `T` should be replaced with `int`.
bool shouldReplaceTWithInt = false;

class Parameter implements Printable {
  final TypeLike type;
  final String name;

  Parameter(this.type, this.name);

  // Type or name can be null.
  @override
  writeIdentifier(buffer) {
    if (type == null) {
      buffer.write("null");
    } else {
      type.writeIdentifier(buffer);
    }
    buffer.write("_");
    buffer.write(name);
  }

  void writeType(StringBuffer buffer) {
    assert(type != null || name != null);
    if (name == null) {
      type.writeType(buffer);
    } else if (type == null) {
      buffer.write(name);
    } else {
      type.writeType(buffer);
      buffer.write(" ");
      buffer.write(name);
    }
  }

  void writeInFunction(StringBuffer buffer) {
    assert(type != null || name != null);
    if (name == null) {
      type.writeType(buffer);
      buffer.write(" x");
      buffer.write(parameterNameCounter++);
    } else if (type == null) {
      buffer.write(name);
    } else {
      type.writeType(buffer);
      buffer.write(" ");
      buffer.write(name);
    }
  }

  bool operator ==(other) {
    return other is Parameter && name == other.name && type == other.type;
  }

  int get hashCode {
    return ((name.hashCode * 37) ^ type.hashCode) & 0xFFFFFFFF;
  }

  bool get usesT => type?.usesT == true;
}

class GenericParameter implements TypeLike {
  final String name;
  final TypeLike bound;

  GenericParameter(this.name, [this.bound]);

  // Bound may be null.
  @override
  writeIdentifier(buffer) {
    buffer.write(name);
    buffer.write("_");
    if (bound == null) {
      buffer.write("null");
    } else {
      bound.writeIdentifier(buffer);
    }
  }

  @override
  writeType(buffer) {
    buffer.write(name);
    if (bound != null) {
      buffer.write(" extends ");
      bound.writeType(buffer);
    }
  }

  bool operator ==(other) {
    return other is GenericParameter &&
        name == other.name &&
        bound == other.bound;
  }

  int get hashCode {
    return ((name.hashCode * 23) ^ bound.hashCode) & 0xFFFFFFFF;
  }

  bool get usesT {
    return bound?.usesT == true;
  }
}

void _describeList(StringBuffer buffer, List<Printable> list) {
  if (list == null) {
    buffer.write("0");
    return;
  }
  buffer.write(list.length.toString());
  buffer.write("_");
  for (int i = 0; i < list.length; i++) {
    if (i != 0) buffer.write("_");
    list[i].writeIdentifier(buffer);
  }
}

void _writeTypes(StringBuffer buffer, List<TypeLike> list,
    [String prefix = "", String postfix = ""]) {
  if (list == null || list.isEmpty) return;
  buffer.write(prefix);
  for (int i = 0; i < list.length; i++) {
    if (i != 0) buffer.write(", ");
    list[i].writeType(buffer);
  }
  buffer.write(postfix);
}

void _writeParameters(
    StringBuffer buffer, List<Parameter> list, bool inFunction,
    [String prefix = "", String postfix = ""]) {
  if (list == null || list.isEmpty) return;
  buffer.write(prefix);
  for (int i = 0; i < list.length; i++) {
    if (i != 0) buffer.write(", ");
    if (inFunction) {
      list[i].writeInFunction(buffer);
    } else {
      list[i].writeType(buffer);
    }
  }
  buffer.write(postfix);
}

bool _listUsesT(List elements) {
  if (elements == null) return false;
  return elements.any((p) => p.usesT);
}

bool _listEquals(List list1, List list2) {
  if (list1 == list2) return true; // Also covers both being null.
  if (list1 == null || list2 == null) return false;
  for (int i = 0; i < list1.length; i++) {
    if (list1[i] != list2[i]) return false;
  }
  return true;
}

int _listHash(List list) {
  if (list == null) return null.hashCode;
  int result = 71;
  for (int i = 0; i < list.length; i++) {
    result = ((result * 11) ^ list[i].hashCode) & 0xFFFFFFFF;
  }
  return result;
}

class FunctionType implements TypeLike {
  final TypeLike returnType;
  final List<GenericParameter> generic;
  final List<Parameter> required;
  final List<Parameter> optional;
  final List<Parameter> named;

  FunctionType(this.returnType, this.generic, this.required,
      [this.optional, this.named]);

  @override
  writeIdentifier(buffer) {
    buffer.write("Fun_");
    if (returnType == null) {
      buffer.write("null");
    } else {
      returnType.writeIdentifier(buffer);
    }
    buffer.write("_");
    _describeList(buffer, generic);
    buffer.write("_");
    _describeList(buffer, required);
    buffer.write("_");
    _describeList(buffer, optional);
    buffer.write("_");
    _describeList(buffer, named);
  }

  @override
  writeType(buffer) {
    if (returnType != null) {
      returnType.writeType(buffer);
      buffer.write(" ");
    }
    buffer.write("Function");
    if (generic != null) _writeTypes(buffer, generic, "<", ">");
    buffer.write("(");
    bool notInFunction = true;
    _writeParameters(buffer, required, notInFunction);
    if ((optional != null || named != null) &&
        required != null &&
        required.isNotEmpty) {
      buffer.write(", ");
    }
    _writeParameters(buffer, optional, notInFunction, "[", "]");
    _writeParameters(buffer, named, notInFunction, "{", "}");
    buffer.write(")");
  }

  /// Writes this type as if it was a function.
  void writeFunction(StringBuffer buffer, String name, {bool replaceT: true}) {
    shouldReplaceTWithInt = replaceT;
    parameterNameCounter = 0;

    if (returnType != null) {
      returnType.writeType(buffer);
      buffer.write(" ");
    }

    buffer.write(name);
    if (generic != null) _writeTypes(buffer, generic, "<", ">");
    buffer.write("(");
    bool inFunction = true;
    _writeParameters(buffer, required, inFunction);
    if ((optional != null || named != null) &&
        required != null &&
        required.isNotEmpty) {
      buffer.write(", ");
    }
    _writeParameters(buffer, optional, inFunction, "[", "]");
    _writeParameters(buffer, named, inFunction, "{", "}");
    buffer.write(") => null;");

    shouldReplaceTWithInt = false;
  }

  bool operator ==(other) {
    return returnType == other.returnType &&
        _listEquals(generic, other.generic) &&
        _listEquals(required, other.required) &&
        _listEquals(optional, other.optional) &&
        _listEquals(named, other.named);
  }

  int get hashCode {
    return ((returnType.hashCode * 13) ^
            (_listHash(generic) * 17) ^
            (_listHash(required) * 53) ^
            (_listHash(optional) ^ 31) ^
            (_listHash(named) * 87)) &
        0xFFFFFFFF;
  }

  bool get usesT {
    return returnType?.usesT == true ||
        [generic, required, optional, named].any(_listUsesT);
  }
}

class NominalType implements TypeLike {
  final String prefix;
  final String name;
  final List<TypeLike> generic;

  NominalType(this.name, [this.prefix, this.generic]);

  @override
  writeIdentifier(buffer) {
    buffer.write(prefix);
    buffer.write("_");
    buffer.write(name);
    _describeList(buffer, generic);
  }

  @override
  writeType(buffer) {
    if (prefix != null && prefix != "") {
      buffer.write(prefix);
      buffer.write(".");
    }
    if (shouldReplaceTWithInt && name == "T") {
      buffer.write("int");
    } else {
      buffer.write(name);
    }
    _writeTypes(buffer, generic, "<", ">");
  }

  bool operator ==(other) {
    return other is NominalType && prefix == other.prefix && name == other.name;
  }

  int get hashCode {
    return ((prefix.hashCode * 37) ^ name.hashCode) & 0xFFFFFFFF;
  }

  bool get usesT => name == "T" || _listUsesT(generic);
}

List<FunctionType> buildFunctionTypes() {
  List<GenericParameter> as = [
    new GenericParameter("A"),
    // new GenericParameter("A", new NominalType("int")),
    // new GenericParameter("A", new NominalType("int", "core")),
  ];
  List<GenericParameter> bs = [
    // new GenericParameter("B"),
    // new GenericParameter("B", new NominalType("int")),
    new GenericParameter("B", new NominalType("int", "core")),
  ];
  List<TypeLike> basicTypes = [
    new NominalType("int"),
    // new NominalType("int", "core"),
    // new NominalType("List"),
    // new NominalType("List", "core"),
    new NominalType("Function"),
    new NominalType("List", "", [new NominalType("Function")]),
    new NominalType("List", "core", [new NominalType("int", "core")]),
    new NominalType("List", "", [new NominalType("T")]),
    // new NominalType("List", "", [new NominalType("Function")]),
  ];

  List<TypeLike> basicsPlusNull = [
    basicTypes,
    <TypeLike>[null]
  ].expand((x) => x).toList();

  List<TypeLike> basicsPlusNullPlusVoid = [
    basicsPlusNull,
    [new NominalType("void")],
  ].expand((x) => x).toList();

  List<TypeLike> basicsPlusNullPlusB = [
    basicsPlusNull,
    [
      new NominalType("B"),
      new NominalType("List", "", [new NominalType("B")])
    ]
  ].expand((x) => x).toList();

  List<TypeLike> basicsPlusNullPlusBPlusVoid = [
    basicsPlusNullPlusB,
    [new NominalType("void")],
  ].expand((x) => x).toList();

  List<TypeLike> basicsPlusNullPlusA = [
    basicsPlusNull,
    [
      new NominalType("A"),
      new NominalType("List", "", [new NominalType("A")])
    ]
  ].expand((x) => x).toList();

  List<TypeLike> basicsPlusNullPlusAPlusVoid = [
    basicsPlusNullPlusA,
    [new NominalType("void")],
  ].expand((x) => x).toList();

  List<TypeLike> buildFunctionTypes(TypeLike returnType, TypeLike parameterType,
      [List<GenericParameter> generics,
      bool generateMoreCombinations = false]) {
    List<TypeLike> result = [];

    if (parameterType == null) {
      // int Function().
      result.add(new FunctionType(returnType, generics, null));
      return result;
    }

    // int Function(int x).
    result.add(new FunctionType(
        returnType, generics, [new Parameter(parameterType, "x")]));

    if (!generateMoreCombinations) return result;

    // int Function([int x]).
    result.add(new FunctionType(
        returnType, generics, null, [new Parameter(parameterType, "x")]));
    // int Function(int, [int x])
    result.add(new FunctionType(
        returnType,
        generics,
        [new Parameter(new NominalType("int"), null)],
        [new Parameter(parameterType, "x")]));
    // int Function(int x, [int x])
    result.add(new FunctionType(
        returnType,
        generics,
        [new Parameter(new NominalType("int"), "y")],
        [new Parameter(parameterType, "x")]));
    // int Function(int);
    result.add(new FunctionType(
        returnType, generics, [new Parameter(parameterType, null)]));
    // int Function([int]);
    result.add(new FunctionType(
        returnType, generics, null, [new Parameter(parameterType, null)]));
    // int Function(int, [int])
    result.add(new FunctionType(
        returnType,
        generics,
        [new Parameter(new NominalType("int"), null)],
        [new Parameter(parameterType, null)]));
    // int Function(int x, [int])
    result.add(new FunctionType(
        returnType,
        generics,
        [new Parameter(new NominalType("int"), "x")],
        [new Parameter(parameterType, null)]));
    // int Function({int x}).
    result.add(new FunctionType(
        returnType, generics, null, null, [new Parameter(parameterType, "x")]));
    // int Function(int, {int x})
    result.add(new FunctionType(
        returnType,
        generics,
        [new Parameter(new NominalType("int"), null)],
        null,
        [new Parameter(parameterType, "x")]));
    // int Function(int x, {int x})
    result.add(new FunctionType(
        returnType,
        generics,
        [new Parameter(new NominalType("int"), "y")],
        null,
        [new Parameter(parameterType, "x")]));
    return result;
  }

  // The "smaller" function types. May also be used non-nested.
  List<TypeLike> functionTypes = [];

  for (TypeLike returnType in basicsPlusNullPlusVoid) {
    for (TypeLike parameterType in basicsPlusNull) {
      bool generateMoreCombinations = true;
      functionTypes.addAll(buildFunctionTypes(
          returnType, parameterType, null, generateMoreCombinations));
    }
  }

  // These use `B` from the generic type of the enclosing function.
  List<TypeLike> returnFunctionTypesB = [];
  for (TypeLike returnType in basicsPlusNullPlusBPlusVoid) {
    TypeLike parameterType = new NominalType("B");
    returnFunctionTypesB.addAll(buildFunctionTypes(returnType, parameterType));
  }
  for (TypeLike parameterType in basicsPlusNull) {
    TypeLike returnType = new NominalType("B");
    returnFunctionTypesB.addAll(buildFunctionTypes(returnType, parameterType));
  }

  for (TypeLike returnType in basicsPlusNullPlusAPlusVoid) {
    for (TypeLike parameterType in basicsPlusNullPlusA) {
      for (GenericParameter a in as) {
        functionTypes
            .addAll(buildFunctionTypes(returnType, parameterType, [a]));
      }
    }
  }

  List<TypeLike> types = [];
  types.addAll(functionTypes);

  // Now add some higher-order function types.
  for (TypeLike returnType in functionTypes) {
    types.addAll(buildFunctionTypes(returnType, null));
    types.addAll(buildFunctionTypes(returnType, new NominalType("int")));
    for (var b in bs) {
      types.addAll(buildFunctionTypes(returnType, null, [b]));
      types.addAll(buildFunctionTypes(returnType, new NominalType("int"), [b]));
    }
  }
  for (TypeLike returnType in returnFunctionTypesB) {
    for (var b in bs) {
      types.addAll(buildFunctionTypes(returnType, null, [b]));
      types.addAll(buildFunctionTypes(returnType, new NominalType("int"), [b]));
    }
  }

  return types;
}

final String HEADER = """
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// GENERATED - DON'T EDIT.
// GENERATED - DON'T EDIT.
// GENERATED - DON'T EDIT.
// GENERATED - DON'T EDIT.
// GENERATED - DON'T EDIT.
// GENERATED - DON'T EDIT.
// GENERATED - DON'T EDIT.
// GENERATED - DON'T EDIT.

import 'dart:core';
import 'dart:core' as core;
import 'package:expect/expect.dart';

@NoInline()
@AssumeDynamic()
confuse(f) => f;
""";

class Unit {
  int typeCounter = 0;
  final String name;
  final StringBuffer typedefs = new StringBuffer();
  final StringBuffer globals = new StringBuffer();
  final StringBuffer tests = new StringBuffer();
  final StringBuffer fields = new StringBuffer();
  final StringBuffer statics = new StringBuffer();
  final StringBuffer testMethods = new StringBuffer();
  final StringBuffer methods = new StringBuffer();

  Unit(this.name);

  void write(StringBuffer buffer) {
    buffer.write("""
$HEADER

$typedefs

$globals

class $name<T> {
  final bool tIsBool;
  final bool tIsInt;
  final bool tIsDynamic;

$fields

  $name({this.tIsBool: false, this.tIsInt: false})
      : tIsDynamic = !tIsBool && !tIsInt;

$methods

  runTests() {\n$tests  }

$testMethods
}

void main() {
  new $name().runTests();
  new $name<int>(tIsInt: true).runTests();
  new $name<bool>(tIsBool: true).runTests();
}
    """);
  }
}

final TEST_METHOD_HEADER = """
  /// #typeCode
  void #testName() {""";

// Tests that apply for every type.
final COMMON_TESTS_TEMPLATE = """
    Expect.isTrue(#staticFunName is #typeName);
    Expect.isTrue(confuse(#staticFunName) is #typeName);
    // In checked mode, verifies the type.
    #typeCode #localName;
    // The static function #staticFunName sets `T` to `int`.
    if (!tIsBool) {
      #fieldName = #staticFunName as dynamic;
      #localName = #staticFunName as dynamic;
      #fieldName = confuse(#staticFunName);
      #localName = confuse(#staticFunName);
    }

    Expect.isTrue(#methodFunName is #typeName);
    Expect.isTrue(#methodFunName is #typeCode);
    Expect.isTrue(confuse(#methodFunName) is #typeName);
    // In checked mode, verifies the type.
    #fieldName = #methodFunName;
    #localName = #methodFunName;
    #fieldName = confuse(#methodFunName);
    #localName = confuse(#methodFunName);""";

// Tests that depend on the typedef "T" argument.
//
// These tests are executed when the surrounding class is instantiated with
// its generic type set to `int`, `dynamic` or `bool`. In the latter case, the
// class field `tIsBool` is set to true.

// While the types themselves are not affected by the class` `T`, the methods
// of the class may use `T`:
//
// For example:
//   class A<T> {
//      f(List<T> x) {}
//   }
final TYPEDEF_T_TESTS_TEMPLATE = """
    if (!tIsBool) {
      Expect.isTrue(#staticFunName is #typeName<int>);
      Expect.isFalse(#staticFunName is #typeName<bool>);
      Expect.isTrue(confuse(#staticFunName) is #typeName<int>);
      Expect.isFalse(confuse(#staticFunName) is #typeName<bool>);
      Expect.equals(tIsDynamic, #methodFunName is #typeName<bool>);
      Expect.equals(tIsDynamic, confuse(#methodFunName) is #typeName<bool>);
    } else {
      if (typeAssertionsEnabled) {
        Expect.throws(() { #fieldName = (#staticFunName as dynamic); });
        Expect.throws(() { #fieldName = confuse(#staticFunName); });
        #typeCode #localName;
        Expect.throws(() { #localName = (#staticFunName as dynamic); });
        Expect.throws(() { #localName = confuse(#staticFunName); });
      }
      #typeCode #localName = #methodFunName;
      // In checked mode, verifies the type.
      #fieldName = #methodFunName;
      #fieldName = confuse(#methodFunName);
    }""";

final TEST_METHOD_FOOTER = "  }";

String createTypeName(int id) => "F$id";
String createStaticFunName(int id) => "f$id";
String createMethodFunName(int id) => "m$id";
String createFieldName(int id) => "x$id";
String createLocalName(int id) => "l$id";
String createTestName(int id) => "test${createTypeName(id)}";

String createTypeCode(FunctionType type) {
  StringBuffer typeBuffer = new StringBuffer();
  type.writeType(typeBuffer);
  return typeBuffer.toString();
}

String createStaticFunCode(FunctionType type, int id) {
  StringBuffer staticFunBuffer = new StringBuffer();
  type.writeFunction(staticFunBuffer, createStaticFunName(id));
  return staticFunBuffer.toString();
}

String createMethodFunCode(FunctionType type, int id) {
  StringBuffer methodFunBuffer = new StringBuffer();
  type.writeFunction(methodFunBuffer, createMethodFunName(id), replaceT: false);
  return methodFunBuffer.toString();
}

String createTestMethodFunCode(FunctionType type, String typeCode, int id) {
  String fillTemplate(String template, int id) {
    var result = template
        .replaceAll("#typeName", createTypeName(id))
        .replaceAll("#staticFunName", createStaticFunName(id))
        .replaceAll("#methodFunName", createMethodFunName(id))
        .replaceAll("#fieldName", createFieldName(id))
        .replaceAll("#localName", createLocalName(id))
        .replaceAll("#testName", createTestName(id))
        .replaceAll("#typeCode", typeCode);
    assert(!result.contains("#"));
    return result;
  }

  String commonTests = fillTemplate(COMMON_TESTS_TEMPLATE, id);
  String genericTTests = "";
  if (type.usesT) {
    genericTTests = fillTemplate(TYPEDEF_T_TESTS_TEMPLATE, id);
  }
  return """
${fillTemplate(TEST_METHOD_HEADER, id)}
$commonTests
$genericTTests
$TEST_METHOD_FOOTER
""";
}

void generateTests() {
  // Keep methods and classes smaller by distributing over several different
  // classes.
  List<Unit> units = [];
  for (int i = 0; i < 100; i++) {
    units.add(new Unit("U$i"));
  }

  var types = buildFunctionTypes();

  int unitCounter = 0;
  types.forEach((FunctionType type) {
    Unit unit = units[unitCounter % units.length];
    unitCounter++;
    int typeCounter = unit.typeCounter++;

    String typeName = createTypeName(typeCounter);
    String fieldName = createFieldName(typeCounter);
    String testName = createTestName(typeCounter);

    String typeCode = createTypeCode(type);
    String staticFunCode = createStaticFunCode(type, typeCounter);
    String methodFunCode = createMethodFunCode(type, typeCounter);
    String testMethodCode =
        createTestMethodFunCode(type, typeCode, typeCounter);

    unit.typedefs.writeln("typedef $typeName<T> = $typeCode;");
    unit.globals.writeln(staticFunCode);
    unit.fields.writeln("  $typeCode $fieldName;");
    unit.methods.writeln("  $methodFunCode");
    unit.testMethods.writeln("$testMethodCode");
    unit.tests.writeln("    $testName();");
  });

  for (int i = 0; i < units.length; i++) {
    var unit = units[i];
    var buffer = new StringBuffer();
    unit.write(buffer);
    var path = Platform.script.resolve("function_type${i}_test.dart").path;
    new File(path).writeAsStringSync(buffer.toString());
  }
}

void printUsage() {
  print("""
Generates function type tests.

All tests are generated in the same directory as this script.
""");
}

void main(List<String> arguments) {
  if (arguments.length != 0) {
    printUsage();
    return;
  }
  generateTests();
}
