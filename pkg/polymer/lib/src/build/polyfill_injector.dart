// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Includes any additional polyfills that may needed by the deployed app.
library polymer.src.build.polyfill_injector;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:html5lib/dom.dart' show
    Document, DocumentFragment, Element, Node;
import 'package:html5lib/parser.dart' show parseFragment;
import 'common.dart';

/// Ensures that any scripts and polyfills needed to run a polymer application
/// are included.
///
/// This step also replaces "packages/browser/dart.js" and the Dart script tag
/// with a script tag that loads the dart2js compiled code directly.
class PolyfillInjector extends Transformer with PolymerTransformer {
  final TransformOptions options;

  PolyfillInjector(this.options);

  /// Only run on entry point .html files.
  // TODO(nweiz): This should just take an AssetId when barback <0.13.0 support
  // is dropped.
  Future<bool> isPrimary(idOrAsset) {
    var id = idOrAsset is AssetId ? idOrAsset : idOrAsset.id;
    return new Future.value(options.isHtmlEntryPoint(id));
  }

  Future apply(Transform transform) {
    return readPrimaryAsHtml(transform).then((document) {
      bool webComponentsFound = false;
      Element dartJs;
      final dartScripts = <Element>[];

      for (var tag in document.querySelectorAll('script')) {
        var src = tag.attributes['src'];
        if (src != null) {
          var last = src.split('/').last;
          if (_webComponentsJS.hasMatch(last)) {
            webComponentsFound = true;
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

      // Remove "packages/browser/dart.js". It is not needed in release mode,
      // and in debug mode we want to ensure it is the last script on the page.
      if (dartJs != null) dartJs.remove();

      // TODO(jmesserly): ideally we would generate an HTML that loads
      // dart2dart too. But for now dart2dart is not a supported deployment
      // target, so just inline the JS script. This has the nice side effect of
      // fixing our tests: even if content_shell supports Dart VM, we'll still
      // test the compiled JS code.
      if (options.directlyIncludeJS) {
        // Replace all other Dart script tags with JavaScript versions.
        for (var script in dartScripts) {
          final src = script.attributes['src'];
          if (src.endsWith('.dart')) {
            script.attributes.remove('type');
            script.attributes['src'] = '$src.js';
            // TODO(sigmund): we shouldn't need 'async' here. Remove this
            // workaround for dartbug.com/19653.
            script.attributes['async'] = '';
          }
        }
      } else {
        document.body.nodes.add(parseFragment(
              '<script src="packages/browser/dart.js"></script>'));
      }

      _addScriptFirst(urlSegment) {
        document.head.nodes.insert(0, parseFragment(
              '<script src="packages/$urlSegment"></script>\n'));
      }

      var suffix = options.releaseMode ? '.js' : '.concat.js';
      if (!webComponentsFound) {
        _addScriptFirst('web_components/dart_support.js');

        // platform.js should come before all other scripts.
        _addScriptFirst('web_components/platform$suffix');
      }

      transform.addOutput(
          new Asset.fromString(transform.primaryInput.id, document.outerHtml));
    });
  }
}

final _webComponentsJS = new RegExp(r'platform.*\.js',
    caseSensitive: false);
