// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of models;

enum ProfileTreeDirection { inclusive, exclusive }

abstract class SampleProfile {
  int get sampleCount;
  int get maxStackDepth;
  double get sampleRate;
  double get timeSpan;
  List<ProfileCode> get codes;
  List<ProfileFunction> get functions;

  FunctionCallTree loadFunctionTree(ProfileTreeDirection direction);
  CodeCallTree loadCodeTree(ProfileTreeDirection direction);
}

abstract class Profile {
  double get normalizedExclusiveTicks;
  double get normalizedInclusiveTicks;
  void clearTicks();
  void tickTag();
}

abstract class ProfileCode extends Profile {
  CodeRef get code;
  Map<ProfileCode, int> get callers;
  Map<ProfileCode, int> get callees;
}

abstract class ProfileFunction extends Profile {
  FunctionRef get function;
  String get resolvedUrl;
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
  int get count;
  int get inclusiveNativeAllocations;
  int get exclusiveNativeAllocations;
  Iterable<CallTreeNode> get children;
  void sortChildren();

  void tick(Map sample, {bool exclusive = false});
}

abstract class CodeCallTreeNode extends CallTreeNode {
  ProfileCode get profileCode;
  Iterable<CodeCallTreeNode> get children;
}

abstract class FunctionCallTreeNode extends CallTreeNode {
  ProfileFunction get profileFunction;
  Iterable<FunctionCallTreeNode> get children;
}
