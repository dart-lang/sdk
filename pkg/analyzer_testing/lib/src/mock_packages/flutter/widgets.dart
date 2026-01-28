// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

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
''');
