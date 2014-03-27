// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:isolate";

// This type corresponds to the VM-internal class LibraryPrefix.

class _LibraryPrefix {
  _load() native "LibraryPrefix_load";

  loadLibrary() {
    var completer = new Completer<bool>();
    var port = new RawReceivePort();
    port.handler = (_) {
      this._load();
      completer.complete(true);
      port.close();
    };
    port.sendPort.send(1);
    return completer.future;
  }
}
