// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart' show ResourceProvider;
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart' as mock_sdk;
import 'package:args/args.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/migration_cli.dart';
import 'package:nnbd_migration/src/front_end/dartfix_listener.dart';
import 'package:nnbd_migration/src/front_end/instrumentation_listener.dart';
import 'package:nnbd_migration/src/front_end/migration_summary.dart';
import 'package:nnbd_migration/src/front_end/non_nullable_fix.dart';
import 'package:nnbd_migration/src/front_end/web/edit_details.dart';
import 'package:nnbd_migration/src/front_end/web/file_details.dart';
import 'package:nnbd_migration/src/front_end/web/navigation_tree.dart';
import 'package:nnbd_migration/src/messages.dart' as messages;
import 'package:nnbd_migration/src/preview/preview_site.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'utilities/test_logger.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(_MigrationCliTestPosix);
    defineReflectiveTests(_MigrationCliTestWindows);
  });
}

/// Specialization of [InstrumentationListener] that generates artificial
/// exceptions, so that we can test they are properly propagated to top level.
class _ExceptionGeneratingInstrumentationListener
    extends InstrumentationListener {
  _ExceptionGeneratingInstrumentationListener(
      {MigrationSummary migrationSummary})
      : super(migrationSummary: migrationSummary);

  @override
  void externalDecoratedType(Element element, DecoratedTypeInfo decoratedType) {
    if (element.name == 'print') {
      throw StateError('Artificial exception triggered');
    }
    super.externalDecoratedType(element, decoratedType);
  }
}

/// Specialization of [NonNullableFix] that generates artificial exceptions, so
/// that we can test they are properly propagated to top level.
class _ExceptionGeneratingNonNullableFix extends NonNullableFix {
  _ExceptionGeneratingNonNullableFix(
      DartFixListener listener,
      ResourceProvider resourceProvider,
      LineInfo Function(String) getLineInfo,
      Object bindAddress,
      Logger logger,
      {List<String> included = const <String>[],
      int preferredPort,
      String summaryPath,
      @required String sdkPath})
      : super(listener, resourceProvider, getLineInfo, bindAddress, logger,
            included: included,
            preferredPort: preferredPort,
            summaryPath: summaryPath,
            sdkPath: sdkPath);

  @override
  InstrumentationListener createInstrumentationListener(
          {MigrationSummary migrationSummary}) =>
      _ExceptionGeneratingInstrumentationListener(
          migrationSummary: migrationSummary);
}

class _MigrationCli extends MigrationCli {
  final _MigrationCliTestBase _test;

  /// If non-null, callback function that will be invoked by the `applyHook`
  /// override.
  void Function() _onApplyHook;

  _MigrationCli(this._test)
      : super(
            binaryName: 'nnbd_migration',
            loggerFactory: (isVerbose) => _test.logger = TestLogger(isVerbose),
            defaultSdkPathOverride:
                _test.resourceProvider.convertPath(mock_sdk.sdkRoot),
            resourceProvider: _test.resourceProvider,
            environmentVariables: _test.environmentVariables);

  _MigrationCliRunner decodeCommandLineArgs(ArgResults argResults,
      {bool isVerbose}) {
    var runner = super.decodeCommandLineArgs(argResults, isVerbose: isVerbose);
    if (runner == null) return null;
    return _MigrationCliRunner(this, runner.options);
  }
}

class _MigrationCliRunner extends MigrationCliRunner {
  Future<void> Function() _runWhilePreviewServerActive;

  _MigrationCliRunner(_MigrationCli cli, CommandLineOptions options)
      : super(cli, options);

  _MigrationCli get cli => super.cli as _MigrationCli;

  @override
  void applyHook() {
    super.applyHook();
    cli._onApplyHook?.call();
  }

  @override
  Future<void> blockUntilSignalInterrupt() async {
    if (_runWhilePreviewServerActive == null) {
      fail('Preview server not expected to have been started');
    }
    await _runWhilePreviewServerActive.call();
    _runWhilePreviewServerActive = null;
  }

  @override
  Object computeBindAddress() {
    var address = super.computeBindAddress();
    if (Platform.environment.containsKey('FORCE_IPV6') &&
        address == InternetAddress.loopbackIPv4) {
      return InternetAddress.loopbackIPv6;
    }
    return address;
  }

  @override
  Set<String> computePathsToProcess(DriverBasedAnalysisContext context) =>
      cli._test.overridePathsToProcess ??
      _sortPaths(super.computePathsToProcess(context));

  @override
  NonNullableFix createNonNullableFix(
      DartFixListener listener,
      ResourceProvider resourceProvider,
      LineInfo Function(String path) getLineInfo,
      Object bindAddress,
      {List<String> included = const <String>[],
      int preferredPort,
      String summaryPath,
      @required String sdkPath}) {
    if (cli._test.injectArtificialException) {
      return _ExceptionGeneratingNonNullableFix(
          listener, resourceProvider, getLineInfo, bindAddress, logger,
          included: included,
          preferredPort: preferredPort,
          summaryPath: summaryPath,
          sdkPath: sdkPath);
    } else {
      return super.createNonNullableFix(
          listener, resourceProvider, getLineInfo, bindAddress,
          included: included,
          preferredPort: preferredPort,
          summaryPath: summaryPath,
          sdkPath: sdkPath);
    }
  }

  Future<void> runWithPreviewServer(Future<void> Function() callback) async {
    _runWhilePreviewServerActive = callback;
    await run();
    if (_runWhilePreviewServerActive != null) {
      fail('Preview server never started');
    }
  }

  @override
  bool shouldBeMigrated(DriverBasedAnalysisContext context, String path) =>
      cli._test.overrideShouldBeMigrated?.call(path) ??
      super.shouldBeMigrated(context, path);

  /// Sorts the paths in [paths] for repeatability of migration tests.
  Set<String> _sortPaths(Set<String> paths) {
    var pathList = paths.toList();
    pathList.sort();
    return pathList.toSet();
  }
}

abstract class _MigrationCliTestBase {
  Map<String, String> environmentVariables = {};

  /// If `true`, then an artificial exception should be generated when migration
  /// encounters a reference to the `print` function.
  bool injectArtificialException = false;

  /// If non-null, this is injected as the return value for
  /// [_MigrationCliRunner.computePathsToProcess].
  Set<String> overridePathsToProcess;

  bool Function(String) overrideShouldBeMigrated;

  set logger(TestLogger logger);

  MemoryResourceProvider get resourceProvider;
}

mixin _MigrationCliTestMethods on _MigrationCliTestBase {
  @override
  /*late*/ TestLogger logger;

  final hasVerboseHelpMessage = contains('for verbose help output');

  final hasUsageText = contains('Usage: nnbd_migration');

  final urlStartRegexp = RegExp('https?:');

  final dartVersionIsNullSafeByDefault =
      Feature.non_nullable.releaseVersion != null;

  String assertDecodeArgsFailure(List<String> args) {
    var cli = _createCli();
    try {
      cli.decodeCommandLineArgs(MigrationCli.createParser().parse(args));
      fail('Migration succeeded; expected it to abort with an error');
    } on MigrationExit catch (migrationExit) {
      expect(migrationExit.exitCode, isNotNull);
      expect(migrationExit.exitCode, isNot(0));
    }
    var stderrText = logger.stderrBuffer.toString();
    expect(stderrText, hasUsageText);
    expect(stderrText, hasVerboseHelpMessage);
    return stderrText;
  }

  Future<String> assertErrorExit(
      MigrationCliRunner cliRunner, FutureOr<void> Function() callback,
      {@required bool withUsage, dynamic expectedExitCode}) async {
    expectedExitCode ??= isNot(0);
    try {
      await callback();
      fail('Migration succeeded; expected it to abort with an error');
    } on MigrationExit catch (migrationExit) {
      expect(migrationExit.exitCode, isNotNull);
      expect(migrationExit.exitCode, expectedExitCode);
    }
    expect(cliRunner.isPreviewServerRunning, isFalse);
    return assertStderr(withUsage: withUsage);
  }

  void assertHttpSuccess(http.Response response) {
    if (response.statusCode == 500) {
      try {
        var decodedResponse = jsonDecode(response.body);
        print('Exception: ${decodedResponse['exception']}');
        print('Stack trace:');
        print(decodedResponse['stackTrace']);
      } catch (_) {
        print(response.body);
      }
      fail('HTTP request failed');
    }
    expect(response.statusCode, 200);
  }

  void assertNormalExit(MigrationCliRunner cliRunner) {
    expect(cliRunner.isPreviewServerRunning, isFalse);
  }

  Future<String> assertParseArgsFailure(List<String> args) async {
    try {
      MigrationCli.createParser().parse(args);
    } on FormatException catch (e) {
      // Parsing failed, which was expected.
      return e.message;
    }
    fail('Parsing was expected to fail, but did not');
  }

  CommandLineOptions assertParseArgsSuccess(List<String> args) {
    var cliRunner = _createCli()
        .decodeCommandLineArgs(MigrationCli.createParser().parse(args));
    assertNormalExit(cliRunner);
    var options = cliRunner.options;
    expect(options, isNotNull);
    return options;
  }

  Future assertPreviewServerResponsive(String url) async {
    var response = await httpGet(url);
    assertHttpSuccess(response);
  }

  void assertProjectContents(String projectDir, Map<String, String> expected) {
    for (var entry in expected.entries) {
      var relativePathPosix = entry.key;
      assert(!path.posix.isAbsolute(relativePathPosix));
      var filePath = resourceProvider.pathContext
          .join(projectDir, resourceProvider.convertPath(relativePathPosix));
      expect(
          resourceProvider.getFile(filePath).readAsStringSync(), entry.value);
    }
  }

  Future<String> assertRunFailure(List<String> args,
      {MigrationCli cli,
      bool withUsage = false,
      dynamic expectedExitCode}) async {
    expectedExitCode ??= isNot(0);
    cli ??= _createCli();
    MigrationCliRunner cliRunner;
    try {
      cliRunner =
          cli.decodeCommandLineArgs(MigrationCli.createParser().parse(args));
    } on MigrationExit catch (e) {
      expect(e.exitCode, isNotNull);
      expect(e.exitCode, expectedExitCode);
      return assertStderr(withUsage: withUsage);
    }
    return await assertErrorExit(cliRunner, () => cliRunner.run(),
        withUsage: withUsage, expectedExitCode: expectedExitCode);
  }

  String assertStderr({@required bool withUsage}) {
    var stderrText = logger.stderrBuffer.toString();
    expect(stderrText, withUsage ? hasUsageText : isNot(hasUsageText));
    expect(stderrText,
        withUsage ? hasVerboseHelpMessage : isNot(hasVerboseHelpMessage));
    return stderrText;
  }

  /// Wraps a future containing an HTTP response so that when that response is
  /// received, we will verify that it is reasonable.
  Future<http.Response> checkHttpResponse(
      Future<http.Response> futureResponse) async {
    var response = await futureResponse;
    // Check that all "http:" and "https:" URLs in the given HTTP response are
    // absolute (guards against https://github.com/dart-lang/sdk/issues/43545).
    for (var match in urlStartRegexp.allMatches(response.body)) {
      expect(response.body.substring(match.end), startsWith('//'));
    }
    return response;
  }

  String createProjectDir(Map<String, String> contents,
      {String posixPath = '/test_project'}) {
    for (var entry in contents.entries) {
      var relativePathPosix = entry.key;
      assert(!path.posix.isAbsolute(relativePathPosix));
      var filePathPosix = path.posix.join(posixPath, relativePathPosix);
      resourceProvider.newFile(
          resourceProvider.convertPath(filePathPosix), entry.value);
    }
    return resourceProvider.convertPath(posixPath);
  }

  Future<String> getSourceFromServer(Uri uri, String path) async {
    http.Response response = await tryGetSourceFromServer(uri, path);
    assertHttpSuccess(response);
    return jsonDecode(response.body)['sourceCode'] as String;
  }

  /// Performs an HTTP get, verifying that the response received (if any) is
  /// reasonable.
  Future<http.Response> httpGet(dynamic url, {Map<String, String> headers}) {
    return checkHttpResponse(http.get(url, headers: headers));
  }

  /// Performs an HTTP post, verifying that the response received (if any) is
  /// reasonable.
  Future<http.Response> httpPost(dynamic url,
      {Map<String, String> headers, dynamic body, Encoding encoding}) {
    return checkHttpResponse(
        http.post(url, headers: headers, body: body, encoding: encoding));
  }

  String packagePath(String path) =>
      resourceProvider.convertPath('/.pub-cache/$path');

  Future<void> runWithPreviewServer(_MigrationCli cli, List<String> args,
      Future<void> Function(String) callback) async {
    String url;
    var cliRunner = cli.decodeCommandLineArgs(_parseArgs(args));
    if (cliRunner != null) {
      await cliRunner.runWithPreviewServer(() async {
        // Server should be running now
        url = RegExp('http://.*', multiLine: true)
            .stringMatch(logger.stdoutBuffer.toString());
        await callback(url);
      });
      // Server should be stopped now
      expect(httpGet(url), throwsA(anything));
      assertNormalExit(cliRunner);
    }
  }

  void setUp() {
    resourceProvider.newFolder(resourceProvider.pathContext.current);
    environmentVariables.clear();
  }

  Map<String, String> simpleProject(
      {bool migrated = false,
      String sourceText,
      String pubspecText,
      String packageConfigText,
      String analysisOptionsText}) {
    return {
      'pubspec.yaml': pubspecText ??
          '''
name: test
environment:
  sdk: '${migrated ? '>=2.12.0 <3.0.0' : '>=2.6.0 <3.0.0'}'
''',
      '.dart_tool/package_config.json':
          packageConfigText ?? _getPackageConfigText(migrated: migrated),
      'lib/test.dart': sourceText ??
          '''
int${migrated ? '?' : ''} f() => null;
''',
      if (analysisOptionsText != null)
        'analysis_options.yaml': analysisOptionsText,
    };
  }

  void tearDown() {
    NonNullableFix.shutdownAllServers();
  }

  test_default_logger() {
    // When running normally, we don't override the logger; make sure it has a
    // non-null default so that there won't be a crash.
    expect(MigrationCli(binaryName: 'nnbd_migration').logger, isNotNull);
  }

  test_detect_old_sdk() async {
    var cli = _createCli();
    // Alter the mock SDK, changing the signature of Object.operator== to match
    // the signature that was present prior to NNBD.  (This is what the
    // migration tool uses to detect an old SDK).
    var coreLib = resourceProvider.getFile(
        resourceProvider.convertPath('${mock_sdk.sdkRoot}/lib/core/core.dart'));
    var oldCoreLibText = coreLib.readAsStringSync();
    var newCoreLibText = oldCoreLibText.replaceAll(
        'external bool operator ==(Object other)',
        'external bool operator ==(dynamic other)');
    expect(newCoreLibText, isNot(oldCoreLibText));
    coreLib.writeAsStringSync(newCoreLibText);
    var projectDir = createProjectDir(simpleProject());
    await assertRunFailure([projectDir], cli: cli);
    var output = logger.stdoutBuffer.toString();
    expect(output, contains(messages.sdkNnbdOff));
  }

  test_detect_old_sdk_environment_variable() async {
    environmentVariables['SDK_PATH'] = '/fake-old-sdk-path';
    var cli = _createCli(); // Creates the mock SDK as a side effect
    // Alter the mock SDK, changing the signature of Object.operator== to match
    // the signature that was present prior to NNBD.  (This is what the
    // migration tool uses to detect an old SDK).
    var coreLib = resourceProvider.getFile(
        resourceProvider.convertPath('${mock_sdk.sdkRoot}/lib/core/core.dart'));
    var oldCoreLibText = coreLib.readAsStringSync();
    var newCoreLibText = oldCoreLibText.replaceAll(
        'external bool operator ==(Object other)',
        'external bool operator ==(dynamic other)');
    expect(newCoreLibText, isNot(oldCoreLibText));
    coreLib.writeAsStringSync(newCoreLibText);
    var projectDir = createProjectDir(simpleProject());
    await assertRunFailure([projectDir], cli: cli);
    var output = logger.stdoutBuffer.toString();
    expect(output, contains(messages.sdkNnbdOff));
    expect(output, contains(messages.sdkPathEnvironmentVariableSet));
    expect(output, contains(environmentVariables['SDK_PATH']));
  }

  test_flag_apply_changes_default() {
    expect(assertParseArgsSuccess([]).applyChanges, isFalse);
    expect(assertParseArgsSuccess([]).webPreview, isTrue);
  }

  test_flag_apply_changes_disable() async {
    // "--no-apply-changes" is not an option.
    await assertParseArgsFailure(['--no-apply-changes']);
  }

  test_flag_apply_changes_enable() {
    var options = assertParseArgsSuccess(['--apply-changes']);
    expect(options.applyChanges, isTrue);
    expect(options.webPreview, isFalse);
  }

  test_flag_apply_changes_enable_with_no_web_preview() {
    expect(
        assertParseArgsSuccess(['--no-web-preview', '--apply-changes'])
            .applyChanges,
        isTrue);
  }

  test_flag_apply_changes_incompatible_with_web_preview() {
    expect(assertDecodeArgsFailure(['--web-preview', '--apply-changes']),
        contains('--apply-changes requires --no-web-preview'));
  }

  test_flag_help() {
    var helpText = _getHelpText(verbose: false);
    expect(helpText, hasUsageText);
    expect(helpText, hasVerboseHelpMessage);
  }

  test_flag_help_verbose() {
    var helpText = _getHelpText(verbose: true);
    expect(helpText, hasUsageText);
    expect(helpText, isNot(hasVerboseHelpMessage));
  }

  test_flag_ignore_errors_default() {
    expect(assertParseArgsSuccess([]).ignoreErrors, isFalse);
  }

  test_flag_ignore_errors_disable() async {
    await assertParseArgsFailure(['--no-ignore-errors']);
  }

  test_flag_ignore_errors_enable() {
    expect(assertParseArgsSuccess(['--ignore-errors']).ignoreErrors, isTrue);
  }

  test_flag_ignore_exceptions_default() {
    expect(assertParseArgsSuccess([]).ignoreExceptions, isFalse);
  }

  test_flag_ignore_exceptions_disable() async {
    await assertParseArgsFailure(['--no-ignore-exceptions']);
  }

  test_flag_ignore_exceptions_enable() {
    expect(assertParseArgsSuccess(['--ignore-exceptions']).ignoreExceptions,
        isTrue);
  }

  test_flag_ignore_exceptions_hidden() {
    var flagName = '--ignore-exceptions';
    expect(_getHelpText(verbose: false), isNot(contains(flagName)));
    expect(_getHelpText(verbose: true), contains(flagName));
  }

  test_flag_skip_import_check_default() {
    expect(assertParseArgsSuccess([]).skipImportCheck, isFalse);
  }

  test_flag_skip_import_check_disable() async {
    // "--no-skip-import-check" is not an option.
    await assertParseArgsFailure(['--no-skip-import_check']);
  }

  test_flag_skip_import_check_enable() {
    expect(assertParseArgsSuccess(['--skip-import-check']).skipImportCheck,
        isTrue);
  }

  test_flag_web_preview_default() {
    expect(assertParseArgsSuccess([]).webPreview, isTrue);
  }

  test_flag_web_preview_disable() {
    expect(assertParseArgsSuccess(['--no-web-preview']).webPreview, isFalse);
  }

  test_flag_web_preview_enable() {
    expect(assertParseArgsSuccess(['--web-preview']).webPreview, isTrue);
  }

  test_lifecycle_already_migrated_file() async {
    Map<String, String> createProject({bool migrated = false}) {
      var projectContents = simpleProject(sourceText: '''
${migrated ? '' : '// @dart = 2.6'}
import 'already_migrated.dart';
int${migrated ? '?' : ''} x = y;
''', migrated: true);
      projectContents['lib/already_migrated.dart'] = '''
int? y = 0;
''';
      return projectContents;
    }

    var projectContents = createProject();
    var projectDir = createProjectDir(projectContents);
    var cliRunner = _createCli(nullSafePackages: ['test'])
        .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
    await cliRunner.run();
    assertNormalExit(cliRunner);
    // Check that a summary was printed
    expect(logger.stdoutBuffer.toString(), contains('Applying changes'));
    // And that it refers to test.dart, but not pubspec.yaml or
    // already_migrated.dart.
    expect(logger.stdoutBuffer.toString(), contains('test.dart'));
    expect(logger.stdoutBuffer.toString(), isNot(contains('pubspec.yaml')));
    expect(logger.stdoutBuffer.toString(),
        isNot(contains('already_migrated.dart')));
    // And that it does not tell the user they can rerun with `--apply-changes`
    expect(logger.stdoutBuffer.toString(), isNot(contains('--apply-changes')));
    // Check that the non-migrated library was changed but not the migrated one
    assertProjectContents(projectDir, createProject(migrated: true));
  }

  test_lifecycle_apply_changes() async {
    var projectContents = simpleProject();
    var projectDir = createProjectDir(projectContents);
    var cli = _createCli();
    var cliRunner =
        cli.decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
    bool applyHookCalled = false;
    cli._onApplyHook = () {
      expect(applyHookCalled, false);
      applyHookCalled = true;
      // Changes should have been made
      assertProjectContents(projectDir, simpleProject(migrated: true));
    };
    await cliRunner.run();
    assertNormalExit(cliRunner);
    expect(applyHookCalled, true);
    // Check that a summary was printed
    expect(logger.stdoutBuffer.toString(), contains('Applying changes'));
    // And that it refers to test.dart and pubspec.yaml
    expect(logger.stdoutBuffer.toString(), contains('test.dart'));
    expect(logger.stdoutBuffer.toString(), contains('pubspec.yaml'));
    // And that it does not tell the user they can rerun with `--apply-changes`
    expect(logger.stdoutBuffer.toString(), isNot(contains('--apply-changes')));
  }

  test_lifecycle_contextdiscovery_handles_multiple() async {
    var projectContents = simpleProject();
    var subProject = simpleProject();
    for (var filePath in subProject.keys) {
      projectContents['example/$filePath'] = subProject[filePath];
    }
    projectContents['example/analysis_options.yaml'] = '''
analyzer:
  strong-mode:
    implicit-casts: false
linter:
  rules:
    - empty_constructor_bodies
''';

    var projectDir = createProjectDir(projectContents);
    var cliRunner = _createCli()
        .decodeCommandLineArgs(_parseArgs(['--no-web-preview', projectDir]));
    await cliRunner.run();
    assertNormalExit(cliRunner);
    expect(cliRunner.hasMultipleAnalysisContext, true);
    expect(cliRunner.analysisContext, isNotNull);
    var output = logger.stdoutBuffer.toString();
    expect(output, contains('more than one project found'));
  }

  test_lifecycle_contextdiscovery_handles_single() async {
    var projectContents = simpleProject();
    var projectDir = createProjectDir(projectContents);
    var cliRunner = _createCli()
        .decodeCommandLineArgs(_parseArgs(['--no-web-preview', projectDir]));
    await cliRunner.run();
    assertNormalExit(cliRunner);
    expect(cliRunner.hasMultipleAnalysisContext, false);
    expect(cliRunner.analysisContext, isNotNull);
  }

  test_lifecycle_exception_handling() async {
    var projectContents = simpleProject(sourceText: 'main() { print(0); }');
    var projectDir = createProjectDir(projectContents);
    injectArtificialException = true;
    await assertRunFailure([projectDir]);
    var errorOutput = logger.stderrBuffer.toString();
    expect(errorOutput, contains('Artificial exception triggered'));
    expect(
        errorOutput, isNot(contains('try to fix errors in the source code')));
    expect(errorOutput, contains('re-run with\n--ignore-exceptions'));
    expect(errorOutput, contains('consider filing a bug report'));
    expect(
        errorOutput,
        contains(
            RegExp(r'Please include the SDK version \([0-9]+\.[0-9]+\..*\)')));
  }

  test_lifecycle_exception_handling_ignore() async {
    var projectContents = simpleProject(sourceText: '''
main() {
  print(0);
  int x = null;
}
''');
    var projectDir = createProjectDir(projectContents);
    injectArtificialException = true;
    var cli = _createCli();
    await runWithPreviewServer(cli, ['--ignore-exceptions', projectDir],
        (url) async {
      var output = logger.stdoutBuffer.toString();
      expect(output, contains('No analysis issues found'));
      expect(output, isNot(contains('Artificial exception triggered')));
      expect(
          output,
          contains('Attempting to perform\nmigration anyway due to the use'
              ' of --ignore-exceptions.'));
      expect(output, contains('re-run without --ignore-exceptions'));
      await assertPreviewServerResponsive(url);
      await _tellPreviewToApplyChanges(url);
      assertProjectContents(
          projectDir, simpleProject(migrated: true, sourceText: '''
main() {
  print(0);
  int? x = null;
}
'''));
    });
    expect(logger.stderrBuffer.toString(), isEmpty);
  }

  test_lifecycle_exception_handling_multiple() async {
    var projectContents =
        simpleProject(sourceText: 'main() { print(0); print(1); }');
    var projectDir = createProjectDir(projectContents);
    injectArtificialException = true;
    await assertRunFailure([projectDir]);
    var errorOutput = logger.stderrBuffer.toString();
    expect(
        'Artificial exception triggered'.allMatches(errorOutput), hasLength(1));
    expect(
        errorOutput, isNot(contains('try to fix errors in the source code')));
    expect(errorOutput, contains('re-run with\n--ignore-exceptions'));
  }

  test_lifecycle_exception_handling_with_error() async {
    var projectContents =
        simpleProject(sourceText: 'main() { print(0); unresolved; }');
    var projectDir = createProjectDir(projectContents);
    injectArtificialException = true;
    await assertRunFailure(['--ignore-errors', projectDir]);
    var errorOutput = logger.stderrBuffer.toString();
    expect(errorOutput, contains('Artificial exception triggered'));
    expect(errorOutput, contains('try to fix errors in the source code'));
    expect(errorOutput, contains('re-run with\n--ignore-exceptions'));
  }

  test_lifecycle_ignore_errors_disable() async {
    var projectContents = simpleProject(sourceText: '''
int f() => null
''');
    var projectDir = createProjectDir(projectContents);
    await assertRunFailure([projectDir]);
    var output = logger.stdoutBuffer.toString();
    expect(output, contains('1 analysis issue found'));
    var sep = resourceProvider.pathContext.separator;
    expect(
        output,
        contains("error • Expected to find ';' at lib${sep}test.dart:1:12 • "
            '(expected_token)'));
    expect(output, contains('erroneous migration suggestions'));
    expect(output, contains('We recommend fixing the analysis issues'));
    expect(output, isNot(contains('Set the lower SDK constraint')));
  }

  test_lifecycle_ignore_errors_enable() async {
    var projectContents = simpleProject(sourceText: '''
int? f() => null
''');
    var projectDir = createProjectDir(projectContents);
    var cli = _createCli();
    await runWithPreviewServer(cli, ['--ignore-errors', projectDir],
        (url) async {
      var output = logger.stdoutBuffer.toString();
      expect(output, isNot(contains('No analysis issues found')));
      expect(
          output,
          contains('Continuing with migration suggestions due to the use of '
              '--ignore-errors.'));
      await assertPreviewServerResponsive(url);
    });
  }

  test_lifecycle_import_check_via_export() async {
    // If the user's code exports a library that imports a non-migrated library,
    // that's a problem too.
    var projectContents = simpleProject(
        sourceText: "export 'package:foo/foo.dart';",
        packageConfigText: _getPackageConfigText(
            migrated: false, packagesMigrated: {'foo': true, 'bar': false}));
    var projectDir = createProjectDir(projectContents);
    resourceProvider.newFile(
        packagePath('foo/lib/foo.dart'), "import 'package:bar/bar.dart';");
    resourceProvider.newFile(packagePath('bar/lib/bar.dart'), '');
    await assertRunFailure([projectDir], expectedExitCode: 1);
    var output = logger.stdoutBuffer.toString();
    expect(output, contains('Error: package has unmigrated dependencies'));
    // Output should mention bar.dart, since it's unmigrated
    expect(output, contains('package:bar/bar.dart'));
    // But it should not mention foo.dart, which is migrated
    expect(output, isNot(contains('package:foo/foo.dart')));
  }

  test_lifecycle_import_check_via_indirect_export() async {
    // If the user's code imports a library that exports a library that imports
    // a non-migrated library, that's a problem too.
    var projectContents = simpleProject(
        sourceText: "import 'package:foo/foo.dart';",
        packageConfigText: _getPackageConfigText(
            migrated: false,
            packagesMigrated: {'foo': true, 'bar': true, 'baz': false}));
    var projectDir = createProjectDir(projectContents);
    resourceProvider.newFile(
        packagePath('foo/lib/foo.dart'), "export 'package:bar/bar.dart';");
    resourceProvider.newFile(
        packagePath('bar/lib/bar.dart'), "import 'package:baz/baz.dart';");
    resourceProvider.newFile(packagePath('baz/lib/baz.dart'), '');
    await assertRunFailure([projectDir], expectedExitCode: 1);
    var output = logger.stdoutBuffer.toString();
    expect(output, contains('Error: package has unmigrated dependencies'));
    // Output should mention baz.dart, since it's unmigrated
    expect(output, contains('package:baz/baz.dart'));
    // But it should not mention foo.dart or bar.dart, which are migrated
    expect(output, isNot(contains('package:foo/foo.dart')));
    expect(output, isNot(contains('package:bar/bar.dart')));
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44118')
  test_lifecycle_issue_44118() async {
    var projectContents = simpleProject(sourceText: '''
int f() => null
''');
    projectContents['lib/foo.dart'] = '''
import 'test.dart';
''';
    var projectDir = createProjectDir(projectContents);
    await assertRunFailure([projectDir]);
    var output = logger.stdoutBuffer.toString();
    expect(output, contains('1 analysis issue found'));
    var sep = resourceProvider.pathContext.separator;
    expect(
        output,
        contains("error • Expected to find ';' at lib${sep}test.dart:1:12 • "
            '(expected_token)'));
    expect(
        output,
        contains(
            'analysis errors will result in erroneous migration suggestions'));
    expect(output, contains('Please fix the analysis issues'));
  }

  test_lifecycle_migration_already_performed() async {
    var projectContents = simpleProject(migrated: true);
    var projectDir = createProjectDir(projectContents);
    await assertRunFailure([projectDir], expectedExitCode: 0);
    var output = logger.stdoutBuffer.toString();
    expect(output,
        contains('All sources appear to be already migrated.  Nothing to do.'));
  }

  test_lifecycle_no_preview() async {
    var projectContents = simpleProject();
    var projectDir = createProjectDir(projectContents);
    var cliRunner = _createCli()
        .decodeCommandLineArgs(_parseArgs(['--no-web-preview', projectDir]));
    await cliRunner.run();
    assertNormalExit(cliRunner);
    // Check that a summary was printed
    var output = logger.stdoutBuffer.toString();
    expect(output, contains('Diff of changes'));
    // And that it refers to test.dart and pubspec.yaml
    expect(output, contains('test.dart'));
    expect(output, contains('pubspec.yaml'));
    // And that it contains text from a changed line
    expect(output, contains('f() => null'));
    // And that it tells the user they can rerun with `--apply-changes`
    expect(output, contains('--apply-changes'));
    // No changes should have been made
    assertProjectContents(projectDir, projectContents);
  }

  test_lifecycle_override_paths() async {
    Map<String, String> makeProject({bool migrated = false}) {
      var projectContents = simpleProject(migrated: migrated);
      projectContents['lib/test.dart'] = '''
import 'skip.dart';
import 'analyze_but_do_not_migrate.dart';
void f(int x) {}
void g(int${migrated ? '?' : ''} x) {}
void h(int${migrated ? '?' : ''} x) {}
void call_h() => h(null);
''';
      projectContents['lib/skip.dart'] = '''
import 'test.dart';
void call_f() => f(null);
''';
      projectContents['lib/analyze_but_do_not_migrate.dart'] = '''
import 'test.dart';
void call_g() => g(null);
''';
      return projectContents;
    }

    var projectContents = makeProject();
    var projectDir = createProjectDir(projectContents);
    var testPath =
        resourceProvider.pathContext.join(projectDir, 'lib', 'test.dart');
    var analyzeButDoNotMigratePath = resourceProvider.pathContext
        .join(projectDir, 'lib', 'analyze_but_do_not_migrate.dart');
    overridePathsToProcess = {testPath, analyzeButDoNotMigratePath};
    overrideShouldBeMigrated = (path) => path == testPath;
    var cliRunner = _createCli().decodeCommandLineArgs(_parseArgs([
      '--no-web-preview',
      '--apply-changes',
      '--skip-import-check',
      projectDir
    ]));
    await cliRunner.run();
    assertNormalExit(cliRunner);
    // Check that a summary was printed
    expect(logger.stdoutBuffer.toString(), contains('Applying changes'));
    // And that it refers to test.dart and pubspec.yaml
    expect(logger.stdoutBuffer.toString(), contains('test.dart'));
    expect(logger.stdoutBuffer.toString(), contains('pubspec.yaml'));
    // And that it does not tell the user they can rerun with `--apply-changes`
    expect(logger.stdoutBuffer.toString(), isNot(contains('--apply-changes')));
    // Changes should have been made only to test.dart, and only accounting for
    // the calls coming from analyze_but_do_not_migrate.dart and test.dart
    assertProjectContents(projectDir, makeProject(migrated: true));
  }

  test_lifecycle_preview() async {
    var projectContents = simpleProject();
    var projectDir = createProjectDir(projectContents);
    var cli = _createCli();
    await runWithPreviewServer(cli, [projectDir], (url) async {
      var localhostAddressText = Platform.environment.containsKey('FORCE_IPV6')
          ? '[::1]'
          : '127.0.0.1';
      expect(
          logger.stdoutBuffer.toString(), contains('No analysis issues found'));
      expect(url, startsWith('http://$localhostAddressText:'));
      await assertPreviewServerResponsive(url);
    });
    // No changes should have been made.
    assertProjectContents(projectDir, projectContents);
  }

  test_lifecycle_preview_add_hint() async {
    var projectContents = simpleProject(sourceText: 'int x;');
    var projectDir = createProjectDir(projectContents);
    var cli = _createCli();
    await runWithPreviewServer(cli, [projectDir], (url) async {
      expect(
          logger.stdoutBuffer.toString(), contains('No analysis issues found'));
      await assertPreviewServerResponsive(url);
      var uri = Uri.parse(url);
      var authToken = uri.queryParameters['authToken'];
      var response = await httpPost(
          uri.replace(
              path: resourceProvider.pathContext
                  .toUri(resourceProvider.pathContext
                      .join(projectDir, 'lib', 'test.dart'))
                  .path,
              queryParameters: {
                'offset': '3',
                'end': '3',
                'replacement': '/*!*/',
                'authToken': authToken
              }),
          headers: {'Content-Type': 'application/json; charset=UTF-8'});
      assertHttpSuccess(response);
      assertProjectContents(
          projectDir, simpleProject(sourceText: 'int/*!*/ x;'));
    });
  }

  test_lifecycle_preview_apply_changes() async {
    var projectContents = simpleProject();
    var projectDir = createProjectDir(projectContents);
    var cli = _createCli();
    bool applyHookCalled = false;
    cli._onApplyHook = () {
      expect(applyHookCalled, false);
      applyHookCalled = true;
      // Changes should have been made
      assertProjectContents(projectDir, simpleProject(migrated: true));
    };
    await runWithPreviewServer(cli, [projectDir], (url) async {
      expect(
          logger.stdoutBuffer.toString(), contains('No analysis issues found'));
      await assertPreviewServerResponsive(url);
      await _tellPreviewToApplyChanges(url);
      expect(applyHookCalled, true);
    });
  }

  test_lifecycle_preview_extra_forward_slash() async {
    var projectDir = createProjectDir(simpleProject());
    var cli = _createCli();
    await runWithPreviewServer(cli, [projectDir], (url) async {
      var uri = Uri.parse(url);
      await assertPreviewServerResponsive(
          uri.replace(path: uri.path + '/').toString());
    });
  }

  test_lifecycle_preview_navigation_links() async {
    var projectContents = simpleProject(sourceText: 'int x;');
    projectContents['lib/src/test.dart'] = 'import "../test.dart"; int y = x;';
    var projectDir = createProjectDir(projectContents);
    var cli = _createCli();
    await runWithPreviewServer(cli, [projectDir], (url) async {
      expect(
          logger.stdoutBuffer.toString(), contains('No analysis issues found'));
      await assertPreviewServerResponsive(url);
      final uri = Uri.parse(url);
      final authToken = uri.queryParameters['authToken'];
      final fileResponse = await httpGet(
          uri.replace(
              path: resourceProvider.pathContext
                  .toUri(resourceProvider.pathContext
                      .join(projectDir, 'lib', 'src', 'test.dart'))
                  .path,
              queryParameters: {'inline': 'true', 'authToken': authToken}),
          headers: {'Content-Type': 'application/json; charset=UTF-8'});
      final fileJson = FileDetails.fromJson(jsonDecode(fileResponse.body));
      final navigation = fileJson.navigationContent;
      final aLink = RegExp(r'<a href="([^"]+)" class="nav-link">');
      for (final match in aLink.allMatches(navigation)) {
        var href = match.group(1);
        final contentsResponse = await httpGet(
            uri.replace(
                path: Uri.parse(href).path,
                queryParameters: {'inline': 'true', 'authToken': authToken}),
            headers: {'Content-Type': 'application/json; charset=UTF-8'});
        assertHttpSuccess(contentsResponse);
      }
    });
  }

  test_lifecycle_preview_navigation_tree() async {
    var projectContents = simpleProject(sourceText: 'int x;');
    var projectDir = createProjectDir(projectContents);
    var cli = _createCli();
    await runWithPreviewServer(cli, [projectDir], (url) async {
      expect(
          logger.stdoutBuffer.toString(), contains('No analysis issues found'));
      await assertPreviewServerResponsive(url);
      var uri = Uri.parse(url);
      var authToken = uri.queryParameters['authToken'];
      var treeResponse = await httpGet(
          uri.replace(
              path: '/_preview/navigationTree.json',
              queryParameters: {'authToken': authToken}),
          headers: {'Content-Type': 'application/json; charset=UTF-8'});
      var navRoots = jsonDecode(treeResponse.body);
      for (final root in navRoots) {
        var navTree =
            NavigationTreeNode.fromJson(root) as NavigationTreeDirectoryNode;
        for (final file in navTree.subtree) {
          if (file is NavigationTreeFileNode) {
            final contentsResponse = await httpGet(
                uri
                    .resolve(file.href)
                    .replace(queryParameters: {'authToken': authToken}),
                headers: {'Content-Type': 'application/json; charset=UTF-8'});
            assertHttpSuccess(contentsResponse);
          }
        }
      }
    });
  }

  test_lifecycle_preview_on_host_any() async {
    var projectContents = simpleProject();
    var projectDir = createProjectDir(projectContents);
    var cli = _createCli()
      ..decodeCommandLineArgs(_parseArgs(['--preview-hostname=any']));
    await runWithPreviewServer(cli, [projectDir], (url) async {
      expect(url, isNot(contains('localhost')));
      await assertPreviewServerResponsive(url);
    });
    // No changes should have been made.
    assertProjectContents(projectDir, projectContents);
  }

  test_lifecycle_preview_region_link() async {
    var projectContents = simpleProject(sourceText: 'int x;');
    var projectDir = createProjectDir(projectContents);
    var cli = _createCli();
    await runWithPreviewServer(cli, [projectDir], (url) async {
      expect(
          logger.stdoutBuffer.toString(), contains('No analysis issues found'));
      await assertPreviewServerResponsive(url);
      var uri = Uri.parse(url);
      var authToken = uri.queryParameters['authToken'];
      var regionResponse = await httpGet(
          uri.replace(
              path: resourceProvider.pathContext
                  .toUri(resourceProvider.pathContext
                      .join(projectDir, 'lib', 'test.dart'))
                  .path,
              queryParameters: {
                'region': 'region',
                'offset': '3',
                'authToken': authToken
              }),
          headers: {'Content-Type': 'application/json; charset=UTF-8'});
      var regionJson = EditDetails.fromJson(jsonDecode(regionResponse.body));
      final displayPath = regionJson.displayPath;
      final uriPath = regionJson.uriPath;
      // uriPath should be a working URI
      final contentsResponse = await httpGet(
          uri.replace(
              path: uriPath,
              queryParameters: {'inline': 'true', 'authToken': authToken}),
          headers: {'Content-Type': 'application/json; charset=UTF-8'});
      assertHttpSuccess(contentsResponse);

      // Display path should be the actual windows path
      final file = resourceProvider
          .getFolder(projectDir)
          .getChildAssumingFile(displayPath);
      expect(file.exists, isTrue);
    });
  }

  test_lifecycle_preview_region_table_path() async {
    var projectContents = simpleProject(sourceText: 'int x;');
    var projectDir = createProjectDir(projectContents);
    var cli = _createCli();
    await runWithPreviewServer(cli, [projectDir], (url) async {
      expect(
          logger.stdoutBuffer.toString(), contains('No analysis issues found'));
      await assertPreviewServerResponsive(url);
      final uri = Uri.parse(url);
      final authToken = uri.queryParameters['authToken'];
      final fileResponse = await httpGet(
          uri.replace(
              path: resourceProvider.pathContext
                  .toUri(resourceProvider.pathContext
                      .join(projectDir, 'lib', 'test.dart'))
                  .path,
              queryParameters: {'inline': 'true', 'authToken': authToken}),
          headers: {'Content-Type': 'application/json; charset=UTF-8'});
      final fileJson = FileDetails.fromJson(jsonDecode(fileResponse.body));
      final regions = fileJson.regions;
      final regionsPathRegex = RegExp(r'<table data-path="([^"]+)">');
      expect(regionsPathRegex.hasMatch(regions), true);
      final regionsPath = regionsPathRegex.matchAsPrefix(regions).group(1);
      final contentsResponse = await httpGet(
          uri.replace(
              path: Uri.parse(regionsPath).path,
              queryParameters: {'inline': 'true', 'authToken': authToken}),
          headers: {'Content-Type': 'application/json; charset=UTF-8'});
      assertHttpSuccess(contentsResponse);
    });
  }

  test_lifecycle_preview_rerun() async {
    var origSourceText = 'void f() {}';
    var projectContents = simpleProject(sourceText: origSourceText);
    var projectDir = createProjectDir(projectContents);
    var cli = _createCli();
    await runWithPreviewServer(cli, [projectDir], (url) async {
      await assertPreviewServerResponsive(url);
      var uri = Uri.parse(url);
      var testPath =
          resourceProvider.pathContext.join(projectDir, 'lib', 'test.dart');
      var newSourceText = 'void g() {}';
      resourceProvider.getFile(testPath).writeAsStringSync(newSourceText);
      // We haven't rerun, so getting the file details from the server should
      // still yield the original source text
      expect(await getSourceFromServer(uri, testPath), origSourceText);
      var response = await httpPost(uri.replace(path: 'rerun-migration'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'});
      assertHttpSuccess(response);
      // Now that we've rerun, the server should yield the new source text
      expect(await getSourceFromServer(uri, testPath), newSourceText);
    });
  }

  test_lifecycle_preview_rerun_added_file() async {
    var projectContents = simpleProject();
    var projectDir = createProjectDir(projectContents);
    var cli = _createCli();
    await runWithPreviewServer(cli, [projectDir], (url) async {
      await assertPreviewServerResponsive(url);
      var uri = Uri.parse(url);
      var test2Path =
          resourceProvider.pathContext.join(projectDir, 'lib', 'test2.dart');
      var newSourceText = 'void g() {}';
      resourceProvider.getFile(test2Path).writeAsStringSync(newSourceText);
      // We haven't rerun, so getting the file details from the server should
      // fail
      var response = await tryGetSourceFromServer(uri, test2Path);
      expect(response.statusCode, 404);
      response = await httpPost(uri.replace(path: 'rerun-migration'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'});
      assertHttpSuccess(response);
      // Now that we've rerun, the server should yield the new source text
      expect(await getSourceFromServer(uri, test2Path), newSourceText);
    });
  }

  test_lifecycle_preview_rerun_deleted_file() async {
    var projectContents = {...simpleProject(), 'lib/other.dart': ''};
    var projectDir = createProjectDir(projectContents);
    var cli = _createCli();
    // Note: we use the summary to verify that the deletion was noticed
    var summaryPath = resourceProvider.convertPath('/summary.json');
    await runWithPreviewServer(cli, ['--summary', summaryPath, projectDir],
        (url) async {
      await assertPreviewServerResponsive(url);
      // lib/test.dart should be readable from the server and appear in the
      // summary
      var uri = Uri.parse(url);
      var testPath =
          resourceProvider.pathContext.join(projectDir, 'lib', 'test.dart');
      await getSourceFromServer(uri, testPath);
      var summaryData =
          jsonDecode(resourceProvider.getFile(summaryPath).readAsStringSync());
      var separator = resourceProvider.pathContext.separator;
      expect(summaryData['changes']['byPath'],
          contains('lib${separator}test.dart'));
      // Now delete the lib file and rerun
      resourceProvider.deleteFile(testPath);
      var response = await httpPost(uri.replace(path: 'rerun-migration'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'});
      assertHttpSuccess(response);
      // lib/test.dart should no longer be readable from the server and
      // should no longer appear in the summary
      response = await tryGetSourceFromServer(uri, testPath);
      expect(response.statusCode, 404);
      summaryData =
          jsonDecode(resourceProvider.getFile(summaryPath).readAsStringSync());
      expect(summaryData['changes']['byPath'],
          isNot(contains('lib${separator}test.dart')));
    });
  }

  test_lifecycle_preview_rerun_with_new_analysis_errors() async {
    var origSourceText = 'void f(int i) {}';
    var projectContents = simpleProject(sourceText: origSourceText);
    var projectDir = createProjectDir(projectContents);
    var cli = _createCli();
    await runWithPreviewServer(cli, [projectDir], (url) async {
      await assertPreviewServerResponsive(url);
      var uri = Uri.parse(url);
      var testPath =
          resourceProvider.pathContext.join(projectDir, 'lib', 'test.dart');
      var newSourceText = 'void f(int? i) {}';
      resourceProvider.getFile(testPath).writeAsStringSync(newSourceText);
      // We haven't rerun, so getting the file details from the server should
      // still yield the original source text, with informational space.
      expect(await getSourceFromServer(uri, testPath), 'void f(int  i) {}');
      var response = await httpPost(uri.replace(path: 'rerun-migration'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'});
      assertHttpSuccess(response);
      var body = jsonDecode(response.body);
      expect(body['success'], isFalse);
      expect(body['errors'], hasLength(1));
      var error = body['errors'].single;
      expect(error['severity'], equals('error'));
      expect(
          error['message'],
          equals(
              "This requires the 'non-nullable' language feature to be enabled"));
      expect(error['location'],
          equals(resourceProvider.pathContext.join('lib', 'test.dart:1:11')));
      expect(error['code'], equals('experiment_not_enabled'));
    });
  }

  test_lifecycle_preview_serves_only_from_project_dir() async {
    var crazyFunctionName = 'crazyFunctionNameThatHasNeverBeenSeenBefore';
    var projectContents =
        simpleProject(sourceText: 'void $crazyFunctionName() {}');
    var mainProjectDir = createProjectDir(projectContents);
    var otherProjectDir =
        createProjectDir(projectContents, posixPath: '/other_project_dir');
    var cli = _createCli();
    await runWithPreviewServer(cli, [mainProjectDir], (url) async {
      await assertPreviewServerResponsive(url);
      var uri = Uri.parse(url);

      Future<http.Response> tryGetSourceFromProject(String projectDir) =>
          tryGetSourceFromServer(
              uri,
              resourceProvider.pathContext
                  .join(projectDir, 'lib', 'test.dart'));

      // To verify that we're forming the request correctly, make sure that we
      // can read a file from mainProjectDir.
      var response = await tryGetSourceFromProject(mainProjectDir);
      assertHttpSuccess(response);
      // And that crazyFunctionName appears in the response
      expect(response.body, contains(crazyFunctionName));
      // Now verify that making the exact same request from otherProjectDir
      // fails.
      response = await tryGetSourceFromProject(otherProjectDir);
      expect(response.statusCode, 404);
      // And check that we didn't leak any info through the 404 response.
      expect(response.body, isNot(contains(crazyFunctionName)));
    });
  }

  test_lifecycle_preview_stack_hint_action() async {
    var projectContents = simpleProject(sourceText: 'int x;');
    var projectDir = createProjectDir(projectContents);
    var cli = _createCli();
    await runWithPreviewServer(cli, [projectDir], (url) async {
      expect(
          logger.stdoutBuffer.toString(), contains('No analysis issues found'));
      await assertPreviewServerResponsive(url);
      var uri = Uri.parse(url);
      var authToken = uri.queryParameters['authToken'];
      var regionResponse = await httpGet(
          uri.replace(
              path: resourceProvider.pathContext
                  .toUri(resourceProvider.pathContext
                      .join(projectDir, 'lib', 'test.dart'))
                  .path,
              queryParameters: {
                'region': 'region',
                'offset': '3',
                'authToken': authToken
              }),
          headers: {'Content-Type': 'application/json; charset=UTF-8'});
      var regionJson = jsonDecode(regionResponse.body);
      var response = await httpPost(
          uri.replace(
              path: 'apply-hint', queryParameters: {'authToken': authToken}),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode(
              regionJson['traces'][0]['entries'][0]['hintActions'][0]));
      assertHttpSuccess(response);
      assertProjectContents(
          projectDir, simpleProject(sourceText: 'int/*?*/ x;'));
    });
  }

  test_lifecycle_preview_stacktrace_link() async {
    var projectContents = simpleProject(sourceText: 'int x;');
    var projectDir = createProjectDir(projectContents);
    var cli = _createCli();
    await runWithPreviewServer(cli, [projectDir], (url) async {
      expect(
          logger.stdoutBuffer.toString(), contains('No analysis issues found'));
      await assertPreviewServerResponsive(url);
      var uri = Uri.parse(url);
      var authToken = uri.queryParameters['authToken'];
      var regionUri = uri.replace(
          path: resourceProvider.pathContext
              .toUri(resourceProvider.pathContext
                  .join(projectDir, 'lib', 'test.dart'))
              .path,
          queryParameters: {
            'region': 'region',
            'offset': '3',
            'authToken': authToken
          });
      var regionResponse = await httpGet(regionUri,
          headers: {'Content-Type': 'application/json; charset=UTF-8'});
      var regionJson = EditDetails.fromJson(jsonDecode(regionResponse.body));
      final traceEntry = regionJson.traces[0].entries[0];
      final uriPath = traceEntry.link.href;
      // uriPath should be a working URI
      final contentsResponse = await httpGet(
          regionUri
              .resolve(uriPath)
              .replace(queryParameters: {'authToken': authToken}),
          headers: {'Content-Type': 'application/json; charset=UTF-8'});
      assertHttpSuccess(contentsResponse);
    });
  }

  test_lifecycle_skip_import_check_disable() async {
    var projectContents = simpleProject(
        sourceText: '''
import 'package:foo/foo.dart';
import 'package:foo/bar.dart';

int f() => null;
''',
        packageConfigText: _getPackageConfigText(
            migrated: false, packagesMigrated: {'foo': false}));
    var projectDir = createProjectDir(projectContents);
    resourceProvider.newFile(packagePath('foo/lib/foo.dart'), '');
    resourceProvider.newFile(packagePath('foo/lib/bar.dart'), '');
    await assertRunFailure([projectDir], expectedExitCode: 1);
    var output = logger.stdoutBuffer.toString();
    expect(output, contains('Error: package has unmigrated dependencies'));
    // Output should contain an indented, sorted list of all unmigrated
    // dependencies.
    expect(
        output, contains('\n  package:foo/bar.dart\n  package:foo/foo.dart'));
    // Output should mention that the user can rerun with `--skip-import-check`.
    expect(output, contains('`--${CommandLineOptions.skipImportCheckFlag}`'));
  }

  test_lifecycle_skip_import_check_enable() async {
    var projectContents = simpleProject(
        sourceText: '''
import 'package:foo/foo.dart';
import 'package:foo/bar.dart';

int f() => null;
''',
        packageConfigText: _getPackageConfigText(
            migrated: false, packagesMigrated: {'foo': false}));
    var projectDir = createProjectDir(projectContents);
    resourceProvider.newFile(packagePath('foo/lib/foo.dart'), '');
    resourceProvider.newFile(packagePath('foo/lib/bar.dart'), '');
    var cli = _createCli();
    await runWithPreviewServer(cli, ['--skip-import-check', projectDir],
        (url) async {
      await assertPreviewServerResponsive(url);
      var output = logger.stdoutBuffer.toString();
      expect(output, contains('Warning: package has unmigrated dependencies'));
      // Output should not mention the particular unmigrated dependencies.
      expect(output, isNot(contains('package:foo')));
      // Output should mention that the user can rerun without
      // `--skip-import-check`.
      expect(output, contains('`--${CommandLineOptions.skipImportCheckFlag}`'));
    });
  }

  test_lifecycle_summary() async {
    var projectContents = simpleProject();
    var projectDir = createProjectDir(projectContents);
    var summaryPath = resourceProvider.convertPath('/summary.json');
    var cliRunner = _createCli().decodeCommandLineArgs(
        _parseArgs(['--no-web-preview', '--summary', summaryPath, projectDir]));
    await cliRunner.run();
    var summaryData =
        jsonDecode(resourceProvider.getFile(summaryPath).readAsStringSync());
    expect(summaryData, TypeMatcher<Map>());
    expect(summaryData, contains('changes'));
    assertNormalExit(cliRunner);
  }

  test_lifecycle_summary_does_not_double_count_hint_removals() async {
    var projectContents = simpleProject(sourceText: 'int/*?*/ x;');
    var projectDir = createProjectDir(projectContents);
    var summaryPath = resourceProvider.convertPath('/summary.json');
    var cliRunner = _createCli().decodeCommandLineArgs(
        _parseArgs(['--no-web-preview', '--summary', summaryPath, projectDir]));
    await cliRunner.run();
    assertNormalExit(cliRunner);
    var summaryData =
        jsonDecode(resourceProvider.getFile(summaryPath).readAsStringSync());
    var separator = resourceProvider.pathContext.separator;
    expect(summaryData['changes']['byPath']['lib${separator}test.dart'],
        {'makeTypeNullableDueToHint': 1});
  }

  test_lifecycle_summary_rewritten_upon_rerun() async {
    var projectContents = simpleProject(sourceText: 'int f(int/*?*/ i) => i;');
    var projectDir = createProjectDir(projectContents);
    var cli = _createCli();
    var summaryPath = resourceProvider.convertPath('/summary.json');
    await runWithPreviewServer(cli, ['--summary', summaryPath, projectDir],
        (url) async {
      await assertPreviewServerResponsive(url);
      var summaryData =
          jsonDecode(resourceProvider.getFile(summaryPath).readAsStringSync());
      var separator = resourceProvider.pathContext.separator;
      expect(summaryData['changes']['byPath']['lib${separator}test.dart'],
          {'makeTypeNullableDueToHint': 1, 'makeTypeNullable': 1});
      var testPath =
          resourceProvider.pathContext.join(projectDir, 'lib', 'test.dart');
      var newSourceText = 'int f(int/*?*/ i) => i + 1;';
      resourceProvider.getFile(testPath).writeAsStringSync(newSourceText);
      // Rerunning should create a new summary
      var uri = Uri.parse(url);
      var response = await httpPost(uri.replace(path: 'rerun-migration'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'});
      assertHttpSuccess(response);
      summaryData =
          jsonDecode(resourceProvider.getFile(summaryPath).readAsStringSync());
      expect(summaryData['changes']['byPath']['lib${separator}test.dart'], {
        'typeNotMadeNullable': 1,
        'makeTypeNullableDueToHint': 1,
        'checkExpression': 1
      });
    });
  }

  test_lifecycle_uri_error() async {
    var projectContents = simpleProject(sourceText: '''
import 'package:does_not/exist.dart';
int f() => null;
''');
    var projectDir = createProjectDir(projectContents);
    await assertRunFailure([projectDir]);
    var output = logger.stdoutBuffer.toString();
    expect(output, contains('1 analysis issue found'));
    expect(output, contains('uri_does_not_exist'));
    expect(output, isNot(contains('erroneous migration suggestions')));
    expect(output, contains('Run `dart pub get`'));
    expect(output, contains('Try running `dart migrate` again'));
    expect(output, isNot(contains('Set the lower SDK constraint')));
  }

  test_migrate_path_absolute() {
    resourceProvider.newFolder(resourceProvider.pathContext
        .join(resourceProvider.pathContext.current, 'foo'));
    expect(
        resourceProvider.pathContext
            .isAbsolute(assertParseArgsSuccess(['foo']).directory),
        isTrue);
  }

  test_migrate_path_file() {
    resourceProvider.newFile(resourceProvider.pathContext.absolute('foo'), '');
    expect(assertDecodeArgsFailure(['foo']), contains('foo is a file'));
  }

  test_migrate_path_non_existent() {
    expect(assertDecodeArgsFailure(['foo']), contains('foo does not exist'));
  }

  test_migrate_path_none() {
    expect(assertParseArgsSuccess([]).directory,
        resourceProvider.pathContext.current);
  }

  test_migrate_path_normalized() {
    expect(assertParseArgsSuccess(['foo/..']).directory, isNot(contains('..')));
  }

  test_migrate_path_one() {
    resourceProvider.newFolder(resourceProvider.pathContext
        .join(resourceProvider.pathContext.current, 'foo'));
    expect(
        assertParseArgsSuccess(['foo']).directory,
        resourceProvider.pathContext
            .join(resourceProvider.pathContext.current, 'foo'));
  }

  test_migrate_path_two() async {
    var stderrText = await assertRunFailure(['foo', 'bar'], withUsage: true);
    expect(stderrText, contains('No more than one path may be specified'));
  }

  test_option_preview_hostname() {
    expect(
        assertParseArgsSuccess(['--preview-hostname', 'any']).previewHostname,
        'any');
  }

  test_option_preview_hostname_default() {
    expect(assertParseArgsSuccess([]).previewHostname, 'localhost');
  }

  test_option_preview_port() {
    expect(
        assertParseArgsSuccess(['--preview-port', '4040']).previewPort, 4040);
  }

  test_option_preview_port_default() {
    expect(assertParseArgsSuccess([]).previewPort, isNull);
  }

  test_option_preview_port_format_error() {
    expect(assertDecodeArgsFailure(['--preview-port', 'abc']),
        contains('Invalid value for --preview-port'));
  }

  test_option_sdk() {
    var path = Uri.parse('file:///foo/bar/baz').toFilePath();
    expect(assertParseArgsSuccess(['--sdk-path', path]).sdkPath, same(path));
  }

  test_option_sdk_default() {
    var cli = MigrationCli(binaryName: 'nnbd_migration');
    var cliRunner = cli.decodeCommandLineArgs(_parseArgs([]));
    expect(Directory(path.join(cliRunner.options.sdkPath, 'bin')).existsSync(),
        isTrue);
  }

  test_option_sdk_hidden() {
    var optionName = '--sdk-path';
    expect(_getHelpText(verbose: false), isNot(contains(optionName)));
    expect(_getHelpText(verbose: true), contains(optionName));
  }

  test_option_summary() {
    var summaryPath = resourceProvider.convertPath('/summary.json');
    expect(assertParseArgsSuccess(['--summary', summaryPath]).summary,
        summaryPath);
  }

  test_option_unrecognized() async {
    expect(
        await assertParseArgsFailure(['--this-option-does-not-exist']),
        contains(
            'Could not find an option named "this-option-does-not-exist"'));
  }

  test_package_config_does_not_exist() async {
    var projectContents = simpleProject()
      ..remove('.dart_tool/package_config.json');
    var projectDir = createProjectDir(projectContents);

    if (dartVersionIsNullSafeByDefault) {
      // The lack of a package config file means the test file is already opted
      // in.
      await assertRunFailure(['--apply-changes', projectDir]);
      _expectErrorIndicatingCodeIsAlreadyOptedIn();
    } else {
      var cliRunner = _createCli()
          .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
      await cliRunner.run();
      // The Dart source code should still be migrated.
      assertProjectContents(
          projectDir,
          simpleProject(migrated: true)
            ..remove('.dart_tool/package_config.json'));
    }
  }

  test_package_config_is_missing_languageVersion() async {
    var packageConfigText = '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/"
    }
  ]
}
''';
    var projectContents = simpleProject(packageConfigText: packageConfigText);
    var projectDir = createProjectDir(projectContents);

    if (dartVersionIsNullSafeByDefault) {
      // An omitted languageVersion field means the code is opted in to null
      // safety.
      await assertRunFailure(['--apply-changes', projectDir]);
      _expectErrorIndicatingCodeIsAlreadyOptedIn();
    } else {
      var cliRunner = _createCli()
          .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
      await cliRunner.run();
      // The Dart source code should still be migrated.
      assertProjectContents(projectDir,
          simpleProject(migrated: true, packageConfigText: packageConfigText));
    }
  }

  test_package_config_is_missing_this_package() async {
    var packageConfigText = '''
{
  "configVersion": 2,
  "packages": [
  ]
}
''';
    var projectContents = simpleProject(packageConfigText: packageConfigText);
    var projectDir = createProjectDir(projectContents);

    if (dartVersionIsNullSafeByDefault) {
      // An omitted entry in the package config means the code is opted in to null
      // safety.
      await assertRunFailure(['--apply-changes', projectDir]);
      _expectErrorIndicatingCodeIsAlreadyOptedIn();
    } else {
      var cliRunner = _createCli()
          .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
      await cliRunner.run();
      // The Dart source code should still be migrated.
      assertProjectContents(projectDir,
          simpleProject(migrated: true, packageConfigText: packageConfigText));
    }
  }

  test_package_config_is_wrong_version() async {
    var packageConfigText = '''
{
  "configVersion": 3,
  "packages": [
    {
      "name": "test",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "2.6"
    }
  ]
}
''';
    var projectContents = simpleProject(packageConfigText: packageConfigText);
    var projectDir = createProjectDir(projectContents);

    if (dartVersionIsNullSafeByDefault) {
      // An unreadable package config means the code is opted in to null safety.
      await assertRunFailure(['--apply-changes', projectDir]);
      _expectErrorIndicatingCodeIsAlreadyOptedIn();
    } else {
      var cliRunner = _createCli()
          .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
      await cliRunner.run();
      // The Dart source code should still be migrated.
      assertProjectContents(projectDir,
          simpleProject(migrated: true, packageConfigText: packageConfigText));
    }
  }

  test_pubspec_add_collection_dependency() async {
    var projectContents = simpleProject(sourceText: '''
int firstEven(Iterable<int> x)
    => x.firstWhere((x) => x.isEven, orElse: () => null);
''', pubspecText: '''
name: test
environment:
  sdk: '>=2.6.0 <3.0.0'
dependencies:
  foo: ^1.2.3
''');
    var projectDir = createProjectDir(projectContents);
    var cliRunner = _createCli()
        .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
    await cliRunner.run();
    expect(
        logger.stdoutBuffer.toString(), contains('Please run `dart pub get`'));
    // The Dart source code should still be migrated.
    assertProjectContents(
        projectDir, simpleProject(migrated: true, sourceText: '''
import 'package:collection/collection.dart' show IterableExtension;

int? firstEven(Iterable<int> x)
    => x.firstWhereOrNull((x) => x.isEven);
''', pubspecText: '''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  foo: ^1.2.3
  collection: ^1.15.0-nullsafety.4
'''));
  }

  test_pubspec_add_dependency_and_environment_sections() async {
    var projectContents = simpleProject(sourceText: '''
int firstEven(Iterable<int> x)
    => x.firstWhere((x) => x.isEven, orElse: () => null);
''', pubspecText: '''
name: test
''');
    var projectDir = createProjectDir(projectContents);
    var cliRunner = _createCli()
        .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
    await cliRunner.run();
    expect(
        logger.stdoutBuffer.toString(), contains('Please run `dart pub get`'));
    // The Dart source code should still be migrated.
    assertProjectContents(
        projectDir, simpleProject(migrated: true, sourceText: '''
import 'package:collection/collection.dart' show IterableExtension;

int? firstEven(Iterable<int> x)
    => x.firstWhereOrNull((x) => x.isEven);
''',
            // Note: section order is weird, but it's valid and this is a rare use
            // case.
            pubspecText: '''
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  collection: ^1.15.0-nullsafety.4
name: test
'''));
  }

  test_pubspec_add_dependency_section() async {
    var projectContents = simpleProject(sourceText: '''
int firstEven(Iterable<int> x)
    => x.firstWhere((x) => x.isEven, orElse: () => null);
''');
    var projectDir = createProjectDir(projectContents);
    var cliRunner = _createCli()
        .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
    await cliRunner.run();
    expect(
        logger.stdoutBuffer.toString(), contains('Please run `dart pub get`'));
    // The Dart source code should still be migrated.
    assertProjectContents(projectDir, simpleProject(migrated: true, sourceText: '''
import 'package:collection/collection.dart' show IterableExtension;

int? firstEven(Iterable<int> x)
    => x.firstWhereOrNull((x) => x.isEven);
''',
        // Note: `dependencies` section is in a weird place, but it's valid and
        // this is a rare use case.
        pubspecText: '''
dependencies:
  collection: ^1.15.0-nullsafety.4
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
'''));
  }

  test_pubspec_does_not_exist() async {
    var projectContents = simpleProject()..remove('pubspec.yaml');
    var projectDir = createProjectDir(projectContents);
    var cliRunner = _createCli()
        .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
    await cliRunner.run();
    // The Dart source code should still be migrated.
    assertProjectContents(
        projectDir,
        simpleProject(
            migrated: true,
            // The package config file should not have been touched.
            packageConfigText: _getPackageConfigText(migrated: false))
          ..remove('pubspec.yaml'));
  }

  test_pubspec_environment_is_missing_sdk() async {
    var projectContents = simpleProject(pubspecText: '''
name: test
environment:
  foo: 1
''');
    var projectDir = createProjectDir(projectContents);
    var cliRunner = _createCli()
        .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
    await cliRunner.run();
    // The Dart source code should still be migrated.
    assertProjectContents(
        projectDir, simpleProject(migrated: true, pubspecText: '''
name: test
environment:
  foo: 1
  sdk: '>=2.12.0 <3.0.0'
'''));
  }

  test_pubspec_environment_is_not_a_map() async {
    var pubspecText = '''
name: test
environment: 1
''';
    var projectContents = simpleProject(pubspecText: pubspecText);
    var projectDir = createProjectDir(projectContents);
    var cliRunner = _createCli()
        .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
    await cliRunner.run();
    // The Dart source code should still be migrated.
    assertProjectContents(
        projectDir, simpleProject(migrated: true, pubspecText: pubspecText));
  }

  test_pubspec_environment_sdk_is_not_string() async {
    var pubspecText = '''
name: test
environment:
  sdk: 1
''';
    var projectContents = simpleProject(pubspecText: pubspecText);
    var projectDir = createProjectDir(projectContents);
    var cliRunner = _createCli()
        .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
    await cliRunner.run();
    // The Dart source code should still be migrated.
    assertProjectContents(
        projectDir,
        simpleProject(
            migrated: true,
            pubspecText: pubspecText,
            // The package config file should not have been touched.
            packageConfigText: _getPackageConfigText(migrated: false)));
  }

  test_pubspec_has_unusual_max_sdk_constraint() async {
    // No one should be using a weird max SDK constraint like this.  If they are
    // doing so, we'll fix it to 3.0.0.
    var projectContents = simpleProject(pubspecText: '''
name: test
environment:
  sdk: '>=2.6.0 <2.17.4'
''');
    var projectDir = createProjectDir(projectContents);
    var cliRunner = _createCli()
        .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
    await cliRunner.run();
    // The Dart source code should still be migrated.
    assertProjectContents(
        projectDir, simpleProject(migrated: true, pubspecText: '''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
'''));
  }

  test_pubspec_is_missing_environment() async {
    var projectContents = simpleProject(pubspecText: '''
name: test
''');
    var projectDir = createProjectDir(projectContents);
    var cliRunner = _createCli()
        .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
    await cliRunner.run();
    // The Dart source code should still be migrated.
    assertProjectContents(projectDir, simpleProject(migrated: true, pubspecText:
        // This is strange-looking, but valid.
        '''
environment:
  sdk: '>=2.12.0 <3.0.0'
name: test
'''));
  }

  test_pubspec_is_not_a_map() async {
    var projectContents = simpleProject(pubspecText: 'not-a-map');
    var projectDir = createProjectDir(projectContents);
    var cliRunner = _createCli()
        .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
    var message = await assertErrorExit(
        cliRunner, () async => await cliRunner.run(),
        withUsage: false);
    expect(message, contains('Failed to parse pubspec file'));
  }

  test_pubspec_preserve_collection_dependency() async {
    var projectContents = simpleProject(sourceText: '''
int firstEven(Iterable<int> x)
    => x.firstWhere((x) => x.isEven, orElse: () => null);
''', pubspecText: '''
name: test
environment:
  sdk: '>=2.6.0 <3.0.0'
dependencies:
  collection: ^1.16.0
''');
    var projectDir = createProjectDir(projectContents);
    var cliRunner = _createCli()
        .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
    await cliRunner.run();
    expect(logger.stdoutBuffer.toString(),
        isNot(contains('Please run `dart pub get`')));
    // The Dart source code should still be migrated.
    assertProjectContents(
        projectDir, simpleProject(migrated: true, sourceText: '''
import 'package:collection/collection.dart' show IterableExtension;

int? firstEven(Iterable<int> x)
    => x.firstWhereOrNull((x) => x.isEven);
''', pubspecText: '''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  collection: ^1.16.0
'''));
  }

  test_pubspec_update_collection_dependency() async {
    var projectContents = simpleProject(sourceText: '''
int firstEven(Iterable<int> x)
    => x.firstWhere((x) => x.isEven, orElse: () => null);
''', pubspecText: '''
name: test
environment:
  sdk: '>=2.6.0 <3.0.0'
dependencies:
  collection: ^1.14.0
''');
    var projectDir = createProjectDir(projectContents);
    var cliRunner = _createCli()
        .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
    await cliRunner.run();
    expect(
        logger.stdoutBuffer.toString(), contains('Please run `dart pub get`'));
    // The Dart source code should still be migrated.
    assertProjectContents(
        projectDir, simpleProject(migrated: true, sourceText: '''
import 'package:collection/collection.dart' show IterableExtension;

int? firstEven(Iterable<int> x)
    => x.firstWhereOrNull((x) => x.isEven);
''', pubspecText: '''
name: test
environment:
  sdk: '>=2.12.0 <3.0.0'
dependencies:
  collection: ^1.15.0-nullsafety.4
'''));
  }

  test_pubspec_with_sdk_version_beta() async {
    var projectDir = createProjectDir(simpleProject());
    var cliRunner = _createCli(sdkVersion: '2.12.0-1.2.beta')
        .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
    await cliRunner.run();
    assertProjectContents(
        projectDir, simpleProject(migrated: true, pubspecText: '''
name: test
environment:
  sdk: '>=2.12.0-1.2.beta <3.0.0'
'''));
  }

  test_pubspec_with_sdk_version_dev() async {
    var projectDir = createProjectDir(simpleProject());
    var cliRunner = _createCli(sdkVersion: '2.12.0-1.2.dev')
        .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
    await cliRunner.run();
    assertProjectContents(
        projectDir, simpleProject(migrated: true, pubspecText: '''
name: test
environment:
  sdk: '>=2.12.0-0 <3.0.0'
'''));
  }

  test_pubspec_with_sdk_version_edge() async {
    var projectDir = createProjectDir(simpleProject());
    var cliRunner = _createCli(sdkVersion: '2.12.0-edge.1234567')
        .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
    await cliRunner.run();
    assertProjectContents(
        projectDir, simpleProject(migrated: true, pubspecText: '''
name: test
environment:
  sdk: '>=2.12.0-0 <3.0.0'
'''));
  }

  test_pubspec_with_sdk_version_internal() async {
    var projectDir = createProjectDir(simpleProject());
    var cliRunner = _createCli(sdkVersion: '2.12.0-1234567')
        .decodeCommandLineArgs(_parseArgs(['--apply-changes', projectDir]));
    await cliRunner.run();
    assertProjectContents(
        projectDir, simpleProject(migrated: true, pubspecText: '''
name: test
environment:
  sdk: '>=2.12.0-0 <3.0.0'
'''));
  }

  test_uses_physical_resource_provider_by_default() {
    var cli = MigrationCli(binaryName: 'nnbd_migration');
    expect(cli.resourceProvider, same(PhysicalResourceProvider.INSTANCE));
  }

  Future<http.Response> tryGetSourceFromServer(Uri uri, String path) async {
    var authToken = uri.queryParameters['authToken'];
    return await httpGet(
        uri.replace(
            path: resourceProvider.pathContext.toUri(path).path,
            queryParameters: {'inline': 'true', 'authToken': authToken}),
        headers: {'Content-Type': 'application/json; charset=UTF-8'});
  }

  _MigrationCli _createCli(
      {List<String> nullSafePackages = const [], String sdkVersion}) {
    mock_sdk.MockSdk(
        resourceProvider: resourceProvider,
        nullSafePackages: nullSafePackages,
        sdkVersion: sdkVersion);
    return _MigrationCli(this);
  }

  void _expectErrorIndicatingCodeIsAlreadyOptedIn() {
    var errorOutput = logger.stdoutBuffer.toString();
    expect(errorOutput, contains('1 analysis issue found:'));
    expect(
        errorOutput,
        contains("A value of type 'Null' can't be returned from function 'f' "
            "because it has a return type of 'int'"));
    expect(errorOutput, contains('Set the lower SDK constraint'));
  }

  String _getHelpText({@required bool verbose}) {
    var cliRunner = _createCli().decodeCommandLineArgs(_parseArgs(
        ['--${CommandLineOptions.helpFlag}', if (verbose) '--verbose']));
    expect(cliRunner, isNull);
    var helpText = logger.stderrBuffer.toString();
    return helpText;
  }

  String _getPackageConfigText(
      {@required bool migrated,
      Map<String, bool> packagesMigrated = const {}}) {
    Object makePackageEntry(String name, bool migrated, {String rootUri}) {
      rootUri ??=
          resourceProvider.pathContext.toUri(packagePath(name)).toString();
      return {
        'name': name,
        'rootUri': rootUri,
        'packageUri': 'lib/',
        'languageVersion': migrated ? '2.12' : '2.6'
      };
    }

    var json = {
      'configVersion': 2,
      'packages': [
        makePackageEntry('test', migrated, rootUri: '../'),
        for (var entry in packagesMigrated.entries)
          makePackageEntry(entry.key, entry.value)
      ]
    };
    return JsonEncoder.withIndent('  ').convert(json) + '\n';
  }

  ArgResults _parseArgs(List<String> args) {
    return MigrationCli.createParser().parse(args);
  }

  Future<void> _tellPreviewToApplyChanges(String url) async {
    var uri = Uri.parse(url);
    var authToken = uri.queryParameters['authToken'];
    var response = await httpPost(
        uri.replace(
            path: PreviewSite.applyMigrationPath,
            queryParameters: {'authToken': authToken}),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({'navigationTree': []}));
    assertHttpSuccess(response);
  }
}

@reflectiveTest
class _MigrationCliTestPosix extends _MigrationCliTestBase
    with _MigrationCliTestMethods {
  @override
  final resourceProvider;

  _MigrationCliTestPosix()
      : resourceProvider = MemoryResourceProvider(
            context: path.style == path.Style.posix
                ? null
                : path.Context(
                    style: path.Style.posix, current: '/working_dir'));
}

@reflectiveTest
class _MigrationCliTestWindows extends _MigrationCliTestBase
    with _MigrationCliTestMethods {
  @override
  final resourceProvider;

  _MigrationCliTestWindows()
      : resourceProvider = MemoryResourceProvider(
            context: path.style == path.Style.windows
                ? null
                : path.Context(
                    style: path.Style.windows, current: 'C:\\working_dir'));
}
