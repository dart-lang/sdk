// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test switch statement using labels.

import "package:expect/expect.dart";

class Switcher {
  Switcher() {}

  say1(sound) {
    var x = 0;
    switch (sound) {
      MOO:
      case "moo":
        x = 100;
        break;
      case "woof":
        x = 200;
        continue MOO;
      default:
        x = 300;
        break;
    }
    return x;
  }

  say2(sound) {
    var x = 0;
    switch (sound) {
      WOOF:
      case "woof":
        x = 200;
        break;
      case "moo":
        x = 100;
        continue WOOF;
      default:
        x = 300;
        break;
    }
    return x;
  }

  // forward label to outer switch
  say3(animal, sound) {
    var x = 0;
    switch (animal) {
      case "cow":
        switch (sound) {
          case "moo":
            x = 100;
            break;
          case "muh":
            x = 200;
            break;
          default:
            continue NIX_UNDERSTAND;
        }
        break;
      case "dog":
        if (sound == "woof") {
          x = 300;
        } else {
          continue NIX_UNDERSTAND;
        }
        break;
      NIX_UNDERSTAND:
      case "unicorn":
        x = 400;
        break;
      default:
        x = 500;
        break;
    }
    return x;
  }
}

class SwitchLabelTest {
  static testMain() {
    Switcher s = new Switcher();
    Expect.equals(100, s.say1("moo"));
    Expect.equals(100, s.say1("woof"));
    Expect.equals(300, s.say1("cockadoodledoo"));

    Expect.equals(200, s.say2("moo"));
    Expect.equals(200, s.say2("woof"));
    Expect.equals(300, s.say2("")); // Dead unicorn says nothing.

    Expect.equals(100, s.say3("cow", "moo"));
    Expect.equals(200, s.say3("cow", "muh"));
    Expect.equals(400, s.say3("cow", "boeh")); // Don't ask.
    Expect.equals(300, s.say3("dog", "woof"));
    Expect.equals(400, s.say3("dog", "boj")); // Ĉu vi parolas Esperanton?
    Expect.equals(400, s.say3("unicorn", "")); // Still dead.
    Expect.equals(500, s.say3("angry bird", "whoooo"));
  }
}

main() {
  SwitchLabelTest.testMain();
}
