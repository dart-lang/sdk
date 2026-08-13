// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

typedef Marker = ({String label, int value});

Marker? makeMarker(bool enabled) {
  if (!enabled) return null;
  return (label: 'marker', value: 3);
}

class MarkerPainter {
  final Marker marker;

  const MarkerPainter({required this.marker});

  String paint() => '${marker.label}:${marker.value}';
}

String render(bool showMarker) {
  final marker = makeMarker(showMarker);
  if (marker == null) return 'nothing';
  return MarkerPainter(marker: marker).paint();
}

void main() {
  Expect.equals(render(false), 'nothing');
  Expect.equals(render(true), 'marker:3');
}
