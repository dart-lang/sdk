// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dartdev/src/commands/create.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('create', defineCreateTests, timeout: longTimeout);
}

void defineCreateTests() {
  TestProject p;

  setUp(() => p = null);

  tearDown(() => p?.dispose());

  test('default template exists', () {
    expect(CreateCommand.legalTemplateIds,
        contains(CreateCommand.defaultTemplateId));
  });

  test('all templates exist', () {
    for (String templateId in CreateCommand.legalTemplateIds) {
      expect(CreateCommand.legalTemplateIds, contains(templateId));
    }
  });

  test('list templates', () {
    p = project();

    ProcessResult result = p.runSync(['create', '--list-templates']);
    expect(result.exitCode, 0);

    String output = result.stdout.toString();
    var parsedResult = jsonDecode(output);
    expect(parsedResult, hasLength(CreateCommand.legalTemplateIds.length));
    expect(parsedResult[0]['name'], isNotNull);
    expect(parsedResult[0]['label'], isNotNull);
    expect(parsedResult[0]['description'], isNotNull);
  });

  test('no directory given', () {
    p = project();

    ProcessResult result = p.runSync([
      'create',
    ]);
    expect(result.exitCode, 1);
  });

  test('directory already exists', () {
    p = project();

    ProcessResult result = p.runSync(
        ['create', '--template', CreateCommand.defaultTemplateId, p.dir.path]);
    expect(result.exitCode, 73);
  });

  test('bad template id', () {
    p = project();

    ProcessResult result =
        p.runSync(['create', '--no-pub', '--template', 'foo-bar', p.dir.path]);
    expect(result.exitCode, isNot(0));
  });

  // Create tests for each template.
  for (String templateId in CreateCommand.legalTemplateIds) {
    test('create $templateId', () {
      p = project();

      ProcessResult result = p
          .runSync(['create', '--force', '--template', templateId, p.dir.path]);
      expect(result.exitCode, 0);

      String projectName = path.basename(p.dir.path);

      String entry =
          CreateCommand.retrieveTemplateGenerator(templateId).entrypoint.path;
      entry = entry.replaceAll('__projectName__', projectName);
      File entryFile = File(path.join(p.dir.path, entry));

      expect(entryFile.existsSync(), true,
          reason: 'File not found: ${entryFile.path}');
    });
  }
}
