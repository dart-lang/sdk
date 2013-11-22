// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Includes any additional polyfills that may needed by the deployed app. */
library polymer.src.build.polyfill_injector;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:html5lib/dom.dart' show
    Document, DocumentFragment, Element, Node;
import 'package:html5lib/parser.dart' show parseFragment;
import 'common.dart';

/**
 * Ensures that any scripts and polyfills needed to run a polymer application
 * are included. For example, this transformer will ensure that there is a
 * script tag that loads the shadow_dom polyfill and interop.js (used for the
 * css shimming).
 *
 * This step also replaces "packages/browser/dart.js" and the Dart script tag
 * with a script tag that loads the dart2js compiled code directly.
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
      Element dartJs;
      final dartScripts = <Element>[];

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
          } else if (last == 'dart.js') {
            dartJs = tag;
          }
        }

        if (tag.attributes['type'] == 'application/dart') {
          dartScripts.add(tag);
        }
      }

      if (dartScripts.isEmpty) {
        // This HTML has no Dart code, there is nothing to do here.
        transform.addOutput(transform.primaryInput);
        return;
      }

      // TODO(jmesserly): ideally we would generate an HTML that loads
      // dart2dart too. But for now dart2dart is not a supported deployment
      // target, so just inline the JS script. This has the nice side effect of
      // fixing our tests: even if content_shell supports Dart VM, we'll still
      // test the compiled JS code.
      if (options.directlyIncludeJS) {
        // If using CSP add the "precompiled" extension
        final csp = options.contentSecurityPolicy ? '.precompiled' : '';

        // Replace all other Dart script tags with JavaScript versions.
        for (var script in dartScripts) {
          final src = script.attributes['src'];
          if (src.endsWith('.dart')) {
            script.attributes.remove('type');
            script.attributes['src'] = '$src$csp.js';
          }
        }
        // Remove "packages/browser/dart.js"
        if (dartJs != null) dartJs.remove();
      } else if (dartJs == null) {
        document.body.nodes.add(parseFragment(
              '<script src="packages/browser/dart.js"></script>'));
      }

      _addScript(urlSegment) {
        document.head.nodes.insert(0, parseFragment(
              '<script src="packages/$urlSegment"></script>\n'));
      }

      // JS interop code is required for Polymer CSS shimming.
      if (!jsInteropFound) _addScript('browser/interop.js');

      // TODO(sigmund): enable using .min.js. This currently fails in checked
      // mode because of bugs in dart2js mirrors (dartbug.com/14720).
      // var suffix = options.releaseMode ? '.min.js' : '.debug.js';
      var suffix = '.debug.js';
      if (!customElementFound) {
        _addScript('custom_element/custom-elements$suffix');
      }

      // This polyfill needs to be the first one on the head
      if (!shadowDomFound) _addScript('shadow_dom/shadow_dom$suffix');

      transform.addOutput(
          new Asset.fromString(transform.primaryInput.id, document.outerHtml));
    });
  }
}

final _shadowDomJS = new RegExp(r'shadow_dom\..*\.js', caseSensitive: false);
final _customElementJS = new RegExp(r'custom-elements\..*\.js',
    caseSensitive: false);
