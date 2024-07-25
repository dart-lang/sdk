// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r"Don't have a library name in a `library` declaration.";

const _details = r'''
**DON'T** have a library name in a `library` declaration.

Library names are not necessary.

A library does not need a library declaration, but one can be added to attach
library documentation and library metadata to. A declaration of `library;` is
sufficient for those uses.

The only *use* of a library name is for a `part` file to refer back to its
owning library, but part files should prefer to use a string URI to refer back
to the library file, not a library name.

If a library name is added to a library declaration, it introduces the risk of
name *conflicts*. It's a compile-time error if two libraries in the same program
have the same library name. To avoid that, library names tend to be long,
including the package name and path, just to avoid accidental name clashes. That
makes such library names hard to read, and not even useful as documentation.

**BAD:**
```dart
/// This library has a long name.
library magnificator.src.helper.bananas;
```

```dart
library utils; // Not as verbose, but risks conflicts.
```

**GOOD:**
```dart
/// This library is awesome.
library;

part "apart.dart"; // contains: `part of "good_library.dart";`
```
''';

class UnnecessaryLibraryName extends LintRule {
  static const LintCode code = LintCode(
      'unnecessary_library_name', 'Library names are not necessary.',
      correctionMessage: 'Remove the library name.');

  UnnecessaryLibraryName()
      : super(
            name: 'unnecessary_library_name',
            description: _desc,
            details: _details,
            categories: {
              LintRuleCategory.brevity,
              LintRuleCategory.languageFeatureUsage,
              LintRuleCategory.style,
            });

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!context.libraryElement!.featureSet
        .isEnabled(Feature.unnamedLibraries)) {
      return;
    }

    var visitor = _Visitor(this);
    registry.addLibraryDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitLibraryDirective(LibraryDirective node) {
    var name = node.name2;
    if (name != null) {
      rule.reportLint(name);
    }
  }
}
