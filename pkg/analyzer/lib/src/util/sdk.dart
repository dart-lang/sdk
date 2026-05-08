// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/platform_info.dart';
import 'package:path/path.dart' as path;

/// Return the path to the runtime Dart SDK.
String getSdkPath() => path.dirname(path.dirname(platform.resolvedExecutable));
