// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cpu_profiler;

class CodeCallTreeNode {
  final ProfileCode profileCode;
  final int count;
  double get percentage => _percentage;
  double _percentage = 0.0;
  final children;
  final Set<String> attributes = new Set<String>();
  CodeCallTreeNode(this.profileCode, this.count, int childCount)
      : children = new List<CodeCallTreeNode>(childCount) {
    attributes.addAll(profileCode.attributes);
  }
}

class CodeCallTree {
  final bool inclusive;
  final CodeCallTreeNode root;
  CodeCallTree(this.inclusive, this.root) {
    _setCodePercentage(null, root);
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

  _recordCallerAndCalleesInner(CodeCallTreeNode caller,
                               CodeCallTreeNode callee) {
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

class FunctionCallTreeNode {
  final ProfileFunction profileFunction;
  final int count;
  double get percentage => _percentage;
  double _percentage = 0.0;
  final children = new List<FunctionCallTreeNode>();
  final Set<String> attributes = new Set<String>();
  final codes = new List<FunctionCallTreeNodeCode>();
  int _totalCodeTicks = 0;
  int get totalCodesTicks => _totalCodeTicks;

  FunctionCallTreeNode(this.profileFunction, this.count){
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
      if (profileCode.code.kind == CodeKind.Stub) {
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
      if (profileCode.code.kind == CodeKind.Stub) {
        continue;
      }
      // If the code's function isn't this function.
      if (profileCode.code.function != profileFunction.function) {
        return true;
      }
    }
    return false;
  }

  setCodeAttributes() {
  }
}

/// Predicate filter function. Returns true if path from root to [node] and all
/// of [node]'s children should be added to the filtered tree.
typedef bool FunctionCallTreeNodeFilter(FunctionCallTreeNode node);

/// Build a filter version of a FunctionCallTree.
class _FilteredFunctionCallTreeBuilder {
  /// The filter.
  final FunctionCallTreeNodeFilter filter;
  /// The unfiltered tree.
  final FunctionCallTree _unfilteredTree;
  /// The filtered tree (construct by [build]).
  final FunctionCallTree filtered;
  final List _currentPath = [];

  /// Construct a filtered tree builder using [filter] and [tree].
  _FilteredFunctionCallTreeBuilder(this.filter, FunctionCallTree tree)
      : _unfilteredTree = tree,
        filtered =
          new FunctionCallTree(
              tree.inclusive,
              new FunctionCallTreeNode(
                  tree.root.profileFunction,
                  tree.root.count));

  /// Build the filtered tree.
  build() {
    assert(filtered != null);
    assert(filter != null);
    assert(_unfilteredTree != null);
    _descend(_unfilteredTree.root);
  }

  FunctionCallTreeNode _findFunctionInChildren(FunctionCallTreeNode current,
                                               FunctionCallTreeNode needle) {
    for (var child in current.children) {
      if (child.profileFunction == needle.profileFunction) {
        return child;
      }
    }
    return null;
  }

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
      var child = _findFunctionInChildren(current, toAdd);
      if (child == null) {
        // New node.
        child = new FunctionCallTreeNode(toAdd.profileFunction, toAdd.count);
        current.children.add(child);
      }
      current = child;
      assert(current.count == toAdd.count);
    }
    return current;
  }

  /// Starting at [current] append [next] and all of [next]'s sub-trees
  _appendTree(FunctionCallTreeNode current, FunctionCallTreeNode next) {
    if (next == null) {
      return;
    }
    var child = _findFunctionInChildren(current, next);
    if (child == null) {
      child = new FunctionCallTreeNode(next.profileFunction, next.count);
      current.children.add(child);
    }
    current = child;
    for (var nextChild in next.children) {
      _appendTree(current, nextChild);
    }
  }

  /// Add path from root to [child], [child], and all of [child]'s sub-trees
  /// to filtered tree.
  _addTree(FunctionCallTreeNode child) {
    var current = _addCurrentPath();
    _appendTree(current, child);
  }

  /// Descend further into the tree. [current] is from the unfiltered tree.
  _descend(FunctionCallTreeNode current) {
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

class FunctionCallTree {
  final bool inclusive;
  final FunctionCallTreeNode root;
  FunctionCallTree(this.inclusive, this.root) {
    _setFunctionPercentage(null, root);
  }

  FunctionCallTree filtered(FunctionCallTreeNodeFilter filter) {
    var treeFilter = new _FilteredFunctionCallTreeBuilder(filter, this);
    treeFilter.build();
    _setFunctionPercentage(null, treeFilter.filtered.root);
    return treeFilter.filtered;
  }

  void _setFunctionPercentage(FunctionCallTreeNode parent,
                              FunctionCallTreeNode node) {
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

  _markFunctionCallsInner(FunctionCallTreeNode caller,
                          FunctionCallTreeNode callee) {
    if (caller != null) {
      caller.profileFunction._recordCallee(callee.profileFunction, callee.count);
      callee.profileFunction._recordCaller(caller.profileFunction, caller.count);
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

class ProfileCode {
  final CpuProfile profile;
  final Code code;
  int exclusiveTicks;
  int inclusiveTicks;
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

  void _processTicks(List<String> profileTicks) {
    assert(profileTicks != null);
    assert((profileTicks.length % 3) == 0);
    for (var i = 0; i < profileTicks.length; i += 3) {
      var address = int.parse(profileTicks[i], radix:16);
      var exclusive = int.parse(profileTicks[i + 1]);
      var inclusive = int.parse(profileTicks[i + 2]);
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

    if (code.isDartCode) {
      if (code.isOptimized) {
        attributes.add('optimized');
      } else {
        attributes.add('unoptimized');
      }
    }
    if (code.isDartCode) {
      attributes.add('dart');
    } else if (code.kind == CodeKind.Tag) {
      attributes.add('tag');
    } else if (code.kind == CodeKind.Native) {
      attributes.add('native');
    }
    inclusiveTicks = int.parse(data['inclusiveTicks']);
    exclusiveTicks = int.parse(data['exclusiveTicks']);

    normalizedExclusiveTicks = exclusiveTicks / profile.sampleCount;

    normalizedInclusiveTicks = inclusiveTicks / profile.sampleCount;

    var ticks = data['ticks'];
    if (ticks != null) {
      _processTicks(ticks);
    }

    formattedExclusivePercent =
        Utils.formatPercent(exclusiveTicks, profile.sampleCount);

    formattedCpuTime =
        Utils.formatTimeMilliseconds(
            profile.approximateMillisecondsForCount(exclusiveTicks));

    formattedOnStackTime =
        Utils.formatTimeMilliseconds(
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

class ProfileFunction {
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
      if (profileCode.code.kind == CodeKind.Stub) {
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
      if (profileCode.code.kind == CodeKind.Stub) {
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
    if (function.kind == FunctionKind.kTag) {
      attribs.add('tag');
    } else if (function.kind == FunctionKind.kStub) {
      attribs.add('dart');
      attribs.add('stub');
    } else if (function.kind == FunctionKind.kNative) {
      attribs.add('native');
    } else if (function.kind.isSynthetic()) {
      attribs.add('synthetic');
    } else {
      attribs.add('dart');
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
    exclusiveTicks = int.parse(data['exclusiveTicks']);
    inclusiveTicks = int.parse(data['inclusiveTicks']);

    normalizedExclusiveTicks = exclusiveTicks / profile.sampleCount;
    normalizedInclusiveTicks = inclusiveTicks / profile.sampleCount;

    formattedExclusivePercent =
        Utils.formatPercent(exclusiveTicks, profile.sampleCount);

    formattedCpuTime =
        Utils.formatTimeMilliseconds(
            profile.approximateMillisecondsForCount(exclusiveTicks));

    formattedOnStackTime =
        Utils.formatTimeMilliseconds(
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
class CpuProfile {
  final double MICROSECONDS_PER_SECOND = 1000000.0;
  final double displayThreshold = 0.0002; // 0.02%.

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

  CodeCallTree loadCodeTree(String name) {
    if (name == 'inclusive') {
      return _loadCodeTree(true, tries['inclusiveCodeTrie']);
    } else {
      return _loadCodeTree(false, tries['exclusiveCodeTrie']);
    }
  }

  FunctionCallTree loadFunctionTree(String name) {
    if (name == 'inclusive') {
      return _loadFunctionTree(true, tries['inclusiveFunctionTrie']);
    } else {
      return _loadFunctionTree(false, tries['exclusiveFunctionTrie']);
    }
  }

  buildCodeCallerAndCallees() {
    if (_builtCodeCalls) {
      return;
    }
    _builtCodeCalls = true;
    var tree = loadCodeTree('inclusive');
    tree._recordCallerAndCallees();
  }

  buildFunctionCallerAndCallees() {
    if (_builtFunctionCalls) {
      return;
    }
    _builtFunctionCalls = true;
    var tree = loadFunctionTree('inclusive');
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

  load(Isolate isolate, ServiceMap profile) {
    clear();
    if ((isolate == null) || (profile == null)) {
      return;
    }

    this.isolate = isolate;
    isolate.resetCachedProfileData();

    sampleCount = profile['sampleCount'];
    samplePeriod = profile['samplePeriod'];
    sampleRate = (MICROSECONDS_PER_SECOND / samplePeriod);
    stackDepth = profile['stackDepth'];
    timeSpan = profile['timeSpan'];

    // Process code table.
    for (var codeRegion in profile['codes']) {
      Code code = codeRegion['code'];
      assert(code != null);
      codes.add(new ProfileCode.fromMap(this, code, codeRegion));
    }

    // Process function table.
    for (var profileFunction in profile['functions']) {
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
    // Create node.
    var node = new CodeCallTreeNode(code, count, children);
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
    // Create node.
    var node = new FunctionCallTreeNode(function, count);
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
    var MICROSECONDS_PER_MILLISECOND = 1000.0;
    return (count * samplePeriod) ~/ MICROSECONDS_PER_MILLISECOND;
  }

  double approximateSecondsForCount(count) {
    var MICROSECONDS_PER_SECOND = 1000000.0;
    return (count * samplePeriod) / MICROSECONDS_PER_SECOND;
  }
}
