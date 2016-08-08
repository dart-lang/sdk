// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class ScriptRefMock implements M.ScriptRef {
  final String id;
  final String uri;

  const ScriptRefMock({this.id, this.uri});
}

typedef int TokenToInt(int token);

class ScriptMock implements M.Script {
  final String id;
  final int size;
  final String uri;
  final String source;

  final TokenToInt _tokenToLine;
  final TokenToInt _tokenToCol;

  int tokenToLine(int token) => _tokenToLine(token);
  int tokenToCol(int token) => _tokenToCol(token);

  const ScriptMock({this.id, this.size, this.uri, this.source,
      TokenToInt tokenToLine, TokenToInt tokenToCol})
    : _tokenToLine = tokenToLine,
      _tokenToCol = tokenToCol;
}
