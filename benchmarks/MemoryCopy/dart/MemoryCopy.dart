// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Micro-benchmarks for copying typed data lists.

import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:ffi/ffi.dart';

const maxSizeInBytes = 10 * 1024 * 1024;

final argParser = ArgParser()
  ..addMultiOption('length',
      abbr: 'l',
      help: 'Byte length to benchmark',
      valueHelp: 'INT',
      defaultsTo: const [])
  ..addFlag('mebibytes-per-second',
      abbr: 'm', help: 'Show MiB/s', defaultsTo: false)
  ..addFlag('nanoseconds-per-byte',
      abbr: 'n', help: 'Show ns/byte', defaultsTo: false)
  ..addFlag('bytes-per-second',
      abbr: 'b', help: 'Show byte/s', defaultsTo: true)
  ..addFlag('verbose', abbr: 'v', help: 'Verbose output', defaultsTo: false)
  ..addFlag('aligned',
      abbr: 'a', help: 'Align results on initial numbers', defaultsTo: false);

class Emitter {
  final bool bytesPerSecond;
  final bool nanosecondsPerByte;
  final bool mebibytesPerSecond;
  final bool _alignedOutput;

  Emitter(ArgResults results)
      : bytesPerSecond = results['bytes-per-second'] || results['verbose'],
        nanosecondsPerByte =
            results['nanoseconds-per-byte'] || results['verbose'],
        mebibytesPerSecond =
            results['mebibytes-per-second'] || results['verbose'],
        _alignedOutput = results['aligned'];

  static final kValueRegexp = RegExp(r'^([0-9]+)');
  static final kMaxLabelLength =
      'MemoryCopy.1048576.setRange.TypedData.Double(NanosecondsPerChar)'.length;
  // Maximum expected number of digits on either side of the decimal point.
  static final kMaxDigits = 16;

  void printLabeledValue(String label, double value) {
    final valueString = value.toString();
    final buffer = StringBuffer();
    buffer
      ..write(label)
      ..write(': ');
    if (_alignedOutput) {
      final matches = kValueRegexp.firstMatch(valueString)!;
      final valuePadding = (kMaxLabelLength - label.length) +
          max<int>(kMaxDigits - matches[1]!.length, 0);
      buffer..write(' ' * valuePadding);
    }
    buffer.write(valueString);
    print(buffer.toString());
  }
}

// A modified version of BenchmarkBase from package:benchmark_harness where
// - the run() method takes a number of rounds, so that there is only one run()
//   call per measurement and thus the overhead of calling the run() method is
//   the same across subclass results.
// - the measureFor() method returns the number of bytes transfered per second,
//   not the number of microseconds per iteration (round).
abstract class MemoryCopyBenchmark {
  final String name;
  final int bytes;

  MemoryCopyBenchmark(String name, this.bytes) : name = 'MemoryCopy.$name';

  static const targetBatchSizeInBytes = 32 * 1024;

  // Returns the number of bytes copied per second.
  double measureFor(Duration minDuration) {
    // The logic below is based off of BenchmarkBase._measureForImpl.
    // We can't use BenchmarkBase.measureFor directly, because
    // * it calls the function in a loop instead of passing the number of
    //   desired iterations to the function being called. Here, method
    //   invocation would dominate the actual body for small byte counts.
    // * it doesn't provide the caller with the number of iterations performed,
    //   which we need to calculate the number of bytes transferred.

    // Start off with enough rounds to ensure a minimum number of bytes copied
    // per run() invocation.
    int rounds = max(targetBatchSizeInBytes ~/ bytes, 1);

    // If running a long measurement permit some amount of measurement jitter
    // to avoid discarding results that almost, but not quite, reach the minimum
    // duration requested.
    final allowedJitter = Duration(
        microseconds: minDuration.inSeconds > 0
            ? (minDuration.inMicroseconds * 0.1).floor()
            : 0);

    final watch = Stopwatch()..start();
    while (true) {
      // Try running for the current number of rounds and see if that reaches
      // the minimum duration requested, so we only get the elapsed time from
      // the StopWatch once for the final results used.
      watch.reset();
      run(rounds);
      final elapsed = watch.elapsed;
      final numberOfBytesCopied = rounds * bytes;
      if (elapsed >= (minDuration - allowedJitter)) {
        return (numberOfBytesCopied / elapsed.inMicroseconds) *
            Duration.microsecondsPerSecond;
      }
      // If not, then adjust our estimate of how many iterations are needed to
      // reach the minimum and try again.
      if (elapsed.inMilliseconds == 0) {
        rounds *= 1000;
      } else {
        rounds *= (minDuration.inMicroseconds / elapsed.inMicroseconds).ceil();
      }
    }
  }

  double measure() {
    setup();

    // Warmup for 100 ms.
    measureFor(const Duration(milliseconds: 100));

    // Run benchmark for 1 second.
    final double result = measureFor(const Duration(seconds: 1));

    teardown();
    return result;
  }

  void report(Emitter emitter) {
    final bytesPerSecond = measure();

    if (emitter.bytesPerSecond) {
      emitter.printLabeledValue('$name(BytesPerSecond)', bytesPerSecond);
    }
    if (emitter.nanosecondsPerByte) {
      const nanoSecondsPerSecond = 1000 * 1000 * 1000;
      final nanosecondsPerByte = nanoSecondsPerSecond / bytesPerSecond;
      emitter.printLabeledValue(
          '$name(NanosecondsPerChar)', nanosecondsPerByte);
    }
    if (emitter.mebibytesPerSecond) {
      const bytesPerMebibyte = 1024 * 1024;
      final mibPerSecond = bytesPerSecond / bytesPerMebibyte;
      emitter.printLabeledValue('$name(MebibytesPerSecond)', mibPerSecond);
    }
  }

  void setup();
  void teardown();
  void run(int rounds);
}

abstract class Uint8ListCopyBenchmark extends MemoryCopyBenchmark {
  final int count;
  late Uint8List input;
  late Uint8List result;

  Uint8ListCopyBenchmark(String method, int bytes)
      : count = bytes,
        super('$bytes.$method.TypedData.Uint8', bytes);

  @override
  void setup() {
    input = Uint8List(count);
    for (int i = 0; i < count; ++i) {
      input[i] = (i + 3) & 0xff;
    }
    result = Uint8List(maxSizeInBytes);
  }

  @override
  void teardown() {
    for (int i = 0; i < count; ++i) {
      final expected = (i + 3) & 0xff;
      if (result[i] != expected) {
        throw 'Expected result[$i] = $expected, got ${result[i]}';
      }
    }
    final expected = 0;
    for (int i = count; i < maxSizeInBytes; ++i) {
      if (result[i] != expected) {
        throw 'Expected result[$i] = $expected, got ${result[i]}';
      }
    }
  }
}

class Uint8ListCopyViaLoopBenchmark extends Uint8ListCopyBenchmark {
  Uint8ListCopyViaLoopBenchmark(int bytes) : super('loop', bytes);

  @override
  void run(int rounds) {
    final count = this.count;
    final input = this.input;
    final result = this.result;
    for (int r = 0; r < rounds; r++) {
      for (int i = 0; i < count; i++) {
        result[i] = input[i];
      }
    }
  }
}

class Uint8ListCopyViaSetRangeBenchmark extends Uint8ListCopyBenchmark {
  Uint8ListCopyViaSetRangeBenchmark(int bytes) : super('setRange', bytes);

  @override
  void run(int rounds) {
    for (int r = 0; r < rounds; r++) {
      result.setRange(0, count, input);
    }
  }
}

abstract class Float64ListCopyBenchmark extends MemoryCopyBenchmark {
  final int count;
  late Float64List input;
  late Float64List result;

  Float64ListCopyBenchmark(String method, int bytes)
      : count = bytes ~/ 8,
        super('$bytes.$method.TypedData.Double', bytes);

  static const maxSizeInElements = maxSizeInBytes ~/ 8;

  @override
  void setup() {
    input = Float64List(count);
    for (int i = 0; i < count; ++i) {
      input[i] = (i - 7).toDouble();
    }
    result = Float64List(maxSizeInElements);
  }

  @override
  void teardown() {
    for (int i = 0; i < count; ++i) {
      final expected = (i - 7).toDouble();
      if (result[i] != expected) {
        throw 'Expected result[$i] = $expected, got ${result[i]}';
      }
    }
    final expected = 0.0;
    for (int i = count; i < maxSizeInElements; ++i) {
      if (result[i] != expected) {
        throw 'Expected result[$i] = $expected, got ${result[i]}';
      }
    }
  }
}

class Float64ListCopyViaLoopBenchmark extends Float64ListCopyBenchmark {
  Float64ListCopyViaLoopBenchmark(int bytes) : super('loop', bytes);

  @override
  void run(int rounds) {
    final count = this.count;
    final input = this.input;
    final result = this.result;
    for (int r = 0; r < rounds; r++) {
      for (int i = 0; i < count; i++) {
        result[i] = input[i];
      }
    }
  }
}

class Float64ListCopyViaSetRangeBenchmark extends Float64ListCopyBenchmark {
  Float64ListCopyViaSetRangeBenchmark(int bytes) : super('setRange', bytes);

  @override
  void run(int rounds) {
    for (int r = 0; r < rounds; r++) {
      result.setRange(0, count, input);
    }
  }
}

abstract class PointerUint8CopyBenchmark extends MemoryCopyBenchmark {
  final int count;
  late Pointer<Uint8> input;
  late Pointer<Uint8> result;

  PointerUint8CopyBenchmark(String method, int bytes)
      : count = bytes,
        super('$bytes.$method.Pointer.Uint8', bytes);

  @override
  void setup() {
    input = malloc<Uint8>(count);
    for (var i = 0; i < count; ++i) {
      input[i] = (i + 3) & 0xff;
    }
    result = calloc<Uint8>(maxSizeInBytes);
  }

  @override
  void teardown() {
    malloc.free(input);
    for (var i = 0; i < count; ++i) {
      final expected = (i + 3) & 0xff;
      if (result[i] != expected) {
        throw 'Expected result[$i] = $expected, got ${result[i]}';
      }
    }
    final expected = 0;
    for (var i = count; i < maxSizeInBytes; ++i) {
      if (result[i] != expected) {
        throw 'Expected result[$i] = $expected, got ${result[i]}';
      }
    }
    calloc.free(result);
  }
}

class PointerUint8CopyViaLoopBenchmark extends PointerUint8CopyBenchmark {
  PointerUint8CopyViaLoopBenchmark(int bytes) : super('loop', bytes);

  @override
  void run(int rounds) {
    // Compare the setRange version to looping using Pointer.[]/Pointer.[]=.
    final count = this.count;
    final input = this.input;
    final result = this.result;
    for (int r = 0; r < rounds; r++) {
      for (int i = 0; i < count; i++) {
        result[i] = input[i];
      }
    }
  }
}

class PointerUint8CopyViaSetRangeBenchmark extends PointerUint8CopyBenchmark {
  PointerUint8CopyViaSetRangeBenchmark(int bytes) : super('setRange', bytes);

  @override
  void run(int rounds) {
    for (int r = 0; r < rounds; r++) {
      result
          .asTypedList(maxSizeInBytes)
          .setRange(0, count, input.asTypedList(count));
    }
  }
}

@Native<Void Function(Pointer<Void>, Pointer<Void>, Size)>(isLeaf: true)
external void memmove(Pointer<Void> to, Pointer<Void> from, int size);

class PointerUint8CopyViaMemmoveBenchmark extends PointerUint8CopyBenchmark {
  // This particular benchmark was originally written using memcpy, but a
  // better comparison is against memmove. While our benchmarks don't use
  // to and from memory that overlaps, in general this case must be handled.
  //
  // In order to not have to change the benchmark suite in golem, we keep the
  // old name for this result.
  PointerUint8CopyViaMemmoveBenchmark(int bytes) : super('memcpy', bytes);

  @override
  void run(int rounds) {
    for (int r = 0; r < rounds; r++) {
      memmove(result.cast(), input.cast(), count);
    }
  }
}

abstract class PointerDoubleCopyBenchmark extends MemoryCopyBenchmark {
  final int count;
  late Pointer<Double> input;
  late Pointer<Double> result;

  PointerDoubleCopyBenchmark(String method, int bytes)
      : count = bytes ~/ 8,
        super('$bytes.$method.Pointer.Double', bytes);

  static const maxSizeInElements = maxSizeInBytes ~/ 8;

  @override
  void setup() {
    input = malloc<Double>(count);
    for (var i = 0; i < count; ++i) {
      input[i] = (i - 7).toDouble();
    }
    result = calloc<Double>(maxSizeInElements);
  }

  @override
  void teardown() {
    malloc.free(input);
    for (var i = 0; i < count; ++i) {
      final expected = (i - 7).toDouble();
      if (result[i] != expected) {
        throw 'Expected result[$i] = $expected, got ${result[i]}';
      }
    }
    final expected = 0.0;
    for (var i = count; i < maxSizeInElements; ++i) {
      if (result[i] != expected) {
        throw 'Expected result[$i] = $expected, got ${result[i]}';
      }
    }
    calloc.free(result);
  }
}

class PointerDoubleCopyViaLoopBenchmark extends PointerDoubleCopyBenchmark {
  PointerDoubleCopyViaLoopBenchmark(int bytes) : super('loop', bytes);

  @override
  void run(int rounds) {
    // Compare the setRange version to looping using Pointer.[]/Pointer.[]=.
    final count = this.count;
    final input = this.input;
    final result = this.result;
    for (int r = 0; r < rounds; r++) {
      for (int i = 0; i < count; i++) {
        result[i] = input[i];
      }
    }
  }
}

class PointerDoubleCopyViaSetRangeBenchmark extends PointerDoubleCopyBenchmark {
  PointerDoubleCopyViaSetRangeBenchmark(int bytes) : super('setRange', bytes);

  @override
  void run(int rounds) {
    for (int r = 0; r < rounds; r++) {
      result
          .asTypedList(PointerDoubleCopyBenchmark.maxSizeInElements)
          .setRange(0, count, input.asTypedList(count));
    }
  }
}

final defaultLengthsInBytes = [8, 64, 512, 4 * 1024, 1024 * 1024];

void main(List<String> args) {
  final results = argParser.parse(args);
  List<int> lengthsInBytes = defaultLengthsInBytes;
  final emitter = Emitter(results);
  if (results['length'].isNotEmpty) {
    lengthsInBytes = (results['length'] as List<String>)
        .map(int.parse)
        .where((i) => i <= maxSizeInBytes)
        .toList();
  }
  final filter = results.rest.firstOrNull;
  final benchmarks = [
    for (int bytes in lengthsInBytes) ...[
      PointerUint8CopyViaMemmoveBenchmark(bytes),
      PointerUint8CopyViaLoopBenchmark(bytes),
      PointerDoubleCopyViaLoopBenchmark(bytes),
      Uint8ListCopyViaLoopBenchmark(bytes),
      Float64ListCopyViaLoopBenchmark(bytes),
      PointerUint8CopyViaSetRangeBenchmark(bytes),
      PointerDoubleCopyViaSetRangeBenchmark(bytes),
      Uint8ListCopyViaSetRangeBenchmark(bytes),
      Float64ListCopyViaSetRangeBenchmark(bytes),
    ],
  ];
  for (var bench in benchmarks) {
    if (filter == null || bench.name.contains(filter)) {
      bench.report(emitter);
    }
  }
}
