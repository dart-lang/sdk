// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/fasta/token_utils.dart';
import 'package:front_end/src/scanner/errors.dart' as analyzer;
import 'package:front_end/src/scanner/reader.dart' as analyzer;
import 'package:front_end/src/scanner/scanner.dart' as analyzer;
import 'package:front_end/src/scanner/token.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'scanner_fasta_test.dart';
import 'scanner_test.dart';

main() {
  // round trip test removed
}

class TestScanner extends analyzer.Scanner {
  TestScanner(analyzer.CharacterReader reader) : super.create(reader);

  @override
  void reportError(
      analyzer.ScannerErrorCode errorCode, int offset, List<Object> arguments) {
    fail('Unexpected error $errorCode while scanning offset $offset\n'
        '   arguments: $arguments');
  }
}
