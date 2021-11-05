// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'data_driven_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterBulkTest);
  });
}

@reflectiveTest
class FlutterBulkTest extends DataDrivenBulkFixProcessorTest {
  Future<void>
      test_material_ThemeData_textSelectionHandleColor_deprecated() async {
    setPackageContent('''
class ThemeData {
  ThemeData({
    @deprecated Color? textSelectionHandleColor,
    @deprecated bool useTextSelectionTheme = false,
    TextSelectionThemeData? textSelectionTheme}) {}
}
class TextSelectionThemeData {
  TextSelectionThemeData({Color selectionHandleColor}) {}
}
class Color {}
class Colors {
  static Color yellow = Color();
}
''');
    addPackageDataFile('''
version: 1
transforms:
  - title: "Migrate to 'TextSelectionThemeData'"
    date: 2020-09-24
    element:
      uris: ['$importUri']
      constructor: ''
      inClass: 'ThemeData'
    oneOf:
      - if: "textSelectionColor != '' && cursorColor != '' && textSelectionHandleColor != ''"
        changes:
          - kind: 'addParameter'
            index: 73
            name: 'textSelectionTheme'
            style: optional_named
            argumentValue:
              expression: 'TextSelectionThemeData(cursorColor: {% cursorColor %}, selectionColor: {% textSelectionColor %}, selectionHandleColor: {% textSelectionHandleColor %},)'
              requiredIf: "textSelectionColor != '' && cursorColor != '' && textSelectionHandleColor != ''"
          - kind: 'removeParameter'
            name: 'textSelectionColor'
          - kind: 'removeParameter'
            name: 'cursorColor'
          - kind: 'removeParameter'
            name: 'textSelectionHandleColor'
          - kind: 'removeParameter'
            name: 'useTextSelectionTheme'
      - if: "textSelectionColor == '' && cursorColor != '' && textSelectionHandleColor != ''"
        changes:
          - kind: 'addParameter'
            index: 73
            name: 'textSelectionTheme'
            style: optional_named
            argumentValue:
              expression: 'TextSelectionThemeData(cursorColor: {% cursorColor %}, selectionHandleColor: {% textSelectionHandleColor %},)'
              requiredIf: "textSelectionColor == '' && cursorColor != '' && textSelectionHandleColor != ''"
          - kind: 'removeParameter'
            name: 'cursorColor'
          - kind: 'removeParameter'
            name: 'textSelectionHandleColor'
          - kind: 'removeParameter'
            name: 'useTextSelectionTheme'
      - if: "textSelectionColor != '' && cursorColor != '' && textSelectionHandleColor == ''"
        changes:
          - kind: 'addParameter'
            index: 73
            name: 'textSelectionTheme'
            style: optional_named
            argumentValue:
              expression: 'TextSelectionThemeData(cursorColor: {% cursorColor %}, selectionColor: {% textSelectionColor %},)'
              requiredIf: "textSelectionColor != '' && cursorColor != '' && textSelectionHandleColor == ''"
          - kind: 'removeParameter'
            name: 'textSelectionColor'
          - kind: 'removeParameter'
            name: 'cursorColor'
          - kind: 'removeParameter'
            name: 'useTextSelectionTheme'
      - if: "textSelectionColor != '' && cursorColor == '' && textSelectionHandleColor != ''"
        changes:
          - kind: 'addParameter'
            index: 73
            name: 'textSelectionTheme'
            style: optional_named
            argumentValue:
              expression: 'TextSelectionThemeData(selectionColor: {% textSelectionColor %}, selectionHandleColor: {% textSelectionHandleColor %},)'
              requiredIf: "textSelectionColor != '' && cursorColor == '' && textSelectionHandleColor != ''"
          - kind: 'removeParameter'
            name: 'textSelectionColor'
          - kind: 'removeParameter'
            name: 'textSelectionHandleColor'
          - kind: 'removeParameter'
            name: 'useTextSelectionTheme'
      - if: "textSelectionColor == '' && cursorColor != '' && textSelectionHandleColor == ''"
        changes:
          - kind: 'addParameter'
            index: 73
            name: 'textSelectionTheme'
            style: optional_named
            argumentValue:
              expression: 'TextSelectionThemeData(cursorColor: {% cursorColor %})'
              requiredIf: "textSelectionColor == '' && cursorColor != '' && textSelectionHandleColor == ''"
          - kind: 'removeParameter'
            name: 'cursorColor'
          - kind: 'removeParameter'
            name: 'useTextSelectionTheme'
      - if: "textSelectionColor != '' && cursorColor == '' && textSelectionHandleColor == ''"
        changes:
          - kind: 'addParameter'
            index: 73
            name: 'textSelectionTheme'
            style: optional_named
            argumentValue:
              expression: 'TextSelectionThemeData(selectionColor: {% textSelectionColor %})'
              requiredIf: "textSelectionColor != '' && cursorColor == '' && textSelectionHandleColor == ''"
          - kind: 'removeParameter'
            name: 'textSelectionColor'
          - kind: 'removeParameter'
            name: 'useTextSelectionTheme'
      - if: "textSelectionColor == '' && cursorColor == '' && textSelectionHandleColor != ''"
        changes:
          - kind: 'addParameter'
            index: 73
            name: 'textSelectionTheme'
            style: optional_named
            argumentValue:
              expression: 'TextSelectionThemeData(selectionHandleColor: {% textSelectionHandleColor %})'
              requiredIf: "textSelectionColor == '' && cursorColor == '' && textSelectionHandleColor != ''"
          - kind: 'removeParameter'
            name: 'textSelectionHandleColor'
          - kind: 'removeParameter'
            name: 'useTextSelectionTheme'
      - if: "useTextSelectionTheme != ''"
        changes:
          - kind: 'removeParameter'
            name: 'useTextSelectionTheme'
    variables:
      textSelectionColor:
        kind: 'fragment'
        value: 'arguments[textSelectionColor]'
      cursorColor:
        kind: 'fragment'
        value: 'arguments[cursorColor]'
      textSelectionHandleColor:
        kind: 'fragment'
        value: 'arguments[textSelectionHandleColor]'
      useTextSelectionTheme:
        kind: 'fragment'
        value: 'arguments[useTextSelectionTheme]'
''');
    await resolveTestCode('''
import '$importUri';

void f() {
  ThemeData(textSelectionHandleColor: Colors.yellow, useTextSelectionTheme: false);
}
''');
    await assertHasFix('''
import '$importUri';

void f() {
  ThemeData(textSelectionTheme: TextSelectionThemeData(selectionHandleColor: Colors.yellow));
}
''');
  }
}
