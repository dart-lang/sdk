// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class QualifyReference extends CorrectionProducer {
  String _qualifiedName;

  @override
  List<Object> get fixArguments => [_qualifiedName];

  @override
  FixKind get fixKind => DartFixKind.QUALIFY_REFERENCE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier memberName = node;
    var parent = node.parent;
    AstNode target;
    if (parent is MethodInvocation && node == parent.methodName) {
      target = parent.target;
    } else if (parent is PropertyAccess && node == parent.propertyName) {
      target = parent.target;
    }
    if (target != null) {
      return;
    }
    var enclosingElement = memberName.staticElement.enclosingElement;
    if (enclosingElement.library != libraryElement) {
      // TODO(brianwilkerson) Support qualifying references to members defined
      //  in other libraries. `DartEditBuilder` currently defines the method
      //  `writeType`, which is close, but we also need to handle extensions,
      //  which don't have a type.
      return;
    }
    var containerName = enclosingElement.name;
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(node.offset, '$containerName.');
    });
    _qualifiedName = '$containerName.${memberName.name}';
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static QualifyReference newInstance() => QualifyReference();
}
