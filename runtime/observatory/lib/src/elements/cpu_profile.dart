// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library cpu_profile_element;

import 'dart:html';
import 'observatory_element.dart';
import 'package:logging/logging.dart';
import 'package:observatory/service.dart';
import 'package:observatory/app.dart';
import 'package:observatory/elements.dart';
import 'package:polymer/polymer.dart';

class ProfileCodeTrieNodeTreeRow extends TableTreeRow {
  final ServiceMap profile;
  @reflectable final CodeTrieNode root;
  @reflectable final CodeTrieNode node;
  @reflectable Code get code => node.code;

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
    var period = profile['period'];
    var MICROSECONDS_PER_SECOND = 1000000.0;
    var seconds = (period * node.count) / MICROSECONDS_PER_SECOND; // seconds
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
      tipExclusive = Utils.formatPercent(node.code.exclusiveTicks, root.count);
    }
  }

  bool shouldDisplayChild(CodeTrieNode childNode, double threshold) {
    return ((childNode.count / node.count) > threshold) ||
            ((childNode.code.exclusiveTicks / root.count) > threshold);
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
      var threshold = profile['threshold'];
      for (var childNode in node.children) {
        if (!shouldDisplayChild(childNode, threshold)) {
          continue;
        }
        var row =
            new ProfileCodeTrieNodeTreeRow(profile, root, childNode, tree, this);
        children.add(row);
      }
    }
    var row = tr;

    var methodCell = tableColumns[0];
    // Enable expansion by clicking anywhere on the method column.
    methodCell.onClick.listen(onClick);

    // Insert the parent percentage
    var parentPercent = new DivElement();
    parentPercent.style.position = 'relative';
    parentPercent.style.display = 'inline';
    parentPercent.text = tipParent;
    methodCell.children.add(parentPercent);

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

/// Displays a CpuProfile
@CustomTag('cpu-profile')
class CpuProfileElement extends ObservatoryElement {
  CpuProfileElement.created() : super.created();
  @published ServiceMap profile;
  @observable bool hideTagsChecked;
  @observable String sampleCount = '';
  @observable String refreshTime = '';
  @observable String sampleRate = '';
  @observable String sampleDepth = '';
  @observable String displayCutoff = '';
  @observable String timeSpan = '';
  @reflectable double displayThreshold = 0.0002; // 0.02%.

  @observable String tagSelector = 'uv';

  final _id = '#tableTree';
  TableTree tree;

  static const MICROSECONDS_PER_SECOND = 1000000.0;

  void profileChanged(oldValue) {
    if (profile == null) {
      return;
    }
    var totalSamples = profile['samples'];
    var now = new DateTime.now();
    sampleCount = totalSamples.toString();
    refreshTime = now.toString();
    sampleDepth = profile['depth'].toString();
    var period = profile['period'];
    sampleRate = (MICROSECONDS_PER_SECOND / period).toStringAsFixed(0);
    timeSpan = formatTime(profile['timeSpan']);
    displayCutoff = '${(displayThreshold * 100.0).toString()}%';
    profile.isolate.processProfile(profile);
    profile['threshold'] = displayThreshold;
    _update();
  }


  @override
  void attached() {
    super.attached();
    var tableBody = shadowRoot.querySelector('#tableTreeBody');
    assert(tableBody != null);
    tree = new TableTree(tableBody, 2);
    _update();
  }

  void tagSelectorChanged(oldValue) {
    refresh(null);
  }

  void refresh(var done) {
    var request = 'profile?tags=$tagSelector';
    profile.isolate.get(request).then((ServiceMap m) {
      // Assert we got back the a profile.
      assert(m.type == 'Profile');
      profile = m;
    }).whenComplete(done);
  }

  void _update() {
    if (profile == null) {
      return;
    }
    _buildTree();
  }

  void _buildStackTree() {
    var root = profile.isolate.profileTrieRoot;
    if (root == null) {
      return;
    }
    try {
      tree.initialize(
          new ProfileCodeTrieNodeTreeRow(profile, root, root, tree, null));
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
      Logger.root.warning('_buildStackTree', e, stackTrace);
    }
    // Check if we only have one node at the root and expand it.
    if (tree.rows.length == 1) {
      tree.toggle(tree.rows[0]);
    }
    notifyPropertyChange(#tree, null, tree);
  }

  void _buildTree() {
    _buildStackTree();
  }
}
