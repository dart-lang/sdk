// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of mocks;

class FlagsRepositoryMock implements M.FlagsRepository {
  final Iterable<M.Flag> _list;
  bool isListInvoked = false;

  Future<Iterable<M.Flag>> list() async {
    await null;
    isListInvoked = true;
    return _list;
  }

  FlagsRepositoryMock({Iterable<M.Flag> list: const []})
      : _list = new List.unmodifiable(list);
}
