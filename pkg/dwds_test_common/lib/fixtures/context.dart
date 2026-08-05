// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate' as isolate show Isolate;

import 'package:dwds/asset_reader.dart';
import 'package:dwds/dart_web_debug_service.dart';
import 'package:dwds/data/build_result.dart';
import 'package:dwds/src/connections/app_connection.dart';
import 'package:dwds/src/connections/debug_connection.dart';
import 'package:dwds/src/debugging/webkit_debugger.dart';
import 'package:dwds/src/loaders/strategy.dart';
import 'package:dwds/src/services/chrome/chrome_proxy_service.dart';
import 'package:dwds/src/services/expression_compiler.dart';
import 'package:dwds/src/utilities/dart_uri.dart';
import 'package:dwds/src/utilities/server.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:logging/logging.dart' as logging;
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';
import 'package:webdriver/async_io.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import '../logging.dart';
import '../test_sdk_configuration.dart';
import '../utilities.dart';
import 'project.dart';
import 'server.dart';
import 'utilities.dart';

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

typedef TestContextFactory =
    TestContext Function(TestProject, TestSdkConfigurationProvider);

abstract class TestContext {
  static const reloadedSourcesFileName = 'reloaded_sources.json';

  final TestProject project;
  final TestSdkConfigurationProvider sdkConfigurationProvider;

  String get appUrl => _appUrl!;
  late String? _appUrl;

  WipConnection get tabConnection => _tabConnection!;
  late WipConnection? _tabConnection;

  TestServer get testServer => _testServer!;
  TestServer? _testServer;

  Dwds? get dwds => _testServer?.dwds;

  WebDriver get webDriver => _webDriver!;
  WebDriver? _webDriver;

  Process get chromeDriver => _chromeDriver!;
  Process? _chromeDriver;

  WebkitDebugger get webkitDebugger => _webkitDebugger!;
  late WebkitDebugger? _webkitDebugger;

  Client get client => _client!;
  Client? _client;

  int get port => _port!;
  late int? _port;

  Directory get outputDir => _outputDir!;
  Directory? _outputDir;

  late WipConnection extensionConnection;
  late AppConnection appConnection;
  late DebugConnection debugConnection;

  final _logger = logging.Logger('Context');

  final _serviceNameToMethod = <String, String?>{};

  /// Internal VM service.
  ///
  /// Prefer using [vmService] instead in tests when possible, to include
  /// testing of the VmServerConnection (bypassed when using [service]).
  ChromeProxyService get service => fetchChromeProxyService(debugConnection);

  /// External VM service.
  VmService get vmService => debugConnection.vmService;

  TestContext.protected(this.project, this.sdkConfigurationProvider);

  bool get usesFrontendServer => false;
  bool get usesBuildDaemon => false;
  bool get usesDdcModulesOnly => false;

  // Abstract members:
  AssetReader get assetReader;
  Handler get assetHandler;
  LoadStrategy get loadStrategy;
  Stream<BuildResult> get buildResults;
  ExpressionCompiler? get expressionCompiler;

  String get appUrlPath;
  String get basePath => '';

  Future<void> modeSetUp(
    TestSettings testSettings,
    TestDebugSettings debugSettings,
    TestAppMetadata appMetadata,
    Uri reloadedSourcesUri,
  );

  Future<void> modeTearDown();

  String get chromeDriverExecutable => _resolveChromeDriverExecutable();
  String get chromeExecutable => _resolveChromeExecutable();

  Future<void> setUp({
    TestSettings testSettings = const TestSettings(),
    TestAppMetadata appMetadata = const TestAppMetadata.externalApp(),
    TestDebugSettings debugSettings =
        const TestDebugSettings.noDevToolsLaunch(),
  }) async {
    try {
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

      final sharedChromeDriverPort =
          Platform.environment['DWDS_CHROMEDRIVER_PORT'];
      final chromeDriverPort = sharedChromeDriverPort != null
          ? int.parse(sharedChromeDriverPort)
          : await findUnusedPort();
      final chromeDriverUrlBase = 'wd/hub';
      if (sharedChromeDriverPort == null) {
        try {
          _chromeDriver = await Process.start(chromeDriverExecutable, [
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
      }

      final packageConfig = File(
        p.join(
          project.absolutePackageDirectory,
          '.dart_tool',
          'package_config.json',
        ),
      );
      if (!packageConfig.existsSync()) {
        await Process.run(sdkLayout.dartPath, [
          'pub',
          'upgrade',
        ], workingDirectory: project.absolutePackageDirectory);
      }

      // Start the HTTP server and save its used port.
      final httpServer = await startHttpServer('localhost');
      _port = httpServer.port;

      final reloadedSourcesUri = Uri.parse(
        'http://localhost:$_port/$reloadedSourcesFileName',
      );

      await modeSetUp(
        testSettings,
        debugSettings,
        appMetadata,
        reloadedSourcesUri,
      );

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
        final capabilities = {...Capabilities.chrome}
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
                // When the DevTools has focus we don't want to slow down the
                // application.
                '--disable-background-timer-throttling',
                '--disable-blink-features=TimerThrottlingForBackgroundTabs',
                '--disable-features=IntensiveWakeUpThrottling',
                // Since we are using a temp profile, disable features that slow
                // the Chrome launch.
                '--disable-extensions',
                '--disable-popup-blocking',
                '--bwsi',
                '--no-first-run',
                '--no-default-browser-check',
                '--disable-default-apps',
                '--disable-translate',
                '--start-maximized',
                // When running on MacOS, Chrome may open system dialogs
                // requesting credentials. This uses a mock keychain to avoid
                // that dialog from blocking.
                '--use-mock-keychain',
                // Prevent warnings for using flags that are not recommended for
                // general browsing but are applicable for use in dev-focused
                // workflows.
                '--test-type',
                // Dev runs of the browser should be considered independent of
                // one another, don't announce when the previous session
                // crashed.
                '--disable-session-crashed-bubble',
                '--no-sandbox',
              ],
              'binary': chromeExecutable,
            },
          });
        _webDriver = await _createDriverWithRetry(
          capabilities: capabilities,
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

      _testServer = await TestServer.start(
        debugSettings: debugSettings.copyWith(
          expressionCompiler: expressionCompiler,
        ),
        appMetadata: appMetadata,
        port: port,
        assetHandler: assetHandler,
        assetReader: assetReader,
        strategy: loadStrategy,
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
          ? 'http://localhost:$port/$appUrlPath'
          : 'http://localhost:$port/$basePath/$appUrlPath';

      if (testSettings.launchChrome) {
        await _webDriver?.get(appUrl).timeout(const Duration(seconds: 30));
        _tabConnection = await _getTabConnection(
          connection,
          appUrl,
        ).timeout(const Duration(seconds: 30));
        tabConnectionCompleter.complete();

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
    await modeTearDown();
    await _webDriver?.quit(closeSession: true);
    _chromeDriver?.kill();
    DartUri.currentDirectory = p.current;
    await _testServer?.stop();
    _client?.close();
    await _outputDir?.delete(recursive: true);
    stopLogWriter();
    await project.tearDown();

    // clear the state for next setup
    _webDriver = null;
    _chromeDriver = null;
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

    _reloadedSources.add({
      'src': '/$srcPath.ddc.js',
      'module': moduleName,
      'libraries': [libUri],
    });
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

  /// Wraps a handler to serve the reloaded_sources.json file for
  /// reloads/restarts in the DDC Library Bundle module system.
  Handler handleReloadedSources(Handler proxy) {
    return (request) {
      final path = request.url.path;
      if (path.endsWith(reloadedSourcesFileName)) {
        return shelf.Response.ok(jsonEncode(_reloadedSources));
      }
      return proxy(request);
    };
  }

  Future<void> recompile({required bool fullRestart}) => throw UnsupportedError(
    'recompile is only supported in Frontend Server mode',
  );

  Future<void> waitForSuccessfulBuild({
    Duration? timeout,
    bool propagateToBrowser = false,
  }) => throw UnsupportedError(
    'waitForSuccessfulBuild is only supported in Build Daemon mode',
  );

  Future<void> _buildDebugExtension() async {
    final process = await Process.run('tool/build_extension.sh', [
      'prod',
    ], workingDirectory: absolutePath(pathFromDwds: 'debug_extension'));
    print(process.stdout);
  }

  Future<WipConnection> _getTabConnection(
    ChromeConnection connection,
    String appUrl,
  ) async {
    final tab = await connection.getTab(
      (t) => t.url == appUrl,
      retryFor: const Duration(seconds: 5),
    );
    if (tab == null) {
      throw StateError(
        'Unable to connect to tab after retrying for 5 seconds.',
      );
    }
    final tabConnection = await tab.connect().timeout(
      const Duration(seconds: 30),
    );
    await tabConnection.runtime.enable();
    await tabConnection.debugger.enable();
    return tabConnection;
  }

  Future<ChromeTab> _fetchDartDebugExtensionTab(
    ChromeConnection connection,
  ) async {
    const retries = 5;
    for (var i = 0; i < retries; i++) {
      if (i > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
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

Future<WebDriver> _createDriverWithRetry({
  required Map<String, dynamic> capabilities,
  required Uri uri,
  int maxAttempts = 3,
  Duration timeout = const Duration(seconds: 30),
}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await createDriver(
        spec: WebDriverSpec.JsonWire,
        desired: capabilities,
        uri: uri,
      ).timeout(timeout);
    } catch (e) {
      if (attempt == maxAttempts) rethrow;
      await Future<void>.delayed(Duration(seconds: attempt));
    }
  }
  throw StateError('Unreachable');
}

final _sdkRoot = isolate.Isolate.resolvePackageUriSync(
  Uri.parse('package:dwds_test_common/fixtures/context.dart'),
)!.resolve('../../../../');

final _chromeDriverName = Platform.isWindows
    ? 'chromedriver.exe'
    : 'chromedriver';

final _chromeExecutableName = Platform.isWindows
    ? 'Application\\chrome.exe'
    : 'google-chrome';

String _resolveExecutable({
  required List<String> environmentKeys,
  required String sdkRelativePath,
  required String fallbackName,
}) {
  for (final env in environmentKeys) {
    if (Platform.environment.containsKey(env)) {
      return Platform.environment[env]!;
    }
  }
  final sdkPath = _sdkRoot.resolve(sdkRelativePath).toFilePath();
  if (File(sdkPath).existsSync()) {
    return sdkPath;
  }
  return fallbackName;
}

String _resolveChromeDriverExecutable() => _resolveExecutable(
  environmentKeys: const ['CHROMEDRIVER_PATH'],
  sdkRelativePath: 'third_party/webdriver/chrome/$_chromeDriverName',
  fallbackName: _chromeDriverName,
);

String _resolveChromeExecutable() => _resolveExecutable(
  environmentKeys: const ['CHROME_EXECUTABLE', 'CHROME_PATH'],
  sdkRelativePath: 'third_party/browsers/chrome/chrome/$_chromeExecutableName',
  fallbackName: _chromeExecutableName,
);
