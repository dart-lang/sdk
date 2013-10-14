// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Final phase of the polymer transformation: includes any additional polyfills
 * that may needed by the deployed app.
 */
library polymer.src.build.polyfill_injector;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:html5lib/dom.dart' show Document, Node, DocumentFragment;
import 'package:html5lib/parser.dart' show parseFragment;
import 'common.dart';

/**
 * Ensures that any scripts and polyfills needed to run a polymer application
 * are included. For example, this transformer will ensure that there is a
 * script tag that loads the shadow_dom polyfill and interop.js (used for the
 * css shimming).
 */
class PolyfillInjector extends Transformer with PolymerTransformer {
  final TransformOptions options;

  PolyfillInjector(this.options);

  /** Only run on entry point .html files. */
  Future<bool> isPrimary(Asset input) =>
      new Future.value(options.isHtmlEntryPoint(input.id));

  Future apply(Transform transform) {
    return readPrimaryAsHtml(transform).then((document) {
      bool shadowDomFound = false;
      bool jsInteropFound = false;
      bool customElementFound = false;
      bool dartScriptTags = false;

      for (var tag in document.queryAll('script')) {
        var src = tag.attributes['src'];
        if (src != null) {
          var last = src.split('/').last;
          if (last == 'interop.js') {
            jsInteropFound = true;
          } else if (_shadowDomJS.hasMatch(last)) {
            shadowDomFound = true;
          } else if (_customElementJS.hasMatch(last)) {
            customElementFound = true;
          }
        }

        if (tag.attributes['type'] == 'application/dart') {
          dartScriptTags = true;
        }
      }

      if (!dartScriptTags) {
        // This HTML has no Dart code, there is nothing to do here.
        transform.addOutput(transform.primaryInput);
        return;
      }

      if (!jsInteropFound) {
        // JS interop code is required for Polymer CSS shimming.
        document.body.nodes.insert(0, parseFragment(
            '<script src="packages/browser/interop.js"></script>\n'));
      }

      if (!customElementFound) {
        document.body.nodes.insert(0, parseFragment(
            '<script src="packages/custom_element/custom-elements.debug.js">'
            '</script>\n'));
      }

      if (!shadowDomFound) {
        // Insert at the beginning (this polyfill needs to run as early as
        // possible).
        // TODO(jmesserly): this is .debug to workaround issue 13046.
        document.body.nodes.insert(0, parseFragment(
            '<script src="packages/shadow_dom/shadow_dom.debug.js"></script>\n'));
      }

      transform.addOutput(
          new Asset.fromString(transform.primaryInput.id, document.outerHtml));
    });
  }
}

final _shadowDomJS = new RegExp(r'shadow_dom\..*\.js', caseSensitive: false);
final _customElementJS = new RegExp(r'custom-elements\..*\.js',
    caseSensitive: false);
