// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  var executor = new Executor();
  new Command1().execute(executor);
  executor.execute<Command1>(new Command1());
}

class Command1 extends CommandBase<Command1> {}

abstract class Command {}

abstract class CommandBase<TSelf extends CommandBase<TSelf>> extends Command {
  void execute(Executor e) {
    TSelf self = this as TSelf;
    e.execute<TSelf>(self);
  }
}

abstract class CommandHandler<T extends Command> {
  void handle(T command);
}

class Executor {
  void execute<T extends Command>(T action) {
    testTypeEquality<CommandHandler<T>, CommandHandler<Command1>>();
  }
}

void testTypeEquality<T1, T2>() {
  Expect.equals(T1.hashCode, T2.hashCode);
  Expect.equals(T1, T2);
  Expect.identical(T1, T2);
}
