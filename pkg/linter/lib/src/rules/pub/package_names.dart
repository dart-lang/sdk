// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/pubspec.dart';
import 'package:analyzer/error/error.dart';

import '../../analyzer.dart';
import '../../utils.dart';

const _desc = r'Use `lowercase_with_underscores` for package names.';

class PackageNames extends LintRule {
  PackageNames() : super(name: LintNames.package_names, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.package_names;

  @override
  PubspecVisitor<void> get pubspecVisitor => Visitor(this);
}

class Visitor extends PubspecVisitor<void> {
  final LintRule rule;

  Visitor(this.rule);

  @override
  void visitPackageName(PubspecEntry name) {
    var packageName = name.value.text;
    if (packageName != null && !isValidPackageName(packageName)) {
      rule.reportAtPubNode(name.value, arguments: [packageName]);
    }
  }
}
