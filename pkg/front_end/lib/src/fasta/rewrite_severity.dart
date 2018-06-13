// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'severity.dart' show Severity;

import 'messages.dart' as msg;

Severity rewriteSeverity(
    Severity severity, msg.Code<Object> code, Uri fileUri) {
  if (severity == Severity.ignored &&
      fileUri.path.contains("/pkg/front_end/lib/src/fasta/")) {
    return Severity.error;
  }
  return severity;
}
