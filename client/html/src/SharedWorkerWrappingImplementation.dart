// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SharedWorkerWrappingImplementation extends AbstractWorkerWrappingImplementation implements SharedWorker {
  SharedWorkerWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  MessagePort get port() { return LevelDom.wrapMessagePort(_ptr.port); }
}
