// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This tool gives a breakdown of code size by deferred part in the program.
library dart2js_info.bin.deferred_library_size;

import 'dart:math';

import 'package:args/command_runner.dart';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/io.dart';

import 'usage_exception.dart';

/// This tool gives a breakdown of code size by deferred part in the program.
class DeferredLibrarySize extends Command<void> with PrintUsageException {
  final String name = "deferred_size";
  final String description = "Show breakdown of codesize by deferred part.";

  void run() async {
    var args = argResults.rest;
    if (args.length < 1) {
      usageException('Missing argument: info.data');
    }
    // TODO(het): Would be faster to only parse the 'outputUnits' part
    var info = await infoFromFile(args.first);
    var sizeByImport = getSizeByImport(info);
    printSizes(sizeByImport, info.program.size);
  }
}

class ImportSize {
  final String import;
  final int size;

  const ImportSize(this.import, this.size);

  String toString() {
    return '$import: $size';
  }
}

void printSizes(Map<String, int> sizeByImport, int programSize) {
  var importSizes = <ImportSize>[];
  sizeByImport.forEach((import, size) {
    importSizes.add(new ImportSize(import, size));
  });
  // Sort by size, largest first.
  importSizes.sort((a, b) => b.size - a.size);
  int longest = importSizes.fold('Percent of code deferred'.length,
      (longest, importSize) => max(longest, importSize.import.length));

  _printRow(label, data, {int width: 15}) {
    print('${label.toString().padRight(longest + 1)}'
        '${data.toString().padLeft(width)}');
  }

  print('');
  print('Size by library');
  print('-' * (longest + 16));
  for (var importSize in importSizes) {
    // TODO(het): split into specific and shared size
    _printRow(importSize.import, importSize.size);
  }
  print('-' * (longest + 16));

  var mainChunkSize = sizeByImport['main'];
  var deferredSize = programSize - mainChunkSize;
  var percentDeferred = (deferredSize * 100 / programSize).toStringAsFixed(2);
  _printRow('Main chunk size', mainChunkSize);
  _printRow('Deferred code size', deferredSize);
  _printRow('Percent of code deferred', '$percentDeferred%');
}

Map<String, int> getSizeByImport(AllInfo info) {
  var sizeByImport = <String, int>{};
  for (var outputUnit in info.outputUnits) {
    if (outputUnit.name == 'main' || outputUnit.name == null) {
      sizeByImport['main'] = outputUnit.size;
    } else {
      for (var import in outputUnit.imports) {
        sizeByImport.putIfAbsent(import, () => 0);
        sizeByImport[import] += outputUnit.size;
      }
    }
  }
  return sizeByImport;
}
