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
  final M.ClassRef clazz;
  final String vmName;
  final int size;
  final String uri;
  final String source;
  final M.LibraryRef library;

  final TokenToInt _tokenToLine;
  final TokenToInt _tokenToCol;

  final DateTime loadTime;
  final int firstTokenPos;
  final int lastTokenPos;
  final int lineOffset;
  final int columnOffset;

  int tokenToLine(int token) => _tokenToLine(token);
  int tokenToCol(int token) => _tokenToCol(token);

  const ScriptMock({this.id: 'script-id', this.vmName: 'script-vmNmae',
                    this.clazz, this.size, this.uri, this.source,
                    this.library: const LibraryRefMock(),
                    TokenToInt tokenToLine, TokenToInt tokenToCol,
                    this.loadTime, this.firstTokenPos, this.lastTokenPos,
                    this.lineOffset, this.columnOffset})
    : _tokenToLine = tokenToLine,
      _tokenToCol = tokenToCol;
}
