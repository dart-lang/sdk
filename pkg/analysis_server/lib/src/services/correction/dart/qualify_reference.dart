// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class QualifyReference extends ResolvedCorrectionProducer {
  String _qualifiedName = '';

  @override
  List<Object> get fixArguments => [_qualifiedName];

  @override
  FixKind get fixKind => DartFixKind.QUALIFY_REFERENCE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var memberName = node;
    if (memberName is! SimpleIdentifier) {
      return;
    }

    AstNode? target;
    var parent = node.parent;
    if (parent is MethodInvocation && node == parent.methodName) {
      target = parent.target;
    } else if (parent is PropertyAccess && node == parent.propertyName) {
      target = parent.target;
    }
    if (target != null) {
      return;
    }

    var memberElement = memberName.staticElement;
    if (memberElement == null) {
      return;
    }

    var enclosingElement = memberElement.enclosingElement2;
    if (enclosingElement == null ||
        enclosingElement.library != libraryElement) {
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
}
