// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Cryptographic algorithms, with support for hash functions such as
 * SHA-1, SHA-256, HMAC, and MD5.
 */
library crypto;

import 'dart:math';

part 'src/crypto_utils.dart';
part 'src/hash_utils.dart';
part 'src/hmac.dart';
part 'src/md5.dart';
part 'src/sha1.dart';
part 'src/sha256.dart';

/**
 * Interface for cryptographic hash functions.
 *
 * The [add] method is used to add data to the hash. The [close] method
 * is used to extract the message digest.
 *
 * Once the [close] method has been called no more data can be added using the
 * [add] method. If [add] is called after the first call to [close] a
 * HashException is thrown.
 *
 * If multiple instances of a given Hash is needed the [newInstance]
 * method can provide a new instance.
 */
// TODO(floitsch): make Hash implement Sink, EventSink or similar.
abstract class Hash {
  /**
   * Add a list of bytes to the hash computation.
   */
  void add(List<int> data);

  /**
   * Finish the hash computation and extract the message digest as
   * a list of bytes.
   */
  List<int> close();

  /**
   * Returns a new instance of this hash function.
   */
  Hash newInstance();

  /**
   * Internal block size of the hash in bytes.
   *
   * This is exposed for use by the HMAC class which needs to know the
   * block size for the [Hash] it is using.
   */
  int get blockSize;
}

/**
 * Utility methods for working with message digests.
 */
class CryptoUtils {
  /**
   * Convert a list of bytes (for example a message digest) into a hex
   * string.
   */
  static String bytesToHex(List<int> bytes) {
    return _CryptoUtils.bytesToHex(bytes);
  }

  /**
   * Converts a list of bytes into a Base 64 encoded string.
   *
   * The list can be any list of integers in the range 0..255,
   * for example a message digest.
   *
   * If [addLineSeparator] is true, the resulting string will  be
   * broken into lines of 76 characters, separated by "\r\n".
   *
   * If [urlSafe] is true, the result is URL and filename safe.
   *
   * Based on [RFC 4648](http://tools.ietf.org/html/rfc4648)
   *
   */
  static String bytesToBase64(List<int> bytes,
                              {bool urlSafe : false,
                               bool addLineSeparator : false}) {
    return _CryptoUtils.bytesToBase64(bytes,
                                      urlSafe,
                                      addLineSeparator);
  }


  /**
   * Converts a Base 64 encoded String into list of bytes.
   *
   * Decoder ignores "\r\n" sequences from input.
   *
   * Accepts both URL safe and unsafe Base 64 encoded strings.
   *
   * Throws a FormatException exception if input contains invalid characters.
   *
   * Based on [RFC 4648](http://tools.ietf.org/html/rfc4648)
   */
  static List<int> base64StringToBytes(String input) {
    return _CryptoUtils.base64StringToBytes(input);
  }
}
