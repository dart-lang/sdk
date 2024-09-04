// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analysis_server_plugin/src/plugin_server.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as protocol;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() async {
  defineReflectiveTests(PluginServerTest);
}

@reflectiveTest
class PluginServerTest with ResourceProviderMixin {
  final channel = _FakeChannel();

  late final PluginServer pluginServer;

  Folder get byteStoreRoot => getFolder('/byteStore');

  Folder get sdkRoot => getFolder('/sdk');

  Future<void> setUp() async {
    createMockSdk(resourceProvider: resourceProvider, root: sdkRoot);

    pluginServer = PluginServer(
      resourceProvider: resourceProvider,
      plugins: [_NoBoolsPlugin()],
    );
    await pluginServer.initialize();
    pluginServer.start(channel);

    await pluginServer.handlePluginVersionCheck(
      protocol.PluginVersionCheckParams(
        byteStoreRoot.path,
        sdkRoot.path,
        '0.0.1',
      ),
    );
  }

  void tearDown() => registeredFixGenerators.clearLintProducers();

  Future<void> test_handleAnalysisSetContextRoots() async {
    var packagePath = convertPath('/package1');
    var filePath = join(packagePath, 'lib', 'test.dart');
    newFile(filePath, 'bool b = false;');
    var contextRoot = protocol.ContextRoot(packagePath, []);
    await pluginServer.handleAnalysisSetContextRoots(
        protocol.AnalysisSetContextRootsParams([contextRoot]));
    var notification = await channel.notifications.first;
    var params = protocol.AnalysisErrorsParams.fromNotification(notification);
    expect(params.file, convertPath('/package1/lib/test.dart'));
    expect(params.errors, hasLength(1));

    expect(
      params.errors.single,
      isA<protocol.AnalysisError>()
          .having((e) => e.severity, 'severity',
              protocol.AnalysisErrorSeverity.INFO)
          .having(
              (e) => e.type, 'type', protocol.AnalysisErrorType.STATIC_WARNING)
          .having((e) => e.message, 'message', 'No bools message'),
    );
  }

  Future<void> test_handleEditGetFixes() async {
    var packagePath = convertPath('/package1');
    var filePath = join(packagePath, 'lib', 'test.dart');
    newFile(filePath, 'bool b = false;');
    var contextRoot = protocol.ContextRoot(packagePath, []);
    await pluginServer.handleAnalysisSetContextRoots(
        protocol.AnalysisSetContextRootsParams([contextRoot]));

    var result = await pluginServer.handleEditGetFixes(
        protocol.EditGetFixesParams(filePath, 'bool b = '.length));
    var fixes = result.fixes;
    // We expect 1 fix because neither `IgnoreDiagnosticOnLine` nor
    // `IgnoreDiagnosticInFile` are registered by the plugin.
    // TODO(srawlins): Investigate whether they should be.
    expect(fixes, hasLength(1));
    expect(fixes[0].fixes, hasLength(1));
  }
}

class _FakeChannel implements PluginCommunicationChannel {
  final _completers = <String, Completer<protocol.Response>>{};

  final StreamController<protocol.Notification> _notificationsController =
      StreamController();

  Stream<protocol.Notification> get notifications =>
      _notificationsController.stream;

  @override
  void close() {}

  @override
  void listen(void Function(protocol.Request request)? onRequest,
      {void Function()? onDone, Function? onError, Function? onNotification}) {}

  @override
  void sendNotification(protocol.Notification notification) {
    _notificationsController.add(notification);
  }

  @override
  void sendResponse(protocol.Response response) {
    var completer = _completers.remove(response.id);
    completer?.complete(response);
  }
}

class _NoBoolsPlugin extends Plugin {
  @override
  void register(PluginRegistry registry) {
    registry.registerRule(_NoBoolsRule());
    registry.registerFixForRule(_NoBoolsRule.code, _WrapInQuotes.new);
  }
}

class _NoBoolsRule extends LintRule {
  static const LintCode code = LintCode(
    'no_bools',
    'No bools message',
    correctionMessage: 'No bools correction',
  );

  _NoBoolsRule()
      : super(
          name: 'no_bools',
          description: 'No bools desc',
          details: 'No bools details',
          categories: {LintRuleCategory.errorProne},
        );

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _NoBoolsVisitor(this);
    registry.addBooleanLiteral(this, visitor);
  }
}

class _NoBoolsVisitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _NoBoolsVisitor(this.rule);

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    rule.reportLint(node);
  }
}

class _WrapInQuotes extends ResolvedCorrectionProducer {
  static const _wrapInQuotesKind =
      FixKind('dart.fix.wrapInQuotes', 50, 'Wrap in quotes');

  static const _wrapInQuotesMultiKind = FixKind(
      'dart.fix.wrapInQuotes.multi', 40, 'Wrap in quotes everywhere in file');

  @override
  final CorrectionApplicability applicability;

  _WrapInQuotes({required super.context})
      : applicability = CorrectionApplicability.acrossFiles;

  @override
  FixKind get fixKind => _wrapInQuotesKind;

  @override
  FixKind get multiFixKind => _wrapInQuotesMultiKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var literal = node;
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(literal.offset, "'");
      builder.addSimpleInsertion(literal.end, "'");
    });
  }
}
