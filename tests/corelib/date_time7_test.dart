// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test DateTime timeZoneName and timeZoneOffset getters.

testUtc() {
  var d = DateTime.parse("2012-03-04T03:25:38.123Z");
  Expect.equals("UTC", d.timeZoneName);
  Expect.equals(0, d.timeZoneOffset.inSeconds);
}

testLocal() {
  checkOffset(String name, Duration offset) {
    // Timezone abbreviations are not in bijection with their timezones.
    // For example AST stands for "Arab Standard Time" (UTC+03), as well as
    // "Arabian Standard Time" (UTC+04), or PST stands for Pacific Standard Time
    // and Philippine Standard Time.
    //
    // Hardcode some common timezones, in both their abbreviated and expanded
    // forms to account for differences between host platforms.
    switch (name) {
      case "CET" || "Central European Time" || "Central European Standard Time":
        Expect.equals(1, offset.inHours);
      case "CEST" || "Central European Summer Time":
        Expect.equals(2, offset.inHours);
      case "GMT" || "Greenwich Mean Time":
        Expect.equals(0, offset.inSeconds);
      case "EST" || "Eastern Standard Time":
        Expect.equals(-5, offset.inHours);
      case "EDT" || "Eastern Daylight Time":
        Expect.equals(-4, offset.inHours);
      case "PDT" || "Pacific Daylight Time":
        Expect.equals(-7, offset.inHours);
      case "PST" || "Pacific Standard Time":
        Expect.equals(-8, offset.inHours);
      case "CST" || "Central Standard Time":
        Expect.equals(-6, offset.inHours);
      case "CDT" || "Central Daylight Time":
        Expect.equals(-5, offset.inHours);
    }
  }

  var d = DateTime.parse("2012-01-02T13:45:23");
  String name = d.timeZoneName;
  checkOffset(name, d.timeZoneOffset);

  d = DateTime.parse("2012-07-02T13:45:23");
  name = d.timeZoneName;
  checkOffset(name, d.timeZoneOffset);
}

main() {
  testUtc();
  testLocal();
}
