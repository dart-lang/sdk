// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter.full_emitter;

class _DeferredOutputUnitHash extends jsAst.DeferredString {
  String _hash;
  final OutputUnit _outputUnit;

  _DeferredOutputUnitHash(this._outputUnit);

  void setHash(String hash) {
    assert(_hash == null);
    _hash = hash;
  }

  String get value {
    assert(_hash != null);
    return '"$_hash"';
  }

  String toString() => "HashCode for ${_outputUnit} [$_hash]";
}
