// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  var c = new Class();
  c. /*1:main*/ instancePositional1(0);
}

class Class {
  @pragma('dart2js:noInline')
  instancePositional1(a, [b = 42, c = 87]) {
    print('instancePositional1($a,$b,$c)');
    /*2:Class.instancePositional1*/ instancePositional2(1, 2);
  }

  @pragma('dart2js:noInline')
  instancePositional2(a, [b = 42, c = 87]) {
    print('instancePositional2($a,$b,$c)');
    /*3:Class.instancePositional2*/ instancePositional3(3, 4, 5);
  }

  @pragma('dart2js:noInline')
  instancePositional3(a, [b = 42, c = 87]) {
    print('instancePositional3($a,$b,$c)');
    /*4:Class.instancePositional3*/ instanceNamed1(0);
  }

  @pragma('dart2js:noInline')
  instanceNamed1(a, {b: 42, c: 87, d: 735}) {
    print('instanceNamed1($a,b:$b,c:$c,d:$d)');
    /*5:Class.instanceNamed1*/ instanceNamed2(1, b: 2);
  }

  @pragma('dart2js:noInline')
  instanceNamed2(a, {b: 42, c: 87, d: 735}) {
    print('instanceNamed2($a,b:$b,c:$c,d:$d)');
    /*6:Class.instanceNamed2*/ instanceNamed3(3, c: 123);
  }

  @pragma('dart2js:noInline')
  instanceNamed3(a, {b: 42, c: 87, d: 735}) {
    print('instanceNamed3($a,b:$b,c:$c,d:$d)');
    /*7:Class.instanceNamed3*/ instanceNamed4(4, c: 45, b: 76);
  }

  @pragma('dart2js:noInline')
  instanceNamed4(a, {b: 42, c: 87, d: 735}) {
    print('instanceNamed4($a,b:$b,c:$c,d:$d)');
    /*8:Class.instanceNamed4*/ instanceNamed5(5, c: 6, b: 7, d: 8);
  }

  @pragma('dart2js:noInline')
  instanceNamed5(a, {b: 42, c: 87, d: 735}) {
    print('instanceNamed5($a,b:$b,c:$c,d:$d)');
    /*12:Class.instanceNamed5[function-entry$0].local*/ local([e = 42]) {
      print('instanceNamed5.local($e)');
      /*13:Class.instanceNamed5.local*/ throw '>ExceptionMarker<';
    }

    var anonymous = /*10:Class.instanceNamed5[function-entry$0].<anonymous function>*/ (
        {f: 87}) {
      print('instanceNamed5.<anonymous(f:$f)');
      /*11:Class.instanceNamed5.<anonymous function>*/ local();
    };
    anonymous. /*9:Class.instanceNamed5*/ call();
  }
}
