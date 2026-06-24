// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

via_await(int? i, int? j) {
  compute() async {
    if (i == null) return;
    /*demoteViaSuspension*/
    await null;
    i. /*notPromoted(demoteViaSuspension)*/ isEven;
  }

  i = j;
}

via_yield(int? i, int? j) {
  compute() async* {
    if (i == null) return;
    /*demoteViaSuspension*/
    yield 0;
    i. /*notPromoted(demoteViaSuspension)*/ isEven;
  }

  i = j;
}
