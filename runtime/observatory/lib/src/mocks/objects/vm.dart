// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of mocks;

class VMRefMock implements M.VMRef {
  final String name;
  const VMRefMock({this.name});
}

class VMMock implements M.VM {
  final String name;
  final int architectureBits;
  final String targetCPU;
  final String hostCPU;
  final String version;
  final int pid;
  final DateTime startTime;
  final Iterable<M.IsolateRef> isolates;
  const VMMock({this.name, this.architectureBits, this.targetCPU, this.hostCPU,
      this.version, this.pid, this.startTime, this.isolates : const []});
}
