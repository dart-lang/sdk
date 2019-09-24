// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int field;
}

extension Extension on Class {
  int get property => field;
}

main() {
  Class c;
  c?.property ?? 0;
  // TODO(johnniwinther): Handle null-aware explicit extension access.
  // Extension(c)?.property ?? 0;
  c = new Class();
  c.property ?? 0;
  Extension(c).property ?? 0;
}