// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:meta/meta.dart';

/// The data related to a parameter that has been renamed.
class RenameParameter extends Change<_Data> {
  /// The old name of the parameter.
  final String oldName;

  /// The new name of the parameter.
  final String newName;

  /// Initialize a newly created transform to describe a renaming of a parameter
  /// from the [oldName] to the [newName].
  RenameParameter({@required this.newName, @required this.oldName});

  @override
  void apply(DartFileEditBuilder builder, DataDrivenFix fix, _Data data) {
    if (data is _InvocationData) {
      builder.addSimpleReplacement(range.node(data.nameNode), newName);
    } else if (data is _OverrideData) {
      var declaration = data.methodDeclaration;
      var parameter = declaration.parameterNamed(oldName);
      if (parameter != null) {
        var overriddenMethod = declaration.overriddenElement();
        var overriddenParameter = overriddenMethod?.parameterNamed(oldName);
        if (overriddenParameter == null) {
          // If the overridden parameter has already been removed, then just
          // rename the old parameter to have the new name.
          builder.addSimpleReplacement(
              range.node(parameter.identifier), newName);
        } else {
          // If the overridden parameter still exists, then mark it as
          // deprecated (if it isn't already) and add a declaration of the new
          // parameter.
          builder.addInsertion(parameter.offset, (builder) {
            var parameterElement = parameter.declaredElement;
            builder.writeParameter(newName,
                isCovariant: parameterElement.isCovariant,
                isRequiredNamed: parameterElement.isRequiredNamed,
                type: parameterElement.type);
            builder.write(', ');
            if (!parameterElement.hasDeprecated) {
              builder.write('@deprecated ');
            }
          });
        }
      }
    }
  }

  @override
  _Data validate(DataDrivenFix fix) {
    var node = fix.node;
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (node.name == oldName &&
          parent is Label &&
          parent.parent is NamedExpression) {
        var invocation = parent.parent.parent.parent;
        if (fix.element.matches(invocation)) {
          return _InvocationData(node);
        }
      } else if (parent is MethodDeclaration) {
        return _OverrideData(parent);
      }
    }
    return const _IgnoredData();
  }
}

/// The data returned from `validate`.
abstract class _Data {
  const _Data();
}

/// The data returned when the change doesn't apply.
class _IgnoredData extends _Data {
  const _IgnoredData();
}

/// The data returned when updating an invocation site.
class _InvocationData extends _Data {
  /// The node representing the name to be replaced.
  final SimpleIdentifier nameNode;

  /// Initialize newly created data about an invocation site.
  _InvocationData(this.nameNode);
}

/// The data returned when updating an override site.
class _OverrideData extends _Data {
  /// The node representing the overriding method.
  final MethodDeclaration methodDeclaration;

  /// Initialize newly created data about an override site.
  _OverrideData(this.methodDeclaration);
}

extension on MethodDeclaration {
  /// Return the parameter of this method whose name matches the given [name],
  /// or `null` if there is no such parameter.
  FormalParameter parameterNamed(String name) {
    for (var parameter in parameters.parameters) {
      if (parameter.declaredElement.name == name) {
        return parameter;
      }
    }
    return null;
  }

  /// Return the element that this method overrides, or `null` if this method
  /// doesn't override any inherited member.
  ExecutableElement overriddenElement() {
    var element = declaredElement;
    var enclosingElement = element.enclosingElement;
    if (enclosingElement is ClassElement) {
      var name = Name(enclosingElement.library.source.uri, element.name);
      return InheritanceManager3().getInherited2(enclosingElement, name);
    }
    return null;
  }
}

extension on ExecutableElement {
  /// Return the parameter of this executable element whose name matches the
  /// given [name], or `null` if there is no such parameter.
  ParameterElement parameterNamed(String name) {
    for (var parameter in parameters) {
      if (parameter.name == name) {
        return parameter;
      }
    }
    return null;
  }
}
