// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// sandbox.js provides a JSON-RPC 2.0 wrapper around functionality exposed
// by ddc_module.loader.js
//
// This is intended to run inside the _sandboxed iframe_ and allows the host to
// load modules, run code, hot-reload, receive console messages, etc. inside the
// iframe using RPC over a `MessageChannel` exchanged through `postMessage`.
//
// The client side of these RPC calls is wrapped by [Sandbox] from
// `package:dartpad`.
(function () {
  // Port for JSON-RPC 2.0 communication with host.
  let rpcPort = null;

  const errorCode = {
    // JSON-RPC 2.0 Spec.
    METHOD_NOT_FOUND: -32601,
    INVALID_PARAMS: -32602,
    SERVER_ERROR: -32000,
    // pkg/dartpad/lib/src/exceptions.yaml
    MODULE_LOADER_NOT_AVAILABLE: 8001,
    FLUTTER_LOADER_NOT_AVAILABLE: 8002,
    MODULE_LOADING_FAILED: 8100,
    EXECUTION_FAILED: 8200,
    HOT_RESTART_FAILED: 8300,
    HOT_RELOAD_FAILED: 8400,
  };

  class RpcError extends Error {
    constructor(message, code = errorCode.SERVER_ERROR) {
      super(message);
      this.code = code;
      this.name = "RpcError";
    }
  }


  // Registry of RPC methods
  const rpcMethods = {};

  async function onRcpMessage(ev) {
    const m = JSON.parse(ev.data);

    // Ignore invalid messages or responses from the host
    if (!m || m.jsonrpc !== '2.0' || !m.method) return;

    const handler = rpcMethods[m.method];

    try {
      if (!handler) {
        throw new RpcError(
          `Method not found: ${m.method}`,
          errorCode.METHOD_NOT_FOUND
        );
      }

      // Execute the registered method
      const result = await handler(m.params);

      // If it's a request (has an id), send a success response
      if (m.id !== undefined) {
        rpcPort.postMessage(JSON.stringify({
          jsonrpc: '2.0',
          id: m.id,
          result: result ?? {}
        }));
      }
    } catch (e) {
      if (m.id === undefined) {
        console.error(`RPC Notification Error (${m.method}):`, e);
        return;
      }
      const code = e instanceof RpcError ? e.code : errorCode.SERVER_ERROR;
      const message = e instanceof Error ? e.message : String(e);

      rpcPort.postMessage(JSON.stringify({
        jsonrpc: '2.0',
        id: m.id,
        error: { code, message }
      }));
    }
  }


  function sendNotification(method, params) {
    if (!rpcPort) return;
    rpcPort.postMessage(JSON.stringify({
      jsonrpc: '2.0',
      method: method,
      params: params
    }));
  }

  // Serialize arg similar to what console.log would do.
  function safeSerialize(arg) {
    if (arg === null) return 'null';
    if (arg === undefined) return 'undefined';
    if (arg instanceof Error) return arg.stack || arg.toString();
    if (typeof arg === 'function') return `[Function: ${arg.name || 'anonymous'}]`;
    if (arg instanceof HTMLElement) return `<${arg.tagName.toLowerCase()}>`;
    if (typeof arg === 'object') {
      try {
        return JSON.stringify(arg);
      } catch (_) {
        return Object.prototype.toString.call(arg);
      }
    }
    return `${arg}`;
  }

  const originalConsole = {
    log: console.log,
    info: console.info,
    warn: console.warn,
    error: console.error
  };

  // Proxy console over RPC
  for (const level of Object.keys(originalConsole)) {
    console[level] = function (...args) {
      // Format message as a single string
      const message = args.map(safeSerialize).join(' ');
      sendNotification('console', { level, message });

      // Pass to actual browser console for DevTools debugging
      originalConsole[level].apply(console, args);
    };
  }

  // Catch unhandled browser errors and route them to our console proxy
  window.addEventListener('error', (e) => console.error(`Uncaught: ${e.message}`));
  window.addEventListener('unhandledrejection', (e) => console.error(`Unhandled Rejection: ${e.reason}`));

  // Create a blob URL and register it with DDC's internal loader.
  function createAndRegisterBlob(moduleName, code) {
    const blob = new Blob([code], { type: 'application/javascript' });
    const newUrl = URL.createObjectURL(blob);

    if (self.$dartLoader) {
      // Clean up old mappings and free memory
      const oldUrl = self.$dartLoader.moduleIdToUrl.get(moduleName);
      if (oldUrl) {
        self.$dartLoader.urlToModuleId.delete(oldUrl);
        // TODO(jonasfj): We should consider cleaning up <script> tags, if
        //                nothing else just to keep the DOM clean.
        if (oldUrl.startsWith('blob:')) {
          try {
            URL.revokeObjectURL(oldUrl);
          } catch (e) {
            // ignore
          }
        }
      }

      // Register new mappings so DDC stack traces work
      self.$dartLoader.moduleIdToUrl.set(moduleName, newUrl);
      self.$dartLoader.urlToModuleId.set(newUrl, moduleName);
    }

    return newUrl;
  }

  rpcMethods.loadModule = async (params) => {
    const { code, moduleName } = params;

    if (!code) {
      throw new RpcError("'code' is required.", errorCode.INVALID_PARAMS);
    }
    if (!moduleName) {
      throw new RpcError("'moduleName' is required.", errorCode.INVALID_PARAMS);
    }

    const url = createAndRegisterBlob(moduleName, code);
    await new Promise((resolve) =>
      // TODO(jonasfj): Handle script loading failure and throw
      //                MODULE_LOADING_FAILED. Requires us to duplicate logic
      //                from DDC module loader.
      self.$dartLoader.forceLoadScript(url, resolve),
    );

    return {};
  };

  rpcMethods.runMain = async (params) => {
    const { libraryUri, options = {} } = params;

    if (!libraryUri) {
      throw new RpcError(
        "libraryUri is required to run code.",
        errorCode.INVALID_PARAMS
      );
    }
    if (!self.dartDevEmbedder) {
      throw new RpcError(
        "dartDevEmbedder is not initialized.",
        errorCode.MODULE_LOADER_NOT_AVAILABLE
      );
    }

    try {
      self.dartDevEmbedder.runMain(libraryUri, options);
      return { status: 'running' };
    } catch (e) {
      throw new RpcError(e.message || String(e), errorCode.EXECUTION_FAILED);
    }
  };

  rpcMethods.runApp = async (params) => {
    const { libraryUri, options = {} } = params;

    if (!libraryUri) {
      throw new RpcError(
        "libraryUri is required to run code.",
        errorCode.INVALID_PARAMS
      );
    }
    if (!self.dartDevEmbedder) {
      throw new RpcError(
        "dartDevEmbedder is not initialized.",
        errorCode.MODULE_LOADER_NOT_AVAILABLE
      );
    }
    if (!self._flutter || !self._flutter.loader) {
      throw new RpcError(
        "flutter.js is not loaded!",
        errorCode.FLUTTER_LOADER_NOT_AVAILABLE
      );
    }

    // To run a flutter app, you don't call the entrypoint, instead you call
    // a wrapper (or bootstrap script) that starts flutter engine and calls the
    // entrypoint.
    const bootstrapWrapperUri = libraryUri + '.virtual-bootstrap-wrapper.dart';
    const libraryUriJson = JSON.stringify(bootstrapWrapperUri);
    const optionsJson = JSON.stringify(options);
    const url = URL.createObjectURL(new Blob([`
      try {
        self.dartDevEmbedder.runMain(${libraryUriJson}, ${optionsJson});
      } catch (e) {
        console.error('runMain() inside runApp() failed: ', e.message || String(e));
      }
    `], { type: 'application/javascript' }));

    try {
      const engineInitializer = await new Promise((resolve) => {
        self._flutter.loader.loadEntrypoint({
          entrypointUrl: url,
          onEntrypointLoaded: resolve,
        });
      });

      const appRunner = await engineInitializer.initializeEngine(
        self.dartpadFlutterConfiguration,
      );
      await appRunner.runApp();
      return { status: 'running' };
    } catch (e) {
      throw new RpcError(e.message || String(e), errorCode.EXECUTION_FAILED);
    } finally {
      URL.revokeObjectURL(url);
    }
  };

  rpcMethods.hotRestart = async (params) => {
    const { code, moduleName } = params;

    if (!self.dartDevEmbedder) {
      throw new RpcError(
        "dartDevEmbedder is not initialized.",
        errorCode.MODULE_LOADER_NOT_AVAILABLE
      );
    }

    if (code && !moduleName) {
      throw new RpcError("'moduleName' is required.", errorCode.INVALID_PARAMS);
    }

    try {
      // Define the official DDC hook for reloading modules during restart
      const reloadModules = (appName, callback) => {
        if (code) {
          const url = createAndRegisterBlob(moduleName, code);
          self.$dartLoader.forceLoadScript(url, callback);
        } else {
          callback();
        }
      };

      self.$dartReloadModifiedModules = reloadModules;
      await self.dartDevEmbedder.hotRestart();

      if (self.$dartReloadModifiedModules === reloadModules) {
        self.$dartReloadModifiedModules = null;
      }
      return { generation: self.dartDevEmbedder.hotRestartGeneration };
    } catch (e) {
      throw new RpcError(e.message || String(e), errorCode.HOT_RESTART_FAILED);
    }
  };

  rpcMethods.hotReload = async (params) => {
    const { code, librariesToReload = [], moduleName } = params;

    if (!self.dartDevEmbedder) {
      throw new RpcError(
        "dartDevEmbedder is not initialized.",
        errorCode.MODULE_LOADER_NOT_AVAILABLE
      );
    }

    const filesToLoad = [];
    if (code) {
      if (!moduleName) {
        throw new RpcError("'moduleName' is required.", errorCode.INVALID_PARAMS);
      }
      filesToLoad.push(createAndRegisterBlob(moduleName, code));
    }

    try {
      await self.dartDevEmbedder.hotReload(filesToLoad, librariesToReload);
      if (self.dartDevEmbedder.debugger.extensionNames.includes('ext.flutter.reassemble')) {
        await self.dartDevEmbedder.debugger.invokeExtension('ext.flutter.reassemble', '{}');
      }
      return { generation: self.dartDevEmbedder.hotReloadGeneration };
    } catch (e) {
      throw new RpcError(e.message || String(e), errorCode.HOT_RELOAD_FAILED);
    }
  };

  rpcMethods.appMetrics = async () => {
    if (!self.dart_library || !self.dart_library.appMetrics) return {};
    return self.dart_library.appMetrics();
  };

  rpcMethods.getHotRestartGeneration = async () => {
    if (!self.dartDevEmbedder) return { generation: 0 };
    return { generation: self.dartDevEmbedder.hotRestartGeneration };
  };

  rpcMethods.getHotReloadGeneration = async () => {
    if (!self.dartDevEmbedder) return { generation: 0 };
    return { generation: self.dartDevEmbedder.hotReloadGeneration };
  };

  function onWindowMessage(ev) {
    if (ev.source !== window.parent) {
      console.warn('Rejected connect message from untrusted source.');
      return;
    }

    // We expect the Dart host to send {'action': 'connect'}
    if (ev.data?.action !== 'connect') {
      console.warn('Received non-connect message:', ev);
      return;
    }
    if (ev.ports?.length !== 1) {
      console.error('Connect message missing port:', ev);
      return;
    }
    window.removeEventListener('message', onWindowMessage);

    rpcPort = ev.ports[0];
    rpcPort.onmessage = onRcpMessage;
    rpcPort.start();
  }

  window.addEventListener('message', onWindowMessage);
})();
