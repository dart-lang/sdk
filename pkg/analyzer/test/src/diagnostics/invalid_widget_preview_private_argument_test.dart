// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/utilities/package_config_file_builder.dart';
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

    await assertErrorsInCode(
      '''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

const String $kPrivateName = 'Name';

@Preview(name: $kPrivateName)
Widget privateName() => Text('Foo');
''',
      [
        error(
          diag.invalidWidgetPreviewPrivateArgument,
          133,
          18,
          correctionContains: correctionMessageBuilder(
            kPrivateName,
            kPrivateName.substring(1),
          ),
        ),
      ],
    );
  }

  test_invalidPrivatePreviewArguments_extraPrivate() async {
    const String kExtraPrivateName = '__extraPrivateName';

    await assertErrorsInCode(
      '''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

const String $kExtraPrivateName = 'Extra';

@Preview(name: $kExtraPrivateName)
Widget extraPrivateName() => Text('Foo');
''',
      [
        error(
          diag.invalidWidgetPreviewPrivateArgument,
          140,
          24,
          correctionContains: correctionMessageBuilder(
            kExtraPrivateName,
            kExtraPrivateName.substring(2),
          ),
        ),
      ],
    );
  }

  test_invalidPrivatePreviewArguments_interpolatedInStringArgument() async {
    const String kPrivateName = '_privateName';

    await assertErrorsInCode(
      '''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

const String $kPrivateName = 'Name';

@Preview(name: '\$$kPrivateName')
Widget privateNameStringInterp() => Text('Foo');
''',
      [
        error(
          diag.invalidWidgetPreviewPrivateArgument,
          133,
          21,
          correctionContains: correctionMessageBuilder(
            kPrivateName,
            kPrivateName.substring(1),
          ),
        ),
      ],
    );
  }

  test_invalidPrivatePreviewArguments_size() async {
    // TODO(srawlins): Update to the new Size argument.
    const String kPrivateWidth = '_privateWidth';
    const String kPrivateHeight = '_privateHeight';
    const String kPrivateTextScaleFactor = '_textScaleFactor';

    await assertErrorsInCode(
      '''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

const double $kPrivateWidth = 42.0;
const double $kPrivateHeight = 24.0;
const double $kPrivateTextScaleFactor = 2.0;

@Preview(width: $kPrivateWidth,
        height: $kPrivateHeight,
        textScaleFactor: $kPrivateTextScaleFactor)
Widget privateDoubles() => Text('Foo');
''',
      [
        error(
          diag.invalidWidgetPreviewPrivateArgument,
          205,
          20,
          correctionContains: correctionMessageBuilder(
            kPrivateWidth,
            kPrivateWidth.substring(1),
          ),
        ),
        error(
          diag.invalidWidgetPreviewPrivateArgument,
          235,
          22,
          correctionContains: correctionMessageBuilder(
            kPrivateHeight,
            kPrivateHeight.substring(1),
          ),
        ),
        error(
          diag.invalidWidgetPreviewPrivateArgument,
          267,
          33,
          correctionContains: correctionMessageBuilder(
            kPrivateTextScaleFactor,
            kPrivateTextScaleFactor.substring(1),
          ),
        ),
      ],
    );
  }

  test_invalidPrivatePreviewArguments_theme() async {
    const String kPrivateTheme = '_privateTheme';

    await assertErrorsInCode(
      '''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

PreviewThemeData $kPrivateTheme() => PreviewThemeData();

@Preview(theme: $kPrivateTheme)
Widget privateThemeData() => Text('Foo');

''',
      [
        error(
          diag.invalidWidgetPreviewPrivateArgument,
          153,
          20,
          correctionContains: correctionMessageBuilder(
            kPrivateTheme,
            kPrivateTheme.substring(1),
          ),
        ),
      ],
    );
  }

  test_invalidPrivatePreviewArguments_widthInArgument() async {
    const String kPrivateWidth = '_privateWidth';

    await assertErrorsInCode(
      '''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

const double $kPrivateWidth = 42.0;

@Preview(width: $kPrivateWidth + 10)
Widget numericExpressionWithPrivateDouble() => Text('Foo');
''',
      [
        error(
          diag.invalidWidgetPreviewPrivateArgument,
          132,
          25,
          correctionContains: correctionMessageBuilder(
            kPrivateWidth,
            kPrivateWidth.substring(1),
          ),
        ),
      ],
    );
  }

  test_invalidPrivatePreviewArguments_wrapper() async {
    const String kPrivateWrapper = '_privateWrapper';

    await assertErrorsInCode(
      '''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

Widget $kPrivateWrapper(Widget child) => child;

@Preview(wrapper: $kPrivateWrapper)
Widget privateWrapper() => Text('Foo');
''',
      [
        error(
          diag.invalidWidgetPreviewPrivateArgument,
          144,
          24,
          correctionContains: correctionMessageBuilder(
            kPrivateWrapper,
            kPrivateWrapper.substring(1),
          ),
        ),
      ],
    );
  }
}
