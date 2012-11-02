// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _HMAC implements HMAC {
  _HMAC(Hash this._hash, List<int> this._key) : _message = [];

  HMAC update(List<int> data) {
    _message.addAll(data);
    return this;
  }

  List<int> digest() {
    var blockSize = _hash.blockSize;

    // Hash the key if it is longer than the block size of the hash.
    if (_key.length > blockSize) {
      _hash = _hash.newInstance();
      _key = _hash.update(_key).digest();
    }

    // Zero-pad the key until its size is equal to the block size of the hash.
    if (_key.length < blockSize) {
      var newKey = new List(blockSize);
      newKey.setRange(0, _key.length, _key);
      for (var i = _key.length; i < blockSize; i++) {
        newKey[i] = 0;
      }
      _key = newKey;
    }

    // Compute inner padding.
    var padding = new List(blockSize);
    for (var i = 0; i < blockSize; i++) {
      padding[i] = 0x36 ^ _key[i];
    }

    // Inner hash computation.
    _hash = _hash.newInstance();
    var innerHash = _hash.update(padding).update(_message).digest();

    // Compute outer padding.
    for (var i = 0; i < blockSize; i++) {
      padding[i] = 0x5c ^ _key[i];
    }

    // Outer hash computation which is the result.
    _hash = _hash.newInstance();
    return _hash.update(padding).update(innerHash).digest();
  }

  // HMAC internal state.
  Hash _hash;
  List<int> _key;
  List<int> _message;
}
