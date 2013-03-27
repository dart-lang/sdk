// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/common/extension.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "embedders/openglui/common/canvas_context.h"
#include "embedders/openglui/common/image_cache.h"
#include "embedders/openglui/common/graphics_handler.h"
#include "embedders/openglui/common/log.h"
#include "embedders/openglui/common/opengl.h"
#include "include/dart_api.h"

Dart_Handle HandleError(Dart_Handle handle) {
  if (Dart_IsError(handle)) Dart_PropagateError(handle);
  return handle;
}

void CheckGLError(const char *function) {
  int error = glGetError();
  if (error != GL_NO_ERROR) {
    if (error == GL_INVALID_ENUM) {
      LOGE("%s: An unacceptable value is given for an enumerated argument.",
           function);
    } else if (error == GL_INVALID_VALUE) {
      LOGE("%s: A numeric argument is out of range.", function);
    } else if (error == GL_INVALID_OPERATION) {
      LOGE("%s: The specified operation is not allowed in the current state.",
           function);
    } else if (error == GL_INVALID_FRAMEBUFFER_OPERATION) {
      LOGE("%s: The framebuffer object is not complete.", function);
    } else if (error == GL_OUT_OF_MEMORY) {
      LOGE("%s: There is not enough memory left to execute the command.",
          function);
    } else {
      LOGE("ERROR!: %s returns %d", function, error);
    }
  }
}

const char* GetArgAsString(Dart_NativeArguments arguments, int idx) {
  Dart_Handle handle = HandleError(Dart_GetNativeArgument(arguments, idx));
  uint8_t* str;
  intptr_t length;
  HandleError(Dart_StringLength(handle, &length));
  HandleError(Dart_StringToUTF8(handle, &str, &length));
  str[length] = 0;
  return  const_cast<const char*>(reinterpret_cast<char*>(str));
}

double GetArgAsDouble(Dart_NativeArguments arguments, int index) {
  Dart_Handle handle = HandleError(Dart_GetNativeArgument(arguments, index));
  if (Dart_IsDouble(handle)) {
    double v;
    HandleError(Dart_DoubleValue(handle, &v));
    return v;
  }
  if (Dart_IsInteger(handle)) {
    int64_t v;
    HandleError(Dart_IntegerToInt64(handle, &v));
    return static_cast<double>(v);
  }
  LOGE("Argument at index %d has non-numeric type", index);
  Dart_ThrowException(Dart_NewStringFromCString("Numeric argument expected."));
  return 0;
}

int64_t GetArgAsInt(Dart_NativeArguments arguments, int index) {
  Dart_Handle handle = HandleError(Dart_GetNativeArgument(arguments, index));
  if (Dart_IsDouble(handle)) {
    double v;
    HandleError(Dart_DoubleValue(handle, &v));
    return static_cast<int64_t>(v);
  }
  if (Dart_IsInteger(handle)) {
    int64_t v;
    HandleError(Dart_IntegerToInt64(handle, &v));
    return v;
  }
  LOGE("Argument at index %d has non-numeric type", index);
  Dart_ThrowException(Dart_NewStringFromCString("Numeric argument expected."));
  return 0;
}

bool GetArgAsBool(Dart_NativeArguments arguments, int index) {
  Dart_Handle handle = HandleError(Dart_GetNativeArgument(arguments, index));
  if (Dart_IsBoolean(handle)) {
    bool v;
    HandleError(Dart_BooleanValue(handle, &v));
    return v;
  }
  LOGI("Argument at index %d has non-Boolean type", index);
  Dart_ThrowException(Dart_NewStringFromCString("Boolean argument expected."));
  return false;
}

int GetListLength(Dart_NativeArguments arguments, int index,
    Dart_Handle& argHandle) {
  argHandle = HandleError(Dart_GetNativeArgument(arguments, index));
  if (Dart_IsList(argHandle)) {
    intptr_t len;
    HandleError(Dart_ListLength(argHandle, &len));
    return len;
  }
  LOGI("Argument at index %d has non-List type", index);
  Dart_ThrowException(Dart_NewStringFromCString("List argument expected."));
  return -1;
}

GLint* GetArgsAsGLintList(Dart_NativeArguments arguments, int index,
                          int* len_out) {
  Dart_Handle argHandle;
  int len = GetListLength(arguments, index, argHandle);
  if (len < 0) return NULL;
  GLint* list = new GLint[len];
  for (int i = 0; i < len; i++) {
    Dart_Handle vHandle = Dart_ListGetAt(argHandle, i);
    int64_t v;
    HandleError(Dart_IntegerToInt64(vHandle, &v));
    list[i] = v;
  }
  *len_out = len;
  return list;
}

GLfloat* GetArgsAsFloatList(Dart_NativeArguments arguments, int index,
                            int* len_out) {
  Dart_Handle argHandle;
  int len = GetListLength(arguments, index, argHandle);
  if (len < 0) return NULL;
  GLfloat* list = new GLfloat[len];
  for (int i = 0; i < len; i++) {
    Dart_Handle vHandle = Dart_ListGetAt(argHandle, i);
    double v;
    HandleError(Dart_DoubleValue(vHandle, &v));
    list[i] = v;
  }
  *len_out = len;
  return list;
}

char** GetArgsAsStringList(Dart_NativeArguments arguments, int index,
                            int* len_out) {
  Dart_Handle argHandle;
  int len = GetListLength(arguments, index, argHandle);
  if (len < 0) return NULL;
  char** list = new char*[len];
  for (int i = 0; i < len; i++) {
    Dart_Handle vHandle = Dart_ListGetAt(argHandle, i);
    uint8_t* str;
    intptr_t length;
    HandleError(Dart_StringLength(vHandle, &length));
    HandleError(Dart_StringToUTF8(vHandle, &str, &length));
    str[length] = 0;
    list[i] = reinterpret_cast<char*>(str);
  }
  *len_out = len;
  return list;
}

void SetBoolReturnValue(Dart_NativeArguments arguments, bool b) {
  Dart_Handle result = HandleError(Dart_NewBoolean(b));
  Dart_SetReturnValue(arguments, result);
}

void SetIntReturnValue(Dart_NativeArguments arguments, int v) {
  Dart_Handle result = HandleError(Dart_NewInteger(v));
  Dart_SetReturnValue(arguments, result);
}

void SetDoubleReturnValue(Dart_NativeArguments arguments, double v) {
  Dart_Handle result = HandleError(Dart_NewDouble(v));
  Dart_SetReturnValue(arguments, result);
}

void SetStringReturnValue(Dart_NativeArguments arguments, const char* s) {
  Dart_Handle result = HandleError(Dart_NewStringFromCString(s));
  Dart_SetReturnValue(arguments, result);
}

void Log(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  LOGI("%s", GetArgAsString(arguments, 0));
  Dart_ExitScope();
}

void LogError(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  LOGE("%s", GetArgAsString(arguments, 0));
  Dart_ExitScope();
}

void SystemRand(Dart_NativeArguments arguments) {
  Dart_EnterScope();
  SetIntReturnValue(arguments, rand());
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
  SetBoolReturnValue(arguments, success);
  Dart_ExitScope();
}

void GetDeviceScreenWidth(Dart_NativeArguments arguments) {
  LOGI("GetDeviceScreenWidth");
  Dart_EnterScope();
  SetIntReturnValue(arguments, graphics->width());
  Dart_ExitScope();
}

void GetDeviceScreenHeight(Dart_NativeArguments arguments) {
  LOGI("GetDeviceScreenHeight");
  Dart_EnterScope();
  SetIntReturnValue(arguments, graphics->height());
  Dart_ExitScope();
}

void SwapBuffers(Dart_NativeArguments arguments) {
  LOGI("SwapBuffers");
  Dart_EnterScope();
  GLSwapBuffers();
  CheckGLError("GLSwapBuffers");
  Dart_ExitScope();
}

void GLAttachShader(Dart_NativeArguments arguments) {
  LOGI("GLAttachShader");
  Dart_EnterScope();

  int64_t program = GetArgAsInt(arguments, 0);
  int64_t shader = GetArgAsInt(arguments, 1);

  glAttachShader(program, shader);
  CheckGLError("glAttachShader");
  Dart_ExitScope();
}

void GLBindBuffer(Dart_NativeArguments arguments) {
  LOGI("GLBindBuffer");
  Dart_EnterScope();

  int64_t target = GetArgAsInt(arguments, 0);
  int64_t buffer = GetArgAsInt(arguments, 1);

  glBindBuffer(target, buffer);
  CheckGLError("glBindBuffer");
  Dart_ExitScope();
}

void GLBufferData(Dart_NativeArguments arguments) {
  LOGI("GLBufferData");
  Dart_EnterScope();

  int64_t target = GetArgAsInt(arguments, 0);

  Dart_Handle dataHandle = HandleError(Dart_GetNativeArgument(arguments, 1));
  intptr_t size;
  HandleError(Dart_ListLength(dataHandle, &size));

  LOGI("Size: %d", static_cast<int>(size));

  // TODO(vsm): No guarantee that this is a float!
  float* data = new float[size];
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

  glBufferData(target, size * sizeof(data[0]), data, usage);
  CheckGLError("glBufferData");
  delete[] data;
  Dart_ExitScope();
}

void GLCompileShader(Dart_NativeArguments arguments) {
  LOGI("GLCompileShader");
  Dart_EnterScope();
  int64_t shader = GetArgAsInt(arguments, 0);
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
  SetIntReturnValue(arguments, buffer);
  Dart_ExitScope();
}

void GLCreateProgram(Dart_NativeArguments arguments) {
  LOGI("GLCreateProgram");
  Dart_EnterScope();
  int64_t program = glCreateProgram();
  CheckGLError("glCreateProgram");
  SetIntReturnValue(arguments, program);
  Dart_ExitScope();
}

void GLCreateShader(Dart_NativeArguments arguments) {
  LOGI("GLCreateShader");
  Dart_EnterScope();
  int64_t type = GetArgAsInt(arguments, 0);
  int64_t shader = glCreateShader((GLenum)type);
  CheckGLError("glCreateShader");
  SetIntReturnValue(arguments, shader);
  Dart_ExitScope();
}

void GLDrawArrays(Dart_NativeArguments arguments) {
  LOGI("GLDrawArrays");
  Dart_EnterScope();

  int64_t mode = GetArgAsInt(arguments, 0);
  int64_t first = GetArgAsInt(arguments, 1);
  int64_t count = GetArgAsInt(arguments, 2);

  glDrawArrays(mode, first, count);
  CheckGLError("glDrawArrays");
  Dart_ExitScope();
  LOGI("Done GLDrawArrays");
}

void GLEnableVertexAttribArray(Dart_NativeArguments arguments) {
  LOGI("GLEnableVertexAttribArray");
  Dart_EnterScope();

  int64_t location = GetArgAsInt(arguments, 0);

  glEnableVertexAttribArray(location);
  CheckGLError("glEnableVertexAttribArray");
  Dart_ExitScope();
}

void GLGetAttribLocation(Dart_NativeArguments arguments) {
  LOGI("GLGetAttribLocation");
  Dart_EnterScope();

  int64_t program = GetArgAsInt(arguments, 0);

  Dart_Handle nameHandle = HandleError(Dart_GetNativeArgument(arguments, 1));
  intptr_t length;
  HandleError(Dart_StringLength(nameHandle, &length));
  uint8_t* str;
  HandleError(Dart_StringToUTF8(nameHandle, &str, &length));
  str[length] = 0;

  int64_t location = glGetAttribLocation(program,
      const_cast<const GLchar*>(reinterpret_cast<GLchar*>(str)));
  CheckGLError("glGetAttribLocation");
  SetIntReturnValue(arguments, location);
  Dart_ExitScope();
}

void GLGetError(Dart_NativeArguments arguments) {
  LOGI("GLGetError");
  Dart_EnterScope();
  SetIntReturnValue(arguments, glGetError());
  Dart_ExitScope();
}

void GLGetProgramParameter(Dart_NativeArguments arguments) {
  LOGI("GLGetProgramParameter");
  Dart_EnterScope();

  int64_t program = GetArgAsInt(arguments, 0);
  int64_t param = GetArgAsInt(arguments, 1);

  GLint value = -1;
  glGetProgramiv(program, param, &value);
  CheckGLError("glGetProgramiv");

  SetIntReturnValue(arguments, value);
  Dart_ExitScope();
}

void GLGetShaderParameter(Dart_NativeArguments arguments) {
  LOGI("GLGetShaderParameter");
  Dart_EnterScope();

  int64_t shader = GetArgAsInt(arguments, 0);
  int64_t param = GetArgAsInt(arguments, 1);

  GLint value = -1;
  glGetShaderiv((GLuint)shader, (GLenum)param, &value);
  CheckGLError("glGetShaderiv");

  SetIntReturnValue(arguments, value);
  Dart_ExitScope();
}

void GLGetShaderInfoLog(Dart_NativeArguments arguments) {
  LOGI("GLGetShaderInfoLog");
  Dart_EnterScope();

  int64_t shader = GetArgAsInt(arguments, 0);

  GLint infoLogLength = 0;
  glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLogLength);
  GLchar* strInfoLog = new GLchar[infoLogLength + 1];
  glGetShaderInfoLog(shader, infoLogLength, NULL, strInfoLog);
  strInfoLog[infoLogLength] = 0;

  SetStringReturnValue(arguments, strInfoLog);
  Dart_ExitScope();
  delete[] strInfoLog;
}

void GLGetProgramInfoLog(Dart_NativeArguments arguments) {
  LOGI("GLGetProgramInfoLog");
  Dart_EnterScope();

  int64_t program = GetArgAsInt(arguments, 0);

  GLint infoLogLength;
  glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLogLength);

  GLchar* strInfoLog = new GLchar[infoLogLength + 1];
  glGetProgramInfoLog(program, infoLogLength, NULL, strInfoLog);
  strInfoLog[infoLogLength] = 0;

  SetStringReturnValue(arguments, strInfoLog);
  Dart_ExitScope();
  delete[] strInfoLog;
}

void GLGetUniformLocation(Dart_NativeArguments arguments) {
  LOGI("GLGetUniformLocation");
  Dart_EnterScope();

  int64_t program = GetArgAsInt(arguments, 0);


  Dart_Handle nameHandle = HandleError(Dart_GetNativeArgument(arguments, 1));
  intptr_t length;
  HandleError(Dart_StringLength(nameHandle, &length));
  uint8_t* str;
  HandleError(Dart_StringToUTF8(nameHandle, &str, &length));
  str[length] = 0;

  int64_t location = glGetUniformLocation(program,
      const_cast<const GLchar*>(reinterpret_cast<GLchar*>(str)));
  CheckGLError("glGetUniformLocation");
  SetIntReturnValue(arguments, location);
  Dart_ExitScope();
}

void GLLinkProgram(Dart_NativeArguments arguments) {
  LOGI("GLLinkProgram");
  Dart_EnterScope();
  int64_t program = GetArgAsInt(arguments, 0);
  glLinkProgram(program);
  CheckGLError("glLinkProgram");
  Dart_ExitScope();
}

void GLShaderSource(Dart_NativeArguments arguments) {
  LOGI("GLShaderSource");
  Dart_EnterScope();

  int64_t shader = GetArgAsInt(arguments, 0);

  Dart_Handle sourceHandle = HandleError(Dart_GetNativeArgument(arguments, 1));
  intptr_t length[1];
  HandleError(Dart_StringLength(sourceHandle, length));
  LOGI("Source length is %d", static_cast<int>(length[0]));
  uint8_t* str[1];
  HandleError(Dart_StringToUTF8(sourceHandle, &str[0], length));
  LOGI("Converted length is %d", static_cast<int>(length[0]));
  str[0][*length] = 0;

  LOGI("Source: %s",
      const_cast<const GLchar*>(reinterpret_cast<GLchar*>(str[0])));
  glShaderSource(shader, 1,
      const_cast<const GLchar**>(reinterpret_cast<GLchar**>(str)), NULL);
  CheckGLError("glShaderSource");
  Dart_ExitScope();
}

void GLUseProgram(Dart_NativeArguments arguments) {
  LOGI("GLUseProgram");
  Dart_EnterScope();
  int64_t program = GetArgAsInt(arguments, 0);
  glUseProgram(program);
  CheckGLError("glUseProgram");
  Dart_ExitScope();
}

void GLUniform1i(Dart_NativeArguments arguments) {
  LOGI("GLUniform1i");
  Dart_EnterScope();
  int64_t location = GetArgAsInt(arguments, 0);
  int64_t v0 = GetArgAsInt(arguments, 1);
  glUniform1i(location, v0);
  CheckGLError("glUniform1i");
  Dart_ExitScope();
}

void GLUniform2i(Dart_NativeArguments arguments) {
  LOGI("GLUniform2i");
  Dart_EnterScope();
  int64_t location = GetArgAsInt(arguments, 0);
  int64_t v0 = GetArgAsInt(arguments, 1);
  int64_t v1 = GetArgAsInt(arguments, 2);
  glUniform2i(location, v0, v1);
  CheckGLError("glUniform2i");
  Dart_ExitScope();
}

void GLUniform3i(Dart_NativeArguments arguments) {
  LOGI("GLUniform3i");
  Dart_EnterScope();
  int64_t location = GetArgAsInt(arguments, 0);
  int64_t v0 = GetArgAsInt(arguments, 1);
  int64_t v1 = GetArgAsInt(arguments, 2);
  int64_t v2 = GetArgAsInt(arguments, 3);
  glUniform3i(location, v0, v1, v2);
  CheckGLError("glUniform3i");
  Dart_ExitScope();
}

void GLUniform4i(Dart_NativeArguments arguments) {
  LOGI("GLUniform4i");
  Dart_EnterScope();
  int64_t location = GetArgAsInt(arguments, 0);
  int64_t v0 = GetArgAsInt(arguments, 1);
  int64_t v1 = GetArgAsInt(arguments, 2);
  int64_t v2 = GetArgAsInt(arguments, 3);
  int64_t v3 = GetArgAsInt(arguments, 4);
  glUniform4i(location, v0, v1, v2, v3);
  CheckGLError("glUniform4i");
  Dart_ExitScope();
}

void GLUniform1f(Dart_NativeArguments arguments) {
  LOGI("GLUniform1f");
  Dart_EnterScope();
  int64_t location = GetArgAsInt(arguments, 0);
  double v0 = GetArgAsDouble(arguments, 1);
  glUniform1f(location, v0);
  CheckGLError("glUniform1f");
  Dart_ExitScope();
}

void GLUniform2f(Dart_NativeArguments arguments) {
  LOGI("GLUniform2f");
  Dart_EnterScope();
  int64_t location = GetArgAsInt(arguments, 0);
  double v0 = GetArgAsDouble(arguments, 1);
  double v1 = GetArgAsDouble(arguments, 2);
  glUniform2f(location, v0, v1);
  CheckGLError("glUniform2f");
  Dart_ExitScope();
}

void GLUniform3f(Dart_NativeArguments arguments) {
  LOGI("GLUniform3f");
  Dart_EnterScope();
  int64_t location = GetArgAsInt(arguments, 0);
  double v0 = GetArgAsDouble(arguments, 1);
  double v1 = GetArgAsDouble(arguments, 2);
  double v2 = GetArgAsDouble(arguments, 3);
  glUniform3f(location, v0, v1, v2);
  CheckGLError("glUniform3f");
  Dart_ExitScope();
}

void GLUniform4f(Dart_NativeArguments arguments) {
  LOGI("GLUniform4f");
  Dart_EnterScope();
  int64_t location = GetArgAsInt(arguments, 0);
  double v0 = GetArgAsDouble(arguments, 1);
  double v1 = GetArgAsDouble(arguments, 2);
  double v2 = GetArgAsDouble(arguments, 3);
  double v3 = GetArgAsDouble(arguments, 4);
  glUniform4f(location, v0, v1, v2, v3);
  CheckGLError("glUniform4f");
  Dart_ExitScope();
}

void GLUniform1iv(Dart_NativeArguments arguments) {
  LOGI("GLUniform1iv");
  Dart_EnterScope();
  int64_t location = GetArgAsInt(arguments, 0);
  int len;
  GLint* list = GetArgsAsGLintList(arguments, 1, &len);
  if (list != NULL) {
    glUniform1iv(location, len, list);
    delete [] list;
    CheckGLError("glUniform1iv");
  }
  Dart_ExitScope();
}

void GLUniform2iv(Dart_NativeArguments arguments) {
  LOGI("GLUniform2iv");
  Dart_EnterScope();
  int64_t location = GetArgAsInt(arguments, 0);
  int len;
  GLint* list = GetArgsAsGLintList(arguments, 1, &len);
  if (list != NULL) {
    glUniform2iv(location, len / 2, list);
    delete [] list;
    CheckGLError("glUniform2iv");
  }
  Dart_ExitScope();
}

void GLUniform3iv(Dart_NativeArguments arguments) {
  LOGI("GLUniform3iv");
  Dart_EnterScope();
  int64_t location = GetArgAsInt(arguments, 0);
  int len;
  GLint* list = GetArgsAsGLintList(arguments, 1, &len);
  if (list != NULL) {
    glUniform3iv(location, len / 3, list);
    delete [] list;
    CheckGLError("glUniform3iv");
  }
  Dart_ExitScope();
}

void GLUniform4iv(Dart_NativeArguments arguments) {
  LOGI("GLUniform4iv");
  Dart_EnterScope();
  int64_t location = GetArgAsInt(arguments, 0);
  int len;
  GLint* list = GetArgsAsGLintList(arguments, 1, &len);
  if (list != NULL) {
    glUniform1iv(location, len / 4, list);
    delete [] list;
    CheckGLError("glUniform4iv");
  }
  Dart_ExitScope();
}

void GLUniform1fv(Dart_NativeArguments arguments) {
  LOGI("GLUniform1fv");
  Dart_EnterScope();
  int64_t location = GetArgAsInt(arguments, 0);
  int len;
  GLfloat* list = GetArgsAsFloatList(arguments, 1, &len);
  if (list != NULL) {
    glUniform1fv(location, len, list);
    delete [] list;
    CheckGLError("glUniform1fv");
  }
  Dart_ExitScope();
}

void GLUniform2fv(Dart_NativeArguments arguments) {
  LOGI("GLUniform2fv");
  Dart_EnterScope();
  int64_t location = GetArgAsInt(arguments, 0);
  int len;
  GLfloat* list = GetArgsAsFloatList(arguments, 1, &len);
  if (list != NULL) {
    glUniform2fv(location, len / 2, list);
    delete [] list;
    CheckGLError("glUniform2fv");
  }
  Dart_ExitScope();
}

void GLUniform3fv(Dart_NativeArguments arguments) {
  LOGI("GLUniform3fv");
  Dart_EnterScope();
  int64_t location = GetArgAsInt(arguments, 0);
  int len;
  GLfloat* list = GetArgsAsFloatList(arguments, 1, &len);
  if (list != NULL) {
    glUniform3fv(location, len / 3, list);
    delete [] list;
    CheckGLError("glUniform3fv");
  }
  Dart_ExitScope();
}

void GLUniform4fv(Dart_NativeArguments arguments) {
  LOGI("In GLUniform4fv");
  Dart_EnterScope();
  int64_t location = GetArgAsInt(arguments, 0);
  int len;
  GLfloat* list = GetArgsAsFloatList(arguments, 1, &len);
  if (list != NULL) {
    glUniform4fv(location, len / 4, list);
    delete [] list;
    CheckGLError("glUniform4fv");
  }
  Dart_ExitScope();
}

void GLViewport(Dart_NativeArguments arguments) {
  LOGI("GLViewport");
  Dart_EnterScope();
  int64_t x = GetArgAsInt(arguments, 0);
  int64_t y = GetArgAsInt(arguments, 1);
  int64_t width = GetArgAsInt(arguments, 2);
  int64_t height = GetArgAsInt(arguments, 3);
  glViewport(x, y, width, height);
  CheckGLError("glViewPort");
  Dart_ExitScope();
}

void GLVertexAttribPointer(Dart_NativeArguments arguments) {
  LOGI("GLVertexAttribPointer");
  Dart_EnterScope();
  int64_t index = GetArgAsInt(arguments, 0);
  int64_t size = GetArgAsInt(arguments, 1);
  int64_t type = GetArgAsInt(arguments, 2);
  bool normalized = GetArgAsBool(arguments, 3);
  int64_t stride = GetArgAsInt(arguments, 4);

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
  double red = GetArgAsDouble(arguments, 0);
  double green = GetArgAsDouble(arguments, 1);
  double blue = GetArgAsDouble(arguments, 2);
  double alpha = GetArgAsDouble(arguments, 3);
  glClearColor(red, green, blue, alpha);
  CheckGLError("glClearColor");
  Dart_ExitScope();
}

void GLClearDepth(Dart_NativeArguments arguments) {
  LOGI("GLClearDepth");
  Dart_EnterScope();
  double depth = GetArgAsDouble(arguments, 0);
#if defined(__ANDROID__)
  glClearDepthf(depth);
#else
  glClearDepth(depth);
#endif
  CheckGLError("glClearDepth");
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

void ReturnGLIntConstant(Dart_NativeArguments arguments, int c) {
  Dart_EnterScope();
  SetIntReturnValue(arguments, c);
  Dart_ExitScope();
}

void GLArrayBuffer(Dart_NativeArguments arguments) {
  ReturnGLIntConstant(arguments, GL_ARRAY_BUFFER);
}

void GLColorBufferBit(Dart_NativeArguments arguments) {
  ReturnGLIntConstant(arguments, GL_COLOR_BUFFER_BIT);
}

void GLCompileStatus(Dart_NativeArguments arguments) {
  ReturnGLIntConstant(arguments, GL_COMPILE_STATUS);
}

void GLDeleteStatus(Dart_NativeArguments arguments) {
  ReturnGLIntConstant(arguments, GL_DELETE_STATUS);
}

void GLDepthBufferBit(Dart_NativeArguments arguments) {
  ReturnGLIntConstant(arguments, GL_DEPTH_BUFFER_BIT);
}

void GLFloat(Dart_NativeArguments arguments) {
  ReturnGLIntConstant(arguments, GL_FLOAT);
}

void GLFragmentShader(Dart_NativeArguments arguments) {
  ReturnGLIntConstant(arguments, GL_FRAGMENT_SHADER);
}

void GLLinkStatus(Dart_NativeArguments arguments) {
  ReturnGLIntConstant(arguments, GL_LINK_STATUS);
}

void GLStaticDraw(Dart_NativeArguments arguments) {
  ReturnGLIntConstant(arguments, GL_STATIC_DRAW);
}

void GLTriangleStrip(Dart_NativeArguments arguments) {
  ReturnGLIntConstant(arguments, GL_TRIANGLE_STRIP);
}

void GLTriangles(Dart_NativeArguments arguments) {
  ReturnGLIntConstant(arguments, GL_TRIANGLES);
}

void GLTrue(Dart_NativeArguments arguments) {
  ReturnGLIntConstant(arguments, GL_TRUE);
}

void GLValidateStatus(Dart_NativeArguments arguments) {
  ReturnGLIntConstant(arguments, GL_VALIDATE_STATUS);
}

void GLVertexShader(Dart_NativeArguments arguments) {
  ReturnGLIntConstant(arguments, GL_VERTEX_SHADER);
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
  const char* what = GetArgAsString(arguments, 0);
  int rtn = PlayBackgroundSound(what);
  SetIntReturnValue(arguments, rtn);
  Dart_ExitScope();
}

void StopBackground(Dart_NativeArguments arguments) {
  LOGI("StopBackground");
  Dart_EnterScope();
  StopBackgroundSound();
  Dart_ExitScope();
}

void LoadSample(Dart_NativeArguments arguments) {
  LOGI("LoadSample");
  Dart_EnterScope();
  const char* what = GetArgAsString(arguments, 0);
  int rtn = LoadSoundSample(what);
  SetIntReturnValue(arguments, rtn);
  Dart_ExitScope();
}

void PlaySample(Dart_NativeArguments arguments) {
  LOGI("PlaySample");
  Dart_EnterScope();
  const char* what = GetArgAsString(arguments, 0);
  int rtn = PlaySoundSample(what);
  SetIntReturnValue(arguments, rtn);
  Dart_ExitScope();
}

// 2D Canvas.

CanvasContext* display_context = NULL;

void C2DCreateNativeContext(Dart_NativeArguments arguments) {
  LOGI("In C2DCreateNativeContext");
  Dart_EnterScope();

  int handle = GetArgAsInt(arguments, 0);
  int width = GetArgAsInt(arguments, 1);
  int height = GetArgAsInt(arguments, 2);

  CanvasContext* rtn = new CanvasContext(handle, width, height);
  if (display_context == NULL) {
    LOGI("Created display context");
    display_context = rtn;
  }
  Dart_ExitScope();
  LOGI("Out C2DCreateNativeContext");
}

void C2DSetWidth(Dart_NativeArguments arguments) {
  LOGI("In C2DSetWidth");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  int width = GetArgAsInt(arguments, 1);
  SetIntReturnValue(arguments, Context2D(handle)->setWidth(width));
  Dart_ExitScope();
  LOGI("Out C2DSetWidth");
}

void C2DSetHeight(Dart_NativeArguments arguments) {
  LOGI("In C2DSetHeight");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  int height = GetArgAsInt(arguments, 1);
  SetIntReturnValue(arguments, Context2D(handle)->setHeight(height));
  Dart_ExitScope();
  LOGI("Out C2DSetHeight");
}

void C2DSetGlobalAlpha(Dart_NativeArguments arguments) {
  LOGI("In C2DSetGlobalAlpha");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double alpha = GetArgAsDouble(arguments, 1);
  alpha = MIN(1.0, MAX(alpha, 0.0));
  Context2D(handle)->setGlobalAlpha(alpha);
  SetDoubleReturnValue(arguments, alpha);
  Dart_ExitScope();
  LOGI("Out C2DSetGlobalAlpha");
}

void C2DSetFillStyle(Dart_NativeArguments arguments) {
  LOGI("In C2DSetFillStyle");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  const char* color = GetArgAsString(arguments, 1);
  Context2D(handle)->setFillColor(color);
  Dart_ExitScope();
  LOGI("Out C2DSetFillStyle");
}

void C2DSetFont(Dart_NativeArguments arguments) {
  LOGI("In C2DSetFont");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  const char* font = GetArgAsString(arguments, 1);
  SetStringReturnValue(arguments, Context2D(handle)->setFont(font));
  Dart_ExitScope();
  LOGI("Out C2DSetFont");
}

void C2DSetGlobalCompositeOperation(Dart_NativeArguments arguments) {
  LOGI("In C2DSetGlobalCompositeOperation");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  const char* op = GetArgAsString(arguments, 1);
  Context2D(handle)->setGlobalCompositeOperation(op);
  Dart_ExitScope();
  LOGI("Out C2DSetGlobalCompositeOperation");
}

void C2DSetLineCap(Dart_NativeArguments arguments) {
  LOGI("In C2DSetLineCap");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  const char* lc = GetArgAsString(arguments, 1);
  Context2D(handle)->setLineCap(lc);
  Dart_ExitScope();
  LOGI("Out C2DSetLineCap");
}

void C2DSetLineJoin(Dart_NativeArguments arguments) {
  LOGI("In C2DSetLineJoin");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  const char* lj = GetArgAsString(arguments, 1);
  Context2D(handle)->setLineJoin(lj);
  Dart_ExitScope();
  LOGI("Out C2DSetLineJoin");
}

void C2DSetLineWidth(Dart_NativeArguments arguments) {
  LOGI("In C2DSetLineWidth");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double w = GetArgAsDouble(arguments, 1);
  Context2D(handle)->setLineWidth(w);
  Dart_ExitScope();
  LOGI("Out C2DSetLineWidth");
}

void C2DSetMiterLimit(Dart_NativeArguments arguments) {
  LOGI("In C2DSetMiterLimit");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double w = GetArgAsDouble(arguments, 1);
  Context2D(handle)->setMiterLimit(w);
  Dart_ExitScope();
  LOGI("Out C2DSetMiterLimit");
}

void C2DSetShadowBlur(Dart_NativeArguments arguments) {
  LOGI("In C2DSetShadowBlur");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double blur = GetArgAsDouble(arguments, 1);
  Context2D(handle)->setShadowBlur(blur);
  Dart_ExitScope();
  LOGI("Out C2DSetShadowBlur");
}

void C2DSetShadowColor(Dart_NativeArguments arguments) {
  LOGI("In C2DSetShadowColor");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  const char* color = GetArgAsString(arguments, 1);
  Context2D(handle)->setShadowColor(color);
  Dart_ExitScope();
  LOGI("Out C2DSetShadowColor");
}

void C2DSetShadowOffsetX(Dart_NativeArguments arguments) {
  LOGI("In C2DSetShadowOffsetX");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double offset = GetArgAsDouble(arguments, 1);
  Context2D(handle)->setShadowOffsetX(offset);
  Dart_ExitScope();
  LOGI("Out C2DSetShadowOffsetX");
}

void C2DSetShadowOffsetY(Dart_NativeArguments arguments) {
  LOGI("In C2DSetShadowOffsetY");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double offset = GetArgAsDouble(arguments, 1);
  Context2D(handle)->setShadowOffsetY(offset);
  Dart_ExitScope();
  LOGI("Out C2DSetShadowOffsetY");
}

void C2DSetStrokeStyle(Dart_NativeArguments arguments) {
  LOGI("In C2DSetStrokeStyle");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  const char* color = GetArgAsString(arguments, 1);
  Context2D(handle)->setStrokeColor(color);
  Dart_ExitScope();
  LOGI("Out C2DSetStrokeStyle");
}

void C2DSetTextAlign(Dart_NativeArguments arguments) {
  LOGI("In C2DSetTextAlign");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  const char* align = GetArgAsString(arguments, 1);
  SetStringReturnValue(arguments, Context2D(handle)->setTextAlign(align));
  Dart_ExitScope();
  LOGI("Out C2DSetTextAlign");
}

void C2DSetTextBaseline(Dart_NativeArguments arguments) {
  LOGI("In C2DSetTextBaseline");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  const char* baseline = GetArgAsString(arguments, 1);
  SetStringReturnValue(arguments, Context2D(handle)->setTextBaseline(baseline));
  Dart_ExitScope();
  LOGI("Out C2DSetTextBaseline");
}

void C2DGetImageSmoothingEnabled(Dart_NativeArguments arguments) {
  LOGI("In C2DGetImageSmoothingEnabled");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  SetDoubleReturnValue(arguments, Context2D(handle)->imageSmoothingEnabled());
  Dart_ExitScope();
  LOGI("Out C2DGetImageSmoothingEnabled");
}

void C2DArc(Dart_NativeArguments arguments) {
  LOGI("In C2DArc");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double x = GetArgAsDouble(arguments, 1);
  double y = GetArgAsDouble(arguments, 2);
  double r = GetArgAsDouble(arguments, 3);
  double a1 = GetArgAsDouble(arguments, 4);
  double a2 = GetArgAsDouble(arguments, 5);
  bool anticlockwise = GetArgAsBool(arguments, 6);
  Context2D(handle)->Arc(x, y, r, a1, a2, anticlockwise);
  Dart_ExitScope();
  LOGI("Out C2DArc");
}

void C2DArcTo(Dart_NativeArguments arguments) {
  LOGI("In C2DArcTo");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double x1 = GetArgAsDouble(arguments, 1);
  double y1 = GetArgAsDouble(arguments, 2);
  double x2 = GetArgAsDouble(arguments, 3);
  double y2 = GetArgAsDouble(arguments, 4);
  double radius = GetArgAsDouble(arguments, 5);
  Context2D(handle)->ArcTo(x1, y1, x2, y2, radius);
  Dart_ExitScope();
  LOGI("Out C2DArcTo");
}

void C2DBeginPath(Dart_NativeArguments arguments) {
  LOGI("In C2DBeginPath");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  Context2D(handle)->BeginPath();
  Dart_ExitScope();
  LOGI("Out C2DBeginPath");
}

void C2DBezierCurveTo(Dart_NativeArguments arguments) {
  LOGI("In C2DBezierCurveTo");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double cp1x = GetArgAsDouble(arguments, 1);
  double cp1y = GetArgAsDouble(arguments, 2);
  double cp2x = GetArgAsDouble(arguments, 3);
  double cp2y = GetArgAsDouble(arguments, 4);
  double x = GetArgAsDouble(arguments, 5);
  double y = GetArgAsDouble(arguments, 6);
  Context2D(handle)->BezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
  Dart_ExitScope();
  LOGI("Out C2DBezierCurveTo");
}

void C2DClearRect(Dart_NativeArguments arguments) {
  LOGI("In C2DClearRect");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double left = GetArgAsDouble(arguments, 1);
  double top = GetArgAsDouble(arguments, 2);
  double width = GetArgAsDouble(arguments, 3);
  double height = GetArgAsDouble(arguments, 4);
  Context2D(handle)->ClearRect(left, top, width, height);
  Dart_ExitScope();
  LOGI("Out C2DClearRect");
}

void C2DClip(Dart_NativeArguments arguments) {
  LOGI("In C2DClip");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  Context2D(handle)->Clip();
  Dart_ExitScope();
  LOGI("Out C2DClip");
}

void C2DClosePath(Dart_NativeArguments arguments) {
  LOGI("In C2DClosePath");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  Context2D(handle)->ClosePath();
  Dart_ExitScope();
  LOGI("Out C2DClosePath");
}

void C2DCreateImageDataFromDimensions(Dart_NativeArguments arguments) {
  LOGI("In C2DCreateImageDataFromDimensions");
  Dart_EnterScope();
  // int handle = GetArgAsInt(arguments, 0);
  // double sw = GetArgAsDouble(arguments, 1);
  // double sh = GetArgAsDouble(arguments, 2);
  // GLubyte* pixels = (GLubyte*)calloc(sw * sh * 4, sizeof(GLubyte));
  // ImageData* imageData = new ImageData(sw, sh, pixels);
  // TODO(gram): How do we create a Dart ImageData object from this?
  Dart_ExitScope();
  LOGI("Out C2DCreateImageDataFromDimensions");
}

void C2DDrawImage(Dart_NativeArguments arguments) {
  LOGI("In C2DDrawImage");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  const char* src_url = GetArgAsString(arguments, 1);
  int sx = GetArgAsInt(arguments, 2);
  int sy = GetArgAsInt(arguments, 3);
  bool has_src_dimensions = GetArgAsBool(arguments, 4);
  int sw = GetArgAsInt(arguments, 5);
  int sh = GetArgAsInt(arguments, 6);
  int dx = GetArgAsInt(arguments, 7);
  int dy = GetArgAsInt(arguments, 8);
  bool has_dst_dimensions = GetArgAsBool(arguments, 9);
  int dw = GetArgAsInt(arguments, 10);
  int dh = GetArgAsInt(arguments, 11);
  Context2D(handle)->DrawImage(src_url,
                               sx, sy, has_src_dimensions, sw, sh,
                               dx, dy, has_dst_dimensions, dw, dh);
  Dart_ExitScope();
  LOGI("Out C2DDrawImage");
}

void C2DFill(Dart_NativeArguments arguments) {
  LOGI("In C2DFill");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  Context2D(handle)->Fill();
  Dart_ExitScope();
  LOGI("Out C2DFill");
}

void C2DFillRect(Dart_NativeArguments arguments) {
  LOGI("In C2DFillRect");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double left = GetArgAsDouble(arguments, 1);
  double top = GetArgAsDouble(arguments, 2);
  double width = GetArgAsDouble(arguments, 3);
  double height = GetArgAsDouble(arguments, 4);
  Context2D(handle)->FillRect(left, top, width, height);
  Dart_ExitScope();
  LOGI("Out C2DFillRect");
}

void C2DFillText(Dart_NativeArguments arguments) {
  LOGI("In C2DFillText");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  const char* text = GetArgAsString(arguments, 1);
  double x = GetArgAsDouble(arguments, 2);
  double y = GetArgAsDouble(arguments, 3);
  double maxWidth = GetArgAsDouble(arguments, 4);
  Context2D(handle)->FillText(text, x, y, maxWidth);
  Dart_ExitScope();
  LOGI("Out C2DFillText");
}

void C2DGetImageData(Dart_NativeArguments arguments) {
  LOGI("In C2DGetImageData");
  Dart_EnterScope();
  // TODO(gram): Complete this.
  // int handle = GetArgAsInt(arguments, 0);
  // double sx = GetArgAsDouble(arguments, 1);
  // double sy = GetArgAsDouble(arguments, 2);
  // double sw = GetArgAsDouble(arguments, 3);
  // double sh = GetArgAsDouble(arguments, 4);
  // ... = Context2D(handle)->GetImageData(text, x, y, maxWidth);
  Dart_ExitScope();
  LOGI("Out C2DGetImageData");
}

void C2DLineTo(Dart_NativeArguments arguments) {
  LOGI("In C2DLineTo");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double x = GetArgAsDouble(arguments, 1);
  double y = GetArgAsDouble(arguments, 2);
  Context2D(handle)->LineTo(x, y);
  Dart_ExitScope();
  LOGI("Out C2DLineTo");
}

void C2DMeasureText(Dart_NativeArguments arguments) {
  LOGI("In C2DMeasureText");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  const char* text = GetArgAsString(arguments, 1);
  float width = Context2D(handle)->MeasureText(text);
  SetDoubleReturnValue(arguments, width);
  Dart_ExitScope();
  LOGI("Out C2DMeasureText");
}

void C2DMoveTo(Dart_NativeArguments arguments) {
  LOGI("IN C2DMoveTo");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double x = GetArgAsDouble(arguments, 1);
  double y = GetArgAsDouble(arguments, 2);
  Context2D(handle)->MoveTo(x, y);
  Dart_ExitScope();
  LOGI("Out C2DMoveTo");
}

void C2DPutImageData(Dart_NativeArguments arguments) {
  LOGI("IN C2DPutImageData");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  // Get object arguments 2
  // BindingImageData* imageData = GetArgAsObject(arguments, 1);
  double dx = GetArgAsDouble(arguments, 2);
  double dy = GetArgAsDouble(arguments, 3);
  Context2D(handle)->PutImageData(NULL, dx, dy);
  Dart_ExitScope();
  LOGI("Out C2DPutImageData");
}

void C2DQuadraticCurveTo(Dart_NativeArguments arguments) {
  LOGI("In C2DQuadraticCurveTo");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double cpx = GetArgAsDouble(arguments, 1);
  double cpy = GetArgAsDouble(arguments, 2);
  double x = GetArgAsDouble(arguments, 3);
  double y = GetArgAsDouble(arguments, 4);
  Context2D(handle)->QuadraticCurveTo(cpx, cpy, x, y);
  Dart_ExitScope();
  LOGI("Out C2DQuadraticCurveTo");
}

void C2DRect(Dart_NativeArguments arguments) {
  LOGI("In C2DRect");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double x = GetArgAsDouble(arguments, 1);
  double y = GetArgAsDouble(arguments, 2);
  double w = GetArgAsDouble(arguments, 3);
  double h = GetArgAsDouble(arguments, 4);
  Context2D(handle)->Rect(x, y, w, h);
  Dart_ExitScope();
  LOGI("Out C2DRect");
}

void C2DRestore(Dart_NativeArguments arguments) {
  LOGI("In C2DRestore");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  CanvasContext* context = Context2D(handle);
  context->Restore();
  Dart_ExitScope();
  LOGI("Out C2DRestore");
}

void C2DRotate(Dart_NativeArguments arguments) {
  LOGI("In C2DRotate");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double a = GetArgAsDouble(arguments, 1);
  Context2D(handle)->Rotate(a);
  Dart_ExitScope();
  LOGI("Out C2DRotate");
}

void C2DSave(Dart_NativeArguments arguments) {
  LOGI("In C2DSave");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  Context2D(handle)->Save();
  Dart_ExitScope();
  LOGI("Out C2DSave");
}

void C2DScale(Dart_NativeArguments arguments) {
  LOGI("In C2DScale");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double sx = GetArgAsDouble(arguments, 1);
  double sy = GetArgAsDouble(arguments, 2);
  Context2D(handle)->Scale(sx, sy);
  Dart_ExitScope();
  LOGI("Out C2DScale");
}

void C2DSetLineDash(Dart_NativeArguments arguments) {
  LOGI("In C2DSetLineDash");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  int len;
  float* dash = static_cast<float*>(GetArgsAsFloatList(arguments, 1, &len));
  if (dash != NULL) {
    Context2D(handle)->setLineDash(dash, len);
    delete[] dash;
  }
  Dart_ExitScope();
  LOGI("Out C2DSetLineDash");
}

void C2DSetLineDashOffset(Dart_NativeArguments arguments) {
  LOGI("In C2DSetLineDashOffset");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double offset = GetArgAsDouble(arguments, 1);
  Context2D(handle)->setLineDashOffset(offset);
  Dart_ExitScope();
  LOGI("Out C2DSetLineDashOffset");
}

void C2DSetTransform(Dart_NativeArguments arguments) {
  LOGI("In C2DSetTransform");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double m11 = GetArgAsDouble(arguments, 1);
  double m12 = GetArgAsDouble(arguments, 2);
  double m21 = GetArgAsDouble(arguments, 3);
  double m22 = GetArgAsDouble(arguments, 4);
  double dx = GetArgAsDouble(arguments, 5);
  double dy = GetArgAsDouble(arguments, 6);
  Context2D(handle)->setTransform(m11, m12, m21, m22, dx, dy);
  Dart_ExitScope();
  LOGI("Out C2DSetTransform");
}

void C2DStroke(Dart_NativeArguments arguments) {
  LOGI("In C2DStroke");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  Context2D(handle)->Stroke();
  Dart_ExitScope();
  LOGI("Out C2DStroke");
}

void C2DStrokeRect(Dart_NativeArguments arguments) {
  LOGI("In C2DStrokeRect");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double left = GetArgAsDouble(arguments, 1);
  double top = GetArgAsDouble(arguments, 2);
  double width = GetArgAsDouble(arguments, 3);
  double height = GetArgAsDouble(arguments, 4);
  Context2D(handle)->StrokeRect(left, top, width, height);
  Dart_ExitScope();
  LOGI("Out C2DStrokeRect");
}

void C2DStrokeText(Dart_NativeArguments arguments) {
  LOGI("In C2DStrokeText");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  const char* text = GetArgAsString(arguments, 1);
  double x = GetArgAsDouble(arguments, 2);
  double y = GetArgAsDouble(arguments, 3);
  double maxWidth = GetArgAsDouble(arguments, 4);
  Context2D(handle)->StrokeText(text, x, y, maxWidth);
  Dart_ExitScope();
  LOGI("Out C2DStrokeText");
}

void C2DTransform(Dart_NativeArguments arguments) {
  LOGI("In C2DTransform");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double m11 = GetArgAsDouble(arguments, 1);
  double m12 = GetArgAsDouble(arguments, 2);
  double m21 = GetArgAsDouble(arguments, 3);
  double m22 = GetArgAsDouble(arguments, 4);
  double dx = GetArgAsDouble(arguments, 5);
  double dy = GetArgAsDouble(arguments, 6);
  Context2D(handle)->Transform(m11, m12, m21, m22, dx, dy);
  Dart_ExitScope();
  LOGI("Out C2DTransform");
}

void C2DTranslate(Dart_NativeArguments arguments) {
  LOGI("In C2DTranslate");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  double x = GetArgAsDouble(arguments, 1);
  double y = GetArgAsDouble(arguments, 2);
  Context2D(handle)->Translate(x, y);
  Dart_ExitScope();
  LOGI("Out C2DTranslate");
}

void C2DSetFillGradient(Dart_NativeArguments arguments) {
  LOGI("In C2DSetFillGradient");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  bool is_radial = GetArgAsBool(arguments, 1);
  double x0 = GetArgAsDouble(arguments, 2);
  double y0 = GetArgAsDouble(arguments, 3);
  double r0 = GetArgAsDouble(arguments, 4);
  double x1 = GetArgAsDouble(arguments, 5);
  double y1 = GetArgAsDouble(arguments, 6);
  double r1 = GetArgAsDouble(arguments, 7);
  int num_positions, num_colors;
  float* positions = GetArgsAsFloatList(arguments, 8, &num_positions);
  char** colors = GetArgsAsStringList(arguments, 9, &num_colors);
  Context2D(handle)->SetFillGradient(is_radial, x0, y0, r0, x1, y1, r1,
    num_positions, positions, colors);
  Dart_ExitScope();
  LOGI("Out C2DSetFillGradient");
}

void C2DSetStrokeGradient(Dart_NativeArguments arguments) {
  LOGI("In C2DSetStrokeGradient");
  Dart_EnterScope();
  int handle = GetArgAsInt(arguments, 0);
  bool is_radial = GetArgAsBool(arguments, 1);
  double x0 = GetArgAsDouble(arguments, 2);
  double y0 = GetArgAsDouble(arguments, 3);
  double r0 = GetArgAsDouble(arguments, 4);
  double x1 = GetArgAsDouble(arguments, 5);
  double y1 = GetArgAsDouble(arguments, 6);
  double r1 = GetArgAsDouble(arguments, 7);
  int num_positions, num_colors;
  float* positions = GetArgsAsFloatList(arguments, 8, &num_positions);
  char** colors = GetArgsAsStringList(arguments, 9, &num_colors);
  Context2D(handle)->SetStrokeGradient(is_radial, x0, y0, r0, x1, y1, r1,
    num_positions, positions, colors);
  Dart_ExitScope();
  LOGI("Out C2DSetStrokeGradient");
}

void C2DGetImageWidth(Dart_NativeArguments arguments) {
  LOGI("In C2DGetImageWidth");
  Dart_EnterScope();
  const char* src_url = GetArgAsString(arguments, 0);
  int w = ImageCache::GetWidth(src_url);
  SetIntReturnValue(arguments, w);
  Dart_ExitScope();
  LOGI("Out C2DGetImageWidth");
}

void C2DGetImageHeight(Dart_NativeArguments arguments) {
  LOGI("In C2DGetImageHeight");
  Dart_EnterScope();
  const char* src_url = GetArgAsString(arguments, 0);
  int h = ImageCache::GetHeight(src_url);
  SetIntReturnValue(arguments, h);
  Dart_ExitScope();
  LOGI("Out C2DGetImageHeight");
}

struct FunctionLookup {
  const char* name;
  Dart_NativeFunction function;
};

FunctionLookup function_list[] = {
    {"Log", Log},
    {"LogError", LogError},
    {"SystemRand", SystemRand},
    {"SystemSrand", SystemSrand},
    {"SwapBuffers", SwapBuffers},
    {"GetDeviceScreenWidth", GetDeviceScreenWidth},
    {"GetDeviceScreenHeight", GetDeviceScreenHeight},
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
    {"GLDeleteStatus", GLDeleteStatus},
    {"GLDepthBufferBit", GLDepthBufferBit},
    {"GLFloat", GLFloat},
    {"GLFragmentShader", GLFragmentShader},
    {"GLLinkStatus", GLLinkStatus},
    {"GLTriangleStrip", GLTriangleStrip},
    {"GLTriangles", GLTriangles},
    {"GLTrue", GLTrue},
    {"GLStaticDraw", GLStaticDraw},
    {"GLValidateStatus", GLValidateStatus},
    {"GLVertexShader", GLVertexShader},
    {"GLGetShaderInfoLog", GLGetShaderInfoLog},
    {"GLGetProgramInfoLog", GLGetProgramInfoLog},
    {"RandomArray_ServicePort", RandomArrayServicePort},

    // Audio support.
    {"PlayBackground", PlayBackground},
    {"StopBackground", StopBackground},
    {"LoadSample", LoadSample},
    {"PlaySample", PlaySample},

    // 2D Support

    { "C2DCreateNativeContext", C2DCreateNativeContext},

    // Property getters/setters.

    { "C2DSetWidth", C2DSetWidth},
    { "C2DSetHeight", C2DSetHeight},
    { "C2DSetGlobalAlpha", C2DSetGlobalAlpha},
    { "C2DSetFillStyle", C2DSetFillStyle},
    { "C2DSetFont", C2DSetFont},
    { "C2DSetGlobalCompositeOperation", C2DSetGlobalCompositeOperation},
    { "C2DSetLineCap", C2DSetLineCap},
    { "C2DSetLineJoin", C2DSetLineJoin},
    { "C2DSetLineWidth", C2DSetLineWidth},
    { "C2DSetMiterLimit", C2DSetMiterLimit},
    { "C2DSetShadowBlur", C2DSetShadowBlur},
    { "C2DSetShadowColor", C2DSetShadowColor},
    { "C2DSetShadowOffsetX", C2DSetShadowOffsetX},
    { "C2DSetShadowOffsetY", C2DSetShadowOffsetY},
    { "C2DSetStrokeStyle", C2DSetStrokeStyle},
    { "C2DSetTextAlign", C2DSetTextAlign},
    { "C2DSetTextBaseline", C2DSetTextBaseline},
    { "C2DGetImageSmoothingEnabled", C2DGetImageSmoothingEnabled},

    // Methods.
    { "C2DArc", C2DArc},
    { "C2DArcTo", C2DArcTo},
    { "C2DBeginPath", C2DBeginPath},
    { "C2DBezierCurveTo", C2DBezierCurveTo},
    { "C2DClearRect", C2DClearRect},
    { "C2DClip", C2DClip},
    { "C2DClosePath", C2DClosePath},
    { "C2DCreateImageDataFromDimensions", C2DCreateImageDataFromDimensions},
    { "C2DDrawImage", C2DDrawImage},
    { "C2DFill", C2DFill},
    { "C2DFillRect", C2DFillRect},
    { "C2DFillText", C2DFillText},
    { "C2DGetImageData", C2DGetImageData},
    { "C2DLineTo", C2DLineTo},
    { "C2DMeasureText", C2DMeasureText},
    { "C2DMoveTo", C2DMoveTo},
    { "C2DPutImageData", C2DPutImageData},
    { "C2DQuadraticCurveTo", C2DQuadraticCurveTo},
    { "C2DRect", C2DRect},
    { "C2DRestore", C2DRestore},
    { "C2DRotate", C2DRotate},
    { "C2DSave", C2DSave},
    { "C2DScale", C2DScale},
    { "C2DSetLineDash", C2DSetLineDash},
    { "C2DSetLineDashOffset", C2DSetLineDashOffset},
    { "C2DSetTransform", C2DSetTransform},
    { "C2DStroke", C2DStroke},
    { "C2DStrokeRect", C2DStrokeRect},
    { "C2DStrokeText", C2DStrokeText},
    { "C2DTransform", C2DTransform},
    { "C2DTranslate", C2DTranslate},
    { "C2DSetFillGradient", C2DSetFillGradient},
    { "C2DSetStrokeGradient", C2DSetStrokeGradient},
    { "C2DGetImageWidth", C2DGetImageWidth},
    { "C2DGetImageHeight", C2DGetImageHeight},

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
