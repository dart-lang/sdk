// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of mocks;

typedef M.FunctionCallTree SampleProfileMockLoadFunctionTreeCallback(
    M.ProfileTreeDirection direction);
typedef M.CodeCallTree SampleProfileMockLoadCodeTreeCallback(
    M.ProfileTreeDirection direction);

class SampleProfileMock implements M.SampleProfile {
  final SampleProfileMockLoadFunctionTreeCallback _loadFunctionTree;
  final SampleProfileMockLoadCodeTreeCallback _loadCodeTree;

  final int sampleCount;
  final int stackDepth;
  final double sampleRate;
  final double timeSpan;
  final Iterable<M.ProfileCode> codes;
  final Iterable<M.ProfileFunction> functions;

  M.FunctionCallTree loadFunctionTree(M.ProfileTreeDirection direction) {
    if (_loadFunctionTree != null) {
      return _loadFunctionTree(direction);
    }
    return null;
  }
  M.CodeCallTree loadCodeTree(M.ProfileTreeDirection direction) {
    if (_loadCodeTree != null) {
      return _loadCodeTree(direction);
    }
    return null;
  }

  SampleProfileMock({this.sampleCount: 0, this.stackDepth: 0,
      this.sampleRate: 1.0, this.timeSpan: 1.0,
      this.codes: const [], this.functions: const [],
      SampleProfileMockLoadFunctionTreeCallback loadFunctionTree,
      SampleProfileMockLoadCodeTreeCallback loadCodeTree})
    : _loadFunctionTree = loadFunctionTree,
      _loadCodeTree = loadCodeTree;
}
