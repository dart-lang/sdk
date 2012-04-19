// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// String concatenation test.

interface V {
  static final Version = "7.3.5.3";
}


class StringConcatTest {

  static final Tag = "version-" + V.Version;

  static Answer() {
    return 42;
  }

  static testMain() {
    int nofExceptions = 0;

    var x = 3;
    var y = 5;
    Expect.equals("" + x + y, "35");
    Expect.equals(x + y, 8);

    var s1 = "The answer is " + Answer() + '.';
    Expect.equals(s1, "The answer is 42.");

    Expect.equals("version-7.3.5.3", Tag);

    // Adding a number to a string value creates a new, concatenated
    // string.
    s1 = "Grandmaster Flash and the Furious ";
    s1 = "$s1${4 + 1}";
    Expect.equals(true, s1.endsWith("Furious 5"));

    // Adding a string to a number is not supported.
    try {
      String cantDo = x + " should't work";  // throws noSuchMethodException.
      Expect.equals(1, 0);  // this should never be executed.
    } catch(NoSuchMethodException e) {
      // In default mode.
      nofExceptions++;
    } catch (TypeError e) {
      // In type checked mode.
      nofExceptions++;
    } catch (IllegalArgumentException e) {
      // TODO(floitsch): IllegalArgumentException might not be correct. If
      // number operations are supposed to be implemented as double-dispatch
      // then we should get a NoSuchMethodException instead. In frog the
      // argument is eagerly checked and throws an IllegalArgumentException.
      nofExceptions++;
    }

    // Check that compile time constants are canonicalized.
    // TODO(hausner): Add more examples once we concatenate
    // CT constants other than string literals at compile time.
    var fake = "Milli" + " " + "Vanilli";
    Expect.equals(fake, "Milli Vanilli");
    Expect.equals(true, fake === "Milli Vanilli");
    Expect.equals(true, fake === "Milli " + 'Vanilli');

    Expect.equals(nofExceptions, 1);
  }
}

main() {
  StringConcatTest.testMain();
}
