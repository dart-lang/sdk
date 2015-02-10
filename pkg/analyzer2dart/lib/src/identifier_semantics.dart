// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Code for classifying the semantics of identifiers appearing in a Dart file.
 */
library analyzer2dart.identifierSemantics;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:sharedfrontend/elements.dart' as shared;
import 'package:sharedfrontend/src/access_semantics.dart';


// TODO(johnniwinther,paulberry): This should be a constant.
final AccessSemanticsVisitor ACCESS_SEMANTICS_VISITOR =
    new AccessSemanticsVisitor();

// TODO(johnniwinther,paulberry): This should extend a non-recursive visitor.
class AccessSemanticsVisitor extends RecursiveAstVisitor<AccessSemantics> {
  /**
   * Return the semantics for [node].
   */
  @override
  AccessSemantics visitMethodInvocation(MethodInvocation node) {
    Expression target = node.realTarget;
    Element staticElement = node.methodName.staticElement;
    if (target == null) {
      if (staticElement is FunctionElement) {
        if (staticElement.enclosingElement is CompilationUnitElement) {
          return new AccessSemantics.staticMethod(
              node.methodName.name,
              staticElement,
              null,
              isInvoke: true);
        } else {
          return new AccessSemantics.localFunction(
              node.methodName.name,
              staticElement,
              isInvoke: true);
        }
      } else if (staticElement is MethodElement && staticElement.isStatic) {
        return new AccessSemantics.staticMethod(
            node.methodName.name,
            staticElement,
            staticElement.enclosingElement,
            isInvoke: true);
      } else if (staticElement is PropertyAccessorElement) {
        if (staticElement.isSynthetic) {
          if (staticElement.enclosingElement is CompilationUnitElement) {
            return new AccessSemantics.staticField(
                node.methodName.name,
                staticElement.variable,
                null,
                isInvoke: true);
          } else if (staticElement.isStatic) {
            shared.Element classElement = staticElement.enclosingElement;
            return new AccessSemantics.staticField(
                node.methodName.name,
                staticElement.variable,
                classElement,
                isInvoke: true);
          }
        } else {
          if (staticElement.enclosingElement is CompilationUnitElement) {
            return new AccessSemantics.staticProperty(
                node.methodName.name,
                staticElement,
                null,
                isInvoke: true);
          } else if (staticElement.isStatic) {
            shared.Element classElement = staticElement.enclosingElement;
            return new AccessSemantics.staticProperty(
                node.methodName.name,
                staticElement,
                classElement,
                isInvoke: true);
          }
        }
      } else if (staticElement is LocalVariableElement) {
        return new AccessSemantics.localVariable(
            node.methodName.name,
            staticElement,
            isInvoke: true);
      } else if (staticElement is ParameterElement) {
        return new AccessSemantics.parameter(
            node.methodName.name,
            staticElement,
            isInvoke: true);
      } else if (staticElement is TypeParameterElement) {
        return new AccessSemantics.typeParameter(
            node.methodName.name,
            staticElement,
            isInvoke: true);
      } else if (staticElement is ClassElement ||
          staticElement is FunctionTypeAliasElement ||
          staticElement is DynamicElementImpl) {
        return new AccessSemantics.toplevelType(
            node.methodName.name,
            staticElement,
            isInvoke: true);
      }
    } else if (target is Identifier) {
      Element targetStaticElement = target.staticElement;
      if (targetStaticElement is PrefixElement) {
        if (staticElement == null) {
          return new AccessSemantics.dynamic(
              node.methodName.name,
              null,
              isInvoke: true);
        } else if (staticElement is PropertyAccessorElement) {
          if (staticElement.isSynthetic) {
            return new AccessSemantics.staticField(
                node.methodName.name,
                staticElement.variable,
                null,
                isInvoke: true);
          } else {
            return new AccessSemantics.staticProperty(
                node.methodName.name,
                staticElement,
                null,
                isInvoke: true);
          }
        } else if (staticElement is TypeParameterElement) {
          return new AccessSemantics.typeParameter(
              node.methodName.name,
              staticElement,
              isInvoke: true);
        } else if (staticElement is ClassElement ||
            staticElement is FunctionTypeAliasElement) {
          return new AccessSemantics.toplevelType(
              node.methodName.name,
              staticElement,
              isInvoke: true);
        } else {
          return new AccessSemantics.staticMethod(
              node.methodName.name,
              staticElement,
              null,
              isInvoke: true);
        }
      } else if (targetStaticElement is ClassElement) {
        if (staticElement is PropertyAccessorElement) {
          if (staticElement.isSynthetic) {
            return new AccessSemantics.staticField(
                node.methodName.name,
                staticElement.variable,
                targetStaticElement,
                isInvoke: true);
          } else {
            return new AccessSemantics.staticProperty(
                node.methodName.name,
                staticElement,
                targetStaticElement,
                isInvoke: true);
          }
        } else {
          return new AccessSemantics.staticMethod(
              node.methodName.name,
              staticElement,
              targetStaticElement,
              isInvoke: true);
        }
      }
    }
    return new AccessSemantics.dynamic(
        node.methodName.name, target, isInvoke: true);
  }

  /**
   * Return the access semantics for [node].
   */
  @override
  AccessSemantics visitPrefixedIdentifier(PrefixedIdentifier node) {
    return _classifyPrefixed(node.prefix, node.identifier);
  }

  /**
   * Return the access semantics for [node].
   */
  @override
  AccessSemantics visitPropertyAccess(PropertyAccess node) {
    if (node.target is Identifier) {
      return _classifyPrefixed(node.target, node.propertyName);
    } else {
      return new AccessSemantics.dynamic(
          node.propertyName.name,
          node.realTarget,
          isRead: node.propertyName.inGetterContext(),
          isWrite: node.propertyName.inSetterContext());
    }
  }

  /**
   * Return the access semantics for [node].
   *
   * Note: if [node] is the right hand side of a [PropertyAccess] or
   * [PrefixedIdentifier], or the method name of a [MethodInvocation], the return
   * value is null, since the semantics are determined by the parent.  In
   * practice these cases should never arise because the parent will visit the
   * parent node before visiting this one.
   */
  @override
  AccessSemantics visitSimpleIdentifier(SimpleIdentifier node) {
    AstNode parent = node.parent;
    if (node.inDeclarationContext()) {
      // This identifier is a declaration, not a use.
      return null;
    }
    if (parent is TypeName) {
      // TODO(paulberry): do we need to handle this case?
      return null;
    }
    if ((parent is PropertyAccess && parent.propertyName == node) ||
        (parent is PrefixedIdentifier && parent.identifier == node) ||
        (parent is MethodInvocation && parent.methodName == node)) {
      // The access semantics are determined by the parent.
      return null;
    }
    // TODO(paulberry): handle PrefixElement.
    Element staticElement = node.staticElement;
    if (staticElement is PropertyAccessorElement) {
      if (staticElement.isSynthetic) {
        if (staticElement.enclosingElement is CompilationUnitElement) {
          return new AccessSemantics.staticField(
              node.name,
              staticElement.variable,
              null,
              isRead: node.inGetterContext(),
              isWrite: node.inSetterContext());
        } else if (staticElement.isStatic) {
          shared.Element classElement = staticElement.enclosingElement;
          return new AccessSemantics.staticField(
              node.name,
              staticElement.variable,
              classElement,
              isRead: node.inGetterContext(),
              isWrite: node.inSetterContext());
        }
      } else {
        if (staticElement.enclosingElement is CompilationUnitElement) {
          return new AccessSemantics.staticProperty(
              node.name,
              staticElement,
              null,
              isRead: node.inGetterContext(),
              isWrite: node.inSetterContext());
        } else if (staticElement.isStatic) {
          shared.Element classElement = staticElement.enclosingElement;
          return new AccessSemantics.staticProperty(
              node.name,
              staticElement,
              classElement,
              isRead: node.inGetterContext(),
              isWrite: node.inSetterContext());
        }
      }
    } else if (staticElement is LocalVariableElement) {
      return new AccessSemantics.localVariable(
          node.name,
          staticElement,
          isRead: node.inGetterContext(),
          isWrite: node.inSetterContext());
    } else if (staticElement is ParameterElement) {
      return new AccessSemantics.parameter(
          node.name,
          staticElement,
          isRead: node.inGetterContext(),
          isWrite: node.inSetterContext());
    } else if (staticElement is FunctionElement) {
      if (staticElement.enclosingElement is CompilationUnitElement) {
        return new AccessSemantics.staticMethod(
            node.name,
            staticElement,
            null,
            isRead: node.inGetterContext(),
            isWrite: node.inSetterContext());
      } else {
        return new AccessSemantics.localFunction(
            node.name,
            staticElement,
            isRead: node.inGetterContext(),
            isWrite: node.inSetterContext());
      }
    } else if (staticElement is MethodElement && staticElement.isStatic) {
      return new AccessSemantics.staticMethod(
          node.name,
          staticElement,
          staticElement.enclosingElement,
          isRead: node.inGetterContext(),
          isWrite: node.inSetterContext());
    } else if (staticElement is TypeParameterElement) {
      return new AccessSemantics.typeParameter(
          node.name,
          staticElement,
          isRead: node.inGetterContext(),
          isWrite: node.inSetterContext());
    } else if (staticElement is ClassElement ||
        staticElement is FunctionTypeAliasElement ||
        staticElement is DynamicElementImpl) {
      return new AccessSemantics.toplevelType(
          node.name,
          staticElement,
          isRead: node.inGetterContext(),
          isWrite: node.inSetterContext());
    }
    return new AccessSemantics.dynamic(
        node.name,
        null,
        isRead: node.inGetterContext(),
        isWrite: node.inSetterContext());
  }

  /**
   * Helper function for classifying an expression of type
   * Identifier.SimpleIdentifier.
   */
  AccessSemantics _classifyPrefixed(Identifier lhs, SimpleIdentifier rhs) {
    Element lhsElement = lhs.staticElement;
    Element rhsElement = rhs.staticElement;
    if (lhsElement is PrefixElement) {
      if (rhsElement is PropertyAccessorElement) {
        if (rhsElement.isSynthetic) {
          return new AccessSemantics.staticField(
              rhs.name,
              rhsElement.variable,
              null,
              isRead: rhs.inGetterContext(),
              isWrite: rhs.inSetterContext());
        } else {
          return new AccessSemantics.staticProperty(
              rhs.name,
              rhsElement,
              null,
              isRead: rhs.inGetterContext(),
              isWrite: rhs.inSetterContext());
        }
      } else if (rhsElement is FunctionElement) {
        return new AccessSemantics.staticMethod(
            rhs.name,
            rhsElement,
            null,
            isRead: rhs.inGetterContext(),
            isWrite: rhs.inSetterContext());
      } else if (rhsElement is ClassElement ||
                 rhsElement is FunctionTypeAliasElement) {
        return new AccessSemantics.toplevelType(
            rhs.name,
            rhsElement,
            isRead: rhs.inGetterContext(),
            isWrite: rhs.inSetterContext());
      } else {
        return new AccessSemantics.dynamic(
            rhs.name,
            null,
            isRead: rhs.inGetterContext(),
            isWrite: rhs.inSetterContext());
      }
    } else if (lhsElement is ClassElement) {
      if (rhsElement is PropertyAccessorElement && rhsElement.isSynthetic) {
        return new AccessSemantics.staticField(
            rhs.name,
            rhsElement.variable,
            lhsElement,
            isRead: rhs.inGetterContext(),
            isWrite: rhs.inSetterContext());
      } else if (rhsElement is MethodElement) {
        return new AccessSemantics.staticMethod(
            rhs.name,
            rhsElement,
            lhsElement,
            isRead: rhs.inGetterContext(),
            isWrite: rhs.inSetterContext());
      } else {
        return new AccessSemantics.staticProperty(
            rhs.name,
            rhsElement,
            lhsElement,
            isRead: rhs.inGetterContext(),
            isWrite: rhs.inSetterContext());
      }
    } else {
      return new AccessSemantics.dynamic(
          rhs.name,
          lhs,
          isRead: rhs.inGetterContext(),
          isWrite: rhs.inSetterContext());
    }
  }
}
