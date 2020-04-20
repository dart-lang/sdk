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

import 'utils/package_root.dart';

void main() {
  var provider = PhysicalResourceProvider.INSTANCE;
  var normalizedRoot = provider.pathContext.normalize(packageRoot);
  var packagePath =
      provider.pathContext.join(normalizedRoot, 'analysis_server');
  var mockPackagesPath =
      provider.pathContext.join(packagePath, 'test', 'mock_packages');
  // TODO(brianwilkerson) Fix the generator to sort the generated files and
  //  remove these exclusions.
  var generatedFilePaths = <String>[
    provider.pathContext.join(
        packagePath, 'lib', 'lsp_protocol', 'protocol_custom_generated.dart'),
    provider.pathContext
        .join(packagePath, 'lib', 'lsp_protocol', 'protocol_generated.dart'),
    provider.pathContext
        .join(packagePath, 'lib', 'protocol', 'protocol_constants.dart'),
    provider.pathContext
        .join(packagePath, 'lib', 'protocol', 'protocol_generated.dart'),
    provider.pathContext.join(packagePath, 'lib', 'src', 'edit',
        'nnbd_migration', 'resources', 'resources.g.dart'),
    provider.pathContext.join(packagePath, 'test', 'integration', 'support',
        'integration_test_methods.dart'),
    provider.pathContext.join(packagePath, 'test', 'integration', 'support',
        'protocol_matchers.dart'),
    // The following are not generated, but can't be sorted because the contain
    // ignore comments in the directives, which sorting deletes.
    provider.pathContext
        .join(packagePath, 'lib', 'src', 'edit', 'edit_domain.dart'),
    provider.pathContext
        .join(packagePath, 'lib', 'src', 'services', 'kythe', 'schema.dart'),
    provider.pathContext.join(
        packagePath, 'test', 'services', 'completion', 'dart', 'test_all.dart'),
  ];

  var collection = AnalysisContextCollection(
      includedPaths: <String>[packagePath],
      excludedPaths: [mockPackagesPath, ...generatedFilePaths],
      resourceProvider: provider);
  var contexts = collection.contexts;
  if (contexts.length != 1) {
    fail('The directory $packagePath contains multiple analysis contexts.');
  }

  buildTestsIn(contexts[0].currentSession, packagePath, generatedFilePaths,
      mockPackagesPath, provider.getFolder(packagePath));
}

void buildTestsIn(
    AnalysisSession session,
    String testDirPath,
    List<String> generatedFilePaths,
    String mockPackagesPath,
    Folder directory) {
  var pathContext = session.resourceProvider.pathContext;
  var children = directory.getChildren();
  children.sort((first, second) => first.shortName.compareTo(second.shortName));
  for (var child in children) {
    if (child is Folder) {
      if (child.path != mockPackagesPath) {
        buildTestsIn(
            session, testDirPath, generatedFilePaths, mockPackagesPath, child);
      }
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
