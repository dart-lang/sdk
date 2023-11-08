// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

/// Writes constant coverage for [component] into [buffer}.
///
/// Libraries for whose import uri [skipImportUri] returns `true` are skipped.
void addConstantCoverageToExpectation(Component component, StringBuffer buffer,
    {required bool Function(Uri?) skipImportUri}) {
  bool printedConstantCoverageHeader = false;
  for (Source source in component.uriToSource.values) {
    if (skipImportUri(source.importUri)) continue;

    if (source.constantCoverageConstructors != null &&
        source.constantCoverageConstructors!.isNotEmpty) {
      if (!printedConstantCoverageHeader) {
        buffer.writeln("");
        buffer.writeln("");
        buffer.writeln("Constructor coverage from constants:");
        printedConstantCoverageHeader = true;
      }
      buffer.writeln("${source.fileUri}:");
      for (Reference reference in source.constantCoverageConstructors!) {
        buffer.writeln(
            "- ${reference.node} (from ${locationToString(reference)})");
      }
      buffer.writeln("");
    }
  }
}

/// Computes a string representation of the location of the node from
/// [reference].
///
/// References to sdk nodes only include the file uri to avoid unnecessary
/// dependency on sdk library sources.
String locationToString(Reference reference) {
  Location? location = reference.node?.location;
  if (location != null && location.file.isScheme('org-dartlang-sdk')) {
    // Don't include line/column numbers for sdk libraries to avoid unnecessary
    // dependency on sdk library sources.
    return '${location.file}';
  }
  return '$location';
}
