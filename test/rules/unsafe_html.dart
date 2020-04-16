// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unsafe_html`

import 'dart:html';

void main() {
  AnchorElement()..href = 'foo'; // LINT
  var embed = EmbedElement();
  embed.src = 'foo'; // LINT
  IFrameElement()..src = 'foo'; // LINT
  ImageElement()..src = 'foo'; // LINT

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

  IFrameElement()..srcdoc = 'foo'; // LINT

  var heading = HeadingElement.h1();
  heading.createFragment('<script>'); // LINT
  heading..createFragment('<script>'); // LINT
  heading.setInnerHtml('<script>'); // LINT
  heading..setInnerHtml('<script>'); // LINT

  Window().open('url', 'name'); // LINT
  Window()..open('url', 'name'); // LINT

  DocumentFragment.html('<script>'); // LINT
  Element.html('<script>'); // LINT

  C().src = 'foo.js'; // OK
  var c = C();
  c..src = 'foo.js'; // OK
  c?.src = 'foo.js'; // OK
  c.srcdoc = 'foo.js'; // OK
  c.createFragment('<script>'); // OK
  c.open('url', 'name'); // OK
  c.setInnerHtml('<script>'); // OK
  C.html('<script>'); // OK

  dynamic d;
  d.src = 'foo.js'; // LINT
  d.srcdoc = 'foo.js'; // LINT
  d.href = 'foo.js'; // LINT
  d.createFragment('<script>'); // LINT
  d.open('url', 'name'); // LINT
  d.setInnerHtml('<script>'); // LINT
  (script as dynamic).src = 'foo.js'; // LINT
  (C() as dynamic).src = 'foo.js'; // LINT

  // As a SecurityLintCode, unsafe_html reports cannot be ignored.
  // ignore: unsafe_html
  IFrameElement()..srcdoc = 'foo'; // LINT
}

class C {
  String src;
  String srcdoc;
  String href;

  C();

  C.html(String content);

  void createFragment(String html) {}

  void open(String url, String name) {}

  void setInnerHtml(String html) {}
}

extension on ScriptElement {
  void sneakySetSrc1(String url) => src = url; // LINT
  void sneakySetSrc2(String url) => this.src = url; // LINT

  void sneakyCreateFragment1(String html) => createFragment(html); // LINT
  void sneakyCreateFragment2(String html) => this.createFragment(html); // LINT

  void sneakySetInnerHtml1(String html) => setInnerHtml(html); // LINT
  void sneakySetInnerHtml2(String html) => this.setInnerHtml(html); // LINT
}

extension on Window {
  void sneakyOpen1(String url, String name) => open(url, name); // LINT
  void sneakyOpen2(String url, String name) => this.open(url, name); // LINT
}

extension on C {
  void sneakySetSrc1(String url) => src = url; // OK
  void sneakySetSrc2(String url) => this.src = url; // OK

  void sneakyCreateFragment1(String html) => createFragment(html); // OK
  void sneakyCreateFragment2(String html) => this.createFragment(html); // OK

  void sneakySetInnerHtml1(String html) => setInnerHtml(html); // OK
  void sneakySetInnerHtml2(String html) => this.setInnerHtml(html); // OK

  void sneakyOpen1(String url, String name) => open(url, name); // OK
  void sneakyOpen2(String url, String name) => this.open(url, name); // OK
}
