// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:math' as math;

class Trace {
  List<Frame> frames = [];
}

class Frame {
  String location = '';
}

main() {
  List<Trace> traces = [];
  var longest = traces
      .map((trace) {
        return trace.frames
            .map((frame) => frame.location.length)
            .fold(0, math.max);
      })
      .fold(0, math.max);
}
