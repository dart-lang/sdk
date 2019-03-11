// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart2js_info/info.dart';

/// Modify [info] to fill in the text of code spans.
///
/// By default, code spans contains the offsets but omit the text
/// (`CodeSpan.text` is null). This function reads the output files emitted by
/// dart2js to extract the code denoted by each span.
void injectText(AllInfo info) {
  // Fill the text of each code span. The binary form produced by dart2js
  // produces code spans, but excludes the orignal text
  info.functions.forEach((f) {
    f.code.forEach((span) => _fillSpan(span, f.outputUnit));
  });
  info.fields.forEach((f) {
    f.code.forEach((span) => _fillSpan(span, f.outputUnit));
  });
  info.constants.forEach((c) {
    c.code.forEach((span) => _fillSpan(span, c.outputUnit));
  });
}

Map<String, String> _cache = {};

_getContents(OutputUnitInfo unit) => _cache.putIfAbsent(unit.filename, () {
      var uri = Uri.base.resolve(unit.filename);
      return new File.fromUri(uri).readAsStringSync();
    });

_fillSpan(CodeSpan span, OutputUnitInfo unit) {
  if (span.text == null && span.start != null && span.end != 0) {
    var contents = _getContents(unit);
    span.text = contents.substring(span.start, span.end);
  }
}
