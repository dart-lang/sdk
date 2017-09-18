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

function compareTimestamp(a, b) { return a.ts - b.ts; }
function compareBeginTimestamp(a, b) { return a.begin.ts - b.begin.ts; }
function compareEndTimestamp(a, b) { return a.end.ts - b.end.ts; }

var basicModelEventsWaterfall = [
  // Sort events and remove orphan async ends.
  function filterUnwantedEvents(events) {
    events = events.slice();
    events.sort(compareTimestamp);
    var threads = {};
    return events.filter(function (event) {
      if (event.ph === 'E') {
        return threads[event.tid] && threads[event.tid].pop();
      }
      var result = event.args && event.args.mode === 'basic';
      if (event.ph === 'B') {
        threads[event.tid] = threads[event.tid] || [];
        threads[event.tid].push(result);
      }
      return result;
    });
  }
];

var frameModelEventsWaterfall = [
  // Sort events and remove orphan async ends.
  function filterUnwantedEvents(events) {
    events = events.slice();
    events.sort(compareTimestamp);
    var threads = {};
    return events.filter(function (event) {
      if (event.ph === 'E') {
        if (!threads[event.tid]) {
          return false
        }
        threads[event.tid] -= 1;
      } else if (event.ph === 'B') {
        threads[event.tid] = (threads[event.tid] || 0) + 1;
      }
      return true;
    });
  },
  // Clone the events (we want to preserve them for dumps).
  function cloneDeep(input) {
    if (typeof input === 'object') {
      if (Array.isArray(input)) {
        return input.map(cloneDeep);
      } else {
        var clone = {};
        Object.keys(input).forEach(function (key) {
          clone[key] = cloneDeep(input[key]);
        });
        return clone;
      }
    }
    return input;
  },
  // Group nested sync begin end sequences on every thread.
  //
  // Example:
  // Input = [B,B,E,B,E,E,B,E,B,B,E,E]
  // Output = [[B,B,E,B,E,E],[B,E],[B,B,E,E]]
  function groupIsolatedPerThreadSequences(events) {
    var sequences = [],
      timeless = [],
      threadOpen = {};
      threadSequences = {};
    events.forEach(function (event) {
      if (event.ph === 'M') {
        timeless.push(event);
      } else if (event.ph === 'B') {
        threadOpen[event.tid] = Math.max(threadOpen[event.tid] || 0) + 1;
        threadSequences[event.tid] = threadSequences[event.tid] || [];
        threadSequences[event.tid].push(event);
      } else if (event.ph === 'E') {
        threadSequences[event.tid].push(event);
        threadOpen[event.tid] -= 1;
        if (threadOpen[event.tid] == 0) {
          threadSequences[event.tid].sort()
          sequences.push(threadSequences[event.tid]);
          threadSequences[event.tid] = [];
        }
      } else if (threadSequences[event.tid]){
        threadSequences[event.tid] = threadSequences[event.tid] || [];
        threadSequences[event.tid].push(event);
      }
    })
    return {
      timeless: timeless,
      sequences: sequences
    };
  },
  // Transform every sequence into an object for rapid begin end analysis and
  // block types lookup.
  //
  // Example:
  // Input = [B1,B2,E2,B3,E3,E1]
  // Output = {
  //   begin: B1,
  //   end: E1,
  //   events: [B1,B2,E2,B3,E3,E1],
  //   isGPU: ...,
  //   isVSync: ...,
  //   isFramework: ...,
  //   isShiftable: ...,
  // }
  function sequenceToBlockDescriptor(input) {
    return {
      timeless: input.timeless,
      blocks: input.sequences.map(function (events) {
        var begin,
            end,
            isGPU,
            isVSync,
            isFramework;
        events.forEach(function (event) {
          if (event.ph === 'B') {
            begin = begin || event;
          } else if (event.ph === 'E') {
            end = event;
          }
        });
        isGPU = begin.name === 'GPU Workload';
        isVSync = begin.name === 'VSYNC';
        isFramework = begin.name === 'Framework Workload';
        return {
          begin: begin,
          end: end,
          events: events,
          isGPU: isGPU,
          isVSync: isVSync,
          isFramework: isFramework,
          isShiftable: !(isGPU || isVSync || isFramework)
        };
      })
    };
  },
  // Remove all the blocks that ended before the first VSYNC.
  // These events do not give any information to the analysis.
  function removePreVSyncBlocks(input) {
    input.blocks.sort(compareEndTimestamp);
    var sawVSyncBlock = false;
    return {
      timeless: input.timeless,
      blocks: input.blocks.filter(function (block) {
        sawVSyncBlock = sawVSyncBlock || block.isVSync;
        return sawVSyncBlock;
      })
    };
  },
  // Remove all the GPU blocks that started before the first Framework block.
  // They are orphans of other frames.
  function removePreFrameworkGPUBlocks(input) {
    input.blocks.sort(compareBeginTimestamp);
    var firstFrameworkBlockBeginTimestamp = 0;
    return {
      timeless: input.timeless,
      blocks: input.blocks.filter(function (block) {
        if (block.isFramework) {
          firstFrameworkBlockBeginTimestamp =
              firstFrameworkBlockBeginTimestamp || block.begin.ts;
        } else if (block.isGPU) {
          if (!firstFrameworkBlockBeginTimestamp) {
            return false;
          } else if (block.begin.ts < firstFrameworkBlockBeginTimestamp) {
            return false;
          }
        }
        return true;
      })
    };
  },
  // Merge all shiftable blocks that are between two Framework blocks.
  // By merging them we preserve their relative timing.
  function mergeShiftableBlocks(input) {
    input.blocks.sort(compareEndTimestamp);
    var begin,
        end,
        events = [],
        shiftableBlocks = [],
        blocks;
    blocks = input.blocks.filter(function (block) {
      if (block.isShiftable) {
        begin = begin || block.begin;
        end = block.end;
        events = events.concat(block.events);
        return false;
      } else if (block.isFramework) {
        if (events.length) {
          shiftableBlocks.push({
            begin: begin,
            end: end,
            events: events
          });
        }
      }
      return true;
    });
    if (events.length) {
      shiftableBlocks.push({
        begin: begin,
        end: end,
        events: events
      });
    }
    return {
      timeless: input.timeless,
      blocks: blocks.concat(shiftableBlocks)
    };
  },
  // Remove all VSyncs that didn't started an actual frame.
  function filterFramelessVSyncs(input) {
    input.blocks.sort(compareBeginTimestamp);
    var lastVSyncBlock,
      blocks,
      vSyncBlocks = [];
    blocks = input.blocks.filter(function (block) {
      if (block.isVSync) {
        lastVSyncBlock = block;
        return false;
      } else if (block.isFramework) {
        vSyncBlocks.push(lastVSyncBlock);
      }
      return true;
    });
    return {
      timeless: input.timeless,
      blocks: blocks.concat(vSyncBlocks)
    };
  },
  // Group blocks by type.
  //
  // Example:
  // Input = [S1, V1, F1, V2, G1, F2, V3, G2, F3]
  // Output = {
  //   gpu: [G1, G2],
  //   vsync: [V1, V2, V3],
  //   framework: [F1, F2, F3],
  //   shiftable: [S1]
  // }
  function groupBlocksByFrames(input) {
    return {
      timeless: input.timeless,
      gpu: input.blocks.filter(function (b) { return b.isGPU; }),
      vsync: input.blocks.filter(function (b) { return b.isVSync; }),
      framework: input.blocks.filter(function (b) { return b.isFramework; }),
      shiftable: input.blocks.filter(function (b) { return b.isShiftable; })
    };
  },
  // Remove possible out of sync GPU Blocks.
  // If the buffer has already delete the VSync and the Framework, but not the
  // GPU it can potentially be still alive.
  function groupBlocksByFrames(input) {
    var gpu = input.gpu,
        framework = input.framework;
    while (gpu.length &&
           gpu[0].begin.args.frame !== framework[0].begin.args.frame) {
      gpu.shift();
    }
    return input;
  },
  // Group blocks related to the same frame.
  // Input = {
  //   gpu: [G1, G2],
  //   vsync: [V1, V2],
  //   framework: [F1, F2],
  //   shiftable: [S1]
  // }
  // Output = [{V1, F1, G1, S1}, {V2, F2, G2}, {V3, F3, G3}]
  function groupBlocksByFrames(input) {
    var shiftable = input.shiftable.slice();
    return {
      timeless: input.timeless,
      frames: input.vsync.map(function (vsync, i) {
        var frame = {
          begin: vsync.begin,
          vsync: vsync,
          framework: input.framework[i],
          deadline: parseInt(vsync.begin.args.deadline) + 1000
        };
        if (i < input.gpu.length) {
          frame.gpu = input.gpu[i];
        }
        if (shiftable.length && shiftable[0].begin.ts < framework.begin.ts ) {
          frame.shiftable = shiftable.shift();
        }
        return frame;
      })
    };
  },
  // Move Framework and GPU as back in time as possible
  //
  // Example:
  // Before
  //                               [GPU]
  //     [VSYNC]
  //  [SHIFTABLE]     [FRAMEWORK]
  // After
  //             |[GPU]
  //     [VSYNC] |
  //  [SHIFTABLE]|[FRAMEWORK]
  function shiftEvents(input) {
    input.frames.forEach(function (frame) {
      var earlierTimestamp = frame.vsync.end.ts,
          shift;
      if (frame.shiftable) {
        frame.shiftable.events.forEach(function (event) {
          if (event.tid === frame.framework.begin.tid) {
            earlierTimestamp = Math.max(earlierTimestamp, event.ts);
          }
        });
      }
      if (frame.gpu) {
        if (frame.shiftable) {
          frame.shiftable.events.forEach(function (event) {
            if (event.tid === frame.gpu.begin.tid) {
              earlierTimestamp = Math.max(earlierTimestamp, event.ts);
            }
          });
        }
        shift = earlierTimestamp - frame.gpu.begin.ts;
        frame.gpu.events.forEach(function (event) {
          event.ts += shift;
        });
      }
      shift = earlierTimestamp - frame.framework.begin.ts;
      frame.framework.events.forEach(function (event) {
        event.ts += shift;
      });
      frame.end = frame.framework.end;
      if (frame.gpu && frame.framework.end.ts < frame.gpu.end.ts) {
        frame.end = frame.gpu.end;
      }
    });
    return input;
  },
  // Group events in frame (precomputation for next stage).
  function groupEventsInFrame(input) {
    input.frames.forEach(function (frame) {
      var events = frame.vsync.events;
      events = events.concat(frame.framework.events);
      if (frame.gpu) {
        events = events.concat(frame.gpu.events);
      }
      if (frame.shiftable) {
        events = events.concat(frame.shiftable.events);
      }
      events.sort(compareTimestamp);
      frame.events = events;
    });
    return input;
  },
  // Move frames in order to do not overlap.
  //
  // Example:
  // Before
  //              |[GPU1--------------------]
  //                                     |[GPU2----]
  //     [VSYNC1] |             [VSYNC2] |
  //  [SHIFTABLE1]|[FRAMEWORK1]          |[FRAMEWORK2]
  // After
  //              |[GPU1--------------------]|         |[GPU2-----]
  //     [VSYNC1] |                          |[VSYNC2] |
  //  [SHIFTABLE1]|[FRAMEWORK1]              |         |[FRAMEWORK2]
  // OtherExample:
  // Before
  //     {FRAME BUDGET1-------------------------}
  //                            {FRAME BUDGET2-------------------------}
  //              |[GPU1]
  //                                     |[GPU2]
  //     [VSYNC1] |             [VSYNC2] |
  //  [SHIFTABLE1]|[FRAMEWORK1]          |[FRAMEWORK2]
  // After
  //     {FRAME BUDGET1-------------------------}|{FRAME BUDGET2----------------
  //              |[GPU1]                        |         |[GPU2-----]
  //     [VSYNC1] |                              |[VSYNC2] |
  //  [SHIFTABLE1]|[FRAMEWORK1]                  |         |[FRAMEWORK2]
  function shiftBlocks(input) {
    function minThreadtimestamps(frame) {
      var timestamps = {};
      frame.events.forEach(function (event) {
        if (event.tid != undefined) {
          timestamps[event.tid] = timestamps[event.tid] || event.ts;
        }
      });
      return timestamps;
    }
    function maxThreadTimestamps(frame) {
      var timestamps = {};
      frame.events.forEach(function (event) {
        if (event.tid != undefined) {
          timestamps[event.tid] = event.ts;
        }
      });
      return timestamps;
    }
    input.frames.slice(1).forEach(function (current, index) {
      var previous = input.frames[index],
        shift = Math.max(previous.end.ts, previous.deadline) - current.begin.ts,
        maxThreadTimestamp = maxThreadTimestamps(previous),
        minThreadTimestamp = minThreadtimestamps(current);
      Object.keys(maxThreadTimestamp).forEach(function (tid) {
        if (minThreadTimestamp[tid]) {
          var delta = maxThreadTimestamp[tid] - minThreadTimestamp[tid];
          shift = Math.max(shift, delta);
        }
      });
      current.events.forEach(function (event) {
        event.ts += shift;
      });
      current.deadline += shift;
    });
    return input;
  },
  // Add auxilary events to frame (Frame Budget and Frame Length).
  // Example:
  // Before
  //              |[GPU1--------------------]|         |[GPU2-----]
  //     [VSYNC1] |                          |[VSYNC2] |
  //  [SHIFTABLE1]|[FRAMEWORK1]              |         |[FRAMEWORK2]
  // After
  //     [Budget1---------------------------]|[Budget2--------------------------
  //     [Length1---------------------------]|[Length2------------]
  //              |[GPU1--------------------]|         |[GPU2-----]
  //     [VSYNC1] |                          |[VSYNC2] |
  //  [SHIFTABLE1]|[FRAMEWORK1]              |         |[FRAMEWORK2]
  function addAuxilaryEvents(input) {
    input.frames.forEach(function (frame) {
      frame.events.unshift({
        args: {name: "Frame Budgets"},
        name: "thread_name",
        ph: "M",
        pid: frame.begin.pid,
        tid: "budgets",
      });
      frame.events.unshift({
        args: {name: "Frames"},
        name: "thread_name",
        ph: "M",
        pid: frame.begin.pid,
        tid: "frames",
      });
      var duration = Math.floor((frame.end.ts - frame.begin.ts) / 1000),
          frameName = "Frame " + duration + "ms";
      frame.events = frame.events.concat({
          ph: "B",
          name: "Frame Budget",
          cat: "budgets",
          pid: frame.begin.pid,
          tid: "budgets",
          ts: frame.begin.ts
        }, {
          ph: "E",
          name: "Frame Budget",
          cat: "budgets",
          pid: frame.begin.pid,
          tid: "budgets",
          ts: frame.deadline,
          cname: 'rail_response'
        }, {
          ph: "B",
          name: frameName,
          cat: "frames",
          pid: frame.begin.pid,
          tid: "frames",
          ts: frame.begin.ts
        }, {
          ph: "E",
          name: frameName,
          cat: "frames",
          pid: frame.begin.pid,
          tid: "frames",
          ts: frame.end.ts,
          cname: frame.end.ts > frame.deadline ? 'terrible' : 'good'
        });
    });
    return input;
  },
  // Restore the events array used by catapult.
  function linearizeBlocks(input) {
    return input.frames.reduce(function (events, frame) {
      return events.concat(frame.events);
    }, input.timeless);
  }
];

function basicModelEventsMap(events) {
  return basicModelEventsWaterfall.reduce(function (input, step) {
    return step(input);
  }, events);
}

function frameModelEventsMap(events) {
  return frameModelEventsWaterfall.reduce(function (input, step) {
    return step(input);
  }, events);
}

function updateTimeline(events) {
  if (window.location.hash.indexOf('mode=basic') > -1) {
    events = {
      'stackFrames': events['stackFrames'],
      'traceEvents': basicModelEventsMap(events['traceEvents'])
    };
  }
  if (window.location.hash.indexOf('view=frame') > -1) {
    events = {
      'stackFrames': events['stackFrames'],
      'traceEvents': frameModelEventsMap(events['traceEvents'])
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

function refreshTimeline() {
  updateTimeline(traceObject);
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
  document.getElementById('trace-viewer').highlightVSync = true;
  if (timeline_vm_address != undefined) {
    console.log('Triggering delayed timeline refresh.');
    fetchTimeline(timeline_vm_address, timeline_isolates);
    timeline_vm_address = undefined;
    timeline_isolates = undefined;
  }
});

console.log('timeline.js loaded');
