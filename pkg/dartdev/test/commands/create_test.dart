// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dartdev/src/commands/create.dart';
import 'package:dartdev/src/templates.dart' as templates;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('create', defineCreateTests, timeout: longTimeout);
}

void defineCreateTests() {
  TestProject? p;

  setUp(() => p = null);

  tearDown(() async => await p?.dispose());

  test('--help', () async {
    p = project();
    var result = await p!.run(['create', '--help']);

    expect(result.stdout, contains('Create a new Dart project.'));
    expect(
      result.stdout,
      contains(
        'Usage: dart create [arguments] <directory>',
      ),
    );
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test('--help --verbose', () async {
    p = project();
    var result = await p!.run(['create', '--help', '--verbose']);

    expect(result.stdout, contains('Create a new Dart project.'));
    expect(
      result.stdout,
      contains(
        'Usage: dart [vm-options] create [arguments] <directory>',
      ),
    );
    expect(result.stderr, isEmpty);
    expect(result.exitCode, 0);
  });

  test('default template exists', () async {
    expect(CreateCommand.legalTemplateIds,
        contains(CreateCommand.defaultTemplateId));
  });

  test('all templates exist', () async {
    for (String templateId in CreateCommand.legalTemplateIds) {
      expect(CreateCommand.legalTemplateIds, contains(templateId));
    }
  });

  test('list templates', () async {
    p = project();

    ProcessResult result = await p!.run(['create', '--list-templates']);
    expect(result.exitCode, 0);

    String output = result.stdout.toString();
    var parsedResult = jsonDecode(output);
    expect(parsedResult, hasLength(CreateCommand.legalTemplateIds.length));
    expect(parsedResult[0]['name'], isNotNull);
    expect(parsedResult[0]['label'], isNotNull);
    expect(parsedResult[0]['description'], isNotNull);
  });

  test('no directory given', () async {
    p = project();

    ProcessResult result = await p!.run([
      'create',
    ]);
    expect(result.exitCode, 1);
  });

  test('directory already exists', () async {
    p = project();

    ProcessResult result = await p!.run(
        ['create', '--template', CreateCommand.defaultTemplateId, p!.dir.path]);
    expect(result.exitCode, 73);
  });

  test('project in current directory', () async {
    p = project();
    final projectDir = Directory('foo')..createSync();
    final result = await p!.run(
      ['create', '--force', '.'],
      workingDir: projectDir.path,
    );
    expect(result.stderr, isEmpty);
    expect(result.stdout, contains('Created project foo in .!'));
    expect(result.exitCode, 0);
  });

  test('project with normalized package name', () async {
    p = project();
    final result = await p!.run(['create', 'requires-normalization']);
    expect(result.stderr, isEmpty);
    expect(
        result.stdout,
        contains(
            'Created project requires_normalization in requires-normalization!'));
    expect(result.exitCode, 0);
  });

  test('project with an invalid package name', () async {
    p = project();
    final result = await p!.run(['create', 'bad-package^name']);
    expect(
      result.stderr,
      contains(
        '"bad_package^name" is not a valid Dart project name.\n\n'
        'See https://dart.dev/tools/pub/pubspec#name for more information.',
      ),
    );
    expect(result.exitCode, 73);
  });

  test('bad template id', () async {
    p = project();

    ProcessResult result = await p!
        .run(['create', '--no-pub', '--template', 'foo-bar', p!.dir.path]);
    expect(result.exitCode, isNot(0));
  });

  // Create tests for each template.
  for (String templateId in CreateCommand.legalTemplateIds) {
    test(templateId, () async {
      p = project();
      const projectName = 'template_project';
      ProcessResult result = await p!.run([
        'create',
        '--force',
        '--no-pub',
        '--template',
        templateId,
        projectName,
      ]);
      expect(result.exitCode, 0);

      String entry = templates.getGenerator(templateId)!.entrypoint!.path;
      entry = entry.replaceAll('__projectName__', projectName);
      File entryFile = File(path.join(p!.dir.path, projectName, entry));

      expect(entryFile.existsSync(), true,
          reason: 'File not found: ${entryFile.path}');
    });
  }

  for (final generator in templates.generators) {
    test('${generator.id} getting started message', () {
      const dir = 'foo';
      const projectName = dir;
      final lines = generator
          .getInstallInstructions(dir, scriptPath: projectName)
          .split('\n')
          .map((e) => e.trim())
          .toList();
      if (generator.categories.contains('web')) {
        expect(lines.length, 3);
        expect(lines[0], 'cd $dir');
        expect(lines[1], 'dart pub global activate webdev');
        expect(lines[2], 'webdev serve');
      } else if (generator.categories.contains('console')) {
        expect(lines.length, 2);
        expect(lines[0], 'cd $dir');
        expect(lines[1], 'dart run');
      } else if (generator.categories.contains('server')) {
        expect(lines.length, 2);
        expect(lines[0], 'cd $dir');
        expect(lines[1], 'dart run bin/server.dart');
      } else {
        expect(lines.length, 2);
        expect(lines[0], 'cd $dir');
        expect(lines[1], 'dart run example/${projectName}_example.dart');
      }
    });
  }
}
