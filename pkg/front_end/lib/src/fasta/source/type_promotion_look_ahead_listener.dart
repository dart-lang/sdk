// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.type_promotion_look_ahead_listener;

import '../parser.dart' show Listener;

class TypePromotionLookAheadListener extends Listener {
  logEvent(String name) {
    print("Unhandled event: $name");
  }
}
