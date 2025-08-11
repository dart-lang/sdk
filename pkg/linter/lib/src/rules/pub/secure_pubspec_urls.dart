// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/pubspec.dart';
import 'package:analyzer/error/error.dart';

import '../../analyzer.dart';

const _desc = r'Use secure urls in `pubspec.yaml`.';

class SecurePubspecUrls extends LintRule {
  SecurePubspecUrls()
    : super(name: LintNames.secure_pubspec_urls, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.secure_pubspec_urls;

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

  @override
  void visitPackageDocumentation(PubspecEntry documentation) {
    _checkUrl(documentation.value);
  }

  @override
  void visitPackageHomepage(PubspecEntry homepage) {
    _checkUrl(homepage.value);
  }

  @override
  void visitPackageIssueTracker(PubspecEntry issueTracker) {
    _checkUrl(issueTracker.value);
  }

  @override
  void visitPackageRepository(PubspecEntry repository) {
    _checkUrl(repository.value);
  }

  void _checkUrl(PubspecNode? node) {
    if (node == null) return;
    var text = node.text;
    if (text != null) {
      var uri = Uri.tryParse(text);
      if (uri != null && (uri.isScheme('http') || uri.isScheme('git'))) {
        rule.reportAtPubNode(node, arguments: [uri.scheme]);
      }
    }
  }

  void _visitDeps(PubspecDependencyList dependencies) {
    for (var dep in dependencies) {
      _checkUrl(dep.git?.url?.value);
      _checkUrl(dep.host?.url?.value);
    }
  }
}
