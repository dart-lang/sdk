// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../tool/spec/from_html.dart';

/// Define tests to fail if there's no mention in the coverage file.
void main() {
  // parse the API file
  var pathPrefix = path.join(pkg_root.packageRoot, 'analysis_server');
  var api = readApi(pkg_root.packageRoot);

  var coverageFile = File(
    path.join(pathPrefix, 'integration_test', 'coverage.md'),
  );
  var lines = coverageFile.readAsLinesSync();

  // ## server domain
  var coveredDomains =
      lines
          .where((line) => line.startsWith('## ') && line.endsWith(' domain'))
          .map(
            (line) =>
                line
                    .substring('##'.length, line.length - 'domain'.length)
                    .trim(),
          )
          .toSet();

  // Remove any ' (test failed)' suffixes.
  lines =
      lines.map((String line) {
        var index = line.indexOf('(');
        return index != -1 ? line.substring(0, index).trim() : line;
      }).toList();

  // - [ ] server.getVersion
  var allMembers =
      lines
          .where((line) => line.startsWith('- '))
          .map((line) => line.substring('- [ ]'.length).trim())
          .toSet();
  var coveredMembers =
      lines
          .where((line) => line.startsWith('- [x]'))
          .map((line) => line.substring('- [x]'.length).trim())
          .toSet();

  // generate domain tests
  for (var domain in api.domains) {
    group('integration coverage of ${domain.name}', () {
      // domain
      test('domain', () {
        if (!coveredDomains.contains(domain.name)) {
          fail('${domain.name} domain not found in ${coverageFile.path}');
        }
      });

      // requests
      group('request', () {
        for (var request in domain.requests) {
          var fullName = '${domain.name}.${request.method}';
          test(fullName, () {
            if (!allMembers.contains(fullName)) {
              fail('$fullName not found in ${coverageFile.path}');
            }

            var fileName = getCamelWords(
              request.method,
            ).map((s) => s.toLowerCase()).join('_');
            var testName = path.join(domain.name, '${fileName}_test.dart');
            var testPath = path.join(pathPrefix, 'integration_test', testName);

            // Test that if checked, a test file exists; if not checked, no such
            // file exists.
            var fileExists = FileSystemEntity.isFileSync(testPath);
            var isMarkedAsCovered = coveredMembers.contains(fullName);
            expect(
              fileExists,
              isMarkedAsCovered,
              reason:
                  isMarkedAsCovered
                      ? '$testName marked as covered but has no test at $testPath'
                      : '$testName marked as not covered has test at $testPath',
            );
          });
        }
      });
    });
  }

  // validate no unexpected domains
  group('integration coverage', () {
    test('no unexpected domains', () {
      for (var domain in coveredDomains) {
        expect(api.domains.map((d) => d.name), contains(domain));
      }
    });
  });
}
