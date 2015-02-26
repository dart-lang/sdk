// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cpu_profiler;

class CodeTrieNode {
  final ProfileCode profileCode;
  final int count;
  final children = new List<CodeTrieNode>();
  CodeTrieNode(this.profileCode, this.count);
}

class FunctionTrieNodeCode {
  final ProfileCode code;
  final int ticks;
  FunctionTrieNodeCode(this.code, this.ticks);
}

class FunctionTrieNode {
  final ProfileFunction profileFunction;
  final int count;
  final children = new List<FunctionTrieNode>();
  final codes = new List<FunctionTrieNodeCode>();
  int _totalCodeTicks = 0;
  int get totalCodesTicks => _totalCodeTicks;
  FunctionTrieNode(this.profileFunction, this.count);
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
  final addressTicks = new Map<int, CodeTick>();
  final intervalTicks = new Map<int, InlineIntervalTick>();
  String formattedInclusiveTicks = '';
  String formattedExclusiveTicks = '';

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

    inclusiveTicks = int.parse(data['inclusiveTicks']);
    exclusiveTicks = int.parse(data['exclusiveTicks']);
    var ticks = data['ticks'];
    if (ticks != null) {
      _processTicks(ticks);
    }

    formattedInclusiveTicks =
      '${Utils.formatPercent(inclusiveTicks, profile.sampleCount)} '
      '($inclusiveTicks)';

    formattedExclusiveTicks =
      '${Utils.formatPercent(exclusiveTicks, profile.sampleCount)} '
      '($exclusiveTicks)';
  }
}

class ProfileFunction {
  final CpuProfile profile;
  final ServiceFunction function;
  // List of compiled code objects containing this function.
  final List<ProfileCode> profileCodes = new List<ProfileCode>();

  // Absolute ticks:
  int exclusiveTicks = 0;
  int inclusiveTicks = 0;

  // Global percentages:
  double globalExclusiveTicks = 0.0;
  double globalInclusiveTicks = 0.0;

  int _sortCodes(ProfileCode a, ProfileCode b) {
    if (a.code.isOptimized == b.code.isOptimized) {
      return b.code.profile.exclusiveTicks - a.code.profile.exclusiveTicks;
    }
    if (a.code.isOptimized) {
      return -1;
    }
    return 1;
  }

  ProfileFunction.fromMap(this.profile, this.function, Map data) {
    for (var codeIndex in data['codes']) {
      var profileCode = profile.codes[codeIndex];
      profileCodes.add(profileCode);
    }
    profileCodes.sort(_sortCodes);

    exclusiveTicks = int.parse(data['exclusiveTicks']);
    inclusiveTicks = int.parse(data['inclusiveTicks']);

    globalExclusiveTicks = exclusiveTicks / profile.sampleCount;
    globalInclusiveTicks = inclusiveTicks / profile.sampleCount;
  }
}


class CpuProfile {
  final double MICROSECONDS_PER_SECOND = 1000000.0;
  final double displayThreshold = 0.0002; // 0.02%.

  Isolate isolate;

  int sampleCount = 0;
  int samplePeriod = 0;
  double sampleRate = 0.0;

  int stackDepth = 0;

  double timeSpan = 0.0;

  CodeTrieNode codeTrieRoot;
  FunctionTrieNode functionTrieRoot;

  final List<ProfileCode> codes = new List<ProfileCode>();
  final List<ProfileFunction> functions = new List<ProfileFunction>();

  void clear() {
    sampleCount = 0;
    samplePeriod = 0;
    sampleRate = 0.0;
    stackDepth = 0;
    timeSpan = 0.0;
    codeTrieRoot = null;
    functionTrieRoot = null;
    codes.clear();
    functions.clear();
  }

  void load(Isolate isolate, ServiceMap profile) {
    if ((isolate == null) || (profile == null)) {
      return;
    }

    this.isolate = isolate;
    isolate.resetCachedProfileData();

    clear();

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

    // Process code trie.
    var exclusiveCodeTrie = profile['exclusiveCodeTrie'];
    assert(exclusiveCodeTrie != null);
    codeTrieRoot = _processCodeTrie(exclusiveCodeTrie);

    // Process function trie.
    var exclusiveFunctionTrie = profile['exclusiveFunctionTrie'];
    assert(exclusiveFunctionTrie != null);
    functionTrieRoot = _processFunctionTrie(exclusiveFunctionTrie);
  }

  // Data shared across calls to _read*TrieNode.
  int _trieDataCursor;
  List<int> _trieData;

  // The code trie is serialized as a list of integers. Each node
  // is recreated by consuming some portion of the list. The format is as
  // follows:
  // [0] index into codeTable of code object.
  // [1] tick count (number of times this stack frame occured).
  // [2] child node count
  // Reading the trie is done by recursively reading the tree depth-first
  // pre-order.
  CodeTrieNode _processCodeTrie(List<int> data) {
    // Setup state shared across calls to _readTrieNode.
    _trieDataCursor = 0;
    _trieData = data;
    if (_trieData == null) {
      return null;
    }
    if (_trieData.length < 3) {
      // Not enough integers for 1 node.
      return null;
    }
    // Read the tree, returns the root node.
    return _readCodeTrieNode();
  }

  CodeTrieNode _readCodeTrieNode() {
    // Read index into code table.
    var index = _trieData[_trieDataCursor++];
    // Lookup code object.
    var code = codes[index];
    // Frame counter.
    var count = _trieData[_trieDataCursor++];
    // Create node.
    var node = new CodeTrieNode(code, count);
    // Number of children.
    var children = _trieData[_trieDataCursor++];
    // Recursively read child nodes.
    for (var i = 0; i < children; i++) {
      var child = _readCodeTrieNode();
      node.children.add(child);
    }
    return node;
  }

  FunctionTrieNode _processFunctionTrie(List<int> data) {
    // Setup state shared across calls to _readTrieNode.
    _trieDataCursor = 0;
    _trieData = data;
    if (_trieData == null) {
      return null;
    }
    if (_trieData.length < 3) {
      // Not enough integers for 1 node.
      return null;
    }
    // Read the tree, returns the root node.
    return _readFunctionTrieNode();
  }

  FunctionTrieNode _readFunctionTrieNode() {
    // Read index into function table.
    var index = _trieData[_trieDataCursor++];
    // Lookup function object.
    var function = functions[index];
    // Frame counter.
    var count = _trieData[_trieDataCursor++];
    // Create node.
    var node = new FunctionTrieNode(function, count);
    // Number of code index / count pairs.
    var codeCount = _trieData[_trieDataCursor++];
    var totalCodeTicks = 0;
    for (var i = 0; i < codeCount; i++) {
      var codeIndex = _trieData[_trieDataCursor++];
      var code = codes[codeIndex];
      var codeTicks = _trieData[_trieDataCursor++];
      totalCodeTicks += codeTicks;
      var nodeCode = new FunctionTrieNodeCode(code, codeTicks);
      node.codes.add(nodeCode);
    }
    node._totalCodeTicks = totalCodeTicks;
    // Number of children.
    var children = _trieData[_trieDataCursor++];
    // Recursively read child nodes.
    for (var i = 0; i < children; i++) {
      var child = _readFunctionTrieNode();
      node.children.add(child);
    }
    return node;
  }

  double approximateSecondsForCount(count) {
    var MICROSECONDS_PER_SECOND = 1000000.0;
    return (count * samplePeriod) / MICROSECONDS_PER_SECOND;
  }
}
