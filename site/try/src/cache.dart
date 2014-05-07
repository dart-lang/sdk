// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.cache;

import 'dart:async' show
    Timer;

import 'dart:html' show
    AnchorElement,
    ApplicationCache,
    Event,
    MeterElement,
    ProgressEvent,
    window;

import 'ui.dart' show
    cacheStatusElement;

/// Called when the window has finished loading.
void onLoad(Event event) {
  if (!ApplicationCache.supported) return;
  window.applicationCache.onUpdateReady.listen(updateCacheStatus);
  window.applicationCache.onCached.listen(updateCacheStatus);
  window.applicationCache.onChecking.listen(updateCacheStatus);
  window.applicationCache.onDownloading.listen(updateCacheStatus);
  window.applicationCache.onError.listen(updateCacheStatus);
  window.applicationCache.onNoUpdate.listen(updateCacheStatus);
  window.applicationCache.onObsolete.listen(updateCacheStatus);
  window.applicationCache.onProgress.listen(onCacheProgress);
}

void onCacheProgress(Event event) {
  if (event is ProgressEvent) {
    // Firefox doesn't fire a ProgressEvent on cache progress.  Just a plain
    // Event with type == "progress".
    if (event.lengthComputable) {
      updateCacheStatusFromEvent(event);
      return;
    }
  }
  updateCacheStatus(null);
}

void updateCacheStatusFromEvent(ProgressEvent event) {
  cacheStatusElement.nodes.clear();
  cacheStatusElement.appendText('Downloading SDK ');
  var progress = '${event.loaded} of ${event.total}';
  if (MeterElement.supported) {
    cacheStatusElement.append(
        new MeterElement()
            ..appendText(progress)
            ..min = 0
            ..max = event.total
            ..value = event.loaded);
  } else {
    cacheStatusElement.appendText(progress);
  }
}

String cacheStatus() {
  if (!ApplicationCache.supported) return 'offline not supported';
  int status = window.applicationCache.status;
  if (status == ApplicationCache.CHECKING) return 'Checking for updates';
  if (status == ApplicationCache.DOWNLOADING) return 'Downloading SDK';
  if (status == ApplicationCache.IDLE) return 'Try Dart! works offline';
  if (status == ApplicationCache.OBSOLETE) return 'OBSOLETE';
  if (status == ApplicationCache.UNCACHED) return 'offline not available';
  if (status == ApplicationCache.UPDATEREADY) return 'SDK downloaded';
  return '?';
}

void updateCacheStatus(_) {
  cacheStatusElement.nodes.clear();
  int status = window.applicationCache.status;
  if (status == ApplicationCache.UPDATEREADY) {
    cacheStatusElement.appendText('New version of Try Dart! ready: ');
    cacheStatusElement.append(
        new AnchorElement(href: '#')
            ..appendText('Load')
            ..onClick.listen((event) {
              event.preventDefault();
              window.applicationCache.swapCache();
              window.location.reload();
            }));
  } else if (status == ApplicationCache.IDLE) {
    cacheStatusElement.appendText(cacheStatus());
    cacheStatusElement.classes.add('offlineyay');
    new Timer(const Duration(seconds: 10), () {
      cacheStatusElement.style.display = 'none';
    });
  } else {
    cacheStatusElement.appendText(cacheStatus());
  }
}
