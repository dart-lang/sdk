// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

function native__Logger__printString(str) {
  if (isolate$workerPrint) {
    isolate$workerPrint(str);
  } else if (this.console) {
    this.console.log(str);
  } else if (this.write) {
    this.write(str);
    this.write('\n');
  }
}
