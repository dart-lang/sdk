// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class MakeConditionalOnDebugMode extends CorrectionProducer {
  /// The URI of the library in which kDebugMode is declared.
  static final Uri _foundationUri =
      Uri.parse('package:flutter/foundation.dart');

  @override
  // This fix isn't enabled for fix-all or bulk fix because it doesn't currently
  // account for having multiple `print` invocations in sequence.
  bool get canBeAppliedToFile => false;

  @override
  FixKind get fixKind => DartFixKind.MAKE_CONDITIONAL_ON_DEBUG_MODE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (unitResult.session.uriConverter.uriToPath(_foundationUri) == null) {
      return;
    }
    var printInvocation = utils.findSimplePrintInvocation(node);
    if (printInvocation != null) {
      var indent = utils.getLinePrefix(printInvocation.offset);
      await builder.addDartFileEdit(file, (builder) {
        builder.addInsertion(printInvocation.offset, (builder) {
          builder.writeln('if (kDebugMode) {');
          builder.write(indent);
          builder.write(utils.getIndent(1));
        });
        builder.addInsertion(printInvocation.end, (builder) {
          builder.writeln();
          builder.write(indent);
          builder.write('}');
        });
      });
    }
  }
}
