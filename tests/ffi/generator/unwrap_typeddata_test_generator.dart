// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'c_types.dart';
import 'utils.dart';

void main() async {
  await Future.wait([
    writeC(),
    for (bool isNative in [true, false]) writeDart(isNative: isNative),
  ]);
}

final elementTypes = [
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

const generatorPath =
    'tests/ffi/generator/unwrap_typeddata_test_generator.dart';

Future<void> writeDart({
  required bool isNative,
}) async {
  final StringBuffer buffer = StringBuffer();
  buffer.write(headerDart(
    copyrightYear: 2023,
  ));

  final forceDlOpen = !isNative
      ? ''
      : '''
  // Force dlopen so @Native lookups in DynamicLibrary.process() succeed.
  dlopenGlobalPlatformSpecific('ffi_test_functions');

''';

  buffer.write("""
void main() {$forceDlOpen
  for (int i = 0; i < 100; ++i) {
""");

  for (final elementType in elementTypes) {
    final pointerType = PointerType(elementType);
    buffer.write("""
    testUnwrap${pointerType.dartTypedData}();
    testUnwrap${pointerType.dartTypedData}View();
    testUnwrap${pointerType.dartTypedData}Many();
""");
  }

  buffer.write("""
  }
}

""");

  for (final elementType in elementTypes) {
    final pointerType = PointerType(elementType);
    String value = elementType.isSigned ? 'i % 2 == 0 ? i : -i' : 'i';
    if (elementType.isFloatingPoint) {
      value = '($value).toDouble()';
    }
    final equals = elementType.isFloatingPoint ? 'approxEquals' : 'equals';

    final manyDartCTypes = Iterable.generate(
      many,
      (i) => '${pointerType.dartCType}',
    ).join(',');
    final manyArgs = Iterable.generate(
      many,
      (i) => '${pointerType.dartTypedData} typedData$i',
    ).join(',');
    final manyBodies = Iterable.generate(
      many,
      (i) =>
          '${pointerType.dartTypedData}.view(source.buffer, elementSize * $i, 1)',
    ).join(',');

    if (isNative) {
      buffer.write("""
@Native<${elementType.dartCType} Function(${pointerType.dartCType}, Size)>(symbol: 'Unwrap${pointerType.dartTypedData}', isLeaf: true)
external ${elementType.dartType} unwrap${pointerType.dartTypedData}(${pointerType.dartTypedData} typedData, int length);

@Native<${elementType.dartCType} Function($manyDartCTypes,)>(symbol: 'Unwrap${pointerType.dartTypedData}Many', isLeaf: true)
external ${elementType.dartType} unwrap${pointerType.dartTypedData}Many($manyArgs,);

""");
    } else {
      buffer.write("""
final unwrap${pointerType.dartTypedData} = ffiTestFunctions.lookupFunction<
    ${elementType.dartCType} Function(${pointerType.dartCType}, Size),
    ${elementType.dartType} Function(${pointerType.dartTypedData}, int)>('Unwrap${pointerType.dartTypedData}', isLeaf: true);

final unwrap${pointerType.dartTypedData}Many = ffiTestFunctions.lookupFunction<
    ${elementType.dartCType} Function($manyDartCTypes,),
    ${elementType.dartType} Function($manyArgs,)>('Unwrap${pointerType.dartTypedData}Many', isLeaf: true);

""");
    }

    buffer.write("""
void testUnwrap${pointerType.dartTypedData}() {
  const length = 10;
  final typedData = ${pointerType.dartTypedData}(length);
  ${elementType.dartType} expectedResult = 0;
  for (int i = 0; i < length; i++) {
    final value = $value;
    typedData[i] = value;
    expectedResult += value;
  }
  final result = unwrap${pointerType.dartTypedData}(typedData, typedData.length);
  Expect.$equals(expectedResult, result);
}

void testUnwrap${pointerType.dartTypedData}View() {
  const sourceLength = 30;
  const elementSize = ${elementType.size};
  const viewStart = 10;
  const viewOffsetInBytes = viewStart * elementSize;
  const viewLength = 10;
  final viewEnd = viewStart + viewLength;
  final source = ${pointerType.dartTypedData}(sourceLength);
  final view = ${pointerType.dartTypedData}.view(source.buffer, viewOffsetInBytes, viewLength);
  ${elementType.dartType} expectedResult = 0;
  for (int i = 0; i < sourceLength; i++) {
    final value = $value;
    source[i] = value;
    if (viewStart <= i && i < viewEnd) {
      expectedResult += value;
    }
  }
  final result = unwrap${pointerType.dartTypedData}(view, view.length);
  Expect.$equals(expectedResult, result);
}

void testUnwrap${pointerType.dartTypedData}Many() {
  const length = 20;
  const elementSize = ${elementType.size};
  final source = ${pointerType.dartTypedData}(length);
  ${elementType.dartType} expectedResult = 0;
  for (int i = 0; i < length; i++) {
    final value = $value;
    source[i] = value;
    expectedResult += value;
  }
  final result = unwrap${pointerType.dartTypedData}Many(
    $manyBodies,
  );
  Expect.$equals(expectedResult, result);
}

""");
  }

  final path = testPath(isNative: isNative);
  await File(path).writeAsString(buffer.toString());
  await runProcess(Platform.resolvedExecutable, ["format", path]);
}

String testPath({
  required bool isNative,
}) {
  final suffix = '${isNative ? '_native' : ''}';
  return Platform.script
      .resolve("../../ffi/unwrap_typeddata_generated${suffix}_test.dart")
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

import 'dart:ffi';
import 'dart:typed_data';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

final ffiTestFunctions = dlopenPlatformSpecific('ffi_test_functions');

""";
}

const many = 20;

Future<void> writeC() async {
  final StringBuffer buffer = StringBuffer();
  buffer.write(headerC(copyrightYear: 2023, generatorPath: generatorPath));

  for (final elementType in elementTypes) {
    final pointerType = PointerType(elementType);

    String coutCast(String input) {
      if (elementType == uint8 || elementType == int8) {
        return "static_cast<int>($input)";
      }
      return input;
    }

    final manyArgs = Iterable.generate(
      many,
      (i) => '${pointerType.cType} data$i',
    ).join(',');
    final manyBodies = Iterable.generate(
      many,
      (i) => '''
std::cout << "data$i[0] = " << ${coutCast('data$i[0]')} << "\\n";
result += data$i[0];''',
    ).join('\n');

    buffer.write('''
DART_EXPORT ${elementType.cType} Unwrap${pointerType.dartTypedData}(${pointerType.cType} data, size_t length) {
  ${elementType.cType} result = 0;
  for (size_t i = 0; i < length; i++) {
    std::cout << "data[" << i << "] = " << ${coutCast('data[i]')} << "\\n";
    result += data[i];
  }
  return result;
}

DART_EXPORT ${elementType.cType} Unwrap${pointerType.dartTypedData}Many($manyArgs) {
  ${elementType.cType} result = 0;
  $manyBodies
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
