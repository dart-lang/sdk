// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js bug http://dartbug.com/11570.

import 'package:expect/expect.dart';

void main() {
  var c = new Cool(true);
  Expect.stringEquals('{}', '${c.thing}');

  c = new Cool(false);
  Expect.stringEquals('[]', '${c.thing}');

  c = new Cool.alt(true);
  Expect.stringEquals('{}', '${c.thing}');

  c = new Cool.alt(false);
  Expect.stringEquals('[]', '${c.thing}');
}

class Cool {
  final thing;

  Cool(bool option) : thing = option ? <String, String>{} : <String>[];
  Cool.alt(bool option) : thing = !option ? <String>[] : <String, String>{};
}
