// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

function native_Window__postMessage(message, origin) {
  window.postMessage(message, origin);
}

function native_HTMLBodyElement__innerHTML(html) {
  document.body.innerHTML = html;
}
