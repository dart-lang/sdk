// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

/// The LocationManager class observes and parses the hash ('#') portion of the
/// URL in window.location. The text after the '#' is used as the request
/// string for the VM service.
class LocationManager extends Observable {
  static const String defaultHash = '#/isolates/';
  static final RegExp _currentIsolateMatcher = new RegExp(r'#/isolates/\d+');
  static final RegExp _currentObjectMatcher = new RegExp(r'#/isolates/\d+(/|$)');
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

  /// Parses the location entry and extracts the id for the object
  /// inside the current isolate.
  String currentIsolateObjectId() {
    Match m = _currentObjectMatcher.matchAsPrefix(currentHash);
    if (m == null) {
      return null;
    }
    return m.input.substring(m.end);
  }

  /// Parses the location entry and extracts the id for the current isolate.
  String currentIsolateId() {
    Match m = _currentIsolateMatcher.matchAsPrefix(currentHash);
    if (m == null) {
      return '';
    }
    return m.input.substring(2, m.end);
  }

  /// Returns the current isolate.
  @observable Isolate currentIsolate() {
    var id = currentIsolateId();
    if (id == '') {
      return null;
    }
    return _app.vm.isolates.getIsolate(id);
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

  void _setResponse(ServiceObject serviceObject) {
    _app.response = serviceObject;
  }

  /// Refresh the service object reference in the location entry.
  void requestCurrentHash() {
    currentHash = window.location.hash;
    _app.isolate = currentIsolate();
    if (_app.isolate == null) {
      // No current isolate, refresh the isolate list.
      _app.vm.isolates.reload().then(_setResponse);
      return;
    }
    // Have a current isolate, request object.
    var objectId = currentIsolateObjectId();
    _app.isolate.get(objectId).then(_setResponse);
  }
}
