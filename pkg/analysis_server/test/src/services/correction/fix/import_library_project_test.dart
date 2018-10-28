// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportLibraryProject1Test);
    defineReflectiveTests(ImportLibraryProject2Test);
    defineReflectiveTests(ImportLibraryProject3Test);
  });
}

@reflectiveTest
class ImportLibraryProject1Test extends FixProcessorTest
    with ImportLibraryTestMixin {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT1;

  test_alreadyImported_package() async {
    testFile = '/project/bin/test.dart';
    addSource('/project/bin/lib.dart', '''
class A {}
class B {}
''');
    await resolveTestUnit('''
import 'lib.dart' show A;
main() {
  A a;
  B b;
  print('\$a \$b');
}
''');
    await assertNoFix();
  }

  test_notInLib_BUILD() async {
    testFile = '/project/lib/test.dart';
    addSource('/other/test/lib.dart', 'class Test {}');
    await resolveTestUnit('''
main() {
  Test t;
  print(t);
}
''');
    await assertNoFix();
  }

  test_notInLib_pubspec() async {
    testFile = '/project/lib/test.dart';
    addSource('/other/test/lib.dart', 'class Test {}');
    await resolveTestUnit('''
main() {
  Test t;
  print(t);
}
''');
    await assertNoFix();
  }

  test_preferDirectOverExport() async {
    _configureMyPkg({'b.dart': 'class Test {}', 'a.dart': "export 'b.dart';"});
    await resolveTestUnit('''
main() {
  Test test = null;
  print(test);
}
''');
    await assertHasFix('''
import 'package:my_pkg/b.dart';

main() {
  Test test = null;
  print(test);
}
''');
  }

  test_preferDirectOverExport_src() async {
    _configureMyPkg({'b.dart': 'class Test {}', 'a.dart': "export 'b.dart';"});
    await resolveTestUnit('''
main() {
  Test test = null;
  print(test);
}
''');
    await assertHasFix('''
import 'package:my_pkg/b.dart';

main() {
  Test test = null;
  print(test);
}
''');
  }

  test_withClass_annotation() async {
    testFile = '/project/lib/test.dart';
    addSource('/project/lib/lib.dart', '''
library lib;
class Test {
  const Test(int p);
}
''');
    await resolveTestUnit('''
@Test(0)
main() {
}
''');
    await assertHasFix('''
import 'lib.dart';

@Test(0)
main() {
}
''');
  }

  test_withClass_hasOtherLibraryWithPrefix() async {
    testFile = '/project/bin/test.dart';
    addSource('/project/bin/a.dart', '''
library a;
class One {}
''');
    addSource('/project/bin/b.dart', '''
library b;
class One {}
class Two {}
''');
    await resolveTestUnit('''
import 'b.dart' show Two;
main () {
  new Two();
  new One();
}
''');
    await assertHasFix('''
import 'a.dart';
import 'b.dart' show Two;
main () {
  new Two();
  new One();
}
''');
  }

  test_withClass_inParentFolder() async {
    testFile = '/project/bin/test.dart';
    addSource('/project/lib.dart', '''
library lib;
class Test {}
''');
    await resolveTestUnit('''
main() {
  Test t = null;
  print(t);
}
''');
    await assertHasFix('''
import '../lib.dart';

main() {
  Test t = null;
  print(t);
}
''');
  }

  test_withClass_inRelativeFolder() async {
    testFile = '/project/bin/test.dart';
    addSource('/project/lib/sub/folder/lib.dart', '''
library lib;
class Test {}
''');
    await resolveTestUnit('''
main() {
  Test t = null;
  print(t);
}
''');
    await assertHasFix('''
import '../lib/sub/folder/lib.dart';

main() {
  Test t = null;
  print(t);
}
''');
  }

  test_withClass_inSameFolder() async {
    testFile = '/project/bin/test.dart';
    addSource('/project/bin/lib.dart', '''
library lib;
class Test {}
''');
    await resolveTestUnit('''
main() {
  Test t = null;
  print(t);
}
''');
    await assertHasFix('''
import 'lib.dart';

main() {
  Test t = null;
  print(t);
}
''');
  }

  test_withClass_instanceCreation_const() async {
    testFile = '/project/lib/test.dart';
    addSource('/project/lib/lib.dart', '''
class Test {
  const Test();
}
''');
    await resolveTestUnit('''
main() {
  return const Test();
}
''');
    await assertHasFix('''
import 'lib.dart';

main() {
  return const Test();
}
''');
  }

  test_withClass_instanceCreation_const_namedConstructor() async {
    testFile = '/project/lib/test.dart';
    addSource('/project/lib/lib.dart', '''
class Test {
  const Test.named();
}
''');
    await resolveTestUnit('''
main() {
  const Test.named();
}
''');
    await assertHasFix('''
import 'lib.dart';

main() {
  const Test.named();
}
''');
  }

  test_withClass_instanceCreation_implicit() async {
    testFile = '/project/lib/test.dart';
    addSource('/project/lib/lib.dart', '''
class Test {
  const Test();
}
''');
    await resolveTestUnit('''
main() {
  return Test();
}
''');
    await assertHasFix('''
import 'lib.dart';

main() {
  return Test();
}
''');
  }

  test_withClass_instanceCreation_new() async {
    testFile = '/project/lib/test.dart';
    addSource('/project/lib/lib.dart', '''
class Test {
  const Test();
}
''');
    await resolveTestUnit('''
main() {
  return new Test();
}
''');
    await assertHasFix('''
import 'lib.dart';

main() {
  return new Test();
}
''');
  }

  test_withClass_instanceCreation_new_namedConstructor() async {
    testFile = '/project/lib/test.dart';
    addSource('/project/lib/lib.dart', '''
class Test {
  Test.named();
}
''');
    await resolveTestUnit('''
main() {
  new Test.named();
}
''');
    await assertHasFix('''
import 'lib.dart';

main() {
  new Test.named();
}
''');
  }

  test_withFunction() async {
    testFile = '/project/lib/test.dart';
    addSource('/project/lib/lib.dart', '''
library lib;
myFunction() {}
''');
    await resolveTestUnit('''
main() {
  myFunction();
}
''');
    await assertHasFix('''
import 'lib.dart';

main() {
  myFunction();
}
''');
  }

  test_withFunction_unresolvedMethod() async {
    testFile = '/project/lib/test.dart';
    addSource('/project/lib/lib.dart', '''
library lib;
myFunction() {}
''');
    await resolveTestUnit('''
class A {
  main() {
    myFunction();
  }
}
''');
    await assertHasFix('''
import 'lib.dart';

class A {
  main() {
    myFunction();
  }
}
''');
  }

  test_withFunctionTypeAlias() async {
    testFile = '/project/bin/test.dart';
    addSource('/project/bin/lib.dart', '''
library lib;
typedef MyFunction();
''');
    await resolveTestUnit('''
main() {
  MyFunction t = null;
  print(t);
}
''');
    await assertHasFix('''
import 'lib.dart';

main() {
  MyFunction t = null;
  print(t);
}
''');
  }

  test_withTopLevelVariable() async {
    testFile = '/project/lib/test.dart';
    addSource('/project/lib/lib.dart', '''
library lib;
int MY_VAR = 42;
''');
    await resolveTestUnit('''
main() {
  print(MY_VAR);
}
''');
    await assertHasFix('''
import 'lib.dart';

main() {
  print(MY_VAR);
}
''');
  }
}

@reflectiveTest
class ImportLibraryProject2Test extends FixProcessorTest
    with ImportLibraryTestMixin {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT2;

  test_preferDirectOverExport() async {
    _configureMyPkg({
      'b.dart': 'class Test {}',
      'a.dart': "export 'b.dart';",
    });
    await resolveTestUnit('''
main() {
  Test test = null;
  print(test);
}
''');
    await assertHasFix('''
import 'package:my_pkg/a.dart';

main() {
  Test test = null;
  print(test);
}
''');
  }

  test_preferDirectOverExport_src() async {
    _configureMyPkg({
      'b.dart': 'class Test {}',
      'a.dart': "export 'b.dart';",
    });
    await resolveTestUnit('''
main() {
  Test test = null;
  print(test);
}
''');
    await assertHasFix('''
import 'package:my_pkg/a.dart';

main() {
  Test test = null;
  print(test);
}
''');
  }
}

@reflectiveTest
class ImportLibraryProject3Test extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PROJECT3;

  test_inLibSrc_differentContextRoot() async {
    addPackageSource('bbb', 'b1.dart', r'''
import 'src/b2.dart';
class A {}
''');
    addPackageSource('bbb', 'src/b2.dart', 'class Test {}');
    await resolveTestUnit('''
import 'package:bbb/b1.dart';
main() {
  Test t;
  A a;
  print('\$t \$a');
}
''');
    await assertNoFix();
  }

  test_inLibSrc_thisContextRoot() async {
    testFile = '/project/lib/test.dart';
    packageMap['project'] = [newFolder('/project/lib')];
    addSource('/project/lib/src/lib.dart', 'class Test {}');
    configureDriver();
    await resolveTestUnit('''
main() {
  Test t;
  print(t);
}
''');
    await assertHasFix('''
import 'package:project/src/lib.dart';

main() {
  Test t;
  print(t);
}
''');
  }
}

mixin ImportLibraryTestMixin on FixProcessorTest {
  /// Configures the source factory to have a package named 'my_pkg' and for
  /// the package to contain all of the files described by the [pathToCode] map.
  /// The keys in the map are paths relative to the root of the package, and the
  /// values are the contents of the files at those paths.
  void _configureMyPkg(Map<String, String> pathToCode) {
    pathToCode.forEach((path, code) {
      newFile('/packages/my_pkg/lib/$path', content: code);
    });
    // configure SourceFactory
    Folder myPkgFolder = getFolder('/packages/my_pkg/lib');
    PackageMapUriResolver pkgResolver =
        new PackageMapUriResolver(resourceProvider, {
      'my_pkg': [myPkgFolder]
    });
    SourceFactory sourceFactory = new SourceFactory(
        [new DartUriResolver(sdk), pkgResolver, resourceResolver]);
    driver.configure(sourceFactory: sourceFactory);
    // force 'my_pkg' resolution
    addSource(
        '/tmp/other.dart',
        pathToCode.keys
            .map((path) => "import 'package:my_pkg/$path';")
            .join('\n'));
  }
}
