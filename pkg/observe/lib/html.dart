// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): can we handle this more elegantly?
// In general, it seems like we want a convenient way to take a Stream plus a
// getter and convert this into an Observable.

/// Helpers for exposing dart:html as observable data.
library observe.html;

import 'dart:html';

import 'observe.dart';

/// An observable version of [window.location.hash].
final ObservableLocationHash windowLocation = new ObservableLocationHash._();

class ObservableLocationHash extends ChangeNotifier {
  Object _currentHash;

  ObservableLocationHash._() {
    // listen on changes to #hash in the URL
    // Note: listen on both popState and hashChange, because IE9 doesn't support
    // history API. See http://dartbug.com/5483
    // TODO(jmesserly): only listen to these if someone is listening to our
    // changes.
    window.onHashChange.listen(_notifyHashChange);
    window.onPopState.listen(_notifyHashChange);

    _currentHash = hash;
  }

  @reflectable String get hash => window.location.hash;

  /// Pushes a new URL state, similar to the affect of clicking a link.
  /// Has no effect if the [value] already equals [window.location.hash].
  @reflectable void set hash(String value) {
    if (value == hash) return;

    window.history.pushState(null, '', value);
    _notifyHashChange(null);
  }

  void _notifyHashChange(_) {
    var oldValue = _currentHash;
    _currentHash = hash;
    notifyPropertyChange(#hash, oldValue, _currentHash);
  }
}

/// *Deprecated* use [CssClassSet.toggle] instead.
///
/// Add or remove CSS class [className] based on the [value].
@deprecated
void updateCssClass(Element element, String className, bool value) {
  if (value == true) {
    element.classes.add(className);
  } else {
    element.classes.remove(className);
  }
}

/// *Deprecated* use `class="{{ binding }}"` in your HTML instead. It will also
/// work on a `<polymer-element>`.
///
/// Bind a CSS class to the observable [object] and property [path].
@deprecated
PathObserver bindCssClass(Element element, String className,
    Observable object, String path) {

  callback(value) {
    updateCssClass(element, className, value);
  }

  var obs = new PathObserver(object, path);
  callback(obs.open(callback));
  return obs;
}
