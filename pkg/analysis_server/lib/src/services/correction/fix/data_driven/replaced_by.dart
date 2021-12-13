// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_descriptor.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
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
  void apply(DartFileEditBuilder builder, DataDrivenFix fix, _Data data) {
    var referenceRange = data.referenceRange;
    builder.addSimpleReplacement(referenceRange, _referenceTo(newElement));
  }

  @override
  _Data? validate(DataDrivenFix fix) {
    var node = fix.node;
    if (node is SimpleIdentifier) {
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
      var typeName = node.type2.name;
      SimpleIdentifier classNameNode;
      if (typeName is SimpleIdentifier) {
        classNameNode = typeName;
      } else if (typeName is PrefixedIdentifier) {
        classNameNode = typeName.identifier;
      } else {
        return null;
      }
      var constructorNameNode = node.name;
      var constructorName = constructorNameNode?.name ?? '';
      var components = fix.element.components;
      if (components.length == 2 &&
          constructorName == components[0] &&
          classNameNode.name == components[1]) {
        if (constructorNameNode != null) {
          return _Data(range.startEnd(classNameNode, constructorNameNode));
        }
        return _Data(range.node(classNameNode));
      }
    }
    return null;
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

  _Data(this.referenceRange);
}
