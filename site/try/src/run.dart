// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.run;

import 'dart:html' show
    Blob,
    IFrameElement,
    Url;

makeOutputFrame(String scriptUrl) {
  final String outputHtml = '''
<!DOCTYPE html>
<html lang="en">
<head>
<title>JavaScript output</title>
<meta http-equiv="Content-type" content="text/html;charset=UTF-8">
</head>
<body>
<script type="application/javascript" src="$outputHelper"></script>
<script type="application/javascript" src="$scriptUrl"></script>
</body>
</html>
''';

  return new IFrameElement()
      ..src = Url.createObjectUrl(new Blob([outputHtml], "text/html"))
      ..style.width = '100%'
      ..style.height = '0px'
      ..seamless = false;
}

final String outputHelper =
    Url.createObjectUrl(new Blob([OUTPUT_HELPER], 'application/javascript'));

const String OUTPUT_HELPER = r'''
function dartPrint(msg) {
  window.parent.postMessage(String(msg), "*");
}

function dartMainRunner(main) {
  main();
}

window.onerror = function (message, url, lineNumber) {
  window.parent.postMessage(
      ["error", {message: message, url: url, lineNumber: lineNumber}], "*");
};

(function () {

function postScrollHeight() {
  window.parent.postMessage(["scrollHeight", document.documentElement.scrollHeight], "*");
}

var observer = new (window.MutationObserver||window.WebKitMutationObserver||window.MozMutationObserver)(function(mutations) {
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
''';
