// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart' show InterfaceElement;
import 'package:analyzer/dart/element/type.dart';

/// A description of an element.
class ElementDescriptor {
  /// The URIs of the library in which the element is defined.
  final List<Uri> libraryUris;

  /// The kind of element that was changed.
  final ElementKind kind;

  /// A flag indicating whether the element is a static member of a container
  /// such as a class, enum, mixin, or extension.
  ///
  /// The flag should be `false` for top-level declarations. The implication is
  /// that the flag will only be true if the list of [components] has more than
  /// one element.
  final bool isStatic;

  /// The components that uniquely identify the element within its library. The
  /// components are ordered from the most local to the most global.
  final List<String> components;

  /// Initialize a newly created element descriptor to describe an element
  /// accessible via any of the [libraryUris] where the path to the element
  /// within the library is given by the list of [components]. The [kind] of the
  /// element is represented by the key used in the data file.
  ElementDescriptor(
      {required this.libraryUris,
      required this.kind,
      required this.isStatic,
      required this.components});

  /// Return `true` if the described element is a constructor.
  bool get isConstructor => kind == ElementKind.constructorKind;

  /// Return `true` if the given [node] appears to be consistent with the
  /// element being described.
  bool matches(AstNode node) {
    // TODO(brianwilkerson) Check the resolved element, if one exists, for more
    //  accurate results.
    return switch (kind) {
      ElementKind.classKind =>
        // TODO(brianwilkerson) Handle this case.
        false,
      ElementKind.constantKind =>
        // TODO(brianwilkerson) Handle this case.
        false,
      ElementKind.constructorKind => _matchesConstructor(node),
      ElementKind.enumKind =>
        // TODO(brianwilkerson) Handle this case.
        false,
      ElementKind.extensionKind =>
        // TODO(brianwilkerson) Handle this case.
        false,
      ElementKind.fieldKind =>
        // TODO(brianwilkerson) Handle this case.
        false,
      ElementKind.functionKind => _matchesFunction(node),
      ElementKind.getterKind =>
        // TODO(brianwilkerson) Handle this case.
        false,
      ElementKind.methodKind => _matchesMethod(node),
      ElementKind.mixinKind =>
        // TODO(brianwilkerson) Handle this case.
        false,
      ElementKind.setterKind =>
        // TODO(brianwilkerson) Handle this case.
        false,
      ElementKind.typedefKind =>
        // TODO(brianwilkerson) Handle this case.
        false,
      ElementKind.variableKind =>
        // TODO(brianwilkerson) Handle this case.
        false
    };
  }

  /// Return `true` if the given [node] appears to be consistent with the
  /// constructor being described.
  bool _matchesConstructor(AstNode node) {
    if (node is Annotation) {
      var className = _nameFromIdentifier(node.name);
      var constructorName = node.constructorName ?? '';
      if (components[0] == constructorName && components[1] == className) {
        return true;
      }
    } else if (node is InstanceCreationExpression) {
      var name = node.constructorName;
      var className = name.type.name2.lexeme;
      var constructorName = name.name?.name ?? '';
      if (components[0] == constructorName && components[1] == className) {
        return true;
      }
    } else if (node is MethodInvocation) {
      var target = node.target;
      if (target == null) {
        if (components[0] == '' && components[1] == node.methodName.name) {
          return true;
        }
      } else if (target is Identifier) {
        var className = _nameFromIdentifier(target);
        var constructorName = node.methodName.name;
        if (components[0] == constructorName && components[1] == className) {
          return true;
        }
      }
    }
    return false;
  }

  /// Return `true` if the given [node] appears to be consistent with the
  /// function being described.
  bool _matchesFunction(AstNode node) {
    if (node is MethodInvocation) {
      if (node.realTarget == null && components[0] == node.methodName.name) {
        return true;
      }
    }
    return false;
  }

  /// Return `true` if the given [node] appears to be consistent with the
  /// method being described.
  bool _matchesMethod(AstNode node) {
    if (node is MethodInvocation) {
      if (components[0] == node.methodName.name) {
        var target = node.realTarget;
        if (target == null) {
          // TODO(brianwilkerson) If `node.target == null` then the invocation
          //  should be in a subclass of the element's class.
          return true;
        } else {
          var type = target.staticType;
          if (type == null && target is SimpleIdentifier) {
            var element = target.staticElement;
            // TODO(brianwilkerson) Handle more than `InterfaceElement`.
            if (element is InterfaceElement) {
              type = element.thisType;
            }
          }
          if (type == null) {
            // We can't get more specific type information, so we assume
            // that the method might have been in the element's class.
            return true;
          }
          if (type is InterfaceType) {
            if (components[1] == type.element.name) {
              return true;
            }
            for (var supertype in type.allSupertypes) {
              if (components[1] == supertype.element.name) {
                return true;
              }
            }
          }
        }
      }
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
