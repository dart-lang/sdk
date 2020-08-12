// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/value_extractor.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:meta/meta.dart';

/// The data related to a type parameter that was added to either a function or
/// a type.
class AddTypeParameterChange extends Change<_Data> {
  /// The index of the type parameter that was added.
  final int index;

  /// The name of the type parameter that was added.
  final String name;

  /// The name of the type that the type parameter extends, or `null` if the
  /// type parameter doesn't have a bound.
  final String extendedType;

  /// The value extractor used to compute the value of the type argument.
  final ValueExtractor value;

  /// Initialize a newly created change to describe adding a type parameter to a
  /// type or a function.
  // TODO(brianwilkerson) Support adding multiple type parameters.
  AddTypeParameterChange(
      {@required this.index,
      @required this.name,
      @required this.value,
      this.extendedType})
      : assert(index >= 0),
        assert(name != null),
        assert(value != null);

  @override
  void apply(DartFileEditBuilder builder, DataDrivenFix fix, _Data data) {
    if (data is _TypeArgumentData) {
      _applyToTypeArguments(builder, data);
    } else {
      _applyToTypeParameters(builder, data as _TypeParameterData);
    }
  }

  @override
  _Data validate(DataDrivenFix fix) {
    var node = fix.node;
    if (node is NamedType) {
      // wrong_number_of_type_arguments
      // wrong_number_of_type_arguments_constructor
      var argument = value.from(node, fix.utils);
      if (argument == null) {
        return null;
      }
      var typeArguments = node.typeArguments;
      if (_isInvalidIndex(typeArguments?.arguments)) {
        return null;
      }
      return _TypeArgumentData(typeArguments, argument, node.name.end);
    }
    var parent = node.parent;
    if (parent is InvocationExpression) {
      // wrong_number_of_type_arguments_method
      var argument = value.from(parent, fix.utils);
      if (argument == null) {
        return null;
      }
      var typeArguments = parent.typeArguments;
      if (_isInvalidIndex(typeArguments?.arguments)) {
        return null;
      }
      return _TypeArgumentData(
          typeArguments, argument, parent.argumentList.offset);
    } else if (parent is MethodDeclaration) {
      // invalid_override
      var typeParameters = parent.typeParameters;
      if (_isInvalidIndex(typeParameters?.typeParameters)) {
        return null;
      }
      return _TypeParameterData(typeParameters, parent.name.end);
    } else if (node is TypeArgumentList && parent is ExtensionOverride) {
      // wrong_number_of_type_arguments_extension
      var argument = value.from(node, fix.utils);
      if (argument == null) {
        return null;
      }
      if (_isInvalidIndex(node?.arguments)) {
        return null;
      }
      return _TypeArgumentData(node, argument, parent.extensionName.end);
    }
    return null;
  }

  void _applyToTypeArguments(
      DartFileEditBuilder builder, _TypeArgumentData data) {
    var typeArguments = data.typeArguments;
    var argumentValue = data.argumentValue;
    if (typeArguments == null) {
      // Adding the first type argument.
      builder.addSimpleInsertion(data.newListOffset, '<$argumentValue>');
    } else {
      if (index == 0) {
        // Inserting the type argument at the beginning of the list.
        builder.addSimpleInsertion(
            typeArguments.leftBracket.end, '$argumentValue, ');
      } else {
        // Inserting the type argument after an existing type argument.
        var previous = typeArguments.arguments[index - 1];
        builder.addSimpleInsertion(previous.end, ', $argumentValue');
      }
    }
  }

  void _applyToTypeParameters(
      DartFileEditBuilder builder, _TypeParameterData data) {
    var argumentValue =
        extendedType == null ? name : '$name extends $extendedType';
    var typeParameters = data.typeParameters;
    if (typeParameters == null) {
      // Adding the first type argument.
      builder.addSimpleInsertion(data.newListOffset, '<$argumentValue>');
    } else {
      if (index == 0) {
        // Inserting the type argument at the beginning of the list.
        builder.addSimpleInsertion(
            typeParameters.leftBracket.end, '$argumentValue, ');
      } else {
        // Inserting the type argument after an existing type argument.
        var previous = typeParameters.typeParameters[index - 1];
        builder.addSimpleInsertion(previous.end, ', $argumentValue');
      }
    }
  }

  bool _isInvalidIndex(List<AstNode> list) {
    var length = list == null ? 0 : list.length;
    return index > length;
  }
}

/// The data returned when adding a type parameter.
class _Data {}

/// The data returned when updating a type argument list.
class _TypeArgumentData extends _Data {
  /// The list of type arguments to which a new type argument is being added, or
  /// `null` if the first type argument is being added.
  final TypeArgumentList typeArguments;

  /// The value of the type argument being added.
  final String argumentValue;

  /// The offset at which the type argument list should be inserted if
  /// [typeArguments] is `null`.
  final int newListOffset;

  /// Initialize newly created data.
  _TypeArgumentData(this.typeArguments, this.argumentValue, this.newListOffset);
}

/// The data returned when updating a type parameter list.
class _TypeParameterData extends _Data {
  /// The list of type parameters to which a new type paramete is being added,
  /// or `null` if the first type parameter is being added.
  final TypeParameterList typeParameters;

  /// The offset at which the type parameter list should be inserted if
  /// [typeParameters] is `null`.
  final int newListOffset;

  /// Initialize newly created data.
  _TypeParameterData(this.typeParameters, this.newListOffset);
}
