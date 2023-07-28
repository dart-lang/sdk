import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';

class DartCLIStartup extends BenchmarkBase {
  const DartCLIStartup() : super('DartCLIStartup');

  // The benchmark code.
  @override
  void run() {
    try {
      Process.runSync(Platform.executable, ['help']);
    } catch (e) {
      print('Error occurred: $e');
    }
  }
}

void main() {
  const DartCLIStartup().report();
}
