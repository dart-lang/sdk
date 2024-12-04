// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../fix_processor.dart';
import 'data_driven_test_support.dart';
import 'sdk_fix_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PlatformUseCaseTest);
    defineReflectiveTests(SdkFixIoTest);
  });
}

@reflectiveTest
class PlatformUseCaseTest extends DataDrivenFixProcessorTest {
  Future<void> test_package_os_detect_platform_deprecated() async {
    newFile('$workspaceRootPath/p/lib/os.dart', '''
  @deprecated
  bool get isAndroid => true;
''');
    newFile('$workspaceRootPath/p2/lib/host.dart', '''
 class HostPlatform {
  static HostPlatform get current => HostPlatform();
  bool get isAndroid => true;
}
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'p', rootPath: '$workspaceRootPath/p')
            ..add(name: 'p2', rootPath: '$workspaceRootPath/p2'),
    );

    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace package os_detect by package platform HostPlatform'
    date: 2023-11-09
    element:
      uris: [  'package:p/os.dart' ]
      getter: 'isAndroid'
    changes:
    - kind: 'replacedBy'
      replaceTarget: true
      newElement:
        uris: [  'package:p2/host.dart' ]
        getter: current.isAndroid
        inClass: HostPlatform
        static: true
''');

    await resolveTestCode('''
import 'package:p/os.dart' as Platform;

main() {
  bool onAndroid = Platform.isAndroid;
  print(onAndroid);
}
''');
    await assertHasFix('''
import 'package:p/os.dart' as Platform;
import 'package:p2/host.dart';

main() {
  bool onAndroid = HostPlatform.current.isAndroid;
  print(onAndroid);
}
''');
  }

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
      config:
          PackageConfigFileBuilder()
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

  Future<void> test_platform_LocalPlatform_localHostname_deprecated() async {
    newFile('$workspaceRootPath/p/lib/lib.dart', '''
class LocalPlatform {
  @deprecated
  String get localHostname => 'hostname';
}
''');
    newFile('$workspaceRootPath/p/lib/native.dart', '''
class NativePlatform {
  static NativePlatform get current => NativePlatform();
  String get localHostname => 'hostname';
}
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'p', rootPath: '$workspaceRootPath/p'),
    );

    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace by NativePlatform'
    date: 2023-11-09
    element:
      uris: [  '$importUri' ]
      getter: 'localHostname'
      inClass: LocalPlatform
    changes:
    - kind: 'replacedBy'
      replaceTarget: true
      newElement:
        uris: [  'package:p/native.dart' ]
        getter: current.localHostname
        inClass: NativePlatform
        static: true
''');

    await resolveTestCode('''
import '$importUri';

main() {
  var hostname =  LocalPlatform().localHostname;
  print(hostname);
}
''');
    await assertHasFix('''
import '$importUri';
import 'package:p/native.dart';

main() {
  var hostname =  NativePlatform.current.localHostname;
  print(hostname);
}
''');
  }
}

@reflectiveTest
class SdkFixIoTest extends AbstractSdkFixTest {
  @override
  String importUri = 'dart:io';

  Future<void> test_platform_dartIo_localHostname_deprecated() async {
    newFile('$workspaceRootPath/p/lib/native.dart', '''
class NativePlatform {
  static NativePlatform get current => NativePlatform();
  String get localHostname => 'hostname';
}
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'p', rootPath: '$workspaceRootPath/p'),
    );

    addSdkDataFile('''
version: 1
transforms:
  - title: 'Replace by NativePlatform'
    date: 2023-11-09
    element:
      uris: [  '$importUri' ]
      getter: 'localHostname'
      inClass: Platform
    changes:
    - kind: 'replacedBy'
      replaceTarget: true
      newElement:
        uris: [  'package:p/native.dart' ]
        getter: current.localHostname
        inClass: NativePlatform
        static: true
''');

    await resolveTestCode('''
import '$importUri';

main() {
  var hostname =  Platform.localHostname;
  print(hostname);
}
''');
    await assertHasFix('''
import '$importUri';

import 'package:p/native.dart';

main() {
  var hostname =  NativePlatform.current.localHostname;
  print(hostname);
}
''');
  }

  Future<void> test_platform_dartIo_onAndroid_deprecated() async {
    newFile('$workspaceRootPath/p/lib/host.dart', '''
class HostPlatform {
  static HostPlatform get current => HostPlatform();
  bool get isAndroid => true;
}
''');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'p', rootPath: '$workspaceRootPath/p'),
    );

    addSdkDataFile('''
version: 1
transforms:
  - title: 'Replace by HostPlatform'
    date: 2023-11-09
    element:
      uris: [  '$importUri' ]
      getter: 'isAndroid'
      inClass: Platform
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
  bool onAndroid = Platform.isAndroid;
  print(onAndroid);
}
''');
    await assertHasFix('''
import '$importUri';

import 'package:p/host.dart';

main() {
  bool onAndroid = HostPlatform.current.isAndroid;
  print(onAndroid);
}
''');
  }
}
