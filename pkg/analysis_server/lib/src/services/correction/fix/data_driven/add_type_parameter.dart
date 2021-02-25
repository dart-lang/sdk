// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/code_template.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:meta/meta.dart';

/// The data related to a type parameter that was added to either a function or
/// a type.
class AddTypeParameter extends Change<_Data> {
  /// The index of the type parameter that was added.
  final int index;

  /// The name of the type parameter that was added.
  final String name;

  /// The name of the type that the type parameter extends, or `null` if the
  /// type parameter doesn't have a bound.
  final CodeTemplate extendedType;

  /// The code template used to compute the value of the type argument.
  final CodeTemplate argumentValue;

  /// Initialize a newly created change to describe adding a type parameter to a
  /// type or a function.
  AddTypeParameter(
      {@required this.index,
      @required this.name,
      @required this.argumentValue,
      @required this.extendedType})
      : assert(index >= 0),
        assert(name != null),
        assert(argumentValue != null);

  @override
  void apply(DartFileEditBuilder builder, DataDrivenFix fix, _Data data) {
    if (data is _TypeArgumentData) {
      _applyToTypeArguments(builder, fix, data);
    } else if (data is _TypeParameterData) {
      _applyToTypeParameters(builder, fix, data);
    } else {
      throw StateError('Unsupported class of data: ${data.runtimeType}');
    }
  }

  @override
  _Data validate(DataDrivenFix fix) {
    var node = fix.node;
    var context = TemplateContext.forInvocation(node, fix.utils);
    if (node is NamedType) {
      // wrong_number_of_type_arguments
      // wrong_number_of_type_arguments_constructor
      if (!argumentValue.validate(context)) {
        return null;
      }
      var typeArguments = node.typeArguments;
      if (_isInvalidIndex(typeArguments?.arguments)) {
        return null;
      }
      return _TypeArgumentData(typeArguments, node.name.end);
    }
    var parent = node.parent;
    if (parent is InvocationExpression) {
      // wrong_number_of_type_arguments_method
      var argument = argumentValue.validate(context);
      if (argument == null) {
        return null;
      }
      var typeArguments = parent.typeArguments;
      if (_isInvalidIndex(typeArguments?.arguments)) {
        return null;
      }
      return _TypeArgumentData(typeArguments, parent.argumentList.offset);
    } else if (parent is MethodDeclaration) {
      // invalid_override
      if (extendedType != null && !extendedType.validate(context)) {
        return null;
      }
      var typeParameters = parent.typeParameters;
      if (_isInvalidIndex(typeParameters?.typeParameters)) {
        return null;
      }
      return _TypeParameterData(typeParameters, parent.name.end);
    } else if (node is TypeArgumentList && parent is ExtensionOverride) {
      // wrong_number_of_type_arguments_extension
      var argument = argumentValue.validate(context);
      if (argument == null) {
        return null;
      }
      if (_isInvalidIndex(node?.arguments)) {
        return null;
      }
      return _TypeArgumentData(node, parent.extensionName.end);
    }
    return null;
  }

  void _applyToTypeArguments(
      DartFileEditBuilder builder, DataDrivenFix fix, _TypeArgumentData data) {
    var context = TemplateContext.forInvocation(fix.node, fix.utils);
    var typeArguments = data.typeArguments;
    if (typeArguments == null) {
      // Adding the first type argument.
      builder.addInsertion(data.newListOffset, (builder) {
        builder.write('<');
        argumentValue.writeOn(builder, context);
        builder.write('>');
      });
    } else {
      if (index == 0) {
        // Inserting the type argument at the beginning of the list.
        builder.addInsertion(typeArguments.leftBracket.end, (builder) {
          argumentValue.writeOn(builder, context);
          builder.write(', ');
        });
      } else {
        // Inserting the type argument after an existing type argument.
        var previous = typeArguments.arguments[index - 1];
        builder.addInsertion(previous.end, (builder) {
          builder.write(', ');
          argumentValue.writeOn(builder, context);
        });
      }
    }
  }

  void _applyToTypeParameters(
      DartFileEditBuilder builder, DataDrivenFix fix, _TypeParameterData data) {
    var context = TemplateContext.forInvocation(fix.node, fix.utils);

    void writeParameter(DartEditBuilder builder) {
      builder.write(name);
      if (extendedType != null) {
        builder.write(' extends ');
        extendedType.writeOn(builder, context);
      }
    }

    var typeParameters = data.typeParameters;
    if (typeParameters == null) {
      // Adding the first type argument.
      builder.addInsertion(data.newListOffset, (builder) {
        builder.write('<');
        writeParameter(builder);
        builder.write('>');
      });
    } else {
      if (index == 0) {
        // Inserting the type argument at the beginning of the list.
        builder.addInsertion(typeParameters.leftBracket.end, (builder) {
          writeParameter(builder);
          builder.write(', ');
        });
      } else {
        // Inserting the type argument after an existing type argument.
        var previous = typeParameters.typeParameters[index - 1];
        builder.addInsertion(previous.end, (builder) {
          builder.write(', ');
          writeParameter(builder);
        });
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

  /// The offset at which the type argument list should be inserted if
  /// [typeArguments] is `null`.
  final int newListOffset;

  /// Initialize newly created data.
  _TypeArgumentData(this.typeArguments, this.newListOffset);
}

/// The data returned when updating a type parameter list.
class _TypeParameterData extends _Data {
  /// The list of type parameters to which a new type parameter is being added,
  /// or `null` if the first type parameter is being added.
  final TypeParameterList typeParameters;

  /// The offset at which the type parameter list should be inserted if
  /// [typeParameters] is `null`.
  final int newListOffset;

  /// Initialize newly created data.
  _TypeParameterData(this.typeParameters, this.newListOffset);
}
