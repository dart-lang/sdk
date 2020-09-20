// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Benchmark for UTF-8 encoding

import 'dart:convert';

import 'package:benchmark_harness/benchmark_harness.dart';

import 'datext_latin1_10k.dart';
import 'entext_ascii_10k.dart';
import 'netext_3_10k.dart';
import 'rutext_2_10k.dart';
import 'sktext_10k.dart';
import 'zhtext_10k.dart';

class Utf8Encode extends BenchmarkBase {
  final String language;
  final String originalText;
  // Size is measured in number of runes rather than number of bytes.
  // This differs from the Utf8Decode benchmark, but runes are the input
  // to the encode function which makes them more natural than bytes here.
  final int size;
  List<String> benchmarkTextChunks = List.empty(growable: true);

  static String _makeName(String language, int size) {
    String name = 'Utf8Encode.$language.';
    name += size >= 1000000
        ? '${size ~/ 1000000}M'
        : size >= 1000 ? '${size ~/ 1000}k' : '$size';
    return name;
  }

  Utf8Encode(this.language, this.originalText, this.size)
      : super(_makeName(language, size));

  @override
  void setup() {
    final int nRunes = originalText.runes.toList().length;
    final String repeatedText = originalText * (size / nRunes).ceil();
    final List<int> runes = repeatedText.runes.toList();
    final int nChunks = (size < nRunes) ? (nRunes / size).floor() : 1;
    for (int i = 0; i < nChunks; i++) {
      final offset = i * size;
      benchmarkTextChunks.add(String.fromCharCodes(runes.sublist(offset, offset+size)));
    }
  }

  @override
  void run() {
    for (int i = 0; i < benchmarkTextChunks.length; i++) {
      final encoded = utf8.encode(benchmarkTextChunks[i]);
      if (encoded.length < benchmarkTextChunks[i].length)  {
        throw 'There should be at least as many encoded bytes as runes';
      }
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
    // Report time per input rune.
    return super.measure() / size / benchmarkTextChunks.length;
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
  final benchmarks = [
    for (int size in [10, 10000, 10000000])
      for (String language in texts.keys)
        () => Utf8Encode(language, texts[language]!, size)
  ];

  for (var bm in benchmarks) {
    bm().report();
  }
}
