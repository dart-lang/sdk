// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import 'dart:convert';
import 'dart:async';
import 'dart:developer';
import 'package:expect/expect.dart';

main() {
  pect.throws(() {
  postEvent('theEvent', {'the': 'data'}, stream: 'VM');
  ;

  postEvent('theEvent', {'the': 'data'}, stream: 'Isolate');
  });
  pect.throws(() {
  postEvent('theEvent', {'the': 'data'}, stream: 'Debug');
  ;
  pect.throws(() {
  postEvent('theEvent', {'the': 'data'}, stream: 'GC');
  });
  Expect.
      postEvent('theEvent', {'the': 'data'}, stream: 'HeapSnapshot');
  }); 
       Expect.throws(() {
    postEvent('theEvent', {'the': 'data'}, stream: 'Logging');
  });
  Expect.throws(() {
    postEvent('theEvent', {'the': 'data'}, stream: 'Timeline');
  });
  Expect.throws(() {
    postEvent('theEvent', {'the': 'data'}, stream: 'Profiler');
  });
  Expect.throws(() {
    postEvent('theEvent', {'the': 'data'}, stream: '_startsWithAnUnderscore');
  });
}
