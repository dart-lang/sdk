// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'compiler_helper.dart';

const String TEST_IF = r"""
test(param) {
  if (param is int) {
    param = param + 42;
  }
  return param + 53;
}
""";

const String TEST_IF_ELSE = r"""
test(param) {
  if (param is int) {
    param = param + 42;
  } else {
    param = param + 53;
  }
  return param + 53;
}
""";

const String TEST_IF_RETURN = r"""
test(param) {
  if (param is int) {
    return param + 42;
  }
  return param + 53;
}
""";

const String TEST_IF_NOT_ELSE = r"""
test(param) {
  if (param is !int) {
    param = param + 53;
  } else {
    param = param + 42;
  }
  return param;
}
""";

const String TEST_IF_NOT_RETURN = r"""
test(param) {
  if (param is !int) return param + 53;
  return param + 42;
}
""";

const String TEST_IF_NOT_ELSE_RETURN = r"""
test(param) {
  if (param is !int) {
    return param + 53;
  } else {
    param = param + 42;
  }
  return param;
}
""";

compileAndTest(String code) {
  String generated = compile(code, entry: 'test');
  RegExp validAdd =
      new RegExp("($anyIdentifier \\+ 42)|($anyIdentifier \\+= 42)");
  RegExp invalidAdd = new RegExp("$anyIdentifier \\+ 53");
  Expect.isTrue(validAdd.hasMatch(generated));
  Expect.isFalse(invalidAdd.hasMatch(generated));
}

main() {
  compileAndTest(TEST_IF);
  compileAndTest(TEST_IF_ELSE);
  compileAndTest(TEST_IF_RETURN);
  compileAndTest(TEST_IF_NOT_ELSE);
  compileAndTest(TEST_IF_NOT_RETURN);
  compileAndTest(TEST_IF_NOT_ELSE_RETURN);
}
