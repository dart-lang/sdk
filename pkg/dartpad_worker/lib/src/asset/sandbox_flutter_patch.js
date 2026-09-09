(function () {
  const scriptUrl = document.currentScript?.src || self.location.href;

  // Tell the Flutter engine where to find CanvasKit and assets
  const dartpadFlutterConfiguration = {
    canvasKitBaseUrl: new URL('./canvaskit/', scriptUrl).href,
    assetBase: new URL('./', scriptUrl).href,
  };

  self.$dartpadSandboxScripts = [
    './ddc_module_loader.js',
    './flutter.js',
    './dart_sdk.js',
    './flutter_web.js',
  ];

  async function runConsole(libraryUri, options) {
    self.dartDevEmbedder.runMain(libraryUri, options || {});
    return { status: 'running' };
  }

  async function runflutter(libraryUri, options) {
    if (!self._flutter || !self._flutter.loader) {
      const err = new Error("flutter.js is not loaded!");
      err.name = "SERVER_ERROR";
      throw err;
    }

    const libraryUriJson = JSON.stringify(libraryUri);
    const optionsJson = JSON.stringify(options || {});
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
        dartpadFlutterConfiguration,
      );
      await appRunner.runApp();
      return { status: 'running' };
    } finally {
      URL.revokeObjectURL(url);
    }
  }

  self.$dartpadRunModes = {
    console: runConsole,
    flutter: runflutter,
  };
})();
