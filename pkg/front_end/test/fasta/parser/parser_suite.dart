// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show ParserError, parse;
import 'package:front_end/src/fasta/source/diet_parser.dart';

import 'package:testing/testing.dart'
    show Chain, ChainContext, Result, Step, runMe;

import '../../utils/scanner_chain.dart' show Read, Scan, ScannedFile;

Future<ChainContext> createContext(
    Chain suite, Map<String, String> environment) {
  return new Future.value(new ScannerContext());
}

class ScannerContext extends ChainContext {
  @override
  final List<Step> steps = const <Step>[
    const Read(),
    const Scan(),
    const Parse(),
  ];
}

class Parse extends Step<ScannedFile, Null, ChainContext> {
  const Parse();

  @override
  String get name => "parse";

  @override
  Future<Result<Null>> run(ScannedFile file, ChainContext context) {
    try {
      List<ParserError> errors = parse(file.result.tokens,
          useImplicitCreationExpression: useImplicitCreationExpressionInCfe);
      if (errors.isNotEmpty) {
        return new Future.value(fail(null, errors.join("\n")));
      }
    } on ParserError catch (e, s) {
      return new Future.value(fail(null, e, s));
    }
    return new Future.value(pass(null));
  }
}

void main(List<String> arguments) =>
    runMe(arguments, createContext, configurationPath: "../../../testing.json");
