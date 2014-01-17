// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_profile_element;

import 'dart:html';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';
import 'observatory_element.dart';

/// Displays an IsolateProfile
@CustomTag('isolate-profile')
class IsolateProfileElement extends ObservatoryElement {
  IsolateProfileElement.created() : super.created();
  @observable int methodCountSelected = 0;
  final List methodCounts = [10, 20, 50];
  @observable List topInclusiveCodes = toObservable([]);
  @observable List topExclusiveCodes = toObservable([]);

  void enteredView() {
    var isolateId = app.locationManager.currentIsolateId();
    var isolate = app.isolateManager.getIsolate(isolateId);
    if (isolate == null) {
      return;
    }
    _refreshTopMethods(isolate);
  }

  void _startRequest() {
    // TODO(johnmccutchan): Indicate visually.
  }

  void _endRequest() {
    // TODO(johnmccutchan): Indicate visually.
  }

  methodCountSelectedChanged(oldValue) {;
    var isolateId = app.locationManager.currentIsolateId();
    var isolate = app.isolateManager.getIsolate(isolateId);
    if (isolate == null) {
      return;
    }
    _refreshTopMethods(isolate);
  }

  void refreshData(Event e, var detail, Node target) {
    var isolateId = app.locationManager.currentIsolateId();
    var isolate = app.isolateManager.getIsolate(isolateId);
    if (isolate == null) {
      Logger.root.info('No isolate found.');
      return;
    }
    var request = '/$isolateId/profile';
    _startRequest();
    app.requestManager.requestMap(request).then((Map profile) {
      assert(profile['type'] == 'Profile');
      var samples = profile['samples'];
      Logger.root.info('Profile contains ${samples} samples.');
      _loadProfileData(isolate, samples, profile);
      _endRequest();
    }).catchError((e) {
      _endRequest();
    });
  }

  void _loadProfileData(Isolate isolate, int totalSamples, Map response) {
    isolate.profile = new Profile.fromMap(isolate, response);
    _refreshTopMethods(isolate);
  }

  void _refreshTopMethods(Isolate isolate) {
    topExclusiveCodes.clear();
    topInclusiveCodes.clear();
    if ((isolate == null) || (isolate.profile == null)) {
      return;
    }
    var count = methodCounts[methodCountSelected];
    var topExclusive = isolate.profile.topExclusive(count);
    topExclusiveCodes.addAll(topExclusive);
    var topInclusive = isolate.profile.topInclusive(count);
    topInclusiveCodes.addAll(topInclusive);

  }

  String codeTicks(Code code, bool inclusive) {
    if (code == null) {
      return '';
    }
    return inclusive ? '${code.inclusiveTicks}' : '${code.exclusiveTicks}';
  }

  String codePercent(Code code, bool inclusive) {
    if (code == null) {
      return '';
    }
    var isolateId = app.locationManager.currentIsolateId();
    var isolate = app.isolateManager.getIsolate(isolateId);
    if (isolate == null) {
      return '';
    }
    var ticks = inclusive ? code.inclusiveTicks : code.exclusiveTicks;
    var total = ticks / isolate.profile.totalSamples;
    return (total * 100.0).toStringAsFixed(2);
  }

  String codeName(Code code) {
    if ((code == null) || (code.name == null)) {
      return '';
    }
    return code.name;
  }
}
