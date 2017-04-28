// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/scanner/token.dart';
import 'package:kernel/ast.dart';

/// A null-aware alternative to `token.offset`.  If [token] is `null`, returns
/// `TreeNode.noOffset`.
int offsetForToken(Token token) =>
    token == null ? TreeNode.noOffset : token.offset;
