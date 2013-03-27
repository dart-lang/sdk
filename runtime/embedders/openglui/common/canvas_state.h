// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef EMBEDDERS_OPENGLUI_COMMON_CANVAS_STATE_H_
#define EMBEDDERS_OPENGLUI_COMMON_CANVAS_STATE_H_

#include "embedders/openglui/common/graphics_handler.h"
#include "embedders/openglui/common/log.h"
#include "embedders/openglui/common/opengl.h"
#include "embedders/openglui/common/support.h"

typedef struct CanvasState {
  SkPaint paint_;
  float globalAlpha_;
  float miterLimit_;
  ColorRGBA fillColor_;
  ColorRGBA strokeColor_;
  ColorRGBA shadowColor_;
  float shadowBlur_;
  float shadowOffsetX_;
  float shadowOffsetY_;
  float* lineDash_;
  int lineDashCount_;
  int lineDashOffset_;
  SkShader* fillShader_;
  SkShader* strokeShader_;

  SkPath* path_;
  SkCanvas* canvas_;
  CanvasState* next_;  // For stack.

  CanvasState(SkCanvas* canvas)
    : paint_(),
      globalAlpha_(1.0),
      miterLimit_(10),
      fillColor_(ColorRGBA(255, 0, 0, 255)),
      strokeColor_(fillColor_),
      shadowColor_(ColorRGBA(0, 0, 0, 0)),
      shadowBlur_(0.0),
      shadowOffsetX_(0.0),
      shadowOffsetY_(0.0),
      lineDash_(NULL),
      lineDashCount_(0),
      lineDashOffset_(0),
      fillShader_(NULL),
      strokeShader_(NULL),
      path_(new SkPath()),
      canvas_(canvas),
      next_(NULL) {
    paint_.setStrokeCap(SkPaint::kButt_Cap);
    paint_.setStrokeJoin(SkPaint::kMiter_Join);
    paint_.setStrokeWidth(1);
    paint_.setTextAlign(SkPaint::kLeft_Align);
    paint_.setAntiAlias(true);
    paint_.setStyle(SkPaint::kStroke_Style);
    setFont("Helvetica", 10);
  }

  CanvasState(const CanvasState& state)
    : paint_(state.paint_),
      globalAlpha_(state.globalAlpha_),
      miterLimit_(state.miterLimit_),
      fillColor_(state.fillColor_),
      strokeColor_(state.strokeColor_),
      shadowColor_(state.shadowColor_),
      shadowBlur_(state.shadowBlur_),
      shadowOffsetX_(state.shadowOffsetX_),
      shadowOffsetY_(state.shadowOffsetY_),
      lineDash_(NULL),
      lineDashCount_(state.lineDashCount_),
      lineDashOffset_(state.lineDashOffset_),
      fillShader_(state.fillShader_),
      strokeShader_(state.strokeShader_),
      path_(new SkPath()),
      canvas_(state.canvas_),
      next_(NULL) {
    setLineDash(state.lineDash_, lineDashCount_);
    if (fillShader_ != NULL) fillShader_->ref();
    if (strokeShader_ != NULL) strokeShader_->ref();
  }

  ~CanvasState() {
    if (fillShader_ != NULL) fillShader_->unref();
    if (strokeShader_ != NULL) strokeShader_->unref();
    delete path_;
    delete[] lineDash_;
  }

  static ColorRGBA GetColor(const char* color);

  inline CanvasState* Save() {
    canvas_->save();  // For clip and transform.
    CanvasState *new_state = new CanvasState(*this);
    new_state->next_ = this;
    // If the old state has a non-empty path, use its
    // last point as the new states first point.
    int np = path_->countPoints();
    if (np > 0) {
      new_state->path_->moveTo(path_->getPoint(np-1));
    }
    return new_state;
  }

  CanvasState* Restore();

  inline float Radians2Degrees(float angle) {
    return 180.0 * angle / M_PI;
  }

  inline void setGlobalAlpha(float alpha) {
    globalAlpha_ = alpha;
  }

  inline void setFillColor(const char* color) {
    if (fillShader_ != NULL) {
      fillShader_->unref();
      fillShader_ = NULL;
    }
    fillColor_ = GetColor(color);
  }

  inline void setStrokeColor(const char* color) {
    if (strokeShader_ != NULL) {
      strokeShader_->unref();
      strokeShader_ = NULL;
    }
    strokeColor_ = GetColor(color);
  }

  const char* setFont(const char*name, float size = -1);
  void setLineCap(const char* lc);
  void setLineJoin(const char* lj);

  inline void setMiterLimit(float limit) {
    miterLimit_ = limit;
  }

  const char* setTextAlign(const char* align);
  const char* setTextBaseline(const char* baseline);
  const char* setTextDirection(const char* direction);

  inline void FillText(const char* text, float x, float y, float maxWidth) {
    setFillMode();
    canvas_->drawText(text, strlen(text), x, y, paint_);
  }

  inline void StrokeText(const char* text, float x, float y, float maxWidth) {
    setStrokeMode();
    canvas_->drawText(text, strlen(text), x, y, paint_);
  }

  inline float MeasureText(const char *text) {
    // TODO(gram): make sure this is not supposed to be affected
    // by the canvas transform.
    return paint_.measureText(text, strlen(text));
  }

  inline void setLineWidth(float w) {
    paint_.setStrokeWidth(w);
  }

  void setMode(SkPaint::Style style, ColorRGBA color, SkShader* shader);

  inline void setLineDashEffect() {
    if (lineDashCount_ > 0) {
      SkDashPathEffect* dashPathEffect =
        new SkDashPathEffect(lineDash_, lineDashCount_, lineDashOffset_);
        paint_.setPathEffect(dashPathEffect)->unref();
    } else {
      paint_.setPathEffect(NULL);
    }
  }

  inline void setLineDash(float* dashes, int len) {
    if (len == 0) {
      lineDashCount_ = 0;
      delete[] lineDash_;
      lineDash_ = NULL;
    } else {
      lineDash_ = new float[lineDashCount_ = len];
      for (int i = 0; i < len; i++) {
        lineDash_[i] = dashes[i];
      }
    }
    setLineDashEffect();
  }

  inline void setLineDashOffset(int offset) {
    if (offset != lineDashOffset_) {
      lineDashOffset_ = offset;
      setLineDashEffect();
    }
  }

  inline void setShadowColor(const char* color) {
    shadowColor_ = GetColor(color);
  }

  inline void setShadowBlur(float blur) {
    shadowBlur_ = blur;
  }

  inline void setShadowOffsetX(float ox) {
    shadowOffsetX_ = ox;
  }

  inline void setShadowOffsetY(float oy) {
    shadowOffsetY_ = oy;
  }

  inline void setFillMode() {
    setMode(SkPaint::kFill_Style, fillColor_, fillShader_);
  }

  inline void setStrokeMode() {
    setMode(SkPaint::kStroke_Style, strokeColor_, strokeShader_);
  }

  inline void FillRect(float left, float top,
                       float width, float height) {
    // Does not affect the path.
    setFillMode();
    canvas_->drawRectCoords(left, top, left + width, top + height, paint_);
  }

  inline void StrokeRect(float left, float top,
                         float width, float height) {
    // Does not affect the path.
    setStrokeMode();
    canvas_->drawRectCoords(left, top, left + width, top + height, paint_);
  }

  inline void BeginPath() {
    path_->rewind();
  }

  inline void Fill() {
    setFillMode();
    canvas_->drawPath(*path_, paint_);
  }

  inline void Stroke() {
    setStrokeMode();
    canvas_->drawPath(*path_, paint_);
  }

  inline void ClosePath() {
    path_->close();
  }

  inline void MoveTo(float x, float y) {
    path_->moveTo(x, y);
  }

  inline void LineTo(float x, float y) {
    path_->lineTo(x, y);
  }

  void Arc(float x, float y, float radius, float startAngle, float endAngle,
           bool antiClockwise);

  inline void QuadraticCurveTo(float cpx, float cpy, float x, float y) {
    path_->quadTo(cpx, cpy, x, y);
  }

  inline void BezierCurveTo(float cp1x, float cp1y, float cp2x, float cp2y,
                     float x, float y) {
    path_->cubicTo(cp1x, cp1y, cp2x, cp2y, x, y);
  }

  inline void ArcTo(float x1, float y1, float x2, float y2, float radius) {
    path_->arcTo(x1, y1, x2, y2, radius);
  }

  inline void Rect(float x, float y, float w, float h) {
    // TODO(gram): Should we draw this directly? If so, what happens with the
    // path?
    path_->addRect(x, y, x + w, y + h);
  }

  void setGlobalCompositeOperation(const char* op);

  void DrawImage(const SkBitmap& bm,
                 int sx, int sy, int sw, int sh,
                 int dx, int dy, int dw, int dh);

  inline void Clip() {
    canvas_->clipPath(*path_);
  }

  void SetFillGradient(bool is_radial, double x0, double y0, double r0,
      double x1, double y1, double r1,
      int stops, float* positions, char** colors);

  void SetStrokeGradient(bool is_radial, double x0, double y0, double r0,
      double x1, double y1, double r1,
      int stops, float* positions, char** colors);

 private:
  SkShader* CreateRadialGradient(
      double x0, double y0, double r0,
      double x1, double y1, double r1,
      int stops, float* positions, char** colors);

  SkShader* CreateLinearGradient(
      double x0, double y0, double x1, double y1,
      int stops, float* positions, char** colors);
} CanvasState;

#endif  // EMBEDDERS_OPENGLUI_COMMON_CANVAS_STATE_H_

