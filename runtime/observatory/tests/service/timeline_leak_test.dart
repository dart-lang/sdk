// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--timeline-recorder=ring --timeline-streams=Dart

import 'dart:developer';

main() {
  for (var i = 0; i < 100000; i++) {
    // OneByteString, ASCII
    Timeline.startSync('ASCII', arguments: {'arg': 'ASCII'});
    Timeline.finishSync();

    // OneByteString, Latin1
    Timeline.startSync('blåbærgrød', arguments: {'arg': 'blåbærgrød'});
    Timeline.finishSync();

    // TwoByteString
    Timeline.startSync('Îñţérñåţîöñåļîžåţîờñ',
        arguments: {'arg': 'Îñţérñåţîöñåļîžåţîờñ'});
    Timeline.finishSync();
  }
}
