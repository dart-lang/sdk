// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'regress_34396_helper.dart' as helper;

main() {
  Expect.isFalse(#_privateSymbol == helper.privateSymbol);
  Expect.isFalse(#_privateSymbol == helper.privateSymbolSame);
  Expect.isFalse(identical(#_privateSymbol, helper.privateSymbol));
  Expect.isFalse(identical(#_privateSymbol, helper.privateSymbolSame));

  Expect.isTrue(helper.privateSymbol == helper.privateSymbolSame);
  Expect.isTrue(identical(helper.privateSymbol, helper.privateSymbolSame));
}
