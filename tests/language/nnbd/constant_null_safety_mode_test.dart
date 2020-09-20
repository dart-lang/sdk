// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  const trueInWeakMode = <Null>[] is List<int>;
  Expect.equals(isWeakMode, trueInWeakMode);

  // The following tests use the Uri.pathSegments() to access a constant list
  // that is defined in the SDK and verify the type associated with it does not
  // allow null when running with sound null safety.
  var emptyUri = Uri(pathSegments: []);
  dynamic stringList = emptyUri.pathSegments.toList();
  if (isStrongMode) {
    Expect.throwsTypeError(() {
      stringList.add(null);
    });
  } else {
    stringList.add(null);
    Expect.listEquals([null], stringList);
  }
}
