// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _HTMLIFrameElementJs extends _HTMLElementJs implements HTMLIFrameElement native "*HTMLIFrameElement" {

  String align;

  String frameBorder;

  String height;

  String longDesc;

  String marginHeight;

  String marginWidth;

  String name;

  String sandbox;

  String scrolling;

  String src;

  String width;

  _SVGDocumentJs getSVGDocument() native;


  Window get _contentWindow() native "return this.contentWindow;";

  // Override contentWindow to return secure wrapper.
  Window get contentWindow() {
    return _DOMWindowCrossFrameImpl._createSafe(_contentWindow);
  }
}
