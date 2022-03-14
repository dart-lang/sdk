// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToSuperInitializingParameter extends CorrectionProducer {
  @override
  AssistKind get assistKind =>
      DartAssistKind.CONVERT_TO_SUPER_INITIALIZING_PARAMETER;

  /// If the selected node is the name of either a simple formal parameter or a
  /// function-typed formal parameter, either with or without a default value,
  /// then return the formal parameter. Otherwise return `null`.
  FormalParameter? get _formalParameter {
    final node = this.node;
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is NormalFormalParameter &&
          (parent is SimpleFormalParameter ||
              parent is FunctionTypedFormalParameter) &&
          parent.identifier == node) {
        var grandparent = parent.parent;
        if (grandparent is DefaultFormalParameter) {
          return grandparent;
        }
        return parent;
      }
    }
    return null;
  }

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (!libraryElement.featureSet.isEnabled(Feature.super_parameters)) {
      // If the library doesn't support super_parameters then the change isn't
      // appropriate.
      return;
    }
    var parameter = _formalParameter;
    if (parameter == null) {
      // If the user hasn't selected a formal parameter to convert then there
      // is nothing to change.
      return;
    }
    var parameterList = parameter.parent;
    if (parameterList is! FormalParameterList) {
      // This is here to safely cast the parent. This branch should never be
      // reached.
      return;
    }
    var constructor = parameterList.parent;
    if (constructor is! ConstructorDeclaration) {
      // If this isn't a parameter in a constructor declaration then the change
      // isn't appropriate.
      return;
    }
    var superInvocation = _superInvocation(constructor);
    if (superInvocation == null) {
      // If there isn't an explicit invocation of the super constructor then the
      // change isn't appropriate.
      return;
    }
    var superConstructor = superInvocation.staticElement;
    if (superConstructor == null) {
      // If the super constructor wasn't resolved then we can't apply the
      // change.
      return;
    }
    var thisParameter = parameter.declaredElement;
    if (thisParameter == null) {
      return;
    }

    _ParameterData? data;
    if (parameter.isPositional) {
      data = _dataForPositionalParameter(
          parameter, thisParameter, superConstructor, superInvocation);
    } else if (parameter.isNamed) {
      data = _dataForNamedParameter(
          parameter, thisParameter, superConstructor, superInvocation);
    }
    if (data == null) {
      return;
    }

    final parameterData = data;
    await builder.addDartFileEdit(file, (builder) {
      var typeToDelete = parameterData.typeToDelete;
      if (typeToDelete == null) {
        builder.addSimpleInsertion(parameter.identifier!.offset, 'super.');
      } else {
        var primaryRange = typeToDelete.primaryRange;
        if (primaryRange == null) {
          builder.addSimpleInsertion(parameter.identifier!.offset, 'super.');
        } else {
          builder.addSimpleReplacement(primaryRange, 'super.');
        }
        var parameterRange = typeToDelete.parameterRange;
        if (parameterRange != null) {
          builder.addDeletion(parameterRange);
        }
      }
      parameterData.argumentUpdate.addDeletion(builder);
      var defaultValueRange = parameterData.defaultValueRange;
      if (defaultValueRange != null) {
        builder.addDeletion(defaultValueRange);
      }
    });
  }

  ParameterElement? _correspondingNamedParameter(
      ConstructorElement superConstructor, ParameterElement thisParameter) {
    for (var superParameter in superConstructor.parameters) {
      if (superParameter.isNamed && superParameter.name == thisParameter.name) {
        return superParameter;
      }
    }
    return null;
  }

  /// Return `true` if the named [parameter] can be converted into a super
  /// initializing formal parameter.
  _ParameterData? _dataForNamedParameter(
      FormalParameter parameter,
      ParameterElement thisParameter,
      ConstructorElement superConstructor,
      SuperConstructorInvocation superInvocation) {
    var superParameter =
        _correspondingNamedParameter(superConstructor, thisParameter);
    if (superParameter == null) {
      return null;
    }
    // Validate that the parameter is used in the super constructor invocation.
    _ArgumentUpdate? argumentUpdate;
    var arguments = superInvocation.argumentList.arguments;
    for (var argument in arguments) {
      if (argument is NamedExpression &&
          argument.name.label.name == thisParameter.name) {
        var expression = argument.expression;
        if (expression is SimpleIdentifier &&
            expression.staticElement == thisParameter) {
          argumentUpdate = _RemoveArgument(argument);
          break;
        }
      }
    }
    if (argumentUpdate == null) {
      // If the selected parameter isn't being passed to the super constructor,
      // then the change isn't appropriate.
      return null;
    } else if (arguments.length == 1) {
      // If the selected parameter is the only parameter being passed to the
      // super constructor then we no longer need to invoke the super
      // constructor.
      argumentUpdate = _RemoveInvocation(superInvocation);
    }
    // Compare the types.
    var superType = superParameter.type;
    var thisType = thisParameter.type;
    if (!typeSystem.isAssignableTo(superType, thisType)) {
      // If the type of the selected parameter can't be assigned to the super
      // parameter, the the change isn't appropriate.
      return null;
    }
    // Return the data.
    return _ParameterData(
      argumentUpdate: argumentUpdate,
      defaultValueRange:
          _defaultValueRange(parameter, superParameter, thisParameter),
      typeToDelete: superType == thisType ? _type(parameter) : null,
    );
  }

  /// Return `true` if the positional [parameter] can be converted into a super
  /// initializing formal parameter.
  _ParameterData? _dataForPositionalParameter(
      FormalParameter parameter,
      ParameterElement thisParameter,
      ConstructorElement superConstructor,
      SuperConstructorInvocation superInvocation) {
    var positionalArguments = _positionalArguments(superInvocation);
    if (positionalArguments.length != 1) {
      // If there's more than one positional parameter then they would all need
      // to be converted at the same time. If there's less than one, the the
      // selected parameter isn't being passed to the super constructor.
      return null;
    }
    var argument = positionalArguments[0];
    if (argument is! SimpleIdentifier ||
        argument.staticElement != parameter.declaredElement) {
      // If the selected parameter isn't the one being passed to the super
      // constructor then the change isn't appropriate.
      return null;
    }
    var positionalParameters = superConstructor.parameters
        .where((param) => param.isPositional)
        .toList();
    if (positionalParameters.isEmpty) {
      return null;
    }
    var superParameter = positionalParameters[0];
    _ArgumentUpdate? argumentUpdate;
    if (superInvocation.argumentList.arguments.length == 1) {
      argumentUpdate = _RemoveInvocation(superInvocation);
    } else {
      argumentUpdate = _RemoveArgument(argument);
    }
    // Compare the types.
    var superType = superParameter.type;
    var thisType = thisParameter.type;
    if (!typeSystem.isSubtypeOf(thisType, superType)) {
      // If the type of the selected parameter can't be assigned to the super
      // parameter, the the change isn't appropriate.
      return null;
    }
    // Return the data.
    return _ParameterData(
      argumentUpdate: argumentUpdate,
      defaultValueRange:
          _defaultValueRange(parameter, superParameter, thisParameter),
      typeToDelete: superType == thisType ? _type(parameter) : null,
    );
  }

  /// Return the range of the default value associated with the [parameter], or
  /// `null` if the parameter doesn't have a default value or if the default
  /// value is not the same as the default value in the super constructor.
  SourceRange? _defaultValueRange(FormalParameter parameter,
      ParameterElement superParameter, ParameterElement thisParameter) {
    if (parameter is DefaultFormalParameter) {
      var defaultValue = parameter.defaultValue;
      if (defaultValue != null) {
        var superDefault = superParameter.computeConstantValue();
        var thisDefault = thisParameter.computeConstantValue();
        if (superDefault != null && superDefault == thisDefault) {
          return range.endEnd(parameter.identifier!, defaultValue);
        }
      }
    }
    return null;
  }

  List<Expression> _positionalArguments(SuperConstructorInvocation invocation) {
    return invocation.argumentList.arguments
        .where((argument) => argument is! NamedExpression)
        .toList();
  }

  SuperConstructorInvocation? _superInvocation(
      ConstructorDeclaration constructor) {
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

  _TypeData? _type(FormalParameter parameter) {
    if (parameter is DefaultFormalParameter) {
      return _type(parameter.parameter);
    } else if (parameter is SimpleFormalParameter) {
      var typeAnnotation = parameter.type;
      if (typeAnnotation != null) {
        return _TypeData(
            primaryRange:
                range.startStart(typeAnnotation, parameter.identifier!));
      }
    } else if (parameter is FunctionTypedFormalParameter) {
      var returnType = parameter.returnType;
      return _TypeData(
          primaryRange: returnType != null
              ? range.startStart(returnType, parameter.identifier)
              : null,
          parameterRange: range.node(parameter.parameters));
    }
    return null;
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static ConvertToSuperInitializingParameter newInstance() =>
      ConvertToSuperInitializingParameter();
}

abstract class _ArgumentUpdate {
  void addDeletion(DartFileEditBuilder builder);
}

class _ParameterData {
  /// Information used to remove the argument from the super constructor
  /// invocation.
  final _ArgumentUpdate argumentUpdate;

  /// Information about the type annotation that should be deleted, or `null` if
  /// there is no type annotation to delete or if the type should not be
  /// deleted.
  final _TypeData? typeToDelete;

  /// The range of the default value that is to be deleted, or `null` if there
  /// is no default value, the default value isn't to be deleted.
  final SourceRange? defaultValueRange;

  /// Initialize a newly create data object.
  _ParameterData(
      {required this.argumentUpdate,
      required this.typeToDelete,
      required this.defaultValueRange});
}

class _RemoveArgument extends _ArgumentUpdate {
  final Expression argument;

  _RemoveArgument(this.argument);

  @override
  void addDeletion(DartFileEditBuilder builder) {
    var argumentList = argument.parent as ArgumentList;
    var index = argumentList.arguments.indexOf(argument);
    builder.addDeletion(range.argumentRange(argumentList, index, index, true));
  }
}

class _RemoveInvocation extends _ArgumentUpdate {
  final SuperConstructorInvocation invocation;

  _RemoveInvocation(this.invocation);

  @override
  void addDeletion(DartFileEditBuilder builder) {
    var declaration = invocation.parent as ConstructorDeclaration;
    var initializerList = declaration.initializers;
    if (initializerList.length == 1) {
      builder.addDeletion(range.endEnd(declaration.parameters, invocation));
    } else {
      builder.addDeletion(range.nodeInList(initializerList, invocation));
    }
  }
}

class _TypeData {
  SourceRange? primaryRange;

  SourceRange? parameterRange;

  _TypeData({required this.primaryRange, this.parameterRange});
}
