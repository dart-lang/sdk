// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show ParserError, parse;

import 'package:testing/testing.dart'
    show Chain, ChainContext, Result, Step, runMe;

import '../../utils/scanner_chain.dart' show Read, Scan, ScannedFile;

Future<ChainContext> createContext(
    Chain suite, Map<String, String> environment) async {
  return new ScannerContext();
}

class ScannerContext extends ChainContext {
  final List<Step> steps = const <Step>[
    const Read(),
    const Scan(),
    const Parse(),
  ];
}

class Parse extends Step<ScannedFile, Null, ChainContext> {
  const Parse();

  String get name => "parse";

  Future<Result<Null>> run(ScannedFile file, ChainContext context) async {
    try {
      List<ParserError> errors = parse(file.result.tokens);
      if (errors.isNotEmpty) {
        return fail(null, errors.join("\n"));
      }
    } on ParserError catch (e, s) {
      return fail(null, e, s);
    }
    return pass(null);
  }
}

main(List<String> arguments) =>
    runMe(arguments, createContext, configurationPath: "../../../testing.json");
