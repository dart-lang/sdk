// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/codes.dart';
import 'package:_fe_analyzer_shared/src/messages/severity.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:kernel/ast.dart' show Constant, DartType;

import 'package:_fe_analyzer_shared/src/messages/conversions.dart'
    as conversions;
import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    as conversions
    show relativizeUri;
import 'type_labeler.dart';

part 'diagnostic.g.dart';
