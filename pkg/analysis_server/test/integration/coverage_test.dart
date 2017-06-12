// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../tool/spec/api.dart';
import '../../tool/spec/from_html.dart';

/// Define tests to fail if there's no mention in the coverage file.
main() {
  Api api;
  File coverageFile;
  String pathPrefix;

  // parse the API file
  if (FileSystemEntity
      .isFileSync(path.join('tool', 'spec', 'spec_input.html'))) {
    api = readApi('.');
    pathPrefix = '.';
  } else {
    api = readApi(path.join('pkg', 'analysis_server'));
    pathPrefix = path.join('pkg', 'analysis_server');
  }

  coverageFile =
      new File(path.join(pathPrefix, 'test', 'integration', 'coverage.md'));
  List<String> lines = coverageFile.readAsLinesSync();

  // ## server domain
  Set<String> coveredDomains = lines
      .where((line) => line.startsWith('## ') && line.endsWith(' domain'))
      .map((line) =>
          line.substring('##'.length, line.length - 'domain'.length).trim())
      .toSet();

  // Remove any ' (test failed)' suffixes.
  lines = lines.map((String line) {
    int index = line.indexOf('(');
    return index != -1 ? line.substring(0, index).trim() : line;
  }).toList();

  // - [ ] server.getVersion
  Set<String> allMembers = lines
      .where((line) => line.startsWith('- '))
      .map((line) => line.substring('- [ ]'.length).trim())
      .toSet();
  Set<String> coveredMembers = lines
      .where((line) => line.startsWith('- [x]'))
      .map((line) => line.substring('- [x]'.length).trim())
      .toSet();

  // generate domain tests
  for (Domain domain in api.domains) {
    group('integration coverage of ${domain.name}', () {
      // domain
      test('domain', () {
        if (!coveredDomains.contains(domain.name)) {
          fail('${domain.name} domain not found in ${coverageFile.path}');
        }
      });

      // requests
      for (Request request in domain.requests) {
        String fullName = '${domain.name}.${request.method}';
        test(fullName, () {
          if (!allMembers.contains(fullName)) {
            fail('$fullName not found in ${coverageFile.path}');
          }

          final String fileName = getCamelWords(request.method)
              .map((s) => s.toLowerCase())
              .join('_');
          final String testName =
              path.join(domain.name, '${fileName}_test.dart');
          final String testPath =
              path.join(pathPrefix, 'test', 'integration', testName);

          // Test that if checked, a test file exists; if not checked, no such
          // file exists.
          expect(FileSystemEntity.isFileSync(testPath),
              coveredMembers.contains(fullName),
              reason: '$testName state incorrect');
        });
      }
    });
  }

  // validate no unexpected domains
  group('integration coverage', () {
    test('no unexpected domains', () {
      for (String domain in coveredDomains) {
        expect(api.domains.map((d) => d.name), contains(domain));
      }
    });
  });
}
