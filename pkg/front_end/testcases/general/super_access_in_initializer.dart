// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  bool get property => true;

  Super(bool value);
}

class Class extends Super {
  bool field;

  Class(bool value)
      : assert(property),
        this.field = property,
        super(property);

  Class.redirect() : this(property);
}

main() {}
