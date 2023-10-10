// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../test/util/tree_string_sink.dart';

String formatSizeInBytes(int value) {
  final buffer = StringBuffer();
  buffer.write('$value');

  final kb = value ~/ 1024;
  if (kb > 0) {
    buffer.write(' = $kb KB');
  }

  final mb = kb ~/ 1024;
  if (mb > 0) {
    buffer.write(' = $mb MB');
  }

  final gb = mb / 1024;
  if (gb >= 1.0) {
    buffer.write(' = ${gb.toStringAsFixed(2)} GB');
  }

  return buffer.toString();
}

void writeBenchmarkResult(TreeStringSink sink, BenchmarkResult result) {
  switch (result) {
    case BenchmarkResultBytes():
      final sizeStr = formatSizeInBytes(result.value);
      sink.writelnWithIndent('${result.name}: $sizeStr');
    case BenchmarkResultCompound():
      sink.writelnWithIndent(result.name);
      sink.withIndent(() {
        for (final child in result.children) {
          writeBenchmarkResult(sink, child);
        }
      });
    case BenchmarkResultCount():
      sink.writelnWithIndent('${result.name}: ${result.value}');
  }
}

sealed class BenchmarkResult {
  final String name;

  BenchmarkResult({
    required this.name,
  });
}

final class BenchmarkResultBytes extends BenchmarkResult {
  final int value;

  BenchmarkResultBytes({
    required super.name,
    required this.value,
  });
}

final class BenchmarkResultCompound extends BenchmarkResult {
  final List<BenchmarkResult> children = [];

  BenchmarkResultCompound({
    required super.name,
    List<BenchmarkResult>? children,
  }) {
    if (children != null) {
      this.children.addAll(children);
    }
  }

  void add(BenchmarkResult child) {
    children.add(child);
  }
}

final class BenchmarkResultCount extends BenchmarkResult {
  final int value;

  BenchmarkResultCount({
    required super.name,
    required this.value,
  });
}
