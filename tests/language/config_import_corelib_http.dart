// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:http";

class Classy {
  String get name => "classy http";
  String httpSpecific() => "classy http";
}

bool general() => true;
bool httpSpecific() => true;
final String name = "http";
