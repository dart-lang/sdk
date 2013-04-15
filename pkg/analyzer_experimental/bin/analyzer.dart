#!/usr/bin/env dart

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** The entry point for the analyzer. */
library analyzer;

import 'dart:async';
import 'dart:io';

import 'package:analyzer_experimental/options.dart';

// Exit status codes.
const OK_EXIT = 0;
const ERROR_EXIT = 1;

void main() {
  run(new Options().arguments).then((result) {
    exit(result.error ? ERROR_EXIT : OK_EXIT);
  });
}

/** The result of an analysis. */
class AnalysisResult {
  final bool error;
  AnalysisResult.forFailure() : error = true;
  AnalysisResult.forSuccess() : error = false;
}


/**
 * Runs the dart analyzer with the command-line options in [args].
 * See [CommandLineOptions] for a list of valid arguments.
 */
Future<AnalysisResult> run(List<String> args) {

  var options = new CommandLineOptions.parse(args);
  if (options == null) {
    return new Future.value(new AnalysisResult.forFailure());
  }

  //TODO(pquitslund): call out to analyzer...

}