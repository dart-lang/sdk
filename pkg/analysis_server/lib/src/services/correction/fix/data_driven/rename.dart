// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/change.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/element_kind.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// The data related to an element that has been renamed.
class Rename extends Change<_Data> {
  /// The new name of the element.
  final String newName;

  /// Initialize a newly created transform to describe a renaming of an element
  /// to the [newName].
  Rename({required this.newName});

  @override
  // The private type of the [data] parameter is dictated by the signature of
  // the super-method and the class's super-class.
  // ignore: library_private_types_in_public_api
  void apply(DartFileEditBuilder builder, DataDrivenFix fix, _Data data) {
    var nameToken = data.nameToken;
    if (fix.element.isConstructor) {
      var node = data.node;
      var parent = node.parent;
      if (node is ConstructorName) {
        if (nameToken != null && newName.isEmpty) {
          // The constructor was renamed from a named constructor to an unnamed
          // constructor.
          builder.addDeletion(range.startEnd(node.period!, node));
        } else if (nameToken == null && newName.isNotEmpty) {
          // The constructor was renamed from an unnamed constructor to a named
          // constructor.
          builder.addSimpleInsertion(node.end, '.$newName');
        } else if (nameToken != null) {
          // The constructor was renamed from a named constructor to another
          // named constructor.
          builder.addSimpleReplacement(range.token(nameToken), newName);
        }
      } else if (nameToken == null) {
        return;
      } else if (parent is MethodInvocation) {
        if (newName.isEmpty) {
          // The constructor was renamed from a named constructor to an unnamed
          // constructor.
          builder.addDeletion(range.startEnd(parent.operator!, nameToken));
        } else {
          // The constructor was renamed from a named constructor to another
          // named constructor.
          builder.addSimpleReplacement(range.token(nameToken), newName);
        }
      } else if (parent is NamedType && parent.parent is ConstructorName) {
        // The constructor was renamed from an unnamed constructor to a named
        // constructor.
        builder.addSimpleInsertion(parent.end, '.$newName');
      } else if (parent is PrefixedIdentifier) {
        // The constructor was renamed from an unnamed constructor to a named
        // constructor.
        builder.addSimpleInsertion(parent.end, '.$newName');
      } else {
        // The constructor was renamed from a named constructor to another named
        // constructor.
        builder.addSimpleReplacement(range.token(nameToken), newName);
      }
    } else if (nameToken != null) {
      // The name is a simple identifier.
      builder.addSimpleReplacement(range.token(nameToken), newName);
    }
  }

  @override
  // The private return type is dictated by the signature of the super-method
  // and the class's super-class.
  // ignore: library_private_types_in_public_api
  _Data? validate(DataDrivenFix fix) {
    var node = fix.node;
    if (node is ExtensionOverride) {
      return _Data(node, node.name);
    } else if (node is MethodDeclaration) {
      return _Data(node, node.name);
    } else if (node is NamedType) {
      var parent = node.parent;
      if (fix.element.kind == ElementKind.constructorKind &&
          parent is ConstructorName) {
        return _Data(parent, parent.name?.token);
      }
      return _Data(node, node.name2);
    } else if (node is SimpleIdentifier) {
      var parent = node.parent;
      var grandParent = parent?.parent;
      if (parent is Label && grandParent is NamedExpression) {
        var invocation = grandParent.parent?.parent;
        if (invocation is InstanceCreationExpression) {
          invocation.constructorName.name;
        } else if (invocation is MethodInvocation) {
          return _Data(node, invocation.methodName.token);
        }
        return null;
      }
      return _Data(node, node.token);
    } else if (node is ConstructorName) {
      return _Data(node, node.name?.token);
    } else if (node is PrefixedIdentifier) {
      return _Data(node.identifier, node.identifier.token);
    }
    return null;
  }
}

/// The data renaming a declaration.
class _Data {
  final AstNode node;
  final Token? nameToken;

  _Data(this.node, this.nameToken);
}
