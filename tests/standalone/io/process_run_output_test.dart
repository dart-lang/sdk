// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test script for testing that output is handled correctly for
// non-interactive processes started with Process.run.

#import("dart:io");
#source("process_test_util.dart");

checkOutput(encoding, output) {
  if (encoding == 'ascii') {
    Expect.equals(output, 'abc');
  } else if (encoding == 'latin1') {
    Expect.equals(output, 'æøå');
  } else if (encoding == 'utf8') {
    Expect.listEquals(output.charCodes(), [955]);
  }
}

test(scriptFile, encoding, stream) {
  var enc;
  if (encoding == 'ascii') {
    enc = Encoding.ASCII;
  } else if (encoding == 'latin1') {
    enc = Encoding.ISO_8859_1;
  } else if (encoding == 'utf8') {
    enc = Encoding.UTF_8;
  }

  var options = new ProcessOptions();
  if (stream == 'stdout') {
    options.stdoutEncoding = enc;
    Process.run(new Options().executable,
                [scriptFile, encoding, stream],
                options). then((result) {
      Expect.equals(result.exitCode, 0);
      Expect.equals(result.stderr, '');
      checkOutput(encoding, result.stdout);
    });
  } else {
    options.stderrEncoding = enc;
    Process.run(new Options().executable,
                [scriptFile, encoding, stream],
                options).then((result) {
      Expect.equals(result.exitCode, 0);
      Expect.equals(result.stdout, '');
      checkOutput(encoding, result.stderr);
    });
  }
}

main() {
  var scriptFile = new File("tests/standalone/io/process_std_io_script2.dart");
  if (!scriptFile.existsSync()) {
    scriptFile =
        new File("../tests/standalone/io/process_std_io_script2.dart");
  }
  Expect.isTrue(scriptFile.existsSync());
  test(scriptFile.name, 'ascii', 'stdout');
  test(scriptFile.name, 'ascii', 'stderr');
  test(scriptFile.name, 'latin1', 'stdout');
  test(scriptFile.name, 'latin1', 'stderr');
  test(scriptFile.name, 'utf8', 'stdout');
  test(scriptFile.name, 'utf8', 'stderr');

}
