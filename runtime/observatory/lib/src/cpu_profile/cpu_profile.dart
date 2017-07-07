// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cpu_profiler;

abstract class CallTreeNode<NodeT extends M.CallTreeNode>
    implements M.CallTreeNode {
  final List<NodeT> children;
  final int count;
  final int inclusiveNativeAllocations;
  final int exclusiveNativeAllocations;
  double get percentage => _percentage;
  double _percentage = 0.0;
  final Set<String> attributes = new Set<String>();

  // Either a ProfileCode or a ProfileFunction.
  Object get profileData;
  String get name;

  CallTreeNode(this.children, this.count, this.inclusiveNativeAllocations,
      this.exclusiveNativeAllocations);
}

class CodeCallTreeNode extends CallTreeNode<CodeCallTreeNode>
    implements M.CodeCallTreeNode {
  final ProfileCode profileCode;

  Object get profileData => profileCode;

  String get name => profileCode.code.name;

  final Set<String> attributes = new Set<String>();
  CodeCallTreeNode(this.profileCode, int count, int inclusiveNativeAllocations,
      int exclusiveNativeAllocations)
      : super(new List<CodeCallTreeNode>(), count, inclusiveNativeAllocations,
            exclusiveNativeAllocations) {
    attributes.addAll(profileCode.attributes);
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
    var treeFilter = new _FilteredCodeCallTreeBuilder(filter, this);
    treeFilter.build();
    if ((treeFilter.filtered.root.inclusiveNativeAllocations != null) &&
        (treeFilter.filtered.root.inclusiveNativeAllocations != 0)) {
      _setCodeMemoryPercentage(null, treeFilter.filtered.root);
    } else {
      _setCodePercentage(null, treeFilter.filtered.root);
    }
    return treeFilter.filtered;
  }

  _setCodePercentage(CodeCallTreeNode parent, CodeCallTreeNode node) {
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

  _setCodeMemoryPercentage(CodeCallTreeNode parent, CodeCallTreeNode node) {
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
  }

  _recordCallerAndCalleesInner(
      CodeCallTreeNode caller, CodeCallTreeNode callee) {
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

class FunctionCallTreeNode extends CallTreeNode {
  final ProfileFunction profileFunction;
  final codes = new List<FunctionCallTreeNodeCode>();
  int _totalCodeTicks = 0;
  int get totalCodesTicks => _totalCodeTicks;

  String get name => M.getFunctionFullName(profileFunction.function);
  Object get profileData => profileFunction;

  FunctionCallTreeNode(this.profileFunction, int count,
      inclusiveNativeAllocations, exclusiveNativeAllocations)
      : super(new List<FunctionCallTreeNode>(), count,
            inclusiveNativeAllocations, exclusiveNativeAllocations) {
    profileFunction._addKindBasedAttributes(attributes);
  }

  // Does this function have an optimized version of itself?
  bool hasOptimizedCode() {
    for (var nodeCode in codes) {
      var profileCode = nodeCode.code;
      if (!profileCode.code.isDartCode) {
        continue;
      }
      if (profileCode.code.function != profileFunction.function) {
        continue;
      }
      if (profileCode.code.isOptimized) {
        return true;
      }
    }
    return false;
  }

  // Does this function have an unoptimized version of itself?
  bool hasUnoptimizedCode() {
    for (var nodeCode in codes) {
      var profileCode = nodeCode.code;
      if (!profileCode.code.isDartCode) {
        continue;
      }
      if (profileCode.code.kind == M.CodeKind.stub) {
        continue;
      }
      if (!profileCode.code.isOptimized) {
        return true;
      }
    }
    return false;
  }

  // Has this function been inlined in another function?
  bool isInlined() {
    for (var nodeCode in codes) {
      var profileCode = nodeCode.code;
      if (!profileCode.code.isDartCode) {
        continue;
      }
      if (profileCode.code.kind == M.CodeKind.stub) {
        continue;
      }
      // If the code's function isn't this function.
      if (profileCode.code.function != profileFunction.function) {
        return true;
      }
    }
    return false;
  }

  setCodeAttributes() {}
}

/// Predicate filter function. Returns true if path from root to [node] and all
/// of [node]'s children should be added to the filtered tree.
typedef bool CallTreeNodeFilter(CallTreeNode node);

/// Build a filter version of a FunctionCallTree.
abstract class _FilteredCallTreeBuilder {
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

  CallTreeNode _findInChildren(CallTreeNode current, CallTreeNode needle) {
    for (var child in current.children) {
      if (child.profileData == needle.profileData) {
        return child;
      }
    }
    return null;
  }

  CallTreeNode _copyNode(CallTreeNode node);

  /// Add all nodes in [_currentPath].
  FunctionCallTreeNode _addCurrentPath() {
    FunctionCallTreeNode current = filtered.root;
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
        current.children.add(child);
      }
      current = child;
      assert(current.count == toAdd.count);
    }
    return current;
  }

  /// Starting at [current] append [next] and all of [next]'s sub-trees
  _appendTree(CallTreeNode current, CallTreeNode next) {
    if (next == null) {
      return;
    }
    var child = _findInChildren(current, next);
    if (child == null) {
      child = _copyNode(next);
      current.children.add(child);
    }
    current = child;
    for (var nextChild in next.children) {
      _appendTree(current, nextChild);
    }
  }

  /// Add path from root to [child], [child], and all of [child]'s sub-trees
  /// to filtered tree.
  _addTree(CallTreeNode child) {
    var current = _addCurrentPath();
    _appendTree(current, child);
  }

  /// Descend further into the tree. [current] is from the unfiltered tree.
  _descend(CallTreeNode current) {
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
          _addTree(child);
        }
      }
    } else {
      // Did not match, descend to each child.
      for (var child in current.children) {
        _descend(child);
      }
    }

    var last = _currentPath.removeLast();
    assert(current == last);
  }
}

class _FilteredFunctionCallTreeBuilder extends _FilteredCallTreeBuilder {
  _FilteredFunctionCallTreeBuilder(
      CallTreeNodeFilter filter, FunctionCallTree tree)
      : super(
            filter,
            tree,
            new FunctionCallTree(
                tree.inclusive,
                new FunctionCallTreeNode(
                    tree.root.profileData,
                    tree.root.count,
                    tree.root.inclusiveNativeAllocations,
                    tree.root.exclusiveNativeAllocations)));

  _copyNode(FunctionCallTreeNode node) {
    return new FunctionCallTreeNode(node.profileData, node.count,
        node.inclusiveNativeAllocations, node.exclusiveNativeAllocations);
  }
}

class _FilteredCodeCallTreeBuilder extends _FilteredCallTreeBuilder {
  _FilteredCodeCallTreeBuilder(CallTreeNodeFilter filter, CodeCallTree tree)
      : super(
            filter,
            tree,
            new CodeCallTree(
                tree.inclusive,
                new CodeCallTreeNode(
                    tree.root.profileData,
                    tree.root.count,
                    tree.root.inclusiveNativeAllocations,
                    tree.root.exclusiveNativeAllocations)));

  _copyNode(CodeCallTreeNode node) {
    return new CodeCallTreeNode(node.profileData, node.count,
        node.inclusiveNativeAllocations, node.exclusiveNativeAllocations);
  }
}

class FunctionCallTree extends CallTree implements M.FunctionCallTree {
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
    var treeFilter = new _FilteredFunctionCallTreeBuilder(filter, this);
    treeFilter.build();
    if ((treeFilter.filtered.root.inclusiveNativeAllocations != null) &&
        (treeFilter.filtered.root.inclusiveNativeAllocations != 0)) {
      _setFunctionMemoryPercentage(null, treeFilter.filtered.root);
    } else {
      _setFunctionPercentage(null, treeFilter.filtered.root);
    }
    return treeFilter.filtered;
  }

  void _setFunctionPercentage(
      FunctionCallTreeNode parent, FunctionCallTreeNode node) {
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
      FunctionCallTreeNode parent, FunctionCallTreeNode node) {
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
  }

  _markFunctionCallsInner(
      FunctionCallTreeNode caller, FunctionCallTreeNode callee) {
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
  final CpuProfile profile;
  final Code code;
  int exclusiveTicks;
  int inclusiveTicks;
  int exclusiveNativeAllocations;
  int inclusiveNativeAllocations;
  double normalizedExclusiveTicks = 0.0;
  double normalizedInclusiveTicks = 0.0;
  final addressTicks = new Map<int, CodeTick>();
  final intervalTicks = new Map<int, InlineIntervalTick>();
  String formattedInclusiveTicks = '';
  String formattedExclusiveTicks = '';
  String formattedExclusivePercent = '';
  String formattedCpuTime = '';
  String formattedOnStackTime = '';
  final Set<String> attributes = new Set<String>();
  final Map<ProfileCode, int> callers = new Map<ProfileCode, int>();
  final Map<ProfileCode, int> callees = new Map<ProfileCode, int>();

  void _processTicks(List<dynamic> profileTicks) {
    assert(profileTicks != null);
    assert((profileTicks.length % 3) == 0);
    for (var i = 0; i < profileTicks.length; i += 3) {
      // TODO(observatory): Address is not necessarily representable as a JS
      // integer.
      var address = int.parse(profileTicks[i] as String, radix: 16);
      var exclusive = profileTicks[i + 1] as int;
      var inclusive = profileTicks[i + 2] as int;
      var tick = new CodeTick(exclusive, inclusive);
      addressTicks[address] = tick;

      var interval = code.findInterval(address);
      if (interval != null) {
        var intervalTick = intervalTicks[interval.start];
        if (intervalTick == null) {
          // Insert into map.
          intervalTick = new InlineIntervalTick(interval.start);
          intervalTicks[interval.start] = intervalTick;
        }
        intervalTick._inclusiveTicks += inclusive;
        intervalTick._exclusiveTicks += exclusive;
      }
    }
  }

  ProfileCode.fromMap(this.profile, this.code, Map data) {
    assert(profile != null);
    assert(code != null);

    code.profile = this;

    if (code.kind == M.CodeKind.stub) {
      attributes.add('stub');
    } else if (code.kind == M.CodeKind.dart) {
      if (code.isNative) {
        attributes.add('ffi'); // Not to be confused with a C function.
      } else {
        attributes.add('dart');
      }
      if (code.hasIntrinsic) {
        attributes.add('intrinsic');
      }
      if (code.isOptimized) {
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

    if (data.containsKey('exclusiveNativeAllocations') &&
        data.containsKey('inclusiveNativeAllocations')) {
      exclusiveNativeAllocations =
          int.parse(data['exclusiveNativeAllocations']);
      inclusiveNativeAllocations =
          int.parse(data['inclusiveNativeAllocations']);
    }

    formattedExclusivePercent =
        Utils.formatPercent(exclusiveTicks, profile.sampleCount);

    formattedCpuTime = Utils.formatTimeMilliseconds(
        profile.approximateMillisecondsForCount(exclusiveTicks));

    formattedOnStackTime = Utils.formatTimeMilliseconds(
        profile.approximateMillisecondsForCount(inclusiveTicks));

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
}

class ProfileFunction implements M.ProfileFunction {
  final CpuProfile profile;
  final ServiceFunction function;
  // List of compiled code objects containing this function.
  final List<ProfileCode> profileCodes = new List<ProfileCode>();
  final Map<ProfileFunction, int> callers = new Map<ProfileFunction, int>();
  final Map<ProfileFunction, int> callees = new Map<ProfileFunction, int>();

  // Absolute ticks:
  int exclusiveTicks = 0;
  int inclusiveTicks = 0;

  // Global percentages:
  double normalizedExclusiveTicks = 0.0;
  double normalizedInclusiveTicks = 0.0;

  // Native allocations:
  int exclusiveNativeAllocations = 0;
  int inclusiveNativeAllocations = 0;

  String formattedInclusiveTicks = '';
  String formattedExclusiveTicks = '';
  String formattedExclusivePercent = '';
  String formattedCpuTime = '';
  String formattedOnStackTime = '';
  final Set<String> attributes = new Set<String>();

  int _sortCodes(ProfileCode a, ProfileCode b) {
    if (a.code.isOptimized == b.code.isOptimized) {
      return b.code.profile.exclusiveTicks - a.code.profile.exclusiveTicks;
    }
    if (a.code.isOptimized) {
      return -1;
    }
    return 1;
  }

  // Does this function have an optimized version of itself?
  bool hasOptimizedCode() {
    for (var profileCode in profileCodes) {
      if (profileCode.code.function != function) {
        continue;
      }
      if (profileCode.code.isOptimized) {
        return true;
      }
    }
    return false;
  }

  // Does this function have an unoptimized version of itself?
  bool hasUnoptimizedCode() {
    for (var profileCode in profileCodes) {
      if (profileCode.code.kind == M.CodeKind.stub) {
        continue;
      }
      if (!profileCode.code.isDartCode) {
        continue;
      }
      if (!profileCode.code.isOptimized) {
        return true;
      }
    }
    return false;
  }

  // Has this function been inlined in another function?
  bool isInlined() {
    for (var profileCode in profileCodes) {
      if (profileCode.code.kind == M.CodeKind.stub) {
        continue;
      }
      if (!profileCode.code.isDartCode) {
        continue;
      }
      // If the code's function isn't this function.
      if (profileCode.code.function != function) {
        return true;
      }
    }
    return false;
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
    } else if (function.isNative) {
      attribs.add('ffi'); // Not to be confused with a C function.
    } else {
      attribs.add('dart');
    }
    if (function.hasIntrinsic == true) {
      attribs.add('intrinsic');
    }
  }

  ProfileFunction.fromMap(this.profile, this.function, Map data) {
    function.profile = this;
    for (var codeIndex in data['codes']) {
      var profileCode = profile.codes[codeIndex];
      profileCodes.add(profileCode);
    }
    profileCodes.sort(_sortCodes);

    _addKindBasedAttributes(attributes);
    exclusiveTicks = data['exclusiveTicks'];
    inclusiveTicks = data['inclusiveTicks'];

    normalizedExclusiveTicks = exclusiveTicks / profile.sampleCount;
    normalizedInclusiveTicks = inclusiveTicks / profile.sampleCount;

    if (data.containsKey('exclusiveNativeAllocations') &&
        data.containsKey('inclusiveNativeAllocations')) {
      exclusiveNativeAllocations =
          int.parse(data['exclusiveNativeAllocations']);
      inclusiveNativeAllocations =
          int.parse(data['inclusiveNativeAllocations']);
    }

    formattedExclusivePercent =
        Utils.formatPercent(exclusiveTicks, profile.sampleCount);

    formattedCpuTime = Utils.formatTimeMilliseconds(
        profile.approximateMillisecondsForCount(exclusiveTicks));

    formattedOnStackTime = Utils.formatTimeMilliseconds(
        profile.approximateMillisecondsForCount(inclusiveTicks));

    formattedInclusiveTicks =
        '${Utils.formatPercent(inclusiveTicks, profile.sampleCount)} '
        '($inclusiveTicks)';

    formattedExclusiveTicks =
        '${Utils.formatPercent(exclusiveTicks, profile.sampleCount)} '
        '($exclusiveTicks)';
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
}

// TODO(johnmccutchan): Rename to SampleProfile
class CpuProfile extends M.SampleProfile {
  Isolate isolate;

  int sampleCount = 0;
  int samplePeriod = 0;
  double sampleRate = 0.0;

  int stackDepth = 0;

  double timeSpan = 0.0;

  final Map<String, List> tries = <String, List>{};
  final List<ProfileCode> codes = new List<ProfileCode>();
  bool _builtCodeCalls = false;
  final List<ProfileFunction> functions = new List<ProfileFunction>();
  bool _builtFunctionCalls = false;

  CodeCallTree loadCodeTree(M.ProfileTreeDirection direction) {
    switch (direction) {
      case M.ProfileTreeDirection.inclusive:
        return _loadCodeTree(true, tries['inclusiveCodeTrie']);
      case M.ProfileTreeDirection.exclusive:
        return _loadCodeTree(false, tries['exclusiveCodeTrie']);
    }
    throw new Exception('Unknown ProfileTreeDirection');
  }

  FunctionCallTree loadFunctionTree(M.ProfileTreeDirection direction) {
    switch (direction) {
      case M.ProfileTreeDirection.inclusive:
        return _loadFunctionTree(true, tries['inclusiveFunctionTrie']);
      case M.ProfileTreeDirection.exclusive:
        return _loadFunctionTree(false, tries['exclusiveFunctionTrie']);
    }
    throw new Exception('Unknown ProfileTreeDirection');
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
    sampleCount = 0;
    samplePeriod = 0;
    sampleRate = 0.0;
    stackDepth = 0;
    timeSpan = 0.0;
    codes.clear();
    functions.clear();
    tries.clear();
    _builtCodeCalls = false;
    _builtFunctionCalls = false;
  }

  Future load(ServiceObjectOwner owner, ServiceMap profile) async {
    await loadProgress(owner, profile).last;
  }

  static Future sleep([Duration duration = const Duration(microseconds: 0)]) {
    final Completer completer = new Completer();
    new Timer(duration, () => completer.complete());
    return completer.future;
  }

  Stream<double> loadProgress(ServiceObjectOwner owner, ServiceMap profile) {
    var progress = new StreamController<double>.broadcast();

    (() async {
      final Stopwatch watch = new Stopwatch();
      watch.start();
      int count = 0;
      var needToUpdate = () {
        count++;
        if (((count % 256) == 0) && (watch.elapsedMilliseconds > 16)) {
          watch.reset();
          return true;
        }
        return false;
      };
      var signal = (double p) {
        progress.add(p);
        return sleep();
      };
      try {
        clear();
        progress.add(0.0);
        if (profile == null) {
          return;
        }

        if ((owner != null) && (owner is Isolate)) {
          isolate = owner;
          isolate.resetCachedProfileData();
        }

        sampleCount = profile['sampleCount'];
        samplePeriod = profile['samplePeriod'];
        sampleRate = (Duration.MICROSECONDS_PER_SECOND / samplePeriod);
        stackDepth = profile['stackDepth'];
        timeSpan = profile['timeSpan'];

        num length = profile['codes'].length + profile['functions'].length;

        // Process code table.
        for (var codeRegion in profile['codes']) {
          if (needToUpdate()) {
            await signal(count * 100.0 / length);
          }
          Code code = codeRegion['code'];
          assert(code != null);
          codes.add(new ProfileCode.fromMap(this, code, codeRegion));
        }
        // Process function table.
        for (var profileFunction in profile['functions']) {
          if (needToUpdate()) {
            await signal(count * 100 / length);
          }
          ServiceFunction function = profileFunction['function'];
          assert(function != null);
          functions.add(
              new ProfileFunction.fromMap(this, function, profileFunction));
        }

        tries['exclusiveCodeTrie'] =
            new Uint32List.fromList(profile['exclusiveCodeTrie']);
        tries['inclusiveCodeTrie'] =
            new Uint32List.fromList(profile['inclusiveCodeTrie']);
        tries['exclusiveFunctionTrie'] =
            new Uint32List.fromList(profile['exclusiveFunctionTrie']);
        tries['inclusiveFunctionTrie'] =
            new Uint32List.fromList(profile['inclusiveFunctionTrie']);
      } finally {
        progress.close();
      }
    }());
    return progress.stream;
  }

  // Data shared across calls to _read*TrieNode.
  int _dataCursor = 0;

  // The code trie is serialized as a list of integers. Each node
  // is recreated by consuming some portion of the list. The format is as
  // follows:
  // [0] index into codeTable of code object.
  // [1] tick count (number of times this stack frame occured).
  // [2] child node count
  // Reading the trie is done by recursively reading the tree depth-first
  // pre-order.
  CodeCallTree _loadCodeTree(bool inclusive, List<int> data) {
    if (data == null) {
      return null;
    }
    if (data.length < 3) {
      // Not enough for root node.
      return null;
    }
    // Read the tree, returns the root node.
    var root = _readCodeTrie(data);
    return new CodeCallTree(inclusive, root);
  }

  CodeCallTreeNode _readCodeTrieNode(List<int> data) {
    // Lookup code object.
    var codeIndex = data[_dataCursor++];
    var code = codes[codeIndex];
    // Node tick counter.
    var count = data[_dataCursor++];
    // Child node count.
    var children = data[_dataCursor++];
    // Inclusive native allocations.
    var inclusiveNativeAllocations = data[_dataCursor++];
    // Exclusive native allocations.
    var exclusiveNativeAllocations = data[_dataCursor++];
    // Create node.
    var node = new CodeCallTreeNode(
        code, count, inclusiveNativeAllocations, exclusiveNativeAllocations);
    node.children.length = children;
    return node;
  }

  CodeCallTreeNode _readCodeTrie(List<int> data) {
    final nodeStack = new List<CodeCallTreeNode>();
    final childIndexStack = new List<int>();

    _dataCursor = 0;
    // Read root.
    var root = _readCodeTrieNode(data);

    // Push root onto stack.
    if (root.children.length > 0) {
      nodeStack.add(root);
      childIndexStack.add(0);
    }

    while (nodeStack.length > 0) {
      var lastIndex = nodeStack.length - 1;
      // Pop parent from stack.
      var parent = nodeStack[lastIndex];
      var childIndex = childIndexStack[lastIndex];

      // Read child node.
      assert(childIndex < parent.children.length);
      var node = _readCodeTrieNode(data);
      parent.children[childIndex++] = node;

      // If parent still has children, update child index.
      if (childIndex < parent.children.length) {
        childIndexStack[lastIndex] = childIndex;
      } else {
        // Finished processing parent node.
        nodeStack.removeLast();
        childIndexStack.removeLast();
      }

      // If node has children, push onto stack.
      if (node.children.length > 0) {
        nodeStack.add(node);
        childIndexStack.add(0);
      }
    }

    return root;
  }

  FunctionCallTree _loadFunctionTree(bool inclusive, List<int> data) {
    if (data == null) {
      return null;
    }
    if (data.length < 3) {
      // Not enough integers for 1 node.
      return null;
    }
    // Read the tree, returns the root node.
    var root = _readFunctionTrie(data);
    return new FunctionCallTree(inclusive, root);
  }

  FunctionCallTreeNode _readFunctionTrieNode(List<int> data) {
    // Read index into function table.
    var index = data[_dataCursor++];
    // Lookup function object.
    var function = functions[index];
    // Counter.
    var count = data[_dataCursor++];
    // Inclusive native allocations.
    var inclusiveNativeAllocations = data[_dataCursor++];
    // Exclusive native allocations.
    var exclusiveNativeAllocations = data[_dataCursor++];
    // Create node.
    var node = new FunctionCallTreeNode(function, count,
        inclusiveNativeAllocations, exclusiveNativeAllocations);
    // Number of code index / count pairs.
    var codeCount = data[_dataCursor++];
    node.codes.length = codeCount;
    var totalCodeTicks = 0;
    for (var i = 0; i < codeCount; i++) {
      var codeIndex = data[_dataCursor++];
      var code = codes[codeIndex];
      assert(code != null);
      var codeTicks = data[_dataCursor++];
      totalCodeTicks += codeTicks;
      var nodeCode = new FunctionCallTreeNodeCode(code, codeTicks);
      node.codes[i] = nodeCode;
    }
    node.setCodeAttributes();
    node._totalCodeTicks = totalCodeTicks;
    // Number of children.
    var childCount = data[_dataCursor++];
    node.children.length = childCount;
    return node;
  }

  FunctionCallTreeNode _readFunctionTrie(List<int> data) {
    final nodeStack = new List<FunctionCallTreeNode>();
    final childIndexStack = new List<int>();

    _dataCursor = 0;

    // Read root.
    var root = _readFunctionTrieNode(data);

    // Push root onto stack.
    if (root.children.length > 0) {
      nodeStack.add(root);
      childIndexStack.add(0);
    }

    while (nodeStack.length > 0) {
      var lastIndex = nodeStack.length - 1;
      // Pop parent from stack.
      var parent = nodeStack[lastIndex];
      var childIndex = childIndexStack[lastIndex];

      // Read child node.
      assert(childIndex < parent.children.length);
      var node = _readFunctionTrieNode(data);
      parent.children[childIndex++] = node;

      // If parent still has children, update child index.
      if (childIndex < parent.children.length) {
        childIndexStack[lastIndex] = childIndex;
      } else {
        // Finished processing parent node.
        nodeStack.removeLast();
        childIndexStack.removeLast();
      }

      // If node has children, push onto stack.
      if (node.children.length > 0) {
        nodeStack.add(node);
        childIndexStack.add(0);
      }
    }

    return root;
  }

  int approximateMillisecondsForCount(count) {
    return (count * samplePeriod) ~/ Duration.MICROSECONDS_PER_MILLISECOND;
  }

  double approximateSecondsForCount(count) {
    return (count * samplePeriod) / Duration.MICROSECONDS_PER_SECOND;
  }
}
