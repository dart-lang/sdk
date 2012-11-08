// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_backend;

import '../elements/elements.dart';
import '../dart2jslib.dart';
import '../tree/tree.dart';
import '../util/util.dart';

import '../scanner/scannerlib.dart' show StringToken,
                                         Keyword,
                                         OPEN_PAREN_INFO,
                                         CLOSE_PAREN_INFO,
                                         SEMICOLON_INFO,
                                         IDENTIFIER_INFO;

part 'backend.dart';
part 'emitter.dart';
part 'renamer.dart';
part 'placeholder_collector.dart';
part 'utils.dart';
