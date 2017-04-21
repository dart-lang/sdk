// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class VMRefMock implements M.VMRef {
  final String name;
  final String displayName;
  const VMRefMock({this.name: 'vm-name', this.displayName: 'vm-display-name'});
}

class VMMock implements M.VM {
  final String name;
  final String displayName;
  final int architectureBits;
  final String targetCPU;
  final String hostCPU;
  final String version;
  final int pid;
  final int maxRSS;
  final DateTime startTime;
  final Iterable<M.IsolateRef> isolates;
  final int nativeZoneMemoryUsage = 0;
  final int heapAllocatedMemoryUsage = 0;
  final int heapAllocationCount = 0;

  Future<dynamic> invokeRpc(String method, Map params) {
    return null;
  }

  const VMMock(
      {this.name: 'vm-name',
      this.displayName: 'vm-display-name',
      this.architectureBits,
      this.targetCPU,
      this.hostCPU,
      this.version,
      this.pid: 0,
      this.maxRSS: 0,
      this.startTime,
      this.isolates: const []});
}
