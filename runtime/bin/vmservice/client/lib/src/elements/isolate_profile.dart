// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_profile_element;

import 'dart:html';
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:observatory/app.dart';
import 'package:polymer/polymer.dart';

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
    columns.add(
        formatPercent(code.exclusiveTicks, totalSamples));
    if (parent == null) {
      // Fill with dummy data.
      columns.add('');
    } else {
      var totalAttributedCalls = parent.code.callersCount(code);
      var totalParentCalls = parent.code.sumCallersCount();
      columns.add(formatPercent(totalAttributedCalls, totalParentCalls));
    }
  }

  void onShow() {
    if (children.length > 0) {
      // Child rows already created.
      return;
    }
    // Create child rows on demand.
    code.callers.forEach((CodeCallCount codeCaller) {
      var row =
          new ProfileCallerTreeRow(profile, codeCaller.code, this);
      children.add(row);
    });
  }

  void onHide() {
  }
}

/// Displays an IsolateProfile
@CustomTag('isolate-profile')
class IsolateProfileElement extends ObservatoryElement {
  IsolateProfileElement.created() : super.created();
  @published ServiceMap profile;
  @reflectable final topExclusiveCodes = new ObservableList<Code>();
  @observable int methodCountSelected = 0;
  @observable String sampleCount = '';
  @observable String refreshTime = '';

  final List methodCounts = [10, 20, 50];
  final _id = '#tableTree';
  TableTree tree;

  void profileChanged(oldValue) {
    if (profile == null) {
      return;
    }
    var totalSamples = profile['samples'];
    var now = new DateTime.now();
    sampleCount = totalSamples.toString();
    refreshTime = now.toString();
    profile.isolate.processProfile(profile);
    _update();
  }

  void enteredView() {
    tree = new TableTree(['Method', 'Exclusive', 'Caller']);
    _update();
  }

  methodCountSelectedChanged(oldValue) {
    _update();
  }

  void refresh(var done) {
    profile.isolate.get('profile').then((ServiceMap m) {
      // Assert we got back the a profile.
      assert(m.serviceType == 'Profile');
      profile = m;
    }).whenComplete(done);
  }

  void _update() {
    if (profile == null) {
      return;
    }
    _refreshTopMethods();
    _rebuildTree();
  }

  void _refreshTopMethods() {
    assert(profile != null);
    var count = methodCounts[methodCountSelected];
    topExclusiveCodes.clear();
    topExclusiveCodes.addAll(profile.isolate.codes.topExclusive(count));
  }

  void _rebuildTree() {
    assert(profile != null);
    var rootChildren = [];
    for (var code in topExclusiveCodes) {
      var row = new ProfileCallerTreeRow(profile, code, null);
      rootChildren.add(row);
    }
    tree.initialize(rootChildren);
    notifyPropertyChange(#tree, null, tree);
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
