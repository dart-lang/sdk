// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/analysis_rule/rule_context.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/lint/analysis_rule_timers.dart';

part 'linter_visitor.g.dart';

/// The soon-to-be-deprecated alias for a [RuleVisitorRegistry].
typedef NodeLintRegistry = RuleVisitorRegistry;

class _AfterLibrarySubscription {
  final AbstractAnalysisRule rule;
  final void Function() callback;
  final Stopwatch? timer;

  _AfterLibrarySubscription(this.rule, this.callback, this.timer);
}

/// A single subscription for a node type, by the specified [rule].
class _Subscription<T> {
  final AbstractAnalysisRule rule;
  final AstVisitor visitor;
  final Stopwatch? timer;

  _Subscription(this.rule, this.visitor, this.timer);
}
