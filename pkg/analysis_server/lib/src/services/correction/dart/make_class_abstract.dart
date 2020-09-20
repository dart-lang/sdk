// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class MakeClassAbstract extends CorrectionProducer {
  String _className;

  @override
  List<Object> get fixArguments => [_className];

  @override
  FixKind get fixKind => DartFixKind.MAKE_CLASS_ABSTRACT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var enclosingClass = node.thisOrAncestorOfType<ClassDeclaration>();
    if (enclosingClass == null) {
      return;
    }
    _className = enclosingClass.name.name;
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(
          enclosingClass.classKeyword.offset, 'abstract ');
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static MakeClassAbstract newInstance() => MakeClassAbstract();
}
