// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Avoid slow asynchronous `dart:io` methods.';

const Set<String> _fileSystemEntityMethodNames = <String>{
  'exists',
  'isDirectory',
  'isFile',
  'isLink',
  'stat',
  'type',
};

class AvoidSlowAsyncIo extends AnalysisRule {
  AvoidSlowAsyncIo()
    : super(name: LintNames.avoid_slow_async_io, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.avoidSlowAsyncIo;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var methodName = node.methodName;
    var element = methodName.element;
    if (element is! MethodElement) return;

    var enclosingElement = element.enclosingElement;
    if (enclosingElement is! ClassElement) return;

    var library = enclosingElement.library;
    if (library.name != 'dart.io') return;

    var name = methodName.name;
    var className = enclosingElement.name;
    if (className == 'File') {
      if (name == 'lastModified') {
        rule.reportAtNode(node);
      }
    } else if (className == 'FileSystemEntity') {
      if (_fileSystemEntityMethodNames.contains(name)) {
        rule.reportAtNode(node);
      }
    }
  }
}
