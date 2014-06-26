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
      ..style.height = '0px';
}

final String outputHelper =
    Url.createObjectUrl(new Blob([OUTPUT_HELPER], 'application/javascript'));

const String OUTPUT_HELPER = r'''
function dartPrint(msg) {
  // Send a message to the main Try Dart window.
  window.parent.postMessage(String(msg), "*");
}

function dartMainRunner(main) {
  // Store the current height (of an empty document).  This implies that the
  // main Try Dart application is only notified if the document is actually
  // changed.
  var previousScrollHeight = document.documentElement.scrollHeight;

  function postScrollHeight(mutations, observer) {
    var scrollHeight = document.documentElement.scrollHeight;
    if (scrollHeight !== previousScrollHeight) {
      previousScrollHeight = scrollHeight;
      window.parent.postMessage(["scrollHeight", scrollHeight], "*");
    }
  }

  var MutationObserver =
      window.MutationObserver ||
      window.WebKitMutationObserver ||
      window.MozMutationObserver;

  // Listen to any changes to the DOM.
  new MutationObserver(postScrollHeight).observe(
      document.documentElement,
      { attributes: true,
        childList: true,
        characterData: true,
        subtree: true });

  main();
}
''';
