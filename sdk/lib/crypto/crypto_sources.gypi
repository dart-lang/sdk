# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file contains all sources for the dart:crypto library.
#
# TODO(ager): crypto_base.dart should be removed when the
# VM can use the 'library' and 'part' directives for libraries.
# At that point crypto.dart should be the only crypto library file.
{
  'sources': [
    'crypto_base.dart',
    'crypto_utils.dart',
    'hash_utils.dart',
    'hmac.dart',
    'md5.dart',
    'sha1.dart',
    'sha256.dart',
  ],
}
