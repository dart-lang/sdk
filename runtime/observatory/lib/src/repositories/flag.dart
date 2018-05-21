// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class Flag implements M.Flag {
  final String name;
  final String comment;
  final bool modified;
  final String valueAsString;
  Flag(this.name, this.comment, this.modified, this.valueAsString) {
    assert(name != null);
    assert(comment != null);
    assert(modified != null);
  }
}

class FlagsRepository implements M.FlagsRepository {
  final S.VM vm;

  FlagsRepository(this.vm);

  Future<Iterable<Flag>> list() async {
    List<Map> flags = ((await vm.getFlagList()) as S.ServiceMap)['flags'];
    return flags.map(_toFlag);
  }

  static Flag _toFlag(Map map) {
    return new Flag(
        map['name'], map['comment'], map['modified'], map['valueAsString']);
  }
}
