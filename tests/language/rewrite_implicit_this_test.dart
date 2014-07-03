// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

String toplevel = 'A';

class Foo {
    String x = 'x';

    easy(z) {
        return x + y + z;
    }

    // Shadow the 'y' field in various ways
    shadow_y_parameter(y) {
        return x + this.y + y;
    }

    shadow_y_local(z) {
        var y = z;
        return x + this.y + y;
    }

    shadow_y_capturedLocal(z) {
        var y = z;
        foo() {
            return x + this.y + y;
        }
        return foo();
    }

    shadow_y_closureParam(z) {
        foo(y) {
            return x + this.y + y;
        }
        return foo(z);
    }

    shadow_y_localInsideClosure(z) {
        foo() {
            var y = z;
            return x + this.y + y;
        }
        return foo();
    }

    // Shadow the 'x' field in various ways
    shadow_x_parameter(x) {
        return this.x + y + x;
    }

    shadow_x_local(z) {
        var x = z;
        return this.x + y + x;
    }

    shadow_x_capturedLocal(z) {
        var x = z;
        foo() {
            return this.x + y + x;
        }
        return foo();
    }

    shadow_x_closureParam(z) {
        foo(x) {
            return this.x + y + x;
        }
        return foo(z);
    }

    shadow_x_localInsideClosure(z) {
        foo() {
            var x = z;
            return this.x + y + x;
        }
        return foo();
    }

    shadow_x_toplevel() {
        return x + this.y + toplevel + this.toplevel;
    }
    
}

class Sub extends Foo {
    String y = 'y';
    String toplevel = 'B';
}

main() {
    Expect.equals('xyz', new Sub().easy('z'));
    Expect.equals('xyz', new Sub().shadow_y_parameter('z'));
    Expect.equals('xyz', new Sub().shadow_y_local('z'));
    Expect.equals('xyz', new Sub().shadow_y_capturedLocal('z'));
    Expect.equals('xyz', new Sub().shadow_y_closureParam('z'));
    Expect.equals('xyz', new Sub().shadow_y_localInsideClosure('z'));
    Expect.equals('xyz', new Sub().shadow_x_parameter('z'));
    Expect.equals('xyz', new Sub().shadow_x_local('z'));
    Expect.equals('xyz', new Sub().shadow_x_capturedLocal('z'));
    Expect.equals('xyz', new Sub().shadow_x_closureParam('z'));
    Expect.equals('xyz', new Sub().shadow_x_localInsideClosure('z'));

    Expect.equals('xyAB', new Sub().shadow_x_toplevel());
}
