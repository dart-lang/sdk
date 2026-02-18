// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/src/error/deprecated_member_use_verifier.dart';
library;

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer/workspace/workspace.dart';
import 'package:collection/collection.dart';

/// Algorithm for detecting usages of a set of elements.
class ElementUsageDetector<TagInfo extends Object> {
  /// Description of the current workspace.
  ///
  /// This is used to compute the value of the `isInSamePackage` parameter of
  /// [ElementUsageReporter.report].
  ///
  /// If not supplied, then `false` will be passed for the `isInSamePackage`
  /// parameter of [ElementUsageReporter.report].
  final WorkspacePackage? _workspacePackage;

  /// The set of elements to detect usages of.
  final ElementUsageSet<TagInfo> elementUsageSet;

  /// What to do when a usage of an element in [elementUsageSet] is detected.
  final ElementUsageReporter<TagInfo> elementUsageReporter;

  ElementUsageDetector({
    required WorkspacePackage? workspacePackage,
    required this.elementUsageSet,
    required this.elementUsageReporter,
  }) : _workspacePackage = workspacePackage;

  void assignmentExpression(AssignmentExpression node) {
    checkUsage(node.readElement, node.leftHandSide);
    checkUsage(node.writeElement, node.leftHandSide);
    checkUsage(node.element, node);
  }

  void binaryExpression(BinaryExpression node) {
    checkUsage(node.element, node);
  }

  /// Reports the usage of [element] at [node] if [element] is in
  /// [elementUsageSet].
  void checkUsage(Element? element, AstNode node) {
    if (element == null) {
      return;
    }
    // Implicit getters/setters.
    if (element is PropertyAccessorElement && element.isOriginVariable) {
      element = element.variable;
    }
    var tagInfo = elementUsageSet.getTagInfo(element);
    if (tagInfo == null) return;

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

    // TODO(srawlins): Consider `node` being a `ConstructorDeclaration`, and use
    // `ConstructorDeclaration.errorRange` here. This would stray from the API
    // of passing a SyntacticEntity here.

    elementUsageReporter.report(
      errorEntity,
      displayName,
      tagInfo,
      isInSamePackage: _isLibraryInWorkspacePackage(element.library),
      isInTestDirectory:
          node.thisOrAncestorOfType<CompilationUnit>()?.inTestDir ?? false,
    );
  }

  void constructorDeclaration(ConstructorDeclaration node) {
    // Check usage of any implicit super-constructor call.
    // There is only an implicit super-constructor if:
    // * this is not a factory constructor,
    // * there is no redirecting constructor invocation, and
    // * there is no explicit super constructor invocation.
    if (node.factoryKeyword != null) return;
    var hasConstructorInvocation = node.initializers.any(
      (i) =>
          i is SuperConstructorInvocation ||
          i is RedirectingConstructorInvocation,
    );
    if (hasConstructorInvocation) return;

    checkUsage(node.declaredFragment!.element.superConstructor, node);
  }

  void constructorName(ConstructorName node) {
    checkUsage(node.element, node);
  }

  void dotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    if (node.element?.enclosingElement case var interfaceElement?) {
      // A dot-shorthand constructor invocation contains an implicit reference
      // to the interface on which the constructor was declared.
      checkUsage(interfaceElement, node);
    }
    _invocationArguments(node.constructorName.element, node.argumentList);
  }

  void dotShorthandInvocation(DotShorthandInvocation node) {
    if (node.memberName.element?.enclosingElement case var interfaceElement?) {
      // A dot-shorthand invocation contains an implicit reference to the
      // interface on which the constructor was declared.
      checkUsage(interfaceElement, node);
    }
    _invocationArguments(node.memberName.element, node.argumentList);
  }

  void dotShorthandPropertyAccess(DotShorthandPropertyAccess node) {
    if (node.propertyName.element?.enclosingElement
        case var interfaceElement?) {
      // A dot-shorthand property access contains an implicit reference to the
      // interface on which the constructor was declared.
      checkUsage(interfaceElement, node);
    }
  }

  void exportDirective(ExportDirective node) {
    checkUsage(node.libraryExport?.exportedLibrary, node);
  }

  void extensionOverride(ExtensionOverride node) {
    checkUsage(node.element, node);
  }

  void formalParameter(FormalParameter node) {
    if (node.parent case DefaultFormalParameter defaultFormalParameter) {
      node = defaultFormalParameter;
    }
    var parent = node.parent;
    if (parent is! FormalParameterList) return;
    if (parent.parent case ConstructorDeclaration constructor) {
      if (constructor.redirectedConstructor?.element
          case var redirectedConstructor?) {
        if (node.isNamed) {
          var redirectedParameter = redirectedConstructor.formalParameters
              .firstWhereOrNull(
                (p) => p.isNamed && p.name == node.name?.lexeme,
              );
          checkUsage(redirectedParameter, node);
        } else {
          // Positional.
          var position = parent.parameters.indexOf(node);
          if (position < 0) return;
          if (position >= redirectedConstructor.formalParameters.length) {
            return;
          }
          var redirectedParameter =
              redirectedConstructor.formalParameters[position];
          if (!redirectedParameter.isPositional) return;
          checkUsage(redirectedParameter, node);
        }
      }
    }
  }

  void functionExpressionInvocation(FunctionExpressionInvocation node) {
    var callElement = node.element;
    if (callElement is MethodElement &&
        callElement.name == MethodElement.CALL_METHOD_NAME) {
      checkUsage(callElement, node);
    }
  }

  void importDirective(ImportDirective node) {
    checkUsage(node.libraryImport?.importedLibrary, node);
  }

  void indexExpression(IndexExpression node) {
    checkUsage(node.element, node);
  }

  void instanceCreationExpression(InstanceCreationExpression node) {
    _invocationArguments(node.constructorName.element, node.argumentList);
  }

  void methodInvocation(MethodInvocation node) {
    _invocationArguments(node.methodName.element, node.argumentList);
  }

  void namedType(NamedType node) {
    checkUsage(node.element, node);
  }

  void patternField(PatternField node) {
    checkUsage(node.element, node);
  }

  void postfixExpression(PostfixExpression node) {
    checkUsage(node.readElement, node.operand);
    checkUsage(node.writeElement, node.operand);
    checkUsage(node.element, node);
  }

  void prefixExpression(PrefixExpression node) {
    checkUsage(node.readElement, node.operand);
    checkUsage(node.writeElement, node.operand);
    checkUsage(node.element, node);
  }

  void redirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    checkUsage(node.element, node);
    _invocationArguments(node.element, node.argumentList);
  }

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
    checkUsage(node.element, node);
    _invocationArguments(node.element, node.argumentList);
  }

  void superFormalParameter(SuperFormalParameter node) {
    checkUsage(node.declaredFragment!.element.superConstructorParameter, node);
  }

  void _invocationArguments(Element? element, ArgumentList arguments) {
    element = element?.baseElement;
    if (element is ExecutableElement) {
      _visitParametersAndArguments(
        element.formalParameters,
        arguments.arguments,
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

  void _simpleIdentifier(SimpleIdentifier identifier) {
    checkUsage(identifier.element, identifier);
  }

  void _visitParametersAndArguments(
    List<FormalParameterElement> parameters,
    List<Expression> arguments,
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
          checkUsage(parameter, argument);
        }
      } else {
        if (positionalIndex < parameters.length) {
          var parameter = parameters[positionalIndex++];
          if (parameter.isPositional) {
            checkUsage(parameter, argument);
          }
        }
      }
    }
  }

  /// Returns whether [element] is a [FormalParameterElement] declared in
  /// [node].
  static bool _isLocalParameter(Element? element, AstNode? node) {
    if (element is FormalParameterElement) {
      var definingFunction = element.enclosingElement;

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
        } else if (node is PrimaryConstructorBody) {
          if (node.declaration?.declaredFragment?.element == definingFunction) {
            return true;
          }
        }
      }
    }
    return false;
  }
}

/// Strategy class that specifies what [ElementUsageDetector] should do when it
/// detects the use of a tagged element.
///
/// For example, [DeprecatedElementUsageReporter] can be used to specify that
/// [ElementUsageDetector] should report "use of deprecated member" warnings.
///
/// [TagInfo] is the type of auxiliary information that can be associated with
/// an element (for example, deprecated elements can be associated with a text
/// string). It should match the [TagInfo] parameter to [ElementUsageSet].
abstract class ElementUsageReporter<TagInfo extends Object> {
  /// Reports an element usage detected by [ElementUsageDetector].
  ///
  /// [usageSite] is the source code location where the usage is located.
  /// [displayName] is the name of the element that was used. [tagInfo] is the
  /// tag information returned by [ElementUsageSet.getTagInfo].
  /// [isInSamePackage] indicates whether the element and its usage are in
  /// the same package.
  /// [isInTestDirectory] indicates whether the usage of the element is in a
  /// "test" directory, according to [CompilationUnitExtension.inTestDir].
  void report(
    SyntacticEntity usageSite,
    String displayName,
    TagInfo tagInfo, {
    required bool isInSamePackage,
    required bool isInTestDirectory,
  });
}

/// Strategy class that specifies the set of elements that
/// [ElementUsageDetector] should detect usages of.
///
/// For example, [DeprecatedElementUsageSet] can be used to specify that
/// [ElementUsageDetector] should detect usages of deprecated elements.
///
/// [TagInfo] is the type of auxiliary information associated with an element in
/// the set (for example, deprecated elements can be associated with a text
/// string). If there is no auxiliary information, supply `()` for this type
/// parameter.
abstract class ElementUsageSet<TagInfo extends Object> {
  /// If [element] is in the set of elements that [ElementUsageDetector] should
  /// detect usages of, returns auxiliary information associated with [element].
  ///
  /// Otherwise returns `null`.
  ///
  /// For example, [DeprecatedElementUsageSet]'s implementation of this method
  /// returns the deprecation message if [element] is deprecated.
  TagInfo? getTagInfo(Element element);
}
