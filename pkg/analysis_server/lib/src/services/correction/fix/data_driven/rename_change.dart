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
class RenameChange extends Change<SimpleIdentifier> {
  /// The new name of the element.
  final String newName;

  /// Initialize a newly created transform to describe a renaming of an element
  /// to the [newName].
  RenameChange({@required this.newName});

  @override
  void apply(DartFileEditBuilder builder, DataDrivenFix fix,
      SimpleIdentifier nameNode) {
    builder.addSimpleReplacement(range.node(nameNode), newName);
  }

  @override
  SimpleIdentifier validate(DataDrivenFix fix) {
    var node = fix.node;
    if (node is SimpleIdentifier) {
      return node;
    } else if (node is ConstructorName) {
      return node.name;
    }
    return null;
  }
}
