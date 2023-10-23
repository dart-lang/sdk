// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:markdown/markdown.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

import 'common/generate_common.dart';
import 'dart/generate_dart_client.dart';
import 'dart/generate_dart_common.dart';
import 'dart/generate_dart_interface.dart';
import 'java/generate_java.dart' as java show Api, api, JavaGenerator;

final bool _stampPubspecVersion = false;

/// Parse the 'service.md' into a model and generate both Dart and Java
/// libraries.
Future<void> main(List<String> args) async {
  final codeGeneratorDir = dirname(Platform.script.toFilePath());

  // Parse service.md into a model.
  final file = File(
    normalize(join(codeGeneratorDir, '../../../runtime/vm/service/service.md')),
  );
  final document = Document();
  final buf = StringBuffer(file.readAsStringSync());
  final nodes = document.parseLines(buf.toString().split('\n'));
  print('Parsed ${file.path}.');
  print('Service protocol version ${ApiParseUtil.parseVersionString(nodes)}.');

  // Generate code from the model.
  print('');

  await _generateDartClient(codeGeneratorDir, nodes);
  await _generateDartInterface(codeGeneratorDir, nodes);
  await _generateJava(codeGeneratorDir, nodes);
}

Future<void> _generateDartClient(
    String codeGeneratorDir, List<Node> nodes) async {
  var outputFilePath = await _generateDartCommon(
    api: VmServiceApi(),
    nodes: nodes,
    codeGeneratorDir: codeGeneratorDir,
    packageName: 'vm_service',
    interfaceName: 'VmService',
  );
  print('Wrote Dart client to $outputFilePath.');
  outputFilePath = await _generateDartCommon(
    api: VmServiceInterfaceApi(),
    nodes: nodes,
    codeGeneratorDir: codeGeneratorDir,
    packageName: 'vm_service',
    interfaceName: 'VmServiceInterface',
    fileNameOverride: 'vm_service_interface',
  );
  print('Wrote Dart temporary interface to $outputFilePath.');
}

Future<void> _generateDartInterface(
    String codeGeneratorDir, List<Node> nodes) async {
  final outputFilePath = await _generateDartCommon(
    api: VmServiceInterfaceApi(),
    nodes: nodes,
    codeGeneratorDir: codeGeneratorDir,
    packageName: 'vm_service_interface',
    interfaceName: 'VmServiceInterface',
  );
  print('Wrote Dart interface to $outputFilePath.');
}

Future<String> _generateDartCommon({
  required Api api,
  required List<Node> nodes,
  required String codeGeneratorDir,
  required String packageName,
  required String interfaceName,
  String? fileNameOverride,
}) async {
  final outDirPath = normalize(
    join(
      codeGeneratorDir,
      '../..',
      packageName,
      'lib/src',
    ),
  );
  final outDir = Directory(outDirPath);
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final outputFile = File(
    join(
      outDirPath,
      '${fileNameOverride ?? packageName}.dart',
    ),
  );
  final generator = DartGenerator(interfaceName: interfaceName);

  // Generate the code.
  api.parse(nodes);
  api.generate(generator);
  outputFile.writeAsStringSync(generator.toString());

  // Clean up the code.
  await _runDartFormat(outDirPath);

  if (_stampPubspecVersion) {
    // Update the pubspec file.
    Version version = ApiParseUtil.parseVersionSemVer(nodes);
    _stampPubspec(version);

    // Validate that the changelog contains an entry for the current version.
    _checkUpdateChangelog(version);
  }
  return outputFile.path;
}

Future<void> _runDartFormat(String outDirPath) async {
  ProcessResult result = Process.runSync('dart', ['format', outDirPath]);
  if (result.exitCode != 0) {
    print('dart format: ${result.stdout}\n${result.stderr}');
    throw result.exitCode;
  }
}

Future<void> _generateJava(String codeGeneratorDir, List<Node> nodes) async {
  var srcDirPath = normalize(join(codeGeneratorDir, '..', 'java', 'src'));
  var generator = java.JavaGenerator(srcDirPath);

  final scriptPath = Platform.script.toFilePath();
  final kSdk = '/sdk/';
  final scriptLocation =
      scriptPath.substring(scriptPath.indexOf(kSdk) + kSdk.length);
  java.api = java.Api(scriptLocation);
  java.api.parse(nodes);
  java.api.generate(generator);

  // We generate files into the java/src/ folder; ensure the generated files
  // aren't committed to git (but manually maintained files in the same
  // directory are).
  List<String> generatedPaths = generator.allWrittenFiles
      .map((path) => relative(path, from: 'java'))
      .toList();
  generatedPaths.sort();
  File gitignoreFile = File(join(codeGeneratorDir, '..', 'java', '.gitignore'));
  gitignoreFile.writeAsStringSync('''
# This is a generated file.

${generatedPaths.join('\n')}
''');

  // Generate a version file.
  Version version = ApiParseUtil.parseVersionSemVer(nodes);
  File file = File(join('java', 'version.properties'));
  file.writeAsStringSync('version=${version.major}.${version.minor}\n');

  print('Wrote Java to $srcDirPath.');
}

// Push the major and minor versions into the pubspec.
void _stampPubspec(Version version) {
  final String pattern = 'version: ';
  File file = File('pubspec.yaml');
  String text = file.readAsStringSync();
  bool found = false;

  text = text.split('\n').map((line) {
    if (line.startsWith(pattern)) {
      found = true;
      Version v = Version.parse(line.substring(pattern.length));
      String? pre = v.preRelease.isEmpty ? null : v.preRelease.join('-');
      String? build = v.build.isEmpty ? null : v.build.join('+');
      v = Version(version.major, version.minor, v.patch,
          pre: pre, build: build);
      return '$pattern${v.toString()}';
    } else {
      return line;
    }
  }).join('\n');

  if (!found) throw '`$pattern` not found';

  file.writeAsStringSync(text);
}

void _checkUpdateChangelog(Version version) {
  // Look for `## major.minor`.
  String check = '## ${version.major}.${version.minor}';

  File file = File('CHANGELOG.md');
  String text = file.readAsStringSync();
  bool containsReleaseNotes =
      text.split('\n').any((line) => line.startsWith(check));
  if (!containsReleaseNotes) {
    throw '`$check` not found in the CHANGELOG.md file';
  }
}
