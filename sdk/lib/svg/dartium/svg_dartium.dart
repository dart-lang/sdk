/**
 * Scalable Vector Graphics:
 * Two-dimensional vector graphics with support for events and animation.
 *
 * For details about the features and syntax of SVG, a W3C standard,
 * refer to the
 * [Scalable Vector Graphics Specification](http://www.w3.org/TR/SVG/).
 */
library dart.dom.svg;

import 'dart:async';
import 'dart:collection';
import 'dart:_internal';
import 'dart:html';
import 'dart:html_common';
import 'dart:nativewrappers';
import 'dart:_blink' as _blink;
import 'dart:js' as js;
// DO NOT EDIT
// Auto-generated dart:svg library.

// FIXME: Can we make this private?
@Deprecated("Internal Use Only")
final svgBlinkMap = {
  'SVGAElement': () => AElement.instanceRuntimeType,
  'SVGAngle': () => Angle.instanceRuntimeType,
  'SVGAnimateElement': () => AnimateElement.instanceRuntimeType,
  'SVGAnimateMotionElement': () => AnimateMotionElement.instanceRuntimeType,
  'SVGAnimateTransformElement': () =>
      AnimateTransformElement.instanceRuntimeType,
  'SVGAnimatedAngle': () => AnimatedAngle.instanceRuntimeType,
  'SVGAnimatedBoolean': () => AnimatedBoolean.instanceRuntimeType,
  'SVGAnimatedEnumeration': () => AnimatedEnumeration.instanceRuntimeType,
  'SVGAnimatedInteger': () => AnimatedInteger.instanceRuntimeType,
  'SVGAnimatedLength': () => AnimatedLength.instanceRuntimeType,
  'SVGAnimatedLengthList': () => AnimatedLengthList.instanceRuntimeType,
  'SVGAnimatedNumber': () => AnimatedNumber.instanceRuntimeType,
  'SVGAnimatedNumberList': () => AnimatedNumberList.instanceRuntimeType,
  'SVGAnimatedPreserveAspectRatio': () =>
      AnimatedPreserveAspectRatio.instanceRuntimeType,
  'SVGAnimatedRect': () => AnimatedRect.instanceRuntimeType,
  'SVGAnimatedString': () => AnimatedString.instanceRuntimeType,
  'SVGAnimatedTransformList': () => AnimatedTransformList.instanceRuntimeType,
  'SVGAnimationElement': () => AnimationElement.instanceRuntimeType,
  'SVGCircleElement': () => CircleElement.instanceRuntimeType,
  'SVGClipPathElement': () => ClipPathElement.instanceRuntimeType,
  'SVGComponentTransferFunctionElement': () =>
      _SVGComponentTransferFunctionElement.instanceRuntimeType,
  'SVGCursorElement': () => _SVGCursorElement.instanceRuntimeType,
  'SVGDefsElement': () => DefsElement.instanceRuntimeType,
  'SVGDescElement': () => DescElement.instanceRuntimeType,
  'SVGDiscardElement': () => DiscardElement.instanceRuntimeType,
  'SVGElement': () => SvgElement.instanceRuntimeType,
  'SVGEllipseElement': () => EllipseElement.instanceRuntimeType,
  'SVGFEBlendElement': () => FEBlendElement.instanceRuntimeType,
  'SVGFEColorMatrixElement': () => FEColorMatrixElement.instanceRuntimeType,
  'SVGFEComponentTransferElement': () =>
      FEComponentTransferElement.instanceRuntimeType,
  'SVGFECompositeElement': () => FECompositeElement.instanceRuntimeType,
  'SVGFEConvolveMatrixElement': () =>
      FEConvolveMatrixElement.instanceRuntimeType,
  'SVGFEDiffuseLightingElement': () =>
      FEDiffuseLightingElement.instanceRuntimeType,
  'SVGFEDisplacementMapElement': () =>
      FEDisplacementMapElement.instanceRuntimeType,
  'SVGFEDistantLightElement': () => FEDistantLightElement.instanceRuntimeType,
  'SVGFEDropShadowElement': () => _SVGFEDropShadowElement.instanceRuntimeType,
  'SVGFEFloodElement': () => FEFloodElement.instanceRuntimeType,
  'SVGFEFuncAElement': () => FEFuncAElement.instanceRuntimeType,
  'SVGFEFuncBElement': () => FEFuncBElement.instanceRuntimeType,
  'SVGFEFuncGElement': () => FEFuncGElement.instanceRuntimeType,
  'SVGFEFuncRElement': () => FEFuncRElement.instanceRuntimeType,
  'SVGFEGaussianBlurElement': () => FEGaussianBlurElement.instanceRuntimeType,
  'SVGFEImageElement': () => FEImageElement.instanceRuntimeType,
  'SVGFEMergeElement': () => FEMergeElement.instanceRuntimeType,
  'SVGFEMergeNodeElement': () => FEMergeNodeElement.instanceRuntimeType,
  'SVGFEMorphologyElement': () => FEMorphologyElement.instanceRuntimeType,
  'SVGFEOffsetElement': () => FEOffsetElement.instanceRuntimeType,
  'SVGFEPointLightElement': () => FEPointLightElement.instanceRuntimeType,
  'SVGFESpecularLightingElement': () =>
      FESpecularLightingElement.instanceRuntimeType,
  'SVGFESpotLightElement': () => FESpotLightElement.instanceRuntimeType,
  'SVGFETileElement': () => FETileElement.instanceRuntimeType,
  'SVGFETurbulenceElement': () => FETurbulenceElement.instanceRuntimeType,
  'SVGFilterElement': () => FilterElement.instanceRuntimeType,
  'SVGFilterPrimitiveStandardAttributes': () =>
      FilterPrimitiveStandardAttributes.instanceRuntimeType,
  'SVGFitToViewBox': () => FitToViewBox.instanceRuntimeType,
  'SVGForeignObjectElement': () => ForeignObjectElement.instanceRuntimeType,
  'SVGGElement': () => GElement.instanceRuntimeType,
  'SVGGeometryElement': () => GeometryElement.instanceRuntimeType,
  'SVGGradientElement': () => _GradientElement.instanceRuntimeType,
  'SVGGraphicsElement': () => GraphicsElement.instanceRuntimeType,
  'SVGImageElement': () => ImageElement.instanceRuntimeType,
  'SVGLength': () => Length.instanceRuntimeType,
  'SVGLengthList': () => LengthList.instanceRuntimeType,
  'SVGLineElement': () => LineElement.instanceRuntimeType,
  'SVGLinearGradientElement': () => LinearGradientElement.instanceRuntimeType,
  'SVGMPathElement': () => _SVGMPathElement.instanceRuntimeType,
  'SVGMarkerElement': () => MarkerElement.instanceRuntimeType,
  'SVGMaskElement': () => MaskElement.instanceRuntimeType,
  'SVGMatrix': () => Matrix.instanceRuntimeType,
  'SVGMetadataElement': () => MetadataElement.instanceRuntimeType,
  'SVGNumber': () => Number.instanceRuntimeType,
  'SVGNumberList': () => NumberList.instanceRuntimeType,
  'SVGPathElement': () => PathElement.instanceRuntimeType,
  'SVGPathSeg': () => PathSeg.instanceRuntimeType,
  'SVGPathSegArcAbs': () => PathSegArcAbs.instanceRuntimeType,
  'SVGPathSegArcRel': () => PathSegArcRel.instanceRuntimeType,
  'SVGPathSegClosePath': () => PathSegClosePath.instanceRuntimeType,
  'SVGPathSegCurvetoCubicAbs': () => PathSegCurvetoCubicAbs.instanceRuntimeType,
  'SVGPathSegCurvetoCubicRel': () => PathSegCurvetoCubicRel.instanceRuntimeType,
  'SVGPathSegCurvetoCubicSmoothAbs': () =>
      PathSegCurvetoCubicSmoothAbs.instanceRuntimeType,
  'SVGPathSegCurvetoCubicSmoothRel': () =>
      PathSegCurvetoCubicSmoothRel.instanceRuntimeType,
  'SVGPathSegCurvetoQuadraticAbs': () =>
      PathSegCurvetoQuadraticAbs.instanceRuntimeType,
  'SVGPathSegCurvetoQuadraticRel': () =>
      PathSegCurvetoQuadraticRel.instanceRuntimeType,
  'SVGPathSegCurvetoQuadraticSmoothAbs': () =>
      PathSegCurvetoQuadraticSmoothAbs.instanceRuntimeType,
  'SVGPathSegCurvetoQuadraticSmoothRel': () =>
      PathSegCurvetoQuadraticSmoothRel.instanceRuntimeType,
  'SVGPathSegLinetoAbs': () => PathSegLinetoAbs.instanceRuntimeType,
  'SVGPathSegLinetoHorizontalAbs': () =>
      PathSegLinetoHorizontalAbs.instanceRuntimeType,
  'SVGPathSegLinetoHorizontalRel': () =>
      PathSegLinetoHorizontalRel.instanceRuntimeType,
  'SVGPathSegLinetoRel': () => PathSegLinetoRel.instanceRuntimeType,
  'SVGPathSegLinetoVerticalAbs': () =>
      PathSegLinetoVerticalAbs.instanceRuntimeType,
  'SVGPathSegLinetoVerticalRel': () =>
      PathSegLinetoVerticalRel.instanceRuntimeType,
  'SVGPathSegList': () => PathSegList.instanceRuntimeType,
  'SVGPathSegMovetoAbs': () => PathSegMovetoAbs.instanceRuntimeType,
  'SVGPathSegMovetoRel': () => PathSegMovetoRel.instanceRuntimeType,
  'SVGPatternElement': () => PatternElement.instanceRuntimeType,
  'SVGPoint': () => Point.instanceRuntimeType,
  'SVGPointList': () => PointList.instanceRuntimeType,
  'SVGPolygonElement': () => PolygonElement.instanceRuntimeType,
  'SVGPolylineElement': () => PolylineElement.instanceRuntimeType,
  'SVGPreserveAspectRatio': () => PreserveAspectRatio.instanceRuntimeType,
  'SVGRadialGradientElement': () => RadialGradientElement.instanceRuntimeType,
  'SVGRect': () => Rect.instanceRuntimeType,
  'SVGRectElement': () => RectElement.instanceRuntimeType,
  'SVGSVGElement': () => SvgSvgElement.instanceRuntimeType,
  'SVGScriptElement': () => ScriptElement.instanceRuntimeType,
  'SVGSetElement': () => SetElement.instanceRuntimeType,
  'SVGStopElement': () => StopElement.instanceRuntimeType,
  'SVGStringList': () => StringList.instanceRuntimeType,
  'SVGStyleElement': () => StyleElement.instanceRuntimeType,
  'SVGSwitchElement': () => SwitchElement.instanceRuntimeType,
  'SVGSymbolElement': () => SymbolElement.instanceRuntimeType,
  'SVGTSpanElement': () => TSpanElement.instanceRuntimeType,
  'SVGTests': () => Tests.instanceRuntimeType,
  'SVGTextContentElement': () => TextContentElement.instanceRuntimeType,
  'SVGTextElement': () => TextElement.instanceRuntimeType,
  'SVGTextPathElement': () => TextPathElement.instanceRuntimeType,
  'SVGTextPositioningElement': () => TextPositioningElement.instanceRuntimeType,
  'SVGTitleElement': () => TitleElement.instanceRuntimeType,
  'SVGTransform': () => Transform.instanceRuntimeType,
  'SVGTransformList': () => TransformList.instanceRuntimeType,
  'SVGURIReference': () => UriReference.instanceRuntimeType,
  'SVGUnitTypes': () => UnitTypes.instanceRuntimeType,
  'SVGUseElement': () => UseElement.instanceRuntimeType,
  'SVGViewElement': () => ViewElement.instanceRuntimeType,
  'SVGViewSpec': () => ViewSpec.instanceRuntimeType,
  'SVGZoomAndPan': () => ZoomAndPan.instanceRuntimeType,
  'SVGZoomEvent': () => ZoomEvent.instanceRuntimeType,
};
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _SvgElementFactoryProvider {
  static SvgElement createSvgElement_tag(String tag) {
    final Element temp =
        document.createElementNS("http://www.w3.org/2000/svg", tag);
    return temp;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGAElement')
@Unstable()
class AElement extends GraphicsElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory AElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGAElement.SVGAElement')
  @DocsEditable()
  factory AElement() => _SvgElementFactoryProvider.createSvgElement_tag("a");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  AElement.created() : super.created();

  @DomName('SVGAElement.target')
  @DocsEditable()
  AnimatedString get target =>
      _blink.BlinkSVGAElement.instance.target_Getter_(this);

  @DomName('SVGAElement.href')
  @DocsEditable()
  AnimatedString get href =>
      _blink.BlinkSVGAElement.instance.href_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGAngle')
@Unstable()
class Angle extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory Angle._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  Angle.internal_() {}

  @DomName('SVGAngle.SVG_ANGLETYPE_DEG')
  @DocsEditable()
  static const int SVG_ANGLETYPE_DEG = 2;

  @DomName('SVGAngle.SVG_ANGLETYPE_GRAD')
  @DocsEditable()
  static const int SVG_ANGLETYPE_GRAD = 4;

  @DomName('SVGAngle.SVG_ANGLETYPE_RAD')
  @DocsEditable()
  static const int SVG_ANGLETYPE_RAD = 3;

  @DomName('SVGAngle.SVG_ANGLETYPE_UNKNOWN')
  @DocsEditable()
  static const int SVG_ANGLETYPE_UNKNOWN = 0;

  @DomName('SVGAngle.SVG_ANGLETYPE_UNSPECIFIED')
  @DocsEditable()
  static const int SVG_ANGLETYPE_UNSPECIFIED = 1;

  @DomName('SVGAngle.unitType')
  @DocsEditable()
  int get unitType => _blink.BlinkSVGAngle.instance.unitType_Getter_(this);

  @DomName('SVGAngle.value')
  @DocsEditable()
  num get value => _blink.BlinkSVGAngle.instance.value_Getter_(this);

  @DomName('SVGAngle.value')
  @DocsEditable()
  set value(num value) =>
      _blink.BlinkSVGAngle.instance.value_Setter_(this, value);

  @DomName('SVGAngle.valueAsString')
  @DocsEditable()
  String get valueAsString =>
      _blink.BlinkSVGAngle.instance.valueAsString_Getter_(this);

  @DomName('SVGAngle.valueAsString')
  @DocsEditable()
  set valueAsString(String value) =>
      _blink.BlinkSVGAngle.instance.valueAsString_Setter_(this, value);

  @DomName('SVGAngle.valueInSpecifiedUnits')
  @DocsEditable()
  num get valueInSpecifiedUnits =>
      _blink.BlinkSVGAngle.instance.valueInSpecifiedUnits_Getter_(this);

  @DomName('SVGAngle.valueInSpecifiedUnits')
  @DocsEditable()
  set valueInSpecifiedUnits(num value) =>
      _blink.BlinkSVGAngle.instance.valueInSpecifiedUnits_Setter_(this, value);

  @DomName('SVGAngle.convertToSpecifiedUnits')
  @DocsEditable()
  void convertToSpecifiedUnits(int unitType) => _blink.BlinkSVGAngle.instance
      .convertToSpecifiedUnits_Callback_1_(this, unitType);

  @DomName('SVGAngle.newValueSpecifiedUnits')
  @DocsEditable()
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) =>
      _blink.BlinkSVGAngle.instance.newValueSpecifiedUnits_Callback_2_(
          this, unitType, valueInSpecifiedUnits);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGAnimateElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class AnimateElement extends AnimationElement {
  // To suppress missing implicit constructor warnings.
  factory AnimateElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGAnimateElement.SVGAnimateElement')
  @DocsEditable()
  factory AnimateElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("animate");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AnimateElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  AnimateElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGAnimateMotionElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class AnimateMotionElement extends AnimationElement {
  // To suppress missing implicit constructor warnings.
  factory AnimateMotionElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGAnimateMotionElement.SVGAnimateMotionElement')
  @DocsEditable()
  factory AnimateMotionElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("animateMotion");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AnimateMotionElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  AnimateMotionElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGAnimateTransformElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class AnimateTransformElement extends AnimationElement {
  // To suppress missing implicit constructor warnings.
  factory AnimateTransformElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGAnimateTransformElement.SVGAnimateTransformElement')
  @DocsEditable()
  factory AnimateTransformElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("animateTransform");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AnimateTransformElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  AnimateTransformElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGAnimatedAngle')
@Unstable()
class AnimatedAngle extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedAngle._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AnimatedAngle.internal_() {}

  @DomName('SVGAnimatedAngle.animVal')
  @DocsEditable()
  Angle get animVal =>
      _blink.BlinkSVGAnimatedAngle.instance.animVal_Getter_(this);

  @DomName('SVGAnimatedAngle.baseVal')
  @DocsEditable()
  Angle get baseVal =>
      _blink.BlinkSVGAnimatedAngle.instance.baseVal_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGAnimatedBoolean')
@Unstable()
class AnimatedBoolean extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedBoolean._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AnimatedBoolean.internal_() {}

  @DomName('SVGAnimatedBoolean.animVal')
  @DocsEditable()
  bool get animVal =>
      _blink.BlinkSVGAnimatedBoolean.instance.animVal_Getter_(this);

  @DomName('SVGAnimatedBoolean.baseVal')
  @DocsEditable()
  bool get baseVal =>
      _blink.BlinkSVGAnimatedBoolean.instance.baseVal_Getter_(this);

  @DomName('SVGAnimatedBoolean.baseVal')
  @DocsEditable()
  set baseVal(bool value) =>
      _blink.BlinkSVGAnimatedBoolean.instance.baseVal_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGAnimatedEnumeration')
@Unstable()
class AnimatedEnumeration extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedEnumeration._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AnimatedEnumeration.internal_() {}

  @DomName('SVGAnimatedEnumeration.animVal')
  @DocsEditable()
  int get animVal =>
      _blink.BlinkSVGAnimatedEnumeration.instance.animVal_Getter_(this);

  @DomName('SVGAnimatedEnumeration.baseVal')
  @DocsEditable()
  int get baseVal =>
      _blink.BlinkSVGAnimatedEnumeration.instance.baseVal_Getter_(this);

  @DomName('SVGAnimatedEnumeration.baseVal')
  @DocsEditable()
  set baseVal(int value) =>
      _blink.BlinkSVGAnimatedEnumeration.instance.baseVal_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGAnimatedInteger')
@Unstable()
class AnimatedInteger extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedInteger._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AnimatedInteger.internal_() {}

  @DomName('SVGAnimatedInteger.animVal')
  @DocsEditable()
  int get animVal =>
      _blink.BlinkSVGAnimatedInteger.instance.animVal_Getter_(this);

  @DomName('SVGAnimatedInteger.baseVal')
  @DocsEditable()
  int get baseVal =>
      _blink.BlinkSVGAnimatedInteger.instance.baseVal_Getter_(this);

  @DomName('SVGAnimatedInteger.baseVal')
  @DocsEditable()
  set baseVal(int value) =>
      _blink.BlinkSVGAnimatedInteger.instance.baseVal_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGAnimatedLength')
@Unstable()
class AnimatedLength extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedLength._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AnimatedLength.internal_() {}

  @DomName('SVGAnimatedLength.animVal')
  @DocsEditable()
  Length get animVal =>
      _blink.BlinkSVGAnimatedLength.instance.animVal_Getter_(this);

  @DomName('SVGAnimatedLength.baseVal')
  @DocsEditable()
  Length get baseVal =>
      _blink.BlinkSVGAnimatedLength.instance.baseVal_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGAnimatedLengthList')
@Unstable()
class AnimatedLengthList extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedLengthList._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AnimatedLengthList.internal_() {}

  @DomName('SVGAnimatedLengthList.animVal')
  @DocsEditable()
  LengthList get animVal =>
      _blink.BlinkSVGAnimatedLengthList.instance.animVal_Getter_(this);

  @DomName('SVGAnimatedLengthList.baseVal')
  @DocsEditable()
  LengthList get baseVal =>
      _blink.BlinkSVGAnimatedLengthList.instance.baseVal_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGAnimatedNumber')
@Unstable()
class AnimatedNumber extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedNumber._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AnimatedNumber.internal_() {}

  @DomName('SVGAnimatedNumber.animVal')
  @DocsEditable()
  num get animVal =>
      _blink.BlinkSVGAnimatedNumber.instance.animVal_Getter_(this);

  @DomName('SVGAnimatedNumber.baseVal')
  @DocsEditable()
  num get baseVal =>
      _blink.BlinkSVGAnimatedNumber.instance.baseVal_Getter_(this);

  @DomName('SVGAnimatedNumber.baseVal')
  @DocsEditable()
  set baseVal(num value) =>
      _blink.BlinkSVGAnimatedNumber.instance.baseVal_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGAnimatedNumberList')
@Unstable()
class AnimatedNumberList extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedNumberList._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AnimatedNumberList.internal_() {}

  @DomName('SVGAnimatedNumberList.animVal')
  @DocsEditable()
  NumberList get animVal =>
      _blink.BlinkSVGAnimatedNumberList.instance.animVal_Getter_(this);

  @DomName('SVGAnimatedNumberList.baseVal')
  @DocsEditable()
  NumberList get baseVal =>
      _blink.BlinkSVGAnimatedNumberList.instance.baseVal_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGAnimatedPreserveAspectRatio')
@Unstable()
class AnimatedPreserveAspectRatio extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedPreserveAspectRatio._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AnimatedPreserveAspectRatio.internal_() {}

  @DomName('SVGAnimatedPreserveAspectRatio.animVal')
  @DocsEditable()
  PreserveAspectRatio get animVal =>
      _blink.BlinkSVGAnimatedPreserveAspectRatio.instance.animVal_Getter_(this);

  @DomName('SVGAnimatedPreserveAspectRatio.baseVal')
  @DocsEditable()
  PreserveAspectRatio get baseVal =>
      _blink.BlinkSVGAnimatedPreserveAspectRatio.instance.baseVal_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGAnimatedRect')
@Unstable()
class AnimatedRect extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedRect._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AnimatedRect.internal_() {}

  @DomName('SVGAnimatedRect.animVal')
  @DocsEditable()
  Rect get animVal =>
      _blink.BlinkSVGAnimatedRect.instance.animVal_Getter_(this);

  @DomName('SVGAnimatedRect.baseVal')
  @DocsEditable()
  Rect get baseVal =>
      _blink.BlinkSVGAnimatedRect.instance.baseVal_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGAnimatedString')
@Unstable()
class AnimatedString extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedString._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AnimatedString.internal_() {}

  @DomName('SVGAnimatedString.animVal')
  @DocsEditable()
  String get animVal =>
      _blink.BlinkSVGAnimatedString.instance.animVal_Getter_(this);

  @DomName('SVGAnimatedString.baseVal')
  @DocsEditable()
  String get baseVal =>
      _blink.BlinkSVGAnimatedString.instance.baseVal_Getter_(this);

  @DomName('SVGAnimatedString.baseVal')
  @DocsEditable()
  set baseVal(String value) =>
      _blink.BlinkSVGAnimatedString.instance.baseVal_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGAnimatedTransformList')
@Unstable()
class AnimatedTransformList extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory AnimatedTransformList._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AnimatedTransformList.internal_() {}

  @DomName('SVGAnimatedTransformList.animVal')
  @DocsEditable()
  TransformList get animVal =>
      _blink.BlinkSVGAnimatedTransformList.instance.animVal_Getter_(this);

  @DomName('SVGAnimatedTransformList.baseVal')
  @DocsEditable()
  TransformList get baseVal =>
      _blink.BlinkSVGAnimatedTransformList.instance.baseVal_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGAnimationElement')
@Unstable()
class AnimationElement extends SvgElement implements Tests {
  // To suppress missing implicit constructor warnings.
  factory AnimationElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGAnimationElement.SVGAnimationElement')
  @DocsEditable()
  factory AnimationElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("animation");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  AnimationElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  AnimationElement.created() : super.created();

  @DomName('SVGAnimationElement.targetElement')
  @DocsEditable()
  SvgElement get targetElement =>
      _blink.BlinkSVGAnimationElement.instance.targetElement_Getter_(this);

  @DomName('SVGAnimationElement.beginElement')
  @DocsEditable()
  void beginElement() =>
      _blink.BlinkSVGAnimationElement.instance.beginElement_Callback_0_(this);

  @DomName('SVGAnimationElement.beginElementAt')
  @DocsEditable()
  void beginElementAt(num offset) => _blink.BlinkSVGAnimationElement.instance
      .beginElementAt_Callback_1_(this, offset);

  @DomName('SVGAnimationElement.endElement')
  @DocsEditable()
  void endElement() =>
      _blink.BlinkSVGAnimationElement.instance.endElement_Callback_0_(this);

  @DomName('SVGAnimationElement.endElementAt')
  @DocsEditable()
  void endElementAt(num offset) => _blink.BlinkSVGAnimationElement.instance
      .endElementAt_Callback_1_(this, offset);

  @DomName('SVGAnimationElement.getCurrentTime')
  @DocsEditable()
  num getCurrentTime() =>
      _blink.BlinkSVGAnimationElement.instance.getCurrentTime_Callback_0_(this);

  @DomName('SVGAnimationElement.getSimpleDuration')
  @DocsEditable()
  num getSimpleDuration() => _blink.BlinkSVGAnimationElement.instance
      .getSimpleDuration_Callback_0_(this);

  @DomName('SVGAnimationElement.getStartTime')
  @DocsEditable()
  num getStartTime() =>
      _blink.BlinkSVGAnimationElement.instance.getStartTime_Callback_0_(this);

  @DomName('SVGAnimationElement.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions =>
      _blink.BlinkSVGAnimationElement.instance.requiredExtensions_Getter_(this);

  @DomName('SVGAnimationElement.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures =>
      _blink.BlinkSVGAnimationElement.instance.requiredFeatures_Getter_(this);

  @DomName('SVGAnimationElement.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage =>
      _blink.BlinkSVGAnimationElement.instance.systemLanguage_Getter_(this);

  @DomName('SVGAnimationElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) =>
      _blink.BlinkSVGAnimationElement.instance
          .hasExtension_Callback_1_(this, extension);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGCircleElement')
@Unstable()
class CircleElement extends GeometryElement {
  // To suppress missing implicit constructor warnings.
  factory CircleElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGCircleElement.SVGCircleElement')
  @DocsEditable()
  factory CircleElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("circle");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  CircleElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  CircleElement.created() : super.created();

  @DomName('SVGCircleElement.cx')
  @DocsEditable()
  AnimatedLength get cx =>
      _blink.BlinkSVGCircleElement.instance.cx_Getter_(this);

  @DomName('SVGCircleElement.cy')
  @DocsEditable()
  AnimatedLength get cy =>
      _blink.BlinkSVGCircleElement.instance.cy_Getter_(this);

  @DomName('SVGCircleElement.r')
  @DocsEditable()
  AnimatedLength get r => _blink.BlinkSVGCircleElement.instance.r_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGClipPathElement')
@Unstable()
class ClipPathElement extends GraphicsElement {
  // To suppress missing implicit constructor warnings.
  factory ClipPathElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGClipPathElement.SVGClipPathElement')
  @DocsEditable()
  factory ClipPathElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("clipPath");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  ClipPathElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  ClipPathElement.created() : super.created();

  @DomName('SVGClipPathElement.clipPathUnits')
  @DocsEditable()
  AnimatedEnumeration get clipPathUnits =>
      _blink.BlinkSVGClipPathElement.instance.clipPathUnits_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGDefsElement')
@Unstable()
class DefsElement extends GraphicsElement {
  // To suppress missing implicit constructor warnings.
  factory DefsElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGDefsElement.SVGDefsElement')
  @DocsEditable()
  factory DefsElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("defs");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  DefsElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  DefsElement.created() : super.created();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGDescElement')
@Unstable()
class DescElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory DescElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGDescElement.SVGDescElement')
  @DocsEditable()
  factory DescElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("desc");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  DescElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  DescElement.created() : super.created();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGDiscardElement')
@Experimental() // untriaged
class DiscardElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory DiscardElement._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  DiscardElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  DiscardElement.created() : super.created();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGEllipseElement')
@Unstable()
class EllipseElement extends GeometryElement {
  // To suppress missing implicit constructor warnings.
  factory EllipseElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGEllipseElement.SVGEllipseElement')
  @DocsEditable()
  factory EllipseElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("ellipse");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  EllipseElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  EllipseElement.created() : super.created();

  @DomName('SVGEllipseElement.cx')
  @DocsEditable()
  AnimatedLength get cx =>
      _blink.BlinkSVGEllipseElement.instance.cx_Getter_(this);

  @DomName('SVGEllipseElement.cy')
  @DocsEditable()
  AnimatedLength get cy =>
      _blink.BlinkSVGEllipseElement.instance.cy_Getter_(this);

  @DomName('SVGEllipseElement.rx')
  @DocsEditable()
  AnimatedLength get rx =>
      _blink.BlinkSVGEllipseElement.instance.rx_Getter_(this);

  @DomName('SVGEllipseElement.ry')
  @DocsEditable()
  AnimatedLength get ry =>
      _blink.BlinkSVGEllipseElement.instance.ry_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEBlendElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEBlendElement extends SvgElement
    implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEBlendElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFEBlendElement.SVGFEBlendElement')
  @DocsEditable()
  factory FEBlendElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feBlend");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEBlendElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEBlendElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEBlendElement.SVG_FEBLEND_MODE_DARKEN')
  @DocsEditable()
  static const int SVG_FEBLEND_MODE_DARKEN = 4;

  @DomName('SVGFEBlendElement.SVG_FEBLEND_MODE_LIGHTEN')
  @DocsEditable()
  static const int SVG_FEBLEND_MODE_LIGHTEN = 5;

  @DomName('SVGFEBlendElement.SVG_FEBLEND_MODE_MULTIPLY')
  @DocsEditable()
  static const int SVG_FEBLEND_MODE_MULTIPLY = 2;

  @DomName('SVGFEBlendElement.SVG_FEBLEND_MODE_NORMAL')
  @DocsEditable()
  static const int SVG_FEBLEND_MODE_NORMAL = 1;

  @DomName('SVGFEBlendElement.SVG_FEBLEND_MODE_SCREEN')
  @DocsEditable()
  static const int SVG_FEBLEND_MODE_SCREEN = 3;

  @DomName('SVGFEBlendElement.SVG_FEBLEND_MODE_UNKNOWN')
  @DocsEditable()
  static const int SVG_FEBLEND_MODE_UNKNOWN = 0;

  @DomName('SVGFEBlendElement.in1')
  @DocsEditable()
  AnimatedString get in1 =>
      _blink.BlinkSVGFEBlendElement.instance.in1_Getter_(this);

  @DomName('SVGFEBlendElement.in2')
  @DocsEditable()
  AnimatedString get in2 =>
      _blink.BlinkSVGFEBlendElement.instance.in2_Getter_(this);

  @DomName('SVGFEBlendElement.mode')
  @DocsEditable()
  AnimatedEnumeration get mode =>
      _blink.BlinkSVGFEBlendElement.instance.mode_Getter_(this);

  @DomName('SVGFEBlendElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGFEBlendElement.instance.height_Getter_(this);

  @DomName('SVGFEBlendElement.result')
  @DocsEditable()
  AnimatedString get result =>
      _blink.BlinkSVGFEBlendElement.instance.result_Getter_(this);

  @DomName('SVGFEBlendElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGFEBlendElement.instance.width_Getter_(this);

  @DomName('SVGFEBlendElement.x')
  @DocsEditable()
  AnimatedLength get x =>
      _blink.BlinkSVGFEBlendElement.instance.x_Getter_(this);

  @DomName('SVGFEBlendElement.y')
  @DocsEditable()
  AnimatedLength get y =>
      _blink.BlinkSVGFEBlendElement.instance.y_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEColorMatrixElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEColorMatrixElement extends SvgElement
    implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEColorMatrixElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFEColorMatrixElement.SVGFEColorMatrixElement')
  @DocsEditable()
  factory FEColorMatrixElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feColorMatrix");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEColorMatrixElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEColorMatrixElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_HUEROTATE')
  @DocsEditable()
  static const int SVG_FECOLORMATRIX_TYPE_HUEROTATE = 3;

  @DomName('SVGFEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA')
  @DocsEditable()
  static const int SVG_FECOLORMATRIX_TYPE_LUMINANCETOALPHA = 4;

  @DomName('SVGFEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_MATRIX')
  @DocsEditable()
  static const int SVG_FECOLORMATRIX_TYPE_MATRIX = 1;

  @DomName('SVGFEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_SATURATE')
  @DocsEditable()
  static const int SVG_FECOLORMATRIX_TYPE_SATURATE = 2;

  @DomName('SVGFEColorMatrixElement.SVG_FECOLORMATRIX_TYPE_UNKNOWN')
  @DocsEditable()
  static const int SVG_FECOLORMATRIX_TYPE_UNKNOWN = 0;

  @DomName('SVGFEColorMatrixElement.in1')
  @DocsEditable()
  AnimatedString get in1 =>
      _blink.BlinkSVGFEColorMatrixElement.instance.in1_Getter_(this);

  @DomName('SVGFEColorMatrixElement.type')
  @DocsEditable()
  AnimatedEnumeration get type =>
      _blink.BlinkSVGFEColorMatrixElement.instance.type_Getter_(this);

  @DomName('SVGFEColorMatrixElement.values')
  @DocsEditable()
  AnimatedNumberList get values =>
      _blink.BlinkSVGFEColorMatrixElement.instance.values_Getter_(this);

  @DomName('SVGFEColorMatrixElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGFEColorMatrixElement.instance.height_Getter_(this);

  @DomName('SVGFEColorMatrixElement.result')
  @DocsEditable()
  AnimatedString get result =>
      _blink.BlinkSVGFEColorMatrixElement.instance.result_Getter_(this);

  @DomName('SVGFEColorMatrixElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGFEColorMatrixElement.instance.width_Getter_(this);

  @DomName('SVGFEColorMatrixElement.x')
  @DocsEditable()
  AnimatedLength get x =>
      _blink.BlinkSVGFEColorMatrixElement.instance.x_Getter_(this);

  @DomName('SVGFEColorMatrixElement.y')
  @DocsEditable()
  AnimatedLength get y =>
      _blink.BlinkSVGFEColorMatrixElement.instance.y_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEComponentTransferElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEComponentTransferElement extends SvgElement
    implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEComponentTransferElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFEComponentTransferElement.SVGFEComponentTransferElement')
  @DocsEditable()
  factory FEComponentTransferElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feComponentTransfer");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEComponentTransferElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEComponentTransferElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEComponentTransferElement.in1')
  @DocsEditable()
  AnimatedString get in1 =>
      _blink.BlinkSVGFEComponentTransferElement.instance.in1_Getter_(this);

  @DomName('SVGFEComponentTransferElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGFEComponentTransferElement.instance.height_Getter_(this);

  @DomName('SVGFEComponentTransferElement.result')
  @DocsEditable()
  AnimatedString get result =>
      _blink.BlinkSVGFEComponentTransferElement.instance.result_Getter_(this);

  @DomName('SVGFEComponentTransferElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGFEComponentTransferElement.instance.width_Getter_(this);

  @DomName('SVGFEComponentTransferElement.x')
  @DocsEditable()
  AnimatedLength get x =>
      _blink.BlinkSVGFEComponentTransferElement.instance.x_Getter_(this);

  @DomName('SVGFEComponentTransferElement.y')
  @DocsEditable()
  AnimatedLength get y =>
      _blink.BlinkSVGFEComponentTransferElement.instance.y_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFECompositeElement')
@Unstable()
class FECompositeElement extends SvgElement
    implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FECompositeElement._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FECompositeElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FECompositeElement.created() : super.created();

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_ARITHMETIC')
  @DocsEditable()
  static const int SVG_FECOMPOSITE_OPERATOR_ARITHMETIC = 6;

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_ATOP')
  @DocsEditable()
  static const int SVG_FECOMPOSITE_OPERATOR_ATOP = 4;

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_IN')
  @DocsEditable()
  static const int SVG_FECOMPOSITE_OPERATOR_IN = 2;

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_OUT')
  @DocsEditable()
  static const int SVG_FECOMPOSITE_OPERATOR_OUT = 3;

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_OVER')
  @DocsEditable()
  static const int SVG_FECOMPOSITE_OPERATOR_OVER = 1;

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_UNKNOWN')
  @DocsEditable()
  static const int SVG_FECOMPOSITE_OPERATOR_UNKNOWN = 0;

  @DomName('SVGFECompositeElement.SVG_FECOMPOSITE_OPERATOR_XOR')
  @DocsEditable()
  static const int SVG_FECOMPOSITE_OPERATOR_XOR = 5;

  @DomName('SVGFECompositeElement.in1')
  @DocsEditable()
  AnimatedString get in1 =>
      _blink.BlinkSVGFECompositeElement.instance.in1_Getter_(this);

  @DomName('SVGFECompositeElement.in2')
  @DocsEditable()
  AnimatedString get in2 =>
      _blink.BlinkSVGFECompositeElement.instance.in2_Getter_(this);

  @DomName('SVGFECompositeElement.k1')
  @DocsEditable()
  AnimatedNumber get k1 =>
      _blink.BlinkSVGFECompositeElement.instance.k1_Getter_(this);

  @DomName('SVGFECompositeElement.k2')
  @DocsEditable()
  AnimatedNumber get k2 =>
      _blink.BlinkSVGFECompositeElement.instance.k2_Getter_(this);

  @DomName('SVGFECompositeElement.k3')
  @DocsEditable()
  AnimatedNumber get k3 =>
      _blink.BlinkSVGFECompositeElement.instance.k3_Getter_(this);

  @DomName('SVGFECompositeElement.k4')
  @DocsEditable()
  AnimatedNumber get k4 =>
      _blink.BlinkSVGFECompositeElement.instance.k4_Getter_(this);

  @DomName('SVGFECompositeElement.operator')
  @DocsEditable()
  AnimatedEnumeration get operator =>
      _blink.BlinkSVGFECompositeElement.instance.operator_Getter_(this);

  @DomName('SVGFECompositeElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGFECompositeElement.instance.height_Getter_(this);

  @DomName('SVGFECompositeElement.result')
  @DocsEditable()
  AnimatedString get result =>
      _blink.BlinkSVGFECompositeElement.instance.result_Getter_(this);

  @DomName('SVGFECompositeElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGFECompositeElement.instance.width_Getter_(this);

  @DomName('SVGFECompositeElement.x')
  @DocsEditable()
  AnimatedLength get x =>
      _blink.BlinkSVGFECompositeElement.instance.x_Getter_(this);

  @DomName('SVGFECompositeElement.y')
  @DocsEditable()
  AnimatedLength get y =>
      _blink.BlinkSVGFECompositeElement.instance.y_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEConvolveMatrixElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEConvolveMatrixElement extends SvgElement
    implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEConvolveMatrixElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFEConvolveMatrixElement.SVGFEConvolveMatrixElement')
  @DocsEditable()
  factory FEConvolveMatrixElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feConvolveMatrix");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEConvolveMatrixElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEConvolveMatrixElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEConvolveMatrixElement.SVG_EDGEMODE_DUPLICATE')
  @DocsEditable()
  static const int SVG_EDGEMODE_DUPLICATE = 1;

  @DomName('SVGFEConvolveMatrixElement.SVG_EDGEMODE_NONE')
  @DocsEditable()
  static const int SVG_EDGEMODE_NONE = 3;

  @DomName('SVGFEConvolveMatrixElement.SVG_EDGEMODE_UNKNOWN')
  @DocsEditable()
  static const int SVG_EDGEMODE_UNKNOWN = 0;

  @DomName('SVGFEConvolveMatrixElement.SVG_EDGEMODE_WRAP')
  @DocsEditable()
  static const int SVG_EDGEMODE_WRAP = 2;

  @DomName('SVGFEConvolveMatrixElement.bias')
  @DocsEditable()
  AnimatedNumber get bias =>
      _blink.BlinkSVGFEConvolveMatrixElement.instance.bias_Getter_(this);

  @DomName('SVGFEConvolveMatrixElement.divisor')
  @DocsEditable()
  AnimatedNumber get divisor =>
      _blink.BlinkSVGFEConvolveMatrixElement.instance.divisor_Getter_(this);

  @DomName('SVGFEConvolveMatrixElement.edgeMode')
  @DocsEditable()
  AnimatedEnumeration get edgeMode =>
      _blink.BlinkSVGFEConvolveMatrixElement.instance.edgeMode_Getter_(this);

  @DomName('SVGFEConvolveMatrixElement.in1')
  @DocsEditable()
  AnimatedString get in1 =>
      _blink.BlinkSVGFEConvolveMatrixElement.instance.in1_Getter_(this);

  @DomName('SVGFEConvolveMatrixElement.kernelMatrix')
  @DocsEditable()
  AnimatedNumberList get kernelMatrix =>
      _blink.BlinkSVGFEConvolveMatrixElement.instance
          .kernelMatrix_Getter_(this);

  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthX')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthX =>
      _blink.BlinkSVGFEConvolveMatrixElement.instance
          .kernelUnitLengthX_Getter_(this);

  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthY')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthY =>
      _blink.BlinkSVGFEConvolveMatrixElement.instance
          .kernelUnitLengthY_Getter_(this);

  @DomName('SVGFEConvolveMatrixElement.orderX')
  @DocsEditable()
  AnimatedInteger get orderX =>
      _blink.BlinkSVGFEConvolveMatrixElement.instance.orderX_Getter_(this);

  @DomName('SVGFEConvolveMatrixElement.orderY')
  @DocsEditable()
  AnimatedInteger get orderY =>
      _blink.BlinkSVGFEConvolveMatrixElement.instance.orderY_Getter_(this);

  @DomName('SVGFEConvolveMatrixElement.preserveAlpha')
  @DocsEditable()
  AnimatedBoolean get preserveAlpha =>
      _blink.BlinkSVGFEConvolveMatrixElement.instance
          .preserveAlpha_Getter_(this);

  @DomName('SVGFEConvolveMatrixElement.targetX')
  @DocsEditable()
  AnimatedInteger get targetX =>
      _blink.BlinkSVGFEConvolveMatrixElement.instance.targetX_Getter_(this);

  @DomName('SVGFEConvolveMatrixElement.targetY')
  @DocsEditable()
  AnimatedInteger get targetY =>
      _blink.BlinkSVGFEConvolveMatrixElement.instance.targetY_Getter_(this);

  @DomName('SVGFEConvolveMatrixElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGFEConvolveMatrixElement.instance.height_Getter_(this);

  @DomName('SVGFEConvolveMatrixElement.result')
  @DocsEditable()
  AnimatedString get result =>
      _blink.BlinkSVGFEConvolveMatrixElement.instance.result_Getter_(this);

  @DomName('SVGFEConvolveMatrixElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGFEConvolveMatrixElement.instance.width_Getter_(this);

  @DomName('SVGFEConvolveMatrixElement.x')
  @DocsEditable()
  AnimatedLength get x =>
      _blink.BlinkSVGFEConvolveMatrixElement.instance.x_Getter_(this);

  @DomName('SVGFEConvolveMatrixElement.y')
  @DocsEditable()
  AnimatedLength get y =>
      _blink.BlinkSVGFEConvolveMatrixElement.instance.y_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEDiffuseLightingElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEDiffuseLightingElement extends SvgElement
    implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEDiffuseLightingElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFEDiffuseLightingElement.SVGFEDiffuseLightingElement')
  @DocsEditable()
  factory FEDiffuseLightingElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feDiffuseLighting");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEDiffuseLightingElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEDiffuseLightingElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEDiffuseLightingElement.diffuseConstant')
  @DocsEditable()
  AnimatedNumber get diffuseConstant =>
      _blink.BlinkSVGFEDiffuseLightingElement.instance
          .diffuseConstant_Getter_(this);

  @DomName('SVGFEDiffuseLightingElement.in1')
  @DocsEditable()
  AnimatedString get in1 =>
      _blink.BlinkSVGFEDiffuseLightingElement.instance.in1_Getter_(this);

  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthX')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthX =>
      _blink.BlinkSVGFEDiffuseLightingElement.instance
          .kernelUnitLengthX_Getter_(this);

  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthY')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthY =>
      _blink.BlinkSVGFEDiffuseLightingElement.instance
          .kernelUnitLengthY_Getter_(this);

  @DomName('SVGFEDiffuseLightingElement.surfaceScale')
  @DocsEditable()
  AnimatedNumber get surfaceScale =>
      _blink.BlinkSVGFEDiffuseLightingElement.instance
          .surfaceScale_Getter_(this);

  @DomName('SVGFEDiffuseLightingElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGFEDiffuseLightingElement.instance.height_Getter_(this);

  @DomName('SVGFEDiffuseLightingElement.result')
  @DocsEditable()
  AnimatedString get result =>
      _blink.BlinkSVGFEDiffuseLightingElement.instance.result_Getter_(this);

  @DomName('SVGFEDiffuseLightingElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGFEDiffuseLightingElement.instance.width_Getter_(this);

  @DomName('SVGFEDiffuseLightingElement.x')
  @DocsEditable()
  AnimatedLength get x =>
      _blink.BlinkSVGFEDiffuseLightingElement.instance.x_Getter_(this);

  @DomName('SVGFEDiffuseLightingElement.y')
  @DocsEditable()
  AnimatedLength get y =>
      _blink.BlinkSVGFEDiffuseLightingElement.instance.y_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEDisplacementMapElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEDisplacementMapElement extends SvgElement
    implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEDisplacementMapElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFEDisplacementMapElement.SVGFEDisplacementMapElement')
  @DocsEditable()
  factory FEDisplacementMapElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feDisplacementMap");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEDisplacementMapElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEDisplacementMapElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEDisplacementMapElement.SVG_CHANNEL_A')
  @DocsEditable()
  static const int SVG_CHANNEL_A = 4;

  @DomName('SVGFEDisplacementMapElement.SVG_CHANNEL_B')
  @DocsEditable()
  static const int SVG_CHANNEL_B = 3;

  @DomName('SVGFEDisplacementMapElement.SVG_CHANNEL_G')
  @DocsEditable()
  static const int SVG_CHANNEL_G = 2;

  @DomName('SVGFEDisplacementMapElement.SVG_CHANNEL_R')
  @DocsEditable()
  static const int SVG_CHANNEL_R = 1;

  @DomName('SVGFEDisplacementMapElement.SVG_CHANNEL_UNKNOWN')
  @DocsEditable()
  static const int SVG_CHANNEL_UNKNOWN = 0;

  @DomName('SVGFEDisplacementMapElement.in1')
  @DocsEditable()
  AnimatedString get in1 =>
      _blink.BlinkSVGFEDisplacementMapElement.instance.in1_Getter_(this);

  @DomName('SVGFEDisplacementMapElement.in2')
  @DocsEditable()
  AnimatedString get in2 =>
      _blink.BlinkSVGFEDisplacementMapElement.instance.in2_Getter_(this);

  @DomName('SVGFEDisplacementMapElement.scale')
  @DocsEditable()
  AnimatedNumber get scale =>
      _blink.BlinkSVGFEDisplacementMapElement.instance.scale_Getter_(this);

  @DomName('SVGFEDisplacementMapElement.xChannelSelector')
  @DocsEditable()
  AnimatedEnumeration get xChannelSelector =>
      _blink.BlinkSVGFEDisplacementMapElement.instance
          .xChannelSelector_Getter_(this);

  @DomName('SVGFEDisplacementMapElement.yChannelSelector')
  @DocsEditable()
  AnimatedEnumeration get yChannelSelector =>
      _blink.BlinkSVGFEDisplacementMapElement.instance
          .yChannelSelector_Getter_(this);

  @DomName('SVGFEDisplacementMapElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGFEDisplacementMapElement.instance.height_Getter_(this);

  @DomName('SVGFEDisplacementMapElement.result')
  @DocsEditable()
  AnimatedString get result =>
      _blink.BlinkSVGFEDisplacementMapElement.instance.result_Getter_(this);

  @DomName('SVGFEDisplacementMapElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGFEDisplacementMapElement.instance.width_Getter_(this);

  @DomName('SVGFEDisplacementMapElement.x')
  @DocsEditable()
  AnimatedLength get x =>
      _blink.BlinkSVGFEDisplacementMapElement.instance.x_Getter_(this);

  @DomName('SVGFEDisplacementMapElement.y')
  @DocsEditable()
  AnimatedLength get y =>
      _blink.BlinkSVGFEDisplacementMapElement.instance.y_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEDistantLightElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEDistantLightElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory FEDistantLightElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFEDistantLightElement.SVGFEDistantLightElement')
  @DocsEditable()
  factory FEDistantLightElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feDistantLight");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEDistantLightElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEDistantLightElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEDistantLightElement.azimuth')
  @DocsEditable()
  AnimatedNumber get azimuth =>
      _blink.BlinkSVGFEDistantLightElement.instance.azimuth_Getter_(this);

  @DomName('SVGFEDistantLightElement.elevation')
  @DocsEditable()
  AnimatedNumber get elevation =>
      _blink.BlinkSVGFEDistantLightElement.instance.elevation_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEFloodElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEFloodElement extends SvgElement
    implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEFloodElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFEFloodElement.SVGFEFloodElement')
  @DocsEditable()
  factory FEFloodElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feFlood");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEFloodElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEFloodElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEFloodElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGFEFloodElement.instance.height_Getter_(this);

  @DomName('SVGFEFloodElement.result')
  @DocsEditable()
  AnimatedString get result =>
      _blink.BlinkSVGFEFloodElement.instance.result_Getter_(this);

  @DomName('SVGFEFloodElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGFEFloodElement.instance.width_Getter_(this);

  @DomName('SVGFEFloodElement.x')
  @DocsEditable()
  AnimatedLength get x =>
      _blink.BlinkSVGFEFloodElement.instance.x_Getter_(this);

  @DomName('SVGFEFloodElement.y')
  @DocsEditable()
  AnimatedLength get y =>
      _blink.BlinkSVGFEFloodElement.instance.y_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEFuncAElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEFuncAElement extends _SVGComponentTransferFunctionElement {
  // To suppress missing implicit constructor warnings.
  factory FEFuncAElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFEFuncAElement.SVGFEFuncAElement')
  @DocsEditable()
  factory FEFuncAElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feFuncA");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEFuncAElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEFuncAElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEFuncBElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEFuncBElement extends _SVGComponentTransferFunctionElement {
  // To suppress missing implicit constructor warnings.
  factory FEFuncBElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFEFuncBElement.SVGFEFuncBElement')
  @DocsEditable()
  factory FEFuncBElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feFuncB");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEFuncBElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEFuncBElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEFuncGElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEFuncGElement extends _SVGComponentTransferFunctionElement {
  // To suppress missing implicit constructor warnings.
  factory FEFuncGElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFEFuncGElement.SVGFEFuncGElement')
  @DocsEditable()
  factory FEFuncGElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feFuncG");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEFuncGElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEFuncGElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEFuncRElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEFuncRElement extends _SVGComponentTransferFunctionElement {
  // To suppress missing implicit constructor warnings.
  factory FEFuncRElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFEFuncRElement.SVGFEFuncRElement')
  @DocsEditable()
  factory FEFuncRElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feFuncR");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEFuncRElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEFuncRElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEGaussianBlurElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEGaussianBlurElement extends SvgElement
    implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEGaussianBlurElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFEGaussianBlurElement.SVGFEGaussianBlurElement')
  @DocsEditable()
  factory FEGaussianBlurElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feGaussianBlur");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEGaussianBlurElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEGaussianBlurElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEGaussianBlurElement.in1')
  @DocsEditable()
  AnimatedString get in1 =>
      _blink.BlinkSVGFEGaussianBlurElement.instance.in1_Getter_(this);

  @DomName('SVGFEGaussianBlurElement.stdDeviationX')
  @DocsEditable()
  AnimatedNumber get stdDeviationX =>
      _blink.BlinkSVGFEGaussianBlurElement.instance.stdDeviationX_Getter_(this);

  @DomName('SVGFEGaussianBlurElement.stdDeviationY')
  @DocsEditable()
  AnimatedNumber get stdDeviationY =>
      _blink.BlinkSVGFEGaussianBlurElement.instance.stdDeviationY_Getter_(this);

  @DomName('SVGFEGaussianBlurElement.setStdDeviation')
  @DocsEditable()
  void setStdDeviation(num stdDeviationX, num stdDeviationY) =>
      _blink.BlinkSVGFEGaussianBlurElement.instance
          .setStdDeviation_Callback_2_(this, stdDeviationX, stdDeviationY);

  @DomName('SVGFEGaussianBlurElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGFEGaussianBlurElement.instance.height_Getter_(this);

  @DomName('SVGFEGaussianBlurElement.result')
  @DocsEditable()
  AnimatedString get result =>
      _blink.BlinkSVGFEGaussianBlurElement.instance.result_Getter_(this);

  @DomName('SVGFEGaussianBlurElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGFEGaussianBlurElement.instance.width_Getter_(this);

  @DomName('SVGFEGaussianBlurElement.x')
  @DocsEditable()
  AnimatedLength get x =>
      _blink.BlinkSVGFEGaussianBlurElement.instance.x_Getter_(this);

  @DomName('SVGFEGaussianBlurElement.y')
  @DocsEditable()
  AnimatedLength get y =>
      _blink.BlinkSVGFEGaussianBlurElement.instance.y_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEImageElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEImageElement extends SvgElement
    implements FilterPrimitiveStandardAttributes, UriReference {
  // To suppress missing implicit constructor warnings.
  factory FEImageElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFEImageElement.SVGFEImageElement')
  @DocsEditable()
  factory FEImageElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feImage");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEImageElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEImageElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEImageElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio =>
      _blink.BlinkSVGFEImageElement.instance.preserveAspectRatio_Getter_(this);

  @DomName('SVGFEImageElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGFEImageElement.instance.height_Getter_(this);

  @DomName('SVGFEImageElement.result')
  @DocsEditable()
  AnimatedString get result =>
      _blink.BlinkSVGFEImageElement.instance.result_Getter_(this);

  @DomName('SVGFEImageElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGFEImageElement.instance.width_Getter_(this);

  @DomName('SVGFEImageElement.x')
  @DocsEditable()
  AnimatedLength get x =>
      _blink.BlinkSVGFEImageElement.instance.x_Getter_(this);

  @DomName('SVGFEImageElement.y')
  @DocsEditable()
  AnimatedLength get y =>
      _blink.BlinkSVGFEImageElement.instance.y_Getter_(this);

  @DomName('SVGFEImageElement.href')
  @DocsEditable()
  AnimatedString get href =>
      _blink.BlinkSVGFEImageElement.instance.href_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEMergeElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEMergeElement extends SvgElement
    implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEMergeElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFEMergeElement.SVGFEMergeElement')
  @DocsEditable()
  factory FEMergeElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feMerge");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEMergeElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEMergeElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEMergeElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGFEMergeElement.instance.height_Getter_(this);

  @DomName('SVGFEMergeElement.result')
  @DocsEditable()
  AnimatedString get result =>
      _blink.BlinkSVGFEMergeElement.instance.result_Getter_(this);

  @DomName('SVGFEMergeElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGFEMergeElement.instance.width_Getter_(this);

  @DomName('SVGFEMergeElement.x')
  @DocsEditable()
  AnimatedLength get x =>
      _blink.BlinkSVGFEMergeElement.instance.x_Getter_(this);

  @DomName('SVGFEMergeElement.y')
  @DocsEditable()
  AnimatedLength get y =>
      _blink.BlinkSVGFEMergeElement.instance.y_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEMergeNodeElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEMergeNodeElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory FEMergeNodeElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFEMergeNodeElement.SVGFEMergeNodeElement')
  @DocsEditable()
  factory FEMergeNodeElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feMergeNode");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEMergeNodeElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEMergeNodeElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEMergeNodeElement.in1')
  @DocsEditable()
  AnimatedString get in1 =>
      _blink.BlinkSVGFEMergeNodeElement.instance.in1_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEMorphologyElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEMorphologyElement extends SvgElement
    implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEMorphologyElement._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEMorphologyElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEMorphologyElement.created() : super.created();

  @DomName('SVGFEMorphologyElement.SVG_MORPHOLOGY_OPERATOR_DILATE')
  @DocsEditable()
  static const int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  @DomName('SVGFEMorphologyElement.SVG_MORPHOLOGY_OPERATOR_ERODE')
  @DocsEditable()
  static const int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  @DomName('SVGFEMorphologyElement.SVG_MORPHOLOGY_OPERATOR_UNKNOWN')
  @DocsEditable()
  static const int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

  @DomName('SVGFEMorphologyElement.in1')
  @DocsEditable()
  AnimatedString get in1 =>
      _blink.BlinkSVGFEMorphologyElement.instance.in1_Getter_(this);

  @DomName('SVGFEMorphologyElement.operator')
  @DocsEditable()
  AnimatedEnumeration get operator =>
      _blink.BlinkSVGFEMorphologyElement.instance.operator_Getter_(this);

  @DomName('SVGFEMorphologyElement.radiusX')
  @DocsEditable()
  AnimatedNumber get radiusX =>
      _blink.BlinkSVGFEMorphologyElement.instance.radiusX_Getter_(this);

  @DomName('SVGFEMorphologyElement.radiusY')
  @DocsEditable()
  AnimatedNumber get radiusY =>
      _blink.BlinkSVGFEMorphologyElement.instance.radiusY_Getter_(this);

  @DomName('SVGFEMorphologyElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGFEMorphologyElement.instance.height_Getter_(this);

  @DomName('SVGFEMorphologyElement.result')
  @DocsEditable()
  AnimatedString get result =>
      _blink.BlinkSVGFEMorphologyElement.instance.result_Getter_(this);

  @DomName('SVGFEMorphologyElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGFEMorphologyElement.instance.width_Getter_(this);

  @DomName('SVGFEMorphologyElement.x')
  @DocsEditable()
  AnimatedLength get x =>
      _blink.BlinkSVGFEMorphologyElement.instance.x_Getter_(this);

  @DomName('SVGFEMorphologyElement.y')
  @DocsEditable()
  AnimatedLength get y =>
      _blink.BlinkSVGFEMorphologyElement.instance.y_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEOffsetElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEOffsetElement extends SvgElement
    implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEOffsetElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFEOffsetElement.SVGFEOffsetElement')
  @DocsEditable()
  factory FEOffsetElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feOffset");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEOffsetElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEOffsetElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEOffsetElement.dx')
  @DocsEditable()
  AnimatedNumber get dx =>
      _blink.BlinkSVGFEOffsetElement.instance.dx_Getter_(this);

  @DomName('SVGFEOffsetElement.dy')
  @DocsEditable()
  AnimatedNumber get dy =>
      _blink.BlinkSVGFEOffsetElement.instance.dy_Getter_(this);

  @DomName('SVGFEOffsetElement.in1')
  @DocsEditable()
  AnimatedString get in1 =>
      _blink.BlinkSVGFEOffsetElement.instance.in1_Getter_(this);

  @DomName('SVGFEOffsetElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGFEOffsetElement.instance.height_Getter_(this);

  @DomName('SVGFEOffsetElement.result')
  @DocsEditable()
  AnimatedString get result =>
      _blink.BlinkSVGFEOffsetElement.instance.result_Getter_(this);

  @DomName('SVGFEOffsetElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGFEOffsetElement.instance.width_Getter_(this);

  @DomName('SVGFEOffsetElement.x')
  @DocsEditable()
  AnimatedLength get x =>
      _blink.BlinkSVGFEOffsetElement.instance.x_Getter_(this);

  @DomName('SVGFEOffsetElement.y')
  @DocsEditable()
  AnimatedLength get y =>
      _blink.BlinkSVGFEOffsetElement.instance.y_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFEPointLightElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FEPointLightElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory FEPointLightElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFEPointLightElement.SVGFEPointLightElement')
  @DocsEditable()
  factory FEPointLightElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("fePointLight");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FEPointLightElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FEPointLightElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFEPointLightElement.x')
  @DocsEditable()
  AnimatedNumber get x =>
      _blink.BlinkSVGFEPointLightElement.instance.x_Getter_(this);

  @DomName('SVGFEPointLightElement.y')
  @DocsEditable()
  AnimatedNumber get y =>
      _blink.BlinkSVGFEPointLightElement.instance.y_Getter_(this);

  @DomName('SVGFEPointLightElement.z')
  @DocsEditable()
  AnimatedNumber get z =>
      _blink.BlinkSVGFEPointLightElement.instance.z_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFESpecularLightingElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FESpecularLightingElement extends SvgElement
    implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FESpecularLightingElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFESpecularLightingElement.SVGFESpecularLightingElement')
  @DocsEditable()
  factory FESpecularLightingElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feSpecularLighting");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FESpecularLightingElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FESpecularLightingElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFESpecularLightingElement.in1')
  @DocsEditable()
  AnimatedString get in1 =>
      _blink.BlinkSVGFESpecularLightingElement.instance.in1_Getter_(this);

  @DomName('SVGFESpecularLightingElement.kernelUnitLengthX')
  @DocsEditable()
  @Experimental() // untriaged
  AnimatedNumber get kernelUnitLengthX =>
      _blink.BlinkSVGFESpecularLightingElement.instance
          .kernelUnitLengthX_Getter_(this);

  @DomName('SVGFESpecularLightingElement.kernelUnitLengthY')
  @DocsEditable()
  @Experimental() // untriaged
  AnimatedNumber get kernelUnitLengthY =>
      _blink.BlinkSVGFESpecularLightingElement.instance
          .kernelUnitLengthY_Getter_(this);

  @DomName('SVGFESpecularLightingElement.specularConstant')
  @DocsEditable()
  AnimatedNumber get specularConstant =>
      _blink.BlinkSVGFESpecularLightingElement.instance
          .specularConstant_Getter_(this);

  @DomName('SVGFESpecularLightingElement.specularExponent')
  @DocsEditable()
  AnimatedNumber get specularExponent =>
      _blink.BlinkSVGFESpecularLightingElement.instance
          .specularExponent_Getter_(this);

  @DomName('SVGFESpecularLightingElement.surfaceScale')
  @DocsEditable()
  AnimatedNumber get surfaceScale =>
      _blink.BlinkSVGFESpecularLightingElement.instance
          .surfaceScale_Getter_(this);

  @DomName('SVGFESpecularLightingElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGFESpecularLightingElement.instance.height_Getter_(this);

  @DomName('SVGFESpecularLightingElement.result')
  @DocsEditable()
  AnimatedString get result =>
      _blink.BlinkSVGFESpecularLightingElement.instance.result_Getter_(this);

  @DomName('SVGFESpecularLightingElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGFESpecularLightingElement.instance.width_Getter_(this);

  @DomName('SVGFESpecularLightingElement.x')
  @DocsEditable()
  AnimatedLength get x =>
      _blink.BlinkSVGFESpecularLightingElement.instance.x_Getter_(this);

  @DomName('SVGFESpecularLightingElement.y')
  @DocsEditable()
  AnimatedLength get y =>
      _blink.BlinkSVGFESpecularLightingElement.instance.y_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFESpotLightElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FESpotLightElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory FESpotLightElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFESpotLightElement.SVGFESpotLightElement')
  @DocsEditable()
  factory FESpotLightElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feSpotLight");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FESpotLightElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FESpotLightElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFESpotLightElement.limitingConeAngle')
  @DocsEditable()
  AnimatedNumber get limitingConeAngle =>
      _blink.BlinkSVGFESpotLightElement.instance
          .limitingConeAngle_Getter_(this);

  @DomName('SVGFESpotLightElement.pointsAtX')
  @DocsEditable()
  AnimatedNumber get pointsAtX =>
      _blink.BlinkSVGFESpotLightElement.instance.pointsAtX_Getter_(this);

  @DomName('SVGFESpotLightElement.pointsAtY')
  @DocsEditable()
  AnimatedNumber get pointsAtY =>
      _blink.BlinkSVGFESpotLightElement.instance.pointsAtY_Getter_(this);

  @DomName('SVGFESpotLightElement.pointsAtZ')
  @DocsEditable()
  AnimatedNumber get pointsAtZ =>
      _blink.BlinkSVGFESpotLightElement.instance.pointsAtZ_Getter_(this);

  @DomName('SVGFESpotLightElement.specularExponent')
  @DocsEditable()
  AnimatedNumber get specularExponent =>
      _blink.BlinkSVGFESpotLightElement.instance.specularExponent_Getter_(this);

  @DomName('SVGFESpotLightElement.x')
  @DocsEditable()
  AnimatedNumber get x =>
      _blink.BlinkSVGFESpotLightElement.instance.x_Getter_(this);

  @DomName('SVGFESpotLightElement.y')
  @DocsEditable()
  AnimatedNumber get y =>
      _blink.BlinkSVGFESpotLightElement.instance.y_Getter_(this);

  @DomName('SVGFESpotLightElement.z')
  @DocsEditable()
  AnimatedNumber get z =>
      _blink.BlinkSVGFESpotLightElement.instance.z_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFETileElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FETileElement extends SvgElement
    implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FETileElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFETileElement.SVGFETileElement')
  @DocsEditable()
  factory FETileElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feTile");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FETileElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FETileElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFETileElement.in1')
  @DocsEditable()
  AnimatedString get in1 =>
      _blink.BlinkSVGFETileElement.instance.in1_Getter_(this);

  @DomName('SVGFETileElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGFETileElement.instance.height_Getter_(this);

  @DomName('SVGFETileElement.result')
  @DocsEditable()
  AnimatedString get result =>
      _blink.BlinkSVGFETileElement.instance.result_Getter_(this);

  @DomName('SVGFETileElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGFETileElement.instance.width_Getter_(this);

  @DomName('SVGFETileElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFETileElement.instance.x_Getter_(this);

  @DomName('SVGFETileElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFETileElement.instance.y_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFETurbulenceElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FETurbulenceElement extends SvgElement
    implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FETurbulenceElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFETurbulenceElement.SVGFETurbulenceElement')
  @DocsEditable()
  factory FETurbulenceElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("feTurbulence");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FETurbulenceElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FETurbulenceElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFETurbulenceElement.SVG_STITCHTYPE_NOSTITCH')
  @DocsEditable()
  static const int SVG_STITCHTYPE_NOSTITCH = 2;

  @DomName('SVGFETurbulenceElement.SVG_STITCHTYPE_STITCH')
  @DocsEditable()
  static const int SVG_STITCHTYPE_STITCH = 1;

  @DomName('SVGFETurbulenceElement.SVG_STITCHTYPE_UNKNOWN')
  @DocsEditable()
  static const int SVG_STITCHTYPE_UNKNOWN = 0;

  @DomName('SVGFETurbulenceElement.SVG_TURBULENCE_TYPE_FRACTALNOISE')
  @DocsEditable()
  static const int SVG_TURBULENCE_TYPE_FRACTALNOISE = 1;

  @DomName('SVGFETurbulenceElement.SVG_TURBULENCE_TYPE_TURBULENCE')
  @DocsEditable()
  static const int SVG_TURBULENCE_TYPE_TURBULENCE = 2;

  @DomName('SVGFETurbulenceElement.SVG_TURBULENCE_TYPE_UNKNOWN')
  @DocsEditable()
  static const int SVG_TURBULENCE_TYPE_UNKNOWN = 0;

  @DomName('SVGFETurbulenceElement.baseFrequencyX')
  @DocsEditable()
  AnimatedNumber get baseFrequencyX =>
      _blink.BlinkSVGFETurbulenceElement.instance.baseFrequencyX_Getter_(this);

  @DomName('SVGFETurbulenceElement.baseFrequencyY')
  @DocsEditable()
  AnimatedNumber get baseFrequencyY =>
      _blink.BlinkSVGFETurbulenceElement.instance.baseFrequencyY_Getter_(this);

  @DomName('SVGFETurbulenceElement.numOctaves')
  @DocsEditable()
  AnimatedInteger get numOctaves =>
      _blink.BlinkSVGFETurbulenceElement.instance.numOctaves_Getter_(this);

  @DomName('SVGFETurbulenceElement.seed')
  @DocsEditable()
  AnimatedNumber get seed =>
      _blink.BlinkSVGFETurbulenceElement.instance.seed_Getter_(this);

  @DomName('SVGFETurbulenceElement.stitchTiles')
  @DocsEditable()
  AnimatedEnumeration get stitchTiles =>
      _blink.BlinkSVGFETurbulenceElement.instance.stitchTiles_Getter_(this);

  @DomName('SVGFETurbulenceElement.type')
  @DocsEditable()
  AnimatedEnumeration get type =>
      _blink.BlinkSVGFETurbulenceElement.instance.type_Getter_(this);

  @DomName('SVGFETurbulenceElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGFETurbulenceElement.instance.height_Getter_(this);

  @DomName('SVGFETurbulenceElement.result')
  @DocsEditable()
  AnimatedString get result =>
      _blink.BlinkSVGFETurbulenceElement.instance.result_Getter_(this);

  @DomName('SVGFETurbulenceElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGFETurbulenceElement.instance.width_Getter_(this);

  @DomName('SVGFETurbulenceElement.x')
  @DocsEditable()
  AnimatedLength get x =>
      _blink.BlinkSVGFETurbulenceElement.instance.x_Getter_(this);

  @DomName('SVGFETurbulenceElement.y')
  @DocsEditable()
  AnimatedLength get y =>
      _blink.BlinkSVGFETurbulenceElement.instance.y_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFilterElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.IE, '10')
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class FilterElement extends SvgElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory FilterElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFilterElement.SVGFilterElement')
  @DocsEditable()
  factory FilterElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("filter");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  FilterElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FilterElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFilterElement.filterUnits')
  @DocsEditable()
  AnimatedEnumeration get filterUnits =>
      _blink.BlinkSVGFilterElement.instance.filterUnits_Getter_(this);

  @DomName('SVGFilterElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGFilterElement.instance.height_Getter_(this);

  @DomName('SVGFilterElement.primitiveUnits')
  @DocsEditable()
  AnimatedEnumeration get primitiveUnits =>
      _blink.BlinkSVGFilterElement.instance.primitiveUnits_Getter_(this);

  @DomName('SVGFilterElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGFilterElement.instance.width_Getter_(this);

  @DomName('SVGFilterElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGFilterElement.instance.x_Getter_(this);

  @DomName('SVGFilterElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGFilterElement.instance.y_Getter_(this);

  @DomName('SVGFilterElement.href')
  @DocsEditable()
  AnimatedString get href =>
      _blink.BlinkSVGFilterElement.instance.href_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFilterPrimitiveStandardAttributes')
@Unstable()
abstract class FilterPrimitiveStandardAttributes extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory FilterPrimitiveStandardAttributes._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFilterPrimitiveStandardAttributes.height')
  @DocsEditable()
  AnimatedLength get height;

  @DomName('SVGFilterPrimitiveStandardAttributes.result')
  @DocsEditable()
  AnimatedString get result;

  @DomName('SVGFilterPrimitiveStandardAttributes.width')
  @DocsEditable()
  AnimatedLength get width;

  @DomName('SVGFilterPrimitiveStandardAttributes.x')
  @DocsEditable()
  AnimatedLength get x;

  @DomName('SVGFilterPrimitiveStandardAttributes.y')
  @DocsEditable()
  AnimatedLength get y;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGFitToViewBox')
@Unstable()
abstract class FitToViewBox extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory FitToViewBox._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGFitToViewBox.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio;

  @DomName('SVGFitToViewBox.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGForeignObjectElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class ForeignObjectElement extends GraphicsElement {
  // To suppress missing implicit constructor warnings.
  factory ForeignObjectElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGForeignObjectElement.SVGForeignObjectElement')
  @DocsEditable()
  factory ForeignObjectElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("foreignObject");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  ForeignObjectElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  ForeignObjectElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGForeignObjectElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGForeignObjectElement.instance.height_Getter_(this);

  @DomName('SVGForeignObjectElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGForeignObjectElement.instance.width_Getter_(this);

  @DomName('SVGForeignObjectElement.x')
  @DocsEditable()
  AnimatedLength get x =>
      _blink.BlinkSVGForeignObjectElement.instance.x_Getter_(this);

  @DomName('SVGForeignObjectElement.y')
  @DocsEditable()
  AnimatedLength get y =>
      _blink.BlinkSVGForeignObjectElement.instance.y_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGGElement')
@Unstable()
class GElement extends GraphicsElement {
  // To suppress missing implicit constructor warnings.
  factory GElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGGElement.SVGGElement')
  @DocsEditable()
  factory GElement() => _SvgElementFactoryProvider.createSvgElement_tag("g");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  GElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  GElement.created() : super.created();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGGeometryElement')
@Experimental() // untriaged
class GeometryElement extends GraphicsElement {
  // To suppress missing implicit constructor warnings.
  factory GeometryElement._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  GeometryElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  GeometryElement.created() : super.created();

  @DomName('SVGGeometryElement.isPointInFill')
  @DocsEditable()
  @Experimental() // untriaged
  bool isPointInFill(Point point) => _blink.BlinkSVGGeometryElement.instance
      .isPointInFill_Callback_1_(this, point);

  @DomName('SVGGeometryElement.isPointInStroke')
  @DocsEditable()
  @Experimental() // untriaged
  bool isPointInStroke(Point point) => _blink.BlinkSVGGeometryElement.instance
      .isPointInStroke_Callback_1_(this, point);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGGraphicsElement')
@Experimental() // untriaged
class GraphicsElement extends SvgElement implements Tests {
  // To suppress missing implicit constructor warnings.
  factory GraphicsElement._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  GraphicsElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  GraphicsElement.created() : super.created();

  @DomName('SVGGraphicsElement.farthestViewportElement')
  @DocsEditable()
  @Experimental() // untriaged
  SvgElement get farthestViewportElement =>
      _blink.BlinkSVGGraphicsElement.instance
          .farthestViewportElement_Getter_(this);

  @DomName('SVGGraphicsElement.nearestViewportElement')
  @DocsEditable()
  @Experimental() // untriaged
  SvgElement get nearestViewportElement =>
      _blink.BlinkSVGGraphicsElement.instance
          .nearestViewportElement_Getter_(this);

  @DomName('SVGGraphicsElement.transform')
  @DocsEditable()
  @Experimental() // untriaged
  AnimatedTransformList get transform =>
      _blink.BlinkSVGGraphicsElement.instance.transform_Getter_(this);

  @DomName('SVGGraphicsElement.getBBox')
  @DocsEditable()
  @Experimental() // untriaged
  Rect getBBox() =>
      _blink.BlinkSVGGraphicsElement.instance.getBBox_Callback_0_(this);

  @DomName('SVGGraphicsElement.getCTM')
  @DocsEditable()
  @Experimental() // untriaged
  Matrix getCtm() =>
      _blink.BlinkSVGGraphicsElement.instance.getCTM_Callback_0_(this);

  @DomName('SVGGraphicsElement.getScreenCTM')
  @DocsEditable()
  @Experimental() // untriaged
  Matrix getScreenCtm() =>
      _blink.BlinkSVGGraphicsElement.instance.getScreenCTM_Callback_0_(this);

  @DomName('SVGGraphicsElement.getTransformToElement')
  @DocsEditable()
  @Experimental() // untriaged
  Matrix getTransformToElement(SvgElement element) =>
      _blink.BlinkSVGGraphicsElement.instance
          .getTransformToElement_Callback_1_(this, element);

  @DomName('SVGGraphicsElement.requiredExtensions')
  @DocsEditable()
  @Experimental() // untriaged
  StringList get requiredExtensions =>
      _blink.BlinkSVGGraphicsElement.instance.requiredExtensions_Getter_(this);

  @DomName('SVGGraphicsElement.requiredFeatures')
  @DocsEditable()
  @Experimental() // untriaged
  StringList get requiredFeatures =>
      _blink.BlinkSVGGraphicsElement.instance.requiredFeatures_Getter_(this);

  @DomName('SVGGraphicsElement.systemLanguage')
  @DocsEditable()
  @Experimental() // untriaged
  StringList get systemLanguage =>
      _blink.BlinkSVGGraphicsElement.instance.systemLanguage_Getter_(this);

  @DomName('SVGGraphicsElement.hasExtension')
  @DocsEditable()
  @Experimental() // untriaged
  bool hasExtension(String extension) => _blink.BlinkSVGGraphicsElement.instance
      .hasExtension_Callback_1_(this, extension);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGImageElement')
@Unstable()
class ImageElement extends GraphicsElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory ImageElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGImageElement.SVGImageElement')
  @DocsEditable()
  factory ImageElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("image");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  ImageElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  ImageElement.created() : super.created();

  @DomName('SVGImageElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGImageElement.instance.height_Getter_(this);

  @DomName('SVGImageElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio =>
      _blink.BlinkSVGImageElement.instance.preserveAspectRatio_Getter_(this);

  @DomName('SVGImageElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGImageElement.instance.width_Getter_(this);

  @DomName('SVGImageElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGImageElement.instance.x_Getter_(this);

  @DomName('SVGImageElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGImageElement.instance.y_Getter_(this);

  @DomName('SVGImageElement.href')
  @DocsEditable()
  AnimatedString get href =>
      _blink.BlinkSVGImageElement.instance.href_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGLength')
@Unstable()
class Length extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory Length._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  Length.internal_() {}

  @DomName('SVGLength.SVG_LENGTHTYPE_CM')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_CM = 6;

  @DomName('SVGLength.SVG_LENGTHTYPE_EMS')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_EMS = 3;

  @DomName('SVGLength.SVG_LENGTHTYPE_EXS')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_EXS = 4;

  @DomName('SVGLength.SVG_LENGTHTYPE_IN')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_IN = 8;

  @DomName('SVGLength.SVG_LENGTHTYPE_MM')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_MM = 7;

  @DomName('SVGLength.SVG_LENGTHTYPE_NUMBER')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_NUMBER = 1;

  @DomName('SVGLength.SVG_LENGTHTYPE_PC')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_PC = 10;

  @DomName('SVGLength.SVG_LENGTHTYPE_PERCENTAGE')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_PERCENTAGE = 2;

  @DomName('SVGLength.SVG_LENGTHTYPE_PT')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_PT = 9;

  @DomName('SVGLength.SVG_LENGTHTYPE_PX')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_PX = 5;

  @DomName('SVGLength.SVG_LENGTHTYPE_UNKNOWN')
  @DocsEditable()
  static const int SVG_LENGTHTYPE_UNKNOWN = 0;

  @DomName('SVGLength.unitType')
  @DocsEditable()
  int get unitType => _blink.BlinkSVGLength.instance.unitType_Getter_(this);

  @DomName('SVGLength.value')
  @DocsEditable()
  num get value => _blink.BlinkSVGLength.instance.value_Getter_(this);

  @DomName('SVGLength.value')
  @DocsEditable()
  set value(num value) =>
      _blink.BlinkSVGLength.instance.value_Setter_(this, value);

  @DomName('SVGLength.valueAsString')
  @DocsEditable()
  String get valueAsString =>
      _blink.BlinkSVGLength.instance.valueAsString_Getter_(this);

  @DomName('SVGLength.valueAsString')
  @DocsEditable()
  set valueAsString(String value) =>
      _blink.BlinkSVGLength.instance.valueAsString_Setter_(this, value);

  @DomName('SVGLength.valueInSpecifiedUnits')
  @DocsEditable()
  num get valueInSpecifiedUnits =>
      _blink.BlinkSVGLength.instance.valueInSpecifiedUnits_Getter_(this);

  @DomName('SVGLength.valueInSpecifiedUnits')
  @DocsEditable()
  set valueInSpecifiedUnits(num value) =>
      _blink.BlinkSVGLength.instance.valueInSpecifiedUnits_Setter_(this, value);

  @DomName('SVGLength.convertToSpecifiedUnits')
  @DocsEditable()
  void convertToSpecifiedUnits(int unitType) => _blink.BlinkSVGLength.instance
      .convertToSpecifiedUnits_Callback_1_(this, unitType);

  @DomName('SVGLength.newValueSpecifiedUnits')
  @DocsEditable()
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) =>
      _blink.BlinkSVGLength.instance.newValueSpecifiedUnits_Callback_2_(
          this, unitType, valueInSpecifiedUnits);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGLengthList')
@Unstable()
class LengthList extends DartHtmlDomObject
    with ListMixin<Length>, ImmutableListMixin<Length>
    implements List<Length> {
  // To suppress missing implicit constructor warnings.
  factory LengthList._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  LengthList.internal_() {}

  @DomName('SVGLengthList.length')
  @DocsEditable()
  @Experimental() // untriaged
  int get length => _blink.BlinkSVGLengthList.instance.length_Getter_(this);

  @DomName('SVGLengthList.numberOfItems')
  @DocsEditable()
  int get numberOfItems =>
      _blink.BlinkSVGLengthList.instance.numberOfItems_Getter_(this);

  Length operator [](int index) {
    if (index < 0 || index >= length) throw new RangeError.index(index, this);
    return getItem(index);
  }

  void operator []=(int index, Length value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Length> mixins.
  // Length is the element type.

  set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  Length get first {
    if (this.length > 0) {
      return getItem(0);
    }
    throw new StateError("No elements");
  }

  Length get last {
    int len = this.length;
    if (len > 0) {
      return getItem(len - 1);
    }
    throw new StateError("No elements");
  }

  Length get single {
    int len = this.length;
    if (len == 1) {
      return getItem(0);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Length elementAt(int index) => this[index];
  // -- end List<Length> mixins.

  @DomName('SVGLengthList.__setter__')
  @DocsEditable()
  @Experimental() // untriaged
  void __setter__(int index, Length newItem) =>
      _blink.BlinkSVGLengthList.instance
          .$__setter___Callback_2_(this, index, newItem);

  @DomName('SVGLengthList.appendItem')
  @DocsEditable()
  Length appendItem(Length newItem) =>
      _blink.BlinkSVGLengthList.instance.appendItem_Callback_1_(this, newItem);

  @DomName('SVGLengthList.clear')
  @DocsEditable()
  void clear() => _blink.BlinkSVGLengthList.instance.clear_Callback_0_(this);

  @DomName('SVGLengthList.getItem')
  @DocsEditable()
  Length getItem(int index) =>
      _blink.BlinkSVGLengthList.instance.getItem_Callback_1_(this, index);

  @DomName('SVGLengthList.initialize')
  @DocsEditable()
  Length initialize(Length newItem) =>
      _blink.BlinkSVGLengthList.instance.initialize_Callback_1_(this, newItem);

  @DomName('SVGLengthList.insertItemBefore')
  @DocsEditable()
  Length insertItemBefore(Length newItem, int index) =>
      _blink.BlinkSVGLengthList.instance
          .insertItemBefore_Callback_2_(this, newItem, index);

  @DomName('SVGLengthList.removeItem')
  @DocsEditable()
  Length removeItem(int index) =>
      _blink.BlinkSVGLengthList.instance.removeItem_Callback_1_(this, index);

  @DomName('SVGLengthList.replaceItem')
  @DocsEditable()
  Length replaceItem(Length newItem, int index) =>
      _blink.BlinkSVGLengthList.instance
          .replaceItem_Callback_2_(this, newItem, index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGLineElement')
@Unstable()
class LineElement extends GeometryElement {
  // To suppress missing implicit constructor warnings.
  factory LineElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGLineElement.SVGLineElement')
  @DocsEditable()
  factory LineElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("line");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  LineElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  LineElement.created() : super.created();

  @DomName('SVGLineElement.x1')
  @DocsEditable()
  AnimatedLength get x1 => _blink.BlinkSVGLineElement.instance.x1_Getter_(this);

  @DomName('SVGLineElement.x2')
  @DocsEditable()
  AnimatedLength get x2 => _blink.BlinkSVGLineElement.instance.x2_Getter_(this);

  @DomName('SVGLineElement.y1')
  @DocsEditable()
  AnimatedLength get y1 => _blink.BlinkSVGLineElement.instance.y1_Getter_(this);

  @DomName('SVGLineElement.y2')
  @DocsEditable()
  AnimatedLength get y2 => _blink.BlinkSVGLineElement.instance.y2_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGLinearGradientElement')
@Unstable()
class LinearGradientElement extends _GradientElement {
  // To suppress missing implicit constructor warnings.
  factory LinearGradientElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGLinearGradientElement.SVGLinearGradientElement')
  @DocsEditable()
  factory LinearGradientElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("linearGradient");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  LinearGradientElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  LinearGradientElement.created() : super.created();

  @DomName('SVGLinearGradientElement.x1')
  @DocsEditable()
  AnimatedLength get x1 =>
      _blink.BlinkSVGLinearGradientElement.instance.x1_Getter_(this);

  @DomName('SVGLinearGradientElement.x2')
  @DocsEditable()
  AnimatedLength get x2 =>
      _blink.BlinkSVGLinearGradientElement.instance.x2_Getter_(this);

  @DomName('SVGLinearGradientElement.y1')
  @DocsEditable()
  AnimatedLength get y1 =>
      _blink.BlinkSVGLinearGradientElement.instance.y1_Getter_(this);

  @DomName('SVGLinearGradientElement.y2')
  @DocsEditable()
  AnimatedLength get y2 =>
      _blink.BlinkSVGLinearGradientElement.instance.y2_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGMarkerElement')
@Unstable()
class MarkerElement extends SvgElement implements FitToViewBox {
  // To suppress missing implicit constructor warnings.
  factory MarkerElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGMarkerElement.SVGMarkerElement')
  @DocsEditable()
  factory MarkerElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("marker");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  MarkerElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  MarkerElement.created() : super.created();

  @DomName('SVGMarkerElement.SVG_MARKERUNITS_STROKEWIDTH')
  @DocsEditable()
  static const int SVG_MARKERUNITS_STROKEWIDTH = 2;

  @DomName('SVGMarkerElement.SVG_MARKERUNITS_UNKNOWN')
  @DocsEditable()
  static const int SVG_MARKERUNITS_UNKNOWN = 0;

  @DomName('SVGMarkerElement.SVG_MARKERUNITS_USERSPACEONUSE')
  @DocsEditable()
  static const int SVG_MARKERUNITS_USERSPACEONUSE = 1;

  @DomName('SVGMarkerElement.SVG_MARKER_ORIENT_ANGLE')
  @DocsEditable()
  static const int SVG_MARKER_ORIENT_ANGLE = 2;

  @DomName('SVGMarkerElement.SVG_MARKER_ORIENT_AUTO')
  @DocsEditable()
  static const int SVG_MARKER_ORIENT_AUTO = 1;

  @DomName('SVGMarkerElement.SVG_MARKER_ORIENT_UNKNOWN')
  @DocsEditable()
  static const int SVG_MARKER_ORIENT_UNKNOWN = 0;

  @DomName('SVGMarkerElement.markerHeight')
  @DocsEditable()
  AnimatedLength get markerHeight =>
      _blink.BlinkSVGMarkerElement.instance.markerHeight_Getter_(this);

  @DomName('SVGMarkerElement.markerUnits')
  @DocsEditable()
  AnimatedEnumeration get markerUnits =>
      _blink.BlinkSVGMarkerElement.instance.markerUnits_Getter_(this);

  @DomName('SVGMarkerElement.markerWidth')
  @DocsEditable()
  AnimatedLength get markerWidth =>
      _blink.BlinkSVGMarkerElement.instance.markerWidth_Getter_(this);

  @DomName('SVGMarkerElement.orientAngle')
  @DocsEditable()
  AnimatedAngle get orientAngle =>
      _blink.BlinkSVGMarkerElement.instance.orientAngle_Getter_(this);

  @DomName('SVGMarkerElement.orientType')
  @DocsEditable()
  AnimatedEnumeration get orientType =>
      _blink.BlinkSVGMarkerElement.instance.orientType_Getter_(this);

  @DomName('SVGMarkerElement.refX')
  @DocsEditable()
  AnimatedLength get refX =>
      _blink.BlinkSVGMarkerElement.instance.refX_Getter_(this);

  @DomName('SVGMarkerElement.refY')
  @DocsEditable()
  AnimatedLength get refY =>
      _blink.BlinkSVGMarkerElement.instance.refY_Getter_(this);

  @DomName('SVGMarkerElement.setOrientToAngle')
  @DocsEditable()
  void setOrientToAngle(Angle angle) => _blink.BlinkSVGMarkerElement.instance
      .setOrientToAngle_Callback_1_(this, angle);

  @DomName('SVGMarkerElement.setOrientToAuto')
  @DocsEditable()
  void setOrientToAuto() =>
      _blink.BlinkSVGMarkerElement.instance.setOrientToAuto_Callback_0_(this);

  @DomName('SVGMarkerElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio =>
      _blink.BlinkSVGMarkerElement.instance.preserveAspectRatio_Getter_(this);

  @DomName('SVGMarkerElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox =>
      _blink.BlinkSVGMarkerElement.instance.viewBox_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGMaskElement')
@Unstable()
class MaskElement extends SvgElement implements Tests {
  // To suppress missing implicit constructor warnings.
  factory MaskElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGMaskElement.SVGMaskElement')
  @DocsEditable()
  factory MaskElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("mask");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  MaskElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  MaskElement.created() : super.created();

  @DomName('SVGMaskElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGMaskElement.instance.height_Getter_(this);

  @DomName('SVGMaskElement.maskContentUnits')
  @DocsEditable()
  AnimatedEnumeration get maskContentUnits =>
      _blink.BlinkSVGMaskElement.instance.maskContentUnits_Getter_(this);

  @DomName('SVGMaskElement.maskUnits')
  @DocsEditable()
  AnimatedEnumeration get maskUnits =>
      _blink.BlinkSVGMaskElement.instance.maskUnits_Getter_(this);

  @DomName('SVGMaskElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGMaskElement.instance.width_Getter_(this);

  @DomName('SVGMaskElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGMaskElement.instance.x_Getter_(this);

  @DomName('SVGMaskElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGMaskElement.instance.y_Getter_(this);

  @DomName('SVGMaskElement.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions =>
      _blink.BlinkSVGMaskElement.instance.requiredExtensions_Getter_(this);

  @DomName('SVGMaskElement.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures =>
      _blink.BlinkSVGMaskElement.instance.requiredFeatures_Getter_(this);

  @DomName('SVGMaskElement.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage =>
      _blink.BlinkSVGMaskElement.instance.systemLanguage_Getter_(this);

  @DomName('SVGMaskElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) => _blink.BlinkSVGMaskElement.instance
      .hasExtension_Callback_1_(this, extension);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGMatrix')
@Unstable()
class Matrix extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory Matrix._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  Matrix.internal_() {}

  @DomName('SVGMatrix.a')
  @DocsEditable()
  num get a => _blink.BlinkSVGMatrix.instance.a_Getter_(this);

  @DomName('SVGMatrix.a')
  @DocsEditable()
  set a(num value) => _blink.BlinkSVGMatrix.instance.a_Setter_(this, value);

  @DomName('SVGMatrix.b')
  @DocsEditable()
  num get b => _blink.BlinkSVGMatrix.instance.b_Getter_(this);

  @DomName('SVGMatrix.b')
  @DocsEditable()
  set b(num value) => _blink.BlinkSVGMatrix.instance.b_Setter_(this, value);

  @DomName('SVGMatrix.c')
  @DocsEditable()
  num get c => _blink.BlinkSVGMatrix.instance.c_Getter_(this);

  @DomName('SVGMatrix.c')
  @DocsEditable()
  set c(num value) => _blink.BlinkSVGMatrix.instance.c_Setter_(this, value);

  @DomName('SVGMatrix.d')
  @DocsEditable()
  num get d => _blink.BlinkSVGMatrix.instance.d_Getter_(this);

  @DomName('SVGMatrix.d')
  @DocsEditable()
  set d(num value) => _blink.BlinkSVGMatrix.instance.d_Setter_(this, value);

  @DomName('SVGMatrix.e')
  @DocsEditable()
  num get e => _blink.BlinkSVGMatrix.instance.e_Getter_(this);

  @DomName('SVGMatrix.e')
  @DocsEditable()
  set e(num value) => _blink.BlinkSVGMatrix.instance.e_Setter_(this, value);

  @DomName('SVGMatrix.f')
  @DocsEditable()
  num get f => _blink.BlinkSVGMatrix.instance.f_Getter_(this);

  @DomName('SVGMatrix.f')
  @DocsEditable()
  set f(num value) => _blink.BlinkSVGMatrix.instance.f_Setter_(this, value);

  @DomName('SVGMatrix.flipX')
  @DocsEditable()
  Matrix flipX() => _blink.BlinkSVGMatrix.instance.flipX_Callback_0_(this);

  @DomName('SVGMatrix.flipY')
  @DocsEditable()
  Matrix flipY() => _blink.BlinkSVGMatrix.instance.flipY_Callback_0_(this);

  @DomName('SVGMatrix.inverse')
  @DocsEditable()
  Matrix inverse() => _blink.BlinkSVGMatrix.instance.inverse_Callback_0_(this);

  @DomName('SVGMatrix.multiply')
  @DocsEditable()
  Matrix multiply(Matrix secondMatrix) =>
      _blink.BlinkSVGMatrix.instance.multiply_Callback_1_(this, secondMatrix);

  @DomName('SVGMatrix.rotate')
  @DocsEditable()
  Matrix rotate(num angle) =>
      _blink.BlinkSVGMatrix.instance.rotate_Callback_1_(this, angle);

  @DomName('SVGMatrix.rotateFromVector')
  @DocsEditable()
  Matrix rotateFromVector(num x, num y) =>
      _blink.BlinkSVGMatrix.instance.rotateFromVector_Callback_2_(this, x, y);

  @DomName('SVGMatrix.scale')
  @DocsEditable()
  Matrix scale(num scaleFactor) =>
      _blink.BlinkSVGMatrix.instance.scale_Callback_1_(this, scaleFactor);

  @DomName('SVGMatrix.scaleNonUniform')
  @DocsEditable()
  Matrix scaleNonUniform(num scaleFactorX, num scaleFactorY) =>
      _blink.BlinkSVGMatrix.instance
          .scaleNonUniform_Callback_2_(this, scaleFactorX, scaleFactorY);

  @DomName('SVGMatrix.skewX')
  @DocsEditable()
  Matrix skewX(num angle) =>
      _blink.BlinkSVGMatrix.instance.skewX_Callback_1_(this, angle);

  @DomName('SVGMatrix.skewY')
  @DocsEditable()
  Matrix skewY(num angle) =>
      _blink.BlinkSVGMatrix.instance.skewY_Callback_1_(this, angle);

  @DomName('SVGMatrix.translate')
  @DocsEditable()
  Matrix translate(num x, num y) =>
      _blink.BlinkSVGMatrix.instance.translate_Callback_2_(this, x, y);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGMetadataElement')
@Unstable()
class MetadataElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory MetadataElement._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  MetadataElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  MetadataElement.created() : super.created();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGNumber')
@Unstable()
class Number extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory Number._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  Number.internal_() {}

  @DomName('SVGNumber.value')
  @DocsEditable()
  num get value => _blink.BlinkSVGNumber.instance.value_Getter_(this);

  @DomName('SVGNumber.value')
  @DocsEditable()
  set value(num value) =>
      _blink.BlinkSVGNumber.instance.value_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGNumberList')
@Unstable()
class NumberList extends DartHtmlDomObject
    with ListMixin<Number>, ImmutableListMixin<Number>
    implements List<Number> {
  // To suppress missing implicit constructor warnings.
  factory NumberList._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  NumberList.internal_() {}

  @DomName('SVGNumberList.length')
  @DocsEditable()
  @Experimental() // untriaged
  int get length => _blink.BlinkSVGNumberList.instance.length_Getter_(this);

  @DomName('SVGNumberList.numberOfItems')
  @DocsEditable()
  int get numberOfItems =>
      _blink.BlinkSVGNumberList.instance.numberOfItems_Getter_(this);

  Number operator [](int index) {
    if (index < 0 || index >= length) throw new RangeError.index(index, this);
    return getItem(index);
  }

  void operator []=(int index, Number value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Number> mixins.
  // Number is the element type.

  set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  Number get first {
    if (this.length > 0) {
      return getItem(0);
    }
    throw new StateError("No elements");
  }

  Number get last {
    int len = this.length;
    if (len > 0) {
      return getItem(len - 1);
    }
    throw new StateError("No elements");
  }

  Number get single {
    int len = this.length;
    if (len == 1) {
      return getItem(0);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Number elementAt(int index) => this[index];
  // -- end List<Number> mixins.

  @DomName('SVGNumberList.__setter__')
  @DocsEditable()
  @Experimental() // untriaged
  void __setter__(int index, Number newItem) =>
      _blink.BlinkSVGNumberList.instance
          .$__setter___Callback_2_(this, index, newItem);

  @DomName('SVGNumberList.appendItem')
  @DocsEditable()
  Number appendItem(Number newItem) =>
      _blink.BlinkSVGNumberList.instance.appendItem_Callback_1_(this, newItem);

  @DomName('SVGNumberList.clear')
  @DocsEditable()
  void clear() => _blink.BlinkSVGNumberList.instance.clear_Callback_0_(this);

  @DomName('SVGNumberList.getItem')
  @DocsEditable()
  Number getItem(int index) =>
      _blink.BlinkSVGNumberList.instance.getItem_Callback_1_(this, index);

  @DomName('SVGNumberList.initialize')
  @DocsEditable()
  Number initialize(Number newItem) =>
      _blink.BlinkSVGNumberList.instance.initialize_Callback_1_(this, newItem);

  @DomName('SVGNumberList.insertItemBefore')
  @DocsEditable()
  Number insertItemBefore(Number newItem, int index) =>
      _blink.BlinkSVGNumberList.instance
          .insertItemBefore_Callback_2_(this, newItem, index);

  @DomName('SVGNumberList.removeItem')
  @DocsEditable()
  Number removeItem(int index) =>
      _blink.BlinkSVGNumberList.instance.removeItem_Callback_1_(this, index);

  @DomName('SVGNumberList.replaceItem')
  @DocsEditable()
  Number replaceItem(Number newItem, int index) =>
      _blink.BlinkSVGNumberList.instance
          .replaceItem_Callback_2_(this, newItem, index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathElement')
@Unstable()
class PathElement extends GeometryElement {
  // To suppress missing implicit constructor warnings.
  factory PathElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGPathElement.SVGPathElement')
  @DocsEditable()
  factory PathElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("path");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  PathElement.created() : super.created();

  @DomName('SVGPathElement.animatedNormalizedPathSegList')
  @DocsEditable()
  PathSegList get animatedNormalizedPathSegList =>
      _blink.BlinkSVGPathElement.instance
          .animatedNormalizedPathSegList_Getter_(this);

  @DomName('SVGPathElement.animatedPathSegList')
  @DocsEditable()
  PathSegList get animatedPathSegList =>
      _blink.BlinkSVGPathElement.instance.animatedPathSegList_Getter_(this);

  @DomName('SVGPathElement.normalizedPathSegList')
  @DocsEditable()
  PathSegList get normalizedPathSegList =>
      _blink.BlinkSVGPathElement.instance.normalizedPathSegList_Getter_(this);

  @DomName('SVGPathElement.pathLength')
  @DocsEditable()
  AnimatedNumber get pathLength =>
      _blink.BlinkSVGPathElement.instance.pathLength_Getter_(this);

  @DomName('SVGPathElement.pathSegList')
  @DocsEditable()
  PathSegList get pathSegList =>
      _blink.BlinkSVGPathElement.instance.pathSegList_Getter_(this);

  @DomName('SVGPathElement.createSVGPathSegArcAbs')
  @DocsEditable()
  PathSegArcAbs createSvgPathSegArcAbs(num x, num y, num r1, num r2, num angle,
          bool largeArcFlag, bool sweepFlag) =>
      _blink.BlinkSVGPathElement.instance.createSVGPathSegArcAbs_Callback_7_(
          this, x, y, r1, r2, angle, largeArcFlag, sweepFlag);

  @DomName('SVGPathElement.createSVGPathSegArcRel')
  @DocsEditable()
  PathSegArcRel createSvgPathSegArcRel(num x, num y, num r1, num r2, num angle,
          bool largeArcFlag, bool sweepFlag) =>
      _blink.BlinkSVGPathElement.instance.createSVGPathSegArcRel_Callback_7_(
          this, x, y, r1, r2, angle, largeArcFlag, sweepFlag);

  @DomName('SVGPathElement.createSVGPathSegClosePath')
  @DocsEditable()
  PathSegClosePath createSvgPathSegClosePath() =>
      _blink.BlinkSVGPathElement.instance
          .createSVGPathSegClosePath_Callback_0_(this);

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicAbs')
  @DocsEditable()
  PathSegCurvetoCubicAbs createSvgPathSegCurvetoCubicAbs(
          num x, num y, num x1, num y1, num x2, num y2) =>
      _blink.BlinkSVGPathElement.instance
          .createSVGPathSegCurvetoCubicAbs_Callback_6_(
              this, x, y, x1, y1, x2, y2);

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicRel')
  @DocsEditable()
  PathSegCurvetoCubicRel createSvgPathSegCurvetoCubicRel(
          num x, num y, num x1, num y1, num x2, num y2) =>
      _blink.BlinkSVGPathElement.instance
          .createSVGPathSegCurvetoCubicRel_Callback_6_(
              this, x, y, x1, y1, x2, y2);

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothAbs')
  @DocsEditable()
  PathSegCurvetoCubicSmoothAbs createSvgPathSegCurvetoCubicSmoothAbs(
          num x, num y, num x2, num y2) =>
      _blink.BlinkSVGPathElement.instance
          .createSVGPathSegCurvetoCubicSmoothAbs_Callback_4_(
              this, x, y, x2, y2);

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothRel')
  @DocsEditable()
  PathSegCurvetoCubicSmoothRel createSvgPathSegCurvetoCubicSmoothRel(
          num x, num y, num x2, num y2) =>
      _blink.BlinkSVGPathElement.instance
          .createSVGPathSegCurvetoCubicSmoothRel_Callback_4_(
              this, x, y, x2, y2);

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticAbs')
  @DocsEditable()
  PathSegCurvetoQuadraticAbs createSvgPathSegCurvetoQuadraticAbs(
          num x, num y, num x1, num y1) =>
      _blink.BlinkSVGPathElement.instance
          .createSVGPathSegCurvetoQuadraticAbs_Callback_4_(this, x, y, x1, y1);

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticRel')
  @DocsEditable()
  PathSegCurvetoQuadraticRel createSvgPathSegCurvetoQuadraticRel(
          num x, num y, num x1, num y1) =>
      _blink.BlinkSVGPathElement.instance
          .createSVGPathSegCurvetoQuadraticRel_Callback_4_(this, x, y, x1, y1);

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothAbs')
  @DocsEditable()
  PathSegCurvetoQuadraticSmoothAbs createSvgPathSegCurvetoQuadraticSmoothAbs(
          num x, num y) =>
      _blink.BlinkSVGPathElement.instance
          .createSVGPathSegCurvetoQuadraticSmoothAbs_Callback_2_(this, x, y);

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothRel')
  @DocsEditable()
  PathSegCurvetoQuadraticSmoothRel createSvgPathSegCurvetoQuadraticSmoothRel(
          num x, num y) =>
      _blink.BlinkSVGPathElement.instance
          .createSVGPathSegCurvetoQuadraticSmoothRel_Callback_2_(this, x, y);

  @DomName('SVGPathElement.createSVGPathSegLinetoAbs')
  @DocsEditable()
  PathSegLinetoAbs createSvgPathSegLinetoAbs(num x, num y) =>
      _blink.BlinkSVGPathElement.instance
          .createSVGPathSegLinetoAbs_Callback_2_(this, x, y);

  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalAbs')
  @DocsEditable()
  PathSegLinetoHorizontalAbs createSvgPathSegLinetoHorizontalAbs(num x) =>
      _blink.BlinkSVGPathElement.instance
          .createSVGPathSegLinetoHorizontalAbs_Callback_1_(this, x);

  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalRel')
  @DocsEditable()
  PathSegLinetoHorizontalRel createSvgPathSegLinetoHorizontalRel(num x) =>
      _blink.BlinkSVGPathElement.instance
          .createSVGPathSegLinetoHorizontalRel_Callback_1_(this, x);

  @DomName('SVGPathElement.createSVGPathSegLinetoRel')
  @DocsEditable()
  PathSegLinetoRel createSvgPathSegLinetoRel(num x, num y) =>
      _blink.BlinkSVGPathElement.instance
          .createSVGPathSegLinetoRel_Callback_2_(this, x, y);

  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalAbs')
  @DocsEditable()
  PathSegLinetoVerticalAbs createSvgPathSegLinetoVerticalAbs(num y) =>
      _blink.BlinkSVGPathElement.instance
          .createSVGPathSegLinetoVerticalAbs_Callback_1_(this, y);

  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalRel')
  @DocsEditable()
  PathSegLinetoVerticalRel createSvgPathSegLinetoVerticalRel(num y) =>
      _blink.BlinkSVGPathElement.instance
          .createSVGPathSegLinetoVerticalRel_Callback_1_(this, y);

  @DomName('SVGPathElement.createSVGPathSegMovetoAbs')
  @DocsEditable()
  PathSegMovetoAbs createSvgPathSegMovetoAbs(num x, num y) =>
      _blink.BlinkSVGPathElement.instance
          .createSVGPathSegMovetoAbs_Callback_2_(this, x, y);

  @DomName('SVGPathElement.createSVGPathSegMovetoRel')
  @DocsEditable()
  PathSegMovetoRel createSvgPathSegMovetoRel(num x, num y) =>
      _blink.BlinkSVGPathElement.instance
          .createSVGPathSegMovetoRel_Callback_2_(this, x, y);

  @DomName('SVGPathElement.getPathSegAtLength')
  @DocsEditable()
  int getPathSegAtLength(num distance) => _blink.BlinkSVGPathElement.instance
      .getPathSegAtLength_Callback_1_(this, distance);

  @DomName('SVGPathElement.getPointAtLength')
  @DocsEditable()
  Point getPointAtLength(num distance) => _blink.BlinkSVGPathElement.instance
      .getPointAtLength_Callback_1_(this, distance);

  @DomName('SVGPathElement.getTotalLength')
  @DocsEditable()
  num getTotalLength() =>
      _blink.BlinkSVGPathElement.instance.getTotalLength_Callback_0_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSeg')
@Unstable()
class PathSeg extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory PathSeg._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSeg.internal_() {}

  @DomName('SVGPathSeg.PATHSEG_ARC_ABS')
  @DocsEditable()
  static const int PATHSEG_ARC_ABS = 10;

  @DomName('SVGPathSeg.PATHSEG_ARC_REL')
  @DocsEditable()
  static const int PATHSEG_ARC_REL = 11;

  @DomName('SVGPathSeg.PATHSEG_CLOSEPATH')
  @DocsEditable()
  static const int PATHSEG_CLOSEPATH = 1;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_CUBIC_ABS')
  @DocsEditable()
  static const int PATHSEG_CURVETO_CUBIC_ABS = 6;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_CUBIC_REL')
  @DocsEditable()
  static const int PATHSEG_CURVETO_CUBIC_REL = 7;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_CUBIC_SMOOTH_ABS')
  @DocsEditable()
  static const int PATHSEG_CURVETO_CUBIC_SMOOTH_ABS = 16;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_CUBIC_SMOOTH_REL')
  @DocsEditable()
  static const int PATHSEG_CURVETO_CUBIC_SMOOTH_REL = 17;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_QUADRATIC_ABS')
  @DocsEditable()
  static const int PATHSEG_CURVETO_QUADRATIC_ABS = 8;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_QUADRATIC_REL')
  @DocsEditable()
  static const int PATHSEG_CURVETO_QUADRATIC_REL = 9;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_QUADRATIC_SMOOTH_ABS')
  @DocsEditable()
  static const int PATHSEG_CURVETO_QUADRATIC_SMOOTH_ABS = 18;

  @DomName('SVGPathSeg.PATHSEG_CURVETO_QUADRATIC_SMOOTH_REL')
  @DocsEditable()
  static const int PATHSEG_CURVETO_QUADRATIC_SMOOTH_REL = 19;

  @DomName('SVGPathSeg.PATHSEG_LINETO_ABS')
  @DocsEditable()
  static const int PATHSEG_LINETO_ABS = 4;

  @DomName('SVGPathSeg.PATHSEG_LINETO_HORIZONTAL_ABS')
  @DocsEditable()
  static const int PATHSEG_LINETO_HORIZONTAL_ABS = 12;

  @DomName('SVGPathSeg.PATHSEG_LINETO_HORIZONTAL_REL')
  @DocsEditable()
  static const int PATHSEG_LINETO_HORIZONTAL_REL = 13;

  @DomName('SVGPathSeg.PATHSEG_LINETO_REL')
  @DocsEditable()
  static const int PATHSEG_LINETO_REL = 5;

  @DomName('SVGPathSeg.PATHSEG_LINETO_VERTICAL_ABS')
  @DocsEditable()
  static const int PATHSEG_LINETO_VERTICAL_ABS = 14;

  @DomName('SVGPathSeg.PATHSEG_LINETO_VERTICAL_REL')
  @DocsEditable()
  static const int PATHSEG_LINETO_VERTICAL_REL = 15;

  @DomName('SVGPathSeg.PATHSEG_MOVETO_ABS')
  @DocsEditable()
  static const int PATHSEG_MOVETO_ABS = 2;

  @DomName('SVGPathSeg.PATHSEG_MOVETO_REL')
  @DocsEditable()
  static const int PATHSEG_MOVETO_REL = 3;

  @DomName('SVGPathSeg.PATHSEG_UNKNOWN')
  @DocsEditable()
  static const int PATHSEG_UNKNOWN = 0;

  @DomName('SVGPathSeg.pathSegType')
  @DocsEditable()
  int get pathSegType =>
      _blink.BlinkSVGPathSeg.instance.pathSegType_Getter_(this);

  @DomName('SVGPathSeg.pathSegTypeAsLetter')
  @DocsEditable()
  String get pathSegTypeAsLetter =>
      _blink.BlinkSVGPathSeg.instance.pathSegTypeAsLetter_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegArcAbs')
@Unstable()
class PathSegArcAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegArcAbs._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegArcAbs.internal_() : super.internal_();

  @DomName('SVGPathSegArcAbs.angle')
  @DocsEditable()
  num get angle => _blink.BlinkSVGPathSegArcAbs.instance.angle_Getter_(this);

  @DomName('SVGPathSegArcAbs.angle')
  @DocsEditable()
  set angle(num value) =>
      _blink.BlinkSVGPathSegArcAbs.instance.angle_Setter_(this, value);

  @DomName('SVGPathSegArcAbs.largeArcFlag')
  @DocsEditable()
  bool get largeArcFlag =>
      _blink.BlinkSVGPathSegArcAbs.instance.largeArcFlag_Getter_(this);

  @DomName('SVGPathSegArcAbs.largeArcFlag')
  @DocsEditable()
  set largeArcFlag(bool value) =>
      _blink.BlinkSVGPathSegArcAbs.instance.largeArcFlag_Setter_(this, value);

  @DomName('SVGPathSegArcAbs.r1')
  @DocsEditable()
  num get r1 => _blink.BlinkSVGPathSegArcAbs.instance.r1_Getter_(this);

  @DomName('SVGPathSegArcAbs.r1')
  @DocsEditable()
  set r1(num value) =>
      _blink.BlinkSVGPathSegArcAbs.instance.r1_Setter_(this, value);

  @DomName('SVGPathSegArcAbs.r2')
  @DocsEditable()
  num get r2 => _blink.BlinkSVGPathSegArcAbs.instance.r2_Getter_(this);

  @DomName('SVGPathSegArcAbs.r2')
  @DocsEditable()
  set r2(num value) =>
      _blink.BlinkSVGPathSegArcAbs.instance.r2_Setter_(this, value);

  @DomName('SVGPathSegArcAbs.sweepFlag')
  @DocsEditable()
  bool get sweepFlag =>
      _blink.BlinkSVGPathSegArcAbs.instance.sweepFlag_Getter_(this);

  @DomName('SVGPathSegArcAbs.sweepFlag')
  @DocsEditable()
  set sweepFlag(bool value) =>
      _blink.BlinkSVGPathSegArcAbs.instance.sweepFlag_Setter_(this, value);

  @DomName('SVGPathSegArcAbs.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegArcAbs.instance.x_Getter_(this);

  @DomName('SVGPathSegArcAbs.x')
  @DocsEditable()
  set x(num value) =>
      _blink.BlinkSVGPathSegArcAbs.instance.x_Setter_(this, value);

  @DomName('SVGPathSegArcAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegArcAbs.instance.y_Getter_(this);

  @DomName('SVGPathSegArcAbs.y')
  @DocsEditable()
  set y(num value) =>
      _blink.BlinkSVGPathSegArcAbs.instance.y_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegArcRel')
@Unstable()
class PathSegArcRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegArcRel._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegArcRel.internal_() : super.internal_();

  @DomName('SVGPathSegArcRel.angle')
  @DocsEditable()
  num get angle => _blink.BlinkSVGPathSegArcRel.instance.angle_Getter_(this);

  @DomName('SVGPathSegArcRel.angle')
  @DocsEditable()
  set angle(num value) =>
      _blink.BlinkSVGPathSegArcRel.instance.angle_Setter_(this, value);

  @DomName('SVGPathSegArcRel.largeArcFlag')
  @DocsEditable()
  bool get largeArcFlag =>
      _blink.BlinkSVGPathSegArcRel.instance.largeArcFlag_Getter_(this);

  @DomName('SVGPathSegArcRel.largeArcFlag')
  @DocsEditable()
  set largeArcFlag(bool value) =>
      _blink.BlinkSVGPathSegArcRel.instance.largeArcFlag_Setter_(this, value);

  @DomName('SVGPathSegArcRel.r1')
  @DocsEditable()
  num get r1 => _blink.BlinkSVGPathSegArcRel.instance.r1_Getter_(this);

  @DomName('SVGPathSegArcRel.r1')
  @DocsEditable()
  set r1(num value) =>
      _blink.BlinkSVGPathSegArcRel.instance.r1_Setter_(this, value);

  @DomName('SVGPathSegArcRel.r2')
  @DocsEditable()
  num get r2 => _blink.BlinkSVGPathSegArcRel.instance.r2_Getter_(this);

  @DomName('SVGPathSegArcRel.r2')
  @DocsEditable()
  set r2(num value) =>
      _blink.BlinkSVGPathSegArcRel.instance.r2_Setter_(this, value);

  @DomName('SVGPathSegArcRel.sweepFlag')
  @DocsEditable()
  bool get sweepFlag =>
      _blink.BlinkSVGPathSegArcRel.instance.sweepFlag_Getter_(this);

  @DomName('SVGPathSegArcRel.sweepFlag')
  @DocsEditable()
  set sweepFlag(bool value) =>
      _blink.BlinkSVGPathSegArcRel.instance.sweepFlag_Setter_(this, value);

  @DomName('SVGPathSegArcRel.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegArcRel.instance.x_Getter_(this);

  @DomName('SVGPathSegArcRel.x')
  @DocsEditable()
  set x(num value) =>
      _blink.BlinkSVGPathSegArcRel.instance.x_Setter_(this, value);

  @DomName('SVGPathSegArcRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegArcRel.instance.y_Getter_(this);

  @DomName('SVGPathSegArcRel.y')
  @DocsEditable()
  set y(num value) =>
      _blink.BlinkSVGPathSegArcRel.instance.y_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegClosePath')
@Unstable()
class PathSegClosePath extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegClosePath._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegClosePath.internal_() : super.internal_();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegCurvetoCubicAbs')
@Unstable()
class PathSegCurvetoCubicAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoCubicAbs._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegCurvetoCubicAbs.internal_() : super.internal_();

  @DomName('SVGPathSegCurvetoCubicAbs.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.x_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicAbs.x')
  @DocsEditable()
  set x(num value) =>
      _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.x_Setter_(this, value);

  @DomName('SVGPathSegCurvetoCubicAbs.x1')
  @DocsEditable()
  num get x1 => _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.x1_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicAbs.x1')
  @DocsEditable()
  set x1(num value) =>
      _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.x1_Setter_(this, value);

  @DomName('SVGPathSegCurvetoCubicAbs.x2')
  @DocsEditable()
  num get x2 => _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.x2_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicAbs.x2')
  @DocsEditable()
  set x2(num value) =>
      _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.x2_Setter_(this, value);

  @DomName('SVGPathSegCurvetoCubicAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.y_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicAbs.y')
  @DocsEditable()
  set y(num value) =>
      _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.y_Setter_(this, value);

  @DomName('SVGPathSegCurvetoCubicAbs.y1')
  @DocsEditable()
  num get y1 => _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.y1_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicAbs.y1')
  @DocsEditable()
  set y1(num value) =>
      _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.y1_Setter_(this, value);

  @DomName('SVGPathSegCurvetoCubicAbs.y2')
  @DocsEditable()
  num get y2 => _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.y2_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicAbs.y2')
  @DocsEditable()
  set y2(num value) =>
      _blink.BlinkSVGPathSegCurvetoCubicAbs.instance.y2_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegCurvetoCubicRel')
@Unstable()
class PathSegCurvetoCubicRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoCubicRel._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegCurvetoCubicRel.internal_() : super.internal_();

  @DomName('SVGPathSegCurvetoCubicRel.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegCurvetoCubicRel.instance.x_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicRel.x')
  @DocsEditable()
  set x(num value) =>
      _blink.BlinkSVGPathSegCurvetoCubicRel.instance.x_Setter_(this, value);

  @DomName('SVGPathSegCurvetoCubicRel.x1')
  @DocsEditable()
  num get x1 => _blink.BlinkSVGPathSegCurvetoCubicRel.instance.x1_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicRel.x1')
  @DocsEditable()
  set x1(num value) =>
      _blink.BlinkSVGPathSegCurvetoCubicRel.instance.x1_Setter_(this, value);

  @DomName('SVGPathSegCurvetoCubicRel.x2')
  @DocsEditable()
  num get x2 => _blink.BlinkSVGPathSegCurvetoCubicRel.instance.x2_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicRel.x2')
  @DocsEditable()
  set x2(num value) =>
      _blink.BlinkSVGPathSegCurvetoCubicRel.instance.x2_Setter_(this, value);

  @DomName('SVGPathSegCurvetoCubicRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegCurvetoCubicRel.instance.y_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicRel.y')
  @DocsEditable()
  set y(num value) =>
      _blink.BlinkSVGPathSegCurvetoCubicRel.instance.y_Setter_(this, value);

  @DomName('SVGPathSegCurvetoCubicRel.y1')
  @DocsEditable()
  num get y1 => _blink.BlinkSVGPathSegCurvetoCubicRel.instance.y1_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicRel.y1')
  @DocsEditable()
  set y1(num value) =>
      _blink.BlinkSVGPathSegCurvetoCubicRel.instance.y1_Setter_(this, value);

  @DomName('SVGPathSegCurvetoCubicRel.y2')
  @DocsEditable()
  num get y2 => _blink.BlinkSVGPathSegCurvetoCubicRel.instance.y2_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicRel.y2')
  @DocsEditable()
  set y2(num value) =>
      _blink.BlinkSVGPathSegCurvetoCubicRel.instance.y2_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegCurvetoCubicSmoothAbs')
@Unstable()
class PathSegCurvetoCubicSmoothAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoCubicSmoothAbs._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegCurvetoCubicSmoothAbs.internal_() : super.internal_();

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x')
  @DocsEditable()
  num get x =>
      _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.instance.x_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.instance
      .x_Setter_(this, value);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x2')
  @DocsEditable()
  num get x2 =>
      _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.instance.x2_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x2')
  @DocsEditable()
  set x2(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.instance
      .x2_Setter_(this, value);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y')
  @DocsEditable()
  num get y =>
      _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.instance.y_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.instance
      .y_Setter_(this, value);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y2')
  @DocsEditable()
  num get y2 =>
      _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.instance.y2_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y2')
  @DocsEditable()
  set y2(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothAbs.instance
      .y2_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegCurvetoCubicSmoothRel')
@Unstable()
class PathSegCurvetoCubicSmoothRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoCubicSmoothRel._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegCurvetoCubicSmoothRel.internal_() : super.internal_();

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x')
  @DocsEditable()
  num get x =>
      _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.instance.x_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.instance
      .x_Setter_(this, value);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x2')
  @DocsEditable()
  num get x2 =>
      _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.instance.x2_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x2')
  @DocsEditable()
  set x2(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.instance
      .x2_Setter_(this, value);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y')
  @DocsEditable()
  num get y =>
      _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.instance.y_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.instance
      .y_Setter_(this, value);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y2')
  @DocsEditable()
  num get y2 =>
      _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.instance.y2_Getter_(this);

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y2')
  @DocsEditable()
  set y2(num value) => _blink.BlinkSVGPathSegCurvetoCubicSmoothRel.instance
      .y2_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegCurvetoQuadraticAbs')
@Unstable()
class PathSegCurvetoQuadraticAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoQuadraticAbs._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegCurvetoQuadraticAbs.internal_() : super.internal_();

  @DomName('SVGPathSegCurvetoQuadraticAbs.x')
  @DocsEditable()
  num get x =>
      _blink.BlinkSVGPathSegCurvetoQuadraticAbs.instance.x_Getter_(this);

  @DomName('SVGPathSegCurvetoQuadraticAbs.x')
  @DocsEditable()
  set x(num value) =>
      _blink.BlinkSVGPathSegCurvetoQuadraticAbs.instance.x_Setter_(this, value);

  @DomName('SVGPathSegCurvetoQuadraticAbs.x1')
  @DocsEditable()
  num get x1 =>
      _blink.BlinkSVGPathSegCurvetoQuadraticAbs.instance.x1_Getter_(this);

  @DomName('SVGPathSegCurvetoQuadraticAbs.x1')
  @DocsEditable()
  set x1(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticAbs.instance
      .x1_Setter_(this, value);

  @DomName('SVGPathSegCurvetoQuadraticAbs.y')
  @DocsEditable()
  num get y =>
      _blink.BlinkSVGPathSegCurvetoQuadraticAbs.instance.y_Getter_(this);

  @DomName('SVGPathSegCurvetoQuadraticAbs.y')
  @DocsEditable()
  set y(num value) =>
      _blink.BlinkSVGPathSegCurvetoQuadraticAbs.instance.y_Setter_(this, value);

  @DomName('SVGPathSegCurvetoQuadraticAbs.y1')
  @DocsEditable()
  num get y1 =>
      _blink.BlinkSVGPathSegCurvetoQuadraticAbs.instance.y1_Getter_(this);

  @DomName('SVGPathSegCurvetoQuadraticAbs.y1')
  @DocsEditable()
  set y1(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticAbs.instance
      .y1_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegCurvetoQuadraticRel')
@Unstable()
class PathSegCurvetoQuadraticRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoQuadraticRel._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegCurvetoQuadraticRel.internal_() : super.internal_();

  @DomName('SVGPathSegCurvetoQuadraticRel.x')
  @DocsEditable()
  num get x =>
      _blink.BlinkSVGPathSegCurvetoQuadraticRel.instance.x_Getter_(this);

  @DomName('SVGPathSegCurvetoQuadraticRel.x')
  @DocsEditable()
  set x(num value) =>
      _blink.BlinkSVGPathSegCurvetoQuadraticRel.instance.x_Setter_(this, value);

  @DomName('SVGPathSegCurvetoQuadraticRel.x1')
  @DocsEditable()
  num get x1 =>
      _blink.BlinkSVGPathSegCurvetoQuadraticRel.instance.x1_Getter_(this);

  @DomName('SVGPathSegCurvetoQuadraticRel.x1')
  @DocsEditable()
  set x1(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticRel.instance
      .x1_Setter_(this, value);

  @DomName('SVGPathSegCurvetoQuadraticRel.y')
  @DocsEditable()
  num get y =>
      _blink.BlinkSVGPathSegCurvetoQuadraticRel.instance.y_Getter_(this);

  @DomName('SVGPathSegCurvetoQuadraticRel.y')
  @DocsEditable()
  set y(num value) =>
      _blink.BlinkSVGPathSegCurvetoQuadraticRel.instance.y_Setter_(this, value);

  @DomName('SVGPathSegCurvetoQuadraticRel.y1')
  @DocsEditable()
  num get y1 =>
      _blink.BlinkSVGPathSegCurvetoQuadraticRel.instance.y1_Getter_(this);

  @DomName('SVGPathSegCurvetoQuadraticRel.y1')
  @DocsEditable()
  set y1(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticRel.instance
      .y1_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegCurvetoQuadraticSmoothAbs')
@Unstable()
class PathSegCurvetoQuadraticSmoothAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoQuadraticSmoothAbs._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegCurvetoQuadraticSmoothAbs.internal_() : super.internal_();

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.x')
  @DocsEditable()
  num get x =>
      _blink.BlinkSVGPathSegCurvetoQuadraticSmoothAbs.instance.x_Getter_(this);

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothAbs.instance
      .x_Setter_(this, value);

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.y')
  @DocsEditable()
  num get y =>
      _blink.BlinkSVGPathSegCurvetoQuadraticSmoothAbs.instance.y_Getter_(this);

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothAbs.instance
      .y_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegCurvetoQuadraticSmoothRel')
@Unstable()
class PathSegCurvetoQuadraticSmoothRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegCurvetoQuadraticSmoothRel._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegCurvetoQuadraticSmoothRel.internal_() : super.internal_();

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.x')
  @DocsEditable()
  num get x =>
      _blink.BlinkSVGPathSegCurvetoQuadraticSmoothRel.instance.x_Getter_(this);

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothRel.instance
      .x_Setter_(this, value);

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.y')
  @DocsEditable()
  num get y =>
      _blink.BlinkSVGPathSegCurvetoQuadraticSmoothRel.instance.y_Getter_(this);

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPathSegCurvetoQuadraticSmoothRel.instance
      .y_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegLinetoAbs')
@Unstable()
class PathSegLinetoAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoAbs._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegLinetoAbs.internal_() : super.internal_();

  @DomName('SVGPathSegLinetoAbs.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegLinetoAbs.instance.x_Getter_(this);

  @DomName('SVGPathSegLinetoAbs.x')
  @DocsEditable()
  set x(num value) =>
      _blink.BlinkSVGPathSegLinetoAbs.instance.x_Setter_(this, value);

  @DomName('SVGPathSegLinetoAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegLinetoAbs.instance.y_Getter_(this);

  @DomName('SVGPathSegLinetoAbs.y')
  @DocsEditable()
  set y(num value) =>
      _blink.BlinkSVGPathSegLinetoAbs.instance.y_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegLinetoHorizontalAbs')
@Unstable()
class PathSegLinetoHorizontalAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoHorizontalAbs._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegLinetoHorizontalAbs.internal_() : super.internal_();

  @DomName('SVGPathSegLinetoHorizontalAbs.x')
  @DocsEditable()
  num get x =>
      _blink.BlinkSVGPathSegLinetoHorizontalAbs.instance.x_Getter_(this);

  @DomName('SVGPathSegLinetoHorizontalAbs.x')
  @DocsEditable()
  set x(num value) =>
      _blink.BlinkSVGPathSegLinetoHorizontalAbs.instance.x_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegLinetoHorizontalRel')
@Unstable()
class PathSegLinetoHorizontalRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoHorizontalRel._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegLinetoHorizontalRel.internal_() : super.internal_();

  @DomName('SVGPathSegLinetoHorizontalRel.x')
  @DocsEditable()
  num get x =>
      _blink.BlinkSVGPathSegLinetoHorizontalRel.instance.x_Getter_(this);

  @DomName('SVGPathSegLinetoHorizontalRel.x')
  @DocsEditable()
  set x(num value) =>
      _blink.BlinkSVGPathSegLinetoHorizontalRel.instance.x_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegLinetoRel')
@Unstable()
class PathSegLinetoRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoRel._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegLinetoRel.internal_() : super.internal_();

  @DomName('SVGPathSegLinetoRel.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegLinetoRel.instance.x_Getter_(this);

  @DomName('SVGPathSegLinetoRel.x')
  @DocsEditable()
  set x(num value) =>
      _blink.BlinkSVGPathSegLinetoRel.instance.x_Setter_(this, value);

  @DomName('SVGPathSegLinetoRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegLinetoRel.instance.y_Getter_(this);

  @DomName('SVGPathSegLinetoRel.y')
  @DocsEditable()
  set y(num value) =>
      _blink.BlinkSVGPathSegLinetoRel.instance.y_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegLinetoVerticalAbs')
@Unstable()
class PathSegLinetoVerticalAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoVerticalAbs._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegLinetoVerticalAbs.internal_() : super.internal_();

  @DomName('SVGPathSegLinetoVerticalAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegLinetoVerticalAbs.instance.y_Getter_(this);

  @DomName('SVGPathSegLinetoVerticalAbs.y')
  @DocsEditable()
  set y(num value) =>
      _blink.BlinkSVGPathSegLinetoVerticalAbs.instance.y_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegLinetoVerticalRel')
@Unstable()
class PathSegLinetoVerticalRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegLinetoVerticalRel._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegLinetoVerticalRel.internal_() : super.internal_();

  @DomName('SVGPathSegLinetoVerticalRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegLinetoVerticalRel.instance.y_Getter_(this);

  @DomName('SVGPathSegLinetoVerticalRel.y')
  @DocsEditable()
  set y(num value) =>
      _blink.BlinkSVGPathSegLinetoVerticalRel.instance.y_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegList')
@Unstable()
class PathSegList extends DartHtmlDomObject
    with ListMixin<PathSeg>, ImmutableListMixin<PathSeg>
    implements List<PathSeg> {
  // To suppress missing implicit constructor warnings.
  factory PathSegList._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegList.internal_() {}

  @DomName('SVGPathSegList.length')
  @DocsEditable()
  @Experimental() // untriaged
  int get length => _blink.BlinkSVGPathSegList.instance.length_Getter_(this);

  @DomName('SVGPathSegList.numberOfItems')
  @DocsEditable()
  int get numberOfItems =>
      _blink.BlinkSVGPathSegList.instance.numberOfItems_Getter_(this);

  PathSeg operator [](int index) {
    if (index < 0 || index >= length) throw new RangeError.index(index, this);
    return getItem(index);
  }

  void operator []=(int index, PathSeg value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<PathSeg> mixins.
  // PathSeg is the element type.

  set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  PathSeg get first {
    if (this.length > 0) {
      return getItem(0);
    }
    throw new StateError("No elements");
  }

  PathSeg get last {
    int len = this.length;
    if (len > 0) {
      return getItem(len - 1);
    }
    throw new StateError("No elements");
  }

  PathSeg get single {
    int len = this.length;
    if (len == 1) {
      return getItem(0);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  PathSeg elementAt(int index) => this[index];
  // -- end List<PathSeg> mixins.

  @DomName('SVGPathSegList.__setter__')
  @DocsEditable()
  @Experimental() // untriaged
  void __setter__(int index, PathSeg newItem) =>
      _blink.BlinkSVGPathSegList.instance
          .$__setter___Callback_2_(this, index, newItem);

  @DomName('SVGPathSegList.appendItem')
  @DocsEditable()
  PathSeg appendItem(PathSeg newItem) =>
      _blink.BlinkSVGPathSegList.instance.appendItem_Callback_1_(this, newItem);

  @DomName('SVGPathSegList.clear')
  @DocsEditable()
  void clear() => _blink.BlinkSVGPathSegList.instance.clear_Callback_0_(this);

  @DomName('SVGPathSegList.getItem')
  @DocsEditable()
  PathSeg getItem(int index) =>
      _blink.BlinkSVGPathSegList.instance.getItem_Callback_1_(this, index);

  @DomName('SVGPathSegList.initialize')
  @DocsEditable()
  PathSeg initialize(PathSeg newItem) =>
      _blink.BlinkSVGPathSegList.instance.initialize_Callback_1_(this, newItem);

  @DomName('SVGPathSegList.insertItemBefore')
  @DocsEditable()
  PathSeg insertItemBefore(PathSeg newItem, int index) =>
      _blink.BlinkSVGPathSegList.instance
          .insertItemBefore_Callback_2_(this, newItem, index);

  @DomName('SVGPathSegList.removeItem')
  @DocsEditable()
  PathSeg removeItem(int index) =>
      _blink.BlinkSVGPathSegList.instance.removeItem_Callback_1_(this, index);

  @DomName('SVGPathSegList.replaceItem')
  @DocsEditable()
  PathSeg replaceItem(PathSeg newItem, int index) =>
      _blink.BlinkSVGPathSegList.instance
          .replaceItem_Callback_2_(this, newItem, index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegMovetoAbs')
@Unstable()
class PathSegMovetoAbs extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegMovetoAbs._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegMovetoAbs.internal_() : super.internal_();

  @DomName('SVGPathSegMovetoAbs.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegMovetoAbs.instance.x_Getter_(this);

  @DomName('SVGPathSegMovetoAbs.x')
  @DocsEditable()
  set x(num value) =>
      _blink.BlinkSVGPathSegMovetoAbs.instance.x_Setter_(this, value);

  @DomName('SVGPathSegMovetoAbs.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegMovetoAbs.instance.y_Getter_(this);

  @DomName('SVGPathSegMovetoAbs.y')
  @DocsEditable()
  set y(num value) =>
      _blink.BlinkSVGPathSegMovetoAbs.instance.y_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPathSegMovetoRel')
@Unstable()
class PathSegMovetoRel extends PathSeg {
  // To suppress missing implicit constructor warnings.
  factory PathSegMovetoRel._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PathSegMovetoRel.internal_() : super.internal_();

  @DomName('SVGPathSegMovetoRel.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPathSegMovetoRel.instance.x_Getter_(this);

  @DomName('SVGPathSegMovetoRel.x')
  @DocsEditable()
  set x(num value) =>
      _blink.BlinkSVGPathSegMovetoRel.instance.x_Setter_(this, value);

  @DomName('SVGPathSegMovetoRel.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPathSegMovetoRel.instance.y_Getter_(this);

  @DomName('SVGPathSegMovetoRel.y')
  @DocsEditable()
  set y(num value) =>
      _blink.BlinkSVGPathSegMovetoRel.instance.y_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPatternElement')
@Unstable()
class PatternElement extends SvgElement
    implements FitToViewBox, UriReference, Tests {
  // To suppress missing implicit constructor warnings.
  factory PatternElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGPatternElement.SVGPatternElement')
  @DocsEditable()
  factory PatternElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("pattern");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PatternElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  PatternElement.created() : super.created();

  @DomName('SVGPatternElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGPatternElement.instance.height_Getter_(this);

  @DomName('SVGPatternElement.patternContentUnits')
  @DocsEditable()
  AnimatedEnumeration get patternContentUnits =>
      _blink.BlinkSVGPatternElement.instance.patternContentUnits_Getter_(this);

  @DomName('SVGPatternElement.patternTransform')
  @DocsEditable()
  AnimatedTransformList get patternTransform =>
      _blink.BlinkSVGPatternElement.instance.patternTransform_Getter_(this);

  @DomName('SVGPatternElement.patternUnits')
  @DocsEditable()
  AnimatedEnumeration get patternUnits =>
      _blink.BlinkSVGPatternElement.instance.patternUnits_Getter_(this);

  @DomName('SVGPatternElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGPatternElement.instance.width_Getter_(this);

  @DomName('SVGPatternElement.x')
  @DocsEditable()
  AnimatedLength get x =>
      _blink.BlinkSVGPatternElement.instance.x_Getter_(this);

  @DomName('SVGPatternElement.y')
  @DocsEditable()
  AnimatedLength get y =>
      _blink.BlinkSVGPatternElement.instance.y_Getter_(this);

  @DomName('SVGPatternElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio =>
      _blink.BlinkSVGPatternElement.instance.preserveAspectRatio_Getter_(this);

  @DomName('SVGPatternElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox =>
      _blink.BlinkSVGPatternElement.instance.viewBox_Getter_(this);

  @DomName('SVGPatternElement.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions =>
      _blink.BlinkSVGPatternElement.instance.requiredExtensions_Getter_(this);

  @DomName('SVGPatternElement.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures =>
      _blink.BlinkSVGPatternElement.instance.requiredFeatures_Getter_(this);

  @DomName('SVGPatternElement.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage =>
      _blink.BlinkSVGPatternElement.instance.systemLanguage_Getter_(this);

  @DomName('SVGPatternElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) => _blink.BlinkSVGPatternElement.instance
      .hasExtension_Callback_1_(this, extension);

  @DomName('SVGPatternElement.href')
  @DocsEditable()
  AnimatedString get href =>
      _blink.BlinkSVGPatternElement.instance.href_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPoint')
@Unstable()
class Point extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory Point._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  Point.internal_() {}

  @DomName('SVGPoint.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGPoint.instance.x_Getter_(this);

  @DomName('SVGPoint.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGPoint.instance.x_Setter_(this, value);

  @DomName('SVGPoint.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGPoint.instance.y_Getter_(this);

  @DomName('SVGPoint.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGPoint.instance.y_Setter_(this, value);

  @DomName('SVGPoint.matrixTransform')
  @DocsEditable()
  Point matrixTransform(Matrix matrix) =>
      _blink.BlinkSVGPoint.instance.matrixTransform_Callback_1_(this, matrix);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPointList')
@Unstable()
class PointList extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory PointList._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PointList.internal_() {}

  @DomName('SVGPointList.length')
  @DocsEditable()
  @Experimental() // untriaged
  int get length => _blink.BlinkSVGPointList.instance.length_Getter_(this);

  @DomName('SVGPointList.numberOfItems')
  @DocsEditable()
  int get numberOfItems =>
      _blink.BlinkSVGPointList.instance.numberOfItems_Getter_(this);

  @DomName('SVGPointList.__setter__')
  @DocsEditable()
  @Experimental() // untriaged
  void __setter__(int index, Point newItem) => _blink.BlinkSVGPointList.instance
      .$__setter___Callback_2_(this, index, newItem);

  @DomName('SVGPointList.appendItem')
  @DocsEditable()
  Point appendItem(Point newItem) =>
      _blink.BlinkSVGPointList.instance.appendItem_Callback_1_(this, newItem);

  @DomName('SVGPointList.clear')
  @DocsEditable()
  void clear() => _blink.BlinkSVGPointList.instance.clear_Callback_0_(this);

  @DomName('SVGPointList.getItem')
  @DocsEditable()
  Point getItem(int index) =>
      _blink.BlinkSVGPointList.instance.getItem_Callback_1_(this, index);

  @DomName('SVGPointList.initialize')
  @DocsEditable()
  Point initialize(Point newItem) =>
      _blink.BlinkSVGPointList.instance.initialize_Callback_1_(this, newItem);

  @DomName('SVGPointList.insertItemBefore')
  @DocsEditable()
  Point insertItemBefore(Point newItem, int index) =>
      _blink.BlinkSVGPointList.instance
          .insertItemBefore_Callback_2_(this, newItem, index);

  @DomName('SVGPointList.removeItem')
  @DocsEditable()
  Point removeItem(int index) =>
      _blink.BlinkSVGPointList.instance.removeItem_Callback_1_(this, index);

  @DomName('SVGPointList.replaceItem')
  @DocsEditable()
  Point replaceItem(Point newItem, int index) =>
      _blink.BlinkSVGPointList.instance
          .replaceItem_Callback_2_(this, newItem, index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPolygonElement')
@Unstable()
class PolygonElement extends GeometryElement {
  // To suppress missing implicit constructor warnings.
  factory PolygonElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGPolygonElement.SVGPolygonElement')
  @DocsEditable()
  factory PolygonElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("polygon");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PolygonElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  PolygonElement.created() : super.created();

  @DomName('SVGPolygonElement.animatedPoints')
  @DocsEditable()
  PointList get animatedPoints =>
      _blink.BlinkSVGPolygonElement.instance.animatedPoints_Getter_(this);

  @DomName('SVGPolygonElement.points')
  @DocsEditable()
  PointList get points =>
      _blink.BlinkSVGPolygonElement.instance.points_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPolylineElement')
@Unstable()
class PolylineElement extends GeometryElement {
  // To suppress missing implicit constructor warnings.
  factory PolylineElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGPolylineElement.SVGPolylineElement')
  @DocsEditable()
  factory PolylineElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("polyline");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PolylineElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  PolylineElement.created() : super.created();

  @DomName('SVGPolylineElement.animatedPoints')
  @DocsEditable()
  PointList get animatedPoints =>
      _blink.BlinkSVGPolylineElement.instance.animatedPoints_Getter_(this);

  @DomName('SVGPolylineElement.points')
  @DocsEditable()
  PointList get points =>
      _blink.BlinkSVGPolylineElement.instance.points_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGPreserveAspectRatio')
@Unstable()
class PreserveAspectRatio extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory PreserveAspectRatio._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  PreserveAspectRatio.internal_() {}

  @DomName('SVGPreserveAspectRatio.SVG_MEETORSLICE_MEET')
  @DocsEditable()
  static const int SVG_MEETORSLICE_MEET = 1;

  @DomName('SVGPreserveAspectRatio.SVG_MEETORSLICE_SLICE')
  @DocsEditable()
  static const int SVG_MEETORSLICE_SLICE = 2;

  @DomName('SVGPreserveAspectRatio.SVG_MEETORSLICE_UNKNOWN')
  @DocsEditable()
  static const int SVG_MEETORSLICE_UNKNOWN = 0;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_NONE')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_NONE = 1;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_UNKNOWN')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_UNKNOWN = 0;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMAXYMAX')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_XMAXYMAX = 10;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMAXYMID')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_XMAXYMID = 7;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMAXYMIN')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_XMAXYMIN = 4;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMIDYMAX')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_XMIDYMAX = 9;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMIDYMID')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_XMIDYMID = 6;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMIDYMIN')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_XMIDYMIN = 3;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMINYMAX')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_XMINYMAX = 8;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMINYMID')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_XMINYMID = 5;

  @DomName('SVGPreserveAspectRatio.SVG_PRESERVEASPECTRATIO_XMINYMIN')
  @DocsEditable()
  static const int SVG_PRESERVEASPECTRATIO_XMINYMIN = 2;

  @DomName('SVGPreserveAspectRatio.align')
  @DocsEditable()
  int get align =>
      _blink.BlinkSVGPreserveAspectRatio.instance.align_Getter_(this);

  @DomName('SVGPreserveAspectRatio.align')
  @DocsEditable()
  set align(int value) =>
      _blink.BlinkSVGPreserveAspectRatio.instance.align_Setter_(this, value);

  @DomName('SVGPreserveAspectRatio.meetOrSlice')
  @DocsEditable()
  int get meetOrSlice =>
      _blink.BlinkSVGPreserveAspectRatio.instance.meetOrSlice_Getter_(this);

  @DomName('SVGPreserveAspectRatio.meetOrSlice')
  @DocsEditable()
  set meetOrSlice(int value) => _blink.BlinkSVGPreserveAspectRatio.instance
      .meetOrSlice_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGRadialGradientElement')
@Unstable()
class RadialGradientElement extends _GradientElement {
  // To suppress missing implicit constructor warnings.
  factory RadialGradientElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGRadialGradientElement.SVGRadialGradientElement')
  @DocsEditable()
  factory RadialGradientElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("radialGradient");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  RadialGradientElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  RadialGradientElement.created() : super.created();

  @DomName('SVGRadialGradientElement.cx')
  @DocsEditable()
  AnimatedLength get cx =>
      _blink.BlinkSVGRadialGradientElement.instance.cx_Getter_(this);

  @DomName('SVGRadialGradientElement.cy')
  @DocsEditable()
  AnimatedLength get cy =>
      _blink.BlinkSVGRadialGradientElement.instance.cy_Getter_(this);

  @DomName('SVGRadialGradientElement.fr')
  @DocsEditable()
  AnimatedLength get fr =>
      _blink.BlinkSVGRadialGradientElement.instance.fr_Getter_(this);

  @DomName('SVGRadialGradientElement.fx')
  @DocsEditable()
  AnimatedLength get fx =>
      _blink.BlinkSVGRadialGradientElement.instance.fx_Getter_(this);

  @DomName('SVGRadialGradientElement.fy')
  @DocsEditable()
  AnimatedLength get fy =>
      _blink.BlinkSVGRadialGradientElement.instance.fy_Getter_(this);

  @DomName('SVGRadialGradientElement.r')
  @DocsEditable()
  AnimatedLength get r =>
      _blink.BlinkSVGRadialGradientElement.instance.r_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGRect')
@Unstable()
class Rect extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory Rect._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  Rect.internal_() {}

  @DomName('SVGRect.height')
  @DocsEditable()
  num get height => _blink.BlinkSVGRect.instance.height_Getter_(this);

  @DomName('SVGRect.height')
  @DocsEditable()
  set height(num value) =>
      _blink.BlinkSVGRect.instance.height_Setter_(this, value);

  @DomName('SVGRect.width')
  @DocsEditable()
  num get width => _blink.BlinkSVGRect.instance.width_Getter_(this);

  @DomName('SVGRect.width')
  @DocsEditable()
  set width(num value) =>
      _blink.BlinkSVGRect.instance.width_Setter_(this, value);

  @DomName('SVGRect.x')
  @DocsEditable()
  num get x => _blink.BlinkSVGRect.instance.x_Getter_(this);

  @DomName('SVGRect.x')
  @DocsEditable()
  set x(num value) => _blink.BlinkSVGRect.instance.x_Setter_(this, value);

  @DomName('SVGRect.y')
  @DocsEditable()
  num get y => _blink.BlinkSVGRect.instance.y_Getter_(this);

  @DomName('SVGRect.y')
  @DocsEditable()
  set y(num value) => _blink.BlinkSVGRect.instance.y_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGRectElement')
@Unstable()
class RectElement extends GeometryElement {
  // To suppress missing implicit constructor warnings.
  factory RectElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGRectElement.SVGRectElement')
  @DocsEditable()
  factory RectElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("rect");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  RectElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  RectElement.created() : super.created();

  @DomName('SVGRectElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGRectElement.instance.height_Getter_(this);

  @DomName('SVGRectElement.rx')
  @DocsEditable()
  AnimatedLength get rx => _blink.BlinkSVGRectElement.instance.rx_Getter_(this);

  @DomName('SVGRectElement.ry')
  @DocsEditable()
  AnimatedLength get ry => _blink.BlinkSVGRectElement.instance.ry_Getter_(this);

  @DomName('SVGRectElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGRectElement.instance.width_Getter_(this);

  @DomName('SVGRectElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGRectElement.instance.x_Getter_(this);

  @DomName('SVGRectElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGRectElement.instance.y_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGScriptElement')
@Unstable()
class ScriptElement extends SvgElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory ScriptElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGScriptElement.SVGScriptElement')
  @DocsEditable()
  factory ScriptElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("script");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  ScriptElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  ScriptElement.created() : super.created();

  @DomName('SVGScriptElement.type')
  @DocsEditable()
  String get type => _blink.BlinkSVGScriptElement.instance.type_Getter_(this);

  @DomName('SVGScriptElement.type')
  @DocsEditable()
  set type(String value) =>
      _blink.BlinkSVGScriptElement.instance.type_Setter_(this, value);

  @DomName('SVGScriptElement.href')
  @DocsEditable()
  AnimatedString get href =>
      _blink.BlinkSVGScriptElement.instance.href_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGSetElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class SetElement extends AnimationElement {
  // To suppress missing implicit constructor warnings.
  factory SetElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGSetElement.SVGSetElement')
  @DocsEditable()
  factory SetElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("set");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  SetElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  SetElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGStopElement')
@Unstable()
class StopElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory StopElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGStopElement.SVGStopElement')
  @DocsEditable()
  factory StopElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("stop");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  StopElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  StopElement.created() : super.created();

  @DomName('SVGStopElement.offset')
  @DocsEditable()
  AnimatedNumber get gradientOffset =>
      _blink.BlinkSVGStopElement.instance.offset_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGStringList')
@Unstable()
class StringList extends DartHtmlDomObject
    with ListMixin<String>, ImmutableListMixin<String>
    implements List<String> {
  // To suppress missing implicit constructor warnings.
  factory StringList._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  StringList.internal_() {}

  @DomName('SVGStringList.length')
  @DocsEditable()
  @Experimental() // untriaged
  int get length => _blink.BlinkSVGStringList.instance.length_Getter_(this);

  @DomName('SVGStringList.numberOfItems')
  @DocsEditable()
  int get numberOfItems =>
      _blink.BlinkSVGStringList.instance.numberOfItems_Getter_(this);

  String operator [](int index) {
    if (index < 0 || index >= length) throw new RangeError.index(index, this);
    return getItem(index);
  }

  void operator []=(int index, String value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<String> mixins.
  // String is the element type.

  set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  String get first {
    if (this.length > 0) {
      return getItem(0);
    }
    throw new StateError("No elements");
  }

  String get last {
    int len = this.length;
    if (len > 0) {
      return getItem(len - 1);
    }
    throw new StateError("No elements");
  }

  String get single {
    int len = this.length;
    if (len == 1) {
      return getItem(0);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  String elementAt(int index) => this[index];
  // -- end List<String> mixins.

  @DomName('SVGStringList.__setter__')
  @DocsEditable()
  @Experimental() // untriaged
  void __setter__(int index, String newItem) =>
      _blink.BlinkSVGStringList.instance
          .$__setter___Callback_2_(this, index, newItem);

  @DomName('SVGStringList.appendItem')
  @DocsEditable()
  String appendItem(String newItem) =>
      _blink.BlinkSVGStringList.instance.appendItem_Callback_1_(this, newItem);

  @DomName('SVGStringList.clear')
  @DocsEditable()
  void clear() => _blink.BlinkSVGStringList.instance.clear_Callback_0_(this);

  @DomName('SVGStringList.getItem')
  @DocsEditable()
  String getItem(int index) =>
      _blink.BlinkSVGStringList.instance.getItem_Callback_1_(this, index);

  @DomName('SVGStringList.initialize')
  @DocsEditable()
  String initialize(String newItem) =>
      _blink.BlinkSVGStringList.instance.initialize_Callback_1_(this, newItem);

  @DomName('SVGStringList.insertItemBefore')
  @DocsEditable()
  String insertItemBefore(String item, int index) =>
      _blink.BlinkSVGStringList.instance
          .insertItemBefore_Callback_2_(this, item, index);

  @DomName('SVGStringList.removeItem')
  @DocsEditable()
  String removeItem(int index) =>
      _blink.BlinkSVGStringList.instance.removeItem_Callback_1_(this, index);

  @DomName('SVGStringList.replaceItem')
  @DocsEditable()
  String replaceItem(String newItem, int index) =>
      _blink.BlinkSVGStringList.instance
          .replaceItem_Callback_2_(this, newItem, index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGStyleElement')
// http://www.w3.org/TR/SVG/types.html#InterfaceSVGStylable
@Experimental() // nonstandard
class StyleElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory StyleElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGStyleElement.SVGStyleElement')
  @DocsEditable()
  factory StyleElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("style");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  StyleElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  StyleElement.created() : super.created();

  @DomName('SVGStyleElement.disabled')
  @DocsEditable()
  bool get disabled =>
      _blink.BlinkSVGStyleElement.instance.disabled_Getter_(this);

  @DomName('SVGStyleElement.disabled')
  @DocsEditable()
  set disabled(bool value) =>
      _blink.BlinkSVGStyleElement.instance.disabled_Setter_(this, value);

  @DomName('SVGStyleElement.media')
  @DocsEditable()
  String get media => _blink.BlinkSVGStyleElement.instance.media_Getter_(this);

  @DomName('SVGStyleElement.media')
  @DocsEditable()
  set media(String value) =>
      _blink.BlinkSVGStyleElement.instance.media_Setter_(this, value);

  @DomName('SVGStyleElement.sheet')
  @DocsEditable()
  @Experimental() // untriaged
  StyleSheet get sheet =>
      _blink.BlinkSVGStyleElement.instance.sheet_Getter_(this);

  @DomName('SVGStyleElement.title')
  @DocsEditable()
  String get title => _blink.BlinkSVGStyleElement.instance.title_Getter_(this);

  @DomName('SVGStyleElement.title')
  @DocsEditable()
  set title(String value) =>
      _blink.BlinkSVGStyleElement.instance.title_Setter_(this, value);

  @DomName('SVGStyleElement.type')
  @DocsEditable()
  String get type => _blink.BlinkSVGStyleElement.instance.type_Getter_(this);

  @DomName('SVGStyleElement.type')
  @DocsEditable()
  set type(String value) =>
      _blink.BlinkSVGStyleElement.instance.type_Setter_(this, value);
}
// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _AttributeClassSet extends CssClassSetImpl {
  final Element _element;

  _AttributeClassSet(this._element);

  Set<String> readClasses() {
    var classname = _element.attributes['class'];

    Set<String> s = new LinkedHashSet<String>();
    if (classname == null) {
      return s;
    }
    for (String name in classname.split(' ')) {
      String trimmed = name.trim();
      if (!trimmed.isEmpty) {
        s.add(trimmed);
      }
    }
    return s;
  }

  void writeClasses(Set s) {
    _element.attributes['class'] = s.join(' ');
  }
}

@DomName('SVGElement')
@Unstable()
class SvgElement extends Element implements GlobalEventHandlers {
  static final _START_TAG_REGEXP = new RegExp('<(\\w+)');

  factory SvgElement.tag(String tag) =>
      document.createElementNS("http://www.w3.org/2000/svg", tag);
  factory SvgElement.svg(String svg,
      {NodeValidator validator, NodeTreeSanitizer treeSanitizer}) {
    if (validator == null && treeSanitizer == null) {
      validator = new NodeValidatorBuilder.common()..allowSvg();
    }

    final match = _START_TAG_REGEXP.firstMatch(svg);
    var parentElement;
    if (match != null && match.group(1).toLowerCase() == 'svg') {
      parentElement = document.body;
    } else {
      parentElement = new SvgSvgElement();
    }
    var fragment = parentElement.createFragment(svg,
        validator: validator, treeSanitizer: treeSanitizer);
    return fragment.nodes.where((e) => e is SvgElement).single;
  }

  CssClassSet get classes => new _AttributeClassSet(this);

  List<Element> get children => new FilteredElementList(this);

  set children(List<Element> value) {
    final children = this.children;
    children.clear();
    children.addAll(value);
  }

  String get outerHtml {
    final container = new DivElement();
    final SvgElement cloned = this.clone(true);
    container.children.add(cloned);
    return container.innerHtml;
  }

  String get innerHtml {
    final container = new DivElement();
    final SvgElement cloned = this.clone(true);
    container.children.addAll(cloned.children);
    return container.innerHtml;
  }

  set innerHtml(String value) {
    this.setInnerHtml(value);
  }

  DocumentFragment createFragment(String svg,
      {NodeValidator validator, NodeTreeSanitizer treeSanitizer}) {
    if (treeSanitizer == null) {
      if (validator == null) {
        validator = new NodeValidatorBuilder.common()..allowSvg();
      }
      treeSanitizer = new NodeTreeSanitizer(validator);
    }

    // We create a fragment which will parse in the HTML parser
    var html = '<svg version="1.1">$svg</svg>';
    var fragment =
        document.body.createFragment(html, treeSanitizer: treeSanitizer);

    var svgFragment = new DocumentFragment();
    // The root is the <svg/> element, need to pull out the contents.
    var root = fragment.nodes.single;
    while (root.firstChild != null) {
      svgFragment.append(root.firstChild);
    }
    return svgFragment;
  }

  // Unsupported methods inherited from Element.

  @DomName('Element.insertAdjacentText')
  void insertAdjacentText(String where, String text) {
    throw new UnsupportedError("Cannot invoke insertAdjacentText on SVG.");
  }

  @DomName('Element.insertAdjacentHTML')
  void insertAdjacentHtml(String where, String text,
      {NodeValidator validator, NodeTreeSanitizer treeSanitizer}) {
    throw new UnsupportedError("Cannot invoke insertAdjacentHtml on SVG.");
  }

  @DomName('Element.insertAdjacentElement')
  Element insertAdjacentElement(String where, Element element) {
    throw new UnsupportedError("Cannot invoke insertAdjacentElement on SVG.");
  }

  HtmlCollection get _children {
    throw new UnsupportedError("Cannot get _children on SVG.");
  }

  bool get isContentEditable => false;
  void click() {
    throw new UnsupportedError("Cannot invoke click SVG.");
  }

  /**
   * Checks to see if the SVG element type is supported by the current platform.
   *
   * The tag should be a valid SVG element tag name.
   */
  static bool isTagSupported(String tag) {
    var e = new SvgElement.tag(tag);
    return e is SvgElement && !(e is UnknownElement);
  }

  set _svgClassName(AnimatedString value) =>
      _blink.BlinkSVGElement.instance.className_Setter_(this, value);

  // To suppress missing implicit constructor warnings.
  factory SvgElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGElement.abortEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> abortEvent =
      const EventStreamProvider<Event>('abort');

  @DomName('SVGElement.blurEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> blurEvent =
      const EventStreamProvider<Event>('blur');

  @DomName('SVGElement.canplayEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> canPlayEvent =
      const EventStreamProvider<Event>('canplay');

  @DomName('SVGElement.canplaythroughEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> canPlayThroughEvent =
      const EventStreamProvider<Event>('canplaythrough');

  @DomName('SVGElement.changeEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> changeEvent =
      const EventStreamProvider<Event>('change');

  @DomName('SVGElement.clickEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> clickEvent =
      const EventStreamProvider<MouseEvent>('click');

  @DomName('SVGElement.contextmenuEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> contextMenuEvent =
      const EventStreamProvider<MouseEvent>('contextmenu');

  @DomName('SVGElement.dblclickEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> doubleClickEvent =
      const EventStreamProvider<Event>('dblclick');

  @DomName('SVGElement.dragEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> dragEvent =
      const EventStreamProvider<MouseEvent>('drag');

  @DomName('SVGElement.dragendEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> dragEndEvent =
      const EventStreamProvider<MouseEvent>('dragend');

  @DomName('SVGElement.dragenterEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> dragEnterEvent =
      const EventStreamProvider<MouseEvent>('dragenter');

  @DomName('SVGElement.dragleaveEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> dragLeaveEvent =
      const EventStreamProvider<MouseEvent>('dragleave');

  @DomName('SVGElement.dragoverEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> dragOverEvent =
      const EventStreamProvider<MouseEvent>('dragover');

  @DomName('SVGElement.dragstartEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> dragStartEvent =
      const EventStreamProvider<MouseEvent>('dragstart');

  @DomName('SVGElement.dropEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> dropEvent =
      const EventStreamProvider<MouseEvent>('drop');

  @DomName('SVGElement.durationchangeEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> durationChangeEvent =
      const EventStreamProvider<Event>('durationchange');

  @DomName('SVGElement.emptiedEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> emptiedEvent =
      const EventStreamProvider<Event>('emptied');

  @DomName('SVGElement.endedEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> endedEvent =
      const EventStreamProvider<Event>('ended');

  @DomName('SVGElement.errorEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> errorEvent =
      const EventStreamProvider<Event>('error');

  @DomName('SVGElement.focusEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> focusEvent =
      const EventStreamProvider<Event>('focus');

  @DomName('SVGElement.inputEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> inputEvent =
      const EventStreamProvider<Event>('input');

  @DomName('SVGElement.invalidEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> invalidEvent =
      const EventStreamProvider<Event>('invalid');

  @DomName('SVGElement.keydownEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<KeyboardEvent> keyDownEvent =
      const EventStreamProvider<KeyboardEvent>('keydown');

  @DomName('SVGElement.keypressEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<KeyboardEvent> keyPressEvent =
      const EventStreamProvider<KeyboardEvent>('keypress');

  @DomName('SVGElement.keyupEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<KeyboardEvent> keyUpEvent =
      const EventStreamProvider<KeyboardEvent>('keyup');

  @DomName('SVGElement.loadEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> loadEvent =
      const EventStreamProvider<Event>('load');

  @DomName('SVGElement.loadeddataEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> loadedDataEvent =
      const EventStreamProvider<Event>('loadeddata');

  @DomName('SVGElement.loadedmetadataEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> loadedMetadataEvent =
      const EventStreamProvider<Event>('loadedmetadata');

  @DomName('SVGElement.mousedownEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> mouseDownEvent =
      const EventStreamProvider<MouseEvent>('mousedown');

  @DomName('SVGElement.mouseenterEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> mouseEnterEvent =
      const EventStreamProvider<MouseEvent>('mouseenter');

  @DomName('SVGElement.mouseleaveEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> mouseLeaveEvent =
      const EventStreamProvider<MouseEvent>('mouseleave');

  @DomName('SVGElement.mousemoveEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> mouseMoveEvent =
      const EventStreamProvider<MouseEvent>('mousemove');

  @DomName('SVGElement.mouseoutEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> mouseOutEvent =
      const EventStreamProvider<MouseEvent>('mouseout');

  @DomName('SVGElement.mouseoverEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> mouseOverEvent =
      const EventStreamProvider<MouseEvent>('mouseover');

  @DomName('SVGElement.mouseupEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> mouseUpEvent =
      const EventStreamProvider<MouseEvent>('mouseup');

  @DomName('SVGElement.mousewheelEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<WheelEvent> mouseWheelEvent =
      const EventStreamProvider<WheelEvent>('mousewheel');

  @DomName('SVGElement.pauseEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> pauseEvent =
      const EventStreamProvider<Event>('pause');

  @DomName('SVGElement.playEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> playEvent =
      const EventStreamProvider<Event>('play');

  @DomName('SVGElement.playingEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> playingEvent =
      const EventStreamProvider<Event>('playing');

  @DomName('SVGElement.ratechangeEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> rateChangeEvent =
      const EventStreamProvider<Event>('ratechange');

  @DomName('SVGElement.resetEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> resetEvent =
      const EventStreamProvider<Event>('reset');

  @DomName('SVGElement.resizeEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> resizeEvent =
      const EventStreamProvider<Event>('resize');

  @DomName('SVGElement.scrollEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> scrollEvent =
      const EventStreamProvider<Event>('scroll');

  @DomName('SVGElement.seekedEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> seekedEvent =
      const EventStreamProvider<Event>('seeked');

  @DomName('SVGElement.seekingEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> seekingEvent =
      const EventStreamProvider<Event>('seeking');

  @DomName('SVGElement.selectEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> selectEvent =
      const EventStreamProvider<Event>('select');

  @DomName('SVGElement.stalledEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> stalledEvent =
      const EventStreamProvider<Event>('stalled');

  @DomName('SVGElement.submitEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> submitEvent =
      const EventStreamProvider<Event>('submit');

  @DomName('SVGElement.suspendEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> suspendEvent =
      const EventStreamProvider<Event>('suspend');

  @DomName('SVGElement.timeupdateEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> timeUpdateEvent =
      const EventStreamProvider<Event>('timeupdate');

  @DomName('SVGElement.volumechangeEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> volumeChangeEvent =
      const EventStreamProvider<Event>('volumechange');

  @DomName('SVGElement.waitingEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<Event> waitingEvent =
      const EventStreamProvider<Event>('waiting');

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  SvgElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  SvgElement.created() : super.created();

  @DomName('SVGElement.className')
  @DocsEditable()
  @Experimental() // untriaged
  AnimatedString get _svgClassName =>
      _blink.BlinkSVGElement.instance.className_Getter_(this);

  @DomName('SVGElement.ownerSVGElement')
  @DocsEditable()
  SvgSvgElement get ownerSvgElement =>
      _blink.BlinkSVGElement.instance.ownerSVGElement_Getter_(this);

  @DomName('SVGElement.style')
  @DocsEditable()
  @Experimental() // untriaged
  CssStyleDeclaration get style =>
      _blink.BlinkSVGElement.instance.style_Getter_(this);

  @DomName('SVGElement.tabIndex')
  @DocsEditable()
  @Experimental() // untriaged
  int get tabIndex => _blink.BlinkSVGElement.instance.tabIndex_Getter_(this);

  @DomName('SVGElement.tabIndex')
  @DocsEditable()
  @Experimental() // untriaged
  set tabIndex(int value) =>
      _blink.BlinkSVGElement.instance.tabIndex_Setter_(this, value);

  @DomName('SVGElement.viewportElement')
  @DocsEditable()
  SvgElement get viewportElement =>
      _blink.BlinkSVGElement.instance.viewportElement_Getter_(this);

  @DomName('SVGElement.blur')
  @DocsEditable()
  @Experimental() // untriaged
  void blur() => _blink.BlinkSVGElement.instance.blur_Callback_0_(this);

  @DomName('SVGElement.focus')
  @DocsEditable()
  @Experimental() // untriaged
  void focus() => _blink.BlinkSVGElement.instance.focus_Callback_0_(this);

  @DomName('SVGElement.onabort')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onAbort => abortEvent.forElement(this);

  @DomName('SVGElement.onblur')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onBlur => blurEvent.forElement(this);

  @DomName('SVGElement.oncanplay')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onCanPlay => canPlayEvent.forElement(this);

  @DomName('SVGElement.oncanplaythrough')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onCanPlayThrough =>
      canPlayThroughEvent.forElement(this);

  @DomName('SVGElement.onchange')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onChange => changeEvent.forElement(this);

  @DomName('SVGElement.onclick')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onClick => clickEvent.forElement(this);

  @DomName('SVGElement.oncontextmenu')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onContextMenu =>
      contextMenuEvent.forElement(this);

  @DomName('SVGElement.ondblclick')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onDoubleClick => doubleClickEvent.forElement(this);

  @DomName('SVGElement.ondrag')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onDrag => dragEvent.forElement(this);

  @DomName('SVGElement.ondragend')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onDragEnd => dragEndEvent.forElement(this);

  @DomName('SVGElement.ondragenter')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onDragEnter => dragEnterEvent.forElement(this);

  @DomName('SVGElement.ondragleave')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onDragLeave => dragLeaveEvent.forElement(this);

  @DomName('SVGElement.ondragover')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onDragOver => dragOverEvent.forElement(this);

  @DomName('SVGElement.ondragstart')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onDragStart => dragStartEvent.forElement(this);

  @DomName('SVGElement.ondrop')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onDrop => dropEvent.forElement(this);

  @DomName('SVGElement.ondurationchange')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onDurationChange =>
      durationChangeEvent.forElement(this);

  @DomName('SVGElement.onemptied')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onEmptied => emptiedEvent.forElement(this);

  @DomName('SVGElement.onended')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onEnded => endedEvent.forElement(this);

  @DomName('SVGElement.onerror')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onError => errorEvent.forElement(this);

  @DomName('SVGElement.onfocus')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onFocus => focusEvent.forElement(this);

  @DomName('SVGElement.oninput')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onInput => inputEvent.forElement(this);

  @DomName('SVGElement.oninvalid')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onInvalid => invalidEvent.forElement(this);

  @DomName('SVGElement.onkeydown')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<KeyboardEvent> get onKeyDown => keyDownEvent.forElement(this);

  @DomName('SVGElement.onkeypress')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<KeyboardEvent> get onKeyPress => keyPressEvent.forElement(this);

  @DomName('SVGElement.onkeyup')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<KeyboardEvent> get onKeyUp => keyUpEvent.forElement(this);

  @DomName('SVGElement.onload')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onLoad => loadEvent.forElement(this);

  @DomName('SVGElement.onloadeddata')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onLoadedData => loadedDataEvent.forElement(this);

  @DomName('SVGElement.onloadedmetadata')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onLoadedMetadata =>
      loadedMetadataEvent.forElement(this);

  @DomName('SVGElement.onmousedown')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onMouseDown => mouseDownEvent.forElement(this);

  @DomName('SVGElement.onmouseenter')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onMouseEnter =>
      mouseEnterEvent.forElement(this);

  @DomName('SVGElement.onmouseleave')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onMouseLeave =>
      mouseLeaveEvent.forElement(this);

  @DomName('SVGElement.onmousemove')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onMouseMove => mouseMoveEvent.forElement(this);

  @DomName('SVGElement.onmouseout')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onMouseOut => mouseOutEvent.forElement(this);

  @DomName('SVGElement.onmouseover')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onMouseOver => mouseOverEvent.forElement(this);

  @DomName('SVGElement.onmouseup')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<MouseEvent> get onMouseUp => mouseUpEvent.forElement(this);

  @DomName('SVGElement.onmousewheel')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<WheelEvent> get onMouseWheel =>
      mouseWheelEvent.forElement(this);

  @DomName('SVGElement.onpause')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onPause => pauseEvent.forElement(this);

  @DomName('SVGElement.onplay')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onPlay => playEvent.forElement(this);

  @DomName('SVGElement.onplaying')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onPlaying => playingEvent.forElement(this);

  @DomName('SVGElement.onratechange')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onRateChange => rateChangeEvent.forElement(this);

  @DomName('SVGElement.onreset')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onReset => resetEvent.forElement(this);

  @DomName('SVGElement.onresize')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onResize => resizeEvent.forElement(this);

  @DomName('SVGElement.onscroll')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onScroll => scrollEvent.forElement(this);

  @DomName('SVGElement.onseeked')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onSeeked => seekedEvent.forElement(this);

  @DomName('SVGElement.onseeking')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onSeeking => seekingEvent.forElement(this);

  @DomName('SVGElement.onselect')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onSelect => selectEvent.forElement(this);

  @DomName('SVGElement.onstalled')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onStalled => stalledEvent.forElement(this);

  @DomName('SVGElement.onsubmit')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onSubmit => submitEvent.forElement(this);

  @DomName('SVGElement.onsuspend')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onSuspend => suspendEvent.forElement(this);

  @DomName('SVGElement.ontimeupdate')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onTimeUpdate => timeUpdateEvent.forElement(this);

  @DomName('SVGElement.onvolumechange')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onVolumeChange => volumeChangeEvent.forElement(this);

  @DomName('SVGElement.onwaiting')
  @DocsEditable()
  @Experimental() // untriaged
  ElementStream<Event> get onWaiting => waitingEvent.forElement(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DomName('SVGSVGElement')
@Unstable()
class SvgSvgElement extends GraphicsElement
    implements FitToViewBox, ZoomAndPan {
  factory SvgSvgElement() {
    final el = new SvgElement.tag("svg");
    // The SVG spec requires the version attribute to match the spec version
    el.attributes['version'] = "1.1";
    return el;
  }

  // To suppress missing implicit constructor warnings.
  factory SvgSvgElement._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  SvgSvgElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  SvgSvgElement.created() : super.created();

  @DomName('SVGSVGElement.currentScale')
  @DocsEditable()
  num get currentScale =>
      _blink.BlinkSVGSVGElement.instance.currentScale_Getter_(this);

  @DomName('SVGSVGElement.currentScale')
  @DocsEditable()
  set currentScale(num value) =>
      _blink.BlinkSVGSVGElement.instance.currentScale_Setter_(this, value);

  @DomName('SVGSVGElement.currentTranslate')
  @DocsEditable()
  Point get currentTranslate =>
      _blink.BlinkSVGSVGElement.instance.currentTranslate_Getter_(this);

  @DomName('SVGSVGElement.currentView')
  @DocsEditable()
  ViewSpec get currentView =>
      _blink.BlinkSVGSVGElement.instance.currentView_Getter_(this);

  @DomName('SVGSVGElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGSVGElement.instance.height_Getter_(this);

  @DomName('SVGSVGElement.pixelUnitToMillimeterX')
  @DocsEditable()
  num get pixelUnitToMillimeterX =>
      _blink.BlinkSVGSVGElement.instance.pixelUnitToMillimeterX_Getter_(this);

  @DomName('SVGSVGElement.pixelUnitToMillimeterY')
  @DocsEditable()
  num get pixelUnitToMillimeterY =>
      _blink.BlinkSVGSVGElement.instance.pixelUnitToMillimeterY_Getter_(this);

  @DomName('SVGSVGElement.screenPixelToMillimeterX')
  @DocsEditable()
  num get screenPixelToMillimeterX =>
      _blink.BlinkSVGSVGElement.instance.screenPixelToMillimeterX_Getter_(this);

  @DomName('SVGSVGElement.screenPixelToMillimeterY')
  @DocsEditable()
  num get screenPixelToMillimeterY =>
      _blink.BlinkSVGSVGElement.instance.screenPixelToMillimeterY_Getter_(this);

  @DomName('SVGSVGElement.useCurrentView')
  @DocsEditable()
  bool get useCurrentView =>
      _blink.BlinkSVGSVGElement.instance.useCurrentView_Getter_(this);

  @DomName('SVGSVGElement.viewport')
  @DocsEditable()
  Rect get viewport =>
      _blink.BlinkSVGSVGElement.instance.viewport_Getter_(this);

  @DomName('SVGSVGElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGSVGElement.instance.width_Getter_(this);

  @DomName('SVGSVGElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGSVGElement.instance.x_Getter_(this);

  @DomName('SVGSVGElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGSVGElement.instance.y_Getter_(this);

  @DomName('SVGSVGElement.animationsPaused')
  @DocsEditable()
  bool animationsPaused() =>
      _blink.BlinkSVGSVGElement.instance.animationsPaused_Callback_0_(this);

  @DomName('SVGSVGElement.checkEnclosure')
  @DocsEditable()
  bool checkEnclosure(SvgElement element, Rect rect) =>
      _blink.BlinkSVGSVGElement.instance
          .checkEnclosure_Callback_2_(this, element, rect);

  @DomName('SVGSVGElement.checkIntersection')
  @DocsEditable()
  bool checkIntersection(SvgElement element, Rect rect) =>
      _blink.BlinkSVGSVGElement.instance
          .checkIntersection_Callback_2_(this, element, rect);

  @DomName('SVGSVGElement.createSVGAngle')
  @DocsEditable()
  Angle createSvgAngle() =>
      _blink.BlinkSVGSVGElement.instance.createSVGAngle_Callback_0_(this);

  @DomName('SVGSVGElement.createSVGLength')
  @DocsEditable()
  Length createSvgLength() =>
      _blink.BlinkSVGSVGElement.instance.createSVGLength_Callback_0_(this);

  @DomName('SVGSVGElement.createSVGMatrix')
  @DocsEditable()
  Matrix createSvgMatrix() =>
      _blink.BlinkSVGSVGElement.instance.createSVGMatrix_Callback_0_(this);

  @DomName('SVGSVGElement.createSVGNumber')
  @DocsEditable()
  Number createSvgNumber() =>
      _blink.BlinkSVGSVGElement.instance.createSVGNumber_Callback_0_(this);

  @DomName('SVGSVGElement.createSVGPoint')
  @DocsEditable()
  Point createSvgPoint() =>
      _blink.BlinkSVGSVGElement.instance.createSVGPoint_Callback_0_(this);

  @DomName('SVGSVGElement.createSVGRect')
  @DocsEditable()
  Rect createSvgRect() =>
      _blink.BlinkSVGSVGElement.instance.createSVGRect_Callback_0_(this);

  @DomName('SVGSVGElement.createSVGTransform')
  @DocsEditable()
  Transform createSvgTransform() =>
      _blink.BlinkSVGSVGElement.instance.createSVGTransform_Callback_0_(this);

  @DomName('SVGSVGElement.createSVGTransformFromMatrix')
  @DocsEditable()
  Transform createSvgTransformFromMatrix(Matrix matrix) =>
      _blink.BlinkSVGSVGElement.instance
          .createSVGTransformFromMatrix_Callback_1_(this, matrix);

  @DomName('SVGSVGElement.deselectAll')
  @DocsEditable()
  void deselectAll() =>
      _blink.BlinkSVGSVGElement.instance.deselectAll_Callback_0_(this);

  @DomName('SVGSVGElement.forceRedraw')
  @DocsEditable()
  void forceRedraw() =>
      _blink.BlinkSVGSVGElement.instance.forceRedraw_Callback_0_(this);

  @DomName('SVGSVGElement.getCurrentTime')
  @DocsEditable()
  num getCurrentTime() =>
      _blink.BlinkSVGSVGElement.instance.getCurrentTime_Callback_0_(this);

  @DomName('SVGSVGElement.getElementById')
  @DocsEditable()
  Element getElementById(String elementId) => _blink.BlinkSVGSVGElement.instance
      .getElementById_Callback_1_(this, elementId);

  @DomName('SVGSVGElement.getEnclosureList')
  @DocsEditable()
  List<Node> getEnclosureList(Rect rect, SvgElement referenceElement) =>
      (_blink.BlinkSVGSVGElement.instance
          .getEnclosureList_Callback_2_(this, rect, referenceElement));

  @DomName('SVGSVGElement.getIntersectionList')
  @DocsEditable()
  List<Node> getIntersectionList(Rect rect, SvgElement referenceElement) =>
      (_blink.BlinkSVGSVGElement.instance
          .getIntersectionList_Callback_2_(this, rect, referenceElement));

  @DomName('SVGSVGElement.pauseAnimations')
  @DocsEditable()
  void pauseAnimations() =>
      _blink.BlinkSVGSVGElement.instance.pauseAnimations_Callback_0_(this);

  @DomName('SVGSVGElement.setCurrentTime')
  @DocsEditable()
  void setCurrentTime(num seconds) => _blink.BlinkSVGSVGElement.instance
      .setCurrentTime_Callback_1_(this, seconds);

  @DomName('SVGSVGElement.suspendRedraw')
  @DocsEditable()
  int suspendRedraw(int maxWaitMilliseconds) =>
      _blink.BlinkSVGSVGElement.instance
          .suspendRedraw_Callback_1_(this, maxWaitMilliseconds);

  @DomName('SVGSVGElement.unpauseAnimations')
  @DocsEditable()
  void unpauseAnimations() =>
      _blink.BlinkSVGSVGElement.instance.unpauseAnimations_Callback_0_(this);

  @DomName('SVGSVGElement.unsuspendRedraw')
  @DocsEditable()
  void unsuspendRedraw(int suspendHandleId) =>
      _blink.BlinkSVGSVGElement.instance
          .unsuspendRedraw_Callback_1_(this, suspendHandleId);

  @DomName('SVGSVGElement.unsuspendRedrawAll')
  @DocsEditable()
  void unsuspendRedrawAll() =>
      _blink.BlinkSVGSVGElement.instance.unsuspendRedrawAll_Callback_0_(this);

  @DomName('SVGSVGElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio =>
      _blink.BlinkSVGSVGElement.instance.preserveAspectRatio_Getter_(this);

  @DomName('SVGSVGElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox =>
      _blink.BlinkSVGSVGElement.instance.viewBox_Getter_(this);

  @DomName('SVGSVGElement.zoomAndPan')
  @DocsEditable()
  int get zoomAndPan =>
      _blink.BlinkSVGSVGElement.instance.zoomAndPan_Getter_(this);

  @DomName('SVGSVGElement.zoomAndPan')
  @DocsEditable()
  set zoomAndPan(int value) =>
      _blink.BlinkSVGSVGElement.instance.zoomAndPan_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGSwitchElement')
@Unstable()
class SwitchElement extends GraphicsElement {
  // To suppress missing implicit constructor warnings.
  factory SwitchElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGSwitchElement.SVGSwitchElement')
  @DocsEditable()
  factory SwitchElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("switch");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  SwitchElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  SwitchElement.created() : super.created();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGSymbolElement')
@Unstable()
class SymbolElement extends SvgElement implements FitToViewBox {
  // To suppress missing implicit constructor warnings.
  factory SymbolElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGSymbolElement.SVGSymbolElement')
  @DocsEditable()
  factory SymbolElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("symbol");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  SymbolElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  SymbolElement.created() : super.created();

  @DomName('SVGSymbolElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio =>
      _blink.BlinkSVGSymbolElement.instance.preserveAspectRatio_Getter_(this);

  @DomName('SVGSymbolElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox =>
      _blink.BlinkSVGSymbolElement.instance.viewBox_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGTSpanElement')
@Unstable()
class TSpanElement extends TextPositioningElement {
  // To suppress missing implicit constructor warnings.
  factory TSpanElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGTSpanElement.SVGTSpanElement')
  @DocsEditable()
  factory TSpanElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("tspan");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  TSpanElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  TSpanElement.created() : super.created();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGTests')
@Unstable()
abstract class Tests extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory Tests._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGTests.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions;

  @DomName('SVGTests.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures;

  @DomName('SVGTests.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage;

  @DomName('SVGTests.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGTextContentElement')
@Unstable()
class TextContentElement extends GraphicsElement {
  // To suppress missing implicit constructor warnings.
  factory TextContentElement._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  TextContentElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  TextContentElement.created() : super.created();

  @DomName('SVGTextContentElement.LENGTHADJUST_SPACING')
  @DocsEditable()
  static const int LENGTHADJUST_SPACING = 1;

  @DomName('SVGTextContentElement.LENGTHADJUST_SPACINGANDGLYPHS')
  @DocsEditable()
  static const int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  @DomName('SVGTextContentElement.LENGTHADJUST_UNKNOWN')
  @DocsEditable()
  static const int LENGTHADJUST_UNKNOWN = 0;

  @DomName('SVGTextContentElement.lengthAdjust')
  @DocsEditable()
  AnimatedEnumeration get lengthAdjust =>
      _blink.BlinkSVGTextContentElement.instance.lengthAdjust_Getter_(this);

  @DomName('SVGTextContentElement.textLength')
  @DocsEditable()
  AnimatedLength get textLength =>
      _blink.BlinkSVGTextContentElement.instance.textLength_Getter_(this);

  @DomName('SVGTextContentElement.getCharNumAtPosition')
  @DocsEditable()
  int getCharNumAtPosition(Point point) =>
      _blink.BlinkSVGTextContentElement.instance
          .getCharNumAtPosition_Callback_1_(this, point);

  @DomName('SVGTextContentElement.getComputedTextLength')
  @DocsEditable()
  num getComputedTextLength() => _blink.BlinkSVGTextContentElement.instance
      .getComputedTextLength_Callback_0_(this);

  @DomName('SVGTextContentElement.getEndPositionOfChar')
  @DocsEditable()
  Point getEndPositionOfChar(int charnum) =>
      _blink.BlinkSVGTextContentElement.instance
          .getEndPositionOfChar_Callback_1_(this, charnum);

  @DomName('SVGTextContentElement.getExtentOfChar')
  @DocsEditable()
  Rect getExtentOfChar(int charnum) =>
      _blink.BlinkSVGTextContentElement.instance
          .getExtentOfChar_Callback_1_(this, charnum);

  @DomName('SVGTextContentElement.getNumberOfChars')
  @DocsEditable()
  int getNumberOfChars() => _blink.BlinkSVGTextContentElement.instance
      .getNumberOfChars_Callback_0_(this);

  @DomName('SVGTextContentElement.getRotationOfChar')
  @DocsEditable()
  num getRotationOfChar(int charnum) =>
      _blink.BlinkSVGTextContentElement.instance
          .getRotationOfChar_Callback_1_(this, charnum);

  @DomName('SVGTextContentElement.getStartPositionOfChar')
  @DocsEditable()
  Point getStartPositionOfChar(int charnum) =>
      _blink.BlinkSVGTextContentElement.instance
          .getStartPositionOfChar_Callback_1_(this, charnum);

  @DomName('SVGTextContentElement.getSubStringLength')
  @DocsEditable()
  num getSubStringLength(int charnum, int nchars) =>
      _blink.BlinkSVGTextContentElement.instance
          .getSubStringLength_Callback_2_(this, charnum, nchars);

  @DomName('SVGTextContentElement.selectSubString')
  @DocsEditable()
  void selectSubString(int charnum, int nchars) =>
      _blink.BlinkSVGTextContentElement.instance
          .selectSubString_Callback_2_(this, charnum, nchars);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGTextElement')
@Unstable()
class TextElement extends TextPositioningElement {
  // To suppress missing implicit constructor warnings.
  factory TextElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGTextElement.SVGTextElement')
  @DocsEditable()
  factory TextElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("text");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  TextElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  TextElement.created() : super.created();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGTextPathElement')
@Unstable()
class TextPathElement extends TextContentElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory TextPathElement._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  TextPathElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  TextPathElement.created() : super.created();

  @DomName('SVGTextPathElement.TEXTPATH_METHODTYPE_ALIGN')
  @DocsEditable()
  static const int TEXTPATH_METHODTYPE_ALIGN = 1;

  @DomName('SVGTextPathElement.TEXTPATH_METHODTYPE_STRETCH')
  @DocsEditable()
  static const int TEXTPATH_METHODTYPE_STRETCH = 2;

  @DomName('SVGTextPathElement.TEXTPATH_METHODTYPE_UNKNOWN')
  @DocsEditable()
  static const int TEXTPATH_METHODTYPE_UNKNOWN = 0;

  @DomName('SVGTextPathElement.TEXTPATH_SPACINGTYPE_AUTO')
  @DocsEditable()
  static const int TEXTPATH_SPACINGTYPE_AUTO = 1;

  @DomName('SVGTextPathElement.TEXTPATH_SPACINGTYPE_EXACT')
  @DocsEditable()
  static const int TEXTPATH_SPACINGTYPE_EXACT = 2;

  @DomName('SVGTextPathElement.TEXTPATH_SPACINGTYPE_UNKNOWN')
  @DocsEditable()
  static const int TEXTPATH_SPACINGTYPE_UNKNOWN = 0;

  @DomName('SVGTextPathElement.method')
  @DocsEditable()
  AnimatedEnumeration get method =>
      _blink.BlinkSVGTextPathElement.instance.method_Getter_(this);

  @DomName('SVGTextPathElement.spacing')
  @DocsEditable()
  AnimatedEnumeration get spacing =>
      _blink.BlinkSVGTextPathElement.instance.spacing_Getter_(this);

  @DomName('SVGTextPathElement.startOffset')
  @DocsEditable()
  AnimatedLength get startOffset =>
      _blink.BlinkSVGTextPathElement.instance.startOffset_Getter_(this);

  @DomName('SVGTextPathElement.href')
  @DocsEditable()
  AnimatedString get href =>
      _blink.BlinkSVGTextPathElement.instance.href_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGTextPositioningElement')
@Unstable()
class TextPositioningElement extends TextContentElement {
  // To suppress missing implicit constructor warnings.
  factory TextPositioningElement._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  TextPositioningElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  TextPositioningElement.created() : super.created();

  @DomName('SVGTextPositioningElement.dx')
  @DocsEditable()
  AnimatedLengthList get dx =>
      _blink.BlinkSVGTextPositioningElement.instance.dx_Getter_(this);

  @DomName('SVGTextPositioningElement.dy')
  @DocsEditable()
  AnimatedLengthList get dy =>
      _blink.BlinkSVGTextPositioningElement.instance.dy_Getter_(this);

  @DomName('SVGTextPositioningElement.rotate')
  @DocsEditable()
  AnimatedNumberList get rotate =>
      _blink.BlinkSVGTextPositioningElement.instance.rotate_Getter_(this);

  @DomName('SVGTextPositioningElement.x')
  @DocsEditable()
  AnimatedLengthList get x =>
      _blink.BlinkSVGTextPositioningElement.instance.x_Getter_(this);

  @DomName('SVGTextPositioningElement.y')
  @DocsEditable()
  AnimatedLengthList get y =>
      _blink.BlinkSVGTextPositioningElement.instance.y_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGTitleElement')
@Unstable()
class TitleElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory TitleElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGTitleElement.SVGTitleElement')
  @DocsEditable()
  factory TitleElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("title");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  TitleElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  TitleElement.created() : super.created();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGTransform')
@Unstable()
class Transform extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory Transform._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  Transform.internal_() {}

  @DomName('SVGTransform.SVG_TRANSFORM_MATRIX')
  @DocsEditable()
  static const int SVG_TRANSFORM_MATRIX = 1;

  @DomName('SVGTransform.SVG_TRANSFORM_ROTATE')
  @DocsEditable()
  static const int SVG_TRANSFORM_ROTATE = 4;

  @DomName('SVGTransform.SVG_TRANSFORM_SCALE')
  @DocsEditable()
  static const int SVG_TRANSFORM_SCALE = 3;

  @DomName('SVGTransform.SVG_TRANSFORM_SKEWX')
  @DocsEditable()
  static const int SVG_TRANSFORM_SKEWX = 5;

  @DomName('SVGTransform.SVG_TRANSFORM_SKEWY')
  @DocsEditable()
  static const int SVG_TRANSFORM_SKEWY = 6;

  @DomName('SVGTransform.SVG_TRANSFORM_TRANSLATE')
  @DocsEditable()
  static const int SVG_TRANSFORM_TRANSLATE = 2;

  @DomName('SVGTransform.SVG_TRANSFORM_UNKNOWN')
  @DocsEditable()
  static const int SVG_TRANSFORM_UNKNOWN = 0;

  @DomName('SVGTransform.angle')
  @DocsEditable()
  num get angle => _blink.BlinkSVGTransform.instance.angle_Getter_(this);

  @DomName('SVGTransform.matrix')
  @DocsEditable()
  Matrix get matrix => _blink.BlinkSVGTransform.instance.matrix_Getter_(this);

  @DomName('SVGTransform.type')
  @DocsEditable()
  int get type => _blink.BlinkSVGTransform.instance.type_Getter_(this);

  @DomName('SVGTransform.setMatrix')
  @DocsEditable()
  void setMatrix(Matrix matrix) =>
      _blink.BlinkSVGTransform.instance.setMatrix_Callback_1_(this, matrix);

  @DomName('SVGTransform.setRotate')
  @DocsEditable()
  void setRotate(num angle, num cx, num cy) => _blink.BlinkSVGTransform.instance
      .setRotate_Callback_3_(this, angle, cx, cy);

  @DomName('SVGTransform.setScale')
  @DocsEditable()
  void setScale(num sx, num sy) =>
      _blink.BlinkSVGTransform.instance.setScale_Callback_2_(this, sx, sy);

  @DomName('SVGTransform.setSkewX')
  @DocsEditable()
  void setSkewX(num angle) =>
      _blink.BlinkSVGTransform.instance.setSkewX_Callback_1_(this, angle);

  @DomName('SVGTransform.setSkewY')
  @DocsEditable()
  void setSkewY(num angle) =>
      _blink.BlinkSVGTransform.instance.setSkewY_Callback_1_(this, angle);

  @DomName('SVGTransform.setTranslate')
  @DocsEditable()
  void setTranslate(num tx, num ty) =>
      _blink.BlinkSVGTransform.instance.setTranslate_Callback_2_(this, tx, ty);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGTransformList')
@Unstable()
class TransformList extends DartHtmlDomObject
    with ListMixin<Transform>, ImmutableListMixin<Transform>
    implements List<Transform> {
  // To suppress missing implicit constructor warnings.
  factory TransformList._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  TransformList.internal_() {}

  @DomName('SVGTransformList.length')
  @DocsEditable()
  @Experimental() // untriaged
  int get length => _blink.BlinkSVGTransformList.instance.length_Getter_(this);

  @DomName('SVGTransformList.numberOfItems')
  @DocsEditable()
  int get numberOfItems =>
      _blink.BlinkSVGTransformList.instance.numberOfItems_Getter_(this);

  Transform operator [](int index) {
    if (index < 0 || index >= length) throw new RangeError.index(index, this);
    return getItem(index);
  }

  void operator []=(int index, Transform value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Transform> mixins.
  // Transform is the element type.

  set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  Transform get first {
    if (this.length > 0) {
      return getItem(0);
    }
    throw new StateError("No elements");
  }

  Transform get last {
    int len = this.length;
    if (len > 0) {
      return getItem(len - 1);
    }
    throw new StateError("No elements");
  }

  Transform get single {
    int len = this.length;
    if (len == 1) {
      return getItem(0);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Transform elementAt(int index) => this[index];
  // -- end List<Transform> mixins.

  @DomName('SVGTransformList.__setter__')
  @DocsEditable()
  @Experimental() // untriaged
  void __setter__(int index, Transform newItem) =>
      _blink.BlinkSVGTransformList.instance
          .$__setter___Callback_2_(this, index, newItem);

  @DomName('SVGTransformList.appendItem')
  @DocsEditable()
  Transform appendItem(Transform newItem) =>
      _blink.BlinkSVGTransformList.instance
          .appendItem_Callback_1_(this, newItem);

  @DomName('SVGTransformList.clear')
  @DocsEditable()
  void clear() => _blink.BlinkSVGTransformList.instance.clear_Callback_0_(this);

  @DomName('SVGTransformList.consolidate')
  @DocsEditable()
  Transform consolidate() =>
      _blink.BlinkSVGTransformList.instance.consolidate_Callback_0_(this);

  @DomName('SVGTransformList.createSVGTransformFromMatrix')
  @DocsEditable()
  Transform createSvgTransformFromMatrix(Matrix matrix) =>
      _blink.BlinkSVGTransformList.instance
          .createSVGTransformFromMatrix_Callback_1_(this, matrix);

  @DomName('SVGTransformList.getItem')
  @DocsEditable()
  Transform getItem(int index) =>
      _blink.BlinkSVGTransformList.instance.getItem_Callback_1_(this, index);

  @DomName('SVGTransformList.initialize')
  @DocsEditable()
  Transform initialize(Transform newItem) =>
      _blink.BlinkSVGTransformList.instance
          .initialize_Callback_1_(this, newItem);

  @DomName('SVGTransformList.insertItemBefore')
  @DocsEditable()
  Transform insertItemBefore(Transform newItem, int index) =>
      _blink.BlinkSVGTransformList.instance
          .insertItemBefore_Callback_2_(this, newItem, index);

  @DomName('SVGTransformList.removeItem')
  @DocsEditable()
  Transform removeItem(int index) =>
      _blink.BlinkSVGTransformList.instance.removeItem_Callback_1_(this, index);

  @DomName('SVGTransformList.replaceItem')
  @DocsEditable()
  Transform replaceItem(Transform newItem, int index) =>
      _blink.BlinkSVGTransformList.instance
          .replaceItem_Callback_2_(this, newItem, index);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGUnitTypes')
@Unstable()
class UnitTypes extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory UnitTypes._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  UnitTypes.internal_() {}

  @DomName('SVGUnitTypes.SVG_UNIT_TYPE_OBJECTBOUNDINGBOX')
  @DocsEditable()
  static const int SVG_UNIT_TYPE_OBJECTBOUNDINGBOX = 2;

  @DomName('SVGUnitTypes.SVG_UNIT_TYPE_UNKNOWN')
  @DocsEditable()
  static const int SVG_UNIT_TYPE_UNKNOWN = 0;

  @DomName('SVGUnitTypes.SVG_UNIT_TYPE_USERSPACEONUSE')
  @DocsEditable()
  static const int SVG_UNIT_TYPE_USERSPACEONUSE = 1;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGURIReference')
@Unstable()
abstract class UriReference extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory UriReference._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGURIReference.href')
  @DocsEditable()
  AnimatedString get href;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGUseElement')
@Unstable()
class UseElement extends GraphicsElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory UseElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGUseElement.SVGUseElement')
  @DocsEditable()
  factory UseElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("use");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  UseElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  UseElement.created() : super.created();

  @DomName('SVGUseElement.height')
  @DocsEditable()
  AnimatedLength get height =>
      _blink.BlinkSVGUseElement.instance.height_Getter_(this);

  @DomName('SVGUseElement.width')
  @DocsEditable()
  AnimatedLength get width =>
      _blink.BlinkSVGUseElement.instance.width_Getter_(this);

  @DomName('SVGUseElement.x')
  @DocsEditable()
  AnimatedLength get x => _blink.BlinkSVGUseElement.instance.x_Getter_(this);

  @DomName('SVGUseElement.y')
  @DocsEditable()
  AnimatedLength get y => _blink.BlinkSVGUseElement.instance.y_Getter_(this);

  @DomName('SVGUseElement.href')
  @DocsEditable()
  AnimatedString get href =>
      _blink.BlinkSVGUseElement.instance.href_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGViewElement')
@Unstable()
class ViewElement extends SvgElement implements FitToViewBox, ZoomAndPan {
  // To suppress missing implicit constructor warnings.
  factory ViewElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGViewElement.SVGViewElement')
  @DocsEditable()
  factory ViewElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("view");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  ViewElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  ViewElement.created() : super.created();

  @DomName('SVGViewElement.viewTarget')
  @DocsEditable()
  StringList get viewTarget =>
      _blink.BlinkSVGViewElement.instance.viewTarget_Getter_(this);

  @DomName('SVGViewElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio =>
      _blink.BlinkSVGViewElement.instance.preserveAspectRatio_Getter_(this);

  @DomName('SVGViewElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox =>
      _blink.BlinkSVGViewElement.instance.viewBox_Getter_(this);

  @DomName('SVGViewElement.zoomAndPan')
  @DocsEditable()
  int get zoomAndPan =>
      _blink.BlinkSVGViewElement.instance.zoomAndPan_Getter_(this);

  @DomName('SVGViewElement.zoomAndPan')
  @DocsEditable()
  set zoomAndPan(int value) =>
      _blink.BlinkSVGViewElement.instance.zoomAndPan_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGViewSpec')
@Unstable()
class ViewSpec extends DartHtmlDomObject implements FitToViewBox, ZoomAndPan {
  // To suppress missing implicit constructor warnings.
  factory ViewSpec._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  ViewSpec.internal_() {}

  @DomName('SVGViewSpec.preserveAspectRatioString')
  @DocsEditable()
  String get preserveAspectRatioString =>
      _blink.BlinkSVGViewSpec.instance.preserveAspectRatioString_Getter_(this);

  @DomName('SVGViewSpec.transform')
  @DocsEditable()
  TransformList get transform =>
      _blink.BlinkSVGViewSpec.instance.transform_Getter_(this);

  @DomName('SVGViewSpec.transformString')
  @DocsEditable()
  String get transformString =>
      _blink.BlinkSVGViewSpec.instance.transformString_Getter_(this);

  @DomName('SVGViewSpec.viewBoxString')
  @DocsEditable()
  String get viewBoxString =>
      _blink.BlinkSVGViewSpec.instance.viewBoxString_Getter_(this);

  @DomName('SVGViewSpec.viewTarget')
  @DocsEditable()
  SvgElement get viewTarget =>
      _blink.BlinkSVGViewSpec.instance.viewTarget_Getter_(this);

  @DomName('SVGViewSpec.viewTargetString')
  @DocsEditable()
  String get viewTargetString =>
      _blink.BlinkSVGViewSpec.instance.viewTargetString_Getter_(this);

  @DomName('SVGViewSpec.preserveAspectRatio')
  @DocsEditable()
  @Experimental() // nonstandard
  AnimatedPreserveAspectRatio get preserveAspectRatio =>
      _blink.BlinkSVGViewSpec.instance.preserveAspectRatio_Getter_(this);

  @DomName('SVGViewSpec.viewBox')
  @DocsEditable()
  @Experimental() // nonstandard
  AnimatedRect get viewBox =>
      _blink.BlinkSVGViewSpec.instance.viewBox_Getter_(this);

  @DomName('SVGViewSpec.zoomAndPan')
  @DocsEditable()
  @Experimental() // nonstandard
  int get zoomAndPan =>
      _blink.BlinkSVGViewSpec.instance.zoomAndPan_Getter_(this);

  @DomName('SVGViewSpec.zoomAndPan')
  @DocsEditable()
  @Experimental() // nonstandard
  set zoomAndPan(int value) =>
      _blink.BlinkSVGViewSpec.instance.zoomAndPan_Setter_(this, value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGZoomAndPan')
@Unstable()
abstract class ZoomAndPan extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory ZoomAndPan._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGZoomAndPan.SVG_ZOOMANDPAN_DISABLE')
  @DocsEditable()
  static const int SVG_ZOOMANDPAN_DISABLE = 1;

  @DomName('SVGZoomAndPan.SVG_ZOOMANDPAN_MAGNIFY')
  @DocsEditable()
  static const int SVG_ZOOMANDPAN_MAGNIFY = 2;

  @DomName('SVGZoomAndPan.SVG_ZOOMANDPAN_UNKNOWN')
  @DocsEditable()
  static const int SVG_ZOOMANDPAN_UNKNOWN = 0;

  @DomName('SVGZoomAndPan.zoomAndPan')
  @DocsEditable()
  int get zoomAndPan;

  @DomName('SVGZoomAndPan.zoomAndPan')
  @DocsEditable()
  set zoomAndPan(int value);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGZoomEvent')
@Unstable()
class ZoomEvent extends UIEvent {
  // To suppress missing implicit constructor warnings.
  factory ZoomEvent._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  ZoomEvent.internal_() : super.internal_();

  @DomName('SVGZoomEvent.newScale')
  @DocsEditable()
  num get newScale => _blink.BlinkSVGZoomEvent.instance.newScale_Getter_(this);

  @DomName('SVGZoomEvent.newTranslate')
  @DocsEditable()
  Point get newTranslate =>
      _blink.BlinkSVGZoomEvent.instance.newTranslate_Getter_(this);

  @DomName('SVGZoomEvent.previousScale')
  @DocsEditable()
  num get previousScale =>
      _blink.BlinkSVGZoomEvent.instance.previousScale_Getter_(this);

  @DomName('SVGZoomEvent.previousTranslate')
  @DocsEditable()
  Point get previousTranslate =>
      _blink.BlinkSVGZoomEvent.instance.previousTranslate_Getter_(this);

  @DomName('SVGZoomEvent.zoomRectScreen')
  @DocsEditable()
  Rect get zoomRectScreen =>
      _blink.BlinkSVGZoomEvent.instance.zoomRectScreen_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGGradientElement')
@Unstable()
class _GradientElement extends SvgElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory _GradientElement._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  _GradientElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _GradientElement.created() : super.created();

  @DomName('SVGGradientElement.SVG_SPREADMETHOD_PAD')
  @DocsEditable()
  static const int SVG_SPREADMETHOD_PAD = 1;

  @DomName('SVGGradientElement.SVG_SPREADMETHOD_REFLECT')
  @DocsEditable()
  static const int SVG_SPREADMETHOD_REFLECT = 2;

  @DomName('SVGGradientElement.SVG_SPREADMETHOD_REPEAT')
  @DocsEditable()
  static const int SVG_SPREADMETHOD_REPEAT = 3;

  @DomName('SVGGradientElement.SVG_SPREADMETHOD_UNKNOWN')
  @DocsEditable()
  static const int SVG_SPREADMETHOD_UNKNOWN = 0;

  @DomName('SVGGradientElement.gradientTransform')
  @DocsEditable()
  AnimatedTransformList get gradientTransform =>
      _blink.BlinkSVGGradientElement.instance.gradientTransform_Getter_(this);

  @DomName('SVGGradientElement.gradientUnits')
  @DocsEditable()
  AnimatedEnumeration get gradientUnits =>
      _blink.BlinkSVGGradientElement.instance.gradientUnits_Getter_(this);

  @DomName('SVGGradientElement.spreadMethod')
  @DocsEditable()
  AnimatedEnumeration get spreadMethod =>
      _blink.BlinkSVGGradientElement.instance.spreadMethod_Getter_(this);

  @DomName('SVGGradientElement.href')
  @DocsEditable()
  AnimatedString get href =>
      _blink.BlinkSVGGradientElement.instance.href_Getter_(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

@DocsEditable()
@DomName('SVGComponentTransferFunctionElement')
@Unstable()
class _SVGComponentTransferFunctionElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGComponentTransferFunctionElement._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  _SVGComponentTransferFunctionElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGComponentTransferFunctionElement.created() : super.created();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('SVGCursorElement')
@Unstable()
class _SVGCursorElement extends SvgElement implements UriReference, Tests {
  // To suppress missing implicit constructor warnings.
  factory _SVGCursorElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGCursorElement.SVGCursorElement')
  @DocsEditable()
  factory _SVGCursorElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("cursor");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  _SVGCursorElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGCursorElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  // Override these methods for Dartium _SVGCursorElement can't be abstract.
  StringList get requiredExtensions =>
      _blink.BlinkSVGCursorElement.instance.requiredExtensions_Getter_(this);
  StringList get requiredFeatures =>
      _blink.BlinkSVGCursorElement.instance.requiredFeatures_Getter_(this);
  StringList get systemLanguage =>
      _blink.BlinkSVGCursorElement.instance.systemLanguage_Getter_(this);
  AnimatedString get href =>
      _blink.BlinkSVGCursorElement.instance.href_Getter_(this);
  bool hasExtension(String extension) => _blink.BlinkSVGCursorElement.instance
      .hasExtension_Callback_1_(this, extension);
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('SVGFEDropShadowElement')
@Experimental() // nonstandard
class _SVGFEDropShadowElement extends SvgElement
    implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory _SVGFEDropShadowElement._() {
    throw new UnsupportedError("Not supported");
  }

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  _SVGFEDropShadowElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGFEDropShadowElement.created() : super.created();

  // Override these methods for Dartium _SVGFEDropShadowElement can't be abstract.
  AnimatedLength get height =>
      _blink.BlinkSVGFEDropShadowElement.instance.height_Getter_(this);
  AnimatedString get result =>
      _blink.BlinkSVGFEDropShadowElement.instance.result_Getter_(this);
  AnimatedLength get width =>
      _blink.BlinkSVGFEDropShadowElement.instance.width_Getter_(this);
  AnimatedLength get x =>
      _blink.BlinkSVGFEDropShadowElement.instance.x_Getter_(this);
  AnimatedLength get y =>
      _blink.BlinkSVGFEDropShadowElement.instance.y_Getter_(this);
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@DocsEditable()
@DomName('SVGMPathElement')
class _SVGMPathElement extends SvgElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory _SVGMPathElement._() {
    throw new UnsupportedError("Not supported");
  }

  @DomName('SVGMPathElement.SVGMPathElement')
  @DocsEditable()
  factory _SVGMPathElement() =>
      _SvgElementFactoryProvider.createSvgElement_tag("mpath");

  @Deprecated("Internal Use Only")
  external static Type get instanceRuntimeType;

  @Deprecated("Internal Use Only")
  _SVGMPathElement.internal_() : super.internal_();

  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGMPathElement.created() : super.created();

  // Override these methods for Dartium _SVGMPathElement can't be abstract.
  AnimatedString get href =>
      _blink.BlinkSVGMPathElement.instance.href_Getter_(this);
}
