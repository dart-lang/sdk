// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of sample_profiler;

abstract class CallTreeNode<NodeT extends M.CallTreeNode>
    implements M.CallTreeNode {
  final List<NodeT> children;
  int get count => _count;
  int _count = 0;
  int inclusiveNativeAllocations = 0;
  int exclusiveNativeAllocations = 0;
  double get percentage => _percentage;
  double _percentage = 0.0;
  final attributes = <String>{};

  // Used for building timeline
  int? frameId = null;
  int? parentId = null;

  // Either a ProfileCode or a ProfileFunction.
  Object get profileData;
  String get name;

  CallTreeNode(this.children,
      [this._count = 0,
      this.inclusiveNativeAllocations = 0,
      this.exclusiveNativeAllocations = 0]) {}

  NodeT getChild(int index);

  void sortChildren() {
    children.sort((a, b) => b.count - a.count);
    children.forEach((NodeT child) => child.sortChildren());
  }

  void tick(Map sample, {bool exclusive = false}) {
    ++_count;
    if (SampleProfile._isNativeAllocationSample(sample)) {
      final allocationSize =
          sample[SampleProfile._kNativeAllocationSizeBytes] as int;
      if (exclusive) {
        exclusiveNativeAllocations += allocationSize;
      }
      inclusiveNativeAllocations += allocationSize;
    }
  }
}

class CodeCallTreeNode extends CallTreeNode<CodeCallTreeNode>
    implements M.CodeCallTreeNode {
  final ProfileCode profileCode;
  final SampleProfile profile;

  Object get profileData => profileCode;

  String get name => profileCode.code.name!;

  final attributes = <String>{};
  CodeCallTreeNode(this.profileCode, int count, int inclusiveNativeAllocations,
      int exclusiveNativeAllocations)
      : profile = profileCode.profile,
        super(<CodeCallTreeNode>[], count, inclusiveNativeAllocations,
            exclusiveNativeAllocations) {
    attributes.addAll(profileCode.attributes);
  }

  CodeCallTreeNode.fromIndex(this.profile, int tableIndex)
      : profileCode = profile.codes[tableIndex] as ProfileCode,
        super(<CodeCallTreeNode>[]);

  CodeCallTreeNode getChild(int codeTableIndex) {
    final length = children.length;
    int i = 0;
    while (i < length) {
      final child = children[i];
      final childTableIndex = child.profileCode.tableIndex;
      if (childTableIndex == codeTableIndex) {
        return child;
      }
      if (childTableIndex > codeTableIndex) {
        break;
      }
      ++i;
    }
    final child = CodeCallTreeNode.fromIndex(profile, codeTableIndex);
    if (i < length) {
      children.insert(i, child);
    } else {
      children.add(child);
    }
    return child;
  }
}

class CallTree<NodeT extends CallTreeNode> {
  final bool inclusive;
  final NodeT root;

  CallTree(this.inclusive, this.root);
}

class CodeCallTree extends CallTree<CodeCallTreeNode>
    implements M.CodeCallTree {
  CodeCallTree(bool inclusive, CodeCallTreeNode root) : super(inclusive, root) {
    if ((root.inclusiveNativeAllocations != null) &&
        (root.inclusiveNativeAllocations != 0)) {
      _setCodeMemoryPercentage(null, root);
    } else {
      _setCodePercentage(null, root);
    }
  }

  CodeCallTree filtered(CallTreeNodeFilter filter) {
    final treeFilter = _FilteredCodeCallTreeBuilder(filter, this);
    treeFilter.build();
    if ((treeFilter.filtered.root.inclusiveNativeAllocations != null) &&
        (treeFilter.filtered.root.inclusiveNativeAllocations != 0)) {
      _setCodeMemoryPercentage(
          null, treeFilter.filtered.root as CodeCallTreeNode);
    } else {
      _setCodePercentage(null, treeFilter.filtered.root as CodeCallTreeNode);
    }
    return treeFilter.filtered as CodeCallTree;
  }

  _setCodePercentage(CodeCallTreeNode? parent, CodeCallTreeNode node) {
    assert(node != null);
    var parentPercentage = 1.0;
    var parentCount = node.count;
    if (parent != null) {
      parentPercentage = parent._percentage;
      parentCount = parent.count;
    }
    if (inclusive) {
      node._percentage = parentPercentage * (node.count / parentCount);
    } else {
      node._percentage = (node.count / parentCount);
    }
    for (var child in node.children) {
      _setCodePercentage(node, child);
    }
  }

  _setCodeMemoryPercentage(CodeCallTreeNode? parent, CodeCallTreeNode node) {
    assert(node != null);
    var parentPercentage = 1.0;
    var parentMemory = node.inclusiveNativeAllocations;
    if (parent != null) {
      parentPercentage = parent._percentage;
      parentMemory = parent.inclusiveNativeAllocations;
    }
    if (inclusive) {
      node._percentage =
          parentPercentage * (node.inclusiveNativeAllocations / parentMemory);
    } else {
      node._percentage = (node.inclusiveNativeAllocations / parentMemory);
    }
    for (var child in node.children) {
      _setCodeMemoryPercentage(node, child);
    }
    node.children.sort((a, b) {
      return b.inclusiveNativeAllocations - a.inclusiveNativeAllocations;
    });
  }

  _recordCallerAndCalleesInner(
      CodeCallTreeNode? caller, CodeCallTreeNode callee) {
    if (caller != null) {
      caller.profileCode._recordCallee(callee.profileCode, callee.count);
      callee.profileCode._recordCaller(caller.profileCode, caller.count);
    }

    for (var child in callee.children) {
      _recordCallerAndCalleesInner(callee, child);
    }
  }

  _recordCallerAndCallees() {
    for (var child in root.children) {
      _recordCallerAndCalleesInner(null, child);
    }
  }
}

class FunctionCallTreeNodeCode {
  final ProfileCode code;
  final int ticks;
  FunctionCallTreeNodeCode(this.code, this.ticks);
}

class FunctionCallTreeNode extends CallTreeNode<FunctionCallTreeNode>
    implements M.FunctionCallTreeNode {
  final ProfileFunction profileFunction;
  final SampleProfile profile;
  final codes = <FunctionCallTreeNodeCode>[];
  int _totalCodeTicks = 0;
  int get totalCodesTicks => _totalCodeTicks;

  String get name => M.getFunctionFullName(profileFunction.function);
  Object get profileData => profileFunction;

  FunctionCallTreeNode(this.profileFunction, int count,
      inclusiveNativeAllocations, exclusiveNativeAllocations)
      : profile = profileFunction.profile,
        super(<FunctionCallTreeNode>[], count, inclusiveNativeAllocations,
            exclusiveNativeAllocations) {
    profileFunction._addKindBasedAttributes(attributes);
  }

  FunctionCallTreeNode.fromIndex(this.profile, int tableIndex)
      : profileFunction = profile.functions[tableIndex] as ProfileFunction,
        super(<FunctionCallTreeNode>[]);

  FunctionCallTreeNode getChild(int functionTableIndex) {
    final length = children.length;
    int i = 0;
    while (i < length) {
      final child = children[i];
      final childTableIndex = child.profileFunction.tableIndex;
      if (childTableIndex == functionTableIndex) {
        return child;
      }
      if (childTableIndex > functionTableIndex) {
        break;
      }
      ++i;
    }
    final child = FunctionCallTreeNode.fromIndex(profile, functionTableIndex);
    if (i < length) {
      children.insert(i, child);
    } else {
      children.add(child);
    }
    return child;
  }
}

/// Predicate filter function. Returns true if path from root to [node] and all
/// of [node]'s children should be added to the filtered tree.
typedef CallTreeNodeFilter = bool Function(CallTreeNode node);

/// Build a filter version of a FunctionCallTree.
abstract class _FilteredCallTreeBuilder<NodeT extends CallTreeNode> {
  /// The filter.
  final CallTreeNodeFilter filter;

  /// The unfiltered tree.
  final CallTree _unfilteredTree;

  /// The filtered tree (construct by [build]).
  final CallTree filtered;
  final List _currentPath = [];

  /// Construct a filtered tree builder using [filter] and [tree].
  _FilteredCallTreeBuilder(this.filter, CallTree tree, this.filtered)
      : _unfilteredTree = tree;

  /// Build the filtered tree.
  build() {
    assert(filtered != null);
    assert(filter != null);
    assert(_unfilteredTree != null);
    _descend(_unfilteredTree.root);
  }

  CallTreeNode? _findInChildren(CallTreeNode current, CallTreeNode needle) {
    for (var child in current.children) {
      if ((child as CallTreeNode).profileData == needle.profileData) {
        return child;
      }
    }
    return null;
  }

  NodeT _copyNode(NodeT node);

  /// Add all nodes in [_currentPath].
  FunctionCallTreeNode _addCurrentPath() {
    FunctionCallTreeNode current = filtered.root as FunctionCallTreeNode;
    // Tree root is always the first element of the current path.
    assert(_unfilteredTree.root == _currentPath[0]);
    // Assert that unfiltered tree's root and filtered tree's root are different.
    assert(_unfilteredTree.root != current);
    for (var i = 1; i < _currentPath.length; i++) {
      // toAdd is from the unfiltered tree.
      var toAdd = _currentPath[i];
      // See if we already have a node for toAdd in the filtered tree.
      var child = _findInChildren(current, toAdd);
      if (child == null) {
        // New node.
        child = _copyNode(toAdd);
        current.children.add(child as FunctionCallTreeNode);
      }
      current = child as FunctionCallTreeNode;
    }
    return current;
  }

  /// Starting at [current] append [next] and all of [next]'s sub-trees
  _appendTree(CallTreeNode current, CallTreeNode? next) {
    if (next == null) {
      return;
    }
    var child = _findInChildren(current, next);
    if (child == null) {
      child = _copyNode(next as NodeT);
      current.children.add(child);
    }
    current = child;
    for (var nextChild in next.children) {
      _appendTree(current, nextChild as CallTreeNode);
    }
  }

  /// Add path from root to [child], [child], and all of [child]'s sub-trees
  /// to filtered tree.
  _addTree(CallTreeNode? child) {
    var current = _addCurrentPath();
    _appendTree(current, child);
  }

  /// Descend further into the tree. [current] is from the unfiltered tree.
  _descend(CallTreeNode? current) {
    if (current == null) {
      return;
    }
    _currentPath.add(current);

    if (filter(current)) {
      // Filter matched.
      if (current.children.length == 0) {
        // Have no children. Add this path.
        _addTree(null);
      } else {
        // Add all child trees.
        for (var child in current.children) {
          _addTree(child as CallTreeNode);
        }
      }
    } else {
      // Did not match, descend to each child.
      for (var child in current.children) {
        _descend(child as CallTreeNode);
      }
    }

    var last = _currentPath.removeLast();
    assert(current == last);
  }
}

class _FilteredFunctionCallTreeBuilder
    extends _FilteredCallTreeBuilder<FunctionCallTreeNode> {
  _FilteredFunctionCallTreeBuilder(
      CallTreeNodeFilter filter, FunctionCallTree tree)
      : super(
            filter,
            tree,
            FunctionCallTree(
                tree.inclusive,
                FunctionCallTreeNode(
                    tree.root.profileData as ProfileFunction,
                    tree.root.count,
                    tree.root.inclusiveNativeAllocations,
                    tree.root.exclusiveNativeAllocations)));

  _copyNode(FunctionCallTreeNode node) {
    return FunctionCallTreeNode(node.profileData as ProfileFunction, node.count,
        node.inclusiveNativeAllocations, node.exclusiveNativeAllocations);
  }
}

class _FilteredCodeCallTreeBuilder
    extends _FilteredCallTreeBuilder<CodeCallTreeNode> {
  _FilteredCodeCallTreeBuilder(CallTreeNodeFilter filter, CodeCallTree tree)
      : super(
            filter,
            tree,
            CodeCallTree(
                tree.inclusive,
                CodeCallTreeNode(
                    tree.root.profileData as ProfileCode,
                    tree.root.count,
                    tree.root.inclusiveNativeAllocations,
                    tree.root.exclusiveNativeAllocations)));

  _copyNode(CodeCallTreeNode node) {
    return CodeCallTreeNode(node.profileData as ProfileCode, node.count,
        node.inclusiveNativeAllocations, node.exclusiveNativeAllocations);
  }
}

class FunctionCallTree extends CallTree<FunctionCallTreeNode>
    implements M.FunctionCallTree {
  FunctionCallTree(bool inclusive, FunctionCallTreeNode root)
      : super(inclusive, root) {
    if ((root.inclusiveNativeAllocations != null) &&
        (root.inclusiveNativeAllocations != 0)) {
      _setFunctionMemoryPercentage(null, root);
    } else {
      _setFunctionPercentage(null, root);
    }
  }

  FunctionCallTree filtered(CallTreeNodeFilter filter) {
    final treeFilter = _FilteredFunctionCallTreeBuilder(filter, this);
    treeFilter.build();
    if ((treeFilter.filtered.root.inclusiveNativeAllocations != null) &&
        (treeFilter.filtered.root.inclusiveNativeAllocations != 0)) {
      _setFunctionMemoryPercentage(
          null, treeFilter.filtered.root as FunctionCallTreeNode);
    } else {
      _setFunctionPercentage(
          null, treeFilter.filtered.root as FunctionCallTreeNode);
    }
    return treeFilter.filtered as FunctionCallTree;
  }

  void _setFunctionPercentage(
      FunctionCallTreeNode? parent, FunctionCallTreeNode node) {
    assert(node != null);
    var parentPercentage = 1.0;
    var parentCount = node.count;
    if (parent != null) {
      parentPercentage = parent._percentage;
      parentCount = parent.count;
    }
    if (inclusive) {
      node._percentage = parentPercentage * (node.count / parentCount);
    } else {
      node._percentage = (node.count / parentCount);
    }
    for (var child in node.children) {
      _setFunctionPercentage(node, child);
    }
  }

  void _setFunctionMemoryPercentage(
      FunctionCallTreeNode? parent, FunctionCallTreeNode node) {
    assert(node != null);
    var parentPercentage = 1.0;
    var parentMemory = node.inclusiveNativeAllocations;
    if (parent != null) {
      parentPercentage = parent._percentage;
      parentMemory = parent.inclusiveNativeAllocations;
    }
    if (inclusive) {
      node._percentage =
          parentPercentage * (node.inclusiveNativeAllocations / parentMemory);
    } else {
      node._percentage = (node.inclusiveNativeAllocations / parentMemory);
    }
    for (var child in node.children) {
      _setFunctionMemoryPercentage(node, child);
    }
    node.children.sort((a, b) {
      return b.inclusiveNativeAllocations - a.inclusiveNativeAllocations;
    });
  }

  _markFunctionCallsInner(
      FunctionCallTreeNode? caller, FunctionCallTreeNode callee) {
    if (caller != null) {
      caller.profileFunction
          ._recordCallee(callee.profileFunction, callee.count);
      callee.profileFunction
          ._recordCaller(caller.profileFunction, caller.count);
    }
    for (var child in callee.children) {
      _markFunctionCallsInner(callee, child);
    }
  }

  _markFunctionCalls() {
    for (var child in root.children) {
      _markFunctionCallsInner(null, child);
    }
  }
}

class CodeTick {
  final int exclusiveTicks;
  final int inclusiveTicks;
  CodeTick(this.exclusiveTicks, this.inclusiveTicks);
}

class InlineIntervalTick {
  final int startAddress;
  int _inclusiveTicks = 0;
  int get inclusiveTicks => _inclusiveTicks;
  int _exclusiveTicks = 0;
  int get exclusiveTicks => _exclusiveTicks;
  InlineIntervalTick(this.startAddress);
}

class ProfileCode implements M.ProfileCode {
  final int tableIndex;
  final SampleProfile profile;
  final Code code;
  int exclusiveTicks = 0;
  int inclusiveTicks = 0;
  double normalizedExclusiveTicks = 0.0;
  double normalizedInclusiveTicks = 0.0;
  final addressTicks = <int, CodeTick>{};
  final intervalTicks = <int, InlineIntervalTick>{};
  String formattedInclusiveTicks = '';
  String formattedExclusiveTicks = '';
  String formattedExclusivePercent = '';
  final Set<String> attributes = <String>{};
  final callers = <ProfileCode, int>{};
  final callees = <ProfileCode, int>{};

  void _processTicks(List<dynamic> profileTicks) {
    assert(profileTicks != null);
    assert((profileTicks.length % 3) == 0);
    for (var i = 0; i < profileTicks.length; i += 3) {
      // TODO(observatory): Address is not necessarily representable as a JS
      // integer.
      var address = int.parse(profileTicks[i] as String, radix: 16);
      var exclusive = profileTicks[i + 1] as int;
      var inclusive = profileTicks[i + 2] as int;
      var tick = CodeTick(exclusive, inclusive);
      addressTicks[address] = tick;

      var interval = code.findInterval(address);
      if (interval != null) {
        var intervalTick = intervalTicks[interval.start];
        if (intervalTick == null) {
          // Insert into map.
          intervalTick = InlineIntervalTick(interval.start);
          intervalTicks[interval.start] = intervalTick;
        }
        intervalTick._inclusiveTicks += inclusive;
        intervalTick._exclusiveTicks += exclusive;
      }
    }
  }

  void clearTicks() {
    exclusiveTicks = 0;
    inclusiveTicks = 0;
    normalizedExclusiveTicks = 0;
    normalizedInclusiveTicks = 0;
    formattedInclusiveTicks = '';
    formattedExclusiveTicks = '';
    formattedExclusivePercent = '';
  }

  ProfileCode.fromMap(this.tableIndex, this.profile, this.code, Map data) {
    assert(profile != null);
    assert(code != null);

    code.profile = this;

    if (code.kind == M.CodeKind.stub) {
      attributes.add('stub');
    } else if (code.kind == M.CodeKind.dart) {
      if (code.isNative!) {
        attributes.add('ffi'); // Not to be confused with a C function.
      } else {
        attributes.add('dart');
      }
      if (code.hasIntrinsic!) {
        attributes.add('intrinsic');
      }
      if (code.isOptimized!) {
        attributes.add('optimized');
      } else {
        attributes.add('unoptimized');
      }
    } else if (code.kind == M.CodeKind.tag) {
      attributes.add('tag');
    } else if (code.kind == M.CodeKind.native) {
      attributes.add('native');
    }
    inclusiveTicks = data['inclusiveTicks'];
    exclusiveTicks = data['exclusiveTicks'];

    normalizedExclusiveTicks = exclusiveTicks / profile.sampleCount;

    normalizedInclusiveTicks = inclusiveTicks / profile.sampleCount;

    var ticks = data['ticks'];
    if (ticks != null) {
      _processTicks(ticks);
    }

    formattedExclusivePercent =
        Utils.formatPercent(exclusiveTicks, profile.sampleCount);

    formattedInclusiveTicks =
        '${Utils.formatPercent(inclusiveTicks, profile.sampleCount)} '
        '($inclusiveTicks)';

    formattedExclusiveTicks =
        '${Utils.formatPercent(exclusiveTicks, profile.sampleCount)} '
        '($exclusiveTicks)';
  }

  _recordCaller(ProfileCode caller, int count) {
    var r = callers[caller];
    if (r == null) {
      r = 0;
    }
    callers[caller] = r + count;
  }

  _recordCallee(ProfileCode callee, int count) {
    var r = callees[callee];
    if (r == null) {
      r = 0;
    }
    callees[callee] = r + count;
  }

  void _normalizeTicks() {
    normalizedExclusiveTicks = exclusiveTicks / profile.sampleCount;
    normalizedInclusiveTicks = inclusiveTicks / profile.sampleCount;

    formattedExclusivePercent =
        Utils.formatPercent(exclusiveTicks, profile.sampleCount);

    formattedInclusiveTicks =
        '${Utils.formatPercent(inclusiveTicks, profile.sampleCount)} '
        '($inclusiveTicks)';

    formattedExclusiveTicks =
        '${Utils.formatPercent(exclusiveTicks, profile.sampleCount)} '
        '($exclusiveTicks)';
  }

  void tickTag() {
    // All functions *except* those for tags are ticked in the VM while
    // generating the CpuSamples response.
    if (code.kind != M.CodeKind.tag) {
      throw StateError('Only tags should be ticked. '
          'Attempted to tick: ${code.name}');
    }
    ++exclusiveTicks;
    ++inclusiveTicks;
    _normalizeTicks();
  }
}

class ProfileFunction implements M.ProfileFunction {
  final int tableIndex;
  final SampleProfile profile;
  final ServiceFunction function;
  final String resolvedUrl;
  final callers = <ProfileFunction, int>{};
  final callees = <ProfileFunction, int>{};

  // Absolute ticks:
  int exclusiveTicks = 0;
  int inclusiveTicks = 0;

  // Global percentages:
  double normalizedExclusiveTicks = 0.0;
  double normalizedInclusiveTicks = 0.0;

  String formattedInclusiveTicks = '';
  String formattedExclusiveTicks = '';
  String formattedExclusivePercent = '';
  final attributes = <String>{};

  void clearTicks() {
    exclusiveTicks = 0;
    inclusiveTicks = 0;
    normalizedExclusiveTicks = 0;
    normalizedInclusiveTicks = 0;
    formattedInclusiveTicks = '';
    formattedExclusiveTicks = '';
    formattedExclusivePercent = '';
  }

  void _addKindBasedAttributes(Set<String> attribs) {
    if (function.kind == M.FunctionKind.tag) {
      attribs.add('tag');
    } else if (function.kind == M.FunctionKind.stub) {
      attribs.add('stub');
    } else if (function.kind == M.FunctionKind.native) {
      attribs.add('native');
    } else if (M.isSyntheticFunction(function.kind)) {
      attribs.add('synthetic');
    } else if (function.isNative!) {
      attribs.add('ffi'); // Not to be confused with a C function.
    } else {
      attribs.add('dart');
    }
    if (function.hasIntrinsic == true) {
      attribs.add('intrinsic');
    }
  }

  ProfileFunction.fromMap(
      this.tableIndex, this.profile, this.function, Map data)
      : resolvedUrl = data['resolvedUrl'] {
    function.profile = this;
    _addKindBasedAttributes(attributes);
    exclusiveTicks = data['exclusiveTicks'];
    inclusiveTicks = data['inclusiveTicks'];
    _normalizeTicks();
  }

  _recordCaller(ProfileFunction caller, int count) {
    var r = callers[caller];
    if (r == null) {
      r = 0;
    }
    callers[caller] = r + count;
  }

  _recordCallee(ProfileFunction callee, int count) {
    var r = callees[callee];
    if (r == null) {
      r = 0;
    }
    callees[callee] = r + count;
  }

  void _normalizeTicks() {
    normalizedExclusiveTicks = exclusiveTicks / profile.sampleCount;
    normalizedInclusiveTicks = inclusiveTicks / profile.sampleCount;

    formattedExclusivePercent =
        Utils.formatPercent(exclusiveTicks, profile.sampleCount);

    formattedInclusiveTicks =
        '${Utils.formatPercent(inclusiveTicks, profile.sampleCount)} '
        '($inclusiveTicks)';

    formattedExclusiveTicks =
        '${Utils.formatPercent(exclusiveTicks, profile.sampleCount)} '
        '($exclusiveTicks)';
  }

  void tickTag() {
    // All functions *except* those for functions are ticked in the VM while
    // generating the CpuSamples response.
    if (function.kind != M.FunctionKind.tag) {
      throw StateError('Only tags should be ticked. '
          'Attempted to tick: ${function.name}');
    }
    ++exclusiveTicks;
    ++inclusiveTicks;
    _normalizeTicks();
  }
}

class SampleProfile extends M.SampleProfile {
  Isolate? isolate;

  int sampleCount = 0;
  int samplePeriod = 0;
  double sampleRate = 0.0;
  int pid = 0;
  int maxStackDepth = 0;

  double timeSpan = 0.0;

  M.SampleProfileTag tagOrder = M.SampleProfileTag.none;

  final _functionTagMapping = <String, int>{};
  final _codeTagMapping = <String, int>{};

  final List samples = [];
  final codes = <ProfileCode>[];
  bool _builtCodeCalls = false;
  final functions = <ProfileFunction>[];
  bool _builtFunctionCalls = false;

  static const String _kCode = 'code';
  static const String _kCodes = '_codes';
  static const String _kCodeStack = '_codeStack';
  static const String _kFunction = 'function';
  static const String _kFunctions = 'functions';
  static const String _kNativeAllocationSizeBytes =
      '_nativeAllocationSizeBytes';
  static const String _kPid = 'pid';
  static const String _kSampleCount = 'sampleCount';
  static const String _kSamplePeriod = 'samplePeriod';
  static const String _kSamples = 'samples';
  static const String _kStack = 'stack';
  static const String _kMaxStackDepth = 'maxStackDepth';
  static const String _kTimeSpan = 'timespan';
  static const String _kUserTag = 'userTag';
  static const String _kVmTag = 'vmTag';

  // Names of special tag types.
  static const String kNativeTag = 'Native';
  static const String kRootTag = 'Root';
  static const String kRuntimeTag = 'Runtime';
  static const String kTruncatedTag = '[Truncated]';

  // Used to stash trie information in samples for timeline processing.
  static const String kTimelineFunctionTrie = 'timelineFunctionTrie';

  CodeCallTree loadCodeTree(M.ProfileTreeDirection direction) {
    switch (direction) {
      case M.ProfileTreeDirection.inclusive:
        return _loadCodeTree(true);
      case M.ProfileTreeDirection.exclusive:
        return _loadCodeTree(false);
    }
    throw Exception('Unknown ProfileTreeDirection');
  }

  FunctionCallTree loadFunctionTree(M.ProfileTreeDirection direction) {
    switch (direction) {
      case M.ProfileTreeDirection.inclusive:
        return _loadFunctionTree(true);
      case M.ProfileTreeDirection.exclusive:
        return _loadFunctionTree(false);
    }
    throw Exception('Unknown ProfileTreeDirection');
  }

  buildCodeCallerAndCallees() {
    if (_builtCodeCalls) {
      return;
    }
    _builtCodeCalls = true;
    var tree = loadCodeTree(M.ProfileTreeDirection.inclusive);
    tree._recordCallerAndCallees();
  }

  buildFunctionCallerAndCallees() {
    if (_builtFunctionCalls) {
      return;
    }
    _builtFunctionCalls = true;
    var tree = loadFunctionTree(M.ProfileTreeDirection.inclusive);
    tree._markFunctionCalls();
  }

  clear() {
    pid = -1;
    sampleCount = 0;
    samplePeriod = 0;
    sampleRate = 0.0;
    maxStackDepth = 0;
    timeSpan = 0.0;
    codes.clear();
    functions.clear();
    _builtCodeCalls = false;
    _builtFunctionCalls = false;
  }

  Future load(ServiceObjectOwner owner, ServiceMap profile) async {
    await loadProgress(owner, profile).drain();
  }

  static Future sleep([Duration duration = const Duration(microseconds: 0)]) =>
      Future.delayed(duration);

  Future _loadCommon(ServiceObjectOwner owner, ServiceMap profile,
      [StreamController<double>? progress]) async {
    final watch = Stopwatch();
    watch.start();
    int count = 0;
    var needToUpdate = () {
      if (progress == null) {
        return false;
      }
      count++;
      if (((count % 256) == 0) && (watch.elapsedMilliseconds > 16)) {
        watch.reset();
        return true;
      }
      return false;
    };
    var signal = (double p) {
      if (progress == null) {
        return null;
      }
      progress.add(p);
      return sleep();
    };
    try {
      clear();
      progress?.add(0.0);
      if (profile == null) {
        return;
      }

      if ((owner != null) && (owner is Isolate)) {
        isolate = owner;
        isolate!.resetCachedProfileData();
      }

      pid = profile[_kPid];
      sampleCount = profile[_kSampleCount];
      samplePeriod = profile[_kSamplePeriod];
      sampleRate = (Duration.microsecondsPerSecond / samplePeriod);
      maxStackDepth = profile[_kMaxStackDepth];
      timeSpan = profile[_kTimeSpan];

      num length = 0;

      if (profile.containsKey(_kCodes)) {
        length += profile[_kCodes].length;
      }
      length += profile[_kFunctions].length;

      // Process code table.
      int tableIndex = 0;
      if (profile.containsKey(_kCodes)) {
        for (var codeRegion in profile[_kCodes]) {
          if (needToUpdate()) {
            await signal(count * 100.0 / length);
          }
          Code code = codeRegion[_kCode];
          assert(code != null);
          codes.add(ProfileCode.fromMap(tableIndex, this, code, codeRegion));
          ++tableIndex;
        }
      }
      // Process function table.
      tableIndex = 0;
      for (var profileFunction in profile[_kFunctions]) {
        if (needToUpdate()) {
          await signal(count * 100 / length);
        }
        ServiceFunction function = profileFunction[_kFunction];
        assert(function != null);
        functions.add(ProfileFunction.fromMap(
            tableIndex, this, function, profileFunction));
        ++tableIndex;
      }
      if (profile.containsKey(_kCodes)) {
        _buildCodeTagMapping();
      }

      _buildFunctionTagMapping();

      samples.addAll(profile[_kSamples]);
    } finally {
      progress?.close();
    }
  }

  Stream<double> loadProgress(ServiceObjectOwner owner, ServiceMap profile) {
    Logger.root.info('sampling counters ${profile['_counters']}');

    var progress = StreamController<double>.broadcast();

    _loadCommon(owner, profile, progress);
    return progress.stream;
  }

  // Helpers for reading optional flags from a sample.
  static bool _isNativeEntryTag(Map sample) =>
      sample.containsKey('nativeEntryTag');
  static bool _isRuntimeEntryTag(Map sample) =>
      sample.containsKey('runtimeEntryTag');
  static bool _isTruncated(Map sample) => sample.containsKey('truncated');
  static bool _isNativeAllocationSample(Map sample) =>
      sample.containsKey('_nativeAllocationSizeBytes');

  int _getProfileFunctionTagIndex(String tag) {
    if (_functionTagMapping.containsKey(tag)) {
      return _functionTagMapping[tag]!;
    }
    throw ArgumentError('$tag is not a valid tag!');
  }

  int _getProfileCodeTagIndex(String tag) {
    if (_codeTagMapping.containsKey(tag)) {
      return _codeTagMapping[tag]!;
    }
    throw ArgumentError('$tag is not a valid tag!');
  }

  void _buildFunctionTagMapping() {
    for (int i = 0; i < functions.length; ++i) {
      final function = functions[i].function!;
      if (function.kind == M.FunctionKind.tag) {
        _functionTagMapping[function.name!] = i;
      }
    }
  }

  void _buildCodeTagMapping() {
    for (int i = 0; i < codes.length; ++i) {
      final code = codes[i].code!;
      if (code.kind == M.CodeKind.tag) {
        _codeTagMapping[code.name!] = i;
      }
    }
  }

  void _clearProfileFunctionTagTicks() =>
      _functionTagMapping.forEach((String name, int tableIndex) {
        // Truncated tag is ticked in the VM, so don't clear it.
        if (name != kTruncatedTag) {
          functions[tableIndex].clearTicks();
        }
      });

  void _clearProfileCodeTagTicks() =>
      _codeTagMapping.forEach((String name, int tableIndex) {
        // Truncated tag is ticked in the VM, so don't clear it.
        if (name != kTruncatedTag) {
          codes[tableIndex].clearTicks();
        }
      });

  NodeT _appendUserTag<NodeT extends CallTreeNode>(
      String userTag, NodeT current, Map sample) {
    bool isCode = (current is CodeCallTreeNode);
    try {
      final tableIndex = isCode
          ? _getProfileCodeTagIndex(userTag)
          : _getProfileFunctionTagIndex(userTag);
      current = current.getChild(tableIndex) as NodeT;
      current.tick(sample);
    } catch (_) {/* invalid tag */} finally {
      return current;
    }
  }

  NodeT _appendTruncatedTag<NodeT extends CallTreeNode>(
      NodeT current, Map sample) {
    final isCode = (current is CodeCallTreeNode);
    try {
      final tableIndex = isCode
          ? _getProfileCodeTagIndex(kTruncatedTag)
          : _getProfileFunctionTagIndex(kTruncatedTag);
      current = current.getChild(tableIndex) as NodeT;
      current.tick(sample);
      // We don't need to tick the tag itself since this is done in the VM for
      // the truncated tag, unlike other VM and user tags.
    } catch (_) {/* invalid tag */} finally {
      return current;
    }
  }

  FunctionCallTreeNode _getFunctionTagAndTick(
      String tag, FunctionCallTreeNode current, Map sample) {
    try {
      final tableIndex = _getProfileFunctionTagIndex(tag);
      current = current.getChild(tableIndex);
      current.tick(sample);
    } catch (_) {/* invalid tag */} finally {
      return current;
    }
  }

  CodeCallTreeNode _getCodeTagAndTick(
      String tag, CodeCallTreeNode current, Map sample) {
    try {
      final tableIndex = _getProfileCodeTagIndex(tag);
      current = current.getChild(tableIndex);
      current.tick(sample);
    } catch (_) {/* invalid tag */} finally {
      return current;
    }
  }

  NodeT _getTagAndTick<NodeT extends CallTreeNode>(
      String tag, NodeT current, Map sample) {
    if (current is FunctionCallTreeNode) {
      return _getFunctionTagAndTick(tag, current, sample) as NodeT;
    } else if (current is CodeCallTreeNode) {
      return _getCodeTagAndTick(tag, current, sample) as NodeT;
    }
    throw ArgumentError('Unexpected tree type: $NodeT');
  }

  NodeT _appendVMTag<NodeT extends CallTreeNode>(
      String vmTag, NodeT current, Map sample) {
    if (_isNativeEntryTag(sample)) {
      return _getTagAndTick(kNativeTag, current, sample);
    } else if (_isRuntimeEntryTag(sample)) {
      return _getTagAndTick(kRuntimeTag, current, sample);
    } else {
      return _getTagAndTick(vmTag, current, sample);
    }
  }

  NodeT _appendSpecificNativeRuntimeEntryVMTag<NodeT extends CallTreeNode>(
      NodeT current, Map sample) {
    // Only Native and Runtime entries have a second VM tag.
    if (!_isNativeEntryTag(sample) && !_isRuntimeEntryTag(sample)) {
      return current;
    }
    final vmTag = sample[_kVmTag];
    return _getTagAndTick(vmTag, current, sample);
  }

  NodeT _appendVMTags<NodeT extends CallTreeNode>(
      String vmTag, NodeT current, Map sample) {
    current = _appendVMTag(vmTag, current, sample);
    current = _appendSpecificNativeRuntimeEntryVMTag(current, sample);
    return current;
  }

  void _tickTags(String vmTag, String userTag, bool tickCode) {
    if (tickCode) {
      final vmTagIndex = _getProfileCodeTagIndex(vmTag);
      codes[vmTagIndex].tickTag();

      final userTagIndex = _getProfileCodeTagIndex(userTag);
      codes[userTagIndex].tickTag();
    } else {
      final vmTagIndex = _getProfileFunctionTagIndex(vmTag);
      functions[vmTagIndex].tickTag();

      final userTagIndex = _getProfileFunctionTagIndex(userTag);
      functions[userTagIndex].tickTag();
    }
  }

  NodeT _appendTags<NodeT extends CallTreeNode>(
      String vmTag, String userTag, NodeT current, Map sample) {
    final tickCode = (current is M.CodeCallTreeNode);
    _tickTags(vmTag, userTag, tickCode);
    if (tagOrder == M.SampleProfileTag.none) {
      return current;
    }
    // User first.
    if (tagOrder == M.SampleProfileTag.userVM ||
        tagOrder == M.SampleProfileTag.userOnly) {
      current = _appendUserTag(userTag, current, sample);
      // Only user.
      if (tagOrder == M.SampleProfileTag.userOnly) {
        return current;
      }
      return _appendVMTags(vmTag, current, sample);
    }

    // VM first.
    current = _appendVMTags(vmTag, current, sample);
    // Only VM.
    if (tagOrder == M.SampleProfileTag.vmOnly) {
      return current;
    }
    return _appendUserTag(userTag, current, sample);
  }

  NodeT _processFrame<NodeT extends CallTreeNode>(NodeT parent, int sampleIndex,
      Map sample, List<int> stack, int frameIndex, bool inclusive) {
    final child = parent.getChild(stack[frameIndex]);
    child.tick(sample, exclusive: (frameIndex == 0));
    return child as NodeT;
  }

  FunctionCallTreeNode buildFunctionTrie(bool inclusive) {
    final root = FunctionCallTreeNode.fromIndex(
        this, _getProfileFunctionTagIndex(kRootTag));

    for (int sampleIndex = 0; sampleIndex < samples.length; ++sampleIndex) {
      final sample = samples[sampleIndex];
      FunctionCallTreeNode current = root;
      // Tick the root for each sample as we always visit the root node.
      root.tick(sample);

      // VM + User tags.
      final vmTag = sample[_kVmTag];
      final userTag = sample[_kUserTag];
      final stack = sample[_kStack].cast<int>();
      current = _appendTags(vmTag, userTag, current, sample);

      if (inclusive) {
        if (_isTruncated(sample)) {
          current = _appendTruncatedTag(current, sample);
        }
        for (int frameIndex = stack.length - 1; frameIndex >= 0; --frameIndex) {
          current = _processFrame(
              current, sampleIndex, sample, stack, frameIndex, true);
        }

        // Used by the timeline to find the root of each sample.
        sample[kTimelineFunctionTrie] = current;
      } else {
        for (int frameIndex = 0; frameIndex < stack.length; ++frameIndex) {
          current = _processFrame(
              current, sampleIndex, sample, stack, frameIndex, false);
        }

        if (_isTruncated(sample)) {
          current = _appendTruncatedTag(current, sample);
        }
      }
    }
    return root;
  }

  CodeCallTreeNode buildCodeTrie(bool inclusive) {
    final root =
        CodeCallTreeNode.fromIndex(this, _getProfileCodeTagIndex(kRootTag));

    for (int sampleIndex = 0; sampleIndex < samples.length; ++sampleIndex) {
      final sample = samples[sampleIndex];

      CodeCallTreeNode current = root;
      // Tick the root for each sample as we always visit the root node.
      root.tick(sample);

      // VM + User tags.
      final vmTag = sample[_kVmTag];
      final userTag = sample[_kUserTag];
      final stack = sample[_kCodeStack].cast<int>();
      current = _appendTags(vmTag, userTag, current, sample);

      if (inclusive) {
        if (_isTruncated(sample)) {
          current = _appendTruncatedTag(current, sample);
        }
        for (int frameIndex = stack.length - 1; frameIndex >= 0; --frameIndex) {
          current = _processFrame(
              current, sampleIndex, sample, stack, frameIndex, true);
        }
      } else {
        for (int frameIndex = 0; frameIndex < stack.length; ++frameIndex) {
          current = _processFrame(
              current, sampleIndex, sample, stack, frameIndex, false);
        }

        if (_isTruncated(sample)) {
          current = _appendTruncatedTag(current, sample);
        }
      }
    }
    return root;
  }

  FunctionCallTree _loadFunctionTree(bool inclusive) {
    // Since we're only ticking tag functions when building the trie, we need
    // to clean up ticks from previous tree builds.
    _clearProfileFunctionTagTicks();

    // Read the tree, returns the root node.
    final root = buildFunctionTrie(inclusive);
    root.sortChildren();
    return FunctionCallTree(inclusive, root);
  }

  CodeCallTree _loadCodeTree(bool inclusive) {
    // Since we're only ticking tag code when building the trie, we need
    // to clean up ticks from previous tree builds.
    _clearProfileCodeTagTicks();

    // Read the tree, returns the root node.
    final root = buildCodeTrie(inclusive);
    root.sortChildren();
    return CodeCallTree(inclusive, root);
  }

  int approximateMillisecondsForCount(count) {
    return (count * samplePeriod) ~/ Duration.microsecondsPerMillisecond;
  }

  double approximateSecondsForCount(count) {
    return (count * samplePeriod) / Duration.microsecondsPerSecond;
  }
}
