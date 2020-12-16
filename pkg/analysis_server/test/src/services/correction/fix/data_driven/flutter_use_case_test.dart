// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterUseCaseTest);
  });
}

@reflectiveTest
class FlutterUseCaseTest extends DataDrivenFixProcessorTest {
  @failingTest
  Future<void>
      test_cupertino_CupertinoDialog_toCupertinoAlertDialog_deprecated() async {
    // This test fails because we don't rename the parameter to the constructor.
    setPackageContent('''
@deprecated
class CupertinoDialog {
  CupertinoDialog({String child}) {}
}
class CupertinoAlertDialog {
  CupertinoAlertDialog({String content}) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title:  'Replace with CupertinoAlertDialog'
    date: 2020-09-24
    bulkApply: false
    element:
      uris: ['$importUri']
      class: 'CupertinoDialog'
    changes:
      - kind: 'rename'
        newName: 'CupertinoAlertDialog'
      - kind: 'renameParameter'
        oldName: 'child'
        newName: 'content'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  CupertinoDialog(child: 'x');
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  CupertinoAlertDialog(content: 'x');
}
''');
  }

  @failingTest
  Future<void>
      test_cupertino_CupertinoDialog_toCupertinoAlertDialog_removed() async {
    // This test fails because we don't rename the parameter to the constructor.
    setPackageContent('''
class CupertinoAlertDialog {
  CupertinoAlertDialog({String content}) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title:  'Replace with CupertinoAlertDialog'
    date: 2020-09-24
    bulkApply: false
    element:
      uris: ['$importUri']
      class: 'CupertinoDialog'
    changes:
      - kind: 'rename'
        newName: 'CupertinoAlertDialog'
      - kind: 'renameParameter'
        oldName: 'child'
        newName: 'content'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  CupertinoDialog(child: 'x');
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  CupertinoAlertDialog(content: 'x');
}
''', errorFilter: ignoreUnusedImport);
  }

  Future<void>
      test_cupertino_CupertinoDialog_toCupertinoPopupSurface_deprecated() async {
    setPackageContent('''
@deprecated
class CupertinoDialog {
  CupertinoDialog({String child}) {}
}
class CupertinoPopupSurface {
  CupertinoPopupSurface({String content}) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace with CupertinoPopupSurface'
    date: 2020-09-24
    bulkApply: false
    element:
      uris: ['$importUri']
      class: 'CupertinoDialog'
    changes:
      - kind: 'rename'
        newName: 'CupertinoPopupSurface'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  CupertinoDialog(child: 'x');
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  CupertinoPopupSurface(child: 'x');
}
''');
  }

  Future<void>
      test_cupertino_CupertinoDialog_toCupertinoPopupSurface_removed() async {
    setPackageContent('''
class CupertinoPopupSurface {
  CupertinoPopupSurface({String content}) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace with CupertinoPopupSurface'
    date: 2020-09-24
    bulkApply: false
    element:
      uris: ['$importUri']
      class: 'CupertinoDialog'
    changes:
      - kind: 'rename'
        newName: 'CupertinoPopupSurface'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  CupertinoDialog(child: 'x');
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  CupertinoPopupSurface(child: 'x');
}
''', errorFilter: ignoreUnusedImport);
  }

  Future<void>
      test_cupertino_CupertinoTextThemeData_copyWith_deprecated() async {
    setPackageContent('''
class CupertinoTextThemeData {
  copyWith({Color color, @deprecated Brightness brightness}) {}
}
class Color {}
class Colors {
  static Color blue = Color();
}
class Brightness {
  static Brightness dark = Brightness();
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Removed brightness'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      method: 'copyWith'
      inClass: 'CupertinoTextThemeData'
    changes:
      - kind: 'removeParameter'
        name: 'brightness'
''');
    await resolveTestCode('''
import '$importUri';

void f(CupertinoTextThemeData data) {
  data.copyWith(color: Colors.blue, brightness: Brightness.dark);
}
''');
    await assertHasFix('''
import '$importUri';

void f(CupertinoTextThemeData data) {
  data.copyWith(color: Colors.blue);
}
''');
  }

  Future<void> test_cupertino_CupertinoTextThemeData_copyWith_removed() async {
    setPackageContent('''
class CupertinoTextThemeData {
  copyWith({Color color}) {}
}
class Color {}
class Colors {
  static Color blue = Color();
}
class Brightness {
  static Brightness dark = Brightness();
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Removed brightness'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      method: 'copyWith'
      inClass: 'CupertinoTextThemeData'
    changes:
      - kind: 'removeParameter'
        name: 'brightness'
''');
    await resolveTestCode('''
import '$importUri';

void f(CupertinoTextThemeData data) {
  data.copyWith(color: Colors.blue, brightness: Brightness.dark);
}
''');
    await assertHasFix('''
import '$importUri';

void f(CupertinoTextThemeData data) {
  data.copyWith(color: Colors.blue);
}
''');
  }

  Future<void>
      test_cupertino_CupertinoTextThemeData_defaultConstructor_deprecated() async {
    setPackageContent('''
class CupertinoTextThemeData {
  CupertinoTextThemeData({Color color, @deprecated Brightness brightness}) {}
}
class Color {}
class Colors {
  static Color blue = Color();
}
class Brightness {
  static Brightness dark = Brightness();
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Removed brightness'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'CupertinoTextThemeData'
    changes:
      - kind: 'removeParameter'
        name: 'brightness'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  CupertinoTextThemeData(color: Colors.blue, brightness: Brightness.dark);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  CupertinoTextThemeData(color: Colors.blue);
}
''');
  }

  Future<void>
      test_cupertino_CupertinoTextThemeData_defaultConstructor_removed() async {
    setPackageContent('''
class CupertinoTextThemeData {
  CupertinoTextThemeData({Color color}) {}
}
class Color {}
class Colors {
  static Color blue = Color();
}
class Brightness {
  static Brightness dark = Brightness();
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Removed brightness'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'CupertinoTextThemeData'
    changes:
      - kind: 'removeParameter'
        name: 'brightness'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  CupertinoTextThemeData(color: Colors.blue, brightness: Brightness.dark);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  CupertinoTextThemeData(color: Colors.blue);
}
''');
  }

  Future<void>
      test_gestures_PointerEnterEvent_fromHoverEvent_deprecated() async {
    setPackageContent('''
class PointerEnterEvent {
  @deprecated
  PointerEnterEvent.fromHoverEvent(PointerHoverEvent event);
  PointerEnterEvent.fromMouseEvent(PointerEvent event);
}
class PointerHoverEvent extends PointerEvent {}
class PointerEvent {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to fromMouseEvent'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: 'fromHoverEvent'
      inClass: 'PointerEnterEvent'
    changes:
      - kind: 'rename'
        newName: 'fromMouseEvent'
''');
    await resolveTestCode('''
import '$importUri';

void f(PointerHoverEvent event) {
  PointerEnterEvent.fromHoverEvent(event);
}
''');
    await assertHasFix('''
import '$importUri';

void f(PointerHoverEvent event) {
  PointerEnterEvent.fromMouseEvent(event);
}
''');
  }

  Future<void> test_gestures_PointerEnterEvent_fromHoverEvent_removed() async {
    setPackageContent('''
class PointerEnterEvent {
  PointerEnterEvent.fromMouseEvent(PointerEvent event);
}
class PointerHoverEvent extends PointerEvent {}
class PointerEvent {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to fromMouseEvent'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: 'fromHoverEvent'
      inClass: 'PointerEnterEvent'
    changes:
      - kind: 'rename'
        newName: 'fromMouseEvent'
''');
    await resolveTestCode('''
import '$importUri';

void f(PointerHoverEvent event) {
  PointerEnterEvent.fromHoverEvent(event);
}
''');
    await assertHasFix('''
import '$importUri';

void f(PointerHoverEvent event) {
  PointerEnterEvent.fromMouseEvent(event);
}
''');
  }

  Future<void>
      test_gestures_PointerExitEvent_fromHoverEvent_deprecated() async {
    setPackageContent('''
class PointerExitEvent {
  @deprecated
  PointerExitEvent.fromHoverEvent(PointerHoverEvent event);
  PointerExitEvent.fromMouseEvent(PointerEvent event);
}
class PointerHoverEvent extends PointerEvent {}
class PointerEvent {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to fromMouseEvent'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: 'fromHoverEvent'
      inClass: 'PointerExitEvent'
    changes:
      - kind: 'rename'
        newName: 'fromMouseEvent'
''');
    await resolveTestCode('''
import '$importUri';

void f(PointerHoverEvent event) {
  PointerExitEvent.fromHoverEvent(event);
}
''');
    await assertHasFix('''
import '$importUri';

void f(PointerHoverEvent event) {
  PointerExitEvent.fromMouseEvent(event);
}
''');
  }

  Future<void> test_gestures_PointerExitEvent_fromHoverEvent_removed() async {
    setPackageContent('''
class PointerExitEvent {
  PointerExitEvent.fromMouseEvent(PointerEvent event);
}
class PointerHoverEvent extends PointerEvent {}
class PointerEvent {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to fromMouseEvent'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: 'fromHoverEvent'
      inClass: 'PointerExitEvent'
    changes:
      - kind: 'rename'
        newName: 'fromMouseEvent'
''');
    await resolveTestCode('''
import '$importUri';

void f(PointerHoverEvent event) {
  PointerExitEvent.fromHoverEvent(event);
}
''');
    await assertHasFix('''
import '$importUri';

void f(PointerHoverEvent event) {
  PointerExitEvent.fromMouseEvent(event);
}
''');
  }

  Future<void>
      test_material_BottomNavigationBarItem_unnamedConstructor_deprecated() async {
    setPackageContent('''
class BottomNavigationBarItem {
  BottomNavigationBarItem({String label, @deprecated Text title});
}
class Text {
  Text(String text);
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replaced title with label'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'BottomNavigationBarItem'
    changes:
      - kind: 'addParameter'
        index: 0
        name: 'label'
        style: required_named
        argumentValue:
          expression: '{% label %}'
          variables:
            label:
              kind: fragment
              value: 'arguments[title].arguments[0]'
      - kind: 'removeParameter'
        name: 'title'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  BottomNavigationBarItem(title: Text('x'));
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  BottomNavigationBarItem(label: 'x');
}
''');
  }

  Future<void>
      test_material_BottomNavigationBarItem_unnamedConstructor_removed() async {
    setPackageContent('''
class BottomNavigationBarItem {
  BottomNavigationBarItem({String label});
}
class Text {
  Text(String text);
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replaced title with label'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'BottomNavigationBarItem'
    changes:
      - kind: 'addParameter'
        index: 0
        name: 'label'
        style: required_named
        argumentValue:
          expression: '{% label %}'
          variables:
            label:
              kind: fragment
              value: 'arguments[title].arguments[0]'
      - kind: 'removeParameter'
        name: 'title'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  BottomNavigationBarItem(title: Text('x'));
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  BottomNavigationBarItem(label: 'x');
}
''');
  }

  Future<void>
      test_material_InputDecoration_defaultConstructor_matchFirstCase_deprecated() async {
    setPackageContent('''
class InputDecoration {
  InputDecoration({
    @deprecated bool hasFloatingPlaceholder: true,
    FloatingLabelBehavior floatingLabelBehavior: FloatingLabelBehavior.auto,
  });
}
enum FloatingLabelBehavior {always, auto, never}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to floatingLabelBehavior'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'InputDecoration'
    oneOf:
      - if: "hasFloatingPlaceholder == 'true'"
        changes:
          - kind: 'addParameter'
            index: 14
            name: 'floatingLabelBehavior'
            style: optional_named
            argumentValue:
              expression: '{% FloatingLabelBehavior %}.auto'
              requiredIf: "hasFloatingPlaceholder == 'true'"
              variables:
                FloatingLabelBehavior:
                  kind: 'import'
                  uris: ['$importUri']
                  name: 'FloatingLabelBehavior'
          - kind: 'removeParameter'
            name: 'hasFloatingPlaceholder'
      - if: "hasFloatingPlaceholder == 'false'"
        changes:
          - kind: 'addParameter'
            index: 14
            name: 'floatingLabelBehavior'
            style: optional_named
            argumentValue:
              expression: '{% FloatingLabelBehavior %}.never'
              requiredIf: "hasFloatingPlaceholder == 'false'"
              variables:
                FloatingLabelBehavior:
                  kind: 'import'
                  uris: ['$importUri']
                  name: 'FloatingLabelBehavior'
          - kind: 'removeParameter'
            name: 'hasFloatingPlaceholder'
      - if: "hasFloatingPlaceholder != 'true' && hasFloatingPlaceholder != 'false'"
        changes:
          - kind: 'addParameter'
            index: 14
            name: 'floatingLabelBehavior'
            style: optional_named
            argumentValue:
              expression: '{% hasFloatingPlaceholder %} ? {% FloatingLabelBehavior %}.auto : {% FloatingLabelBehavior %}.never'
              requiredIf: "hasFloatingPlaceholder != 'true' && hasFloatingPlaceholder != 'false'"
              variables:
                FloatingLabelBehavior:
                  kind: 'import'
                  uris: ['$importUri']
                  name: 'FloatingLabelBehavior'
          - kind: 'removeParameter'
            name: 'hasFloatingPlaceholder'
    variables:
      hasFloatingPlaceholder:
        kind: 'fragment'
        value: 'arguments[hasFloatingPlaceholder]'
''');
    await resolveTestCode('''
import '$importUri';

InputDecoration f(bool b) => InputDecoration(hasFloatingPlaceholder: true);
''');
    await assertHasFix('''
import '$importUri';

InputDecoration f(bool b) => InputDecoration(floatingLabelBehavior: FloatingLabelBehavior.auto);
''');
  }

  Future<void>
      test_material_InputDecoration_defaultConstructor_matchSecondCase_deprecated() async {
    setPackageContent('''
class InputDecoration {
  InputDecoration({
    @deprecated bool hasFloatingPlaceholder: true,
    FloatingLabelBehavior floatingLabelBehavior: FloatingLabelBehavior.auto,
  });
}
enum FloatingLabelBehavior {always, auto, never}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to floatingLabelBehavior'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'InputDecoration'
    oneOf:
      - if: "hasFloatingPlaceholder == 'true'"
        changes:
          - kind: 'addParameter'
            index: 14
            name: 'floatingLabelBehavior'
            style: optional_named
            argumentValue:
              expression: '{% FloatingLabelBehavior %}.auto'
              requiredIf: "hasFloatingPlaceholder == 'true'"
              variables:
                FloatingLabelBehavior:
                  kind: 'import'
                  uris: ['$importUri']
                  name: 'FloatingLabelBehavior'
          - kind: 'removeParameter'
            name: 'hasFloatingPlaceholder'
      - if: "hasFloatingPlaceholder == 'false'"
        changes:
          - kind: 'addParameter'
            index: 14
            name: 'floatingLabelBehavior'
            style: optional_named
            argumentValue:
              expression: '{% FloatingLabelBehavior %}.never'
              requiredIf: "hasFloatingPlaceholder == 'false'"
              variables:
                FloatingLabelBehavior:
                  kind: 'import'
                  uris: ['$importUri']
                  name: 'FloatingLabelBehavior'
          - kind: 'removeParameter'
            name: 'hasFloatingPlaceholder'
      - if: "hasFloatingPlaceholder != 'true' && hasFloatingPlaceholder != 'false'"
        changes:
          - kind: 'addParameter'
            index: 14
            name: 'floatingLabelBehavior'
            style: optional_named
            argumentValue:
              expression: '{% hasFloatingPlaceholder %} ? {% FloatingLabelBehavior %}.auto : {% FloatingLabelBehavior %}.never'
              requiredIf: "hasFloatingPlaceholder != 'true' && hasFloatingPlaceholder != 'false'"
              variables:
                FloatingLabelBehavior:
                  kind: 'import'
                  uris: ['$importUri']
                  name: 'FloatingLabelBehavior'
          - kind: 'removeParameter'
            name: 'hasFloatingPlaceholder'
    variables:
      hasFloatingPlaceholder:
        kind: 'fragment'
        value: 'arguments[hasFloatingPlaceholder]'
''');
    await resolveTestCode('''
import '$importUri';

InputDecoration f(bool b) => InputDecoration(hasFloatingPlaceholder: false);
''');
    await assertHasFix('''
import '$importUri';

InputDecoration f(bool b) => InputDecoration(floatingLabelBehavior: FloatingLabelBehavior.never);
''');
  }

  Future<void>
      test_material_InputDecoration_defaultConstructor_matchThirdCase_deprecated() async {
    setPackageContent('''
class InputDecoration {
  InputDecoration({
    @deprecated bool hasFloatingPlaceholder: true,
    FloatingLabelBehavior floatingLabelBehavior: FloatingLabelBehavior.auto,
  });
}
enum FloatingLabelBehavior {always, auto, never}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to floatingLabelBehavior'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'InputDecoration'
    oneOf:
      - if: "hasFloatingPlaceholder == 'true'"
        changes:
          - kind: 'addParameter'
            index: 14
            name: 'floatingLabelBehavior'
            style: optional_named
            argumentValue:
              expression: '{% FloatingLabelBehavior %}.auto'
              requiredIf: "hasFloatingPlaceholder == 'true'"
              variables:
                FloatingLabelBehavior:
                  kind: 'import'
                  uris: ['$importUri']
                  name: 'FloatingLabelBehavior'
          - kind: 'removeParameter'
            name: 'hasFloatingPlaceholder'
      - if: "hasFloatingPlaceholder == 'false'"
        changes:
          - kind: 'addParameter'
            index: 14
            name: 'floatingLabelBehavior'
            style: optional_named
            argumentValue:
              expression: '{% FloatingLabelBehavior %}.never'
              requiredIf: "hasFloatingPlaceholder == 'false'"
              variables:
                FloatingLabelBehavior:
                  kind: 'import'
                  uris: ['$importUri']
                  name: 'FloatingLabelBehavior'
          - kind: 'removeParameter'
            name: 'hasFloatingPlaceholder'
      - if: "hasFloatingPlaceholder != 'true' && hasFloatingPlaceholder != 'false'"
        changes:
          - kind: 'addParameter'
            index: 14
            name: 'floatingLabelBehavior'
            style: optional_named
            argumentValue:
              expression: '{% hasFloatingPlaceholder %} ? {% FloatingLabelBehavior %}.auto : {% FloatingLabelBehavior %}.never'
              requiredIf: "hasFloatingPlaceholder != 'true' && hasFloatingPlaceholder != 'false'"
              variables:
                FloatingLabelBehavior:
                  kind: 'import'
                  uris: ['$importUri']
                  name: 'FloatingLabelBehavior'
          - kind: 'removeParameter'
            name: 'hasFloatingPlaceholder'
    variables:
      hasFloatingPlaceholder:
        kind: 'fragment'
        value: 'arguments[hasFloatingPlaceholder]'
''');
    await resolveTestCode('''
import '$importUri';

InputDecoration f(bool b) => InputDecoration(hasFloatingPlaceholder: b);
''');
    await assertHasFix('''
import '$importUri';

InputDecoration f(bool b) => InputDecoration(floatingLabelBehavior: b ? FloatingLabelBehavior.auto : FloatingLabelBehavior.never);
''');
  }

  Future<void> test_material_Scaffold_of_matchFirstCase() async {
    setPackageContent('''
class Scaffold {
  static ScaffoldState of(BuildContext context) => ScaffoldState();
  static ScaffoldState maybeOf(BuildContext context) => ScaffoldState();
}
class ScaffoldState {}
class BuildContext {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Remove nullOk'
    date: 2020-11-04
    element:
      uris: ['$importUri']
      method: 'of'
      inClass: 'Scaffold'
    oneOf:
      - if: "nullOk == 'true'"
        changes:
          - kind: 'rename'
            newName: 'maybeOf'
          - kind: 'removeParameter'
            name: 'nullOk'
      - if: "nullOk == 'false'"
        changes:
          - kind: 'removeParameter'
            name: 'nullOk'
    variables:
      nullOk:
        kind: 'fragment'
        value: 'arguments[nullOk]'
''');
    await resolveTestCode('''
import '$importUri';

void f(BuildContext context, bool b) {
  Scaffold.of(context, nullOk: true);
}
''');
    await assertHasFix('''
import '$importUri';

void f(BuildContext context, bool b) {
  Scaffold.maybeOf(context);
}
''');
  }

  Future<void> test_material_Scaffold_of_matchNoCases() async {
    setPackageContent('''
class Scaffold {
  static ScaffoldState of(BuildContext context) => ScaffoldState();
  static ScaffoldState maybeOf(BuildContext context) => ScaffoldState();
}
class ScaffoldState {}
class BuildContext {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Remove nullOk'
    date: 2020-11-04
    element:
      uris: ['$importUri']
      method: 'of'
      inClass: 'Scaffold'
    oneOf:
      - if: "nullOk == 'true'"
        changes:
          - kind: 'rename'
            newName: 'maybeOf'
          - kind: 'removeParameter'
            name: 'nullOk'
      - if: "nullOk == 'false'"
        changes:
          - kind: 'removeParameter'
            name: 'nullOk'
    variables:
      nullOk:
        kind: 'fragment'
        value: 'arguments[nullOk]'
''');
    await resolveTestCode('''
import '$importUri';

void f(BuildContext context, bool b) {
  Scaffold.of(context, nullOk: b);
}
''');
    await assertNoFix();
  }

  Future<void> test_material_Scaffold_of_matchSecondCase() async {
    setPackageContent('''
class Scaffold {
  static ScaffoldState of(BuildContext context) => ScaffoldState();
  static ScaffoldState maybeOf(BuildContext context) => ScaffoldState();
}
class ScaffoldState {}
class BuildContext {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Remove nullOk'
    date: 2020-11-04
    element:
      uris: ['$importUri']
      method: 'of'
      inClass: 'Scaffold'
    oneOf:
      - if: "nullOk == 'true'"
        changes:
          - kind: 'rename'
            newName: 'maybeOf'
          - kind: 'removeParameter'
            name: 'nullOk'
      - if: "nullOk == 'false'"
        changes:
          - kind: 'removeParameter'
            name: 'nullOk'
    variables:
      nullOk:
        kind: 'fragment'
        value: 'arguments[nullOk]'
''');
    await resolveTestCode('''
import '$importUri';

void f(BuildContext context, bool b) {
  Scaffold.of(context, nullOk: false);
}
''');
    await assertHasFix('''
import '$importUri';

void f(BuildContext context, bool b) {
  Scaffold.of(context);
}
''');
  }

  Future<void> test_material_Scaffold_of_missingArgument() async {
    setPackageContent('''
class Scaffold {
  static ScaffoldState of(BuildContext context) => ScaffoldState();
  static ScaffoldState maybeOf(BuildContext context) => ScaffoldState();
}
class ScaffoldState {}
class BuildContext {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Remove nullOk'
    date: 2020-11-04
    element:
      uris: ['$importUri']
      method: 'of'
      inClass: 'Scaffold'
    oneOf:
      - if: "nullOk == 'true'"
        changes:
          - kind: 'rename'
            newName: 'maybeOf'
          - kind: 'removeParameter'
            name: 'nullOk'
      - if: "nullOk == 'false'"
        changes:
          - kind: 'removeParameter'
            name: 'nullOk'
    variables:
      nullOk:
        kind: 'fragment'
        value: 'arguments[nullOk]'
''');
    await resolveTestCode('''
import '$importUri';

void f(BuildContext context) {
  Scaffold.of(context, undefined: 3);
}
''');
    await assertNoFix();
  }

  @failingTest
  Future<void> test_material_Scaffold_of_wrongType() async {
    setPackageContent('''
class Theme {
  static ThemeData of(BuildContext context, {bool shadowThemeOnly: false}) => ThemeData();
}
class ThemeData {}
class BuildContext {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Remove nullOk'
    date: 2020-11-04
    element:
      uris: ['$importUri']
      method: 'of'
      inClass: 'Scaffold'
    oneOf:
      - if: "nullOk == 'true'"
        changes:
          - kind: 'rename'
            newName: 'maybeOf'
          - kind: 'removeParameter'
            name: 'nullOk'
      - if: "nullOk == 'false'"
        changes:
          - kind: 'removeParameter'
            name: 'nullOk'
    variables:
      nullOk:
        kind: 'fragment'
        value: 'arguments[nullOk]'
''');
    await resolveTestCode('''
import '$importUri';

void f(BuildContext context) {
  Theme.of(context, nullOk: true);
}
''');
    await assertNoFix();
  }

  Future<void>
      test_material_Scaffold_resizeToAvoidBottomPadding_deprecated() async {
    setPackageContent('''
class Scaffold {
  @deprecated
  bool resizeToAvoidBottomPadding;
  bool resizeToAvoidBottomInset;
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to resizeToAvoidBottomInset'
    date: 2020-09-14
    element:
      uris: ['$importUri']
      field: 'resizeToAvoidBottomPadding'
      inClass: 'Scaffold'
    changes:
      - kind: 'rename'
        newName: 'resizeToAvoidBottomInset'
''');
    await resolveTestCode('''
import '$importUri';

void f(Scaffold scaffold) {
  scaffold.resizeToAvoidBottomPadding;
}
''');
    await assertHasFix('''
import '$importUri';

void f(Scaffold scaffold) {
  scaffold.resizeToAvoidBottomInset;
}
''');
  }

  Future<void>
      test_material_Scaffold_resizeToAvoidBottomPadding_removed() async {
    setPackageContent('''
class Scaffold {
  bool resizeToAvoidBottomInset;
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to resizeToAvoidBottomInset'
    date: 2020-09-14
    element:
      uris: ['$importUri']
      field: 'resizeToAvoidBottomPadding'
      inClass: 'Scaffold'
    changes:
      - kind: 'rename'
        newName: 'resizeToAvoidBottomInset'
''');
    await resolveTestCode('''
import '$importUri';

void f(Scaffold scaffold) {
  scaffold.resizeToAvoidBottomPadding;
}
''');
    await assertHasFix('''
import '$importUri';

void f(Scaffold scaffold) {
  scaffold.resizeToAvoidBottomInset;
}
''');
  }

  Future<void> test_material_showDialog_deprecated() async {
    setPackageContent('''
void showDialog({
  @deprecated Widget child,
  Widget Function(BuildContext) builder}) {}

class Widget {}
class BuildContext {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace child with builder'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      function: 'showDialog'
    changes:
      - kind: 'addParameter'
        index: 0
        name: 'builder'
        style: optional_named
        argumentValue:
          expression: '(context) => {% widget %}'
          requiredIf: "widget != ''"
          variables:
            widget:
              kind: fragment
              value: 'arguments[child]'
      - kind: 'removeParameter'
        name: 'child'
''');
    await resolveTestCode('''
import '$importUri';

void f(Widget widget) {
  showDialog(child: widget);
}
''');
    await assertHasFix('''
import '$importUri';

void f(Widget widget) {
  showDialog(builder: (context) => widget);
}
''');
  }

  Future<void> test_material_showDialog_removed() async {
    setPackageContent('''
void showDialog({
  @deprecated Widget child,
  Widget Function(BuildContext) builder}) {}

class Widget {}
class BuildContext {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace child with builder'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      function: 'showDialog'
    changes:
      - kind: 'addParameter'
        index: 0
        name: 'builder'
        style: optional_named
        argumentValue:
          expression: '(context) => {% widget %}'
          requiredIf: "widget != ''"
          variables:
            widget:
              kind: fragment
              value: 'arguments[child]'
      - kind: 'removeParameter'
        name: 'child'
''');
    await resolveTestCode('''
import '$importUri';

void f(Widget widget) {
  showDialog(child: widget);
}
''');
    await assertHasFix('''
import '$importUri';

void f(Widget widget) {
  showDialog(builder: (context) => widget);
}
''');
  }

  Future<void> test_material_TextTheme_copyWith_deprecated() async {
    setPackageContent('''
class TextTheme {
  TextTheme copyWith({TextStyle headline1, TextStyle headline2,
  TextStyle headline3, TextStyle headline4, TextStyle headline5,
  TextStyle headline6, TextStyle subtitle1, TextStyle subtitle2,
  TextStyle bodyText1, TextStyle bodyText2, TextStyle caption,
  TextStyle button, TextStyle overline,
  @deprecated TextStyle display4, @deprecated TextStyle display3,
  @deprecated TextStyle display2, @deprecated TextStyle display1,
  @deprecated TextStyle headline, @deprecated TextStyle title,
  @deprecated TextStyle subhead, @deprecated TextStyle subtitle,
  @deprecated TextStyle body2, @deprecated TextStyle body1}) {}
}
class TextStyle {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename arguments'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      method: 'copyWith'
      inClass: 'TextTheme'
    changes:
      - kind: 'renameParameter'
        oldName: 'display4'
        newName: 'headline1'
      - kind: 'renameParameter'
        oldName: 'display3'
        newName: 'headline2'
      - kind: 'renameParameter'
        oldName: 'display2'
        newName: 'headline3'
      - kind: 'renameParameter'
        oldName: 'display1'
        newName: 'headline4'
      - kind: 'renameParameter'
        oldName: 'headline'
        newName: 'headline5'
      - kind: 'renameParameter'
        oldName: 'title'
        newName: 'headline6'
      - kind: 'renameParameter'
        oldName: 'subhead'
        newName: 'subtitle1'
      - kind: 'renameParameter'
        oldName: 'subtitle'
        newName: 'subtitle2'
      - kind: 'renameParameter'
        oldName: 'body2'
        newName: 'bodytext1'
      - kind: 'renameParameter'
        oldName: 'body1'
        newName: 'bodytext2'
''');
    await resolveTestCode('''
import '$importUri';

void f(TextTheme t, TextStyle s) {
  t.copyWith(display2: s);
}
''');
    await assertHasFix('''
import '$importUri';

void f(TextTheme t, TextStyle s) {
  t.copyWith(headline3: s);
}
''');
  }

  Future<void> test_material_TextTheme_copyWith_removed() async {
    setPackageContent('''
class TextTheme {
  TextTheme copyWith({TextStyle headline1, TextStyle headline2,
  TextStyle headline3, TextStyle headline4, TextStyle headline5,
  TextStyle headline6, TextStyle subtitle1, TextStyle subtitle2,
  TextStyle bodyText1, TextStyle bodyText2, TextStyle caption,
  TextStyle button, TextStyle overline}) {}
}
class TextStyle {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename arguments'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      method: 'copyWith'
      inClass: 'TextTheme'
    changes:
      - kind: 'renameParameter'
        oldName: 'display4'
        newName: 'headline1'
      - kind: 'renameParameter'
        oldName: 'display3'
        newName: 'headline2'
      - kind: 'renameParameter'
        oldName: 'display2'
        newName: 'headline3'
      - kind: 'renameParameter'
        oldName: 'display1'
        newName: 'headline4'
      - kind: 'renameParameter'
        oldName: 'headline'
        newName: 'headline5'
      - kind: 'renameParameter'
        oldName: 'title'
        newName: 'headline6'
      - kind: 'renameParameter'
        oldName: 'subhead'
        newName: 'subtitle1'
      - kind: 'renameParameter'
        oldName: 'subtitle'
        newName: 'subtitle2'
      - kind: 'renameParameter'
        oldName: 'body2'
        newName: 'bodytext1'
      - kind: 'renameParameter'
        oldName: 'body1'
        newName: 'bodytext2'
''');
    await resolveTestCode('''
import '$importUri';

void f(TextTheme t, TextStyle s) {
  t.copyWith(subtitle: s);
}
''');
    await assertHasFix('''
import '$importUri';

void f(TextTheme t, TextStyle s) {
  t.copyWith(subtitle2: s);
}
''');
  }

  Future<void> test_material_TextTheme_defaultConstructor_deprecated() async {
    setPackageContent('''
class TextTheme {
  TextTheme({TextStyle headline1, TextStyle headline2, TextStyle headline3,
  TextStyle headline4, TextStyle headline5, TextStyle headline6,
  TextStyle subtitle1, TextStyle subtitle2, TextStyle bodyText1,
  TextStyle bodyText2, TextStyle caption, TextStyle button, TextStyle overline,
  @deprecated TextStyle display4, @deprecated TextStyle display3,
  @deprecated TextStyle display2, @deprecated TextStyle display1,
  @deprecated TextStyle headline, @deprecated TextStyle title,
  @deprecated TextStyle subhead, @deprecated TextStyle subtitle,
  @deprecated TextStyle body2, @deprecated TextStyle body1}) {}
}
class TextStyle {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename arguments'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'TextTheme'
    changes:
      - kind: 'renameParameter'
        oldName: 'display4'
        newName: 'headline1'
      - kind: 'renameParameter'
        oldName: 'display3'
        newName: 'headline2'
      - kind: 'renameParameter'
        oldName: 'display2'
        newName: 'headline3'
      - kind: 'renameParameter'
        oldName: 'display1'
        newName: 'headline4'
      - kind: 'renameParameter'
        oldName: 'headline'
        newName: 'headline5'
      - kind: 'renameParameter'
        oldName: 'title'
        newName: 'headline6'
      - kind: 'renameParameter'
        oldName: 'subhead'
        newName: 'subtitle1'
      - kind: 'renameParameter'
        oldName: 'subtitle'
        newName: 'subtitle2'
      - kind: 'renameParameter'
        oldName: 'body2'
        newName: 'bodytext1'
      - kind: 'renameParameter'
        oldName: 'body1'
        newName: 'bodytext2'
''');
    await resolveTestCode('''
import '$importUri';

void f(TextStyle s) {
  TextTheme(display4: s);
}
''');
    await assertHasFix('''
import '$importUri';

void f(TextStyle s) {
  TextTheme(headline1: s);
}
''');
  }

  Future<void> test_material_TextTheme_defaultConstructor_removed() async {
    setPackageContent('''
class TextTheme {
  TextTheme({TextStyle headline1, TextStyle headline2, TextStyle headline3,
  TextStyle headline4, TextStyle headline5, TextStyle headline6,
  TextStyle subtitle1, TextStyle subtitle2, TextStyle bodyText1,
  TextStyle bodyText2, TextStyle caption, TextStyle button, TextStyle overline,
  }) {}
}
class TextStyle {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename arguments'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'TextTheme'
    changes:
      - kind: 'renameParameter'
        oldName: 'display4'
        newName: 'headline1'
      - kind: 'renameParameter'
        oldName: 'display3'
        newName: 'headline2'
      - kind: 'renameParameter'
        oldName: 'display2'
        newName: 'headline3'
      - kind: 'renameParameter'
        oldName: 'display1'
        newName: 'headline4'
      - kind: 'renameParameter'
        oldName: 'headline'
        newName: 'headline5'
      - kind: 'renameParameter'
        oldName: 'title'
        newName: 'headline6'
      - kind: 'renameParameter'
        oldName: 'subhead'
        newName: 'subtitle1'
      - kind: 'renameParameter'
        oldName: 'subtitle'
        newName: 'subtitle2'
      - kind: 'renameParameter'
        oldName: 'body2'
        newName: 'bodytext1'
      - kind: 'renameParameter'
        oldName: 'body1'
        newName: 'bodytext2'
''');
    await resolveTestCode('''
import '$importUri';

void f(TextStyle s) {
  TextTheme(display3: s);
}
''');
    await assertHasFix('''
import '$importUri';

void f(TextStyle s) {
  TextTheme(headline2: s);
}
''');
  }

  Future<void> test_material_TextTheme_display4_deprecated() async {
    setPackageContent('''
class TextTheme {
  @deprecated
  int get display4 => 0;
  int get headline1 => 0;
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to headline1'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      getter: display4
      inClass: 'TextTheme'
    changes:
      - kind: 'rename'
        newName: 'headline1'
''');
    await resolveTestCode('''
import '$importUri';

void f(TextTheme theme) {
  theme.display4;
}
''');
    await assertHasFix('''
import '$importUri';

void f(TextTheme theme) {
  theme.headline1;
}
''');
  }

  Future<void> test_material_TextTheme_display4_removed() async {
    setPackageContent('''
class TextTheme {
  int get headline1 => 0;
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to headline1'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      getter: display4
      inClass: 'TextTheme'
    changes:
      - kind: 'rename'
        newName: 'headline1'
''');
    await resolveTestCode('''
import '$importUri';

void f(TextTheme theme) {
  theme.display4;
}
''');
    await assertHasFix('''
import '$importUri';

void f(TextTheme theme) {
  theme.headline1;
}
''');
  }

  Future<void> test_material_Typography_defaultConstructor_deprecated() async {
    setPackageContent('''
class Typography {
  @deprecated
  Typography();
  Typography.material2014();
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Use Typography.material2014'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'Typography'
    changes:
      - kind: 'rename'
        newName: 'material2014'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  Typography();
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  Typography.material2014();
}
''');
  }

  Future<void> test_material_Typography_defaultConstructor_removed() async {
    setPackageContent('''
class Typography {
  Typography.material2014();
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Use Typography.material2014'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'Typography'
    changes:
      - kind: 'rename'
        newName: 'material2014'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  Typography();
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  Typography.material2014();
}
''');
  }

  Future<void>
      test_widgets_BuildContext_ancestorInheritedElementForWidgetOfExactType_deprecated() async {
    setPackageContent('''
class BuildContext {
  @deprecated
  void ancestorInheritedElementForWidgetOfExactType(Type t) {}
  void getElementForInheritedWidgetOfExactType<T>() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to getElementForInheritedWidgetOfExactType'
    date: 2020-09-14
    element:
      uris: ['$importUri']
      method: 'ancestorInheritedElementForWidgetOfExactType'
      inClass: 'BuildContext'
    changes:
      - kind: 'rename'
        newName: 'getElementForInheritedWidgetOfExactType'
      - kind: 'addTypeParameter'
        index: 0
        name: 'T'
        argumentValue:
          expression: '{% type %}'
          variables:
            type:
              kind: 'fragment'
              value: 'arguments[0]'
      - kind: 'removeParameter'
        index: 0
''');
    await resolveTestCode('''
import '$importUri';

void f(BuildContext context) {
  context.ancestorInheritedElementForWidgetOfExactType(String);
}
''');
    await assertHasFix('''
import '$importUri';

void f(BuildContext context) {
  context.getElementForInheritedWidgetOfExactType<String>();
}
''');
  }

  Future<void>
      test_widgets_BuildContext_ancestorInheritedElementForWidgetOfExactType_removed() async {
    setPackageContent('''
class BuildContext {
  void getElementForInheritedWidgetOfExactType<T>() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to getElementForInheritedWidgetOfExactType'
    date: 2020-09-14
    element:
      uris: ['$importUri']
      method: 'ancestorInheritedElementForWidgetOfExactType'
      inClass: 'BuildContext'
    changes:
      - kind: 'rename'
        newName: 'getElementForInheritedWidgetOfExactType'
      - kind: 'addTypeParameter'
        index: 0
        name: 'T'
        argumentValue:
          expression: '{% type %}'
          variables:
            type:
              kind: 'fragment'
              value: 'arguments[0]'
      - kind: 'removeParameter'
        index: 0
''');
    await resolveTestCode('''
import '$importUri';

void f(BuildContext context) {
  context.ancestorInheritedElementForWidgetOfExactType(String);
}
''');
    await assertHasFix('''
import '$importUri';

void f(BuildContext context) {
  context.getElementForInheritedWidgetOfExactType<String>();
}
''');
  }

  Future<void>
      test_widgets_BuildContext_ancestorStateOfType_deprecated() async {
    setPackageContent('''
class BuildContext {
  @deprecated
  void ancestorStateOfType(TypeMatcher matcher) {}
  void findAncestorStateOfType<T>() {}
}
class TypeMatcher<T> {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to findAncestorStateOfType'
    date: 2020-09-14
    element:
      uris: ['$importUri']
      method: 'ancestorStateOfType'
      inClass: 'BuildContext'
    changes:
      - kind: 'rename'
        newName: 'findAncestorStateOfType'
      - kind: 'addTypeParameter'
        index: 0
        name: 'T'
        argumentValue:
          expression: '{% type %}'
          variables:
            type:
              kind: 'fragment'
              value: 'arguments[0].typeArguments[0]'
      - kind: 'removeParameter'
        index: 0
''');
    await resolveTestCode('''
import '$importUri';

void f(BuildContext context) {
  context.ancestorStateOfType(TypeMatcher<String>());
}
''');
    await assertHasFix('''
import '$importUri';

void f(BuildContext context) {
  context.findAncestorStateOfType<String>();
}
''');
  }

  Future<void>
      test_widgets_BuildContext_ancestorWidgetOfExactType_deprecated() async {
    setPackageContent('''
class BuildContext {
  @deprecated
  void ancestorWidgetOfExactType(Type t) {}
  void findAncestorWidgetOfExactType<T>() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to getElementForInheritedWidgetOfExactType'
    date: 2020-09-14
    element:
      uris: ['$importUri']
      method: 'ancestorWidgetOfExactType'
      inClass: 'BuildContext'
    changes:
      - kind: 'rename'
        newName: 'findAncestorWidgetOfExactType'
      - kind: 'addTypeParameter'
        index: 0
        name: 'T'
        argumentValue:
          expression: '{% type %}'
          variables:
            type:
              kind: 'fragment'
              value: 'arguments[0]'
      - kind: 'removeParameter'
        index: 0
''');
    await resolveTestCode('''
import '$importUri';

void f(BuildContext context) {
  context.ancestorWidgetOfExactType(String);
}
''');
    await assertHasFix('''
import '$importUri';

void f(BuildContext context) {
  context.findAncestorWidgetOfExactType<String>();
}
''');
  }

  Future<void>
      test_widgets_BuildContext_ancestorWidgetOfExactType_removed() async {
    setPackageContent('''
class BuildContext {
  void findAncestorWidgetOfExactType<T>() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to getElementForInheritedWidgetOfExactType'
    date: 2020-09-14
    element:
      uris: ['$importUri']
      method: 'ancestorWidgetOfExactType'
      inClass: 'BuildContext'
    changes:
      - kind: 'rename'
        newName: 'findAncestorWidgetOfExactType'
      - kind: 'addTypeParameter'
        index: 0
        name: 'T'
        argumentValue:
          expression: '{% type %}'
          variables:
            type:
              kind: 'fragment'
              value: 'arguments[0]'
      - kind: 'removeParameter'
        index: 0
''');
    await resolveTestCode('''
import '$importUri';

void f(BuildContext context) {
  context.ancestorWidgetOfExactType(String);
}
''');
    await assertHasFix('''
import '$importUri';

void f(BuildContext context) {
  context.findAncestorWidgetOfExactType<String>();
}
''');
  }

  Future<void> test_widgets_BuildContext_inheritFromElement_deprecated() async {
    setPackageContent('''
class BuildContext {
  @deprecated
  void inheritFromElement() {}
  void dependOnInheritedElement() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to dependOnInheritedElement'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      method: 'inheritFromElement'
      inClass: 'BuildContext'
    changes:
      - kind: 'rename'
        newName: 'dependOnInheritedElement'
''');
    await resolveTestCode('''
import '$importUri';

void f(BuildContext context) {
  context.inheritFromElement();
}
''');
    await assertHasFix('''
import '$importUri';

void f(BuildContext context) {
  context.dependOnInheritedElement();
}
''');
  }

  Future<void> test_widgets_BuildContext_inheritFromElement_removed() async {
    setPackageContent('''
class BuildContext {
  void dependOnInheritedElement() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to dependOnInheritedElement'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      method: 'inheritFromElement'
      inClass: 'BuildContext'
    changes:
      - kind: 'rename'
        newName: 'dependOnInheritedElement'
''');
    await resolveTestCode('''
import '$importUri';

void f(BuildContext context) {
  context.inheritFromElement();
}
''');
    await assertHasFix('''
import '$importUri';

void f(BuildContext context) {
  context.dependOnInheritedElement();
}
''');
  }

  Future<void>
      test_widgets_BuildContext_inheritFromWidgetOfExactType_deprecated() async {
    setPackageContent('''
class BuildContext {
  @deprecated
  void inheritFromWidgetOfExactType(Type t) {}
  void dependOnInheritedWidgetOfExactType<T>() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to dependOnInheritedWidgetOfExactType'
    date: 2020-09-14
    element:
      uris: ['$importUri']
      method: 'inheritFromWidgetOfExactType'
      inClass: 'BuildContext'
    changes:
      - kind: 'rename'
        newName: 'dependOnInheritedWidgetOfExactType'
      - kind: 'addTypeParameter'
        index: 0
        name: 'T'
        argumentValue:
          expression: '{% type %}'
          variables:
            type:
              kind: 'fragment'
              value: 'arguments[0]'
      - kind: 'removeParameter'
        index: 0
''');
    await resolveTestCode('''
import '$importUri';

void f(BuildContext context) {
  context.inheritFromWidgetOfExactType(String);
}
''');
    await assertHasFix('''
import '$importUri';

void f(BuildContext context) {
  context.dependOnInheritedWidgetOfExactType<String>();
}
''');
  }

  Future<void>
      test_widgets_BuildContext_inheritFromWidgetOfExactType_removed() async {
    setPackageContent('''
class BuildContext {
  void dependOnInheritedWidgetOfExactType<T>() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to dependOnInheritedWidgetOfExactType'
    date: 2020-09-14
    element:
      uris: ['$importUri']
      method: 'inheritFromWidgetOfExactType'
      inClass: 'BuildContext'
    changes:
      - kind: 'rename'
        newName: 'dependOnInheritedWidgetOfExactType'
      - kind: 'addTypeParameter'
        index: 0
        name: 'T'
        argumentValue:
          expression: '{% type %}'
          variables:
            type:
              kind: 'fragment'
              value: 'arguments[0]'
      - kind: 'removeParameter'
        index: 0
''');
    await resolveTestCode('''
import '$importUri';

void f(BuildContext context) {
  context.inheritFromWidgetOfExactType(String);
}
''');
    await assertHasFix('''
import '$importUri';

void f(BuildContext context) {
  context.dependOnInheritedWidgetOfExactType<String>();
}
''');
  }

  Future<void>
      test_widgets_Element_ancestorInheritedElementForWidgetOfExactType_deprecated() async {
    setPackageContent('''
class Element {
  @deprecated
  void ancestorInheritedElementForWidgetOfExactType(Type t) {}
  void getElementForInheritedWidgetOfExactType<T>() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to getElementForInheritedWidgetOfExactType'
    date: 2020-09-14
    element:
      uris: ['$importUri']
      method: 'ancestorInheritedElementForWidgetOfExactType'
      inClass: 'Element'
    changes:
      - kind: 'rename'
        newName: 'getElementForInheritedWidgetOfExactType'
      - kind: 'addTypeParameter'
        index: 0
        name: 'T'
        argumentValue:
          expression: '{% type %}'
          variables:
            type:
              kind: 'fragment'
              value: 'arguments[0]'
      - kind: 'removeParameter'
        index: 0
''');
    await resolveTestCode('''
import '$importUri';

void f(Element element) {
  element.ancestorInheritedElementForWidgetOfExactType(String);
}
''');
    await assertHasFix('''
import '$importUri';

void f(Element element) {
  element.getElementForInheritedWidgetOfExactType<String>();
}
''');
  }

  Future<void>
      test_widgets_Element_ancestorInheritedElementForWidgetOfExactType_removed() async {
    setPackageContent('''
class Element {
  void getElementForInheritedWidgetOfExactType<T>() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to getElementForInheritedWidgetOfExactType'
    date: 2020-09-14
    element:
      uris: ['$importUri']
      method: 'ancestorInheritedElementForWidgetOfExactType'
      inClass: 'Element'
    changes:
      - kind: 'rename'
        newName: 'getElementForInheritedWidgetOfExactType'
      - kind: 'addTypeParameter'
        index: 0
        name: 'T'
        argumentValue:
          expression: '{% type %}'
          variables:
            type:
              kind: 'fragment'
              value: 'arguments[0]'
      - kind: 'removeParameter'
        index: 0
''');
    await resolveTestCode('''
import '$importUri';

void f(Element element) {
  element.ancestorInheritedElementForWidgetOfExactType(String);
}
''');
    await assertHasFix('''
import '$importUri';

void f(Element element) {
  element.getElementForInheritedWidgetOfExactType<String>();
}
''');
  }

  Future<void>
      test_widgets_Element_ancestorWidgetOfExactType_deprecated() async {
    setPackageContent('''
class Element {
  @deprecated
  void ancestorWidgetOfExactType(Type t) {}
  void findAncestorWidgetOfExactType<T>() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to getElementForInheritedWidgetOfExactType'
    date: 2020-09-14
    element:
      uris: ['$importUri']
      method: 'ancestorWidgetOfExactType'
      inClass: 'Element'
    changes:
      - kind: 'rename'
        newName: 'findAncestorWidgetOfExactType'
      - kind: 'addTypeParameter'
        index: 0
        name: 'T'
        argumentValue:
          expression: '{% type %}'
          variables:
            type:
              kind: 'fragment'
              value: 'arguments[0]'
      - kind: 'removeParameter'
        index: 0
''');
    await resolveTestCode('''
import '$importUri';

void f(Element element) {
  element.ancestorWidgetOfExactType(String);
}
''');
    await assertHasFix('''
import '$importUri';

void f(Element element) {
  element.findAncestorWidgetOfExactType<String>();
}
''');
  }

  Future<void> test_widgets_Element_ancestorWidgetOfExactType_removed() async {
    setPackageContent('''
class Element {
  void findAncestorWidgetOfExactType<T>() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to getElementForInheritedWidgetOfExactType'
    date: 2020-09-14
    element:
      uris: ['$importUri']
      method: 'ancestorWidgetOfExactType'
      inClass: 'Element'
    changes:
      - kind: 'rename'
        newName: 'findAncestorWidgetOfExactType'
      - kind: 'addTypeParameter'
        index: 0
        name: 'T'
        argumentValue:
          expression: '{% type %}'
          variables:
            type:
              kind: 'fragment'
              value: 'arguments[0]'
      - kind: 'removeParameter'
        index: 0
''');
    await resolveTestCode('''
import '$importUri';

void f(Element element) {
  element.ancestorWidgetOfExactType(String);
}
''');
    await assertHasFix('''
import '$importUri';

void f(Element element) {
  element.findAncestorWidgetOfExactType<String>();
}
''');
  }

  Future<void> test_widgets_Element_inheritFromElement_deprecated() async {
    setPackageContent('''
class Element {
  @deprecated
  void inheritFromElement() {}
  void dependOnInheritedElement() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to dependOnInheritedElement'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      method: 'inheritFromElement'
      inClass: 'Element'
    changes:
      - kind: 'rename'
        newName: 'dependOnInheritedElement'
''');
    await resolveTestCode('''
import '$importUri';

void f(Element element) {
  element.inheritFromElement();
}
''');
    await assertHasFix('''
import '$importUri';

void f(Element element) {
  element.dependOnInheritedElement();
}
''');
  }

  Future<void> test_widgets_Element_inheritFromElement_removed() async {
    setPackageContent('''
class Element {
  void dependOnInheritedElement() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to dependOnInheritedElement'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      method: 'inheritFromElement'
      inClass: 'Element'
    changes:
      - kind: 'rename'
        newName: 'dependOnInheritedElement'
''');
    await resolveTestCode('''
import '$importUri';

void f(Element element) {
  element.inheritFromElement();
}
''');
    await assertHasFix('''
import '$importUri';

void f(Element element) {
  element.dependOnInheritedElement();
}
''');
  }

  Future<void>
      test_widgets_Element_inheritFromWidgetOfExactType_deprecated() async {
    setPackageContent('''
class Element {
  @deprecated
  void inheritFromWidgetOfExactType(Type t) {}
  void dependOnInheritedWidgetOfExactType<T>() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to dependOnInheritedWidgetOfExactType'
    date: 2020-09-14
    element:
      uris: ['$importUri']
      method: 'inheritFromWidgetOfExactType'
      inClass: 'Element'
    changes:
      - kind: 'rename'
        newName: 'dependOnInheritedWidgetOfExactType'
      - kind: 'addTypeParameter'
        index: 0
        name: 'T'
        argumentValue:
          expression: '{% type %}'
          variables:
            type:
              kind: 'fragment'
              value: 'arguments[0]'
      - kind: 'removeParameter'
        index: 0
''');
    await resolveTestCode('''
import '$importUri';

void f(Element element) {
  element.inheritFromWidgetOfExactType(String);
}
''');
    await assertHasFix('''
import '$importUri';

void f(Element element) {
  element.dependOnInheritedWidgetOfExactType<String>();
}
''');
  }

  Future<void>
      test_widgets_Element_inheritFromWidgetOfExactType_removed() async {
    setPackageContent('''
class Element {
  void dependOnInheritedWidgetOfExactType<T>() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to dependOnInheritedWidgetOfExactType'
    date: 2020-09-14
    element:
      uris: ['$importUri']
      method: 'inheritFromWidgetOfExactType'
      inClass: 'Element'
    changes:
      - kind: 'rename'
        newName: 'dependOnInheritedWidgetOfExactType'
      - kind: 'addTypeParameter'
        index: 0
        name: 'T'
        argumentValue:
          expression: '{% type %}'
          variables:
            type:
              kind: 'fragment'
              value: 'arguments[0]'
      - kind: 'removeParameter'
        index: 0
''');
    await resolveTestCode('''
import '$importUri';

void f(Element element) {
  element.inheritFromWidgetOfExactType(String);
}
''');
    await assertHasFix('''
import '$importUri';

void f(Element element) {
  element.dependOnInheritedWidgetOfExactType<String>();
}
''');
  }

  Future<void>
      test_widgets_ScrollPosition_jumpToWithoutSettling_deprecated() async {
    setPackageContent('''
class ScrollPosition {
  @deprecated
  void jumpToWithoutSettling(double d);
  void jumpTo(double d);
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to jumpTo'
    date: 2020-09-14
    element:
      uris: ['$importUri']
      method: 'jumpToWithoutSettling'
      inClass: 'ScrollPosition'
    changes:
      - kind: 'rename'
        newName: 'jumpTo'
''');
    await resolveTestCode('''
import '$importUri';

void f(ScrollPosition position) {
  position.jumpToWithoutSettling(0.5);
}
''');
    await assertHasFix('''
import '$importUri';

void f(ScrollPosition position) {
  position.jumpTo(0.5);
}
''');
  }

  Future<void>
      test_widgets_ScrollPosition_jumpToWithoutSettling_removed() async {
    setPackageContent('''
class ScrollPosition {
  void jumpTo(double d);
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to jumpTo'
    date: 2020-09-14
    element:
      uris: ['$importUri']
      method: 'jumpToWithoutSettling'
      inClass: 'ScrollPosition'
    changes:
      - kind: 'rename'
        newName: 'jumpTo'
''');
    await resolveTestCode('''
import '$importUri';

void f(ScrollPosition position) {
  position.jumpToWithoutSettling(0.5);
}
''');
    await assertHasFix('''
import '$importUri';

void f(ScrollPosition position) {
  position.jumpTo(0.5);
}
''');
  }

  Future<void>
      test_widgets_StatefulElement_inheritFromElement_deprecated() async {
    setPackageContent('''
class StatefulElement {
  @deprecated
  void inheritFromElement() {}
  void dependOnInheritedElement() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to dependOnInheritedElement'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      method: 'inheritFromElement'
      inClass: 'StatefulElement'
    changes:
      - kind: 'rename'
        newName: 'dependOnInheritedElement'
''');
    await resolveTestCode('''
import '$importUri';

void f(StatefulElement element) {
  element.inheritFromElement();
}
''');
    await assertHasFix('''
import '$importUri';

void f(StatefulElement element) {
  element.dependOnInheritedElement();
}
''');
  }

  Future<void> test_widgets_StatefulElement_inheritFromElement_removed() async {
    setPackageContent('''
class StatefulElement {
  void dependOnInheritedElement() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to dependOnInheritedElement'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      method: 'inheritFromElement'
      inClass: 'StatefulElement'
    changes:
      - kind: 'rename'
        newName: 'dependOnInheritedElement'
''');
    await resolveTestCode('''
import '$importUri';

void f(StatefulElement element) {
  element.inheritFromElement();
}
''');
    await assertHasFix('''
import '$importUri';

void f(StatefulElement element) {
  element.dependOnInheritedElement();
}
''');
  }

  Future<void>
      test_widgets_WidgetsBinding_allowFirstFrameReport_deprecated() async {
    setPackageContent('''
class WidgetsBinding {
  @deprecated
  void allowFirstFrameReport() {}
  void allowFirstFrame() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to allowFirstFrame'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      method: 'allowFirstFrameReport'
      inClass: 'WidgetsBinding'
    changes:
      - kind: 'rename'
        newName: 'allowFirstFrame'
''');
    await resolveTestCode('''
import '$importUri';

void f(WidgetsBinding binding) {
  binding.allowFirstFrameReport();
}
''');
    await assertHasFix('''
import '$importUri';

void f(WidgetsBinding binding) {
  binding.allowFirstFrame();
}
''');
  }

  Future<void>
      test_widgets_WidgetsBinding_allowFirstFrameReport_removed() async {
    setPackageContent('''
class WidgetsBinding {
  void allowFirstFrame() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to allowFirstFrame'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      method: 'allowFirstFrameReport'
      inClass: 'WidgetsBinding'
    changes:
      - kind: 'rename'
        newName: 'allowFirstFrame'
''');
    await resolveTestCode('''
import '$importUri';

void f(WidgetsBinding binding) {
  binding.allowFirstFrameReport();
}
''');
    await assertHasFix('''
import '$importUri';

void f(WidgetsBinding binding) {
  binding.allowFirstFrame();
}
''');
  }

  Future<void>
      test_widgets_WidgetsBinding_deferFirstFrameReport_deprecated() async {
    setPackageContent('''
class WidgetsBinding {
  @deprecated
  void deferFirstFrameReport() {}
  void deferFirstFrame() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to deferFirstFrame'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      method: 'deferFirstFrameReport'
      inClass: 'WidgetsBinding'
    changes:
      - kind: 'rename'
        newName: 'deferFirstFrame'
''');
    await resolveTestCode('''
import '$importUri';

void f(WidgetsBinding binding) {
  binding.deferFirstFrameReport();
}
''');
    await assertHasFix('''
import '$importUri';

void f(WidgetsBinding binding) {
  binding.deferFirstFrame();
}
''');
  }

  Future<void>
      test_widgets_WidgetsBinding_deferFirstFrameReport_removed() async {
    setPackageContent('''
class WidgetsBinding {
  void deferFirstFrame() {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Rename to deferFirstFrame'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      method: 'deferFirstFrameReport'
      inClass: 'WidgetsBinding'
    changes:
      - kind: 'rename'
        newName: 'deferFirstFrame'
''');
    await resolveTestCode('''
import '$importUri';

void f(WidgetsBinding binding) {
  binding.deferFirstFrameReport();
}
''');
    await assertHasFix('''
import '$importUri';

void f(WidgetsBinding binding) {
  binding.deferFirstFrame();
}
''');
  }
}
