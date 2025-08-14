// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
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
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(PackageConfigFileBuilder(), flutter: true);
  }

  // @Preview cannot accept any arguments including references to private
  // symbols.
  test_invalidPrivatePreviewArguments() async {
    String correctionMessageBuilder(String original, String public) {
      return "Rename private symbol '$original' to '$public'.";
    }

    const String kPrivateName = '_privateName';
    const String kExtraPrivateName = '__extraPrivateName';
    const String kPrivateWidth = '_privateWidth';
    const String kPrivateHeight = '_privateHeight';
    const String kPrivateTextScaleFactor = '_textScaleFactor';
    const String kPrivateWrapper = '_privateWrapper';
    const String kPrivateTheme = '_privateTheme';

    await assertErrorsInCode(
      '''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

const String $kPrivateName = 'Name';
const String $kExtraPrivateName = 'Extra';
const double $kPrivateWidth = 42.0;
const double $kPrivateHeight = 24.0;
const double $kPrivateTextScaleFactor = 2.0;

Widget $kPrivateWrapper(Widget child) => child;
PreviewThemeData $kPrivateTheme() => PreviewThemeData();

@Preview(name: $kPrivateName)
Widget privateName() => Text('Foo');

@Preview(name: '\$$kPrivateName')
Widget privateNameStringInterp() => Text('Foo');

@Preview(name: $kExtraPrivateName)
Widget extraPrivateName() => Text('Foo');

@Preview(width: $kPrivateWidth,
        height: $kPrivateHeight,
        textScaleFactor: $kPrivateTextScaleFactor)
Widget privateDoubles() => Text('Foo');

@Preview(width: $kPrivateWidth + 10)
Widget numericExpressionWithPrivateDouble() => Text('Foo');

@Preview(wrapper: $kPrivateWrapper)
Widget privateWrapper() => Text('Foo');

@Preview(theme: $kPrivateTheme)
Widget privateThemeData() => Text('Foo');

''',
      [
        error(
          WarningCode.invalidWidgetPreviewPrivateArgument,
          388,
          18,
          correctionContains: correctionMessageBuilder(
            kPrivateName,
            kPrivateName.substring(1),
          ),
        ),
        error(
          WarningCode.invalidWidgetPreviewPrivateArgument,
          455,
          21,
          correctionContains: correctionMessageBuilder(
            kPrivateName,
            kPrivateName.substring(1),
          ),
        ),
        error(
          WarningCode.invalidWidgetPreviewPrivateArgument,
          537,
          24,
          correctionContains: correctionMessageBuilder(
            kExtraPrivateName,
            kExtraPrivateName.substring(2),
          ),
        ),
        error(
          WarningCode.invalidWidgetPreviewPrivateArgument,
          615,
          20,
          correctionContains: correctionMessageBuilder(
            kPrivateWidth,
            kPrivateWidth.substring(1),
          ),
        ),
        error(
          WarningCode.invalidWidgetPreviewPrivateArgument,
          645,
          22,
          correctionContains: correctionMessageBuilder(
            kPrivateHeight,
            kPrivateHeight.substring(1),
          ),
        ),
        error(
          WarningCode.invalidWidgetPreviewPrivateArgument,
          677,
          33,
          correctionContains: correctionMessageBuilder(
            kPrivateTextScaleFactor,
            kPrivateTextScaleFactor.substring(1),
          ),
        ),
        error(
          WarningCode.invalidWidgetPreviewPrivateArgument,
          762,
          25,
          correctionContains: correctionMessageBuilder(
            kPrivateWidth,
            kPrivateWidth.substring(1),
          ),
        ),
        error(
          WarningCode.invalidWidgetPreviewPrivateArgument,
          859,
          24,
          correctionContains: correctionMessageBuilder(
            kPrivateWrapper,
            kPrivateWrapper.substring(1),
          ),
        ),
        error(
          WarningCode.invalidWidgetPreviewPrivateArgument,
          935,
          20,
          correctionContains: correctionMessageBuilder(
            kPrivateTheme,
            kPrivateTheme.substring(1),
          ),
        ),
      ],
    );
  }
}
