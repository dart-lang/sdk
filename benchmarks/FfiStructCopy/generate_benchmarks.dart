// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

Future<void> main() async {
  final contents = [
    header,
    for (final size in sizes) generateSize(size),
  ].join('\n');

  final uri = Platform.script.resolve('dart/benchmark_generated.dart');

  await File.fromUri(uri).writeAsString(contents);
}

const sizes = [
  1,
  32,
  1024,
  1024 * 32,
];

const header =
    '''// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'FfiStructCopy.dart';
''';

String generateSize(int size) => '''
final class Struct${size}Bytes extends Struct {
  @Array($size)
  external Array<Uint8> a0;
}

final class Struct${size}BytesWrapper extends Struct {
  external Struct${size}Bytes nested;
}

final class Copy${size}Bytes extends StructCopyBenchmark {
  @override
  Pointer<Struct${size}BytesWrapper> from = nullptr;
  @override
  Pointer<Struct${size}BytesWrapper> to = nullptr;

  Copy${size}Bytes() : super('FfiStructCopy.Copy${size}Bytes');

  @override
  int get copySizeInBytes => sizeOf<Struct${size}BytesWrapper>();

  @override
  void setup(int batchSize) {
    from = calloc(batchSize);
    to = calloc(batchSize);
  }

  @override
  void run(int batchSize) {
    for (int i = 0; i < batchSize; i++) {
      to[i].nested = from[i].nested;
    }
  }
}
''';
