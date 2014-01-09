// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

function dartPrint(msg) {
  window.parent.postMessage(String(msg), "*");
}

window.onerror = function (message, url, lineNumber) {
  window.parent.postMessage(
      ["error", {message: message, url: url, lineNumber: lineNumber}], "*");
};

function onMessageReceived(event) {
  var data = event.data;
  if (data instanceof Array) {
    if (data.length == 2 && data[0] == 'source') {
      var script = document.createElement('script');
      script.innerHTML = data[1];
      script.type = 'application/javascript';
      document.head.appendChild(script);
      return;
    }
  }
}

window.addEventListener("message", onMessageReceived, false);

(function () {
  function postScrollHeight() {
    window.parent.postMessage(
      ["scrollHeight", document.documentElement.scrollHeight], "*");
  }

  var mutationObserverConstructor =
      window.MutationObserver ||
      window.WebKitMutationObserver ||
      window.MozMutationObserver;

  var observer = new mutationObserverConstructor(function(mutations) {
    postScrollHeight()
    window.setTimeout(postScrollHeight, 500);
  });

  observer.observe(
      document.body,
      { attributes: true,
        childList: true,
        characterData: true,
        subtree: true });
})();
