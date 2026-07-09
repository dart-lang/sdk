// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tar/tar.dart';

/// Tool to build the sdk.tar file for DartPad.
///
/// Usage: `dart build_dart_sdk_tar.dart --output <path-to-sdk.tar>`
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('output', abbr: 'o', help: 'Output path for sdk.tar')
    ..addOption('sdk-root', help: 'Path to the Dart SDK root');

  final results = parser.parse(args);
  final outputPath = results['output'];
  if (outputPath is! String) {
    print(
      'Usage: build_dart_sdk_tar.dart --output <path/to/sdk.tar> [--sdk-root <path>]',
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

  final outputFile = File(outputPath);
  if (!outputFile.parent.existsSync()) {
    outputFile.parent.createSync(recursive: true);
  }

  final tarSink = tarWritingSink(outputFile.openWrite());

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
  print('Wrote ${outputFile.path} (${files.length} files)');
}

List<String> _requiredFilesFromSdk(Uri sdkPath) {
  // TODO(jonasfj): We can use analyzer summaries instead, this is probably
  // faster, but requires a few changes to analyzer.
  final dartFilesForAnalyzer = Directory.fromUri(sdkPath.resolve('lib/'))
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') || f.path.endsWith('.json'))
      // TODO(jonasfj): Figure out exactly what we need from lib/_internal/
      //.where((f) =>  !f.uri.path.substring(sdkPath.path.length).contains('lib/_internal/'))
      .map((f) => f.uri)
      .followedBy([
        sdkPath.resolve('lib/_internal/allowed_experiments.json'),
        sdkPath.resolve('version'),
      ])
      .map((u) => u.path);

  return {
    ...dartFilesForAnalyzer,
    sdkPath.resolve('lib/_internal/allowed_experiments.json').path,
    sdkPath.resolve('lib/_internal/ddc_outline.dill').path,
    sdkPath.resolve('lib/libraries.json').path,
    sdkPath.resolve('version').path,
  }.map((path) => path.substring(sdkPath.path.length)).toList();
}
