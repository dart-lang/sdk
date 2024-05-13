// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'c_types.dart';
import 'utils.dart';
import 'structs_by_value_tests_generator.dart';

void main() async {
  await Future.wait([
    writeC(),
    for (final container in Container.values) writeDart(container),
    writeDartShared()
  ]);
}

class Container {
  /// The name of the container in Dart code.
  final String name;

  /// The copyright year for the generated test file for this container.
  final int copyrightYear;

  /// How this containers' name shows up in tests.
  final String Function(PointerType) testName;

  final Iterable<Test> tests;

  final Iterable<FundamentalType> elementTypes;

  const Container(
    this.name,
    this.copyrightYear,
    this.testName,
    this.tests,
    this.elementTypes,
  );

  static final array = Container(
    'Array',
    2024,
    (pointerType) => '${pointerType.pointerTo}Array',
    [
      Test.self,
      Test.elementAt,
    ],
    [
      int8,
      int16,
      int32,
      int64,
      uint8,
      uint16,
      uint32,
      uint64,
      float,
      double_,
      bool_,
    ],
  );

  static final struct = Container(
    'Struct',
    2024,
    (pointerType) => '${pointerType.pointerTo}Struct',
    [
      Test.field,
    ],
    [
      int8,
      int16,
      int32,
      int64,
      uint8,
      uint16,
      uint32,
      uint64,
      float,
      double_,
      bool_,
    ],
  );

  static final typedData = Container(
    'TypedData',
    2024,
    (pointerType) => pointerType.dartTypedData,
    [
      Test.self,
      Test.elementAt,
      Test.view,
      Test.viewMany,
    ],
    [
      int8,
      int16,
      int32,
      int64,
      uint8,
      uint16,
      uint32,
      uint64,
      float,
      double_,
    ],
  );

  static final values = [
    array,
    struct,
    typedData,
  ];
}

class Test {
  final String name;

  const Test(this.name);

  String testName(Container container, CType elementType) {
    final containerName = container.testName(PointerType(elementType));
    return 'testAddressOf$containerName$name';
  }

  static const elementAt = Test('ElementAt');
  static const field = Test('Field');
  static const self = Test('');
  static const view = Test('View');
  static const viewMany = Test('ViewMany');
}

const generatorPath = 'tests/ffi/generator/address_of_test_generator.dart';

Future<void> writeDart(Container container) async {
  final StringBuffer buffer = StringBuffer();
  buffer.write(headerDart(
    copyrightYear: container.copyrightYear,
  ));

  buffer.write("""
void main() {${'''
  // Force dlopen so @Native lookups in DynamicLibrary.process() succeed.
  dlopenGlobalPlatformSpecific('ffi_test_functions');

'''}
  for (int i = 0; i < 100; ++i) {
""");

  for (final elementType in container.elementTypes) {
    for (final test in container.tests) {
      buffer.write("""
    ${test.testName(container, elementType)}();
""");
    }
  }
  if (container == Container.struct) {
    buffer.write('''
    testAddressOfStructPointerMany();
''');
  }
  buffer.write("""
  }
}

""");

  for (final elementType in container.elementTypes) {
    final pointerType = PointerType(elementType);
    final testName = container.testName(pointerType);
    final varName = container.name.lowerCaseFirst();
    String value = elementType.isSigned ? 'i % 2 == 0 ? i : -i' : 'i';
    if (elementType.isFloatingPoint) {
      value = '($value).toDouble()';
    }
    final equals = elementType.isFloatingPoint ? 'approxEquals' : 'equals';

    if (container == Container.array) {
      buffer.write("""
final class ${elementType.dartCType}ArrayStruct extends Struct {
  @Array(20)
  external Array<${elementType.dartCType}> array;
}

Array<${elementType.dartCType}> make${elementType.dartCType}Array(int length){
  assert(length == 20);
  final typedData = make${pointerType.dartTypedData}(length);
  final struct = Struct.create<${elementType.dartCType}ArrayStruct>(typedData);
  return struct.array;
}

""");
    }
    if (container == Container.struct) {
      buffer.write("""
final class ${elementType.dartCType}Struct extends Struct {
${[
        for (int i = 0; i < manyCount; i++)
          '''
@${elementType.dartCType}()
external ${elementType.dartType} a$i;
'''
      ].join()}
}

${elementType.dartCType}Struct make${elementType.dartCType}Struct(int length){
  assert(length == 20);
  final typedData = make${pointerType.dartTypedData}(length);
  final struct = Struct.create<${elementType.dartCType}Struct>(typedData);
  return struct;
}

""");
    }

    for (final test in container.tests) {
      final methodName = test.testName(container, elementType);
      switch (test) {
        case Test.self:
          buffer.write("""
void $methodName() {
  const length = 20;
  final $varName = make${testName}(length);
  final expectedResult = makeExpectedResult${elementType.dartCType}(0, length);
  final result = take${elementType.dartCType}Pointer($varName.address, length);
  Expect.$equals(expectedResult, result);
}

""");
        case Test.elementAt:
          buffer.write("""
void $methodName() {
  const length = $manyCount;
  final $varName = make${testName}(length);
  final expectedResult = makeExpectedResult${elementType.dartCType}(0, length);
  final result = take${elementType.dartCType}PointerMany(${[
            for (int i = 0; i < manyCount; i++) '$varName[$i].address,'
          ].join()});
  Expect.$equals(expectedResult, result);
}
""");
        case Test.view:
          buffer.write("""
void $methodName() {
  const sourceLength = 30;
  const viewStart = 10;
  const viewLength = 10;
  final viewEnd = viewStart + viewLength;
  final source = make${pointerType.dartTypedData}(sourceLength);
  final view = ${pointerType.dartTypedData}.sublistView(source, viewStart, viewEnd);
  final expectedResult = makeExpectedResult${elementType.dartCType}(viewStart, viewEnd);
  final result = take${elementType.dartCType}Pointer(view.address, view.length);
  Expect.$equals(expectedResult, result);
}

""");
        case Test.viewMany:
          buffer.write("""
void $methodName() {
  const length = $manyCount;
  final typedData = make${pointerType.dartTypedData}(length);
  final expectedResult = makeExpectedResult${elementType.dartCType}(0, length);
  final result = take${elementType.dartCType}PointerMany(${[
            for (int i = 0; i < manyCount; i++)
              '${pointerType.dartTypedData}.sublistView(typedData, $i, $i + 1).address,'
          ].join()});
  Expect.$equals(expectedResult, result);
}

""");
        case Test.field:
          buffer.write("""
void $methodName() {
  const length = $manyCount;
  final $varName = make${testName}(length);
  final expectedResult = makeExpectedResult${elementType.dartCType}(0, length);
  final result = take${elementType.dartCType}PointerMany(${[
            for (int i = 0; i < manyCount; i++) '$varName.a$i.address,'
          ].join()});
  Expect.$equals(expectedResult, result);
}
""");
      }
    }
  }

  if (container == Container.struct) {
    final elementType = int16;
    for (final compoundType in [
      StructType([elementType]),
      UnionType([elementType])
    ]) {
      final compoundKind = compoundType is StructType ? 'Struct' : 'Union';
      final pointerType = PointerType(compoundType);

      buffer.write(compoundType.dartClass());

      buffer.write('''
@Native<${elementType.dartCType} Function(
  ${[for (int i = 0; i < manyCount; i++) '${pointerType.dartCType},'].join()}
)>(symbol: 'Take${compoundKind}2BytesIntPointerMany', isLeaf: true)
external ${elementType.dartType} take${compoundKind}2BytesIntPointerMany(
  ${[
        for (int i = 0; i < manyCount; i++)
          '${pointerType.dartCType} pointer$i,',
      ].join()}
);

void testAddressOf${compoundKind}PointerMany() {
  const length = $manyCount;
  final typedData = makeInt16List(length);
${[
        for (int i = 0; i < manyCount; i++)
          'final struct$i = ${compoundKind}.create<${compoundKind}2BytesInt>(typedData, $i);'
      ].join()}
  final expectedResult = makeExpectedResult${elementType.dartCType}(0, length);
  final result = take${compoundKind}2BytesIntPointerMany(${[
        for (int i = 0; i < manyCount; i++) 'struct$i.address,'
      ].join()});
  Expect.equals(expectedResult, result);
}
''');
    }
  }

  final path = testPath(container);
  await File(path).writeAsString(buffer.toString());
  await runProcess(Platform.resolvedExecutable, ["format", path]);
}

Future<void> writeDartShared() async {
  final StringBuffer buffer = StringBuffer();
  buffer.write(headerDart(
    copyrightYear: 2024,
  ));

  for (final elementType in Container.struct.elementTypes) {
    final pointerType = PointerType(elementType);
    String value = elementType.isSigned ? 'i % 2 == 0 ? i : -i' : 'i';
    if (elementType.isFloatingPoint) {
      value = '($value).toDouble()';
    }

    buffer.write("""
@Native<${elementType.dartCType} Function(${pointerType.dartCType}, Size)>(symbol: 'Take${elementType.dartCType}Pointer', isLeaf: true)
external ${elementType.dartType} take${elementType.dartCType}Pointer(${pointerType.dartCType} pointer, int length);

@Native<${elementType.dartCType} Function(
  ${[for (int i = 0; i < manyCount; i++) '${pointerType.dartCType},'].join()}
)>(symbol: 'Take${elementType.dartCType}PointerMany', isLeaf: true)
external ${elementType.dartType} take${elementType.dartCType}PointerMany(
  ${[
      for (int i = 0; i < manyCount; i++) '${pointerType.dartCType} pointer$i,',
    ].join()}
);

""");
    if (elementType != bool_) {
      buffer.write("""
${pointerType.dartTypedData} make${pointerType.dartTypedData}(int length) {
  final typedData = ${pointerType.dartTypedData}(length);
  for (int i = 0; i < length; i++) {
    final value = $value;
    typedData[i] = value;
  }
  return typedData;
}

${elementType.dartType} makeExpectedResult${elementType.dartCType}(int start, int end) {
  ${elementType.dartType} expectedResult = 0;
  for (int i = start; i < end; i++) {
    final value = $value;
    expectedResult += value;
  }
  return expectedResult;
}

""");
    }
  }

  final path = Platform.script
      .resolve("../../ffi/address_of_generated_shared.dart")
      .toFilePath();
  ;
  await File(path).writeAsString(buffer.toString());
  await runProcess(Platform.resolvedExecutable, ["format", path]);
}

String testPath(Container container) {
  final lowerCase = container.name.toLowerCase();
  return Platform.script
      .resolve("../../ffi/address_of_${lowerCase}_generated_test.dart")
      .toFilePath();
}

String headerDart({
  required int copyrightYear,
}) {
  return """
${headerCommon(copyrightYear: copyrightYear, generatorPath: generatorPath)}
//
// SharedObjects=ffi_test_functions
// VMOptions=
// VMOptions=--deterministic --optimization-counter-threshold=90
// VMOptions=--use-slow-path
// VMOptions=--use-slow-path --stacktrace-every=100

// ignore_for_file: unused_import

import 'dart:ffi';
import 'dart:typed_data';

import 'package:expect/expect.dart';

import 'address_of_generated_shared.dart';
import 'address_of_shared.dart';
import 'dylib_utils.dart';

final ffiTestFunctions = dlopenPlatformSpecific('ffi_test_functions');

""";
}

const manyCount = 20;

Future<void> writeC() async {
  final StringBuffer buffer = StringBuffer();
  buffer.write(headerC(copyrightYear: 2024, generatorPath: generatorPath));

  for (final elementType in Container.struct.elementTypes) {
    final pointerType = PointerType(elementType);

    String coutCast(String input) {
      if (elementType == uint8 || elementType == int8 || elementType == bool_) {
        return "static_cast<int>($input)";
      }
      return input;
    }

    String opCast(String input) {
      if (elementType == bool_) {
        return "static_cast<int>($input)";
      }
      return input;
    }

    buffer.write('''
DART_EXPORT ${elementType.cType} Take${elementType.dartCType}Pointer(${pointerType.cType} data, size_t length) {
  ${elementType.cType} result = ${elementType.zero};
  if (length > 100) {
    std::cout << "Mangled arguments\\n";
    return result;
  }
  for (size_t i = 0; i < length; i++) {
    std::cout << "data[" << i << "] = " << ${coutCast('data[i]')} << "\\n";
    result ${elementType.addAssignOp} ${opCast('data[i]')};
  }
  return result;
}

DART_EXPORT ${elementType.cType} Take${elementType.dartCType}PointerMany(
  ${[
      for (int i = 0; i < manyCount; i++) '${pointerType.cType} data$i'
    ].join(',')}
) {
  ${elementType.cType} result = ${elementType.zero};
  ${[
      for (int i = 0; i < manyCount; i++)
        '''
std::cout << "data$i[0] = " << ${coutCast('data$i[0]')} << "\\n";
result ${elementType.addAssignOp} ${opCast('data$i[0]')};''',
    ].join('\n')}
  return result;
}

''');
  }

  final elementType = int16;
  for (final compoundType in [
    StructType([elementType]),
    UnionType([elementType])
  ]) {
    final pointerType = PointerType(compoundType);

    buffer.write(compoundType.cDefinition);

    buffer.write('''
DART_EXPORT ${elementType.cType} Take${compoundType.dartCType}PointerMany(
  ${[
      for (int i = 0; i < manyCount; i++) '${pointerType.cType} data$i'
    ].join(',')}
) {
  ${elementType.cType} result = ${elementType.zero};
  ${[
      for (int i = 0; i < manyCount; i++)
        '''
std::cout << "data$i->a0 = " << ${'data$i->a0'} << "\\n";
result += data$i->a0;''',
    ].join('\n')}
  return result;
}
  
''');
  }

  buffer.write(footerC);

  await File(ccPath).writeAsString(buffer.toString());
  await runProcess("clang-format", ["-i", ccPath]);
}

final ccPath = Platform.script
    .resolve("../../../runtime/bin/ffi_test/ffi_test_functions_generated_2.cc")
    .toFilePath();
