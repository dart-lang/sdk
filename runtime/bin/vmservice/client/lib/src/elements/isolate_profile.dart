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

  static String formatPercent(num a, num total) {
    var percent = 100.0 * (a / total);
    return '${percent.toStringAsFixed(2)}%';
  }

  ProfileCodeTrieNodeTreeRow(this.profile, this.root, this.node,
                             ProfileCodeTrieNodeTreeRow parent)
      : super(parent) {
    assert(root != null);
    assert(node != null);
    var totalSamples = root.count;
    // When the row is created, fill out the columns.
    if (parent == null) {
      columns.add(formatPercent(node.count, root.count));
    } else {
      columns.add(formatPercent(node.count, parent.node.count));
    }
    columns.add(formatPercent(node.code.exclusiveTicks, totalSamples));
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
}

class ProfileCallerTreeRow extends TableTreeRow {
  final ServiceMap profile;
  @reflectable final Code code;

  static String formatPercent(num a, num total) {
    var percent = 100.0 * (a / total);
    return '${percent.toStringAsFixed(2)}%';
  }

  ProfileCallerTreeRow(this.profile, this.code, ProfileCallerTreeRow parent) :
      super(parent) {
    assert(profile != null);
    assert(code != null);
    var totalSamples = profile['samples'];
    // When the row is created, fill out the columns.
    if (parent == null) {
      var root = profile.isolate.codes.tagRoot();
      var totalAttributedCalls = root.callersCount(code);
      var totalParentCalls = root.sumCallersCount();
      columns.add(formatPercent(totalAttributedCalls, totalParentCalls));
    } else {
      var totalAttributedCalls = parent.code.callersCount(code);
      var totalParentCalls = parent.code.sumCallersCount();
      columns.add(formatPercent(totalAttributedCalls, totalParentCalls));
    }
    columns.add(formatPercent(code.exclusiveTicks, totalSamples));
  }

  bool shouldDisplayChild(CodeCallCount childNode, totalSamples,
                          double threshold) {
    var callerPercent = code.callersCount(childNode.code) /
                        code.sumCallersCount();
    return (callerPercent > threshold) ||
            ((childNode.code.exclusiveTicks / totalSamples) > threshold);
  }

  void onShow() {
    var threshold = profile['threshold'];
    var totalSamples = profile['samples'];
    if (children.length > 0) {
      // Child rows already created.
      return;
    }
    for (var codeCaller in code.callers) {
      if (!shouldDisplayChild(codeCaller, totalSamples, threshold)) {
        continue;
      }
      var row = new ProfileCallerTreeRow(profile, codeCaller.code, this);
      children.add(row);
    }
  }

  void onHide() {
  }
}

/// Displays an IsolateProfile
@CustomTag('isolate-profile')
class IsolateProfileElement extends ObservatoryElement {
  IsolateProfileElement.created() : super.created();
  @published ServiceMap profile;
  @observable bool callGraphChecked;
  @observable bool hideTagsChecked;
  @observable String sampleCount = '';
  @observable String refreshTime = '';
  @observable String sampleRate = '';
  @observable String sampleDepth = '';
  @observable String displayCutoff = '';
  @reflectable double displayThreshold = 0.0001; // 0.5%.

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
    displayCutoff = '${(displayThreshold * 100.0).toString()}%';
    profile.isolate.processProfile(profile);
    profile['threshold'] = displayThreshold;
    _update();
  }

  void callGraphCheckedChanged(oldValue) {
    _update();
  }


  void enteredView() {
    tree = new TableTree();
    _update();
  }

  void hideTagsCheckedChanged(oldValue) {
    refresh(null);
  }

  void refresh(var done) {
    var request = 'profile';
    if ((hideTagsChecked != null) && hideTagsChecked) {
      request += '?tags=hide';
    }
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

  void _buildCallersTree() {
    assert(profile != null);
    var root = profile.isolate.codes.tagRoot();
    if (root == null) {
      Logger.root.warning('No profile root tag.');
    }
    try {
      tree.initialize(new ProfileCallerTreeRow(profile, root, null));
    } catch (e, stackTrace) {
      Logger.root.warning('_buildCallersTree', e, stackTrace);
    }

    notifyPropertyChange(#tree, null, tree);
  }

  void _buildStackTree() {
    var root = profile.isolate.profileTrieRoot;
    if (root == null) {
      Logger.root.warning('No profile trie root.');
    }
    try {
      tree.initialize(
          new ProfileCodeTrieNodeTreeRow(profile, root, root, null));
    } catch (e, stackTrace) {
      Logger.root.warning('_buildStackTree', e, stackTrace);
    }
    notifyPropertyChange(#tree, null, tree);
  }

  void _buildTree() {
    if ((callGraphChecked) != null && callGraphChecked) {
      _buildCallersTree();
    } else {
      _buildStackTree();
    }
  }

  @observable String padding(TableTreeRow row) {
    return 'padding-left: ${row.depth * 16}px;';
  }

  @observable String coloring(TableTreeRow row) {
    const colors = const ['active', 'success', 'warning', 'danger', 'info'];
    var index = row.depth % colors.length;
    return colors[index];
  }

  @observable void toggleExpanded(Event e, var detail, Element target) {
    var row = target.parent;
    if (row is TableRowElement) {
      // Subtract 1 to get 0 based indexing.
      tree.toggle(row.rowIndex - 1);
    }
  }

}
