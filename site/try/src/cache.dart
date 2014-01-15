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
  window.applicationCache.onUpdateReady.listen((_) => updateCacheStatus());
  window.applicationCache.onCached.listen((_) => updateCacheStatus());
  window.applicationCache.onChecking.listen((_) => updateCacheStatus());
  window.applicationCache.onDownloading.listen((_) => updateCacheStatus());
  window.applicationCache.onError.listen((_) => updateCacheStatus());
  window.applicationCache.onNoUpdate.listen((_) => updateCacheStatus());
  window.applicationCache.onObsolete.listen((_) => updateCacheStatus());
  window.applicationCache.onProgress.listen(onCacheProgress);
}

onCacheProgress(ProgressEvent event) {
  if (!event.lengthComputable) {
    updateCacheStatus();
    return;
  }
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

void updateCacheStatus() {
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
