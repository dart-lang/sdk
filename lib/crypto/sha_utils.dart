// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Constants.
final _MASK_8 = 0xff;
final _MASK_32 = 0xffffffff;
final _BITS_PER_BYTE = 8;
final _BYTES_PER_WORD = 4;

// Base class encapsulating common behavior for SHA cryptographic hash
// functions.
class _SHAHashBase implements Hash {
  _SHAHashBase(int this._chunkSizeInWords, int this._digestSizeInWords)
      : _pendingData = [] {
    _currentChunk = new List(_chunkSizeInWords);
    _h = new List(_digestSizeInWords);
  }

  // Update the hasher with more data.
  _SHAHashBase update(List<int> data) {
    if (_digestCalled) {
      throw new HashException(
          'Hash update method called after digest was retrieved');
    }
    _lengthInBytes += data.length;
    _pendingData.addAll(data);
    _iterate();
    return this;
  }

  // Finish the hash computation and return the digest string.
  List<int> digest() {
    if (_digestCalled) {
      return _resultAsBytes();
    }
    _digestCalled = true;
    _finalizeData();
    _iterate();
    assert(_pendingData.length == 0);
    return _resultAsBytes();
  }

  // Returns the block size of the hash in bytes.
  int get blockSize() {
    return _chunkSizeInWords * _BYTES_PER_WORD;
  }

  // Create a fresh instance of this Hash.
  abstract newInstance();

  // One round of the hash computation.
  abstract _updateHash(List<int> m);

  // Helper methods.
  _add32(x, y) => (x + y) & _MASK_32;
  _roundUp(val, n) => (val + n - 1) & -n;

  // Compute the final result as a list of bytes from the hash words.
  _resultAsBytes() {
    var result = [];
    for (var i = 0; i < _h.length; i++) {
      result.addAll(_wordToBytes(_h[i]));
    }
    return result;
  }

  // Converts a list of bytes to a chunk of 32-bit words.
  _bytesToChunk(List<int> data, int dataIndex) {
    assert((data.length - dataIndex) >= (_chunkSizeInWords * _BYTES_PER_WORD));
    for (var wordIndex = 0; wordIndex < _chunkSizeInWords; wordIndex++) {
      var word = (data[dataIndex++] & 0xff) << 24;
      word |= (data[dataIndex++] & _MASK_8) << 16;
      word |= (data[dataIndex++] & _MASK_8) << 8;
      word |= (data[dataIndex++] & _MASK_8);
      _currentChunk[wordIndex] = word;
    }
  }

  // Convert a 32-bit word to four bytes.
  _wordToBytes(int word) {
    List<int> bytes = new List(_BYTES_PER_WORD);
    bytes[0] = word >> 24;
    bytes[1] = (word >> 16) & _MASK_8;
    bytes[2] = (word >> 8) & _MASK_8;
    bytes[3] = word & _MASK_8;
    return bytes;
  }

  // Iterate through data updating the hash computation for each
  // chunk.
  _iterate() {
    var len = _pendingData.length;
    var chunkSizeInBytes = _chunkSizeInWords * _BYTES_PER_WORD;
    if (len >= chunkSizeInBytes) {
      var index = 0;
      for (; (len - index) >= chunkSizeInBytes; index += chunkSizeInBytes) {
        _bytesToChunk(_pendingData, index);
        _updateHash(_currentChunk);
      }
      var remaining = len - index;
      _pendingData = _pendingData.getRange(index, remaining);
    }
  }

  // Finalize the data. Add a 1 bit to the end of the message. Expand with
  // 0 bits and the length of the message.
  _finalizeData() {
    _pendingData.add(0x80);
    var contentsLength = _lengthInBytes + 9;
    var chunkSizeInBytes = _chunkSizeInWords * _BYTES_PER_WORD;
    var finalizedLength = _roundUp(contentsLength, chunkSizeInBytes);
    var zeroPadding = finalizedLength - contentsLength;
    for (var i = 0; i < zeroPadding; i++) {
      _pendingData.add(0);
    }
    var lengthInBits = _lengthInBytes * _BITS_PER_BYTE;
    _pendingData.addAll(_wordToBytes(lengthInBits >> 32));
    _pendingData.addAll(_wordToBytes(lengthInBits & _MASK_32));
  }

  // Hasher state.
  final int _chunkSizeInWords;
  final int _digestSizeInWords;
  int _lengthInBytes = 0;
  List<int> _pendingData;
  List<int> _currentChunk;
  List<int> _h;
  bool _digestCalled = false;
}
