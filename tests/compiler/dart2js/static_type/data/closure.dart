// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  Class next;
}

main() {
  closure1(null);
  closure2(null);
  closure3(null);
  closure4(null);
  closure5(null);
}

closure1(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    local() {
      /*dynamic*/ c.next;
      if (/*dynamic*/ c is Class) {
        /*Class*/ c.next;
      }
      c = 0;
    }

    /*dynamic*/ c.next;
    /*invoke: Null*/ local();
    /*dynamic*/ c.next;
  }
}

closure2(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    local() {
      /*Class*/ c.next;
    }

    /*Class*/ c.next;
    /*invoke: Null*/ local();
    /*Class*/ c.next;
  }
}

closure3(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    local() {
      /*dynamic*/ c.next;
    }

    c = 0;
    /*dynamic*/ c.next;
    /*invoke: Null*/ local();
    /*dynamic*/ c.next;
  }
}

closure4(dynamic c) {
  if (/*dynamic*/ c is Class) {
    /*Class*/ c.next;
    local() {
      /*dynamic*/ c.next;
    }

    /*dynamic*/ c.next;
    /*invoke: Null*/ local();
    /*dynamic*/ c.next;
    c = 0;
    /*dynamic*/ c.next;
  }
}

closure5(dynamic c) {
  /*dynamic*/ c.next;
  local() {
    /*dynamic*/ c.next;
    if (/*dynamic*/ c is! Class) return;
    /*Class*/ c.next;
  }

  /*dynamic*/ c.next;
  /*invoke: Null*/ local();
  /*dynamic*/ c.next;
  c = 0;
  /*dynamic*/ c.next;
}
