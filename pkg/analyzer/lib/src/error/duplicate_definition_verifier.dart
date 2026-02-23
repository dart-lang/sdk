// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/diagnostic/diagnostic_factory.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

class DuplicateDefinitionVerifier {
  final LibraryElementImpl _currentLibrary;
  final DiagnosticReporter _diagnosticReporter;

  final DiagnosticFactory _diagnosticFactory = DiagnosticFactory();
  final Set<Token> _reportedTokens = Set.identity();

  DuplicateDefinitionVerifier(this._currentLibrary, this._diagnosticReporter);

  /// Check that the exception and stack trace parameters have different names.
  void checkCatchClause(CatchClause node) {
    var exceptionParameter = node.exceptionParameter;
    var stackTraceParameter = node.stackTraceParameter;
    if (exceptionParameter != null && stackTraceParameter != null) {
      var element = exceptionParameter.declaredFragment?.element;
      if (element != null && element.isWildcardVariable) return;
      String exceptionName = exceptionParameter.name.lexeme;
      if (exceptionName == stackTraceParameter.name.lexeme) {
        _diagnosticReporter.report(
          _diagnosticFactory.duplicateDefinitionForNodes(
            _diagnosticReporter.source,
            diag.duplicateDefinition.withArguments(name: exceptionName),
            stackTraceParameter,
            exceptionParameter,
          ),
        );
      }
    }
  }

  /// Check that the given list of variable declarations does not define
  /// multiple variables of the same name.
  void checkForVariables(VariableDeclarationListImpl node) {
    var scope = _DuplicateIdentifierScope(this);
    for (var variable in node.variables) {
      scope.add(variable.name, node: variable);
    }
  }

  /// Check that all of the parameters have unique names.
  void checkParameters(FormalParameterListImpl node) {
    var scope = _FormalParameterDuplicateIdentifierScope(this);
    for (var parameter in node.parameters) {
      // The identifier can be null if this is a parameter list for a generic
      // function type.
      var identifier = parameter.name;
      if (identifier == null) {
        continue;
      }

      scope.add(identifier, node: parameter);
    }

    // For private named parameters, also look for collisions with their public
    // name and other parameters.
    for (var parameter in node.parameters) {
      if (parameter.declaredFragment
          case FieldFormalParameterFragment fragment) {
        if (fragment.privateName != null) {
          scope.checkPublicName(
            privateName: parameter.name!,
            publicName: fragment.name!,
          );
        }
      }
    }
  }

  /// Check that all of the variables have unique names.
  void checkStatements(List<StatementImpl> statements) {
    var scope = _DuplicateIdentifierScope(this);
    for (var statement in statements) {
      if (statement is VariableDeclarationStatementImpl) {
        for (var variable in statement.variables.variables) {
          scope.add(variable.name, node: variable);
        }
      } else if (statement is FunctionDeclarationStatementImpl) {
        if (!_isWildCardFunction(statement)) {
          scope.add(
            statement.functionDeclaration.name,
            node: statement.functionDeclaration,
          );
        }
      } else if (statement is PatternVariableDeclarationStatementImpl) {
        for (var variable in statement.declaration.elements) {
          scope.add(variable.node.name, node: variable.node);
        }
      }
    }
  }

  /// Check that all of the parameters have unique names.
  void checkTypeParameters(TypeParameterListImpl node) {
    var scope = _DuplicateIdentifierScope(this);
    for (var parameter in node.typeParameters) {
      scope.add(parameter.name, node: parameter);
    }
  }

  /// Check that there are no members with the same name.
  void checkUnit(CompilationUnitImpl node) {
    var fragment = node.declaredFragment!;
    var definedGetters = <String, ElementImpl>{};
    var definedSetters = <String, ElementImpl>{};

    void addWithoutChecking(LibraryFragmentImpl libraryFragment) {
      for (var fragment in libraryFragment.getters) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.setters) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedSetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.classes) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.enums) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.extensions) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.extensionTypes) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.functions) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.mixins) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
      for (var fragment in libraryFragment.typeAliases) {
        var element = fragment.element;
        if (element.lookupName case var name?) {
          definedGetters[name] = element;
        }
      }
    }

    var libraryDeclarations = _currentLibrary.libraryDeclarations;
    for (var importPrefix in fragment.prefixes) {
      var name = importPrefix.name;
      if (name != null) {
        if (libraryDeclarations.withName(name) case var existing?) {
          _diagnosticReporter.report(
            _diagnosticFactory.duplicateDefinition(
              diag.prefixCollidesWithTopLevelMember.withArguments(name: name),
              importPrefix.firstFragment,
              existing as ElementImpl,
            ),
          );
        }
      }
    }

    // TODO(scheglov): carry across resolved units
    var currentLibraryFragment = node.declaredFragment!;
    for (var libraryFragment in _currentLibrary.fragments) {
      if (libraryFragment == currentLibraryFragment) {
        break;
      }
      addWithoutChecking(libraryFragment);
    }

    for (var member in node.declarations) {
      switch (member) {
        case ClassDeclarationImpl():
          var declaredFragment = member.declaredFragment!;
          if (!declaredFragment.isAugmentation) {
            _checkDuplicateFragmentIdentifier(
              definedGetters,
              member.namePart.typeName,
              fragment: declaredFragment,
            );
          }
        case EnumDeclarationImpl():
          var declaredFragment = member.declaredFragment!;
          if (!declaredFragment.isAugmentation) {
            _checkDuplicateFragmentIdentifier(
              definedGetters,
              member.namePart.typeName,
              fragment: declaredFragment,
            );
          }
        case ExtensionDeclarationImpl():
          var identifier = member.name;
          if (identifier != null) {
            var declaredFragment = member.declaredFragment!;
            if (!declaredFragment.isAugmentation) {
              _checkDuplicateFragmentIdentifier(
                definedGetters,
                identifier,
                fragment: declaredFragment,
              );
            }
          }
        case ExtensionTypeDeclarationImpl():
          var declaredFragment = member.declaredFragment!;
          if (!declaredFragment.isAugmentation) {
            _checkDuplicateFragmentIdentifier(
              definedGetters,
              member.primaryConstructor.typeName,
              fragment: declaredFragment,
            );
          }
        case FunctionDeclarationImpl():
          var declaredFragment = member.declaredFragment!;
          if (!declaredFragment.isAugmentation) {
            if (declaredFragment is SetterFragment) {
              _checkDuplicateFragmentIdentifier(
                definedSetters,
                member.name,
                fragment: declaredFragment,
              );
            } else {
              _checkDuplicateFragmentIdentifier(
                definedGetters,
                member.name,
                fragment: declaredFragment,
              );
            }
          }
        case MixinDeclarationImpl():
          var declaredFragment = member.declaredFragment!;
          if (!declaredFragment.isAugmentation) {
            _checkDuplicateFragmentIdentifier(
              definedGetters,
              member.name,
              fragment: declaredFragment,
            );
          }
        case TopLevelVariableDeclarationImpl():
          for (var variable in member.variables.variables) {
            var declaredFragment = variable.declaredFragment;
            declaredFragment as TopLevelVariableFragmentImpl;
            if (!declaredFragment.isAugmentation) {
              var declaredElement = declaredFragment.element;
              if (declaredElement.getter?.firstFragment case var getter?) {
                _checkDuplicateFragmentIdentifier(
                  definedGetters,
                  variable.name,
                  originFragment: declaredFragment,
                  fragment: getter,
                );
              }
              if (declaredElement.definesSetter) {
                if (declaredElement.setter?.firstFragment case var setter?) {
                  _checkDuplicateFragmentIdentifier(
                    definedSetters,
                    variable.name,
                    originFragment: declaredFragment,
                    fragment: setter,
                  );
                }
              }
            }
          }
        case TypeAliasImpl():
          var declaredFragment = member.declaredFragment!;
          if (!declaredFragment.isAugmentation) {
            _checkDuplicateFragmentIdentifier(
              definedGetters,
              member.name,
              fragment: declaredFragment,
            );
          }
      }
    }
  }

  /// Check whether the given [fragment] defined by the [identifier] is already
  /// in [scope], and produce an error if it is.
  void _checkDuplicateFragmentIdentifier(
    Map<String, ElementImpl> scope,
    Token identifier, {
    FragmentImpl? originFragment,
    required FragmentImpl fragment,
  }) {
    if (identifier.isSynthetic) {
      return;
    }

    var lookupName = fragment.element.lookupName;
    if (lookupName == null) {
      return;
    }

    if (_reportedTokens.contains(identifier)) {
      return;
    }

    if (scope[lookupName] case var previous?) {
      _reportedTokens.add(identifier);
      _diagnosticReporter.report(
        _diagnosticFactory.duplicateDefinition(
          diag.duplicateDefinition.withArguments(name: lookupName),
          originFragment ?? fragment,
          previous,
        ),
      );
    } else {
      scope[lookupName] = fragment.element;
    }
  }

  bool _isWildCardFunction(FunctionDeclarationStatement statement) =>
      statement.functionDeclaration.name.lexeme == '_' &&
      _currentLibrary.hasWildcardVariablesFeatureEnabled;
}

/// A single scope where colliding definitions with the same name is an error.
class _DuplicateIdentifierScope<T extends AstNode> {
  final DuplicateDefinitionVerifier _verifier;

  final Map<String, (T, Token)> _scope = {};

  _DuplicateIdentifierScope(this._verifier);

  /// Reports an error if there is already a node in this scope with the given
  /// [identifier] name.
  ///
  /// Otherwise, adds [node] to the scope.
  void add(Token identifier, {required T node}) {
    if (identifier.isSynthetic) {
      return;
    }

    if (_verifier._reportedTokens.contains(identifier)) {
      return;
    }

    // Wildcards do not collide.
    if (isWildcard(identifier, node)) {
      return;
    }

    if (_scope[identifier.lexeme] case (var previousNode, var previousToken)) {
      _verifier._reportedTokens.add(identifier);
      _verifier._diagnosticReporter.report(
        _verifier._diagnosticFactory.duplicateDefinitionForNodes(
          _verifier._diagnosticReporter.source,
          getDiagnostic(
            previousNode,
            node,
          ).withArguments(name: identifier.lexeme),
          identifier,
          previousToken,
        ),
      );
    } else {
      _scope[identifier.lexeme] = (node, identifier);
    }
  }

  /// The diagnostic code to use when [previous] and [current] have the same
  /// name.
  DiagnosticWithArguments<LocatableDiagnostic Function({required String name})>
  getDiagnostic(T previous, T current) => diag.duplicateDefinition;

  /// Whether [node] named [identifier] acts as a wildcard.
  bool isWildcard(Token identifier, T node) {
    return identifier.lexeme == '_' &&
        _verifier._currentLibrary.hasWildcardVariablesFeatureEnabled;
  }
}

/// A [_DuplicateIdentifierScope] for formal parameters.
///
/// Handles private named parameters and initializing formals.
class _FormalParameterDuplicateIdentifierScope
    extends _DuplicateIdentifierScope<FormalParameter> {
  _FormalParameterDuplicateIdentifierScope(super.verifier);

  /// Given a private named parameter with [privateName] and corresponding
  /// [publicName], checks that the public name doesn't collide with any other
  /// parameter.
  void checkPublicName({
    required Token privateName,
    required String publicName,
  }) {
    if (_scope[publicName] case (var _, var previousToken)) {
      _verifier._diagnosticReporter.report(
        _verifier._diagnosticFactory.duplicateDefinitionForNodes(
          _verifier._diagnosticReporter.source,
          diag.privateNamedParameterDuplicatePublicName.withArguments(
            name: publicName,
          ),
          privateName,
          previousToken,
        ),
      );
    }
  }

  @override
  DiagnosticWithArguments<LocatableDiagnostic Function({required String name})>
  getDiagnostic(FormalParameter previous, FormalParameter current) {
    // When two initializing formals collide, tell the user they can't
    // initialize the same field twice.
    if (previous.notDefault is FieldFormalParameter &&
        current.notDefault is FieldFormalParameter) {
      return diag.duplicateFieldFormalParameter;
    }
    return diag.duplicateDefinition;
  }

  @override
  bool isWildcard(Token identifier, FormalParameter node) {
    if (!super.isWildcard(identifier, node)) {
      return false;
    }

    // Since fields can be named `_`, initializing formals are not
    // considered wildcards.
    var element = node.declaredFragment!.element;
    if (element is FieldFormalParameterElement) {
      return false;
    }
    return true;
  }
}
