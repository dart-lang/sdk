// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

exhaustiveBoundedTypeVariableByValue<T extends bool>(T x1, T x2) {
  /*
   checkingOrder={bool,true,false},
   subtypes={true,false},
   type=bool
  */
  switch (x1) {
    /*space=true*/
    case true:
    /*space=false*/
    case false:
      break;
  }
  return /*
   checkingOrder={bool,true,false},
   subtypes={true,false},
   type=bool
  */
      switch (x2) {
    true /*space=true*/ => 0,
    false /*space=false*/ => 1,
  };
}

exhaustiveBoundedTypeVariableByType<T extends bool>(T x1, T x2) {
  /*
   checkingOrder={bool,true,false},
   subtypes={true,false},
   type=bool
  */
  switch (x1) {
    /*space=bool*/
    case T():
      break;
  }
  return /*
   checkingOrder={bool,true,false},
   subtypes={true,false},
   type=bool
  */
      switch (x2) {
    T() /*space=bool*/ => 0,
  };
}

nonExhaustiveBoundedTypeVariable<T extends bool>(T x1, T x2) {
  /*
   checkingOrder={bool,true,false},
   error=non-exhaustive:false,
   subtypes={true,false},
   type=bool
  */
  switch (x1) {
    /*space=true*/
    case true:
      break;
  }
  return /*
   checkingOrder={bool,true,false},
   error=non-exhaustive:false,
   subtypes={true,false},
   type=bool
  */
      switch (x2) {
    true /*space=true*/ => 0,
  };
}

exhaustiveBoundedTypeVariableByBound<T extends bool>(T x1, T x2) {
  /*
   checkingOrder={bool,true,false},
   subtypes={true,false},
   type=bool
  */
  switch (x1) {
    /*space=bool*/
    case bool():
      break;
  }
  return /*
   checkingOrder={bool,true,false},
   subtypes={true,false},
   type=bool
  */
      switch (x2) {
    bool() /*space=bool*/ => 0,
  };
}

nonExhaustiveBoundedTypeVariableByOtherType<T extends bool, S extends bool>(
    T x1, T x2) {
  /*
   checkingOrder={bool,true,false},
   error=non-exhaustive:true;false,
   subtypes={true,false},
   type=bool
  */
  switch (x1) {
    /*space=bool*/
    case S():
      break;
  }
  return /*
   checkingOrder={bool,true,false},
   error=non-exhaustive:true;false,
   subtypes={true,false},
   type=bool
  */
      switch (x2) {
    S() /*space=bool*/ => 0,
  };
}

exhaustivePromotedTypeVariableByValue<T>(T x1, T x2) {
  if (x1 is bool) {
    /*
     checkingOrder={bool,true,false},
     subtypes={true,false},
     type=bool
    */
    switch (x1) {
      /*space=true*/
      case true:
      /*space=false*/
      case false:
        break;
    }
  }
  if (x2 is bool) {
    var a = /*
     checkingOrder={bool,true,false},
     subtypes={true,false},
     type=bool
    */
        switch (x2) {
      true /*space=true*/ => 0,
      false /*space=false*/ => 1,
    };
  }
}

exhaustivePromotedTypeVariableByType<T>(T x1, T x2) {
  if (x1 is bool) {
    /*
     checkingOrder={bool,true,false},
     subtypes={true,false},
     type=bool
    */
    switch (x1) {
      /*space=bool*/
      case T():
        break;
    }
  }
  if (x2 is bool) {
    var a = /*
     checkingOrder={bool,true,false},
     subtypes={true,false},
     type=bool
    */
        switch (x2) {
      T() /*space=bool*/ => 0,
    };
  }
}

nonExhaustivePromotedTypeVariable<T>(T x1, T x2) {
  if (x1 is bool) {
    /*
     checkingOrder={bool,true,false},
     error=non-exhaustive:false,
     subtypes={true,false},
     type=bool
    */
    switch (x1) {
      /*space=true*/
      case true:
        break;
    }
  }
  if (x2 is bool) {
    var a = /*
     checkingOrder={bool,true,false},
     error=non-exhaustive:false,
     subtypes={true,false},
     type=bool
    */
        switch (x2) {
      true /*space=true*/ => 0,
    };
  }
}

exhaustivePromotedTypeVariableByBound<T>(T x1, T x2) {
  if (x1 is bool) {
    /*
     checkingOrder={bool,true,false},
     subtypes={true,false},
     type=bool
    */
    switch (x1) {
      /*space=bool*/
      case bool():
        break;
    }
  }
  if (x2 is bool) {
    var a = /*
     checkingOrder={bool,true,false},
     subtypes={true,false},
     type=bool
    */
        switch (x2) {
      bool() /*space=bool*/ => 0,
    };
  }
}

nonExhaustivePromotedTypeVariableByOtherType<T, S extends bool>(T x1, T x2) {
  if (x1 is bool) {
    /*
     checkingOrder={bool,true,false},
     error=non-exhaustive:true;false,
     subtypes={true,false},
     type=bool
    */
    switch (x1) {
      /*space=bool*/
      case S():
        break;
    }
  }
  if (x2 is bool) {
    var a = /*
     checkingOrder={bool,true,false},
     error=non-exhaustive:true;false,
     subtypes={true,false},
     type=bool
    */
        switch (x2) {
      S() /*space=bool*/ => 0,
    };
  }
}
