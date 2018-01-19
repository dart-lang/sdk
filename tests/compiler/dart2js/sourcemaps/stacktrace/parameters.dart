// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/dart2js.dart';

main() {
  var c = new Class();
  c. /*1:main*/ instancePositional1(0);
}

class Class {
  @noInline
  /*2:Class.instancePositional1[function-entry$1]*/ instancePositional1(a,
      [b = 42, c = 87]) {
    print('instancePositional1($a,$b,$c)');
    /*3:Class.instancePositional1*/ instancePositional2(1, 2);
  }

  @noInline
  /*4:Class.instancePositional2[function-entry$2]*/ instancePositional2(a,
      [b = 42, c = 87]) {
    print('instancePositional2($a,$b,$c)');
    /*5:Class.instancePositional2*/ instancePositional3(3, 4, 5);
  }

  @noInline
  instancePositional3(a, [b = 42, c = 87]) {
    print('instancePositional3($a,$b,$c)');
    /*6:Class.instancePositional3*/ instanceNamed1(0);
  }

  @noInline
  /*7:Class.instanceNamed1[function-entry$1]*/ instanceNamed1(a,
      {b: 42, c: 87, d: 735}) {
    print('instanceNamed1($a,b:$b,c:$c,d:$d)');
    /*8:Class.instanceNamed1*/ instanceNamed2(1, b: 2);
  }

  @noInline
  /*9:Class.instanceNamed2[function-entry$1$b]*/ instanceNamed2(a,
      {b: 42, c: 87, d: 735}) {
    print('instanceNamed2($a,b:$b,c:$c,d:$d)');
    /*10:Class.instanceNamed2*/ instanceNamed3(3, c: 123);
  }

  @noInline
  /*11:Class.instanceNamed3[function-entry$1$c]*/ instanceNamed3(a,
      {b: 42, c: 87, d: 735}) {
    print('instanceNamed3($a,b:$b,c:$c,d:$d)');
    /*12:Class.instanceNamed3*/ instanceNamed4(4, c: 45, b: 76);
  }

  @noInline
  /*13:Class.instanceNamed4[function-entry$1$b$c]*/ instanceNamed4(a,
      {b: 42, c: 87, d: 735}) {
    print('instanceNamed4($a,b:$b,c:$c,d:$d)');
    /*14:Class.instanceNamed4*/ instanceNamed5(5, c: 6, b: 7, d: 8);
  }

  @noInline
  instanceNamed5(a, {b: 42, c: 87, d: 735}) {
    print('instanceNamed5($a,b:$b,c:$c,d:$d)');
    /*18:Class.instanceNamed5[function-entry$0].local*/ local([e = 42]) {
      print('instanceNamed5.local($e)');
      /*19:Class.instanceNamed5.local*/ throw '>ExceptionMarker<';
    }

    var anonymous = /*16:Class.instanceNamed5[function-entry$0].<anonymous function>*/ (
        {f: 87}) {
      print('instanceNamed5.<anonymous(f:$f)');
      /*17:Class.instanceNamed5.<anonymous function>*/ local();
    };
    anonymous. /*15:Class.instanceNamed5*/ call();
  }
}
