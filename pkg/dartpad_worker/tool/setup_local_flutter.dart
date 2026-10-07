// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:dartpad/src/cli/main.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:tar/tar.dart';

/// Sets up the Flutter DartPad SDK and cached pub package archives in
/// `.dart_tool/dartpad_worker/` for local testing in `pkg/dartpad_worker`.
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'bootstrap-code-path',
      help: 'Path to a file containing the bootstrap code.',
    )
    ..addOption(
      'web-sdk',
      allowed: ['copy', 'build'],
      defaultsTo: 'build',
      help: 'Copy or build `ddc_outline.dill` + `dart_sdk.js` from Flutter SDK',
    )
    ..addFlag(
      'use-cdn',
      defaultsTo: true,
      help:
          'Use CanvasKit from Google CDN instead of bundling canvaskit/ locally.',
    );

  final results = parser.parse(args);

  final dartSdkRoot = p.dirname(p.dirname(Platform.resolvedExecutable));
  final dartDartPadSdk = p.normalize(p.join(dartSdkRoot, '..', 'dartpad'));
  if (!Directory(dartDartPadSdk).existsSync()) {
    print(
      'Error: Did not find a Dart DartPad SDK at $dartDartPadSdk.\n'
      'Did you run the script with the `dart` binary from your build output '
      'directory (e.g. out/ReleaseX64/dart-sdk/bin/dart)?',
    );
    exit(1);
  }

  final pkgUri = await Isolate.resolvePackageUri(
    Uri.parse('package:dartpad_worker/dartpad_worker.dart'),
  );
  if (pkgUri == null) {
    throw StateError('Unable to resolve package:dartpad_worker');
  }
  final projectRoot = File.fromUri(pkgUri).parent.parent.path;
  final dotDartTool = p.join(projectRoot, '.dart_tool', 'dartpad_worker');
  final flutterAssetDir = p.join(dotDartTool, 'asset', 'flutter');
  if (Directory(flutterAssetDir).existsSync()) {
    Directory(flutterAssetDir).deleteSync(recursive: true);
  }
  final packageDir = p.join(dotDartTool, 'packages');

  await runDartPadCli([
    'setup',
    'flutter',
    '--output',
    flutterAssetDir,
    '--dartpad-sdk',
    dartDartPadSdk,
    '--web-sdk',
    results.option('web-sdk')!,
    if (results.flag('use-cdn')) '--use-cdn' else '--no-use-cdn',
    if (results.option('bootstrap-code-path') case final path?) ...[
      '--bootstrap-code-path',
      path,
    ],
  ]);

  // Download the pinned hosted package tarballs from `/sdk/packages/flutter/pubspec.yaml`
  // inside `sdk.tar` into `.dart_tool/dartpad_worker/packages` for PubTestServer.
  print('Downloading hosted dependencies for PubTestServer...');
  Directory(packageDir).createSync(recursive: true);
  final sdkTarFile = File(p.join(flutterAssetDir, 'sdk.tar'));
  final hostedVersions = await _readPinnedHostedVersionsFromSdkTar(sdkTarFile);
  await _downloadHostedPackages(hostedVersions, packageDir);

  print('\nSuccessfully set up local Flutter assets!');
  print('Run your tests with PubTestServer reporting hasFlutter: true.');
}

Future<Map<String, String>> _readPinnedHostedVersionsFromSdkTar(
  File sdkTarFile,
) async {
  final reader = TarReader(sdkTarFile.openRead());
  try {
    while (await reader.moveNext()) {
      final entry = reader.current;
      if (entry.name == '/sdk/packages/flutter/pubspec.yaml' ||
          entry.name == 'sdk/packages/flutter/pubspec.yaml') {
        final content = await utf8.decodeStream(entry.contents);
        final pubspec = jsonDecode(content) as Map<String, Object?>;
        final deps = pubspec['dependencies'] as Map<String, Object?>? ?? {};
        return {
          for (final MapEntry(:key, :value) in deps.entries)
            if (value is String) key: value,
        };
      }
    }
  } finally {
    await reader.cancel();
  }
  throw StateError(
    'Could not find /sdk/packages/flutter/pubspec.yaml in ${sdkTarFile.path}',
  );
}

Future<void> _downloadHostedPackages(
  Map<String, String> hostedVersions,
  String dest,
) async {
  final expectedTarballs = {
    for (final MapEntry(key: name, value: version) in hostedVersions.entries)
      '$name-$version.tar.gz',
  };
  for (final entity in Directory(dest).listSync()) {
    if (entity is File && !expectedTarballs.contains(p.basename(entity.path))) {
      entity.deleteSync();
    }
  }

  final client = http.Client();
  try {
    for (final MapEntry(key: name, value: version) in hostedVersions.entries) {
      final tarballName = '$name-$version.tar.gz';
      final tarballFile = File(p.join(dest, tarballName));
      if (tarballFile.existsSync()) continue;

      print('Downloading $name $version...');
      final url = 'https://pub.dev/api/archives/$tarballName';
      final response = await client.get(Uri.parse(url));
      if (response.statusCode == 200) {
        tarballFile.writeAsBytesSync(response.bodyBytes);
      } else {
        throw StateError(
          'Failed to download $url (HTTP ${response.statusCode})',
        );
      }
    }
  } finally {
    client.close();
  }
}
