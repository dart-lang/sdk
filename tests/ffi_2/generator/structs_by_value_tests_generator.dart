// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'c_types.dart';
import 'structs_by_value_tests_configuration.dart';
import 'utils.dart';

/// The test type determines how to convert the arguments into return values
/// such that the caller knows what to check.
enum TestType {
  /// Tested by getting all the individual fields out of the structs and
  /// summing their values.
  structArguments,

  /// Tested by passing assigning the arguments to the struct fields.
  structReturn,

  /// Tested by returning the struct passed in.
  structReturnArgument,
}

extension on FunctionType {
  TestType get testType {
    if (arguments.containsStructs && returnValue is FundamentalType) {
      return TestType.structArguments;
    }
    if (returnValue is StructType && argumentTypes.contains(returnValue)) {
      return TestType.structReturnArgument;
    }
    if (returnValue is StructType) {
      if (arguments.length == (returnValue as StructType).members.length) {
        return TestType.structReturn;
      }
    }
    throw Exception("Unknown test type: $this");
  }
}

/// We use the class structure as an algebraic data type in order to keep the
/// relevant parts of the code generation closer together.
extension on CType {
  /// The part of the cout expression after `std::cout` and before the `;`.
  String coutExpression(String variableName) {
    switch (this.runtimeType) {
      case FundamentalType:
        if (this == uint8 || this == int8) {
          return "<< static_cast<int>($variableName)";
        }
        return "<< $variableName";

      case StructType:
        final this_ = this as StructType;
        return this_.members.coutExpression("$variableName.");
    }

    throw Exception("Not implemented for ${this.runtimeType}");
  }

  /// A statement recursively outputting all members.
  String coutStatement(String variableName) {
    final coutExpr = this.coutExpression(variableName);
    return 'std::cout << "$variableName = " $coutExpr << "\\n";';
  }
}

extension on List<Member> {
  /// The part of the cout expression after `std::cout` and before the `;`.
  String coutExpression([String namePrefix = ""]) {
    String result = '<< "("';
    result += this
        .map((m) => m.type.coutExpression("$namePrefix${m.name}"))
        .join('<< ", "');
    result += '<< ")"';
    return result.trimCouts();
  }
}

extension on CType {
  /// A list of statements adding all members recurisvely to `result`.
  ///
  /// Both valid in Dart and C.
  String addToResultStatements(String variableName) {
    switch (this.runtimeType) {
      case FundamentalType:
        return "result += $variableName;\n";

      case StructType:
        final this_ = this as StructType;
        return this_.members.addToResultStatements("$variableName.");
    }

    throw Exception("Not implemented for ${this.runtimeType}");
  }
}

extension on List<Member> {
  /// A list of statements adding all members recurisvely to `result`.
  ///
  /// Both valid in Dart and C.
  String addToResultStatements([String namePrefix = ""]) {
    return map((m) => m.type.addToResultStatements("$namePrefix${m.name}"))
        .join();
  }
}

extension on CType {
  /// A list of statements recursively assigning all members with [a].
  ///
  /// Both valid in Dart and C.
  String assignValueStatements(ArgumentValueAssigner a, String variableName) {
    switch (this.runtimeType) {
      case FundamentalType:
        final this_ = this as FundamentalType;
        return "$variableName = ${a.nextValue(this_)};\n";

      case StructType:
        final this_ = this as StructType;
        return this_.members.assignValueStatements(a, "$variableName.");
    }

    throw Exception("Not implemented for ${this.runtimeType}");
  }

  /// A list of statements recursively coping all members from [source].
  ///
  /// Both valid in Dart and C.
  String copyValueStatements(String source, String destination) {
    switch (this.runtimeType) {
      case FundamentalType:
        return "$destination = $source;\n";

      case StructType:
        final this_ = this as StructType;
        return this_.members.copyValueStatements("$source.", "$destination.");
    }

    throw Exception("Not implemented for ${this.runtimeType}");
  }
}

extension on List<Member> {
  /// A list of statements recursively assigning all members with [a].
  ///
  /// Both valid in Dart and C.
  String assignValueStatements(ArgumentValueAssigner a,
      [String namePrefix = ""]) {
    return map((m) => m.type.assignValueStatements(a, "$namePrefix${m.name}"))
        .join();
  }

  /// A list of statements recursively coping all members from [source].
  ///
  /// Both valid in Dart and C.
  String copyValueStatements([sourcePrefix = "", destinationPrefix = ""]) {
    return map((m) => m.type.copyValueStatements(
        "$sourcePrefix${m.name}", "$destinationPrefix${m.name}")).join();
  }
}

/// A helper class that assigns values to fundamental types.
///
/// Also keeps track of a sum of all values, to be used for testing the result.
class ArgumentValueAssigner {
  int i = 1;
  int sum = 0;
  String nextValue(FundamentalType type) {
    int argumentValue = i;
    i++;
    if (type.isSigned && i % 2 == 0) {
      argumentValue = -argumentValue;
    }
    sum += argumentValue;
    if (type.isFloatingPoint) {
      return argumentValue.toDouble().toString();
    } else {
      return argumentValue.toString();
    }
  }

  String sumValue(FundamentalType type) {
    if (type.isFloatingPoint) {
      return sum.toDouble().toString();
    } else {
      return sum.toString();
    }
  }
}

extension on CType {
  /// A list of Dart statements recursively allocating all members.
  String dartAllocateStatements(String variableName) {
    switch (this.runtimeType) {
      case FundamentalType:
        return "${dartType} ${variableName};\n";

      case StructType:
        return "${dartType} ${variableName} = allocate<$dartType>().ref;\n";
    }

    throw Exception("Not implemented for ${this.runtimeType}");
  }

  /// A list of Dart statements allocating as zero or nullptr.
  String dartAllocateZeroStatements(String variableName) {
    switch (this.runtimeType) {
      case FundamentalType:
        final this_ = this as FundamentalType;
        if (this_.isInteger) {
          return "${dartType} ${variableName} = 0;\n";
        }
        return "${dartType} ${variableName} = 0.0;\n";

      case StructType:
        return "${dartType} ${variableName} = ${dartType}();\n";
    }

    throw Exception("Not implemented for ${this.runtimeType}");
  }
}

extension on List<Member> {
  /// A list of Dart statements recursively allocating all members.
  String dartAllocateStatements([String namePrefix = ""]) {
    return map((m) => m.type.dartAllocateStatements("$namePrefix${m.name}"))
        .join();
  }

  /// A list of Dart statements as zero or nullptr.
  String dartAllocateZeroStatements([String namePrefix = ""]) {
    return map((m) => m.type.dartAllocateZeroStatements("$namePrefix${m.name}"))
        .join();
  }
}

extension on CType {
  /// A list of Dart statements recursively freeing all members.
  String dartFreeStatements(String variableName) {
    switch (this.runtimeType) {
      case FundamentalType:
        return "";

      case StructType:
        return "free($variableName.addressOf);\n";
    }

    throw Exception("Not implemented for ${this.runtimeType}");
  }
}

extension on List<Member> {
  /// A list of Dart statements recursively freeing all members.
  String dartFreeStatements([String namePrefix = ""]) {
    return map((m) => m.type.dartFreeStatements("$namePrefix${m.name}")).join();
  }
}

extension on CType {
  /// A list of C statements recursively allocating all members.
  String cAllocateStatements(String variableName) {
    switch (this.runtimeType) {
      case FundamentalType:
      case StructType:
        return "${cType} ${variableName};\n";
    }

    throw Exception("Not implemented for ${this.runtimeType}");
  }
}

extension on List<Member> {
  /// A list of C statements recursively allocating all members.
  String cAllocateStatements([String namePrefix = ""]) {
    return map((m) => m.type.cAllocateStatements("$namePrefix${m.name}"))
        .join();
  }
}

extension on CType {
  /// A list of Dart statements recursively checking all members.
  String dartExpectsStatements(String expected, String actual) {
    switch (this.runtimeType) {
      case FundamentalType:
        final this_ = this as FundamentalType;
        if (this_.isInteger) {
          return "Expect.equals(${expected}, ${actual});";
        }
        assert(this_.isFloatingPoint);
        return "Expect.approxEquals(${expected}, ${actual});";

      case StructType:
        final this_ = this as StructType;
        return this_.members.dartExpectsStatements("$expected.", "$actual.");
    }

    throw Exception("Not implemented for ${this.runtimeType}");
  }
}

extension on List<Member> {
  /// A list of Dart statements recursively checking all members.
  String dartExpectsStatements(
      [String expectedPrefix = "", String actualPrefix = ""]) {
    return map((m) => m.type.dartExpectsStatements(
        "$expectedPrefix${m.name}", "$actualPrefix${m.name}")).join();
  }
}

extension on CType {
  /// A list of C statements recursively checking all members.
  String cExpectsStatements(String expected, String actual) {
    switch (this.runtimeType) {
      case FundamentalType:
        final this_ = this as FundamentalType;
        if (this_.isInteger) {
          return "CHECK_EQ(${expected}, ${actual});";
        }
        assert(this_.isFloatingPoint);
        return "CHECK_APPROX(${expected}, ${actual});";

      case StructType:
        final this_ = this as StructType;
        return this_.members.cExpectsStatements("$expected.", "$actual.");
    }

    throw Exception("Not implemented for ${this.runtimeType}");
  }

  /// A list of C statements recursively checking all members for zero.
  String cExpectsZeroStatements(String actual) {
    switch (this.runtimeType) {
      case FundamentalType:
        final this_ = this as FundamentalType;
        if (this_.isInteger) {
          return "CHECK_EQ(0, ${actual});";
        }
        assert(this_.isFloatingPoint);
        return "CHECK_APPROX(0.0, ${actual});";

      case StructType:
        final this_ = this as StructType;
        return this_.members.cExpectsZeroStatements("$actual.");
    }

    throw Exception("Not implemented for ${this.runtimeType}");
  }
}

extension on List<Member> {
  /// A list of C statements recursively checking all members.
  String cExpectsStatements(
      [String expectedPrefix = "", String actualPrefix = ""]) {
    return map((m) => m.type.cExpectsStatements(
        "$expectedPrefix${m.name}", "$actualPrefix${m.name}")).join();
  }

  /// A list of C statements recursively checking all members for zero.
  String cExpectsZeroStatements([String actualPrefix = ""]) {
    return map((m) => m.type.cExpectsZeroStatements("$actualPrefix${m.name}"))
        .join();
  }
}

extension on CType {
  /// Expression denoting the first FundamentalType field.
  ///
  /// Both valid in Dart and C.
  String firstArgumentName(String variableName) {
    switch (this.runtimeType) {
      case FundamentalType:
        return variableName;

      case StructType:
        final this_ = this as StructType;
        return this_.members.firstArgumentName("$variableName.");
    }

    throw Exception("Not implemented for ${this.runtimeType}");
  }
}

extension on List<Member> {
  /// Expression denoting the first FundamentalType field.
  ///
  /// Both valid in Dart and C.
  String firstArgumentName([String prefix = ""]) {
    return this[0].type.firstArgumentName("$prefix${this[0].name}");
  }
}

extension on StructType {
  String dartClass(bool nnbd) {
    String dartFields = "";
    for (final member in members) {
      dartFields += "${member.dartStructField(nnbd)}\n\n";
    }
    String toStringBody = members.map((m) => "\$\{${m.name}\}").join(", ");
    return """
    class $name extends Struct {
      $dartFields

      String toString() => "($toStringBody)";
    }
    """;
  }

  String get cDefinition {
    String cFields = "";
    for (final member in members) {
      cFields += "  ${member.cStructField}\n";
    }
    return """
    struct $name {
      $cFields
    };

    """;
  }
}

extension on FunctionType {
  String get dartCallCode {
    final a = ArgumentValueAssigner();
    final assignValues = arguments.assignValueStatements(a);
    final argumentFrees = arguments.dartFreeStatements();

    final argumentNames = arguments.map((e) => e.name).join(", ");

    String expects;
    switch (testType) {
      case TestType.structArguments:
        // Check against sum value.
        final expectedResult = a.sumValue(returnValue as FundamentalType);
        expects = returnValue.dartExpectsStatements(expectedResult, "result");
        break;
      case TestType.structReturn:
        // Check against input arguments.
        expects = arguments.dartExpectsStatements("", "result.");
        break;
      case TestType.structReturnArgument:
        expects = returnValue.dartExpectsStatements(
            structReturnArgument.name, "result");
        break;
    }

    return """
    final $dartName =
      ffiTestFunctions.lookupFunction<$dartCType, $dartType>("$cName");

    ${reason.makeDartDocComment()}
    void $dartTestName() {
      ${arguments.dartAllocateStatements()}

      ${assignValues}

      final result = $dartName($argumentNames);

      print("result = \$result");

      $expects

      $argumentFrees
    }
    """;
  }

  String dartCallbackCode(bool nnbd) {
    final argumentss =
        arguments.map((a) => "${a.type.dartType} ${a.name}").join(", ");

    final prints = arguments.map((a) => "\$\{${a.name}\}").join(", ");

    String buildReturnValue = "";
    switch (testType) {
      case TestType.structArguments:
        // Sum all input values.
        buildReturnValue = """
        ${returnValue.dartType} result = 0;

        ${arguments.addToResultStatements('${dartName}_')}
        """;
        break;
      case TestType.structReturn:
        // Allocate a struct.
        buildReturnValue = """
        ${returnValue.dartType} result = allocate<${returnValue.dartType}>().ref;

        ${arguments.copyValueStatements("${dartName}_", "result.")}
        """;
        break;
      case TestType.structReturnArgument:
        buildReturnValue = """
        ${returnValue.cType} result = ${dartName}_${structReturnArgument.name};
        """;
        break;
    }

    final globals = arguments.dartAllocateZeroStatements("${dartName}_");

    final copyToGlobals =
        arguments.map((a) => '${dartName}_${a.name} = ${a.name};').join("\n");

    // Simulate assigning values the same way as in C, so that we know what the
    // final return value should be.
    final a = ArgumentValueAssigner();
    arguments.assignValueStatements(a);
    String afterCallbackExpects = "";
    String afterCallbackFrees = "";
    switch (testType) {
      case TestType.structArguments:
        // Check that the input structs are still available.
        // Check against sum value.
        final expectedResult = a.sumValue(returnValue as FundamentalType);
        afterCallbackExpects =
            returnValue.dartExpectsStatements(expectedResult, "result");
        break;
      case TestType.structReturn:
        // We're passing allocating structs in [buildReturnValue].
        afterCallbackFrees =
            returnValue.dartFreeStatements("${dartName}Result");
        break;
      case TestType.structReturnArgument:
        break;
    }

    String returnNull = "";
    if (!nnbd) {
      returnNull = """
      if (${arguments.firstArgumentName()} == $returnNullValue) {
        print("returning null!");
        return null;
      }
      """;
    }

    return """
    typedef ${cName}Type = $dartCType;

    // Global variables to be able to test inputs after callback returned.
    $globals

    // Result variable also global, so we can delete it after the callback.
    ${returnValue.dartAllocateZeroStatements("${dartName}Result")}

    ${returnValue.dartType} ${dartName}CalculateResult() {
      $buildReturnValue

      ${dartName}Result = result;

      return result;
    }

    ${reason.makeDartDocComment()}
    ${returnValue.dartType} $dartName($argumentss) {
      print("$dartName($prints)");

      // In legacy mode, possibly return null.
      $returnNull

      // In both nnbd and legacy mode, possibly throw.
      if (${arguments.firstArgumentName()} == $throwExceptionValue ||
          ${arguments.firstArgumentName()} == $returnNullValue) {
        print("throwing!");
        throw Exception("$cName throwing on purpuse!");
      }

      $copyToGlobals

      final result = ${dartName}CalculateResult();

      print(\"result = \$result\");

      return result;
    }

    void ${dartName}AfterCallback() {
      $afterCallbackFrees

      final result = ${dartName}CalculateResult();

      print(\"after callback result = \$result\");

      $afterCallbackExpects

      $afterCallbackFrees
    }

    """;
  }

  String get dartCallbackTestConstructor {
    String exceptionalReturn = "";
    if (returnValue is FundamentalType) {
      if ((returnValue as FundamentalType).isFloatingPoint) {
        exceptionalReturn = ", 0.0";
      } else {
        exceptionalReturn = ", 0";
      }
    }
    return """
    CallbackTest.withCheck("$cName",
      Pointer.fromFunction<${cName}Type>($dartName$exceptionalReturn),
      ${dartName}AfterCallback),
    """;
  }

  String get cCallCode {
    String body = "";
    switch (testType) {
      case TestType.structArguments:
        body = """
        ${returnValue.cType} result = 0;

        ${arguments.addToResultStatements()}
        """;
        break;
      case TestType.structReturn:
        body = """
        ${returnValue.cType} result;

        ${arguments.copyValueStatements("", "result.")}
        """;
        break;
      case TestType.structReturnArgument:
        body = """
        ${returnValue.cType} result = ${structReturnArgument.name};
        """;
        break;
    }

    final argumentss =
        arguments.map((e) => "${e.type.cType} ${e.name}").join(", ");

    return """
    // Used for testing structs by value.
    ${reason.makeCComment()}
    DART_EXPORT ${returnValue.cType} $cName($argumentss) {
      std::cout << \"$cName\" ${arguments.coutExpression()} << \"\\n\";

      $body

      ${returnValue.coutStatement("result")}

      return result;
    }

    """;
  }

  String get cCallbackCode {
    final a = ArgumentValueAssigner();
    final argumentAllocations = arguments.cAllocateStatements();
    final assignValues = arguments.assignValueStatements(a);

    final argumentss =
        arguments.map((e) => "${e.type.cType} ${e.name}").join(", ");

    final argumentNames = arguments.map((e) => e.name).join(", ");

    String expects = "";
    String expectsZero = "";
    switch (testType) {
      case TestType.structArguments:
        // Check against sum value.
        final returnValue_ = returnValue as FundamentalType;
        final expectedResult = a.sumValue(returnValue_);
        expects = returnValue.cExpectsStatements(expectedResult, "result");

        expectsZero = returnValue.cExpectsZeroStatements("result");
        break;
      case TestType.structReturn:
        // Check against input statements.
        expects = arguments.cExpectsStatements("", "result.");

        expectsZero = arguments.cExpectsZeroStatements("result.");
        break;
      case TestType.structReturnArgument:
        // Check against input struct fields.
        expects =
            returnValue.cExpectsStatements(structReturnArgument.name, "result");

        expectsZero = returnValue.cExpectsZeroStatements("result");
        break;
    }

    return """
    // Used for testing structs by value.
    ${reason.makeCComment()}
    DART_EXPORT intptr_t
    Test$cName(
        // NOLINTNEXTLINE(whitespace/parens)
        ${returnValue.cType} (*f)($argumentss)) {
      $argumentAllocations

      $assignValues

      std::cout << \"Calling Test$cName(\" ${arguments.coutExpression()} << \")\\n\";

      ${returnValue.cType} result = f($argumentNames);

      ${returnValue.coutStatement("result")}

      $expects

      // Pass argument that will make the Dart callback throw.
      ${arguments.firstArgumentName()} = $throwExceptionValue;

      result = f($argumentNames);

      $expectsZero

      // Pass argument that will make the Dart callback return null.
      ${arguments.firstArgumentName()} = $returnNullValue;

      result = f($argumentNames);

      $expectsZero

      return 0;
    }

    """;
  }
}

/// Some value between 0 and 127 (works in every native type).
const throwExceptionValue = 42;

/// Some value between 0 and 127 (works in every native type).
const returnNullValue = 84;

const headerDartCallTest = """
// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
//
// SharedObjects=ffi_test_functions
// VMOptions=
// VMOptions=--deterministic --optimization-counter-threshold=5
// VMOptions=--use-slow-path
// VMOptions=--use-slow-path --stacktrace-every=100

import 'dart:ffi';

import "package:expect/expect.dart";
import "package:ffi/ffi.dart";

import 'dylib_utils.dart';

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");
""";

void writeDartCallTest() {
  for (bool nnbd in [true, false]) {
    final StringBuffer buffer = StringBuffer();
    buffer.write(headerDartCallTest);

    buffer.write("""
    void main() {
      for (int i = 0; i < 10; ++i) {
        ${functions.map((e) => "${e.dartTestName}();").join("\n")}
      }
    }
    """);
    buffer.writeAll(structs.map((e) => e.dartClass(nnbd)));
    buffer.writeAll(functions.map((e) => e.dartCallCode));

    final path = callTestPath(nnbd);
    File(path).writeAsStringSync(buffer.toString());
    Process.runSync("dartfmt", ["-w", path]);
  }
}

String callTestPath(bool nnbd) {
  final folder = nnbd ? "ffi" : "ffi_2";
  return Platform.script
      .resolve("../../$folder/function_structs_by_value_generated_test.dart")
      .path;
}

const headerDartCallbackTest = """
// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
//
// SharedObjects=ffi_test_functions
// VMOptions=
// VMOptions=--deterministic --optimization-counter-threshold=10
// VMOptions=--use-slow-path
// VMOptions=--use-slow-path --stacktrace-every=100

import 'dart:ffi';

import "package:expect/expect.dart";
import "package:ffi/ffi.dart";

import 'callback_tests_utils.dart';

// Reuse the struct classes.
import 'function_structs_by_value_generated_test.dart';


void main() {
  testCases.forEach((t) {
    print("==== Running " + t.name);
    t.run();
  });
}


""";

void writeDartCallbackTest() {
  for (bool nnbd in [true, false]) {
    final StringBuffer buffer = StringBuffer();
    buffer.write(headerDartCallbackTest);

    buffer.write("""
  final testCases = [
    ${functions.map((e) => e.dartCallbackTestConstructor).join("\n")}
  ];
  """);

    buffer.writeAll(functions.map((e) => e.dartCallbackCode(nnbd)));

    final path = callbackTestPath(nnbd);
    File(path).writeAsStringSync(buffer.toString());
    Process.runSync("dartfmt", ["-w", path]);
  }
}

String callbackTestPath(bool nnbd) {
  final folder = nnbd ? "ffi" : "ffi_2";
  return Platform.script
      .resolve(
          "../../$folder/function_callbacks_structs_by_value_generated_test.dart")
      .path;
}

const headerC = """
// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.

#include <stddef.h>
#include <stdlib.h>
#include <sys/types.h>

#include <cmath>
#include <iostream>
#include <limits>

#if defined(_WIN32)
#define DART_EXPORT extern "C" __declspec(dllexport)
#else
#define DART_EXPORT                                                            \\
  extern "C" __attribute__((visibility("default"))) __attribute((used))
#endif

namespace dart {

#define CHECK(X)                                                               \\
  if (!(X)) {                                                                  \\
    fprintf(stderr, "%s\\n", "Check failed: " #X);                              \\
    return 1;                                                                  \\
  }

#define CHECK_EQ(X, Y) CHECK((X) == (Y))

// Works for positive, negative and zero.
#define CHECK_APPROX(EXPECTED, ACTUAL)                                         \\
  CHECK(((EXPECTED * 0.99) <= (ACTUAL) && (EXPECTED * 1.01) >= (ACTUAL)) ||    \\
        ((EXPECTED * 0.99) >= (ACTUAL) && (EXPECTED * 1.01) <= (ACTUAL)))

""";

const footerC = """

}  // namespace dart
""";

void writeC() {
  final StringBuffer buffer = StringBuffer();
  buffer.write(headerC);

  buffer.writeAll(structs.map((e) => e.cDefinition));
  buffer.writeAll(functions.map((e) => e.cCallCode));
  buffer.writeAll(functions.map((e) => e.cCallbackCode));

  buffer.write(footerC);

  File(ccPath).writeAsStringSync(buffer.toString());
  Process.runSync("clang-format", ["-i", ccPath]);
}

final ccPath = Platform.script
    .resolve("../../../runtime/bin/ffi_test/ffi_test_functions_generated.cc")
    .path;

void printUsage() {
  print("""
Generates structs by value tests.

Generates:
- $ccPath
- ${callbackTestPath(true)}
- ${callTestPath(true)}
- ${callbackTestPath(false)}
- ${callTestPath(false)}
""");
}

void main(List<String> arguments) {
  if (arguments.length != 0) {
    printUsage();
    return;
  }

  writeDartCallTest();
  writeDartCallbackTest();
  writeC();
}
