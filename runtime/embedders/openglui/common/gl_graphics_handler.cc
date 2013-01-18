// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/common/gl_graphics_handler.h"
#include "embedders/openglui/common/log.h"

extern void CheckGLError(const char *function);

void GLGraphicsHandler::SetViewport(int left, int top, int width, int height) {
  glViewport(left, top, width, height);
  CheckGLError("glViewPort");
}

int GLGraphicsHandler::BuildProgram(const char* vertexShaderSource,
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

int GLGraphicsHandler::BuildShader(const char* source,
                                   GLenum shaderType) const {
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

