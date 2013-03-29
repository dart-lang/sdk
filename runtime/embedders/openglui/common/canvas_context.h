// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_COMMON_CANVAS_CONTEXT_H_
#define EMBEDDERS_OPENGLUI_COMMON_CANVAS_CONTEXT_H_

#include "embedders/openglui/common/canvas_state.h"
#include "embedders/openglui/common/graphics_handler.h"
#include "embedders/openglui/common/log.h"
#include "embedders/openglui/common/opengl.h"
#include "embedders/openglui/common/support.h"

typedef struct ImageData {
  int width;
  int height;
  GLubyte* pixels;

  ImageData(int wp, int hp, GLubyte* pp)
    : width(wp), height(hp), pixels(pp) {
  }
  ImageData()
    : width(0), height(0), pixels(NULL) {
  }
} ImageData;

class CanvasContext {
 protected:
  SkCanvas* canvas_;
  int16_t width_, height_;
  bool imageSmoothingEnabled_;
  bool isDirty_;
  CanvasState* state_;

  static inline float Radians2Degrees(float angle) {
    return 180.0 * angle / M_PI;
  }

  inline void NotImplemented(const char* method) {
    LOGE("Method CanvasContext::%s is not yet implemented", method);
  }

 public:
  CanvasContext(int handle, int16_t width, int16_t height);
  virtual ~CanvasContext();

  inline bool isDirty() {
    return isDirty_;
  }

  inline void clearDirty() {
    isDirty_ = false;
  }

  inline void setGlobalAlpha(float alpha) {
    state_->setGlobalAlpha(alpha);
  }

  inline void setFillColor(const char* color) {
    state_->setFillColor(color);
  }

  inline void setStrokeColor(const char* color) {
    state_->setStrokeColor(color);
  }

  inline void setShadowBlur(float blur) {
    state_->setShadowBlur(blur);
  }

  inline void setShadowColor(const char* color) {
    state_->setShadowColor(color);
  }

  inline void setShadowOffsetX(float offset) {
    state_->setShadowOffsetX(offset);
  }

  inline void setShadowOffsetY(float offset) {
    state_->setShadowOffsetY(offset);
  }

  // For now, we don't allow resizing.
  // TODO(gram): fix this or remove these.
  inline int setWidth(int widthp) {
    return width_;
  }

  inline int setHeight(int heightp) {
    return height_;
  }

  inline bool imageSmoothingEnabled() {
    return imageSmoothingEnabled_;
  }

  inline void setImageSmoothingEnabled(bool enabled) {
    // TODO(gram): We're not actually doing anything with this yet.
    imageSmoothingEnabled_ = enabled;
  }

  inline void setGlobalCompositeOperation(const char* op) {
    state_->setGlobalCompositeOperation(op);
  }

  void Save();
  void Restore();

  inline void Rotate(float angle) {
    canvas_->rotate(Radians2Degrees(angle));
  }

  inline void Translate(float x, float y) {
    canvas_->translate(x, y);
  }

  inline void Scale(float x, float y) {
    canvas_->scale(x, y);
  }

  inline void Transform(float a, float b,
                        float c, float d,
                        float e, float f) {
    SkMatrix t;
    // Our params are for a 3 x 2 matrix in column order:
    //
    // a c e
    // b d f
    //
    // We need to turn this into a 3x3 matrix:
    //
    // a c e
    // b d f
    // 0 0 1
    //
    // and pass the params in row order:
    t.setAll(a, c, e, b, d, f, 0, 0, 1);
    canvas_->concat(t);
  }

  inline void setTransform(float a, float b,
                           float c, float d,
                           float e, float f) {
    SkMatrix t;
    t.setAll(a, c, e, b, d, f, 0, 0, 1);
    canvas_->setMatrix(t);
  }

  ImageData* GetImageData(float sx, float sy, float sw, float sh) {
    NotImplemented("GetImageData");
    return NULL;
  }

  void PutImageData(ImageData* imageData, float  dx, float dy) {
    NotImplemented("PutImageData");
  }

  void DrawImage(const char* src_url,
                 int sx, int sy, bool has_src_dimensions, int sw, int sh,
                 int dx, int dy, bool has_dst_dimensions, int dw, int dh);

  inline void Clear() {
    canvas_->drawColor(0xFFFFFFFF);
    isDirty_ = true;
  }

  void ClearRect(float left, float top, float width, float height);

  inline void FillRect(float left, float top, float width, float height) {
    // Does not affect the path.
    state_->FillRect(left, top, width, height);
    isDirty_ = true;
  }

  inline void StrokeRect(float left, float top, float width, float height) {
    // Does not affect the path.
    state_->StrokeRect(left, top, width, height);
    isDirty_ = true;
  }

  inline void BeginPath() {
    state_->BeginPath();
  }

  inline void Fill() {
    state_->Fill();
    isDirty_ = true;
  }

  inline void Stroke() {
    state_->Stroke();
    isDirty_ = true;
  }

  inline void ClosePath() {
    state_->ClosePath();
  }

  inline void MoveTo(float x, float y) {
    state_->MoveTo(x, y);
  }

  inline void LineTo(float x, float y) {
    state_->LineTo(x, y);
  }

  inline void QuadraticCurveTo(float cpx, float cpy, float x, float y) {
    state_->QuadraticCurveTo(cpx, cpy, x, y);
  }

  inline void BezierCurveTo(float cp1x, float cp1y, float cp2x, float cp2y,
                     float x, float y) {
    state_->BezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
  }

  inline void ArcTo(float x1, float y1, float x2, float y2, float radius) {
    state_->ArcTo(x1, y1, x2, y2, radius);
  }

  inline void Rect(float x, float y, float w, float h) {
    state_->Rect(x, y, w, h);
  }

  inline void Arc(float x, float y, float radius,
                  float startAngle, float endAngle,
                  bool antiClockwise) {
    state_->Arc(x, y, radius, startAngle, endAngle, antiClockwise);
  }

  inline void setLineWidth(double w) {
    state_->setLineWidth(w);
  }

  inline void setLineCap(const char* lc) {
    state_->setLineCap(lc);
  }

  inline void setLineDash(float* dashes, int len) {
    state_->setLineDash(dashes, len);
  }

  inline void setLineDashOffset(float offset) {
    state_->setLineDashOffset(offset);
  }

  inline void setLineJoin(const char* lj) {
    state_->setLineJoin(lj);
  }

  inline void setMiterLimit(float limit) {
    state_->setMiterLimit(limit);
  }

  inline const char* setFont(const char* font) {
    return state_->setFont(font);
  }

  inline const char* setTextAlign(const char* align) {
    return state_->setTextAlign(align);
  }

  const char* setTextBaseline(const char* baseline) {
    return state_->setTextBaseline(baseline);
  }

  inline const char* setDirection(const char* direction) {
    return state_->setTextDirection(direction);
  }

  inline void FillText(const char* text, float x, float y,
                       float maxWidth = -1) {
    state_->FillText(text, x, y, maxWidth);
    isDirty_ = true;
  }

  inline void StrokeText(const char* text, float x, float y,
                         float maxWidth = -1) {
    state_->StrokeText(text, x, y, maxWidth);
    isDirty_ = true;
  }

  inline float MeasureText(const char *text) {
    return state_->MeasureText(text);
  }

  inline void Clip() {
    state_->Clip();
  }

  inline void ResetClip() {
    // TODO(gram): Check this. Is it affected by the transform?
    canvas_->clipRect(SkRect::MakeLTRB(0, 0, width_, height_),
                      SkRegion::kReplace_Op);
  }

  virtual void Flush() {
    canvas_->flush();
  }

  inline void SetFillGradient(bool is_radial, double x0, double y0, double r0,
      double x1, double y1, double r1,
      int stops, float* positions, char** colors) {
    state_->SetFillGradient(is_radial, x0, y0, r0, x1, y1, r1,
        stops, positions, colors);
  }

  inline void SetStrokeGradient(bool is_radial, double x0, double y0, double r0,
      double x1, double y1, double r1,
      int stops, float* positions, char** colors) {
    state_->SetStrokeGradient(is_radial, x0, y0, r0, x1, y1, r1,
        stops, positions, colors);
  }

  inline const SkBitmap* GetBitmap() {
    SkDevice* device = canvas_->getDevice();
    return &device->accessBitmap(false);
  }
};

CanvasContext* Context2D(int handle);
void FreeContexts();

#endif  // EMBEDDERS_OPENGLUI_COMMON_CANVAS_CONTEXT_H_

