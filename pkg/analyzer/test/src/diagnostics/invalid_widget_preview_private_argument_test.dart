// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidWidgetPreviewPrivateArgumentTest);
  });
}

@reflectiveTest
class InvalidWidgetPreviewPrivateArgumentTest extends PubPackageResolutionTest {
  String correctionMessageBuilder(String original, String public) {
    return "Rename private symbol '$original' to '$public'.";
  }

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(PackageConfigFileBuilder(), flutter: true);
  }

  test_invalidPrivatePreviewArgument() async {
    const String kPrivateName = '_privateName';

    await resolveTestCodeWithDiagnostics('''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

const String $kPrivateName = 'Name';

@Preview(name: $kPrivateName)
//       ^^^^^^^^^^^^^^^^^^
// [diag.invalidWidgetPreviewPrivateArgument] '@Preview(...)' can only accept arguments that consist of literals and public symbols.
Widget privateName() => Text('Foo');
''');
  }

  test_invalidPrivatePreviewArguments_extraPrivate() async {
    const String kExtraPrivateName = '__extraPrivateName';

    await resolveTestCodeWithDiagnostics('''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

const String $kExtraPrivateName = 'Extra';

@Preview(name: $kExtraPrivateName)
//       ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidWidgetPreviewPrivateArgument] '@Preview(...)' can only accept arguments that consist of literals and public symbols.
Widget extraPrivateName() => Text('Foo');
''');
  }

  test_invalidPrivatePreviewArguments_inArgumentExpression() async {
    const String kPrivateTextScaleFactor = '_textScaleFactor';

    await resolveTestCodeWithDiagnostics('''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

const double $kPrivateTextScaleFactor = 2.0;

@Preview(textScaleFactor: $kPrivateTextScaleFactor + 1)
//       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidWidgetPreviewPrivateArgument] '@Preview(...)' can only accept arguments that consist of literals and public symbols.
Widget numericExpressionWithPrivateDouble() => Text('Foo');
''');
  }

  test_invalidPrivatePreviewArguments_interpolatedInStringArgument() async {
    const String kPrivateName = '_privateName';

    await resolveTestCodeWithDiagnostics('''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

const String $kPrivateName = 'Name';

@Preview(name: '\$$kPrivateName')
//       ^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidWidgetPreviewPrivateArgument] '@Preview(...)' can only accept arguments that consist of literals and public symbols.
Widget privateNameStringInterp() => Text('Foo');
''');
  }

  test_invalidPrivatePreviewArguments_size() async {
    const String kPrivateSize = '_privateSize';
    const String kPrivateTextScaleFactor = '_textScaleFactor';

    await resolveTestCodeWithDiagnostics('''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

const Size $kPrivateSize =  Size(42.0, 24.0);
const double $kPrivateTextScaleFactor = 2.0;

@Preview(
  size: $kPrivateSize,
//^^^^^^^^^^^^^^^^^^
// [diag.invalidWidgetPreviewPrivateArgument] '@Preview(...)' can only accept arguments that consist of literals and public symbols.
  textScaleFactor: $kPrivateTextScaleFactor,
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidWidgetPreviewPrivateArgument] '@Preview(...)' can only accept arguments that consist of literals and public symbols.
)
Widget privateDoubles() => Text('Foo');
''');
  }

  test_invalidPrivatePreviewArguments_theme() async {
    const String kPrivateTheme = '_privateTheme';

    await resolveTestCodeWithDiagnostics('''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

PreviewThemeData $kPrivateTheme() => PreviewThemeData();

@Preview(theme: $kPrivateTheme)
//       ^^^^^^^^^^^^^^^^^^^^
// [diag.invalidWidgetPreviewPrivateArgument] '@Preview(...)' can only accept arguments that consist of literals and public symbols.
Widget privateThemeData() => Text('Foo');
''');
  }

  test_invalidPrivatePreviewArguments_wrapper() async {
    const String kPrivateWrapper = '_privateWrapper';

    await resolveTestCodeWithDiagnostics('''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

Widget $kPrivateWrapper(Widget child) => child;

@Preview(wrapper: $kPrivateWrapper)
//       ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.invalidWidgetPreviewPrivateArgument] '@Preview(...)' can only accept arguments that consist of literals and public symbols.
Widget privateWrapper() => Text('Foo');
''');
  }
}
