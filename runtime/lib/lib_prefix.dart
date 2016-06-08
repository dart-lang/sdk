// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:isolate";

// This type corresponds to the VM-internal class LibraryPrefix.
class _LibraryPrefix {
  bool _load() native "LibraryPrefix_load";
  Error _loadError() native "LibraryPrefix_loadError";
  bool isLoaded() native "LibraryPrefix_isLoaded";
  bool _invalidateDependentCode()
      native "LibraryPrefix_invalidateDependentCode";

  loadLibrary() {
    for (int i = 0; i < _outstandingLoadRequests.length; i++) {
      if (_outstandingLoadRequests[i][0] == this) {
        return _outstandingLoadRequests[i][1].future;
      }
    }

    var completer = new Completer<bool>();
    var pair = new List();
    pair.add(this);
    pair.add(completer);
    _outstandingLoadRequests.add(pair);
    Timer.run(() {
      var hasCompleted = this._load();
      // Loading can complete immediately, for example when the same
      // library has been loaded eagerly or through another deferred
      // prefix. If that is the case, we must invalidate the dependent
      // code and complete the future now since there will be no callback
      // from the VM.
      if (hasCompleted) {
        _invalidateDependentCode();
        completer.complete(true);
        _outstandingLoadRequests.remove(pair);
      }
    });
    return completer.future;
  }
}

// A list of two element lists. The first element is the _LibraryPrefix. The
// second element is the Completer for the load request.
var _outstandingLoadRequests = new List<List>();

// Called from the VM when an outstanding load request has finished.
_completeDeferredLoads() {
  // Determine which outstanding load requests have completed and complete
  // their completer (with an error or true). For outstanding load requests
  // which have not completed, remember them for next time in
  // stillOutstandingLoadRequests.
  var stillOutstandingLoadRequests = new List<List>();
  for (int i = 0; i < _outstandingLoadRequests.length; i++) {
    var prefix = _outstandingLoadRequests[i][0];
    if (prefix._load()) {
      var completer = _outstandingLoadRequests[i][1];
      var error = prefix._loadError();
      if (error != null) {
        completer.completeError(error);
      } else {
        prefix._invalidateDependentCode();
        completer.complete(true);
      }
    } else {
      stillOutstandingLoadRequests.add(_outstandingLoadRequests[i]);
    }
  }
  _outstandingLoadRequests = stillOutstandingLoadRequests;
}
