// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/error/element_usage_frontier_detector.dart' // ignore: implementation_imports
    show ElementUsageFrontierDetector;
import 'package:analyzer/src/utilities/extensions/ast.dart'; // ignore: implementation_imports

/// Reports uses of tagged elements with an [ElementUsageFrontierDetector].
///
/// Each declaration is pushed onto the detector while its contents are
/// visited, so that the detector reports a use only if the use is not inside
/// a declaration that is itself tagged. This is the "frontier" between the
/// tagged and the untagged code.
class ElementUsageFrontierVisitor<TagInfo extends Object>
    extends RecursiveAstVisitor<void> {
  final ElementUsageFrontierDetector<TagInfo> _detector;

  new(this._detector);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _detector.assignmentExpression(node);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _detector.binaryExpression(node);
    super.visitBinaryExpression(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _withDeclaration(node, () {
      super.visitClassDeclaration(node);
    });
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _withDeclaration(node, () {
      super.visitClassTypeAlias(node);
    });
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var library = node.declaredFragment?.element;
    if (library == null) {
      return;
    }
    _detector.pushElement(library);

    super.visitCompilationUnit(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _withDeclaration(node, () {
      _detector.constructorDeclaration(node);
      super.visitConstructorDeclaration(node);
    });
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _detector.constructorName(node);
    super.visitConstructorName(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _withDeclaration(node, () {
      super.visitEnumDeclaration(node);
    });
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _detector.exportDirective(node);
    super.visitExportDirective(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _withDeclaration(node, () {
      super.visitExtensionDeclaration(node);
    });
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    _detector.extensionOverride(node);
    super.visitExtensionOverride(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    _withDeclaration(node, () {
      super.visitExtensionTypeDeclaration(node);
    });
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _detector.pushElement(node.firstVariableElement);

    try {
      super.visitFieldDeclaration(node);
    } finally {
      _detector.popElement();
    }
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _withFormalParameter(node, () {
      super.visitFieldFormalParameter(node);
    });
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _withDeclaration(node, () {
      super.visitFunctionDeclaration(node);
    });
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _detector.functionExpressionInvocation(node);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _withDeclaration(node, () {
      super.visitFunctionTypeAlias(node);
    });
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _withDeclaration(node, () {
      super.visitGenericTypeAlias(node);
    });
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _detector.importDirective(node);
    super.visitImportDirective(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _detector.indexExpression(node);
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _detector.instanceCreationExpression(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _withDeclaration(node, () {
      super.visitMethodDeclaration(node);
    });
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _detector.methodInvocation(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _withDeclaration(node, () {
      super.visitMixinDeclaration(node);
    });
  }

  @override
  void visitNamedType(NamedType node) {
    _detector.namedType(node);
    super.visitNamedType(node);
  }

  @override
  void visitPatternField(PatternField node) {
    _detector.patternField(node);
    super.visitPatternField(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _detector.postfixExpression(node);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _detector.prefixExpression(node);
    super.visitPrefixExpression(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    _detector.redirectingConstructorInvocation(node);
    super.visitRedirectingConstructorInvocation(node);
  }

  @override
  void visitRegularFormalParameter(RegularFormalParameter node) {
    _withFormalParameter(node, () {
      super.visitRegularFormalParameter(node);
    });
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _detector.simpleIdentifier(node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _detector.superConstructorInvocation(node);
    super.visitSuperConstructorInvocation(node);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    _withFormalParameter(node, () {
      super.visitSuperFormalParameter(node);
    });
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _detector.pushElement(node.firstVariableElement);

    try {
      super.visitTopLevelVariableDeclaration(node);
    } finally {
      _detector.popElement();
    }
  }

  void _withDeclaration<T extends Declaration>(
    T node,
    void Function() recurse,
  ) {
    _withFragment(node.declaredFragment, recurse);
  }

  void _withFormalParameter<T extends FormalParameter>(
    T node,
    void Function() recurse,
  ) {
    _withFragment(node.declaredFragment, recurse);
  }

  void _withFragment(Fragment? fragment, void Function() recurse) {
    _detector.pushElement(fragment?.element);
    try {
      recurse();
    } finally {
      _detector.popElement();
    }
  }
}
