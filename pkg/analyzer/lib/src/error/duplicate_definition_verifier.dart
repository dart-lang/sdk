// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';

class DuplicateDefinitionVerifier {
  final InheritanceManager3 _inheritanceManager;
  final LibraryElement _currentLibrary;
  final ErrorReporter _errorReporter;
  final DuplicationDefinitionContext context;

  final DiagnosticFactory _diagnosticFactory = DiagnosticFactory();

  DuplicateDefinitionVerifier(
    this._inheritanceManager,
    this._currentLibrary,
    this._errorReporter,
    this.context,
  );

  /// Check that the exception and stack trace parameters have different names.
  void checkCatchClause(CatchClause node) {
    var exceptionParameter = node.exceptionParameter;
    var stackTraceParameter = node.stackTraceParameter;
    if (exceptionParameter != null && stackTraceParameter != null) {
      String exceptionName = exceptionParameter.name.lexeme;
      if (exceptionName == stackTraceParameter.name.lexeme) {
        _errorReporter.reportError(_diagnosticFactory
            .duplicateDefinitionForNodes(
                _errorReporter.source,
                CompileTimeErrorCode.DUPLICATE_DEFINITION,
                stackTraceParameter,
                exceptionParameter,
                [exceptionName]));
      }
    }
  }

  void checkClass(ClassDeclaration node) {
    _checkClassMembers(node.declaredElement!, node.members);
  }

  /// Check that there are no members with the same name.
  void checkEnum(EnumDeclaration node) {
    var element = node.declaredElement!;
    var augmented = element.augmented;
    var declarationElement = augmented.declaration;
    var declarationName = declarationElement.name;

    var constructorNames = <String>{};
    var instanceGetters = <String, Element>{};
    var instanceSetters = <String, Element>{};
    var staticGetters = <String, Element>{};
    var staticSetters = <String, Element>{};

    for (EnumConstantDeclaration constant in node.constants) {
      _checkDuplicateIdentifier(staticGetters, constant.name,
          element: constant.declaredElement!);
      _checkValuesDeclarationInEnum(constant.name);
    }

    for (var member in node.members) {
      if (member is ConstructorDeclaration) {
        if (member.returnType.name == declarationElement.name) {
          var name = member.declaredElement!.name;
          if (!constructorNames.add(name)) {
            if (name.isEmpty) {
              _errorReporter.reportErrorForName(
                CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT,
                member,
              );
            } else {
              _errorReporter.reportErrorForName(
                CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME,
                member,
                arguments: [name],
              );
            }
          }
        }
      } else if (member is FieldDeclaration) {
        for (var field in member.fields.variables) {
          var identifier = field.name;
          _checkDuplicateIdentifier(
            member.isStatic ? staticGetters : instanceGetters,
            identifier,
            element: field.declaredElement!,
            setterScope: member.isStatic ? staticSetters : instanceSetters,
          );
          _checkValuesDeclarationInEnum(identifier);
        }
      } else if (member is MethodDeclaration) {
        _checkDuplicateIdentifier(
          member.isStatic ? staticGetters : instanceGetters,
          member.name,
          element: member.declaredElement!,
          setterScope: member.isStatic ? staticSetters : instanceSetters,
        );
        if (!(member.isStatic && member.isSetter)) {
          _checkValuesDeclarationInEnum2(member.name);
        }
      }
    }

    if (declarationName == 'values') {
      _errorReporter.atToken(
        node.name,
        CompileTimeErrorCode.ENUM_WITH_NAME_VALUES,
      );
    }

    for (var constant in node.constants) {
      if (constant.name.lexeme == declarationName) {
        _errorReporter.atToken(
          constant.name,
          CompileTimeErrorCode.ENUM_CONSTANT_SAME_NAME_AS_ENCLOSING,
        );
      }
    }

    _checkConflictingConstructorAndStatic(
      interfaceElement: declarationElement,
      staticGetters: staticGetters,
      staticSetters: staticSetters,
    );

    for (var accessor in declarationElement.accessors) {
      var baseName = accessor.displayName;
      if (accessor.isStatic) {
        var instance = _getInterfaceMember(declarationElement, baseName);
        if (instance != null && baseName != 'values') {
          _errorReporter.atElement(
            accessor,
            CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
            arguments: [declarationName, baseName, declarationName],
          );
        }
      } else {
        var inherited = _getInheritedMember(declarationElement, baseName);
        if (inherited is MethodElement) {
          _errorReporter.atElement(
            accessor,
            CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD,
            arguments: [
              declarationElement.displayName,
              baseName,
              inherited.enclosingElement.displayName,
            ],
          );
        }
      }
    }

    for (var method in declarationElement.methods) {
      var baseName = method.displayName;
      if (method.isStatic) {
        var instance = _getInterfaceMember(declarationElement, baseName);
        if (instance != null) {
          _errorReporter.atElement(
            method,
            CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
            arguments: [declarationName, baseName, declarationName],
          );
        }
      } else {
        var inherited = _getInheritedMember(declarationElement, baseName);
        if (inherited is PropertyAccessorElement) {
          _errorReporter.atElement(
            method,
            CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD,
            arguments: [
              declarationElement.displayName,
              baseName,
              inherited.enclosingElement.displayName,
            ],
          );
        }
      }
    }
  }

  /// Check that there are no members with the same name.
  void checkExtension(ExtensionDeclaration node) {
    var instanceGetters = <String, Element>{};
    var instanceSetters = <String, Element>{};
    var staticGetters = <String, Element>{};
    var staticSetters = <String, Element>{};

    for (var member in node.members) {
      if (member is FieldDeclaration) {
        for (var field in member.fields.variables) {
          var identifier = field.name;
          _checkDuplicateIdentifier(
            member.isStatic ? staticGetters : instanceGetters,
            identifier,
            element: field.declaredElement!,
            setterScope: member.isStatic ? staticSetters : instanceSetters,
          );
        }
      } else if (member is MethodDeclaration) {
        _checkDuplicateIdentifier(
          member.isStatic ? staticGetters : instanceGetters,
          member.name,
          element: member.declaredElement!,
          setterScope: member.isStatic ? staticSetters : instanceSetters,
        );
      }
    }

    // Check for local static members conflicting with local instance members.
    for (var member in node.members) {
      if (member is FieldDeclaration) {
        if (member.isStatic) {
          for (var field in member.fields.variables) {
            var identifier = field.name;
            var name = identifier.lexeme;
            if (instanceGetters.containsKey(name) ||
                instanceSetters.containsKey(name)) {
              _errorReporter.atToken(
                identifier,
                CompileTimeErrorCode.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE,
                arguments: [name],
              );
            }
          }
        }
      } else if (member is MethodDeclaration) {
        if (member.isStatic) {
          var identifier = member.name;
          var name = identifier.lexeme;
          if (instanceGetters.containsKey(name) ||
              instanceSetters.containsKey(name)) {
            _errorReporter.atToken(
              identifier,
              CompileTimeErrorCode.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE,
              arguments: [name],
            );
          }
        }
      }
    }
  }

  void checkExtensionType(
    ExtensionTypeDeclaration node,
    ExtensionTypeElement element,
  ) {
    var declarationElement = element.augmented.declaration;
    var primaryConstructorName = element.constructors.first.name;
    var representationGetter = element.representation.getter!;
    _getElementContext(declarationElement)
      ..constructorNames.add(primaryConstructorName)
      ..instanceGetters[representationGetter.name] = representationGetter;

    _checkClassMembers(element, node.members);
  }

  /// Check that the given list of variable declarations does not define
  /// multiple variables of the same name.
  void checkForVariables(VariableDeclarationList node) {
    Map<String, Element> definedNames = HashMap<String, Element>();
    for (VariableDeclaration variable in node.variables) {
      _checkDuplicateIdentifier(definedNames, variable.name,
          element: variable.declaredElement!);
    }
  }

  void checkMixin(MixinDeclaration node) {
    _checkClassMembers(node.declaredElement!, node.members);
  }

  /// Check that all of the parameters have unique names.
  void checkParameters(FormalParameterList node) {
    Map<String, Element> definedNames = HashMap<String, Element>();
    for (FormalParameter parameter in node.parameters) {
      var identifier = parameter.name;
      if (identifier != null) {
        // The identifier can be null if this is a parameter list for a generic
        // function type.
        _checkDuplicateIdentifier(definedNames, identifier,
            element: parameter.declaredElement!);
      }
    }
  }

  /// Check that all of the variables have unique names.
  void checkStatements(List<Statement> statements) {
    Map<String, Element> definedNames = HashMap<String, Element>();
    for (Statement statement in statements) {
      if (statement is VariableDeclarationStatement) {
        for (VariableDeclaration variable in statement.variables.variables) {
          _checkDuplicateIdentifier(definedNames, variable.name,
              element: variable.declaredElement!);
        }
      } else if (statement is FunctionDeclarationStatement) {
        _checkDuplicateIdentifier(
          definedNames,
          statement.functionDeclaration.name,
          element: statement.functionDeclaration.declaredElement!,
        );
      } else if (statement is PatternVariableDeclarationStatementImpl) {
        for (var variable in statement.declaration.elements) {
          _checkDuplicateIdentifier(definedNames, variable.node.name,
              element: variable);
        }
      }
    }
  }

  /// Check that all of the parameters have unique names.
  void checkTypeParameters(TypeParameterList node) {
    Map<String, Element> definedNames = HashMap<String, Element>();
    for (TypeParameter parameter in node.typeParameters) {
      _checkDuplicateIdentifier(definedNames, parameter.name,
          element: parameter.declaredElement!);
    }
  }

  /// Check that there are no members with the same name.
  void checkUnit(CompilationUnit node) {
    Map<String, Element> definedGetters = HashMap<String, Element>();
    Map<String, Element> definedSetters = HashMap<String, Element>();

    void addWithoutChecking(CompilationUnitElement element) {
      for (PropertyAccessorElement accessor in element.accessors) {
        String name = accessor.name;
        if (accessor.isSetter) {
          name += '=';
        }
        definedGetters[name] = accessor;
      }
      for (ClassElement class_ in element.classes) {
        definedGetters[class_.name] = class_;
      }
      for (var type in element.enums) {
        definedGetters[type.name] = type;
      }
      for (FunctionElement function in element.functions) {
        definedGetters[function.name] = function;
      }
      for (TopLevelVariableElement variable in element.topLevelVariables) {
        definedGetters[variable.name] = variable;
        if (!variable.isFinal && !variable.isConst) {
          definedGetters['${variable.name}='] = variable;
        }
      }
      for (TypeAliasElement alias in element.typeAliases) {
        definedGetters[alias.name] = alias;
      }
    }

    for (var importElement in _currentLibrary.libraryImports) {
      var prefix = importElement.prefix?.element;
      if (prefix != null) {
        definedGetters[prefix.name] = prefix;
      }
    }
    CompilationUnitElement element = node.declaredElement!;
    if (element != _currentLibrary.definingCompilationUnit) {
      addWithoutChecking(_currentLibrary.definingCompilationUnit);
      for (var unitElement in _currentLibrary.units) {
        if (element == unitElement) {
          break;
        }
        addWithoutChecking(unitElement);
      }
    }
    for (CompilationUnitMember member in node.declarations) {
      if (member is ExtensionDeclaration) {
        var identifier = member.name;
        if (identifier != null) {
          _checkDuplicateIdentifier(definedGetters, identifier,
              element: member.declaredElement!, setterScope: definedSetters);
        }
      } else if (member is NamedCompilationUnitMember) {
        _checkDuplicateIdentifier(definedGetters, member.name,
            element: member.declaredElement!, setterScope: definedSetters);
      } else if (member is TopLevelVariableDeclaration) {
        for (VariableDeclaration variable in member.variables.variables) {
          _checkDuplicateIdentifier(definedGetters, variable.name,
              element: variable.declaredElement!, setterScope: definedSetters);
        }
      }
    }
  }

  /// Check that there are no members with the same name.
  void _checkClassMembers(InterfaceElement element, List<ClassMember> members) {
    var declarationElement = element.augmented.declaration;
    var elementContext = _getElementContext(declarationElement);
    var constructorNames = elementContext.constructorNames;
    var instanceGetters = elementContext.instanceGetters;
    var instanceSetters = elementContext.instanceSetters;
    var staticGetters = elementContext.staticGetters;
    var staticSetters = elementContext.staticSetters;

    for (ClassMember member in members) {
      switch (member) {
        case ConstructorDeclaration():
          // Augmentations are not declarations, can have multiple.
          if (member.augmentKeyword != null) {
            continue;
          }
          if (member.returnType.name != declarationElement.name) {
            // [member] is erroneous; do not count it as a possible duplicate.
            continue;
          }
          var name = member.name?.lexeme ?? '';
          if (name == 'new') {
            name = '';
          }
          if (!constructorNames.add(name)) {
            if (name.isEmpty) {
              _errorReporter.reportErrorForName(
                  CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, member);
            } else {
              _errorReporter.reportErrorForName(
                  CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME, member,
                  arguments: [name]);
            }
          }
        case FieldDeclaration():
          for (VariableDeclaration field in member.fields.variables) {
            _checkDuplicateIdentifier(
              member.isStatic ? staticGetters : instanceGetters,
              field.name,
              element: field.declaredElement!,
              setterScope: member.isStatic ? staticSetters : instanceSetters,
            );
          }
        case MethodDeclaration():
          _checkDuplicateIdentifier(
            member.isStatic ? staticGetters : instanceGetters,
            member.name,
            element: member.declaredElement!,
            setterScope: member.isStatic ? staticSetters : instanceSetters,
          );
      }
    }

    _checkConflictingConstructorAndStatic(
      interfaceElement: declarationElement,
      staticGetters: staticGetters,
      staticSetters: staticSetters,
    );

    // Check for local static members conflicting with local instance members.
    // TODO(scheglov): This code is duplicated for enums. But for classes it is
    // separated also into ErrorVerifier - where we check inherited.
    for (ClassMember member in members) {
      if (member is FieldDeclaration) {
        if (member.isStatic) {
          for (VariableDeclaration field in member.fields.variables) {
            var identifier = field.name;
            String name = identifier.lexeme;
            if (instanceGetters.containsKey(name) ||
                instanceSetters.containsKey(name)) {
              String className = declarationElement.displayName;
              _errorReporter.atToken(
                identifier,
                CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
                arguments: [className, name, className],
              );
            }
          }
        }
      } else if (member is MethodDeclaration) {
        if (member.isStatic) {
          var identifier = member.name;
          String name = identifier.lexeme;
          if (instanceGetters.containsKey(name) ||
              instanceSetters.containsKey(name)) {
            String className = declarationElement.name;
            _errorReporter.atToken(
              identifier,
              CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
              arguments: [className, name, className],
            );
          }
        }
      }
    }
  }

  void _checkConflictingConstructorAndStatic({
    required InterfaceElement interfaceElement,
    required Map<String, Element> staticGetters,
    required Map<String, Element> staticSetters,
  }) {
    for (var constructor in interfaceElement.constructors) {
      var name = constructor.name;
      var staticMember = staticGetters[name] ?? staticSetters[name];
      if (staticMember is PropertyAccessorElement) {
        CompileTimeErrorCode errorCode;
        if (staticMember.isSynthetic) {
          errorCode =
              CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD;
        } else if (staticMember.isGetter) {
          errorCode =
              CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_GETTER;
        } else {
          errorCode =
              CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_SETTER;
        }
        _errorReporter.atElement(
          constructor,
          errorCode,
          arguments: [name],
        );
      } else if (staticMember is MethodElement) {
        _errorReporter.atElement(
          constructor,
          CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD,
          arguments: [name],
        );
      }
    }
  }

  /// Check whether the given [element] defined by the [identifier] is already
  /// in one of the scopes - [getterScope] or [setterScope], and produce an
  /// error if it is.
  void _checkDuplicateIdentifier(
      Map<String, Element> getterScope, Token identifier,
      {required Element element, Map<String, Element>? setterScope}) {
    if (identifier.isSynthetic) {
      return;
    }

    switch (element) {
      case ExecutableElement _:
        if (element.isAugmentation) return;
      case FieldElement _:
        if (element.isAugmentation) return;
      case InstanceElement _:
        if (element.isAugmentation) return;
      case TypeAliasElement _:
        if (element.isAugmentation) return;
      case TopLevelVariableElement _:
        if (element.isAugmentation) return;
    }

    // Fields define getters and setters, so check them separately.
    if (element is PropertyInducingElement) {
      _checkDuplicateIdentifier(getterScope, identifier,
          element: element.getter!, setterScope: setterScope);
      if (!element.isConst && !element.isFinal) {
        _checkDuplicateIdentifier(getterScope, identifier,
            element: element.setter!, setterScope: setterScope);
      }
      return;
    }

    ErrorCode getError(Element previous, Element current) {
      if (previous is FieldFormalParameterElement &&
          current is FieldFormalParameterElement) {
        return CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER;
      } else if (previous is PrefixElement) {
        return CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER;
      }
      return CompileTimeErrorCode.DUPLICATE_DEFINITION;
    }

    var name = identifier.lexeme;
    if (element is MethodElement) {
      name = element.name;
    }

    var previous = getterScope[name];
    if (previous != null) {
      if (!_isGetterSetterPair(element, previous)) {
        _errorReporter.reportError(_diagnosticFactory.duplicateDefinition(
          getError(previous, element),
          element,
          previous,
          [name],
        ));
      }
    } else {
      getterScope[name] = element;
    }

    if (setterScope != null) {
      if (element is PropertyAccessorElement && element.isSetter) {
        previous = setterScope[name];
        if (previous != null) {
          _errorReporter.reportError(_diagnosticFactory.duplicateDefinition(
            getError(previous, element),
            element,
            previous,
            [name],
          ));
        } else {
          setterScope[name] = element;
        }
      }
    }
  }

  void _checkValuesDeclarationInEnum(Token name) {
    if (name.lexeme == 'values') {
      _errorReporter.atToken(
        name,
        CompileTimeErrorCode.VALUES_DECLARATION_IN_ENUM,
      );
    }
  }

  void _checkValuesDeclarationInEnum2(Token name) {
    if (name.lexeme == 'values') {
      _errorReporter.atToken(
        name,
        CompileTimeErrorCode.VALUES_DECLARATION_IN_ENUM,
      );
    }
  }

  _InterfaceElementContext _getElementContext(InterfaceElement element) {
    return context._interfaceElementContexts[element] ??=
        _InterfaceElementContext();
  }

  ExecutableElement? _getInheritedMember(
      InterfaceElement element, String baseName) {
    var libraryUri = _currentLibrary.source.uri;

    var getterName = Name(libraryUri, baseName);
    var getter = _inheritanceManager.getInherited2(element, getterName);
    if (getter != null) {
      return getter;
    }

    var setterName = Name(libraryUri, '$baseName=');
    return _inheritanceManager.getInherited2(element, setterName);
  }

  ExecutableElement? _getInterfaceMember(
      InterfaceElement element, String baseName) {
    var libraryUri = _currentLibrary.source.uri;

    var getterName = Name(libraryUri, baseName);
    var getter = _inheritanceManager.getMember2(element, getterName);
    if (getter != null) {
      return getter;
    }

    var setterName = Name(libraryUri, '$baseName=');
    return _inheritanceManager.getMember2(element, setterName);
  }

  static bool _isGetterSetterPair(Element a, Element b) {
    if (a is PropertyAccessorElement && b is PropertyAccessorElement) {
      return a.isGetter && b.isSetter || a.isSetter && b.isGetter;
    }
    return false;
  }
}

/// Information to pass from declarations to augmentations.
class DuplicationDefinitionContext {
  final Map<InterfaceElement, _InterfaceElementContext>
      _interfaceElementContexts = {};
}

/// Information accumulated for a single declaration and its augmentations.
class _InterfaceElementContext {
  final Set<String> constructorNames = {};
  final Map<String, Element> instanceGetters = {};
  final Map<String, Element> instanceSetters = {};
  final Map<String, Element> staticGetters = {};
  final Map<String, Element> staticSetters = {};
}
