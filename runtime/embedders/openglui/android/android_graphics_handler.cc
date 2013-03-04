// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/android/android_graphics_handler.h"
#include "embedders/openglui/common/log.h"

AndroidGraphicsHandler::AndroidGraphicsHandler(android_app* application,
                                               const char* resource_path)
    : GraphicsHandler(resource_path),
      application_(application),
      display_(EGL_NO_DISPLAY),
      surface_(EGL_NO_SURFACE),
      context_(EGL_NO_CONTEXT) {
}

int32_t AndroidGraphicsHandler::Start() {
  EGLint format, numConfigs;
  EGLConfig config;
  const EGLint attributes[] = {
      EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
      EGL_NONE
  };
  static const EGLint ctx_attribs[] = {
    EGL_CONTEXT_CLIENT_VERSION, 2,
    EGL_NONE
  };

  display_ = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  if (display_ != EGL_NO_DISPLAY) {
    LOGI("eglInitialize");
    if (eglInitialize(display_, NULL, NULL)) {
      LOGI("eglChooseConfig");
      if (eglChooseConfig(display_, attributes, &config, 1, &numConfigs) &&
          numConfigs > 0) {
        LOGI("eglGetConfigAttrib returned %d configs\n", numConfigs);
        if (eglGetConfigAttrib(display_, config,
                               EGL_NATIVE_VISUAL_ID, &format)) {
          ANativeWindow_setBuffersGeometry(application_->window, 0, 0, format);
          surface_ = eglCreateWindowSurface(display_, config,
                              (EGLNativeWindowType)application_->window, NULL);
          if (surface_ != EGL_NO_SURFACE) {
            LOGI("eglCreateContext");
            context_ = eglCreateContext(display_, config, EGL_NO_CONTEXT,
                                        ctx_attribs);
            if (context_ != EGL_NO_CONTEXT) {
              if (eglMakeCurrent(display_, surface_, surface_, context_) &&
                  eglQuerySurface(display_, surface_, EGL_WIDTH, &width_) &&
                  width_ > 0 &&
                  eglQuerySurface(display_, surface_, EGL_HEIGHT, &height_) &&
                  height_ > 0) {
                LOGI("Got dimensions %d x %d\n", width_, height_);
                SetViewport(0, 0, width_, height_);
                LOGI("GL version %s\n", glGetString(GL_VERSION));
                LOGI("GLSL version: %s\n",
                    glGetString(GL_SHADING_LANGUAGE_VERSION));
                return GraphicsHandler::Start();
              }
            }
          }
        }
      }
    }
  }
  LOGE("Error starting graphics");
  Stop();
  return -1;
}

void AndroidGraphicsHandler::Stop() {
  LOGI("Stopping graphics");
  GraphicsHandler::Stop();
  if (display_ != EGL_NO_DISPLAY) {
    eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
    if (context_ != EGL_NO_CONTEXT) {
      eglDestroyContext(display_, context_);
      context_ = EGL_NO_CONTEXT;
    }
    if (surface_ != EGL_NO_SURFACE) {
      eglDestroySurface(display_, surface_);
      surface_ = EGL_NO_SURFACE;
    }
    eglTerminate(display_);
    display_ = EGL_NO_DISPLAY;
  }
}

