// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'private_access_lib.dart';
import 'private_access_lib.dart' as private;

main() {
  Expect.throws(() => _function(),                      /// 01: static type warning
                (e) => e is NoSuchMethodError);         /// 01: continued
  Expect.throws(() => private._function(),              /// 02: static type warning
                (e) => e is NoSuchMethodError);         /// 02: continued
  Expect.throws(() => new _Class());                    /// 03: static type warning
  Expect.throws(() => new private._Class());            /// 04: static type warning
  Expect.throws(() => new Class._constructor(),         /// 05: static type warning
                (e) => e is NoSuchMethodError);         /// 05: continued
  Expect.throws(() => new private.Class._constructor(), /// 06: static type warning
                (e) => e is NoSuchMethodError);         /// 06: continued
}