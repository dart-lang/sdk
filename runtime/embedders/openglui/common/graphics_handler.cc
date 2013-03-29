// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "embedders/openglui/common/graphics_handler.h"
#include "embedders/openglui/common/canvas_context.h"
#include "embedders/openglui/common/log.h"

extern void CheckGLError(const char *function);

GraphicsHandler* graphics;
extern CanvasContext* display_context;

GraphicsHandler::GraphicsHandler(const char* resource_path)
  : resource_path_(resource_path),
    ag(),
    grcontext(NULL),
    width_(0),
    height_(0) {
  graphics = this;
  DecoderHack(0, NULL);
}

void GraphicsHandler::DecoderHack(int x, SkStream* s) {
  if (x) {  // hack to keep the linker from throwing these out
    extern SkImageDecoder* sk_libpng_dfactory(SkStream* s);
    sk_libpng_dfactory(s);

    // TODO(gram): For some reason I get linker errors on these, even though
    // they are defined in libskia_images. Figure out why...
    /*
    extern SkImageDecoder* sk_libjpeg_dfactory(SkStream* s);
    extern SkImageDecoder* sk_libbmp_dfactory(SkStream* s);
    extern SkImageDecoder* sk_libgif_dfactory(SkStream* s);
    extern SkImageDecoder* sk_libico_dfactory(SkStream* s);
    extern SkImageDecoder* sk_libwbmp_dfactory(SkStream* s);
    sk_libjpeg_dfactory(s);
    sk_libbmp_dfactory(s);
    sk_libgif_dfactory(s);
    sk_libico_dfactory(s);
    sk_libwbmp_dfactory(s);
    */
  }
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
  GrGLInterface* fGL = const_cast<GrGLInterface*>(GrGLCreateNativeInterface());
  LOGI("Created native interface %s\n", fGL ? "succeeded" : "failed");
  fGL->fGetString = myGLGetString;
  grcontext = GrContext::Create(kOpenGL_GrBackend, (GrBackendContext)fGL);
  LOGI("Created GrContext %s\n", grcontext ? "succeeded" : "failed");
  return 0;
}

void GraphicsHandler::Stop() {
  LOGI("Releasing display context");
  FreeContexts();
  grcontext->unref();
  grcontext = NULL;
}

SkCanvas* GraphicsHandler::CreateDisplayCanvas() {
  GrBackendRenderTargetDesc desc;
  desc.fWidth = width_;
  desc.fHeight = height_;
  desc.fConfig = kSkia8888_GrPixelConfig;
  desc.fOrigin = kBottomLeft_GrSurfaceOrigin;
  glGetIntegerv(GL_SAMPLES, &desc.fSampleCnt);
  glGetIntegerv(GL_STENCIL_BITS, &desc.fStencilBits);
  LOGI("Creating %dx%d display canvas, samples %d, stencil bits %d",
    width_, height_, desc.fSampleCnt, desc.fStencilBits);
  GrGLint buffer;
  glGetIntegerv(GL_FRAMEBUFFER_BINDING, &buffer);
  desc.fRenderTargetHandle = buffer;
  GrRenderTarget* fGrRenderTarget = grcontext->wrapBackendRenderTarget(desc);
  SkGpuDevice* device = new SkGpuDevice(grcontext, fGrRenderTarget);
//  fGrRenderTarget->unref(); // TODO(gram):  determine if we need this.
  SkCanvas* canvas = new SkCanvas(device);
  device->unref();
  return canvas;
}

SkCanvas* GraphicsHandler::CreateBitmapCanvas(int width, int height) {
  LOGI("Creating %dx%d bitmap canvas", width, height);
  SkDevice* rasterDevice =
      new SkDevice(SkBitmap::kARGB_8888_Config, width, height);
  SkCanvas* canvas = new SkCanvas(rasterDevice);
  rasterDevice->unref();
  return canvas;
}

void GraphicsHandler::SetViewport(int left, int top, int width, int height) {
  width_ = width;
  height_ = height;
  glViewport(left, top, width, height);
  CheckGLError("glViewPort");
}

int32_t GraphicsHandler::Update() {
  LOGI("In GraphicsHandler::Update, display_context dirty %s",
    (display_context == NULL ? "NULL" :
        (display_context->isDirty() ? "yes":"no")));
  if (display_context != NULL && display_context->isDirty()) {
    LOGI("Flushing display context\n");
    display_context->Flush();
    SwapBuffers();
    display_context->clearDirty();
  }
  return 0;
}

