// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

void print(Object object) {
  String line = object.toString();
  if (printToZone == null) {
    printToConsole(line);
  } else {
    printToZone(line);
  }
}
