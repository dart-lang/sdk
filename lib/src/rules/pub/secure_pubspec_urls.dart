// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/pub.dart'; // ignore: implementation_imports

import '../../analyzer.dart';

const _desc = r'Use secure urls in `pubspec.yaml`.';

const _details = r'''
**DO** Use secure urls in `pubspec.yaml`.

Use `https` instead of `http` or `git:`.

**BAD:**
```yaml
repository: http://github.com/dart-lang/example
```

```yaml
git:
  url: git://github.com/dart-lang/example/example.git
```

**GOOD:**
```yaml
repository: https://github.com/dart-lang/example
```

''';

class SecurePubspecUrls extends LintRule {
  static const LintCode code = LintCode('secure_pubspec_urls',
      "The '{0}' protocol shouldn't be used because it isn't secure.",
      correctionMessage: "Try using a secure protocol, such as 'https'.");

  SecurePubspecUrls()
      : super(
            name: 'secure_pubspec_urls',
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

  @override
  void visitPackageDocumentation(PSEntry documentation) {
    _checkUrl(documentation.value);
  }

  @override
  void visitPackageHomepage(PSEntry homepage) {
    _checkUrl(homepage.value);
  }

  @override
  void visitPackageIssueTracker(PSEntry issueTracker) {
    _checkUrl(issueTracker.value);
  }

  @override
  void visitPackageRepository(PSEntry repository) {
    _checkUrl(repository.value);
  }

  _checkUrl(PSNode? node) {
    if (node == null) return;
    var text = node.text;
    if (text != null) {
      var uri = Uri.tryParse(text);
      if (uri != null && (uri.isScheme('http') || uri.isScheme('git'))) {
        rule.reportPubLint(node, arguments: [uri.scheme]);
      }
    }
  }

  void _visitDeps(PSDependencyList dependencies) {
    for (var dep in dependencies) {
      _checkUrl(dep.git?.url?.value);
      _checkUrl(dep.host?.url?.value);
    }
  }
}
