// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test boxing/captures for nested closures.

/*useOne:box=(box0 which holds [b1])*/ useOne(/*boxed*/ b1) {
  /*box=(box1 which holds [b2]),free=[b1,box0]*/ () {
    var /*boxed*/ b2 = (b1 = 1);

    /*free=[b2,box1]*/ () {
      return (b2 = 2);
    };

    return b2;
  };
  return b1;
}

/*useBoth:box=(box0 which holds [b1])*/ useBoth(/*boxed*/ b1) {
  /*box=(box1 which holds [b2]),free=[b1,box0]*/ () {
    var /*boxed*/ b2 = (b1 = 1);

    /*free=[b1,b2,box0,box1]*/ () {
      return b1 + (b2 = 2);
    };

    return b2;
  };
  return b1;
}

/*useMany:box=(box0 which holds [b1,b2,b3])*/ useMany(c1, /*boxed*/ b1) {
  var /*boxed*/ b2 = 2;
  var /*boxed*/ b3 = 3;
  var c2 = 2;
  var c3 = 3;
  /*box=(box1 which holds [b4]),free=[b1,b2,b3,box0,c1,c2,c3]*/ () {
    var c4 = c1 + c2 + c3;
    var /*boxed*/ b4 = (b1 = 1) + (b2 = 2) + (b3 = 3);

    /*free=[b1,b2,b4,box0,box1,c4]*/ () {
      return c4 + (b1 = 1) + (b2 = 2) + (b4 = 4);
    };

    return b4;
  };
  return b1 + b2 + b3 + c1 + c2 + c3;
}

main() {
  useOne(1);
  useBoth(1);
  useMany(1, 2);
}
