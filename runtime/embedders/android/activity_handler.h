// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_ANDROID_ACTIVITY_HANDLER_H_
#define EMBEDDERS_ANDROID_ACTIVITY_HANDLER_H_

class ActivityHandler {
  public:
    virtual int32_t OnActivate() = 0;
    virtual void OnDeactivate() = 0;
    virtual int32_t OnStep() = 0;
    virtual void OnStart() {}
    virtual void OnResume() {}
    virtual void OnPause() {}
    virtual void OnStop() {}
    virtual void OnDestroy() {}
    virtual void OnSaveState(void** data, size_t* size) {}
    virtual void OnConfigurationChanged() {}
    virtual void OnLowMemory() {}
    virtual void OnCreateWindow() {}
    virtual void OnDestroyWindow() {}
    virtual void OnGainedFocus() {}
    virtual void OnLostFocus() {}
    virtual ~ActivityHandler() {}
};

#endif  // EMBEDDERS_ANDROID_ACTIVITY_HANDLER_H_
