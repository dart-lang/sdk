// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This script generates the
// lib/src/edit/nnbd_migration/resources/resources.g.dart file from the contents
// of the lib/src/edit/nnbd_migration/resources directory.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as path;

void main(List<String> args) async {
  if (FileSystemEntity.isFileSync(
      path.join('tool', 'nnbd_migration', 'generate_resources.dart'))) {
    // We're running from the project root - cd up two directories.
    Directory.current = Directory.current.parent.parent;
  } else if (!FileSystemEntity.isDirectorySync(
      path.join('pkg', 'analysis_server'))) {
    fail('Please run this tool from the root of the sdk repo.');
  }

  await compileWebFrontEnd();

  createResourcesGDart();
}

void createResourcesGDart() {
  Directory resourceDir = Directory(path.join('pkg', 'analysis_server', 'lib',
      'src', 'edit', 'nnbd_migration', 'resources'));

  String content = generateResourceFile(resourceDir.listSync().where((entity) {
    String name = path.basename(entity.path);
    return entity is File && (name.endsWith('.js') || name.endsWith('.css'));
  }).cast<File>());

  // write the content
  File resourcesFile = File(path.join('pkg', 'analysis_server', 'lib', 'src',
      'edit', 'nnbd_migration', 'resources', 'resources.g.dart'));
  resourcesFile.writeAsStringSync(content);
}

String generateResourceFile(Iterable<File> resources) {
  String filePath = path.relative(Platform.script.toFilePath());
  StringBuffer buf = StringBuffer('''
// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file is generated; don't edit it directly.
//
// See $filePath for how
// to edit the source content and for re-generation instructions.

import 'dart:convert' as convert;
''');

  // TODO(devoncarew): Also generate file CRCs for files generated from Dart.

  for (File resource in resources) {
    String name = path.basename(resource.path).replaceAll('.', '_');
    buf.writeln();
    buf.writeln('String get $name {');
    buf.writeln('  return _$name ??= _decode(_${name}_base64);');
    buf.writeln('}');
  }

  buf.writeln(r'''

String _decode(String data) {
  data = data.replaceAll('\n', '').trim();
  return String.fromCharCodes(convert.base64Decode(data));
}''');

  for (File resource in resources) {
    String name = path.basename(resource.path).replaceAll('.', '_');
    String source = resource.readAsStringSync();

    String delimiter = "'''";

    buf.writeln();
    buf.writeln('String _$name;');
    buf.writeln('String _${name}_base64 = $delimiter');
    buf.writeln(base64Encode(source.codeUnits));
    buf.writeln('$delimiter;');
  }

  return buf.toString();
}

String base64Encode(List<int> bytes) {
  String encoded = base64.encode(bytes);

  // Logic to cut lines into 80-character chunks.
  var lines = <String>[];
  var index = 0;

  while (index < encoded.length) {
    var line = encoded.substring(index, math.min(index + 80, encoded.length));
    lines.add(line);
    index += line.length;
  }

  return lines.join('\n');
}

void compileWebFrontEnd() async {
  File source = File(path.join('pkg', 'analysis_server', 'lib', 'src', 'edit',
      'nnbd_migration', 'web', 'migration.dart'));
  File output = File(path.join('pkg', 'analysis_server', 'lib', 'src', 'edit',
      'nnbd_migration', 'resources', 'migration.js'));

  String sdkBinDir = path.dirname(Platform.resolvedExecutable);
  String dart2jsPath = path.join(sdkBinDir, 'dart2js');

  // dart2js -m -o output source
  Process process =
      await Process.start(dart2jsPath, ['-m', '-o', output.path, source.path]);
  process.stdout.listen((List<int> data) => stdout.add(data));
  process.stderr.listen((List<int> data) => stderr.add(data));
  int exitCode = await process.exitCode;

  if (exitCode != 0) {
    fail('Failed compiling ${source.path}.');
  }
}

void fail(String message) {
  stderr.writeln(message);
  exit(1);
}
