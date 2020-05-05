// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/edit/fix/non_nullable_fix.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart' as mock_sdk;
import 'package:cli_util/cli_logging.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:nnbd_migration/migration_cli.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(_MigrationCliTestPosix);
    defineReflectiveTests(_MigrationCliTestWindows);
  });
}

class _MigrationCli extends MigrationCli {
  Future<void> Function() _runWhilePreviewServerActive;

  _MigrationCli(_MigrationCliTestBase test)
      : super(
            binaryName: 'nnbd_migration',
            loggerFactory: (isVerbose) => test.logger = _TestLogger(isVerbose),
            defaultSdkPathOverride:
                test.resourceProvider.convertPath(mock_sdk.sdkRoot),
            resourceProvider: test.resourceProvider);

  @override
  Future<void> blockUntilSignalInterrupt() async {
    if (_runWhilePreviewServerActive == null) {
      fail('Preview server not expected to have been started');
    }
    await _runWhilePreviewServerActive.call();
    _runWhilePreviewServerActive = null;
  }

  Future<void> runWithPreviewServer(
      List<String> args, Future<void> callback()) async {
    _runWhilePreviewServerActive = callback;
    await run(args);
    if (_runWhilePreviewServerActive != null) {
      fail('Preview server never started');
    }
  }
}

abstract class _MigrationCliTestBase {
  void set logger(_TestLogger logger);

  MemoryResourceProvider get resourceProvider;
}

mixin _MigrationCliTestMethods on _MigrationCliTestBase {
  @override
  /*late*/ _TestLogger logger;

  final hasVerboseHelpMessage = contains('for verbose help output');

  final hasUsageText = contains('Usage: nnbd_migration');

  String assertErrorExit(MigrationCli cli, {bool withUsage = true}) {
    expect(cli.exitCode, isNotNull);
    expect(cli.exitCode, isNot(0));
    var stderrText = logger.stderrBuffer.toString();
    expect(stderrText, withUsage ? hasUsageText : isNot(hasUsageText));
    expect(stderrText,
        withUsage ? hasVerboseHelpMessage : isNot(hasVerboseHelpMessage));
    return stderrText;
  }

  Future<String> assertParseArgsFailure(List<String> args) async {
    var cli = _createCli();
    await cli.run(args);
    var stderrText = assertErrorExit(cli);
    expect(stderrText, isNot(contains('Exception')));
    return stderrText;
  }

  CommandLineOptions assertParseArgsSuccess(List<String> args) {
    var cli = _createCli();
    cli.parseCommandLineArgs(args);
    expect(cli.exitCode, isNull);
    var options = cli.options;
    return options;
  }

  Future assertPreviewServerResponsive(String url) async {
    var response = await http.get(url);
    expect(response.statusCode, 200);
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

  String createProjectDir(Map<String, String> contents) {
    var projectPathPosix = '/test_project';
    for (var entry in contents.entries) {
      var relativePathPosix = entry.key;
      assert(!path.posix.isAbsolute(relativePathPosix));
      var filePathPosix = path.posix.join(projectPathPosix, relativePathPosix);
      resourceProvider.newFile(
          resourceProvider.convertPath(filePathPosix), entry.value);
    }
    return resourceProvider.convertPath(projectPathPosix);
  }

  Future<void> runWithPreviewServer(_MigrationCli cli, List<String> args,
      Future<void> Function(String) callback) async {
    String url;
    await cli.runWithPreviewServer(args, () async {
      // Server should be running now
      url = RegExp('http://.*', multiLine: true)
          .stringMatch(logger.stdoutBuffer.toString());
      await callback(url);
    });
    // Server should be stopped now
    expect(http.get(url), throwsA(anything));
  }

  Map<String, String> simpleProject({bool migrated: false, String sourceText}) {
    return {
      'pubspec.yaml': '''
name: test
environment:
  sdk: '${migrated ? '>=2.9.0 <2.10.0' : '>=2.6.0 <3.0.0'}'
''',
      'lib/test.dart': sourceText ??
          '''
int${migrated ? '?' : ''} f() => null;
'''
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
    var projectDir = await createProjectDir(simpleProject());
    await cli.run([projectDir]);
    assertErrorExit(cli, withUsage: false);
    var output = logger.stdoutBuffer.toString();
    expect(
        output,
        contains(
            'Bad state: Analysis seems to have an SDK without NNBD enabled'));
  }

  test_flag_apply_changes_default() {
    expect(assertParseArgsSuccess([]).applyChanges, isFalse);
  }

  test_flag_apply_changes_disable() async {
    // "--no-apply-changes" is not an option.
    await assertParseArgsFailure(['--no-apply-changes']);
  }

  test_flag_apply_changes_enable() {
    expect(
        assertParseArgsSuccess(['--no-web-preview', '--apply-changes'])
            .applyChanges,
        isTrue);
  }

  test_flag_apply_changes_incompatible_with_web_preview() async {
    expect(await assertParseArgsFailure(['--web-preview', '--apply-changes']),
        contains('--apply-changes requires --no-web-preview'));
  }

  test_flag_help() async {
    var helpText = await _getHelpText(verbose: false);
    expect(helpText, hasUsageText);
    expect(helpText, hasVerboseHelpMessage);
  }

  test_flag_help_verbose() async {
    var helpText = await _getHelpText(verbose: true);
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

  test_flag_web_preview_default() {
    expect(assertParseArgsSuccess([]).webPreview, isTrue);
  }

  test_flag_web_preview_disable() {
    expect(assertParseArgsSuccess(['--no-web-preview']).webPreview, isFalse);
  }

  test_flag_web_preview_enable() {
    expect(assertParseArgsSuccess(['--web-preview']).webPreview, isTrue);
  }

  test_lifecycle_apply_changes() async {
    var projectContents = simpleProject();
    var projectDir = await createProjectDir(projectContents);
    var cli = _createCli();
    await cli.run(['--no-web-preview', '--apply-changes', projectDir]);
    // Check that a summary was printed
    expect(logger.stdoutBuffer.toString(), contains('Applying changes'));
    // And that it refers to test.dart and pubspec.yaml
    expect(logger.stdoutBuffer.toString(), contains('test.dart'));
    expect(logger.stdoutBuffer.toString(), contains('pubspec.yaml'));
    // And that it does not tell the user they can rerun with `--apply-changes`
    expect(logger.stdoutBuffer.toString(), isNot(contains('--apply-changes')));
    // Changes should have been made
    assertProjectContents(projectDir, simpleProject(migrated: true));
  }

  test_lifecycle_ignore_errors_disable() async {
    var projectContents = simpleProject(sourceText: '''
int f() => null
''');
    var projectDir = await createProjectDir(projectContents);
    var cli = _createCli();
    await cli.run([projectDir]);
    assertErrorExit(cli, withUsage: false);
    var output = logger.stdoutBuffer.toString();
    expect(output, contains('1 analysis issue found'));
    var sep = resourceProvider.pathContext.separator;
    expect(
        output,
        contains("error • Expected to find ';' at lib${sep}test.dart:1:12 • "
            "(expected_token)"));
    expect(
        output,
        contains(
            'analysis errors will result in erroneous migration suggestions'));
    expect(output, contains('Please fix the analysis issues'));
  }

  test_lifecycle_ignore_errors_enable() async {
    var projectContents = simpleProject(sourceText: '''
int? f() => null
''');
    var projectDir = await createProjectDir(projectContents);
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

  test_lifecycle_no_preview() async {
    var projectContents = simpleProject();
    var projectDir = await createProjectDir(projectContents);
    var cli = _createCli();
    await cli.run(['--no-web-preview', projectDir]);
    // Check that a summary was printed
    var output = logger.stdoutBuffer.toString();
    expect(output, contains('Summary'));
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

  test_lifecycle_preview() async {
    var projectContents = simpleProject();
    var projectDir = await createProjectDir(projectContents);
    var cli = _createCli();
    await runWithPreviewServer(cli, [projectDir], (url) async {
      expect(
          logger.stdoutBuffer.toString(), contains('No analysis issues found'));
      await assertPreviewServerResponsive(url);
    });
    // No changes should have been made.
    assertProjectContents(projectDir, projectContents);
  }

  test_lifecycle_preview_extra_forward_slash() async {
    var projectDir = await createProjectDir(simpleProject());
    var cli = _createCli();
    await runWithPreviewServer(cli, [projectDir], (url) async {
      var uri = Uri.parse(url);
      await assertPreviewServerResponsive(
          uri.replace(path: uri.path + '/').toString());
    });
  }

  test_lifecycle_summary() async {
    var projectContents = simpleProject();
    var projectDir = await createProjectDir(projectContents);
    var cli = _createCli();
    var summaryPath = resourceProvider.convertPath('/summary.json');
    await cli.run(['--no-web-preview', '--summary', summaryPath, projectDir]);
    var summaryData =
        jsonDecode(resourceProvider.getFile(summaryPath).readAsStringSync());
    expect(summaryData, TypeMatcher<Map>());
    expect(summaryData, contains('changes'));
  }

  test_lifecycle_summary_does_not_double_count_hint_removals() async {
    var projectContents = simpleProject(sourceText: 'int/*?*/ x;');
    var projectDir = await createProjectDir(projectContents);
    var cli = _createCli();
    var summaryPath = resourceProvider.convertPath('/summary.json');
    await cli.run(['--no-web-preview', '--summary', summaryPath, projectDir]);
    var summaryData =
        jsonDecode(resourceProvider.getFile(summaryPath).readAsStringSync());
    var separator = resourceProvider.pathContext.separator;
    expect(summaryData['changes']['byPath']['lib${separator}test.dart'],
        {'makeTypeNullableDueToHint': 1});
  }

  test_lifecycle_uri_error() async {
    var projectContents = simpleProject(sourceText: '''
import 'package:does_not/exist.dart';
int f() => null;
''');
    var projectDir = await createProjectDir(projectContents);
    var cli = _createCli();
    await cli.run([projectDir]);
    assertErrorExit(cli, withUsage: false);
    var output = logger.stdoutBuffer.toString();
    expect(output, contains('1 analysis issue found'));
    expect(output, contains('uri_does_not_exist'));
    expect(
        output,
        contains(
            'analysis errors will result in erroneous migration suggestions'));
    expect(output,
        contains('Unresolved URIs found.  Did you forget to run "pub get"?'));
    expect(output, contains('Please fix the analysis issues'));
  }

  test_migrate_path_none() {
    expect(assertParseArgsSuccess([]).directory, Directory.current.path);
  }

  test_migrate_path_one() {
    expect(assertParseArgsSuccess(['foo']).directory, 'foo');
  }

  test_migrate_path_two() async {
    var cli = _createCli();
    await cli.run(['foo', 'bar']);
    var stderrText = assertErrorExit(cli);
    expect(stderrText, contains('No more than one path may be specified'));
  }

  test_option_preview_port() {
    expect(
        assertParseArgsSuccess(['--preview-port', '4040']).previewPort, 4040);
  }

  test_option_preview_port_default() {
    expect(assertParseArgsSuccess([]).previewPort, isNull);
  }

  test_option_preview_port_format_error() async {
    expect(await assertParseArgsFailure(['--preview-port', 'abc']),
        contains('Invalid value for --preview-port'));
  }

  test_option_sdk() {
    var path = Uri.parse('file:///foo/bar/baz').toFilePath();
    expect(assertParseArgsSuccess(['--sdk-path', path]).sdkPath, same(path));
  }

  test_option_sdk_default() {
    var cli = MigrationCli(binaryName: 'nnbd_migration');
    cli.parseCommandLineArgs([]);
    expect(
        File(path.join(cli.options.sdkPath, 'version')).existsSync(), isTrue);
  }

  test_option_sdk_hidden() async {
    var optionName = '--sdk-path';
    expect(await _getHelpText(verbose: false), isNot(contains(optionName)));
    expect(await _getHelpText(verbose: true), contains(optionName));
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

  test_uses_physical_resource_provider_by_default() {
    var cli = MigrationCli(binaryName: 'nnbd_migration');
    expect(cli.resourceProvider, same(PhysicalResourceProvider.INSTANCE));
  }

  _MigrationCli _createCli() {
    mock_sdk.MockSdk(resourceProvider: resourceProvider);
    return _MigrationCli(this);
  }

  Future<String> _getHelpText({@required bool verbose}) async {
    var cli = _createCli();
    await cli
        .run(['--${CommandLineOptions.helpFlag}', if (verbose) '--verbose']);
    expect(cli.exitCode, 0);
    var helpText = logger.stderrBuffer.toString();
    return helpText;
  }
}

@reflectiveTest
class _MigrationCliTestPosix extends _MigrationCliTestBase
    with _MigrationCliTestMethods {
  @override
  final resourceProvider;

  _MigrationCliTestPosix()
      : resourceProvider = MemoryResourceProvider(
            context: path.style == path.Style.posix ? null : path.posix);
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
                : path.Context(style: path.Style.windows, current: 'C:\\'));
}

/// TODO(paulberry): move into cli_util
class _TestLogger implements Logger {
  final stderrBuffer = StringBuffer();

  final stdoutBuffer = StringBuffer();

  final bool isVerbose;

  _TestLogger(this.isVerbose);

  @override
  Ansi get ansi => Ansi(false);

  @override
  void flush() {
    throw UnimplementedError('TODO(paulberry)');
  }

  @override
  Progress progress(String message) {
    return SimpleProgress(this, message);
  }

  @override
  void stderr(String message) {
    stderrBuffer.writeln(message);
  }

  @override
  void stdout(String message) {
    stdoutBuffer.writeln(message);
  }

  @override
  void trace(String message) {
    throw UnimplementedError('TODO(paulberry)');
  }
}
