// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

//
// Configuration.
//

const nativeToDartType = {
  'Int8': 'int',
  'Int16': 'int',
  'Int32': 'int',
  'Int64': 'int',
  'Uint8': 'int',
  'Uint16': 'int',
  'Uint32': 'int',
  'Uint64': 'int',
  'Float': 'double',
  'Double': 'double',
  'Pointer<Uint8>': 'Pointer<Uint8>',
  'Handle': 'Object',
};

const generateFor = {
  'Int8': [1],
  'Int16': [1],
  'Int32': [1, 2, 4, 10, 20],
  'Int64': [1, 2, 4, 10, 20],
  'Uint8': [1],
  'Uint16': [1],
  'Uint32': [1],
  'Uint64': [1],
  'Float': [1, 2, 4, 10, 20],
  'Double': [1, 2, 4, 10, 20],
  'Pointer<Uint8>': [1, 2, 4, 10, 20],
  'Handle': [1, 2, 4, 10, 20],
};

const allNumbers = [1, 2, 4, 10, 20];

//
// Generator.
//

void main() {
  final List<String> nativeTypes = nativeToDartType.keys.toList();
  final List<String> dartTypes = nativeToDartType.values.toSet().toList();
  final List<String> nativeIntTypes = nativeTypes.where(isInt).toList();
  final List<String> nativeDoubleTypes = nativeTypes.where(isDouble).toList();
  final List<String> nativePointerTypes = nativeTypes.where(isPointer).toList();
  final List<String> nativeHandleTypes = nativeTypes.where(isHandle).toList();

  final StringBuffer buffer = StringBuffer();
  buffer.write(header);
  generateTypedefs(buffer, 'Function', dartTypes, allNumbers);
  generateTypedefs(buffer, 'NativeFunction', nativeTypes, allNumbers);
  generateBenchmarkInt(buffer, nativeIntTypes);
  generateBenchmarkDouble(buffer, nativeDoubleTypes);
  generateBenchmarkPointer(buffer, nativePointerTypes);
  generateBenchmarkHandle(buffer, nativeHandleTypes);

  final path = Platform.script.resolve('dart/benchmark_generated.dart').path;
  File(path).writeAsStringSync(buffer.toString());
  print(Process.runSync('dart', ['format', path]).stderr);
}

const header = '''
// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, run the following script:
//
// > dart benchmarks/FfiCall/generate_benchmarks.dart

// Using part of, so that the library uri is identical to the main file.
// That way the FfiNativeResolver works for the main uri.
part of 'FfiCall.dart';

''';

void generateTypedefs(StringBuffer buffer, String namePrefix,
    List<String> types, List<int> numbers) {
  for (String type in types) {
    for (int number in numbers) {
      final String name = '$namePrefix$number${toIdentifier(type)}';
      final String arguments = repeat(type, number, ', ');
      buffer.write('typedef $name = $type Function($arguments);');
    }
  }
}

void generateBenchmarkInt(StringBuffer buffer, List<String> types) {
  for (String type in types) {
    final String typeName = toIdentifier(type);
    final String dartType = toIdentifier(nativeToDartType[type]!);
    for (int number in generateFor[type]!) {
      final String name = '${typeName}x${'$number'.padLeft(2, '0')}';
      final String expected = IntVariation(type, number).expectedValue(number);
      final String functionType = 'Function$number$dartType';
      final String functionNativeType = 'NativeFunction$number$typeName';
      final String functionNameC = 'Function$number$typeName';
      final String argument = IntVariation(type, number).argument;
      final String arguments = repeat(argument, number, ', ');
      final String functionNameDart = 'function$number$typeName';
      final String dartArguments =
          List.generate(number, (i) => '$dartType a$i').join(', ');

      buffer.write('''
class $name extends FfiBenchmarkBase {
  final $functionType f;

  $name({bool isLeaf = false})
        : f = isLeaf
            ? ffiTestFunctions.lookupFunction<$functionNativeType,$functionType>('$functionNameC', isLeaf: true)
            : ffiTestFunctions.lookupFunction<$functionNativeType,$functionType>('$functionNameC', isLeaf: false),
        super('FfiCall.$name', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f($arguments);
    }
    expectEquals(x, $expected);
  }
}
''');

      for (bool isLeaf in [false, true]) {
        final leaf = isLeaf ? 'Leaf' : '';
        buffer.write('''
@Native<$functionNativeType>(symbol: '$functionNameC', isLeaf: $isLeaf)
external $dartType $functionNameDart$leaf($dartArguments);

class ${name}Native$leaf extends FfiBenchmarkBase {
  ${name}Native$leaf() : super('FfiCall.${name}Native', isLeaf: $isLeaf);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += $functionNameDart$leaf($arguments);
    }
    expectEquals(x, $expected);
  }
}
''');
      }
    }
  }
}

void generateBenchmarkDouble(StringBuffer buffer, List<String> types) {
  for (String type in types) {
    final String typeName = toIdentifier(type);
    final String dartType = toIdentifier(nativeToDartType[type]!);
    for (int number in generateFor[type]!) {
      final String name = '${typeName}x${'$number'.padLeft(2, '0')}';
      final String expected = number == 1
          ? 'N + N * 42.0' // Do work with single arg.
          : 'N * $number * ($number + 1) / 2 '; // The rest sums arguments.
      final String functionType = 'Function$number$dartType';
      final String functionNativeType = 'NativeFunction$number$typeName';
      final String functionNameC = 'Function$number$typeName';
      final List<double> argVals = List.generate(number, (i) => 1.0 * (i + 1));
      final String arguments = argVals.join(', ');
      final String functionNameDart = 'function$number$typeName';
      final String dartArguments =
          List.generate(number, (i) => '$dartType a$i').join(', ');
      buffer.write('''
class $name extends FfiBenchmarkBase {
  final $functionType f;

  $name({bool isLeaf = false})
        : f = isLeaf
            ? ffiTestFunctions.lookupFunction<$functionNativeType,$functionType>('$functionNameC', isLeaf: true)
            : ffiTestFunctions.lookupFunction<$functionNativeType,$functionType>('$functionNameC', isLeaf: false),
        super('FfiCall.$name', isLeaf: isLeaf);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += f($arguments);
    }
    final double expected = $expected;
    expectApprox(x, expected);
  }
}
''');

      for (bool isLeaf in [false, true]) {
        final leaf = isLeaf ? 'Leaf' : '';
        buffer.write('''
@Native<$functionNativeType>(symbol: '$functionNameC', isLeaf: $isLeaf)
external $dartType $functionNameDart$leaf($dartArguments);

class ${name}Native$leaf extends FfiBenchmarkBase {
  ${name}Native$leaf() : super('FfiCall.${name}Native', isLeaf: $isLeaf);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += $functionNameDart$leaf($arguments);
    }
    final double expected = $expected;
    expectApprox(x, expected);
  }
}
''');
      }
    }
  }
}

void generateBenchmarkPointer(StringBuffer buffer, List<String> types) {
  for (String type in types) {
    if (type != 'Pointer<Uint8>') throw Exception('Not implemented for $type.');
    final String typeName = toIdentifier(type);
    final String dartType = nativeToDartType[type]!;
    final String dartTypeName = toIdentifier(dartType);
    for (int number in generateFor[type]!) {
      final String name = '${typeName}x${'$number'.padLeft(2, '0')}';
      final List<String> pointerNames =
          List.generate(number, (i) => 'p${i + 1}');
      final String pointers =
          pointerNames.map((n) => '$type $n = nullptr;').join('\n');
      final String setup = List.generate(
          number - 1, (i) => 'p${i + 2} = p1.elementAt(${i + 1});').join();
      final String functionType = 'Function$number$dartTypeName';
      final String functionNativeType = 'NativeFunction$number$typeName';
      final String functionNameC = 'Function$number$typeName';
      final String arguments = pointerNames.skip(1).join(', ');
      final String functionNameDart = 'function$number$typeName';
      final String dartArguments =
          List.generate(number, (i) => '$dartType a$i').join(', ');
      buffer.write('''
class $name extends FfiBenchmarkBase {
  final $functionType f;

  $name({bool isLeaf = false})
        : f = isLeaf
            ? ffiTestFunctions.lookupFunction<$functionNativeType,$functionType>('$functionNameC', isLeaf: true)
            : ffiTestFunctions.lookupFunction<$functionNativeType,$functionType>('$functionNameC', isLeaf: false),
        super('FfiCall.$name', isLeaf: isLeaf);

  $pointers

  @override
  void setup() {
    p1 = calloc(N + 1);
    $setup
  }

  @override
  void teardown() {
    calloc.free(p1);
  }

  @override
  void run() {
  $type x = p1;
    for (int i = 0; i < N; i++) {
      x = f(x, $arguments);
    }
    expectEquals(x.address, p1.address + N * sizeOf<Uint8>());
  }
}
''');

      for (bool isLeaf in [false, true]) {
        final leaf = isLeaf ? 'Leaf' : '';
        buffer.write('''
@Native<$functionNativeType>(symbol: '$functionNameC', isLeaf: $isLeaf)
external $dartType $functionNameDart$leaf($dartArguments);

class ${name}Native$leaf extends FfiBenchmarkBase {
  ${name}Native$leaf() : super('FfiCall.${name}Native', isLeaf: $isLeaf);

  $pointers

  @override
  void setup() {
    p1 = calloc(N + 1);
    $setup
  }

  @override
  void teardown() {
    calloc.free(p1);
  }

  @override
  void run() {
  $type x = p1;
    for (int i = 0; i < N; i++) {
      x = $functionNameDart$leaf(x, $arguments);
    }
    expectEquals(x.address, p1.address + N * sizeOf<Uint8>());
  }
}
''');
      }
    }
  }
}

void generateBenchmarkHandle(StringBuffer buffer, List<String> types) {
  for (String type in types) {
    if (type != 'Handle') throw Exception('Not implemented for $type.');
    final String typeName = toIdentifier(type);
    final String dartType = toIdentifier(nativeToDartType[type]!);
    for (int number in generateFor[type]!) {
      final String name = '${typeName}x${'$number'.padLeft(2, '0')}';
      final String setup =
          List.generate(number + 1, (i) => 'final m$i = MyClass($i);')
              .skip(2)
              .join('\n');
      final String functionType = 'Function$number$dartType';
      final String functionNativeType = 'NativeFunction$number$typeName';
      final String functionNameC = 'Function$number$typeName';
      final String arguments =
          List.generate(number - 1, (i) => 'm${i + 2}').join(', ');
      final String functionNameDart = 'function$number$typeName';
      final String dartArguments =
          List.generate(number, (i) => '$dartType a$i').join(', ');
      buffer.write('''
class $name extends FfiBenchmarkBase {
  final $functionType f;

  $name()
        : f = ffiTestFunctions.lookupFunction<$functionNativeType,$functionType>('$functionNameC', isLeaf: false),
        super('FfiCall.$name', isLeaf: false);

  @override
  void run() {
    final m1 = MyClass(123);
    $setup
    Object x = m1;
    for (int i = 0; i < N; i++) {
      x = f(x, $arguments);
    }
    expectIdentical(x, m1);
  }
}

@Native<$functionNativeType>(symbol: '$functionNameC', isLeaf: false)
external $dartType $functionNameDart($dartArguments);

class ${name}Native extends FfiBenchmarkBase {
  ${name}Native() : super('FfiCall.${name}Native', isLeaf: false);

  @override
  void run() {
    final m1 = MyClass(123);
    $setup
    Object x = m1;
    for (int i = 0; i < N; i++) {
      x = $functionNameDart(x, $arguments);
    }
    expectIdentical(x, m1);
  }
}
''');
    }
  }
}

//
// Benchmark variations.
//

class IntVariation {
  /// The argument passed to the C function, the same value is passed if the C
  /// function has multiple parameters.
  final String argument;

  /// The expected value of summation of all return values.
  final String Function(int number) expectedValue;

  /// These benchmarks sum all arguments over all iterations.
  IntVariation.LargeIntManyArguments()
      : argument = 'i',
        expectedValue = ((int number) => 'N * (N - 1) * $number / 2');

  /// Benchmarks with only one argument return 42 added to the argument.
  IntVariation.LargeIntOneArgument()
      : argument = 'i',
        expectedValue = ((int number) => 'N * (N - 1) / 2 + N * 42');

  /// The benchmarks with small ints (`int8_t`, `uint8_t`, etc.) we pass an
  /// arbitrary fixed argument between 0 and 127 to prevent truncation.
  ///
  /// The C function returns 42 added to the argument.
  IntVariation.SmallInt()
      : argument = '17',
        expectedValue = ((int number) => 'N * 17 + N * 42');

  factory IntVariation(String type, int number) {
    if (isSmallInt(type)) {
      return IntVariation.SmallInt();
    }
    if (number == 1) {
      return IntVariation.LargeIntOneArgument();
    }
    return IntVariation.LargeIntManyArguments();
  }
}

//
// Helper functions.
//

String toIdentifier(String type) =>
    type.replaceAll('<', '').replaceAll('>', '');

String repeat(String input, int n, String separator) {
  if (n == 0) {
    return '';
  }

  return (input + separator) * (n - 1) + input;
}

bool isInt(String type) => type.startsWith('Int') || type.startsWith('Uint');

/// True for `int8_t`, `uint8_t`, `int16_t`, and `uint16_t`.
bool isSmallInt(String type) =>
    isInt(type) && (type.contains('8') || type.contains('16'));

bool isDouble(String type) =>
    type.startsWith('Float') || type.startsWith('Double');

bool isPointer(String type) => type.startsWith('Pointer');

bool isHandle(String type) => type == 'Handle';
