// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

/// The LocationManager class observes and parses the hash ('#') portion of the
/// URL in window.location. The text after the '#' is used as the request
/// string for the VM service.
class LocationManager extends Observable {
  static const int InvalidIsolateId = 0;
  static const String defaultHash = '#/isolates/';
  static final RegExp currentIsolateMatcher = new RegExp(r"#/isolates/\d+");

  ObservatoryApplication _app;
  ObservatoryApplication get app => _app;

  @observable bool profile = false;
  @observable String currentHash = '';
  @observable Uri currentHashUri;
  void init() {
    window.onHashChange.listen((event) {
      if (setDefaultHash()) {
        // We just triggered another onHashChange event.
        return;
      }
      notifyPropertyChange(#hasCurrentIsolate, !hasCurrentIsolate,
                           hasCurrentIsolate);
      // Request the current anchor.
      requestCurrentHash();
    });

    if (!setDefaultHash()) {
      // An anchor was already present, trigger a request.
      requestCurrentHash();
    }
  }


  /// Returns the current isolate prefix, i.e. '#/isolates/XX/' if one
  /// is present and null otherwise.
  String currentIsolateAnchorPrefix() {
    Match m = currentIsolateMatcher.matchAsPrefix(currentHash);
    if (m == null) {
      return null;
    }
    return m.input.substring(m.start, m.end);
  }

  /// Returns the current object id.
  String currentObjectId() {
    Match m = currentIsolateMatcher.matchAsPrefix(currentHash);
    if (m == null) {
      return null;
    }
    return m.input.substring(m.end);
  }

  /// Predicate, does the current URL have a current isolate ID in it?
  @observable bool get hasCurrentIsolate {
    return currentIsolateAnchorPrefix() != null;
  }

  /// Extract the current isolate id as an integer. Returns [InvalidIsolateId]
  /// if none is present in window.location.
  String currentIsolateId() {
    var prefix = currentIsolateAnchorPrefix();
    if (prefix == null) {
      return '';
    }
    // Chop off the '/#'.
    return prefix.substring(2);
  }

  /// Returns the current isolate.
  @observable Isolate currentIsolate() {
    var id = currentIsolateId();
    if (id == '') {
      return null;
    }
    return app.vm.getIsolate(id);
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

  /// Take the current request string from window.location and submit the
  /// request to the request manager.
  void requestCurrentHash() {
    currentHash = window.location.hash;
    // Chomp off the #
    String requestUrl = currentHash.substring(1);
    app.isolate = currentIsolate();
    currentHashUri = Uri.parse(requestUrl);
    if (app.isolate == null) {
      Logger.root.warning('Refreshing isolates.');
      app.vm.refreshIsolates();
      return;
    }
    var objectId = currentObjectId();
    Logger.root.info('Asking ${app.isolate.id} for ${objectId}');
    app.isolate.get(objectId).then((so) {
      app.response = so;
    });
  }
}
