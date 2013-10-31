// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observatory;

/// The LocationManager class observes and parses the hash ('#') portion of the
/// URL in window.location. The text after the '#' is used as the request
/// string for the VM service.
class LocationManager extends Observable {
  static const int InvalidIsolateId = 0;
  static const String defaultHash = '#/isolates/';
  static final RegExp currentIsolateMatcher = new RegExp(r"#/isolates/\d+/");

  ObservatoryApplication _application;
  ObservatoryApplication get application => _application;

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

  /// Returns the current isolate prefix, i.e. '#/isolates/XX/' if one
  /// is present and null otherwise.
  String currentIsolateAnchorPrefix() {
    Match m = currentIsolateMatcher.matchAsPrefix(currentHash);
    if (m == null) {
      return null;
    }
    return m.input.substring(m.start, m.end);
  }

  /// Predicate, does the current URL have a current isolate ID in it?
  bool get hasCurrentIsolate {
    return currentIsolateAnchorPrefix() != null;
  }

  /// Extract the current isolate id as an integer. Returns [InvalidIsolateId]
  /// if none is present in window.location.
  int currentIsolateId() {
    String isolatePrefix = currentIsolateAnchorPrefix();
    if (isolatePrefix == null) {
      return InvalidIsolateId;
    }
    String id = isolatePrefix.split("/")[2];
    return int.parse(id);
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
    application.requestManager.get(requestUrl);
  }

  /// Create a request for [l] on the current isolate.
  @observable
  String currentIsolateRelativeLink(String l) {
    var isolateId = currentIsolateId();
    if (isolateId == LocationManager.InvalidIsolateId) {
      return defaultHash;
    }
    return relativeLink(isolateId, l);
  }

  /// Create a request for [objectId] on the current isolate.
  @observable
  String currentIsolateObjectLink(int objectId) {
    var isolateId = currentIsolateId();
    if (isolateId == LocationManager.InvalidIsolateId) {
      return defaultHash;
    }
    return objectLink(isolateId, objectId);
  }

  /// Create a request for [cid] on the current isolate.
  @observable
  String currentIsolateClassLink(int cid) {
    var isolateId = currentIsolateId();
    if (isolateId == LocationManager.InvalidIsolateId) {
      return defaultHash;
    }
    return classLink(isolateId, cid);
  }

  /// Create a request for [l] on [isolateId].
  @observable
  String relativeLink(int isolateId, String l) {
    return '#/isolates/$isolateId/$l';
  }

  /// Create a request for [objectId] on [isolateId].
  @observable
  String objectLink(int isolateId, int objectId) {
    return '#/isolates/$isolateId/objects/$objectId';
  }

  /// Create a request for [cid] on [isolateId].
  @observable
  String classLink(int isolateId, int cid) {
    return '#/isolates/$isolateId/classes/$cid';
  }
}
