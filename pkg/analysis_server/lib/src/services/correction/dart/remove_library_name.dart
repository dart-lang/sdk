// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveLibraryName extends ResolvedCorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  // There can only be one library declaration per file.
  bool get canBeAppliedToFile => false;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_LIBRARY_NAME;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var libraryName = node;
    if (libraryName is SimpleIdentifier || libraryName is LibraryIdentifier) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.endStart(
            libraryName.beginToken.previous!, libraryName.endToken.next!));
      });
    }
  }
}
