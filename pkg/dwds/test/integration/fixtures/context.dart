// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build_daemon/client.dart';
import 'package:build_daemon/data/build_status.dart';
import 'package:build_daemon/data/build_target.dart';
import 'package:dwds/asset_reader.dart';
import 'package:dwds/dart_web_debug_service.dart';
import 'package:dwds/src/connections/app_connection.dart';
import 'package:dwds/src/connections/debug_connection.dart';
import 'package:dwds/src/debugging/webkit_debugger.dart';
import 'package:dwds/src/loaders/build_runner_strategy_provider.dart';
import 'package:dwds/src/loaders/frontend_server_strategy_provider.dart';
import 'package:dwds/src/loaders/strategy.dart';
import 'package:dwds/src/readers/proxy_server_asset_reader.dart';
import 'package:dwds/src/services/chrome/chrome_proxy_service.dart';
import 'package:dwds/src/services/expression_compiler.dart';
import 'package:dwds/src/services/expression_compiler_service.dart';
import 'package:dwds/src/utilities/dart_uri.dart';
import 'package:dwds/src/utilities/server.dart';
import 'package:dwds_test_common/logging.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:dwds_test_common/utilities.dart';
import 'package:file/local.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:logging/logging.dart' as logging;
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf.dart';
import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';
import 'package:webdriver/async_io.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../../frontend_server_common/devfs.dart';
import '../../frontend_server_common/resident_runner.dart';
import 'project.dart';
import 'server.dart';
import 'utilities.dart';

final _exeExt = Platform.isWindows ? '.exe' : '';

const isRPCError = TypeMatcher<RPCError>();
const isSentinelException = TypeMatcher<SentinelException>();

final Matcher throwsRPCError = throwsA(isRPCError);
final Matcher throwsSentinelException = throwsA(isSentinelException);

Matcher isRPCErrorWithMessage(String message) => isA<RPCError>().having(
  (RPCError e) => e.message,
  'message',
  contains(message),
);
Matcher throwsRPCErrorWithMessage(String message) =>
    throwsA(isRPCErrorWithMessage(message));

Matcher isRPCErrorWithCode(int code) =>
    isA<RPCError>().having((RPCError e) => e.code, 'code', equals(code));
Matcher throwsRPCErrorWithCode(int code) => throwsA(isRPCErrorWithCode(code));

enum CompilationMode {
  buildDaemon(false, true, false),
  frontendServer(true, false, false),
  buildDaemonAndFrontendServer(true, true, true);

  final bool usesFrontendServer;
  final bool usesBuildDaemon;
  final bool usesDdcModulesOnly;

  const CompilationMode(
    this.usesFrontendServer,
    this.usesBuildDaemon,
    this.usesDdcModulesOnly,
  );
}

class TestContext {
  final TestProject project;
  final TestSdkConfigurationProvider sdkConfigurationProvider;

  String get appUrl => _appUrl!;
  late String? _appUrl;

  WipConnection get tabConnection => _tabConnection!;
  late WipConnection? _tabConnection;

  TestServer get testServer => _testServer!;
  TestServer? _testServer;

  Dwds? get dwds => _testServer?.dwds;

  BuildDaemonClient get daemonClient => _daemonClient!;
  BuildDaemonClient? _daemonClient;

  ResidentWebRunner get webRunner => _webRunner!;
  ResidentWebRunner? _webRunner;

  WebDriver get webDriver => _webDriver!;
  WebDriver? _webDriver;

  Process get chromeDriver => _chromeDriver!;
  Process? _chromeDriver;

  WebkitDebugger get webkitDebugger => _webkitDebugger!;
  late WebkitDebugger? _webkitDebugger;

  Handler get assetHandler => _assetHandler!;
  late Handler? _assetHandler;

  Client get client => _client!;
  Client? _client;

  ExpressionCompilerService? ddcService;

  int get port => _port!;
  late int? _port;

  Directory get outputDir => _outputDir!;
  Directory? _outputDir;

  late WipConnection extensionConnection;
  late AppConnection appConnection;
  late DebugConnection debugConnection;

  final _logger = logging.Logger('Context');

  final _serviceNameToMethod = <String, String?>{};

  late LocalFileSystem frontendServerFileSystem;

  late String _hostname;

  /// Internal VM service.
  ///
  /// Prefer using [vmService] instead in tests when possible, to include
  /// testing of the VmServerConnection (bypassed when using [service]).
  ChromeProxyService get service => fetchChromeProxyService(debugConnection);

  /// External VM service.
  VmService get vmService => debugConnection.vmService;

  TestContext(this.project, this.sdkConfigurationProvider);

  Future<void> setUp({
    TestSettings testSettings = const TestSettings(),
    TestAppMetadata appMetadata = const TestAppMetadata.externalApp(),
    TestDebugSettings debugSettings =
        const TestDebugSettings.noDevToolsLaunch(),
  }) async {
    try {
      // Build settings to return from load strategy.
      final buildSettings = TestBuildSettings(
        appEntrypoint: project.dartEntryFilePackageUri,
        canaryFeatures: testSettings.canaryFeatures,
        isFlutterApp: testSettings.isFlutterApp,
        experiments: testSettings.experiments,
      );

      // Make sure configuration was created correctly.
      final sdkLayout = sdkConfigurationProvider.sdkLayout;
      final configuration = await sdkConfigurationProvider.configuration;
      configuration.validate();
      await project.setUp();

      DartUri.currentDirectory = project.absolutePackageDirectory;

      _logger.info(
        'Serving: ${project.directoryToServe}/${project.filePathToServe}',
      );
      _logger.info('Project: ${project.absolutePackageDirectory}');
      _logger.info('Packages: ${project.packageConfigFile}');
      _logger.info('Entry: ${project.dartEntryFilePath}');

      configureLogWriter();

      _client = IOClient(
        HttpClient()
          ..maxConnectionsPerHost = 200
          ..idleTimeout = const Duration(seconds: 30)
          ..connectionTimeout = const Duration(seconds: 30),
      );

      final systemTempDir = Directory.systemTemp;
      _outputDir = systemTempDir.createTempSync('foo bar');

      final chromeDriverPort = await findUnusedPort();
      final chromeDriverUrlBase = 'wd/hub';
      try {
        _chromeDriver = await Process.start('chromedriver$_exeExt', [
          '--port=$chromeDriverPort',
          '--url-base=$chromeDriverUrlBase',
        ]);
        final stdOutLines = chromeDriver.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .asBroadcastStream();

        final stdErrLines = chromeDriver.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .asBroadcastStream();

        // Sometimes ChromeDriver can be slow to startup.
        // This was seen on a github actions run:
        // > 11:22:59.924700: ChromeDriver stdout: Starting ChromeDriver
        // >                  139.0.7258.154 ([...]) on port 38107
        // > [...]
        // > 11:23:00.237350: ChromeDriver stdout: ChromeDriver was started
        // >                  successfully on port 38107.
        // Where in the 300+ ms it took before it was actually ready to accept
        // a connection we had tried - and failed - to connect.
        // We therefore wait until ChromeDriver reports that it has started
        // successfully.

        final chromeDriverStartup = Completer<void>();
        stdOutLines.listen((line) {
          if (!chromeDriverStartup.isCompleted &&
              line.contains('was started successfully')) {
            chromeDriverStartup.complete();
          }
          _logger.finest('ChromeDriver stdout: $line');
        });
        stdErrLines.listen(
          (line) => _logger.warning('ChromeDriver stderr: $line'),
        );

        await chromeDriverStartup.future;
      } catch (e) {
        throw StateError(
          'Could not start ChromeDriver. Is it installed?\nError: $e',
        );
      }

      await Process.run(sdkLayout.dartPath, [
        'pub',
        'upgrade',
      ], workingDirectory: project.absolutePackageDirectory);

      ExpressionCompiler? expressionCompiler;
      AssetReader assetReader;
      Stream<BuildResults> buildResults;
      LoadStrategy loadStrategy;
      var basePath = '';
      var filePathToServe = project.filePathToServe;

      // Start the HTTP server and save its used port.
      final httpServer = await startHttpServer('localhost');
      _port = httpServer.port;

      final reloadedSourcesUri = Uri.parse(
        'http://localhost:$_port/${WebDevFS.reloadedSourcesFileName}',
      );

      switch (testSettings.compilationMode) {
        case CompilationMode.buildDaemon:
          {
            final options = [
              if (testSettings.enableExpressionEvaluation) ...[
                '--define',
                'build_web_compilers|ddc=generate-full-dill=true',
              ],
              for (final experiment in buildSettings.experiments)
                '--enable-experiment=$experiment',
              if (buildSettings.canaryFeatures) ...[
                '--define',
                'build_web_compilers|ddc=canary=true',
                '--define',
                'build_web_compilers|sdk_js=canary=true',
              ],
              if (testSettings.moduleFormat == ModuleFormat.ddc) ...[
                '--define',
                'build_web_compilers|ddc=ddc-library-bundle=true',
                '--define',
                'build_web_compilers|sdk_js=ddc-library-bundle=true',
                '--define',
                'build_web_compilers|entrypoint=ddc-library-bundle=true',
                '--define',
                'build_web_compilers|entrypoint_marker=ddc-library-bundle=true',
              ],
              '--verbose',
            ];
            _daemonClient = await connectClient(
              sdkLayout.dartPath,
              project.absolutePackageDirectory,
              options,
              (log) {
                final record = log.toLogRecord();
                final name = record.loggerName == ''
                    ? ''
                    : '${record.loggerName}: ';
                _logger.log(
                  record.level,
                  '$name${record.message}',
                  record.error,
                  record.stackTrace,
                );
              },
            );
            daemonClient.registerBuildTarget(
              DefaultBuildTarget((b) => b..target = project.directoryToServe),
            );
            daemonClient.startBuild();

            await waitForSuccessfulBuild();

            final assetServerPort = daemonPort(
              project.absolutePackageDirectory,
            );
            if (testSettings.moduleFormat == ModuleFormat.ddc &&
                buildSettings.canaryFeatures) {
              _assetHandler = _createBuildRunnerDdcLibraryBundleAssetHandler(
                assetServerPort,
              );
              assetReader = ProxyServerAssetReader.fromHandler(_assetHandler!);
            } else {
              _assetHandler = _createBuildRunnerAmdAssetHandler(
                assetServerPort,
              );
              assetReader = ProxyServerAssetReader(
                assetServerPort,
                root: project.directoryToServe,
              );
            }

            if (testSettings.enableExpressionEvaluation) {
              ddcService = ExpressionCompilerService(
                'localhost',
                _port!,
                verbose: testSettings.verboseCompiler,
                sdkConfigurationProvider: sdkConfigurationProvider,
              );
              expressionCompiler = ddcService;
            }

            loadStrategy = switch ((
              testSettings.moduleFormat,
              buildSettings.canaryFeatures,
            )) {
              (ModuleFormat.ddc, true) =>
                BuildRunnerDdcLibraryBundleStrategyProvider(
                  testSettings.reloadConfiguration,
                  assetReader,
                  buildSettings,
                  reloadedSourcesUri: reloadedSourcesUri,
                ).strategy,
              (ModuleFormat.ddc, false) => throw Exception(
                'Unsupported DDC configuration: build daemon + canary (false) '
                '+ DDC module format ${testSettings.moduleFormat.name}.',
              ),

              _ => BuildRunnerRequireStrategyProvider(
                testSettings.reloadConfiguration,
                assetReader,
                buildSettings,
              ).strategy,
            };

            buildResults = daemonClient.buildResults;
          }
          break;
        case CompilationMode.frontendServer:
          {
            filePathToServe = webCompatiblePath([
              project.directoryToServe,
              project.filePathToServe,
            ]);

            _logger.info('Serving: $filePathToServe');

            final entry = p.toUri(
              p.join(project.webAssetsPath, project.dartEntryFileName),
            );
            frontendServerFileSystem = const LocalFileSystem();
            final packageUriMapper = await PackageUriMapper.create(
              frontendServerFileSystem,
              project.packageConfigFile,
              useDebuggerModuleNames: testSettings.useDebuggerModuleNames,
            );

            final compilerOptions = TestCompilerOptions(
              experiments: buildSettings.experiments,
              canaryFeatures: buildSettings.canaryFeatures,
              moduleFormat: testSettings.moduleFormat,
            );

            _webRunner = ResidentWebRunner(
              mainUri: entry,
              urlTunneler: debugSettings.urlEncoder,
              projectDirectory: Directory(project.absolutePackageDirectory).uri,
              packageConfigFile: project.packageConfigFile,
              packageUriMapper: packageUriMapper,
              fileSystemRoots: [
                Directory(project.absolutePackageDirectory).uri,
              ],
              fileSystemScheme: 'org-dartlang-app',
              outputPath: outputDir.path,
              compilerOptions: compilerOptions,
              sdkLayout: sdkLayout,
              verbose: testSettings.verboseCompiler,
            );

            final assetServerPort = await findUnusedPort();
            _hostname = appMetadata.hostname;
            await webRunner.run(
              frontendServerFileSystem,
              hostname: _hostname,
              port: assetServerPort,
              index: filePathToServe,
            );

            if (testSettings.enableExpressionEvaluation) {
              expressionCompiler = webRunner.expressionCompiler;
            }

            basePath = webRunner.devFS!.assetServer.basePath;
            assetReader = webRunner.devFS!.assetServer;
            _assetHandler = webRunner.devFS!.assetServer.handleRequest;
            loadStrategy = switch (testSettings.moduleFormat) {
              ModuleFormat.amd => FrontendServerRequireStrategyProvider(
                testSettings.reloadConfiguration,
                assetReader,
                packageUriMapper,
                () async => {},
                buildSettings,
              ).strategy,
              ModuleFormat.ddc =>
                buildSettings.canaryFeatures
                    ? FrontendServerDdcLibraryBundleStrategyProvider(
                        testSettings.reloadConfiguration,
                        assetReader,
                        packageUriMapper,
                        () async => {},
                        buildSettings,
                        reloadedSourcesUri: reloadedSourcesUri,
                      ).strategy
                    : FrontendServerDdcStrategyProvider(
                        testSettings.reloadConfiguration,
                        assetReader,
                        packageUriMapper,
                        () async => {},
                        buildSettings,
                      ).strategy,
              _ => throw Exception(
                'Unsupported DDC module format '
                '${testSettings.moduleFormat.name}.',
              ),
            };
            buildResults = const Stream<BuildResults>.empty();
          }
          break;
        case CompilationMode.buildDaemonAndFrontendServer:
          {
            final options = [
              if (testSettings.enableExpressionEvaluation) ...[
                '--define',
                'build_web_compilers|ddc=generate-full-dill=true',
              ],
              for (final experiment in buildSettings.experiments)
                '--enable-experiment=$experiment',
              '--define',
              'build_web_compilers|ddc=canary=true',
              '--define',
              'build_web_compilers|sdk_js=canary=true',
              '--define',
              'build_web_compilers|sdk_js=web-hot-reload=true',
              '--define',
              'build_web_compilers|entrypoint=web-hot-reload=true',
              '--define',
              'build_web_compilers|entrypoint_marker=web-hot-reload=true',
              '--define',
              'build_web_compilers|entrypoint_marker=web-assets-path='
                  '${project.webAssetsPath}',
              '--define',
              'build_web_compilers|ddc=web-hot-reload=true',
              '--define',
              'build_web_compilers|ddc_modules=web-hot-reload=true',
              '--verbose',
            ];
            _daemonClient = await connectClient(
              sdkLayout.dartPath,
              project.absolutePackageDirectory,
              options,
              (log) {
                final record = log.toLogRecord();
                final name = record.loggerName == ''
                    ? ''
                    : '${record.loggerName}: ';
                _logger.log(
                  record.level,
                  '$name${record.message}',
                  record.error,
                  record.stackTrace,
                );
              },
            );
            daemonClient.registerBuildTarget(
              DefaultBuildTarget((b) => b..target = project.directoryToServe),
            );
            daemonClient.startBuild();

            await waitForSuccessfulBuild();

            final assetServerPort = daemonPort(
              project.absolutePackageDirectory,
            );
            _assetHandler = _createBuildRunnerDdcLibraryBundleAssetHandler(
              assetServerPort,
            );
            assetReader = ProxyServerAssetReader.fromHandler(_assetHandler!);

            if (testSettings.enableExpressionEvaluation) {
              ddcService = ExpressionCompilerService(
                'localhost',
                _port!,
                verbose: testSettings.verboseCompiler,
                sdkConfigurationProvider: sdkConfigurationProvider,
              );
              expressionCompiler = ddcService;
            }
            frontendServerFileSystem = const LocalFileSystem();
            final packageUriMapper = await PackageUriMapper.create(
              frontendServerFileSystem,
              project.packageConfigFile,
              useDebuggerModuleNames: testSettings.useDebuggerModuleNames,
            );
            loadStrategy = switch ((
              testSettings.moduleFormat,
              buildSettings.canaryFeatures,
            )) {
              (ModuleFormat.ddc, true) =>
                FrontendServerDdcLibraryBundleStrategyProvider(
                  testSettings.reloadConfiguration,
                  assetReader,
                  packageUriMapper,
                  () async => {},
                  buildSettings,
                  injectScriptLoad: false,
                  reloadedSourcesUri: reloadedSourcesUri,
                ).strategy,
              _ => throw Exception(
                'Unsupported DDC module format when compiling with Frontend '
                'Server + build_runner ${testSettings.moduleFormat.name}.',
              ),
            };
            buildResults = const Stream<BuildResults>.empty();
          }
          break;
      }

      final debugPort = await findUnusedPort();
      if (testSettings.launchChrome) {
        // If the environment variable DWDS_DEBUG_CHROME is set to the string
        // true then Chrome will be launched with a UI rather than headless.
        // If the extension is enabled, then Chrome will be launched with a UI
        // since headless Chrome does not support extensions.
        final enableDebugExtension = debugSettings.enableDebugExtension;
        final headless =
            Platform.environment['DWDS_DEBUG_CHROME'] != 'true' &&
            !enableDebugExtension;
        if (enableDebugExtension) {
          await _buildDebugExtension();
        }
        final capabilities = Capabilities.chrome
          ..addAll({
            Capabilities.chromeOptions: {
              'args': [
                // --disable-gpu speeds up the tests that use ChromeDriver when
                // they are run on GitHub Actions.
                '--disable-gpu',
                'remote-debugging-port=$debugPort',
                if (enableDebugExtension)
                  '--load-extension=debug_extension/prod_build',
                if (headless) '--headless',
              ],
            },
          });
        _webDriver = await createDriver(
          spec: WebDriverSpec.JsonWire,
          desired: capabilities,
          uri: Uri.parse(
            'http://127.0.0.1:$chromeDriverPort/$chromeDriverUrlBase/',
          ),
        );
      }

      // The debugger tab must be enabled and connected before certain
      // listeners in DWDS or `main` is run.
      final tabConnectionCompleter = Completer<void>();
      final appConnectionCompleter = Completer<void>();
      final connection = ChromeConnection('localhost', debugPort);

      // TODO(srujzs): In the case of the frontend server, it doesn't make sense
      // that we initialize a new HTTP server instead of reusing the one in
      // `TestAssetServer`. We should instead use that one to align with Flutter
      // tools.
      _testServer = await TestServer.start(
        debugSettings: debugSettings.copyWith(
          expressionCompiler: expressionCompiler,
        ),
        appMetadata: appMetadata,
        port: port,
        assetHandler: assetHandler,
        assetReader: assetReader,
        strategy: loadStrategy,
        target: project.directoryToServe,
        buildResults: buildResults,
        chromeConnection: () async => connection,
        httpServer: httpServer,
      );

      _testServer!.dwds.connectedApps.listen((connection) async {
        // Ensure that we've established a tab connection before running main.
        await tabConnectionCompleter.future;
        if (testSettings.autoRun) {
          connection.runMain();
        }

        // We may reuse the app connection, so only save it the first time
        // it's encountered.
        if (!appConnectionCompleter.isCompleted) {
          appConnection = connection;
          appConnectionCompleter.complete();
        }
      });

      _appUrl = basePath.isEmpty
          ? 'http://localhost:$port/$filePathToServe'
          : 'http://localhost:$port/$basePath/$filePathToServe';

      if (testSettings.launchChrome) {
        await _webDriver?.get(appUrl);
        final tab = await connection.getTab((t) => t.url == appUrl);
        if (tab != null) {
          _tabConnection = await tab.connect();
          await tabConnection.runtime.enable();
          await tabConnection.debugger.enable().then(
            (_) => tabConnectionCompleter.complete(),
          );
        } else {
          throw StateError('Unable to connect to tab.');
        }

        if (debugSettings.enableDebugExtension) {
          final extensionTab = await _fetchDartDebugExtensionTab(connection);
          extensionConnection = await extensionTab.connect();
          await extensionConnection.runtime.enable();
        }

        await appConnectionCompleter.future;
        if (debugSettings.enableDebugging && !testSettings.waitToDebug) {
          await startDebugging();
        }
        _webkitDebugger = WebkitDebugger(WipDebugger(tabConnection));
      } else {
        // No tab needs to be discovered, so fulfill the relevant completer.
        tabConnectionCompleter.complete();
      }
    } catch (e, s) {
      _logger.severe('Failed to setup the service, $e:$s');
      await tearDown();
      rethrow;
    }
  }

  /// Creates a VM service connection connected to the debug URI.
  ///
  /// This can be used to test behavior that should be available to a client
  /// connected to DWDS.
  Future<VmService> connectFakeClient() async {
    final fakeClient = await vmServiceConnectUri(debugConnection.uri);

    fakeClient.onEvent(EventStreams.kService).listen(_handleServiceEvent);
    await fakeClient.streamListen(EventStreams.kService);

    return fakeClient;
  }

  /// Returns the service extension method given the [extensionName].
  ///
  /// The extension be called by a client created with [connectFakeClient].
  String? getRegisteredServiceExtension(String extensionName) {
    if (_serviceNameToMethod.isEmpty) {
      throw StateError('''
        No registered service extensions. Did you call connectFakeClient?
      ''');
    }

    return _serviceNameToMethod[extensionName];
  }

  void _handleServiceEvent(Event e) {
    if (e.kind == EventKind.kServiceRegistered) {
      final serviceName = e.service!;
      _serviceNameToMethod[serviceName] = e.method;
    }
  }

  Future<void> startDebugging() async {
    debugConnection = await testServer.dwds.debugConnection(appConnection);
  }

  Future<void> tearDown() async {
    await _webRunner?.stop();
    await _webDriver?.quit(closeSession: true);
    _chromeDriver?.kill();
    DartUri.currentDirectory = p.current;
    await _daemonClient?.close();
    await ddcService?.stop();
    await _testServer?.stop();
    _client?.close();
    await _outputDir?.delete(recursive: true);
    stopLogWriter();
    await project.tearDown();

    // clear the state for next setup
    _webDriver = null;
    _chromeDriver = null;
    _daemonClient = null;
    ddcService = null;
    _webRunner = null;
    _testServer = null;
    _client = null;
    _outputDir = null;
  }

  /// Given a list of edits, use file IO to write them to the file system.
  ///
  /// If `file` has the same name as the project's entry file name, that file
  /// will be edited. Otherwise, it's assumed to be a library file.
  // TODO(srujzs): It's possible we may want a library file with the same name
  // as the entry file, but this function doesn't allow that. Potentially
  // support that.
  Future<void> makeEdits(List<Edit> edits) async {
    // `dart:io`'s `stat` on Windows does not have millisecond precision so we
    // need to make sure we wait long enough that modifications result in a
    // timestamp that is guaranteed to be after the previous compile.
    // TODO(https://github.com/dart-lang/sdk/issues/51937): Remove once this bug
    // is fixed.
    if (Platform.isWindows) {
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    _reloadedSources.clear();
    for (var (:file, :originalString, :newString) in edits) {
      if (file == project.dartEntryFileName) {
        file = project.dartEntryFilePath;
      } else {
        file = project.dartLibFilePath(file);
      }
      final f = File(file);
      final fileContents = f.readAsStringSync();
      f.writeAsStringSync(fileContents.replaceAll(originalString, newString));

      _updateReloadedSources(file);
    }
  }

  /// Updates the reloaded_sources.json manifest file for a running test.
  ///
  /// This logic essentially replicates the build system's naming conventions
  /// for DDC's generated code. DWDS itself uses the metadata file, but this
  /// isn't available for our test fixtures.
  /// Rules:
  /// - Entrypoints (served): web/main.dart -> main
  /// - Entrypoints (nested): test/hello_world/main.dart -> hello_world/main
  /// - Library files: lib/path/to/some_file.dart
  ///     -> packages/`package`/path/to/some_file
  void _updateReloadedSources(String absolutePath) {
    final relativePath = p.relative(
      absolutePath,
      from: project.absolutePackageDirectory,
    );
    final relativeUrl = p.toUri(relativePath).path;

    String moduleName;
    String libUri;
    String srcPath;

    if (relativeUrl.startsWith('lib/')) {
      final pathInLib = relativeUrl.substring(4);
      moduleName =
          'packages/${project.packageName}/${p.withoutExtension(pathInLib)}';
      libUri = 'package:${project.packageName}/$pathInLib';
      srcPath = moduleName;
    } else if (absolutePath == project.dartEntryFilePath) {
      moduleName = p.withoutExtension(relativeUrl);
      libUri = project.dartEntryFilePackageUri.toString();

      final servePath = '${project.directoryToServe}/';
      if (relativeUrl.startsWith(servePath)) {
        // e.g. web/main.dart -> main
        srcPath = p.withoutExtension(relativeUrl.substring(servePath.length));
      } else {
        // e.g. example/hello_world/main.dart -> example/hello_world/main
        srcPath = moduleName;
      }
    } else {
      throw StateError(
        "Unhandled file path in test context's reloaded_sources.json: "
        " $absolutePath. Only entrypoints and files in 'lib/' are supported.",
      );
    }

    _reloadedSources.add(
      WebDevFS.createReloadedSourceEntry(
        src: '/$srcPath.ddc.js',
        module: moduleName,
        libraries: [libUri],
      ),
    );
  }

  /// Contains contents of the reloaded_sources.json manifest file.
  ///
  /// Used by the DDC Library Bundle module system to record changed files for
  /// hot restart/reload.
  final _reloadedSources = <Map<String, Object>>[];

  void addLibraryFile({required String libFileName, required String contents}) {
    final file = File(project.dartLibFilePath(libFileName));
    // Library folder may not exist yet, so create it.
    file.createSync(recursive: true);
    file.writeAsStringSync(contents);
    _updateReloadedSources(file.path);
  }

  /// Returns a handler for build runner + DDC AMD module system.
  Handler _createBuildRunnerAmdAssetHandler(int assetServerPort) {
    return proxyHandler(
      'http://localhost:$assetServerPort/${project.directoryToServe}/',
      client: client,
    );
  }

  /// Returns a handler for build runner + the DDC Library Bundle module
  /// system.
  ///
  /// This handler:
  /// - serves the reloaded_sources.json file for reloads/restarts.
  /// - serves the application directory and entrypoint from
  ///   `project.directoryToServe`.
  Handler _createBuildRunnerDdcLibraryBundleAssetHandler(int assetServerPort) {
    final entrypointProxy = proxyHandler(
      'http://localhost:$assetServerPort/${project.directoryToServe}/',
      client: client,
    );

    return (request) {
      final path = request.url.path;
      if (path.endsWith(WebDevFS.reloadedSourcesFileName)) {
        return shelf.Response.ok(jsonEncode(_reloadedSources));
      }
      return entrypointProxy(request);
    };
  }

  Future<void> recompile({required bool fullRestart}) async {
    await webRunner.rerun(
      fullRestart: fullRestart,
      fileServerUri: Uri.parse('http://${testServer.host}:${testServer.port}'),
    );
    return;
  }

  Future<void> waitForSuccessfulBuild({
    Duration? timeout,
    bool propagateToBrowser = false,
  }) async {
    // Wait for the build until the timeout is reached:
    await daemonClient.buildResults
        .firstWhere(
          (BuildResults results) => results.results.any(
            (BuildResult result) => result.status == BuildStatus.succeeded,
          ),
        )
        .timeout(timeout ?? const Duration(seconds: 60));

    if (propagateToBrowser) {
      // Allow change to propagate to the browser.
      // Windows, or at least Travis on Windows, seems to need more time.
      // TODO: Wait for an explicit finish signal instead of adding this delay.
      final delay = Platform.isWindows
          ? const Duration(seconds: 5)
          : const Duration(seconds: 2);
      await Future<void>.delayed(delay);
    }
  }

  Future<void> _buildDebugExtension() async {
    final process = await Process.run(
      'tool/build_extension.sh',
      ['prod'],
      workingDirectory: absolutePath(pathFromDwds: 'debug_extension'),
    );
    print(process.stdout);
  }

  Future<ChromeTab> _fetchDartDebugExtensionTab(
    ChromeConnection connection,
  ) async {
    final extensionTabs = (await connection.getTabs()).where((tab) {
      return tab.isChromeExtension;
    });
    for (final tab in extensionTabs) {
      final tabConnection = await tab.connect();
      final response = await tabConnection.runtime.evaluate(
        'window.isDartDebugExtension',
      );
      if (response.value == true) {
        return tab;
      }
    }
    throw StateError('No extension installed.');
  }

  /// Finds the line number in [scriptRef] matching [breakpointId].
  ///
  /// A breakpoint ID is found by looking for a line that ends with a comment
  /// of exactly this form: `// Breakpoint: <id>`.
  ///
  /// Throws if it can't find the matching line.
  Future<int> findBreakpointLine(
    String breakpointId,
    String isolateId,
    ScriptRef scriptRef,
  ) async {
    final script =
        await debugConnection.vmService.getObject(isolateId, scriptRef.id!)
            as Script;
    final lines = LineSplitter.split(script.source!).toList();
    final lineNumber = lines.indexWhere(
      (l) => l.endsWith('// Breakpoint: $breakpointId'),
    );
    if (lineNumber == -1) {
      throw StateError(
        'Unable to find breakpoint in ${scriptRef.uri} with id '
        '$breakpointId',
      );
    }
    return lineNumber + 1;
  }
}

typedef Edit = ({String file, String originalString, String newString});
