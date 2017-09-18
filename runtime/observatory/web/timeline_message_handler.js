// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file is loaded before the about:tracing code is loaded so that we have
// an event listener registered early.

// Used to delay the initial timeline load until the timeline has finished
// loading.
timeline_loaded = false;
timeline_vm_address = undefined;
timeline_isolates = undefined;

function registerForMessages() {
  window.addEventListener("message", onMessage, false);
  window.addEventListener("hashchange", onHashChange, false);
}

registerForMessages();

function onMessage(event) {
  var request = JSON.parse(event.data);
  var method = request['method'];
  var params = request['params'];
  console.log('method: ' + method)
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

function onHashChange() {
  refreshTimeline();
}

console.log('message handler registered');
