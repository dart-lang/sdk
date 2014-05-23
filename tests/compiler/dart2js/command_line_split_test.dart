// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import '../../../sdk/lib/_internal/compiler/implementation/util/command_line.dart';

main() {
  Expect.listEquals(["foo", "bar"], splitLine("foo bar"));
  Expect.listEquals(["foo bar"], splitLine(r"foo\ bar"));
  Expect.listEquals(["foo'", '"bar'], splitLine(r"""foo\' \"bar"""));
  Expect.listEquals(["foo'", '"bar'], splitLine(r"""foo"'" '"'bar"""));
  Expect.listEquals(["foo", "bar"], splitLine("'f''o''o' " + '"b""a""r"'));
  Expect.listEquals(["\n", "\t", "\t", "\b", "\f", "\v", "\\", "a", "Z", "-"],
                    splitLine(r"\n \t \t \b \f \v \\ \a \Z \-"));
}
