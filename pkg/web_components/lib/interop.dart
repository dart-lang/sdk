// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Provides support for associating a Dart type for Javascript Custom Elements.
/// This will not work unless `dart_support.js` is loaded.
library web_components.interop;

import 'dart:async' show Stream, StreamController;
import 'dart:html' show document, Element;
import 'dart:js' show JsObject, JsFunction;

final _doc = new JsObject.fromBrowserObject(document);

/// Returns whether [registerDartType] is supported, which requires to have
/// `dart_support.js` already loaded in the page.
bool get isSupported => _doc.hasProperty('_registerDartTypeUpgrader');

/// Watches when Javascript custom elements named [tagName] are created and
/// associates the created element with the given [dartType]. Only one Dart type
/// can be registered for a given tag name.
void registerDartType(String tagName, Type dartType, {String extendsTag}) {
  if (!isSupported) {
    throw new UnsupportedError("Couldn't find "
        "`document._registerDartTypeUpgrader`. Please make sure that "
        "`packages/web_components/dart_support.js` is loaded and available "
        "before calling this function.");
  }

  var upgrader = document.createElementUpgrader(
      dartType, extendsTag: extendsTag);
  _doc.callMethod('_registerDartTypeUpgrader', [tagName, upgrader.upgrade]);
}
