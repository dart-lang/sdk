// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../util/leak_detector_visitor.dart';

const _desc = r'Close instances of `dart:core` `Sink`.';

class CloseSinks extends LintRule {
  CloseSinks() : super(name: LintNames.close_sinks, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.close_sinks;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addFieldDeclaration(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends LeakDetectorProcessors {
  static final Map<DartTypePredicate, String> _predicates = {
    _isSink: 'close',
    _isSocket: 'destroy',
  };

  _Visitor(super.rule);

  @override
  Map<DartTypePredicate, String> get predicates => _predicates;

  static bool _isSink(DartType type) =>
      type.implementsInterface('Sink', 'dart.core');

  static bool _isSocket(DartType type) =>
      type.implementsInterface('Socket', 'dart.io');
}
