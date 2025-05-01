// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'package:code_assets/code_assets.dart' show OS;
import 'package:dartdev/src/sdk_cache.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:hooks_runner/hooks_runner.dart' show Target;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http;
import 'package:test/test.dart';

const dartArchiveUri = 'https://storage.googleapis.com/dart-archive';

void main() {
  late SdkCache cache;
  late FileSystem fs;
  late StringBuffer stderr;
  late Map<String, http.Response> expectedRequests;
  late Map<String, io.ProcessResult> chmodRuns;

  setUp(() {
    // Make sure we support both path separators.
    fs = MemoryFileSystem(
        style: io.Platform.isWindows
            ? FileSystemStyle.windows
            : FileSystemStyle.posix);
    stderr = StringBuffer();
    expectedRequests = <String, http.Response>{};
    chmodRuns = <String, io.ProcessResult>{};

    cache = SdkCache(
        directory: fs.directory(Uri.file('/tmp/cache')).path,
        stderr: stderr,
        verbose: true,
        fs: fs,
        httpClient: http.MockClient((request) async {
          final key = '${request.method.toUpperCase()} ${request.url}';
          if (!expectedRequests.containsKey(key)) {
            throw Exception('Unexpected request $key');
          }
          return expectedRequests[key]!;
        }),
        chmod: (path) => chmodRuns[path]!);
  });

  group('resolveStage', () {
    test('Uses signed on macOS dev for executables', () {
      expect(
          SdkCache.resolveStage(
              channel: Channel.dev, isExecutable: true, hostOS: OS.macOS),
          Stage.signed);
    });

    test('Uses raw on macOS main for executables', () {
      expect(
          SdkCache.resolveStage(
              channel: Channel.main, isExecutable: true, hostOS: OS.macOS),
          Stage.raw);
    });

    test('Uses raw on macOS stable for non-executables', () {
      expect(
          SdkCache.resolveStage(
              channel: Channel.stable, isExecutable: false, hostOS: OS.macOS),
          Stage.raw);
    });
  });

  group('resolveVersion', () {
    test('Resolves release version', () async {
      final version = '3.4.4';
      final revision = '60465149414572c8ca189d8f65fdb39795c4b97d';
      final folder = await cache.resolveVersion(
          version: version,
          revision: revision,
          channelName: 'stable',
          host: Target.linuxArm64);
      expect(folder.version, version);
      expect(folder.revision, revision);
      expect(folder.channel, Channel.stable);
      expect(folder.fileUri('VERSION', stage: Stage.raw).toString(),
          '$dartArchiveUri/channels/stable/raw/hash/$revision/VERSION');
    });

    test('Falls back to the latest on empty main revision', () async {
      final version = '3.8.0';
      final revision = '';

      final latestVersion =
          '3.8.0-edge.7ee7416a62efb7eb23eb2a87eb34d2895559ba06';
      final latestRevision = '7ee7416a62efb7eb23eb2a87eb34d2895559ba06';

      expectedRequests['GET $dartArchiveUri/channels/main/raw/latest/VERSION'] =
          http.Response(
              json.encode(
                  {'version': latestVersion, 'revision': latestRevision}),
              io.HttpStatus.ok);
      final folder = await cache.resolveVersion(
          version: version,
          revision: revision,
          channelName: 'main',
          host: Target.macOSArm64);
      expect(folder.version, latestVersion);
      expect(folder.revision, latestRevision);
      expect(folder.channel, Channel.main);
    });

    test('Falls back to the latest on unknown main revision', () async {
      final version = '3.8.0';
      final revision = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

      final latestVersion =
          '3.8.0-edge.7ee7416a62efb7eb23eb2a87eb34d2895559ba06';
      final latestRevision = '7ee7416a62efb7eb23eb2a87eb34d2895559ba06';

      expectedRequests.addAll({
        // Revision validation request.
        'HEAD $dartArchiveUri/channels/main/raw/hash/$revision/VERSION':
            http.Response('', io.HttpStatus.notFound),
        // Revision resolution request.
        'GET $dartArchiveUri/channels/main/raw/latest/VERSION': http.Response(
            json.encode({'version': latestVersion, 'revision': latestRevision}),
            io.HttpStatus.ok)
      });

      final folder = await cache.resolveVersion(
          version: version,
          revision: revision,
          channelName: 'main',
          host: Target.macOSArm64);
      expect(folder.version, latestVersion);
      expect(folder.revision, latestRevision);
      expect(folder.channel, Channel.main);
    });

    test('Reports unknown channel', () async {
      try {
        await cache.resolveVersion(
            channelName: 'wat',
            host: Target.linuxArm64,
            revision: '',
            version: '4.0');
        fail('expected to throw');
      } on ArgumentError catch (e) {
        expect(e.message, contains('Unsupported channel'));
      }
    });
  });

  group('ensureArtifact', () {
    test('Skips download when file exists', () async {
      final version = '3.4.4';
      final revision = '60465149414572c8ca189d8f65fdb39795c4b97d';

      final genSnapshotFile = fs.file(Uri.file(
          '/tmp/cache/$version/gen_snapshot_windows_arm64_linux_x64.exe'));
      genSnapshotFile.createSync(exclusive: true, recursive: true);

      final path = await cache.ensureGenSnapshot(
          archiveFolder: ArchiveFolder(
              channel: Channel.stable, version: version, revision: revision),
          host: Target.windowsArm64,
          target: Target.linuxX64);
      expect(path, genSnapshotFile.path);
    });

    test('Downloads signed gen_snapshot on macOS beta', () async {
      final version = '3.8.0-171.2.beta';
      final revision = '54cec4d7d36e7a5066770287998f425606a2f983';

      final archiveFolder = ArchiveFolder(
          channel: Channel.beta, version: version, revision: revision);
      expectedRequests['GET $dartArchiveUri/channels/beta/signed/hash/'
              '$revision/sdk/gen_snapshot_macos_arm64_linux_x64'] =
          http.Response('i am gen_snapshot', io.HttpStatus.ok);

      final path = await cache.ensureGenSnapshot(
          archiveFolder: archiveFolder,
          host: Target.macOSArm64,
          target: Target.linuxX64);

      expect(
          path,
          fs
              .file(Uri.file(
                  '/tmp/cache/$version/gen_snapshot_macos_arm64_linux_x64'))
              .path);
      expect(fs.file(path).readAsStringSync(), 'i am gen_snapshot');
    });

    test('Downloads raw dartaotruntime on macOS beta', () async {
      final version = '3.8.0-171.2.beta';
      final revision = '54cec4d7d36e7a5066770287998f425606a2f983';

      final archiveFolder = ArchiveFolder(
          channel: Channel.beta, version: version, revision: revision);
      expectedRequests['GET $dartArchiveUri/channels/beta/raw/hash/'
              '$revision/sdk/dartaotruntime_linux_x64'] =
          http.Response('i am dartaotruntime', io.HttpStatus.ok);

      final path = await cache.ensureDartAotRuntime(
          archiveFolder: archiveFolder,
          host: Target.macOSArm64,
          target: Target.linuxX64);

      expect(
          path,
          fs
              .file(Uri.file('/tmp/cache/$version/dartaotruntime_linux_x64'))
              .path);
      expect(fs.file(path).readAsStringSync(), 'i am dartaotruntime');
    });

    test('Downloads gen_snapshot.exe on Windows stable', () async {
      final version = '3.7.2';
      final channel = Channel.stable;
      final revision = '9594995093f642957b780603c6435d9e7a61b923';
      final binary = 'gen_snapshot_windows_x64_linux_x64.exe';

      final archiveFolder =
          ArchiveFolder(channel: channel, version: version, revision: revision);
      expectedRequests['GET $dartArchiveUri/channels/stable/raw/hash/'
              '$revision/sdk/$binary'] =
          http.Response('i am gen_snapshot', io.HttpStatus.ok);

      final path = await cache.ensureGenSnapshot(
          archiveFolder: archiveFolder,
          host: Target.windowsX64,
          target: Target.linuxX64);

      expect(path, fs.file(Uri.file('/tmp/cache/$version/$binary')).path);
      expect(fs.file(path).readAsStringSync(), 'i am gen_snapshot');
    });

    test('Downloads dartaotruntime on Windows stable', () async {
      final version = '3.7.2';
      final channel = Channel.stable;
      final revision = '9594995093f642957b780603c6435d9e7a61b923';
      final binary = 'dartaotruntime_linux_x64';

      final archiveFolder =
          ArchiveFolder(channel: channel, version: version, revision: revision);
      expectedRequests['GET $dartArchiveUri/channels/stable/raw/hash/'
              '$revision/sdk/$binary'] =
          http.Response('i am dartaotruntime', io.HttpStatus.ok);

      final path = await cache.ensureDartAotRuntime(
          archiveFolder: archiveFolder,
          host: Target.windowsX64,
          target: Target.linuxX64);

      expect(path, fs.file(Uri.file('/tmp/cache/$version/$binary')).path);
      expect(fs.file(path).readAsStringSync(), 'i am dartaotruntime');
    });
  });
}
