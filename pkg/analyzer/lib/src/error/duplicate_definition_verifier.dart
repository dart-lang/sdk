// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/error/codes.dart';

class DuplicateDefinitionVerifier {
  static final Set<String> _enumInstanceMembers = {
    'hashCode',
    'index',
    'noSuchMethod',
    'runtimeType',
    'toString',
  };

  final LibraryElement _currentLibrary;
  final ErrorReporter _errorReporter;

  DuplicateDefinitionVerifier(this._currentLibrary, this._errorReporter);

  /// Check that the exception and stack trace parameters have different names.
  void checkCatchClause(CatchClause node) {
    SimpleIdentifier exceptionParameter = node.exceptionParameter;
    SimpleIdentifier stackTraceParameter = node.stackTraceParameter;
    if (exceptionParameter != null && stackTraceParameter != null) {
      String exceptionName = exceptionParameter.name;
      if (exceptionName == stackTraceParameter.name) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.DUPLICATE_DEFINITION,
            stackTraceParameter,
            [exceptionName]);
      }
    }
  }

  void checkClass(ClassDeclaration node) {
    _checkClassMembers(node.declaredElement, node.members);
  }

  /// Check that there are no members with the same name.
  void checkEnum(EnumDeclaration node) {
    ClassElement element = node.declaredElement;

    Map<String, Element> staticGetters = {
      'values': element.getGetter('values')
    };

    for (EnumConstantDeclaration constant in node.constants) {
      _checkDuplicateIdentifier(staticGetters, constant.name);
    }

    String enumName = element.name;
    for (EnumConstantDeclaration constant in node.constants) {
      SimpleIdentifier identifier = constant.name;
      String name = identifier.name;
      if (name == enumName) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ENUM_CONSTANT_SAME_NAME_AS_ENCLOSING,
          identifier,
        );
      } else if (_enumInstanceMembers.contains(name)) {
        _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
          identifier,
          [enumName, name, enumName],
        );
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
            setterScope: member.isStatic ? staticSetters : instanceSetters,
          );
        }
      } else if (member is MethodDeclaration) {
        _checkDuplicateIdentifier(
          member.isStatic ? staticGetters : instanceGetters,
          member.name,
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
            var name = identifier.name;
            if (instanceGetters.containsKey(name) ||
                instanceSetters.containsKey(name)) {
              _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE,
                identifier,
                [node.declaredElement.name, name],
              );
            }
          }
        }
      } else if (member is MethodDeclaration) {
        if (member.isStatic) {
          var identifier = member.name;
          var name = identifier.name;
          if (instanceGetters.containsKey(name) ||
              instanceSetters.containsKey(name)) {
            _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE,
              identifier,
              [node.declaredElement.name, name],
            );
          }
        }
      }
    }
  }

  /// Check that the given list of variable declarations does not define
  /// multiple variables of the same name.
  void checkForVariables(VariableDeclarationList node) {
    Map<String, Element> definedNames = HashMap<String, Element>();
    for (VariableDeclaration variable in node.variables) {
      _checkDuplicateIdentifier(definedNames, variable.name);
    }
  }

  void checkMixin(MixinDeclaration node) {
    _checkClassMembers(node.declaredElement, node.members);
  }

  /// Check that all of the parameters have unique names.
  void checkParameters(FormalParameterList node) {
    Map<String, Element> definedNames = HashMap<String, Element>();
    for (FormalParameter parameter in node.parameters) {
      SimpleIdentifier identifier = parameter.identifier;
      if (identifier != null) {
        // The identifier can be null if this is a parameter list for a generic
        // function type.
        _checkDuplicateIdentifier(definedNames, identifier);
      }
    }
  }

  /// Check that all of the variables have unique names.
  void checkStatements(List<Statement> statements) {
    Map<String, Element> definedNames = HashMap<String, Element>();
    for (Statement statement in statements) {
      if (statement is VariableDeclarationStatement) {
        for (VariableDeclaration variable in statement.variables.variables) {
          _checkDuplicateIdentifier(definedNames, variable.name);
        }
      } else if (statement is FunctionDeclarationStatement) {
        _checkDuplicateIdentifier(
            definedNames, statement.functionDeclaration.name);
      }
    }
  }

  /// Check that all of the parameters have unique names.
  void checkTypeParameters(TypeParameterList node) {
    Map<String, Element> definedNames = HashMap<String, Element>();
    for (TypeParameter parameter in node.typeParameters) {
      _checkDuplicateIdentifier(definedNames, parameter.name);
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
      for (ClassElement type in element.enums) {
        definedGetters[type.name] = type;
      }
      for (FunctionElement function in element.functions) {
        definedGetters[function.name] = function;
      }
      for (FunctionTypeAliasElement alias in element.functionTypeAliases) {
        definedGetters[alias.name] = alias;
      }
      for (TopLevelVariableElement variable in element.topLevelVariables) {
        definedGetters[variable.name] = variable;
        if (!variable.isFinal && !variable.isConst) {
          definedGetters[variable.name + '='] = variable;
        }
      }
      for (ClassElement type in element.types) {
        definedGetters[type.name] = type;
      }
    }

    for (ImportElement importElement in _currentLibrary.imports) {
      PrefixElement prefix = importElement.prefix;
      if (prefix != null) {
        definedGetters[prefix.name] = prefix;
      }
    }
    CompilationUnitElement element = node.declaredElement;
    if (element != _currentLibrary.definingCompilationUnit) {
      addWithoutChecking(_currentLibrary.definingCompilationUnit);
      for (CompilationUnitElement part in _currentLibrary.parts) {
        if (element == part) {
          break;
        }
        addWithoutChecking(part);
      }
    }
    for (CompilationUnitMember member in node.declarations) {
      if (member is ExtensionDeclaration) {
        var identifier = member.name;
        if (identifier != null) {
          _checkDuplicateIdentifier(definedGetters, identifier,
              setterScope: definedSetters);
        }
      } else if (member is NamedCompilationUnitMember) {
        _checkDuplicateIdentifier(definedGetters, member.name,
            setterScope: definedSetters);
      } else if (member is TopLevelVariableDeclaration) {
        for (VariableDeclaration variable in member.variables.variables) {
          _checkDuplicateIdentifier(definedGetters, variable.name,
              setterScope: definedSetters);
        }
      }
    }
  }

  /// Check that there are no members with the same name.
  void _checkClassMembers(ClassElement element, List<ClassMember> members) {
    Set<String> constructorNames = HashSet<String>();
    Map<String, Element> instanceGetters = HashMap<String, Element>();
    Map<String, Element> instanceSetters = HashMap<String, Element>();
    Map<String, Element> staticGetters = HashMap<String, Element>();
    Map<String, Element> staticSetters = HashMap<String, Element>();

    for (ClassMember member in members) {
      if (member is ConstructorDeclaration) {
        var name = member.name?.name ?? '';
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
      } else if (member is FieldDeclaration) {
        for (VariableDeclaration field in member.fields.variables) {
          SimpleIdentifier identifier = field.name;
          _checkDuplicateIdentifier(
            member.isStatic ? staticGetters : instanceGetters,
            identifier,
            setterScope: member.isStatic ? staticSetters : instanceSetters,
          );
        }
      } else if (member is MethodDeclaration) {
        _checkDuplicateIdentifier(
          member.isStatic ? staticGetters : instanceGetters,
          member.name,
          setterScope: member.isStatic ? staticSetters : instanceSetters,
        );
      }
    }

    // Check for local static members conflicting with local instance members.
    for (ClassMember member in members) {
      if (member is ConstructorDeclaration) {
        if (member.name != null) {
          String name = member.name.name;
          var staticMember = staticGetters[name] ?? staticSetters[name];
          if (staticMember != null) {
            if (staticMember is PropertyAccessorElement) {
              _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD,
                member.name,
                [name],
              );
            } else {
              _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD,
                member.name,
                [name],
              );
            }
          }
        }
      } else if (member is FieldDeclaration) {
        if (member.isStatic) {
          for (VariableDeclaration field in member.fields.variables) {
            SimpleIdentifier identifier = field.name;
            String name = identifier.name;
            if (instanceGetters.containsKey(name) ||
                instanceSetters.containsKey(name)) {
              String className = element.displayName;
              _errorReporter.reportErrorForNode(
                  CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
                  identifier,
                  [className, name, className]);
            }
          }
        }
      } else if (member is MethodDeclaration) {
        if (member.isStatic) {
          SimpleIdentifier identifier = member.name;
          String name = identifier.name;
          if (instanceGetters.containsKey(name) ||
              instanceSetters.containsKey(name)) {
            String className = identifier.staticElement.enclosingElement.name;
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE,
                identifier,
                [className, name, className]);
          }
        }
      }
    }
  }

  /// Check whether the given [element] defined by the [identifier] is already
  /// in one of the scopes - [getterScope] or [setterScope], and produce an
  /// error if it is.
  void _checkDuplicateIdentifier(
      Map<String, Element> getterScope, SimpleIdentifier identifier,
      {Element element, Map<String, Element> setterScope}) {
    if (identifier.isSynthetic) {
      return;
    }
    element ??= identifier.staticElement;

    // Fields define getters and setters, so check them separately.
    if (element is PropertyInducingElement) {
      _checkDuplicateIdentifier(getterScope, identifier,
          element: element.getter, setterScope: setterScope);
      if (!element.isConst && !element.isFinal) {
        _checkDuplicateIdentifier(getterScope, identifier,
            element: element.setter, setterScope: setterScope);
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

    var name = identifier.name;
    if (element is MethodElement) {
      name = element.name;
    }

    Element previous = getterScope[name];
    if (previous != null) {
      if (_isGetterSetterPair(element, previous)) {
        // OK
      } else if (element is FieldFormalParameterElement &&
          previous is FieldFormalParameterElement &&
          element.field != null &&
          element.field.isFinal) {
        // Reported as CompileTimeErrorCode.FINAL_INITIALIZED_MULTIPLE_TIMES.
      } else {
        _errorReporter.reportErrorForNode(
          getError(previous, element),
          identifier,
          [name],
        );
      }
    } else {
      getterScope[name] = element;
    }

    if (element is PropertyAccessorElement && element.isSetter) {
      previous = setterScope[name];
      if (previous != null) {
        _errorReporter.reportErrorForNode(
          getError(previous, element),
          identifier,
          [name],
        );
      } else {
        setterScope[name] = element;
      }
    }
  }

  static bool _isGetterSetterPair(Element a, Element b) {
    if (a is PropertyAccessorElement && b is PropertyAccessorElement) {
      return a.isGetter && b.isSetter || a.isSetter && b.isGetter;
    }
    return false;
  }
}
