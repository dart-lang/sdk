// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'messages.dart' as msg;

Severity rewriteSeverity(
    Severity severity, msg.Code<Object> code, Uri fileUri) {
  if (severity != Severity.ignored) {
    return severity;
  }

  String path = fileUri.path;
  String fastaPath = "/pkg/front_end/lib/src/fasta/";
  int index = path.indexOf(fastaPath);
  if (index == -1) {
    fastaPath = "/pkg/front_end/tool/_fasta/";
    index = path.indexOf(fastaPath);
    if (index == -1) return severity;
  }
  if (code == msg.codeUseOfDeprecatedIdentifier) {
    // TODO(ahe): Remove the exceptions below.
    // We plan to remove all uses of deprecated identifiers from Fasta. The
    // strategy is to remove files from the list below one by one. To get
    // started on cleaning up a given file, simply remove it from the list
    // below and compile Fasta with itself to get a list of remaining call
    // sites.
    switch (path.substring(fastaPath.length + index)) {
      case "command_line.dart":
      case "kernel/body_builder.dart":
        return severity;
    }
  }
  return Severity.error;
}
