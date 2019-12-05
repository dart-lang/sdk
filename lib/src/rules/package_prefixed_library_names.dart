// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc =
    r'Prefix library names with the package name and a dot-separated path.';

const _details = r'''

**DO** prefix library names with the package name and a dot-separated path.

This guideline helps avoid the warnings you get when two libraries have the same
name.  Here are the rules we recommend:

* Prefix all library names with the package name.
* Make the entry library have the same name as the package.
* For all other libraries in a package, after the package name add the
dot-separated path to the library's Dart file.
* For libraries under `lib`, omit the top directory name.

For example, say the package name is `my_package`.  Here are the library names
for various files in the package:

**GOOD:**
```
// In lib/my_package.dart
library my_package;

// In lib/other.dart
library my_package.other;

// In lib/foo/bar.dart
library my_package.foo.bar;

// In example/foo/bar.dart
library my_package.example.foo.bar;

// In lib/src/private.dart
library my_package.src.private;
```

''';

bool matchesOrIsPrefixedBy(String name, String prefix) =>
    name == prefix || name.startsWith('$prefix.');

class PackagePrefixedLibraryNames extends LintRule
    implements ProjectVisitor, NodeLintRule {
  DartProject project;

  PackagePrefixedLibraryNames()
      : super(
            name: 'package_prefixed_library_names',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  ProjectVisitor getProjectVisitor() => this;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addLibraryDirective(this, visitor);
  }

  @override
  void visit(DartProject project) {
    this.project = project;
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PackagePrefixedLibraryNames rule;

  _Visitor(this.rule);

  DartProject get project => rule.project;

  @override
  void visitLibraryDirective(LibraryDirective node) {
    // If no project info is set, bail early.
    // https://github.com/dart-lang/linter/issues/154
    if (project == null) {
      return;
    }
    final source = node.element.source;
    var prefix = Analyzer.facade.createLibraryNamePrefix(
        libraryPath: source.fullName,
        projectRoot: project.root.absolute.path,
        packageName: project.name);

    var libraryName = node.element.name;
    if (!matchesOrIsPrefixedBy(libraryName, prefix)) {
      rule.reportLint(node.name);
    }
  }
}
