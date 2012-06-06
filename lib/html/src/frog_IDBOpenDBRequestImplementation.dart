// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IDBOpenDBRequest.  IDBFactory.open returns a plain IDBRequest on Chrome and
// Dartium but an IDBOpenDBRequest on Firefox.  Chrome/Dartium is expected to
// change at some point as IDBOpenDBRequest is more standard.  When it appears
// in the WebKit IDL we can remove this hand-written file.
//
// See:
// http://www.w3.org/TR/IndexedDB/#request-api
// http://dvcs.w3.org/hg/IndexedDB/raw-file/tip/Overview.html#request-api

class _IDBOpenDBRequestImpl extends _IDBRequestImpl implements IDBOpenDBRequest
    native "*IDBOpenDBRequest" {

  _IDBOpenDBRequestEventsImpl get on() =>
    new _IDBOpenDBRequestEventsImpl(this);
}

class _IDBOpenDBRequestEventsImpl extends _IDBRequestEventsImpl implements IDBOpenDBRequestEvents {
  _IDBOpenDBRequestEventsImpl(_ptr) : super(_ptr);

  EventListenerList get blocked() => _get('blocked');

  EventListenerList get upgradeneeded() => _get('upgradeneeded');
}
