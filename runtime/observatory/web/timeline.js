// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Used to delay the initial timeline load until the timeline has finished
// loading.
timeline_loaded = false;
timeline_vm_address = undefined;
timeline_isolates = undefined;

function registerForMessages() {
  window.addEventListener("message", onMessage, false);
}

registerForMessages();

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

  if (response.error) {
    // Maybe profiling is disabled.
    console.log("ERROR " + response.error.message);
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
      (traceObject.traceEvents.length == 0)) {
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
  var defaultFilename = "dart-timeline-" +
                        now.getFullYear() +
                        "-" +
                        now.getMonth() +
                        "-" +
                        now.getDate() +
                        ".json";
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

function onMessage(event) {
  var request = JSON.parse(event.data);
  var method = request['method'];
  var params = request['params'];
  switch (method) {
    case 'refresh':
      if (!timeline_loaded) {
        timeline_vm_address = params['vmAddress'];
        timeline_isolates = params['isolateIds'];
        console.log('Delaying timeline refresh until loaded.');
      } else {
        fetchTimeline(params['vmAddress'], params['isolateIds']);
      }
    break;
    case 'clear':
      clearTimeline();
    break;
    case 'save':
      saveTimeline();
    break;
    case 'load':
      loadTimeline();
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
  timeline_loaded = true;
  if (timeline_vm_address != undefined) {
    console.log('Triggering delayed timeline refresh.');
    fetchTimeline(timeline_vm_address, timeline_isolates);
    timeline_vm_address = undefined;
    timeline_isolates = undefined;
  }
});

console.log('loaded');
