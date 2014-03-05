// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_profile_element;

import 'dart:html';
import 'isolate_element.dart';
import 'package:logging/logging.dart';
import 'package:observatory/app.dart';
import 'package:polymer/polymer.dart';

class ProfileCallerTreeRow extends TableTreeRow {
  final Isolate isolate;
  @observable final Code code;

  static String formatPercent(num a, num total) {
    var percent = 100.0 * (a / total);
    return '${percent.toStringAsFixed(2)}%';
  }

  ProfileCallerTreeRow(this.isolate, this.code, ProfileCallerTreeRow parent) :
      super(parent) {
    // When the row is created, fill out the columns.
    columns.add(
        formatPercent(code.exclusiveTicks, isolate.profile.totalSamples));
    if (parent == null) {
      // Fill with dummy data.
      columns.add('');
    } else {
      var totalAttributedCalls = parent.code.callersCount(code);
      var totalParentCalls = parent.code.sumCallersCount();
      columns.add(formatPercent(totalAttributedCalls, totalParentCalls));
    }
    columns.add(
        formatPercent(code.inclusiveTicks, isolate.profile.totalSamples));
  }

  void onShow() {
    if (children.length > 0) {
      // Child rows already created.
      return;
    }
    // Create child rows on demand.
    code.callers.forEach((CodeCallCount codeCaller) {
      var row =
          new ProfileCallerTreeRow(isolate, codeCaller.code, this);
      children.add(row);
    });
  }

  void onHide() {
  }
}

/// Displays an IsolateProfile
@CustomTag('isolate-profile')
class IsolateProfileElement extends IsolateElement {
  IsolateProfileElement.created() : super.created();
  @observable int methodCountSelected = 0;
  final List methodCounts = [10, 20, 50];
  @observable List topExclusiveCodes = toObservable([]);
  final _id = '#tableTree';
  TableTree tree;
  @published Map profile;

  void profileChanged(oldValue) {
    if (profile == null) {
      return;
    }
    print('profile changed');
    var samples = profile['samples'];
    _loadProfileData(isolate, samples, profile);
    _refresh(isolate);
  }

  void enteredView() {
    tree = new TableTree(['Method', 'Exclusive', 'Caller', 'Inclusive']);
    _refresh(isolate);
  }

  methodCountSelectedChanged(oldValue) {
    _refresh(isolate);
  }

  void refresh(var done) {
    isolate.getMap('profile').then((Map profile) {
      assert(profile['type'] == 'Profile');
      var samples = profile['samples'];
      Logger.root.info('Profile contains ${samples} samples.');
      _loadProfileData(isolate, samples, profile);
    }).catchError((e, st) {
      Logger.root.warning('Error refreshing profile', e, st);
    }).whenComplete(done);
  }

  void _loadProfileData(Isolate isolate, int totalSamples, Map response) {
    isolate.profile = new Profile.fromMap(isolate, response);
    _refresh(isolate);
  }

  void _refresh(Isolate isolate) {
    _refreshTopMethods(isolate);
    _refreshTree(isolate);
  }

  void _refreshTree(Isolate isolate) {
    var rootChildren = [];
    for (var code in topExclusiveCodes) {
      var row = new ProfileCallerTreeRow(isolate, code, null);
      rootChildren.add(row);
    }
    tree.initialize(rootChildren);
    notifyPropertyChange(#tree, null, tree);
  }


  void _refreshTopMethods(Isolate isolate) {
    topExclusiveCodes.clear();
    if ((isolate == null) || (isolate.profile == null)) {
      return;
    }
    var count = methodCounts[methodCountSelected];
    var topExclusive = isolate.profile.topExclusive(count);
    topExclusiveCodes.addAll(topExclusive);
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
