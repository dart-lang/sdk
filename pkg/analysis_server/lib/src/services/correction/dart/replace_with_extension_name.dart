// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithExtensionName extends CorrectionProducer {
  String _extensionName = '';

  @override
  List<Object> get fixArguments => [_extensionName];

  @override
  FixKind get fixKind => DartFixKind.REPLACE_WITH_EXTENSION_NAME;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node is! SimpleIdentifier) {
      return;
    }
    var target = _getTarget(node.parent);
    if (target is ExtensionOverride) {
      final importPrefix = target.importPrefix;
      final prefixedName = importPrefix != null
          ? '${importPrefix.name.lexeme}.${target.name.lexeme}'
          : target.name.lexeme;
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(target), prefixedName);
      });
      _extensionName = prefixedName;
    }
  }

  AstNode? _getTarget(AstNode? invocation) {
    if (invocation is MethodInvocation && node == invocation.methodName) {
      return invocation.target;
    } else if (invocation is PropertyAccess &&
        node == invocation.propertyName) {
      return invocation.target;
    }
    return null;
  }
}
