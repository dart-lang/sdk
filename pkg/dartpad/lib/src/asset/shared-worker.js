// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const params = new URL(self.location.href).searchParams;
const assetBaseUrl = params.get('assetBaseUrl');

const promisedWorker = (async () => {
  const {Worker} = await import(new URL('./worker.js', assetBaseUrl).href);
  return await Worker.create(Object.fromEntries(params));
})();
promisedWorker.catch(() => {});

self.onconnect = async (event) => {
  const port = event.ports[0];
  try {
    const worker = await promisedWorker;
    const {port1, port2} = new MessageChannel();
    worker.session(port1);
    port.postMessage({action: 'session', port: port2}, [port2]);
  } catch (e) {
    console.error(e);
    port.postMessage({action: 'error', message: e.toString()});
    setTimeout(() => self.close(), 0);
  } finally {
    port.close();
  }
};
