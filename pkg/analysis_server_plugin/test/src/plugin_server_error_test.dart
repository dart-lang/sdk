// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analysis_server_plugin/src/plugin_server.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as protocol;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'lint_rules.dart';
import 'plugin_server_test_base.dart';

void main() async {
  defineReflectiveTests(PluginServerErrorTest);
}

@reflectiveTest
class PluginServerErrorTest extends PluginServerTestBase {
  String get packagePath => convertPath('/package1');

  @override
  Future<void> setUp() async {
    await super.setUp();
    newAnalysisOptionsYamlFile(packagePath, '''
plugins:
  no_bools:
    path: some/path
    diagnostics:
      - no_bools
''');
  }

  Future<void> test_handleAnalysisSetContextRoots_throwingAsyncError() async {
    pluginServer = PluginServer(
      resourceProvider: resourceProvider,
      plugins: [_RuleThrowsAsyncErrorPlugin()],
    );
    await startPlugin();

    var filePath = join(packagePath, 'lib', 'test.dart');
    newFile(filePath, 'bool b = false;');
    var contextRoot = protocol.ContextRoot(packagePath, []);

    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));

    // Create a broadcast Stream of notifications, so that we can have multiple
    // StreamQueues listening.
    var notifications = channel.notifications.asBroadcastStream();
    var analysisErrorsParamsQueue = StreamQueue(notifications
        .map((n) => protocol.AnalysisErrorsParams.fromNotification(n))
        .where((p) => p.file == filePath));
    var analysisErrorsParams = await analysisErrorsParamsQueue.next;
    expect(analysisErrorsParams.errors, isEmpty);

    var pluginErrorParamsQueue = StreamQueue(notifications
        .map((n) => protocol.PluginErrorParams.fromNotification(n)));
    var pluginErrorParams = await pluginErrorParamsQueue.next;
    expect(pluginErrorParams.isFatal, false);
    expect(pluginErrorParams.message, 'Bad state: A message.');
    // TODO(srawlins): Does `StackTrace.toString()` not do what I think?
    expect(pluginErrorParams.stackTrace, '');
  }

  Future<void> test_handleAnalysisSetContextRoots_throwingSyncError() async {
    pluginServer = PluginServer(
      resourceProvider: resourceProvider,
      plugins: [_RuleThrowsSyncErrorPlugin()],
    );
    await startPlugin();

    var filePath = join(packagePath, 'lib', 'test.dart');
    newFile(filePath, 'bool b = false;');
    var contextRoot = protocol.ContextRoot(packagePath, []);

    var response = await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));

    expect(
      response.error,
      isA<protocol.RequestError>()
          .having((e) => e.message, 'message', 'Bad state: A message.')
          .having((e) => e.stackTrace, 'stackTrace', isNotNull),
    );
  }

  Future<void> test_handleEditGetFixes_throwingAsyncError() async {
    pluginServer = PluginServer(
      resourceProvider: resourceProvider,
      plugins: [_FixThrowsAsyncErrorPlugin()],
    );
    await startPlugin();

    var filePath = join(packagePath, 'lib', 'test.dart');
    newFile(filePath, 'bool b = false;');
    var contextRoot = protocol.ContextRoot(packagePath, []);

    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));
    await channel
        .sendRequest(protocol.EditGetFixesParams(filePath, 'bool b = '.length));

    // Create a broadcast Stream of notifications, so that we can have multiple
    // StreamQueues listening.
    var notifications = channel.notifications.asBroadcastStream();
    var analysisErrorsParamsQueue = StreamQueue(notifications
        .map((n) => protocol.AnalysisErrorsParams.fromNotification(n))
        .where((p) => p.file == filePath));
    var analysisErrorsParams = await analysisErrorsParamsQueue.next;
    expect(analysisErrorsParams.errors.single, isNotNull);

    var pluginErrorParamsQueue = StreamQueue(notifications
        .map((n) => protocol.PluginErrorParams.fromNotification(n)));
    var pluginErrorParams = await pluginErrorParamsQueue.next;
    expect(pluginErrorParams.isFatal, false);
    expect(pluginErrorParams.message, 'Bad state: A message.');
    // TODO(srawlins): Does `StackTrace.toString()` not do what I think?
    expect(pluginErrorParams.stackTrace, '');
  }

  Future<void> test_handleEditGetFixes_throwingSyncError() async {
    pluginServer = PluginServer(
      resourceProvider: resourceProvider,
      plugins: [_FixThrowsSyncErrorPlugin()],
    );
    await startPlugin();

    var filePath = join(packagePath, 'lib', 'test.dart');
    newFile(filePath, 'bool b = false;');
    var contextRoot = protocol.ContextRoot(packagePath, []);

    await channel
        .sendRequest(protocol.AnalysisSetContextRootsParams([contextRoot]));

    var response = await channel
        .sendRequest(protocol.EditGetFixesParams(filePath, 'bool b = '.length));
    expect(
      response.error,
      isA<protocol.RequestError>()
          .having((e) => e.message, 'message', 'Bad state: A message.')
          .having((e) => e.stackTrace, 'stackTrace', isNotNull),
    );
  }
}

class _FixThrowsAsyncErrorPlugin extends Plugin {
  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(NoBoolsRule());
    registry.registerFixForRule(NoBoolsRule.code, _ThrowsAsyncErrorFix.new);
  }
}

class _FixThrowsSyncErrorPlugin extends Plugin {
  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(NoBoolsRule());
    registry.registerFixForRule(NoBoolsRule.code, _ThrowsSyncErrorFix.new);
  }
}

class _RuleThrowsAsyncErrorPlugin extends Plugin {
  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(_ThrowsAsyncErrorRule());
  }
}

class _RuleThrowsSyncErrorPlugin extends Plugin {
  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(_ThrowsSyncErrorRule());
  }
}

/// A correction producer that throws an async error while computing a
/// correction.
class _ThrowsAsyncErrorFix extends ResolvedCorrectionProducer {
  _ThrowsAsyncErrorFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossFiles;

  @override
  FixKind get fixKind => FixKind('unused', 50, 'Unused');

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // Raise an async error that can only be caught by an error zone's `onError`
    // handler.
    // ignore: unawaited_futures
    Future<void>.error(StateError('A message.'));
  }
}

class _ThrowsAsyncErrorRule extends AnalysisRule {
  static const LintCode code = LintCode('no_bools', 'No bools message');

  _ThrowsAsyncErrorRule()
      : super(name: 'no_bools', description: 'No bools desc');

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _ThrowsAsyncErrorVisitor(this);
    registry.addBooleanLiteral(this, visitor);
  }
}

class _ThrowsAsyncErrorVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _ThrowsAsyncErrorVisitor(this.rule);

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    // Raise an async error that can only be caught by an error zone's `onError`
    // handler.
    // ignore: unawaited_futures
    Future<void>.error(StateError('A message.'));
  }
}

/// A correction producer that throws a sync error while computing a correction.
class _ThrowsSyncErrorFix extends ResolvedCorrectionProducer {
  _ThrowsSyncErrorFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossFiles;

  @override
  FixKind get fixKind => FixKind('unused', 50, 'Unused');

  @override
  Future<void> compute(ChangeBuilder builder) async {
    throw StateError('A message.');
  }
}

class _ThrowsSyncErrorRule extends AnalysisRule {
  static const LintCode code = LintCode('no_bools', 'No bools message');

  _ThrowsSyncErrorRule()
      : super(name: 'no_bools', description: 'No bools desc');

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _ThrowsSyncErrorVisitor(this);
    registry.addBooleanLiteral(this, visitor);
  }
}

class _ThrowsSyncErrorVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _ThrowsSyncErrorVisitor(this.rule);

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    throw StateError('A message.');
  }
}
