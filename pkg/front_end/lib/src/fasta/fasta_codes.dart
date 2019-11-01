// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.codes;

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    hide demangleMixinApplicationName;

import 'package:kernel/ast.dart'
    show Constant, DartType, demangleMixinApplicationName;

import 'kernel/type_labeler.dart';

export 'package:_fe_analyzer_shared/src/messages/codes.dart'
    hide demangleMixinApplicationName;

part 'fasta_codes_cfe_generated.dart';
