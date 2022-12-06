// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/pub.dart'; // ignore: implementation_imports
import 'package:source_span/source_span.dart';

import '../../analyzer.dart';

const _desc = r'Sort pub dependencies alphabetically.';

const _details = r'''
**DO** sort pub dependencies alphabetically (A to Z) in `pubspec.yaml`.

Sorting list of pub dependencies makes maintenance easier.
''';

class SortPubDependencies extends LintRule {
  static const LintCode code = LintCode(
      'sort_pub_dependencies', 'Unsorted dependencies.',
      correctionMessage: 'Try sorting the dependencies.');

  SortPubDependencies()
      : super(
            name: 'sort_pub_dependencies',
            description: _desc,
            details: _details,
            group: Group.pub);

  @override
  LintCode get lintCode => code;

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
  void visitPackageDependencyOverrides(PSDependencyList dependencies) {
    _visitDeps(dependencies);
  }

  @override
  void visitPackageDevDependencies(PSDependencyList dependencies) {
    _visitDeps(dependencies);
  }

  void _visitDeps(PSDependencyList dependencies) {
    int compare(SourceLocation? lc1, SourceLocation? lc2) {
      if (lc1 == null || lc2 == null) {
        return 0;
      }
      return lc1.compareTo(lc2);
    }

    var depsByLocation = dependencies.toList()
      ..sort((d1, d2) => compare(d1.name?.span.start, d2.name?.span.start));
    var previousName = '';
    for (var dep in depsByLocation) {
      var name = dep.name;
      if (name != null) {
        var text = name.text;
        if (text != null) {
          if (text.compareTo(previousName) < 0) {
            rule.reportPubLint(name);
            return;
          }
          previousName = text;
        }
      }
    }
  }
}
