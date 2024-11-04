// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analysis_server_plugin/src/plugin_server.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as protocol;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'lint_rules.dart';
import 'plugin_server_test_base.dart';

void main() async {
  defineReflectiveTests(PluginServerTest);
}

@reflectiveTest
class PluginServerTest extends PluginServerTestBase {
  protocol.ContextRoot get contextRoot => protocol.ContextRoot(packagePath, []);

  String get filePath => join(packagePath, 'lib', 'test.dart');

  String get packagePath => convertPath('/package1');

  @override
  Future<void> setUp() async {
    await super.setUp();

    pluginServer = PluginServer(
        resourceProvider: resourceProvider, plugins: [_NoLiteralsPlugin()]);
    await startPlugin();
  }

  Future<void> test_handleAnalysisSetContextRoots() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));
    var paramsQueue = StreamQueue(channel.notifications
        .map((n) => protocol.AnalysisErrorsParams.fromNotification(n))
        .where((p) => p.file == filePath));
    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');
  }

  Future<void> test_handleEditGetFixes() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));

    var result = await pluginServer.handleEditGetFixes(
        protocol.EditGetFixesParams(filePath, 'bool b = '.length));
    var fixes = result.fixes;
    // We expect 1 fix because neither `IgnoreDiagnosticOnLine` nor
    // `IgnoreDiagnosticInFile` are registered by the plugin.
    // TODO(srawlins): Investigate whether they should be.
    expect(fixes, hasLength(1));
    expect(fixes[0].fixes, hasLength(1));
  }

  Future<void> test_lintDiagnosticsAreDisabledByDefault() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'double x = 3.14;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));
    var paramsQueue = StreamQueue(channel.notifications
        .map((n) => protocol.AnalysisErrorsParams.fromNotification(n))
        .where((p) => p.file == filePath));
    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);
  }

  Future<void> test_lintDiagnosticsCanBeEnabled() async {
    writeAnalysisOptionsWithPlugin({'no_doubles': true});
    newFile(filePath, 'double x = 3.14;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));
    var paramsQueue = StreamQueue(channel.notifications
        .map((n) => protocol.AnalysisErrorsParams.fromNotification(n))
        .where((p) => p.file == filePath));
    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No doubles message');
  }

  Future<void> test_updateContent_addOverlay() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'int b = 7;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));

    var paramsQueue = StreamQueue(channel.notifications
        .map((n) => protocol.AnalysisErrorsParams.fromNotification(n))
        .where((p) => p.file == filePath));
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

    var paramsQueue = StreamQueue(channel.notifications
        .map((n) => protocol.AnalysisErrorsParams.fromNotification(n))
        .where((p) => p.file == filePath));
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

    var paramsQueue = StreamQueue(channel.notifications
        .map((n) => protocol.AnalysisErrorsParams.fromNotification(n))
        .where((p) => p.file == filePath));
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

  Future<void> test_warningDiagnosticsAreEnabledByDefault() async {
    writeAnalysisOptionsWithPlugin();
    newFile(filePath, 'bool b = false;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));
    var paramsQueue = StreamQueue(channel.notifications
        .map((n) => protocol.AnalysisErrorsParams.fromNotification(n))
        .where((p) => p.file == filePath));
    var params = await paramsQueue.next;
    expect(params.errors, hasLength(1));
    _expectAnalysisError(params.errors.single, message: 'No bools message');
  }

  Future<void> test_warningDiagnosticsCanBeDisabled() async {
    writeAnalysisOptionsWithPlugin({'no_bools': false});
    newFile(filePath, 'bool b = false;');
    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));
    var paramsQueue = StreamQueue(channel.notifications
        .map((n) => protocol.AnalysisErrorsParams.fromNotification(n))
        .where((p) => p.file == filePath));
    var params = await paramsQueue.next;
    expect(params.errors, isEmpty);
  }

  void writeAnalysisOptionsWithPlugin(
      [Map<String, bool> diagnosticConfiguration = const {}]) {
    var buffer = StringBuffer('''
plugins:
  no_literals:
    diagnostics:
''');
    for (var MapEntry(key: diagnosticName, value: isEnabled)
        in diagnosticConfiguration.entries) {
      buffer.writeln('      $diagnosticName: $isEnabled');
    }
    newAnalysisOptionsYamlFile(packagePath, buffer.toString());
  }

  void _expectAnalysisError(protocol.AnalysisError error,
      {required String message}) {
    expect(
      error,
      isA<protocol.AnalysisError>()
          .having((e) => e.severity, 'severity',
              protocol.AnalysisErrorSeverity.INFO)
          .having(
              (e) => e.type, 'type', protocol.AnalysisErrorType.STATIC_WARNING)
          .having((e) => e.message, 'message', message),
    );
  }
}

class _NoLiteralsPlugin extends Plugin {
  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(NoBoolsRule());
    registry.registerLintRule(NoDoublesRule());
    registry.registerFixForRule(NoBoolsRule.code, _WrapInQuotes.new);
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
