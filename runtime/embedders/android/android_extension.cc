// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/android/android_extension.h"

#include <android/log.h>
#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <jni.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "include/dart_api.h"
#include "embedders/android/log.h"

Dart_Handle HandleError(Dart_Handle handle) {
  if (Dart_IsError(handle)) Dart_PropagateError(handle);
  return handle;
}

void CheckGLError(const char *function) {
  int error = glGetError();
  if (error != GL_NO_ERROR) {
    LOGE("ERROR!: %s returns %d", function, error);
  }
}

const char* GetStringArg(Dart_NativeArguments arguments, int idx) {
  Dart_Handle whatHandle = HandleError(Dart_GetNativeArgument(arguments, idx));
  uint8_t* str;
  intptr_t length;
  HandleError(Dart_StringLength(whatHandle, &length));
  HandleError(Dart_StringToUTF8(whatHandle, &str, &length));
  str[length] = 0;
  return  const_cast<const char*>(reinterpret_cast<char*>(str));
}

void Log(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  LOGI(GetStringArg(arguments, 0));
  Dart_ExitScope();
}

void SystemRand(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  Dart_Handle result = HandleError(Dart_NewInteger(rand()));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void SystemSrand(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  bool success = false;
  Dart_Handle seed_object = HandleError(Dart_GetNativeArgument(arguments, 0));
  if (Dart_IsInteger(seed_object)) {
    bool fits;
    HandleError(Dart_IntegerFitsIntoInt64(seed_object, &fits));
    if (fits) {
      int64_t seed;
      HandleError(Dart_IntegerToInt64(seed_object, &seed));
      srand(static_cast<unsigned>(seed));
      success = true;
    }
  }
  Dart_SetReturnValue(arguments, HandleError(Dart_NewBoolean(success)));
  Dart_ExitScope();
}

void EGLSwapBuffers(Dart_NativeArguments arguments) {
  LOGI("GLSwapBuffers");
  Dart_EnterScope();

  EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  EGLSurface surface = eglGetCurrentSurface(EGL_DRAW);
  eglSwapBuffers(display, surface);

  CheckGLError("eglSwapBuffers");
  Dart_ExitScope();
}

void GLAttachShader(Dart_NativeArguments arguments) {
  LOGI("GLAttachShader");
  Dart_EnterScope();

  Dart_Handle programHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t program;
  HandleError(Dart_IntegerToInt64(programHandle, &program));

  Dart_Handle shaderHandle = HandleError(Dart_GetNativeArgument(arguments, 1));
  int64_t shader;
  HandleError(Dart_IntegerToInt64(shaderHandle, &shader));

  glAttachShader(program, shader);
  CheckGLError("glAttachShader");
  Dart_ExitScope();
}

void GLBindBuffer(Dart_NativeArguments arguments) {
  LOGI("GLBindBuffer");
  Dart_EnterScope();

  Dart_Handle targetHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t target;
  HandleError(Dart_IntegerToInt64(targetHandle, &target));

  Dart_Handle bufferHandle = HandleError(Dart_GetNativeArgument(arguments, 1));
  int64_t buffer;
  HandleError(Dart_IntegerToInt64(bufferHandle, &buffer));

  glBindBuffer(target, buffer);
  CheckGLError("glBindBuffer");
  Dart_ExitScope();
}

void GLBufferData(Dart_NativeArguments arguments) {
  LOGI("GLBufferData");
  Dart_EnterScope();

  Dart_Handle targetHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t target;
  HandleError(Dart_IntegerToInt64(targetHandle, &target));

  Dart_Handle dataHandle = HandleError(Dart_GetNativeArgument(arguments, 1));
  intptr_t size;
  HandleError(Dart_ListLength(dataHandle, &size));

  LOGI("Size: %d", size);

  // TODO(vsm): No guarantee that this is a float!
  float* data = reinterpret_cast<float*>(malloc(size * sizeof(float)));
  for (int i = 0; i < size; i++) {
    Dart_Handle elemHandle = HandleError(Dart_ListGetAt(dataHandle, i));
    double value;
    Dart_DoubleValue(elemHandle, &value);
    data[i] = static_cast<float>(value);
    LOGI("Value[%d]: %f", i, data[i]);
  }

  Dart_Handle usageHandle = HandleError(Dart_GetNativeArgument(arguments, 2));
  int64_t usage;
  HandleError(Dart_IntegerToInt64(usageHandle, &usage));

  glBufferData(target, size * sizeof(float), data, usage);
  CheckGLError("glBufferData");
  free(data);
  Dart_ExitScope();
}

void GLCompileShader(Dart_NativeArguments arguments) {
  Dart_EnterScope();

  Dart_Handle shaderHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t shader;
  HandleError(Dart_IntegerToInt64(shaderHandle, &shader));

  LOGI("GLCompileShader");
  glCompileShader(shader);
  CheckGLError("glCompileShader");
  Dart_ExitScope();
}

void GLCreateBuffer(Dart_NativeArguments arguments) {
  LOGI("GLCreateBuffer");
  Dart_EnterScope();
  GLuint buffer;

  glGenBuffers(1, &buffer);
  CheckGLError("glGenBuffers");
  Dart_Handle result = HandleError(Dart_NewInteger(buffer));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLCreateProgram(Dart_NativeArguments arguments) {
  LOGI("GLCreateProgram");
  Dart_EnterScope();

  int64_t program = glCreateProgram();
  CheckGLError("glCreateProgram");
  Dart_Handle result = HandleError(Dart_NewInteger(program));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLCreateShader(Dart_NativeArguments arguments) {
  Dart_EnterScope();

  Dart_Handle typeHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t type;
  HandleError(Dart_IntegerToInt64(typeHandle, &type));

  int64_t shader = glCreateShader((GLenum)type);
  LOGI("GLCreateShader");
  CheckGLError("glCreateShader");
  Dart_Handle result = HandleError(Dart_NewInteger(shader));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLDrawArrays(Dart_NativeArguments arguments) {
  LOGI("GLDrawArrays");
  Dart_EnterScope();

  Dart_Handle modeHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t mode;
  HandleError(Dart_IntegerToInt64(modeHandle, &mode));

  Dart_Handle firstHandle = HandleError(Dart_GetNativeArgument(arguments, 1));
  int64_t first;
  HandleError(Dart_IntegerToInt64(firstHandle, &first));

  Dart_Handle countHandle = HandleError(Dart_GetNativeArgument(arguments, 2));
  int64_t count;
  HandleError(Dart_IntegerToInt64(countHandle, &count));

  glDrawArrays(mode, first, count);
  CheckGLError("glDrawArrays");
  Dart_ExitScope();
}

void GLEnableVertexAttribArray(Dart_NativeArguments arguments) {
  LOGI("GLEnableVertexAttribArray");
  Dart_EnterScope();

  Dart_Handle locationHandle =
      HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t location;
  HandleError(Dart_IntegerToInt64(locationHandle, &location));

  glEnableVertexAttribArray(location);
  CheckGLError("glEnableVertexAttribArray");
  Dart_ExitScope();
}

void GLGetAttribLocation(Dart_NativeArguments arguments) {
  LOGI("GLGetAttribLocation");
  Dart_EnterScope();

  Dart_Handle programHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t program;
  HandleError(Dart_IntegerToInt64(programHandle, &program));

  Dart_Handle nameHandle = HandleError(Dart_GetNativeArgument(arguments, 1));
  intptr_t length;
  HandleError(Dart_StringLength(nameHandle, &length));
  uint8_t* str;
  HandleError(Dart_StringToUTF8(nameHandle, &str, &length));
  str[length] = 0;

  int64_t location = glGetAttribLocation(program,
      const_cast<const GLchar*>(reinterpret_cast<GLchar*>(str)));
  CheckGLError("glGetAttribLocation");
  Dart_Handle result = HandleError(Dart_NewInteger(location));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLGetError(Dart_NativeArguments arguments) {
  LOGI("GLGetError");
  Dart_EnterScope();

  int64_t error = glGetError();
  Dart_Handle result = HandleError(Dart_NewInteger(error));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLGetProgramParameter(Dart_NativeArguments arguments) {
  LOGI("GLGetProgramParameter");
  Dart_EnterScope();

  Dart_Handle programHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t program;
  HandleError(Dart_IntegerToInt64(programHandle, &program));

  Dart_Handle paramHandle = HandleError(Dart_GetNativeArgument(arguments, 1));
  int64_t param;
  HandleError(Dart_IntegerToInt64(paramHandle, &param));

  GLint value = -1;
  glGetProgramiv(program, param, &value);
  CheckGLError("glGetProgramiv");

  Dart_Handle result = HandleError(Dart_NewInteger(value));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLGetShaderParameter(Dart_NativeArguments arguments) {
  LOGI("GLGetShaderParameter");
  Dart_EnterScope();

  Dart_Handle shaderHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t shader;
  HandleError(Dart_IntegerToInt64(shaderHandle, &shader));

  Dart_Handle paramHandle = HandleError(Dart_GetNativeArgument(arguments, 1));
  int64_t param;
  HandleError(Dart_IntegerToInt64(paramHandle, &param));

  GLint value = -1;
  glGetShaderiv((GLuint)shader, (GLenum)param, &value);
  CheckGLError("glGetShaderiv");

  Dart_Handle result = HandleError(Dart_NewInteger(value));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLGetShaderInfoLog(Dart_NativeArguments arguments) {
  LOGI("GLGetShaderInfoLog");
  Dart_EnterScope();

  Dart_Handle shaderHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t shader;
  HandleError(Dart_IntegerToInt64(shaderHandle, &shader));

  GLint infoLogLength = 0;
  glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLogLength);

  GLchar* strInfoLog = new GLchar[infoLogLength + 1];
  glGetShaderInfoLog(shader, infoLogLength, NULL, strInfoLog);
  strInfoLog[infoLogLength] = 0;

  Dart_Handle result = HandleError(Dart_NewStringFromCString(strInfoLog));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
  delete[] strInfoLog;
}

void GLGetProgramInfoLog(Dart_NativeArguments arguments) {
  LOGI("GLGetProgramInfoLog");
  Dart_EnterScope();

  Dart_Handle programHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t program;
  HandleError(Dart_IntegerToInt64(programHandle, &program));

  GLint infoLogLength;
  glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLogLength);

  GLchar* strInfoLog = new GLchar[infoLogLength + 1];
  glGetProgramInfoLog(program, infoLogLength, NULL, strInfoLog);
  strInfoLog[infoLogLength] = 0;

  Dart_Handle result = HandleError(Dart_NewStringFromCString(strInfoLog));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
  delete[] strInfoLog;
}

void GLGetUniformLocation(Dart_NativeArguments arguments) {
  LOGI("GLGetUniformLocation");
  Dart_EnterScope();

  Dart_Handle programHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t program;
  HandleError(Dart_IntegerToInt64(programHandle, &program));

  Dart_Handle nameHandle = HandleError(Dart_GetNativeArgument(arguments, 1));
  intptr_t length;
  HandleError(Dart_StringLength(nameHandle, &length));
  uint8_t* str;
  HandleError(Dart_StringToUTF8(nameHandle, &str, &length));
  str[length] = 0;

  int64_t location = glGetUniformLocation(program,
      const_cast<const GLchar*>(reinterpret_cast<GLchar*>(str)));
  CheckGLError("glGetUniformLocation");
  Dart_Handle result = HandleError(Dart_NewInteger(location));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLLinkProgram(Dart_NativeArguments arguments) {
  LOGI("GLLinkProgram");
  Dart_EnterScope();

  Dart_Handle programHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t program;
  HandleError(Dart_IntegerToInt64(programHandle, &program));

  glLinkProgram(program);
  CheckGLError("glLinkProgram");
  Dart_ExitScope();
}

void GLShaderSource(Dart_NativeArguments arguments) {
  LOGI("GLShaderSource");
  Dart_EnterScope();

  Dart_Handle shaderHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t shader;
  HandleError(Dart_IntegerToInt64(shaderHandle, &shader));

  Dart_Handle sourceHandle = HandleError(Dart_GetNativeArgument(arguments, 1));
  intptr_t length[1];
  HandleError(Dart_StringLength(sourceHandle, length));
  LOGI("Source length is %d", length[0]);
  uint8_t* str[1];
  HandleError(Dart_StringToUTF8(sourceHandle, &str[0], length));
  LOGI("Converted length is %d", length[0]);
  str[0][*length] = 0;

  const GLchar* source =
      const_cast<const GLchar*>(reinterpret_cast<GLchar*>(str[0]));
  LOGI("Source: %s", source);
  glShaderSource(shader, 1,
      const_cast<const GLchar**>(reinterpret_cast<GLchar**>(str)), NULL);
  CheckGLError("glShaderSource");
  Dart_ExitScope();
}

void GLUseProgram(Dart_NativeArguments arguments) {
  LOGI("GLUseProgram");
  Dart_EnterScope();

  Dart_Handle programHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t program;
  HandleError(Dart_IntegerToInt64(programHandle, &program));

  glUseProgram(program);
  CheckGLError("glUseProgram");
  Dart_ExitScope();
}

void GLUniform1i(Dart_NativeArguments arguments) {
  LOGI("GLUniform1i");
  Dart_EnterScope();

  Dart_Handle locationHandle =
      HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t location;
  HandleError(Dart_IntegerToInt64(locationHandle, &location));

  Dart_Handle v0Handle = HandleError(Dart_GetNativeArgument(arguments, 1));
  int64_t v0;
  HandleError(Dart_IntegerToInt64(v0Handle, &v0));

  glUniform1i(location, v0);
  CheckGLError("glUniform1i");
  Dart_ExitScope();
}

void GLUniform2i(Dart_NativeArguments arguments) {
  LOGI("GLUniform2i");
  Dart_EnterScope();

  Dart_Handle locationHandle =
      HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t location;
  HandleError(Dart_IntegerToInt64(locationHandle, &location));

  Dart_Handle v0Handle = HandleError(Dart_GetNativeArgument(arguments, 1));
  int64_t v0;
  HandleError(Dart_IntegerToInt64(v0Handle, &v0));

  Dart_Handle v1Handle = HandleError(Dart_GetNativeArgument(arguments, 2));
  int64_t v1;
  HandleError(Dart_IntegerToInt64(v1Handle, &v1));

  glUniform2i(location, v0, v1);
  CheckGLError("glUniform2i");
  Dart_ExitScope();
}

void GLUniform3i(Dart_NativeArguments arguments) {
  LOGI("GLUniform3i");
  Dart_EnterScope();

  Dart_Handle locationHandle =
      HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t location;
  HandleError(Dart_IntegerToInt64(locationHandle, &location));

  Dart_Handle v0Handle = HandleError(Dart_GetNativeArgument(arguments, 1));
  int64_t v0;
  HandleError(Dart_IntegerToInt64(v0Handle, &v0));

  Dart_Handle v1Handle = HandleError(Dart_GetNativeArgument(arguments, 2));
  int64_t v1;
  HandleError(Dart_IntegerToInt64(v1Handle, &v1));

  Dart_Handle v2Handle = HandleError(Dart_GetNativeArgument(arguments, 3));
  int64_t v2;
  HandleError(Dart_IntegerToInt64(v2Handle, &v2));

  glUniform3i(location, v0, v1, v2);
  CheckGLError("glUniform3i");
  Dart_ExitScope();
}

void GLUniform4i(Dart_NativeArguments arguments) {
  LOGI("GLUniform4i");
  Dart_EnterScope();

  Dart_Handle locationHandle =
      HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t location;
  HandleError(Dart_IntegerToInt64(locationHandle, &location));

  Dart_Handle v0Handle = HandleError(Dart_GetNativeArgument(arguments, 1));
  int64_t v0;
  HandleError(Dart_IntegerToInt64(v0Handle, &v0));

  Dart_Handle v1Handle = HandleError(Dart_GetNativeArgument(arguments, 2));
  int64_t v1;
  HandleError(Dart_IntegerToInt64(v1Handle, &v1));

  Dart_Handle v2Handle = HandleError(Dart_GetNativeArgument(arguments, 3));
  int64_t v2;
  HandleError(Dart_IntegerToInt64(v2Handle, &v2));

  Dart_Handle v3Handle = HandleError(Dart_GetNativeArgument(arguments, 4));
  int64_t v3;
  HandleError(Dart_IntegerToInt64(v3Handle, &v3));

  glUniform4i(location, v0, v1, v2, v3);
  CheckGLError("glUniform4i");
  Dart_ExitScope();
}

void GLUniform1f(Dart_NativeArguments arguments) {
  LOGI("GLUniform1f");
  Dart_EnterScope();

  Dart_Handle locationHandle =
      HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t location;
  HandleError(Dart_IntegerToInt64(locationHandle, &location));

  Dart_Handle v0Handle = HandleError(Dart_GetNativeArgument(arguments, 1));
  double v0;
  HandleError(Dart_DoubleValue(v0Handle, &v0));

  glUniform1f(location, v0);
  CheckGLError("glUniform1f");
  Dart_ExitScope();
}

void GLUniform2f(Dart_NativeArguments arguments) {
  LOGI("GLUniform2f");
  Dart_EnterScope();

  Dart_Handle locationHandle =
      HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t location;
  HandleError(Dart_IntegerToInt64(locationHandle, &location));

  Dart_Handle v0Handle = HandleError(Dart_GetNativeArgument(arguments, 1));
  double v0;
  HandleError(Dart_DoubleValue(v0Handle, &v0));

  Dart_Handle v1Handle = HandleError(Dart_GetNativeArgument(arguments, 2));
  double v1;
  HandleError(Dart_DoubleValue(v1Handle, &v1));

  glUniform2f(location, v0, v1);
  CheckGLError("glUniform2f");
  Dart_ExitScope();
}

void GLUniform3f(Dart_NativeArguments arguments) {
  LOGI("GLUniform3f");
  Dart_EnterScope();

  Dart_Handle locationHandle =
      HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t location;
  HandleError(Dart_IntegerToInt64(locationHandle, &location));

  Dart_Handle v0Handle = HandleError(Dart_GetNativeArgument(arguments, 1));
  double v0;
  HandleError(Dart_DoubleValue(v0Handle, &v0));

  Dart_Handle v1Handle = HandleError(Dart_GetNativeArgument(arguments, 2));
  double v1;
  HandleError(Dart_DoubleValue(v1Handle, &v1));

  Dart_Handle v2Handle = HandleError(Dart_GetNativeArgument(arguments, 3));
  double v2;
  HandleError(Dart_DoubleValue(v2Handle, &v2));

  glUniform3f(location, v0, v1, v2);
  CheckGLError("glUniform3f");
  Dart_ExitScope();
}

void GLUniform4f(Dart_NativeArguments arguments) {
  LOGI("GLUniform4f");
  Dart_EnterScope();

  Dart_Handle locationHandle =
      HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t location;
  HandleError(Dart_IntegerToInt64(locationHandle, &location));

  Dart_Handle v0Handle = HandleError(Dart_GetNativeArgument(arguments, 1));
  double v0;
  HandleError(Dart_DoubleValue(v0Handle, &v0));

  Dart_Handle v1Handle = HandleError(Dart_GetNativeArgument(arguments, 2));
  double v1;
  HandleError(Dart_DoubleValue(v1Handle, &v1));

  Dart_Handle v2Handle = HandleError(Dart_GetNativeArgument(arguments, 3));
  double v2;
  HandleError(Dart_DoubleValue(v2Handle, &v2));

  Dart_Handle v3Handle = HandleError(Dart_GetNativeArgument(arguments, 4));
  double v3;
  HandleError(Dart_DoubleValue(v3Handle, &v3));

  glUniform4f(location, v0, v1, v2, v3);
  CheckGLError("glUniform4f");
  Dart_ExitScope();
}

void GLUniform1iv(Dart_NativeArguments arguments) {
  LOGI("GLUniform1iv");
  Dart_EnterScope();

  Dart_Handle locationHandle =
      HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t location;
  HandleError(Dart_IntegerToInt64(locationHandle, &location));

  Dart_Handle argHandle = HandleError(Dart_GetNativeArgument(arguments, 1));

  if (Dart_IsList(argHandle)) {
    int len;
    HandleError(Dart_ListLength(argHandle, &len));
    GLint* list = new GLint[len];
    for (int i = 0; i < len; i++) {
      Dart_Handle vHandle = Dart_ListGetAt(argHandle, i);
      int64_t v;
      HandleError(Dart_IntegerToInt64(vHandle, &v));
      list[i] = v;
    }
    glUniform1iv(location, len, list);
    delete [] list;
    CheckGLError("glUniform1iv");
  }
  Dart_ExitScope();
}

void GLUniform2iv(Dart_NativeArguments arguments) {
  LOGI("GLUniform2iv");
  Dart_EnterScope();

  Dart_Handle locationHandle =
      HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t location;
  HandleError(Dart_IntegerToInt64(locationHandle, &location));

  Dart_Handle argHandle = HandleError(Dart_GetNativeArgument(arguments, 1));

  if (Dart_IsList(argHandle)) {
    int len;
    HandleError(Dart_ListLength(argHandle, &len));
    GLint* list = new GLint[len];
    for (int i = 0; i < len; i++) {
      Dart_Handle vHandle = Dart_ListGetAt(argHandle, i);
      int64_t v;
      HandleError(Dart_IntegerToInt64(vHandle, &v));
      list[i] = v;
    }
    glUniform2iv(location, len / 2, list);
    delete [] list;
    CheckGLError("glUniform2iv");
  }
  Dart_ExitScope();
}

void GLUniform3iv(Dart_NativeArguments arguments) {
  LOGI("GLUniform3iv");
  Dart_EnterScope();

  Dart_Handle locationHandle =
      HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t location;
  HandleError(Dart_IntegerToInt64(locationHandle, &location));

  Dart_Handle argHandle = HandleError(Dart_GetNativeArgument(arguments, 1));

  if (Dart_IsList(argHandle)) {
    int len;
    HandleError(Dart_ListLength(argHandle, &len));
    GLint* list = new GLint[len];
    for (int i = 0; i < len; i++) {
      Dart_Handle vHandle = Dart_ListGetAt(argHandle, i);
      int64_t v;
      HandleError(Dart_IntegerToInt64(vHandle, &v));
      list[i] = v;
    }
    glUniform3iv(location, len / 3, list);
    delete [] list;
    CheckGLError("glUniform3iv");
  }
  Dart_ExitScope();
}

void GLUniform4iv(Dart_NativeArguments arguments) {
  LOGI("GLUniform4iv");
  Dart_EnterScope();

  Dart_Handle locationHandle =
      HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t location;
  HandleError(Dart_IntegerToInt64(locationHandle, &location));

  Dart_Handle argHandle = HandleError(Dart_GetNativeArgument(arguments, 1));

  if (Dart_IsList(argHandle)) {
    int len;
    HandleError(Dart_ListLength(argHandle, &len));
    GLint* list = new GLint[len];
    for (int i = 0; i < len; i++) {
      Dart_Handle vHandle = Dart_ListGetAt(argHandle, i);
      int64_t v;
      HandleError(Dart_IntegerToInt64(vHandle, &v));
      list[i] = v;
    }
    glUniform1iv(location, len / 4, list);
    delete [] list;
    CheckGLError("glUniform4iv");
  }
  Dart_ExitScope();
}

void GLUniform1fv(Dart_NativeArguments arguments) {
  LOGI("GLUniform1fv");
  Dart_EnterScope();

  Dart_Handle locationHandle =
      HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t location;
  HandleError(Dart_IntegerToInt64(locationHandle, &location));

  Dart_Handle argHandle = HandleError(Dart_GetNativeArgument(arguments, 1));

  if (Dart_IsList(argHandle)) {
    int len;
    HandleError(Dart_ListLength(argHandle, &len));
    GLfloat* list = new GLfloat[len];
    for (int i = 0; i < len; i++) {
      Dart_Handle vHandle = Dart_ListGetAt(argHandle, i);
      double v;
      HandleError(Dart_DoubleValue(vHandle, &v));
      list[i] = v;
    }
    glUniform1fv(location, len, list);
    delete [] list;
    CheckGLError("glUniform1fv");
  }
  Dart_ExitScope();
}

void GLUniform2fv(Dart_NativeArguments arguments) {
  LOGI("GLUniform2fv");
  Dart_EnterScope();

  Dart_Handle locationHandle =
      HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t location;
  HandleError(Dart_IntegerToInt64(locationHandle, &location));

  Dart_Handle argHandle = HandleError(Dart_GetNativeArgument(arguments, 1));

  if (Dart_IsList(argHandle)) {
    int len;
    HandleError(Dart_ListLength(argHandle, &len));
    GLfloat* list = new GLfloat[len];
    for (int i = 0; i < len; i++) {
      Dart_Handle vHandle = Dart_ListGetAt(argHandle, i);
      double v;
      HandleError(Dart_DoubleValue(vHandle, &v));
      list[i] = v;
    }
    glUniform2fv(location, len / 2, list);
    delete [] list;
    CheckGLError("glUniform2fv");
  }
  Dart_ExitScope();
}

void GLUniform3fv(Dart_NativeArguments arguments) {
  LOGI("GLUniform3fv");
  Dart_EnterScope();

  Dart_Handle locationHandle =
      HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t location;
  HandleError(Dart_IntegerToInt64(locationHandle, &location));

  Dart_Handle argHandle = HandleError(Dart_GetNativeArgument(arguments, 1));

  if (Dart_IsList(argHandle)) {
    int len;
    HandleError(Dart_ListLength(argHandle, &len));
    GLfloat* list = new GLfloat[len];
    for (int i = 0; i < len; i++) {
      Dart_Handle vHandle = Dart_ListGetAt(argHandle, i);
      double v;
      HandleError(Dart_DoubleValue(vHandle, &v));
      list[i] = v;
    }
    glUniform3fv(location, len / 3, list);
    delete [] list;
    CheckGLError("glUniform3fv");
  }
  Dart_ExitScope();
}

void GLUniform4fv(Dart_NativeArguments arguments) {
  LOGI("In GLUniform4fv");
  Dart_EnterScope();

  Dart_Handle locationHandle =
      HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t location;
  HandleError(Dart_IntegerToInt64(locationHandle, &location));

  Dart_Handle argHandle = HandleError(Dart_GetNativeArgument(arguments, 1));

  if (Dart_IsList(argHandle)) {
    int len;
    HandleError(Dart_ListLength(argHandle, &len));
    GLfloat* list = new GLfloat[len];
    for (int i = 0; i < len; i++) {
      Dart_Handle vHandle = Dart_ListGetAt(argHandle, i);
      double v;
      HandleError(Dart_DoubleValue(vHandle, &v));
      list[i] = v;
    }
    glUniform4fv(location, len / 4, list);
    delete [] list;
    CheckGLError("glUniform4fv");
  }
  Dart_ExitScope();
}

void GLViewport(Dart_NativeArguments arguments) {
  LOGI("GLViewport");
  Dart_EnterScope();

  Dart_Handle xHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t x;
  HandleError(Dart_IntegerToInt64(xHandle, &x));

  Dart_Handle yHandle = HandleError(Dart_GetNativeArgument(arguments, 1));
  int64_t y;
  HandleError(Dart_IntegerToInt64(yHandle, &y));

  Dart_Handle widthHandle = HandleError(Dart_GetNativeArgument(arguments, 2));
  int64_t width;
  HandleError(Dart_IntegerToInt64(widthHandle, &width));

  Dart_Handle heightHandle = HandleError(Dart_GetNativeArgument(arguments, 3));
  int64_t height;
  HandleError(Dart_IntegerToInt64(heightHandle, &height));

  LOGI("Dimensions: [%d, %d, %d, %d]",
       static_cast<int>(x),
       static_cast<int>(y),
       static_cast<int>(width),
       static_cast<int>(height));

  glViewport(x, y, width, height);
  CheckGLError("glViewPort");
  Dart_ExitScope();
}

void GLVertexAttribPointer(Dart_NativeArguments arguments) {
  LOGI("GLVertexAttribPointer");
  Dart_EnterScope();

  Dart_Handle indexHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t index;
  HandleError(Dart_IntegerToInt64(indexHandle, &index));

  Dart_Handle sizeHandle = HandleError(Dart_GetNativeArgument(arguments, 1));
  int64_t size;
  HandleError(Dart_IntegerToInt64(sizeHandle, &size));

  Dart_Handle typeHandle = HandleError(Dart_GetNativeArgument(arguments, 2));
  int64_t type;
  HandleError(Dart_IntegerToInt64(typeHandle, &type));

  Dart_Handle normalizedHandle =
      HandleError(Dart_GetNativeArgument(arguments, 3));
  bool normalized;
  HandleError(Dart_BooleanValue(normalizedHandle, &normalized));

  Dart_Handle strideHandle = HandleError(Dart_GetNativeArgument(arguments, 4));
  int64_t stride;
  HandleError(Dart_IntegerToInt64(strideHandle, &stride));

  Dart_Handle pointerHandle = HandleError(Dart_GetNativeArgument(arguments, 5));
  int64_t pointerValue;
  HandleError(Dart_IntegerToInt64(pointerHandle, &pointerValue));
  const void* pointer;
  pointer = const_cast<const void*>(reinterpret_cast<void*>(pointerValue));

  glVertexAttribPointer(index, size, type, normalized, stride, pointer);
  CheckGLError("glVertexAttribPointer");
  Dart_ExitScope();
}

void GLClearColor(Dart_NativeArguments arguments) {
  LOGI("GLClearColor");
  Dart_EnterScope();

  Dart_Handle redHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  double red;
  HandleError(Dart_DoubleValue(redHandle, &red));

  Dart_Handle greenHandle = HandleError(Dart_GetNativeArgument(arguments, 1));
  double green;
  HandleError(Dart_DoubleValue(greenHandle, &green));

  Dart_Handle blueHandle = HandleError(Dart_GetNativeArgument(arguments, 2));
  double blue;
  HandleError(Dart_DoubleValue(blueHandle, &blue));

  Dart_Handle alphaHandle = HandleError(Dart_GetNativeArgument(arguments, 3));
  double alpha;
  HandleError(Dart_DoubleValue(alphaHandle, &alpha));

  glClearColor(red, green, blue, alpha);
  CheckGLError("glClearColor");
  Dart_ExitScope();
}

void GLClearDepth(Dart_NativeArguments arguments) {
  LOGI("GLClearDepth");
  Dart_EnterScope();

  Dart_Handle depthHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  double depth;
  HandleError(Dart_DoubleValue(depthHandle, &depth));

  glClearDepthf(depth);
  CheckGLError("glClearDepthf");
  Dart_ExitScope();
}

void GLClear(Dart_NativeArguments arguments) {
  LOGI("GLClear");
  Dart_EnterScope();
  Dart_Handle maskHandle = HandleError(Dart_GetNativeArgument(arguments, 0));
  int64_t mask;
  HandleError(Dart_IntegerToInt64(maskHandle, &mask));
  glClear(mask);
  CheckGLError("glClear");
  Dart_ExitScope();
}

void GLArrayBuffer(Dart_NativeArguments arguments) {
  LOGI("GLArrayBuffer");
  Dart_EnterScope();
  Dart_Handle result = HandleError(Dart_NewInteger(GL_ARRAY_BUFFER));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLColorBufferBit(Dart_NativeArguments arguments) {
  LOGI("GLColorBuffer");
  Dart_EnterScope();
  Dart_Handle result = HandleError(Dart_NewInteger(GL_COLOR_BUFFER_BIT));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLCompileStatus(Dart_NativeArguments arguments) {
  LOGI("GLCompileStatus");
  Dart_EnterScope();
  Dart_Handle result = HandleError(Dart_NewInteger(GL_COMPILE_STATUS));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLDepthBufferBit(Dart_NativeArguments arguments) {
  LOGI("GLDepthBufferBit");
  Dart_EnterScope();
  Dart_Handle result = HandleError(Dart_NewInteger(GL_DEPTH_BUFFER_BIT));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLFloat(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  Dart_Handle result = HandleError(Dart_NewInteger(GL_FLOAT));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLFragmentShader(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  Dart_Handle result = HandleError(Dart_NewInteger(GL_FRAGMENT_SHADER));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLLinkStatus(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  Dart_Handle result = HandleError(Dart_NewInteger(GL_LINK_STATUS));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLStaticDraw(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  Dart_Handle result = HandleError(Dart_NewInteger(GL_STATIC_DRAW));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLTriangleStrip(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  Dart_Handle result = HandleError(Dart_NewInteger(GL_TRIANGLE_STRIP));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLTriangles(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  Dart_Handle result = HandleError(Dart_NewInteger(GL_TRIANGLES));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLTrue(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  Dart_Handle result = HandleError(Dart_NewInteger(GL_TRUE));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

void GLVertexShader(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  Dart_Handle result = HandleError(Dart_NewInteger(GL_VERTEX_SHADER));
  Dart_SetReturnValue(arguments, result);
  Dart_ExitScope();
}

uint8_t* RandomArray(int seed, int length) {
  if (length <= 0 || length > 10000000) return NULL;
  uint8_t* values = reinterpret_cast<uint8_t*>(malloc(length));
  if (NULL == values) return NULL;
  srand(seed);
  for (int i = 0; i < length; ++i) {
    values[i] = rand() % 256;
  }
  return values;
}

void WrappedRandomArray(Dart_Port dest_port_id,
                        Dart_Port reply_port_id,
                        Dart_CObject* message) {
  if (message->type == Dart_CObject::kArray &&
      2 == message->value.as_array.length) {
    // Use .as_array and .as_int32 to access the data in the Dart_CObject.
    Dart_CObject* param0 = message->value.as_array.values[0];
    Dart_CObject* param1 = message->value.as_array.values[1];
    if (param0->type == Dart_CObject::kInt32 &&
        param1->type == Dart_CObject::kInt32) {
      int length = param0->value.as_int32;
      int seed = param1->value.as_int32;

      uint8_t* values = RandomArray(seed, length);

      if (values != NULL) {
        Dart_CObject result;
        result.type = Dart_CObject::kUint8Array;
        result.value.as_byte_array.values = values;
        result.value.as_byte_array.length = length;
        Dart_PostCObject(reply_port_id, &result);
        free(values);
        // It is OK that result is destroyed when function exits.
        // Dart_PostCObject has copied its data.
        return;
      }
    }
  }
  Dart_CObject result;
  result.type = Dart_CObject::kNull;
  Dart_PostCObject(reply_port_id, &result);
}

void RandomArrayServicePort(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  Dart_SetReturnValue(arguments, Dart_Null());
  Dart_Port service_port =
      Dart_NewNativePort("RandomArrayService", WrappedRandomArray, true);
  if (service_port != ((Dart_Port)0)) {
    Dart_Handle send_port = HandleError(Dart_NewSendPort(service_port));
    Dart_SetReturnValue(arguments, send_port);
  }
  Dart_ExitScope();
}

void PlayBackground(Dart_NativeArguments arguments) {
  LOGI("PlayBackground");
  Dart_EnterScope();
  const char* what = GetStringArg(arguments, 0);
  PlayBackground(what);
  Dart_ExitScope();
}

void StopBackground(Dart_NativeArguments arguments) {
  LOGI("StopBackground");
  Dart_EnterScope();
  StopBackground();
  Dart_ExitScope();
}

struct FunctionLookup {
  const char* name;
  Dart_NativeFunction function;
};

FunctionLookup function_list[] = {
    {"Log", Log},
    {"SystemRand", SystemRand},
    {"SystemSrand", SystemSrand},
    {"EGLSwapBuffers", EGLSwapBuffers},
    {"GLAttachShader", GLAttachShader},
    {"GLBindBuffer", GLBindBuffer},
    {"GLBufferData", GLBufferData},
    {"GLClear", GLClear},
    {"GLClearColor", GLClearColor},
    {"GLClearDepth", GLClearDepth},
    {"GLCompileShader", GLCompileShader},
    {"GLCreateBuffer", GLCreateBuffer},
    {"GLCreateProgram", GLCreateProgram},
    {"GLCreateShader", GLCreateShader},
    {"GLDrawArrays", GLDrawArrays},
    {"GLEnableVertexAttribArray", GLEnableVertexAttribArray},
    {"GLGetAttribLocation", GLGetAttribLocation},
    {"GLGetError", GLGetError},
    {"GLGetProgramParameter", GLGetProgramParameter},
    {"GLGetShaderParameter", GLGetShaderParameter},
    {"GLGetUniformLocation", GLGetUniformLocation},
    {"GLLinkProgram", GLLinkProgram},
    {"GLShaderSource", GLShaderSource},
    {"GLUniform1f", GLUniform1f},
    {"GLUniform2f", GLUniform2f},
    {"GLUniform3f", GLUniform3f},
    {"GLUniform4f", GLUniform4f},
    {"GLUniform1i", GLUniform1i},
    {"GLUniform2i", GLUniform2i},
    {"GLUniform3i", GLUniform3i},
    {"GLUniform4i", GLUniform4i},
    {"GLUniform1fv", GLUniform1fv},
    {"GLUniform2fv", GLUniform2fv},
    {"GLUniform3fv", GLUniform3fv},
    {"GLUniform4fv", GLUniform4fv},
    {"GLUniform1iv", GLUniform1iv},
    {"GLUniform2iv", GLUniform2iv},
    {"GLUniform3iv", GLUniform3iv},
    {"GLUniform4iv", GLUniform4iv},
    {"GLUseProgram", GLUseProgram},
    {"GLVertexAttribPointer", GLVertexAttribPointer},
    {"GLViewport", GLViewport},
    {"GLArrayBuffer", GLArrayBuffer},
    {"GLColorBufferBit", GLColorBufferBit},
    {"GLCompileStatus", GLCompileStatus},
    {"GLDepthBufferBit", GLDepthBufferBit},
    {"GLFloat", GLFloat},
    {"GLFragmentShader", GLFragmentShader},
    {"GLLinkStatus", GLLinkStatus},
    {"GLTriangleStrip", GLTriangleStrip},
    {"GLTriangles", GLTriangles},
    {"GLTrue", GLTrue},
    {"GLStaticDraw", GLStaticDraw},
    {"GLVertexShader", GLVertexShader},
    {"GLGetShaderInfoLog", GLGetShaderInfoLog},
    {"GLGetProgramInfoLog", GLGetProgramInfoLog},
    {"RandomArray_ServicePort", RandomArrayServicePort},

    // Audio support.
    {"PlayBackground", PlayBackground},
    {"StopBackground", StopBackground},

    {NULL, NULL}};

Dart_NativeFunction ResolveName(Dart_Handle name, int argc) {
  if (!Dart_IsString(name)) return NULL;
  Dart_NativeFunction result = NULL;
  Dart_EnterScope();
  const char* cname;
  HandleError(Dart_StringToCString(name, &cname));
  for (int i = 0; function_list[i].name != NULL; ++i) {
    if (strcmp(function_list[i].name, cname) == 0) {
      result = function_list[i].function;
      break;
    }
  }
  Dart_ExitScope();
  return result;
}
