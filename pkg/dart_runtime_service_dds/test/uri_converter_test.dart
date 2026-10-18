// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:dart_runtime_service_dds/dart_runtime_service_dds.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' as vm;
import 'package:vm_service/vm_service_io.dart';
import 'package:web_socket_channel/io.dart';

const _collectedIsolateId = 'isolates/collected';
const _runningIsolateId = 'isolates/1';
const _unresolvedUris = <String>[
  'dart:io',
  'package:test/has_local.dart',
  'package:does_not_exist/does_not_exist.dart',
];

class MockVmService {
  MockVmService._(this.server);

  final HttpServer server;
  final clients = <json_rpc.Peer>[];
  Map<String, Object?>? lastLookupParams;

  Uri get uri => Uri.parse('http://localhost:${server.port}/');

  static Future<MockVmService> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final mock = MockVmService._(server);

    server.transform(WebSocketTransformer()).listen((webSocket) {
      final peer = json_rpc.Peer(IOWebSocketChannel(webSocket).cast<String>())
        ..registerMethod(
          'getVM',
          (_) => <String, Object?>{
            'type': 'VM',
            'name': 'mock-vm',
            'isolates': <Map<String, Object?>>[],
          },
        )
        ..registerMethod('_yieldControlToDDS', (_) => vm.Success().toJson())
        ..registerMethod('streamListen', (_) => vm.Success().toJson())
        ..registerMethod(
          'getFlagList',
          (_) => vm.FlagList(flags: <vm.Flag>[]).toJson(),
        )
        ..registerMethod('lookupResolvedPackageUris', (
          json_rpc.Parameters params,
        ) {
          mock.lastLookupParams = params.asMap.cast<String, Object?>();
          if (params['isolateId'].asString == _collectedIsolateId) {
            return vm.Sentinel(
              kind: vm.SentinelKind.kCollected,
              valueAsString: '<collected>',
            ).toJson();
          }
          final uris = params['uris'].asList.cast<String>();
          return vm.UriList(
            uris: <String?>[
              for (final uri in uris)
                switch (uri) {
                  'dart:io' => 'org-dartlang-sdk:///sdk/lib/io/io.dart',
                  'package:test/test.dart' => 'file:///vm/resolved/test.dart',
                  'package:test/has_local.dart' =>
                    'file:///vm/resolved/has_local.dart',
                  _ => null,
                },
            ],
          ).toJson();
        })
        ..listen();
      mock.clients.add(peer);
    });

    return mock;
  }

  Future<void> shutdown() async {
    for (final client in clients) {
      await client.close();
    }
    await server.close(force: true);
  }
}

void main() {
  group('lookupResolvedPackageUris and UriConverter', () {
    late MockVmService mockVmService;
    DartRuntimeService? ddsService;
    vm.VmService? ddsClient;

    Future<vm.VmService> startDds({UriConverter? uriConverter}) async {
      ddsService = await DartRuntimeService.initialize(
        config: const DartRuntimeServiceOptions(),
        backendBuilder: (frontend) => DartRuntimeServiceDdsBackend(
          mockVmService.uri,
          frontend: frontend,
          uriConverter: uriConverter,
        ),
      );
      return ddsClient = await vmServiceConnectUri(ddsService!.uri.toString());
    }

    setUp(() async {
      mockVmService = await MockVmService.start();
    });

    tearDown(() async {
      await ddsClient?.dispose();
      await ddsService?.shutdown();
      await mockVmService.shutdown();
    });

    test('returns local paths with a custom uriConverter', () async {
      final homeHasLocalPath = path.join(
        path.rootPrefix(path.current),
        'home',
        'has_local.dart',
      );
      final client = await startDds(
        uriConverter: (uri) =>
            uri == 'package:test/has_local.dart' ? homeHasLocalPath : null,
      );

      final result = await client.lookupResolvedPackageUris(
        _runningIsolateId,
        _unresolvedUris,
        local: true,
      );

      expect(mockVmService.lastLookupParams, isNotNull);
      expect(mockVmService.lastLookupParams!.containsKey('local'), isFalse);
      expect(result.uris, <String?>[
        'org-dartlang-sdk:///sdk/lib/io/io.dart',
        Uri.file(homeHasLocalPath).toString(),
        null,
      ]);
    });

    test(
      'does not invoke uriConverter when local is false or omitted',
      () async {
        var converterInvoked = false;
        final client = await startDds(
          uriConverter: (_) {
            converterInvoked = true;
            return '/unexpected/path.dart';
          },
        );
        const expectedVmUris = <String?>[
          'org-dartlang-sdk:///sdk/lib/io/io.dart',
          'file:///vm/resolved/has_local.dart',
          null,
        ];

        final resultDefault = await client.lookupResolvedPackageUris(
          _runningIsolateId,
          _unresolvedUris,
        );
        expect(converterInvoked, isFalse);
        expect(resultDefault.uris, expectedVmUris);

        final resultLocalFalse = await client.lookupResolvedPackageUris(
          _runningIsolateId,
          _unresolvedUris,
          local: false,
        );
        expect(converterInvoked, isFalse);
        expect(resultLocalFalse.uris, expectedVmUris);
      },
    );

    test('propagates Sentinel when VM returns Sentinel', () async {
      final client = await startDds(
        uriConverter: (_) => '/home/has_local.dart',
      );

      await expectLater(
        client.lookupResolvedPackageUris(_collectedIsolateId, <String>[
          'package:test/has_local.dart',
        ], local: true),
        throwsA(
          isA<vm.SentinelException>().having(
            (e) => e.sentinel.kind,
            'sentinel.kind',
            vm.SentinelKind.kCollected,
          ),
        ),
      );
    });

    test('BazelUriConverter resolves google3 and blaze URIs', () {
      final tempDir = Directory.systemTemp.createTempSync('bazel_uri_test');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final root = path.normalize(tempDir.resolveSymbolicLinksSync());
      final fastbuildBinDir = Directory(
        path.join(root, 'blaze-out', 'k8-fastbuild', 'bin'),
      )..createSync(recursive: true);
      final blazeBinDir = Directory(path.join(root, 'blaze-bin'))
        ..createSync(recursive: true);
      final blazeGenfilesDir = Directory(path.join(root, 'blaze-genfiles'))
        ..createSync(recursive: true);

      final generatedFile = File(
        path.join(blazeGenfilesDir.path, 'foo', 'bar', 'lib', 'generated.dart'),
      )..createSync(recursive: true);
      final binFile = File(
        path.join(
          blazeBinDir.path,
          'third_party',
          'dart',
          'pkg',
          'lib',
          'a.dart',
        ),
      )..createSync(recursive: true);
      final writableFile = File(
        path.join(root, 'foo', 'bar', 'lib', 'writable.dart'),
      )..createSync(recursive: true);

      final converter = BazelUriConverter(root);

      // Basic dart:, google3://, and package: paths.
      expect(converter.uriToPath('dart:io'), path.join(root, 'io'));
      expect(
        converter.uriToPath('google3://workspace_name/my/script.dart'),
        path.join(root, 'my', 'script.dart'),
      );
      expect(
        converter.uriToPath('package:foo/foo.dart'),
        path.join(root, 'third_party', 'dart', 'foo', 'lib', 'foo.dart'),
      );
      expect(
        converter.uriToPath('package:foo.bar.baz/qux.dart'),
        path.join(root, 'foo', 'bar', 'baz', 'lib', 'qux.dart'),
      );

      // Generated file in blaze-genfiles takes precedence and caches result.
      expect(
        converter.uriToPath('package:foo.bar/generated.dart'),
        generatedFile.path,
      );
      expect(
        converter.uriToPath('package:foo.bar/generated.dart'),
        generatedFile.path,
      );

      // Generated file in blaze-bin is resolved when not in blaze-genfiles.
      expect(converter.uriToPath('package:pkg/a.dart'), binFile.path);

      // File in blaze-out/k8-fastbuild/bin maps back to writable workspace file.
      final fastbuildFileUri = Uri.file(
        path.join(fastbuildBinDir.path, 'foo', 'bar', 'lib', 'writable.dart'),
      );
      expect(
        converter.uriToPath(fastbuildFileUri.toString()),
        writableFile.path,
      );
    });

    test(
      'CLI entrypoint wires --google3-workspace-root to BazelUriConverter',
      () async {
        final workspaceRoot = path.join(
          path.rootPrefix(path.current),
          'workspace',
          'root',
        );
        final entrypointPath = Isolate.resolvePackageUriSync(
          Uri.parse(
            'package:dart_runtime_service_dds/dart_runtime_service_dds.dart',
          ),
        )!.resolve('../bin/dds_entrypoint.dart').toFilePath();

        final process =
            await Process.start(Platform.resolvedExecutable, <String>[
              if (Platform.packageConfig case final String packageConfig)
                '--packages=$packageConfig',
              entrypointPath,
              '--${DartDevelopmentServiceOptions.vmServiceUriOption}='
                  '${mockVmService.uri}',
              '--${DartDevelopmentServiceOptions.google3WorkspaceRootOption}='
                  '$workspaceRoot',
            ]);
        addTearDown(process.kill);

        final stderrOutput = await process.stderr
            .transform(utf8.decoder)
            .join();
        final launchInfo =
            json.decode(stderrOutput.trim()) as Map<String, Object?>;
        expect(launchInfo['state'], 'started');

        final ddsHttpUri = Uri.parse(launchInfo['ddsUri']! as String);
        final ddsWsUri = ddsHttpUri.replace(
          scheme: 'ws',
          path: '${ddsHttpUri.path}ws',
        );
        ddsClient = await vmServiceConnectUri(ddsWsUri.toString());

        final result = await ddsClient!.lookupResolvedPackageUris(
          _runningIsolateId,
          <String>[
            'google3://workspace_name/my/script.dart',
            'package:foo/foo.dart',
          ],
          local: true,
        );

        expect(result.uris, <String?>[
          Uri.file(path.join(workspaceRoot, 'my', 'script.dart')).toString(),
          Uri.file(
            path.join(
              workspaceRoot,
              'third_party',
              'dart',
              'foo',
              'lib',
              'foo.dart',
            ),
          ).toString(),
        ]);
      },
    );
  });
}
