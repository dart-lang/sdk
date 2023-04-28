// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart' hide ElementKind;
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// The data related to an element that has been replaced by another element.
class ReplacedBy extends Change<_Data> {
  /// The replacing element.
  final ElementDescriptor newElement;

  /// Initialize a newly created transform to describe a replacement of an old
  /// element by a [newElement].
  ReplacedBy({required this.newElement});

  @override
  // The private type of the [data] parameter is dictated by the signature of
  // the super-method and the class's super-class.
  // ignore: library_private_types_in_public_api
  void apply(DartFileEditBuilder builder, DataDrivenFix fix, _Data data) {
    var referenceRange = data.referenceRange;
    builder.addSimpleReplacement(
        referenceRange, data.replacement ?? _referenceTo(newElement));
    var libraryUris = newElement.libraryUris;
    if (libraryUris.isEmpty) return;
    if (!libraryUris.any((uri) => builder.importsLibrary(uri))) {
      builder.importLibraryElement(libraryUris.first);
    }
  }

  @override
  // The private return type is dictated by the signature of the super-method
  // and the class's super-class.
  // ignore: library_private_types_in_public_api
  _Data? validate(DataDrivenFix fix) {
    var node = fix.node;
    if (node is SimpleIdentifier) {
      var staticElement = node.staticElement;
      if (staticElement is ExecutableElement && !staticElement.isStatic) {
        return _instance(node, staticElement);
      }

      var components = fix.element.components;
      if (components.isEmpty) {
        return null;
      } else if (components.length == 1) {
        if (components[0] != node.name) {
          return null;
        }
        // We have an '<element>' pattern, so we replace the name.
        return _Data(range.node(node));
      }
      // The element being replaced is a member in a top-level element.
      var containerName = components[1];
      if (components[0].isEmpty && containerName == node.name) {
        // We have a '<className>()' pattern, so we replace the class name.
        return _Data(range.node(node));
      }
      var parent = node.parent;
      if (parent is MethodInvocation) {
        var target = parent.target;
        if (target == null) {
          // We have a '<member>()' pattern, so we replace the member name.
          return _Data(range.node(node));
        } else if (target is SimpleIdentifier && target.name == containerName) {
          // We have a '<container>.<member>()' pattern, so we replace both parts.
          return _Data(range.startEnd(target, node));
        } else if (target is PrefixedIdentifier) {
          if (target.prefix.staticElement is PrefixElement &&
              target.identifier.name == containerName) {
            // We have a '<prefix>.<container>.<member>()' pattern so we leave
            // the prefix while replacing the rest.
            return _Data(range.startEnd(target.identifier, node));
          }
          // We shouldn't get here.
          return null;
        }
      } else if (parent is NamedType) {
        var grandparent = parent.parent;
        if (grandparent is ConstructorName &&
            grandparent.name?.name == components[0]) {
          // TODO(brianwilkerson) This doesn't correctly handle constructor
          //  invocations with type arguments. We really need to replace the
          //  class and constructor names separately.
          return _Data(range.node(grandparent));
        }
      } else if (parent is PrefixedIdentifier) {
        if (parent.prefix.staticElement is PrefixElement) {
          // We have a '<prefix>.<topLevel>' pattern so we leave the prefix
          // while replacing the rest.
          return _Data(range.node(node));
        }
        // We have a '<container>.<member>' pattern so we replace both parts.
        return _Data(range.node(parent));
      } else if (parent is PropertyAccess) {
        var target = parent.target;
        if (target is PrefixedIdentifier) {
          // We have a '<prefix>.<container>.<member>' pattern so we leave the
          // prefix while replacing the rest.
          return _Data(range.startEnd(target.identifier, node));
        }
        // We have a '<container>.<member>' pattern so we replace both parts.
        return _Data(range.node(parent));
      }
      // We have a '<member>' pattern so we replace the member name.
      return _Data(range.node(node));
    } else if (node is PrefixedIdentifier) {
      var parent = node.parent;
      if (parent is NamedType) {
        var identifier = node.identifier;
        var components = fix.element.components;
        if (components.length > 1 &&
            components[0].isEmpty &&
            components[1] == identifier.name) {
          // We have a '<prefix>.<className>' pattern, so we replace only the
          // class name.
          return _Data(range.node(identifier));
        }
      }
    } else if (node is ConstructorName) {
      var classNameToken = node.type.name2;
      var constructorNameNode = node.name;
      var constructorName = constructorNameNode?.name ?? '';
      var components = fix.element.components;
      if (components.length == 2 &&
          constructorName == components[0] &&
          classNameToken.lexeme == components[1]) {
        if (constructorNameNode != null) {
          return _Data(range.startEnd(classNameToken, constructorNameNode));
        }
        return _Data(range.token(classNameToken));
      }
    }
    return null;
  }

  /// Return a replacement of an instance kind, not static.
  _Data? _instance(AstNode node, ExecutableElement staticElement) {
    var newComponents = newElement.components;
    var newKind = newElement.kind;
    var suffix = '';
    SourceRange? referenceRange;
    if (newKind == ElementKind.methodKind &&
        staticElement is PropertyAccessorElement &&
        staticElement.isGetter) {
      suffix = '()';
      referenceRange = range.node(node);
    } else if (newKind == ElementKind.getterKind) {
      var parent = node.parent;
      if (parent is MethodInvocation) {
        var argumentList = parent.argumentList;
        if (argumentList.arguments.isNotEmpty) {
          return null;
        }
        referenceRange = range.startEnd(node, argumentList);
      }
    }
    if (referenceRange == null) return null;
    return _Data(
      referenceRange,
      replacement: '${newComponents[0]}$suffix',
    );
  }

  String _referenceTo(ElementDescriptor element) {
    var components = element.components;
    if (components[0].isEmpty) {
      return components[1];
    }
    return components.reversed.join('.');
  }
}

/// The data about a reference to an element that's been replaced.
class _Data {
  final SourceRange referenceRange;
  final String? replacement;

  _Data(this.referenceRange, {this.replacement});
}
