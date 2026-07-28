// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import { compileStreaming } from './worker.mjs';

export class Worker {
  constructor({ session }) {
    this.session = session;
  }

  static async create(options) {
    const wasmUrl = new URL('./worker.wasm', import.meta.url);
    const compiledApp = await compileStreaming(fetch(wasmUrl));
    const instantiatedApp = await compiledApp.instantiate({});

    let { promise, resolve, reject } = Promise.withResolvers();
    self._workerOptions = {
      assetBaseUrl: new URL('./', import.meta.url).toString(),
      ...options,
      resolve,
      reject,
    };
    instantiatedApp.invokeMain();
    self._workerOptions = null;

    return new Worker({ session: await promise });
  }
}
