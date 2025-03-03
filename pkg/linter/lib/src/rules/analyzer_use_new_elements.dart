// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart' // ignore: implementation_imports
    show RecursiveTypeVisitor;

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Use new element model in opted-in files.';

bool _isOldModelElement(Element2? element) {
  if (element == null) {
    return false;
  }

  var firstFragment = element.firstFragment;
  var libraryFragment = firstFragment.libraryFragment;
  if (libraryFragment == null) {
    return false;
  }

  var uriStr = libraryFragment.source.uri.toString();

  switch (element) {
    case InstanceElement2():
      if (uriStr == 'package:analyzer/dart/element/element.dart') {
        // Skip classes that don't required migration.
        if (const {
          'DirectiveUri',
          'DirectiveUriWithLibrary',
          'DirectiveUriWithRelativeUri',
          'DirectiveUriWithRelativeUriString',
          'DirectiveUriWithSource',
          'DirectiveUriWithUnit',
          'ElementAnnotation',
          'ElementKind',
          'ElementLocation',
          'HideElementCombinator',
          'LibraryLanguageVersion',
          'NamespaceCombinator',
          'ShowElementCombinator',
        }.contains(firstFragment.name2)) {
          return false;
        }
        return true;
      }
    case GetterElement():
      switch (uriStr) {
        case 'package:analyzer/src/dart/ast/ast.dart':
          return element.name3 == 'declaredElement';
        case 'package:analyzer/src/dart/element/type.dart':
          var enclosingElement = element.enclosingElement2;
          if (enclosingElement is InterfaceElement2) {
            if (enclosingElement.thisType.implementsDartType) {
              return element.name3 == 'element';
            }
          }
      }
  }
  return false;
}

bool _isOldModelType(DartType? type) {
  if (type is InterfaceType) {
    if (type.element3.isExactly(
      'FlowAnalysis',
      Uri.parse(
        'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart',
      ),
    )) {
      return false;
    }
  }

  var visitor = _TypeVisitor();
  type?.accept(visitor);
  return visitor.result;
}

class AnalyzerUseNewElements extends LintRule {
  static const LintCode code = LintCode(
    'analyzer_use_new_elements',
    'This code uses the old analyzer element model.',
    correctionMessage: 'Try using the new elements.',
  );

  /// Whether to use or bypass the opt-in file.
  bool useOptInFile;

  AnalyzerUseNewElements({this.useOptInFile = true})
    : super(name: code.name, description: _desc, state: const State.internal());

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
    NodeLintRegistry registry,
    LinterContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
    registry.addNamedType(this, visitor);
    registry.addSimpleIdentifier(this, visitor);
  }
}

class _TypeVisitor extends RecursiveTypeVisitor {
  bool result = false;

  @override
  bool visitInterfaceType(InterfaceType type) {
    result |= _isOldModelElement(type.element3);
    return super.visitInterfaceType(type);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final Map<AstNode, bool> _deprecatedNodes = {};

  _Visitor(this.rule);

  @override
  visitMethodInvocation(MethodInvocation node) {
    if (_isDeprecatedNode(node)) {
      return;
    }

    if (_isOldModelType(node.staticType)) {
      rule.reportLint(node.methodName);
    }
  }

  @override
  visitNamedType(NamedType node) {
    if (_isDeprecatedNode(node)) {
      return;
    }

    if (_isOldModelElement(node.element2)) {
      rule.reportLintForToken(node.name2);
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (_isDeprecatedNode(node)) {
      return;
    }

    if (node.parent case MethodInvocation invocation) {
      if (invocation.methodName == node) {
        return;
      }
    }

    if (_isOldModelElement(node.element)) {
      rule.reportLint(node);
    }

    if (_isOldModelType(node.staticType)) {
      _isDeprecatedNode(node);
      rule.reportLint(node);
    }
  }

  /// Returns whether [node] is or inside a deprecated node.
  bool _isDeprecatedNode(AstNode? node) {
    if (node == null) {
      return false;
    }

    if (_deprecatedNodes[node] case var result?) {
      return result;
    }

    if (node is Declaration) {
      var element = node.declaredFragment?.element;
      if (element case Annotatable annotatable) {
        var hasDeprecated = annotatable.metadata2.hasDeprecated;
        if (hasDeprecated) {
          return _deprecatedNodes[node] = true;
        }
      }
    }

    return _deprecatedNodes[node] = _isDeprecatedNode(node.parent);
  }
}

extension on InterfaceType {
  bool get implementsDartType => allSupertypes.any((t) => t.isDartType);

  bool get isDartType =>
      element3.library2.uri.toString() ==
          'package:analyzer/dart/element/type.dart' &&
      element3.name3 == 'DartType';
}
