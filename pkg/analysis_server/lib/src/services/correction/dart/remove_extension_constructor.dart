// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

class RemoveExtensionConstructor extends ResolvedCorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.REMOVE_EXTENSION_CONSTRUCTOR;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final extension = node;
    if (extension is! ExtensionDeclaration) {
      return;
    }

    final constructor = _findConstructor();
    if (constructor == null) {
      return;
    }

    final previous = extension.members.lastWhereOrNull(
      (e) => e.end < constructor.offset,
    );

    await builder.addDartFileEdit(file, (builder) {
      final constructorRange = range.endEnd(
        previous?.endToken ?? extension.leftBracket,
        constructor.endToken,
      );
      builder.addDeletion(constructorRange);
    });
  }

  ConstructorDeclaration? _findConstructor() {
    final errorOffset = this.errorOffset;
    if (errorOffset == null) {
      return null;
    }

    for (final constructor in invalidNodes) {
      if (constructor is ConstructorDeclaration) {
        if (range.node(constructor).contains(errorOffset)) {
          return constructor;
        }
      }
    }

    return null;
  }
}
