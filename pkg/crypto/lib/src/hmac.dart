// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of crypto;

/**
 * Hash-based Message Authentication Code support.
 *
 * The [add] method is used to add data to the message. The [digest] and
 * [close] methods are used to extract the message authentication code.
 */
// TODO(floitsch): make Hash implement Sink, EventSink or similar.
class HMAC {
  bool _isClosed = false;

  /**
   * Create an [HMAC] object from a [Hash] and a key.
   */
  HMAC(Hash this._hash, List<int> this._key) : _message = [];

  /**
   * Add a list of bytes to the message.
   */
  void add(List<int> data) {
    if (_isClosed) throw new StateError("HMAC is closed");
    _message.addAll(data);
  }

  /**
   * Extract the message digest as a list of bytes without closing [this].
   */
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

  /**
   * Perform the actual computation and extract the message digest
   * as a list of bytes.
   */
  List<int> close() {
    _isClosed = true;
    return digest;
  }

  /**
   * Verify that the HMAC computed for the data so far matches the
   * given message digest.
   *
   * This method should be used instead of memcmp-style comparisons
   * to avoid leaking information via timing.
   *
   * Throws an exception if the given digest does not have the same
   * size as the digest computed by this HMAC instance.
   */
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
  final List<int> _message;
}
