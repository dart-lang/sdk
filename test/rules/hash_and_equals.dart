// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N hash_and_equals`

class Bad {
  final int value;
  Bad(this.value);

  @override
  bool operator ==(Object other) => other is Bad && other.value == value; //LINT
}

class Bad2 {
  final int value;
  Bad2(this.value);

  @override
  int get hashCode => value.hashCode; //LINT
}

class Better //OK!
{
  final int value;
  Better(this.value);

  @override
  bool operator ==(Object other) => other is Better && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

class OK {}

class AlsoOk {
  @override
  final int hashCode;
  AlsoOk(this.hashCode);

  @override
  bool operator ==(Object other) => other is AlsoOk && other.hashCode == hashCode; //OK
}

class NotOk {
  @override
  final int hashCode; //LINT
  NotOk(this.hashCode);
}
