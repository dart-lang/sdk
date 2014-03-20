// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

/// The LocationManager class observes and parses the hash ('#') portion of the
/// URL in window.location. The text after the '#' is used as the request
/// string for the VM service.
class LocationManager extends Observable {
  static const String defaultHash = '#/vm';

  ObservatoryApplication _app;
  @observable String currentHash = '';

  void init() {
    window.onHashChange.listen((event) {
      if (setDefaultHash()) {
        // We just triggered another onHashChange event.
        return;
      }
      // Request the current anchor.
      requestCurrentHash();
    });

    if (!setDefaultHash()) {
      // An anchor was already present, trigger a request.
      requestCurrentHash();
    }
  }

  /// If no anchor is set, set the default anchor and return true.
  /// Return false otherwise.
  bool setDefaultHash() {
    currentHash = window.location.hash;
    if (currentHash == '' || currentHash == '#') {
      window.location.hash = defaultHash;
      return true;
    }
    return false;
  }

  /// Refresh the service object reference in the location entry.
  void requestCurrentHash() {
    currentHash = window.location.hash;
    assert(currentHash.startsWith('#/'));

    var parts = currentHash.substring(2).split('#');
    var location = parts[0];
    var args = (parts.length > 1 ? parts[1] : '');
    if (parts.length > 2) {
      Logger.root.warning('Found more than 2 #-characters in $currentHash');
    }
    _app.vm.get(currentHash.substring(2)).then((obj) {
        _app.response = obj;
        _app.args = args;
      });
  }
}
