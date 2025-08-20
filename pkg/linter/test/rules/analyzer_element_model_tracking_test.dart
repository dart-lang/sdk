// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_testing/package_root.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalyzerElementModelTrackingTest);
  });
}

@reflectiveTest
class AnalyzerElementModelTrackingTest extends LintRuleTest {
  @override
  String get lintRule => 'analyzer_element_model_tracking';

  @override
  void setUp() {
    super.setUp();

    var physicalProvider = PhysicalResourceProvider.INSTANCE;
    var pkgPath = physicalProvider.pathContext.normalize(packageRoot);
    var analyzerLibSource = physicalProvider
        .getFolder(pkgPath)
        .getChildAssumingFolder('analyzer')
        .getChildAssumingFolder('lib');

    var analyzerFolder = newFolder('/packages/analyzer');
    analyzerLibSource.copyTo(analyzerFolder);

    newPackageConfigJsonFileFromBuilder(
      testPackageRootPath,
      PackageConfigFileBuilder()
        ..add(name: 'analyzer', rootPath: analyzerFolder.path),
    );
  }

  test_constructor_trackedIncludedInId() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIncludedInId
  A();
}
''',
      [lint(80, 20, name: 'analyzer_element_model_tracking_bad')],
    );
  }

  test_public_instancePrivate_field_trackedIncludedInId() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIncludedInId
  final int _foo = 0;
}
''',
      [lint(80, 20, name: 'analyzer_element_model_tracking_bad')],
    );
  }

  test_public_instancePrivate_getter_trackedIncludedInId() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIncludedInId
  int get _foo => 0;
}
''',
      [lint(80, 20, name: 'analyzer_element_model_tracking_bad')],
    );
  }

  test_public_instancePrivate_method_trackedIncludedInId() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIncludedInId
  int _foo() => 0;
}
''',
      [lint(80, 20, name: 'analyzer_element_model_tracking_bad')],
    );
  }

  test_public_instancePublic_field_noAnnotation() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  final int foo = 0;
}
''',
      [lint(90, 3, name: 'analyzer_element_model_tracking_zero')],
    );
  }

  test_public_instancePublic_field_trackedDirectly() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedDirectly
  final int foo = 0;
}
''',
      [
        lint(80, 16, name: 'analyzer_element_model_tracking_bad'),
        lint(109, 3, name: 'analyzer_element_model_tracking_zero'),
      ],
    );
  }

  test_public_instancePublic_field_trackedIncludedInId() async {
    await assertNoDiagnostics(r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIncludedInId
  final int foo = 0;
}
''');
  }

  test_public_instancePublic_field_trackedIncludedInId2() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIncludedInId
  @trackedIncludedInId
  final int foo = 0;
}
''',
      [lint(103, 20, name: 'analyzer_element_model_tracking_more_than_one')],
    );
  }

  test_public_instancePublic_getter_noAnnotation() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  int get foo => 0;
}
''',
      [lint(88, 3, name: 'analyzer_element_model_tracking_zero')],
    );
  }

  test_public_instancePublic_getter_noAnnotation_abstract() async {
    await assertNoDiagnostics(r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
abstract class A {
  int get foo;
}
''');
  }

  test_public_instancePublic_getter_trackedDirectly() async {
    await assertNoDiagnostics(r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedDirectly
  int get foo => 0;
}
''');
  }

  test_public_instancePublic_getter_trackedDirectlyExpensive() async {
    await assertNoDiagnostics(r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedDirectlyExpensive
  int get foo => 0;
}
''');
  }

  test_public_instancePublic_getter_trackedDirectlyOpaque() async {
    await assertNoDiagnostics(r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedDirectlyOpaque
  int get foo => 0;
}
''');
  }

  test_public_instancePublic_getter_trackedIncludedInId() async {
    await assertNoDiagnostics(r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIncludedInId
  int get foo => 0;
}
''');
  }

  test_public_instancePublic_getter_trackedIncludedInId2() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIncludedInId
  @trackedIncludedInId
  int get foo => 0;
}
''',
      [lint(103, 20, name: 'analyzer_element_model_tracking_more_than_one')],
    );
  }

  test_public_instancePublic_getter_trackedIndirectly() async {
    await assertNoDiagnostics(r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIndirectly
  int get foo => 0;
}
''');
  }

  test_public_instancePublic_method_noAnnotation() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  int foo() => 0;
}
''',
      [lint(84, 3, name: 'analyzer_element_model_tracking_zero')],
    );
  }

  test_public_instancePublic_method_noAnnotation_abstract() async {
    await assertNoDiagnostics(r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
abstract class A {
  int foo();
}
''');
  }

  test_public_instancePublic_method_noAnnotation_void() async {
    await assertNoDiagnostics(r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  void foo() {}
}
''');
  }

  test_public_instancePublic_method_trackedDirectly() async {
    await assertNoDiagnostics(r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedDirectly
  int foo() => 0;
}
''');
  }

  test_public_instancePublic_method_trackedDirectlyExpensive() async {
    await assertNoDiagnostics(r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedDirectlyExpensive
  int foo() => 0;
}
''');
  }

  test_public_instancePublic_method_trackedDirectlyOpaque() async {
    await assertNoDiagnostics(r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedDirectlyOpaque
  int foo() => 0;
}
''');
  }

  test_public_instancePublic_method_trackedIncludedInId() async {
    await assertNoDiagnostics(r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIncludedInId
  int foo() => 0;
}
''');
  }

  test_public_instancePublic_method_trackedIncludedInId2() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIncludedInId
  @trackedIncludedInId
  int foo() => 0;
}
''',
      [lint(103, 20, name: 'analyzer_element_model_tracking_more_than_one')],
    );
  }

  test_public_instancePublic_method_trackedIndirectly() async {
    await assertNoDiagnostics(r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIndirectly
  int foo() => 0;
}
''');
  }

  test_public_staticPrivate_field_trackedIncludedInId() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIncludedInId
  static final int _foo = 0;
}
''',
      [lint(80, 20, name: 'analyzer_element_model_tracking_bad')],
    );
  }

  test_public_staticPrivate_getter_trackedIncludedInId() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIncludedInId
  static int get _foo => 0;
}
''',
      [lint(80, 20, name: 'analyzer_element_model_tracking_bad')],
    );
  }

  test_public_staticPrivate_method_trackedIncludedInId() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIncludedInId
  static int _foo() => 0;
}
''',
      [lint(80, 20, name: 'analyzer_element_model_tracking_bad')],
    );
  }

  test_public_staticPublic_field_trackedIncludedInId() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIncludedInId
  static final int foo = 0;
}
''',
      [lint(80, 20, name: 'analyzer_element_model_tracking_bad')],
    );
  }

  test_public_staticPublic_getter_trackedIncludedInId() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIncludedInId
  static int get foo => 0;
}
''',
      [lint(80, 20, name: 'analyzer_element_model_tracking_bad')],
    );
  }

  test_public_staticPublic_method_trackedIncludedInId() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIncludedInId
  static int foo() => 0;
}
''',
      [lint(80, 20, name: 'analyzer_element_model_tracking_bad')],
    );
  }

  test_setter_trackedIncludedInId() async {
    await assertDiagnostics(
      r'''
import 'package:analyzer/src/fine/annotations.dart';

@elementClass
class A {
  @trackedIncludedInId
  set foo(int _) {}
}
''',
      [lint(80, 20, name: 'analyzer_element_model_tracking_bad')],
    );
  }
}
