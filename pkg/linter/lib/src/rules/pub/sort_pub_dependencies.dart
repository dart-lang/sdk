// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/pubspec.dart';
import 'package:analyzer/error/error.dart';
import 'package:source_span/source_span.dart';

import '../../analyzer.dart';

const _desc = r'Sort pub dependencies alphabetically.';

class SortPubDependencies extends LintRule {
  SortPubDependencies()
    : super(name: LintNames.sort_pub_dependencies, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.sortPubDependencies;

  @override
  PubspecVisitor<void> get pubspecVisitor => Visitor(this);
}

class Visitor extends PubspecVisitor<void> {
  final LintRule rule;

  Visitor(this.rule);

  @override
  void visitPackageDependencies(PubspecDependencyList dependencies) {
    _visitDeps(dependencies);
  }

  @override
  void visitPackageDependencyOverrides(PubspecDependencyList dependencies) {
    _visitDeps(dependencies);
  }

  @override
  void visitPackageDevDependencies(PubspecDependencyList dependencies) {
    _visitDeps(dependencies);
  }

  void _visitDeps(PubspecDependencyList dependencies) {
    int compare(SourceLocation? lc1, SourceLocation? lc2) {
      if (lc1 == null || lc2 == null) {
        return 0;
      }
      return lc1.compareTo(lc2);
    }

    var depsByLocation =
        dependencies.toList()
          ..sort((d1, d2) => compare(d1.name?.span.start, d2.name?.span.start));
    var previousName = '';
    for (var dep in depsByLocation) {
      var name = dep.name;
      if (name != null) {
        var text = name.text;
        if (text != null) {
          if (text.compareTo(previousName) < 0) {
            rule.reportAtPubNode(name);
            return;
          }
          previousName = text;
        }
      }
    }
  }
}
