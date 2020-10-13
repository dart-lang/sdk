// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Benchmark for UTF-8 decoding

// @dart=2.9

import 'dart:convert';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';

import 'datext_latin1_10k.dart';
import 'entext_ascii_10k.dart';
import 'netext_3_10k.dart';
import 'rutext_2_10k.dart';
import 'sktext_10k.dart';
import 'zhtext_10k.dart';

class Utf8Decode extends BenchmarkBase {
  final String language;
  final String text;
  final int size;
  final bool allowMalformed;
  List<Uint8List> chunks;
  int totalInputSize;
  int totalOutputSize;

  static String _makeName(String language, int size, bool allowMalformed) {
    String name = 'Utf8Decode.$language.';
    name += size >= 1000000
        ? '${size ~/ 1000000}M'
        : size >= 1000 ? '${size ~/ 1000}k' : '$size';
    if (allowMalformed) name += '.malformed';
    return name;
  }

  Utf8Decode(this.language, this.text, this.size, this.allowMalformed)
      : super(_makeName(language, size, allowMalformed));

  @override
  void setup() {
    final Uint8List data = utf8.encode(text) as Uint8List;
    if (data.length != 10000) {
      throw 'Expected input data of exactly 10000 bytes.';
    }
    if (size < data.length) {
      // Split into chunks.
      chunks = <Uint8List>[];
      int startPos = 0;
      for (int pos = size; pos < data.length; pos += size) {
        int endPos = pos;
        while ((data[endPos] & 0xc0) == 0x80) {
          endPos--;
        }
        chunks.add(Uint8List.fromList(data.sublist(startPos, endPos)));
        startPos = endPos;
      }
      chunks.add(Uint8List.fromList(data.sublist(startPos, data.length)));
      totalInputSize = data.length;
      totalOutputSize = text.length;
    } else if (size > data.length) {
      // Repeat data to the desired length.
      final Uint8List expanded = Uint8List(size);
      for (int i = 0; i < size; i++) {
        expanded[i] = data[i % data.length];
      }
      chunks = <Uint8List>[expanded];
      totalInputSize = size;
      totalOutputSize = text.length * size ~/ data.length;
    } else {
      // Use data as is.
      chunks = <Uint8List>[data];
      totalInputSize = data.length;
      totalOutputSize = text.length;
    }
  }

  @override
  void run() {
    int lengthSum = 0;
    for (int i = 0; i < chunks.length; i++) {
      final String s = utf8.decode(chunks[i], allowMalformed: allowMalformed);
      lengthSum += s.length;
    }
    if (lengthSum != totalOutputSize) {
      throw 'Output length doesn\'t match expected.';
    }
  }

  @override
  void exercise() {
    // Only a single run per measurement.
    run();
  }

  @override
  void warmup() {
    BenchmarkBase.measureFor(run, 1000);
  }

  @override
  double measure() {
    // Report time per input byte.
    return super.measure() / totalInputSize;
  }

  @override
  void report() {
    // Report time in nanoseconds.
    final double score = measure() * 1000.0;
    print('$name(RunTime): $score ns.');
  }
}

void main(List<String> args) {
  const texts = {
    'en': en,
    'da': da,
    'sk': sk,
    'ru': ru,
    'ne': ne,
    'zh': zh,
  };
  final bool testMalformed =
      args != null && args.isNotEmpty && args.first == 'malformed';
  final benchmarks = [
    // Only benchmark with allowMalformed: false unless specified otherwise.
    for (bool allowMalformed in [false, if (testMalformed) true])
      for (int size in [10, 10000, 10000000])
        for (String language in texts.keys)
          () => Utf8Decode(language, texts[language], size, allowMalformed)
  ];

  for (var bm in benchmarks) {
    bm().report();
  }
}
