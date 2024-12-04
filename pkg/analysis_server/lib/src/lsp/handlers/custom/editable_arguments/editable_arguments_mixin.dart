// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/extensions/numeric.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';

/// Information about the arguments and parameters for an invocation.
typedef EditableInvocationInfo =
    ({
      List<FormalParameterElement> parameters,
      Map<FormalParameterElement, Expression> parameterArguments,
      Map<FormalParameterElement, int> positionalParameterIndexes,
      ArgumentList argumentList,
      int numPositionals,
      int numSuppliedPositionals,
    });

/// A mixin that provides functionality for locating arguments and associated
/// parameters in a document to allow a client to provide editing capabilities.
mixin EditableArgumentsMixin {
  /// Gets information about an invocation at [offset] in [result] that can be
  /// edited.
  EditableInvocationInfo? getInvocationInfo(
    ResolvedUnitResult result,
    int offset,
  ) {
    var node = result.unit.nodeCovering(offset: offset);
    // Walk up to find an invocation that is widget creation.
    var invocation = node?.thisOrAncestorMatching((node) {
      return switch (node) {
        InstanceCreationExpression() => node.isWidgetCreation,
        InvocationExpressionImpl() => node.isWidgetFactory,
        _ => false,
      };
    });

    // Return the related argument list.
    var (parameters, argumentList) = switch (invocation) {
      InstanceCreationExpression() => (
        invocation.constructorName.element?.formalParameters,
        invocation.argumentList,
      ),
      MethodInvocation(
        methodName: Identifier(element: ExecutableElement2 element),
      ) =>
        (element.formalParameters, invocation.argumentList),
      _ => (null, null),
    };

    if (parameters == null || argumentList == null) {
      return null;
    }

    var numPositionals = parameters.where((p) => p.isPositional).length;
    var numSuppliedPositionals =
        argumentList.arguments
            .where((argument) => argument is! NamedExpression)
            .length;

    // Build a map of parameters to their positional index so we can tell
    // whether a parameter that doesn't already have an argument will be
    // editable (positionals can only be added if all previous positionals
    // exist).
    var currentParameterIndex = 0;
    var positionalParameterIndexes = {
      for (var parameter in parameters)
        if (parameter.isPositional) parameter: currentParameterIndex++,
    };

    // Build a map of the parameters that have arguments so we can put them
    // first or look up whether a parameter is editable based on the argument.
    var parameterArguments = {
      for (var argument in argumentList.arguments)
        if (argument.correspondingParameter case var parameter?)
          parameter: argument,
    };

    return (
      parameters: parameters,
      positionalParameterIndexes: positionalParameterIndexes,
      parameterArguments: parameterArguments,
      argumentList: argumentList,
      numPositionals: numPositionals,
      numSuppliedPositionals: numSuppliedPositionals,
    );
  }

  /// Checks whether [argument] is editable and if not, returns a human-readable
  /// description why.
  String? getNotEditableReason({
    required Expression? argument,
    required int? positionalIndex,
    required int numPositionals,
    required int numSuppliedPositionals,
  }) {
    // If the argument has an existing value, editability is based only on that
    // value.
    if (argument != null) {
      return switch (argument) {
        AdjacentStrings() => "Adjacent strings can't be edited",
        StringInterpolation() => "Interpolated strings can't be edited",
        SimpleStringLiteral() when argument.value.contains('\n') =>
          "Strings containing newlines can't be edited",
        _ => null,
      };
    }

    // If we are missing positionals, we can only add this one if it is the next
    // (first missing) one.
    if (positionalIndex != null && numSuppliedPositionals < numPositionals) {
      // To be allowed, we must be the next one. Eg. our index is equal to the
      // length/count of the existing ones.
      if (positionalIndex != numSuppliedPositionals) {
        return 'A value for the ${(positionalIndex + 1).toStringWithSuffix()} '
            "parameter can't be added until a value for all preceding "
            'positional parameters have been added.';
      }
    }

    return null;
  }

  /// Returns the name of an enum constant prefixed with the enum name.
  String? getQualifiedEnumConstantName(FieldElement2 enumConstant) {
    var enumName = enumConstant.enclosingElement2.name3;
    var name = enumConstant.name3;
    return enumName != null && name != null ? '$enumName.$name' : null;
  }

  /// Returns a list of the constants of an enum constant prefixed with the enum
  /// name.
  List<String> getQualifiedEnumConstantNames(EnumElement2 element3) =>
      element3.constants2.map(getQualifiedEnumConstantName).nonNulls.toList();
}

extension on InvocationExpressionImpl {
  /// Whether this is an invocation for an extension method that has the
  /// `@widgetFactory` annotation.
  bool get isWidgetFactory {
    // Only consider functions that return widgets.
    if (!staticType.isWidgetType) {
      return false;
    }

    // We only support @widgetFactory on extension methods.
    var element = switch (function) {
      Identifier(:var element)
          when element?.enclosingElement2 is ExtensionElement2 =>
        element,
      _ => null,
    };

    return switch (element) {
      FragmentedAnnotatableElementMixin(:var metadata2) =>
        metadata2.hasWidgetFactory,
      _ => false,
    };
  }
}
