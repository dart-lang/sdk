// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ChangeToStaticAccess extends ResolvedCorrectionProducer {
  String _className = '';

  ChangeToStaticAccess({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_className];

  @override
  FixKind get fixKind => DartFixKind.CHANGE_TO_STATIC_ACCESS;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var identifier = node;
    if (identifier is! SimpleIdentifier) {
      return;
    }

    Expression target;
    var parent = identifier.parent;
    if (parent case MethodInvocation(target: var parentTarget?)) {
      if (parent.methodName != identifier) {
        return;
      }
      target = parentTarget;
    } else if (parent is PrefixedIdentifier) {
      if (parent.identifier != identifier) {
        return;
      }
      target = parent.prefix;
    } else {
      return;
    }

    var invokedElement = identifier.element;
    if (invokedElement is! ExecutableElement) {
      return;
    }

    var declaringElement = invokedElement.enclosingElement;

    if (declaringElement is InterfaceElement) {
      var declaringElementName = declaringElement.name;
      if (declaringElementName != null) {
        _className = declaringElementName;
        await builder.addDartFileEdit(file, (builder) {
          builder.addReplacement(range.node(target), (builder) {
            builder.writeReference(declaringElement);
          });
        });
      }
    } else if (declaringElement is ExtensionElement) {
      var extensionName = declaringElement.name;
      if (extensionName != null) {
        _className = extensionName;
        await builder.addDartFileEdit(file, (builder) {
          builder.addReplacement(range.node(target), (builder) {
            builder.writeReference(declaringElement);
          });
        });
      }
    }
  }
}
