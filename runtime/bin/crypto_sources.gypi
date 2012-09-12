# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file contains all sources for the dart:crypto library.
#
# TODO(ager): ../lib/crypto/crypto_vm.dart should be removed when the
# VM can use the #source directive for libraries.  At that point
# ../../lib/crypto/crypto.dart should be the only crypto library file.
{
  'sources': [
    '../lib/crypto/crypto_vm.dart',
    '../../lib/crypto/crypto_utils.dart',
    '../../lib/crypto/hash_utils.dart',
    '../../lib/crypto/hmac.dart',
    '../../lib/crypto/md5.dart',
    '../../lib/crypto/sha1.dart',
    '../../lib/crypto/sha256.dart',
  ],
}
