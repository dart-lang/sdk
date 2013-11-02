library dart.dom.svg;

import 'dart:async';
import 'dart:collection';
import 'dart:_collection-dev' hide deprecated;
import 'dart:html';
import 'dart:html_common';
import 'dart:nativewrappers';
// DO NOT EDIT
// Auto-generated dart:svg library.





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
class AElement extends GraphicsElement implements UriReference, ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory AElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAElement.SVGAElement')
  @DocsEditable()
  factory AElement() => _SvgElementFactoryProvider.createSvgElement_tag("a");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  AElement.created() : super.created();

  @DomName('SVGAElement.target')
  @DocsEditable()
  AnimatedString get target native "SVGAElement_target_Getter";

  @DomName('SVGAElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGAElement_externalResourcesRequired_Getter";

  @DomName('SVGAElement.href')
  @DocsEditable()
  AnimatedString get href native "SVGAElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAltGlyphElement')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Unstable()
class AltGlyphElement extends TextPositioningElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory AltGlyphElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAltGlyphElement.SVGAltGlyphElement')
  @DocsEditable()
  factory AltGlyphElement() => _SvgElementFactoryProvider.createSvgElement_tag("altGlyph");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  AltGlyphElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGAltGlyphElement.format')
  @DocsEditable()
  String get format native "SVGAltGlyphElement_format_Getter";

  @DomName('SVGAltGlyphElement.format')
  @DocsEditable()
  void set format(String value) native "SVGAltGlyphElement_format_Setter";

  @DomName('SVGAltGlyphElement.glyphRef')
  @DocsEditable()
  String get glyphRef native "SVGAltGlyphElement_glyphRef_Getter";

  @DomName('SVGAltGlyphElement.glyphRef')
  @DocsEditable()
  void set glyphRef(String value) native "SVGAltGlyphElement_glyphRef_Setter";

  @DomName('SVGAltGlyphElement.href')
  @DocsEditable()
  AnimatedString get href native "SVGAltGlyphElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAngle')
@Unstable()
class Angle extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Angle._() { throw new UnsupportedError("Not supported"); }

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
  int get unitType native "SVGAngle_unitType_Getter";

  @DomName('SVGAngle.value')
  @DocsEditable()
  num get value native "SVGAngle_value_Getter";

  @DomName('SVGAngle.value')
  @DocsEditable()
  void set value(num value) native "SVGAngle_value_Setter";

  @DomName('SVGAngle.valueAsString')
  @DocsEditable()
  String get valueAsString native "SVGAngle_valueAsString_Getter";

  @DomName('SVGAngle.valueAsString')
  @DocsEditable()
  void set valueAsString(String value) native "SVGAngle_valueAsString_Setter";

  @DomName('SVGAngle.valueInSpecifiedUnits')
  @DocsEditable()
  num get valueInSpecifiedUnits native "SVGAngle_valueInSpecifiedUnits_Getter";

  @DomName('SVGAngle.valueInSpecifiedUnits')
  @DocsEditable()
  void set valueInSpecifiedUnits(num value) native "SVGAngle_valueInSpecifiedUnits_Setter";

  @DomName('SVGAngle.convertToSpecifiedUnits')
  @DocsEditable()
  void convertToSpecifiedUnits(int unitType) native "SVGAngle_convertToSpecifiedUnits_Callback";

  @DomName('SVGAngle.newValueSpecifiedUnits')
  @DocsEditable()
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native "SVGAngle_newValueSpecifiedUnits_Callback";

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
  factory AnimateElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimateElement.SVGAnimateElement')
  @DocsEditable()
  factory AnimateElement() => _SvgElementFactoryProvider.createSvgElement_tag("animate");
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
  factory AnimateMotionElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimateMotionElement.SVGAnimateMotionElement')
  @DocsEditable()
  factory AnimateMotionElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateMotion");
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
  factory AnimateTransformElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimateTransformElement.SVGAnimateTransformElement')
  @DocsEditable()
  factory AnimateTransformElement() => _SvgElementFactoryProvider.createSvgElement_tag("animateTransform");
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
class AnimatedAngle extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedAngle._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedAngle.animVal')
  @DocsEditable()
  Angle get animVal native "SVGAnimatedAngle_animVal_Getter";

  @DomName('SVGAnimatedAngle.baseVal')
  @DocsEditable()
  Angle get baseVal native "SVGAnimatedAngle_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedBoolean')
@Unstable()
class AnimatedBoolean extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedBoolean._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedBoolean.animVal')
  @DocsEditable()
  bool get animVal native "SVGAnimatedBoolean_animVal_Getter";

  @DomName('SVGAnimatedBoolean.baseVal')
  @DocsEditable()
  bool get baseVal native "SVGAnimatedBoolean_baseVal_Getter";

  @DomName('SVGAnimatedBoolean.baseVal')
  @DocsEditable()
  void set baseVal(bool value) native "SVGAnimatedBoolean_baseVal_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedEnumeration')
@Unstable()
class AnimatedEnumeration extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedEnumeration._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedEnumeration.animVal')
  @DocsEditable()
  int get animVal native "SVGAnimatedEnumeration_animVal_Getter";

  @DomName('SVGAnimatedEnumeration.baseVal')
  @DocsEditable()
  int get baseVal native "SVGAnimatedEnumeration_baseVal_Getter";

  @DomName('SVGAnimatedEnumeration.baseVal')
  @DocsEditable()
  void set baseVal(int value) native "SVGAnimatedEnumeration_baseVal_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedInteger')
@Unstable()
class AnimatedInteger extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedInteger._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedInteger.animVal')
  @DocsEditable()
  int get animVal native "SVGAnimatedInteger_animVal_Getter";

  @DomName('SVGAnimatedInteger.baseVal')
  @DocsEditable()
  int get baseVal native "SVGAnimatedInteger_baseVal_Getter";

  @DomName('SVGAnimatedInteger.baseVal')
  @DocsEditable()
  void set baseVal(int value) native "SVGAnimatedInteger_baseVal_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedLength')
@Unstable()
class AnimatedLength extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedLength._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedLength.animVal')
  @DocsEditable()
  Length get animVal native "SVGAnimatedLength_animVal_Getter";

  @DomName('SVGAnimatedLength.baseVal')
  @DocsEditable()
  Length get baseVal native "SVGAnimatedLength_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedLengthList')
@Unstable()
class AnimatedLengthList extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedLengthList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedLengthList.animVal')
  @DocsEditable()
  LengthList get animVal native "SVGAnimatedLengthList_animVal_Getter";

  @DomName('SVGAnimatedLengthList.baseVal')
  @DocsEditable()
  LengthList get baseVal native "SVGAnimatedLengthList_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedNumber')
@Unstable()
class AnimatedNumber extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedNumber._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedNumber.animVal')
  @DocsEditable()
  double get animVal native "SVGAnimatedNumber_animVal_Getter";

  @DomName('SVGAnimatedNumber.baseVal')
  @DocsEditable()
  num get baseVal native "SVGAnimatedNumber_baseVal_Getter";

  @DomName('SVGAnimatedNumber.baseVal')
  @DocsEditable()
  void set baseVal(num value) native "SVGAnimatedNumber_baseVal_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedNumberList')
@Unstable()
class AnimatedNumberList extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedNumberList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedNumberList.animVal')
  @DocsEditable()
  NumberList get animVal native "SVGAnimatedNumberList_animVal_Getter";

  @DomName('SVGAnimatedNumberList.baseVal')
  @DocsEditable()
  NumberList get baseVal native "SVGAnimatedNumberList_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedPreserveAspectRatio')
@Unstable()
class AnimatedPreserveAspectRatio extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedPreserveAspectRatio._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedPreserveAspectRatio.animVal')
  @DocsEditable()
  PreserveAspectRatio get animVal native "SVGAnimatedPreserveAspectRatio_animVal_Getter";

  @DomName('SVGAnimatedPreserveAspectRatio.baseVal')
  @DocsEditable()
  PreserveAspectRatio get baseVal native "SVGAnimatedPreserveAspectRatio_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedRect')
@Unstable()
class AnimatedRect extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedRect._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedRect.animVal')
  @DocsEditable()
  Rect get animVal native "SVGAnimatedRect_animVal_Getter";

  @DomName('SVGAnimatedRect.baseVal')
  @DocsEditable()
  Rect get baseVal native "SVGAnimatedRect_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedString')
@Unstable()
class AnimatedString extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedString._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedString.animVal')
  @DocsEditable()
  String get animVal native "SVGAnimatedString_animVal_Getter";

  @DomName('SVGAnimatedString.baseVal')
  @DocsEditable()
  String get baseVal native "SVGAnimatedString_baseVal_Getter";

  @DomName('SVGAnimatedString.baseVal')
  @DocsEditable()
  void set baseVal(String value) native "SVGAnimatedString_baseVal_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimatedTransformList')
@Unstable()
class AnimatedTransformList extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory AnimatedTransformList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimatedTransformList.animVal')
  @DocsEditable()
  TransformList get animVal native "SVGAnimatedTransformList_animVal_Getter";

  @DomName('SVGAnimatedTransformList.baseVal')
  @DocsEditable()
  TransformList get baseVal native "SVGAnimatedTransformList_baseVal_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimationElement')
@Unstable()
class AnimationElement extends SvgElement implements ExternalResourcesRequired, Tests {
  // To suppress missing implicit constructor warnings.
  factory AnimationElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGAnimationElement.SVGAnimationElement')
  @DocsEditable()
  factory AnimationElement() => _SvgElementFactoryProvider.createSvgElement_tag("animation");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  AnimationElement.created() : super.created();

  @DomName('SVGAnimationElement.targetElement')
  @DocsEditable()
  SvgElement get targetElement native "SVGAnimationElement_targetElement_Getter";

  @DomName('SVGAnimationElement.beginElement')
  @DocsEditable()
  void beginElement() native "SVGAnimationElement_beginElement_Callback";

  @DomName('SVGAnimationElement.beginElementAt')
  @DocsEditable()
  void beginElementAt(num offset) native "SVGAnimationElement_beginElementAt_Callback";

  @DomName('SVGAnimationElement.endElement')
  @DocsEditable()
  void endElement() native "SVGAnimationElement_endElement_Callback";

  @DomName('SVGAnimationElement.endElementAt')
  @DocsEditable()
  void endElementAt(num offset) native "SVGAnimationElement_endElementAt_Callback";

  @DomName('SVGAnimationElement.getCurrentTime')
  @DocsEditable()
  double getCurrentTime() native "SVGAnimationElement_getCurrentTime_Callback";

  @DomName('SVGAnimationElement.getSimpleDuration')
  @DocsEditable()
  double getSimpleDuration() native "SVGAnimationElement_getSimpleDuration_Callback";

  @DomName('SVGAnimationElement.getStartTime')
  @DocsEditable()
  double getStartTime() native "SVGAnimationElement_getStartTime_Callback";

  @DomName('SVGAnimationElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGAnimationElement_externalResourcesRequired_Getter";

  @DomName('SVGAnimationElement.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions native "SVGAnimationElement_requiredExtensions_Getter";

  @DomName('SVGAnimationElement.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures native "SVGAnimationElement_requiredFeatures_Getter";

  @DomName('SVGAnimationElement.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage native "SVGAnimationElement_systemLanguage_Getter";

  @DomName('SVGAnimationElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) native "SVGAnimationElement_hasExtension_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGCircleElement')
@Unstable()
class CircleElement extends GraphicsElement implements ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory CircleElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGCircleElement.SVGCircleElement')
  @DocsEditable()
  factory CircleElement() => _SvgElementFactoryProvider.createSvgElement_tag("circle");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  CircleElement.created() : super.created();

  @DomName('SVGCircleElement.cx')
  @DocsEditable()
  AnimatedLength get cx native "SVGCircleElement_cx_Getter";

  @DomName('SVGCircleElement.cy')
  @DocsEditable()
  AnimatedLength get cy native "SVGCircleElement_cy_Getter";

  @DomName('SVGCircleElement.r')
  @DocsEditable()
  AnimatedLength get r native "SVGCircleElement_r_Getter";

  @DomName('SVGCircleElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGCircleElement_externalResourcesRequired_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGClipPathElement')
@Unstable()
class ClipPathElement extends GraphicsElement implements ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory ClipPathElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGClipPathElement.SVGClipPathElement')
  @DocsEditable()
  factory ClipPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("clipPath");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  ClipPathElement.created() : super.created();

  @DomName('SVGClipPathElement.clipPathUnits')
  @DocsEditable()
  AnimatedEnumeration get clipPathUnits native "SVGClipPathElement_clipPathUnits_Getter";

  @DomName('SVGClipPathElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGClipPathElement_externalResourcesRequired_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGDefsElement')
@Unstable()
class DefsElement extends GraphicsElement implements ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory DefsElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGDefsElement.SVGDefsElement')
  @DocsEditable()
  factory DefsElement() => _SvgElementFactoryProvider.createSvgElement_tag("defs");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  DefsElement.created() : super.created();

  @DomName('SVGDefsElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGDefsElement_externalResourcesRequired_Getter";

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
  factory DescElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGDescElement.SVGDescElement')
  @DocsEditable()
  factory DescElement() => _SvgElementFactoryProvider.createSvgElement_tag("desc");
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
@DomName('SVGElementInstance')
@Unstable()
class ElementInstance extends EventTarget {
  // To suppress missing implicit constructor warnings.
  factory ElementInstance._() { throw new UnsupportedError("Not supported"); }

  /**
   * Static factory designed to expose `abort` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.abortEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> abortEvent = const EventStreamProvider<Event>('abort');

  /**
   * Static factory designed to expose `beforecopy` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.beforecopyEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> beforeCopyEvent = const EventStreamProvider<Event>('beforecopy');

  /**
   * Static factory designed to expose `beforecut` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.beforecutEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> beforeCutEvent = const EventStreamProvider<Event>('beforecut');

  /**
   * Static factory designed to expose `beforepaste` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.beforepasteEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> beforePasteEvent = const EventStreamProvider<Event>('beforepaste');

  /**
   * Static factory designed to expose `blur` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.blurEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> blurEvent = const EventStreamProvider<Event>('blur');

  /**
   * Static factory designed to expose `change` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.changeEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> changeEvent = const EventStreamProvider<Event>('change');

  /**
   * Static factory designed to expose `click` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.clickEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> clickEvent = const EventStreamProvider<MouseEvent>('click');

  /**
   * Static factory designed to expose `contextmenu` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.contextmenuEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> contextMenuEvent = const EventStreamProvider<MouseEvent>('contextmenu');

  /**
   * Static factory designed to expose `copy` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.copyEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> copyEvent = const EventStreamProvider<Event>('copy');

  /**
   * Static factory designed to expose `cut` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.cutEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> cutEvent = const EventStreamProvider<Event>('cut');

  /**
   * Static factory designed to expose `doubleclick` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.dblclickEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> doubleClickEvent = const EventStreamProvider<Event>('dblclick');

  /**
   * Static factory designed to expose `drag` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.dragEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> dragEvent = const EventStreamProvider<MouseEvent>('drag');

  /**
   * Static factory designed to expose `dragend` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.dragendEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> dragEndEvent = const EventStreamProvider<MouseEvent>('dragend');

  /**
   * Static factory designed to expose `dragenter` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.dragenterEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> dragEnterEvent = const EventStreamProvider<MouseEvent>('dragenter');

  /**
   * Static factory designed to expose `dragleave` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.dragleaveEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> dragLeaveEvent = const EventStreamProvider<MouseEvent>('dragleave');

  /**
   * Static factory designed to expose `dragover` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.dragoverEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> dragOverEvent = const EventStreamProvider<MouseEvent>('dragover');

  /**
   * Static factory designed to expose `dragstart` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.dragstartEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> dragStartEvent = const EventStreamProvider<MouseEvent>('dragstart');

  /**
   * Static factory designed to expose `drop` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.dropEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> dropEvent = const EventStreamProvider<MouseEvent>('drop');

  /**
   * Static factory designed to expose `error` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.errorEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  /**
   * Static factory designed to expose `focus` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.focusEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> focusEvent = const EventStreamProvider<Event>('focus');

  /**
   * Static factory designed to expose `input` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.inputEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> inputEvent = const EventStreamProvider<Event>('input');

  /**
   * Static factory designed to expose `keydown` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.keydownEvent')
  @DocsEditable()
  static const EventStreamProvider<KeyboardEvent> keyDownEvent = const EventStreamProvider<KeyboardEvent>('keydown');

  /**
   * Static factory designed to expose `keypress` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.keypressEvent')
  @DocsEditable()
  static const EventStreamProvider<KeyboardEvent> keyPressEvent = const EventStreamProvider<KeyboardEvent>('keypress');

  /**
   * Static factory designed to expose `keyup` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.keyupEvent')
  @DocsEditable()
  static const EventStreamProvider<KeyboardEvent> keyUpEvent = const EventStreamProvider<KeyboardEvent>('keyup');

  /**
   * Static factory designed to expose `load` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.loadEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> loadEvent = const EventStreamProvider<Event>('load');

  /**
   * Static factory designed to expose `mousedown` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.mousedownEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> mouseDownEvent = const EventStreamProvider<MouseEvent>('mousedown');

  /**
   * Static factory designed to expose `mouseenter` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.mouseenterEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> mouseEnterEvent = const EventStreamProvider<MouseEvent>('mouseenter');

  /**
   * Static factory designed to expose `mouseleave` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.mouseleaveEvent')
  @DocsEditable()
  @Experimental() // untriaged
  static const EventStreamProvider<MouseEvent> mouseLeaveEvent = const EventStreamProvider<MouseEvent>('mouseleave');

  /**
   * Static factory designed to expose `mousemove` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.mousemoveEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> mouseMoveEvent = const EventStreamProvider<MouseEvent>('mousemove');

  /**
   * Static factory designed to expose `mouseout` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.mouseoutEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> mouseOutEvent = const EventStreamProvider<MouseEvent>('mouseout');

  /**
   * Static factory designed to expose `mouseover` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.mouseoverEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> mouseOverEvent = const EventStreamProvider<MouseEvent>('mouseover');

  /**
   * Static factory designed to expose `mouseup` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.mouseupEvent')
  @DocsEditable()
  static const EventStreamProvider<MouseEvent> mouseUpEvent = const EventStreamProvider<MouseEvent>('mouseup');

  /**
   * Static factory designed to expose `mousewheel` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.mousewheelEvent')
  @DocsEditable()
  static const EventStreamProvider<WheelEvent> mouseWheelEvent = const EventStreamProvider<WheelEvent>('mousewheel');

  /**
   * Static factory designed to expose `paste` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.pasteEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> pasteEvent = const EventStreamProvider<Event>('paste');

  /**
   * Static factory designed to expose `reset` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.resetEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> resetEvent = const EventStreamProvider<Event>('reset');

  /**
   * Static factory designed to expose `resize` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.resizeEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> resizeEvent = const EventStreamProvider<Event>('resize');

  /**
   * Static factory designed to expose `scroll` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.scrollEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> scrollEvent = const EventStreamProvider<Event>('scroll');

  /**
   * Static factory designed to expose `search` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.searchEvent')
  @DocsEditable()
  // http://www.w3.org/TR/html-markup/input.search.html
  @Experimental()
  static const EventStreamProvider<Event> searchEvent = const EventStreamProvider<Event>('search');

  /**
   * Static factory designed to expose `select` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.selectEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> selectEvent = const EventStreamProvider<Event>('select');

  /**
   * Static factory designed to expose `selectstart` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.selectstartEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> selectStartEvent = const EventStreamProvider<Event>('selectstart');

  /**
   * Static factory designed to expose `submit` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.submitEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> submitEvent = const EventStreamProvider<Event>('submit');

  /**
   * Static factory designed to expose `unload` events to event
   * handlers that are not necessarily instances of [ElementInstance].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('SVGElementInstance.unloadEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> unloadEvent = const EventStreamProvider<Event>('unload');

  @DomName('SVGElementInstance.childNodes')
  @DocsEditable()
  List<ElementInstance> get childNodes native "SVGElementInstance_childNodes_Getter";

  @DomName('SVGElementInstance.correspondingElement')
  @DocsEditable()
  SvgElement get correspondingElement native "SVGElementInstance_correspondingElement_Getter";

  @DomName('SVGElementInstance.correspondingUseElement')
  @DocsEditable()
  UseElement get correspondingUseElement native "SVGElementInstance_correspondingUseElement_Getter";

  @DomName('SVGElementInstance.firstChild')
  @DocsEditable()
  ElementInstance get firstChild native "SVGElementInstance_firstChild_Getter";

  @DomName('SVGElementInstance.lastChild')
  @DocsEditable()
  ElementInstance get lastChild native "SVGElementInstance_lastChild_Getter";

  @DomName('SVGElementInstance.nextSibling')
  @DocsEditable()
  ElementInstance get nextSibling native "SVGElementInstance_nextSibling_Getter";

  @DomName('SVGElementInstance.parentNode')
  @DocsEditable()
  ElementInstance get parentNode native "SVGElementInstance_parentNode_Getter";

  @DomName('SVGElementInstance.previousSibling')
  @DocsEditable()
  ElementInstance get previousSibling native "SVGElementInstance_previousSibling_Getter";

  @DomName('SVGElementInstance.addEventListener')
  @DocsEditable()
  @Experimental() // untriaged
  void addEventListener(String type, EventListener listener, [bool useCapture]) native "SVGElementInstance_addEventListener_Callback";

  @DomName('SVGElementInstance.dispatchEvent')
  @DocsEditable()
  @Experimental() // untriaged
  bool dispatchEvent(Event event) native "SVGElementInstance_dispatchEvent_Callback";

  @DomName('SVGElementInstance.removeEventListener')
  @DocsEditable()
  @Experimental() // untriaged
  void removeEventListener(String type, EventListener listener, [bool useCapture]) native "SVGElementInstance_removeEventListener_Callback";

  /// Stream of `abort` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onabort')
  @DocsEditable()
  Stream<Event> get onAbort => abortEvent.forTarget(this);

  /// Stream of `beforecopy` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onbeforecopy')
  @DocsEditable()
  Stream<Event> get onBeforeCopy => beforeCopyEvent.forTarget(this);

  /// Stream of `beforecut` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onbeforecut')
  @DocsEditable()
  Stream<Event> get onBeforeCut => beforeCutEvent.forTarget(this);

  /// Stream of `beforepaste` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onbeforepaste')
  @DocsEditable()
  Stream<Event> get onBeforePaste => beforePasteEvent.forTarget(this);

  /// Stream of `blur` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onblur')
  @DocsEditable()
  Stream<Event> get onBlur => blurEvent.forTarget(this);

  /// Stream of `change` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onchange')
  @DocsEditable()
  Stream<Event> get onChange => changeEvent.forTarget(this);

  /// Stream of `click` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onclick')
  @DocsEditable()
  Stream<MouseEvent> get onClick => clickEvent.forTarget(this);

  /// Stream of `contextmenu` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.oncontextmenu')
  @DocsEditable()
  Stream<MouseEvent> get onContextMenu => contextMenuEvent.forTarget(this);

  /// Stream of `copy` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.oncopy')
  @DocsEditable()
  Stream<Event> get onCopy => copyEvent.forTarget(this);

  /// Stream of `cut` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.oncut')
  @DocsEditable()
  Stream<Event> get onCut => cutEvent.forTarget(this);

  /// Stream of `doubleclick` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.ondblclick')
  @DocsEditable()
  Stream<Event> get onDoubleClick => doubleClickEvent.forTarget(this);

  /// Stream of `drag` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.ondrag')
  @DocsEditable()
  Stream<MouseEvent> get onDrag => dragEvent.forTarget(this);

  /// Stream of `dragend` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.ondragend')
  @DocsEditable()
  Stream<MouseEvent> get onDragEnd => dragEndEvent.forTarget(this);

  /// Stream of `dragenter` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.ondragenter')
  @DocsEditable()
  Stream<MouseEvent> get onDragEnter => dragEnterEvent.forTarget(this);

  /// Stream of `dragleave` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.ondragleave')
  @DocsEditable()
  Stream<MouseEvent> get onDragLeave => dragLeaveEvent.forTarget(this);

  /// Stream of `dragover` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.ondragover')
  @DocsEditable()
  Stream<MouseEvent> get onDragOver => dragOverEvent.forTarget(this);

  /// Stream of `dragstart` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.ondragstart')
  @DocsEditable()
  Stream<MouseEvent> get onDragStart => dragStartEvent.forTarget(this);

  /// Stream of `drop` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.ondrop')
  @DocsEditable()
  Stream<MouseEvent> get onDrop => dropEvent.forTarget(this);

  /// Stream of `error` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onerror')
  @DocsEditable()
  Stream<Event> get onError => errorEvent.forTarget(this);

  /// Stream of `focus` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onfocus')
  @DocsEditable()
  Stream<Event> get onFocus => focusEvent.forTarget(this);

  /// Stream of `input` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.oninput')
  @DocsEditable()
  Stream<Event> get onInput => inputEvent.forTarget(this);

  /// Stream of `keydown` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onkeydown')
  @DocsEditable()
  Stream<KeyboardEvent> get onKeyDown => keyDownEvent.forTarget(this);

  /// Stream of `keypress` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onkeypress')
  @DocsEditable()
  Stream<KeyboardEvent> get onKeyPress => keyPressEvent.forTarget(this);

  /// Stream of `keyup` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onkeyup')
  @DocsEditable()
  Stream<KeyboardEvent> get onKeyUp => keyUpEvent.forTarget(this);

  /// Stream of `load` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onload')
  @DocsEditable()
  Stream<Event> get onLoad => loadEvent.forTarget(this);

  /// Stream of `mousedown` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onmousedown')
  @DocsEditable()
  Stream<MouseEvent> get onMouseDown => mouseDownEvent.forTarget(this);

  /// Stream of `mouseenter` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onmouseenter')
  @DocsEditable()
  @Experimental() // untriaged
  Stream<MouseEvent> get onMouseEnter => mouseEnterEvent.forTarget(this);

  /// Stream of `mouseleave` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onmouseleave')
  @DocsEditable()
  @Experimental() // untriaged
  Stream<MouseEvent> get onMouseLeave => mouseLeaveEvent.forTarget(this);

  /// Stream of `mousemove` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onmousemove')
  @DocsEditable()
  Stream<MouseEvent> get onMouseMove => mouseMoveEvent.forTarget(this);

  /// Stream of `mouseout` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onmouseout')
  @DocsEditable()
  Stream<MouseEvent> get onMouseOut => mouseOutEvent.forTarget(this);

  /// Stream of `mouseover` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onmouseover')
  @DocsEditable()
  Stream<MouseEvent> get onMouseOver => mouseOverEvent.forTarget(this);

  /// Stream of `mouseup` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onmouseup')
  @DocsEditable()
  Stream<MouseEvent> get onMouseUp => mouseUpEvent.forTarget(this);

  /// Stream of `mousewheel` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onmousewheel')
  @DocsEditable()
  Stream<WheelEvent> get onMouseWheel => mouseWheelEvent.forTarget(this);

  /// Stream of `paste` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onpaste')
  @DocsEditable()
  Stream<Event> get onPaste => pasteEvent.forTarget(this);

  /// Stream of `reset` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onreset')
  @DocsEditable()
  Stream<Event> get onReset => resetEvent.forTarget(this);

  /// Stream of `resize` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onresize')
  @DocsEditable()
  Stream<Event> get onResize => resizeEvent.forTarget(this);

  /// Stream of `scroll` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onscroll')
  @DocsEditable()
  Stream<Event> get onScroll => scrollEvent.forTarget(this);

  /// Stream of `search` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onsearch')
  @DocsEditable()
  // http://www.w3.org/TR/html-markup/input.search.html
  @Experimental()
  Stream<Event> get onSearch => searchEvent.forTarget(this);

  /// Stream of `select` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onselect')
  @DocsEditable()
  Stream<Event> get onSelect => selectEvent.forTarget(this);

  /// Stream of `selectstart` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onselectstart')
  @DocsEditable()
  Stream<Event> get onSelectStart => selectStartEvent.forTarget(this);

  /// Stream of `submit` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onsubmit')
  @DocsEditable()
  Stream<Event> get onSubmit => submitEvent.forTarget(this);

  /// Stream of `unload` events handled by this [ElementInstance].
  @DomName('SVGElementInstance.onunload')
  @DocsEditable()
  Stream<Event> get onUnload => unloadEvent.forTarget(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGEllipseElement')
@Unstable()
class EllipseElement extends GraphicsElement implements ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory EllipseElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGEllipseElement.SVGEllipseElement')
  @DocsEditable()
  factory EllipseElement() => _SvgElementFactoryProvider.createSvgElement_tag("ellipse");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  EllipseElement.created() : super.created();

  @DomName('SVGEllipseElement.cx')
  @DocsEditable()
  AnimatedLength get cx native "SVGEllipseElement_cx_Getter";

  @DomName('SVGEllipseElement.cy')
  @DocsEditable()
  AnimatedLength get cy native "SVGEllipseElement_cy_Getter";

  @DomName('SVGEllipseElement.rx')
  @DocsEditable()
  AnimatedLength get rx native "SVGEllipseElement_rx_Getter";

  @DomName('SVGEllipseElement.ry')
  @DocsEditable()
  AnimatedLength get ry native "SVGEllipseElement_ry_Getter";

  @DomName('SVGEllipseElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGEllipseElement_externalResourcesRequired_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGExternalResourcesRequired')
@Unstable()
abstract class ExternalResourcesRequired extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory ExternalResourcesRequired._() { throw new UnsupportedError("Not supported"); }

  /// Checks if this type is supported on the current platform.
  static bool supported(SvgElement element) => true;

  @DomName('SVGExternalResourcesRequired.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGExternalResourcesRequired_externalResourcesRequired_Getter";

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
class FEBlendElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEBlendElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEBlendElement.SVGFEBlendElement')
  @DocsEditable()
  factory FEBlendElement() => _SvgElementFactoryProvider.createSvgElement_tag("feBlend");
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
  AnimatedString get in1 native "SVGFEBlendElement_in1_Getter";

  @DomName('SVGFEBlendElement.in2')
  @DocsEditable()
  AnimatedString get in2 native "SVGFEBlendElement_in2_Getter";

  @DomName('SVGFEBlendElement.mode')
  @DocsEditable()
  AnimatedEnumeration get mode native "SVGFEBlendElement_mode_Getter";

  @DomName('SVGFEBlendElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGFEBlendElement_height_Getter";

  @DomName('SVGFEBlendElement.result')
  @DocsEditable()
  AnimatedString get result native "SVGFEBlendElement_result_Getter";

  @DomName('SVGFEBlendElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGFEBlendElement_width_Getter";

  @DomName('SVGFEBlendElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGFEBlendElement_x_Getter";

  @DomName('SVGFEBlendElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGFEBlendElement_y_Getter";

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
class FEColorMatrixElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEColorMatrixElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEColorMatrixElement.SVGFEColorMatrixElement')
  @DocsEditable()
  factory FEColorMatrixElement() => _SvgElementFactoryProvider.createSvgElement_tag("feColorMatrix");
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
  AnimatedString get in1 native "SVGFEColorMatrixElement_in1_Getter";

  @DomName('SVGFEColorMatrixElement.type')
  @DocsEditable()
  AnimatedEnumeration get type native "SVGFEColorMatrixElement_type_Getter";

  @DomName('SVGFEColorMatrixElement.values')
  @DocsEditable()
  AnimatedNumberList get values native "SVGFEColorMatrixElement_values_Getter";

  @DomName('SVGFEColorMatrixElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGFEColorMatrixElement_height_Getter";

  @DomName('SVGFEColorMatrixElement.result')
  @DocsEditable()
  AnimatedString get result native "SVGFEColorMatrixElement_result_Getter";

  @DomName('SVGFEColorMatrixElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGFEColorMatrixElement_width_Getter";

  @DomName('SVGFEColorMatrixElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGFEColorMatrixElement_x_Getter";

  @DomName('SVGFEColorMatrixElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGFEColorMatrixElement_y_Getter";

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
class FEComponentTransferElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEComponentTransferElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEComponentTransferElement.SVGFEComponentTransferElement')
  @DocsEditable()
  factory FEComponentTransferElement() => _SvgElementFactoryProvider.createSvgElement_tag("feComponentTransfer");
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
  AnimatedString get in1 native "SVGFEComponentTransferElement_in1_Getter";

  @DomName('SVGFEComponentTransferElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGFEComponentTransferElement_height_Getter";

  @DomName('SVGFEComponentTransferElement.result')
  @DocsEditable()
  AnimatedString get result native "SVGFEComponentTransferElement_result_Getter";

  @DomName('SVGFEComponentTransferElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGFEComponentTransferElement_width_Getter";

  @DomName('SVGFEComponentTransferElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGFEComponentTransferElement_x_Getter";

  @DomName('SVGFEComponentTransferElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGFEComponentTransferElement_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFECompositeElement')
@Unstable()
class FECompositeElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FECompositeElement._() { throw new UnsupportedError("Not supported"); }
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
  AnimatedString get in1 native "SVGFECompositeElement_in1_Getter";

  @DomName('SVGFECompositeElement.in2')
  @DocsEditable()
  AnimatedString get in2 native "SVGFECompositeElement_in2_Getter";

  @DomName('SVGFECompositeElement.k1')
  @DocsEditable()
  AnimatedNumber get k1 native "SVGFECompositeElement_k1_Getter";

  @DomName('SVGFECompositeElement.k2')
  @DocsEditable()
  AnimatedNumber get k2 native "SVGFECompositeElement_k2_Getter";

  @DomName('SVGFECompositeElement.k3')
  @DocsEditable()
  AnimatedNumber get k3 native "SVGFECompositeElement_k3_Getter";

  @DomName('SVGFECompositeElement.k4')
  @DocsEditable()
  AnimatedNumber get k4 native "SVGFECompositeElement_k4_Getter";

  @DomName('SVGFECompositeElement.operator')
  @DocsEditable()
  AnimatedEnumeration get operator native "SVGFECompositeElement_operator_Getter";

  @DomName('SVGFECompositeElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGFECompositeElement_height_Getter";

  @DomName('SVGFECompositeElement.result')
  @DocsEditable()
  AnimatedString get result native "SVGFECompositeElement_result_Getter";

  @DomName('SVGFECompositeElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGFECompositeElement_width_Getter";

  @DomName('SVGFECompositeElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGFECompositeElement_x_Getter";

  @DomName('SVGFECompositeElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGFECompositeElement_y_Getter";

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
class FEConvolveMatrixElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEConvolveMatrixElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEConvolveMatrixElement.SVGFEConvolveMatrixElement')
  @DocsEditable()
  factory FEConvolveMatrixElement() => _SvgElementFactoryProvider.createSvgElement_tag("feConvolveMatrix");
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
  AnimatedNumber get bias native "SVGFEConvolveMatrixElement_bias_Getter";

  @DomName('SVGFEConvolveMatrixElement.divisor')
  @DocsEditable()
  AnimatedNumber get divisor native "SVGFEConvolveMatrixElement_divisor_Getter";

  @DomName('SVGFEConvolveMatrixElement.edgeMode')
  @DocsEditable()
  AnimatedEnumeration get edgeMode native "SVGFEConvolveMatrixElement_edgeMode_Getter";

  @DomName('SVGFEConvolveMatrixElement.in1')
  @DocsEditable()
  AnimatedString get in1 native "SVGFEConvolveMatrixElement_in1_Getter";

  @DomName('SVGFEConvolveMatrixElement.kernelMatrix')
  @DocsEditable()
  AnimatedNumberList get kernelMatrix native "SVGFEConvolveMatrixElement_kernelMatrix_Getter";

  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthX')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthX native "SVGFEConvolveMatrixElement_kernelUnitLengthX_Getter";

  @DomName('SVGFEConvolveMatrixElement.kernelUnitLengthY')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthY native "SVGFEConvolveMatrixElement_kernelUnitLengthY_Getter";

  @DomName('SVGFEConvolveMatrixElement.orderX')
  @DocsEditable()
  AnimatedInteger get orderX native "SVGFEConvolveMatrixElement_orderX_Getter";

  @DomName('SVGFEConvolveMatrixElement.orderY')
  @DocsEditable()
  AnimatedInteger get orderY native "SVGFEConvolveMatrixElement_orderY_Getter";

  @DomName('SVGFEConvolveMatrixElement.preserveAlpha')
  @DocsEditable()
  AnimatedBoolean get preserveAlpha native "SVGFEConvolveMatrixElement_preserveAlpha_Getter";

  @DomName('SVGFEConvolveMatrixElement.targetX')
  @DocsEditable()
  AnimatedInteger get targetX native "SVGFEConvolveMatrixElement_targetX_Getter";

  @DomName('SVGFEConvolveMatrixElement.targetY')
  @DocsEditable()
  AnimatedInteger get targetY native "SVGFEConvolveMatrixElement_targetY_Getter";

  @DomName('SVGFEConvolveMatrixElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGFEConvolveMatrixElement_height_Getter";

  @DomName('SVGFEConvolveMatrixElement.result')
  @DocsEditable()
  AnimatedString get result native "SVGFEConvolveMatrixElement_result_Getter";

  @DomName('SVGFEConvolveMatrixElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGFEConvolveMatrixElement_width_Getter";

  @DomName('SVGFEConvolveMatrixElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGFEConvolveMatrixElement_x_Getter";

  @DomName('SVGFEConvolveMatrixElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGFEConvolveMatrixElement_y_Getter";

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
class FEDiffuseLightingElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEDiffuseLightingElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEDiffuseLightingElement.SVGFEDiffuseLightingElement')
  @DocsEditable()
  factory FEDiffuseLightingElement() => _SvgElementFactoryProvider.createSvgElement_tag("feDiffuseLighting");
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
  AnimatedNumber get diffuseConstant native "SVGFEDiffuseLightingElement_diffuseConstant_Getter";

  @DomName('SVGFEDiffuseLightingElement.in1')
  @DocsEditable()
  AnimatedString get in1 native "SVGFEDiffuseLightingElement_in1_Getter";

  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthX')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthX native "SVGFEDiffuseLightingElement_kernelUnitLengthX_Getter";

  @DomName('SVGFEDiffuseLightingElement.kernelUnitLengthY')
  @DocsEditable()
  AnimatedNumber get kernelUnitLengthY native "SVGFEDiffuseLightingElement_kernelUnitLengthY_Getter";

  @DomName('SVGFEDiffuseLightingElement.surfaceScale')
  @DocsEditable()
  AnimatedNumber get surfaceScale native "SVGFEDiffuseLightingElement_surfaceScale_Getter";

  @DomName('SVGFEDiffuseLightingElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGFEDiffuseLightingElement_height_Getter";

  @DomName('SVGFEDiffuseLightingElement.result')
  @DocsEditable()
  AnimatedString get result native "SVGFEDiffuseLightingElement_result_Getter";

  @DomName('SVGFEDiffuseLightingElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGFEDiffuseLightingElement_width_Getter";

  @DomName('SVGFEDiffuseLightingElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGFEDiffuseLightingElement_x_Getter";

  @DomName('SVGFEDiffuseLightingElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGFEDiffuseLightingElement_y_Getter";

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
class FEDisplacementMapElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEDisplacementMapElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEDisplacementMapElement.SVGFEDisplacementMapElement')
  @DocsEditable()
  factory FEDisplacementMapElement() => _SvgElementFactoryProvider.createSvgElement_tag("feDisplacementMap");
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
  AnimatedString get in1 native "SVGFEDisplacementMapElement_in1_Getter";

  @DomName('SVGFEDisplacementMapElement.in2')
  @DocsEditable()
  AnimatedString get in2 native "SVGFEDisplacementMapElement_in2_Getter";

  @DomName('SVGFEDisplacementMapElement.scale')
  @DocsEditable()
  AnimatedNumber get scale native "SVGFEDisplacementMapElement_scale_Getter";

  @DomName('SVGFEDisplacementMapElement.xChannelSelector')
  @DocsEditable()
  AnimatedEnumeration get xChannelSelector native "SVGFEDisplacementMapElement_xChannelSelector_Getter";

  @DomName('SVGFEDisplacementMapElement.yChannelSelector')
  @DocsEditable()
  AnimatedEnumeration get yChannelSelector native "SVGFEDisplacementMapElement_yChannelSelector_Getter";

  @DomName('SVGFEDisplacementMapElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGFEDisplacementMapElement_height_Getter";

  @DomName('SVGFEDisplacementMapElement.result')
  @DocsEditable()
  AnimatedString get result native "SVGFEDisplacementMapElement_result_Getter";

  @DomName('SVGFEDisplacementMapElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGFEDisplacementMapElement_width_Getter";

  @DomName('SVGFEDisplacementMapElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGFEDisplacementMapElement_x_Getter";

  @DomName('SVGFEDisplacementMapElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGFEDisplacementMapElement_y_Getter";

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
  factory FEDistantLightElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEDistantLightElement.SVGFEDistantLightElement')
  @DocsEditable()
  factory FEDistantLightElement() => _SvgElementFactoryProvider.createSvgElement_tag("feDistantLight");
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
  AnimatedNumber get azimuth native "SVGFEDistantLightElement_azimuth_Getter";

  @DomName('SVGFEDistantLightElement.elevation')
  @DocsEditable()
  AnimatedNumber get elevation native "SVGFEDistantLightElement_elevation_Getter";

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
class FEFloodElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEFloodElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEFloodElement.SVGFEFloodElement')
  @DocsEditable()
  factory FEFloodElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFlood");
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
  AnimatedLength get height native "SVGFEFloodElement_height_Getter";

  @DomName('SVGFEFloodElement.result')
  @DocsEditable()
  AnimatedString get result native "SVGFEFloodElement_result_Getter";

  @DomName('SVGFEFloodElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGFEFloodElement_width_Getter";

  @DomName('SVGFEFloodElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGFEFloodElement_x_Getter";

  @DomName('SVGFEFloodElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGFEFloodElement_y_Getter";

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
  factory FEFuncAElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEFuncAElement.SVGFEFuncAElement')
  @DocsEditable()
  factory FEFuncAElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFuncA");
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
  factory FEFuncBElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEFuncBElement.SVGFEFuncBElement')
  @DocsEditable()
  factory FEFuncBElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFuncB");
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
  factory FEFuncGElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEFuncGElement.SVGFEFuncGElement')
  @DocsEditable()
  factory FEFuncGElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFuncG");
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
  factory FEFuncRElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEFuncRElement.SVGFEFuncRElement')
  @DocsEditable()
  factory FEFuncRElement() => _SvgElementFactoryProvider.createSvgElement_tag("feFuncR");
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
class FEGaussianBlurElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEGaussianBlurElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEGaussianBlurElement.SVGFEGaussianBlurElement')
  @DocsEditable()
  factory FEGaussianBlurElement() => _SvgElementFactoryProvider.createSvgElement_tag("feGaussianBlur");
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
  AnimatedString get in1 native "SVGFEGaussianBlurElement_in1_Getter";

  @DomName('SVGFEGaussianBlurElement.stdDeviationX')
  @DocsEditable()
  AnimatedNumber get stdDeviationX native "SVGFEGaussianBlurElement_stdDeviationX_Getter";

  @DomName('SVGFEGaussianBlurElement.stdDeviationY')
  @DocsEditable()
  AnimatedNumber get stdDeviationY native "SVGFEGaussianBlurElement_stdDeviationY_Getter";

  @DomName('SVGFEGaussianBlurElement.setStdDeviation')
  @DocsEditable()
  void setStdDeviation(num stdDeviationX, num stdDeviationY) native "SVGFEGaussianBlurElement_setStdDeviation_Callback";

  @DomName('SVGFEGaussianBlurElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGFEGaussianBlurElement_height_Getter";

  @DomName('SVGFEGaussianBlurElement.result')
  @DocsEditable()
  AnimatedString get result native "SVGFEGaussianBlurElement_result_Getter";

  @DomName('SVGFEGaussianBlurElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGFEGaussianBlurElement_width_Getter";

  @DomName('SVGFEGaussianBlurElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGFEGaussianBlurElement_x_Getter";

  @DomName('SVGFEGaussianBlurElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGFEGaussianBlurElement_y_Getter";

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
class FEImageElement extends SvgElement implements FilterPrimitiveStandardAttributes, UriReference, ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory FEImageElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEImageElement.SVGFEImageElement')
  @DocsEditable()
  factory FEImageElement() => _SvgElementFactoryProvider.createSvgElement_tag("feImage");
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
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGFEImageElement_preserveAspectRatio_Getter";

  @DomName('SVGFEImageElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGFEImageElement_externalResourcesRequired_Getter";

  @DomName('SVGFEImageElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGFEImageElement_height_Getter";

  @DomName('SVGFEImageElement.result')
  @DocsEditable()
  AnimatedString get result native "SVGFEImageElement_result_Getter";

  @DomName('SVGFEImageElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGFEImageElement_width_Getter";

  @DomName('SVGFEImageElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGFEImageElement_x_Getter";

  @DomName('SVGFEImageElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGFEImageElement_y_Getter";

  @DomName('SVGFEImageElement.href')
  @DocsEditable()
  AnimatedString get href native "SVGFEImageElement_href_Getter";

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
class FEMergeElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEMergeElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEMergeElement.SVGFEMergeElement')
  @DocsEditable()
  factory FEMergeElement() => _SvgElementFactoryProvider.createSvgElement_tag("feMerge");
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
  AnimatedLength get height native "SVGFEMergeElement_height_Getter";

  @DomName('SVGFEMergeElement.result')
  @DocsEditable()
  AnimatedString get result native "SVGFEMergeElement_result_Getter";

  @DomName('SVGFEMergeElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGFEMergeElement_width_Getter";

  @DomName('SVGFEMergeElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGFEMergeElement_x_Getter";

  @DomName('SVGFEMergeElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGFEMergeElement_y_Getter";

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
  factory FEMergeNodeElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEMergeNodeElement.SVGFEMergeNodeElement')
  @DocsEditable()
  factory FEMergeNodeElement() => _SvgElementFactoryProvider.createSvgElement_tag("feMergeNode");
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
  AnimatedString get in1 native "SVGFEMergeNodeElement_in1_Getter";

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
class FEMorphologyElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEMorphologyElement._() { throw new UnsupportedError("Not supported"); }
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
  AnimatedString get in1 native "SVGFEMorphologyElement_in1_Getter";

  @DomName('SVGFEMorphologyElement.operator')
  @DocsEditable()
  AnimatedEnumeration get operator native "SVGFEMorphologyElement_operator_Getter";

  @DomName('SVGFEMorphologyElement.radiusX')
  @DocsEditable()
  AnimatedNumber get radiusX native "SVGFEMorphologyElement_radiusX_Getter";

  @DomName('SVGFEMorphologyElement.radiusY')
  @DocsEditable()
  AnimatedNumber get radiusY native "SVGFEMorphologyElement_radiusY_Getter";

  @DomName('SVGFEMorphologyElement.setRadius')
  @DocsEditable()
  void setRadius(num radiusX, num radiusY) native "SVGFEMorphologyElement_setRadius_Callback";

  @DomName('SVGFEMorphologyElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGFEMorphologyElement_height_Getter";

  @DomName('SVGFEMorphologyElement.result')
  @DocsEditable()
  AnimatedString get result native "SVGFEMorphologyElement_result_Getter";

  @DomName('SVGFEMorphologyElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGFEMorphologyElement_width_Getter";

  @DomName('SVGFEMorphologyElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGFEMorphologyElement_x_Getter";

  @DomName('SVGFEMorphologyElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGFEMorphologyElement_y_Getter";

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
class FEOffsetElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FEOffsetElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEOffsetElement.SVGFEOffsetElement')
  @DocsEditable()
  factory FEOffsetElement() => _SvgElementFactoryProvider.createSvgElement_tag("feOffset");
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
  AnimatedNumber get dx native "SVGFEOffsetElement_dx_Getter";

  @DomName('SVGFEOffsetElement.dy')
  @DocsEditable()
  AnimatedNumber get dy native "SVGFEOffsetElement_dy_Getter";

  @DomName('SVGFEOffsetElement.in1')
  @DocsEditable()
  AnimatedString get in1 native "SVGFEOffsetElement_in1_Getter";

  @DomName('SVGFEOffsetElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGFEOffsetElement_height_Getter";

  @DomName('SVGFEOffsetElement.result')
  @DocsEditable()
  AnimatedString get result native "SVGFEOffsetElement_result_Getter";

  @DomName('SVGFEOffsetElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGFEOffsetElement_width_Getter";

  @DomName('SVGFEOffsetElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGFEOffsetElement_x_Getter";

  @DomName('SVGFEOffsetElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGFEOffsetElement_y_Getter";

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
  factory FEPointLightElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFEPointLightElement.SVGFEPointLightElement')
  @DocsEditable()
  factory FEPointLightElement() => _SvgElementFactoryProvider.createSvgElement_tag("fePointLight");
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
  AnimatedNumber get x native "SVGFEPointLightElement_x_Getter";

  @DomName('SVGFEPointLightElement.y')
  @DocsEditable()
  AnimatedNumber get y native "SVGFEPointLightElement_y_Getter";

  @DomName('SVGFEPointLightElement.z')
  @DocsEditable()
  AnimatedNumber get z native "SVGFEPointLightElement_z_Getter";

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
class FESpecularLightingElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FESpecularLightingElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFESpecularLightingElement.SVGFESpecularLightingElement')
  @DocsEditable()
  factory FESpecularLightingElement() => _SvgElementFactoryProvider.createSvgElement_tag("feSpecularLighting");
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
  AnimatedString get in1 native "SVGFESpecularLightingElement_in1_Getter";

  @DomName('SVGFESpecularLightingElement.specularConstant')
  @DocsEditable()
  AnimatedNumber get specularConstant native "SVGFESpecularLightingElement_specularConstant_Getter";

  @DomName('SVGFESpecularLightingElement.specularExponent')
  @DocsEditable()
  AnimatedNumber get specularExponent native "SVGFESpecularLightingElement_specularExponent_Getter";

  @DomName('SVGFESpecularLightingElement.surfaceScale')
  @DocsEditable()
  AnimatedNumber get surfaceScale native "SVGFESpecularLightingElement_surfaceScale_Getter";

  @DomName('SVGFESpecularLightingElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGFESpecularLightingElement_height_Getter";

  @DomName('SVGFESpecularLightingElement.result')
  @DocsEditable()
  AnimatedString get result native "SVGFESpecularLightingElement_result_Getter";

  @DomName('SVGFESpecularLightingElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGFESpecularLightingElement_width_Getter";

  @DomName('SVGFESpecularLightingElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGFESpecularLightingElement_x_Getter";

  @DomName('SVGFESpecularLightingElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGFESpecularLightingElement_y_Getter";

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
  factory FESpotLightElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFESpotLightElement.SVGFESpotLightElement')
  @DocsEditable()
  factory FESpotLightElement() => _SvgElementFactoryProvider.createSvgElement_tag("feSpotLight");
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
  AnimatedNumber get limitingConeAngle native "SVGFESpotLightElement_limitingConeAngle_Getter";

  @DomName('SVGFESpotLightElement.pointsAtX')
  @DocsEditable()
  AnimatedNumber get pointsAtX native "SVGFESpotLightElement_pointsAtX_Getter";

  @DomName('SVGFESpotLightElement.pointsAtY')
  @DocsEditable()
  AnimatedNumber get pointsAtY native "SVGFESpotLightElement_pointsAtY_Getter";

  @DomName('SVGFESpotLightElement.pointsAtZ')
  @DocsEditable()
  AnimatedNumber get pointsAtZ native "SVGFESpotLightElement_pointsAtZ_Getter";

  @DomName('SVGFESpotLightElement.specularExponent')
  @DocsEditable()
  AnimatedNumber get specularExponent native "SVGFESpotLightElement_specularExponent_Getter";

  @DomName('SVGFESpotLightElement.x')
  @DocsEditable()
  AnimatedNumber get x native "SVGFESpotLightElement_x_Getter";

  @DomName('SVGFESpotLightElement.y')
  @DocsEditable()
  AnimatedNumber get y native "SVGFESpotLightElement_y_Getter";

  @DomName('SVGFESpotLightElement.z')
  @DocsEditable()
  AnimatedNumber get z native "SVGFESpotLightElement_z_Getter";

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
class FETileElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FETileElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFETileElement.SVGFETileElement')
  @DocsEditable()
  factory FETileElement() => _SvgElementFactoryProvider.createSvgElement_tag("feTile");
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
  AnimatedString get in1 native "SVGFETileElement_in1_Getter";

  @DomName('SVGFETileElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGFETileElement_height_Getter";

  @DomName('SVGFETileElement.result')
  @DocsEditable()
  AnimatedString get result native "SVGFETileElement_result_Getter";

  @DomName('SVGFETileElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGFETileElement_width_Getter";

  @DomName('SVGFETileElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGFETileElement_x_Getter";

  @DomName('SVGFETileElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGFETileElement_y_Getter";

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
class FETurbulenceElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory FETurbulenceElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFETurbulenceElement.SVGFETurbulenceElement')
  @DocsEditable()
  factory FETurbulenceElement() => _SvgElementFactoryProvider.createSvgElement_tag("feTurbulence");
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
  AnimatedNumber get baseFrequencyX native "SVGFETurbulenceElement_baseFrequencyX_Getter";

  @DomName('SVGFETurbulenceElement.baseFrequencyY')
  @DocsEditable()
  AnimatedNumber get baseFrequencyY native "SVGFETurbulenceElement_baseFrequencyY_Getter";

  @DomName('SVGFETurbulenceElement.numOctaves')
  @DocsEditable()
  AnimatedInteger get numOctaves native "SVGFETurbulenceElement_numOctaves_Getter";

  @DomName('SVGFETurbulenceElement.seed')
  @DocsEditable()
  AnimatedNumber get seed native "SVGFETurbulenceElement_seed_Getter";

  @DomName('SVGFETurbulenceElement.stitchTiles')
  @DocsEditable()
  AnimatedEnumeration get stitchTiles native "SVGFETurbulenceElement_stitchTiles_Getter";

  @DomName('SVGFETurbulenceElement.type')
  @DocsEditable()
  AnimatedEnumeration get type native "SVGFETurbulenceElement_type_Getter";

  @DomName('SVGFETurbulenceElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGFETurbulenceElement_height_Getter";

  @DomName('SVGFETurbulenceElement.result')
  @DocsEditable()
  AnimatedString get result native "SVGFETurbulenceElement_result_Getter";

  @DomName('SVGFETurbulenceElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGFETurbulenceElement_width_Getter";

  @DomName('SVGFETurbulenceElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGFETurbulenceElement_x_Getter";

  @DomName('SVGFETurbulenceElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGFETurbulenceElement_y_Getter";

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
class FilterElement extends SvgElement implements UriReference, ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory FilterElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFilterElement.SVGFilterElement')
  @DocsEditable()
  factory FilterElement() => _SvgElementFactoryProvider.createSvgElement_tag("filter");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  FilterElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('SVGFilterElement.filterResX')
  @DocsEditable()
  AnimatedInteger get filterResX native "SVGFilterElement_filterResX_Getter";

  @DomName('SVGFilterElement.filterResY')
  @DocsEditable()
  AnimatedInteger get filterResY native "SVGFilterElement_filterResY_Getter";

  @DomName('SVGFilterElement.filterUnits')
  @DocsEditable()
  AnimatedEnumeration get filterUnits native "SVGFilterElement_filterUnits_Getter";

  @DomName('SVGFilterElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGFilterElement_height_Getter";

  @DomName('SVGFilterElement.primitiveUnits')
  @DocsEditable()
  AnimatedEnumeration get primitiveUnits native "SVGFilterElement_primitiveUnits_Getter";

  @DomName('SVGFilterElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGFilterElement_width_Getter";

  @DomName('SVGFilterElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGFilterElement_x_Getter";

  @DomName('SVGFilterElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGFilterElement_y_Getter";

  @DomName('SVGFilterElement.setFilterRes')
  @DocsEditable()
  void setFilterRes(int filterResX, int filterResY) native "SVGFilterElement_setFilterRes_Callback";

  @DomName('SVGFilterElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGFilterElement_externalResourcesRequired_Getter";

  @DomName('SVGFilterElement.href')
  @DocsEditable()
  AnimatedString get href native "SVGFilterElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFilterPrimitiveStandardAttributes')
@Unstable()
abstract class FilterPrimitiveStandardAttributes extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory FilterPrimitiveStandardAttributes._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFilterPrimitiveStandardAttributes.height')
  @DocsEditable()
  AnimatedLength get height native "SVGFilterPrimitiveStandardAttributes_height_Getter";

  @DomName('SVGFilterPrimitiveStandardAttributes.result')
  @DocsEditable()
  AnimatedString get result native "SVGFilterPrimitiveStandardAttributes_result_Getter";

  @DomName('SVGFilterPrimitiveStandardAttributes.width')
  @DocsEditable()
  AnimatedLength get width native "SVGFilterPrimitiveStandardAttributes_width_Getter";

  @DomName('SVGFilterPrimitiveStandardAttributes.x')
  @DocsEditable()
  AnimatedLength get x native "SVGFilterPrimitiveStandardAttributes_x_Getter";

  @DomName('SVGFilterPrimitiveStandardAttributes.y')
  @DocsEditable()
  AnimatedLength get y native "SVGFilterPrimitiveStandardAttributes_y_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFitToViewBox')
@Unstable()
abstract class FitToViewBox extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory FitToViewBox._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGFitToViewBox.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGFitToViewBox_preserveAspectRatio_Getter";

  @DomName('SVGFitToViewBox.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox native "SVGFitToViewBox_viewBox_Getter";

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
class ForeignObjectElement extends GraphicsElement implements ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory ForeignObjectElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGForeignObjectElement.SVGForeignObjectElement')
  @DocsEditable()
  factory ForeignObjectElement() => _SvgElementFactoryProvider.createSvgElement_tag("foreignObject");
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
  AnimatedLength get height native "SVGForeignObjectElement_height_Getter";

  @DomName('SVGForeignObjectElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGForeignObjectElement_width_Getter";

  @DomName('SVGForeignObjectElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGForeignObjectElement_x_Getter";

  @DomName('SVGForeignObjectElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGForeignObjectElement_y_Getter";

  @DomName('SVGForeignObjectElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGForeignObjectElement_externalResourcesRequired_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGGElement')
@Unstable()
class GElement extends GraphicsElement implements ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory GElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGGElement.SVGGElement')
  @DocsEditable()
  factory GElement() => _SvgElementFactoryProvider.createSvgElement_tag("g");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  GElement.created() : super.created();

  @DomName('SVGGElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGGElement_externalResourcesRequired_Getter";

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
  factory GraphicsElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  GraphicsElement.created() : super.created();

  @DomName('SVGGraphicsElement.farthestViewportElement')
  @DocsEditable()
  @Experimental() // untriaged
  SvgElement get farthestViewportElement native "SVGGraphicsElement_farthestViewportElement_Getter";

  @DomName('SVGGraphicsElement.nearestViewportElement')
  @DocsEditable()
  @Experimental() // untriaged
  SvgElement get nearestViewportElement native "SVGGraphicsElement_nearestViewportElement_Getter";

  @DomName('SVGGraphicsElement.transform')
  @DocsEditable()
  @Experimental() // untriaged
  AnimatedTransformList get transform native "SVGGraphicsElement_transform_Getter";

  @DomName('SVGGraphicsElement.getBBox')
  @DocsEditable()
  @Experimental() // untriaged
  Rect getBBox() native "SVGGraphicsElement_getBBox_Callback";

  @DomName('SVGGraphicsElement.getCTM')
  @DocsEditable()
  @Experimental() // untriaged
  Matrix getCtm() native "SVGGraphicsElement_getCTM_Callback";

  @DomName('SVGGraphicsElement.getScreenCTM')
  @DocsEditable()
  @Experimental() // untriaged
  Matrix getScreenCtm() native "SVGGraphicsElement_getScreenCTM_Callback";

  @DomName('SVGGraphicsElement.getTransformToElement')
  @DocsEditable()
  @Experimental() // untriaged
  Matrix getTransformToElement(SvgElement element) native "SVGGraphicsElement_getTransformToElement_Callback";

  @DomName('SVGGraphicsElement.requiredExtensions')
  @DocsEditable()
  @Experimental() // untriaged
  StringList get requiredExtensions native "SVGGraphicsElement_requiredExtensions_Getter";

  @DomName('SVGGraphicsElement.requiredFeatures')
  @DocsEditable()
  @Experimental() // untriaged
  StringList get requiredFeatures native "SVGGraphicsElement_requiredFeatures_Getter";

  @DomName('SVGGraphicsElement.systemLanguage')
  @DocsEditable()
  @Experimental() // untriaged
  StringList get systemLanguage native "SVGGraphicsElement_systemLanguage_Getter";

  @DomName('SVGGraphicsElement.hasExtension')
  @DocsEditable()
  @Experimental() // untriaged
  bool hasExtension(String extension) native "SVGGraphicsElement_hasExtension_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGImageElement')
@Unstable()
class ImageElement extends GraphicsElement implements UriReference, ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory ImageElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGImageElement.SVGImageElement')
  @DocsEditable()
  factory ImageElement() => _SvgElementFactoryProvider.createSvgElement_tag("image");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  ImageElement.created() : super.created();

  @DomName('SVGImageElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGImageElement_height_Getter";

  @DomName('SVGImageElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGImageElement_preserveAspectRatio_Getter";

  @DomName('SVGImageElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGImageElement_width_Getter";

  @DomName('SVGImageElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGImageElement_x_Getter";

  @DomName('SVGImageElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGImageElement_y_Getter";

  @DomName('SVGImageElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGImageElement_externalResourcesRequired_Getter";

  @DomName('SVGImageElement.href')
  @DocsEditable()
  AnimatedString get href native "SVGImageElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGLength')
@Unstable()
class Length extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Length._() { throw new UnsupportedError("Not supported"); }

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
  int get unitType native "SVGLength_unitType_Getter";

  @DomName('SVGLength.value')
  @DocsEditable()
  num get value native "SVGLength_value_Getter";

  @DomName('SVGLength.value')
  @DocsEditable()
  void set value(num value) native "SVGLength_value_Setter";

  @DomName('SVGLength.valueAsString')
  @DocsEditable()
  String get valueAsString native "SVGLength_valueAsString_Getter";

  @DomName('SVGLength.valueAsString')
  @DocsEditable()
  void set valueAsString(String value) native "SVGLength_valueAsString_Setter";

  @DomName('SVGLength.valueInSpecifiedUnits')
  @DocsEditable()
  num get valueInSpecifiedUnits native "SVGLength_valueInSpecifiedUnits_Getter";

  @DomName('SVGLength.valueInSpecifiedUnits')
  @DocsEditable()
  void set valueInSpecifiedUnits(num value) native "SVGLength_valueInSpecifiedUnits_Setter";

  @DomName('SVGLength.convertToSpecifiedUnits')
  @DocsEditable()
  void convertToSpecifiedUnits(int unitType) native "SVGLength_convertToSpecifiedUnits_Callback";

  @DomName('SVGLength.newValueSpecifiedUnits')
  @DocsEditable()
  void newValueSpecifiedUnits(int unitType, num valueInSpecifiedUnits) native "SVGLength_newValueSpecifiedUnits_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGLengthList')
@Unstable()
class LengthList extends NativeFieldWrapperClass2 with ListMixin<Length>, ImmutableListMixin<Length> implements List<Length> {
  // To suppress missing implicit constructor warnings.
  factory LengthList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGLengthList.numberOfItems')
  @DocsEditable()
  int get numberOfItems native "SVGLengthList_numberOfItems_Getter";

  Length operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.range(index, 0, length);
    return getItem(index);
  }

  void operator[]=(int index, Length value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Length> mixins.
  // Length is the element type.

  // SVG Collections expose numberOfItems rather than length.
  int get length => numberOfItems;

  void set length(int value) {
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

  @DomName('SVGLengthList.appendItem')
  @DocsEditable()
  Length appendItem(Length item) native "SVGLengthList_appendItem_Callback";

  @DomName('SVGLengthList.clear')
  @DocsEditable()
  void clear() native "SVGLengthList_clear_Callback";

  @DomName('SVGLengthList.getItem')
  @DocsEditable()
  Length getItem(int index) native "SVGLengthList_getItem_Callback";

  @DomName('SVGLengthList.initialize')
  @DocsEditable()
  Length initialize(Length item) native "SVGLengthList_initialize_Callback";

  @DomName('SVGLengthList.insertItemBefore')
  @DocsEditable()
  Length insertItemBefore(Length item, int index) native "SVGLengthList_insertItemBefore_Callback";

  @DomName('SVGLengthList.removeItem')
  @DocsEditable()
  Length removeItem(int index) native "SVGLengthList_removeItem_Callback";

  @DomName('SVGLengthList.replaceItem')
  @DocsEditable()
  Length replaceItem(Length item, int index) native "SVGLengthList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGLineElement')
@Unstable()
class LineElement extends GraphicsElement implements ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory LineElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGLineElement.SVGLineElement')
  @DocsEditable()
  factory LineElement() => _SvgElementFactoryProvider.createSvgElement_tag("line");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  LineElement.created() : super.created();

  @DomName('SVGLineElement.x1')
  @DocsEditable()
  AnimatedLength get x1 native "SVGLineElement_x1_Getter";

  @DomName('SVGLineElement.x2')
  @DocsEditable()
  AnimatedLength get x2 native "SVGLineElement_x2_Getter";

  @DomName('SVGLineElement.y1')
  @DocsEditable()
  AnimatedLength get y1 native "SVGLineElement_y1_Getter";

  @DomName('SVGLineElement.y2')
  @DocsEditable()
  AnimatedLength get y2 native "SVGLineElement_y2_Getter";

  @DomName('SVGLineElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGLineElement_externalResourcesRequired_Getter";

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
  factory LinearGradientElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGLinearGradientElement.SVGLinearGradientElement')
  @DocsEditable()
  factory LinearGradientElement() => _SvgElementFactoryProvider.createSvgElement_tag("linearGradient");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  LinearGradientElement.created() : super.created();

  @DomName('SVGLinearGradientElement.x1')
  @DocsEditable()
  AnimatedLength get x1 native "SVGLinearGradientElement_x1_Getter";

  @DomName('SVGLinearGradientElement.x2')
  @DocsEditable()
  AnimatedLength get x2 native "SVGLinearGradientElement_x2_Getter";

  @DomName('SVGLinearGradientElement.y1')
  @DocsEditable()
  AnimatedLength get y1 native "SVGLinearGradientElement_y1_Getter";

  @DomName('SVGLinearGradientElement.y2')
  @DocsEditable()
  AnimatedLength get y2 native "SVGLinearGradientElement_y2_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGMarkerElement')
@Unstable()
class MarkerElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory MarkerElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGMarkerElement.SVGMarkerElement')
  @DocsEditable()
  factory MarkerElement() => _SvgElementFactoryProvider.createSvgElement_tag("marker");
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
  AnimatedLength get markerHeight native "SVGMarkerElement_markerHeight_Getter";

  @DomName('SVGMarkerElement.markerUnits')
  @DocsEditable()
  AnimatedEnumeration get markerUnits native "SVGMarkerElement_markerUnits_Getter";

  @DomName('SVGMarkerElement.markerWidth')
  @DocsEditable()
  AnimatedLength get markerWidth native "SVGMarkerElement_markerWidth_Getter";

  @DomName('SVGMarkerElement.orientAngle')
  @DocsEditable()
  AnimatedAngle get orientAngle native "SVGMarkerElement_orientAngle_Getter";

  @DomName('SVGMarkerElement.orientType')
  @DocsEditable()
  AnimatedEnumeration get orientType native "SVGMarkerElement_orientType_Getter";

  @DomName('SVGMarkerElement.refX')
  @DocsEditable()
  AnimatedLength get refX native "SVGMarkerElement_refX_Getter";

  @DomName('SVGMarkerElement.refY')
  @DocsEditable()
  AnimatedLength get refY native "SVGMarkerElement_refY_Getter";

  @DomName('SVGMarkerElement.setOrientToAngle')
  @DocsEditable()
  void setOrientToAngle(Angle angle) native "SVGMarkerElement_setOrientToAngle_Callback";

  @DomName('SVGMarkerElement.setOrientToAuto')
  @DocsEditable()
  void setOrientToAuto() native "SVGMarkerElement_setOrientToAuto_Callback";

  @DomName('SVGMarkerElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGMarkerElement_externalResourcesRequired_Getter";

  @DomName('SVGMarkerElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGMarkerElement_preserveAspectRatio_Getter";

  @DomName('SVGMarkerElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox native "SVGMarkerElement_viewBox_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGMaskElement')
@Unstable()
class MaskElement extends SvgElement implements ExternalResourcesRequired, Tests {
  // To suppress missing implicit constructor warnings.
  factory MaskElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGMaskElement.SVGMaskElement')
  @DocsEditable()
  factory MaskElement() => _SvgElementFactoryProvider.createSvgElement_tag("mask");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  MaskElement.created() : super.created();

  @DomName('SVGMaskElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGMaskElement_height_Getter";

  @DomName('SVGMaskElement.maskContentUnits')
  @DocsEditable()
  AnimatedEnumeration get maskContentUnits native "SVGMaskElement_maskContentUnits_Getter";

  @DomName('SVGMaskElement.maskUnits')
  @DocsEditable()
  AnimatedEnumeration get maskUnits native "SVGMaskElement_maskUnits_Getter";

  @DomName('SVGMaskElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGMaskElement_width_Getter";

  @DomName('SVGMaskElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGMaskElement_x_Getter";

  @DomName('SVGMaskElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGMaskElement_y_Getter";

  @DomName('SVGMaskElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGMaskElement_externalResourcesRequired_Getter";

  @DomName('SVGMaskElement.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions native "SVGMaskElement_requiredExtensions_Getter";

  @DomName('SVGMaskElement.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures native "SVGMaskElement_requiredFeatures_Getter";

  @DomName('SVGMaskElement.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage native "SVGMaskElement_systemLanguage_Getter";

  @DomName('SVGMaskElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) native "SVGMaskElement_hasExtension_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGMatrix')
@Unstable()
class Matrix extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Matrix._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGMatrix.a')
  @DocsEditable()
  num get a native "SVGMatrix_a_Getter";

  @DomName('SVGMatrix.a')
  @DocsEditable()
  void set a(num value) native "SVGMatrix_a_Setter";

  @DomName('SVGMatrix.b')
  @DocsEditable()
  num get b native "SVGMatrix_b_Getter";

  @DomName('SVGMatrix.b')
  @DocsEditable()
  void set b(num value) native "SVGMatrix_b_Setter";

  @DomName('SVGMatrix.c')
  @DocsEditable()
  num get c native "SVGMatrix_c_Getter";

  @DomName('SVGMatrix.c')
  @DocsEditable()
  void set c(num value) native "SVGMatrix_c_Setter";

  @DomName('SVGMatrix.d')
  @DocsEditable()
  num get d native "SVGMatrix_d_Getter";

  @DomName('SVGMatrix.d')
  @DocsEditable()
  void set d(num value) native "SVGMatrix_d_Setter";

  @DomName('SVGMatrix.e')
  @DocsEditable()
  num get e native "SVGMatrix_e_Getter";

  @DomName('SVGMatrix.e')
  @DocsEditable()
  void set e(num value) native "SVGMatrix_e_Setter";

  @DomName('SVGMatrix.f')
  @DocsEditable()
  num get f native "SVGMatrix_f_Getter";

  @DomName('SVGMatrix.f')
  @DocsEditable()
  void set f(num value) native "SVGMatrix_f_Setter";

  @DomName('SVGMatrix.flipX')
  @DocsEditable()
  Matrix flipX() native "SVGMatrix_flipX_Callback";

  @DomName('SVGMatrix.flipY')
  @DocsEditable()
  Matrix flipY() native "SVGMatrix_flipY_Callback";

  @DomName('SVGMatrix.inverse')
  @DocsEditable()
  Matrix inverse() native "SVGMatrix_inverse_Callback";

  @DomName('SVGMatrix.multiply')
  @DocsEditable()
  Matrix multiply(Matrix secondMatrix) native "SVGMatrix_multiply_Callback";

  @DomName('SVGMatrix.rotate')
  @DocsEditable()
  Matrix rotate(num angle) native "SVGMatrix_rotate_Callback";

  @DomName('SVGMatrix.rotateFromVector')
  @DocsEditable()
  Matrix rotateFromVector(num x, num y) native "SVGMatrix_rotateFromVector_Callback";

  @DomName('SVGMatrix.scale')
  @DocsEditable()
  Matrix scale(num scaleFactor) native "SVGMatrix_scale_Callback";

  @DomName('SVGMatrix.scaleNonUniform')
  @DocsEditable()
  Matrix scaleNonUniform(num scaleFactorX, num scaleFactorY) native "SVGMatrix_scaleNonUniform_Callback";

  @DomName('SVGMatrix.skewX')
  @DocsEditable()
  Matrix skewX(num angle) native "SVGMatrix_skewX_Callback";

  @DomName('SVGMatrix.skewY')
  @DocsEditable()
  Matrix skewY(num angle) native "SVGMatrix_skewY_Callback";

  @DomName('SVGMatrix.translate')
  @DocsEditable()
  Matrix translate(num x, num y) native "SVGMatrix_translate_Callback";

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
  factory MetadataElement._() { throw new UnsupportedError("Not supported"); }
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
class Number extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Number._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGNumber.value')
  @DocsEditable()
  num get value native "SVGNumber_value_Getter";

  @DomName('SVGNumber.value')
  @DocsEditable()
  void set value(num value) native "SVGNumber_value_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGNumberList')
@Unstable()
class NumberList extends NativeFieldWrapperClass2 with ListMixin<Number>, ImmutableListMixin<Number> implements List<Number> {
  // To suppress missing implicit constructor warnings.
  factory NumberList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGNumberList.numberOfItems')
  @DocsEditable()
  int get numberOfItems native "SVGNumberList_numberOfItems_Getter";

  Number operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.range(index, 0, length);
    return getItem(index);
  }

  void operator[]=(int index, Number value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Number> mixins.
  // Number is the element type.

  // SVG Collections expose numberOfItems rather than length.
  int get length => numberOfItems;

  void set length(int value) {
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

  @DomName('SVGNumberList.appendItem')
  @DocsEditable()
  Number appendItem(Number item) native "SVGNumberList_appendItem_Callback";

  @DomName('SVGNumberList.clear')
  @DocsEditable()
  void clear() native "SVGNumberList_clear_Callback";

  @DomName('SVGNumberList.getItem')
  @DocsEditable()
  Number getItem(int index) native "SVGNumberList_getItem_Callback";

  @DomName('SVGNumberList.initialize')
  @DocsEditable()
  Number initialize(Number item) native "SVGNumberList_initialize_Callback";

  @DomName('SVGNumberList.insertItemBefore')
  @DocsEditable()
  Number insertItemBefore(Number item, int index) native "SVGNumberList_insertItemBefore_Callback";

  @DomName('SVGNumberList.removeItem')
  @DocsEditable()
  Number removeItem(int index) native "SVGNumberList_removeItem_Callback";

  @DomName('SVGNumberList.replaceItem')
  @DocsEditable()
  Number replaceItem(Number item, int index) native "SVGNumberList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathElement')
@Unstable()
class PathElement extends GraphicsElement implements ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory PathElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathElement.SVGPathElement')
  @DocsEditable()
  factory PathElement() => _SvgElementFactoryProvider.createSvgElement_tag("path");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  PathElement.created() : super.created();

  @DomName('SVGPathElement.animatedNormalizedPathSegList')
  @DocsEditable()
  PathSegList get animatedNormalizedPathSegList native "SVGPathElement_animatedNormalizedPathSegList_Getter";

  @DomName('SVGPathElement.animatedPathSegList')
  @DocsEditable()
  PathSegList get animatedPathSegList native "SVGPathElement_animatedPathSegList_Getter";

  @DomName('SVGPathElement.normalizedPathSegList')
  @DocsEditable()
  PathSegList get normalizedPathSegList native "SVGPathElement_normalizedPathSegList_Getter";

  @DomName('SVGPathElement.pathLength')
  @DocsEditable()
  AnimatedNumber get pathLength native "SVGPathElement_pathLength_Getter";

  @DomName('SVGPathElement.pathSegList')
  @DocsEditable()
  PathSegList get pathSegList native "SVGPathElement_pathSegList_Getter";

  @DomName('SVGPathElement.createSVGPathSegArcAbs')
  @DocsEditable()
  PathSegArcAbs createSvgPathSegArcAbs(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native "SVGPathElement_createSVGPathSegArcAbs_Callback";

  @DomName('SVGPathElement.createSVGPathSegArcRel')
  @DocsEditable()
  PathSegArcRel createSvgPathSegArcRel(num x, num y, num r1, num r2, num angle, bool largeArcFlag, bool sweepFlag) native "SVGPathElement_createSVGPathSegArcRel_Callback";

  @DomName('SVGPathElement.createSVGPathSegClosePath')
  @DocsEditable()
  PathSegClosePath createSvgPathSegClosePath() native "SVGPathElement_createSVGPathSegClosePath_Callback";

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicAbs')
  @DocsEditable()
  PathSegCurvetoCubicAbs createSvgPathSegCurvetoCubicAbs(num x, num y, num x1, num y1, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicAbs_Callback";

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicRel')
  @DocsEditable()
  PathSegCurvetoCubicRel createSvgPathSegCurvetoCubicRel(num x, num y, num x1, num y1, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicRel_Callback";

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothAbs')
  @DocsEditable()
  PathSegCurvetoCubicSmoothAbs createSvgPathSegCurvetoCubicSmoothAbs(num x, num y, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicSmoothAbs_Callback";

  @DomName('SVGPathElement.createSVGPathSegCurvetoCubicSmoothRel')
  @DocsEditable()
  PathSegCurvetoCubicSmoothRel createSvgPathSegCurvetoCubicSmoothRel(num x, num y, num x2, num y2) native "SVGPathElement_createSVGPathSegCurvetoCubicSmoothRel_Callback";

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticAbs')
  @DocsEditable()
  PathSegCurvetoQuadraticAbs createSvgPathSegCurvetoQuadraticAbs(num x, num y, num x1, num y1) native "SVGPathElement_createSVGPathSegCurvetoQuadraticAbs_Callback";

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticRel')
  @DocsEditable()
  PathSegCurvetoQuadraticRel createSvgPathSegCurvetoQuadraticRel(num x, num y, num x1, num y1) native "SVGPathElement_createSVGPathSegCurvetoQuadraticRel_Callback";

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothAbs')
  @DocsEditable()
  PathSegCurvetoQuadraticSmoothAbs createSvgPathSegCurvetoQuadraticSmoothAbs(num x, num y) native "SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothAbs_Callback";

  @DomName('SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothRel')
  @DocsEditable()
  PathSegCurvetoQuadraticSmoothRel createSvgPathSegCurvetoQuadraticSmoothRel(num x, num y) native "SVGPathElement_createSVGPathSegCurvetoQuadraticSmoothRel_Callback";

  @DomName('SVGPathElement.createSVGPathSegLinetoAbs')
  @DocsEditable()
  PathSegLinetoAbs createSvgPathSegLinetoAbs(num x, num y) native "SVGPathElement_createSVGPathSegLinetoAbs_Callback";

  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalAbs')
  @DocsEditable()
  PathSegLinetoHorizontalAbs createSvgPathSegLinetoHorizontalAbs(num x) native "SVGPathElement_createSVGPathSegLinetoHorizontalAbs_Callback";

  @DomName('SVGPathElement.createSVGPathSegLinetoHorizontalRel')
  @DocsEditable()
  PathSegLinetoHorizontalRel createSvgPathSegLinetoHorizontalRel(num x) native "SVGPathElement_createSVGPathSegLinetoHorizontalRel_Callback";

  @DomName('SVGPathElement.createSVGPathSegLinetoRel')
  @DocsEditable()
  PathSegLinetoRel createSvgPathSegLinetoRel(num x, num y) native "SVGPathElement_createSVGPathSegLinetoRel_Callback";

  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalAbs')
  @DocsEditable()
  PathSegLinetoVerticalAbs createSvgPathSegLinetoVerticalAbs(num y) native "SVGPathElement_createSVGPathSegLinetoVerticalAbs_Callback";

  @DomName('SVGPathElement.createSVGPathSegLinetoVerticalRel')
  @DocsEditable()
  PathSegLinetoVerticalRel createSvgPathSegLinetoVerticalRel(num y) native "SVGPathElement_createSVGPathSegLinetoVerticalRel_Callback";

  @DomName('SVGPathElement.createSVGPathSegMovetoAbs')
  @DocsEditable()
  PathSegMovetoAbs createSvgPathSegMovetoAbs(num x, num y) native "SVGPathElement_createSVGPathSegMovetoAbs_Callback";

  @DomName('SVGPathElement.createSVGPathSegMovetoRel')
  @DocsEditable()
  PathSegMovetoRel createSvgPathSegMovetoRel(num x, num y) native "SVGPathElement_createSVGPathSegMovetoRel_Callback";

  @DomName('SVGPathElement.getPathSegAtLength')
  @DocsEditable()
  int getPathSegAtLength(num distance) native "SVGPathElement_getPathSegAtLength_Callback";

  @DomName('SVGPathElement.getPointAtLength')
  @DocsEditable()
  Point getPointAtLength(num distance) native "SVGPathElement_getPointAtLength_Callback";

  @DomName('SVGPathElement.getTotalLength')
  @DocsEditable()
  double getTotalLength() native "SVGPathElement_getTotalLength_Callback";

  @DomName('SVGPathElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGPathElement_externalResourcesRequired_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSeg')
@Unstable()
class PathSeg extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory PathSeg._() { throw new UnsupportedError("Not supported"); }

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
  int get pathSegType native "SVGPathSeg_pathSegType_Getter";

  @DomName('SVGPathSeg.pathSegTypeAsLetter')
  @DocsEditable()
  String get pathSegTypeAsLetter native "SVGPathSeg_pathSegTypeAsLetter_Getter";

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
  factory PathSegArcAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegArcAbs.angle')
  @DocsEditable()
  num get angle native "SVGPathSegArcAbs_angle_Getter";

  @DomName('SVGPathSegArcAbs.angle')
  @DocsEditable()
  void set angle(num value) native "SVGPathSegArcAbs_angle_Setter";

  @DomName('SVGPathSegArcAbs.largeArcFlag')
  @DocsEditable()
  bool get largeArcFlag native "SVGPathSegArcAbs_largeArcFlag_Getter";

  @DomName('SVGPathSegArcAbs.largeArcFlag')
  @DocsEditable()
  void set largeArcFlag(bool value) native "SVGPathSegArcAbs_largeArcFlag_Setter";

  @DomName('SVGPathSegArcAbs.r1')
  @DocsEditable()
  num get r1 native "SVGPathSegArcAbs_r1_Getter";

  @DomName('SVGPathSegArcAbs.r1')
  @DocsEditable()
  void set r1(num value) native "SVGPathSegArcAbs_r1_Setter";

  @DomName('SVGPathSegArcAbs.r2')
  @DocsEditable()
  num get r2 native "SVGPathSegArcAbs_r2_Getter";

  @DomName('SVGPathSegArcAbs.r2')
  @DocsEditable()
  void set r2(num value) native "SVGPathSegArcAbs_r2_Setter";

  @DomName('SVGPathSegArcAbs.sweepFlag')
  @DocsEditable()
  bool get sweepFlag native "SVGPathSegArcAbs_sweepFlag_Getter";

  @DomName('SVGPathSegArcAbs.sweepFlag')
  @DocsEditable()
  void set sweepFlag(bool value) native "SVGPathSegArcAbs_sweepFlag_Setter";

  @DomName('SVGPathSegArcAbs.x')
  @DocsEditable()
  num get x native "SVGPathSegArcAbs_x_Getter";

  @DomName('SVGPathSegArcAbs.x')
  @DocsEditable()
  void set x(num value) native "SVGPathSegArcAbs_x_Setter";

  @DomName('SVGPathSegArcAbs.y')
  @DocsEditable()
  num get y native "SVGPathSegArcAbs_y_Getter";

  @DomName('SVGPathSegArcAbs.y')
  @DocsEditable()
  void set y(num value) native "SVGPathSegArcAbs_y_Setter";

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
  factory PathSegArcRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegArcRel.angle')
  @DocsEditable()
  num get angle native "SVGPathSegArcRel_angle_Getter";

  @DomName('SVGPathSegArcRel.angle')
  @DocsEditable()
  void set angle(num value) native "SVGPathSegArcRel_angle_Setter";

  @DomName('SVGPathSegArcRel.largeArcFlag')
  @DocsEditable()
  bool get largeArcFlag native "SVGPathSegArcRel_largeArcFlag_Getter";

  @DomName('SVGPathSegArcRel.largeArcFlag')
  @DocsEditable()
  void set largeArcFlag(bool value) native "SVGPathSegArcRel_largeArcFlag_Setter";

  @DomName('SVGPathSegArcRel.r1')
  @DocsEditable()
  num get r1 native "SVGPathSegArcRel_r1_Getter";

  @DomName('SVGPathSegArcRel.r1')
  @DocsEditable()
  void set r1(num value) native "SVGPathSegArcRel_r1_Setter";

  @DomName('SVGPathSegArcRel.r2')
  @DocsEditable()
  num get r2 native "SVGPathSegArcRel_r2_Getter";

  @DomName('SVGPathSegArcRel.r2')
  @DocsEditable()
  void set r2(num value) native "SVGPathSegArcRel_r2_Setter";

  @DomName('SVGPathSegArcRel.sweepFlag')
  @DocsEditable()
  bool get sweepFlag native "SVGPathSegArcRel_sweepFlag_Getter";

  @DomName('SVGPathSegArcRel.sweepFlag')
  @DocsEditable()
  void set sweepFlag(bool value) native "SVGPathSegArcRel_sweepFlag_Setter";

  @DomName('SVGPathSegArcRel.x')
  @DocsEditable()
  num get x native "SVGPathSegArcRel_x_Getter";

  @DomName('SVGPathSegArcRel.x')
  @DocsEditable()
  void set x(num value) native "SVGPathSegArcRel_x_Setter";

  @DomName('SVGPathSegArcRel.y')
  @DocsEditable()
  num get y native "SVGPathSegArcRel_y_Getter";

  @DomName('SVGPathSegArcRel.y')
  @DocsEditable()
  void set y(num value) native "SVGPathSegArcRel_y_Setter";

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
  factory PathSegClosePath._() { throw new UnsupportedError("Not supported"); }

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
  factory PathSegCurvetoCubicAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoCubicAbs.x')
  @DocsEditable()
  num get x native "SVGPathSegCurvetoCubicAbs_x_Getter";

  @DomName('SVGPathSegCurvetoCubicAbs.x')
  @DocsEditable()
  void set x(num value) native "SVGPathSegCurvetoCubicAbs_x_Setter";

  @DomName('SVGPathSegCurvetoCubicAbs.x1')
  @DocsEditable()
  num get x1 native "SVGPathSegCurvetoCubicAbs_x1_Getter";

  @DomName('SVGPathSegCurvetoCubicAbs.x1')
  @DocsEditable()
  void set x1(num value) native "SVGPathSegCurvetoCubicAbs_x1_Setter";

  @DomName('SVGPathSegCurvetoCubicAbs.x2')
  @DocsEditable()
  num get x2 native "SVGPathSegCurvetoCubicAbs_x2_Getter";

  @DomName('SVGPathSegCurvetoCubicAbs.x2')
  @DocsEditable()
  void set x2(num value) native "SVGPathSegCurvetoCubicAbs_x2_Setter";

  @DomName('SVGPathSegCurvetoCubicAbs.y')
  @DocsEditable()
  num get y native "SVGPathSegCurvetoCubicAbs_y_Getter";

  @DomName('SVGPathSegCurvetoCubicAbs.y')
  @DocsEditable()
  void set y(num value) native "SVGPathSegCurvetoCubicAbs_y_Setter";

  @DomName('SVGPathSegCurvetoCubicAbs.y1')
  @DocsEditable()
  num get y1 native "SVGPathSegCurvetoCubicAbs_y1_Getter";

  @DomName('SVGPathSegCurvetoCubicAbs.y1')
  @DocsEditable()
  void set y1(num value) native "SVGPathSegCurvetoCubicAbs_y1_Setter";

  @DomName('SVGPathSegCurvetoCubicAbs.y2')
  @DocsEditable()
  num get y2 native "SVGPathSegCurvetoCubicAbs_y2_Getter";

  @DomName('SVGPathSegCurvetoCubicAbs.y2')
  @DocsEditable()
  void set y2(num value) native "SVGPathSegCurvetoCubicAbs_y2_Setter";

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
  factory PathSegCurvetoCubicRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoCubicRel.x')
  @DocsEditable()
  num get x native "SVGPathSegCurvetoCubicRel_x_Getter";

  @DomName('SVGPathSegCurvetoCubicRel.x')
  @DocsEditable()
  void set x(num value) native "SVGPathSegCurvetoCubicRel_x_Setter";

  @DomName('SVGPathSegCurvetoCubicRel.x1')
  @DocsEditable()
  num get x1 native "SVGPathSegCurvetoCubicRel_x1_Getter";

  @DomName('SVGPathSegCurvetoCubicRel.x1')
  @DocsEditable()
  void set x1(num value) native "SVGPathSegCurvetoCubicRel_x1_Setter";

  @DomName('SVGPathSegCurvetoCubicRel.x2')
  @DocsEditable()
  num get x2 native "SVGPathSegCurvetoCubicRel_x2_Getter";

  @DomName('SVGPathSegCurvetoCubicRel.x2')
  @DocsEditable()
  void set x2(num value) native "SVGPathSegCurvetoCubicRel_x2_Setter";

  @DomName('SVGPathSegCurvetoCubicRel.y')
  @DocsEditable()
  num get y native "SVGPathSegCurvetoCubicRel_y_Getter";

  @DomName('SVGPathSegCurvetoCubicRel.y')
  @DocsEditable()
  void set y(num value) native "SVGPathSegCurvetoCubicRel_y_Setter";

  @DomName('SVGPathSegCurvetoCubicRel.y1')
  @DocsEditable()
  num get y1 native "SVGPathSegCurvetoCubicRel_y1_Getter";

  @DomName('SVGPathSegCurvetoCubicRel.y1')
  @DocsEditable()
  void set y1(num value) native "SVGPathSegCurvetoCubicRel_y1_Setter";

  @DomName('SVGPathSegCurvetoCubicRel.y2')
  @DocsEditable()
  num get y2 native "SVGPathSegCurvetoCubicRel_y2_Getter";

  @DomName('SVGPathSegCurvetoCubicRel.y2')
  @DocsEditable()
  void set y2(num value) native "SVGPathSegCurvetoCubicRel_y2_Setter";

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
  factory PathSegCurvetoCubicSmoothAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x')
  @DocsEditable()
  num get x native "SVGPathSegCurvetoCubicSmoothAbs_x_Getter";

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x')
  @DocsEditable()
  void set x(num value) native "SVGPathSegCurvetoCubicSmoothAbs_x_Setter";

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x2')
  @DocsEditable()
  num get x2 native "SVGPathSegCurvetoCubicSmoothAbs_x2_Getter";

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.x2')
  @DocsEditable()
  void set x2(num value) native "SVGPathSegCurvetoCubicSmoothAbs_x2_Setter";

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y')
  @DocsEditable()
  num get y native "SVGPathSegCurvetoCubicSmoothAbs_y_Getter";

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y')
  @DocsEditable()
  void set y(num value) native "SVGPathSegCurvetoCubicSmoothAbs_y_Setter";

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y2')
  @DocsEditable()
  num get y2 native "SVGPathSegCurvetoCubicSmoothAbs_y2_Getter";

  @DomName('SVGPathSegCurvetoCubicSmoothAbs.y2')
  @DocsEditable()
  void set y2(num value) native "SVGPathSegCurvetoCubicSmoothAbs_y2_Setter";

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
  factory PathSegCurvetoCubicSmoothRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x')
  @DocsEditable()
  num get x native "SVGPathSegCurvetoCubicSmoothRel_x_Getter";

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x')
  @DocsEditable()
  void set x(num value) native "SVGPathSegCurvetoCubicSmoothRel_x_Setter";

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x2')
  @DocsEditable()
  num get x2 native "SVGPathSegCurvetoCubicSmoothRel_x2_Getter";

  @DomName('SVGPathSegCurvetoCubicSmoothRel.x2')
  @DocsEditable()
  void set x2(num value) native "SVGPathSegCurvetoCubicSmoothRel_x2_Setter";

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y')
  @DocsEditable()
  num get y native "SVGPathSegCurvetoCubicSmoothRel_y_Getter";

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y')
  @DocsEditable()
  void set y(num value) native "SVGPathSegCurvetoCubicSmoothRel_y_Setter";

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y2')
  @DocsEditable()
  num get y2 native "SVGPathSegCurvetoCubicSmoothRel_y2_Getter";

  @DomName('SVGPathSegCurvetoCubicSmoothRel.y2')
  @DocsEditable()
  void set y2(num value) native "SVGPathSegCurvetoCubicSmoothRel_y2_Setter";

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
  factory PathSegCurvetoQuadraticAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoQuadraticAbs.x')
  @DocsEditable()
  num get x native "SVGPathSegCurvetoQuadraticAbs_x_Getter";

  @DomName('SVGPathSegCurvetoQuadraticAbs.x')
  @DocsEditable()
  void set x(num value) native "SVGPathSegCurvetoQuadraticAbs_x_Setter";

  @DomName('SVGPathSegCurvetoQuadraticAbs.x1')
  @DocsEditable()
  num get x1 native "SVGPathSegCurvetoQuadraticAbs_x1_Getter";

  @DomName('SVGPathSegCurvetoQuadraticAbs.x1')
  @DocsEditable()
  void set x1(num value) native "SVGPathSegCurvetoQuadraticAbs_x1_Setter";

  @DomName('SVGPathSegCurvetoQuadraticAbs.y')
  @DocsEditable()
  num get y native "SVGPathSegCurvetoQuadraticAbs_y_Getter";

  @DomName('SVGPathSegCurvetoQuadraticAbs.y')
  @DocsEditable()
  void set y(num value) native "SVGPathSegCurvetoQuadraticAbs_y_Setter";

  @DomName('SVGPathSegCurvetoQuadraticAbs.y1')
  @DocsEditable()
  num get y1 native "SVGPathSegCurvetoQuadraticAbs_y1_Getter";

  @DomName('SVGPathSegCurvetoQuadraticAbs.y1')
  @DocsEditable()
  void set y1(num value) native "SVGPathSegCurvetoQuadraticAbs_y1_Setter";

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
  factory PathSegCurvetoQuadraticRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoQuadraticRel.x')
  @DocsEditable()
  num get x native "SVGPathSegCurvetoQuadraticRel_x_Getter";

  @DomName('SVGPathSegCurvetoQuadraticRel.x')
  @DocsEditable()
  void set x(num value) native "SVGPathSegCurvetoQuadraticRel_x_Setter";

  @DomName('SVGPathSegCurvetoQuadraticRel.x1')
  @DocsEditable()
  num get x1 native "SVGPathSegCurvetoQuadraticRel_x1_Getter";

  @DomName('SVGPathSegCurvetoQuadraticRel.x1')
  @DocsEditable()
  void set x1(num value) native "SVGPathSegCurvetoQuadraticRel_x1_Setter";

  @DomName('SVGPathSegCurvetoQuadraticRel.y')
  @DocsEditable()
  num get y native "SVGPathSegCurvetoQuadraticRel_y_Getter";

  @DomName('SVGPathSegCurvetoQuadraticRel.y')
  @DocsEditable()
  void set y(num value) native "SVGPathSegCurvetoQuadraticRel_y_Setter";

  @DomName('SVGPathSegCurvetoQuadraticRel.y1')
  @DocsEditable()
  num get y1 native "SVGPathSegCurvetoQuadraticRel_y1_Getter";

  @DomName('SVGPathSegCurvetoQuadraticRel.y1')
  @DocsEditable()
  void set y1(num value) native "SVGPathSegCurvetoQuadraticRel_y1_Setter";

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
  factory PathSegCurvetoQuadraticSmoothAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.x')
  @DocsEditable()
  num get x native "SVGPathSegCurvetoQuadraticSmoothAbs_x_Getter";

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.x')
  @DocsEditable()
  void set x(num value) native "SVGPathSegCurvetoQuadraticSmoothAbs_x_Setter";

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.y')
  @DocsEditable()
  num get y native "SVGPathSegCurvetoQuadraticSmoothAbs_y_Getter";

  @DomName('SVGPathSegCurvetoQuadraticSmoothAbs.y')
  @DocsEditable()
  void set y(num value) native "SVGPathSegCurvetoQuadraticSmoothAbs_y_Setter";

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
  factory PathSegCurvetoQuadraticSmoothRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.x')
  @DocsEditable()
  num get x native "SVGPathSegCurvetoQuadraticSmoothRel_x_Getter";

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.x')
  @DocsEditable()
  void set x(num value) native "SVGPathSegCurvetoQuadraticSmoothRel_x_Setter";

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.y')
  @DocsEditable()
  num get y native "SVGPathSegCurvetoQuadraticSmoothRel_y_Getter";

  @DomName('SVGPathSegCurvetoQuadraticSmoothRel.y')
  @DocsEditable()
  void set y(num value) native "SVGPathSegCurvetoQuadraticSmoothRel_y_Setter";

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
  factory PathSegLinetoAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoAbs.x')
  @DocsEditable()
  num get x native "SVGPathSegLinetoAbs_x_Getter";

  @DomName('SVGPathSegLinetoAbs.x')
  @DocsEditable()
  void set x(num value) native "SVGPathSegLinetoAbs_x_Setter";

  @DomName('SVGPathSegLinetoAbs.y')
  @DocsEditable()
  num get y native "SVGPathSegLinetoAbs_y_Getter";

  @DomName('SVGPathSegLinetoAbs.y')
  @DocsEditable()
  void set y(num value) native "SVGPathSegLinetoAbs_y_Setter";

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
  factory PathSegLinetoHorizontalAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoHorizontalAbs.x')
  @DocsEditable()
  num get x native "SVGPathSegLinetoHorizontalAbs_x_Getter";

  @DomName('SVGPathSegLinetoHorizontalAbs.x')
  @DocsEditable()
  void set x(num value) native "SVGPathSegLinetoHorizontalAbs_x_Setter";

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
  factory PathSegLinetoHorizontalRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoHorizontalRel.x')
  @DocsEditable()
  num get x native "SVGPathSegLinetoHorizontalRel_x_Getter";

  @DomName('SVGPathSegLinetoHorizontalRel.x')
  @DocsEditable()
  void set x(num value) native "SVGPathSegLinetoHorizontalRel_x_Setter";

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
  factory PathSegLinetoRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoRel.x')
  @DocsEditable()
  num get x native "SVGPathSegLinetoRel_x_Getter";

  @DomName('SVGPathSegLinetoRel.x')
  @DocsEditable()
  void set x(num value) native "SVGPathSegLinetoRel_x_Setter";

  @DomName('SVGPathSegLinetoRel.y')
  @DocsEditable()
  num get y native "SVGPathSegLinetoRel_y_Getter";

  @DomName('SVGPathSegLinetoRel.y')
  @DocsEditable()
  void set y(num value) native "SVGPathSegLinetoRel_y_Setter";

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
  factory PathSegLinetoVerticalAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoVerticalAbs.y')
  @DocsEditable()
  num get y native "SVGPathSegLinetoVerticalAbs_y_Getter";

  @DomName('SVGPathSegLinetoVerticalAbs.y')
  @DocsEditable()
  void set y(num value) native "SVGPathSegLinetoVerticalAbs_y_Setter";

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
  factory PathSegLinetoVerticalRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegLinetoVerticalRel.y')
  @DocsEditable()
  num get y native "SVGPathSegLinetoVerticalRel_y_Getter";

  @DomName('SVGPathSegLinetoVerticalRel.y')
  @DocsEditable()
  void set y(num value) native "SVGPathSegLinetoVerticalRel_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPathSegList')
@Unstable()
class PathSegList extends NativeFieldWrapperClass2 with ListMixin<PathSeg>, ImmutableListMixin<PathSeg> implements List<PathSeg> {
  // To suppress missing implicit constructor warnings.
  factory PathSegList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegList.numberOfItems')
  @DocsEditable()
  int get numberOfItems native "SVGPathSegList_numberOfItems_Getter";

  PathSeg operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.range(index, 0, length);
    return getItem(index);
  }

  void operator[]=(int index, PathSeg value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<PathSeg> mixins.
  // PathSeg is the element type.

  // SVG Collections expose numberOfItems rather than length.
  int get length => numberOfItems;

  void set length(int value) {
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

  @DomName('SVGPathSegList.appendItem')
  @DocsEditable()
  PathSeg appendItem(PathSeg newItem) native "SVGPathSegList_appendItem_Callback";

  @DomName('SVGPathSegList.clear')
  @DocsEditable()
  void clear() native "SVGPathSegList_clear_Callback";

  @DomName('SVGPathSegList.getItem')
  @DocsEditable()
  PathSeg getItem(int index) native "SVGPathSegList_getItem_Callback";

  @DomName('SVGPathSegList.initialize')
  @DocsEditable()
  PathSeg initialize(PathSeg newItem) native "SVGPathSegList_initialize_Callback";

  @DomName('SVGPathSegList.insertItemBefore')
  @DocsEditable()
  PathSeg insertItemBefore(PathSeg newItem, int index) native "SVGPathSegList_insertItemBefore_Callback";

  @DomName('SVGPathSegList.removeItem')
  @DocsEditable()
  PathSeg removeItem(int index) native "SVGPathSegList_removeItem_Callback";

  @DomName('SVGPathSegList.replaceItem')
  @DocsEditable()
  PathSeg replaceItem(PathSeg newItem, int index) native "SVGPathSegList_replaceItem_Callback";

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
  factory PathSegMovetoAbs._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegMovetoAbs.x')
  @DocsEditable()
  num get x native "SVGPathSegMovetoAbs_x_Getter";

  @DomName('SVGPathSegMovetoAbs.x')
  @DocsEditable()
  void set x(num value) native "SVGPathSegMovetoAbs_x_Setter";

  @DomName('SVGPathSegMovetoAbs.y')
  @DocsEditable()
  num get y native "SVGPathSegMovetoAbs_y_Getter";

  @DomName('SVGPathSegMovetoAbs.y')
  @DocsEditable()
  void set y(num value) native "SVGPathSegMovetoAbs_y_Setter";

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
  factory PathSegMovetoRel._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPathSegMovetoRel.x')
  @DocsEditable()
  num get x native "SVGPathSegMovetoRel_x_Getter";

  @DomName('SVGPathSegMovetoRel.x')
  @DocsEditable()
  void set x(num value) native "SVGPathSegMovetoRel_x_Setter";

  @DomName('SVGPathSegMovetoRel.y')
  @DocsEditable()
  num get y native "SVGPathSegMovetoRel_y_Getter";

  @DomName('SVGPathSegMovetoRel.y')
  @DocsEditable()
  void set y(num value) native "SVGPathSegMovetoRel_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPatternElement')
@Unstable()
class PatternElement extends SvgElement implements FitToViewBox, UriReference, ExternalResourcesRequired, Tests {
  // To suppress missing implicit constructor warnings.
  factory PatternElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPatternElement.SVGPatternElement')
  @DocsEditable()
  factory PatternElement() => _SvgElementFactoryProvider.createSvgElement_tag("pattern");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  PatternElement.created() : super.created();

  @DomName('SVGPatternElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGPatternElement_height_Getter";

  @DomName('SVGPatternElement.patternContentUnits')
  @DocsEditable()
  AnimatedEnumeration get patternContentUnits native "SVGPatternElement_patternContentUnits_Getter";

  @DomName('SVGPatternElement.patternTransform')
  @DocsEditable()
  AnimatedTransformList get patternTransform native "SVGPatternElement_patternTransform_Getter";

  @DomName('SVGPatternElement.patternUnits')
  @DocsEditable()
  AnimatedEnumeration get patternUnits native "SVGPatternElement_patternUnits_Getter";

  @DomName('SVGPatternElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGPatternElement_width_Getter";

  @DomName('SVGPatternElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGPatternElement_x_Getter";

  @DomName('SVGPatternElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGPatternElement_y_Getter";

  @DomName('SVGPatternElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGPatternElement_externalResourcesRequired_Getter";

  @DomName('SVGPatternElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGPatternElement_preserveAspectRatio_Getter";

  @DomName('SVGPatternElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox native "SVGPatternElement_viewBox_Getter";

  @DomName('SVGPatternElement.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions native "SVGPatternElement_requiredExtensions_Getter";

  @DomName('SVGPatternElement.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures native "SVGPatternElement_requiredFeatures_Getter";

  @DomName('SVGPatternElement.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage native "SVGPatternElement_systemLanguage_Getter";

  @DomName('SVGPatternElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) native "SVGPatternElement_hasExtension_Callback";

  @DomName('SVGPatternElement.href')
  @DocsEditable()
  AnimatedString get href native "SVGPatternElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPoint')
@Unstable()
class Point extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Point._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPoint.x')
  @DocsEditable()
  num get x native "SVGPoint_x_Getter";

  @DomName('SVGPoint.x')
  @DocsEditable()
  void set x(num value) native "SVGPoint_x_Setter";

  @DomName('SVGPoint.y')
  @DocsEditable()
  num get y native "SVGPoint_y_Getter";

  @DomName('SVGPoint.y')
  @DocsEditable()
  void set y(num value) native "SVGPoint_y_Setter";

  @DomName('SVGPoint.matrixTransform')
  @DocsEditable()
  Point matrixTransform(Matrix matrix) native "SVGPoint_matrixTransform_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPointList')
@Unstable()
class PointList extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory PointList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPointList.numberOfItems')
  @DocsEditable()
  int get numberOfItems native "SVGPointList_numberOfItems_Getter";

  @DomName('SVGPointList.appendItem')
  @DocsEditable()
  Point appendItem(Point item) native "SVGPointList_appendItem_Callback";

  @DomName('SVGPointList.clear')
  @DocsEditable()
  void clear() native "SVGPointList_clear_Callback";

  @DomName('SVGPointList.getItem')
  @DocsEditable()
  Point getItem(int index) native "SVGPointList_getItem_Callback";

  @DomName('SVGPointList.initialize')
  @DocsEditable()
  Point initialize(Point item) native "SVGPointList_initialize_Callback";

  @DomName('SVGPointList.insertItemBefore')
  @DocsEditable()
  Point insertItemBefore(Point item, int index) native "SVGPointList_insertItemBefore_Callback";

  @DomName('SVGPointList.removeItem')
  @DocsEditable()
  Point removeItem(int index) native "SVGPointList_removeItem_Callback";

  @DomName('SVGPointList.replaceItem')
  @DocsEditable()
  Point replaceItem(Point item, int index) native "SVGPointList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPolygonElement')
@Unstable()
class PolygonElement extends GraphicsElement implements ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory PolygonElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPolygonElement.SVGPolygonElement')
  @DocsEditable()
  factory PolygonElement() => _SvgElementFactoryProvider.createSvgElement_tag("polygon");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  PolygonElement.created() : super.created();

  @DomName('SVGPolygonElement.animatedPoints')
  @DocsEditable()
  PointList get animatedPoints native "SVGPolygonElement_animatedPoints_Getter";

  @DomName('SVGPolygonElement.points')
  @DocsEditable()
  PointList get points native "SVGPolygonElement_points_Getter";

  @DomName('SVGPolygonElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGPolygonElement_externalResourcesRequired_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPolylineElement')
@Unstable()
class PolylineElement extends GraphicsElement implements ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory PolylineElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGPolylineElement.SVGPolylineElement')
  @DocsEditable()
  factory PolylineElement() => _SvgElementFactoryProvider.createSvgElement_tag("polyline");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  PolylineElement.created() : super.created();

  @DomName('SVGPolylineElement.animatedPoints')
  @DocsEditable()
  PointList get animatedPoints native "SVGPolylineElement_animatedPoints_Getter";

  @DomName('SVGPolylineElement.points')
  @DocsEditable()
  PointList get points native "SVGPolylineElement_points_Getter";

  @DomName('SVGPolylineElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGPolylineElement_externalResourcesRequired_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPreserveAspectRatio')
@Unstable()
class PreserveAspectRatio extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory PreserveAspectRatio._() { throw new UnsupportedError("Not supported"); }

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
  int get align native "SVGPreserveAspectRatio_align_Getter";

  @DomName('SVGPreserveAspectRatio.align')
  @DocsEditable()
  void set align(int value) native "SVGPreserveAspectRatio_align_Setter";

  @DomName('SVGPreserveAspectRatio.meetOrSlice')
  @DocsEditable()
  int get meetOrSlice native "SVGPreserveAspectRatio_meetOrSlice_Getter";

  @DomName('SVGPreserveAspectRatio.meetOrSlice')
  @DocsEditable()
  void set meetOrSlice(int value) native "SVGPreserveAspectRatio_meetOrSlice_Setter";

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
  factory RadialGradientElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGRadialGradientElement.SVGRadialGradientElement')
  @DocsEditable()
  factory RadialGradientElement() => _SvgElementFactoryProvider.createSvgElement_tag("radialGradient");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  RadialGradientElement.created() : super.created();

  @DomName('SVGRadialGradientElement.cx')
  @DocsEditable()
  AnimatedLength get cx native "SVGRadialGradientElement_cx_Getter";

  @DomName('SVGRadialGradientElement.cy')
  @DocsEditable()
  AnimatedLength get cy native "SVGRadialGradientElement_cy_Getter";

  @DomName('SVGRadialGradientElement.fr')
  @DocsEditable()
  AnimatedLength get fr native "SVGRadialGradientElement_fr_Getter";

  @DomName('SVGRadialGradientElement.fx')
  @DocsEditable()
  AnimatedLength get fx native "SVGRadialGradientElement_fx_Getter";

  @DomName('SVGRadialGradientElement.fy')
  @DocsEditable()
  AnimatedLength get fy native "SVGRadialGradientElement_fy_Getter";

  @DomName('SVGRadialGradientElement.r')
  @DocsEditable()
  AnimatedLength get r native "SVGRadialGradientElement_r_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGRect')
@Unstable()
class Rect extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Rect._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGRect.height')
  @DocsEditable()
  num get height native "SVGRect_height_Getter";

  @DomName('SVGRect.height')
  @DocsEditable()
  void set height(num value) native "SVGRect_height_Setter";

  @DomName('SVGRect.width')
  @DocsEditable()
  num get width native "SVGRect_width_Getter";

  @DomName('SVGRect.width')
  @DocsEditable()
  void set width(num value) native "SVGRect_width_Setter";

  @DomName('SVGRect.x')
  @DocsEditable()
  num get x native "SVGRect_x_Getter";

  @DomName('SVGRect.x')
  @DocsEditable()
  void set x(num value) native "SVGRect_x_Setter";

  @DomName('SVGRect.y')
  @DocsEditable()
  num get y native "SVGRect_y_Getter";

  @DomName('SVGRect.y')
  @DocsEditable()
  void set y(num value) native "SVGRect_y_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGRectElement')
@Unstable()
class RectElement extends GraphicsElement implements ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory RectElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGRectElement.SVGRectElement')
  @DocsEditable()
  factory RectElement() => _SvgElementFactoryProvider.createSvgElement_tag("rect");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  RectElement.created() : super.created();

  @DomName('SVGRectElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGRectElement_height_Getter";

  @DomName('SVGRectElement.rx')
  @DocsEditable()
  AnimatedLength get rx native "SVGRectElement_rx_Getter";

  @DomName('SVGRectElement.ry')
  @DocsEditable()
  AnimatedLength get ry native "SVGRectElement_ry_Getter";

  @DomName('SVGRectElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGRectElement_width_Getter";

  @DomName('SVGRectElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGRectElement_x_Getter";

  @DomName('SVGRectElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGRectElement_y_Getter";

  @DomName('SVGRectElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGRectElement_externalResourcesRequired_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGRenderingIntent')
@Unstable()
class RenderingIntent extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory RenderingIntent._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGRenderingIntent.RENDERING_INTENT_ABSOLUTE_COLORIMETRIC')
  @DocsEditable()
  static const int RENDERING_INTENT_ABSOLUTE_COLORIMETRIC = 5;

  @DomName('SVGRenderingIntent.RENDERING_INTENT_AUTO')
  @DocsEditable()
  static const int RENDERING_INTENT_AUTO = 1;

  @DomName('SVGRenderingIntent.RENDERING_INTENT_PERCEPTUAL')
  @DocsEditable()
  static const int RENDERING_INTENT_PERCEPTUAL = 2;

  @DomName('SVGRenderingIntent.RENDERING_INTENT_RELATIVE_COLORIMETRIC')
  @DocsEditable()
  static const int RENDERING_INTENT_RELATIVE_COLORIMETRIC = 3;

  @DomName('SVGRenderingIntent.RENDERING_INTENT_SATURATION')
  @DocsEditable()
  static const int RENDERING_INTENT_SATURATION = 4;

  @DomName('SVGRenderingIntent.RENDERING_INTENT_UNKNOWN')
  @DocsEditable()
  static const int RENDERING_INTENT_UNKNOWN = 0;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGScriptElement')
@Unstable()
class ScriptElement extends SvgElement implements UriReference, ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory ScriptElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGScriptElement.SVGScriptElement')
  @DocsEditable()
  factory ScriptElement() => _SvgElementFactoryProvider.createSvgElement_tag("script");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  ScriptElement.created() : super.created();

  @DomName('SVGScriptElement.type')
  @DocsEditable()
  String get type native "SVGScriptElement_type_Getter";

  @DomName('SVGScriptElement.type')
  @DocsEditable()
  void set type(String value) native "SVGScriptElement_type_Setter";

  @DomName('SVGScriptElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGScriptElement_externalResourcesRequired_Getter";

  @DomName('SVGScriptElement.href')
  @DocsEditable()
  AnimatedString get href native "SVGScriptElement_href_Getter";

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
  factory SetElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGSetElement.SVGSetElement')
  @DocsEditable()
  factory SetElement() => _SvgElementFactoryProvider.createSvgElement_tag("set");
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
  factory StopElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGStopElement.SVGStopElement')
  @DocsEditable()
  factory StopElement() => _SvgElementFactoryProvider.createSvgElement_tag("stop");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  StopElement.created() : super.created();

  @DomName('SVGStopElement.offset')
  @DocsEditable()
  AnimatedNumber get gradientOffset native "SVGStopElement_offset_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGStringList')
@Unstable()
class StringList extends NativeFieldWrapperClass2 with ListMixin<String>, ImmutableListMixin<String> implements List<String> {
  // To suppress missing implicit constructor warnings.
  factory StringList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGStringList.numberOfItems')
  @DocsEditable()
  int get numberOfItems native "SVGStringList_numberOfItems_Getter";

  String operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.range(index, 0, length);
    return getItem(index);
  }

  void operator[]=(int index, String value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<String> mixins.
  // String is the element type.

  // SVG Collections expose numberOfItems rather than length.
  int get length => numberOfItems;

  void set length(int value) {
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

  @DomName('SVGStringList.appendItem')
  @DocsEditable()
  String appendItem(String item) native "SVGStringList_appendItem_Callback";

  @DomName('SVGStringList.clear')
  @DocsEditable()
  void clear() native "SVGStringList_clear_Callback";

  @DomName('SVGStringList.getItem')
  @DocsEditable()
  String getItem(int index) native "SVGStringList_getItem_Callback";

  @DomName('SVGStringList.initialize')
  @DocsEditable()
  String initialize(String item) native "SVGStringList_initialize_Callback";

  @DomName('SVGStringList.insertItemBefore')
  @DocsEditable()
  String insertItemBefore(String item, int index) native "SVGStringList_insertItemBefore_Callback";

  @DomName('SVGStringList.removeItem')
  @DocsEditable()
  String removeItem(int index) native "SVGStringList_removeItem_Callback";

  @DomName('SVGStringList.replaceItem')
  @DocsEditable()
  String replaceItem(String item, int index) native "SVGStringList_replaceItem_Callback";

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
  factory StyleElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGStyleElement.SVGStyleElement')
  @DocsEditable()
  factory StyleElement() => _SvgElementFactoryProvider.createSvgElement_tag("style");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  StyleElement.created() : super.created();

  @DomName('SVGStyleElement.disabled')
  @DocsEditable()
  bool get disabled native "SVGStyleElement_disabled_Getter";

  @DomName('SVGStyleElement.disabled')
  @DocsEditable()
  void set disabled(bool value) native "SVGStyleElement_disabled_Setter";

  @DomName('SVGStyleElement.media')
  @DocsEditable()
  String get media native "SVGStyleElement_media_Getter";

  @DomName('SVGStyleElement.media')
  @DocsEditable()
  void set media(String value) native "SVGStyleElement_media_Setter";

  @DomName('SVGStyleElement.title')
  @DocsEditable()
  String get title native "SVGStyleElement_title_Getter";

  @DomName('SVGStyleElement.title')
  @DocsEditable()
  void set title(String value) native "SVGStyleElement_title_Setter";

  @DomName('SVGStyleElement.type')
  @DocsEditable()
  String get type native "SVGStyleElement_type_Getter";

  @DomName('SVGStyleElement.type')
  @DocsEditable()
  void set type(String value) native "SVGStyleElement_type_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGDocument')
@Unstable()
class SvgDocument extends Document {
  // To suppress missing implicit constructor warnings.
  factory SvgDocument._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGDocument.rootElement')
  @DocsEditable()
  SvgSvgElement get rootElement native "SVGDocument_rootElement_Getter";

  @DomName('SVGDocument.createEvent')
  @DocsEditable()
  Event _createEvent(String eventType) native "SVGDocument_createEvent_Callback";

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
class SvgElement extends Element {
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
    var fragment = parentElement.createFragment(svg, validator: validator,
        treeSanitizer: treeSanitizer);
    return fragment.nodes.where((e) => e is SvgElement).single;
  }

  _AttributeClassSet _cssClassSet;
  CssClassSet get classes {
    if (_cssClassSet == null) {
      _cssClassSet = new _AttributeClassSet(this);
    }
    return _cssClassSet;
  }

  List<Element> get children => new FilteredElementList<Element>(this);

  void set children(List<Element> value) {
    final children = this.children;
    children.clear();
    children.addAll(value);
  }

  String get outerHtml {
    final container = new Element.tag("div");
    final SvgElement cloned = this.clone(true);
    container.children.add(cloned);
    return container.innerHtml;
  }

  String get innerHtml {
    final container = new Element.tag("div");
    final SvgElement cloned = this.clone(true);
    container.children.addAll(cloned.children);
    return container.innerHtml;
  }

  void set innerHtml(String value) {
    this.setInnerHtml(value);
  }

  DocumentFragment createFragment(String svg,
      {NodeValidator validator, NodeTreeSanitizer treeSanitizer}) {

    if (treeSanitizer == null) {
      if (validator == null) {
        validator = new NodeValidatorBuilder.common()
          ..allowSvg();
      }
      treeSanitizer = new NodeTreeSanitizer(validator);
    }

    // We create a fragment which will parse in the HTML parser
    var html = '<svg version="1.1">$svg</svg>';
    var fragment = document.body.createFragment(html,
        treeSanitizer: treeSanitizer);

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
  void insertAdjacentHtml(String where, String text) {
    throw new UnsupportedError("Cannot invoke insertAdjacentHtml on SVG.");
  }

  @DomName('Element.insertAdjacentHTML')
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
  // To suppress missing implicit constructor warnings.
  factory SvgElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  SvgElement.created() : super.created();

  @DomName('SVGElement.className')
  @DocsEditable()
  @Experimental() // untriaged
  AnimatedString get _svgClassName native "SVGElement_className_Getter";

  @DomName('SVGElement.ownerSVGElement')
  @DocsEditable()
  SvgSvgElement get ownerSvgElement native "SVGElement_ownerSVGElement_Getter";

  @DomName('SVGElement.style')
  @DocsEditable()
  @Experimental() // untriaged
  CssStyleDeclaration get style native "SVGElement_style_Getter";

  @DomName('SVGElement.viewportElement')
  @DocsEditable()
  SvgElement get viewportElement native "SVGElement_viewportElement_Getter";

  @DomName('SVGElement.xmlbase')
  @DocsEditable()
  String get xmlbase native "SVGElement_xmlbase_Getter";

  @DomName('SVGElement.xmlbase')
  @DocsEditable()
  void set xmlbase(String value) native "SVGElement_xmlbase_Setter";

  @DomName('SVGElement.xmllang')
  @DocsEditable()
  @Experimental() // untriaged
  String get xmllang native "SVGElement_xmllang_Getter";

  @DomName('SVGElement.xmllang')
  @DocsEditable()
  @Experimental() // untriaged
  void set xmllang(String value) native "SVGElement_xmllang_Setter";

  @DomName('SVGElement.xmlspace')
  @DocsEditable()
  @Experimental() // untriaged
  String get xmlspace native "SVGElement_xmlspace_Getter";

  @DomName('SVGElement.xmlspace')
  @DocsEditable()
  @Experimental() // untriaged
  void set xmlspace(String value) native "SVGElement_xmlspace_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('SVGSVGElement')
@Unstable()
class SvgSvgElement extends GraphicsElement implements FitToViewBox, ExternalResourcesRequired, ZoomAndPan {
  factory SvgSvgElement() {
    final el = new SvgElement.tag("svg");
    // The SVG spec requires the version attribute to match the spec version
    el.attributes['version'] = "1.1";
    return el;
  }

  // To suppress missing implicit constructor warnings.
  factory SvgSvgElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  SvgSvgElement.created() : super.created();

  @DomName('SVGSVGElement.contentScriptType')
  @DocsEditable()
  String get contentScriptType native "SVGSVGElement_contentScriptType_Getter";

  @DomName('SVGSVGElement.contentScriptType')
  @DocsEditable()
  void set contentScriptType(String value) native "SVGSVGElement_contentScriptType_Setter";

  @DomName('SVGSVGElement.contentStyleType')
  @DocsEditable()
  String get contentStyleType native "SVGSVGElement_contentStyleType_Getter";

  @DomName('SVGSVGElement.contentStyleType')
  @DocsEditable()
  void set contentStyleType(String value) native "SVGSVGElement_contentStyleType_Setter";

  @DomName('SVGSVGElement.currentScale')
  @DocsEditable()
  num get currentScale native "SVGSVGElement_currentScale_Getter";

  @DomName('SVGSVGElement.currentScale')
  @DocsEditable()
  void set currentScale(num value) native "SVGSVGElement_currentScale_Setter";

  @DomName('SVGSVGElement.currentTranslate')
  @DocsEditable()
  Point get currentTranslate native "SVGSVGElement_currentTranslate_Getter";

  @DomName('SVGSVGElement.currentView')
  @DocsEditable()
  ViewSpec get currentView native "SVGSVGElement_currentView_Getter";

  @DomName('SVGSVGElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGSVGElement_height_Getter";

  @DomName('SVGSVGElement.pixelUnitToMillimeterX')
  @DocsEditable()
  double get pixelUnitToMillimeterX native "SVGSVGElement_pixelUnitToMillimeterX_Getter";

  @DomName('SVGSVGElement.pixelUnitToMillimeterY')
  @DocsEditable()
  double get pixelUnitToMillimeterY native "SVGSVGElement_pixelUnitToMillimeterY_Getter";

  @DomName('SVGSVGElement.screenPixelToMillimeterX')
  @DocsEditable()
  double get screenPixelToMillimeterX native "SVGSVGElement_screenPixelToMillimeterX_Getter";

  @DomName('SVGSVGElement.screenPixelToMillimeterY')
  @DocsEditable()
  double get screenPixelToMillimeterY native "SVGSVGElement_screenPixelToMillimeterY_Getter";

  @DomName('SVGSVGElement.useCurrentView')
  @DocsEditable()
  bool get useCurrentView native "SVGSVGElement_useCurrentView_Getter";

  @DomName('SVGSVGElement.viewport')
  @DocsEditable()
  Rect get viewport native "SVGSVGElement_viewport_Getter";

  @DomName('SVGSVGElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGSVGElement_width_Getter";

  @DomName('SVGSVGElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGSVGElement_x_Getter";

  @DomName('SVGSVGElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGSVGElement_y_Getter";

  @DomName('SVGSVGElement.animationsPaused')
  @DocsEditable()
  bool animationsPaused() native "SVGSVGElement_animationsPaused_Callback";

  @DomName('SVGSVGElement.checkEnclosure')
  @DocsEditable()
  bool checkEnclosure(SvgElement element, Rect rect) native "SVGSVGElement_checkEnclosure_Callback";

  @DomName('SVGSVGElement.checkIntersection')
  @DocsEditable()
  bool checkIntersection(SvgElement element, Rect rect) native "SVGSVGElement_checkIntersection_Callback";

  @DomName('SVGSVGElement.createSVGAngle')
  @DocsEditable()
  Angle createSvgAngle() native "SVGSVGElement_createSVGAngle_Callback";

  @DomName('SVGSVGElement.createSVGLength')
  @DocsEditable()
  Length createSvgLength() native "SVGSVGElement_createSVGLength_Callback";

  @DomName('SVGSVGElement.createSVGMatrix')
  @DocsEditable()
  Matrix createSvgMatrix() native "SVGSVGElement_createSVGMatrix_Callback";

  @DomName('SVGSVGElement.createSVGNumber')
  @DocsEditable()
  Number createSvgNumber() native "SVGSVGElement_createSVGNumber_Callback";

  @DomName('SVGSVGElement.createSVGPoint')
  @DocsEditable()
  Point createSvgPoint() native "SVGSVGElement_createSVGPoint_Callback";

  @DomName('SVGSVGElement.createSVGRect')
  @DocsEditable()
  Rect createSvgRect() native "SVGSVGElement_createSVGRect_Callback";

  @DomName('SVGSVGElement.createSVGTransform')
  @DocsEditable()
  Transform createSvgTransform() native "SVGSVGElement_createSVGTransform_Callback";

  @DomName('SVGSVGElement.createSVGTransformFromMatrix')
  @DocsEditable()
  Transform createSvgTransformFromMatrix(Matrix matrix) native "SVGSVGElement_createSVGTransformFromMatrix_Callback";

  @DomName('SVGSVGElement.deselectAll')
  @DocsEditable()
  void deselectAll() native "SVGSVGElement_deselectAll_Callback";

  @DomName('SVGSVGElement.forceRedraw')
  @DocsEditable()
  void forceRedraw() native "SVGSVGElement_forceRedraw_Callback";

  @DomName('SVGSVGElement.getCurrentTime')
  @DocsEditable()
  double getCurrentTime() native "SVGSVGElement_getCurrentTime_Callback";

  @DomName('SVGSVGElement.getElementById')
  @DocsEditable()
  Element getElementById(String elementId) native "SVGSVGElement_getElementById_Callback";

  @DomName('SVGSVGElement.getEnclosureList')
  @DocsEditable()
  List<Node> getEnclosureList(Rect rect, SvgElement referenceElement) native "SVGSVGElement_getEnclosureList_Callback";

  @DomName('SVGSVGElement.getIntersectionList')
  @DocsEditable()
  List<Node> getIntersectionList(Rect rect, SvgElement referenceElement) native "SVGSVGElement_getIntersectionList_Callback";

  @DomName('SVGSVGElement.pauseAnimations')
  @DocsEditable()
  void pauseAnimations() native "SVGSVGElement_pauseAnimations_Callback";

  @DomName('SVGSVGElement.setCurrentTime')
  @DocsEditable()
  void setCurrentTime(num seconds) native "SVGSVGElement_setCurrentTime_Callback";

  @DomName('SVGSVGElement.suspendRedraw')
  @DocsEditable()
  int suspendRedraw(int maxWaitMilliseconds) native "SVGSVGElement_suspendRedraw_Callback";

  @DomName('SVGSVGElement.unpauseAnimations')
  @DocsEditable()
  void unpauseAnimations() native "SVGSVGElement_unpauseAnimations_Callback";

  @DomName('SVGSVGElement.unsuspendRedraw')
  @DocsEditable()
  void unsuspendRedraw(int suspendHandleId) native "SVGSVGElement_unsuspendRedraw_Callback";

  @DomName('SVGSVGElement.unsuspendRedrawAll')
  @DocsEditable()
  void unsuspendRedrawAll() native "SVGSVGElement_unsuspendRedrawAll_Callback";

  @DomName('SVGSVGElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGSVGElement_externalResourcesRequired_Getter";

  @DomName('SVGSVGElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGSVGElement_preserveAspectRatio_Getter";

  @DomName('SVGSVGElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox native "SVGSVGElement_viewBox_Getter";

  @DomName('SVGSVGElement.zoomAndPan')
  @DocsEditable()
  int get zoomAndPan native "SVGSVGElement_zoomAndPan_Getter";

  @DomName('SVGSVGElement.zoomAndPan')
  @DocsEditable()
  void set zoomAndPan(int value) native "SVGSVGElement_zoomAndPan_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGSwitchElement')
@Unstable()
class SwitchElement extends GraphicsElement implements ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory SwitchElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGSwitchElement.SVGSwitchElement')
  @DocsEditable()
  factory SwitchElement() => _SvgElementFactoryProvider.createSvgElement_tag("switch");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  SwitchElement.created() : super.created();

  @DomName('SVGSwitchElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGSwitchElement_externalResourcesRequired_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGSymbolElement')
@Unstable()
class SymbolElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory SymbolElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGSymbolElement.SVGSymbolElement')
  @DocsEditable()
  factory SymbolElement() => _SvgElementFactoryProvider.createSvgElement_tag("symbol");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  SymbolElement.created() : super.created();

  @DomName('SVGSymbolElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGSymbolElement_externalResourcesRequired_Getter";

  @DomName('SVGSymbolElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGSymbolElement_preserveAspectRatio_Getter";

  @DomName('SVGSymbolElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox native "SVGSymbolElement_viewBox_Getter";

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
  factory TSpanElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTSpanElement.SVGTSpanElement')
  @DocsEditable()
  factory TSpanElement() => _SvgElementFactoryProvider.createSvgElement_tag("tspan");
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
abstract class Tests extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Tests._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTests.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions native "SVGTests_requiredExtensions_Getter";

  @DomName('SVGTests.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures native "SVGTests_requiredFeatures_Getter";

  @DomName('SVGTests.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage native "SVGTests_systemLanguage_Getter";

  @DomName('SVGTests.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) native "SVGTests_hasExtension_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGTextContentElement')
@Unstable()
class TextContentElement extends GraphicsElement implements ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory TextContentElement._() { throw new UnsupportedError("Not supported"); }
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
  AnimatedEnumeration get lengthAdjust native "SVGTextContentElement_lengthAdjust_Getter";

  @DomName('SVGTextContentElement.textLength')
  @DocsEditable()
  AnimatedLength get textLength native "SVGTextContentElement_textLength_Getter";

  @DomName('SVGTextContentElement.getCharNumAtPosition')
  @DocsEditable()
  int getCharNumAtPosition(Point point) native "SVGTextContentElement_getCharNumAtPosition_Callback";

  @DomName('SVGTextContentElement.getComputedTextLength')
  @DocsEditable()
  double getComputedTextLength() native "SVGTextContentElement_getComputedTextLength_Callback";

  @DomName('SVGTextContentElement.getEndPositionOfChar')
  @DocsEditable()
  Point getEndPositionOfChar(int offset) native "SVGTextContentElement_getEndPositionOfChar_Callback";

  @DomName('SVGTextContentElement.getExtentOfChar')
  @DocsEditable()
  Rect getExtentOfChar(int offset) native "SVGTextContentElement_getExtentOfChar_Callback";

  @DomName('SVGTextContentElement.getNumberOfChars')
  @DocsEditable()
  int getNumberOfChars() native "SVGTextContentElement_getNumberOfChars_Callback";

  @DomName('SVGTextContentElement.getRotationOfChar')
  @DocsEditable()
  double getRotationOfChar(int offset) native "SVGTextContentElement_getRotationOfChar_Callback";

  @DomName('SVGTextContentElement.getStartPositionOfChar')
  @DocsEditable()
  Point getStartPositionOfChar(int offset) native "SVGTextContentElement_getStartPositionOfChar_Callback";

  @DomName('SVGTextContentElement.getSubStringLength')
  @DocsEditable()
  double getSubStringLength(int offset, int length) native "SVGTextContentElement_getSubStringLength_Callback";

  @DomName('SVGTextContentElement.selectSubString')
  @DocsEditable()
  void selectSubString(int offset, int length) native "SVGTextContentElement_selectSubString_Callback";

  @DomName('SVGTextContentElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGTextContentElement_externalResourcesRequired_Getter";

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
  factory TextElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTextElement.SVGTextElement')
  @DocsEditable()
  factory TextElement() => _SvgElementFactoryProvider.createSvgElement_tag("text");
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
  factory TextPathElement._() { throw new UnsupportedError("Not supported"); }
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
  AnimatedEnumeration get method native "SVGTextPathElement_method_Getter";

  @DomName('SVGTextPathElement.spacing')
  @DocsEditable()
  AnimatedEnumeration get spacing native "SVGTextPathElement_spacing_Getter";

  @DomName('SVGTextPathElement.startOffset')
  @DocsEditable()
  AnimatedLength get startOffset native "SVGTextPathElement_startOffset_Getter";

  @DomName('SVGTextPathElement.href')
  @DocsEditable()
  AnimatedString get href native "SVGTextPathElement_href_Getter";

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
  factory TextPositioningElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  TextPositioningElement.created() : super.created();

  @DomName('SVGTextPositioningElement.dx')
  @DocsEditable()
  AnimatedLengthList get dx native "SVGTextPositioningElement_dx_Getter";

  @DomName('SVGTextPositioningElement.dy')
  @DocsEditable()
  AnimatedLengthList get dy native "SVGTextPositioningElement_dy_Getter";

  @DomName('SVGTextPositioningElement.rotate')
  @DocsEditable()
  AnimatedNumberList get rotate native "SVGTextPositioningElement_rotate_Getter";

  @DomName('SVGTextPositioningElement.x')
  @DocsEditable()
  AnimatedLengthList get x native "SVGTextPositioningElement_x_Getter";

  @DomName('SVGTextPositioningElement.y')
  @DocsEditable()
  AnimatedLengthList get y native "SVGTextPositioningElement_y_Getter";

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
  factory TitleElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTitleElement.SVGTitleElement')
  @DocsEditable()
  factory TitleElement() => _SvgElementFactoryProvider.createSvgElement_tag("title");
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
class Transform extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory Transform._() { throw new UnsupportedError("Not supported"); }

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
  double get angle native "SVGTransform_angle_Getter";

  @DomName('SVGTransform.matrix')
  @DocsEditable()
  Matrix get matrix native "SVGTransform_matrix_Getter";

  @DomName('SVGTransform.type')
  @DocsEditable()
  int get type native "SVGTransform_type_Getter";

  @DomName('SVGTransform.setMatrix')
  @DocsEditable()
  void setMatrix(Matrix matrix) native "SVGTransform_setMatrix_Callback";

  @DomName('SVGTransform.setRotate')
  @DocsEditable()
  void setRotate(num angle, num cx, num cy) native "SVGTransform_setRotate_Callback";

  @DomName('SVGTransform.setScale')
  @DocsEditable()
  void setScale(num sx, num sy) native "SVGTransform_setScale_Callback";

  @DomName('SVGTransform.setSkewX')
  @DocsEditable()
  void setSkewX(num angle) native "SVGTransform_setSkewX_Callback";

  @DomName('SVGTransform.setSkewY')
  @DocsEditable()
  void setSkewY(num angle) native "SVGTransform_setSkewY_Callback";

  @DomName('SVGTransform.setTranslate')
  @DocsEditable()
  void setTranslate(num tx, num ty) native "SVGTransform_setTranslate_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGTransformList')
@Unstable()
class TransformList extends NativeFieldWrapperClass2 with ListMixin<Transform>, ImmutableListMixin<Transform> implements List<Transform> {
  // To suppress missing implicit constructor warnings.
  factory TransformList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGTransformList.numberOfItems')
  @DocsEditable()
  int get numberOfItems native "SVGTransformList_numberOfItems_Getter";

  Transform operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.range(index, 0, length);
    return getItem(index);
  }

  void operator[]=(int index, Transform value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Transform> mixins.
  // Transform is the element type.

  // SVG Collections expose numberOfItems rather than length.
  int get length => numberOfItems;

  void set length(int value) {
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

  @DomName('SVGTransformList.appendItem')
  @DocsEditable()
  Transform appendItem(Transform item) native "SVGTransformList_appendItem_Callback";

  @DomName('SVGTransformList.clear')
  @DocsEditable()
  void clear() native "SVGTransformList_clear_Callback";

  @DomName('SVGTransformList.consolidate')
  @DocsEditable()
  Transform consolidate() native "SVGTransformList_consolidate_Callback";

  @DomName('SVGTransformList.createSVGTransformFromMatrix')
  @DocsEditable()
  Transform createSvgTransformFromMatrix(Matrix matrix) native "SVGTransformList_createSVGTransformFromMatrix_Callback";

  @DomName('SVGTransformList.getItem')
  @DocsEditable()
  Transform getItem(int index) native "SVGTransformList_getItem_Callback";

  @DomName('SVGTransformList.initialize')
  @DocsEditable()
  Transform initialize(Transform item) native "SVGTransformList_initialize_Callback";

  @DomName('SVGTransformList.insertItemBefore')
  @DocsEditable()
  Transform insertItemBefore(Transform item, int index) native "SVGTransformList_insertItemBefore_Callback";

  @DomName('SVGTransformList.removeItem')
  @DocsEditable()
  Transform removeItem(int index) native "SVGTransformList_removeItem_Callback";

  @DomName('SVGTransformList.replaceItem')
  @DocsEditable()
  Transform replaceItem(Transform item, int index) native "SVGTransformList_replaceItem_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGUnitTypes')
@Unstable()
class UnitTypes extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory UnitTypes._() { throw new UnsupportedError("Not supported"); }

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
abstract class UriReference extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory UriReference._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGURIReference.href')
  @DocsEditable()
  AnimatedString get href native "SVGURIReference_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGUseElement')
@Unstable()
class UseElement extends GraphicsElement implements UriReference, ExternalResourcesRequired, Tests {
  // To suppress missing implicit constructor warnings.
  factory UseElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGUseElement.SVGUseElement')
  @DocsEditable()
  factory UseElement() => _SvgElementFactoryProvider.createSvgElement_tag("use");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  UseElement.created() : super.created();

  @DomName('SVGUseElement.animatedInstanceRoot')
  @DocsEditable()
  ElementInstance get animatedInstanceRoot native "SVGUseElement_animatedInstanceRoot_Getter";

  @DomName('SVGUseElement.height')
  @DocsEditable()
  AnimatedLength get height native "SVGUseElement_height_Getter";

  @DomName('SVGUseElement.instanceRoot')
  @DocsEditable()
  ElementInstance get instanceRoot native "SVGUseElement_instanceRoot_Getter";

  @DomName('SVGUseElement.width')
  @DocsEditable()
  AnimatedLength get width native "SVGUseElement_width_Getter";

  @DomName('SVGUseElement.x')
  @DocsEditable()
  AnimatedLength get x native "SVGUseElement_x_Getter";

  @DomName('SVGUseElement.y')
  @DocsEditable()
  AnimatedLength get y native "SVGUseElement_y_Getter";

  @DomName('SVGUseElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGUseElement_externalResourcesRequired_Getter";

  @DomName('SVGUseElement.requiredExtensions')
  @DocsEditable()
  StringList get requiredExtensions native "SVGUseElement_requiredExtensions_Getter";

  @DomName('SVGUseElement.requiredFeatures')
  @DocsEditable()
  StringList get requiredFeatures native "SVGUseElement_requiredFeatures_Getter";

  @DomName('SVGUseElement.systemLanguage')
  @DocsEditable()
  StringList get systemLanguage native "SVGUseElement_systemLanguage_Getter";

  @DomName('SVGUseElement.hasExtension')
  @DocsEditable()
  bool hasExtension(String extension) native "SVGUseElement_hasExtension_Callback";

  @DomName('SVGUseElement.href')
  @DocsEditable()
  AnimatedString get href native "SVGUseElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGViewElement')
@Unstable()
class ViewElement extends SvgElement implements FitToViewBox, ExternalResourcesRequired, ZoomAndPan {
  // To suppress missing implicit constructor warnings.
  factory ViewElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGViewElement.SVGViewElement')
  @DocsEditable()
  factory ViewElement() => _SvgElementFactoryProvider.createSvgElement_tag("view");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  ViewElement.created() : super.created();

  @DomName('SVGViewElement.viewTarget')
  @DocsEditable()
  StringList get viewTarget native "SVGViewElement_viewTarget_Getter";

  @DomName('SVGViewElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGViewElement_externalResourcesRequired_Getter";

  @DomName('SVGViewElement.preserveAspectRatio')
  @DocsEditable()
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGViewElement_preserveAspectRatio_Getter";

  @DomName('SVGViewElement.viewBox')
  @DocsEditable()
  AnimatedRect get viewBox native "SVGViewElement_viewBox_Getter";

  @DomName('SVGViewElement.zoomAndPan')
  @DocsEditable()
  int get zoomAndPan native "SVGViewElement_zoomAndPan_Getter";

  @DomName('SVGViewElement.zoomAndPan')
  @DocsEditable()
  void set zoomAndPan(int value) native "SVGViewElement_zoomAndPan_Setter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGViewSpec')
@Unstable()
class ViewSpec extends NativeFieldWrapperClass2 implements FitToViewBox {
  // To suppress missing implicit constructor warnings.
  factory ViewSpec._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGViewSpec.preserveAspectRatioString')
  @DocsEditable()
  String get preserveAspectRatioString native "SVGViewSpec_preserveAspectRatioString_Getter";

  @DomName('SVGViewSpec.transform')
  @DocsEditable()
  TransformList get transform native "SVGViewSpec_transform_Getter";

  @DomName('SVGViewSpec.transformString')
  @DocsEditable()
  String get transformString native "SVGViewSpec_transformString_Getter";

  @DomName('SVGViewSpec.viewBoxString')
  @DocsEditable()
  String get viewBoxString native "SVGViewSpec_viewBoxString_Getter";

  @DomName('SVGViewSpec.viewTarget')
  @DocsEditable()
  SvgElement get viewTarget native "SVGViewSpec_viewTarget_Getter";

  @DomName('SVGViewSpec.viewTargetString')
  @DocsEditable()
  String get viewTargetString native "SVGViewSpec_viewTargetString_Getter";

  @DomName('SVGViewSpec.zoomAndPan')
  @DocsEditable()
  @Experimental() // nonstandard
  int get zoomAndPan native "SVGViewSpec_zoomAndPan_Getter";

  @DomName('SVGViewSpec.zoomAndPan')
  @DocsEditable()
  @Experimental() // nonstandard
  void set zoomAndPan(int value) native "SVGViewSpec_zoomAndPan_Setter";

  @DomName('SVGViewSpec.preserveAspectRatio')
  @DocsEditable()
  @Experimental() // nonstandard
  AnimatedPreserveAspectRatio get preserveAspectRatio native "SVGViewSpec_preserveAspectRatio_Getter";

  @DomName('SVGViewSpec.viewBox')
  @DocsEditable()
  @Experimental() // nonstandard
  AnimatedRect get viewBox native "SVGViewSpec_viewBox_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGZoomAndPan')
@Unstable()
abstract class ZoomAndPan extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory ZoomAndPan._() { throw new UnsupportedError("Not supported"); }

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
  int get zoomAndPan native "SVGZoomAndPan_zoomAndPan_Getter";

  @DomName('SVGZoomAndPan.zoomAndPan')
  @DocsEditable()
  void set zoomAndPan(int value) native "SVGZoomAndPan_zoomAndPan_Setter";

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
  factory ZoomEvent._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGZoomEvent.newScale')
  @DocsEditable()
  double get newScale native "SVGZoomEvent_newScale_Getter";

  @DomName('SVGZoomEvent.newTranslate')
  @DocsEditable()
  Point get newTranslate native "SVGZoomEvent_newTranslate_Getter";

  @DomName('SVGZoomEvent.previousScale')
  @DocsEditable()
  double get previousScale native "SVGZoomEvent_previousScale_Getter";

  @DomName('SVGZoomEvent.previousTranslate')
  @DocsEditable()
  Point get previousTranslate native "SVGZoomEvent_previousTranslate_Getter";

  @DomName('SVGZoomEvent.zoomRectScreen')
  @DocsEditable()
  Rect get zoomRectScreen native "SVGZoomEvent_zoomRectScreen_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGElementInstanceList')
@Unstable()
class _ElementInstanceList extends NativeFieldWrapperClass2 with ListMixin<ElementInstance>, ImmutableListMixin<ElementInstance> implements List<ElementInstance> {
  // To suppress missing implicit constructor warnings.
  factory _ElementInstanceList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGElementInstanceList.length')
  @DocsEditable()
  int get length native "SVGElementInstanceList_length_Getter";

  ElementInstance operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.range(index, 0, length);
    return _nativeIndexedGetter(index);
  }
  ElementInstance _nativeIndexedGetter(int index) native "SVGElementInstanceList_item_Callback";

  void operator[]=(int index, ElementInstance value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<ElementInstance> mixins.
  // ElementInstance is the element type.


  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  ElementInstance get first {
    if (this.length > 0) {
      return _nativeIndexedGetter(0);
    }
    throw new StateError("No elements");
  }

  ElementInstance get last {
    int len = this.length;
    if (len > 0) {
      return _nativeIndexedGetter(len - 1);
    }
    throw new StateError("No elements");
  }

  ElementInstance get single {
    int len = this.length;
    if (len == 1) {
      return _nativeIndexedGetter(0);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  ElementInstance elementAt(int index) => this[index];
  // -- end List<ElementInstance> mixins.

  @DomName('SVGElementInstanceList.item')
  @DocsEditable()
  ElementInstance item(int index) native "SVGElementInstanceList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGGradientElement')
@Unstable()
class _GradientElement extends SvgElement implements UriReference, ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory _GradientElement._() { throw new UnsupportedError("Not supported"); }
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
  AnimatedTransformList get gradientTransform native "SVGGradientElement_gradientTransform_Getter";

  @DomName('SVGGradientElement.gradientUnits')
  @DocsEditable()
  AnimatedEnumeration get gradientUnits native "SVGGradientElement_gradientUnits_Getter";

  @DomName('SVGGradientElement.spreadMethod')
  @DocsEditable()
  AnimatedEnumeration get spreadMethod native "SVGGradientElement_spreadMethod_Getter";

  @DomName('SVGGradientElement.externalResourcesRequired')
  @DocsEditable()
  AnimatedBoolean get externalResourcesRequired native "SVGGradientElement_externalResourcesRequired_Getter";

  @DomName('SVGGradientElement.href')
  @DocsEditable()
  AnimatedString get href native "SVGGradientElement_href_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAltGlyphDefElement')
@Unstable()
abstract class _SVGAltGlyphDefElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGAltGlyphDefElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGAltGlyphDefElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAltGlyphItemElement')
@Unstable()
abstract class _SVGAltGlyphItemElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGAltGlyphItemElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGAltGlyphItemElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGAnimateColorElement')
@Unstable()
abstract class _SVGAnimateColorElement extends AnimationElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGAnimateColorElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGAnimateColorElement.created() : super.created();

}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Hack because the baseclass is private in dart:html, and we want to omit this
// type entirely but can't.
@DocsEditable()
@DomName('SVGColor')
@Unstable()
abstract class _SVGColor {
  _SVGColor.internal();
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGComponentTransferFunctionElement')
@Unstable()
abstract class _SVGComponentTransferFunctionElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGComponentTransferFunctionElement._() { throw new UnsupportedError("Not supported"); }
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

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGCursorElement')
@Unstable()
abstract class _SVGCursorElement extends SvgElement implements UriReference, ExternalResourcesRequired, Tests {
  // To suppress missing implicit constructor warnings.
  factory _SVGCursorElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGCursorElement.SVGCursorElement')
  @DocsEditable()
  factory _SVGCursorElement() => _SvgElementFactoryProvider.createSvgElement_tag("cursor");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGCursorElement.created() : super.created();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFEDropShadowElement')
@Experimental() // nonstandard
abstract class _SVGFEDropShadowElement extends SvgElement implements FilterPrimitiveStandardAttributes {
  // To suppress missing implicit constructor warnings.
  factory _SVGFEDropShadowElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGFEDropShadowElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFontElement')
@Unstable()
abstract class _SVGFontElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGFontElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGFontElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFontFaceElement')
@Unstable()
abstract class _SVGFontFaceElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGFontFaceElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGFontFaceElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFontFaceFormatElement')
@Unstable()
abstract class _SVGFontFaceFormatElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGFontFaceFormatElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGFontFaceFormatElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFontFaceNameElement')
@Unstable()
abstract class _SVGFontFaceNameElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGFontFaceNameElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGFontFaceNameElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFontFaceSrcElement')
@Unstable()
abstract class _SVGFontFaceSrcElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGFontFaceSrcElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGFontFaceSrcElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGFontFaceUriElement')
@Unstable()
abstract class _SVGFontFaceUriElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGFontFaceUriElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGFontFaceUriElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGGlyphElement')
@Unstable()
abstract class _SVGGlyphElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGGlyphElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGGlyphElement.SVGGlyphElement')
  @DocsEditable()
  factory _SVGGlyphElement() => _SvgElementFactoryProvider.createSvgElement_tag("glyph");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGGlyphElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGGlyphRefElement')
@Unstable()
abstract class _SVGGlyphRefElement extends SvgElement implements UriReference {
  // To suppress missing implicit constructor warnings.
  factory _SVGGlyphRefElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGGlyphRefElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGHKernElement')
@Unstable()
abstract class _SVGHKernElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGHKernElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGHKernElement.SVGHKernElement')
  @DocsEditable()
  factory _SVGHKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("hkern");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGHKernElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGMPathElement')
abstract class _SVGMPathElement extends SvgElement implements UriReference, ExternalResourcesRequired {
  // To suppress missing implicit constructor warnings.
  factory _SVGMPathElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGMPathElement.SVGMPathElement')
  @DocsEditable()
  factory _SVGMPathElement() => _SvgElementFactoryProvider.createSvgElement_tag("mpath");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGMPathElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGMissingGlyphElement')
@Unstable()
abstract class _SVGMissingGlyphElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGMissingGlyphElement._() { throw new UnsupportedError("Not supported"); }
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGMissingGlyphElement.created() : super.created();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGPaint')
@Unstable()
abstract class _SVGPaint extends _SVGColor {
  // To suppress missing implicit constructor warnings.
  factory _SVGPaint._() { throw new UnsupportedError("Not supported"); }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SVGVKernElement')
@Unstable()
abstract class _SVGVKernElement extends SvgElement {
  // To suppress missing implicit constructor warnings.
  factory _SVGVKernElement._() { throw new UnsupportedError("Not supported"); }

  @DomName('SVGVKernElement.SVGVKernElement')
  @DocsEditable()
  factory _SVGVKernElement() => _SvgElementFactoryProvider.createSvgElement_tag("vkern");
  /**
   * Constructor instantiated by the DOM when a custom element has been created.
   *
   * This can only be called by subclasses from their created constructor.
   */
  _SVGVKernElement.created() : super.created();

}
