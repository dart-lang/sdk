// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:collection/collection.dart';

abstract class BaseDeprecatedMemberUseVerifier {
  /// We push a new value every time when we enter into a scope which
  /// can be marked as deprecated - a class, a method, fields (multiple).
  final List<bool> _inDeprecatedMemberStack = [false];

  BaseDeprecatedMemberUseVerifier();

  void assignmentExpression(AssignmentExpression node) {
    _checkForDeprecated(node.readElement, node.leftHandSide);
    _checkForDeprecated(node.writeElement, node.leftHandSide);
    _checkForDeprecated(node.element, node);
  }

  void binaryExpression(BinaryExpression node) {
    _checkForDeprecated(node.element, node);
  }

  void constructorName(ConstructorName node) {
    _checkForDeprecated(node.element, node);
  }

  void dotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    _invocationArguments(node.constructorName.element, node.argumentList);
  }

  void exportDirective(ExportDirective node) {
    _checkForDeprecated(node.libraryExport?.exportedLibrary, node);
  }

  void extensionOverride(ExtensionOverride node) {
    _checkForDeprecated(node.element, node);
  }

  void functionExpressionInvocation(FunctionExpressionInvocation node) {
    var callElement = node.element;
    if (callElement is MethodElement &&
        callElement.name == MethodElement.CALL_METHOD_NAME) {
      _checkForDeprecated(callElement, node);
    }
  }

  void importDirective(ImportDirective node) {
    _checkForDeprecated(node.libraryImport?.importedLibrary, node);
  }

  void indexExpression(IndexExpression node) {
    _checkForDeprecated(node.element, node);
  }

  void instanceCreationExpression(InstanceCreationExpression node) {
    _invocationArguments(node.constructorName.element, node.argumentList);
  }

  void methodInvocation(MethodInvocation node) {
    _invocationArguments(node.methodName.element, node.argumentList);
  }

  void namedType(NamedType node) {
    _checkForDeprecated(node.element, node);
  }

  void patternField(PatternField node) {
    _checkForDeprecated(node.element, node);
  }

  void popInDeprecated() {
    _inDeprecatedMemberStack.removeLast();
  }

  void postfixExpression(PostfixExpression node) {
    _checkForDeprecated(node.readElement, node.operand);
    _checkForDeprecated(node.writeElement, node.operand);
    _checkForDeprecated(node.element, node);
  }

  void prefixExpression(PrefixExpression node) {
    _checkForDeprecated(node.readElement, node.operand);
    _checkForDeprecated(node.writeElement, node.operand);
    _checkForDeprecated(node.element, node);
  }

  void pushInDeprecatedValue(bool value) {
    var newValue = _inDeprecatedMemberStack.last || value;
    _inDeprecatedMemberStack.add(newValue);
  }

  void redirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    _checkForDeprecated(node.element, node);
    _invocationArguments(node.element, node.argumentList);
  }

  void reportError(
    SyntacticEntity errorEntity,
    Element element,
    String displayName,
    String? message,
  );

  void simpleIdentifier(SimpleIdentifier node) {
    // Don't report declared identifiers.
    if (node.inDeclarationContext()) {
      return;
    }

    // Report full ConstructorName, not just the constructor name.
    var parent = node.parent;
    if (parent is ConstructorName && identical(node, parent.name)) {
      return;
    }

    // Report full SuperConstructorInvocation, not just the constructor name.
    if (parent is SuperConstructorInvocation &&
        identical(node, parent.constructorName)) {
      return;
    }

    // HideCombinator is forgiving.
    if (parent is HideCombinator) {
      return;
    }

    _simpleIdentifier(node);
  }

  void superConstructorInvocation(SuperConstructorInvocation node) {
    _checkForDeprecated(node.element, node);
    _invocationArguments(node.element, node.argumentList);
  }

  /// Reports the use of [element] at [node] if its use is deprecated.
  void _checkForDeprecated(Element? element, AstNode node) {
    if (element == null || !element.isUseDeprecated) {
      return;
    }

    if (_inDeprecatedMemberStack.last) {
      return;
    }

    if (_isLocalParameter(element, node)) {
      return;
    }

    if (element is FormalParameterElement && element.isRequired) {
      return;
    }

    SyntacticEntity errorEntity = node;
    var parent = node.parent;
    if (parent is AssignmentExpression && parent.leftHandSide == node) {
      if (node is SimpleIdentifier) {
        errorEntity = node;
      } else if (node is PrefixedIdentifier) {
        errorEntity = node.identifier;
      } else if (node is PropertyAccess) {
        errorEntity = node.propertyName;
      }
    } else if (node is ExtensionOverride) {
      errorEntity = node.name;
    } else if (node is NamedType) {
      errorEntity = node.name;
    } else if (node is NamedExpression) {
      errorEntity = node.name.label;
    } else if (node is PatternFieldImpl) {
      var fieldName = node.name;
      if (fieldName != null) {
        var name = fieldName.name;
        if (name == null) {
          var variablePattern = node.pattern.variablePattern;
          if (variablePattern != null) {
            errorEntity = variablePattern.name;
          }
        } else {
          errorEntity = name;
        }
      }
    }

    String displayName = element.displayName;
    if (element is ConstructorElement) {
      // TODO(jwren): We should modify ConstructorElement.displayName,
      // or have the logic centralized elsewhere, instead of doing this logic
      // here.
      displayName = element.name == null
          ? '${element.displayName}.new'
          : element.displayName;
    } else if (element is LibraryElement) {
      displayName = element.uri.toString();
    } else if (node is MethodInvocation &&
        displayName == MethodElement.CALL_METHOD_NAME) {
      var invokeType = node.staticInvokeType as InterfaceType;
      var invokeClass = invokeType.element;
      displayName = '${invokeClass.name}.${element.displayName}';
    }
    var message = _deprecatedMessage(element);
    reportError(errorEntity, element, displayName, message);
  }

  void _invocationArguments(Element? element, ArgumentList arguments) {
    element = element?.baseElement;
    if (element is ExecutableElement) {
      _visitParametersAndArguments(
        element.formalParameters,
        arguments.arguments,
        _checkForDeprecated,
      );
    }
  }

  void _simpleIdentifier(SimpleIdentifier identifier) {
    _checkForDeprecated(identifier.element, identifier);
  }

  /// The message in the deprecated annotation on the given [element], or
  /// `null` if the element doesn't have a deprecated annotation or if the
  /// annotation does not have a message.
  static String? _deprecatedMessage(Element element) {
    // Implicit getters/setters.
    if (element.isSynthetic && element is PropertyAccessorElement) {
      element = element.variable;
    }
    var annotation = element.metadata.annotations.firstWhereOrNull(
      (e) => e.isDeprecated,
    );
    if (annotation == null || annotation.element is PropertyAccessorElement) {
      return null;
    }
    var constantValue = annotation.computeConstantValue();
    return constantValue?.getField('message')?.toStringValue() ??
        constantValue?.getField('expires')?.toStringValue();
  }

  /// Returns whether [element] is a [FormalParameterElement] declared in
  /// [node].
  static bool _isLocalParameter(Element? element, AstNode? node) {
    if (element is FormalParameterElement) {
      var definingFunction =
          element.firstFragment.enclosingFragment?.element as ExecutableElement;

      for (; node != null; node = node.parent) {
        if (node is ConstructorDeclaration) {
          if (node.declaredFragment?.element == definingFunction) {
            return true;
          }
        } else if (node is FunctionExpression) {
          if (node.declaredFragment?.element == definingFunction) {
            return true;
          }
        } else if (node is MethodDeclaration) {
          if (node.declaredFragment?.element == definingFunction) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static void _visitParametersAndArguments(
    List<FormalParameterElement> parameters,
    List<Expression> arguments,
    void Function(FormalParameterElement, Expression) f,
  ) {
    Map<String, FormalParameterElement>? namedParameters;

    var positionalIndex = 0;
    for (var argument in arguments) {
      if (argument is NamedExpression) {
        if (namedParameters == null) {
          namedParameters = {};
          for (var parameter in parameters) {
            if (parameter.isNamed) {
              if (parameter.name case var name?) {
                namedParameters[name] = parameter;
              }
            }
          }
        }
        var name = argument.name.label.name;
        var parameter = namedParameters[name];
        if (parameter != null) {
          f(parameter, argument);
        }
      } else {
        if (positionalIndex < parameters.length) {
          var parameter = parameters[positionalIndex++];
          if (parameter.isPositional) {
            f(parameter, argument);
          }
        }
      }
    }
  }
}

class DeprecatedMemberUseVerifier extends BaseDeprecatedMemberUseVerifier {
  final WorkspacePackageImpl? _workspacePackage;
  final DiagnosticReporter _diagnosticReporter;

  DeprecatedMemberUseVerifier(this._workspacePackage, this._diagnosticReporter);

  @override
  void reportError(
    SyntacticEntity errorEntity,
    Element element,
    String displayName,
    String? message,
  ) {
    var library = element is LibraryElement ? element : element.library;

    message = message?.trim();
    if (message == null || message.isEmpty || message == '.') {
      _diagnosticReporter.atEntity(
        errorEntity,
        _isLibraryInWorkspacePackage(library)
            ? HintCode.deprecatedMemberUseFromSamePackage
            : HintCode.deprecatedMemberUse,
        arguments: [displayName],
      );
    } else {
      if (!message.endsWith('.') &&
          !message.endsWith('?') &&
          !message.endsWith('!')) {
        message = '$message.';
      }
      _diagnosticReporter.atEntity(
        errorEntity,
        _isLibraryInWorkspacePackage(library)
            ? HintCode.deprecatedMemberUseFromSamePackageWithMessage
            : HintCode.deprecatedMemberUseWithMessage,
        arguments: [displayName, message],
      );
    }
  }

  bool _isLibraryInWorkspacePackage(LibraryElement? library) {
    // Better to not make a big claim that they _are_ in the same package,
    // if we were unable to determine what package [_currentLibrary] is in.
    if (_workspacePackage == null || library == null) {
      return false;
    }
    library as LibraryElementImpl;
    return _workspacePackage.contains(library.internal.firstFragment.source);
  }
}
