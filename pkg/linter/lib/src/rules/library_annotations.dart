// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:meta/meta_meta.dart';

import '../analyzer.dart';

const _desc = r'Attach library annotations to library directives.';

const _details = r'''
Attach library annotations to library directives, rather than
some other library-level element.

**BAD:**
```dart
@TestOn('browser')

import 'package:test/test.dart';

void main() {}
```

**GOOD:**
```dart
@TestOn('browser')
library;

import 'package:test/test.dart';

void main() {}
```

**NOTE:** An unnamed library, like `library;` above, is only supported in Dart
2.19 and later. Code which might run in earlier versions of Dart will need to
provide a name in the `library` directive.
''';

class LibraryAnnotations extends LintRule {
  static const LintCode code = LintCode('library_annotations',
      'This annotation must be attached to a library directive.',
      correctionMessage:
          'Try attaching library annotations to library directives.');

  LibraryAnnotations()
      : super(
            name: 'library_annotations',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LibraryAnnotations rule;

  Directive? firstDirective;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    if (node.directives.isNotEmpty) {
      firstDirective = node.directives.first;
    }
    for (var directive in node.directives) {
      if (directive is PartDirective) {
        return;
      }
      if (directive is! LibraryDirective) {
        _check(directive);
      }
    }

    node.declarations.forEach(_check);
  }

  void _check(AnnotatedNode node) {
    for (var annotation in node.metadata) {
      var elementAnnotation = annotation.elementAnnotation;
      if (elementAnnotation == null) {
        return;
      }

      if (elementAnnotation.targetKinds.length == 1 &&
          elementAnnotation.targetKinds.contains(TargetKind.library) &&
          firstDirective == node) {
        rule.reportLint(annotation);
      } else if (elementAnnotation.isPragmaLateTrust) {
        rule.reportLint(annotation);
      }
    }
  }
}

extension on ElementAnnotation {
  /// Whether this is an annotation of the form `@pragma('dart2js:late:trust')`.
  bool get isPragmaLateTrust {
    if (_isConstructor(libraryName: 'dart.core', className: 'pragma')) {
      var value = computeConstantValue();
      var nameValue = value?.getField('name');
      return nameValue?.toStringValue() == 'dart2js:late:trust';
    }
    return false;
  }

  // Copied from package:analyzer/src/dart/element/element.dart
  bool _isConstructor({
    required String libraryName,
    required String className,
  }) {
    var element = this.element;
    return element is ConstructorElement &&
        element.enclosingElement.name == className &&
        element.library.name == libraryName;
  }
}
