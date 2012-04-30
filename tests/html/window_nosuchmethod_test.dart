// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('WindowNSMETest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html', prefix: 'dom');

// Not defined in dom.Window.
foo(x) => x;

class Unused {
  foo(x) => 'not $x';
}

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

main() {
  useHtmlConfiguration();
  var things = [new Unused(), dom.window];

  test('windowNonMethod', () {
      var win = things[inscrutable(1)];
      final message = foo("Hello World");
      try {
        String x = win.foo(message);
        Expect.fail('Should not reach here: $x');
      } catch (NoSuchMethodException e) {
        // Expected exception.
      } catch (Exception e) {
        Expect.fail('Wrong exception: $e');
      }
    });

  test('foo', () {
      var win = things[inscrutable(0)];
      String x = win.foo('bar');
      Expect.equals('not bar', x);
    });

  // Use dom.window direclty in case the compiler does type inference.
  test('windowNonMethod2', () {
      final message = foo("Hello World");
      try {
        String x = dom.window.foo(message);
        Expect.fail('Should not reach here: $x');
      } catch (NoSuchMethodException e) {
        // Expected exception.
      } catch (Exception e) {
        Expect.fail('Wrong exception: $e');
      }
    }); 
}
