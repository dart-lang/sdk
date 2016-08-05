// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class SourceLocationMock implements M.SourceLocation {
  final M.ScriptRef script;
  final int tokenPos;
  final int endTokenPos;

  const SourceLocationMock({this.script, this.tokenPos, this.endTokenPos});
}
