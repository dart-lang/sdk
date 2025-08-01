// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// The data related to a parameter that has been renamed.
class RenameParameter extends Change<_Data> {
  /// The old name of the parameter.
  final String oldName;

  /// The new name of the parameter.
  final String newName;

  /// Initialize a newly created transform to describe a renaming of a parameter
  /// from the [oldName] to the [newName].
  RenameParameter({required this.newName, required this.oldName});

  @override
  // The private type of the [data] parameter is dictated by the signature of
  // the super-method and the class's super-class.
  // ignore: library_private_types_in_public_api
  void apply(DartFileEditBuilder builder, DataDrivenFix fix, _Data data) {
    if (data is _InvocationData) {
      builder.addSimpleReplacement(range.node(data.nameNode), newName);
    } else if (data is _OverrideData) {
      var declaration = data.methodDeclaration;
      var parameter = declaration.parameterNamed(oldName);
      if (parameter != null) {
        var overriddenMethod = declaration.overriddenElement;
        var overriddenParameter = overriddenMethod?.parameterNamed(oldName);
        if (overriddenParameter == null) {
          // If the overridden parameter has already been removed, then just
          // rename the old parameter to have the new name.
          var identifier = parameter.name;
          if (identifier != null) {
            builder.addSimpleReplacement(range.token(identifier), newName);
          }
        } else {
          // If the overridden parameter still exists, then mark the overriding
          // parameter as deprecated (if it isn't already and the overridden
          // parameter is) and add a declaration of the new parameter.
          var parameterElement = parameter.declaredFragment?.element;
          if (parameterElement != null) {
            builder.addInsertion(parameter.offset, (builder) {
              builder.writeParameter(
                newName,
                isCovariant: parameterElement.isCovariant,
                isRequiredNamed: parameterElement.isRequiredNamed,
                type: parameterElement.type,
              );
              builder.write(', ');
              if (overriddenParameter.metadata.hasDeprecated &&
                  !parameterElement.metadata.hasDeprecated) {
                builder.write('@deprecated ');
              }
            });
          }
        }
      }
    }
  }

  @override
  // The private return type is dictated by the signature of the super-method
  // and the class's super-class.
  // ignore: library_private_types_in_public_api
  _Data validate(DataDrivenFix fix) {
    var node = fix.node;
    if (node is MethodDeclaration) {
      return _OverrideData(node);
    } else if (node is SimpleIdentifier) {
      var parent = node.parent;
      var grandParent = parent?.parent;
      if (node.name == oldName &&
          parent is Label &&
          grandParent is NamedExpression) {
        var invocation = grandParent.parent?.parent;
        if (invocation != null) {
          return _InvocationData(node);
        }
      } else if (parent is MethodInvocation) {
        for (var argument in parent.argumentList.arguments) {
          if (argument is NamedExpression) {
            var label = argument.name.label;
            if (label.name == oldName) {
              return _InvocationData(label);
            }
          }
        }
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
  /// Returns the element that this method overrides.
  ///
  /// Returns `null` if this method doesn't override any inherited member.
  ExecutableElement? get overriddenElement {
    var element = declaredFragment?.element;
    if (element != null) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement is InterfaceElement) {
        var name = Name(enclosingElement.library.uri, element.name!);
        return enclosingElement.getInheritedMember(name);
      }
    }
    return null;
  }

  /// Returns the parameter of this method whose name matches the given [name].
  ///
  /// Returns `null` if there is no such parameter.
  FormalParameter? parameterNamed(String name) {
    var parameters = this.parameters;
    if (parameters != null) {
      for (var parameter in parameters.parameters) {
        if (parameter.declaredFragment?.name == name) {
          return parameter;
        }
      }
    }
    return null;
  }
}

extension on ExecutableElement {
  /// Returns the parameter of this executable element whose name matches the
  /// given [name]
  ///
  /// Returns `null` if there is no such parameter.
  FormalParameterElement? parameterNamed(String name) {
    for (var formalParameter in formalParameters) {
      if (formalParameter.name == name) {
        return formalParameter;
      }
    }
    return null;
  }
}
