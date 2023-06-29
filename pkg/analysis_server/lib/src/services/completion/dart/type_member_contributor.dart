// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer_plugin/src/utilities/completion/optype.dart';
import 'package:analyzer_plugin/src/utilities/visitors/local_declaration_visitor.dart';
import 'package:collection/collection.dart';

/// A contributor that produces suggestions based on the instance members of a
/// given type, whether declared by that type directly or inherited from a
/// superinterface. More concretely, this class produces suggestions for
/// expressions of the form `o.^`, where `o` is an expression denoting an
/// instance of a type.
class TypeMemberContributor extends DartCompletionContributor {
  TypeMemberContributor(super.request, super.builder);

  @override
  Future<void> computeSuggestions({
    required OperationPerformanceImpl performance,
  }) async {
    final patternLocation = request.opType.patternLocation;
    if (patternLocation is NamedPatternFieldWantsFinalOrVar) {
      return;
    } else if (patternLocation is NamedPatternFieldWantsName) {
      var excludedGetters = patternLocation.existingFields
          .map((field) => field.name?.name?.lexeme)
          .whereNotNull()
          .toSet();
      _suggestFromType(
        expression: null,
        expressionType: patternLocation.matchedType,
        excludedGetters: excludedGetters,
        includeSetters: false,
      );
      return;
    }

    // Recompute the target because resolution might have changed it.
    var expression = request.target.dotTarget;
    if (expression == null ||
        expression.isSynthetic ||
        expression is ExtensionOverride) {
      var containingNode = request.target.containingNode;
      if (containingNode is ObjectPattern) {
        // TODO(brianwilkerson) This is really only intended to be reached when
        //  `expression` is `null`. It's not ideal that we're using this
        //  contributor this way, and we should look into better ways to
        //  structure the code.
        var excludedGetters = containingNode.fields
            .map((field) => field.name?.name?.lexeme)
            .whereNotNull()
            .toSet();
        _suggestFromType(
            expression: null,
            expressionType: containingNode.type.type,
            excludedGetters: excludedGetters,
            includeSetters: false);
      }
      return;
    }
    if (expression is Identifier) {
      var elem = expression.staticElement;
      if (elem is InterfaceElement) {
        // Suggestions provided by StaticMemberContributor.
        return;
      }
      if (elem is PrefixElement) {
        // Suggestions provided by LibraryMemberContributor.
        return;
      }
    }
    _suggestFromType(
        expression: expression,
        expressionType: expression.staticType,
        excludedGetters: const {},
        includeSetters: true);
  }

  void _suggestFromDartCoreObject() {
    _suggestFromInterfaceType(request.objectType,
        excludedGetters: const {}, includeSetters: true);
  }

  void _suggestFromInterfaceType(InterfaceType type,
      {required Set<String> excludedGetters, required bool includeSetters}) {
    _SuggestionBuilder(request, builder).buildSuggestions(
        type: type,
        excludedGetters: excludedGetters,
        includeSetters: includeSetters);
  }

  void _suggestFromRecordType({
    required RecordType type,
    required Set<String> excludedFields,
  }) {
    for (final (index, field) in type.positionalFields.indexed) {
      builder.suggestRecordField(
        field: field,
        name: '\$${index + 1}',
      );
    }

    for (final field in type.namedFields) {
      if (!excludedFields.contains(field.name)) {
        builder.suggestRecordField(
          field: field,
          name: field.name,
        );
      }
    }
  }

  void _suggestFromType(
      {Expression? expression,
      DartType? expressionType,
      required Set<String> excludedGetters,
      required bool includeSetters}) {
    // Determine the target expression's type.
    var type = expressionType != null
        ? request.libraryElement.typeSystem.resolveToBound(expressionType)
        : null;
    if (type == null || type is DynamicType) {
      // If the expression does not provide a good type, then attempt to get a
      // better type from the element.
      if (expression is Identifier) {
        var elem = expression.staticElement;
        if (elem is FunctionTypedElement) {
          type = elem.returnType2;
        } else if (elem is ParameterElement) {
          type = elem.type;
        } else if (elem is LocalVariableElement) {
          type = elem.type;
        }
        if ((type == null || type is DynamicType) &&
            expression is SimpleIdentifier) {
          // If the element does not provide a good type, then attempt to get a
          // better type from a local declaration.
          var visitor = _LocalBestTypeVisitor(expression.name, request.offset);
          if (visitor.visit(expression) && visitor.typeFound != null) {
            type = visitor.typeFound;
          }
        }
      }
    }

    if (type is FunctionType) {
      builder.suggestFunctionCall();
      _suggestFromDartCoreObject();
    } else if (type is InterfaceType) {
      if (expression is SuperExpression) {
        _SuggestionBuilder(request, builder).buildSuggestions(
          type: type,
          excludedGetters: excludedGetters,
          includeSetters: includeSetters,
          onlySuper: true,
        );
      } else {
        _suggestFromInterfaceType(type,
            excludedGetters: excludedGetters, includeSetters: includeSetters);
      }
    } else if (type is RecordType) {
      _suggestFromRecordType(
        type: type,
        excludedFields: excludedGetters,
      );
      _suggestFromDartCoreObject();
    } else {
      _suggestFromDartCoreObject();
    }
  }
}

/// An [AstVisitor] which looks for a declaration with the given name and if
/// found, tries to determine a type for that declaration.
class _LocalBestTypeVisitor extends LocalDeclarationVisitor {
  /// The name for the declaration to be found.
  final String targetName;

  /// The best type for the found declaration, or `null` if no declaration found
  /// or failed to determine a type.
  DartType? typeFound;

  /// Construct a new instance to search for a declaration.
  _LocalBestTypeVisitor(this.targetName, int offset) : super(offset);

  @override
  void declaredClass(ClassDeclaration declaration) {
    if (declaration.name.lexeme == targetName) {
      // no type
      finished();
    }
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
    if (declaration.name.lexeme == targetName) {
      // no type
      finished();
    }
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
    if (varDecl.name.lexeme == targetName) {
      // Type provided by the element in computeFull above
      finished();
    }
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    if (declaration.name.lexeme == targetName) {
      var returnType = declaration.returnType;
      if (returnType != null) {
        var type = returnType.type;
        if (type != null) {
          typeFound = type;
        }
      }
      finished();
    }
  }

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {
    if (declaration.name.lexeme == targetName) {
      var returnType = declaration.returnType;
      if (returnType != null) {
        var type = returnType.type;
        if (type != null) {
          typeFound = type;
        }
      }
      finished();
    }
  }

  @override
  void declaredGenericTypeAlias(GenericTypeAlias declaration) {
    if (declaration.name.lexeme == targetName) {
      var returnType = declaration.functionType?.returnType;
      if (returnType != null) {
        var type = returnType.type;
        if (type != null) {
          typeFound = type;
        }
      }
      finished();
    }
  }

  @override
  void declaredLabel(Label label, bool isCaseLabel) {
    if (label.label.name == targetName) {
      // no type
      finished();
    }
  }

  @override
  void declaredLocalVar(
    Token name,
    TypeAnnotation? type,
    LocalVariableElement declaredElement,
  ) {
    if (name.lexeme == targetName) {
      typeFound = declaredElement.type;
      finished();
    }
  }

  @override
  void declaredMethod(MethodDeclaration declaration) {
    if (declaration.name.lexeme == targetName) {
      var returnType = declaration.returnType;
      if (returnType != null) {
        var type = returnType.type;
        if (type != null) {
          typeFound = type;
        }
      }
      finished();
    }
  }

  @override
  void declaredParam(Token name, Element? element, TypeAnnotation? type) {
    if (name.lexeme == targetName) {
      // Type provided by the element in computeFull above.
      finished();
    }
  }

  @override
  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {
    if (varDecl.name.lexeme == targetName) {
      // Type provided by the element in computeFull above.
      finished();
    }
  }
}

/// This class provides suggestions based upon the visible instance members in
/// an interface type.
class _SuggestionBuilder extends MemberSuggestionBuilder {
  /// Initialize a newly created suggestion builder.
  _SuggestionBuilder(super.request, super.builder);

  /// Add completion suggestions for 'dot' completions on the given [type].
  /// If [onlySuper] is `true`, only valid super members will be suggested.
  void buildSuggestions(
      {required InterfaceType type,
      required Set<String> excludedGetters,
      required bool includeSetters,
      bool onlySuper = false}) {
    var inheritanceDistances = <InterfaceElement, double>{};
    var substitution = Substitution.fromInterfaceType(type);
    var map = onlySuper
        ? request.inheritanceManager.getInheritedConcreteMap2(type.element)
        : request.inheritanceManager.getInterface(type.element).map;

    for (final rawMember in map.values) {
      var member = ExecutableMember.from2(rawMember, substitution);
      var enclosingInterface = member.enclosingElement2 as InterfaceElement;
      var inheritanceDistance = inheritanceDistances.putIfAbsent(
        enclosingInterface,
        () => request.featureComputer
            .inheritanceDistanceFeature(type.element, enclosingInterface),
      );
      if (member is MethodElement) {
        // Exclude static methods when completion on an instance.
        if (!member.isStatic) {
          addSuggestionForMethod(
            method: member,
            kind: protocol.CompletionSuggestionKind.INVOCATION,
            inheritanceDistance: inheritanceDistance,
          );
        }
      } else if (member is PropertyAccessorElement) {
        if (!member.isStatic) {
          if (member.isGetter && !excludedGetters.contains(member.name) ||
              member.isSetter && includeSetters) {
            addSuggestionForAccessor(
                accessor: member, inheritanceDistance: inheritanceDistance);
          }
        }
      }
    }
    if ((type.isDartCoreFunction && !onlySuper) ||
        type.allSupertypes.any((type) => type.isDartCoreFunction)) {
      builder.suggestFunctionCall();
    }
  }
}
