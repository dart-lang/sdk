// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../fix_processor.dart';
import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PlatformUseCaseTest);
  });
}

@reflectiveTest
class PlatformUseCaseTest extends DataDrivenFixProcessorTest {
  Future<void> test_platform_LocalPlatform_isAndroid_deprecated() async {
    newFile('$workspaceRootPath/p/lib/lib.dart', '''
class LocalPlatform {
  @deprecated
  bool get isAndroid => true;
}
''');
    newFile('$workspaceRootPath/p/lib/host.dart', '''
class HostPlatform {
  static HostPlatform get current => HostPlatform();
  bool get isAndroid => true;
}
''');

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'p', rootPath: '$workspaceRootPath/p'),
    );

    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace by HostPlatform'
    date: 2023-11-09
    element:
      uris: [  '$importUri' ]
      getter: 'isAndroid'
      inClass: LocalPlatform
    changes:
    - kind: 'replacedBy'
      replaceTarget: true
      newElement:
        uris: [  'package:p/host.dart' ]
        getter: current.isAndroid
        inClass: HostPlatform
        static: true
''');

    await resolveTestCode('''
import '$importUri';

main() {
  var isAndroid =  LocalPlatform().isAndroid;
  print(isAndroid);
}
''');
    await assertHasFix('''
import 'package:p/host.dart';
import '$importUri';

main() {
  var isAndroid =  HostPlatform.current.isAndroid;
  print(isAndroid);
}
''');
  }
}
