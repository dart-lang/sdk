// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test [source_update.dart].
library trydart.source_update_test;

import 'dart:convert' show
    JSON;

import 'package:expect/expect.dart' show
    Expect;

import 'source_update.dart' show
    expandDiff,
    expandUpdates,
    splitFiles,
    splitLines;

main() {
  Expect.listEquals(
      ["head v1 tail", "head v2 tail"],
      expandUpdates(["head ", ["v1", "v2"], " tail"]));

  Expect.listEquals(
      ["head v1 tail v2", "head v2 tail v1"],
      expandUpdates(["head ", ["v1", "v2"], " tail ", ["v2", "v1"]]));

  Expect.throws(() {
    expandUpdates(["head ", ["v1", "v2"], " tail ", ["v1"]]);
  });

  Expect.throws(() {
    expandUpdates(["head ", ["v1", "v2"], " tail ", ["v1", "v2", "v3"]]);
  });

  Expect.stringEquals(
      JSON.encode({
          "file1.dart": """
First line of file 1.
Second line of file 1.
Third line of file 1.
""",
          "empty.dart":"",
          "file2.dart":"""
First line of file 2.
Second line of file 2.
Third line of file 2.
"""}),

      JSON.encode(splitFiles(r"""
==> file1.dart <==
First line of file 1.
Second line of file 1.
Third line of file 1.
==> empty.dart <==
==> file2.dart <==
First line of file 2.
Second line of file 2.
Third line of file 2.
""")));

  Expect.stringEquals("{}", JSON.encode(splitFiles("")));

  Expect.stringEquals("[]", JSON.encode(splitLines("")));

  Expect.stringEquals('["1"]', JSON.encode(splitLines("1")));

  Expect.stringEquals('["\\n"]', JSON.encode(splitLines("\n")));

  Expect.stringEquals('["\\n","1"]', JSON.encode(splitLines("\n1")));

  Expect.stringEquals(
      '["","",""]',
      JSON.encode(expandUpdates(expandDiff(r"""
<<<<<<<
=======
=======
>>>>>>>
"""))));

  Expect.stringEquals(
      r'["first\nv1\nlast\n","first\nv2\nlast\n","first\nv3\nlast\n"]',
      JSON.encode(expandUpdates(expandDiff(r"""
first
<<<<<<<
v1
=======
v2
=======
v3
>>>>>>>
last
"""))));

  Expect.stringEquals(
      r'["v1\nlast\n","v2\nlast\n","v3\nlast\n"]',
      JSON.encode(expandUpdates(expandDiff(r"""
<<<<<<<
v1
=======
v2
=======
v3
>>>>>>>
last
"""))));

  Expect.stringEquals(
      r'["v1\n","v2\n","v3\n"]',
      JSON.encode(expandUpdates(expandDiff(r"""
<<<<<<<
v1
=======
v2
=======
v3
>>>>>>>
"""))));
}
