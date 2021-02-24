// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library front_end.terminal_color_support;

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show DiagnosticMessage;

import 'package:_fe_analyzer_shared/src/util/colors.dart' show enableColors;

export 'package:_fe_analyzer_shared/src/util/colors.dart' show enableColors;

void printDiagnosticMessage(
    DiagnosticMessage message, void Function(String) println) {
  if (enableColors) {
    message.ansiFormatted.forEach(println);
  } else {
    message.plainTextFormatted.forEach(println);
  }
}
