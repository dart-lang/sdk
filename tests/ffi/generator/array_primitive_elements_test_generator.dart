// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'c_types.dart';
import 'utils.dart';

void main() async {
  final StringBuffer buffer = StringBuffer();

  buffer.write(headerDart(copyrightYear: 2025));
  buffer.write(mainFunction(supportedTypes));
  for (FundamentalType type in supportedTypes) {
    buffer.write(testStruct(type));
    buffer.write(testBackedByTypedData(type));
    buffer.write(testBackedByInt64List(type));
    buffer.write(testBackedByPointer(type));
    buffer.write(testWriteToElementsBackedByTypedData(type));
    buffer.write(testWriteToElementsBackedByPointer(type));
    buffer.write(testElementsFirstAndLast(type));
    if (typedDataListTypes.contains(type)) {
      buffer.write(testElementsTypedDataListBackedByTypedData(type));
      buffer.write(testElementsTypedDataListBackedByPointer(type));
      if (type.size != 1) buffer.write(testMisaligned(type));
    }
  }

  final path = Platform.script
      .resolve('../array_primitive_elements_generated_test.dart')
      .toFilePath();
  await File(path).writeAsString(buffer.toString());
  await runProcess(Platform.resolvedExecutable, ['format', path]);
}

final List<FundamentalType> typedDataListTypes = [
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
];

final List<FundamentalType> supportedTypes = [
  ...typedDataListTypes,
  bool_,
  wchar, // Exercises `AbiSpecificIntegerArray.elements`.
];

const generatorPath =
    'tests/ffi/generator/array_primitive_elements_test_generator.dart';

String headerDart({required int copyrightYear}) {
  return """
${headerCommon(copyrightYear: copyrightYear, generatorPath: generatorPath)}
//
// SharedObjects=ffi_test_functions
// VMOptions=
// VMOptions=--deterministic --optimization-counter-threshold=90
// VMOptions=--use-slow-path
// VMOptions=--use-slow-path --stacktrace-every=100

import 'dart:ffi';
import 'dart:typed_data';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

const int arrayLength = 5;

""";
}

String testBackedByTypedDataFunctionName(FundamentalType type) =>
    'test${type.dartCType}ArrayElements';
String testBackedByInt64ListFunctionName(FundamentalType type) =>
    'test${type.dartCType}ArrayBackedByInt64ListElements';
String testBackedByPointerFunctionName(FundamentalType type) =>
    'testMalloced${type.dartCType}ArrayElements';
String testWriteToElementsBackedByTypedDataFunctionName(FundamentalType type) =>
    'testWriteTo${type.dartCType}ArrayElementsBackedByTypedData';
String testWriteToElementsBackedByPointerFunctionName(FundamentalType type) =>
    'testWriteTo${type.dartCType}ArrayElementsBackedByPointer';
String testElementsFirstAndLastFunctionName(FundamentalType type) =>
    'test${type.dartCType}ArrayElementsFirstAndLast';
String testElementsTypedDataListBackedByTypedDataFunctionName(
  FundamentalType type,
) => 'test${type.dartCType}ArrayElementsTypedDataListBackedByTypedData';
String testElementsTypedDataListBackedByPointerFunctionName(
  FundamentalType type,
) => 'test${type.dartCType}ArrayElementsTypedDataListBackedByPointer';
String testMisalignedFunctionName(FundamentalType type) =>
    'test${type.dartCType}Misaligned';

String structName(FundamentalType type, [String prefix = '']) =>
    '$prefix${type.dartCType}ArrayStruct';

String mainFunction(List<FundamentalType> typesToTest) {
  String testFunctions = [
    for (FundamentalType type in typesToTest) ...[
      '${testBackedByTypedDataFunctionName(type)}();',
      '${testBackedByInt64ListFunctionName(type)}();',
      '${testBackedByPointerFunctionName(type)}();',
      '${testWriteToElementsBackedByTypedDataFunctionName(type)}();',
      '${testWriteToElementsBackedByPointerFunctionName(type)}();',
      '${testElementsFirstAndLastFunctionName(type)}();',
      if (typedDataListTypes.contains(type)) ...[
        '${testElementsTypedDataListBackedByTypedDataFunctionName(type)}();',
        '${testElementsTypedDataListBackedByPointerFunctionName(type)}();',
        if (type.size != 1) '${testMisalignedFunctionName(type)}();',
      ],
    ],
  ].join('\n');

  return """
void main() {
  // Loop enough to trigger optimizations or stacktraces. See "VMOptions" above.
  for (int i = 0; i < 100; ++i) {
    $testFunctions
  }
}
""";
}

String testStruct(FundamentalType type, [String namePrefix = '']) {
  return """
final class ${structName(type, namePrefix)} extends Struct {
  // Placeholder value before array to test the offset calculation logic.
  @Int8()
  external int placeholder;

  @Array(arrayLength)
  external Array<${type.dartCType}> array;
}
""";
}

String testBackedByTypedData(FundamentalType type) {
  return """
void ${testBackedByTypedDataFunctionName(type)}() {
  final struct = Struct.create<${structName(type)}>();
  final array = struct.array;
  final expected = <${type.dartType}>[];
  for (int i = 0; i < arrayLength; i++) {
    final value = ${calculateArrayItem(type, 'i')};
    array[i] = value;
    expected.add(value);
  }
  Expect.listEquals(expected, array.elements);
}
""";
}

String testBackedByInt64List(FundamentalType type) {
  return """
void ${testBackedByInt64ListFunctionName(type)}() {
  final list = Int64List(6);
  final struct = Struct.create<${structName(type)}>(list);
  final array = struct.array;
  final expected = <${type.dartType}>[];
  for (int i = 0; i < arrayLength; i++) {
    final value = ${calculateArrayItem(type, 'i')};
    array[i] = value;
    expected.add(value);
  }
  Expect.listEquals(expected, array.elements);
}
""";
}

String testBackedByPointer(FundamentalType type) {
  return """
void ${testBackedByPointerFunctionName(type)}() {
  final struct = malloc<${structName(type)}>();
  final array = struct.ref.array;
  final expected = <${type.dartType}>[];
  for (int i = 0; i < arrayLength; i++) {
    final value = ${calculateArrayItem(type, 'i')};
    array[i] = value;
    expected.add(value);
  }
  Expect.listEquals(expected, array.elements);
  malloc.free(struct);
}
""";
}

String testWriteToElementsBackedByTypedData(FundamentalType type) {
  return """
void ${testWriteToElementsBackedByTypedDataFunctionName(type)}() {
  final struct = Struct.create<${structName(type)}>();
  final array = struct.array;
  final expected = <${type.dartType}>[];
  for (int i = 0; i < arrayLength; i++) {
    final value = ${calculateArrayItem(type, 'i')};
    array.elements[i] = value;
    expected.add(value);
  }
  Expect.listEquals(expected, array.elements);
  final actual = <${type.dartType}>[];
  for (int i = 0; i < arrayLength; i++) {
    actual.add(array[i]);
  }
  Expect.listEquals(expected, actual);
}
""";
}

String testWriteToElementsBackedByPointer(FundamentalType type) {
  return """
void ${testWriteToElementsBackedByPointerFunctionName(type)}() {
  final struct = malloc<${structName(type)}>();
  final array = struct.ref.array;
  final expected = <${type.dartType}>[];
  for (int i = 0; i < arrayLength; i++) {
    final value = ${calculateArrayItem(type, 'i')};
    array.elements[i] = value;
    expected.add(value);
  }
  Expect.listEquals(expected, array.elements);
  final actual = <${type.dartType}>[];
  for (int i = 0; i < arrayLength; i++) {
    actual.add(array[i]);
  }
  Expect.listEquals(expected, actual);
  malloc.free(struct);
}
""";
}

String testElementsFirstAndLast(FundamentalType type) {
  return """
void ${testElementsFirstAndLastFunctionName(type)}() {
  final struct = Struct.create<${structName(type)}>();
  final elements = struct.array.elements;
  var value = ${calculateArrayItem(type, '3')};
  elements.first = value;
  Expect.equals(value, elements.first);
  value = ${calculateArrayItem(type, '4')};
  elements.last = value;
  Expect.equals(value, elements.last);
}
""";
}

String testElementsTypedDataListBackedByTypedData(FundamentalType type) {
  return """
void ${testElementsTypedDataListBackedByTypedDataFunctionName(type)}() {
  final struct = Struct.create<${structName(type)}>();
  final array = struct.array;
  final elements = array.elements;
  Expect.equals(sizeOf<${type.dartCType}>(), elements.offsetInBytes);
  Expect.equals(sizeOf<${type.dartCType}>() * arrayLength, elements.lengthInBytes);
  Expect.equals(sizeOf<${type.dartCType}>(), elements.elementSizeInBytes);

  final expected = <${type.dartType}>[];
  for (int i = 0; i < arrayLength; i++) {
    final value = ${calculateArrayItem(type, 'i')};
    array[i] = value;
    expected.add(value);
  }

  Expect.equals(expected.first, elements.first);
  Expect.equals(expected.last, elements.last);

  // Removed one element from the beginning and one from the end.
  final view = ${typedDataListName(type)}.view(
    elements.buffer,
    elements.offsetInBytes + sizeOf<${type.dartCType}>(), 
    arrayLength - 2,
  );
  Expect.listEquals(expected.sublist(1, arrayLength - 1), view);
  Expect.listEquals(expected.sublist(1, arrayLength - 1), ${typedDataListName(type)}.sublistView(elements, 1, arrayLength - 1));
}
""";
}

String testElementsTypedDataListBackedByPointer(FundamentalType type) {
  return """
void ${testElementsTypedDataListBackedByPointerFunctionName(type)}() {
  final struct = malloc<${structName(type)}>();
  final array = struct.ref.array;
  final elements = array.elements;
  Expect.equals(0, elements.offsetInBytes);
  Expect.equals(sizeOf<${type.dartCType}>() * arrayLength, elements.lengthInBytes);
  Expect.equals(sizeOf<${type.dartCType}>(), elements.elementSizeInBytes);

  final expected = <${type.dartType}>[];
  for (int i = 0; i < arrayLength; i++) {
    final value = ${calculateArrayItem(type, 'i')};
    array[i] = value;
    expected.add(value);
  }

  Expect.equals(expected.first, elements.first);
  Expect.equals(expected.last, elements.last);

  // Removed one element from the beginning and one from the end.
  final view = ${typedDataListName(type)}.view(
    elements.buffer,
    elements.offsetInBytes + sizeOf<${type.dartCType}>(), 
    arrayLength - 2,
  );
  Expect.listEquals(expected.sublist(1, arrayLength - 1), view);
  Expect.listEquals(expected.sublist(1, arrayLength - 1), ${typedDataListName(type)}.sublistView(elements, 1, arrayLength - 1));
  malloc.free(struct);
}
""";
}

String testMisaligned(FundamentalType type) {
  const String prefix = 'Packed';
  return """
@Packed(1)
${testStruct(type, prefix)}

void ${testMisalignedFunctionName(type)}() {
  final structPointer = malloc<${structName(type, prefix)}>();
  var array = structPointer.ref.array;
  var e = Expect.throwsArgumentError(() => array.elements);
  Expect.isTrue(
    e.message.contains(
      'Pointer address must be aligned to a multiple of the element size',
    ),
  );
  malloc.free(structPointer);

  final struct = Struct.create<${structName(type, prefix)}>();
  array = struct.array;
  e = Expect.throwsRangeError(() => array.elements);
  Expect.isTrue(e.message.contains('must be a multiple of BYTES_PER_ELEMENT'));
}
""";
}

String calculateArrayItem(FundamentalType type, String indexVar) {
  if (type.isBool) {
    return '$indexVar.isEven';
  }
  if (type.isFloatingPoint) {
    return '100.0 + $indexVar';
  }
  return '100 + $indexVar';
}

String typedDataListName(FundamentalType type) => switch (type) {
  float => 'Float32List',
  double_ => 'Float64List',
  FundamentalType() => '${type.dartCType}List',
};
