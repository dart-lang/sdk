// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See also timeline_message_handler.js.

var traceObject;
var pendingRequests;
var loadingOverlay;

function onModelLoaded(model) {
  viewer.globalMode = true;
  viewer.model = model;
}

function clearTimeline() {
  viewer.model = undefined;
}

function onImportFail(err) {
  var overlay = new tr.ui.b.Overlay();
  overlay.textContent = tr.b.normalizeException(err).message;
  overlay.title = 'Import error';
  overlay.visible = true;
  console.log('import failed');
}

function basicModelEventsFilter(event) {
  return event.args && event.args.mode === 'basic'; // white-listed
}

function updateTimeline(events) {
  if (window.location.hash === '#basic') {
    events = {
      'stackFrames': events['stackFrames'],
      'traceEvents': events['traceEvents'].filter(basicModelEventsFilter)
    };
  }
  var model = new tr.Model();
  var importer = new tr.importer.Import(model);
  var p = importer.importTracesWithProgressDialog([events]);
  p.then(onModelLoaded.bind(undefined, model), onImportFail);
}

function fetchUri(uri, onLoad, onError) {
  var xhr = new XMLHttpRequest();
  xhr.open('GET', uri, true);
  xhr.responseType = 'text';
  xhr.addEventListener('load', onLoad);
  xhr.addEventListener('error', onError);
  xhr.send();
  console.log('GET ' + uri);
}

function showLoadingOverlay(msg) {
  if (!loadingOverlay) {
    loadingOverlay = new tr.ui.b.Overlay();
  }
  loadingOverlay.textContent = msg;
  loadingOverlay.title = 'Loading...';
  loadingOverlay.visible = true;
}

function hideLoadingOverlay() {
  if (!loadingOverlay) {
    return;
  }
  loadingOverlay.visible = false;
  loadingOverlay = undefined;
}

function gotReponse() {
  pendingRequests--;
  if (pendingRequests === 0) {
    console.log('Got all timeline parts');
    updateTimeline(traceObject);
    hideLoadingOverlay();
  }
}

function processTimelineResponse(response) {
  if (response.error) {
    // Maybe profiling is disabled.
    console.log('ERROR ' + response.error.message);
  } else {
    var result = response['result'];
    var newStackFrames = result['stackFrames'];  // Map.
    var newTraceEvents = result['traceEvents'];  // List.

    // Merge in timeline events.
    traceObject.traceEvents = traceObject.traceEvents.concat(newTraceEvents);
    for (var key in newStackFrames) {
      if (newStackFrames.hasOwnProperty(key)) {
        traceObject.stackFrames[key] = newStackFrames[key];
      }
    }
  }

  gotReponse();
}

function fetchTimelineOnLoad(event) {
  var xhr = event.target;
  var response = JSON.parse(xhr.responseText);
  processTimelineResponse(response);
}

function fetchTimelineOnError(event) {
  var xhr = event.target;
  console.log(xhr.statusText);
  gotReponse();
}

function fetchCPUProfile(vmAddress, isolateIds, timeOrigin, timeExtent) {
  showLoadingOverlay('Fetching CPU profile(s) from Dart VM');
  var parser = document.createElement('a');
  parser.href = vmAddress;
  pendingRequests += isolateIds.length;
  for (var i = 0; i < isolateIds.length; i++) {
    var isolateId = isolateIds[i];
    var requestUri = 'http://' +
                     parser.hostname +
                     ':' +
                     parser.port +
                     '/_getCpuProfileTimeline?tags=VMUser&isolateId=' +
                     isolateId +
                     '&timeOriginMicros=' + timeOrigin +
                     '&timeExtentMicros=' + timeExtent;
    fetchUri(requestUri, fetchTimelineOnLoad, fetchTimelineOnError);
  }
}

function fetchTimeline(vmAddress, isolateIds, mode) {
  // Reset combined timeline.
  traceObject = {
    'stackFrames': {},
    'traceEvents': []
  };
  timelineMode = mode;
  pendingRequests = 1;

  showLoadingOverlay('Fetching timeline from Dart VM');
  var parser = document.createElement('a');
  parser.href = vmAddress;
  var requestUri = 'http://' +
                   parser.hostname +
                   ':' +
                   parser.port +
                   '/_getVMTimeline';
  fetchUri(requestUri, function(event) {
    // Grab the response.
    var xhr = event.target;
    var response = JSON.parse(xhr.responseText);
    // Extract the time origin and extent.
    var timeOrigin = response['result']['timeOriginMicros'];
    var timeExtent = response['result']['timeExtentMicros'];
    console.assert(Number.isInteger(timeOrigin), timeOrigin);
    console.assert(Number.isInteger(timeExtent), timeExtent);
    console.log(timeOrigin);
    console.log(timeExtent);
    // fetchCPUProfile.
    fetchCPUProfile(vmAddress, isolateIds, timeOrigin, timeExtent);
    // This must happen after 'fetchCPUProfile';
    processTimelineResponse(response, mode);
  }, fetchTimelineOnError);
}

function saveTimeline() {
  if (pendingRequests > 0) {
    var overlay = new tr.ui.b.Overlay();
    overlay.textContent = 'Cannot save timeline while fetching one.';
    overlay.title = 'Save error';
    overlay.visible = true;
    console.log('cannot save timeline while fetching one.');
    return;
  }
  if (!traceObject ||
      !traceObject.traceEvents ||
      (traceObject.traceEvents.length === 0)) {
    var overlay = new tr.ui.b.Overlay();
    overlay.textContent = 'Cannot save an empty timeline.';
    overlay.title = 'Save error';
    overlay.visible = true;
    console.log('Cannot save an empty timeline.');
    return;
  }
  var blob = new Blob([JSON.stringify(traceObject)],
                      {type: 'application/json'});
  var blobUrl = URL.createObjectURL(blob);
  var link = document.createElementNS('http://www.w3.org/1999/xhtml', 'a');
  link.href = blobUrl;
  var now = new Date();
  var defaultFilename = 'dart-timeline-' +
                        now.getFullYear() +
                        '-' +
                        now.getMonth() +
                        '-' +
                        now.getDate() +
                        '.json';
  var filename = window.prompt('Save as', defaultFilename);
  if (filename) {
    link.download = filename;
    link.click();
  }
}

function loadTimeline() {
  if (pendingRequests > 0) {
    var overlay = new tr.ui.b.Overlay();
    overlay.textContent = 'Cannot load timeline while fetching one.';
    overlay.title = 'Save error';
    overlay.visible = true;
    console.log('Cannot load timeline while fetching one.');
    return;
  }
  var inputElement = document.createElement('input');
  inputElement.type = 'file';
  inputElement.multiple = false;

  var changeFired = false;
  inputElement.addEventListener('change', function(e) {
    if (changeFired)
      return;
    changeFired = true;

    var file = inputElement.files[0];
    var reader = new FileReader();
    reader.onload = function(event) {
      try {
        traceObject = JSON.parse(event.target.result);
        updateTimeline(traceObject);
      } catch (error) {
        tr.ui.b.Overlay.showError('Error while loading file: ' + error);
      }
    };
    reader.onerror = function(event) {
      tr.ui.b.Overlay.showError('Error while loading file: ' + event);
    };
    reader.onabort = function(event) {
      tr.ui.b.Overlay.showError('Error while loading file: ' + event);
    }
    reader.readAsText(file);
  });
  inputElement.click();
}

window.addEventListener('DOMContentLoaded', function() {
  var container = document.createElement('track-view-container');
  container.id = 'track_view_container';
  viewer = document.createElement('tr-ui-timeline-view');
  viewer.track_view_container = container;
  viewer.appendChild(container);
  viewer.id = 'trace-viewer';
  viewer.globalMode = true;
  document.body.appendChild(viewer);
  timeline_loaded = true;
  console.log('DOMContentLoaded');
  if (timeline_vm_address != undefined) {
    console.log('Triggering delayed timeline refresh.');
    fetchTimeline(timeline_vm_address, timeline_isolates);
    timeline_vm_address = undefined;
    timeline_isolates = undefined;
  }
});

console.log('timeline.js loaded');
