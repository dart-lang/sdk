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
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  var provider = PhysicalResourceProvider.INSTANCE;
  var normalizedRoot = provider.pathContext.normalize(packageRoot);
  var packagePath = provider.pathContext.join(normalizedRoot, 'analyzer_cli');
  var testDataPath = provider.pathContext.join(packagePath, 'test', 'data');

  var collection = AnalysisContextCollection(
      includedPaths: <String>[packagePath],
      excludedPaths: [testDataPath],
      resourceProvider: provider);
  var contexts = collection.contexts;
  if (contexts.length != 1) {
    fail('The directory $packagePath contains multiple analysis contexts.');
  }

  buildTestsIn(contexts[0].currentSession, packagePath, testDataPath,
      provider.getFolder(packagePath));
}

void buildTestsIn(AnalysisSession session, String testDirPath,
    String testDataPath, Folder directory) {
  var pathContext = session.resourceProvider.pathContext;
  var children = directory.getChildren();
  children.sort((first, second) => first.shortName.compareTo(second.shortName));
  for (var child in children) {
    if (child is Folder) {
      if (child.path != testDataPath) {
        buildTestsIn(session, testDirPath, testDataPath, child);
      }
    } else if (child is File && child.shortName.endsWith('.dart')) {
      var path = child.path;
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
