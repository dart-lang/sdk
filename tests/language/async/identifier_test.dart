// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' as async;
import 'lib.dart' as l; // Minimal library containing "int async;".

// Adapted from Analyzer test testing where `async` was not previously allowed.

// Helpers
void ignore(argument) {}

class GNamed {
  void g({Object? async = null}) {}
}

class AGet {
  int get async => 1;
  set async(int i) {}
}

class ACall {
  int async() => 1;
}

main() {
  // Each test declares a spearate async function, tests that `async`
  // can occur in it, and makes sure the function is run.
  {
    const int async = 0;
    f() async {
      g(@async x) {}
      g(0);
    }

    f();
  }
  {
    f(c) async {
      c.g(async: 0);
    }

    f(GNamed());
  }
  {
    f() async {
      var async = 1;
      ignore(async);
    }

    f();
  }
  {
    f() async* {
      var async = 1;
      ignore(async);
    }

    f().forEach(ignore);
  }
  {
    f() async {
      async:
      while (true) {
        break async;
      }
    }

    f();
  }
  {
    g() {}
    f() async {
      try {
        g();
      } catch (async) {}
    }

    f();
  }
  {
    g() {}
    f() async {
      try {
        g();
      } catch (e, async) {}
    }

    f();
  }
  {
    f() async {
      async:
      while (true) {
        if (false) continue async;
        break;
      }
    }

    f();
  }
  {
    var async;
    f() async {
      for (async in []) {}
    }

    f();
  }
  {
    f() async {
      g(int async) {}
      g(0);
    }

    f();
  }
  {
    f() async {
      return new AGet().async;
    }

    f();
  }
  {
    f() async {
      return new ACall().async();
    }

    f();
  }
  {
    f() async {
      return new ACall()..async();
    }

    f();
  }
  {
    g() {}
    f() async {
      async:
      g();
    }

    f();
  }
  {
    f() async {
      int async() => 0;
      async();
    }

    f();
  }
  {
    f() async {
      return async.Future.value(0);
    }

    f();
  }
  {
    f() async {
      new AGet().async = 1;
    }

    f();
  }
  {
    f() async {
      return new AGet()..async = 1;
    }

    f();
  }
  {
    int async = 1;
    f() async {
      return "$async";
    }

    f();
  }
  {
    f() async {
      return l.async;
    }

    f();
  }
  {
    f() async {
      switch (0) {
        async:
        case 0:
          break;
      }
    }

    f();
  }
  {
    f() sync* {
      var async = 1;
      ignore(async);
    }

    f();
  }
}
