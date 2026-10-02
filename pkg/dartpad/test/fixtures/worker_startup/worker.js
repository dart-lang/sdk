// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercise native worker startup and the session handshake without SDK assets.
export class Worker {
  static async create({pubHostedUrl}) {
    self.postMessage({action: 'initializing'});
    if (pubHostedUrl === 'https://test.invalid/pending') {
      await new Promise(() => {});
    }
    if (pubHostedUrl === 'https://test.invalid/error') {
      throw new Error('Fixture initialization failed');
    }
    return new Worker();
  }

  session(port) {
    port.start();
  }
}
