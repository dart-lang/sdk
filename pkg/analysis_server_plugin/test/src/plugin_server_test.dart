// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analysis_server_plugin/src/correction/ignore_diagnostic.dart';
import 'package:analysis_server_plugin/src/plugin_server.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'lint_rules.dart';
import 'plugin_server_test_base.dart';

void main() {
  defineReflectiveTests(PluginServerTest);
  defineReflectiveTests(PluginServerMapTest);
}

@reflectiveTest
class PluginServerMapTest extends PluginServerTestBase
    with PluginServerTestMixin {
  @override
  Future<void> setUp() async {
    await super.setUp();

    pluginServer = PluginServer.new2(
      resourceProvider: resourceProvider,
      plugins: {
        'other_plugin': _OtherPlugin(),
        'no_literals': _NoLiteralsPlugin(),
      },
    );
    await startPlugin();
  }

  void writeAnalysisOptionsWithPlugin({
    Map<String, String> diagnosticConfiguration = const {},
    StringBuffer? buffer,
  }) {
    buffer ??= StringBuffer();
    buffer.writeln();
    buffer.writeln('''
plugins:
  other_plugin:
    path: some/other/path
  no_literals:
    path: some/path
''');
    for (var MapEntry(key: diagnosticName, value: enablement)
        in diagnosticConfiguration.entries) {
      buffer.writeln('      $diagnosticName: $enablement');
    }
    newAnalysisOptionsYamlFile(packagePath, buffer.toString());
  }

  Future<void> test_excludedPaths() async {
    writeAnalysisOptionsWithPlugin(
      buffer: StringBuffer('''
analyzer:
  exclude:
    - lib/test.dart
'''),
    );
    var fileContent = 'bool b = false;';
    newFile(filePath, fileContent);
    newFile(file2Path, fileContent);
    await _setRoots();

    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;

    // It never sends the result for the excluded file. So we can skip it.

    expect(params.file, file2Path);
    expect(params.errors, hasLength(1));
  }

  Future<void> test_ignoreFixes() async {
    writeAnalysisOptionsWithPlugin();
    var fileContent = 'bool b = false;';
    newFile(filePath, fileContent);

    await _setContextRootsAndReadFirstErrors();

    var result = await pluginServer.handleEditGetFixes(
      protocol.EditGetFixesParams(filePath, 'bool b = '.length),
    );
    var fixes = result.fixes.single.fixes;
    for (var fix in fixes) {
      if (fix.change.id == ignoreErrorLineKind.id) {
        expect(
          fix.change.message,
          "Ignore 'no_literals/no_bools' for this line",
        );
        var resultCode = protocol.SourceEdit.applySequence(
          fileContent,
          fix.change.edits.first.edits,
        );
        expect(
          resultCode,
          normalizeNewlinesForPlatform('''
// ignore: no_literals/no_bools
bool b = false;'''),
        );
      } else if (fix.change.id == ignoreErrorFileKind.id) {
        expect(
          fix.change.message,
          "Ignore 'no_literals/no_bools' for the whole file",
        );
        var resultCode = protocol.SourceEdit.applySequence(
          fileContent,
          fix.change.edits.first.edits,
        );
        expect(
          resultCode,
          normalizeNewlinesForPlatform('''
// ignore_for_file: no_literals/no_bools

bool b = false;'''),
        );
      }
    }
  }

  Future<void> test_warningRulesCanBeDisabled() async {
    writeAnalysisOptionsWithPlugin(
      diagnosticConfiguration: {'no_bools': 'disable'},
    );
    newFile(filePath, 'bool b = false;');
    await _setRoots();
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);
  }

  Future<void> test_warningRulesCanBeDisabled_withOtherPlugins() async {
    newAnalysisOptionsYamlFile(packagePath, '''
plugins:
  no_literals:
    path: some/path
    diagnostics:
      no_bools: disable
  other_plugin:
    path: some/other/path
''');
    newFile(filePath, 'bool b = false;');
    await _setRoots();
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);
  }

  Future<void> test_warningsCanBeIgnored_incorrectPlugin() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, '''
// ignore: other_plugin/no_bools
bool b = false;
''');
    await _setRoots();
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
  }
}

@reflectiveTest
class PluginServerTest extends PluginServerTestBase with PluginServerTestMixin {
  late _NoLiteralsPlugin _plugin;

  @override
  Future<void> setUp() async {
    await super.setUp();

    _plugin = _NoLiteralsPlugin();
    pluginServer = PluginServer(
      resourceProvider: resourceProvider,
      plugins: [_plugin],
    );
    await startPlugin();
  }

  Future<void> test_diagnosticsCanBeIgnored() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, '''
// ignore: no_literals/no_bools
bool b = false;
''');
    await _setRoots();
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);
  }

  Future<void> test_diagnosticsCanBeIgnored_forFile() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, '''
bool b = false;

// ignore_for_file: no_literals/no_bools
''');
    await _setRoots();
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);
  }

  Future<void> test_handleAnalysisSetContextRoots() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');

    var notifications = channel.notifications.asBroadcastStream();
    var statusQueue = StreamQueue(
      notifications
          .where((n) => n.event == protocol.PLUGIN_NOTIFICATION_STATUS)
          .map((n) => protocol.PluginStatusParams.fromNotification(n)),
    );
    var paramsQueue = StreamQueue(
      notifications
          .where((n) => n.event == protocol.ANALYSIS_NOTIFICATION_ERRORS)
          .map((n) => protocol.AnalysisErrorsParams.fromNotification(n)),
    );

    var setRootsFuture = _setRoots();

    var status1 = await statusQueue.next;
    expect(status1.analysis!.isAnalyzing, isTrue);

    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');

    var status2 = await statusQueue.next;
    expect(status2.analysis!.isAnalyzing, isFalse);

    await setRootsFuture;
  }

  Future<void> test_handleAnalysisSetContextRoots_only() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');

    var notifications = channel.notifications.asBroadcastStream();
    var statusQueue = StreamQueue(
      notifications
          .where((n) => n.event == protocol.PLUGIN_NOTIFICATION_STATUS)
          .map((n) => protocol.PluginStatusParams.fromNotification(n)),
    );
    var paramsQueue = StreamQueue(
      notifications
          .where((n) => n.event == protocol.ANALYSIS_NOTIFICATION_ERRORS)
          .map((n) => protocol.AnalysisErrorsParams.fromNotification(n)),
    );

    // Rather than using `_setRoots`, this test emulates Dart Analysis Server
    // <= 3.12.0, where only `protocol.ANALYSIS_REQUEST_SET_CONTEXT_ROOTS` is
    // sent.
    var requestFuture = channel.sendRequest(
      protocol.AnalysisSetContextRootsParams([contextRoot]),
    );

    var status1 = await statusQueue.next;
    expect(status1.analysis!.isAnalyzing, isTrue);

    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');

    var status2 = await statusQueue.next;
    expect(status2.analysis!.isAnalyzing, isFalse);

    await requestFuture;
  }

  Future<void> test_handleEditGetAssists() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');

    await _setContextRootsAndReadFirstErrors();

    var result = await pluginServer.handleEditGetAssists(
      protocol.EditGetAssistsParams(
        filePath,
        'bool b = f'.length,
        3 /* length */,
      ),
    );
    var assists = result.assists;
    expect(assists, hasLength(1));
    var assist = assists.single;
    expect(assist.change.edits, hasLength(1));
  }

  Future<void> test_handleEditGetAssists_viaSendRequest() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');

    await _setContextRootsAndReadFirstErrors();

    var response = await channel.sendRequest(
      protocol.EditGetAssistsParams(filePath, 'bool b = '.length, 1),
    );
    var result = protocol.EditGetAssistsResult.fromResponse(response);
    expect(result.assists, hasLength(1));
  }

  Future<void> test_handleEditGetAssists_viaSendRequest_part() async {
    writeAnalysisOptionsWithPlugin();
    newFile(file2Path, 'part \'test.dart\';');
    var code = TestCode.parseNormalized('''
part of 'test2.dart';
bool b = [!false!];
''');
    newFile(filePath, code.code);

    await _setContextRootsAndReadFirstErrors();

    var range = code.range.sourceRange;
    var response = await channel.sendRequest(
      protocol.EditGetAssistsParams(filePath, range.offset, range.length),
    );
    var result = protocol.EditGetAssistsResult.fromResponse(response);
    expect(result.assists, hasLength(1));
  }

  Future<void> test_handleEditGetFixes() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');

    await _setContextRootsAndReadFirstErrors();

    var result = await pluginServer.handleEditGetFixes(
      protocol.EditGetFixesParams(filePath, 'bool b = '.length),
    );
    var fixes = result.fixes.single;
    // The WrapInQuotes fix plus three "ignore diagnostic" fixes.
    expect(fixes.fixes, hasLength(4));
  }

  Future<void> test_ignoreFixes() async {
    writeAnalysisOptionsWithPlugin();
    var fileContent = 'bool b = false;';
    newFile(filePath, fileContent);

    await _setContextRootsAndReadFirstErrors();

    var result = await pluginServer.handleEditGetFixes(
      protocol.EditGetFixesParams(filePath, 'bool b = '.length),
    );
    var fixes = result.fixes.single.fixes;
    for (var fix in fixes) {
      if (fix.change.id == ignoreErrorLineKind.id) {
        expect(fix.change.message, "Ignore 'no_bools' for this line");
        var resultCode = protocol.SourceEdit.applySequence(
          fileContent,
          fix.change.edits.first.edits,
        );
        expect(
          resultCode,
          normalizeNewlinesForPlatform('''
// ignore: no_bools
bool b = false;'''),
        );
      } else if (fix.change.id == ignoreErrorFileKind.id) {
        expect(fix.change.message, "Ignore 'no_bools' for the whole file");
        var resultCode = protocol.SourceEdit.applySequence(
          fileContent,
          fix.change.edits.first.edits,
        );
        expect(
          resultCode,
          normalizeNewlinesForPlatform('''
// ignore_for_file: no_bools

bool b = false;'''),
        );
      }
    }
  }

  Future<void> test_handleEditGetFixes_afterLine() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;\n\n');
    await _setRoots();

    var result = await pluginServer.handleEditGetFixes(
      protocol.EditGetFixesParams(filePath, 'bool b = false;\n'.length),
    );
    expect(result.fixes, isEmpty);
  }

  Future<void> test_handleEditGetFixes_onSameLine() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');

    await _setContextRootsAndReadFirstErrors();

    var result = await pluginServer.handleEditGetFixes(
      protocol.EditGetFixesParams(filePath, 'bool b = fa'.length),
    );
    var fixes = result.fixes.single;
    // The WrapInQuotes fix plus three "ignore diagnostic" fixes.
    expect(fixes.fixes, hasLength(4));
  }

  Future<void> test_handleEditGetFixes_viaSendRequest() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');

    await _setContextRootsAndReadFirstErrors();

    var response = await channel.sendRequest(
      protocol.EditGetFixesParams(filePath, 'bool b = '.length),
    );
    var result = protocol.EditGetFixesResult.fromResponse(response);
    expect(result.fixes.first.fixes, hasLength(4));
  }

  Future<void> test_handleEditGetFixes_viaSendRequest_part() async {
    writeAnalysisOptionsWithPlugin();
    newFile(file2Path, 'part \'test.dart\';');
    var code = TestCode.parseNormalized('''
part of 'test2.dart';
bool b = ^false;
''');
    newFile(filePath, code.code);

    await _setContextRootsAndReadFirstErrors();

    var response = await channel.sendRequest(
      protocol.EditGetFixesParams(filePath, code.position.offset),
    );
    var result = protocol.EditGetFixesResult.fromResponse(response);
    expect(result.fixes.first.fixes, hasLength(4));
  }

  Future<void> test_handleEditGetFixes_nonLintCode() async {
    writeAnalysisOptionsWithPlugin();
    var code = TestCode.parseNormalized('''
var n = ^10;
''');
    newFile(filePath, code.code);

    await _setContextRootsAndReadFirstErrors();

    var response = await channel.sendRequest(
      protocol.EditGetFixesParams(filePath, code.position.offset),
    );
    var result = protocol.EditGetFixesResult.fromResponse(response);
    expect(result.fixes.first.fixes, hasLength(4));
  }

  Future<void> test_handleEditGetFixes_multiFixInFile() async {
    writeAnalysisOptionsWithPlugin();
    var code = TestCode.parseNormalized('''
void f() {
  bool b1 = ^false;
  bool b2 = true;
  bool b3 = false;
}
''');
    newFile(filePath, code.code);

    await _setContextRootsAndReadFirstErrors();

    var response = await channel.sendRequest(
      protocol.EditGetFixesParams(filePath, code.position.offset),
    );
    var result = protocol.EditGetFixesResult.fromResponse(response);
    expect(result.fixes, isNotEmpty);
    var fixes = result.fixes.first.fixes;

    // Should have fixes available: both individual and multi-fix versions
    // plus 3 ignore fixes
    expect(fixes.length, greaterThanOrEqualTo(4));

    // Verify we have the multi-fix version available
    var multiFixMessages = fixes
        .map((f) => f.change.message)
        .where((msg) => msg.contains('everywhere'))
        .toList();
    expect(
      multiFixMessages.length,
      greaterThan(0),
      reason: 'Should have a multi-fix ("everywhere in file") option',
    );
  }

  Future<void> test_lintCodesCanHaveConfigurableSeverity() async {
    writeAnalysisOptionsWithPlugin({'no_doubles_custom_severity': 'error'});
    newFile(filePath, 'double x = 3.14;');
    await _setRoots();
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(
      params.errors.single,
      message: 'No doubles message',
      severity: protocol.AnalysisErrorSeverity.ERROR,
    );
  }

  Future<void> test_lintCodesCanHaveCustomSeverity() async {
    writeAnalysisOptionsWithPlugin({'no_doubles_custom_severity': 'enable'});
    newFile(filePath, 'double x = 3.14;');
    await _setRoots();
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(
      params.errors.single,
      message: 'No doubles message',
      severity: protocol.AnalysisErrorSeverity.WARNING,
    );
  }

  Future<void> test_lintRulesAreDisabledByDefault() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'double x = 3.14;');
    await _setRoots();
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);
  }

  Future<void> test_lintRulesCanBeEnabled() async {
    writeAnalysisOptionsWithPlugin({'no_doubles': 'enable'});
    newFile(filePath, 'double x = 3.14;');
    await _setRoots();
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No doubles message');
  }

  Future<void> test_partDiagnosticContextMessage() async {
    writeAnalysisOptionsWithPlugin({'no_type_annotations': 'enable'});
    newFile(file2Path, '''
part of 'test.dart';

class C {}
''');
    var code = TestCode.parseNormalized('''
part 'test2.dart';

C? c;
''');
    newFile(filePath, code.code);
    await _setRoots();
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1), reason: 'Expected one diagnostic.');
    var diagnostic = params.errors.single;
    _expectAnalysisError(diagnostic, message: 'No type annotations');
    expect(
      diagnostic.contextMessages,
      hasLength(1),
      reason: 'Expected one context message.',
    );
  }

  Future<void> test_pluginDetails() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');

    var response = await channel.sendRequest(protocol.PluginDetailsParams());

    var result = protocol.PluginDetailsResult.fromResponse(response);
    expect(result.plugins, hasLength(1));
    var details = result.plugins.single;
    expect(details.name, 'No Literals Plugin');
    expect(
      details.lintRules,
      unorderedEquals([
        'needs_package',
        'no_doubles',
        'no_doubles_custom_severity',
        'no_references_to_strings',
        'no_type_annotations',
      ]),
    );
    expect(
      details.warningRules,
      unorderedEquals(['no_bools', 'no_integer_10']),
    );
    expect(details.fixes, hasLength(1));
    var fix = details.fixes.single;
    expect(fix.codes, ['no_bools', 'no_integer_10']);
    expect(fix.id, 'dart.fix.wrapInQuotes');
    expect(fix.message, 'Wrap in quotes');
    expect(details.assists, hasLength(1));
    var assist = details.assists.single;
    expect(assist.id, 'dart.fix.invertBoolean');
    expect(assist.message, 'Invert Boolean value');
  }

  Future<void> test_rulesHaveAccessToPackage() async {
    writeAnalysisOptionsWithPlugin({'needs_package': 'enable'});
    newFile(filePath, 'var x = 1;');
    newFile(testFilePath, 'var x = 1;');
    await _setRoots();
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.file, filePath);
    expect(params.errors, hasLength(1));
    _expectAnalysisError(
      params.errors.single,
      message: 'Needs Package at "$packagePath"',
    );

    params = await paramsQueue.next;
    expect(params.file, testFilePath);
    expect(params.errors, isEmpty);
  }

  Future<void> test_setPriorityFiles() async {
    newFile(filePath, '''
int a = 0;
''');
    newFile(file2Path, '''
int b = 1;
''');
    await _setRoots();

    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.file, filePath);

    params = await paramsQueue.next;
    expect(params.file, file2Path);

    await channel.sendRequest(
      protocol.AnalysisSetPriorityFilesParams([file2Path]),
    );

    expect(pluginServer.priorityPaths, {file2Path});

    await _setRoots();

    params = await paramsQueue.next;
    expect(params.file, file2Path);

    params = await paramsQueue.next;
    expect(params.file, filePath);
  }

  Future<void> test_shutdown() async {
    expect(_plugin.isShutdown, isFalse);
    await channel.sendRequest(protocol.PluginShutdownParams());
    expect(_plugin.isShutdown, isTrue);
  }

  Future<void> test_unsupportedRequest() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');

    await _setRoots();

    // This request is unsupported.
    var response = await channel.sendRequest(
      protocol.CompletionGetSuggestionsParams(filePath, 0 /* offset */),
    );

    expect(response.error?.code, RequestErrorCode.UNKNOWN_REQUEST);
  }

  Future<void> test_updateContent_addOverlay() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'int b = 7;');
    await _setRoots();

    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);

    await channel.sendRequest(
      protocol.AnalysisUpdateContentParams({
        filePath: protocol.AddContentOverlay('bool b = false;'),
      }),
    );

    params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');
  }

  Future<void> test_updateContent_addOverlay_identicalContent() async {
    // This test does not use `_analysisErrorsParams`, as it needs to assert
    // that no more AnalysisErrors notifications are sent after a subscription
    // is cancelled. This requires a different tactic from the conveniant
    // StreamQueue, using a lower-level StreamSubscription on
    // `channel.notifications`.

    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'int b = 7;');

    var notifications = <protocol.Notification>[];
    var subscription = channel.notifications.listen(notifications.add);

    await _setRoots();

    // Wait for initial analysis result.
    await pluginServer.waitForIdle();

    var errorNotifications = notifications
        .where((n) => n.event == protocol.ANALYSIS_NOTIFICATION_ERRORS)
        .toList();
    expect(errorNotifications, hasLength(1));
    notifications.clear(); // Clear for the next step.

    // Add overlay with identical content.
    await channel.sendRequest(
      protocol.AnalysisUpdateContentParams({
        filePath: protocol.AddContentOverlay('int b = 7;'),
      }),
    );

    await subscription.cancel();

    errorNotifications = notifications
        .where((n) => n.event == protocol.ANALYSIS_NOTIFICATION_ERRORS)
        .toList();
    expect(errorNotifications, isEmpty);
  }

  Future<void> test_updateContent_addOverlay_affectedLibrary() async {
    writeAnalysisOptionsWithPlugin({'no_references_to_strings': 'enable'});
    newFile(filePath, '''
int s = 7;
void f() {
  print(s);
}
''');
    newFile(file2Path, '''
import 'test.dart';
void f() {
  print(s);
}
''');
    var paramsQueue = _analysisErrorsParams;
    await _setRoots();

    var params = await paramsQueue.next; // test.dart
    expect(params.errors, isEmpty);
    params = await paramsQueue.next; // test2.dart
    expect(params.errors, isEmpty);

    await channel.sendRequest(
      protocol.AnalysisUpdateContentParams({
        filePath: protocol.AddContentOverlay('''
String s = "hello";
'''),
      }),
    );

    params = await paramsQueue.next; // test.dart
    params = await paramsQueue.next; // test2.dart
    expect(params.errors, hasLength(1));
    expect(params.file, file2Path);
    _expectAnalysisError(
      params.errors.single,
      message: 'No references to Strings',
    );
  }

  Future<void> test_updateContent_addOverlay_affectedPart() async {
    writeAnalysisOptionsWithPlugin({'no_references_to_strings': 'enable'});
    newFile(filePath, '''
part 'test2.dart';
int s = 7;
''');
    newFile(file2Path, '''
part of 'test.dart';
void f() {
  print(s);
}
''');
    await _setRoots();

    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next; // test.dart
    expect(params.errors, isEmpty);
    params = await paramsQueue.next; // test2.dart
    expect(params.errors, isEmpty);

    await channel.sendRequest(
      protocol.AnalysisUpdateContentParams({
        filePath: protocol.AddContentOverlay('''
part 'test2.dart';
String s = "hello";
'''),
      }),
    );

    params = await paramsQueue.next;
    expect(params.errors, isEmpty);
    expect(params.file, filePath);

    params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    expect(params.file, file2Path);
    _expectAnalysisError(
      params.errors.single,
      message: 'No references to Strings',
    );
  }

  Future<void> test_updateContent_changeOverlay() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'int b = 7;');
    var paramsQueue = _analysisErrorsParams;
    await _setRoots();

    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);

    await channel.sendRequest(
      protocol.AnalysisUpdateContentParams({
        filePath: protocol.AddContentOverlay('int b = 0;'),
      }),
    );

    params = await paramsQueue.next;
    expect(params.errors, isEmpty);

    await channel.sendRequest(
      protocol.AnalysisUpdateContentParams({
        filePath: protocol.ChangeContentOverlay([
          protocol.SourceEdit(0, 9, 'bool b = false'),
        ]),
      }),
    );

    params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');
  }

  Future<void> test_updateContent_removeOverlay() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');
    var paramsQueue = _analysisErrorsParams;
    await _setRoots();

    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');

    await channel.sendRequest(
      protocol.AnalysisUpdateContentParams({
        filePath: protocol.AddContentOverlay('int b = 7;'),
      }),
    );

    params = await paramsQueue.next;
    expect(params.errors, isEmpty);

    await channel.sendRequest(
      protocol.AnalysisUpdateContentParams({
        filePath: protocol.RemoveContentOverlay(),
      }),
    );

    params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');
  }

  Future<void> test_warningRulesAreEnabledByDefault() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');
    await _setRoots();
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');
  }

  Future<void> test_warningRulesCanBeDisabled() async {
    writeAnalysisOptionsWithPlugin({'no_bools': 'disable'});
    newFile(filePath, 'bool b = false;');
    await _setRoots();
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);
  }

  Future<void> test_watchEvent_add() async {
    writeAnalysisOptionsWithPlugin();
    await _setRoots();

    var paramsQueue = _analysisErrorsParams;

    newFile(filePath, 'bool b = false;');

    await channel.sendRequest(
      protocol.AnalysisHandleWatchEventsParams([
        WatchEvent(WatchEventType.ADD, filePath),
      ]),
    );

    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');
  }

  Future<void> test_watchEvent_modify() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'int b = 7;');
    await _setRoots();

    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);

    newFile(filePath, 'bool b = false;');

    await channel.sendRequest(
      protocol.AnalysisHandleWatchEventsParams([
        WatchEvent(WatchEventType.MODIFY, filePath),
      ]),
    );

    params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');
  }

  Future<void> test_watchEvent_remove() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'int b = 7;');
    await _setRoots();

    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);

    deleteFile(filePath);

    await channel.sendRequest(
      protocol.AnalysisHandleWatchEventsParams([
        WatchEvent(WatchEventType.REMOVE, filePath),
      ]),
    );

    params = await paramsQueue.next;
    expect(params.errors, isEmpty);
  }

  void writeAnalysisOptionsWithPlugin([
    Map<String, String> diagnosticConfiguration = const {},
  ]) {
    var buffer = StringBuffer('''
plugins:
  no_literals:
    path: some/path
    diagnostics:
''');
    for (var MapEntry(key: diagnosticName, value: enablement)
        in diagnosticConfiguration.entries) {
      buffer.writeln('      $diagnosticName: $enablement');
    }
    newAnalysisOptionsYamlFile(packagePath, buffer.toString());
  }

  void _expectAnalysisError(
    protocol.AnalysisError error, {
    required String message,
    protocol.AnalysisErrorSeverity severity =
        protocol.AnalysisErrorSeverity.INFO,
  }) {
    expect(
      error,
      isA<protocol.AnalysisError>()
          .having((e) => e.severity, 'severity', severity)
          .having(
            (e) => e.type,
            'type',
            protocol.AnalysisErrorType.STATIC_WARNING,
          )
          .having((e) => e.message, 'message', message),
    );
  }
}

mixin PluginServerTestMixin on PluginServerTestBase {
  protocol.ContextRoot get contextRoot => protocol.ContextRoot(packagePath, []);

  Future<void> _setContextRootsAndReadFirstErrors() async {
    var paramsQueue = _analysisErrorsParams;
    await _setRoots();

    // Read the analysis errors.
    await paramsQueue.next;
  }

  String get file2Path => join(packagePath, 'lib', 'test2.dart');

  String get filePath => join(packagePath, 'lib', 'test.dart');

  String get packagePath => convertPath('/package1');

  String get testFilePath => join(packagePath, 'test', 'test.dart');

  StreamQueue<protocol.AnalysisErrorsParams> get _analysisErrorsParams {
    return StreamQueue(
      channel.notifications
          .where((n) => n.event == protocol.ANALYSIS_NOTIFICATION_ERRORS)
          .map((n) => protocol.AnalysisErrorsParams.fromNotification(n))
          .where(
            (p) =>
                p.file == filePath ||
                p.file == file2Path ||
                p.file == testFilePath,
          ),
    );
  }

  Future<void> _setRoots() async {
    var future1 = channel.sendRequest(
      protocol.AnalysisSetContextRootsParams([contextRoot]),
    );
    var future2 = channel.sendRequest(
      protocol.AnalysisSetAnalysisRootsParams([contextRoot.root], []),
    );
    await Future.wait([future1, future2]);
  }
}

class _InvertBoolean extends ResolvedCorrectionProducer {
  static const _invertBooleanKind = AssistKind(
    'dart.fix.invertBoolean',
    50,
    'Invert Boolean value',
  );

  _InvertBoolean({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => _invertBooleanKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node case BooleanLiteral(:var value)) {
      await builder.addDartFileEdit(file, (builder) {
        var invertedValue = (!value).toString();
        builder.addSimpleReplacement(range.node(node), invertedValue);
      });
    }
  }
}

class _NoLiteralsPlugin extends Plugin {
  bool isShutdown = false;

  @override
  String get name => 'No Literals Plugin';

  @override
  void register(PluginRegistry registry) {
    registry.registerLintRule(NeedsPackageRule());
    registry.registerWarningRule(NoBoolsRule());
    registry.registerWarningRule(NoInteger10Rule());
    registry.registerLintRule(NoDoublesRule());
    registry.registerLintRule(NoDoublesCustomSeverityRule());
    registry.registerLintRule(NoReferencesToStringsRule());
    registry.registerLintRule(NoTypeAnnotationsRule());
    registry.registerFixForRule(NoBoolsRule.code, _WrapInQuotes.new);
    registry.registerFixForRule(NoInteger10Rule.code, _WrapInQuotes.new);
    registry.registerAssist(_InvertBoolean.new);
  }

  @override
  Future<void> shutDown() async {
    isShutdown = true;
  }
}

class _OtherPlugin extends Plugin {
  @override
  String get name => 'Other Plugin';

  @override
  void register(PluginRegistry registry) {
    // No-op.
  }
}

class _WrapInQuotes extends ResolvedCorrectionProducer {
  static const _wrapInQuotesKind = FixKind(
    'dart.fix.wrapInQuotes',
    50,
    'Wrap in quotes',
  );

  static const _wrapInQuotesAllKind = FixKind(
    'dart.fix.wrapInQuotes.multi',
    10,
    'Wrap in quotes everywhere in file',
  );

  _WrapInQuotes({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossFiles;

  @override
  FixKind get fixKind => _wrapInQuotesKind;

  @override
  FixKind? get multiFixKind => _wrapInQuotesAllKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var literal = node;
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(literal.offset, "'");
      builder.addSimpleInsertion(literal.end, "'");
    });
  }
}
