// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;
import 'package:dartdev/src/sdk_cache.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http;
import 'package:native_assets_cli/code_assets_builder.dart' show Target;
import 'package:test/test.dart';

const dartArchiveUri = 'https://storage.googleapis.com/dart-archive';

void main() {
  late SdkCache cache;
  late FileSystem fs;
  late StringBuffer stderr;
  late Map<String, http.Response> expectedRequests;
  late Map<String, io.ProcessResult> chmodRuns;

  setUp(() {
    fs = MemoryFileSystem();
    stderr = StringBuffer();
    expectedRequests = <String, http.Response>{};
    chmodRuns = <String, io.ProcessResult>{};

    cache = SdkCache(
        directory: '/tmp/cache',
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
      expect(folder.stage, Stage.raw);
      expect(folder.channel, Channel.stable);
      expect(folder.fileUri('VERSION').toString(),
          '$dartArchiveUri/channels/stable/raw/hash/$revision/VERSION');
    });

    test('Uses signed binaries on macOS', () async {
      final version = '3.8.0-171.2.beta';
      final revision = '54cec4d7d36e7a5066770287998f425606a2f983';
      final folder = await cache.resolveVersion(
          version: version,
          revision: revision,
          channelName: 'beta',
          host: Target.macOSArm64);
      expect(folder.version, version);
      expect(folder.revision, revision);
      expect(folder.stage, Stage.signed);
      expect(folder.channel, Channel.beta);
      expect(folder.fileUri('').toString(),
          '$dartArchiveUri/channels/beta/signed/hash/$revision/');
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
      expect(folder.stage, Stage.raw);
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
      expect(folder.stage, Stage.raw);
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

      final genSnapshotFile = fs
          .file('/tmp/cache/$version/gen_snapshot_windows_arm64_linux_x64.exe');
      genSnapshotFile.createSync(exclusive: true, recursive: true);

      final path = await cache.ensureGenSnapshot(
          archiveFolder: ArchiveFolder(
              channel: Channel.stable,
              stage: Stage.raw,
              version: version,
              revision: revision),
          host: Target.windowsArm64,
          target: Target.linuxX64);
      expect(path, genSnapshotFile.path);
    });

    test('Downloads', () async {
      final version = '3.8.0-171.2.beta';
      final revision = '54cec4d7d36e7a5066770287998f425606a2f983';

      final archiveFolder = ArchiveFolder(
          channel: Channel.beta,
          stage: Stage.signed,
          version: version,
          revision: revision);
      expectedRequests['GET $dartArchiveUri/channels/beta/signed/hash/'
              '$revision/sdk/dartaotruntime_linux_x64'] =
          http.Response('i am dartaotruntime', io.HttpStatus.ok);

      final path = await cache.ensureDartAotRuntime(
          archiveFolder: archiveFolder,
          host: Target.macOSArm64,
          target: Target.linuxX64);

      expect(path, '/tmp/cache/$version/dartaotruntime_linux_x64');
      expect(fs.file(path).readAsStringSync(), 'i am dartaotruntime');
    });
  });
}
