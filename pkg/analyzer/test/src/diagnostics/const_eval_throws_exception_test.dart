// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalThrowsExceptionTest);
    defineReflectiveTests(ConstEvalThrowsExceptionWithUIAsCodeTest);
  });
}

/// TODO(paulberry): move other tests from [CheckedModeCompileTimeErrorCodeTest]
/// and [CompileTimeErrorCodeTestBase] to this class.
@reflectiveTest
class ConstEvalThrowsExceptionTest extends DriverResolutionTest {
  test_CastError_intToDouble_constructor_importAnalyzedAfter() async {
    // See dartbug.com/35993
    addTestFile(r'''
import 'other.dart';

void main() {
  const foo = Foo(1);
  const bar = Bar.some();
  print("$foo, $bar");
}
''');
    newFile('/test/lib/other.dart', content: '''
class Foo {
  final double value;

  const Foo(this.value);
}

class Bar {
  final Foo value;

  const Bar(this.value);

  const Bar.some() : this(const Foo(1));
}''');
    await resolveTestFile();
    assertNoTestErrors();
    var otherFileResult =
        await resolveFile(convertPath('/test/lib/other.dart'));
    expect(otherFileResult.errors, isEmpty);
  }

  test_CastError_intToDouble_constructor_importAnalyzedBefore() async {
    // See dartbug.com/35993
    addTestFile(r'''
import 'other.dart';

void main() {
  const foo = Foo(1);
  const bar = Bar.some();
  print("$foo, $bar");
}
''');
    newFile('/test/lib/other.dart', content: '''
class Foo {
  final double value;

  const Foo(this.value);
}

class Bar {
  final Foo value;

  const Bar(this.value);

  const Bar.some() : this(const Foo(1));
}''');
    var otherFileResult =
        await resolveFile(convertPath('/test/lib/other.dart'));
    expect(otherFileResult.errors, isEmpty);
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_default_constructor_arg_empty_map_importAnalyzedAfter() async {
    addTestFile('''
import 'other.dart';

main() {
  var c = const C();
}
''');
    newFile('/test/lib/other.dart', content: '''
class C {
  final Map<String, int> m;
  const C({this.m = const <String, int>{}})
    : assert(m != null);
}
''');
    await resolveTestFile();
    assertNoTestErrors();
    var otherFileResult =
        await resolveFile(convertPath('/test/lib/other.dart'));
    expect(otherFileResult.errors, isEmpty);
  }

  test_default_constructor_arg_empty_map_importAnalyzedBefore() async {
    addTestFile('''
import 'other.dart';

main() {
  var c = const C();
}
''');
    newFile('/test/lib/other.dart', content: '''
class C {
  final Map<String, int> m;
  const C({this.m = const <String, int>{}})
    : assert(m != null);
}
''');
    var otherFileResult =
        await resolveFile(convertPath('/test/lib/other.dart'));
    expect(otherFileResult.errors, isEmpty);
    await resolveTestFile();
    assertNoTestErrors();
  }
}

@reflectiveTest
class ConstEvalThrowsExceptionWithUIAsCodeTest
    extends ConstEvalThrowsExceptionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections,
    ];

  test_ifElement_false_thenNotEvaluated() async {
    assertNoErrorsInCode('''
const dynamic nil = null;
const c = [if (1 < 0) nil + 1];
''');
  }

  test_ifElement_true_elseNotEvaluated() async {
    assertNoErrorsInCode('''
const dynamic nil = null;
const c = [if (0 < 1) 3 else nil + 1];
''');
  }
}
