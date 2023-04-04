// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

sealed class A {}

class B extends A {}

class C extends A {}

exhaustiveBoolByValue(FutureOr<bool> f) {
  /*
   checkingOrder={FutureOr<bool>,bool,Future<bool>,true,false},
   expandedSubtypes={true,false,Future<bool>},
   subtypes={bool,Future<bool>},
   type=FutureOr<bool>
  */
  switch (f) {
    /*space=true*/
    case true:
      print('true');
      break;
    /*space=false*/
    case false:
      print('false');
      break;
    /*space=Future<bool>*/
    case Future<bool>():
      print('Future');
      break;
  }
  var a = /*
   checkingOrder={FutureOr<bool>,bool,Future<bool>,true,false},
   expandedSubtypes={true,false,Future<bool>},
   subtypes={bool,Future<bool>},
   type=FutureOr<bool>
  */
      switch (f) {
    true /*space=true*/ => 0,
    false /*space=false*/ => 1,
    Future<bool>() /*space=Future<bool>*/ => 2
  };
}

exhaustiveBoolByType(FutureOr<bool> f) {
  /*
   checkingOrder={FutureOr<bool>,bool,Future<bool>,true,false},
   expandedSubtypes={true,false,Future<bool>},
   subtypes={bool,Future<bool>},
   type=FutureOr<bool>
  */
  switch (f) {
    /*space=bool*/
    case bool():
      print('bool');
      break;
    /*space=Future<bool>*/
    case Future<bool>():
      print('Future');
      break;
  }
  /*
   checkingOrder={FutureOr<bool>,bool,Future<bool>,true,false},
   expandedSubtypes={true,false,Future<bool>},
   subtypes={bool,Future<bool>},
   type=FutureOr<bool>
  */
  switch (f) {
    /*space=bool*/
    case bool():
      print('bool');
      break;
    /*space=Future<bool>*/
    case Future():
      print('Future');
      break;
  }
  var a = /*
   checkingOrder={FutureOr<bool>,bool,Future<bool>,true,false},
   expandedSubtypes={true,false,Future<bool>},
   subtypes={bool,Future<bool>},
   type=FutureOr<bool>
  */
      switch (f) {
    bool() /*space=bool*/ => 0,
    Future<bool>() /*space=Future<bool>*/ => 1
  };
}

nonExhaustiveBool(FutureOr<bool> f) {
  /*
   checkingOrder={FutureOr<bool>,bool,Future<bool>,true,false},
   error=non-exhaustive:Future<bool>(),
   expandedSubtypes={true,false,Future<bool>},
   subtypes={bool,Future<bool>},
   type=FutureOr<bool>
  */
  switch (f) {
    /*space=true*/
    case true:
      print('true');
      break;
    /*space=false*/
    case false:
      print('false');
      break;
  }
  /*
   checkingOrder={FutureOr<bool>,bool,Future<bool>,true,false},
   error=non-exhaustive:false,
   expandedSubtypes={true,false,Future<bool>},
   subtypes={bool,Future<bool>},
   type=FutureOr<bool>
  */
  switch (f) {
    /*space=true*/
    case true:
      print('true');
      break;
    /*space=Future<bool>*/
    case Future<bool>():
      print('Future');
      break;
  }
  /*
   checkingOrder={FutureOr<bool>,bool,Future<bool>,true,false},
   error=non-exhaustive:true,
   expandedSubtypes={true,false,Future<bool>},
   subtypes={bool,Future<bool>},
   type=FutureOr<bool>
  */
  switch (f) {
    /*space=false*/
    case false:
      print('false');
      break;
    /*space=Future<bool>*/
    case Future<bool>():
      print('Future');
      break;
  }
  /*
   checkingOrder={FutureOr<bool>,bool,Future<bool>,true,false},
   error=non-exhaustive:Future<bool>(),
   expandedSubtypes={true,false,Future<bool>},
   subtypes={bool,Future<bool>},
   type=FutureOr<bool>
  */
  switch (f) {
    /*space=true*/
    case true:
      print('true');
      break;
    /*space=false*/
    case false:
      print('false');
      break;
    /*space=Future<A>*/
    case Future<A>():
      print('Future<A>');
      break;
  }
  var a = /*
   checkingOrder={FutureOr<bool>,bool,Future<bool>,true,false},
   error=non-exhaustive:Future<bool>(),
   expandedSubtypes={true,false,Future<bool>},
   subtypes={bool,Future<bool>},
   type=FutureOr<bool>
  */
      switch (f) {
    true /*space=true*/ => 0,
    false /*space=false*/ => 1,
  };
  var b = /*
   checkingOrder={FutureOr<bool>,bool,Future<bool>,true,false},
   error=non-exhaustive:false,
   expandedSubtypes={true,false,Future<bool>},
   subtypes={bool,Future<bool>},
   type=FutureOr<bool>
  */
      switch (f) {
    true /*space=true*/ => 0,
    Future<bool>() /*space=Future<bool>*/ => 2
  };
  var c = /*
   checkingOrder={FutureOr<bool>,bool,Future<bool>,true,false},
   error=non-exhaustive:true,
   expandedSubtypes={true,false,Future<bool>},
   subtypes={bool,Future<bool>},
   type=FutureOr<bool>
  */
      switch (f) {
    false /*space=false*/ => 1,
    Future<bool>() /*space=Future<bool>*/ => 2
  };
  var d = /*
   checkingOrder={FutureOr<bool>,bool,Future<bool>,true,false},
   error=non-exhaustive:Future<bool>(),
   expandedSubtypes={true,false,Future<bool>},
   subtypes={bool,Future<bool>},
   type=FutureOr<bool>
  */
      switch (f) {
    true /*space=true*/ => 0,
    false /*space=false*/ => 1,
    Future<A>() /*space=Future<A>*/ => 2,
  };
}

exhaustiveSealedBySubtype(FutureOr<A> f) {
  /*
   checkingOrder={FutureOr<A>,A,Future<A>,B,C},
   expandedSubtypes={B,C,Future<A>},
   subtypes={A,Future<A>},
   type=FutureOr<A>
  */
  switch (f) {
    /*space=B*/
    case B():
      print('B');
      break;
    /*space=C*/
    case C():
      print('C');
      break;
    /*space=Future<A>*/
    case Future<A>():
      print('Future');
      break;
  }
  var a = /*
   checkingOrder={FutureOr<A>,A,Future<A>,B,C},
   expandedSubtypes={B,C,Future<A>},
   subtypes={A,Future<A>},
   type=FutureOr<A>
  */
      switch (f) {
    B() /*space=B*/ => 0,
    C() /*space=C*/ => 1,
    Future<A>() /*space=Future<A>*/ => 2
  };
}

exhaustiveSealedByType(FutureOr<A> f) {
  /*
   checkingOrder={FutureOr<A>,A,Future<A>,B,C},
   expandedSubtypes={B,C,Future<A>},
   subtypes={A,Future<A>},
   type=FutureOr<A>
  */
  switch (f) {
    /*space=A*/
    case A():
      print('A');
      break;
    /*space=Future<A>*/
    case Future<A>():
      print('Future');
      break;
  }
  var a = /*
   checkingOrder={FutureOr<A>,A,Future<A>,B,C},
   expandedSubtypes={B,C,Future<A>},
   subtypes={A,Future<A>},
   type=FutureOr<A>
  */
      switch (f) {
    A() /*space=A*/ => 0,
    Future<A>() /*space=Future<A>*/ => 1
  };
}

nonExhaustiveSealed(FutureOr<A> f) {
  /*
   checkingOrder={FutureOr<A>,A,Future<A>,B,C},
   error=non-exhaustive:Future<A>(),
   expandedSubtypes={B,C,Future<A>},
   subtypes={A,Future<A>},
   type=FutureOr<A>
  */
  switch (f) {
    /*space=B*/
    case B():
      print('B');
      break;
    /*space=C*/
    case C():
      print('C');
      break;
  }
  /*
   checkingOrder={FutureOr<A>,A,Future<A>,B,C},
   error=non-exhaustive:C(),
   expandedSubtypes={B,C,Future<A>},
   subtypes={A,Future<A>},
   type=FutureOr<A>
  */
  switch (f) {
    /*space=B*/
    case B():
      print('true');
      break;
    /*space=Future<A>*/
    case Future<A>():
      print('Future');
      break;
  }
  /*
   checkingOrder={FutureOr<A>,A,Future<A>,B,C},
   error=non-exhaustive:B(),
   expandedSubtypes={B,C,Future<A>},
   subtypes={A,Future<A>},
   type=FutureOr<A>
  */
  switch (f) {
    /*space=C*/
    case C():
      print('C');
      break;
    /*space=Future<A>*/
    case Future<A>():
      print('Future');
      break;
  }
  /*
   checkingOrder={FutureOr<A>,A,Future<A>,B,C},
   error=non-exhaustive:Future<A>(),
   expandedSubtypes={B,C,Future<A>},
   subtypes={A,Future<A>},
   type=FutureOr<A>
  */
  switch (f) {
    /*space=B*/ case B():
      print('B');
      break;
    /*space=C*/ case C():
      print('C');
      break;
    /*space=Future<B>*/ case Future<B>():
      print('Future<B>');
      break;
    /*
     error=unreachable,
     space=Future<B>
    */
    case Future<B>():
      print('Future<C>');
      break;
  }

  var a = /*
   checkingOrder={FutureOr<A>,A,Future<A>,B,C},
   error=non-exhaustive:Future<A>(),
   expandedSubtypes={B,C,Future<A>},
   subtypes={A,Future<A>},
   type=FutureOr<A>
  */
      switch (f) {
    B() /*space=B*/ => 0,
    C() /*space=C*/ => 1,
  };
  var b = /*
   checkingOrder={FutureOr<A>,A,Future<A>,B,C},
   error=non-exhaustive:C(),
   expandedSubtypes={B,C,Future<A>},
   subtypes={A,Future<A>},
   type=FutureOr<A>
  */
      switch (f) {
    B() /*space=B*/ => 0,
    Future<A>() /*space=Future<A>*/ => 2
  };
  var c = /*
   checkingOrder={FutureOr<A>,A,Future<A>,B,C},
   error=non-exhaustive:B(),
   expandedSubtypes={B,C,Future<A>},
   subtypes={A,Future<A>},
   type=FutureOr<A>
  */
      switch (f) {
    C() /*space=C*/ => 1,
    Future<A>() /*space=Future<A>*/ => 2
  };
}

exhaustiveRegular(FutureOr<int> f) {
  var a = /*
   checkingOrder={FutureOr<int>,int,Future<int>},
   subtypes={int,Future<int>},
   type=FutureOr<int>
  */
      switch (f) {
    int() /*space=int*/ => 0,
    Future<int>() /*space=Future<int>*/ => 1
  };
}

nonExhaustiveRegular(FutureOr<int> f) {
  var a = /*
   checkingOrder={FutureOr<int>,int,Future<int>},
   error=non-exhaustive:Future<int>(),
   subtypes={int,Future<int>},
   type=FutureOr<int>
  */
      switch (f) {
    int() /*space=int*/ => 0,
    Future<String>() /*space=Future<String>*/ => 1
  };
  var b = /*
   checkingOrder={FutureOr<int>,int,Future<int>},
   error=non-exhaustive:int(),
   subtypes={int,Future<int>},
   type=FutureOr<int>
  */
      switch (f) {
    String() /*space=String*/ => 0,
    Future<int>() /*space=Future<int>*/ => 1
  };
}

exhaustiveNullable(
    FutureOr<bool>? f1, FutureOr<bool?> f2, FutureOr<bool?>? f3) {
  /*
   checkingOrder={FutureOr<bool>?,FutureOr<bool>,Null,bool,Future<bool>,true,false},
   expandedSubtypes={true,false,Future<bool>,Null},
   subtypes={FutureOr<bool>,Null},
   type=FutureOr<bool>?
  */
  switch (f1) {
    /*space=true*/
    case true:
      print('true');
      break;
    /*space=false*/
    case false:
      print('false');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
    /*space=Future<bool>*/
    case Future<bool>():
      print('Future');
      break;
  }
  /*
   checkingOrder={FutureOr<bool?>,bool?,Future<bool?>,bool,Null,true,false},
   expandedSubtypes={true,false,Null,Future<bool?>},
   subtypes={bool?,Future<bool?>},
   type=FutureOr<bool?>
  */
  switch (f2) {
    /*space=true*/
    case true:
      print('true');
      break;
    /*space=false*/
    case false:
      print('false');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
    /*space=Future<bool?>*/
    case Future<bool?>():
      print('Future');
      break;
  }
  /*
   checkingOrder={FutureOr<bool?>,FutureOr<bool?>,Null,bool?,Future<bool?>,bool,Null,true,false},
   expandedSubtypes={true,false,Null,Future<bool?>},
   subtypes={FutureOr<bool?>,Null},
   type=FutureOr<bool?>
  */
  switch (f3) {
    /*space=true*/
    case true:
      print('true');
      break;
    /*space=false*/
    case false:
      print('false');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
    /*space=Future<bool?>*/
    case Future<bool?>():
      print('Future');
      break;
  }
}

nonExhaustiveNullable(
    FutureOr<bool>? f1, FutureOr<bool?> f2, FutureOr<bool?>? f3) {
  /*
   checkingOrder={FutureOr<bool>?,FutureOr<bool>,Null,bool,Future<bool>,true,false},
   error=non-exhaustive:null,
   expandedSubtypes={true,false,Future<bool>,Null},
   subtypes={FutureOr<bool>,Null},
   type=FutureOr<bool>?
  */
  switch (f1) {
    /*space=true*/
    case true:
      print('true');
      break;
    /*space=false*/
    case false:
      print('false');
      break;
    /*space=Future<bool>*/
    case Future<bool>():
      print('Future');
      break;
  }
  /*
   checkingOrder={FutureOr<bool?>,bool?,Future<bool?>,bool,Null,true,false},
   error=non-exhaustive:null,
   expandedSubtypes={true,false,Null,Future<bool?>},
   subtypes={bool?,Future<bool?>},
   type=FutureOr<bool?>
  */
  switch (f2) {
    /*space=true*/
    case true:
      print('true');
      break;
    /*space=false*/
    case false:
      print('false');
      break;
    /*space=Future<bool?>*/
    case Future<bool?>():
      print('Future');
      break;
  }
  /*
   checkingOrder={FutureOr<bool?>,bool?,Future<bool?>,bool,Null,true,false},
   error=non-exhaustive:Future<bool?>(),
   expandedSubtypes={true,false,Null,Future<bool?>},
   subtypes={bool?,Future<bool?>},
   type=FutureOr<bool?>
  */
  switch (f2) {
    /*space=true*/
    case true:
      print('true');
      break;
    /*space=false*/
    case false:
      print('false');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
    /*space=Future<bool>*/
    case Future<bool>():
      print('Future');
      break;
  }
  /*
   checkingOrder={FutureOr<bool?>,FutureOr<bool?>,Null,bool?,Future<bool?>,bool,Null,true,false},
   error=non-exhaustive:null,
   expandedSubtypes={true,false,Null,Future<bool?>},
   subtypes={FutureOr<bool?>,Null},
   type=FutureOr<bool?>
  */
  switch (f3) {
    /*space=true*/
    case true:
      print('true');
      break;
    /*space=false*/
    case false:
      print('false');
      break;
    /*space=Future<bool?>*/
    case Future<bool?>():
      print('Future');
      break;
  }
  /*
   checkingOrder={FutureOr<bool?>,FutureOr<bool?>,Null,bool?,Future<bool?>,bool,Null,true,false},
   error=non-exhaustive:Future<bool?>(),
   expandedSubtypes={true,false,Null,Future<bool?>},
   subtypes={FutureOr<bool?>,Null},
   type=FutureOr<bool?>
  */
  switch (f3) {
    /*space=true*/
    case true:
      print('true');
      break;
    /*space=false*/
    case false:
      print('false');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
    /*space=Future<bool>*/
    case Future<bool>():
      print('Future');
      break;
  }
}
