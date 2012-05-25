// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('dart:io');

endProcesses(processes) {
  processes.forEach((p) {
    p.stdin.writeString("line\n");
    p.onExit = (code) => Expect.equals(0, code);
  });
}

main() {
  var num = 75;
  var started = 0;
  var processes = [];
  for (var i = 0; i < num; i++) {
    var script = new File("tests/standalone/io/process_many_script.dart");
    if (!script.existsSync()) {
      script = new File("../tests/standalone/io/process_many_script.dart");
    }
    var p = Process.start(new Options().executable, [script.name]);
    processes.add(p);
    p.onStart = () {
      if (++started == num) endProcesses(processes);
    };
  }
}
