// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyze_dart2js;

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/compiler.dart';
import 'analyze_helper.dart';
import 'related_types.dart';

/**
 * Map of whitelisted warnings and errors.
 *
 * Only add a whitelisting together with a bug report to dartbug.com and add
 * the bug issue number as a comment on the whitelisting.
 *
 * Use an identifiable suffix of the file uri as key. Use a fixed substring of
 * the error/warning message in the list of whitelistings for each file.
 */
// TODO(johnniwinther): Support canonical URIs as keys and message kinds as
// values.
const Map<String, List<String>> WHITE_LIST = const {
  "pkg/front_end/lib/src/fasta/kernel/kernel_library_builder.dart": const [
    "The getter 'iterator' is not defined for the class 'Object'.",
  ],
  "pkg/front_end/lib/src/fasta/type_inference/type_schema.dart": const [
    "The class 'UnknownType' overrides 'operator==', but not 'get hashCode'."
  ],
  "pkg/kernel/lib/transformations/closure/": const [
    "Duplicated library name 'kernel.transformations.closure.converter'",
  ],
  "pkg/kernel/lib/transformations/closure/info.dart": const [
    "Types 'FunctionNode' and 'FunctionDeclaration' have no common subtypes."
  ],
  "third_party/pkg/collection/lib/src/functions.dart": const [
    "Method type variables are treated as `dynamic` in `as` expressions."
  ],
};

void main() {
  var uri = currentDirectory.resolve('pkg/compiler/lib/src/dart2js.dart');
  asyncTest(() => analyze([uri], WHITE_LIST, checkResults: checkResults));
}

bool checkResults(Compiler compiler, CollectingDiagnosticHandler handler) {
  checkRelatedTypes(compiler);
  return !handler.hasHint;
}
