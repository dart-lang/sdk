/**
 * Scalable Vector Graphics:
 * Two-dimensional vector graphics with support for events and animation.
 *
 * For details about the features and syntax of SVG, a W3C standard,
 * refer to the
 * [Scalable Vector Graphics Specification](http://www.w3.org/TR/SVG/).
 */
library dart.dom.svg;

import 'dart:async';
import 'dart:collection';
import 'dart:_internal';
import 'dart:html';
import 'dart:html_common';
import 'dart:_js_helper' show Creates, Returns, JSName, Native;
import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show Interceptor;
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class _SvgElementFactoryProvider {
  static SvgElement createSvgElement_tag(String tag) {
    final Element temp =
      document.createElementNS("http://www.w3.org/2000/svg", tag);
    return temp;
  }
}
// DO NOT EDIT - unless you are editing documentation as per:
// https://code.google.com/p/dart/wiki/ContributingHTMLDocumentation
// Auto-generated dart:svg library.





// FIXME: Can we make this private?
final svgBlinkMap = {

};

// FIXME: Can we make this private?
final svgBlinkFunctionMap = {

};
