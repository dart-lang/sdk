// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_profile_element;

import 'dart:html';
import 'observatory_element.dart';
import 'package:logging/logging.dart';
import 'package:observatory/service.dart';
import 'package:observatory/app.dart';
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
                             ProfileCodeTrieNodeTreeRow parent)
      : super(parent) {
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
    columns.add(tipParent);
    columns.add(tipExclusive);
  }

  bool shouldDisplayChild(CodeTrieNode childNode, double threshold) {
    return ((childNode.count / node.count) > threshold) ||
            ((childNode.code.exclusiveTicks / root.count) > threshold);
  }

  void onShow() {
    var threshold = profile['threshold'];
    if (children.length > 0) {
      // Child rows already created.
      return;
    }
    for (var childNode in node.children) {
      if (!shouldDisplayChild(childNode, threshold)) {
        continue;
      }
      var row = new ProfileCodeTrieNodeTreeRow(profile, root, childNode, this);
      children.add(row);
    }
  }

  void onHide() {
  }

  bool hasChildren() {
    return node.children.length > 0;
  }
}

/// Displays an IsolateProfile
@CustomTag('isolate-profile')
class IsolateProfileElement extends ObservatoryElement {
  IsolateProfileElement.created() : super.created();
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
    tree = new TableTree();
    _update();
  }

  void tagSelectorChanged(oldValue) {
    refresh(null);
  }

  void refresh(var done) {
    var request = 'profile?tags=$tagSelector';
    profile.isolate.get(request).then((ServiceMap m) {
      // Assert we got back the a profile.
      assert(m.serviceType == 'Profile');
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
          new ProfileCodeTrieNodeTreeRow(profile, root, root, null));
    } catch (e, stackTrace) {
      Logger.root.warning('_buildStackTree', e, stackTrace);
    }
    // Check if we only have one node at the root and expand it.
    if (tree.rows.length == 1) {
      tree.toggle(0);
    }
    notifyPropertyChange(#tree, null, tree);
  }

  void _buildTree() {
    _buildStackTree();
  }

  @observable String padding(TableTreeRow row) {
    return 'padding-left: ${row.depth * 16}px;';
  }

  @observable String coloring(TableTreeRow row) {
    const colors = const ['rowColor0', 'rowColor1', 'rowColor2', 'rowColor3',
                          'rowColor4', 'rowColor5', 'rowColor6', 'rowColor7',
                          'rowColor8'];
    var index = (row.depth - 1) % colors.length;
    return colors[index];
  }

  @observable void toggleExpanded(Event e, var detail, Element target) {
    // We only want to expand a tree row if the target of the click is
    // the table cell (passed in as target) or the span containing the
    // expander symbol (#expand).
    var eventTarget = e.target;
    if ((eventTarget.id != 'expand') && (e.target != target)) {
      // Target of click was not the expander span or the table cell.
      return;
    }
    var row = target.parent;
    if (row is TableRowElement) {
      // Subtract 1 to get 0 based indexing.
      try {
        tree.toggle(row.rowIndex - 1);
      }  catch (e, stackTrace) {
        Logger.root.warning('toggleExpanded', e, stackTrace);
      }
    }
  }
}
