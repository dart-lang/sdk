// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.crypto;

import 'dart:math';

part 'crypto_utils.dart';
part 'hash_utils.dart';
part 'hmac.dart';
part 'md5.dart';
part 'sha1.dart';
part 'sha256.dart';

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
// TODO(floitsch): make Hash implement Sink, StreamSink or similar.
abstract class Hash {
  /**
   * Add a list of bytes to the hash computation.
   */
  add(List<int> data);

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
 * SHA1 hash function implementation.
 */
abstract class SHA1 implements Hash {
  factory SHA1() => new _SHA1();
}

/**
 * SHA256 hash function implementation.
 */
abstract class SHA256 implements Hash {
  factory SHA256() => new _SHA256();
}

/**
 * MD5 hash function implementation.
 *
 * WARNING: MD5 has known collisions and should only be used when
 * required for backwards compatibility.
 */
abstract class MD5 implements Hash {
  factory MD5() => new _MD5();
}

/**
 * Hash-based Message Authentication Code support.
 *
 * The [add] method is used to add data to the message. The [digest] and
 * [close] methods are used to extract the message authentication code.
 */
// TODO(floitsch): make Hash implement Sink, StreamSink or similar.
abstract class HMAC {
  /**
   * Create an [HMAC] object from a [Hash] and a key.
   */
  factory HMAC(Hash hash, List<int> key) => new _HMAC(hash, key);

  /**
   * Add a list of bytes to the message.
   */
  add(List<int> data);

  /**
   * Perform the actual computation and extract the message digest
   * as a list of bytes.
   */
  List<int> close();

  /**
   * Extract the message digest as a list of bytes without closing [this].
   */
  List<int> get digest;

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
  bool verify(List<int> digest);
}

/**
 * Utility methods for working with message digests.
 */
abstract class CryptoUtils {
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

