// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

(function () {
  const OriginalWebSocket = window.WebSocket;
  class MessagePortWebSocket extends EventTarget {
    readyState = OriginalWebSocket.OPEN;

    constructor(url, protocols) {
      super();
      if (!String(url).includes('127.0.0.1:1')) {
        return new OriginalWebSocket(url, protocols);
      }
      const { port1: servicePort, port2: remotePort } = new MessageChannel();
      this._port = servicePort;
      window.parent.postMessage(
        { action: 'connect', port: remotePort },
        '*',
        [remotePort],
      );
      // Close the port on pagehide, matching browser WebSocket behavior.
      window.addEventListener('pagehide', () => this.close(), { once: true });
      servicePort.onmessage = (ev) => {
        if (ev.data === null) {
          this.close();
          return;
        }
        const data = ev.data instanceof Uint8Array
          ? ev.data.buffer.slice(
              ev.data.byteOffset,
              ev.data.byteOffset + ev.data.byteLength,
            )
          : ev.data;
        this.dispatchEvent(new MessageEvent('message', { data }));
      };
    }

    send(data) {
      this._port.postMessage(data);
    }

    close(code = 1000, reason = '') {
      if (this.readyState === OriginalWebSocket.CLOSED) return;
      this.readyState = OriginalWebSocket.CLOSED;
      this._port.postMessage(null);
      this._port.onmessage = null;
      this._port.close();
      this.dispatchEvent(new CloseEvent('close', { code, reason }));
    }
  }

  window.WebSocket = MessagePortWebSocket;

  // Rewrite the URL from `.../devtools.html` to `.../devtools/` to match
  // `<base href="devtools/">`, as required by Flutter Web's path URL strategy.
  const currentUrl = new URL('./' + window.location.search, document.baseURI);
  currentUrl.searchParams.set('uri', 'ws://127.0.0.1:1/ws');
  if (!currentUrl.searchParams.has('embedMode')) {
    currentUrl.searchParams.set('embedMode', 'many');
  }
  if (!currentUrl.searchParams.has('hide')) {
    currentUrl.searchParams.set('hide', 'home');
  }
  if (!currentUrl.searchParams.has('compiler')) {
    currentUrl.searchParams.set('compiler', 'wasm');
  }
  window.history.replaceState({}, '', currentUrl.toString());
})();
