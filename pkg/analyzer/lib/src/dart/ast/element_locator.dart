// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';

/// An object used to locate the [Element] associated with a given [AstNode].
class ElementLocator {
  /// Return the element associated with the given [node], or `null` if there
  /// is no element associated with the node.
  static Element? locate(AstNode? node) {
    if (node == null) return null;

    var mapper = _ElementMapper();
    return node.accept(mapper);
  }

  /// Return the element associated with the given [node], or `null` if there
  /// is no element associated with the node.
  static Element2? locate2(AstNode? node) {
    if (node == null) return null;

    var mapper = _ElementMapper2();
    return node.accept(mapper);
  }
}

/// Visitor that maps nodes to elements.
class _ElementMapper extends GeneralizingAstVisitor<Element> {
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
    return node.staticElement;
  }

  @override
  Element? visitBinaryExpression(BinaryExpression node) {
    return node.staticElement;
  }

  @override
  Element? visitClassDeclaration(ClassDeclaration node) {
    return node.declaredElement;
  }

  @override
  Element? visitClassTypeAlias(ClassTypeAlias node) {
    return node.declaredElement;
  }

  @override
  Element? visitCompilationUnit(CompilationUnit node) {
    return node.declaredElement;
  }

  @override
  Element? visitConstructorDeclaration(ConstructorDeclaration node) {
    return node.declaredElement;
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
    return node.declaredElement;
  }

  @override
  Element? visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    return node.declaredElement;
  }

  @override
  Element? visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    return node.declaredElement;
  }

  @override
  Element? visitEnumDeclaration(EnumDeclaration node) {
    return node.declaredElement;
  }

  @override
  Element? visitExportDirective(ExportDirective node) {
    return node.element;
  }

  @override
  Element? visitExtensionDeclaration(ExtensionDeclaration node) {
    return node.declaredElement;
  }

  @override
  Element? visitExtensionOverride(ExtensionOverride node) {
    return node.element;
  }

  @override
  Element? visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    return node.declaredElement;
  }

  @override
  Element? visitFormalParameter(FormalParameter node) {
    return node.declaredElement;
  }

  @override
  Element? visitFunctionDeclaration(FunctionDeclaration node) {
    return node.declaredElement;
  }

  @override
  Element? visitFunctionTypeAlias(FunctionTypeAlias node) {
    return node.declaredElement;
  }

  @override
  Element? visitGenericTypeAlias(GenericTypeAlias node) {
    return node.declaredElement;
  }

  @override
  Element? visitIdentifier(Identifier node) {
    var parent = node.parent;
    if (parent is Annotation) {
      // Type name in Annotation
      if (identical(parent.name, node) && parent.constructorName == null) {
        return parent.element;
      }
    } else if (parent is ConstructorDeclaration) {
      // Extra work to map Constructor Declarations to their associated
      // Constructor Elements
      var returnType = parent.returnType;
      if (identical(returnType, node)) {
        var name = parent.name;
        if (name != null) {
          return parent.declaredElement;
        }
        var element = node.staticElement;
        if (element is InterfaceElement) {
          return element.unnamedConstructor;
        }
      } else if (parent.name == node.endToken) {
        return parent.declaredElement;
      }
    } else if (parent is LibraryIdentifier) {
      var grandParent = parent.parent;
      if (grandParent is PartOfDirective) {
        var element = grandParent.element;
        if (element is LibraryElement) {
          return element.definingCompilationUnit;
        }
      } else if (grandParent is LibraryDirective) {
        return grandParent.element;
      }
    }
    return node.writeOrReadElement;
  }

  @override
  Element? visitImportDirective(ImportDirective node) {
    return node.element;
  }

  @override
  Element? visitImportPrefixReference(ImportPrefixReference node) {
    return node.element;
  }

  @override
  Element? visitIndexExpression(IndexExpression node) {
    return node.staticElement;
  }

  @override
  Element? visitInstanceCreationExpression(InstanceCreationExpression node) {
    return node.constructorName.staticElement;
  }

  @override
  Element? visitLibraryDirective(LibraryDirective node) {
    return node.element;
  }

  @override
  Element? visitMethodDeclaration(MethodDeclaration node) {
    return node.declaredElement;
  }

  @override
  Element? visitMethodInvocation(MethodInvocation node) {
    return node.methodName.staticElement;
  }

  @override
  Element? visitMixinDeclaration(MixinDeclaration node) {
    return node.declaredElement;
  }

  @override
  Element? visitNamedType(NamedType node) {
    return node.element;
  }

  @override
  Element? visitPartOfDirective(PartOfDirective node) {
    return node.element;
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
    return node.staticElement;
  }

  @override
  Element? visitPrefixedIdentifier(PrefixedIdentifier node) {
    return node.staticElement;
  }

  @override
  Element? visitPrefixExpression(PrefixExpression node) {
    return node.staticElement;
  }

  @override
  Element? visitRepresentationConstructorName(
      RepresentationConstructorName node) {
    var representation = node.parent as RepresentationDeclaration;
    return representation.constructorElement;
  }

  @override
  Element? visitRepresentationDeclaration(RepresentationDeclaration node) {
    return node.fieldElement;
  }

  @override
  Element? visitStringLiteral(StringLiteral node) {
    var parent = node.parent;
    if (parent is ExportDirective) {
      return parent.element?.exportedLibrary;
    } else if (parent is ImportDirective) {
      return parent.element?.importedLibrary;
    } else if (parent is PartDirective) {
      var elementUri = parent.element?.uri;
      if (elementUri is DirectiveUriWithUnit) {
        return elementUri.unit;
      }
    }
    return null;
  }

  @override
  Element? visitTypeParameter(TypeParameter node) {
    return node.declaredElement;
  }

  @override
  Element? visitVariableDeclaration(VariableDeclaration node) {
    return node.declaredElement;
  }
}

/// Visitor that maps nodes to elements.
class _ElementMapper2 extends GeneralizingAstVisitor<Element2> {
  @override
  Element2? visitAnnotation(Annotation node) {
    return node.element2;
  }

  @override
  Element2? visitAssignedVariablePattern(AssignedVariablePattern node) {
    return node.element2;
  }

  @override
  Element2? visitAssignmentExpression(AssignmentExpression node) {
    return node.element;
  }

  @override
  Element2? visitBinaryExpression(BinaryExpression node) {
    return node.element;
  }

  @override
  Element2? visitClassDeclaration(ClassDeclaration node) {
    return node.declaredFragment?.element;
  }

  @override
  Element2? visitClassTypeAlias(ClassTypeAlias node) {
    return node.declaredFragment?.element;
  }

  @override
  Element2? visitCompilationUnit(CompilationUnit node) {
    return node.declaredFragment?.element;
  }

  @override
  Element2? visitConstructorDeclaration(ConstructorDeclaration node) {
    return node.declaredFragment?.element;
  }

  @override
  Element2? visitConstructorSelector(ConstructorSelector node) {
    var parent = node.parent;
    if (parent is EnumConstantArguments) {
      var parent2 = parent.parent;
      if (parent2 is EnumConstantDeclaration) {
        return parent2.constructorElement2;
      }
    }
    return null;
  }

  @override
  Element2? visitDeclaredIdentifier(DeclaredIdentifier node) {
    return node.declaredElement2;
  }

  @override
  Element2? visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    return node.declaredElement2;
  }

  @override
  Element2? visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    return node.declaredFragment?.element;
  }

  @override
  Element2? visitEnumDeclaration(EnumDeclaration node) {
    return node.declaredFragment?.element;
  }

  @override
  Element2? visitExportDirective(ExportDirective node) {
    return node.libraryExport?.exportedLibrary2;
  }

  @override
  Element2? visitExtensionDeclaration(ExtensionDeclaration node) {
    return node.declaredFragment?.element;
  }

  @override
  Element2? visitExtensionOverride(ExtensionOverride node) {
    return node.element2;
  }

  @override
  Element2? visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    return node.declaredFragment?.element;
  }

  @override
  Element2? visitFormalParameter(FormalParameter node) {
    return node.declaredFragment?.element;
  }

  @override
  Element2? visitFunctionDeclaration(FunctionDeclaration node) {
    return node.declaredElement2 ?? node.declaredFragment?.element;
  }

  @override
  Element2? visitFunctionTypeAlias(FunctionTypeAlias node) {
    return node.declaredFragment?.element;
  }

  @override
  Element2? visitGenericTypeAlias(GenericTypeAlias node) {
    return node.declaredFragment?.element;
  }

  @override
  Element2? visitIdentifier(Identifier node) {
    var parent = node.parent;
    if (parent is Annotation) {
      // Map the type name in an annotation.
      if (identical(parent.name, node) && parent.constructorName == null) {
        return parent.element2;
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
        if (element is InterfaceElement2) {
          return element.unnamedConstructor2;
        }
      } else if (parent.name == node.endToken) {
        return parent.declaredFragment?.element;
      }
    } else if (parent is LibraryIdentifier) {
      var grandParent = parent.parent;
      if (grandParent is LibraryDirective) {
        return grandParent.element2;
      }
      return null;
    }
    return node.writeOrReadElement2;
  }

  @override
  Element2? visitImportDirective(ImportDirective node) {
    return node.libraryImport?.importedLibrary2;
  }

  @override
  Element2? visitImportPrefixReference(ImportPrefixReference node) {
    return node.element2;
  }

  @override
  Element2? visitIndexExpression(IndexExpression node) {
    return node.element;
  }

  @override
  Element2? visitInstanceCreationExpression(InstanceCreationExpression node) {
    return node.constructorName.element;
  }

  @override
  Element2? visitLibraryDirective(LibraryDirective node) {
    return node.element2;
  }

  @override
  Element2? visitMethodDeclaration(MethodDeclaration node) {
    return node.declaredFragment?.element;
  }

  @override
  Element2? visitMethodInvocation(MethodInvocation node) {
    return node.methodName.element;
  }

  @override
  Element2? visitMixinDeclaration(MixinDeclaration node) {
    return node.declaredFragment?.element;
  }

  @override
  Element2? visitNamedType(NamedType node) {
    return node.element2;
  }

  @override
  Element2? visitPartOfDirective(PartOfDirective node) {
    return node.libraryName?.element;
  }

  @override
  Element2? visitPatternField(PatternField node) {
    return node.element2;
  }

  @override
  Element2? visitPatternFieldName(PatternFieldName node) {
    var parent = node.parent;
    if (parent is PatternField) {
      return parent.element2;
    } else {
      return null;
    }
  }

  @override
  Element2? visitPostfixExpression(PostfixExpression node) {
    return node.element;
  }

  @override
  Element2? visitPrefixedIdentifier(PrefixedIdentifier node) {
    return node.element;
  }

  @override
  Element2? visitPrefixExpression(PrefixExpression node) {
    return node.element;
  }

  @override
  Element2? visitRepresentationConstructorName(
      RepresentationConstructorName node) {
    var representation = node.parent as RepresentationDeclaration;
    return representation.constructorFragment?.element;
  }

  @override
  Element2? visitRepresentationDeclaration(RepresentationDeclaration node) {
    return node.fieldFragment?.element;
  }

  @override
  Element2? visitStringLiteral(StringLiteral node) {
    var parent = node.parent;
    if (parent is ExportDirective) {
      return parent.libraryExport?.exportedLibrary2;
    } else if (parent is ImportDirective) {
      return parent.libraryImport?.importedLibrary2;
    } else if (parent is PartDirective) {
      return null;
    }
    return null;
  }

  @override
  Element2? visitTypeParameter(TypeParameter node) {
    return node.declaredFragment?.element;
  }

  @override
  Element2? visitVariableDeclaration(VariableDeclaration node) {
    return node.declaredFragment?.element ?? node.declaredElement2;
  }
}
