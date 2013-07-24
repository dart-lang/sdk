// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.convert;

/**
 * Open-ended Encoding enum.
 */
// TODO(floitsch): dart:io already has an Encoding class. If we can't
// consolitate them, we need to remove `Encoding` here.
abstract class Encoding extends Codec<String, List<int>> {
  const Encoding();
}

// TODO(floitsch): add other encodings, like ASCII and ISO_8859_1.
