(function () {
  const scriptUrl = document.currentScript?.src || self.location.href;

  // Tell the Flutter engine where to find CanvasKit and assets
  const dartpadFlutterConfiguration = {
    canvasKitBaseUrl: new URL('{{canvasKitBaseUrl}}', scriptUrl).href,
    assetBase: new URL('./', scriptUrl).href,
  };

  self.$dartpadSandboxScripts = [
    './sandbox_runtime.js',
    './dart_sdk.js',
    './flutter_web.js',
  ];

  async function reassemble() {
    if (
      self.dartDevEmbedder.debugger.extensionNames.includes(
        'ext.flutter.reassemble',
      )
    ) {
      await self.dartDevEmbedder.debugger.invokeExtension(
        'ext.flutter.reassemble',
        '{}',
      );
    }
  }

  function disassemble() {
    if (
      self.dartDevEmbedder.debugger.extensionNames.includes(
        'ext.flutter.disassemble',
      )
    ) {
      self.dartDevEmbedder.debugger
        .invokeExtension('ext.flutter.disassemble', '{}')
        .catch(() => {});
    }
  }

  async function runFlutter(run) {
    if (!self._flutter || !self._flutter.loader) {
      const err = new Error("flutter.js is not loaded!");
      err.name = "SERVER_ERROR";
      throw err;
    }

    const ran = Promise.withResolvers();
    self._dartpadRunMain = async () => {
      try {
        ran.resolve(await run());
      } catch (e) {
        ran.reject(e);
      }
    };
    const url = URL.createObjectURL(
      new Blob(['self._dartpadRunMain();'], {
        type: 'application/javascript',
      }),
    );

    let engineInitializer;
    try {
      await self._flutter.loader.loadEntrypoint({
        entrypointUrl: url,
        onEntrypointLoaded: (initializer) => {
          engineInitializer = initializer;
        },
      });
      await ran.promise;
    } finally {
      delete self._dartpadRunMain;
      URL.revokeObjectURL(url);
    }

    const appRunner = await engineInitializer.initializeEngine(
      dartpadFlutterConfiguration,
    );
    await appRunner.runApp();
  }

  async function hotRestartFlutter(hotRestart) {
    // Must run synchronously before `hotRestart()` so
    // `libraryManager.hotRestart()` increments `hotRestartGeneration` in
    // the same synchronous turn as `_hotRestartListeners`, preventing DOM
    // events (like `focusout` when `<flutter-view>` is removed) from
    // running microtasks in the dying generation.
    disassemble();
    await hotRestart();
  }

  async function hotReloadFlutter(hotReload) {
    await hotReload();
    await reassemble();
  }

  self.$dartpadRunModes = {
    console: {
      run: async (run) => await run(),
      hotRestart: async (hotRestart) => await hotRestart(),
      hotReload: async (hotReload) => await hotReload(),
    },
    flutter: {
      run: runFlutter,
      hotRestart: hotRestartFlutter,
      hotReload: hotReloadFlutter,
    },
  };
})();
