// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This script generates the
// lib/src/edit/nnbd_migration/resources/resources.g.dart file from the contents
// of the lib/src/edit/nnbd_migration/resources directory.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  if (args.isEmpty) {
    // this is valid
  } else if (args.length != 1 || args.first != '--verify') {
    fail('''
usage: dart pkg/analysis_server/tool/nnbd_migration/generate_resources.dart [--verify]

Run with no args to generate web resources for the NNBD migration preview tool.
Run with '--verify' to validate that the web resource have been regenerated.
''');
  }

  if (FileSystemEntity.isFileSync(
      path.join('tool', 'nnbd_migration', 'generate_resources.dart'))) {
    // We're running from the project root - cd up two directories.
    Directory.current = Directory.current.parent.parent;
  } else if (!FileSystemEntity.isDirectorySync(
      path.join('pkg', 'analysis_server'))) {
    fail('Please run this tool from the root of the sdk repo.');
  }

  bool verify = args.isNotEmpty && args.first == '--verify';

  if (verify) {
    verifyResourcesGDartGenerated();
  } else {
    await compileWebFrontEnd();

    print('');

    createResourcesGDart();
  }
}

final File dartSources = File(path.join('pkg', 'analysis_server', 'lib', 'src',
    'edit', 'nnbd_migration', 'web', 'migration.dart'));

final javascriptOutput = File(path.join('pkg', 'analysis_server', 'lib', 'src',
    'edit', 'nnbd_migration', 'resources', 'migration.js'));

final Directory resourceDir = Directory(path.join('pkg', 'analysis_server',
    'lib', 'src', 'edit', 'nnbd_migration', 'resources'));

final File resourcesFile = File(path.join('pkg', 'analysis_server', 'lib',
    'src', 'edit', 'nnbd_migration', 'resources', 'resources.g.dart'));

final List<String> resourceTypes = [
  '.css',
  '.html',
  '.js',
];

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
  String sdkBinDir = path.dirname(Platform.resolvedExecutable);
  String dart2jsPath = path.join(sdkBinDir, 'dart2js');

  const minified = true;

  // dart2js -m -o output source
  Process process = await Process.start(dart2jsPath, [
    if (minified) '-m',
    '--no-frequency-based-minification',
    '-o',
    javascriptOutput.path,
    dartSources.path,
  ]);
  process.stdout.listen((List<int> data) => stdout.add(data));
  process.stderr.listen((List<int> data) => stderr.add(data));
  int exitCode = await process.exitCode;

  if (exitCode != 0) {
    fail('Failed compiling ${dartSources.path}.');
  }
}

void createResourcesGDart() {
  String content =
      generateResourceFile(sortDir(resourceDir.listSync()).where((entity) {
    String name = path.basename(entity.path);
    return entity is File && resourceTypes.contains(path.extension(name));
  }).cast<File>());

  // write the content
  resourcesFile.writeAsStringSync(content);
}

void fail(String message) {
  stderr.writeln(message);
  exit(1);
}

/// Fail the script, and print out a message indicating how to regenerate the
/// resources file.
void failGenerate(String message) {
  stderr.writeln('$message.');
  stderr.writeln();
  stderr.writeln('''
To re-generate lib/src/edit/nnbd_migration/resources/resources.g.dart, run:

  dart pkg/analysis_server/tool/nnbd_migration/generate_resources.dart
''');
  exit(1);
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

  for (File resource in resources) {
    String name = path.basename(resource.path).replaceAll('.', '_');
    print('adding $name...');

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
    if (name == path.basename(javascriptOutput.path).replaceAll('.', '_')) {
      // Write out the crc for the dart code.
      StringBuffer sourceCode = StringBuffer();
      // collect the dart source code
      for (FileSystemEntity entity in sortDir(dartSources.parent.listSync())) {
        if (entity.path.endsWith('.dart')) {
          sourceCode.write((entity as File).readAsStringSync());
        }
      }
      buf.writeln(
          "// migration_dart md5 is '${md5String(sourceCode.toString())}'");
    } else {
      // highlight_css md5 is 'fb012626bafd286510d32da815dae448'
      buf.writeln("// $name md5 is '${md5String(source)}'");
    }
    buf.writeln('String _${name}_base64 = $delimiter');
    buf.writeln(base64Encode(source.codeUnits));
    buf.writeln('$delimiter;');
  }

  return buf.toString();
}

String md5String(String str) {
  return md5.convert(str.codeUnits).toString();
}

List<FileSystemEntity> sortDir(Iterable<FileSystemEntity> entities) {
  var result = entities.toList();
  result.sort((a, b) => a.path.compareTo(b.path));
  return result;
}

void verifyResourcesGDartGenerated({
  VerificationFunction failVerification = failGenerate,
}) {
  print('Verifying that ${path.basename(resourcesFile.path)} is up-to-date...');

  // Find the hashes for the last generated version of resources.g.dart.
  Map<String, String> resourceHashes = {};
  // highlight_css md5 is 'fb012626bafd286510d32da815dae448'
  RegExp hashPattern = RegExp(r"// (\S+) md5 is '(\S+)'");
  for (RegExpMatch match
      in hashPattern.allMatches(resourcesFile.readAsStringSync())) {
    resourceHashes[match.group(1)] = match.group(2);
  }

  // For all resources (modulo compiled JS ones), verify the hash.
  for (FileSystemEntity entity in sortDir(resourceDir.listSync())) {
    String name = path.basename(entity.path);
    if (!resourceTypes.contains(path.extension(name))) {
      continue;
    }

    if (name == 'migration.js') {
      // skip the compiled js
      continue;
    }

    String key = name.replaceAll('.', '_');
    if (!resourceHashes.containsKey(key)) {
      failVerification('No entry on resources.g.dart for $name');
    } else {
      String hash = md5String((entity as File).readAsStringSync());
      if (hash != resourceHashes[key]) {
        failVerification('$name not up to date in resources.g.dart');
      }
    }
  }

  // verify the compiled dart code
  StringBuffer sourceCode = StringBuffer();
  for (FileSystemEntity entity in sortDir(dartSources.parent.listSync())) {
    if (entity.path.endsWith('.dart')) {
      sourceCode.write((entity as File).readAsStringSync());
    }
  }
  String hash = md5String(sourceCode.toString());
  if (hash != resourceHashes['migration_dart']) {
    failVerification('Compiled javascript not up to date in resources.g.dart');
  }

  print('Generated resources up to date.');
}

typedef VerificationFunction = void Function(String);
