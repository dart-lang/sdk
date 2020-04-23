// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// See http://dartbug.com/39406
//
// The following code must not throw.

void main() {
  var regExp = RegExp(r'\w+');
  var message = 'Hello world!';
  var match = regExp.firstMatch(message);
  var groupNames = match!.groupNames.toList();
  Expect.listEquals([], groupNames);
  Expect.throwsArgumentError(() => match.namedGroup("x"));
}