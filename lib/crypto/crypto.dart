// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('crypto');

#source('sha_utils.dart');
#source('sha1.dart');
#source('sha256.dart');

/**
 * Interface for cryptographic hash functions.
 *
 * The [update] method is used to add data to the hash. The [digest] method
 * is used to extract the message digest. Once the [digest] method has been
 * called the CryptoHash object is in an invalid state and should not be
 * used again. If [digest] or [update] are called after the first call to
 * [digest] a CryptoHashException is thrown.
 */
interface CryptoHash {
  /**
   * Add a list of bytes to the hash computation.
   */
  CryptoHash update(List<int> data);

  /**
   * Finish the hash computation and extract the message digest as
   * a list of bytes.
   */
  List<int> digest();
}

/**
 * SHA1 hash function implementation.
 */
interface SHA1 extends CryptoHash default _SHA1 {
  SHA1();
}

/**
 * SHA256 hash function implementation.
 */
interface SHA256 extends CryptoHash default _SHA256 {
  SHA256();
}


/**
 * CryptoHashExceptions are thrown on invalid use of a CryptoHash
 * object.
 */
class CryptoHashException {
  CryptoHashException(String this.message);
  toString() => "CryptoHashException: $message";
  String message;
}

