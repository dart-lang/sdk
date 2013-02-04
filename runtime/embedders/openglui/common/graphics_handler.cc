// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/common/graphics_handler.h"
#include "embedders/openglui/common/canvas_context.h"
#include "embedders/openglui/common/log.h"

extern void CheckGLError(const char *function);

GraphicsHandler* graphics;

GraphicsHandler::GraphicsHandler()
  : ag(),
    grcontext(NULL),
    width_(0),
    height_(0) {
  graphics = this;
}

// Kludge to get around an issue with Android emulator, which returns
// NULL for the shader language version, causing Skia to blow up.
const GrGLubyte* myGLGetString(GLenum name) {
  const GrGLubyte* str = glGetString(name);
  if (NULL == str && GL_SHADING_LANGUAGE_VERSION == name) {
    return reinterpret_cast<GrGLubyte*>(
        const_cast<char*>("OpenGL ES GLSL ES 1.0"));
  } else {
    return str;
  }
}

int32_t GraphicsHandler::Start() {
  SkGraphics::Init();
  GrGLInterface* fGL = const_cast<GrGLInterface*>(GrGLCreateNativeInterface());
  LOGI("Created native interface %s\n", fGL ? "succeeded" : "failed");
  fGL->fGetString = myGLGetString;
  grcontext = GrContext::Create(kOpenGL_Shaders_GrEngine,
                        (GrPlatform3DContext)fGL);
  LOGI("Created GrContext %s\n", grcontext ? "succeeded" : "failed");
  return 0;
}

void GraphicsHandler::Stop() {
  SkGraphics::Term();
}

SkCanvas* GraphicsHandler::CreateCanvas() {
  GrPlatformRenderTargetDesc desc;
  desc.fWidth = width_;
  desc.fHeight = height_;
  desc.fConfig = kSkia8888_PM_GrPixelConfig;
  glGetIntegerv(GL_SAMPLES, &desc.fSampleCnt);
  glGetIntegerv(GL_STENCIL_BITS, &desc.fStencilBits);
  GrGLint buffer;
  glGetIntegerv(GL_FRAMEBUFFER_BINDING, &buffer);
  desc.fRenderTargetHandle = buffer;
  GrRenderTarget* fGrRenderTarget = grcontext->createPlatformRenderTarget(desc);
  return new SkCanvas(new SkGpuDevice(grcontext, fGrRenderTarget));
}

void GraphicsHandler::SetViewport(int left, int top, int width, int height) {
  width_ = width;
  height_ = height;
  glViewport(left, top, width, height);
  CheckGLError("glViewPort");
}

int32_t GraphicsHandler::Update() {
  extern CanvasContext* display_context;
  if (display_context != NULL) {
    LOGI("Flushing display context\n");
    display_context->Flush();
  }
  SwapBuffers();
  return 0;
}




