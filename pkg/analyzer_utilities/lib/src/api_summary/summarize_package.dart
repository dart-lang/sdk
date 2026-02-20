// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_utilities/src/api_summary/src/api_description.dart';
import 'package:analyzer_utilities/src/api_summary/src/node.dart';

/// Creates a human-readable text summary of the public API of a package, in a
/// format suitable for auditing with a `diff` tool.
///
/// [packagePath] is the path to the directory containing the package's
/// `pubspec.yaml` file.
///
/// [packageName] is the name of the package.
Future<String> summarizePackage(String packagePath, String packageName) async {
  var provider = PhysicalResourceProvider.INSTANCE;
  var collection = AnalysisContextCollection(
    includedPaths: [packagePath],
    resourceProvider: provider,
  );
  // Use `.single` to make sure that `collection` just contains a single
  // context. This ensures that `publicApi.build` will see all the files in
  // the package.
  var context = collection.contexts.single;
  var publicApi = ApiDescription(packageName);
  var stringBuffer = StringBuffer();
  printNodes(stringBuffer, await publicApi.build(context));
  return stringBuffer.toString();
}
