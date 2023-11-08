// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A trimmed version of `unsafe_html` used to validate that tests can be run
/// successfully against a "real" and un-mocked SDK.
import 'dart:html';

void main() {
  AnchorElement()
    ..href = 'foo'; // LINT
  var embed = EmbedElement();
  embed.src = 'foo'; // LINT
  IFrameElement()
    ..src = 'foo'; // LINT

  var script = ScriptElement();
  script.src = 'foo.js'; // LINT
  var src = 'foo.js'; // OK
  var src2 = script.src; // OK
  script
    ..type = 'application/javascript'
    ..src = 'foo.js'; // LINT
  script
    ..src = 'foo.js' // LINT
    ..type = 'application/javascript';
  script?.src = 'foo.js'; // LINT

  // ...
}
