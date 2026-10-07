// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// Command to download and extract a prebuilt DartPad SDK for Dart from
/// `gs://dart-archive`.
final class SetupDartCommand extends Command<void> {
  @override
  final String name = 'dart';

  @override
  final String description =
      'Download and extract a DartPad SDK for Dart from gs://dart-archive.';

  SetupDartCommand() {
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        mandatory: true,
        valueHelp: 'dir',
        help: 'Output directory for the DartPad SDK.',
      )
      ..addOption(
        'channel',
        abbr: 'c',
        allowed: ['main', 'dev', 'beta', 'stable'],
        defaultsTo: 'stable',
        help: 'Dart release channel.',
      )
      ..addOption(
        'version',
        defaultsTo: 'latest',
        valueHelp: 'version',
        help:
            'Promoted release version (e.g. "3.13.0" or "latest"). '
            'Ignored when --revision is provided; cannot be used with '
            '--channel=main.',
      )
      ..addOption(
        'revision',
        valueHelp: 'sha',
        help:
            'Specific 40-character Git commit SHA '
            '(fetches from channels/<channel>/raw/hash/<sha>/dartpad/dartpad.zip).',
      );
  }

  @override
  Future<void> run() async {
    final results = argResults!;
    final outputDir = results.option('output')!;
    final channel = results.option('channel')!;
    final version = results.option('version')!;
    final revision = results.option('revision');

    final Uri url;
    try {
      url = resolveDartPadZipUrl(
        channel: channel,
        version: version,
        revision: revision,
      );
    } on FormatException catch (e) {
      usageException(e.message);
    }

    await downloadAndExtractDartPadZip(url, outputDir);
    print('Successfully extracted DartPad SDK for Dart to $outputDir');
  }
}

/// Resolves the `gs://dart-archive` HTTPS download URL for `dartpad.zip`.
Uri resolveDartPadZipUrl({
  required String channel,
  String version = 'latest',
  String? revision,
}) {
  const base = 'https://storage.googleapis.com/dart-archive/channels';
  if (revision != null) {
    final normalizedRev = revision.trim().toLowerCase();
    if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(normalizedRev)) {
      throw FormatException(
        'Expected a 40-character hex Git commit SHA for --revision, '
        'got "$revision".',
      );
    }
    return Uri.parse(
      '$base/$channel/raw/hash/$normalizedRev/dartpad/dartpad.zip',
    );
  }
  if (channel == 'main') {
    if (version != 'latest') {
      throw const FormatException(
        '--version cannot be used with --channel=main '
        '(use --revision=<sha> or omit --version).',
      );
    }
    return Uri.parse('$base/main/raw/latest/dartpad/dartpad.zip');
  }
  return Uri.parse('$base/$channel/release/$version/dartpad/dartpad.zip');
}

/// Downloads `dartpad.zip` from [url] and extracts the contents of its
/// top-level `dartpad/` directory into [destDir] using the OS `unzip` utility.
Future<void> downloadAndExtractDartPadZip(Uri url, String destDir) async {
  final outDir = Directory(destDir);
  if (outDir.existsSync() && outDir.listSync().isNotEmpty) {
    throw StateError(
      'Output directory "$destDir" already exists and is not empty.',
    );
  }
  outDir.createSync(recursive: true);

  final extractor = await _resolveZipExtractor();

  final tempDir = Directory.systemTemp.createTempSync('dartpad_setup_');
  try {
    final zipFile = File(p.join(tempDir.path, 'dartpad.zip'));
    print('Downloading $url...');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw StateError(
        'Failed to download $url (HTTP ${response.statusCode}).',
      );
    }
    zipFile.writeAsBytesSync(response.bodyBytes);

    final extractDir = Directory(p.join(tempDir.path, 'extracted'))
      ..createSync(recursive: true);
    await extractZipFile(zipFile.path, extractDir.path, extractor: extractor);

    final extractedDartPadDir = Directory(p.join(extractDir.path, 'dartpad'));
    if (!extractedDartPadDir.existsSync()) {
      throw StateError(
        'Expected top-level "dartpad/" directory in archive from $url.',
      );
    }

    copyDirectoryContents(extractedDartPadDir.path, outDir.path);
  } finally {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}

/// Checks whether `unzip` (or `tar` on Windows) is available on `PATH`.
/// Returns `'unzip'` if `unzip` is available, or `'tar'` if falling back to
/// `tar` on Windows.
Future<String> _resolveZipExtractor() async {
  final checkCmd = Platform.isWindows ? 'where' : 'which';
  final unzipResult = await Process.run(checkCmd, ['unzip']);
  if (unzipResult.exitCode == 0) return 'unzip';

  if (Platform.isWindows) {
    final tarResult = await Process.run('where', ['tar']);
    if (tarResult.exitCode == 0) return 'tar';
  }

  final tools = Platform.isWindows ? '"unzip" or "tar"' : '"unzip"';
  throw StateError(
    'Could not find $tools on PATH. '
    'Please install $tools and ensure it is available on your PATH.',
  );
}

/// Extracts [zipPath] into [destDir] using OS `unzip` (or `tar -xf` on
/// Windows).
Future<void> extractZipFile(
  String zipPath,
  String destDir, {
  String? extractor,
}) async {
  final tool = extractor ?? await _resolveZipExtractor();

  final ProcessResult result;
  if (tool == 'unzip') {
    result = await Process.run('unzip', ['-q', zipPath, '-d', destDir]);
  } else {
    result = await Process.run('tar', ['-xf', zipPath, '-C', destDir]);
  }

  if (result.exitCode != 0) {
    throw StateError(
      'Failed to extract $zipPath (exit code ${result.exitCode}):\n'
      '${result.stdout}\n${result.stderr}',
    );
  }
}

/// Recursively copies all files in [source] into [dest].
void copyDirectoryContents(String source, String dest) {
  final s = Directory(source);
  if (!s.existsSync()) {
    throw StateError('Expected directory $source to exist.');
  }
  Directory(dest).createSync(recursive: true);
  for (final entity in s.listSync(recursive: true)) {
    if (entity is File) {
      final relative = p.relative(entity.path, from: source);
      final destFile = File(p.join(dest, relative));
      destFile.parent.createSync(recursive: true);
      entity.copySync(destFile.path);
    }
  }
}
