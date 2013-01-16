// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A semi-generic header file that can be used to isolate platform differences
// for OpenGL headers.
#ifndef EMBEDDERS_OPENGLUI_COMMON_OPENGL_H_
#define EMBEDDERS_OPENGLUI_COMMON_OPENGL_H_

#if defined(__APPLE__)
#  ifdef GL_ES_VERSION_2_0
#    include <OpenGLES/ES2/gl.h>
#  else
#    include <Glut/glut.h>
#    include <OpenGL/gl.h>
#  endif
#  define GLSwapBuffers()    glutSwapBuffers()
#elif defined(_WIN32) || defined(_WIN64)
#  include <GL/glew.h>
#  include <GL/wglew.h>
#  include <GLUT/glut.h>
#  include <Windows.h>
#  define GLSwapBuffers()    glutSwapBuffers()
#elif defined(__ANDROID__)
#  include <EGL/egl.h>
#  include <GLES2/gl2.h>
#  include <GLES2/gl2ext.h>
#  define GLSwapBuffers() \
    do {\
      EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY); \
      EGLSurface surface = eglGetCurrentSurface(EGL_DRAW); \
      eglSwapBuffers(display, surface); \
    } while (0);
#else  // Linux.
#  define GL_GLEXT_PROTOTYPES 1
#  include <GL/gl.h>
#  include <GL/glext.h>
#  include <GL/glut.h>
#  define GLSwapBuffers()    glutSwapBuffers()
#endif

#endif  // EMBEDDERS_OPENGLUI_COMMON_OPENGL_H_

