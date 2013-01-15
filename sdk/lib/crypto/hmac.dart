// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.crypto;

class _HMAC implements HMAC {
  bool _isClosed = false;

  _HMAC(Hash this._hash, List<int> this._key) : _message = [];

  add(List<int> data) {
    if (_isClosed) throw new StateError("HMAC is closed");
    _message.addAll(data);
  }

  List<int> get digest {
    var blockSize = _hash.blockSize;

    // Hash the key if it is longer than the block size of the hash.
    if (_key.length > blockSize) {
      _hash = _hash.newInstance();
      _hash.add(_key);
      _key = _hash.close();
    }

    // Zero-pad the key until its size is equal to the block size of the hash.
    if (_key.length < blockSize) {
      var newKey = new List.fixedLength(blockSize);
      newKey.setRange(0, _key.length, _key);
      for (var i = _key.length; i < blockSize; i++) {
        newKey[i] = 0;
      }
      _key = newKey;
    }

    // Compute inner padding.
    var padding = new List.fixedLength(blockSize);
    for (var i = 0; i < blockSize; i++) {
      padding[i] = 0x36 ^ _key[i];
    }

    // Inner hash computation.
    _hash = _hash.newInstance();
    _hash.add(padding);
    _hash.add(_message);
    var innerHash = _hash.close();

    // Compute outer padding.
    for (var i = 0; i < blockSize; i++) {
      padding[i] = 0x5c ^ _key[i];
    }

    // Outer hash computation which is the result.
    _hash = _hash.newInstance();
    _hash.add(padding);
    _hash.add(innerHash);
    return _hash.close();
  }

  List<int> close() {
    _isClosed = true;
    return digest;
  }

  bool verify(List<int> digest) {
    var computedDigest = this.digest;
    if (digest.length != computedDigest.length) {
      throw new ArgumentError(
          'Invalid digest size: ${digest.length} in HMAC.verify. '
          'Expected: ${_hash.blockSize}.');
    }
    int result = 0;
    for (var i = 0; i < digest.length; i++) {
      result |= digest[i] ^ computedDigest[i];
    }
    return result == 0;
  }

  // HMAC internal state.
  Hash _hash;
  List<int> _key;
  List<int> _message;
}
