// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:meta/meta.dart';

/// The data related to an element that has been renamed.
class Rename extends Change<SimpleIdentifier> {
  /// The new name of the element.
  final String newName;

  /// Initialize a newly created transform to describe a renaming of an element
  /// to the [newName].
  Rename({@required this.newName});

  @override
  void apply(DartFileEditBuilder builder, DataDrivenFix fix,
      SimpleIdentifier nameNode) {
    if (fix.element.isConstructor) {
      var parent = nameNode.parent;
      if (parent is ConstructorName) {
        if (nameNode != null && newName.isEmpty) {
          // The constructor was renamed from a named constructor to an unnamed
          // constructor.
          builder.addDeletion(range.startEnd(parent.period, parent));
        } else if (nameNode == null && newName.isNotEmpty) {
          // The constructor was renamed from an unnamed constructor to a named
          // constructor.
          builder.addSimpleInsertion(parent.end, '.$newName');
        } else {
          // The constructor was renamed from a named constructor to another
          // named constructor.
          builder.addSimpleReplacement(range.node(nameNode), newName);
        }
      } else if (parent is MethodInvocation) {
        if (newName.isEmpty) {
          // The constructor was renamed from a named constructor to an unnamed
          // constructor.
          builder.addDeletion(range.startEnd(parent.operator, nameNode));
        } else {
          // The constructor was renamed from a named constructor to another
          // named constructor.
          builder.addSimpleReplacement(range.node(nameNode), newName);
        }
      } else if (parent is TypeName && parent.parent is ConstructorName) {
        // The constructor was renamed from an unnamed constructor to a named
        // constructor.
        builder.addSimpleInsertion(parent.end, '.$newName');
      } else {
        // The constructor was renamed from a named constructor to another named
        // constructor.
        builder.addSimpleReplacement(range.node(nameNode), newName);
      }
    } else {
      // The name is a simple identifier.
      builder.addSimpleReplacement(range.node(nameNode), newName);
    }
  }

  @override
  SimpleIdentifier validate(DataDrivenFix fix) {
    var node = fix.node;
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is Label && parent.parent is NamedExpression) {
        var invocation = parent.parent.parent.parent;
        if (invocation is InstanceCreationExpression) {
          invocation.constructorName.name;
        } else if (invocation is MethodInvocation) {
          return invocation.methodName;
        }
        return null;
      }
      return node;
    } else if (node is ConstructorName) {
      return node.name;
    }
    return null;
  }
}
