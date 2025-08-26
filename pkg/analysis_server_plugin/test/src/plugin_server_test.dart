// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analysis_server_plugin/src/plugin_server.dart';
import 'package:analyzer/dart/ast/ast.dart';
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
}

@reflectiveTest
class PluginServerTest extends PluginServerTestBase {
  protocol.ContextRoot get contextRoot => protocol.ContextRoot(packagePath, []);

  String get filePath => join(packagePath, 'lib', 'test.dart');

  String get packagePath => convertPath('/package1');

  StreamQueue<protocol.AnalysisErrorsParams> get _analysisErrorsParams {
    return StreamQueue(channel.notifications
        .where((n) => n.event == protocol.ANALYSIS_NOTIFICATION_ERRORS)
        .map((n) => protocol.AnalysisErrorsParams.fromNotification(n))
        .where((p) => p.file == filePath));
  }

  @override
  Future<void> setUp() async {
    await super.setUp();

    pluginServer = PluginServer(
        resourceProvider: resourceProvider, plugins: [_NoLiteralsPlugin()]);
    await startPlugin();
  }

  Future<void> test_diagnosticsCanBeIgnored() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, '''
// ignore: no_literals/no_bools
bool b = false;
''');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));
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
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);
  }

  Future<void> test_handleAnalysisSetContextRoots() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');
  }

  Future<void> test_handleEditGetAssists() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));

    var result = await pluginServer.handleEditGetAssists(
      protocol.EditGetAssistsParams(
          filePath, 'bool b = f'.length, 3 /* length */),
    );
    var assists = result.assists;
    expect(assists, hasLength(1));
    var assist = assists.single;
    expect(assist.change.edits, hasLength(1));
  }

  Future<void> test_handleEditGetAssists_viaSendRequest() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');

    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));

    var response = await channel.sendRequest(
        protocol.EditGetAssistsParams(filePath, 'bool b = '.length, 1));
    var result = protocol.EditGetAssistsResult.fromResponse(response);
    expect(result.assists, hasLength(1));
  }

  Future<void> test_handleEditGetFixes() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));

    var result = await pluginServer.handleEditGetFixes(
        protocol.EditGetFixesParams(filePath, 'bool b = '.length));
    var fixes = result.fixes.single;
    // The WrapInQuotes fix plus three "ignore diagnostic" fixes.
    expect(fixes.fixes, hasLength(4));
  }

  Future<void> test_handleEditGetFixes_viaSendRequest() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');

    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));

    var response = await channel
        .sendRequest(protocol.EditGetFixesParams(filePath, 'bool b = '.length));
    var result = protocol.EditGetFixesResult.fromResponse(response);
    expect(result.fixes.first.fixes, hasLength(4));
  }

  Future<void> test_lintCodesCanHaveCustomSeverity() async {
    writeAnalysisOptionsWithPlugin({'no_doubles_warning': 'enable'});
    newFile(filePath, 'double x = 3.14;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(
      params.errors.single,
      message: 'No doubles message',
      severity: protocol.AnalysisErrorSeverity.WARNING,
    );
  }

  Future<void> test_lintCodesCanHaveConfigurableSeverity() async {
    writeAnalysisOptionsWithPlugin({'no_doubles_warning': 'error'});
    newFile(filePath, 'double x = 3.14;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(
      params.errors.single,
      message: 'No doubles message',
      severity: protocol.AnalysisErrorSeverity.ERROR,
    );
  }

  Future<void> test_lintRulesAreDisabledByDefault() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'double x = 3.14;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);
  }

  Future<void> test_lintRulesCanBeEnabled() async {
    writeAnalysisOptionsWithPlugin({'no_doubles': 'enable'});
    newFile(filePath, 'double x = 3.14;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No doubles message');
  }

  Future<void> test_unsupportedRequest() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');

    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));

    // This request is unsupported.
    var response = await channel.sendRequest(
        protocol.CompletionGetSuggestionsParams(filePath, 0 /* offset */));

    expect(response.error?.code, RequestErrorCode.UNKNOWN_REQUEST);
  }

  Future<void> test_updateContent_addOverlay() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'int b = 7;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));

    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);

    await channel.sendRequest(protocol.AnalysisUpdateContentParams(
        {filePath: protocol.AddContentOverlay('bool b = false;')}));

    params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');
  }

  Future<void> test_updateContent_changeOverlay() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'int b = 7;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));

    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);

    await channel.sendRequest(protocol.AnalysisUpdateContentParams(
        {filePath: protocol.AddContentOverlay('int b = 0;')}));

    params = await paramsQueue.next;
    expect(params.errors, isEmpty);

    await channel.sendRequest(protocol.AnalysisUpdateContentParams({
      filePath: protocol.ChangeContentOverlay(
          [protocol.SourceEdit(0, 9, 'bool b = false')])
    }));

    params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');
  }

  Future<void> test_updateContent_removeOverlay() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));

    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');

    await channel.sendRequest(protocol.AnalysisUpdateContentParams(
        {filePath: protocol.AddContentOverlay('int b = 7;')}));

    params = await paramsQueue.next;
    expect(params.errors, isEmpty);

    await channel.sendRequest(protocol.AnalysisUpdateContentParams(
        {filePath: protocol.RemoveContentOverlay()}));

    params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');
  }

  Future<void> test_warningRulesAreEnabledByDefault() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');
  }

  Future<void> test_warningRulesCanBeDisabled() async {
    writeAnalysisOptionsWithPlugin({'no_bools': 'disable'});
    newFile(filePath, 'bool b = false;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));
    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);
  }

  Future<void> test_watchEvent_add() async {
    writeAnalysisOptionsWithPlugin();
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));

    var paramsQueue = _analysisErrorsParams;

    newFile(filePath, 'bool b = false;');

    await channel.sendRequest(protocol.AnalysisHandleWatchEventsParams(
        [WatchEvent(WatchEventType.ADD, filePath)]));

    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');
  }

  Future<void> test_watchEvent_modify() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'int b = 7;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));

    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);

    newFile(filePath, 'bool b = false;');

    await channel.sendRequest(protocol.AnalysisHandleWatchEventsParams(
        [WatchEvent(WatchEventType.MODIFY, filePath)]));

    params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');
  }

  Future<void> test_watchEvent_remove() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'int b = 7;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));

    var paramsQueue = _analysisErrorsParams;
    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);

    deleteFile(filePath);

    await channel.sendRequest(protocol.AnalysisHandleWatchEventsParams(
        [WatchEvent(WatchEventType.REMOVE, filePath)]));

    params = await paramsQueue.next;
    expect(params.errors, isEmpty);
  }

  void writeAnalysisOptionsWithPlugin(
      [Map<String, String> diagnosticConfiguration = const {}]) {
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
              (e) => e.type, 'type', protocol.AnalysisErrorType.STATIC_WARNING)
          .having((e) => e.message, 'message', message),
    );
  }
}

class _InvertBoolean extends ResolvedCorrectionProducer {
  static const _invertBooleanKind =
      AssistKind('dart.fix.invertBooelan', 50, 'Invert Boolean value');

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
  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(NoBoolsRule());
    registry.registerLintRule(NoDoublesRule());
    registry.registerLintRule(NoDoublesWarningRule());
    registry.registerFixForRule(NoBoolsRule.code, _WrapInQuotes.new);
    registry.registerAssist(_InvertBoolean.new);
  }
}

class _WrapInQuotes extends ResolvedCorrectionProducer {
  static const _wrapInQuotesKind =
      FixKind('dart.fix.wrapInQuotes', 50, 'Wrap in quotes');

  _WrapInQuotes({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossFiles;

  @override
  FixKind get fixKind => _wrapInQuotesKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var literal = node;
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(literal.offset, "'");
      builder.addSimpleInsertion(literal.end, "'");
    });
  }
}
