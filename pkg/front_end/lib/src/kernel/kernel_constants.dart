// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/compilation_unit.dart';
import '../codes/cfe_codes.dart' show LocatedMessage;
import '../source/source_loader.dart' show SourceLoader;
import 'constant_evaluator.dart' show ErrorReporter;

class KernelConstantErrorReporter extends ErrorReporter {
  final SourceLoader loader;

  KernelConstantErrorReporter(this.loader);

  @override
  // Coverage-ignore(suite): Not run.
  bool get supportsTrackingReportedErrors => true;

  @override
  bool get hasSeenError => loader.hasSeenError;

  @override
  void report(LocatedMessage message, [List<LocatedMessage>? context]) {
    // Try to find library.
    Uri uri = message.uri!;
    CompilationUnit? compilationUnit = loader.lookupCompilationUnit(uri);
    compilationUnit ??= loader.lookupCompilationUnitByFileUri(uri);
    if (compilationUnit == null) {
      // TODO(jensj): Probably a part or something.
      loader.addProblem(message.messageObject, message.charOffset,
          message.length, message.uri,
          context: context);
    } else {
      compilationUnit.addProblem(message.messageObject, message.charOffset,
          message.length, message.uri,
          context: context);
    }
  }
}
