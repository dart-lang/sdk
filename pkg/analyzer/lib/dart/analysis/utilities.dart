// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:meta/meta.dart';

/// Return the result of parsing the file at the given [path].
///
/// If a [resourceProvider] is given, it will be used to access the file system.
///
/// Note that if more than one file is going to be parsed then this function is
/// inefficient. Clients should instead use [AnalysisContextCollection] to
/// create one or more contexts and use those contexts to parse the files.
ParsedUnitResult parseFile(
    {@required String path, ResourceProvider resourceProvider}) {
  AnalysisContext context =
      _createAnalysisContext(path: path, resourceProvider: resourceProvider);
  return context.currentSession.getParsedUnit(path);
}

/// Return the result of resolving the file at the given [path].
///
/// If a [resourceProvider] is given, it will be used to access the file system.
///
/// Note that if more than one file is going to be resolved then this function
/// is inefficient. Clients should instead use [AnalysisContextCollection] to
/// create one or more contexts and use those contexts to resolve the files.
Future<ResolvedUnitResult> resolveFile(
    {@required String path, ResourceProvider resourceProvider}) async {
  AnalysisContext context =
      _createAnalysisContext(path: path, resourceProvider: resourceProvider);
  return await context.currentSession.getResolvedUnit(path);
}

/// Return a newly create analysis context in which the file at the given [path]
/// can be analyzed.
///
/// If a [resourceProvider] is given, it will be used to access the file system.
AnalysisContext _createAnalysisContext(
    {@required String path, ResourceProvider resourceProvider}) {
  AnalysisContextCollection collection = new AnalysisContextCollection(
    includedPaths: <String>[path],
    resourceProvider: resourceProvider ?? PhysicalResourceProvider.INSTANCE,
  );
  List<AnalysisContext> contexts = collection.contexts;
  if (contexts.length != 1) {
    throw new ArgumentError('path must be an absolute path to a single file');
  }
  return contexts[0];
}
