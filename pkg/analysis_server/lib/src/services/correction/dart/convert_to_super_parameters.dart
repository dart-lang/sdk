// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/range_factory.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToSuperParameters extends ResolvedCorrectionProducer {
  ConvertToSuperParameters({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_SUPER_PARAMETERS;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_SUPER_PARAMETERS;

  @override
  FixKind? get multiFixKind => DartFixKind.CONVERT_TO_SUPER_PARAMETERS_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (!isEnabled(Feature.super_parameters)) {
      // If the library doesn't support super_parameters then the change isn't
      // appropriate.
      return;
    }
    var constructor = _findConstructor();
    if (constructor == null) {
      // If this isn't a constructor declaration then the change isn't
      // appropriate.
      return;
    }
    var superInvocation = _superInvocation(constructor);
    if (superInvocation == null) {
      // If there isn't an explicit invocation of a super constructor then the
      // change isn't appropriate. Note that this also rules out factory
      // constructors because factory constructors can't have initializers.
      return;
    }
    var superConstructor = superInvocation.element;
    if (superConstructor == null) {
      // If the super constructor wasn't resolved then we can't apply the
      // change.
      return;
    }
    // Find the arguments that can be converted. Named arguments are added to
    // [named]. Positional arguments are added to [positional], but the list is
    // set to `null` if a positional argument is found that can't be converted
    // because either all of the positional parameters must be converted or none
    // of them can be converted.
    var referencedParameters = _referencedParameters(constructor);
    var parameterMap = _parameterMap(constructor.parameters);
    List<_ParameterData>? positional = [];
    var named = <_ParameterData>[];
    var argumentList = superInvocation.argumentList;
    var arguments = argumentList.arguments;
    for (
      var argumentIndex = 0;
      argumentIndex < arguments.length;
      argumentIndex++
    ) {
      var argument = arguments[argumentIndex];
      if (argument is NamedExpression) {
        var parameter = _parameterFor(parameterMap, argument.expression);
        if (parameter != null &&
            parameter.isNamed &&
            parameter.element.name3 == argument.name.label.name &&
            !referencedParameters.contains(parameter.element)) {
          var data = _dataForParameter(
            parameter,
            argumentIndex,
            argument.correspondingParameter,
          );
          if (data != null) {
            named.add(data);
          }
        }
      } else if (positional != null) {
        var parameter = _parameterFor(parameterMap, argument);
        if (parameter == null ||
            !parameter.isPositional ||
            referencedParameters.contains(parameter.element)) {
          positional = null;
        } else {
          var data = _dataForParameter(
            parameter,
            argumentIndex,
            argument.correspondingParameter,
          );
          if (data == null) {
            positional = null;
          } else {
            positional.add(data);
          }
        }
      }
    }
    if (positional != null && !_inOrder(positional)) {
      positional = null;
    }
    // At this point:
    // 1. `positional` will be `null` if
    //    - there is at least one positional argument that can't be converted,
    //      which implies that there are no positional arguments that can be
    //      converted, or
    //    - if the order of the positional parameters doesn't match the order of
    //      the positional arguments.
    // 2. `positional` will be empty if there are no positional arguments at
    //    all.
    // 3. `named` will be empty if there are no named arguments that can be
    //    converted.
    if ((positional == null || positional.isEmpty) && named.isEmpty) {
      // There are no parameters that can be converted.
      return;
    }

    var allParameters = <_ParameterData>[...?positional, ...named];

    var argumentsToDelete =
        allParameters.map((data) => data.argumentIndex).toList();
    argumentsToDelete.sort();

    await builder.addDartFileEdit(file, (builder) {
      // Convert the parameters.
      for (var parameterData in allParameters) {
        var keyword = parameterData.finalKeyword;
        var nameOffset = parameterData.name.offset;

        void insertSuper() {
          if (keyword == null) {
            builder.addSimpleInsertion(nameOffset, 'super.');
          } else {
            var tokenAfterKeyword = keyword.next!;
            if (tokenAfterKeyword.offset == nameOffset) {
              builder.addSimpleReplacement(
                range.startStart(keyword, tokenAfterKeyword),
                'super.',
              );
            } else {
              builder.addDeletion(range.startStart(keyword, tokenAfterKeyword));
              builder.addSimpleInsertion(nameOffset, 'super.');
            }
          }
        }

        var typeToDelete = parameterData.typeToDelete;
        if (typeToDelete == null) {
          insertSuper();
        } else {
          var primaryRange = typeToDelete.primaryRange;
          if (primaryRange == null) {
            // This only happens when the type is an inline function type with
            // no return type, such as `f(int i)`. Inline function types can't
            // have a `final` keyword unless there's an error in the code.
            builder.addSimpleInsertion(nameOffset, 'super.');
          } else {
            if (keyword == null) {
              builder.addSimpleReplacement(primaryRange, 'super.');
            } else {
              var tokenAfterKeyword = keyword.next!;
              if (tokenAfterKeyword.offset == primaryRange.offset) {
                builder.addSimpleReplacement(
                  range.startOffsetEndOffset(keyword.offset, primaryRange.end),
                  'super.',
                );
              } else {
                builder.addDeletion(
                  range.startStart(keyword, tokenAfterKeyword),
                );
                builder.addSimpleReplacement(primaryRange, 'super.');
              }
            }
          }
          if (parameterData.nullInitializer) {
            builder.addSimpleInsertion(parameterData.name.end, ' = null');
          }
          var parameterRange = typeToDelete.parameterRange;
          if (parameterRange != null) {
            builder.addDeletion(parameterRange);
          }
        }
        var defaultValueRange = parameterData.defaultValueRange;
        if (defaultValueRange != null) {
          builder.addDeletion(defaultValueRange);
        }
      }

      // Remove the corresponding arguments.
      if (argumentsToDelete.length == arguments.length) {
        if (superInvocation.constructorName == null) {
          // Delete the whole invocation.
          var initializers = constructor.initializers;
          SourceRange initializerRange;
          if (initializers.length == 1) {
            initializerRange = range.endEnd(
              constructor.parameters,
              superInvocation,
            );
          } else {
            initializerRange = range.nodeInList(initializers, superInvocation);
          }
          builder.addDeletion(initializerRange);
        } else {
          // Leave the invocation, but remove all of the arguments, including
          // any trailing comma.
          builder.addDeletion(
            range.endStart(
              argumentList.leftParenthesis,
              argumentList.rightParenthesis,
            ),
          );
        }
      } else {
        // Remove just the arguments that are no longer needed.
        var ranges = range.nodesInList(arguments, argumentsToDelete);
        for (var range in ranges) {
          builder.addDeletion(range);
        }
      }
    });
  }

  /// If the [parameter] can be converted into a super initializing formal
  /// parameter then return the data needed to do so.
  _ParameterData? _dataForParameter(
    _Parameter parameter,
    int argumentIndex,
    FormalParameterElement? superParameter,
  ) {
    if (superParameter == null) {
      return null;
    }
    // If the type of the `thisParameter` isn't a subtype of the type of the
    // super parameter, then the change isn't appropriate.
    var superType = superParameter.type;
    var thisType = parameter.element.type;
    if (!typeSystem.isSubtypeOf(thisType, superType)) {
      return null;
    }

    var parameterNode = parameter.parameter;
    var identifier = parameterNode.name;
    if (identifier == null) {
      // This condition should never occur, but the test is here to promote the
      // type.
      return null;
    }

    // Return the data.
    return _ParameterData(
      argumentIndex: argumentIndex,
      defaultValueRange: _defaultValueRange(
        parameterNode,
        superParameter,
        parameter.element,
      ),
      finalKeyword: _finalKeyword(parameterNode),
      name: identifier,
      nullInitializer: _nullInitializer(parameterNode, superParameter),
      parameterIndex: parameter.index,
      typeToDelete: superType == thisType ? _type(parameterNode) : null,
    );
  }

  /// Return the range of the default value associated with the [parameter], or
  /// `null` if the parameter doesn't have a default value or if the default
  /// value is not the same as the default value in the super constructor.
  SourceRange? _defaultValueRange(
    FormalParameter parameter,
    FormalParameterElement superParameter,
    FormalParameterElement thisParameter,
  ) {
    if (parameter is DefaultFormalParameter) {
      var defaultValue = parameter.defaultValue;
      if (defaultValue != null) {
        var superDefault = superParameter.computeConstantValue();
        var thisDefault = thisParameter.computeConstantValue();
        if (superDefault != null && superDefault == thisDefault) {
          return range.endEnd(parameter.name!, defaultValue);
        }
      }
    }
    return null;
  }

  /// Return data about the type annotation on the [parameter]. This is the
  /// information about the ranges of text that need to be removed in order to
  /// remove the type annotation.
  Token? _finalKeyword(FormalParameter parameter) {
    if (parameter is DefaultFormalParameter) {
      return _finalKeyword(parameter.parameter);
    } else if (parameter is SimpleFormalParameter) {
      var keyword = parameter.keyword;
      if (keyword?.type == Keyword.FINAL) {
        return keyword;
      }
    }
    return null;
  }

  /// Return the constructor to be converted, or `null` if the cursor is not on
  /// the name of a constructor.
  ConstructorDeclaration? _findConstructor() {
    var node = this.node;
    if (node is ConstructorDeclaration) {
      return node;
    }
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is ConstructorDeclaration) {
        return parent;
      } else if (parent is ConstructorName) {
        var grandparent = parent.parent;
        if (grandparent is ConstructorDeclaration) {
          return grandparent;
        }
      }
    }
    return null;
  }

  /// Return `true` if the given list of [parameterData] is in order by the
  /// index of the parameters. The list is known to be in order by the argument
  /// positions, so this test is used to ensure that the order won't be changed
  /// if the parameters are converted.
  bool _inOrder(List<_ParameterData> parameterData) {
    var previousIndex = -1;
    for (var data in parameterData) {
      var index = data.parameterIndex;
      if (index < previousIndex) {
        return false;
      }
      previousIndex = index;
    }
    return true;
  }

  /// Return `true` if the parameter has no default value
  /// and the parameter in the super constructor has a default one
  bool _nullInitializer(
    FormalParameter parameter,
    FormalParameterElement superParameter,
  ) {
    return parameter is DefaultFormalParameter &&
        !parameter.isRequired &&
        parameter.defaultValue == null &&
        superParameter.hasDefaultValue;
  }

  /// Return the parameter corresponding to the [expression], or `null` if the
  /// expression isn't a simple reference to one of the normal parameters in the
  /// constructor being converted.
  _Parameter? _parameterFor(
    Map<FormalParameterElement, _Parameter> parameterMap,
    Expression expression,
  ) {
    if (expression is SimpleIdentifier) {
      var element = expression.element;
      return parameterMap[element];
    }
    return null;
  }

  /// Return a map from parameter elements to the parameters that define those
  /// elements.
  Map<FormalParameterElement, _Parameter> _parameterMap(
    FormalParameterList parameterList,
  ) {
    bool validParameter(FormalParameter parameter) {
      parameter = parameter.notDefault;
      return parameter is SimpleFormalParameter ||
          parameter is FunctionTypedFormalParameter;
    }

    var map = <FormalParameterElement, _Parameter>{};
    var parameters = parameterList.parameters;
    for (var i = 0; i < parameters.length; i++) {
      var parameter = parameters[i];
      if (validParameter(parameter)) {
        var element = parameter.declaredFragment?.element;
        if (element != null) {
          map[element] = _Parameter(parameter, element, i);
        }
      }
    }
    return map;
  }

  /// Return a set containing the elements of all of the parameters that are
  /// referenced in the body of the [constructor].
  Set<FormalParameterElement> _referencedParameters(
    ConstructorDeclaration constructor,
  ) {
    var collector = _ReferencedParameterCollector();
    constructor.body.accept(collector);
    return collector.foundParameters;
  }

  /// Return the invocation of the super constructor.
  SuperConstructorInvocation? _superInvocation(
    ConstructorDeclaration constructor,
  ) {
    var initializers = constructor.initializers;
    // Search all of the initializers in case the code is invalid, but start
    // from the end because the code will usually be correct.
    for (var i = initializers.length - 1; i >= 0; i--) {
      var initializer = initializers[i];
      if (initializer is SuperConstructorInvocation) {
        return initializer;
      }
    }
    return null;
  }

  /// Return data about the type annotation on the [parameter]. This is the
  /// information about the ranges of text that need to be removed in order to
  /// remove the type annotation.
  _TypeData? _type(FormalParameter parameter) {
    if (parameter is DefaultFormalParameter) {
      return _type(parameter.parameter);
    } else if (parameter is SimpleFormalParameter) {
      var typeAnnotation = parameter.type;
      if (typeAnnotation != null) {
        return _TypeData(
          primaryRange: range.startStart(typeAnnotation, parameter.name!),
        );
      }
    } else if (parameter is FunctionTypedFormalParameter) {
      var returnType = parameter.returnType;
      return _TypeData(
        primaryRange:
            returnType != null
                ? range.startStart(returnType, parameter.name)
                : null,
        parameterRange: range.node(parameter.parameters),
      );
    }
    return null;
  }
}

/// Information about a single parameter.
class _Parameter {
  final FormalParameter parameter;

  final FormalParameterElement element;

  final int index;

  _Parameter(this.parameter, this.element, this.index);

  bool get isNamed => element.isNamed;

  bool get isPositional => element.isPositional;
}

/// Information used to convert a single parameter.
class _ParameterData {
  /// The `final` keyword on the parameter, or `null` if there is no `final`
  /// keyword.
  final Token? finalKeyword;

  /// The type annotation that should be deleted from the parameter list, or
  /// `null` if there is no type annotation to delete or if the type should not
  /// be deleted.
  final _TypeData? typeToDelete;

  /// The name.
  final Token name;

  /// Whether to add a default initializer with `null` value or not.
  final bool nullInitializer;

  /// The range of the default value that is to be deleted from the parameter
  /// list, or `null` if there is no default value, or the default value isn't
  /// to be deleted.
  final SourceRange? defaultValueRange;

  /// The index of the parameter to be updated.
  final int parameterIndex;

  /// The index of the argument to be deleted.
  final int argumentIndex;

  /// Initialize a newly create data object.
  _ParameterData({
    required this.finalKeyword,
    required this.typeToDelete,
    required this.name,
    required this.defaultValueRange,
    required this.nullInitializer,
    required this.parameterIndex,
    required this.argumentIndex,
  });
}

class _ReferencedParameterCollector extends RecursiveAstVisitor<void> {
  final Set<FormalParameterElement> foundParameters = {};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.element;
    if (element is FormalParameterElement) {
      foundParameters.add(element);
    }
  }
}

/// Information about the ranges of text that need to be removed in order to
/// remove a type annotation.
class _TypeData {
  SourceRange? primaryRange;

  SourceRange? parameterRange;

  _TypeData({required this.primaryRange, this.parameterRange});
}
