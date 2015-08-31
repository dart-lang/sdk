// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter.startup_emitter.model_emitter;

class _DeferredFragmentHash extends js.DeferredString {
  String _hash;
  final DeferredFragment _fragment;

  _DeferredFragmentHash(this._fragment);

  void setHash(String hash) {
    assert(_hash == null);
    _hash = hash;
  }

  @override
  String get value {
    assert(_hash != null);
    // Note the additional quotes in the returned value.
    return '"$_hash"';
  }

  String toString() => "HashCode for ${_fragment} [$_hash]";
}
