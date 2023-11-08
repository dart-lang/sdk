// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.testing.scanner_chain;

import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ScannerResult, scan;

import 'package:_fe_analyzer_shared/src/scanner/io.dart' show readBytesFromFile;

import 'package:testing/testing.dart'
    show ChainContext, Result, Step, TestDescription;

class ReadFile {
  final Uri uri;

  final Uint8List bytes;

  const ReadFile(this.uri, this.bytes);
}

class ScannedFile {
  final ReadFile file;

  final ScannerResult result;

  const ScannedFile(this.file, this.result);
}

class Read extends Step<TestDescription, ReadFile, ChainContext> {
  const Read();

  @override
  String get name => "read";

  @override
  Future<Result<ReadFile>> run(
      TestDescription input, ChainContext context) async {
    return pass(new ReadFile(input.uri, await readBytesFromFile(input.uri)));
  }
}

class Scan extends Step<ReadFile, ScannedFile, ChainContext> {
  const Scan();

  @override
  String get name => "scan";

  @override
  Future<Result<ScannedFile>> run(ReadFile file, ChainContext context) {
    return new Future.value(pass(new ScannedFile(file, scan(file.bytes))));
  }
}
