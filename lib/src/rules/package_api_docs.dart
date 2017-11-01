// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';

const _desc = r'Provide doc comments for all public APIs.';

const _details = r'''

**DO** provide doc comments for all public APIs.

As described in the [pub package layout doc]
(https://www.dartlang.org/tools/pub/package-layout.html#implementation-files),
public APIs consist in everything in your package's `lib` folder, minus
implementation files in `lib/src`, adding elements explicitly exported with an
`export` directive.

For example, given `lib/foo.dart`:
```
export 'src/bar.dart' show Bar;
export 'src/baz.dart';

class Foo { }

class _Foo { }
```
its API includes:

* `Foo` (but not `_Foo`)
* `Bar` (exported) and
* all *public* elements in `src/baz.dart`

All public API members should be documented with `///` doc-style comments.

**GOOD:**
```
/// A Foo.
abstract class Foo {
  /// Start foo-ing.
  void start() => _start();

  _start();
}
```

**BAD:**
```
class Bar {
  void bar();
}
```

Advice for writing good doc comments can be found in the
[Doc Writing Guidelines]
(https://www.dartlang.org/articles/doc-comment-guidelines).

''';

class PackageApiDocs extends LintRule implements ProjectVisitor {
  DartProject project;

  PackageApiDocs()
      : super(
            name: 'package_api_docs',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  ProjectVisitor getProjectVisitor() => this;

  @override
  AstVisitor getVisitor() => new Visitor(this);

  @override
  visit(DartProject project) {
    this.project = project;
  }
}

class Visitor extends GeneralizingAstVisitor {
  PackageApiDocs rule;
  Visitor(this.rule);

  DartProject get project => rule.project;

  void check(Declaration node) {
    // If no project info is set, bail early.
    // https://github.com/dart-lang/linter/issues/154
    if (project == null) {
      return;
    }
    if (project.isApi(node.element)) {
      if (node.documentationComment == null) {
        rule.reportLint(getNodeToAnnotate(node));
      }
    }
  }

  ///  classMember ::=
  ///    [ConstructorDeclaration]
  ///  | [FieldDeclaration]
  ///  | [MethodDeclaration]
  @override
  visitClassMember(ClassMember node) {
    check(node);
  }

  ///  compilationUnitMember ::=
  ///    [ClassDeclaration]
  ///  | [EnumDeclaration]
  ///  | [FunctionDeclaration]
  ///  | [TopLevelVariableDeclaration]
  ///  | [ClassTypeAlias]
  ///  | [FunctionTypeAlias]
  @override
  visitCompilationUnitMember(CompilationUnitMember node) {
    check(node);
  }

  @override
  visitNode(AstNode node) {
    // Don't visit children
  }
}
