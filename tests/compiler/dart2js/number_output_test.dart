// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart';

const MEMORY_SOURCE_FILES = const {
    'main.dart': '''
        main() {
          print(12300000);
          print(1234567890123456789012345);
          print(double.MAX_FINITE);
        }'''};

void main() {
  OutputCollector collector = new OutputCollector();
  var compiler = compilerFor(MEMORY_SOURCE_FILES, outputProvider: collector);
  asyncTest(() => compiler.run(Uri.parse('memory:main.dart')).then((_) {
    // Check that we use the shorter exponential representations.
    String jsOutput = collector.getOutput('', 'js');

    Expect.isTrue(jsOutput.contains('1.23e+7')); // Shorter than 12300000.
    Expect.isTrue(jsOutput.contains('1.2345678901234568e+24'));
    Expect.isTrue(jsOutput.contains('1.7976931348623157e+308'));
    Expect.isFalse(jsOutput.contains('12300000'));
    Expect.isFalse(jsOutput.contains('1234567890123456789012345'));
    // The decimal expansion of double.MAX_FINITE has 308 digits. We only check
    // for its prefix.
    Expect.isFalse(jsOutput.contains('179769313486231570814527423731'));
  }));
}
