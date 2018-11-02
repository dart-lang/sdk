// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/parser.dart' show Parser;

import 'package:front_end/src/fasta/scanner.dart' show ScannerResult;

import 'package:front_end/src/fasta/source/type_promotion_look_ahead_listener.dart'
    show TypePromotionLookAheadListener;

import 'package:front_end/src/fasta/testing/scanner_chain.dart' show Read, Scan;

import 'package:testing/testing.dart';

Future<ChainContext> createContext(
    Chain suite, Map<String, String> environment) async {
  return new TypePromotionLookAheadContext();
}

class TypePromotionLookAheadContext extends ChainContext {
  final List<Step> steps = const <Step>[
    const Read(),
    const Scan(),
    const TypePromotionLookAheadStep()
  ];
}

class TypePromotionLookAheadStep
    extends Step<ScannerResult, Null, TypePromotionLookAheadContext> {
  const TypePromotionLookAheadStep();

  String get name => "Type Promotion Look Ahead";

  Future<Result<Null>> run(
      ScannerResult scan, TypePromotionLookAheadContext context) async {
    Parser parser = new Parser(new TypePromotionLookAheadListener());
    parser.parseUnit(scan.tokens);
    return pass(null);
  }
}

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, "../../testing.json");
