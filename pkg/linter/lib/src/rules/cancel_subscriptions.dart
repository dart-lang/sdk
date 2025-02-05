// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../util/leak_detector_visitor.dart';

const _desc = r'Cancel instances of `dart:async` `StreamSubscription`.';

class CancelSubscriptions extends LintRule {
  CancelSubscriptions()
      : super(
          name: LintNames.cancel_subscriptions,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.cancel_subscriptions;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFieldDeclaration(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends LeakDetectorProcessors {
  static final _predicates = {
    _isSubscription: 'cancel',
  };

  _Visitor(super.rule);

  @override
  Map<DartTypePredicate, String> get predicates => _predicates;

  static bool _isSubscription(DartType type) =>
      type.implementsInterface('StreamSubscription', 'dart.async');
}
