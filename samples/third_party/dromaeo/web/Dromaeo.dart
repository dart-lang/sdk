library dromaeo_test;

import 'dart:html';
import 'dart:async';
import "dart:convert";
import 'dart:math' as Math;
import 'dart:js' as js;
import 'Suites.dart';

main() {
  new Dromaeo().run();
}

class SuiteController {
  final SuiteDescription _suiteDescription;
  final IFrameElement _suiteIframe;

  DivElement _element;
  double _meanProduct;
  int _nTests;

  SuiteController(this._suiteDescription, this._suiteIframe)
      : _meanProduct = 1.0,
        _nTests = 0 {
    _make();
    _init();
  }

  start() {
    _suiteIframe.contentWindow.postMessage('start', '*');
  }

  update(String testName, num mean, num error, double percent) {
    _meanProduct *= mean;
    _nTests++;

    final meanAsString = mean.toStringAsFixed(2);
    final errorAsString = error.toStringAsFixed(2);
    final Element progressDisplay = _element.nextNode.nextNode;
    progressDisplay.innerHtml =
        '${progressDisplay.innerHtml}<li><b>${testName}:</b>'
        '${meanAsString}<small> runs/s &#177;${errorAsString}%<small></li>';
    _updateTestPos(percent);
  }

  _make() {
    _element = _createDiv('test');
    // TODO(antonm): add an onclick functionality.
    _updateTestPos();
  }

  _updateTestPos([double percent = 1.0]) {
    String suiteName = _suiteDescription.name;
    final done = percent >= 100.0;
    String info = '';
    if (done) {
      final parent = _element.parent;
      parent.attributes['class'] = '${parent.attributes["class"]} done';
      final mean = Math.pow(_meanProduct, 1.0 / _nTests).toStringAsFixed(2);
      info = '<span>${mean} runs/s</span>';
    }
    _element.innerHtml =
        '<b>${suiteName}:</b>'
        '<div class="bar"><div style="width:${percent}%;">${info}</div></div>';
  }

  _init() {
    final div = _createDiv('result-item');
    div.nodes.add(_element);
    final description = _suiteDescription.description;
    final originUrl = _suiteDescription.origin.url;
    final testUrl = '${_suiteDescription.file}';
    div.innerHtml =
        '${div.innerHtml}<p>${description}<br/><a href="${originUrl}">Origin</a'
        '>, <a href="${testUrl}">Source</a>'
        '<ol class="results"></ol>';
    // Reread the element, as the previous wrapper get disconnected thanks
    // to .innerHtml update above.
    _element = div.nodes[0];

    document.querySelector('#main').nodes.add(div);
  }

  DivElement _createDiv(String clazz) {
    final div = new DivElement();
    div.attributes['class'] = clazz;
    return div;
  }
}

class Dromaeo {
  final List<SuiteController> _suiteControllers;
  Function _handler;

  Dromaeo()
      : _suiteControllers = new List<SuiteController>()
  {
    _handler = _createHandler();
    window.onMessage.listen(
        (MessageEvent event) {
          try {
            final response = JSON.decode(event.data);
            _handler = _handler(response['command'], response['data']);
          } catch (e, stacktrace) {
            if (!(e is FormatException &&
                (event.data.toString().startsWith('unittest') ||
                event.data.toString().startsWith('dart')))) {
              // Hack because unittest also uses post messages to communicate.
              // So the fact that the event.data is not proper json is not
              // always an error.
              print('Exception: ${e}: ${stacktrace}');
              print(event.data);
            }
          }
        });
  }

  run() {
    // TODO(vsm): Initial page should not run.  For now, run all
    // tests by default.
    var tags = window.location.search;
    if (tags.length > 1) {
      tags = tags.substring(1);
    } else if (window.navigator.userAgent.contains('(Dart)')) {
      // TODO(vsm): Update when we change Dart VM detection.
      tags = 'js|dart&html';
    } else {
      tags = 'js|dart2js&html';
    }

    // TODO(antonm): create Re-run tests href.
    final Element suiteNameElement = _byId('overview').nodes[0];
    final category = Suites.getCategory(tags);
    if (category != null) {
      suiteNameElement.innerHtml = category;
    }
    _css(_byId('tests'), 'display', 'none');
    for (SuiteDescription suite in Suites.getSuites(tags)) {
      final iframe = new IFrameElement();
      _css(iframe, 'height', '1px');
      _css(iframe, 'width', '1px');
      iframe.src = '${suite.file}';
      document.body.nodes.add(iframe);

      _suiteControllers.add(new SuiteController(suite, iframe));
    }
  }

  static const double _SECS_PER_TEST = 5.0;

  Function _createHandler() {
    int suitesLoaded = 0;
    int totalTests = 0;
    int currentSuite;
    double totalTimeSecs, estimatedTimeSecs;

    // TODO(jat): Remove void type below. Bug 5269037.
    void _updateTime() {
      final mins = (estimatedTimeSecs / 60).floor();
      final secs = (estimatedTimeSecs - mins * 60).round();
      final secsAsString = '${(secs < 10 ? "0" : "")}$secs';
      _byId('left').innerHtml = '${mins}:${secsAsString}';

      final elapsed = totalTimeSecs - estimatedTimeSecs;
      final percent = (100 * elapsed / totalTimeSecs).toStringAsFixed(2);
      _css(_byId('timebar'), 'width', '${percent}%');
    }

    Function loading, running, done;

    loading = (String command, var data) {
      assert(command == 'inited');
      suitesLoaded++;
      totalTests += data['nTests'];
      if (suitesLoaded == _suitesTotal) {
        totalTimeSecs = estimatedTimeSecs = _SECS_PER_TEST * totalTests;
        _updateTime();
        currentSuite = 0;
        _suiteControllers[currentSuite].start();
        return running;
      }

      return loading;
    };

    running = (String command, var data) {
      switch (command) {
        case 'result':
          final testName = data['testName'];
          final mean = data['mean'];
          final error = data['error'];
          final percent = data['percent'];
          _suiteControllers[currentSuite].update(testName, mean, error, percent);
          estimatedTimeSecs -= _SECS_PER_TEST;
          _updateTime();
          return running;

        case 'over':
          currentSuite++;
          if (currentSuite < _suitesTotal) {
            _suiteControllers[currentSuite].start();
            return running;
          }
          document.body.attributes['class'] = 'alldone';

          var report = js.context['reportPerformanceTestDone'];
          if (report != null) {
            report.apply([]);
          } else {
            // This is not running as a performance test. Continue as normal.
            window.console.log('Warning: failed to call '
                'reportPerformanceTestDone. If this is a performance test, '
                'please include '
                'packages/browser_controller/perf_test_controller.js in your '
                'html file.');
          }
          return done;

        default:
          throw 'Unknown command ${command} [${data}]';
      }
    };

    done = (String command, var data) {
    };

    return loading;
  }

  _css(Element element, String property, String value) {
    // TODO(antonm): remove the last argument when CallWithDefaultValue
    // is implemented.
    element.style.setProperty(property, value, '');
  }

  Element _byId(String id) {
    return document.querySelector('#$id');
  }

  int get _suitesTotal {
    return _suiteControllers.length;
  }
}
