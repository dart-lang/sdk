// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'package:compiler/implementation/util/command_line.dart';

main() {
  Expect.listEquals(["foo", "bar"], splitLine("foo bar"));
  Expect.listEquals(["foo", "bar"], splitLine("foo bar", windows: true));

  Expect.listEquals(["foo bar"], splitLine(r"foo\ bar"));
  Expect.listEquals(["foo\\", "bar"], splitLine(r"foo\ bar", windows: true));

  Expect.listEquals(["foo'", '"bar'], splitLine(r"""foo\' \"bar"""));
  Expect.listEquals(["foo\\'", '"bar'],
                    splitLine(r"""foo\' \"bar""", windows: true));

  Expect.listEquals(["foo'", '"bar'], splitLine(r"""foo"'" '"'bar"""));
  Expect.throws(() => splitLine(r"""foo"'" '"'bar""", windows: true),
                (e) => e is FormatException);
  Expect.listEquals(["foo'", "''bar"],
                    splitLine(r"""foo"'" '"'bar" """, windows: true));

  Expect.listEquals(["foo", "bar"], splitLine("'f''o''o' " + '"b""a""r"'));
  // TODO(johnniwinther): This is not actual Windows behavior: "b""a" is
  // interpreted as b"a but "b""a""r" is interpreted as b"ar.
  Expect.listEquals(["'f''o''o'", "bar"],
                    splitLine("'f''o''o' " + '"b""a""r"', windows: true));

  Expect.listEquals(["\n", "\r", "\t", "\b", "\f", "\v", "\\",
                     "a", "Z", "-", '"', "'"],
                    splitLine(r"""\n \r \t \b \f \v \\ \a \Z \- \" \'"""));
  Expect.listEquals(["\\n", "\\r", "\\t", "\\b", "\\f", "\\v",
                     "\\", "\\a", "\\Z", "\\-", '"', "\\'"],
                    splitLine(r"""\n \r \t \b \f \v \\ \a \Z \- \" \'""",
                              windows: true));
  Expect.listEquals(["C:Users\foo\bar\baz.dart"],
      splitLine(r"C:\Users\foo\bar\baz.dart"));
  Expect.listEquals([r"C:\Users\foo\bar\baz.dart"],
      splitLine(r"C:\Users\foo\bar\baz.dart", windows: true));

  Expect.listEquals(["C:Users\foo\bar\name with spaces.dart"],
      splitLine(r'"C:\Users\foo\bar\name with spaces.dart"'));
  Expect.listEquals([r"C:\Users\foo\bar\name with spaces.dart"],
      splitLine(r'"C:\Users\foo\bar\name with spaces.dart"', windows: true));

  Expect.throws(() => splitLine(r"\"), (e) => e is FormatException);
  Expect.throws(() => splitLine(r"\", windows: true),
                (e) => e is FormatException);
}
