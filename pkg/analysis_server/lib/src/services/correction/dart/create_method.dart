// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateMethod extends CorrectionProducer {
  String _memberName;

  @override
  List<Object> get fixArguments => [_memberName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_METHOD;

  @override
  Future<void> compute(DartChangeBuilder builder) async {
    final methodDecl = node.thisOrAncestorOfType<MethodDeclaration>();
    final classDecl = methodDecl.thisOrAncestorOfType<ClassDeclaration>();
    if (methodDecl != null && classDecl != null) {
      final classElement = classDecl.declaredElement;

      var element;
      if (methodDecl.name.name == 'hashCode') {
        _memberName = '==';
        element = classElement.lookUpInheritedMethod(
            _memberName, classElement.library);
      } else {
        _memberName = 'hashCode';
        element = classElement.lookUpInheritedConcreteGetter(
            _memberName, classElement.library);
      }

      final location =
          utils.prepareNewClassMemberLocation(classDecl, (_) => true);

      await builder.addFileEdit(file, (fileBuilder) {
        fileBuilder.addInsertion(location.offset, (builder) {
          builder.write(location.prefix);
          builder.writeOverride(element, invokeSuper: true);
          builder.write(location.suffix);
        });
      });

      builder.setSelection(Position(file, location.offset));
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static CreateMethod newInstance() => CreateMethod();
}
