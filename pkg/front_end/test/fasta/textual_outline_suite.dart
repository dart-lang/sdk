// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.textual_outline_test;

import 'dart:io';

import 'package:_fe_analyzer_shared/src/scanner/abstract_scanner.dart'
    show ScannerConfiguration;

import 'package:dart_style/dart_style.dart' show DartFormatter;

import 'package:front_end/src/fasta/util/textual_outline.dart';
import 'package:testing/testing.dart'
    show
        Chain,
        ChainContext,
        Expectation,
        ExpectationSet,
        Result,
        Step,
        TestDescription,
        runMe;

import '../utils/kernel_chain.dart' show MatchContext;
import 'testing/suite.dart' show UPDATE_EXPECTATIONS;

const List<Map<String, String>> EXPECTATIONS = [
  {
    "name": "ExpectationFileMismatch",
    "group": "Fail",
  },
  {
    "name": "ExpectationFileMissing",
    "group": "Fail",
  },
  {
    "name": "EmptyOutput",
    "group": "Fail",
  },
  {
    "name": "FormatterCrash",
    "group": "Fail",
  },
];

Future<Context> createContext(
    Chain suite, Map<String, String> environment) async {
  return new Context(environment["updateExpectations"] == "true");
}

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, configurationPath: "../../testing.json");

class Context extends ChainContext with MatchContext {
  final bool updateExpectations;

  @override
  String get updateExpectationsOption => '${UPDATE_EXPECTATIONS}=true';

  Context(this.updateExpectations);

  final List<Step> steps = const <Step>[
    const TextualOutline(),
  ];

  final ExpectationSet expectationSet =
      new ExpectationSet.fromJsonList(EXPECTATIONS);
}

class TextualOutline extends Step<TestDescription, TestDescription, Context> {
  const TextualOutline();

  String get name => "TextualOutline";

  Future<Result<TestDescription>> run(
      TestDescription description, Context context) async {
    List<int> bytes = new File.fromUri(description.uri).readAsBytesSync();
    for (bool modelled in [false, true]) {
      String result = textualOutline(bytes,
          throwOnUnexpected: true,
          performModelling: modelled,
          addMarkerForUnknownForTest: modelled,
          configuration:
              const ScannerConfiguration(enableExtensionMethods: true));
      if (result == null) {
        return new Result(
            null, context.expectationSet["EmptyOutput"], description.uri);
      }

      // In an attempt to make it less sensitive to formatting first remove
      // excess new lines, then format.
      List<String> lines = result.split("\n");
      bool containsUnknownChunk = false;
      StringBuffer sb = new StringBuffer();
      for (String line in lines) {
        if (line.trim() != "") {
          if (line == "---- unknown chunk starts ----") {
            containsUnknownChunk = true;
          }
          sb.writeln(line);
        }
      }
      result = sb.toString().trim();

      dynamic formatterException;
      StackTrace formatterExceptionSt;
      if (!containsUnknownChunk) {
        // Try to format only if it doesn't contain the unknown chunk marker.
        try {
          result = new DartFormatter().format(result);
        } catch (e, st) {
          formatterException = e;
          formatterExceptionSt = st;
        }
      }

      String filename = ".textual_outline.expect";
      if (modelled) {
        filename = ".textual_outline_modelled.expect";
      }

      Result expectMatch = await context.match<TestDescription>(
          filename, result, description.uri, description);
      if (expectMatch.outcome != Expectation.Pass) return expectMatch;

      if (formatterException != null) {
        return new Result(
            null, context.expectationSet["FormatterCrash"], formatterException,
            trace: formatterExceptionSt);
      }
    }

    return new Result.pass(description);
  }
}
