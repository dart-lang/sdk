// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of models;

enum ProfileTreeDirection { inclusive, exclusive }

abstract class SampleProfile {
  int get sampleCount;
  int get stackDepth;
  double get sampleRate;
  double get timeSpan;
  Iterable<ProfileCode> get codes;
  Iterable<ProfileFunction> get functions;

  FunctionCallTree loadFunctionTree(ProfileTreeDirection direction);
  CodeCallTree loadCodeTree(ProfileTreeDirection direction);
}

abstract class Profile {
  double get normalizedExclusiveTicks;
  double get normalizedInclusiveTicks;
}

abstract class ProfileCode extends Profile {
  CodeRef get code;
  Map<ProfileCode, int> get callers;
  Map<ProfileCode, int> get callees;
}

abstract class ProfileFunction extends Profile {
  FunctionRef get function;
  Map<ProfileFunction, int> get callers;
  Map<ProfileFunction, int> get callees;
}

typedef bool CallTreeNodeFilter(CallTreeNode);

abstract class CallTree {
  CallTree filtered(CallTreeNodeFilter filter);
}

abstract class CodeCallTree extends CallTree {
  CodeCallTreeNode get root;
  CodeCallTree filtered(CallTreeNodeFilter filter);
}

abstract class FunctionCallTree extends CallTree {
  FunctionCallTreeNode get root;
  FunctionCallTree filtered(CallTreeNodeFilter filter);
}

abstract class CallTreeNode {
  double get percentage;
  Iterable<CallTreeNode> get children;
}

abstract class CodeCallTreeNode extends CallTreeNode {
  ProfileCode get profileCode;
  Iterable<CodeCallTreeNode> get children;
}

abstract class FunctionCallTreeNode extends CallTreeNode {
  ProfileFunction get profileFunction;
  Iterable<FunctionCallTreeNode> get children;
}
