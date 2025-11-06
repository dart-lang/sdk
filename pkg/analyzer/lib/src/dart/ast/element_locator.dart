// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';

/// An object used to locate the [Element] associated with a given [AstNode].
class ElementLocator {
  /// Return the element associated with the given [node], or `null` if there
  /// is no element associated with the node.
  static Element? locate(AstNode? node) {
    if (node == null) return null;

    var mapper = _ElementMapper2();
    return node.accept(mapper);
  }
}

/// Visitor that maps nodes to elements.
class _ElementMapper2 extends GeneralizingAstVisitor<Element> {
  @override
  Element? visitAnnotation(Annotation node) {
    return node.element;
  }

  @override
  Element? visitAssignedVariablePattern(AssignedVariablePattern node) {
    return node.element;
  }

  @override
  Element? visitAssignmentExpression(AssignmentExpression node) {
    return node.element;
  }

  @override
  Element? visitBinaryExpression(BinaryExpression node) {
    return node.element;
  }

  @override
  Element? visitCatchClauseParameter(CatchClauseParameter node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitClassDeclaration(ClassDeclaration node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitClassTypeAlias(ClassTypeAlias node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitCompilationUnit(CompilationUnit node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitConstructorDeclaration(ConstructorDeclaration node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitConstructorSelector(ConstructorSelector node) {
    var parent = node.parent;
    if (parent is EnumConstantArguments) {
      var parent2 = parent.parent;
      if (parent2 is EnumConstantDeclaration) {
        return parent2.constructorElement;
      }
    }
    return null;
  }

  @override
  Element? visitDeclaredIdentifier(DeclaredIdentifier node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    return node.constructorName.element;
  }

  @override
  Element? visitDotShorthandInvocation(DotShorthandInvocation node) {
    return node.memberName.element;
  }

  @override
  Element? visitDotShorthandPropertyAccess(DotShorthandPropertyAccess node) {
    return node.propertyName.element;
  }

  @override
  Element? visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitEnumDeclaration(EnumDeclaration node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitExportDirective(ExportDirective node) {
    return node.libraryExport?.exportedLibrary;
  }

  @override
  Element? visitExtensionDeclaration(ExtensionDeclaration node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitExtensionOverride(ExtensionOverride node) {
    return node.element;
  }

  @override
  Element? visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitFormalParameter(FormalParameter node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitFunctionDeclaration(FunctionDeclaration node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitFunctionTypeAlias(FunctionTypeAlias node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitGenericTypeAlias(GenericTypeAlias node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitIdentifier(Identifier node) {
    var parent = node.parent;
    if (parent is Annotation) {
      // Map the type name in an annotation.
      if (identical(parent.name, node) && parent.constructorName == null) {
        return parent.element;
      }
    } else if (parent is ConstructorDeclaration) {
      // Map a constructor declarations to its associated constructor element.
      var returnType = parent.returnType;
      if (identical(returnType, node)) {
        var name = parent.name;
        if (name != null) {
          return parent.declaredFragment?.element;
        }
        var element = node.element;
        if (element is InterfaceElement) {
          return element.unnamedConstructor;
        }
      } else if (parent.name == node.endToken) {
        return parent.declaredFragment?.element;
      }
    } else if (parent is ConstructorSelector) {
      var parent2 = parent.parent;
      if (parent2 is EnumConstantArguments) {
        var parent3 = parent2.parent;
        if (parent3 is EnumConstantDeclaration) {
          return parent3.constructorElement;
        }
      }
    } else if (parent is LibraryIdentifier) {
      var grandParent = parent.parent;
      if (grandParent is LibraryDirective) {
        return grandParent.element;
      }
      return null;
    } else if (parent is MethodInvocation &&
        parent.methodName == node &&
        parent.methodName.name == MethodElement.CALL_METHOD_NAME) {
      // Handle .call() invocations on functions.
      var method = parent.realTarget;
      if (method is Identifier && method.staticType is FunctionType) {
        return method.element;
      }
    }
    return node.writeOrReadElement;
  }

  @override
  Element? visitImportDirective(ImportDirective node) {
    return node.libraryImport?.importedLibrary;
  }

  @override
  Element? visitImportPrefixReference(ImportPrefixReference node) {
    return node.element;
  }

  @override
  Element? visitIndexExpression(IndexExpression node) {
    return node.element;
  }

  @override
  Element? visitInstanceCreationExpression(InstanceCreationExpression node) {
    return node.constructorName.element;
  }

  @override
  Element? visitLibraryDirective(LibraryDirective node) {
    return node.element;
  }

  @override
  Element? visitMethodDeclaration(MethodDeclaration node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitMethodInvocation(MethodInvocation node) {
    return node.methodName.element;
  }

  @override
  Element? visitMixinDeclaration(MixinDeclaration node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitNamedType(NamedType node) {
    return node.element;
  }

  @override
  Element? visitPartOfDirective(PartOfDirective node) {
    return node.libraryName?.element;
  }

  @override
  Element? visitPatternField(PatternField node) {
    return node.element;
  }

  @override
  Element? visitPatternFieldName(PatternFieldName node) {
    var parent = node.parent;
    if (parent is PatternField) {
      return parent.element;
    } else {
      return null;
    }
  }

  @override
  Element? visitPostfixExpression(PostfixExpression node) {
    return node.element;
  }

  @override
  Element? visitPrefixedIdentifier(PrefixedIdentifier node) {
    return node.element;
  }

  @override
  Element? visitPrefixExpression(PrefixExpression node) {
    return node.element;
  }

  @override
  Element? visitRepresentationConstructorName(
    RepresentationConstructorName node,
  ) {
    var representation = node.parent as RepresentationDeclaration;
    return representation.constructorFragment?.element;
  }

  @override
  Element? visitRepresentationDeclaration(RepresentationDeclaration node) {
    return node.fieldFragment?.element;
  }

  @override
  Element? visitStringLiteral(StringLiteral node) {
    var parent = node.parent;
    if (parent is ExportDirective) {
      return parent.libraryExport?.exportedLibrary;
    } else if (parent is ImportDirective) {
      return parent.libraryImport?.importedLibrary;
    } else if (parent is PartDirective) {
      return null;
    }
    return null;
  }

  @override
  Element? visitTypeParameter(TypeParameter node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitVariableDeclaration(VariableDeclaration node) {
    return node.declaredFragment?.element ?? node.declaredFragment?.element;
  }
}
