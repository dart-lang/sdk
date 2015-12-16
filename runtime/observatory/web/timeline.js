// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

function onModelLoaded() {
  viewer.globalMode = true;
  viewer.model = model;
}

function clearTimeline() {
  viewer.model = undefined;
}

function onImportFail() {
  var overlay = new tr.ui.b.Overlay();
  overlay.textContent = tr.b.normalizeException(err).message;
  overlay.title = 'Import error';
  overlay.visible = true;
  console.log('import failed');
}

function updateTimeline(events) {
  model = new tr.Model();
  var importer = new tr.importer.Import(model);
  var p = importer.importTracesWithProgressDialog([events]);
  p.then(onModelLoaded, onImportFail);
}

function registerForMessages() {
  window.addEventListener("message", onMessage, false);
}

function fetchUri(uri, onLoad, onError) {
  var xhr = new XMLHttpRequest();
  xhr.open('GET', uri, true);
  xhr.responseType = 'text';
  xhr.addEventListener("load", onLoad);
  xhr.addEventListener("error", onError);
  xhr.send();
  console.log('GET ' + uri);
}


var traceObject;
var pendingRequests;

function gotReponse() {
  pendingRequests--;
  if (pendingRequests == 0) {
    console.log("Got all timeline parts");
    updateTimeline(traceObject);
  }
}

function fetchTimelineOnLoad(event) {
  var xhr = event.target;
  var response = JSON.parse(xhr.responseText);
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

  gotReponse();
}

function fetchTimelineOnError(event) {
  var xhr = event.target;
  console.log(xhr.statusText);
  gotReponse();
}

function fetchTimeline(vmAddress, isolateIds) {
  // Reset combined timeline.
  traceObject = {
    'stackFrames': {},
    'traceEvents': []
  };
  pendingRequests = 1 + isolateIds.length;

  var parser = document.createElement('a');
  parser.href = vmAddress;
  var requestUri = 'http://' +
                   parser.hostname +
                   ':' +
                   parser.port +
                   '/_getVMTimeline';
  fetchUri(requestUri, fetchTimelineOnLoad, fetchTimelineOnError);

  for (var i = 0; i < isolateIds.length; i++) {
    var isolateId = isolateIds[i];
    var requestUri = 'http://' +
                     parser.hostname +
                     ':' +
                     parser.port +
                     '/_getCpuProfileTimeline?tags=VMUser&isolateId=' +
                     isolateId;
    fetchUri(requestUri, fetchTimelineOnLoad, fetchTimelineOnError);
  }
}

function onMessage(event) {
  var request = JSON.parse(event.data);
  var method = request['method'];
  var params = request['params'];
  switch (method) {
    case 'refresh':
      fetchTimeline(params['vmAddress'], params['isolateIds']);
    break;
    case 'clear':
      clearTimeline();
    break;
    default:
      console.log('Unknown method:' + method + '.');
  }
}

document.addEventListener('DOMContentLoaded', function() {
  var container = document.createElement('track-view-container');
  container.id = 'track_view_container';
  viewer = document.createElement('tr-ui-timeline-view');
  viewer.track_view_container = container;
  viewer.appendChild(container);
  viewer.id = 'trace-viewer';
  viewer.globalMode = true;
  document.body.appendChild(viewer);
  registerForMessages();
});

console.log('loaded');
