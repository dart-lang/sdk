// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'export_part1.dart';

export 'export_lib3.dart' if (dart.library.html) 'export_lib2.dart';
export 'export_lib2.dart' if (dart.library.io) 'export_lib4.dart';
