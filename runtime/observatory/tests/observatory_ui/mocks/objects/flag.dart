// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of mocks;

class FlagMock implements M.Flag {
  final String name;
  final String comment;
  final bool modified;
  final String valueAsString;

  const FlagMock({this.name, this.comment, this.modified, this.valueAsString});
}
