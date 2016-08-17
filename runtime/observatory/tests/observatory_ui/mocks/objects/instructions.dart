// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class InstructionsRefMock implements M.InstructionsRef {
  final String id;
  final M.CodeRef code;
  const InstructionsRefMock({this.id: 'instructions-id',
                             this.code: const CodeRefMock(
                                        name: 'instruction-ref-code-ref')});
}
