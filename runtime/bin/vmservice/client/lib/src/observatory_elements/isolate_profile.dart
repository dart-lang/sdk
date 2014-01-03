// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_profile_element;

import 'dart:convert';
import 'dart:html';
import 'package:dprof/model.dart' as dprof;
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
  @observable bool disassemble = false;
  void _startRequest() {
    // TODO(johnmccutchan): Indicate visually.
    print('Request sent.');
  }

  void _endRequest() {
    // TODO(johnmccutchan): Indicate visually.
    print('Request finished.');
  }

  methodCountSelectedChanged(oldValue) {
    print('Refresh top');
    var isolateId = app.locationManager.currentIsolateId();
    var isolate = app.isolateManager.getIsolate(isolateId);
    if (isolate == null) {
      print('No isolate found.');
    }
    _refreshTopMethods(isolate);
  }

  void toggleDisassemble(Event e, var detail, CheckboxInputElement target) {
    disassemble = target.checked;
    print(disassemble);
  }

  void refreshData(Event e, var detail, Node target) {
    var isolateId = app.locationManager.currentIsolateId();
    var isolate = app.isolateManager.getIsolate(isolateId);
    if (isolate == null) {
      print('No isolate found.');
    }
    var request = '/$isolateId/profile';
    _startRequest();
    app.requestManager.request(request).then((response) {
      var profile;
      try {
        profile = JSON.decode(response);
      } catch (e) { print(e); }
      if ((profile is Map) && (profile['type'] == 'Profile')) {
        var codes = profile['codes'];
        var samples = profile['samples'];
        _loadProfileData(isolate, samples, codes);
      }
      _endRequest();
    }).catchError((e) {
      _endRequest();
    });
  }

  void _loadProfileData(Isolate isolate, int totalSamples, List codes) {
    isolate.profiler = new dprof.Isolate(0, 0);
    var loader = new dprof.Loader(isolate.profiler);
    loader.load(totalSamples, codes);
    _refreshTopMethods(isolate);
  }

  void _refreshTopMethods(Isolate isolate) {
    topExclusiveCodes.clear();
    topInclusiveCodes.clear();
    if ((isolate == null) || (isolate.profiler == null)) {
      return;
    }
    var count = methodCounts[methodCountSelected];
    var topExclusive = isolate.profiler.topExclusive(count);
    topExclusiveCodes.addAll(topExclusive);
    var topInclusive = isolate.profiler.topInclusive(count);
    topInclusiveCodes.addAll(topInclusive);

  }

  String codeTicks(dprof.Code code, bool inclusive) {
    if (code == null) {
      return '';
    }
    return inclusive ? '${code.inclusiveTicks}' : '${code.exclusiveTicks}';
  }

  String codePercent(dprof.Code code, bool inclusive) {
    if (code == null) {
      return '';
    }
    var isolateId = app.locationManager.currentIsolateId();
    var isolate = app.isolateManager.getIsolate(isolateId);
    if (isolate == null) {
      return '';
    }
    var ticks = inclusive ? code.inclusiveTicks : code.exclusiveTicks;
    var total = ticks / isolate.profiler.totalSamples;
    return (total * 100.0).toStringAsFixed(2);
  }

  String codeName(dprof.Code code) {
    if ((code == null) || (code.method == null)) {
      return '';
    }
    return code.method.name;
  }

  String instructionTicks(dprof.Instruction instruction) {
    if (instruction == null) {
      return '';
    }
    if (instruction.ticks == 0) {
      return '';
    }
    return '${instruction.ticks}';
  }

  String instructionPercent(dprof.Instruction instruction,
                            dprof.Code code) {
    if ((instruction == null) || (code == null)) {
      return '';
    }
    if (instruction.ticks == 0) {
      return '';
    }
    var ticks = instruction.ticks;
    var total = ticks / code.inclusiveTicks;
    return (total * 100.0).toStringAsFixed(2);
  }

  String instructionDisplay(dprof.Instruction instruction) {
    if (instruction == null) {
      return '';
    }
    return instruction.human;
  }
}
