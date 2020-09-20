// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ChangeToStaticAccess extends CorrectionProducer {
  String _className;

  @override
  List<Object> get fixArguments => [_className];

  @override
  FixKind get fixKind => DartFixKind.CHANGE_TO_STATIC_ACCESS;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    Expression target;
    Element invokedElement;
    if (node is SimpleIdentifier && node.parent is MethodInvocation) {
      var invocation = node.parent as MethodInvocation;
      if (invocation.methodName == node) {
        target = invocation.target;
        invokedElement = invocation.methodName.staticElement;
      }
    } else if (node is SimpleIdentifier && node.parent is PrefixedIdentifier) {
      var prefixed = node.parent as PrefixedIdentifier;
      if (prefixed.identifier == node) {
        target = prefixed.prefix;
        invokedElement = prefixed.identifier.staticElement;
      }
    }
    if (target == null) {
      return;
    }
    var declaringElement = invokedElement.enclosingElement;
    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(target), (builder) {
        builder.writeReference(declaringElement);
      });
    });
    _className = declaringElement.name;
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ChangeToStaticAccess newInstance() => ChangeToStaticAccess();
}
