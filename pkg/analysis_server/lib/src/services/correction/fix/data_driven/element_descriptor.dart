// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart' show ClassElement;
import 'package:analyzer/dart/element/type.dart';
import 'package:meta/meta.dart';

/// The path to an element.
class ElementDescriptor {
  /// The URIs of the library in which the element is defined.
  final List<Uri> libraryUris;

  /// The kind of element that was changed.
  final ElementKind kind;

  /// The components that uniquely identify the element within its library.
  final List<String> components;

  /// Initialize a newly created element descriptor to describe an element
  /// accessible via any of the [libraryUris] where the path to the element
  /// within the library is given by the list of [components]. The [kind] of the
  /// element is represented by the key used in the data file.
  ElementDescriptor(
      {@required this.libraryUris,
      @required this.kind,
      @required this.components});

  /// Return `true` if the described element is a constructor.
  bool get isConstructor => kind == ElementKind.constructorKind;

  /// Return `true` if the given [node] appears to be consistent with this kind
  /// of element.
  bool matches(AstNode node) {
    // TODO(brianwilkerson) Check the resolved element if one exists for more
    //  accurate results.
    switch (kind) {
      case ElementKind.classKind:
        // TODO: Handle this case.
        return false;
      case ElementKind.constantKind:
        // TODO: Handle this case.
        return false;
      case ElementKind.constructorKind:
        if (node is Annotation) {
          var className = _nameFromIdentifier(node.name);
          var constructorName = node.constructorName ?? '';
          if (components[0] == className && components[1] == constructorName) {
            return true;
          }
        } else if (node is InstanceCreationExpression) {
          var name = node.constructorName;
          var className = _nameFromIdentifier(name.type.name);
          var constructorName = name.name?.name ?? '';
          if (components[0] == className && components[1] == constructorName) {
            return true;
          }
        } else if (node is MethodInvocation) {
          var target = node.target;
          if (target == null) {
            if (components[0] == node.methodName.name && components[1] == '') {
              return true;
            }
          } else if (target is Identifier) {
            var className = _nameFromIdentifier(target);
            var constructorName = node.methodName.name;
            if (components[0] == className &&
                components[1] == constructorName) {
              return true;
            }
          }
        }
        return false;
      case ElementKind.enumKind:
        // TODO: Handle this case.
        return false;
      case ElementKind.extensionKind:
        // TODO: Handle this case.
        return false;
      case ElementKind.fieldKind:
        // TODO: Handle this case.
        return false;
      case ElementKind.functionKind:
        if (node is MethodInvocation) {
          if (node.realTarget == null &&
              components[0] == node.methodName.name) {
            return true;
          }
        }
        return false;
      case ElementKind.getterKind:
        // TODO: Handle this case.
        return false;
      case ElementKind.methodKind:
        if (node is MethodInvocation) {
          if (components[1] == node.methodName.name) {
            var target = node.realTarget;
            if (target == null) {
              // TODO(brianwilkerson) If `node.target == null` then the invocation
              //  should be in a subclass of the element's class.
              return true;
            } else {
              var type = target.staticType;
              if (type == null && target is SimpleIdentifier) {
                var element = target.staticElement;
                // TODO(brianwilkerson) Handle more than `ClassElement`.
                if (element is ClassElement) {
                  type = element.thisType;
                }
              }
              if (type == null) {
                // We can't get more specific type information, so we assume
                // that the method might have been in the element's class.
                return true;
              }
              if (components[0] == type.element.name) {
                return true;
              }
              if (type is InterfaceType) {
                for (var supertype in type.allSupertypes) {
                  if (components[0] == supertype.element.name) {
                    return true;
                  }
                }
              }
            }
          }
        }
        return false;
      case ElementKind.mixinKind:
        // TODO: Handle this case.
        return false;
      case ElementKind.setterKind:
        // TODO: Handle this case.
        return false;
      case ElementKind.typedefKind:
        // TODO: Handle this case.
        return false;
      case ElementKind.variableKind:
        // TODO: Handle this case.
        return false;
    }
    return false;
  }

  String _nameFromIdentifier(Identifier identifier) {
    if (identifier is SimpleIdentifier) {
      return identifier.name;
    } else if (identifier is PrefixedIdentifier) {
      return identifier.identifier.name;
    }
    throw StateError(
        'Unexpected class of identifier: ${identifier.runtimeType}');
  }
}
