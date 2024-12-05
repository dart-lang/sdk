// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This tool gives a breakdown of code size by deferred part in the program.
library;

import 'dart:math';

import 'package:args/command_runner.dart';
import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/io.dart';

import 'usage_exception.dart';

/// This tool gives a breakdown of code size by deferred part in the program.
class DeferredLibrarySize extends Command<void> with PrintUsageException {
  @override
  final String name = "deferred_size";
  @override
  final String description = "Show breakdown of codesize by deferred part.";

  @override
  void run() async {
    final args = argResults!.rest;
    if (args.isEmpty) {
      usageException('Missing argument: info.data');
    }
    // TODO(het): Would be faster to only parse the 'outputUnits' part
    final info = await infoFromFile(args.first);
    final sizeByImport = getSizeByImport(info);
    printSizes(sizeByImport, info.program!.size);
  }
}

class ImportSize {
  final String import;
  final int size;

  const ImportSize(this.import, this.size);

  @override
  String toString() {
    return '$import: $size';
  }
}

void printSizes(Map<String, int> sizeByImport, int programSize) {
  final importSizes = <ImportSize>[];
  sizeByImport.forEach((import, size) {
    importSizes.add(ImportSize(import, size));
  });
  // Sort by size, largest first.
  importSizes.sort((a, b) => b.size - a.size);
  int longest = importSizes.fold('Percent of code deferred'.length,
      (longest, importSize) => max(longest, importSize.import.length));

  void printRow(label, data, {int width = 15}) {
    print('${label.toString().padRight(longest + 1)}'
        '${data.toString().padLeft(width)}');
  }

  print('');
  print('Size by library');
  print('-' * (longest + 16));
  for (var importSize in importSizes) {
    // TODO(het): split into specific and shared size
    printRow(importSize.import, importSize.size);
  }
  print('-' * (longest + 16));

  final mainChunkSize = sizeByImport['main']!;
  final deferredSize = programSize - mainChunkSize;
  final percentDeferred = (deferredSize * 100 / programSize).toStringAsFixed(2);
  printRow('Main chunk size', mainChunkSize);
  printRow('Deferred code size', deferredSize);
  printRow('Percent of code deferred', '$percentDeferred%');
}

Map<String, int> getSizeByImport(AllInfo info) {
  var sizeByImport = <String, int>{};
  for (final outputUnit in info.outputUnits) {
    if (outputUnit.name == 'main') {
      sizeByImport['main'] = outputUnit.size;
    } else {
      for (final import in outputUnit.imports) {
        sizeByImport.update(import, (value) => value + outputUnit.size,
            ifAbsent: () => outputUnit.size);
      }
    }
  }
  return sizeByImport;
}
