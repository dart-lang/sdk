// Copyright 2020 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:frontend_server_client/frontend_server_client.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

void main() async {
  FrontendServerClient? client;
  late PackageConfig packageConfig;
  late String packageRoot;
  late String packagesJsonPath;

  setUp(() async {
    await d.dir('a', [
      d.file('pubspec.yaml', '''
name: a
dependencies:
  path: ^1.0.0

environment:
  sdk: ^3.10.0-0.0.dev
      '''),
      d.dir('bin', [
        d.file('main.dart', '''
import 'package:path/path.dart' as p;

void main() async {
  print(message);
  /// Runs in a loop until it is hot reloaded with a new message.
  while (!message.contains('goodbye')) {
    await Future.delayed(const Duration(seconds: 1));
  }
  print(message);
}

String get message => p.join('hello', 'world');

'''),
      ]),
    ]).create();
    packageRoot = p.join(d.sandbox, 'a');
    await Process.run(Platform.resolvedExecutable, [
      'pub',
      'get',
    ], workingDirectory: packageRoot);
    packageConfig = (await findPackageConfig(Directory(packageRoot)))!;
    packagesJsonPath =
        findNearestPackageConfigPath(Directory(packageRoot)) ??
        p.join(packageRoot, '.dart_tool', 'package_config.json');
  });

  tearDown(() async {
    await client?.shutdown();
    client = null;
  });

  test('can compile, recompile, and hot reload a vm app', () async {
    final entrypoint = p.join(packageRoot, 'bin', 'main.dart');
    client = await FrontendServerClient.start(
      entrypoint,
      p.join(packageRoot, 'out.dill'),
      vmPlatformDill,
      packagesJson: packagesJsonPath,
    );
    var result = await client!.compile();
    client!.accept();
    expect(result.compilerOutputLines, isEmpty);
    expect(result.errorCount, 0);
    expect(
      result.newSources,
      containsAll([
        File(entrypoint).uri,
        packageConfig.resolve(Uri.parse('package:path/path.dart')),
      ]),
    );
    expect(result.removedSources, isEmpty);
    expect(result.dillOutput, isNotNull);
    expect(File(result.dillOutput!).existsSync(), true);
    final process = await Process.start(Platform.resolvedExecutable, [
      '--observe',
      '--no-pause-isolates-on-exit',
      '--pause-isolates-on-start',
      result.dillOutput!,
    ]);
    addTearDown(process.kill);
    final stdoutLines = StreamQueue(
      process.stdout.transform(utf8.decoder).transform(const LineSplitter()),
    );
    addTearDown(stdoutLines.cancel);

    final observatoryLine = await stdoutLines.next;
    final observatoryUri =
        '${observatoryLine.split(' ').last.replaceFirst('http', 'ws')}ws';
    final vmService = await vmServiceConnectUri(observatoryUri);
    addTearDown(vmService.dispose);
    final isolate = await waitForIsolatesAndResume(vmService);

    await expectLater(stdoutLines, emitsThrough(p.join('hello', 'world')));

    final appFile = File(entrypoint);
    final originalContent = await appFile.readAsString();
    final newContent = originalContent.replaceFirst('hello', 'goodbye');
    await appFile.writeAsString(newContent);

    result = await client!.compile([File(entrypoint).uri]);

    client!.accept();
    expect(result.newSources, isEmpty);
    expect(result.removedSources, isEmpty);
    expect(result.compilerOutputLines, isEmpty);
    expect(result.errorCount, 0);
    expect(result.dillOutput, endsWith('.incremental.dill'));

    await vmService.reloadSources(isolate.id!, rootLibUri: result.dillOutput);

    expect(await stdoutLines.next, p.join('goodbye', 'world'));
    expect(await process.exitCode, 0);
  });

  test('can handle compile errors and reload fixes', () async {
    final entrypoint = p.join(packageRoot, 'bin', 'main.dart');
    final entrypointFile = File(entrypoint);
    final originalContent = await entrypointFile.readAsString();
    // append two compile errors to the bottom
    await entrypointFile.writeAsString(
      '$originalContent\nint foo = 1.0;\nString bar = 4;',
    );

    client = await FrontendServerClient.start(
      entrypoint,
      p.join(packageRoot, 'out.dill'),
      vmPlatformDill,
      packagesJson: packagesJsonPath,
    );
    var result = await client!.compile();

    client!.accept();
    expect(result.errorCount, 2);
    expect(
      result.compilerOutputLines,
      allOf(contains('int foo = 1.0;'), contains('String bar = 4;')),
    );
    expect(
      result.newSources,
      containsAll([
        File(entrypoint).uri,
        packageConfig.resolve(Uri.parse('package:path/path.dart')),
      ]),
    );
    expect(result.removedSources, isEmpty);
    expect(result.dillOutput, isNotNull);
    expect(File(result.dillOutput!).existsSync(), true);

    final process = await Process.start(Platform.resolvedExecutable, [
      '--observe',
      '--no-pause-isolates-on-exit',
      '--pause-isolates-on-start',
      result.dillOutput!,
    ]);
    addTearDown(process.kill);
    final stdoutLines = StreamQueue(
      process.stdout.transform(utf8.decoder).transform(const LineSplitter()),
    );
    addTearDown(stdoutLines.cancel);

    final observatoryLine = await stdoutLines.next;
    final observatoryUri =
        '${observatoryLine.split(' ').last.replaceFirst('http', 'ws')}ws';
    final vmService = await vmServiceConnectUri(observatoryUri);
    addTearDown(vmService.dispose);
    final isolate = await waitForIsolatesAndResume(vmService);

    // The program actually runs regardless of the errors, as they don't affect
    // the runtime behavior.
    await expectLater(stdoutLines, emitsThrough(p.join('hello', 'world')));

    await entrypointFile.writeAsString(
      originalContent.replaceFirst('hello', 'goodbye'),
    );
    result = await client!.compile([entrypointFile.uri]);
    client!.accept();
    expect(result.errorCount, 0);
    expect(result.compilerOutputLines, isEmpty);
    expect(result.newSources, isEmpty);
    expect(result.removedSources, isEmpty);
    expect(result.dillOutput, isNotNull);
    expect(File(result.dillOutput!).existsSync(), true);

    await vmService.reloadSources(isolate.id!, rootLibUri: result.dillOutput);

    expect(await stdoutLines.next, p.join('goodbye', 'world'));
    expect(await process.exitCode, 0);
  });

  test('can compile and recompile a dartdevc app', () async {
    final entrypoint = p
        .toUri(p.join(packageRoot, 'bin', 'main.dart'))
        .toString();
    final dartDevcClient = client = await DartDevcFrontendServerClient.start(
      entrypoint,
      p.join(packageRoot, 'out.dill'),
      platformKernel: p
          .toUri(p.join(sdkDir, 'lib', '_internal', 'ddc_platform.dill'))
          .toString(),
      packagesJson: packagesJsonPath,
    );
    var result = await client!.compile();
    client!.accept();

    expect(result.compilerOutputLines, isEmpty);
    expect(result.errorCount, 0);
    expect(
      result.newSources,
      containsAll([
        Uri.parse(entrypoint),
        packageConfig.resolve(Uri.parse('package:path/path.dart')),
      ]),
    );
    expect(result.removedSources, isEmpty);

    expect(result.dillOutput, isNotNull);
    expect(File(result.jsManifestOutput!).existsSync(), true);
    expect(File(result.jsSourcesOutput!).existsSync(), true);
    expect(File(result.jsSourceMapsOutput!).existsSync(), true);

    final entrypointUri = Uri.parse(entrypoint);
    expect(
      utf8.decode(dartDevcClient.assetBytes('${entrypointUri.path}.lib.js')!),
      contains('hello'),
    );

    final appFile = File(entrypointUri.toFilePath());
    final originalContent = await appFile.readAsString();
    final newContent = originalContent.replaceFirst('hello', 'goodbye');
    await appFile.writeAsString(newContent);

    result = await client!.compile([entrypointUri]);
    client!.accept();
    expect(result.newSources, isEmpty);
    expect(result.removedSources, isEmpty);
    expect(result.compilerOutputLines, isEmpty);
    expect(result.errorCount, 0);
    expect(result.jsManifestOutput, endsWith('.incremental.dill.json'));

    expect(
      utf8.decode(dartDevcClient.assetBytes('${entrypointUri.path}.lib.js')!),
      contains('goodbye'),
    );
  });

  group('DDC library bundle format', () {
    late Uri entrypointUri;
    late String entrypoint;
    late String mainModule;
    late DartDevcFrontendServerClient ddcClient;

    Future<void> startAndCompile() async {
      entrypointUri = p.toUri(p.join(packageRoot, 'bin', 'main.dart'));
      entrypoint = entrypointUri.toString();
      mainModule = '${entrypointUri.path}.lib.js';
      client = ddcClient = await DartDevcFrontendServerClient.start(
        entrypoint,
        p.join(packageRoot, 'out.dill'),
        dartdevcModuleFormat: 'ddc',
        canaryFeatures: true,
        packagesJson: packagesJsonPath,
      );
      final result = await ddcClient.compile();
      ddcClient.accept();
      expect(
        result.errorCount,
        0,
        reason: result.compilerOutputLines.join('\n'),
      );
    }

    Future<void> editMain(String from, String to) async {
      final file = File(entrypointUri.toFilePath());
      await file.writeAsString(
        (await file.readAsString()).replaceFirst(from, to),
      );
    }

    // Compiles an expression at: `print(message);`
    Future<CompileResult> compileExpression(
      String expression, {
      String? libraryUri,
    }) => ddcClient.compileExpressionToJs(
      expression: expression,
      libraryUri: libraryUri ?? entrypoint,
      scriptUri: libraryUri ?? entrypoint,
      line: 4,
      column: 3,
      jsFrameValues: {},
      jsModules: {},
      moduleName: '',
    );

    test('provides debugger metadata and reloaded sources', () async {
      await startAndCompile();
      expect(utf8.decode(ddcClient.assetBytes(mainModule)!), contains('hello'));
      expect(ddcClient.assetBytes('$mainModule.map'), isNotNull);
      final metadata =
          jsonDecode(utf8.decode(ddcClient.assetBytes('$mainModule.metadata')!))
              as Map<String, dynamic>;
      final mergedMetadata = const LineSplitter()
          .convert(ddcClient.mergedMetadata)
          .map(jsonDecode)
          .toList();
      expect(mergedMetadata, hasLength(greaterThan(1)));
      expect(mergedMetadata, contains(equals(metadata)));

      await editMain('hello', 'goodbye');
      final result = await ddcClient.compile([entrypointUri]);
      ddcClient.accept();
      expect(result.errorCount, 0);
      expect(
        utf8.decode(ddcClient.assetBytes(mainModule)!),
        contains('goodbye'),
      );
      expect(ddcClient.reloadedSources, [
        {
          'src': mainModule,
          'module': metadata['name'],
          'libraries': [entrypoint],
        },
      ]);
    });

    test('can hot restart after a rejected hot reload', () async {
      await d.dir('a', [
        d.dir('bin', [
          d.file('main.dart', '''
class A {
  const A();
}

void main() {
  print(const A());
}
'''),
        ]),
      ]).create();
      await startAndCompile();

      await editMain('const A();', 'A();');
      await editMain('const A()', 'A()');
      var result = await ddcClient.compile([entrypointUri]);
      expect(result.errorCount, greaterThan(0));
      expect(
        result.compilerOutputLines,
        contains(contains('Const class cannot become non-const')),
      );
      await ddcClient.reject();

      // Rejected URIs are resent.
      result = await ddcClient.recompileRestart([]);
      ddcClient.accept();
      expect(
        result.errorCount,
        0,
        reason: result.compilerOutputLines.join('\n'),
      );
      expect(ddcClient.reloadedSources.map((entry) => entry['src']), [
        mainModule,
      ]);
    });

    test('can compile expressions to JS', () async {
      await startAndCompile();

      var result = await compileExpression('message.length');
      expect(
        result.errorCount,
        0,
        reason: result.compilerOutputLines.join('\n'),
      );
      expect(result.compiledExpression, contains('message'));

      result = await compileExpression('notDefined');
      expect(result.errorCount, greaterThan(0));
      expect(result.compiledExpression, isNull);
      expect(result.compilerOutputLines.join('\n'), contains('notDefined'));

      // Fails before compiling.
      result = await compileExpression(
        '1',
        libraryUri: 'package:a/missing.dart',
      );
      expect(result.errorCount, 1);
      expect(result.compiledExpression, isNull);
      expect(result.compilerOutputLines.join('\n'), isNotEmpty);
    });

    test(
      'queues expression compile requests until a compile is accepted',
      () async {
        await startAndCompile();
        await editMain('hello', 'goodbye');

        final compile = ddcClient.compile([entrypointUri]);
        var accepted = false;
        final expressions =
            Future.wait([
              compileExpression('message'),
              compileExpression('message.length'),
            ]).then((results) {
              expect(accepted, isTrue);
              return results;
            });
        final result = await compile;
        expect(result.errorCount, 0);
        accepted = true;
        ddcClient.accept();

        for (final result in await expressions) {
          expect(
            result.errorCount,
            0,
            reason: result.compilerOutputLines.join('\n'),
          );
          expect(result.compiledExpression, isNotEmpty);
        }
      },
    );

    test('generates bootstrap scripts', () {
      final bootstrap = generateDdcLibraryBundleBootstrapScript(
        ddcModuleLoaderUrl: 'loader.js',
        mapperUrl: 'mapper.js',
        sdkUrl: 'sdk.js',
        mainModuleUrl: 'main_module.js',
      );
      for (final url in [
        'loader.js',
        'mapper.js',
        'sdk.js',
        'main_module.js',
      ]) {
        expect(bootstrap, contains('"$url"'));
      }

      const app = 'org-dartlang-app:///web/main.dart';
      final mainModuleJs = generateDdcLibraryBundleMainModule(
        entrypoint: app,
        onLoadEndBootstrap: 'on_load_end.js',
      );
      expect(mainModuleJs, contains('const appName = "$app";'));
      expect(mainModuleJs, contains("const onLoadEndSrc = 'on_load_end.js';"));
      expect(mainModuleJs, contains('/* MAIN_EXTENSION_MARKER */'));
    });
  });

  group('DdcLibraryBundleSdkAssets', () {
    // Creates an SDK with only the scripts that it ships.
    Future<String> createSdk() async {
      await d.dir('sdk', [
        d.dir('lib', [
          d.dir('dev_compiler', [
            d.dir('ddc', [d.file('ddc_module_loader.js', 'loader')]),
            d.dir('web', [d.file('dart_stack_trace_mapper.js', 'mapper')]),
          ]),
        ]),
      ]).create();
      return p.join(d.sandbox, 'sdk');
    }

    test('loads SDK scripts with dart_sdk.js from sdkJsPath', () async {
      final sdkRoot = await createSdk();
      await d.dir('out', [
        d.file('dart_sdk.js', 'sdk'),
        d.file('dart_sdk.js.map', 'map'),
      ]).create();
      final assets = await DdcLibraryBundleSdkAssets.load(
        sdkJsPath: p.join(d.sandbox, 'out', 'dart_sdk.js'),
        sdkRoot: sdkRoot,
      );
      expect(
        [
          assets.moduleLoader,
          assets.stackTraceMapper,
          assets.sdkJs,
          assets.sdkJsMap,
        ].map(utf8.decode),
        ['loader', 'mapper', 'sdk', 'map'],
      );
    });

    test('throws if sdkJsPath does not exist', () async {
      expect(
        DdcLibraryBundleSdkAssets.load(
          sdkJsPath: p.join(d.sandbox, 'out', 'dart_sdk.js'),
          sdkRoot: await createSdk(),
        ),
        throwsArgumentError,
      );
    });

    test("throws if the SDK can't be compiled", () async {
      expect(
        DdcLibraryBundleSdkAssets.load(sdkRoot: await createSdk()),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('compiles and caches dart_sdk.js', () async {
      final cacheDir = p.join('.dart_tool', 'frontend_server_client', 'sdk');
      addTearDown(() => Directory(cacheDir).delete(recursive: true));
      await d.dir('stale', [d.file('dart_sdk.js', 'old')]).create(cacheDir);
      await d.dir('tmp_other').create(cacheDir);
      final assets = await DdcLibraryBundleSdkAssets.load();
      expect(utf8.decode(assets.sdkJs), contains('dart_sdk.js.map'));
      expect(assets.sdkJsMap, isNotEmpty);
      expect(assets.moduleLoader, isNotEmpty);
      expect(assets.stackTraceMapper, isNotEmpty);
      expect(
        Directory(p.join(cacheDir, 'stale')).existsSync(),
        isFalse,
        reason: 'Deletes the outputs of other SDK builds.',
      );
      expect(
        Directory(p.join(cacheDir, 'tmp_other')).existsSync(),
        isTrue,
        reason: 'Keeps the outputs of other compiles.',
      );

      final cachedSubdir = Directory(cacheDir)
          .listSync()
          .whereType<Directory>()
          .where((dir) => !p.basename(dir.path).startsWith('tmp_'))
          .single;
      final cachedSdkJs = File(p.join(cachedSubdir.path, 'dart_sdk.js'));
      cachedSdkJs.writeAsStringSync('cached');
      final cachedAssets = await DdcLibraryBundleSdkAssets.load();
      expect(
        utf8.decode(cachedAssets.sdkJs),
        'cached',
        reason: 'Reuses the compiled SDK.',
      );
    }, timeout: const Timeout.factor(4));
  });

  test('can enable experiments', () async {
    await d.dir('a', [
      d.dir('bin', [
        d.file('nnbd.dart', '''

// Compile time error if nnbd is enabled
int x;

void main() {
  print(x);
}
'''),
      ]),
    ]).create();
    final entrypoint = p.join(packageRoot, 'bin', 'nnbd.dart');
    client = await FrontendServerClient.start(
      entrypoint,
      p.join(packageRoot, 'out.dill'),
      vmPlatformDill,
      enabledExperiments: ['non-nullable'],
      packagesJson: packagesJsonPath,
    );
    final result = await client!.compile();
    client!.accept();
    expect(result.errorCount, 1);
    expect(result.compilerOutputLines, contains(contains('int x;')));
  });

  test('can compile and recompile filenames with spaces', () async {
    await d.dir('a', [
      d.dir('bin', [
        d.file('main with spaces.dart', '''
void main() {
  print('hello world');
}
'''),
      ]),
    ]).create();

    final entrypoint = p.join(packageRoot, 'bin', 'main with spaces.dart');
    client = await FrontendServerClient.start(
      entrypoint,
      p.join(packageRoot, 'out with spaces.dill'),
      vmPlatformDill,
      packagesJson: packagesJsonPath,
    );
    var result = await client!.compile();
    client!.accept();
    expect(result.compilerOutputLines, isEmpty);
    expect(result.errorCount, 0);
    expect(result.newSources, containsAll([File(entrypoint).uri]));
    expect(result.removedSources, isEmpty);
    expect(result.dillOutput, isNotNull);
    expect(File(result.dillOutput!).existsSync(), true);
    var processResult = await Process.run(Platform.resolvedExecutable, [
      result.dillOutput!,
    ]);

    expect(processResult.stdout, startsWith('hello world'));
    expect(processResult.exitCode, 0);

    final appFile = File(entrypoint);
    final originalContent = await appFile.readAsString();
    final newContent = originalContent.replaceFirst('hello', 'goodbye');
    await appFile.writeAsString(newContent);
    result = await client!.compile([appFile.uri]);
    expect(result.compilerOutputLines, isEmpty);
    expect(result.errorCount, 0);
    expect(result.newSources, isEmpty);
    expect(result.removedSources, isEmpty);

    processResult = await Process.run(Platform.resolvedExecutable, [
      result.dillOutput!,
    ]);
    expect(processResult.stdout, startsWith('goodbye world'));
    expect(processResult.exitCode, 0);
  });

  test('can support custom librariesSpec', () async {
    final defaultLibrariesJson = File(p.join(sdkDir, 'lib', 'libraries.json'));
    final libraries =
        jsonDecode(defaultLibrariesJson.readAsStringSync())
            as Map<String, Object?>;

    // Create the custom library file
    final customLibFile = File(p.join(packageRoot, 'bin', 'custom_lib.dart'));
    await customLibFile.writeAsString('void hello() => print("custom!");');

    if (libraries['vm_common'] case {
      'libraries': final Map<String, Object?> libs,
    }) {
      libs['custom_lib'] = {'uri': customLibFile.absolute.uri.toString()};
    }

    final customLibrariesJsonFile = File(p.join(packageRoot, 'libraries.json'));
    await customLibrariesJsonFile.writeAsString(jsonEncode(libraries));

    final entrypoint = p.join(packageRoot, 'bin', 'main_custom.dart');
    await File(entrypoint).writeAsString('''
      import 'dart:custom_lib';
      void main() {
        hello();
      }
    ''');

    client = await FrontendServerClient.start(
      entrypoint,
      p.join(packageRoot, 'out_custom.dill'),
      vmPlatformDill,
      packagesJson: packagesJsonPath,
      librariesSpec: customLibrariesJsonFile.uri.toString(),
    );
    var result = await client!.compile();
    client!.accept();
    expect(result.errorCount, 0);
    expect(result.dillOutput, isNotNull);
    await client!.shutdown();

    // Without librariesSpec, compiling the same entrypoint should fail
    client = await FrontendServerClient.start(
      entrypoint,
      p.join(packageRoot, 'out_custom_fail.dill'),
      vmPlatformDill,
      packagesJson: packagesJsonPath,
    );
    result = await client!.compile();
    client!.accept();
    expect(result.errorCount, greaterThan(0));
  });

  test('can compile when specifying an explicit sdkRoot', () async {
    final entrypoint = p.join(packageRoot, 'bin', 'simple.dart');
    await File(entrypoint).writeAsString('void main() => print("ok");');
    client = await FrontendServerClient.start(
      entrypoint,
      p.join(packageRoot, 'out.dill'),
      vmPlatformDill,
      packagesJson: packagesJsonPath,
      sdkRoot: sdkDir,
    );
    final result = await client!.compile();
    client!.accept();
    expect(result.errorCount, 0);
    expect(result.dillOutput, isNotNull);
    final dartExe = p.join(
      sdkDir,
      'bin',
      Platform.isWindows ? 'dart.exe' : 'dart',
    );
    final processResult = await Process.run(dartExe, [result.dillOutput!]);
    expect(processResult.stdout, startsWith('ok'));
    expect(processResult.exitCode, 0);
  });

  test('throws ArgumentError if frontendServerPath does not exist', () async {
    final entrypoint = p.join(packageRoot, 'bin', 'simple.dart');
    await File(entrypoint).writeAsString('void main() => print("ok");');
    expect(
      () => FrontendServerClient.start(
        entrypoint,
        p.join(packageRoot, 'out.dill'),
        vmPlatformDill,
        packagesJson: packagesJsonPath,
        frontendServerPath: p.join(packageRoot, 'non_existent_snapshot'),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test(
    'throws ArgumentError if AOT snapshot does not exist in sdkRoot',
    () async {
      final entrypoint = p.join(packageRoot, 'bin', 'simple.dart');
      await File(entrypoint).writeAsString('void main() => print("ok");');
      expect(
        () => FrontendServerClient.start(
          entrypoint,
          p.join(packageRoot, 'out.dill'),
          vmPlatformDill,
          packagesJson: packagesJsonPath,
          sdkRoot: p.join(packageRoot, 'non_existent_sdk'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    },
  );
}

Future<Isolate> waitForIsolatesAndResume(VmService vmService) async {
  var vm = await vmService.getVM();
  var isolates = vm.isolates;
  while (isolates == null || isolates.isEmpty) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    vm = await vmService.getVM();
    isolates = vm.isolates;
  }
  final isolateRef = isolates.first;
  var isolate = await vmService.getIsolate(isolateRef.id!);
  while (isolate.pauseEvent?.kind != EventKind.kPauseStart) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    isolate = await vmService.getIsolate(isolateRef.id!);
  }
  await vmService.resume(isolate.id!);
  return isolate;
}

final vmPlatformDill = p
    .toUri(p.join(sdkDir, 'lib', '_internal', 'vm_platform_strong.dill'))
    .toString();
final sdkDir = p.dirname(p.dirname(Platform.resolvedExecutable));
