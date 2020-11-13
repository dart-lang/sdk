// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server/src/services/correction/sort_members.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_utilities/package_root.dart';
import 'package:test/test.dart';

void main() {
  var provider = PhysicalResourceProvider.INSTANCE;
  var normalizedRoot = provider.pathContext.normalize(packageRoot);
  var packagePath =
      provider.pathContext.join(normalizedRoot, 'analysis_server_client');
  // TODO(brianwilkerson) Fix the generator to sort the generated files and
  //  remove these exclusions.
  var generatedFilePaths = [
    provider.pathContext
        .join(packagePath, 'lib', 'src', 'protocol', 'protocol_common.dart'),
    provider.pathContext
        .join(packagePath, 'lib', 'src', 'protocol', 'protocol_constants.dart'),
    provider.pathContext
        .join(packagePath, 'lib', 'src', 'protocol', 'protocol_generated.dart'),
  ];

  var collection = AnalysisContextCollection(
      includedPaths: <String>[packagePath],
      excludedPaths: generatedFilePaths,
      resourceProvider: provider);
  var contexts = collection.contexts;
  if (contexts.length != 1) {
    fail('The directory $packagePath contains multiple analysis contexts.');
  }

  buildTestsIn(contexts[0].currentSession, packagePath, generatedFilePaths,
      provider.getFolder(packagePath));
}

void buildTestsIn(AnalysisSession session, String testDirPath,
    List<String> generatedFilePaths, Folder directory) {
  var pathContext = session.resourceProvider.pathContext;
  var children = directory.getChildren();
  children.sort((first, second) => first.shortName.compareTo(second.shortName));
  for (var child in children) {
    if (child is Folder) {
      buildTestsIn(session, testDirPath, generatedFilePaths, child);
    } else if (child is File && child.shortName.endsWith('.dart')) {
      var path = child.path;
      if (generatedFilePaths.contains(path)) {
        continue;
      }
      var relativePath = pathContext.relative(path, from: testDirPath);
      test(relativePath, () {
        var result = session.getParsedUnit(path);
        if (result.state != ResultState.VALID) {
          fail('Could not parse $path');
        }
        var code = result.content;
        var unit = result.unit;
        var errors = result.errors;
        if (errors.isNotEmpty) {
          fail('Errors found when parsing $path');
        }
        var sorter = MemberSorter(code, unit);
        var edits = sorter.sort();
        if (edits.isNotEmpty) {
          fail('Unsorted file $path');
        }
      });
    }
  }
}
