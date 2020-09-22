// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/code_template.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/parameter_reference.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// Use a specified argument from an invocation as the value of a template
/// variable.
class ArgumentExpression extends ValueGenerator {
  /// The parameter corresponding to the argument from the original invocation,
  /// or `null` if the value of the argument can't be taken from the original
  /// invocation.
  final ParameterReference parameter;

  /// Initialize a newly created extractor to extract the argument that
  /// corresponds to the given [parameter].
  ArgumentExpression(this.parameter) : assert(parameter != null);

  @override
  String from(TemplateContext context) {
    var argumentList = _getArgumentList(context.node);
    if (argumentList != null) {
      var expression = parameter.argumentFrom(argumentList);
      if (expression != null) {
        return context.utils.getNodeText(expression);
      }
    }
    return null;
  }

  @override
  bool validate(TemplateContext context) {
    var argumentList = _getArgumentList(context.node);
    if (argumentList == null) {
      return false;
    }
    var expression = parameter.argumentFrom(argumentList);
    if (expression != null) {
      return false;
    }
    return true;
  }

  /// Return the argument list associated with the given [node].
  ArgumentList _getArgumentList(AstNode node) {
    if (node is ArgumentList) {
      return node;
    } else if (node is InvocationExpression) {
      return node.argumentList;
    } else if (node is InstanceCreationExpression) {
      return node.argumentList;
    } else if (node is TypeArgumentList) {
      var parent = node.parent;
      if (parent is InvocationExpression) {
        return parent.argumentList;
      } else if (parent is ExtensionOverride) {
        return parent.argumentList;
      }
    }
    return null;
  }
}

/// Use a name that might need to be imported from a different library as the
/// value of a template variable.
class ImportedName extends ValueGenerator {
  /// The URIs of the libraries from which the name can be imported.
  final List<String> uris;

  /// The name to be used.
  final String name;

  ImportedName(this.uris, this.name);

  @override
  String from(TemplateContext context) {
    // TODO(brianwilkerson) Figure out how to add the import when necessary.
    return name;
  }

  @override
  bool validate(TemplateContext context) {
    // TODO(brianwilkerson) Validate that the import can be added.
    return true;
  }
}

/// An object used to generate the value of a template variable.
abstract class ValueGenerator {
  /// Use the [context] to generate the value of a template variable and return
  /// the generated value.
  String from(TemplateContext context);

  /// Use the [context] to validate that this generator will be able to generate
  /// a value.
  bool validate(TemplateContext context);
}
