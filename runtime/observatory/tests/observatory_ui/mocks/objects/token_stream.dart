// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class TokenStreamRefMock implements M.TokenStreamRef {
  final String id;
  final String name;
  const TokenStreamRefMock({this.id: 'tokenstream-id', this.name});
}
