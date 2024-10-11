// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
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
    Expression? target;
    Element2? invokedElement;
    var identifier = node;
    if (identifier is SimpleIdentifier) {
      var parent = identifier.parent;
      if (parent is MethodInvocation) {
        if (parent.methodName == identifier) {
          target = parent.target;
          invokedElement = identifier.element;
        }
      } else if (parent is PrefixedIdentifier) {
        if (parent.identifier == identifier) {
          target = parent.prefix;
          invokedElement = identifier.element;
        }
      }
    }
    if (target == null || invokedElement is! ExecutableElement2) {
      return;
    }

    var target_final = target;
    var declaringElement = invokedElement.enclosingElement2;

    if (declaringElement is InterfaceElement2) {
      _className = declaringElement.name;
      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.node(target_final), (builder) {
          builder.writeReference2(declaringElement);
        });
      });
    } else if (declaringElement is ExtensionElement2) {
      var extensionName = declaringElement.name;
      if (extensionName != null) {
        _className = extensionName;
        await builder.addDartFileEdit(file, (builder) {
          builder.addReplacement(range.node(target_final), (builder) {
            builder.writeReference2(declaringElement);
          });
        });
      }
    }
  }
}
