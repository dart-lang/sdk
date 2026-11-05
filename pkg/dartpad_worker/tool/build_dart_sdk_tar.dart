// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dartpad_worker/src/shared.dart';
import 'package:dartpad_worker/src/worker_protocol_version.dart';
import 'package:path/path.dart' as p;
import 'package:tar/tar.dart';

/// Tool to build the sdk.tar and version.json files for DartPad.
///
/// Usage: `dart build_dart_sdk_tar.dart --output <path/to/output/folder/>`
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output folder for sdk.tar and version.json',
    )
    ..addOption('sdk-root', help: 'Path to the Dart SDK root');

  final results = parser.parse(args);
  final outputDirPath = results['output'];
  if (outputDirPath is! String) {
    print(
      'Usage: build_dart_sdk_tar.dart --output <path/to/output/folder/> [--sdk-root <path>]',
    );
    exit(1);
  }

  // Determine SDK root: either provided or inferred from the executable.
  final sdkPath = Uri.directory(
    results['sdk-root'] as String? ??
        p.dirname(p.dirname(Platform.resolvedExecutable)),
  );

  print('Building sdk.tar from: ${sdkPath.toFilePath()}');

  final files = _requiredFilesFromSdk(sdkPath);
  files.sort();

  final outputDir = Directory(outputDirPath)..createSync(recursive: true);
  final outputFile = File(p.join(outputDir.path, 'sdk.tar'));

  final tarSink = tarWritingSink(outputFile.openWrite());

  // Synthesize a generic DartPadConfig with just the `console` mode.
  final config = DartPadConfig(
    dartSdkPath: '/sdk',
    summaryModules: {},
    modes: [DartPadRunMode(mode: 'console')],
  );

  tarSink.add(
    TarEntry.data(
      TarHeader(name: '.dartpad_config.json', mode: int.parse('644', radix: 8)),
      utf8.encode(jsonEncode(config.toJson())),
    ),
  );

  for (final f in files) {
    final bytes = File.fromUri(sdkPath.resolve(f)).readAsBytesSync();
    tarSink.add(
      TarEntry.data(
        TarHeader(name: 'sdk/$f', mode: int.parse('644', radix: 8)),
        bytes,
      ),
    );
  }

  await tarSink.close();
  print('Wrote ${outputFile.path} (${files.length + 1} files)');

  final dartVersion = File.fromUri(
    sdkPath.resolve('version'),
  ).readAsStringSync().trim();
  final dartRevision = File.fromUri(
    sdkPath.resolve('revision'),
  ).readAsStringSync().trim();
  final versionInfo = createVersionInfo(
    workerProtocolMajor: workerProtocolMajorVersion,
    workerProtocolMinor: workerProtocolMinorVersion,
    modes: [for (final m in config.modes) m.mode],
    dartVersion: dartVersion,
    dartRevision: dartRevision,
  );
  final versionFile = File(p.join(outputDir.path, 'version.json'));
  versionFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(versionInfo.toJson())}\n',
  );
  print('Wrote ${versionFile.path}');
}

List<String> _requiredFilesFromSdk(Uri sdkPath) {
  // Note: `lib/_internal/js_runtime/` MUST be retained because
  // `sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart` maps
  // `dart:_interceptors`, `dart:_native_typed_data`, and `dart:_js_helper`
  // (used by `dart:js_interop` and `dart:html` in `FolderBasedDartSdk`)
  // to `_internal/js_runtime/lib/...`. Conversely, `js_dev_runtime/` has
  // zero entries in `libraries.dart` and DDC uses `ddc_outline.dill`.
  const excludedInternalDirs = [
    'lib/_internal/vm/',
    'lib/_internal/vm_shared/',
    'lib/_internal/wasm/',
    'lib/_internal/js_dev_runtime/',
  ];
  // TODO(jonasfj): We can use analyzer summaries instead, this is probably
  // faster, but requires a few changes to analyzer.
  final dartFilesForAnalyzer = Directory.fromUri(sdkPath.resolve('lib/'))
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') || f.path.endsWith('.json'))
      .where((f) {
        final rel = f.uri.path.substring(sdkPath.path.length);
        return !excludedInternalDirs.any(rel.startsWith);
      })
      .map((f) => f.uri.path);

  return {
    ...dartFilesForAnalyzer,
    sdkPath.resolve('lib/_internal/allowed_experiments.json').path,
    sdkPath.resolve('lib/_internal/ddc_outline.dill').path,
    sdkPath.resolve('lib/libraries.json').path,
    sdkPath.resolve('version').path,
    sdkPath.resolve('revision').path,
  }.map((path) => path.substring(sdkPath.path.length)).toList();
}
