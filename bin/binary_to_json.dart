// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/binary_serialization.dart' as binary;
import 'package:dart2js_info/json_info_codec.dart';

/// Converts a dump-info file emitted by dart2js in binary format to JSON.
main(args) async {
  if (args.length < 1) {
    print('usage: binary_to_json <input.data> [--compat-mode]'
        '\n\n'
        '    By default files are converted to the latest JSON format, but\n'
        '    passing `--compat-mode` will produce a JSON file that may still\n'
        '    work in the visualizer tool at: \n'
        '    https://dart-lang.github.io/dump-info-visualizer/.\n\n'
        '    Note, however, that files produced in this mode do not contain\n'
        '    all the data available in the input file.');
    exit(1);
  }

  var input = new File(args[0]).readAsBytesSync();
  bool isBackwardCompatible = args.length > 1 && args.contains('--compat-mode');
  AllInfo info = binary.decode(input);

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

  var json = new AllInfoJsonCodec(isBackwardCompatible: isBackwardCompatible)
      .encode(info);
  new File("${args[0]}.json")
      .writeAsStringSync(const JsonEncoder.withIndent("  ").convert(json));
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
