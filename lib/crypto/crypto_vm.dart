// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(ager, iposva): Get rid of this file when the VM snapshot
// generation can deal with normal library structure.

#library('crypto');

#import('dart:math');

/**
 * Interface for cryptographic hash functions.
 *
 * The [update] method is used to add data to the hash. The [digest] method
 * is used to extract the message digest.
 *
 * Once the [digest] method has been called no more data can be added using the
 * [update] method. If [update] is called after the first call to [digest] a
 * HashException is thrown.
 *
 * If multiple instances of a given Hash is needed the [newInstance]
 * method can provide a new instance.
 */
interface Hash {
  /**
   * Add a list of bytes to the hash computation.
   */
  Hash update(List<int> data);

  /**
   * Finish the hash computation and extract the message digest as
   * a list of bytes.
   */
  List<int> digest();

  /**
   * Returns a new instance of this hash function.
   */
  Hash newInstance();

  /**
   * Block size of the hash in bytes.
   */
  int get blockSize();
}

/**
 * SHA1 hash function implementation.
 */
interface SHA1 extends Hash default _SHA1 {
  SHA1();
}

/**
 * SHA256 hash function implementation.
 */
interface SHA256 extends Hash default _SHA256 {
  SHA256();
}

/**
 * MD5 hash function implementation.
 *
 * WARNING: MD5 has known collisions and should only be used when
 * required for backwards compatibility.
 */
interface MD5 extends Hash default _MD5 {
  MD5();
}

/**
 * Hash-based Message Authentication Code support.
 *
 * The [update] method is used to add data to the message. The [digest] method
 * is used to extract the message authentication code.
 */
interface HMAC default _HMAC {
  /**
   * Create an [HMAC] object from a [Hash] and a key.
   */
  HMAC(Hash hash, List<int> key);

  /**
   * Add a list of bytes to the message.
   */
  HMAC update(List<int> data);

  /**
   * Perform the actual computation and extract the message digest
   * as a list of bytes.
   */
  List<int> digest();
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
   * Converts a list of bytes (for example a message digest) into a
   * base64 encoded string optionally broken up in to lines of
   * [lineLength] chars separated by '\r\n'.
   */
  static String bytesToBase64(List<int> bytes, [int lineLength]) {
    return _CryptoUtils.bytesToBase64(bytes, lineLength);
  }
}

/**
 * HashExceptions are thrown on invalid use of a Hash
 * object.
 */
class HashException {
  HashException(String this.message);
  toString() => "HashException: $message";
  String message;
}

