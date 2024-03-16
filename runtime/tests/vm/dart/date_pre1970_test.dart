// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Confirm that timezone information is available on pre-1970 dates, which
// was a problem on Windows.

import 'dart:io';

import "package:expect/expect.dart";

main(List<String> args) async {
  if (args.length == 0) {
    final result = await Process.run(Platform.executable, [
      ...Platform.executableArguments,
      Platform.script.toString(),
      "with_tz_set"
    ], environment: <String, String>{
      "TZ": "GMT-1"
    });
    print('stdout: ${result.stdout}');
    print('stderr: ${result.stderr}');
    Expect.equals(result.exitCode, 0);
    return;
  }

  {
    final DateTime date1 = DateTime.parse('1970-01-01T00:59:59.999+01:00');
    final DateTime date2 = DateTime.parse('1970-01-01T01:00:00.000+01:00');
    final DateTime date3 = DateTime.parse('1970-01-01T01:00:00.001+01:00');

    // executing the following lines with assumption that tz=GMT-1

    Expect.equals("1970-01-01T00:59:59.999", date1.toLocal().toIso8601String());
    Expect.equals("1970-01-01T01:00:00.000", date2.toLocal().toIso8601String());
    Expect.equals("1970-01-01T01:00:00.001", date3.toLocal().toIso8601String());
  }

  {
    var date0 = DateTime(1970, 1, 1);
    var date1 = DateTime.parse('1970-01-01T00:59:59.999+01:00');

    Expect.equals("1:00:00.000000", date0.timeZoneOffset.toString());
    Expect.equals("1970-01-01 00:00:00.000", date0.toString());

    Expect.equals("0:00:00.000000", date1.timeZoneOffset.toString());
    Expect.equals("1969-12-31 23:59:59.999Z", date1.toString());

    var local = date1.toLocal();
    Expect.equals("1:00:00.000000", local.timeZoneOffset.toString());
    Expect.equals("1970-01-01 00:59:59.999", local.toString());

    var local1 = DateTime(1969, 12, 31, 23, 59, 59);
    Expect.equals("1:00:00.000000", local1.timeZoneOffset.toString());
    Expect.equals("1969-12-31 23:59:59.000", local1.toString());
  }
}
