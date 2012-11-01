// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class _HttpSessionManager {
  /* patch */ static Uint8List _getRandomBytes(int count)
      native "Crypto_GetRandomBytes";
}
