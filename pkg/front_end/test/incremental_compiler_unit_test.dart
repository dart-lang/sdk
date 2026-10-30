// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/base/incremental_compiler.dart';
import 'package:kernel/ast.dart';

void main() {
  Uri base = Uri.parse('org-dartlang-test:///');
  Uri aUri = base.resolve('a.dart');
  Uri bUri = base.resolve('b.dart');
  Library libB = Library(bUri, fileUri: bUri);
  Library libA = Library(
    aUri,
    fileUri: aUri,
    dependencies: [LibraryDependency.import(libB)],
  );
  Map<Uri, Source> uriToSource = {
    libA.fileUri: Source.emptySource([0], libA.importUri, libA.fileUri),
    // libB.fileUri intentionally omitted
  };
  TransitiveDependenciesCalculator transitiveDependenciesCalculator =
      new TransitiveDependenciesCalculator(null, uriToSource, [libA, libB]);
  if (transitiveDependenciesCalculator.transitiveDependencies != null) {
    throw "Expected null as return value.";
  }
}
