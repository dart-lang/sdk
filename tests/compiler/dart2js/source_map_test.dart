// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that options '--source-map' and '--out' correctly adds
// `sourceMappingURL` and "file" attributes to source file and source map file.

library test.source_map;

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'memory_compiler.dart';

const SOURCE = const {
  '/main.dart': """
main() {}
""",
};

void find(String text, String substring, bool expected) {
  bool found = text.contains(substring);

  if (expected && !found) {
    Expect.isTrue(found, 'Expected "$substring" in:\n$text');
  }
  if (!expected && found) {
    Expect.isFalse(found,
        'Unexpected "$substring" in:\n'
        '${text.substring(text.indexOf(substring))}');
  }
}

void test({String out, String sourceMap, String mapping, String file}) {
  OutputCollector collector = new OutputCollector();
  List<String> options = <String>[];
  if (out != null) {
    options.add("--out=$out");
  }
  if (sourceMap != null) {
    options.add("--source-map=$sourceMap");
  }
  var compiler = compilerFor(SOURCE,
                             showDiagnostics: true,
                             outputProvider: collector,
                             options: options);
  asyncTest(() => compiler.runCompiler(Uri.parse('memory:/main.dart')).then(
      (_) {
    String jsOutput = collector.getOutput('', 'js');
    Expect.isNotNull(jsOutput);
    if (mapping != null) {
      find(jsOutput, '//# sourceMappingURL=$mapping', true);
    } else {
      find(jsOutput, '//# sourceMappingURL=', false);
    }
    String jsSourceMapOutput = collector.getOutput('', 'js.map');
    Expect.isNotNull(jsSourceMapOutput);
    if (file != null) {
      find(jsSourceMapOutput, '"file": "$file"', true);
    } else {
      find(jsSourceMapOutput, '"file": ', false);
    }
  }));
}

void main() {
  test();
  test(sourceMap: 'file:/out.js.map');
  test(out: 'file:/out.js');
  test(out: 'file:/out.js', sourceMap: 'file:/out.js.map',
       file: 'out.js', mapping: 'out.js.map');
  test(out: 'file:/dir/out.js', sourceMap: 'file:/dir/out.js.map',
       file: 'out.js', mapping: 'out.js.map');
}