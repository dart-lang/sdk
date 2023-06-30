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

class ChangeToStaticAccess extends ResolvedCorrectionProducer {
  String _className = '';

  @override
  List<Object> get fixArguments => [_className];

  @override
  FixKind get fixKind => DartFixKind.CHANGE_TO_STATIC_ACCESS;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    Expression? target;
    Element? invokedElement;
    var identifier = node;
    if (identifier is SimpleIdentifier) {
      var parent = identifier.parent;
      if (parent is MethodInvocation) {
        if (parent.methodName == identifier) {
          target = parent.target;
          invokedElement = identifier.staticElement;
        }
      } else if (parent is PrefixedIdentifier) {
        if (parent.identifier == identifier) {
          target = parent.prefix;
          invokedElement = identifier.staticElement;
        }
      }
    }
    if (target == null || invokedElement is! ExecutableElement) {
      return;
    }

    final target_final = target;
    var declaringElement = invokedElement.enclosingElement2;

    if (declaringElement is InterfaceElement) {
      _className = declaringElement.name;
      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.node(target_final), (builder) {
          builder.writeReference(declaringElement);
        });
      });
    } else if (declaringElement is ExtensionElement) {
      var extensionName = declaringElement.name;
      if (extensionName != null) {
        _className = extensionName;
        await builder.addDartFileEdit(file, (builder) {
          builder.addReplacement(range.node(target_final), (builder) {
            builder.writeReference(declaringElement);
          });
        });
      }
    }
  }
}
