// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mime.magic_number;

class MagicNumber {
  final String mimeType;
  final List<int> numbers;
  final List<int> mask;

  const MagicNumber(this.mimeType, this.numbers, {this.mask});

  bool matches(List<int> header) {
    if (header.length < numbers.length) return false;

    for (int i = 0; i < numbers.length; i++) {
      if (mask != null) {
        if ((mask[i] & numbers[i]) != (mask[i] & header[i])) return false;
      } else {
        if (numbers[i] != header[i]) return false;
      }
    }

    return true;
  }

}

const int DEFAULT_MAGIC_NUMBERS_MAX_LENGTH = 12;

const List<MagicNumber> DEFAULT_MAGIC_NUMBERS = const [
  const MagicNumber('application/pdf', const [0x25, 0x50, 0x44, 0x46]),
  const MagicNumber('application/postscript', const [0x25, 0x51]),
  const MagicNumber('image/gif', const [0x47, 0x49, 0x46, 0x38, 0x37, 0x61]),
  const MagicNumber('image/gif', const [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]),
  const MagicNumber('image/jpeg', const [0xFF, 0xD8]),
  const MagicNumber('image/png',
      const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
  const MagicNumber('image/tiff', const [0x49, 0x49, 0x2A, 0x00]),
  const MagicNumber('image/tiff', const [0x4D, 0x4D, 0x00, 0x2A]),
  const MagicNumber(
      'video/mp4',
      const [0x00, 0x00, 0x00, 0x00, 0x66, 0x74,
             0x79, 0x70, 0x33, 0x67, 0x70, 0x35],
      mask: const [0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF,
                   0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
];
