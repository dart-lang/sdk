// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of crypto;

// Constants.
const _MASK_8 = 0xff;
const _MASK_32 = 0xffffffff;
const _BITS_PER_BYTE = 8;
const _BYTES_PER_WORD = 4;

// Helper functions used by more than one hasher.

// Rotate left limiting to unsigned 32-bit values.
int _rotl32(int val, int shift) {
  var mod_shift = shift & 31;
  return ((val << mod_shift) & _MASK_32) |
      ((val & _MASK_32) >> (32 - mod_shift));
}

// Base class encapsulating common behavior for cryptographic hash
// functions.
abstract class _HashBase implements Hash {
  _HashBase(int chunkSizeInWords,
            int digestSizeInWords,
            bool this._bigEndianWords)
      : _pendingData = [],
        _currentChunk = new List(chunkSizeInWords),
        _h = new List(digestSizeInWords),
        _chunkSizeInWords = chunkSizeInWords,
        _digestSizeInWords = digestSizeInWords;

  // Update the hasher with more data.
  void add(List<int> data) {
    if (_digestCalled) {
      throw new StateError(
          'Hash update method called after digest was retrieved');
    }
    _lengthInBytes += data.length;
    _pendingData.addAll(data);
    _iterate();
  }

  // Finish the hash computation and return the digest string.
  List<int> close() {
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
  int get blockSize {
    return _chunkSizeInWords * _BYTES_PER_WORD;
  }

  // One round of the hash computation.
  void _updateHash(List<int> m);

  // Helper methods.
  int _add32(x, y) => (x + y) & _MASK_32;
  int _roundUp(val, n) => (val + n - 1) & -n;

  // Compute the final result as a list of bytes from the hash words.
  List<int> _resultAsBytes() {
    var result = [];
    for (var i = 0; i < _h.length; i++) {
      result.addAll(_wordToBytes(_h[i]));
    }
    return result;
  }

  // Converts a list of bytes to a chunk of 32-bit words.
  void _bytesToChunk(List<int> data, int dataIndex) {
    assert((data.length - dataIndex) >= (_chunkSizeInWords * _BYTES_PER_WORD));

    for (var wordIndex = 0; wordIndex < _chunkSizeInWords; wordIndex++) {
      var w3 = _bigEndianWords ? data[dataIndex] : data[dataIndex + 3];
      var w2 = _bigEndianWords ? data[dataIndex + 1] : data[dataIndex + 2];
      var w1 = _bigEndianWords ? data[dataIndex + 2] : data[dataIndex + 1];
      var w0 = _bigEndianWords ? data[dataIndex + 3] : data[dataIndex];
      dataIndex += 4;
      var word = (w3 & 0xff) << 24;
      word |= (w2 & _MASK_8) << 16;
      word |= (w1 & _MASK_8) << 8;
      word |= (w0 & _MASK_8);
      _currentChunk[wordIndex] = word;
    }
  }

  // Convert a 32-bit word to four bytes.
  List<int> _wordToBytes(int word) {
    List<int> bytes = new List(_BYTES_PER_WORD);
    bytes[0] = (word >> (_bigEndianWords ? 24 : 0)) & _MASK_8;
    bytes[1] = (word >> (_bigEndianWords ? 16 : 8)) & _MASK_8;
    bytes[2] = (word >> (_bigEndianWords ? 8 : 16)) & _MASK_8;
    bytes[3] = (word >> (_bigEndianWords ? 0 : 24)) & _MASK_8;
    return bytes;
  }

  // Iterate through data updating the hash computation for each
  // chunk.
  void _iterate() {
    var len = _pendingData.length;
    var chunkSizeInBytes = _chunkSizeInWords * _BYTES_PER_WORD;
    if (len >= chunkSizeInBytes) {
      var index = 0;
      for (; (len - index) >= chunkSizeInBytes; index += chunkSizeInBytes) {
        _bytesToChunk(_pendingData, index);
        _updateHash(_currentChunk);
      }
      _pendingData = _pendingData.sublist(index, len);
    }
  }

  // Finalize the data. Add a 1 bit to the end of the message. Expand with
  // 0 bits and add the length of the message.
  void _finalizeData() {
    _pendingData.add(0x80);
    var contentsLength = _lengthInBytes + 9;
    var chunkSizeInBytes = _chunkSizeInWords * _BYTES_PER_WORD;
    var finalizedLength = _roundUp(contentsLength, chunkSizeInBytes);
    var zeroPadding = finalizedLength - contentsLength;
    for (var i = 0; i < zeroPadding; i++) {
      _pendingData.add(0);
    }
    var lengthInBits = _lengthInBytes * _BITS_PER_BYTE;
    assert(lengthInBits < pow(2, 32));
    if (_bigEndianWords) {
      _pendingData.addAll(_wordToBytes(0));
      _pendingData.addAll(_wordToBytes(lengthInBits & _MASK_32));
    } else {
      _pendingData.addAll(_wordToBytes(lengthInBits & _MASK_32));
      _pendingData.addAll(_wordToBytes(0));
    }
  }

  // Hasher state.
  final int _chunkSizeInWords;
  final int _digestSizeInWords;
  final bool _bigEndianWords;
  int _lengthInBytes = 0;
  List<int> _pendingData;
  final List<int> _currentChunk;
  final List<int> _h;
  bool _digestCalled = false;
}
