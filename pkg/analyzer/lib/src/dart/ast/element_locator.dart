// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';

/// An object used to locate the [Element] associated with a given V1 [AstNode].
@ToBeDeprecated('Use ElementLocatorV2 instead')
class ElementLocator {
  /// Return the element associated with the given [node], or `null` if there
  /// is no element associated with the node.
  static Element? locate(AstNode? node) {
    if (node == null) return null;

    var mapper = _ElementMapper();
    return node.accept(mapper);
  }
}

/// An object used to locate the [Element] associated with a given [AstNode].
class ElementLocatorV2 {
  /// Return the element associated with the given [node], or `null` if there
  /// is no element associated with the node.
  static Element? locate(AstNode? node) {
    if (node == null) return null;

    var mapper = _ElementMapperV2();
    return node.accept2(mapper);
  }
}

/// V1 visitor that maps nodes to elements.
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
    return node.element;
  }

  @override
  Element? visitBinaryExpression(BinaryExpression node) {
    return node.element;
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
  Element? visitDottedName(DottedName node) {
    var parent = node.parent;
    if (parent is LibraryDirective) {
      return parent.element;
    }
    return null;
  }

  @override
  Element? visitExportDirective(ExportDirective node) {
    return node.libraryExport?.exportedLibrary;
  }

  @override
  Element? visitExtensionOverride(ExtensionOverride node) {
    return node.element;
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
      var returnType = parent.typeName;
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
    } else if (parent is DottedName) {
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
    } else if (parent is PrefixedIdentifier &&
        parent.identifier == node &&
        parent.identifier.name == MethodElement.CALL_METHOD_NAME &&
        parent.prefix.staticType is FunctionType) {
      // Handle .call tear-offs on functions.
      return parent.prefix.element;
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
  Element? visitLabelReference(LabelReference node) {
    return node.element;
  }

  @override
  Element? visitLibraryDirective(LibraryDirective node) {
    return node.element;
  }

  @override
  Element? visitMethodInvocation(MethodInvocation node) {
    return node.methodName.element ?? visitIdentifier(node.methodName);
  }

  @override
  Element? visitNamedArgument(NamedArgument node) {
    return node.correspondingParameter;
  }

  @override
  Element? visitNamedType(NamedType node) {
    return node.element;
  }

  @override
  Element? visitNameWithTypeParameters(NameWithTypeParameters node) {
    return node.parent!.accept(this);
  }

  @override
  Element? visitNode(AstNode node) {
    return node.tryCast<FragmentDeclaringNode>()?.declaredFragment?.element;
  }

  @override
  Element? visitPartOfDirective(PartOfDirective node) {
    return null;
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
    return node.element ?? visitIdentifier(node.identifier);
  }

  @override
  Element? visitPrefixExpression(PrefixExpression node) {
    return node.element;
  }

  @override
  Element? visitPrimaryConstructorBody(PrimaryConstructorBody node) {
    return node.declaration?.declaredFragment?.element;
  }

  @override
  Element? visitPrimaryConstructorDeclaration(
    PrimaryConstructorDeclaration node,
  ) {
    if (node.parent case Declaration declaration) {
      return declaration.declaredFragment?.element;
    }
    return null;
  }

  @override
  Element? visitPrimaryConstructorName(PrimaryConstructorName node) {
    if (node.parent case PrimaryConstructorDeclaration declaration) {
      return declaration.declaredFragment?.element;
    }
    return node.parent!.accept(this);
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
}

/// Visitor that maps nodes to elements.
class _ElementMapperV2 extends UnifyingAstVisitor2<Element> {
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
  Element? visitBinaryOperatorInvocation(BinaryOperatorInvocation node) {
    return node.element;
  }

  @override
  Element? visitCascadeIndexAssignmentTarget(
    CascadeIndexAssignmentTarget node,
  ) {
    return _visitIndexAssignmentTarget(node);
  }

  @override
  Element? visitCascadeIndexExpression(CascadeIndexExpression node) {
    return _visitIndexExpression2(node);
  }

  @override
  Element? visitCascadeMethodInvocation(CascadeMethodInvocation node) {
    return switch (node.resolution) {
      ExecutableInvocationResolution(:var element) => element,
      InvalidInvocationResolution(
        recovery: ExecutableInvocationResolution(:var element),
      ) =>
        element,
      _ => null,
    };
  }

  @override
  Element? visitCascadePropertyAssignmentTarget(
    CascadePropertyAssignmentTarget node,
  ) {
    if (node.write case NamedWriteResolutionWithElement(:var element)) {
      return element;
    }
    return null;
  }

  @override
  Element? visitCascadePropertyExtraction(CascadePropertyExtraction node) {
    if (node.resolution case NamedReadResolutionWithElement(:var element)) {
      return element;
    }
    return null;
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
  Element? visitCombinatorName(CombinatorName node) {
    return node.element ?? node.setterElement;
  }

  @override
  Element? visitCompoundAssignment(CompoundAssignment node) {
    return node.element;
  }

  @override
  Element? visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    return node.fieldElement;
  }

  @override
  Element? visitConstructorInvocation(ConstructorInvocation node) {
    return node.constructorReference.element;
  }

  @override
  Element? visitConstructorSelector(ConstructorSelector node) {
    var parent = node.parent2;
    if (parent is EnumConstantArguments) {
      var parent2 = parent.parent2;
      if (parent2 is EnumConstantDeclaration) {
        return parent2.constructorElement;
      }
    } else if (parent is RedirectingConstructorInvocation) {
      return parent.element;
    } else if (parent is SuperConstructorInvocation) {
      return parent.element;
    }
    return null;
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
  Element? visitDottedName(DottedName node) {
    var parent = node.parent2;
    if (parent is LibraryDirective) {
      return parent.element;
    }
    return null;
  }

  @override
  Element? visitExportDirective(ExportDirective node) {
    return node.libraryExport?.exportedLibrary;
  }

  @override
  Element? visitExtensionOverride(ExtensionOverride node) {
    return node.element;
  }

  @override
  Element? visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    return switch (node.write) {
      InvalidNamedWriteResolution(:var candidates) =>
        candidates.isEmpty ? null : candidates.first,
      NamedWriteResolutionWithElement(:var element) => element,
      _ => null,
    };
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
  Element? visitLabel(Label node) {
    return node.declaredFragment?.element;
  }

  @override
  Element? visitLabelReference(LabelReference node) {
    return node.element;
  }

  @override
  Element? visitLibraryDirective(LibraryDirective node) {
    return node.element;
  }

  @override
  Element? visitMethodInvocation(MethodInvocation node) {
    return node.methodName.element ?? _visitIdentifier(node.methodName);
  }

  @override
  Element? visitNamedArgument(NamedArgument node) {
    return node.correspondingParameter;
  }

  @override
  Element? visitNamedType(NamedType node) {
    return node.element;
  }

  @override
  Element? visitNameWithTypeParameters(NameWithTypeParameters node) {
    return node.parent2!.accept2(this);
  }

  @override
  Element? visitNode(AstNode node) {
    return switch (node) {
      IncrementOrDecrementExpression(:var element) => element,
      Identifier() => _visitIdentifier(node),
      StringLiteral() => _visitStringLiteral(node),
      _ => node.tryCast<FragmentDeclaringNode>()?.declaredFragment?.element,
    };
  }

  @override
  Element? visitPartOfDirective(PartOfDirective node) {
    return null;
  }

  @override
  Element? visitPatternField(PatternField node) {
    return node.element;
  }

  @override
  Element? visitPatternFieldName(PatternFieldName node) {
    var parent = node.parent2;
    if (parent is PatternField) {
      return parent.element;
    } else {
      return null;
    }
  }

  @override
  Element? visitPrefixedIdentifier(PrefixedIdentifier node) {
    return node.element ?? _visitIdentifier(node.identifier);
  }

  @override
  Element? visitPrimaryConstructorBody(PrimaryConstructorBody node) {
    return node.declaration?.declaredFragment?.element;
  }

  @override
  Element? visitPrimaryConstructorDeclaration(
    PrimaryConstructorDeclaration node,
  ) {
    if (node.parent2 case Declaration declaration) {
      return declaration.declaredFragment?.element;
    }
    return null;
  }

  @override
  Element? visitPrimaryConstructorName(PrimaryConstructorName node) {
    if (node.parent2 case PrimaryConstructorDeclaration declaration) {
      return declaration.declaredFragment?.element;
    }
    return node.parent2!.accept2(this);
  }

  @override
  Element? visitReceiverIndexAssignmentTarget(
    ReceiverIndexAssignmentTarget node,
  ) {
    return _visitIndexAssignmentTarget(node);
  }

  @override
  Element? visitReceiverIndexExpression(ReceiverIndexExpression node) {
    return _visitIndexExpression2(node);
  }

  @override
  Element? visitReceiverPropertyAssignmentTarget(
    ReceiverPropertyAssignmentTarget node,
  ) {
    if (node.write case NamedWriteResolutionWithElement(:var element)) {
      return element;
    }
    return null;
  }

  @override
  Element? visitReceiverPropertyExtraction(ReceiverPropertyExtraction node) {
    if (node.resolution case NamedReadResolutionWithElement(:var element)) {
      return element;
    }
    return null;
  }

  @override
  Element? visitUnaryOperatorInvocation(UnaryOperatorInvocation node) {
    return node.element;
  }

  @override
  Element? visitUnqualifiedNameAssignmentTarget(
    UnqualifiedNameAssignmentTarget node,
  ) {
    if (node.write case NamedWriteResolutionWithElement(:var element)) {
      return element;
    }
    return null;
  }

  Element? _visitIdentifier(Identifier node) {
    var parent = node.parent2;
    if (parent is Annotation) {
      // Map the type name in an annotation.
      if (identical(parent.name, node) && parent.constructorName == null) {
        return parent.element;
      }
    } else if (parent is ConstructorDeclaration) {
      // Map a constructor declarations to its associated constructor element.
      var returnType = parent.typeName;
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
    } else if (parent is DottedName) {
      var grandParent = parent.parent2;
      if (grandParent is LibraryDirective) {
        return grandParent.element;
      }
      return null;
    } else if (parent is MethodInvocation &&
        parent.methodName == node &&
        parent.methodName.name == MethodElement.CALL_METHOD_NAME) {
      // Handle .call() invocations on functions.
      var method = parent.realTarget2;
      if (method is Identifier && method.staticType is FunctionType) {
        return method.element;
      }
    } else if (parent is PrefixedIdentifier &&
        parent.identifier == node &&
        parent.identifier.name == MethodElement.CALL_METHOD_NAME &&
        parent.prefix.staticType is FunctionType) {
      // Handle .call tear-offs on functions.
      return parent.prefix.element;
    }
    return node.writeOrReadElement2;
  }

  Element? _visitIndexAssignmentTarget(IndexAssignmentTarget node) {
    return switch (node.write) {
      MethodIndexWriteResolution(:var element) => element,
      InvalidIndexWriteResolution(
        recovery: MethodIndexWriteResolution(:var element),
      ) =>
        element,
      _ => null,
    };
  }

  Element? _visitIndexExpression2(IndexExpression2 node) {
    return switch (node.resolution) {
      MethodIndexReadResolution(:var element) => element,
      InvalidIndexReadResolution(
        recovery: MethodIndexReadResolution(:var element),
      ) =>
        element,
      _ => null,
    };
  }

  Element? _visitStringLiteral(StringLiteral node) {
    var parent = node.parent2;
    if (parent is ExportDirective) {
      return parent.libraryExport?.exportedLibrary;
    } else if (parent is ImportDirective) {
      return parent.libraryImport?.importedLibrary;
    } else if (parent is PartDirective) {
      return null;
    }
    return null;
  }
}
