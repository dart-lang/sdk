// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

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
    defineReflectiveTests(_MigrationCliTest);
  });
}

class _MigrationCli extends MigrationCli {
  Completer<void> _previewServerStartedCompleter;

  Completer<void> _signalInterruptCompleter;

  _MigrationCli(_MigrationCliTest test)
      : super(
            binaryName: 'nnbd_migration',
            loggerFactory: (isVerbose) => test.logger = _TestLogger(isVerbose),
            defaultSdkPathOverride: mock_sdk.sdkRoot,
            resourceProvider: test.resourceProvider);

  @override
  Future<void> blockUntilSignalInterrupt() {
    _previewServerStartedCompleter.complete();
    _signalInterruptCompleter = Completer<void>();
    return _signalInterruptCompleter.future;
  }

  Future<void> runWithPreviewServer(
      List<String> args, Future<void> callback()) async {
    _previewServerStartedCompleter = Completer<void>();
    var done = run(args);
    await _previewServerStartedCompleter.future;
    await callback();
    _signalInterruptCompleter.complete();
    return done;
  }
}

@reflectiveTest
class _MigrationCliTest {
  /*late*/ _TestLogger logger;

  final hasVerboseHelpMessage = contains('for verbose help output');

  final hasUsageText = contains('Usage: nnbd_migration');

  final resourceProvider = MemoryResourceProvider();

  String assertErrorExit(MigrationCli cli) {
    expect(cli.exitCode, isNotNull);
    expect(cli.exitCode, isNot(0));
    var stderrText = logger.stderrBuffer.toString();
    expect(stderrText, hasUsageText);
    expect(stderrText, hasVerboseHelpMessage);
    return stderrText;
  }

  CommandLineOptions assertParseArgsSuccess(List<String> args) {
    var cli = _createCli();
    cli.parseCommandLineArgs(args);
    expect(cli.exitCode, isNull);
    var options = cli.options;
    return options;
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

  Map<String, String> simpleProject() {
    return {
      'pubspec.yaml': '''
name: test
environment:
sdk: '>=2.6.0 <3.0.0'
''',
      'lib/test.dart': '''
int f() => null;
'''
    };
  }

  test_default_logger() {
    // When running normally, we don't override the logger; make sure it has a
    // non-null default so that there won't be a crash.
    expect(MigrationCli(binaryName: 'nnbd_migration').logger, isNotNull);
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

  test_flag_web_preview_default() {
    expect(assertParseArgsSuccess([]).webPreview, isTrue);
  }

  test_flag_web_preview_disable() {
    expect(assertParseArgsSuccess(['--no-web-preview']).webPreview, isFalse);
  }

  test_flag_web_preview_enable() {
    expect(assertParseArgsSuccess(['--web-preview']).webPreview, isTrue);
  }

  test_lifecycle_no_preview() async {
    var projectContents = simpleProject();
    var projectDir = await createProjectDir(projectContents);
    var cli = _createCli();
    await cli.run(['--no-web-preview', projectDir]);
    // Check that a summary was printed
    expect(logger.stdoutBuffer.toString(), contains('Summary'));
    // And that it refers to test.dart
    expect(logger.stdoutBuffer.toString(), contains('test.dart'));
    // And that it tells the user they can rerun with `--apply-changes`
    expect(logger.stdoutBuffer.toString(), contains('--apply-changes'));
    // No changes should have been made
    assertProjectContents(projectDir, projectContents);
  }

  test_lifecycle_preview() async {
    var projectContents = simpleProject();
    var projectDir = await createProjectDir(projectContents);
    var cli = _createCli();
    String url;
    await cli.runWithPreviewServer([projectDir], () async {
      // Server should be running now
      url = RegExp('http://.*', multiLine: true)
          .stringMatch(logger.stdoutBuffer.toString());
      var response = await http.get(url);
      expect(response.statusCode, 200);
    });
    // Server should be stopped now
    expect(http.get(url), throwsA(anything));
    // And no changes should have been made.
    assertProjectContents(projectDir, projectContents);
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

  test_option_preview_port_format_error() {
    var cli = _createCli();
    cli.parseCommandLineArgs(['--preview-port', 'abc']);
    var stderrText = assertErrorExit(cli);
    expect(stderrText, contains('Invalid value for --preview-port'));
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

  test_option_unrecognized() async {
    var cli = _createCli();
    await cli.run(['--this-option-does-not-exist']);
    var stderrText = assertErrorExit(cli);
    expect(
        stderrText,
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
