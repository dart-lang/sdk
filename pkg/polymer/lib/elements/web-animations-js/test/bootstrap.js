/**
 * Copyright 2013 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
'use strict';

(function() {

var log_element = document.createElement('pre');
log_element.id = 'debug';

var log_element_parent = setInterval(function() {
  if (log_element.parentNode == null && document.body != null) {
     document.body.appendChild(log_element);
     clearInterval(log_element_parent);
  }
}, 100);

function log() {

  var output = [];
  for (var i = 0; i < arguments.length; i++) {
     if (typeof arguments[i] === "function") {
       arguments[i] = '' + arguments[i];
     }
     if (typeof arguments[i] === "string") {
       var bits = arguments[i].replace(/\s*$/, '').split('\n');
       if (bits.length > 5) {
         bits.splice(3, bits.length-5, '...');
       }
       output.push(bits.join('\n'));
     } else if (typeof arguments[i] === "object" && typeof arguments[i].name === "string") {
       output.push('"'+arguments[i].name+'"');
     } else {
       output.push(JSON.stringify(arguments[i], undefined, 2));
     }
     output.push(' ');
  }
  log_element.appendChild(document.createTextNode(output.join('') + '\n'));
}

var thisScript = document.querySelector("script[src$='bootstrap.js']");
var coverageMode = Boolean(parent.window.__coverage__) || /coverage/.test(window.location.hash);

// Inherit these properties from the parent test-runner if any.
window.__resources__ = parent.window.__resources__ || {original: {}};
window.__coverage__ = parent.window.__coverage__;

function getSync(src) {
  var xhr = new XMLHttpRequest();
  xhr.open('GET', src, false);
  xhr.send();
  if (xhr.responseCode > 400) {
    console.error('Error loading ' + src);
    return '';
  }
  return xhr.responseText;
}

function loadScript(src, options) {
  // Add changing parameter to prevent script caching.
  options = options || {coverage: true};
  if (window.__resources__[src]) {
    document.write('<script type="text/javascript">eval(window.__resources__["'+src+'"]);</script>');
  } else if (coverageMode && options.coverage) {
    instrument(src);
    loadScript(src);
  } else {
    if (!inExploreMode()) {
      src += '?' + getCacheBuster();
    }
    document.write('<script type="text/javascript" src="'+ src + '"></script>');
  }
}

function loadCSS(src) {
  document.write('<link rel="stylesheet" type="text/css" href="' + src + '">');
}

function forEach(array, callback, thisObj) {
  for (var i=0; i < array.length; i++) {
    if (array.hasOwnProperty(i)) {
      callback.call(thisObj, array[i], i, array);
    }
  }
}

function hasFlag(flag) {
  return thisScript && thisScript.getAttribute(flag) !== null;
}

function testType() {
  var p = location.pathname;
  p = p.replace(/^disabled-/, '');

  var match = /(auto|impl|manual|unit)-test[^\\\/]*$/.exec(p);
  return match ? match[1]: 'unknown';
}

function inExploreMode() {
  return '#explore' == window.location.hash || window.location.hash.length == 0;
}

/**
 * Get a value for busting the cache. If we got given a cache buster, pass it
 * along, otherwise generate a new one.
 */
var cacheBusterValue = '' + window.Date.now();
function getCacheBuster() {
  if (window.location.search.length > 0)
    cacheBusterValue = window.location.search.substr(1, window.location.search.length);
  return cacheBusterValue;
}

var instrumentationDepsLoaded = false;
/**
 * Instrument the source at {@code location} and store it in
 * {@code window.__resources__[name]}.
 */
function instrument(src) {
  if (__resources__[src]) {
    return;
  }
  if (!instrumentationDepsLoaded) {
    instrumentationDepsLoaded = true;
    (function() {
      eval(getSync('../coverage/esprima/esprima.js'));
      eval(getSync('../coverage/escodegen/escodegen.browser.js'));
      eval(getSync('../coverage/istanbul/lib/instrumenter.js'));
    }).call(window);
  }
  var js = getSync(src);
  window.__resources__.original[src] = js;
  var inst = window.__resources__[src] = new Instrumenter().instrumentSync(js, src);
}


var svg_properties = {
  cx: 1,
  width: 1,
  x: 1,
  y: 1
};

var is_svg_attrib = function(property, target) {
  return target.namespaceURI == 'http://www.w3.org/2000/svg' &&
      property in svg_properties;
};

var svg_namespace_uri = 'http://www.w3.org/2000/svg';

window.test_features = (function() {
  var style = document.createElement('style');
  style.textContent = '' +
     'dummyRuleForTesting {' +
     'width: calc(0px);' +
     'width: -webkit-calc(0px); }';
  document.head.appendChild(style);
  var transformCandidates = [
    'transform',
    'webkitTransform',
    'msTransform'
  ];
  var transformProperty = transformCandidates.filter(function(property) {
    return property in style.sheet.cssRules[0].style;
  })[0];
  var calcFunction = style.sheet.cssRules[0].style.width.split('(')[0];
  document.head.removeChild(style);
  return {
    transformProperty: transformProperty,
    calcFunction: calcFunction
  };
})();

/**
 * Figure out a useful name for an element.
 *
 * @param {Element} element Element to get the name for.
 *
 * @private
 */
function _element_name(element) {
  if (element.id) {
    return element.tagName.toLowerCase() + '#' + element.id;
  } else {
    return 'An anonymous ' + element.tagName.toLowerCase();
  }
}

/**
 * Get the style for a given element.
 *
 * @param {Array.<Object.<string, string>>|Object.<string, string>} style
 *   Either;
 *    * A list of dictionaries, each node returned is checked against the
 *    associated dictionary, or
 *    * A single dictionary, each node returned is checked against the
 *    given dictionary.
 *   Each dictionary should be of the form {style_name: style_value}.
 *
 * @private
 */
function _assert_style_get(style, i) {
  if (typeof style[i] === 'undefined') {
    return style;
  } else {
    return style[i];
  }
}

/**
 * Extract all the informative parts of a string. Ignores spacing, punctuation
 * and other random extra characters.
 */
function _extract_important(input) {
  var re = /([-+]?[0-9]+\.?[0-9]*(?:[eE][-+]?[0-9]+)?)|[A-Za-z%]+/g;

  var match;
  var result = [];
  while (match = re.exec(input)) {
    var value = match[0];
    if (typeof match[1] != "undefined") {
       value = Number(match[1]);
    }
    result.push(value);
  }
  return result;
}
window.assert_styles_extract_important = _extract_important;

function AssertionError(message) {
  this.message = message;
}
window.assert_styles_assertion_error = AssertionError;

/**
 * Asserts that a string is in the array of expected only comparing the
 * important parts. Ignores spacing, punctuation and other random extra
 * characters.
 */
function _assert_important_in_array(actual, expected, message) {
  var actual_array = _extract_important(actual);

  var expected_array_array = [];
  for (var i = 0; i < expected.length; i++) {
    expected_array_array.push(_extract_important(expected[i]));
  }

  var errors = [];
  for (var i = 0; i < expected_array_array.length; i++) {
    var expected_array = expected_array_array[i];

    var element_errors = [];
    if (actual_array.length != expected_array.length) {
      element_errors.push('Number of elements don\'t match');
    }

    for (var j = 0; j < expected_array.length; j++) {
      var actual = actual_array[j];
      var expected = expected_array[j];

      try {
        assert_equals(typeof actual, typeof expected);

        if (typeof actual === 'number') {
          if (Math.abs(actual) < 1e-10) {
            actual = 0;
          }
          actual = '' + actual.toPrecision(4);
        }
        if (typeof expected === 'number') {
          if (Math.abs(expected) < 1e-10) {
            expected = 0;
          }
          expected = '' + expected.toPrecision(4);
        }

        assert_equals(actual, expected);
      } catch (e) {
        element_errors.push(
            'Element ' + j + ' - ' + e.message);
      }
    }

    if (element_errors.length == 0) {
      return;
    } else {
      errors.push(
          '  Expectation ' + JSON.stringify(expected_array) + ' did not match\n' +
          '   ' + element_errors.join('\n   '));
    }
  }
  if (expected_array_array.length > 1)
    errors.unshift('  ' + expected_array_array.length + ' possible expectations');

  errors.unshift('  Actual - ' + JSON.stringify(actual_array));
  if (typeof message !== 'undefined') {
    errors.unshift(message);
  }
  throw new AssertionError(errors.join('\n'));
}
window.assert_styles_assert_important_in_array = _assert_important_in_array;

/**
 * asserts that actual has the same styles as the dictionary given by
 * expected.
 *
 * @param {Element} object DOM node to check the styles on
 * @param {Object.<string, string>} styles Dictionary of {style_name: style_value} to check
 *   on the object.
 * @param {String} description Human readable description of what you are
 *   trying to check.
 *
 * @private
 */
function _assert_style_element(object, style, description) {
  if (typeof message == 'undefined')
    description = '';

  // Create an element of the same type as testing so the style can be applied
  // from the test. This is so the css property (not the -webkit-does-something
  // tag) can be read.
  var reference_element = (object.namespaceURI == svg_namespace_uri) ?
      document.createElementNS(svg_namespace_uri, object.nodeName) :
      document.createElement(object.nodeName);
  var computedObjectStyle = getComputedStyle(object, null);
  for (var i = 0; i < computedObjectStyle.length; i++) {
    var property = computedObjectStyle[i];
    reference_element.style.setProperty(property,
        computedObjectStyle.getPropertyValue(property));
  }
  reference_element.style.position = 'absolute';
  if (object.parentNode) {
    object.parentNode.appendChild(reference_element);
  }

  try {
    // Apply the style
    for (var prop_name in style) {
      // If the passed in value is an element then grab its current style for
      // that property
      if (style[prop_name] instanceof HTMLElement ||
          style[prop_name] instanceof SVGElement) {

        var prop_value = getComputedStyle(style[prop_name], null)[prop_name];
      } else {
        var prop_value = style[prop_name];
      }

      prop_value = '' + prop_value;

      if (prop_name == 'transform') {
        var output_prop_name = test_features.transformProperty;
      } else {
        var output_prop_name = prop_name;
      }

      var is_svg = is_svg_attrib(prop_name, object);
      if (is_svg) {
        reference_element.setAttribute(prop_name, prop_value);

        var current_style = object.attributes;
        var target_style = reference_element.attributes;
      } else {
        reference_element.style[output_prop_name] = prop_value;

        var current_style = computedObjectStyle;
        var target_style = getComputedStyle(reference_element, null);

        _assert_important_in_array(
            prop_value, [reference_element.style[output_prop_name], target_style[output_prop_name]],
            'Tried to set the reference element\'s '+ output_prop_name +
            ' to ' + JSON.stringify(prop_value) +
            ' but neither the style' +
            ' ' + JSON.stringify(reference_element.style[output_prop_name]) +
            ' nor computedStyle ' + JSON.stringify(target) +
            ' ended up matching requested value.');
      }

      if (prop_name == 'ctm') {
        var ctm = object.getCTM();
        var curr = '{' + ctm.a + ', ' + 
          ctm.b + ', ' + ctm.c + ', ' + ctm.d + ', ' + 
          ctm.e + ', ' + ctm.f + '}';

        var target = prop_value;

      } else if (is_svg) {
        var target = target_style[prop_name].value;
        var curr = current_style[prop_name].value;
      } else {
        var target = target_style[output_prop_name];
        var curr = current_style[output_prop_name];
      }

      var description_extra = '\n Property ' + prop_name;
      if (prop_name != output_prop_name)
          description_extra += '(actually ' + output_prop_name + ')';

      _assert_important_in_array(curr, [target], description + description_extra);
    }
  } finally {
    if (reference_element.parentNode) {
      reference_element.parentNode.removeChild(reference_element);
    }
  }
}

/**
 * asserts that elements in the list have given styles.
 *
 * @param {Array.<Element>} objects List of DOM nodes to check the styles on
 * @param {Array.<Object.<string, string>>|Object.<string, string>} style
 *   See _assert_style_get for information.
 * @param {String} description Human readable description of what you are
 *   trying to check.
 *
 * @private
 */
function _assert_style_element_list(objects, style, description) {
  var error = '';
  forEach(objects, function(object, i) {
    try {
      _assert_style_element(
          object, _assert_style_get(style, i),
          description + ' ' + _element_name(object)
          );
    } catch (e) {
      if (error) {
        error += '; ';
      }
      error += 'Element ' + _element_name(object) + ' at index ' + i + ' failed ' + e.message + '\n';
    }
  });
  if (error) {
    throw error;
  }
}

/**
 * asserts that elements returned from a query selector have a list of styles.
 *
 * @param {string} qs A query selector to use to get the DOM nodes.
 * @param {Array.<Object.<string, string>>|Object.<string, string>} style
 *   See _assert_style_get for information.
 * @param {String} description Human readable description of what you are
 *   trying to check.
 *
 * @private
 */
function _assert_style_queryselector(qs, style, description) {
  var objects = document.querySelectorAll(qs);
  assert_true(objects.length > 0, description +
      ' is invalid, no elements match query selector: ' + qs);
  _assert_style_element_list(objects, style, description);
}

/**
 * asserts that elements returned from a query selector have a list of styles.
 *
 * Assert the element with id #hello is 100px wide;
 *   assert_styles(document.getElementById('hello'), {'width': '100px'})
 *   assert_styles('#hello'), {'width': '100px'})
 *
 * Assert all divs are 100px wide;
 *   assert_styles(document.getElementsByTagName('div'), {'width': '100px'})
 *   assert_styles('div', {'width': '100px'})
 *
 * Assert all objects with class 'red' are 100px wide;
 *   assert_styles(document.getElementsByClassName('red'), {'width': '100px'})
 *   assert_styles('.red', {'width': '100px'})
 *
 * Assert first div is 100px wide, second div is 200px wide;
 *   assert_styles(document.getElementsByTagName('div'),
 *           [{'width': '100px'}, {'width': '200px'}])
 *   assert_styles('div',
 *           [{'width': '100px'}, {'width': '200px'}])
 *
 * @param {string|Element|Array.<Element>} objects Either;
 *    * A query selector to use to get DOM nodes,
 *    * A DOM node.
 *    * A list of DOM nodes.
 * @param {Array.<Object.<string, string>>|Object.<string, string>} style
 *   See _assert_style_get for information.
 */
function assert_styles(objects, style, description) {
  switch (typeof objects) {
    case 'string':
      _assert_style_queryselector(objects, style, description);
      break;

    case 'object':
      if (objects instanceof Array || objects instanceof NodeList) {
        _assert_style_element_list(objects, style, description);
      } else if (objects instanceof Element) {
        _assert_style_element(objects, style, description);
      } else {
        throw new Error('Expected Array, NodeList or Element but got ' + objects);
      }
      break;
  }
}
window.assert_styles = assert_styles;

/**
 * Schedule something to be called at a given time.
 *
 * @constructor
 * @param {number} millis Microseconds after start at which the callback should
 *   be called.
 * @param {bool} autostart Auto something...
 */
function TestTimelineGroup(millis) {
  this.millis = millis;

  /**
   * @type {bool}
   */
  this.autorun_ = false;

  /**
   * @type {!Array.<function(): ?Object>}
   */
  this.startCallbacks = null;

  /**
   * Callbacks which are added after the timeline has started. We clear them
   * when going backwards.
   *
   * @type {?Array.<function(): ?Object>}
   */
  this.lateCallbacks = null;

  /**
   * @type {Element}
   */
  this.marker = document.createElement('img');
  /**
   * @type {Element}
   */
  this.info = document.createElement('div');

  this.setup_();
}

TestTimelineGroup.prototype.setup_ = function() {
  this.endTime_ = 0;
  this.startCallbacks = new Array();
  this.lateCallbacks = null;
  this.marker.innerHTML = '';
  this.info.innerHTML = '';
};

/**
 * Add a new callback to the event group
 *
 * @param {function(): ?Object} callback Callback given the currentTime of
 *   callback.
 */
TestTimelineGroup.prototype.add = function(callback) {
  if (this.lateCallbacks === null) {
    this.startCallbacks.unshift(callback);
  } else {
    this.lateCallbacks.unshift(callback);
  }

  // Trim out extra 'function() { ... }'
  var callbackString = callback.name;
  // FIXME: This should probably unindent too....
  this.info.innerHTML += '<div>' + callbackString + '</div>';
};

/**
 * Reset this event group to the state before start was called.
 */
TestTimelineGroup.prototype.reset = function() {
  this.lateCallbacks = null;

  var callbacks = this.startCallbacks.slice(0);
  this.setup_();
  while (callbacks.length > 0) {
    var callback = callbacks.shift();
    this.add(callback);
  }
};

/**
 * Tell the event group that the timeline has started and that any callbacks
 * added from now are dynamically generated and hence should be cleared when a
 * reset is called.
 */
TestTimelineGroup.prototype.start = function() {
  this.lateCallbacks = new Array();
};

/**
 * Call all the callbacks in the EventGroup.
 */
TestTimelineGroup.prototype.call = function() {
  var callbacks = (this.startCallbacks.slice(0)).concat(this.lateCallbacks);
  var statuses = this.info.children;

  var overallResult = true;
  while (callbacks.length > 0) {
    var callback = callbacks.pop();

    var status_ = statuses[statuses.length - callbacks.length - 1];

    if (typeof callback == 'function') {
      log('TestTimelineGroup', 'calling function', callback);
      try {
        callback();
      } catch (e) {
        // On IE the only way to get the real stack is to do this
        window.onerror(e.message, e.fileName, e.lineNumber, e);
        // On other browsers we want to throw the error later
        setTimeout(function () { throw e; }, 0);
      }
    } else {
      log('TestTimelineGroup', 'calling test', callback);
      var result = callback.step(callback.f);
      callback.done();
    }

    if (result === undefined || result == null) {
      overallResult = overallResult && true;

      status_.style.color = 'green';
    } else {
      overallResult = overallResult && false;
      status_.style.color = 'red';
      status_.innerHTML += '<div>' + result.toString() + '</div>';
    }
  }
  if (overallResult) {
    this.marker.src = '../img/success.png';
  } else {
    this.marker.src = '../img/error.png';
  }
}

/**
 * Draw the EventGroup's marker at the correct position on the timeline.
 *
 * FIXME(mithro): This mixes display and control :(
 *
 * @param {number} endTime The endtime of the timeline in millis. Used to
 *   display the marker at the right place on the timeline.
 */
TestTimelineGroup.prototype.draw = function(container, endTime) {
  this.marker.title = this.millis + 'ms';
  this.marker.className = 'marker';
  this.marker.src = '../img/unknown.png';

  var mleft = 'calc(100% - 10px)';
  if (endTime != 0) {
    mleft = 'calc(' + (this.millis / endTime) * 100.0 + '%' + ' - 10px)';
  }
  this.marker.style.left = mleft;

  container.appendChild(this.marker);

  this.info.className = 'info';
  container.appendChild(this.info);

  // Display details about the events at this time period when hovering over
  // the marker.
  this.marker.onmouseover = function() {
    this.style.display = 'block';
  }.bind(this.info);

  this.marker.onmouseout = function() {
    this.style.display = 'none';
  }.bind(this.info);


  var offset = Math.ceil(this.info.offsetWidth / 2);
  var ileft = 'calc(100% - ' + offset + 'px)';
  if (endTime != 0) {
    ileft = 'calc(' + (this.millis / endTime) * 100.0 + '%' + ' - ' + offset +
        'px)';
  }
  this.info.style.left = ileft;

  this.info.style.display = 'none';
};



/**
 * Moves the testharness_timeline in "real time".
 * (IE 1 test second takes 1 real second).
 *
 * @constructor
 */
function RealtimeRunner(timeline) {
  this.timeline = timeline;

  // Capture the real requestAnimationFrame so we can run in 'real time' mode
  // rather than as fast as possible.
  var nativeRequestAnimationFrame = window.requestAnimationFrame || window.mozRequestAnimationFrame;
  this.boundRequestAnimationFrame = function(f) {
    nativeRequestAnimationFrame(f.bind(this))
  };
  this.now = window.Date.now;

  this.zeroTime = null;       // Time the page loaded
  this.pauseStartTime = null; // Time at which we paused raf
  this.timeDrift = 0;         // Amount we have been stopped for
}

/**
 * Callback called from nativeRequestAnimationFrame.
 *
 * @private
 * @param {number} timestamp The current time for the animation frame
 *   (in millis).
 */
RealtimeRunner.prototype.animationFrame_ = function(timestamp) {
  if (this.zeroTime === null) {
    this.zeroTime = timestamp;
  }

  // Are we paused? Stop calling requestAnimationFrame.
  if (this.pauseStartTime != null) {
    return;
  }

  var virtualAnimationTime = timestamp - this.zeroTime - this.timeDrift;
  var endTime = this.timeline.endTime_;
  // If we have no events paste t=0, endTime is going to be zero. Instead
  // make the test run for 2 minutes.
  if (endTime == 0) {
    endTime = 120e3;
  }

  // Do we still have time to go?
  if (virtualAnimationTime < endTime) {
    try {
      this.timeline.setTime(virtualAnimationTime);
    } finally {
      this.boundRequestAnimationFrame(this.animationFrame_);
    }

  } else {
    // Have we gone past endTime_? Force the harness to its endTime_.

    this.timeline.setTime(endTime);
    // Don't continue to raf
  }
};

RealtimeRunner.prototype.start = function() {
  if (this.pauseStartTime != null) {
    this.timeDrift += (this.now() - this.pauseStartTime);
    this.pauseStartTime = null;
  }
  this.boundRequestAnimationFrame(this.animationFrame_);
};

RealtimeRunner.prototype.pause = function() {
  if (this.pauseStartTime != null) {
    return;
  }
  this.pauseStartTime = this.now();
};


/**
 * Class for storing events that happen during at given times (such as
 * animation checks, or setTimeout).
 *
 * @constructor
 */
function TestTimeline(everyFrame) {
  log('TestTimeline', 'constructor', everyFrame);
  /**
   * Stores the events which are upcoming.
   *
   * @type Object.<number, TestTimelineGroup>
   * @private
   */
  this.timeline_ = new Array();

  this.everyFrame = everyFrame;
  this.frameMillis = 1000.0 / 60; //60fps 

  this.currentTime_ = -this.frameMillis;

  // Schedule an event at t=0, needed temporarily.
  this.schedule(function() {}, 0);

  this.reset();

  this.runner_ = new RealtimeRunner(this);
}

/**
 * Create the GUI controller for the timeline.
 * @param {Element} body DOM element to add the GUI too, normally the <body>
 *   element.
 */
TestTimeline.prototype.createGUI = function(body) {
  // HTML needed to create the timeline UI
  this.div = document.createElement('div');
  this.div.id = 'timeline';

  this.timelinebar = document.createElement('div');
  this.timelinebar.className = 'bar';

  this.timelineprogress = document.createElement('div');
  this.timelineprogress.className = 'progress';

  this.timelinebar.appendChild(this.timelineprogress);
  this.div.appendChild(this.timelinebar);

  this.next = document.createElement('button');
  this.next.innerText = '>';
  this.next.id = 'next';
  this.next.onclick = this.toNextEvent.bind(this);
  this.div.appendChild(this.next);

  this.prev = document.createElement('button');
  this.prev.innerText = '<';
  this.prev.id = 'prev';
  this.prev.onclick = this.toPrevEvent.bind(this);
  this.div.appendChild(this.prev);

  this.control = document.createElement('button');
  this.control.innerText = 'Pause';
  this.control.id = 'control';
  this.control.onclick = function() {
    if (this.control.innerText == 'Go!') {
      this.runner_.start();
      this.control.innerText = 'Pause';
    } else {
      this.runner_.pause();
      this.control.innerText = 'Go!';
    }
  }.bind(this);
  this.div.appendChild(this.control);

  body.appendChild(this.div);
}

/**
 * Update GUI elements.
 *
 * @private
 */
TestTimeline.prototype.updateGUI = function () {
  // Update the timeline
  var width = "100%";
  if (this.endTime_ != 0) {
    width = (this.currentTime_ / this.endTime_) * 100.0 +'%'
  }
  this.timelineprogress.style.width = width;
  this.timelinebar.title = (this.currentTime_).toFixed(0) + 'ms';
};


/**
 * Sort the timeline into run order. Should be called after adding something to
 * the timeline.
 *
 * @private
 */
TestTimeline.prototype.sort_ = function() {
  this.timeline_.sort(function(a,b) {
    return a.millis - b.millis;
  });
};

/**
 * Schedule something to be called at a given time.
 *
 * @param {function(number)} callback Callback to call after the number of millis
 *   have elapsed.
 * @param {number} millis Milliseconds after start at which the callback should
 *   be called.
 */
TestTimeline.prototype.schedule = function(callback, millis) {
  log('TestTimeline', 'schedule', millis, callback);
  if (millis < this.currentTime_) {
    // Can't schedule something in the past?
    return;
  }

  // See if there is something at that time in the timeline already?
  var timeline = this.timeline_.slice(0);
  var group = null;
  while (timeline.length > 0) {
    if (timeline[0].millis == millis) {
      group = timeline[0];
      break;
    } else {
      timeline.shift();
    }
  }

  // If not, create a node at that time.
  if (group === null) {
    group = new TestTimelineGroup(millis);
    this.timeline_.unshift(group);
    this.sort_();
  }
  group.add(callback);

  var newEndTime = this.timeline_.slice(-1)[0].millis * 1.1;
  if (this.endTime_ != newEndTime) {
    this.endTime_ = newEndTime;
  }
};

/**
 * Return the current time in milliseconds.
 */
TestTimeline.prototype.now = function() {
  log('TestTimeline', 'now', Math.max(this.currentTime_, 0));
  return Math.max(this.currentTime_, 0);
};

/**
 * Set the current time to a given value.
 *
 * @param {number} millis Time in milliseconds to set the current time too.
 */
TestTimeline.prototype.setTime = function(millis) {
  log('TestTimeline', 'setTime', millis);
  // Time is going backwards, we actually have to reset and go forwards as
  // events can cause the creation of more events.
  if (this.currentTime_ > millis) {
    this.reset();
    this.start();
  }

  var events = this.timeline_.slice(0);

  // Already processed events
  while (events.length > 0 && events[0].millis <= this.currentTime_) {
    events.shift();
  }

  while (this.currentTime_ < millis) {
    var event_ = null;
    var moveTo = millis;

    if (events.length > 0 && events[0].millis <= millis) {
      event_ = events.shift();
      moveTo = event_.millis;
    }

    // Call the callback
    if (this.currentTime_ != moveTo) {
      log('TestTimeline', 'setting time to', moveTo);
      this.currentTime_ = moveTo;
      this.animationFrame(this.currentTime_);
    }

    if (event_) {
      event_.call();
    }
  }

  this.updateGUI();

  if (millis >= this.endTime_) {
    this.done();
  }
};

/**
 * Call all callbacks registered for the next (virtual) animation frame.
 *
 * @param {number} millis Time in milliseconds.
 * @private
 */
TestTimeline.prototype.animationFrame = function(millis) {
  /* FIXME(mithro): Code should appear here to allow testing of running
   * every animation frame.

  if (this.everyFrame) {
  }

  */

  var callbacks = this.animationFrameCallbacks;
  callbacks.reverse();
  this.animationFrameCallbacks = [];
  for (var i = 0; i < callbacks.length; i++) {
    log('TestTimeline raf callback', callbacks[i], millis);
    try {
      callbacks[i](millis);
    } catch (e) {
      // On IE the only way to get the real stack is to do this
      window.onerror(e.message, e.fileName, e.lineNumber, e);
      // On other browsers we want to throw the error later
      setTimeout(function () { throw e; }, 0);
    }
  }
};

/**
 * Set a callback to run at the next (virtual) animation frame.
 *
 * @param {function(millis)} millis Time in milliseconds to set the current
 *   time too.
 */
TestTimeline.prototype.requestAnimationFrame = function(callback) {
  // FIXME: This should return a reference that allows people to cancel the
  // animationFrame callback.
  this.animationFrameCallbacks.push(callback);
  return -1;
};

/**
 * Go to next scheduled event in timeline.
 */
TestTimeline.prototype.toNextEvent = function() {
  var events = this.timeline_.slice(0);
  while (events.length > 0 && events[0].millis <= this.currentTime_) {
    events.shift();
  }
  if (events.length > 0) {
    this.setTime(events[0].millis);

    if (this.autorun_) {
      setTimeout(this.toNextEvent.bind(this), 0);
    }

    return true;
  } else {
    this.setTime(this.endTime_);
    return false;
  }

};

/**
 * Go to previous scheduled event in timeline.
 * (This actually goes back to time zero and then forward to this event.)
 */
TestTimeline.prototype.toPrevEvent = function() {
  var events = this.timeline_.slice(0);
  while (events.length > 0 &&
         events[events.length - 1].millis >= this.currentTime_) {
    events.pop();
  }
  if (events.length > 0) {
    this.setTime(events[events.length - 1].millis);
    return true;
  } else {
    this.setTime(0);
    return false;
  }
};

/**
 * Reset the timeline to time zero.
 */
TestTimeline.prototype.reset = function () {
  for (var t in this.timeline_) {
    this.timeline_[t].reset();
  }

  this.currentTime_ = -this.frameMillis;
  this.animationFrameCallbacks = [];
  this.started_ = false;
};

/**
 * Call to initiate starting???
 */
TestTimeline.prototype.start = function () {
  this.started_ = true;

  var parent = this;

  for (var t in this.timeline_) {
    this.timeline_[t].start();
    // FIXME(mithro) this is confusing...
    this.timeline_[t].draw(this.timelinebar, this.endTime_);

    this.timeline_[t].marker.onclick = function(event) {
      parent.setTime(this.millis);
      event.stopPropagation();
    }.bind(this.timeline_[t]);
  }

  this.timelinebar.onclick = function(evt) {
    var setPercent =
      ((evt.clientX - this.offsetLeft) / this.offsetWidth);
    parent.setTime(setPercent * parent.endTime_);
  }.bind(this.timelinebar);
};

TestTimeline.prototype.done = function () {
  log('TestTime', 'done');
  done();
};

TestTimeline.prototype.autorun = function() {
  this.autorun_ = true;
  this.toNextEvent();
};

function testharness_timeline_setup() {
  log('testharness_timeline_setup');
  testharness_timeline.createGUI(document.getElementsByTagName('body')[0]);
  testharness_timeline.start();
  testharness_timeline.updateGUI();

  // Start running the test on message
  if ('#message' == window.location.hash) {
    window.addEventListener('message', function(evt) {
      switch (evt.data['type']) {
        case 'start':
          if (evt.data['url'] == window.location.href) {
            testharness_timeline.autorun();
          }
          break;
      }
    });
  } else if ('#auto' == window.location.hash || '#coverage' == window.location.hash) {
    // Run the test as fast as possible, skipping time.

    // Need non-zero timeout to allow chrome to run other code.
    setTimeout(testharness_timeline.autorun.bind(testharness_timeline), 1);

  } else if (inExploreMode()) {
    setTimeout(testharness_timeline.runner_.start.bind(testharness_timeline.runner_), 1);
  } else {
    alert('Unknown start mode.');
  }
}

// Capture testharness's test as we are about to screw with it.
var testharness_test = window.test;

function override_at(replacement_at, f, args) {
  var orig_at = window.at;
  window.at = replacement_at;
  f.apply(null, args);
  window.at = orig_at;
}

function timing_test(f, desc) {
  /**
   * at function inside a timing_test function allows testing things at a
   * given time rather then onload.
   * @param {number} seconds Seconds after page load to run the tests.
   * @param {function()} f Closure containing the asserts to be run.
   * @param {string} desc Description 
   */
  var at = function(seconds, f, desc_at) {
    assert_true(typeof seconds == 'number', "at's first argument shoud be a number.");
    assert_true(!isNaN(seconds), "at's first argument should be a number not NaN!");
    assert_true(seconds >= 0, "at's first argument should be greater then 0.");
    assert_true(isFinite(seconds), "at's first argument should be finite.");

    assert_true(typeof f == 'function', "at's second argument should be a function.");

    // Deliberately hoist the desc if we where not given one.
    if (typeof desc_at == 'undefined' || desc_at == null || desc_at.length == 0) {
      desc_at = desc;
    }

    // And then provide 'Unnamed' as a default
    if (typeof desc_at == 'undefined' || desc_at == null || desc_at.length == 0) {
      desc_at = 'Unnamed assert';
    }

    var t = async_test(desc_at + ' at t=' + seconds + 's');
    t.f = f;
    window.testharness_timeline.schedule(t, seconds * 1000.0);
  };
  override_at(at, f);
}

function test_without_at(f, desc) {
   // Make sure calling at inside a test() function is a failure.
  override_at(function() {
    throw {'message': 'Can not use at() inside a test, use a timing_test instead.'};
  }, function() { testharness_test(f, desc); });
}

/**
 * at function schedules a to be called at a given point.
 * @param {number} seconds Seconds after page load to run the function.
 * @param {function()} f Function to be called. Called with no arguments
 */
function at(seconds, f) {
  assert_true(typeof seconds == 'number', "at's first argument shoud be a number.");
  assert_true(typeof f == 'function', "at's second argument should be a function.");

  window.testharness_timeline.schedule(f, seconds * 1000.0);
}

window.testharness_after_loaded = function() {
  log('testharness_after_loaded');
  /**
   * These steps needs to occur after testharness is loaded.
   */
  setup(function() {}, {
      explicit_timeout: true,
      explicit_done: ((typeof window.testharness_timeline) !== 'undefined')});

  /**
   * Create an testharness test which makes sure the page contains no
   * javascript errors. This is needed otherwise if the page contains errors
   * then preventing the tests loading it will look like it passed.
   */
  var pageerror_test = async_test('Page contains no errors');

  window.onerror = function(msg, url, line, e) {
    var msg = '\nError in ' + url + '\n' +
        'Line ' + line + ': ' + msg + '\n';

    if (typeof e != "undefined") {
      msg += e.stack;
    }

    pageerror_test.is_done = true;
    pageerror_test.step(function() { 
      throw new AssertionError(msg);
    });
    pageerror_test.is_done = false;
  };

  var pageerror_tests;
  function pageerror_othertests_finished(test, harness) {
    if (harness == null && pageerror_tests == null) {
      return;
    }

    if (pageerror_tests == null) {
      pageerror_tests = harness;
    }

    if (pageerror_tests.all_loaded && pageerror_tests.num_pending == 1) {
      pageerror_test.done();
    }
  }
  add_result_callback(pageerror_othertests_finished);
  addEventListener('load', pageerror_othertests_finished);

};

loadScript('../testharness/testharness.js', {coverage: false});
document.write('<script type="text/javascript">window.testharness_after_loaded();</script>');
loadCSS('../testharness/testharness.css');
loadCSS('../testharness_timing.css');

if (testType() == 'auto') {
  var checksFile = location.pathname;
  checksFile = checksFile.replace(/disabled-/, '');
  checksFile = checksFile.replace(/.html$/, '-checks.js')
  loadScript(checksFile, {coverage: false});
}

document.write('<div id="log"></div>');
loadScript('../testharness/testharnessreport.js', {coverage: false});

if (!hasFlag('nopolyfill')) {
  loadScript('../../web-animations.js');
}

addEventListener('load', function() {
  if (window._WebAnimationsTestingUtilities) {
    // Currently enabling asserts breaks auto-test-initial in IE.
    //_WebAnimationsTestingUtilities._enableAsserts();
  }
});

// Don't export the timing functions in unittests.
if (testType() != 'unit') {
  addEventListener('load', testharness_timeline_setup);

  window.at = at;
  window.timing_test = timing_test;
  window.test = test_without_at;

  // Expose the extra API
  window.testharness_timeline = new TestTimeline();

  // Override existing timing functions
  window.requestAnimationFrame =
    testharness_timeline.requestAnimationFrame.bind(testharness_timeline);
  window.performance.now = null;
  window.Date.now = testharness_timeline.now.bind(testharness_timeline);
}

})();
