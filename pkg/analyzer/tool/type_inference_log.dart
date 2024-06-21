// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:args/args.dart';
import 'package:path/path.dart';

/// This program analyzes a single source file with type inference logging
/// enabled, and prints out the resulting log.
Future<void> main(List<String> args) async {
  var argParser = ArgParser();
  var argResults = argParser.parse(args);
  var paths = argResults.rest;
  if (paths.length != 1) {
    print('Exactly one path must be specified.');
    exit(1);
  }
  var filePath = normalize(absolute(paths.single));
  var contextCollection = AnalysisContextCollection(
    includedPaths: [filePath],
  );
  inferenceLoggingPredicate = (source) => source.fullName == filePath;
  var result = await contextCollection
      .contextFor(filePath)
      .currentSession
      .getResolvedUnit(filePath);
  if (result is! ResolvedUnitResult) {
    print('Failed to resolve `$filePath`: ${result.runtimeType}');
    exit(1);
  }
  if (!result.exists) {
    print('File does not exist: `$filePath`');
    exit(1);
  }
  var errors = result.errors;
  if (errors.isNotEmpty) {
    print('${errors.length} errors found:');
    for (var error in errors) {
      print('  $error');
    }
  }
}
