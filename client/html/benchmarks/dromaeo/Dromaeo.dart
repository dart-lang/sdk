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
    _suiteIframe.contentWindow.dynamic.postMessage('start', '*');
  }

  update(String testName, num mean, num error, double percent) {
    _meanProduct *= mean;
    _nTests++;

    final meanAsString = mean.toStringAsFixed(2);
    final errorAsString = error.toStringAsFixed(2);
    final Element progressDisplay = _element.nextNode.nextNode;
    progressDisplay.innerHTML +=
        '<li><b>${testName}:</b>' +
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
      parent.attributes['class'] = parent.attributes['class'] + ' done';
      final mean = Math.pow(_meanProduct, 1.0 / _nTests).toStringAsFixed(2);
      info = '<span>${mean} runs/s</span>';
    }
    _element.innerHTML =
        '<b>${suiteName}:</b>' +
        '<div class="bar"><div style="width:${percent}%;">${info}</div></div>';
  }

  _init() {
    final div = _createDiv('result-item');
    div.nodes.add(_element);
    final description = _suiteDescription.description;
    final originUrl = _suiteDescription.origin.url;
    final testUrl = 'tests/' + _suiteDescription.file;
    div.innerHTML +=
        '<p>${description}<br/><a href="${originUrl}">Origin</a>' +
        ', <a href="${testUrl}">Source</a>' +
        '<ol class="results"></ol>';
    // Reread the element, as the previous wrapper get disconnected thanks
    // to .innerHTML update above.
    _element = div.nodes.first;

    document.query('#main').nodes.add(div);
  }

  DivElement _createDiv(String clazz) {
    final div = new Element.tag('div');
    div.attributes['class'] = clazz;
    return div;
  }
}

class Dromaeo {
  final Array<SuiteController> _suiteControllers;
  Function _handler;

  Dromaeo()
      : _suiteControllers = new Array<SuiteController>(),
        _handler = _createHandler()
  {
    window.on.message.add(
        (MessageEvent event) {
          try {
            final response = JSON.parse(event.data);
            _handler = _handler(response['command'], response['data']);
          } catch (final e, final stacktrace) {
            window.alert('Exception: ${e}: ${stacktrace}');
          }
        }
    );
  }

  run() {
    // TODO(antonm): create Re-run tests href.
    document.query('#overview').elements.first.innerHTML = 'DOM Core Tests';
    _css(document.query('#tests'), 'display', 'none');
    for (SuiteDescription suite in Suites.SUITE_DESCRIPTIONS) {
      final iframe = new Element.tag('iframe');
      _css(iframe, 'height', '1px');
      _css(iframe, 'width', '1px');
      iframe.src = 'tests/' + suite.file;
      document.body.nodes.add(iframe);

      _suiteControllers.add(new SuiteController(suite, iframe));
    }
  }

  static final double _SECS_PER_TEST = 5.0;

  Function _createHandler() {
    int suitesLoaded = 0;
    int totalTests = 0;
    int currentSuite;
    double totalTimeSecs, estimatedTimeSecs;

    // TODO(jat): Remove void type below. Bug 5269037.
    void _updateTime() {
      final mins = (estimatedTimeSecs / 60).floor().toInt();
      final secs = (estimatedTimeSecs - mins * 60).round().toInt();
      final secsAsString = (secs < 10 ? '0' : '') + secs;
      document.query('#left').innerHTML = '${mins}:${secsAsString}';

      final elapsed = totalTimeSecs - estimatedTimeSecs;
      final percent = (100 * elapsed / totalTimeSecs).toStringAsFixed(2);
      _css(document.query('#timebar'), 'width', '${percent}%');
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
  
  int get _suitesTotal() {
    return _suiteControllers.length;
  }
}

class Main {
  static main() {
    window.on.load.add((Event evt) => new Dromaeo().run());
  }
}
