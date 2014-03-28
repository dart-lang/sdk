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
      // Request the current anchor.
      requestCurrentHash();
    });

    if (window.location.hash == '') {
      // Fresh start, load the vm page.
      window.location.hash = defaultHash;
    } else {
      // The page is being reloaded.
      requestCurrentHash();
    }
  }

  /// Clear the current hash.
  void clearCurrentHash() {
    window.location.hash = '';
  }

  /// Refresh the service object reference in the location entry.
  void requestCurrentHash() {
    currentHash = window.location.hash;
    if (!currentHash.startsWith('#/')) {
      return;
    }
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
