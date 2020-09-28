// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class CreateFunction extends CorrectionProducer {
  String _functionName;

  @override
  List<Object> get fixArguments => [_functionName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_FUNCTION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // should be the name of the invocation
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
    } else {
      return;
    }
    _functionName = (node as SimpleIdentifier).name;
    var invocation = node.parent as MethodInvocation;
    // function invocation has no target
    var target = invocation.realTarget;
    if (target != null) {
      return;
    }
    // prepare environment
    int insertOffset;
    String sourcePrefix;
    AstNode enclosingMember =
        node.thisOrAncestorOfType<CompilationUnitMember>();
    insertOffset = enclosingMember.end;
    sourcePrefix = '$eol$eol';
    utils.targetClassElement = null;
    // build method source
    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(insertOffset, (builder) {
        builder.write(sourcePrefix);
        // append return type
        {
          var type = inferUndefinedExpressionType(invocation);
          if (builder.writeType(type, groupName: 'RETURN_TYPE')) {
            builder.write(' ');
          }
        }
        // append name
        builder.addLinkedEdit('NAME', (builder) {
          builder.write(_functionName);
        });
        builder.write('(');
        builder.writeParametersMatchingArguments(invocation.argumentList);
        builder.write(') {$eol}');
      });
      builder.addLinkedPosition(range.node(node), 'NAME');
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static CreateFunction newInstance() => CreateFunction();
}
