// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/flutter/widgets/async.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/widgets/basic.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/widgets/container.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/widgets/decorated_sliver.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/widgets/framework.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/widgets/gesture_detector.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/widgets/icon.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/widgets/icon_data.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/widgets/inherited_theme.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/widgets/navigator.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/widgets/placeholder.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/widgets/scroll_view.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/widgets/sliver.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/widgets/text.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/widgets/ticker_provider.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/widgets/value_listenable_builder.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/widgets/widget_inspector.dart';
import 'package:analyzer_testing/src/mock_packages/mock_library.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/widgets/media_query.dart';
import 'package:analyzer_testing/src/mock_packages/flutter/widgets/scroll_delegate.dart';

/// The set of compilation units that make up the mock 'widgets'
/// component of the 'flutter' package.
final List<MockLibraryUnit> units = [
  widgetsLibrary,
  widgetsAsyncLibrary,
  widgetsBasicLibrary,
  widgetsContainerLibrary,
  widgetsFrameworkLibrary,
  widgetsDecoratedSliverLibrary,
  widgetsGestureDetectorLibrary,
  widgetsIconDataLibrary,
  widgetsIconLibrary,
  widgetsInheritedThemeLibrary,
  widgetsNavigatorLibrary,
  widgetsPlaceholderLibrary,
  widgetsScrollViewLibrary,
  widgetsSliverLibrary,
  widgetsTextLibrary,
  widgetsTickerProviderLibrary,
  widgetsValueListenableBuilderLibrary,
  widgetsWidgetInspectorLibrary,
  widgetsMediaQueryLibrary,
  widgetsScrollDelegateLibrary,
];

final widgetsLibrary = MockLibraryUnit('lib/widgets.dart', r'''
export 'package:vector_math/vector_math.dart';

export 'foundation.dart' show UniqueKey;
export 'src/widgets/async.dart';
export 'src/widgets/basic.dart';
export 'src/widgets/container.dart';
export 'src/widgets/decorated_sliver.dart';
export 'src/widgets/framework.dart';
export 'src/widgets/gesture_detector.dart';
export 'src/widgets/icon_data.dart';
export 'src/widgets/icon.dart';
export 'src/widgets/inherited_theme.dart';
export 'src/widgets/navigator.dart';
export 'src/widgets/placeholder.dart';
export 'src/widgets/scroll_view.dart';
export 'src/widgets/sliver.dart';
export 'src/widgets/text.dart';
export 'src/widgets/ticker_provider.dart';
export 'src/widgets/value_listenable_builder.dart';
export 'src/widgets/widget_inspector.dart';
export 'src/widgets/media_query.dart';
export 'src/widgets/scroll_delegate.dart';
''');
