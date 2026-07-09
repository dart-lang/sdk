// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';

class NeedsPackageRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'needs_package',
    'Needs Package at {0}',
    uniqueName: 'LintCode.needs_package',
  );

  NeedsPackageRule()
    : super(name: 'needs_package', description: 'This rule needs package info');

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (context.isInLibDir) {
      var visitor = _NeedsPackageVisitor(this, context);
      registry.addIntegerLiteral(this, visitor);
    }
  }
}

class NoBoolsRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_bools',
    'No bools message',
    uniqueName: 'LintCode.no_bools',
  );

  NoBoolsRule() : super(name: 'no_bools', description: 'No bools desc');

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _NoBoolsVisitor(this);
    registry.addBooleanLiteral(this, visitor);
  }
}

class TestDiagnosticCode extends DiagnosticCode {
  const TestDiagnosticCode(
    String name,
    String message, {
    this.type = DiagnosticType.STATIC_WARNING,
  }) : super(
         problemMessage: message,
         name: name,
         uniqueName: 'TestErrorCode.$name',
       );

  @override
  final DiagnosticType type;

  @override
  DiagnosticSeverity get severity => type.severity;
}

class NoInteger10Rule extends AnalysisRule {
  static const code = TestDiagnosticCode(
    'no_integer_10',
    'No integer 10 message',
  );

  NoInteger10Rule()
    : super(name: 'no_integer_10', description: 'No integer 10 desc');

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _NoIntegersVisitor(this);
    registry.addIntegerLiteral(this, visitor);
  }
}

class _NoIntegersVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _NoIntegersVisitor(this.rule);

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    if (node.value == 10) {
      rule.reportAtNode(node);
    }
  }
}

class NoDoublesCustomSeverityRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_doubles_custom_severity',
    'No doubles message',
    severity: DiagnosticSeverity.WARNING,
    uniqueName: 'LintCode.no_doubles_custom_severity',
  );

  NoDoublesCustomSeverityRule()
    : super(
        name: 'no_doubles_custom_severity',
        description: 'No doubles message',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _NoDoublesVisitor(this);
    registry.addDoubleLiteral(this, visitor);
  }
}

class NoDoublesRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_doubles',
    'No doubles message',
    uniqueName: 'LintCode.no_doubles',
  );

  NoDoublesRule()
    : super(name: 'no_doubles', description: 'No doubles message');

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _NoDoublesVisitor(this);
    registry.addDoubleLiteral(this, visitor);
  }
}

class NoReferencesToStringsRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_references_to_strings',
    'No references to Strings',
    uniqueName: 'LintCode.no_references_to_strings',
  );

  NoReferencesToStringsRule()
    : super(
        name: 'no_references_to_strings',
        description: 'No references to Strings',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _NoReferencesToStringsVisitor(this, context);
    registry.addSimpleIdentifier(this, visitor);
  }
}

class NoTypeAnnotationsRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_type_annotations',
    'No type annotations',
    uniqueName: 'LintCode.no_type_annotations',
  );

  NoTypeAnnotationsRule()
    : super(name: 'no_type_annotations', description: 'No type annotations');

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _NoTypeAnnotationsVisitor(this);
    registry.addNamedType(this, visitor);
  }
}

// TODO(FMorschel): Remove this once there is a public way of instantiating
//  DiagnosticMessage.
// See https://github.com/dart-lang/sdk/issues/61949
class _DiagnosticMessageImpl extends DiagnosticMessage {
  @override
  final String filePath;
  @override
  final int length;
  final String _message;
  @override
  final int offset;
  @override
  final String? url;

  _DiagnosticMessageImpl({
    required this.filePath,
    required this.length,
    required String message,
    required this.offset,
    required this.url,
  }) : _message = message;

  @override
  String messageText({required bool includeUrl}) {
    if (includeUrl && url != null) {
      StringBuffer result = StringBuffer(_message);
      if (!_message.endsWith('.')) {
        result.write('.');
      }
      result.write('  See $url');
      return result.toString();
    }
    return _message;
  }
}

class _NeedsPackageVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  final RuleContext context;

  _NeedsPackageVisitor(this.rule, this.context);

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    rule.reportAtNode(node, arguments: ['"${context.package!.root.path}"']);
  }
}

class _NoBoolsVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _NoBoolsVisitor(this.rule);

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    rule.reportAtNode(node);
  }
}

class _NoDoublesVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _NoDoublesVisitor(this.rule);

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    rule.reportAtNode(node);
  }
}

class _NoReferencesToStringsVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  final RuleContext context;

  _NoReferencesToStringsVisitor(this.rule, this.context);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.staticType?.isDartCoreString ?? false) {
      rule.reportAtNode(node);
    }
  }
}

class _NoTypeAnnotationsVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _NoTypeAnnotationsVisitor(this.rule);

  @override
  void visitNamedType(NamedType node) {
    var element = node.element;
    if (element is! InstanceElement) return;
    var fragment = element.firstFragment;
    rule.reportAtNode(
      node,
      contextMessages: [
        _DiagnosticMessageImpl(
          filePath: fragment.libraryFragment.source.fullName,
          length: fragment.name?.length ?? 1,
          offset: fragment.nameOffset ?? fragment.offset,
          message: 'Declared here',
          url: null,
        ),
      ],
    );
  }
}
