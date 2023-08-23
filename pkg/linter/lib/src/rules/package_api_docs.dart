// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Provide doc comments for all public APIs.';

const _details = r'''
**DO** provide doc comments for all public APIs.

As described in the [pub package layout doc](https://dart.dev/tools/pub/package-layout#implementation-files),
public APIs consist in everything in your package's `lib` folder, minus
implementation files in `lib/src`, adding elements explicitly exported with an
`export` directive.

For example, given `lib/foo.dart`:
```dart
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

**BAD:**
```dart
class Bar {
  void bar();
}
```

**GOOD:**
```dart
/// A Foo.
abstract class Foo {
  /// Start foo-ing.
  void start() => _start();

  _start();
}
```

Advice for writing good doc comments can be found in the
[Doc Writing Guidelines](https://dart.dev/effective-dart/documentation).

''';

class PackageApiDocs extends LintRule {
  static const LintCode code = LintCode(
      'package_api_docs', 'Missing documentation for public API.',
      correctionMessage: 'Try adding a documentation comment.');

  PackageApiDocs()
      : super(
            name: 'package_api_docs',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFieldDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addClassDeclaration(this, visitor);
    registry.addEnumDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addTopLevelVariableDeclaration(this, visitor);
    registry.addClassTypeAlias(this, visitor);
    registry.addFunctionTypeAlias(this, visitor);
  }
}

class _Visitor extends GeneralizingAstVisitor {
  final PackageApiDocs rule;

  _Visitor(this.rule);

  // ignore: prefer_expression_function_bodies
  void check(Declaration node) {
    // See: https://github.com/dart-lang/linter/issues/3395
    // (`DartProject` removal).
    return;

    // // If no project info is set, bail early.
    // // https://github.com/dart-lang/linter/issues/154
    // var currentProject = rule.project;
    // if (currentProject == null) {
    //   return;
    // }
    //
    // var declaredElement = node.declaredElement;
    // if (declaredElement != null && currentProject.isApi(declaredElement)) {
    //   if (node.documentationComment == null) {
    //     rule.reportLint(getNodeToAnnotate(node));
    //   }
    // }
  }

  ///  classMember ::=
  ///    [ConstructorDeclaration]
  ///  | [FieldDeclaration]
  ///  | [MethodDeclaration]
  @override
  void visitClassMember(ClassMember node) {
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
  void visitCompilationUnitMember(CompilationUnitMember node) {
    check(node);
  }

  @override
  void visitNode(AstNode node) {
    // Don't visit children
  }
}
