// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Redirecting factories are encoded using static fields that need to be
// handled by the class hierarchy builder.

class Class {
  factory Class.redirect() = Class;

  Class();
}

main() {}
