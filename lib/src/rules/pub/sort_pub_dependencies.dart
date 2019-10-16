// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/pub.dart'; // ignore: implementation_imports

import '../../analyzer.dart';

const _desc = r'Sort pub dependencies.';

const _details = r'''
**DO** sort pub dependencies in `pubspec.yaml`.

Sorting list of pub dependencies makes maintenance easier.
''';

class SortPubDependencies extends LintRule {
  SortPubDependencies()
      : super(
            name: 'sort_pub_dependencies',
            description: _desc,
            details: _details,
            group: Group.pub);

  @override
  PubspecVisitor getPubspecVisitor() => Visitor(this);
}

class Visitor extends PubspecVisitor<void> {
  final LintRule rule;

  Visitor(this.rule);

  @override
  void visitPackageDependencies(PSDependencyList dependencies) {
    _visitDeps(dependencies);
  }

  @override
  void visitPackageDevDependencies(PSDependencyList dependencies) {
    _visitDeps(dependencies);
  }

  @override
  void visitPackageDependencyOverrides(PSDependencyList dependencies) {
    _visitDeps(dependencies);
  }

  void _visitDeps(PSDependencyList dependencies) {
    final depsByLocation = dependencies.toList()
      ..sort((d1, d2) => d1.name.span.start.compareTo(d2.name.span.start));
    var previousName = '';
    for (final dep in depsByLocation) {
      final name = dep.name.text;
      if (name.compareTo(previousName) < 0) {
        rule.reportPubLint(dep.name);
        return;
      }
      previousName = name;
    }
  }
}
