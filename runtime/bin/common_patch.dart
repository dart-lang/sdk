// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:nativewrappers';

@patch class _IOCrypto {
  @patch static Uint8List getRandomBytes(int count)
      native "Crypto_GetRandomBytes";
}

_setupHooks() {
  VMLibraryHooks.eventHandlerSendData = _EventHandler._sendData;
  VMLibraryHooks.timerMillisecondClock = _EventHandler._timerMillisecondClock;
}
