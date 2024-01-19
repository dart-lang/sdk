// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'codegen.dart';
import 'json_schema.dart';

Future<void> main(List<String> arguments) async {
  final args = argParser.parse(arguments);
  if (args[argHelp]) {
    print(argParser.usage);
    return;
  }

  if (args[argDownload]) {
    await downloadSpec();
  }

  final schemaContent = await File(specFile).readAsString();
  final schemaJson = jsonDecode(schemaContent);
  final schema = JsonSchema.fromJson(schemaJson);

  final buffer = IndentableStringBuffer();
  CodeGenerator().writeAll(buffer, schema);
  final generatedCode = buffer.toString();
  await File(generatedCodeFile)
      .writeAsString('$codeFileHeader\n$generatedCode');

  // Format the generated code.
  await Process.run(Platform.resolvedExecutable, ['format', generatedCodeFile]);
}

const argDownload = 'download';
const argHelp = 'help';
final codeFileHeader = '''
$licenseComment

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "tool/generate_all.dart".

// ignore_for_file: prefer_void_to_null

import 'protocol_common.dart';
import 'protocol_special.dart';
''';
final argParser = ArgParser()
  ..addFlag(argHelp, hide: true)
  ..addFlag(argDownload,
      negatable: false,
      abbr: 'd',
      help: 'Download latest version of the DAP spec before generating types');
final generatedCodeFile =
    path.join(toolFolder, '../lib/src/protocol_generated.dart');
final licenseFile = path.join(toolFolder, '../LICENSE');
final specFile = path.join(specFolder, 'debugAdapterProtocol.json');
final specFolder = path.join(toolFolder, 'external_dap_spec');
final specLicenseUri = Uri.parse(
    'https://raw.githubusercontent.com/microsoft/debug-adapter-protocol/main/License-code.txt');
final specUri = Uri.parse(
    'https://raw.githubusercontent.com/microsoft/debug-adapter-protocol/gh-pages/debugAdapterProtocol.json');
final toolFolder = path.dirname(Platform.script.toFilePath());
final licenseComment = LineSplitter.split(File(licenseFile).readAsStringSync())
    .skipWhile((line) => line != 'Files: lib/protocol_generated.dart')
    .skip(2)
    .map((line) => line.isEmpty ? '//' : '// $line')
    .join('\n');

Future<void> downloadSpec() async {
  final specResp = await http.get(specUri);
  final licenseResp = await http.get(specLicenseUri);

  assert(specResp.statusCode == 200);
  assert(licenseResp.statusCode == 200);

  final String sdkRoot = path.join(toolFolder, '../../../..');
  final dartSdkLicense = await File('$sdkRoot/LICENSE').readAsString();
  final license = '''
$dartSdkLicense

------------------

Files: debugAdapterProtocol.json
Files: lib/protocol_generated.dart

${licenseResp.body}
''';

  await File(specFile).writeAsString(specResp.body);
  await File(licenseFile).writeAsString(license);
}
