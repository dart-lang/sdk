// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/android/graphics.h"

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

#include "embedders/android/log.h"

extern void CheckGLError(const char *function);

Graphics::Graphics(android_app* application, Timer* timer)
    : application_(application),
      timer_(timer),
      width_(0),
      height_(0),
      display_(EGL_NO_DISPLAY),
      surface_(EGL_NO_SURFACE),
      context_(EGL_NO_CONTEXT) {
}

const int32_t& Graphics::height() {
  return height_;
}

const int32_t& Graphics::width() {
  return width_;
}

int32_t Graphics::Start() {
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
        LOGI("eglGetConfigAttrib");
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
                SetViewport(0, 0, width_, height_);
                return 0;
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

void Graphics::Stop() {
  LOGI("Stopping graphics");
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

int32_t Graphics::Update() {
  return 0;
}

void Graphics::SwapBuffers() {
  EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  EGLSurface surface = eglGetCurrentSurface(EGL_DRAW);
  eglSwapBuffers(display, surface);
}

void Graphics::SetViewport(int left, int top, int width, int height) {
  glViewport(left, top, width, height);
  CheckGLError("glViewPort");
}

int Graphics::BuildProgram(const char* vertexShaderSource,
                                 const char* fragmentShaderSource) const {
  int vertexShader = BuildShader(vertexShaderSource, GL_VERTEX_SHADER);
  int fragmentShader = BuildShader(fragmentShaderSource, GL_FRAGMENT_SHADER);
  if (vertexShader < 0 || fragmentShader < 0) {
    return -1;
  }

  GLuint programHandle = glCreateProgram();
  glAttachShader(programHandle, static_cast<GLuint>(vertexShader));
  glAttachShader(programHandle, static_cast<GLuint>(fragmentShader));
  glLinkProgram(programHandle);

  GLint linkSuccess;
  glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
  if (linkSuccess == GL_FALSE) {
    GLint infoLogLength;
    glGetProgramiv(programHandle, GL_INFO_LOG_LENGTH, &infoLogLength);
    GLchar* strInfoLog = new GLchar[infoLogLength + 1];
    glGetProgramInfoLog(programHandle, infoLogLength, NULL, strInfoLog);
    strInfoLog[infoLogLength] = 0;
    LOGE("Link failed: %s", strInfoLog);
    delete[] strInfoLog;
    return -1;
  }
  return static_cast<int>(programHandle);
}

int Graphics::BuildShader(const char* source, GLenum shaderType) const {
  GLuint shaderHandle = glCreateShader(shaderType);
  glShaderSource(shaderHandle, 1, &source, NULL);
  glCompileShader(shaderHandle);

  GLint compileSuccess;
  glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);

  if (compileSuccess == GL_FALSE) {
    GLint infoLogLength = 0;
    glGetShaderiv(shaderHandle, GL_INFO_LOG_LENGTH, &infoLogLength);
    GLchar* strInfoLog = new GLchar[infoLogLength + 1];
    glGetShaderInfoLog(shaderHandle, infoLogLength, NULL, strInfoLog);
    strInfoLog[infoLogLength] = 0;
    LOGE("Shader compile failed: %s", strInfoLog);
    delete [] strInfoLog;
    return -1;
  }
  return static_cast<int>(shaderHandle);
}

