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
```dart
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

/// Checks if the [name] is equivalent to the specified [prefix] or at least
/// is prefixed by it with a delimiting `.`.
bool matchesOrIsPrefixedBy(String name, String prefix) =>
    name == prefix || name.startsWith('$prefix.');

class PackagePrefixedLibraryNames extends LintRule {
  static const LintCode code = LintCode(
      'package_prefixed_library_names',
      'The library name is not prefixed by the package name and a '
          'dot-separated path.',
      correctionMessage: "Try changing the name to '{0}'.");

  PackagePrefixedLibraryNames()
      : super(
            name: 'package_prefixed_library_names',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addLibraryDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PackagePrefixedLibraryNames rule;

  _Visitor(this.rule);

  @override
  // ignore: prefer_expression_function_bodies
  void visitLibraryDirective(LibraryDirective node) {
    // Project info is not being set.
    //See: https://github.com/dart-lang/linter/issues/3395
    return;

    // // If no project info is set, bail early.
    // // https://github.com/dart-lang/linter/issues/154
    // var project = rule.project;
    // var element = node.element;
    // if (project == null || element == null) {
    //   return;
    // }
    //
    // var source = element.source;
    // if (source == null) {
    //   return;
    // }
    //
    // var prefix = Analyzer.facade.createLibraryNamePrefix(
    //     libraryPath: source.fullName,
    //     projectRoot: project.root.absolute.path,
    //     packageName: project.name);
    //
    // var name = element.name;
    // if (name == null || !matchesOrIsPrefixedBy(name, prefix)) {
    //   rule.reportLint(node.name, arguments: ['$prefix.$name']);
    // }
  }
}
