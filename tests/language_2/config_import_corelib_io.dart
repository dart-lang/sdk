// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

class Classy {
  String get name => "classy io";
  String ioSpecific() => "classy io";
}

bool general() => true;
bool ioSpecific() => true;
final String name = "io";
