// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'severity.dart' show Severity;

import 'messages.dart' as msg;

Severity rewriteSeverity(
    Severity severity, msg.Code<Object> code, Uri fileUri) {
  if (severity == Severity.ignored &&
      fileUri.path.contains("/pkg/front_end/lib/src/fasta/")) {
    String path = fileUri.path;
    if (code == msg.codeUseOfDeprecatedIdentifier) {
      // TODO(ahe): Remove the exceptions below.
      // We plan to remove all uses of deprecated identifiers from Fasta. The
      // strategy is to remove files from the list below one by one. To get
      // started on cleaning up a given file, simply remove it from the list
      // below and compile Fasta with itself to get a list of remaining call
      // sites.
      if (path.endsWith("/command_line_reporting.dart")) return severity;
      if (path.endsWith("/deprecated_problems.dart")) return severity;
      if (path.endsWith("/kernel/body_builder.dart")) return severity;
      if (path.endsWith("/kernel/expression_generator.dart")) return severity;
      if (path.endsWith("/kernel/kernel_expression_generator.dart"))
        return severity;
      if (path.endsWith("/kernel/kernel_expression_generator_impl.dart"))
        return severity;
      if (path.endsWith("/kernel/kernel_procedure_builder.dart"))
        return severity;
      if (path.endsWith("/kernel/kernel_target.dart")) return severity;
      if (path.endsWith("/kernel/kernel_type_variable_builder.dart"))
        return severity;
      if (path.endsWith("/quote.dart")) return severity;
      if (path.endsWith("/source/diet_listener.dart")) return severity;
      if (path.endsWith("/source/source_library_builder.dart")) return severity;
      if (path.endsWith("/source/source_loader.dart")) return severity;
      if (path.endsWith("/source/stack_listener.dart")) return severity;
    }
    return Severity.error;
  }
  return severity;
}
