// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

/// Verify that instance calls work when receiver has a dynamically loaded
/// class but target method is from the host app and it is not exposed
/// through dynamic interface.
void main() async {
  final o = (await helper.load('entry1.dart')) as String;
  Expect.equals("Base._privateGetter", o);
  helper.done();
}
