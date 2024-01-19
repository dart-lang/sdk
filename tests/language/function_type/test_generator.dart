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

  /// Whether this type uses T in some way.
  bool get usesT;

  /// Whether this type uses T in a return (covariant) position.
  ///
  /// For example: `T`, `List<T>`, `T Function()`, or `Function(Function(T))`.
  bool get returnsT;

  /// Whether this type uses T in a parameter (contravariant) position.
  ///
  /// For example, `Function(T)`, `Function(List<T>)`, or
  /// `Function(T Function())`.
  bool get takesT;
}

/// Provides a unique integer for every parameter in a function.
int parameterNameCounter = 0;

/// Whether `T` should be replaced with `int`.
bool shouldReplaceTWithInt = false;

class Parameter implements TypeLike {
  final TypeLike? type;
  final String? name;

  Parameter(this.type, this.name);

  // Type or name can be null.
  @override
  writeIdentifier(buffer) {
    if (type == null) {
      buffer.write("null");
    } else {
      type!.writeIdentifier(buffer);
    }
    buffer.write("_");
    buffer.write(name);
  }

  void writeType(StringBuffer buffer) {
    assert(type != null || name != null);
    if (name == null) {
      type!.writeType(buffer);
    } else if (type == null) {
      buffer.write(name);
    } else {
      type!.writeType(buffer);
      buffer.write(" ");
      buffer.write(name);
    }
  }

  void writeInFunction(StringBuffer buffer, {required bool optional}) {
    assert(type != null || name != null);
    if (name == null) {
      type!.writeType(buffer);
      buffer.write(" x");
      buffer.write(parameterNameCounter++);
    } else if (type == null) {
      buffer.write(name);
    } else {
      type!.writeType(buffer);
      buffer.write(" ");
      buffer.write(name);
    }

    // Write a default value for optional parameters to avoid nullability
    // errors.
    if (optional) {
      buffer.write(" = ");

      var nominalType = type as NominalType;
      const baseTypes = {
        "int": "-1",
        "Function": "_voidFunction",
        "List": "const []",
      };

      if (baseTypes.containsKey(nominalType.name)) {
        buffer.write(baseTypes[nominalType.name]);
      } else if (shouldReplaceTWithInt && nominalType.name == "T") {
        buffer.write("-1");
      } else {
        throw UnsupportedError("No default value for $type");
      }
    }
  }

  bool operator ==(other) {
    return other is Parameter && name == other.name && type == other.type;
  }

  int get hashCode {
    return ((name.hashCode * 37) ^ type.hashCode) & 0xFFFFFFFF;
  }

  bool get usesT => type?.usesT ?? false;
  bool get takesT => type?.takesT ?? false;
  bool get returnsT => type?.returnsT ?? false;
}

class GenericParameter implements TypeLike {
  final String name;
  final TypeLike? bound;

  GenericParameter(this.name, [this.bound]);

  // Bound may be null.
  @override
  writeIdentifier(buffer) {
    buffer.write(name);
    buffer.write("_");
    if (bound == null) {
      buffer.write("null");
    } else {
      bound!.writeIdentifier(buffer);
    }
  }

  @override
  writeType(buffer) {
    buffer.write(name);
    if (bound != null) {
      buffer.write(" extends ");
      bound!.writeType(buffer);
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

  bool get usesT => bound?.usesT ?? false;
  bool get takesT => bound?.takesT ?? false;
  bool get returnsT => bound?.returnsT ?? false;
}

void _describeList(StringBuffer buffer, List<Printable>? list) {
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

void _writeTypes(StringBuffer buffer, List<TypeLike>? list,
    [String prefix = "", String postfix = ""]) {
  if (list == null || list.isEmpty) return;
  buffer.write(prefix);
  for (int i = 0; i < list.length; i++) {
    if (i != 0) buffer.write(", ");
    list[i].writeType(buffer);
  }
  buffer.write(postfix);
}

/// Write the parameters in [list] to [buffer]. If [inFunction] is true then
/// the output are the formal parameters of a function signature (where
/// optionals will have default values), and if [inFunction] is false then the
/// output are formal parameter types of a function type (where default values
/// and names of positional parameters are omitted).
void _writeParameters(
    StringBuffer buffer, List<Parameter>? list, bool inFunction,
    [String prefix = "", String postfix = ""]) {
  if (list == null || list.isEmpty) return;
  buffer.write(prefix);
  for (int i = 0; i < list.length; i++) {
    if (i != 0) buffer.write(", ");
    if (inFunction) {
      list[i].writeInFunction(buffer, optional: prefix != "");
    } else {
      list[i].writeType(buffer);
    }
  }
  buffer.write(postfix);
}

bool _listUsesT(List? elements) {
  if (elements == null) return false;
  return elements.any((p) => p.usesT);
}

bool _listEquals(List? list1, List? list2) {
  if (list1 == list2) return true; // Also covers both being null.
  if (list1 == null || list2 == null) return false;
  for (int i = 0; i < list1.length; i++) {
    if (list1[i] != list2[i]) return false;
  }
  return true;
}

int _listHash(List? list) {
  if (list == null) return null.hashCode;
  int result = 71;
  for (int i = 0; i < list.length; i++) {
    result = ((result * 11) ^ list[i].hashCode) & 0xFFFFFFFF;
  }
  return result;
}

class FunctionType implements TypeLike {
  final TypeLike? returnType;
  final List<GenericParameter>? generic;
  final List<Parameter> required;
  final List<Parameter>? optional;
  final List<Parameter>? named;

  FunctionType(this.returnType, this.generic, this.required,
      [this.optional, this.named]);

  @override
  writeIdentifier(buffer) {
    buffer.write("Fun_");
    if (returnType == null) {
      buffer.write("null");
    } else {
      returnType!.writeIdentifier(buffer);
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
      returnType!.writeType(buffer);
      buffer.write(" ");
    }
    buffer.write("Function");
    if (generic != null) _writeTypes(buffer, generic, "<", ">");
    buffer.write("(");
    bool inFunction = false;
    _writeParameters(buffer, required, inFunction);
    if ((optional != null || named != null) && required.isNotEmpty) {
      buffer.write(", ");
    }
    _writeParameters(buffer, optional, inFunction, "[", "]");
    _writeParameters(buffer, named, inFunction, "{", "}");
    buffer.write(")");
  }

  /// Writes this type as if it was a function.
  void writeFunction(StringBuffer buffer, String name, {bool replaceT = true}) {
    shouldReplaceTWithInt = replaceT;
    parameterNameCounter = 0;

    if (returnType != null) {
      returnType!.writeType(buffer);
      buffer.write(" ");
    }

    buffer.write(name);
    if (generic != null) _writeTypes(buffer, generic, "<", ">");
    buffer.write("(");
    bool inFunction = true;
    _writeParameters(buffer, required, inFunction);
    if ((optional != null || named != null) && required.isNotEmpty) {
      buffer.write(", ");
    }
    _writeParameters(buffer, optional, inFunction, "[", "]");
    _writeParameters(buffer, named, inFunction, "{", "}");
    buffer.write(") => throw 'uncalled';");

    shouldReplaceTWithInt = false;
  }

  bool operator ==(other) {
    return other is FunctionType &&
        returnType == other.returnType &&
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
    return (returnType?.usesT ?? false) ||
        [generic, required, optional, named].any(_listUsesT);
  }

  bool get returnsT {
    return (returnType?.returnsT ?? false) ||
        [generic, required, optional, named]
            .any((l) => l?.any((p) => p.takesT) ?? false);
  }

  bool get takesT {
    return (returnType?.takesT ?? false) ||
        [generic, required, optional, named]
            .any((l) => l?.any((p) => p.returnsT) ?? false);
  }

  bool get reifiedTypeUsesT {
    return returnType?.usesT ?? returnsT;
  }
}

class NominalType implements TypeLike {
  final String? prefix;
  final String name;
  final List<TypeLike>? generic;

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

  bool get returnsT =>
      name == "T" || (generic?.any((t) => t.returnsT) ?? false);

  bool get takesT => generic?.any((t) => t.takesT) ?? false;
}

List<FunctionType> buildFunctionTypes() {
  List<GenericParameter> as = [
    GenericParameter("A"),
    // new GenericParameter("A", new NominalType("int")),
    // new GenericParameter("A", new NominalType("int", "core")),
  ];
  List<GenericParameter> bs = [
    // new GenericParameter("B"),
    // new GenericParameter("B", new NominalType("int")),
    GenericParameter("B", NominalType("int", "core")),
  ];
  List<TypeLike> basicTypes = [
    NominalType("int"),
    // new NominalType("int", "core"),
    // new NominalType("List"),
    // new NominalType("List", "core"),
    NominalType("Function"),
    NominalType("List", "", [NominalType("Function")]),
    NominalType("List", "core", [NominalType("int", "core")]),
    NominalType("List", "", [NominalType("T")]),
    // new NominalType("List", "", [new NominalType("Function")]),
  ];

  List<TypeLike?> basicsPlusNull = [
    basicTypes,
    <TypeLike?>[null]
  ].expand((x) => x).toList();

  List<TypeLike?> basicsPlusNullPlusVoid = [
    basicsPlusNull,
    [NominalType("void")],
  ].expand((x) => x).toList();

  List<TypeLike?> basicsPlusNullPlusB = [
    basicsPlusNull,
    [
      NominalType("B"),
      NominalType("List", "", [NominalType("B")])
    ]
  ].expand((x) => x).toList();

  List<TypeLike?> basicsPlusNullPlusBPlusVoid = [
    basicsPlusNullPlusB,
    [NominalType("void")],
  ].expand((x) => x).toList();

  List<TypeLike?> basicsPlusNullPlusA = [
    basicsPlusNull,
    [
      NominalType("A"),
      NominalType("List", "", [NominalType("A")])
    ]
  ].expand((x) => x).toList();

  List<TypeLike?> basicsPlusNullPlusAPlusVoid = [
    basicsPlusNullPlusA,
    [NominalType("void")],
  ].expand((x) => x).toList();

  List<FunctionType> buildFunctionTypes(
      TypeLike? returnType, TypeLike? parameterType,
      [List<GenericParameter>? generics,
      bool generateMoreCombinations = false]) {
    List<FunctionType> result = [];

    if (parameterType == null) {
      // int Function().
      result.add(FunctionType(returnType, generics, []));
      return result;
    }

    // int Function(int x).
    result.add(
        FunctionType(returnType, generics, [Parameter(parameterType, "x")]));

    if (!generateMoreCombinations) return result;

    // int Function([int x]).
    result.add(FunctionType(
        returnType, generics, [], [Parameter(parameterType, "x")]));
    // int Function(int, [int x])
    result.add(FunctionType(
        returnType,
        generics,
        [Parameter(NominalType("int"), null)],
        [Parameter(parameterType, "x")]));
    // int Function(int x, [int x])
    result.add(FunctionType(returnType, generics,
        [Parameter(NominalType("int"), "y")], [Parameter(parameterType, "x")]));
    // int Function(int);
    result.add(
        FunctionType(returnType, generics, [Parameter(parameterType, null)]));
    // int Function([int]);
    result.add(FunctionType(
        returnType, generics, [], [Parameter(parameterType, null)]));
    // int Function(int, [int])
    result.add(FunctionType(
        returnType,
        generics,
        [Parameter(NominalType("int"), null)],
        [Parameter(parameterType, null)]));
    // int Function(int x, [int])
    result.add(FunctionType(
        returnType,
        generics,
        [Parameter(NominalType("int"), "x")],
        [Parameter(parameterType, null)]));
    // int Function({int x}).
    result.add(FunctionType(
        returnType, generics, [], null, [Parameter(parameterType, "x")]));
    // int Function(int, {int x})
    result.add(FunctionType(
        returnType,
        generics,
        [Parameter(NominalType("int"), null)],
        null,
        [Parameter(parameterType, "x")]));
    // int Function(int x, {int x})
    result.add(FunctionType(
        returnType,
        generics,
        [Parameter(NominalType("int"), "y")],
        null,
        [Parameter(parameterType, "x")]));
    return result;
  }

  // The "smaller" function types. May also be used non-nested.
  List<FunctionType> functionTypes = [];

  for (TypeLike? returnType in basicsPlusNullPlusVoid) {
    for (TypeLike? parameterType in basicsPlusNull) {
      bool generateMoreCombinations = true;
      functionTypes.addAll(buildFunctionTypes(
          returnType, parameterType, null, generateMoreCombinations));
    }
  }

  // These use `B` from the generic type of the enclosing function.
  List<TypeLike> returnFunctionTypesB = [];
  for (TypeLike? returnType in basicsPlusNullPlusBPlusVoid) {
    TypeLike parameterType = NominalType("B");
    returnFunctionTypesB.addAll(buildFunctionTypes(returnType, parameterType));
  }
  for (TypeLike? parameterType in basicsPlusNull) {
    TypeLike returnType = NominalType("B");
    returnFunctionTypesB.addAll(buildFunctionTypes(returnType, parameterType));
  }

  for (TypeLike? returnType in basicsPlusNullPlusAPlusVoid) {
    for (TypeLike? parameterType in basicsPlusNullPlusA) {
      for (GenericParameter a in as) {
        functionTypes
            .addAll(buildFunctionTypes(returnType, parameterType, [a]));
      }
    }
  }

  List<FunctionType> types = [];
  types.addAll(functionTypes);

  // Now add some higher-order function types.
  for (TypeLike returnType in functionTypes) {
    types.addAll(buildFunctionTypes(returnType, null));
    types.addAll(buildFunctionTypes(returnType, NominalType("int")));
    for (var b in bs) {
      types.addAll(buildFunctionTypes(returnType, null, [b]));
      types.addAll(buildFunctionTypes(returnType, NominalType("int"), [b]));
    }
  }
  for (TypeLike returnType in returnFunctionTypesB) {
    for (var b in bs) {
      types.addAll(buildFunctionTypes(returnType, null, [b]));
      types.addAll(buildFunctionTypes(returnType, NominalType("int"), [b]));
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

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(f) => f;

void _voidFunction() {}
""";

class Unit {
  int typeCounter = 0;
  final String name;
  final StringBuffer typedefs = StringBuffer();
  final StringBuffer globals = StringBuffer();
  final StringBuffer tests = StringBuffer();
  final StringBuffer fields = StringBuffer();
  final StringBuffer statics = StringBuffer();
  final StringBuffer testMethods = StringBuffer();
  final StringBuffer methods = StringBuffer();

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

  $name({this.tIsBool = false, this.tIsInt = false})
      : tIsDynamic = !tIsBool && !tIsInt;

$methods

  runTests() {\n$tests  }

$testMethods
}

void main() {
  $name().runTests();
  $name<int>(tIsInt: true).runTests();
  $name<bool>(tIsBool: true).runTests();
}
    """);
  }
}

final TEST_METHOD_HEADER = """
  /// #typeCode
  void #testName() {""";

// Tests that apply for every type.
final COMMON_TESTS_TEMPLATE = """
    Expect.isTrue(#staticFunName is #typeName<int>);
    Expect.isTrue(confuse(#staticFunName) is #typeName<int>);
    // In checked mode, verifies the type.
    #typeCode #localName;
    // The static function #staticFunName sets `T` to `int`.
    if (tIsInt) {
      #fieldName = #staticFunName as dynamic;
      #localName = #staticFunName as dynamic;
      #fieldName = confuse(#staticFunName);
      #localName = confuse(#staticFunName);
    }

    Expect.isTrue(#methodFunName is #typeName<T>);
    Expect.isTrue(#methodFunName is #typeCode);
    Expect.isTrue(confuse(#methodFunName) is #typeName<T>);
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
    // The static function has its T always set to int.
    Expect.isTrue(#staticFunName is #typeName<int>);
    Expect.isFalse(#staticFunName is #typeName<bool>);
    Expect.isTrue(confuse(#staticFunName) is #typeName<int>);
    Expect.isFalse(confuse(#staticFunName) is #typeName<bool>);
    if (tIsBool && !dart2jsProductionMode) {
      Expect.throws(() { #fieldName = (#staticFunName as dynamic); });
      Expect.throws(() { #fieldName = confuse(#staticFunName); });
      Expect.throws(() { #localName = (#staticFunName as dynamic); });
      Expect.throws(() { #localName = confuse(#staticFunName); });
    }
    if (tIsInt || tIsBool) {
      Expect.equals(#isIntValue, #methodFunName is #typeName<int>);
      Expect.equals(#isBoolValue, #methodFunName is #typeName<bool>);
      Expect.equals(#isIntValue, confuse(#methodFunName) is #typeName<int>);
      Expect.equals(#isBoolValue, confuse(#methodFunName) is #typeName<bool>);
    }
""";

final TEST_METHOD_FOOTER = "  }";

String createTypeName(int id) => "F$id";
String createStaticFunName(int id) => "f$id";
String createMethodFunName(int id) => "m$id";
String createFieldName(int id) => "x$id";
String createLocalName(int id) => "l$id";
String createTestName(int id) => "test${createTypeName(id)}";

String createTypeCode(FunctionType type) {
  StringBuffer typeBuffer = StringBuffer();
  type.writeType(typeBuffer);
  return typeBuffer.toString();
}

String createStaticFunCode(FunctionType type, int id) {
  StringBuffer staticFunBuffer = StringBuffer();
  type.writeFunction(staticFunBuffer, createStaticFunName(id));
  return staticFunBuffer.toString();
}

String createMethodFunCode(FunctionType type, int id) {
  StringBuffer methodFunBuffer = StringBuffer();
  type.writeFunction(methodFunBuffer, createMethodFunName(id), replaceT: false);
  return methodFunBuffer.toString();
}

String createTestMethodFunCode(FunctionType type, String typeCode, int id) {
  var tIsInt = type.reifiedTypeUsesT ? 'tIsInt' : 'true';
  var tIsBool = type.reifiedTypeUsesT ? 'tIsBool' : 'true';

  String fillTemplate(String template, int id) {
    var result = template
        .replaceAll("#typeName", createTypeName(id))
        .replaceAll("#staticFunName", createStaticFunName(id))
        .replaceAll("#methodFunName", createMethodFunName(id))
        .replaceAll("#fieldName", createFieldName(id))
        .replaceAll("#localName", createLocalName(id))
        .replaceAll("#testName", createTestName(id))
        .replaceAll("#typeCode", typeCode)
        .replaceAll("#isIntValue", tIsInt)
        .replaceAll("#isBoolValue", tIsBool);
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
    units.add(Unit("U$i"));
  }

  List<FunctionType> types = buildFunctionTypes();

  int unitCounter = 0;
  for (var type in types) {
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
    // Mark all fields 'late' to avoid uninitialized field errors.
    unit.fields.writeln("  late $typeCode $fieldName;");
    unit.methods.writeln("  $methodFunCode");
    unit.testMethods.writeln("$testMethodCode");
    unit.tests.writeln("    $testName();");
  }

  for (int i = 0; i < units.length; i++) {
    var unit = units[i];
    var buffer = StringBuffer();
    unit.write(buffer);
    var path = Platform.script.resolve("function_type${i}_test.dart").path;
    File(path).writeAsStringSync(buffer.toString());
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
