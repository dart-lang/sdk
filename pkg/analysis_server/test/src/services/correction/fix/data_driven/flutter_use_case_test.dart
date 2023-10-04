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
  - title: 'Replace with CupertinoAlertDialog'
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

  Future<void>
      test_cupertino_CupertinoDialog_toCupertinoAlertDialog_removed() async {
    setPackageContent('''
class CupertinoAlertDialog {
  CupertinoAlertDialog({String content}) {}
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace with CupertinoAlertDialog'
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
      test_gestures_VelocityTracker_unnamedConstructor_withArg_deprecated() async {
    setPackageContent('''
class VelocityTracker {
  @deprecated
  VelocityTracker([PointerDeviceKind kind = PointerDeviceKind.touch]);
  VelocityTracker.withKind(PointerDeviceKind kind);
}
class PointerDeviceKind {
  static PointerDeviceKind mouse = PointerDeviceKind();
  static PointerDeviceKind touch = PointerDeviceKind();
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: "Use withKind"
    date: 2020-09-17
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'VelocityTracker'
    oneOf:
      - if: "pointerDeviceKind == ''"
        changes:
          - kind: 'rename'
            newName: 'withKind'
          - kind: 'addParameter'
            index: 0
            name: 'kind'
            style: required_positional
            argumentValue:
              expression: 'PointerDeviceKind.touch'
      - if: "pointerDeviceKind != ''"
        changes:
          - kind: 'rename'
            newName: 'withKind'
    variables:
      pointerDeviceKind:
        kind: 'fragment'
        value: 'arguments[0]'
''');
    await resolveTestCode('''
import '$importUri';

VelocityTracker tracker = VelocityTracker(PointerDeviceKind.mouse);
''');
    await assertHasFix('''
import '$importUri';

VelocityTracker tracker = VelocityTracker.withKind(PointerDeviceKind.mouse);
''');
  }

  Future<void>
      test_gestures_VelocityTracker_unnamedConstructor_withoutArg_deprecated() async {
    setPackageContent('''
class VelocityTracker {
  @deprecated
  VelocityTracker([PointerDeviceKind kind = PointerDeviceKind.touch]);
  VelocityTracker.withKind(PointerDeviceKind kind);
}
class PointerDeviceKind {
  static PointerDeviceKind touch = PointerDeviceKind();
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: "Use withKind"
    date: 2020-09-17
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'VelocityTracker'
    oneOf:
      - if: "pointerDeviceKind == ''"
        changes:
          - kind: 'rename'
            newName: 'withKind'
          - kind: 'addParameter'
            index: 0
            name: 'kind'
            style: required_positional
            argumentValue:
              expression: 'PointerDeviceKind.touch'
      - if: "pointerDeviceKind != ''"
        changes:
          - kind: 'rename'
            newName: 'withKind'
    variables:
      pointerDeviceKind:
        kind: 'fragment'
        value: 'arguments[0]'
''');
    await resolveTestCode('''
import '$importUri';

VelocityTracker tracker = VelocityTracker();
''');
    await assertHasFix('''
import '$importUri';

VelocityTracker tracker = VelocityTracker.withKind(PointerDeviceKind.touch);
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

  Future<void> test_material_Curve_standardEasing_deprecated() async {
    setPackageContent('''
abstract class Curve {
  const Curve();
}
class Cubic extends Curve {
  const Cubic(this.a, this.b, this.c, this.d);
}

abstract final class Curves {
  static const Cubic fastOutSlowIn = Cubic(0.4, 0.0, 0.2, 1.0);
}

class Easing {
  static const Curve legacy = Curves.fastOutSlowIn;
}

@deprecated
const Curve standardEasing = Curves.fastOutSlowIn;
''');

    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace by Easing.legacy'
    date: 2020-09-24
    element:
      uris: [  '$importUri' ]
      variable: 'standardEasing'
    changes:
    - kind: 'replacedBy'
      newElement:
        uris: [  '$importUri' ]
        field: legacy
        inClass: Easing
        static: true
''');
    await resolveTestCode('''
import '$importUri';

const Curve c = standardEasing;
''');
    await assertHasFix('''
import '$importUri';

const Curve c = Easing.legacy;
''');
  }

  Future<void> test_material_FlatButton_deprecated() async {
    setPackageContent('''
@deprecated
class FlatButton {
  factory FlatButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
    ValueChanged<bool>? onHighlightChanged,
    ButtonTextTheme? textTheme,
    Color? highlightColor,
    Brightness? colorBrightness,
    Clip? clipBehavior,
    FocusNode? focusNode,
    bool autofocus = true,
    required Widget icon,
    required Widget label,
  }) => FlatButton();
  FlatButton();
}
class Key {}
class UniqueKey extends Key {}
typedef VoidCallback = void Function();
typedef ValueChanged<T> = void Function(T value);
class ButtonTextTheme {}
class Color {}
class Colors {
  static Color blue = Color();
}
class Brightness {
  static Brightness dark = Brightness();
}
class Clip {
  static Clip hardEdge = Clip();
}
class FocusNode {}
class Widget {}
class Icon extends Widget {
  Icon(String icon);
}
class Text extends Widget {
  Text(String content);
}
class Icons {
  static String ten_k_outlined = '';
}
''');
    addPackageDataFile('''
version: 1
transforms:
  # Changes made in https://github.com/flutter/flutter/pull/73352
  - title: "Migrate to 'TextButton.icon'"
    date: 2021-01-08
    element:
      uris: [ '$importUri' ]
      constructor: 'icon'
      inClass: 'FlatButton'
    changes:
      - kind: 'removeParameter'
        name: 'onHighlightChanged'
      - kind: 'removeParameter'
        name: 'textTheme'
      - kind: 'removeParameter'
        name: 'highlightColor'
      - kind: 'removeParameter'
        name: 'colorBrightness'
      - kind: 'replacedBy'
        newElement:
          uris: [ '$importUri' ]
          constructor: 'icon'
          inClass: 'TextButton'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  FlatButton.icon(
    key: UniqueKey(),
    icon: Icon(Icons.ten_k_outlined),
    label: Text('FlatButton'),
    onPressed: (){},
    onLongPress: (){},
    clipBehavior: Clip.hardEdge,
    focusNode: FocusNode(),
    autofocus: true,
    onHighlightChanged: (_) {},
    textTheme: ButtonTextTheme(),
    highlightColor: Colors.blue,
    colorBrightness: Brightness.dark,
  );
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  TextButton.icon(
    key: UniqueKey(),
    icon: Icon(Icons.ten_k_outlined),
    label: Text('FlatButton'),
    onPressed: (){},
    onLongPress: (){},
    clipBehavior: Clip.hardEdge,
    focusNode: FocusNode(),
    autofocus: true,
  );
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

  Future<void>
      test_material_ThemeData_colorSchemeBackground_deprecated() async {
    setPackageContent('''

class ThemeData {

  @deprecated
  final Color  backgroundColor;
  final ColorScheme colorScheme;
  ThemeData(this.backgroundColor): colorScheme = ColorScheme(backgroundColor){}
}

class Color {
  Color(int value) {}
}

class Colors {
  Colors._();

  static Color black = Color(0xFF000000);
  static Color white = Color(0xFFFFFFFF);
}

class ColorScheme {
    final Color background;
    ColorScheme(this.background);
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title:  "Migrate to 'ColorScheme.background'"
    date: 2020-09-24
    element:
      uris: ['$importUri']
      field: 'backgroundColor'
      inClass: 'ThemeData'
    changes:
      - kind: 'rename'
        newName: 'colorScheme.background'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  var themeData = ThemeData(Colors.black);
  var color = themeData.backgroundColor;
  print(color);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  var themeData = ThemeData(Colors.black);
  var color = themeData.colorScheme.background;
  print(color);
}
''');
  }

  Future<void>
      test_material_ThemeData_colorSchemeBackground_deprecated_noFix() async {
    setPackageContent('''

class ThemeData {

  @deprecated
  final Color  backgroundColor;
  final ColorScheme colorScheme;
  ThemeData(this.backgroundColor): colorScheme = ColorScheme(backgroundColor){}
}

class Color {
  Color(int value) {}
}

class Colors {
  Colors._();

  static Color black = Color(0xFF000000);
  static Color white = Color(0xFFFFFFFF);
}

class ColorScheme {
    final Color background;
    ColorScheme(this.background);
}

class ElevatedButton {
   Color? color;

  ElevatedButton(this.color);

  static  ElevatedButton styleFrom({Color? backgroundColor}) {
    return ElevatedButton(backgroundColor);
  }
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title:  "Migrate to 'ColorScheme.background'"
    date: 2020-09-24
    element:
      uris: ['$importUri']
      field: 'backgroundColor'
      inClass: 'ThemeData'
    changes:
      - kind: 'rename'
        newName: 'colorScheme.background'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  var a = ElevatedButton.styleFrom(backgroundColor: backgroundColor);
  print(a);
}
''');
    await assertNoFix();
  }

  Future<void>
      test_material_ThemeData_colorSchemeBackground_deprecated_noFix2() async {
    setPackageContent('''

class ThemeData {

  @deprecated
  final Color  backgroundColor;
  final ColorScheme colorScheme;
  ThemeData(this.backgroundColor): colorScheme = ColorScheme(backgroundColor){}
}

class Color {
  Color(int value) {}
}

class Colors {
  Colors._();

  static Color black = Color(0xFF000000);
  static Color white = Color(0xFFFFFFFF);
}

class ColorScheme {
    final Color background;
    ColorScheme(this.background);
}

class ElevatedButton {
   Color? color;

  ElevatedButton(this.color);

  static  ElevatedButton styleFrom({Color? backgroundColor}) {
    return ElevatedButton(backgroundColor);
  }
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title:  "Migrate to 'ColorScheme.background'"
    date: 2020-09-24
    element:
      uris: ['$importUri']
      field: 'backgroundColor'
      inClass: 'ThemeData'
    changes:
      - kind: 'rename'
        newName: 'colorScheme.background'
''');
    await resolveTestCode('''
import '$importUri';

class E {
  void m() {
    var a = ElevatedButton.styleFrom(backgroundColor: backgroundColor);
    print(a);
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_material_ThemeData_colorSchemeBackground_removed() async {
    setPackageContent('''

class ThemeData {

  final ColorScheme colorScheme;
  ThemeData(this.backgroundColor): colorScheme = ColorScheme(backgroundColor){}
}

class Color {
  Color(int value) {}
}

class Colors {
  Colors._();

  static Color black = Color(0xFF000000);
  static Color white = Color(0xFFFFFFFF);
}

class ColorScheme {
    final Color background;
    ColorScheme(this.background);
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title:  "Migrate to 'ColorScheme.background'"
    date: 2020-09-24
    element:
      uris: ['$importUri']
      field: 'backgroundColor'
      inClass: 'ThemeData'
    changes:
      - kind: 'rename'
        newName: 'colorScheme.background'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  var themeData = ThemeData(Colors.black);
  var color = themeData.backgroundColor;
  print(color);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  var themeData = ThemeData(Colors.black);
  var color = themeData.colorScheme.background;
  print(color);
}
''');
  }

  Future<void> test_material_ThemeData_colorSchemeBackground_removed2() async {
    setPackageContent('''

class ThemeData {

  final ColorScheme colorScheme;
  ThemeData(this.backgroundColor): colorScheme = ColorScheme(backgroundColor){}
}

class Color {
  Color(int value) {}
}

class Colors {
  Colors._();

  static Color black = Color(0xFF000000);
  static Color white = Color(0xFFFFFFFF);
}

class ColorScheme {
    final Color background;
    ColorScheme(this.background);
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title:  "Migrate to 'ColorScheme.background'"
    date: 2020-09-24
    element:
      uris: ['$importUri']
      field: 'backgroundColor'
      inClass: 'ThemeData'
    changes:
      - kind: 'rename'
        newName: 'colorScheme.background'
''');
    await resolveTestCode('''
import '$importUri';

class T extends ThemeData {
  T(Color color) : super(color);

  void f() {
    var color = backgroundColor;
    print(color);
  }
}
''');
    await assertHasFix('''
import '$importUri';

class T extends ThemeData {
  T(Color color) : super(color);

  void f() {
    var color = colorScheme.background;
    print(color);
  }
}
''');
  }

  Future<void>
      test_material_ThemeData_toggleableActiveColor_deprecated_1() async {
    setPackageContent('''

class ThemeData {
  ThemeData({
    Color? primaryColor,
    Color? primaryColorLight,
    Color? primaryColorDark,
    Color? focusColor,
    Color? hoverColor,
    @deprecated
    Color? toggleableActiveColor,
    CheckboxThemeData? checkboxTheme,
    DataTableThemeData? dataTableTheme,
    RadioThemeData? radioTheme,
    SliderThemeData? sliderTheme,
  }) {}
}

class Color {
  Color(int value) {}
}

class Colors {
  Colors._();

  static Color black = Color(0xFF000000);
  static Color white = Color(0xFFFFFFFF);
}

class CheckboxThemeData {}

class DataTableThemeData {}

class RadioThemeData {}

class SliderThemeData {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Migrate ThemeData.toggleableActiveColor to individual themes'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'ThemeData'
    changes:
      - kind: 'removeParameter'
        name: 'toggleableActiveColor'
      - kind: 'addParameter'
        index: 6
        name: 'checkboxTheme'
        style: optional_named
        argumentValue:
          expression: "CheckboxThemeData()"
          requiredIf: "toggleableActiveColor != ''"
      - kind: 'addParameter'
        index: 8
        name: 'radioTheme'
        style: optional_named
        argumentValue:
          expression: "RadioThemeData()"
          requiredIf:  "toggleableActiveColor != ''"
    variables:
      toggleableActiveColor:
        kind: 'fragment'
        value: 'arguments[toggleableActiveColor]'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  ThemeData themeData = ThemeData();
  themeData = ThemeData(toggleableActiveColor: Colors.black);
  print(themeData);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  ThemeData themeData = ThemeData();
  themeData = ThemeData(checkboxTheme: CheckboxThemeData(), radioTheme: RadioThemeData());
  print(themeData);
}
''');
  }

  Future<void>
      test_material_ThemeData_toggleableActiveColor_deprecated_2() async {
    setPackageContent('''

class ThemeData {
  ThemeData({
    Color? primaryColor,
    Color? primaryColorLight,
    Color? primaryColorDark,
    Color? focusColor,
    Color? hoverColor,
    @deprecated
    Color? toggleableActiveColor,
    CheckboxThemeData? checkboxTheme,
    DataTableThemeData? dataTableTheme,
    RadioThemeData? radioTheme,
    SliderThemeData? sliderTheme,
  }) {}
}

class Color {
  Color(int value) {}
}

class Colors {
  Colors._();

  static Color black = Color(0xFF000000);
  static Color white = Color(0xFFFFFFFF);
}

class CheckboxThemeData {}

class DataTableThemeData {}

class RadioThemeData {}

class SliderThemeData {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Migrate ThemeData.toggleableActiveColor to individual themes'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'ThemeData'
    changes:
      - kind: 'removeParameter'
        name: 'toggleableActiveColor'
      - kind: 'addParameter'
        index: 6
        name: 'checkboxTheme'
        style: optional_named
        argumentValue:
          expression: "CheckboxThemeData()"
          requiredIf: "toggleableActiveColor != ''"
      - kind: 'addParameter'
        index: 8
        name: 'radioTheme'
        style: optional_named
        argumentValue:
          expression: "RadioThemeData()"
          requiredIf:  "toggleableActiveColor != ''"
    variables:
      toggleableActiveColor:
        kind: 'fragment'
        value: 'arguments[toggleableActiveColor]'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  ThemeData themeData = ThemeData();
  themeData = ThemeData(
    focusColor: Colors.black,
    toggleableActiveColor: Colors.black,
    hoverColor: Colors.white,
    primaryColor: Colors.white,
    sliderTheme: SliderThemeData()
  );
  print(themeData);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  ThemeData themeData = ThemeData();
  themeData = ThemeData(
    focusColor: Colors.black,
    hoverColor: Colors.white,
    primaryColor: Colors.white,
    sliderTheme: SliderThemeData(), checkboxTheme: CheckboxThemeData(), radioTheme: RadioThemeData()
  );
  print(themeData);
}
''');
  }

  Future<void> test_material_ThemeData_toggleableActiveColor_removed_1() async {
    setPackageContent('''

class ThemeData {
  ThemeData({
    Color? primaryColor,
    Color? primaryColorLight,
    Color? primaryColorDark,
    Color? focusColor,
    Color? hoverColor,
    CheckboxThemeData? checkboxTheme,
    DataTableThemeData? dataTableTheme,
    RadioThemeData? radioTheme,
    SliderThemeData? sliderTheme,
  }) {}
}

class Color {
  Color(int value) {}
}

class Colors {
  Colors._();

  static Color black = Color(0xFF000000);
  static Color white = Color(0xFFFFFFFF);
}

class CheckboxThemeData {}

class DataTableThemeData {}

class RadioThemeData {}

class SliderThemeData {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Migrate ThemeData.toggleableActiveColor to individual themes'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'ThemeData'
    changes:
      - kind: 'removeParameter'
        name: 'toggleableActiveColor'
      - kind: 'addParameter'
        index: 6
        name: 'checkboxTheme'
        style: optional_named
        argumentValue:
          expression: "CheckboxThemeData()"
          requiredIf: "toggleableActiveColor != ''"
      - kind: 'addParameter'
        index: 8
        name: 'radioTheme'
        style: optional_named
        argumentValue:
          expression: "RadioThemeData()"
          requiredIf:  "toggleableActiveColor != ''"
    variables:
      toggleableActiveColor:
        kind: 'fragment'
        value: 'arguments[toggleableActiveColor]'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  ThemeData themeData = ThemeData();
  themeData = ThemeData(toggleableActiveColor: Colors.black);
  print(themeData);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  ThemeData themeData = ThemeData();
  themeData = ThemeData(checkboxTheme: CheckboxThemeData(), radioTheme: RadioThemeData());
  print(themeData);
}
''');
  }

  Future<void> test_material_ThemeData_toggleableActiveColor_removed_2() async {
    setPackageContent('''

class ThemeData {
  ThemeData({
    Color? primaryColor,
    Color? primaryColorLight,
    Color? primaryColorDark,
    Color? focusColor,
    Color? hoverColor,
    CheckboxThemeData? checkboxTheme,
    DataTableThemeData? dataTableTheme,
    RadioThemeData? radioTheme,
    SliderThemeData? sliderTheme,
  }) {}
}

class Color {
  Color(int value) {}
}

class Colors {
  Colors._();

  static Color black = Color(0xFF000000);
  static Color white = Color(0xFFFFFFFF);
}

class CheckboxThemeData {}

class DataTableThemeData {}

class RadioThemeData {}

class SliderThemeData {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Migrate ThemeData.toggleableActiveColor to individual themes'
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'ThemeData'
    changes:
      - kind: 'removeParameter'
        name: 'toggleableActiveColor'
      - kind: 'addParameter'
        index: 6
        name: 'checkboxTheme'
        style: optional_named
        argumentValue:
          expression: "CheckboxThemeData()"
          requiredIf: "toggleableActiveColor != ''"
      - kind: 'addParameter'
        index: 8
        name: 'radioTheme'
        style: optional_named
        argumentValue:
          expression: "RadioThemeData()"
          requiredIf:  "toggleableActiveColor != ''"
    variables:
      toggleableActiveColor:
        kind: 'fragment'
        value: 'arguments[toggleableActiveColor]'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  ThemeData themeData = ThemeData();
  themeData = ThemeData(
    focusColor: Colors.black,
    toggleableActiveColor: Colors.black,
    hoverColor: Colors.white,
    primaryColor: Colors.white,
    sliderTheme: SliderThemeData()
  );
  print(themeData);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  ThemeData themeData = ThemeData();
  themeData = ThemeData(
    focusColor: Colors.black,
    hoverColor: Colors.white,
    primaryColor: Colors.white,
    sliderTheme: SliderThemeData(), checkboxTheme: CheckboxThemeData(), radioTheme: RadioThemeData()
  );
  print(themeData);
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

  Future<void> test_services_ClipboardData_changeParameterNonNull() async {
    setPackageContent('''
class ClipboardData {
  const ClipboardData({required String this.text});

  final String? text;
}
''');

    addPackageDataFile('''
version: 1
transforms:
  - title: "Migrate to empty 'text' string"
    date: 2023-04-19
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'ClipboardData'
    changes:
      - kind: 'changeParameterType'
        name: 'text'
        nullability: non_null
        argumentValue:
          expression: "''"
''');

    await resolveTestCode('''
import '$importUri';

void f() {
  var c = ClipboardData(text: null);
  print(c);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  var c = ClipboardData(text: '');
  print(c);
}
''');
  }

  Future<void>
      test_services_ClipboardData_changeParameterNonNullAbsent() async {
    setPackageContent('''
class ClipboardData {
  const ClipboardData({required String this.text});

  final String? text;
}
''');

    addPackageDataFile('''
version: 1
transforms:
  - title: "Migrate to empty 'text' string"
    date: 2023-04-19
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'ClipboardData'
    changes:
      - kind: 'changeParameterType'
        name: 'text'
        nullability: non_null
        argumentValue:
          expression: "''"
''');

    await resolveTestCode('''
import '$importUri';

void f() {
  var c = ClipboardData();
  print(c);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  var c = ClipboardData(text: '');
  print(c);
}
''');
  }

  Future<void>
      test_services_ClipboardData_changeParameterNonNullAdditional() async {
    setPackageContent('''
class ClipboardData {
  const ClipboardData({required String this.text, String? this.p});

  final String? text;
  final String? p;
}
''');

    addPackageDataFile('''
version: 1
transforms:
  - title: "Migrate to empty 'text' string"
    date: 2023-04-19
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'ClipboardData'
    changes:
      - kind: 'changeParameterType'
        name: 'text'
        nullability: non_null
        argumentValue:
          expression: "''"
''');

    await resolveTestCode('''
import '$importUri';

void f() {
  var c = ClipboardData(text: null, p: 'hello');
  print(c);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  var c = ClipboardData(text: '', p: 'hello');
  print(c);
}
''');
  }

  Future<void> test_services_ClipboardData_changePositionalParameter() async {
    setPackageContent('''
class ClipboardData {
  const ClipboardData(this.text, this.p);

  final String text;
  final String p;
}
''');

    addPackageDataFile('''
version: 1
transforms:
  - title: "Migrate to empty 'text' string"
    date: 2023-04-19
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'ClipboardData'
    changes:
      - kind: 'changeParameterType'
        index: 1
        nullability: non_null
        argumentValue:
          expression: "''"
''');

    await resolveTestCode('''
import '$importUri';

void f() {
  var c = ClipboardData('hello', null);
  print(c);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  var c = ClipboardData('hello', '');
  print(c);
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

  Future<void> test_widgets_Stack_overflow_clip() async {
    setPackageContent('''
class Stack {
  const Stack({
    @deprecated Overflow overflow: Overflow.clip,
    Clip clipBehavior: Clip.hardEdge,
    List<Widget> children: const <Widget>[]});
}
class Overflow {
  static const Overflow clip = Overflow();
  static const Overflow visible = Overflow();
  const Overflow();
}
class Clip {
  static const Clip hardEdge = Clip();
  static const Clip none = Clip();
  const Clip();
}
class Widget {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: "Migrate to 'clipBehavior'"
    date: 2020-09-22
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'Stack'
    oneOf:
      - if: "overflow == 'Overflow.clip'"
        changes:
          - kind: 'addParameter'
            index: 0
            name: 'clipBehavior'
            style: optional_named
            argumentValue:
              expression: 'Clip.hardEdge'
              requiredIf: "overflow == 'Overflow.clip'"
          - kind: 'removeParameter'
            name: 'overflow'
      - if: "overflow == 'Overflow.visible'"
        changes:
          - kind: 'addParameter'
            index: 0
            name: 'clipBehavior'
            style: optional_named
            argumentValue:
              expression: 'Clip.none'
              requiredIf: "overflow == 'Overflow.visible'"
          - kind: 'removeParameter'
            name: 'overflow'
    variables:
      overflow:
        kind: 'fragment'
        value: 'arguments[overflow]'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  const Stack(overflow: Overflow.clip, children: []);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  const Stack(clipBehavior: Clip.hardEdge, children: []);
}
''');
  }

  Future<void> test_widgets_Stack_overflow_visible() async {
    setPackageContent('''
class Stack {
  const Stack({
    @deprecated Overflow overflow: Overflow.clip,
    Clip clipBehavior: Clip.hardEdge,
    List<Widget> children: const <Widget>[]});
}
class Overflow {
  static const Overflow clip = Overflow();
  static const Overflow visible = Overflow();
  const Overflow();
}
class Clip {
  static const Clip hardEdge = Clip();
  static const Clip none = Clip();
  const Clip();
}
class Widget {}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: "Migrate to 'clipBehavior'"
    date: 2020-09-22
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'Stack'
    oneOf:
      - if: "overflow == 'Overflow.clip'"
        changes:
          - kind: 'addParameter'
            index: 0
            name: 'clipBehavior'
            style: optional_named
            argumentValue:
              expression: 'Clip.hardEdge'
              requiredIf: "overflow == 'Overflow.clip'"
          - kind: 'removeParameter'
            name: 'overflow'
      - if: "overflow == 'Overflow.visible'"
        changes:
          - kind: 'addParameter'
            index: 0
            name: 'clipBehavior'
            style: optional_named
            argumentValue:
              expression: 'Clip.none'
              requiredIf: "overflow == 'Overflow.visible'"
          - kind: 'removeParameter'
            name: 'overflow'
    variables:
      overflow:
        kind: 'fragment'
        value: 'arguments[overflow]'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  const Stack(overflow: Overflow.visible, children: []);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  const Stack(clipBehavior: Clip.none, children: []);
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
      test_widgets_WidgetsApp_debugShowWidgetInspectorOverride_replace() async {
    setPackageContent('''
class WidgetsApp {
  @deprecated
  static bool debugShowWidgetInspectorOverride = false;
  static ValueNotifier<bool> debugShowWidgetInspectorOverrideNotifier = ValueNotifier<bool>(false);
}

class ValueNotifier<T> {
  ValueNotifier(this._value);

  T get value => _value;
  T _value;
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: "Migrate to 'debugShowWidgetInspectorOverrideNotifier'"
    date: 2023-03-13
    element:
      uris: ['$importUri']
      field: 'debugShowWidgetInspectorOverride'
      inClass: 'WidgetsApp'
      static: true
    changes:
      - kind: 'replacedBy'
        newElement:
          uris: ['$importUri']
          field: 'debugShowWidgetInspectorOverrideNotifier.value'
          inClass: 'WidgetsApp'
          static: true
  ''');

    await resolveTestCode('''
import '$importUri';

void f() {
  WidgetsApp.debugShowWidgetInspectorOverride = true;
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  WidgetsApp.debugShowWidgetInspectorOverrideNotifier.value = true;
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

  Future<void> test_widgets_WidgetsBinding_window_replace_with_view() async {
    setPackageContent('''
class Window {}

class BuildContext{}

class View {
  static void of(BuildContext context){}
}
class WidgetsBinding {
  static WidgetsBinding get instance => _instance!;
  static WidgetsBinding? _instance;
  final Window _window = Window();
  @deprecated
  Window get window => _window;
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: 'Replace window with View.of'
    date: 2023-05-14
    element:
      uris: ['$importUri']
      getter: 'window'
      inClass: 'WidgetsBinding'
    changes:
      - kind: 'replacedBy'
        replaceTarget: true
        newElement:
          uris: ['$importUri']
          method: 'of'
          inClass: 'View'
          static: true
        arguments: [
          expression: 'context'
        ]
    variables:
      context:
        kind: import
        uris: [ '$importUri' ]
        name: 'BuildContext'
''');
    await resolveTestCode('''
import '$importUri';

void f(WidgetsBinding binding) {
  WidgetsBinding.instance.window;
}
''');
    await assertHasFix('''
import '$importUri';

void f(WidgetsBinding binding) {
  View.of(context);
}
''');
  }
}
