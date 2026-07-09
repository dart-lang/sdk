// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

set noParameter() /* Error */ {}

set optionalPositionalParameter([a]) /* Error */ {
  print(a);
}

set optionalNamedParameter({a}) /* Error */ {
  print(a);
}

set multipleParameters(a, b) /* Error */ {
  print(a);
  print(b);
}

set multiplePositionalParameters(a, [b]) /* Error */ {
  print(a);
  print(b);
}

set multipleNamedParameters(a, {b}) /* Error */ {
  print(a);
  print(b);
}

class C {
  set noParameter() /* Error */ {}

  set optionalPositionalParameter([a]) /* Error */ {
    print(a);
  }

  set optionalNamedParameter({a}) /* Error */ {
    print(a);
  }

  set multipleParameters(a, b) /* Error */ {
    print(a);
    print(b);
  }

  set multiplePositionalParameters(a, [b]) /* Error */ {
    print(a);
    print(b);
  }

  set multipleNamedParameters(a, {b}) /* Error */ {
    print(a);
    print(b);
  }
}

extension E on int {
  set noParameter() /* Error */ {}

  set optionalPositionalParameter([a]) /* Error */ {
    print(a);
  }

  set optionalNamedParameter({a}) /* Error */ {
    print(a);
  }

  set multipleParameters(a, b) /* Error */ {
    print(a);
    print(b);
  }

  set multiplePositionalParameters(a, [b]) /* Error */ {
    print(a);
    print(b);
  }

  set multipleNamedParameters(a, {b}) /* Error */ {
    print(a);
    print(b);
  }
}

extension type ET(int it) {
  set noParameter() /* Error */ {}

  set optionalPositionalParameter([a]) /* Error */ {
    print(a);
  }

  set optionalNamedParameter({a}) /* Error */ {
    print(a);
  }

  set multipleParameters(a, b) /* Error */ {
    print(a);
    print(b);
  }

  set multiplePositionalParameters(a, [b]) /* Error */ {
    print(a);
    print(b);
  }

  set multipleNamedParameters(a, {b}) /* Error */ {
    print(a);
    print(b);
  }
}

