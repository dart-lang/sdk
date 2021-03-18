// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _dartCollectionUri = 'dart.collection';
const _dartConvertUri = 'dart.convert';

const _desc = r'Prefer using mixins.';

const _details = r'''

Dart 2.1 introduced a new syntax for mixins that provides a safe way for a mixin
to invoke inherited members using `super`. The new style of mixins should always
be used for types that are to be mixed in. As a result, this lint will flag any
uses of a class in a `with` clause.

**BAD:**
```dart
class A {}
class B extends Object with A {}
```

**OK:**
```dart
mixin M {}
class C with M {}
```

''';

const _iterableMixinName = 'IterableMixin';
const _listMixinName = 'ListMixin';
const _mapMixinName = 'MapMixin';
const _setMixinName = 'SetMixin';
const _stringConversionSinkName = 'StringConversionSinkMixin';

class PreferMixin extends LintRule implements NodeLintRule {
  PreferMixin()
      : super(
            name: 'prefer_mixin',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addWithClause(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitWithClause(WithClause node) {
    for (var type in node.mixinTypes) {
      var element = type.name.staticElement;
      if (element is TypeAliasElement) {
        element = element.aliasedType.element;
      }
      if (element is ClassElement && !element.isMixin && !isAllowed(element)) {
        rule.reportLint(type);
      }
    }
  }

  /// Check for "legacy"  classes that cannot easily be made `mixin`s for
  /// compatibility reasons.
  /// (See: https://github.com/dart-lang/linter/issues/2082)
  static bool isAllowed(ClassElement element) =>
      // todo (pq): remove allowlist once legacy mixins are otherwise annotated.
      // see: https://github.com/dart-lang/sdk/issues/45343
      DartTypeUtilities.isClassElement(
          element, _iterableMixinName, _dartCollectionUri) ||
      DartTypeUtilities.isClassElement(
          element, _listMixinName, _dartCollectionUri) ||
      DartTypeUtilities.isClassElement(
          element, _mapMixinName, _dartCollectionUri) ||
      DartTypeUtilities.isClassElement(
          element, _setMixinName, _dartCollectionUri) ||
      DartTypeUtilities.isClassElement(
          element, _stringConversionSinkName, _dartConvertUri);
}
