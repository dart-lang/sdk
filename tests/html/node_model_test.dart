// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library node_model_test;
import 'dart:async';
import 'dart:html';
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';

var stepDuration;
Future get nextStep {
  return new Future.delayed(stepDuration);
}

class ModelTracker {
  Element element = new DivElement();
  List models = [];

  ModelTracker() {
    element.onModelChanged.listen((node) {
      models.add(node.model);
    });
  }

  void append(ModelTracker other) {
    element.append(other.element);
  }

  get model => element.model;
  void set model(value) {
    element.model = value;
  }

  void clearModel() {
    element.clearModel();
  }

  void remove() {
    element.remove();
  }
}

main() {
  useHtmlConfiguration();

  if (MutationObserver.supported) {
    stepDuration = new Duration();
  } else {
    // Need to step after the tree update notifications, but on IE9 these may
    // get polyfilled to use setTimeout(0). So use a longer timer to try to
    // get a later callback.
    stepDuration = new Duration(milliseconds: 15);
  }

  test('basic top down', () {
    var a = new DivElement();
    var b = new SpanElement();
    var c = new DivElement();
    var d = new DivElement();
    var e = new DivElement();
    var model = {};
    var model2 = {};
    var model3 = {};

    document.body.append(a);
    a.append(b);

    a.model = model;
    expect(a.model, model);
    expect(b.model, model);

    b.append(c);

    return nextStep.then((_) {
      expect(c.model, model);

      d.append(e);
      c.append(d);

      return nextStep;
    }).then((_) {
      expect(e.model, model);

      b.remove();
      return nextStep;
    }).then((_) {
      expect(b.model, isNull);
      expect(e.model, isNull);

      return nextStep;
    }).then((_) {
      a.append(b);
      a.model = model2;

      return nextStep;
    }).then((_) {
      expect(e.model, model2);

      c.model = model3;
      expect(c.model, model3);
      expect(b.model, model2);
      expect(e.model, model3);

      return nextStep;
    }).then((_) {
      d.remove();
      c.append(d);

      return nextStep;
    }).then((_) {
      expect(d.model, model3);

      c.clearModel();
      expect(d.model, model2);

      a.remove();
      return nextStep;
    });
  });

  test('changes', () {
    var a = new ModelTracker();
    var b = new ModelTracker();
    var c = new ModelTracker();
    var d = new ModelTracker();

    var model = {};
    var cModel = {};

    document.body.append(a.element);

    a.append(b);

    return nextStep.then((_) {
      expect(a.models, []);
      expect(b.models.length, 0);

      a.model = model;

      expect(a.models, [model]);
      expect(b.models, [model]);

      b.append(c);
      return nextStep;
    }).then((_) {
      expect(c.models, [model]);

      c.append(d);
      return nextStep;
    }).then((_) {
      c.model = cModel;
      expect(b.models, [model]);
      expect(c.models, [model, cModel]);
      expect(d.models, [model, cModel]);

      c.clearModel();
      expect(c.models, [model, cModel, model]);
      expect(d.models, [model, cModel, model]);

      a.remove();
      return nextStep;
    });
  });

  test('bottom up', () {
    var a = new ModelTracker();
    var b = new ModelTracker();
    var c = new ModelTracker();
    var d = new ModelTracker();

    var aModel = {};
    var cModel = {};

    c.append(d);
    c.model = cModel;
    b.append(c);
    a.append(b);
    a.model = aModel;
    document.body.append(a.element);

    return nextStep.then((_) {
      expect(a.models, [aModel]);
      expect(b.models, [aModel]);
      expect(c.models, [cModel]);
      expect(d.models, [cModel]);

      a.remove();
      return nextStep;
    });
  });
}
