// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library cpu_profile_element;

import 'dart:async';
import 'dart:html';
import 'observatory_element.dart';
import 'package:logging/logging.dart';
import 'package:observatory/service.dart';
import 'package:observatory/app.dart';
import 'package:observatory/cpu_profile.dart';
import 'package:observatory/elements.dart';
import 'package:polymer/polymer.dart';

class ProfileCodeTrieNodeTreeRow extends TableTreeRow {
  final CpuProfile profile;
  @reflectable final CodeTrieNode root;
  @reflectable final CodeTrieNode node;
  @reflectable Code get code => node.profileCode.code;

  @reflectable String tipKind = '';
  @reflectable String tipParent = '';
  @reflectable String tipExclusive = '';
  @reflectable String tipTicks = '';
  @reflectable String tipTime = '';

  ProfileCodeTrieNodeTreeRow(this.profile, this.root, this.node,
                             TableTree tree,
                             ProfileCodeTrieNodeTreeRow parent)
  : super(tree, parent) {
    assert(root != null);
    assert(node != null);
    tipTicks = '${node.count}';
    var seconds = profile.approximateSecondsForCount(node.count);
    tipTime = Utils.formatTimePrecise(seconds);
    if (code.kind == CodeKind.Tag) {
      tipKind = 'Tag (category)';
      if (parent == null) {
        tipParent = Utils.formatPercent(node.count, root.count);
      } else {
        tipParent = Utils.formatPercent(node.count, parent.node.count);
      }
      tipExclusive = Utils.formatPercent(node.count, root.count);
    } else {
      if ((code.kind == CodeKind.Collected) ||
      (code.kind == CodeKind.Reused)) {
        tipKind = 'Garbage Collected Code';
      } else {
        tipKind = '${code.kind} (Function)';
      }
      if (parent == null) {
        tipParent = Utils.formatPercent(node.count, root.count);
      } else {
        tipParent = Utils.formatPercent(node.count, parent.node.count);
      }
      tipExclusive =
      Utils.formatPercent(node.profileCode.exclusiveTicks, root.count);
    }
  }

  bool shouldDisplayChild(CodeTrieNode childNode, double threshold) {
    return ((childNode.count / node.count) > threshold) ||
    ((childNode.profileCode.exclusiveTicks / root.count) > threshold);
  }

  void _buildTooltip(DivElement memberList, Map<String, String> items) {
    items.forEach((k, v) {
      var item = new DivElement();
      item.classes.add('memberItem');
      var name = new DivElement();
      name.classes.add('memberName');
      name.classes.add('white');
      name.text = k;
      var value = new DivElement();
      value.classes.add('memberValue');
      value.classes.add('white');
      value.text = v;
      item.children.add(name);
      item.children.add(value);
      memberList.children.add(item);
    });
  }

  void onShow() {
    super.onShow();
    if (children.length == 0) {
      var threshold = profile.displayThreshold;
      for (var childNode in node.children) {
        if (!shouldDisplayChild(childNode, threshold)) {
          continue;
        }
        var row =
        new ProfileCodeTrieNodeTreeRow(profile, root, childNode, tree, this);
        children.add(row);
      }
    }

    var methodCell = tableColumns[0];
    // Enable expansion by clicking anywhere on the method column.
    methodCell.onClick.listen(onClick);

    // Grab the flex-row Div inside the methodCell.
    methodCell = methodCell.children[0];

    // Insert the parent percentage
    var parentPercent = new DivElement();
    parentPercent.text = tipParent;
    methodCell.children.add(parentPercent);

    var gap = new SpanElement();
    gap.style.minWidth = '1em';
    methodCell.children.add(gap);

    var codeRef = new Element.tag('code-ref');
    codeRef.ref = code;
    methodCell.children.add(codeRef);

    var selfCell = tableColumns[1];
    selfCell.style.position = 'relative';
    selfCell.text = tipExclusive;

    var tooltipDiv = new DivElement();
    tooltipDiv.classes.add('tooltip');

    var memberListDiv = new DivElement();
    memberListDiv.classes.add('memberList');
    tooltipDiv.children.add(memberListDiv);
    _buildTooltip(memberListDiv, {
        'Kind' : tipKind,
        'Percent of Parent' : tipParent,
        'Sample Count' : tipTicks,
        'Approximate Execution Time': tipTime,
    });
    selfCell.children.add(tooltipDiv);
  }

  bool hasChildren() {
    return node.children.length > 0;
  }
}

class ProfileFunctionTrieNodeTreeRow extends TableTreeRow {
  final CpuProfile profile;
  @reflectable final FunctionTrieNode root;
  @reflectable final FunctionTrieNode node;
  ProfileFunction get profileFunction => node.profileFunction;
  @reflectable ServiceFunction get function => node.profileFunction.function;
  @reflectable String tipKind = '';
  @reflectable String tipParent = '';
  @reflectable String tipExclusive = '';
  @reflectable String tipTime = '';
  @reflectable String tipTicks = '';

  String tipOptimized = '';

  ProfileFunctionTrieNodeTreeRow(this.profile, this.root, this.node,
                                 TableTree tree,
                                 ProfileFunctionTrieNodeTreeRow parent)
      : super(tree, parent) {
    assert(root != null);
    assert(node != null);
    tipTicks = '${node.count}';
    var seconds = profile.approximateSecondsForCount(node.count);
    tipTime = Utils.formatTimePrecise(seconds);
    if (parent == null) {
      tipParent = Utils.formatPercent(node.count, root.count);
    } else {
      tipParent = Utils.formatPercent(node.count, parent.node.count);
    }
    if (function.kind == FunctionKind.kTag) {
      tipExclusive = Utils.formatPercent(node.count, root.count);
    } else {
      tipExclusive =
          Utils.formatPercent(node.profileFunction.exclusiveTicks, root.count);
    }

    if (function.kind == FunctionKind.kTag) {
      tipKind = 'Tag (category)';
    } else if (function.kind == FunctionKind.kCollected) {
      tipKind = 'Garbage Collected Code';
    } else {
      tipKind = '${function.kind} (Function)';
    }
  }

  bool hasChildren() {
    return node.children.length > 0;
  }

  void _buildTooltip(DivElement memberList, Map<String, String> items) {
    items.forEach((k, v) {
      var item = new DivElement();
      item.classes.add('memberItem');
      var name = new DivElement();
      name.classes.add('memberName');
      name.classes.add('white');
      name.text = k;
      var value = new DivElement();
      value.classes.add('memberValue');
      value.classes.add('white');
      value.text = v;
      item.children.add(name);
      item.children.add(value);
      memberList.children.add(item);
    });
  }

  void onShow() {
    super.onShow();
    if (children.length == 0) {
      for (var childNode in node.children) {
        var row = new ProfileFunctionTrieNodeTreeRow(profile,
                                                     root,
                                                     childNode, tree, this);
        children.add(row);
      }
    }

    var selfCell = tableColumns[1];
    selfCell.style.position = 'relative';
    selfCell.text = tipExclusive;

    var methodCell = tableColumns[0];
    // Enable expansion by clicking anywhere on the method column.
    methodCell.onClick.listen(onClick);

    // Grab the flex-row Div inside the methodCell.
    methodCell = methodCell.children[0];

    // Insert the parent percentage
    var parentPercent = new DivElement();
    parentPercent.text = tipParent;
    methodCell.children.add(parentPercent);

    var gap = new SpanElement();
    gap.style.minWidth = '1em';
    methodCell.children.add(gap);

    var functionAndCodeContainer = new DivElement();
    methodCell.children.add(functionAndCodeContainer);

    var functionRef = new Element.tag('function-ref');
    functionRef.ref = function;
    functionAndCodeContainer.children.add(functionRef);

    var codeRow = new DivElement();
    codeRow.style.paddingTop = '1em';
    functionAndCodeContainer.children.add(codeRow);
    if (!function.kind.isSynthetic()) {

      var totalTicks = node.totalCodesTicks;
      var numCodes = node.codes.length;
      var label = new SpanElement();
      label.text = 'Compiled into:\n';
      codeRow.children.add(label);
      var curlyBlock = new Element.tag('curly-block');
      codeRow.children.add(curlyBlock);
      for (var i = 0; i < numCodes; i++) {
        var codeRowSpan = new DivElement();
        codeRowSpan.style.paddingLeft = '1em';
        curlyBlock.children.add(codeRowSpan);
        var nodeCode = node.codes[i];
        var ticks = nodeCode.ticks;
        var percentage = Utils.formatPercent(ticks, totalTicks);
        var percentageSpan = new SpanElement();
        percentageSpan.text = '($percentage) ';
        codeRowSpan.children.add(percentageSpan);
        var codeRef = new Element.tag('code-ref');
        codeRef.ref = nodeCode.code.code;
        codeRowSpan.children.add(codeRef);
      }
    }

    var tooltipDiv = new DivElement();
    tooltipDiv.classes.add('tooltip');

    var memberListDiv = new DivElement();
    memberListDiv.classes.add('memberList');
    tooltipDiv.children.add(memberListDiv);
    _buildTooltip(memberListDiv, {
        'Kind' : tipKind,
        'Percent of Parent' : tipParent,
        'Sample Count' : tipTicks,
        'Approximate Execution Time': tipTime,
    });
    selfCell.children.add(tooltipDiv);
  }
}

/// Displays a CpuProfile
@CustomTag('cpu-profile')
class CpuProfileElement extends ObservatoryElement {
  static const MICROSECONDS_PER_SECOND = 1000000.0;

  @published Isolate isolate;
  @observable String sampleCount = '';
  @observable String refreshTime = '';
  @observable String sampleRate = '';
  @observable String stackDepth = '';
  @observable String displayCutoff = '';
  @observable String timeSpan = '';

  @observable String tagSelector = 'UserVM';
  @observable String modeSelector = 'Function';

  final CpuProfile profile = new CpuProfile();

  CpuProfileElement.created() : super.created();

  @override
  void attached() {
    super.attached();
  }

  void isolateChanged(oldValue) {
    _getCpuProfile();
  }

  void tagSelectorChanged(oldValue) {
    _getCpuProfile();
  }

  void modeSelectorChanged(oldValue) {
    _updateView();
  }

  void clear(var done) {
    _clearCpuProfile().whenComplete(done);
  }

  Future _clearCpuProfile() {
    profile.clear();
    if (isolate == null) {
      return new Future.value(null);
    }
    return isolate.invokeRpc('clearCpuProfile', { })
        .then((ServiceMap response) {
          _updateView();
        });
  }

  void refresh(var done) {
    _getCpuProfile().whenComplete(done);
  }

  Future _getCpuProfile() {
    profile.clear();
    if (isolate == null) {
      return new Future.value(null);
    }
    return isolate.invokeRpc('getCpuProfile', { 'tags': tagSelector })
        .then((ServiceMap response) {
          profile.load(isolate, response);
          _updateView();
        });
  }

  void _updateView() {
    sampleCount = profile.sampleCount.toString();
    refreshTime = new DateTime.now().toString();
    stackDepth = profile.stackDepth.toString();
    sampleRate = profile.sampleRate.toStringAsFixed(0);
    timeSpan = formatTime(profile.timeSpan);
    displayCutoff = '${(profile.displayThreshold * 100.0).toString()}%';
    if (functionTree != null) {
      functionTree.clear();
    }
    if (codeTree != null) {
      codeTree.clear();
    }
    if (modeSelector == 'Code') {
      _buildCodeTree();
    } else {
      _buildFunctionTree();
    }
  }

  TableTree codeTree;
  TableTree functionTree;

  void _buildFunctionTree() {
    if (functionTree == null) {
      var tableBody = shadowRoot.querySelector('#treeBody');
      assert(tableBody != null);
      functionTree = new TableTree(tableBody, 2);
    }
    var root = profile.functionTrieRoot;
    if (root == null) {
      return;
    }
    try {
      functionTree.initialize(
          new ProfileFunctionTrieNodeTreeRow(profile,
                                             root, root, functionTree, null));
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      Logger.root.warning('_buildFunctionTree', e, stackTrace);
    }
    // Check if we only have one node at the root and expand it.
    if (functionTree.rows.length == 1) {
      functionTree.toggle(functionTree.rows[0]);
    }
  }

  void _buildCodeTree() {
    if (codeTree == null) {
      var tableBody = shadowRoot.querySelector('#treeBody');
      assert(tableBody != null);
      codeTree = new TableTree(tableBody, 2);
    }
    var root = profile.codeTrieRoot;
    if (root == null) {
      return;
    }
    try {
      codeTree.initialize(
          new ProfileCodeTrieNodeTreeRow(profile, root, root, codeTree, null));
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      Logger.root.warning('_buildCodeTree', e, stackTrace);
    }
    // Check if we only have one node at the root and expand it.
    if (codeTree.rows.length == 1) {
      codeTree.toggle(codeTree.rows[0]);
    }
  }
}
