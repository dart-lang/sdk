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
        "`packages/web_components/interop_support.html` is loaded and "
        "available before calling this function.");
  }

  var upgrader = document.createElementUpgrader(
      dartType, extendsTag: extendsTag);

  // Unfortunately the dart:html upgrader will throw on an already-upgraded
  // element, so we need to duplicate the type check to prevent that.
  // An element can be upgraded twice if it extends another element and calls
  // createdCallback on the superclass. Since that's a valid use case we must
  // wrap at both levels, and guard against it here.
  upgradeElement(e) {
    if (e.runtimeType != dartType) upgrader.upgrade(e);
  }

  _doc.callMethod('_registerDartTypeUpgrader', [tagName, upgradeElement]);
}

/// This function is mainly used to save resources. By default, we save a log of
/// elements that are created but have no Dart type associated with them. This
/// is so we can upgrade them as soon as [registerDartType] is invoked. This
/// function can be called to indicate that we no longer are interested in
/// logging element creations and that it is sufficient to only upgrade new
/// elements as they are being created. Typically this is called after the last
/// call to [registerDartType] or as soon as you know that no element will be
/// created until the call to [registerDartType] is made.
void onlyUpgradeNewElements() => _doc.callMethod('_onlyUpgradeNewElements');
