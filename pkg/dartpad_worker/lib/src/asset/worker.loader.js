// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

(async () => {
  // Buffer messages until the Dart worker is ready
  let messageQueue = [];
  const queueHandler = (e) => {
    messageQueue.push(e);
  };

  // Hook onmessage to capture early messages
  self.onmessage = queueHandler;

  try {
    // TODO(jonasfj): Consider making a static import of ./worker.mjs
    const { compileStreaming } = await import('./worker.mjs');
    const wasmUrl = new URL('./worker.wasm', import.meta.url);
    const compiledApp = await compileStreaming(fetch(wasmUrl));
    const instantiatedApp = await compiledApp.instantiate({});

    // Invoke Dart main(), which should override self.onmessage
    instantiatedApp.invokeMain();

    // If Dart set an onmessage handler, replay queued messages
    if (self.onmessage && self.onmessage !== queueHandler) {
      const dartHandler = self.onmessage;
      if (messageQueue.length > 0) {
        for (const event of messageQueue) {
          dartHandler(event);
        }
      }
    }

  } catch (e) {
    console.error('Failed to start WASM worker:', e);
    self.postMessage({
      action: 'error',
      message: 'Failed to start WASM worker:' + e.toString(),
    });
  }
})();
