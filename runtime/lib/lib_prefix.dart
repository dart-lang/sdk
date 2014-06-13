// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:isolate";

// This type corresponds to the VM-internal class LibraryPrefix.
class _LibraryPrefix {

  bool _load() native "LibraryPrefix_load";

  void _invalidateDependentCode()
      native "LibraryPrefix_invalidateDependentCode";

  loadLibrary() {
    var completer = _outstandingLoadRequests[this];
    if (completer != null) {
      return completer.future;
    }
    completer = new Completer<bool>();
    _outstandingLoadRequests[this] = completer;
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
        _outstandingLoadRequests.remove(this);
      }
    });
    return completer.future;
  }
}

var _outstandingLoadRequests = new Map<_LibraryPrefix, Completer>();


// Called from the VM when all outstanding load requests have
// finished.
_completeDeferredLoads() {
  var lenghth = _outstandingLoadRequests;
  _outstandingLoadRequests.forEach((prefix, completer) {
    prefix._invalidateDependentCode();
    completer.complete(true);
  });
  _outstandingLoadRequests.clear();
}
