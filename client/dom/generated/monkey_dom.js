// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated Dart DOM implementation.

function DOM$EnsureDartNull(value) {
  return value === null ? (void 0) : value;
}

function DOM$fixStatic(cls, key) {
  cls[key + '$getter'] = function() {
    return DOM$EnsureDartNull(cls[key]);
  };
}
function DOM$fixGetter(cls, key) {
  cls.prototype[key + '$getter'] = function() {
    return DOM$EnsureDartNull(this[key]);
  };
}
function DOM$fixSetter(cls, key) {
  cls.prototype[key + '$setter'] = function(x) { this[key] = x; };
}
function DOM$fixMember(cls, key) {
  cls.prototype[key + '$member'] = function () {
    return DOM$EnsureDartNull(this[key].apply(this, arguments));
  };
}
function DOM$fixProp(cls, key) {
  DOM$fixGetter(cls, key);
  DOM$fixSetter(cls, key);
}
function DOM$fixStatics(cls, keys) {
  // TODO(vsm): We should eliminate this dynamic check.
  if (cls) {
    for (var i = 0; i < keys.length; ++i) {
      DOM$fixStatic(cls, keys[i]);
    }
  }
}
function DOM$fixAccessors(cls, keys) {
  // TODO(vsm): We should eliminate this dynamic check.
  if (cls && cls.prototype) {
    for (var i = 0; i < keys.length; ++i) {
      DOM$fixProp(cls, keys[i]);
    }
  }
}
function DOM$fixGetters(cls, keys) {
  // TODO(vsm): We should eliminate this dynamic check.
  if (cls && cls.prototype) {
    for (var i = 0; i < keys.length; ++i) {
      DOM$fixGetter(cls, keys[i]);
    }
  }
}
function DOM$fixMembers(cls, keys) {
  // TODO(vsm): We should eliminate this dynamic check.
  if (cls && cls.prototype) {
    for (var i = 0; i < keys.length; ++i) {
      DOM$fixMember(cls, keys[i]);
    }
  }
}

function DOM$fixClass$AbstractWorker(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'addEventListener',
    'dispatchEvent',
    'removeEventListener']);
  c.$implements$AbstractWorker$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$ArrayBuffer(c) {
  if (c.prototype) {
    c.prototype.byteLength$getter = function() { return DOM$EnsureDartNull(this.byteLength); };
  }
  DOM$fixMembers(c, ['slice']);
  c.$implements$ArrayBuffer$Dart = 1;
}
function DOM$fixClass$ArrayBufferView(c) {
  if (c.prototype) {
    c.prototype.buffer$getter = function() { return DOM$EnsureDartNull(this.buffer); };
    c.prototype.byteLength$getter = function() { return DOM$EnsureDartNull(this.byteLength); };
    c.prototype.byteOffset$getter = function() { return DOM$EnsureDartNull(this.byteOffset); };
  }
  c.$implements$ArrayBufferView$Dart = 1;
}
function DOM$fixClass$Attr(c) {
  if (c.prototype) {
    c.prototype.isId$getter = function() { return DOM$EnsureDartNull(this.isId); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.ownerElement$getter = function() { return DOM$EnsureDartNull(this.ownerElement); };
    c.prototype.specified$getter = function() { return DOM$EnsureDartNull(this.specified); };
    c.prototype.value$getter = function() { return DOM$EnsureDartNull(this.value); };
    c.prototype.value$setter = function(value) { this.value = value; };
  }
  c.$implements$Attr$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$BarInfo(c) {
  if (c.prototype) {
    c.prototype.visible$getter = function() { return DOM$EnsureDartNull(this.visible); };
  }
  c.$implements$BarInfo$Dart = 1;
}
function DOM$fixClass$BeforeLoadEvent(c) {
  if (c.prototype) {
    c.prototype.url$getter = function() { return DOM$EnsureDartNull(this.url); };
  }
  DOM$fixMembers(c, ['initBeforeLoadEvent']);
  c.$implements$BeforeLoadEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$Blob(c) {
  if (c.prototype) {
    c.prototype.size$getter = function() { return DOM$EnsureDartNull(this.size); };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
  }
  c.$implements$Blob$Dart = 1;
}
function DOM$fixClass$CDATASection(c) {
  if (c.prototype) {
  }
  c.$implements$CDATASection$Dart = 1;
  c.$implements$Text$Dart = 1;
  c.$implements$CharacterData$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$CSSCharsetRule(c) {
  if (c.prototype) {
    c.prototype.encoding$getter = function() { return DOM$EnsureDartNull(this.encoding); };
    c.prototype.encoding$setter = function(value) { this.encoding = value; };
  }
  c.$implements$CSSCharsetRule$Dart = 1;
  c.$implements$CSSRule$Dart = 1;
}
function DOM$fixClass$CSSFontFaceRule(c) {
  if (c.prototype) {
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  c.$implements$CSSFontFaceRule$Dart = 1;
  c.$implements$CSSRule$Dart = 1;
}
function DOM$fixClass$CSSImportRule(c) {
  if (c.prototype) {
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.media$getter = function() { return DOM$EnsureDartNull(this.media); };
    c.prototype.styleSheet$getter = function() { return DOM$EnsureDartNull(this.styleSheet); };
  }
  c.$implements$CSSImportRule$Dart = 1;
  c.$implements$CSSRule$Dart = 1;
}
function DOM$fixClass$CSSMediaRule(c) {
  if (c.prototype) {
    c.prototype.cssRules$getter = function() { return DOM$EnsureDartNull(this.cssRules); };
    c.prototype.media$getter = function() { return DOM$EnsureDartNull(this.media); };
  }
  DOM$fixMembers(c, [
    'deleteRule',
    'insertRule']);
  c.$implements$CSSMediaRule$Dart = 1;
  c.$implements$CSSRule$Dart = 1;
}
function DOM$fixClass$CSSPageRule(c) {
  if (c.prototype) {
    c.prototype.selectorText$getter = function() { return DOM$EnsureDartNull(this.selectorText); };
    c.prototype.selectorText$setter = function(value) { this.selectorText = value; };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  c.$implements$CSSPageRule$Dart = 1;
  c.$implements$CSSRule$Dart = 1;
}
function DOM$fixClass$CSSPrimitiveValue(c) {
  if (c.prototype) {
    c.prototype.primitiveType$getter = function() { return DOM$EnsureDartNull(this.primitiveType); };
  }
  DOM$fixMembers(c, [
    'getCounterValue',
    'getFloatValue',
    'getRGBColorValue',
    'getRectValue',
    'getStringValue',
    'setFloatValue',
    'setStringValue']);
  c.$implements$CSSPrimitiveValue$Dart = 1;
  c.$implements$CSSValue$Dart = 1;
}
function DOM$fixClass$CSSRule(c) {
  if (c.prototype) {
    c.prototype.cssText$getter = function() { return DOM$EnsureDartNull(this.cssText); };
    c.prototype.cssText$setter = function(value) { this.cssText = value; };
    c.prototype.parentRule$getter = function() { return DOM$EnsureDartNull(this.parentRule); };
    c.prototype.parentStyleSheet$getter = function() { return DOM$EnsureDartNull(this.parentStyleSheet); };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
  }
  c.$implements$CSSRule$Dart = 1;
}
function DOM$fixClass$CSSRuleList(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, ['item']);
  c.$implements$CSSRuleList$Dart = 1;
}
function DOM$fixClass$CSSStyleDeclaration(c) {
  if (c.prototype) {
    c.prototype.cssText$getter = function() { return DOM$EnsureDartNull(this.cssText); };
    c.prototype.cssText$setter = function(value) { this.cssText = value; };
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
    c.prototype.parentRule$getter = function() { return DOM$EnsureDartNull(this.parentRule); };
  }
  DOM$fixMembers(c, [
    'getPropertyCSSValue',
    'getPropertyPriority',
    'getPropertyShorthand',
    'getPropertyValue',
    'isPropertyImplicit',
    'item',
    'removeProperty',
    'setProperty']);
  c.$implements$CSSStyleDeclaration$Dart = 1;
}
function DOM$fixClass$CSSStyleRule(c) {
  if (c.prototype) {
    c.prototype.selectorText$getter = function() { return DOM$EnsureDartNull(this.selectorText); };
    c.prototype.selectorText$setter = function(value) { this.selectorText = value; };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  c.$implements$CSSStyleRule$Dart = 1;
  c.$implements$CSSRule$Dart = 1;
}
function DOM$fixClass$CSSStyleSheet(c) {
  if (c.prototype) {
    c.prototype.cssRules$getter = function() { return DOM$EnsureDartNull(this.cssRules); };
    c.prototype.ownerRule$getter = function() { return DOM$EnsureDartNull(this.ownerRule); };
    c.prototype.rules$getter = function() { return DOM$EnsureDartNull(this.rules); };
  }
  DOM$fixMembers(c, [
    'addRule',
    'deleteRule',
    'insertRule',
    'removeRule']);
  c.$implements$CSSStyleSheet$Dart = 1;
  c.$implements$StyleSheet$Dart = 1;
}
function DOM$fixClass$CSSUnknownRule(c) {
  if (c.prototype) {
  }
  c.$implements$CSSUnknownRule$Dart = 1;
  c.$implements$CSSRule$Dart = 1;
}
function DOM$fixClass$CSSValue(c) {
  if (c.prototype) {
    c.prototype.cssText$getter = function() { return DOM$EnsureDartNull(this.cssText); };
    c.prototype.cssText$setter = function(value) { this.cssText = value; };
    c.prototype.cssValueType$getter = function() { return DOM$EnsureDartNull(this.cssValueType); };
  }
  c.$implements$CSSValue$Dart = 1;
}
function DOM$fixClass$CSSValueList(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, ['item']);
  c.$implements$CSSValueList$Dart = 1;
  c.$implements$CSSValue$Dart = 1;
}
function DOM$fixClass$CanvasGradient(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['addColorStop']);
  c.$implements$CanvasGradient$Dart = 1;
}
function DOM$fixClass$CanvasPattern(c) {
  if (c.prototype) {
  }
  c.$implements$CanvasPattern$Dart = 1;
}
function DOM$fixClass$CanvasPixelArray(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
    c.prototype.INDEX$operator = function(k) { return DOM$EnsureDartNull(this[k]); };
    c.prototype.ASSIGN_INDEX$operator = function(k, v) { this[k] = v; };
  }
  DOM$fixMembers(c, ['item']);
  c.$implements$CanvasPixelArray$Dart = 1;
}
function DOM$fixClassOnDemand$CanvasPixelArray(c) {
  if (c.DOM$initialized === true)
    return;
  c.DOM$initialized = true;
  DOM$fixClass$CanvasPixelArray(c);
}
function DOM$fixValue$CanvasPixelArray(value) {
  if (value == null)
    return DOM$EnsureDartNull(value);
  if (typeof value != "object")
    return value;
  var constructor = value.constructor;
  if (constructor == null)
    return value;
  DOM$fixClassOnDemand$CanvasPixelArray(constructor);
  return value;
}
function DOM$fixClass$CanvasRenderingContext(c) {
  if (c.prototype) {
    c.prototype.canvas$getter = function() { return DOM$EnsureDartNull(this.canvas); };
  }
  c.$implements$CanvasRenderingContext$Dart = 1;
}
function DOM$fixClass$CanvasRenderingContext2D(c) {
  if (c.prototype) {
    c.prototype.fillStyle$getter = function() { return DOM$EnsureDartNull(this.fillStyle); };
    c.prototype.fillStyle$setter = function(value) { this.fillStyle = value; };
    c.prototype.font$getter = function() { return DOM$EnsureDartNull(this.font); };
    c.prototype.font$setter = function(value) { this.font = value; };
    c.prototype.globalAlpha$getter = function() { return DOM$EnsureDartNull(this.globalAlpha); };
    c.prototype.globalAlpha$setter = function(value) { this.globalAlpha = value; };
    c.prototype.globalCompositeOperation$getter = function() { return DOM$EnsureDartNull(this.globalCompositeOperation); };
    c.prototype.globalCompositeOperation$setter = function(value) { this.globalCompositeOperation = value; };
    c.prototype.lineCap$getter = function() { return DOM$EnsureDartNull(this.lineCap); };
    c.prototype.lineCap$setter = function(value) { this.lineCap = value; };
    c.prototype.lineJoin$getter = function() { return DOM$EnsureDartNull(this.lineJoin); };
    c.prototype.lineJoin$setter = function(value) { this.lineJoin = value; };
    c.prototype.lineWidth$getter = function() { return DOM$EnsureDartNull(this.lineWidth); };
    c.prototype.lineWidth$setter = function(value) { this.lineWidth = value; };
    c.prototype.miterLimit$getter = function() { return DOM$EnsureDartNull(this.miterLimit); };
    c.prototype.miterLimit$setter = function(value) { this.miterLimit = value; };
    c.prototype.shadowBlur$getter = function() { return DOM$EnsureDartNull(this.shadowBlur); };
    c.prototype.shadowBlur$setter = function(value) { this.shadowBlur = value; };
    c.prototype.shadowColor$getter = function() { return DOM$EnsureDartNull(this.shadowColor); };
    c.prototype.shadowColor$setter = function(value) { this.shadowColor = value; };
    c.prototype.shadowOffsetX$getter = function() { return DOM$EnsureDartNull(this.shadowOffsetX); };
    c.prototype.shadowOffsetX$setter = function(value) { this.shadowOffsetX = value; };
    c.prototype.shadowOffsetY$getter = function() { return DOM$EnsureDartNull(this.shadowOffsetY); };
    c.prototype.shadowOffsetY$setter = function(value) { this.shadowOffsetY = value; };
    c.prototype.strokeStyle$getter = function() { return DOM$EnsureDartNull(this.strokeStyle); };
    c.prototype.strokeStyle$setter = function(value) { this.strokeStyle = value; };
    c.prototype.textAlign$getter = function() { return DOM$EnsureDartNull(this.textAlign); };
    c.prototype.textAlign$setter = function(value) { this.textAlign = value; };
    c.prototype.textBaseline$getter = function() { return DOM$EnsureDartNull(this.textBaseline); };
    c.prototype.textBaseline$setter = function(value) { this.textBaseline = value; };
    c.prototype.webkitLineDash$getter = function() { return DOM$EnsureDartNull(this.webkitLineDash); };
    c.prototype.webkitLineDash$setter = function(value) { this.webkitLineDash = value; };
    c.prototype.webkitLineDashOffset$getter = function() { return DOM$EnsureDartNull(this.webkitLineDashOffset); };
    c.prototype.webkitLineDashOffset$setter = function(value) { this.webkitLineDashOffset = value; };
  }
  DOM$fixMembers(c, [
    'arc',
    'arcTo',
    'beginPath',
    'bezierCurveTo',
    'clearRect',
    'clearShadow',
    'clip',
    'closePath',
    'createLinearGradient',
    'createPattern',
    'createRadialGradient',
    'drawImage',
    'drawImageFromRect',
    'fill',
    'fillRect',
    'fillText',
    'isPointInPath',
    'lineTo',
    'measureText',
    'moveTo',
    'putImageData',
    'quadraticCurveTo',
    'rect',
    'restore',
    'rotate',
    'save',
    'scale',
    'setAlpha',
    'setCompositeOperation',
    'setFillColor',
    'setLineCap',
    'setLineJoin',
    'setLineWidth',
    'setMiterLimit',
    'setShadow',
    'setStrokeColor',
    'setTransform',
    'stroke',
    'strokeRect',
    'strokeText',
    'transform',
    'translate']);
  c.prototype.createImageData$member = function() {
    return DOM$fixValue$ImageData(this.createImageData.apply(this, arguments));
  };
  c.prototype.getImageData$member = function() {
    return DOM$fixValue$ImageData(this.getImageData.apply(this, arguments));
  };
  c.$implements$CanvasRenderingContext2D$Dart = 1;
  c.$implements$CanvasRenderingContext$Dart = 1;
}
function DOM$fixClass$CharacterData(c) {
  if (c.prototype) {
    c.prototype.data$getter = function() { return DOM$EnsureDartNull(this.data); };
    c.prototype.data$setter = function(value) { this.data = value; };
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, [
    'appendData',
    'deleteData',
    'insertData',
    'replaceData',
    'substringData']);
  c.$implements$CharacterData$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$ClientRect(c) {
  if (c.prototype) {
    c.prototype.bottom$getter = function() { return DOM$EnsureDartNull(this.bottom); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.left$getter = function() { return DOM$EnsureDartNull(this.left); };
    c.prototype.right$getter = function() { return DOM$EnsureDartNull(this.right); };
    c.prototype.top$getter = function() { return DOM$EnsureDartNull(this.top); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
  }
  c.$implements$ClientRect$Dart = 1;
}
function DOM$fixClass$ClientRectList(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, ['item']);
  c.$implements$ClientRectList$Dart = 1;
}
function DOM$fixClass$Clipboard(c) {
  if (c.prototype) {
    c.prototype.dropEffect$getter = function() { return DOM$EnsureDartNull(this.dropEffect); };
    c.prototype.dropEffect$setter = function(value) { this.dropEffect = value; };
    c.prototype.effectAllowed$getter = function() { return DOM$EnsureDartNull(this.effectAllowed); };
    c.prototype.effectAllowed$setter = function(value) { this.effectAllowed = value; };
    c.prototype.files$getter = function() { return DOM$EnsureDartNull(this.files); };
    c.prototype.items$getter = function() { return DOM$EnsureDartNull(this.items); };
    c.prototype.types$getter = function() { return DOM$EnsureDartNull(this.types); };
  }
  DOM$fixMembers(c, [
    'clearData',
    'getData',
    'setData',
    'setDragImage']);
  c.$implements$Clipboard$Dart = 1;
}
function DOM$fixClass$CloseEvent(c) {
  if (c.prototype) {
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
    c.prototype.reason$getter = function() { return DOM$EnsureDartNull(this.reason); };
    c.prototype.wasClean$getter = function() { return DOM$EnsureDartNull(this.wasClean); };
  }
  DOM$fixMembers(c, ['initCloseEvent']);
  c.$implements$CloseEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$Comment(c) {
  if (c.prototype) {
  }
  c.$implements$Comment$Dart = 1;
  c.$implements$CharacterData$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$CompositionEvent(c) {
  if (c.prototype) {
    c.prototype.data$getter = function() { return DOM$EnsureDartNull(this.data); };
  }
  DOM$fixMembers(c, ['initCompositionEvent']);
  c.$implements$CompositionEvent$Dart = 1;
  c.$implements$UIEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$Console(c) {
  if (c.prototype) {
    c.prototype.memory$getter = function() { return DOM$EnsureDartNull(this.memory); };
  }
  DOM$fixMembers(c, [
    'count',
    'debug',
    'dir',
    'dirxml',
    'error',
    'group',
    'groupCollapsed',
    'groupEnd',
    'info',
    'log',
    'markTimeline',
    'time',
    'timeEnd',
    'timeStamp',
    'trace',
    'warn']);
  c.prototype.assert$member = function() {
    return DOM$EnsureDartNull(this.assertCondition.apply(this, arguments));
  };
  c.$implements$Console$Dart = 1;
}
function DOM$fixClass$Coordinates(c) {
  if (c.prototype) {
    c.prototype.accuracy$getter = function() { return DOM$EnsureDartNull(this.accuracy); };
    c.prototype.altitude$getter = function() { return DOM$EnsureDartNull(this.altitude); };
    c.prototype.altitudeAccuracy$getter = function() { return DOM$EnsureDartNull(this.altitudeAccuracy); };
    c.prototype.heading$getter = function() { return DOM$EnsureDartNull(this.heading); };
    c.prototype.latitude$getter = function() { return DOM$EnsureDartNull(this.latitude); };
    c.prototype.longitude$getter = function() { return DOM$EnsureDartNull(this.longitude); };
    c.prototype.speed$getter = function() { return DOM$EnsureDartNull(this.speed); };
  }
  c.$implements$Coordinates$Dart = 1;
}
function DOM$fixClass$Counter(c) {
  if (c.prototype) {
    c.prototype.identifier$getter = function() { return DOM$EnsureDartNull(this.identifier); };
    c.prototype.listStyle$getter = function() { return DOM$EnsureDartNull(this.listStyle); };
    c.prototype.separator$getter = function() { return DOM$EnsureDartNull(this.separator); };
  }
  c.$implements$Counter$Dart = 1;
}
function DOM$fixClass$Crypto(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['getRandomValues']);
  c.$implements$Crypto$Dart = 1;
}
function DOM$fixClass$CustomEvent(c) {
  if (c.prototype) {
    c.prototype.detail$getter = function() { return DOM$EnsureDartNull(this.detail); };
  }
  DOM$fixMembers(c, ['initCustomEvent']);
  c.$implements$CustomEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$DOMApplicationCache(c) {
  if (c.prototype) {
    c.prototype.status$getter = function() { return DOM$EnsureDartNull(this.status); };
  }
  DOM$fixMembers(c, [
    'addEventListener',
    'dispatchEvent',
    'removeEventListener',
    'swapCache',
    'update']);
  c.$implements$DOMApplicationCache$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$DOMException(c) {
  if (c.prototype) {
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
    c.prototype.message$getter = function() { return DOM$EnsureDartNull(this.message); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
  }
  DOM$fixMembers(c, ['toString']);
  c.$implements$DOMException$Dart = 1;
}
function DOM$fixClass$DOMFileSystem(c) {
  if (c.prototype) {
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.root$getter = function() { return DOM$EnsureDartNull(this.root); };
  }
  c.$implements$DOMFileSystem$Dart = 1;
}
function DOM$fixClass$DOMFileSystemSync(c) {
  if (c.prototype) {
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.root$getter = function() { return DOM$EnsureDartNull(this.root); };
  }
  c.$implements$DOMFileSystemSync$Dart = 1;
}
function DOM$fixClass$DOMFormData(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['append']);
  c.$implements$DOMFormData$Dart = 1;
}
function DOM$fixClass$DOMImplementation(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'createCSSStyleSheet',
    'createDocument',
    'createDocumentType',
    'createHTMLDocument',
    'hasFeature']);
  c.$implements$DOMImplementation$Dart = 1;
}
function DOM$fixClass$DOMMimeType(c) {
  if (c.prototype) {
    c.prototype.description$getter = function() { return DOM$EnsureDartNull(this.description); };
    c.prototype.enabledPlugin$getter = function() { return DOM$EnsureDartNull(this.enabledPlugin); };
    c.prototype.suffixes$getter = function() { return DOM$EnsureDartNull(this.suffixes); };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
  }
  c.$implements$DOMMimeType$Dart = 1;
}
function DOM$fixClass$DOMMimeTypeArray(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, [
    'item',
    'namedItem']);
  c.$implements$DOMMimeTypeArray$Dart = 1;
}
function DOM$fixClass$DOMParser(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['parseFromString']);
  c.$implements$DOMParser$Dart = 1;
}
function DOM$fixClass$DOMPlugin(c) {
  if (c.prototype) {
    c.prototype.description$getter = function() { return DOM$EnsureDartNull(this.description); };
    c.prototype.filename$getter = function() { return DOM$EnsureDartNull(this.filename); };
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
  }
  DOM$fixMembers(c, [
    'item',
    'namedItem']);
  c.$implements$DOMPlugin$Dart = 1;
}
function DOM$fixClass$DOMPluginArray(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, [
    'item',
    'namedItem',
    'refresh']);
  c.$implements$DOMPluginArray$Dart = 1;
}
function DOM$fixClass$DOMSelection(c) {
  if (c.prototype) {
    c.prototype.anchorNode$getter = function() { return DOM$EnsureDartNull(this.anchorNode); };
    c.prototype.anchorOffset$getter = function() { return DOM$EnsureDartNull(this.anchorOffset); };
    c.prototype.baseNode$getter = function() { return DOM$EnsureDartNull(this.baseNode); };
    c.prototype.baseOffset$getter = function() { return DOM$EnsureDartNull(this.baseOffset); };
    c.prototype.extentNode$getter = function() { return DOM$EnsureDartNull(this.extentNode); };
    c.prototype.extentOffset$getter = function() { return DOM$EnsureDartNull(this.extentOffset); };
    c.prototype.focusNode$getter = function() { return DOM$EnsureDartNull(this.focusNode); };
    c.prototype.focusOffset$getter = function() { return DOM$EnsureDartNull(this.focusOffset); };
    c.prototype.isCollapsed$getter = function() { return DOM$EnsureDartNull(this.isCollapsed); };
    c.prototype.rangeCount$getter = function() { return DOM$EnsureDartNull(this.rangeCount); };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
  }
  DOM$fixMembers(c, [
    'addRange',
    'collapse',
    'collapseToEnd',
    'collapseToStart',
    'containsNode',
    'deleteFromDocument',
    'empty',
    'extend',
    'getRangeAt',
    'modify',
    'removeAllRanges',
    'selectAllChildren',
    'setBaseAndExtent',
    'setPosition',
    'toString']);
  c.$implements$DOMSelection$Dart = 1;
}
function DOM$fixClass$DOMSettableTokenList(c) {
  if (c.prototype) {
    c.prototype.value$getter = function() { return DOM$EnsureDartNull(this.value); };
    c.prototype.value$setter = function(value) { this.value = value; };
  }
  c.$implements$DOMSettableTokenList$Dart = 1;
  c.$implements$DOMTokenList$Dart = 1;
}
function DOM$fixClass$DOMTokenList(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, [
    'add',
    'contains',
    'item',
    'remove',
    'toString',
    'toggle']);
  c.$implements$DOMTokenList$Dart = 1;
}
function DOM$fixClass$DOMURL(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'createObjectURL',
    'revokeObjectURL']);
  c.$implements$DOMURL$Dart = 1;
}
function DOM$fixClass$DOMWindow(c) {
  if (c.prototype) {
    c.prototype.applicationCache$getter = function() { return DOM$EnsureDartNull(this.applicationCache); };
    c.prototype.clientInformation$getter = function() { return DOM$EnsureDartNull(this.clientInformation); };
    c.prototype.clientInformation$setter = function(value) { this.clientInformation = value; };
    c.prototype.closed$getter = function() { return DOM$EnsureDartNull(this.closed); };
    c.prototype.console$getter = function() { return DOM$EnsureDartNull(this.console); };
    c.prototype.console$setter = function(value) { this.console = value; };
    c.prototype.crypto$getter = function() { return DOM$EnsureDartNull(this.crypto); };
    c.prototype.defaultStatus$getter = function() { return DOM$EnsureDartNull(this.defaultStatus); };
    c.prototype.defaultStatus$setter = function(value) { this.defaultStatus = value; };
    c.prototype.defaultstatus$getter = function() { return DOM$EnsureDartNull(this.defaultstatus); };
    c.prototype.defaultstatus$setter = function(value) { this.defaultstatus = value; };
    c.prototype.devicePixelRatio$getter = function() { return DOM$EnsureDartNull(this.devicePixelRatio); };
    c.prototype.devicePixelRatio$setter = function(value) { this.devicePixelRatio = value; };
    c.prototype.document$getter = function() { return DOM$EnsureDartNull(this.document); };
    c.prototype.event$getter = function() { return DOM$EnsureDartNull(this.event); };
    c.prototype.event$setter = function(value) { this.event = value; };
    c.prototype.frameElement$getter = function() { return DOM$EnsureDartNull(this.frameElement); };
    c.prototype.frames$getter = function() { return DOM$EnsureDartNull(this.frames); };
    c.prototype.frames$setter = function(value) { this.frames = value; };
    c.prototype.history$getter = function() { return DOM$EnsureDartNull(this.history); };
    c.prototype.history$setter = function(value) { this.history = value; };
    c.prototype.innerHeight$getter = function() { return DOM$EnsureDartNull(this.innerHeight); };
    c.prototype.innerHeight$setter = function(value) { this.innerHeight = value; };
    c.prototype.innerWidth$getter = function() { return DOM$EnsureDartNull(this.innerWidth); };
    c.prototype.innerWidth$setter = function(value) { this.innerWidth = value; };
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
    c.prototype.length$setter = function(value) { this.length = value; };
    c.prototype.localStorage$getter = function() { return DOM$EnsureDartNull(this.localStorage); };
    c.prototype.location$getter = function() { return DOM$EnsureDartNull(this.location); };
    c.prototype.location$setter = function(value) { this.location = value; };
    c.prototype.locationbar$getter = function() { return DOM$EnsureDartNull(this.locationbar); };
    c.prototype.locationbar$setter = function(value) { this.locationbar = value; };
    c.prototype.menubar$getter = function() { return DOM$EnsureDartNull(this.menubar); };
    c.prototype.menubar$setter = function(value) { this.menubar = value; };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
    c.prototype.navigator$getter = function() { return DOM$EnsureDartNull(this.navigator); };
    c.prototype.navigator$setter = function(value) { this.navigator = value; };
    c.prototype.offscreenBuffering$getter = function() { return DOM$EnsureDartNull(this.offscreenBuffering); };
    c.prototype.offscreenBuffering$setter = function(value) { this.offscreenBuffering = value; };
    c.prototype.opener$getter = function() { return DOM$EnsureDartNull(this.opener); };
    c.prototype.opener$setter = function(value) { this.opener = value; };
    c.prototype.outerHeight$getter = function() { return DOM$EnsureDartNull(this.outerHeight); };
    c.prototype.outerHeight$setter = function(value) { this.outerHeight = value; };
    c.prototype.outerWidth$getter = function() { return DOM$EnsureDartNull(this.outerWidth); };
    c.prototype.outerWidth$setter = function(value) { this.outerWidth = value; };
    c.prototype.pageXOffset$getter = function() { return DOM$EnsureDartNull(this.pageXOffset); };
    c.prototype.pageYOffset$getter = function() { return DOM$EnsureDartNull(this.pageYOffset); };
    c.prototype.parent$getter = function() { return DOM$EnsureDartNull(this.parent); };
    c.prototype.parent$setter = function(value) { this.parent = value; };
    c.prototype.performance$getter = function() { return DOM$EnsureDartNull(this.performance); };
    c.prototype.performance$setter = function(value) { this.performance = value; };
    c.prototype.personalbar$getter = function() { return DOM$EnsureDartNull(this.personalbar); };
    c.prototype.personalbar$setter = function(value) { this.personalbar = value; };
    c.prototype.screen$getter = function() { return DOM$EnsureDartNull(this.screen); };
    c.prototype.screen$setter = function(value) { this.screen = value; };
    c.prototype.screenLeft$getter = function() { return DOM$EnsureDartNull(this.screenLeft); };
    c.prototype.screenLeft$setter = function(value) { this.screenLeft = value; };
    c.prototype.screenTop$getter = function() { return DOM$EnsureDartNull(this.screenTop); };
    c.prototype.screenTop$setter = function(value) { this.screenTop = value; };
    c.prototype.screenX$getter = function() { return DOM$EnsureDartNull(this.screenX); };
    c.prototype.screenX$setter = function(value) { this.screenX = value; };
    c.prototype.screenY$getter = function() { return DOM$EnsureDartNull(this.screenY); };
    c.prototype.screenY$setter = function(value) { this.screenY = value; };
    c.prototype.scrollX$getter = function() { return DOM$EnsureDartNull(this.scrollX); };
    c.prototype.scrollX$setter = function(value) { this.scrollX = value; };
    c.prototype.scrollY$getter = function() { return DOM$EnsureDartNull(this.scrollY); };
    c.prototype.scrollY$setter = function(value) { this.scrollY = value; };
    c.prototype.scrollbars$getter = function() { return DOM$EnsureDartNull(this.scrollbars); };
    c.prototype.scrollbars$setter = function(value) { this.scrollbars = value; };
    c.prototype.self$getter = function() { return DOM$EnsureDartNull(this.self); };
    c.prototype.self$setter = function(value) { this.self = value; };
    c.prototype.sessionStorage$getter = function() { return DOM$EnsureDartNull(this.sessionStorage); };
    c.prototype.status$getter = function() { return DOM$EnsureDartNull(this.status); };
    c.prototype.status$setter = function(value) { this.status = value; };
    c.prototype.statusbar$getter = function() { return DOM$EnsureDartNull(this.statusbar); };
    c.prototype.statusbar$setter = function(value) { this.statusbar = value; };
    c.prototype.styleMedia$getter = function() { return DOM$EnsureDartNull(this.styleMedia); };
    c.prototype.toolbar$getter = function() { return DOM$EnsureDartNull(this.toolbar); };
    c.prototype.toolbar$setter = function(value) { this.toolbar = value; };
    c.prototype.top$getter = function() { return DOM$EnsureDartNull(this.top); };
    c.prototype.top$setter = function(value) { this.top = value; };
    c.prototype.webkitNotifications$getter = function() { return DOM$fixValue$NotificationCenter(this.webkitNotifications); };
    c.prototype.webkitURL$getter = function() { return DOM$EnsureDartNull(this.webkitURL); };
    c.prototype.window$getter = function() { return DOM$EnsureDartNull(this.window); };
  }
  DOM$fixMembers(c, [
    'addEventListener',
    'alert',
    'atob',
    'blur',
    'btoa',
    'captureEvents',
    'clearInterval',
    'clearTimeout',
    'close',
    'confirm',
    'dispatchEvent',
    'find',
    'focus',
    'getComputedStyle',
    'getMatchedCSSRules',
    'getSelection',
    'matchMedia',
    'moveBy',
    'moveTo',
    'open',
    'postMessage',
    'print',
    'prompt',
    'releaseEvents',
    'removeEventListener',
    'resizeBy',
    'resizeTo',
    'scroll',
    'scrollBy',
    'scrollTo',
    'setInterval',
    'setTimeout',
    'showModalDialog',
    'stop',
    'webkitCancelRequestAnimationFrame',
    'webkitConvertPointFromNodeToPage',
    'webkitConvertPointFromPageToNode',
    'webkitPostMessage',
    'webkitRequestAnimationFrame']);
  c.$implements$DOMWindow$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$DataTransferItem(c) {
  if (c.prototype) {
    c.prototype.kind$getter = function() { return DOM$EnsureDartNull(this.kind); };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
  }
  DOM$fixMembers(c, [
    'getAsFile',
    'getAsString']);
  c.$implements$DataTransferItem$Dart = 1;
}
function DOM$fixClass$DataTransferItemList(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, [
    'add',
    'clear',
    'item']);
  c.$implements$DataTransferItemList$Dart = 1;
}
function DOM$fixClass$DataView(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'getFloat32',
    'getFloat64',
    'getInt16',
    'getInt32',
    'getInt8',
    'getUint16',
    'getUint32',
    'getUint8',
    'setFloat32',
    'setFloat64',
    'setInt16',
    'setInt32',
    'setInt8',
    'setUint16',
    'setUint32',
    'setUint8']);
  c.$implements$DataView$Dart = 1;
  c.$implements$ArrayBufferView$Dart = 1;
}
function DOM$fixClass$Database(c) {
  if (c.prototype) {
    c.prototype.version$getter = function() { return DOM$EnsureDartNull(this.version); };
  }
  DOM$fixMembers(c, [
    'changeVersion',
    'readTransaction',
    'transaction']);
  c.$implements$Database$Dart = 1;
}
function DOM$fixClass$DatabaseCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$DatabaseCallback$Dart = 1;
}
function DOM$fixClass$DatabaseSync(c) {
  if (c.prototype) {
    c.prototype.version$getter = function() { return DOM$EnsureDartNull(this.version); };
  }
  DOM$fixMembers(c, [
    'changeVersion',
    'readTransaction',
    'transaction']);
  c.$implements$DatabaseSync$Dart = 1;
}
function DOM$fixClass$DedicatedWorkerContext(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'postMessage',
    'webkitPostMessage']);
  c.$implements$DedicatedWorkerContext$Dart = 1;
  c.$implements$WorkerContext$Dart = 1;
}
function DOM$fixClass$DeviceMotionEvent(c) {
  if (c.prototype) {
    c.prototype.interval$getter = function() { return DOM$EnsureDartNull(this.interval); };
  }
  c.$implements$DeviceMotionEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$DeviceOrientationEvent(c) {
  if (c.prototype) {
    c.prototype.alpha$getter = function() { return DOM$EnsureDartNull(this.alpha); };
    c.prototype.beta$getter = function() { return DOM$EnsureDartNull(this.beta); };
    c.prototype.gamma$getter = function() { return DOM$EnsureDartNull(this.gamma); };
  }
  DOM$fixMembers(c, ['initDeviceOrientationEvent']);
  c.$implements$DeviceOrientationEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$DirectoryEntry(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'createReader',
    'getDirectory',
    'getFile',
    'removeRecursively']);
  c.$implements$DirectoryEntry$Dart = 1;
  c.$implements$Entry$Dart = 1;
}
function DOM$fixClass$DirectoryEntrySync(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'createReader',
    'getDirectory',
    'getFile',
    'removeRecursively']);
  c.$implements$DirectoryEntrySync$Dart = 1;
  c.$implements$EntrySync$Dart = 1;
}
function DOM$fixClass$DirectoryReader(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['readEntries']);
  c.$implements$DirectoryReader$Dart = 1;
}
function DOM$fixClass$DirectoryReaderSync(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['readEntries']);
  c.$implements$DirectoryReaderSync$Dart = 1;
}
function DOM$fixClass$Document(c) {
  if (c.prototype) {
    c.prototype.URL$getter = function() { return DOM$EnsureDartNull(this.URL); };
    c.prototype.anchors$getter = function() { return DOM$EnsureDartNull(this.anchors); };
    c.prototype.applets$getter = function() { return DOM$EnsureDartNull(this.applets); };
    c.prototype.body$getter = function() { return DOM$EnsureDartNull(this.body); };
    c.prototype.body$setter = function(value) { this.body = value; };
    c.prototype.characterSet$getter = function() { return DOM$EnsureDartNull(this.characterSet); };
    c.prototype.charset$getter = function() { return DOM$EnsureDartNull(this.charset); };
    c.prototype.charset$setter = function(value) { this.charset = value; };
    c.prototype.compatMode$getter = function() { return DOM$EnsureDartNull(this.compatMode); };
    c.prototype.cookie$getter = function() { return DOM$EnsureDartNull(this.cookie); };
    c.prototype.cookie$setter = function(value) { this.cookie = value; };
    c.prototype.defaultCharset$getter = function() { return DOM$EnsureDartNull(this.defaultCharset); };
    c.prototype.defaultView$getter = function() { return DOM$EnsureDartNull(this.defaultView); };
    c.prototype.doctype$getter = function() { return DOM$EnsureDartNull(this.doctype); };
    c.prototype.documentElement$getter = function() { return DOM$EnsureDartNull(this.documentElement); };
    c.prototype.documentURI$getter = function() { return DOM$EnsureDartNull(this.documentURI); };
    c.prototype.documentURI$setter = function(value) { this.documentURI = value; };
    c.prototype.domain$getter = function() { return DOM$EnsureDartNull(this.domain); };
    c.prototype.domain$setter = function(value) { this.domain = value; };
    c.prototype.forms$getter = function() { return DOM$EnsureDartNull(this.forms); };
    c.prototype.head$getter = function() { return DOM$EnsureDartNull(this.head); };
    c.prototype.images$getter = function() { return DOM$EnsureDartNull(this.images); };
    c.prototype.implementation$getter = function() { return DOM$EnsureDartNull(this.implementation); };
    c.prototype.inputEncoding$getter = function() { return DOM$EnsureDartNull(this.inputEncoding); };
    c.prototype.lastModified$getter = function() { return DOM$EnsureDartNull(this.lastModified); };
    c.prototype.links$getter = function() { return DOM$EnsureDartNull(this.links); };
    c.prototype.location$getter = function() { return DOM$EnsureDartNull(this.location); };
    c.prototype.location$setter = function(value) { this.location = value; };
    c.prototype.preferredStylesheetSet$getter = function() { return DOM$EnsureDartNull(this.preferredStylesheetSet); };
    c.prototype.readyState$getter = function() { return DOM$EnsureDartNull(this.readyState); };
    c.prototype.referrer$getter = function() { return DOM$EnsureDartNull(this.referrer); };
    c.prototype.selectedStylesheetSet$getter = function() { return DOM$EnsureDartNull(this.selectedStylesheetSet); };
    c.prototype.selectedStylesheetSet$setter = function(value) { this.selectedStylesheetSet = value; };
    c.prototype.styleSheets$getter = function() { return DOM$EnsureDartNull(this.styleSheets); };
    c.prototype.title$getter = function() { return DOM$EnsureDartNull(this.title); };
    c.prototype.title$setter = function(value) { this.title = value; };
    c.prototype.webkitHidden$getter = function() { return DOM$EnsureDartNull(this.webkitHidden); };
    c.prototype.webkitVisibilityState$getter = function() { return DOM$EnsureDartNull(this.webkitVisibilityState); };
    c.prototype.xmlEncoding$getter = function() { return DOM$EnsureDartNull(this.xmlEncoding); };
    c.prototype.xmlStandalone$getter = function() { return DOM$EnsureDartNull(this.xmlStandalone); };
    c.prototype.xmlStandalone$setter = function(value) { this.xmlStandalone = value; };
    c.prototype.xmlVersion$getter = function() { return DOM$EnsureDartNull(this.xmlVersion); };
    c.prototype.xmlVersion$setter = function(value) { this.xmlVersion = value; };
  }
  DOM$fixMembers(c, [
    'adoptNode',
    'caretRangeFromPoint',
    'createAttribute',
    'createAttributeNS',
    'createCDATASection',
    'createComment',
    'createDocumentFragment',
    'createElement',
    'createElementNS',
    'createEntityReference',
    'createEvent',
    'createExpression',
    'createNSResolver',
    'createNodeIterator',
    'createProcessingInstruction',
    'createRange',
    'createTextNode',
    'createTreeWalker',
    'elementFromPoint',
    'evaluate',
    'execCommand',
    'getCSSCanvasContext',
    'getElementById',
    'getElementsByClassName',
    'getElementsByName',
    'getElementsByTagName',
    'getElementsByTagNameNS',
    'getOverrideStyle',
    'getSelection',
    'importNode',
    'queryCommandEnabled',
    'queryCommandIndeterm',
    'queryCommandState',
    'queryCommandSupported',
    'queryCommandValue',
    'querySelector',
    'querySelectorAll']);
  c.$implements$Document$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
}
function DOM$fixClass$DocumentFragment(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'querySelector',
    'querySelectorAll']);
  c.$implements$DocumentFragment$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
}
function DOM$fixClass$DocumentType(c) {
  if (c.prototype) {
    c.prototype.entities$getter = function() { return DOM$EnsureDartNull(this.entities); };
    c.prototype.internalSubset$getter = function() { return DOM$EnsureDartNull(this.internalSubset); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.notations$getter = function() { return DOM$EnsureDartNull(this.notations); };
    c.prototype.publicId$getter = function() { return DOM$EnsureDartNull(this.publicId); };
    c.prototype.systemId$getter = function() { return DOM$EnsureDartNull(this.systemId); };
  }
  c.$implements$DocumentType$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$Element(c) {
  if (c.prototype) {
    c.prototype.childElementCount$getter = function() { return DOM$EnsureDartNull(this.childElementCount); };
    c.prototype.clientHeight$getter = function() { return DOM$EnsureDartNull(this.clientHeight); };
    c.prototype.clientLeft$getter = function() { return DOM$EnsureDartNull(this.clientLeft); };
    c.prototype.clientTop$getter = function() { return DOM$EnsureDartNull(this.clientTop); };
    c.prototype.clientWidth$getter = function() { return DOM$EnsureDartNull(this.clientWidth); };
    c.prototype.firstElementChild$getter = function() { return DOM$EnsureDartNull(this.firstElementChild); };
    c.prototype.lastElementChild$getter = function() { return DOM$EnsureDartNull(this.lastElementChild); };
    c.prototype.nextElementSibling$getter = function() { return DOM$EnsureDartNull(this.nextElementSibling); };
    c.prototype.offsetHeight$getter = function() { return DOM$EnsureDartNull(this.offsetHeight); };
    c.prototype.offsetLeft$getter = function() { return DOM$EnsureDartNull(this.offsetLeft); };
    c.prototype.offsetParent$getter = function() { return DOM$EnsureDartNull(this.offsetParent); };
    c.prototype.offsetTop$getter = function() { return DOM$EnsureDartNull(this.offsetTop); };
    c.prototype.offsetWidth$getter = function() { return DOM$EnsureDartNull(this.offsetWidth); };
    c.prototype.previousElementSibling$getter = function() { return DOM$EnsureDartNull(this.previousElementSibling); };
    c.prototype.scrollHeight$getter = function() { return DOM$EnsureDartNull(this.scrollHeight); };
    c.prototype.scrollLeft$getter = function() { return DOM$EnsureDartNull(this.scrollLeft); };
    c.prototype.scrollLeft$setter = function(value) { this.scrollLeft = value; };
    c.prototype.scrollTop$getter = function() { return DOM$EnsureDartNull(this.scrollTop); };
    c.prototype.scrollTop$setter = function(value) { this.scrollTop = value; };
    c.prototype.scrollWidth$getter = function() { return DOM$EnsureDartNull(this.scrollWidth); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.tagName$getter = function() { return DOM$EnsureDartNull(this.tagName); };
  }
  DOM$fixMembers(c, [
    'blur',
    'focus',
    'getAttribute',
    'getAttributeNS',
    'getAttributeNode',
    'getAttributeNodeNS',
    'getBoundingClientRect',
    'getClientRects',
    'getElementsByClassName',
    'getElementsByTagName',
    'getElementsByTagNameNS',
    'hasAttribute',
    'hasAttributeNS',
    'querySelector',
    'querySelectorAll',
    'removeAttribute',
    'removeAttributeNS',
    'removeAttributeNode',
    'scrollByLines',
    'scrollByPages',
    'scrollIntoView',
    'scrollIntoViewIfNeeded',
    'setAttribute',
    'setAttributeNS',
    'setAttributeNode',
    'setAttributeNodeNS',
    'webkitMatchesSelector']);
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$ElementTimeControl(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'beginElement',
    'beginElementAt',
    'endElement',
    'endElementAt']);
  c.$implements$ElementTimeControl$Dart = 1;
}
function DOM$fixClass$ElementTraversal(c) {
  if (c.prototype) {
    c.prototype.childElementCount$getter = function() { return DOM$EnsureDartNull(this.childElementCount); };
    c.prototype.firstElementChild$getter = function() { return DOM$EnsureDartNull(this.firstElementChild); };
    c.prototype.lastElementChild$getter = function() { return DOM$EnsureDartNull(this.lastElementChild); };
    c.prototype.nextElementSibling$getter = function() { return DOM$EnsureDartNull(this.nextElementSibling); };
    c.prototype.previousElementSibling$getter = function() { return DOM$EnsureDartNull(this.previousElementSibling); };
  }
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$Entity(c) {
  if (c.prototype) {
    c.prototype.notationName$getter = function() { return DOM$EnsureDartNull(this.notationName); };
    c.prototype.publicId$getter = function() { return DOM$EnsureDartNull(this.publicId); };
    c.prototype.systemId$getter = function() { return DOM$EnsureDartNull(this.systemId); };
  }
  c.$implements$Entity$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$EntityReference(c) {
  if (c.prototype) {
  }
  c.$implements$EntityReference$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$EntriesCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$EntriesCallback$Dart = 1;
}
function DOM$fixClass$Entry(c) {
  if (c.prototype) {
    c.prototype.filesystem$getter = function() { return DOM$EnsureDartNull(this.filesystem); };
    c.prototype.fullPath$getter = function() { return DOM$EnsureDartNull(this.fullPath); };
    c.prototype.isDirectory$getter = function() { return DOM$EnsureDartNull(this.isDirectory); };
    c.prototype.isFile$getter = function() { return DOM$EnsureDartNull(this.isFile); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
  }
  DOM$fixMembers(c, [
    'copyTo',
    'getMetadata',
    'getParent',
    'moveTo',
    'remove',
    'toURL']);
  c.$implements$Entry$Dart = 1;
}
function DOM$fixClass$EntryArray(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, ['item']);
  c.$implements$EntryArray$Dart = 1;
}
function DOM$fixClass$EntryArraySync(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, ['item']);
  c.$implements$EntryArraySync$Dart = 1;
}
function DOM$fixClass$EntryCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$EntryCallback$Dart = 1;
}
function DOM$fixClass$EntrySync(c) {
  if (c.prototype) {
    c.prototype.filesystem$getter = function() { return DOM$EnsureDartNull(this.filesystem); };
    c.prototype.fullPath$getter = function() { return DOM$EnsureDartNull(this.fullPath); };
    c.prototype.isDirectory$getter = function() { return DOM$EnsureDartNull(this.isDirectory); };
    c.prototype.isFile$getter = function() { return DOM$EnsureDartNull(this.isFile); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
  }
  DOM$fixMembers(c, [
    'copyTo',
    'getMetadata',
    'getParent',
    'moveTo',
    'remove',
    'toURL']);
  c.$implements$EntrySync$Dart = 1;
}
function DOM$fixClass$ErrorCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$ErrorCallback$Dart = 1;
}
function DOM$fixClass$ErrorEvent(c) {
  if (c.prototype) {
    c.prototype.filename$getter = function() { return DOM$EnsureDartNull(this.filename); };
    c.prototype.lineno$getter = function() { return DOM$EnsureDartNull(this.lineno); };
    c.prototype.message$getter = function() { return DOM$EnsureDartNull(this.message); };
  }
  DOM$fixMembers(c, ['initErrorEvent']);
  c.$implements$ErrorEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$Event(c) {
  if (c.prototype) {
    c.prototype.bubbles$getter = function() { return DOM$EnsureDartNull(this.bubbles); };
    c.prototype.cancelBubble$getter = function() { return DOM$EnsureDartNull(this.cancelBubble); };
    c.prototype.cancelBubble$setter = function(value) { this.cancelBubble = value; };
    c.prototype.cancelable$getter = function() { return DOM$EnsureDartNull(this.cancelable); };
    c.prototype.clipboardData$getter = function() { return DOM$EnsureDartNull(this.clipboardData); };
    c.prototype.currentTarget$getter = function() { return DOM$EnsureDartNull(this.currentTarget); };
    c.prototype.defaultPrevented$getter = function() { return DOM$EnsureDartNull(this.defaultPrevented); };
    c.prototype.eventPhase$getter = function() { return DOM$EnsureDartNull(this.eventPhase); };
    c.prototype.returnValue$getter = function() { return DOM$EnsureDartNull(this.returnValue); };
    c.prototype.returnValue$setter = function(value) { this.returnValue = value; };
    c.prototype.srcElement$getter = function() { return DOM$EnsureDartNull(this.srcElement); };
    c.prototype.target$getter = function() { return DOM$EnsureDartNull(this.target); };
    c.prototype.timeStamp$getter = function() { return DOM$EnsureDartNull(this.timeStamp); };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
  }
  DOM$fixMembers(c, [
    'initEvent',
    'preventDefault',
    'stopImmediatePropagation',
    'stopPropagation']);
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$EventException(c) {
  if (c.prototype) {
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
    c.prototype.message$getter = function() { return DOM$EnsureDartNull(this.message); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
  }
  DOM$fixMembers(c, ['toString']);
  c.$implements$EventException$Dart = 1;
}
function DOM$fixClass$EventSource(c) {
  if (c.prototype) {
    c.prototype.URL$getter = function() { return DOM$EnsureDartNull(this.URL); };
    c.prototype.readyState$getter = function() { return DOM$EnsureDartNull(this.readyState); };
  }
  DOM$fixMembers(c, [
    'addEventListener',
    'close',
    'dispatchEvent',
    'removeEventListener']);
  c.$implements$EventSource$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$EventTarget(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'addEventListener',
    'dispatchEvent',
    'removeEventListener']);
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$File(c) {
  if (c.prototype) {
    c.prototype.fileName$getter = function() { return DOM$EnsureDartNull(this.fileName); };
    c.prototype.fileSize$getter = function() { return DOM$EnsureDartNull(this.fileSize); };
    c.prototype.lastModifiedDate$getter = function() { return DOM$EnsureDartNull(this.lastModifiedDate); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
  }
  c.$implements$File$Dart = 1;
  c.$implements$Blob$Dart = 1;
}
function DOM$fixClass$FileCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$FileCallback$Dart = 1;
}
function DOM$fixClass$FileEntry(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'createWriter',
    'file']);
  c.$implements$FileEntry$Dart = 1;
  c.$implements$Entry$Dart = 1;
}
function DOM$fixClass$FileEntrySync(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'createWriter',
    'file']);
  c.$implements$FileEntrySync$Dart = 1;
  c.$implements$EntrySync$Dart = 1;
}
function DOM$fixClass$FileError(c) {
  if (c.prototype) {
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
  }
  c.$implements$FileError$Dart = 1;
}
function DOM$fixClass$FileException(c) {
  if (c.prototype) {
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
    c.prototype.message$getter = function() { return DOM$EnsureDartNull(this.message); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
  }
  DOM$fixMembers(c, ['toString']);
  c.$implements$FileException$Dart = 1;
}
function DOM$fixClass$FileList(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, ['item']);
  c.$implements$FileList$Dart = 1;
}
function DOM$fixClass$FileReader(c) {
  if (c.prototype) {
    c.prototype.error$getter = function() { return DOM$EnsureDartNull(this.error); };
    c.prototype.readyState$getter = function() { return DOM$EnsureDartNull(this.readyState); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
  }
  DOM$fixMembers(c, [
    'abort',
    'readAsArrayBuffer',
    'readAsBinaryString',
    'readAsDataURL',
    'readAsText']);
  c.$implements$FileReader$Dart = 1;
}
function DOM$fixClass$FileReaderSync(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'readAsArrayBuffer',
    'readAsBinaryString',
    'readAsDataURL',
    'readAsText']);
  c.$implements$FileReaderSync$Dart = 1;
}
function DOM$fixClass$FileSystemCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$FileSystemCallback$Dart = 1;
}
function DOM$fixClass$FileWriter(c) {
  if (c.prototype) {
    c.prototype.error$getter = function() { return DOM$EnsureDartNull(this.error); };
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
    c.prototype.position$getter = function() { return DOM$EnsureDartNull(this.position); };
    c.prototype.readyState$getter = function() { return DOM$EnsureDartNull(this.readyState); };
  }
  DOM$fixMembers(c, [
    'abort',
    'seek',
    'truncate',
    'write']);
  c.$implements$FileWriter$Dart = 1;
}
function DOM$fixClass$FileWriterCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$FileWriterCallback$Dart = 1;
}
function DOM$fixClass$FileWriterSync(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
    c.prototype.position$getter = function() { return DOM$EnsureDartNull(this.position); };
  }
  DOM$fixMembers(c, [
    'seek',
    'truncate',
    'write']);
  c.$implements$FileWriterSync$Dart = 1;
}
function DOM$fixClass$Float32Array(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, ['subarray']);
  c.$implements$Float32Array$Dart = 1;
  c.$implements$ArrayBufferView$Dart = 1;
}
function DOM$fixClass$Float64Array(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, ['subarray']);
  c.$implements$Float64Array$Dart = 1;
  c.$implements$ArrayBufferView$Dart = 1;
}
function DOM$fixClass$Geolocation(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'clearWatch',
    'getCurrentPosition',
    'watchPosition']);
  c.$implements$Geolocation$Dart = 1;
}
function DOM$fixClass$Geoposition(c) {
  if (c.prototype) {
    c.prototype.coords$getter = function() { return DOM$EnsureDartNull(this.coords); };
    c.prototype.timestamp$getter = function() { return DOM$EnsureDartNull(this.timestamp); };
  }
  c.$implements$Geoposition$Dart = 1;
}
function DOM$fixClass$HTMLAllCollection(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, [
    'item',
    'namedItem',
    'tags']);
  c.$implements$HTMLAllCollection$Dart = 1;
}
function DOM$fixClass$HTMLAnchorElement(c) {
  if (c.prototype) {
    c.prototype.accessKey$getter = function() { return DOM$EnsureDartNull(this.accessKey); };
    c.prototype.accessKey$setter = function(value) { this.accessKey = value; };
    c.prototype.charset$getter = function() { return DOM$EnsureDartNull(this.charset); };
    c.prototype.charset$setter = function(value) { this.charset = value; };
    c.prototype.coords$getter = function() { return DOM$EnsureDartNull(this.coords); };
    c.prototype.coords$setter = function(value) { this.coords = value; };
    c.prototype.download$getter = function() { return DOM$EnsureDartNull(this.download); };
    c.prototype.download$setter = function(value) { this.download = value; };
    c.prototype.hash$getter = function() { return DOM$EnsureDartNull(this.hash); };
    c.prototype.hash$setter = function(value) { this.hash = value; };
    c.prototype.host$getter = function() { return DOM$EnsureDartNull(this.host); };
    c.prototype.host$setter = function(value) { this.host = value; };
    c.prototype.hostname$getter = function() { return DOM$EnsureDartNull(this.hostname); };
    c.prototype.hostname$setter = function(value) { this.hostname = value; };
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.href$setter = function(value) { this.href = value; };
    c.prototype.hreflang$getter = function() { return DOM$EnsureDartNull(this.hreflang); };
    c.prototype.hreflang$setter = function(value) { this.hreflang = value; };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
    c.prototype.origin$getter = function() { return DOM$EnsureDartNull(this.origin); };
    c.prototype.pathname$getter = function() { return DOM$EnsureDartNull(this.pathname); };
    c.prototype.pathname$setter = function(value) { this.pathname = value; };
    c.prototype.ping$getter = function() { return DOM$EnsureDartNull(this.ping); };
    c.prototype.ping$setter = function(value) { this.ping = value; };
    c.prototype.port$getter = function() { return DOM$EnsureDartNull(this.port); };
    c.prototype.port$setter = function(value) { this.port = value; };
    c.prototype.protocol$getter = function() { return DOM$EnsureDartNull(this.protocol); };
    c.prototype.protocol$setter = function(value) { this.protocol = value; };
    c.prototype.rel$getter = function() { return DOM$EnsureDartNull(this.rel); };
    c.prototype.rel$setter = function(value) { this.rel = value; };
    c.prototype.rev$getter = function() { return DOM$EnsureDartNull(this.rev); };
    c.prototype.rev$setter = function(value) { this.rev = value; };
    c.prototype.search$getter = function() { return DOM$EnsureDartNull(this.search); };
    c.prototype.search$setter = function(value) { this.search = value; };
    c.prototype.shape$getter = function() { return DOM$EnsureDartNull(this.shape); };
    c.prototype.shape$setter = function(value) { this.shape = value; };
    c.prototype.target$getter = function() { return DOM$EnsureDartNull(this.target); };
    c.prototype.target$setter = function(value) { this.target = value; };
    c.prototype.text$getter = function() { return DOM$EnsureDartNull(this.text); };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.type$setter = function(value) { this.type = value; };
  }
  DOM$fixMembers(c, [
    'getParameter',
    'toString']);
  c.$implements$HTMLAnchorElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLAppletElement(c) {
  if (c.prototype) {
    c.prototype.align$getter = function() { return DOM$EnsureDartNull(this.align); };
    c.prototype.align$setter = function(value) { this.align = value; };
    c.prototype.alt$getter = function() { return DOM$EnsureDartNull(this.alt); };
    c.prototype.alt$setter = function(value) { this.alt = value; };
    c.prototype.archive$getter = function() { return DOM$EnsureDartNull(this.archive); };
    c.prototype.archive$setter = function(value) { this.archive = value; };
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
    c.prototype.code$setter = function(value) { this.code = value; };
    c.prototype.codeBase$getter = function() { return DOM$EnsureDartNull(this.codeBase); };
    c.prototype.codeBase$setter = function(value) { this.codeBase = value; };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.height$setter = function(value) { this.height = value; };
    c.prototype.hspace$getter = function() { return DOM$EnsureDartNull(this.hspace); };
    c.prototype.hspace$setter = function(value) { this.hspace = value; };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
    c.prototype.object$getter = function() { return DOM$EnsureDartNull(this.object); };
    c.prototype.object$setter = function(value) { this.object = value; };
    c.prototype.vspace$getter = function() { return DOM$EnsureDartNull(this.vspace); };
    c.prototype.vspace$setter = function(value) { this.vspace = value; };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.width$setter = function(value) { this.width = value; };
  }
  c.$implements$HTMLAppletElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLAreaElement(c) {
  if (c.prototype) {
    c.prototype.accessKey$getter = function() { return DOM$EnsureDartNull(this.accessKey); };
    c.prototype.accessKey$setter = function(value) { this.accessKey = value; };
    c.prototype.alt$getter = function() { return DOM$EnsureDartNull(this.alt); };
    c.prototype.alt$setter = function(value) { this.alt = value; };
    c.prototype.coords$getter = function() { return DOM$EnsureDartNull(this.coords); };
    c.prototype.coords$setter = function(value) { this.coords = value; };
    c.prototype.hash$getter = function() { return DOM$EnsureDartNull(this.hash); };
    c.prototype.host$getter = function() { return DOM$EnsureDartNull(this.host); };
    c.prototype.hostname$getter = function() { return DOM$EnsureDartNull(this.hostname); };
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.href$setter = function(value) { this.href = value; };
    c.prototype.noHref$getter = function() { return DOM$EnsureDartNull(this.noHref); };
    c.prototype.noHref$setter = function(value) { this.noHref = value; };
    c.prototype.pathname$getter = function() { return DOM$EnsureDartNull(this.pathname); };
    c.prototype.ping$getter = function() { return DOM$EnsureDartNull(this.ping); };
    c.prototype.ping$setter = function(value) { this.ping = value; };
    c.prototype.port$getter = function() { return DOM$EnsureDartNull(this.port); };
    c.prototype.protocol$getter = function() { return DOM$EnsureDartNull(this.protocol); };
    c.prototype.search$getter = function() { return DOM$EnsureDartNull(this.search); };
    c.prototype.shape$getter = function() { return DOM$EnsureDartNull(this.shape); };
    c.prototype.shape$setter = function(value) { this.shape = value; };
    c.prototype.target$getter = function() { return DOM$EnsureDartNull(this.target); };
    c.prototype.target$setter = function(value) { this.target = value; };
  }
  c.$implements$HTMLAreaElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLAudioElement(c) {
  if (c.prototype) {
  }
  c.$implements$HTMLAudioElement$Dart = 1;
  c.$implements$HTMLMediaElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLBRElement(c) {
  if (c.prototype) {
    c.prototype.clear$getter = function() { return DOM$EnsureDartNull(this.clear); };
    c.prototype.clear$setter = function(value) { this.clear = value; };
  }
  c.$implements$HTMLBRElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLBaseElement(c) {
  if (c.prototype) {
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.href$setter = function(value) { this.href = value; };
    c.prototype.target$getter = function() { return DOM$EnsureDartNull(this.target); };
    c.prototype.target$setter = function(value) { this.target = value; };
  }
  c.$implements$HTMLBaseElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLBaseFontElement(c) {
  if (c.prototype) {
    c.prototype.color$getter = function() { return DOM$EnsureDartNull(this.color); };
    c.prototype.color$setter = function(value) { this.color = value; };
    c.prototype.face$getter = function() { return DOM$EnsureDartNull(this.face); };
    c.prototype.face$setter = function(value) { this.face = value; };
    c.prototype.size$getter = function() { return DOM$EnsureDartNull(this.size); };
    c.prototype.size$setter = function(value) { this.size = value; };
  }
  c.$implements$HTMLBaseFontElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLBodyElement(c) {
  if (c.prototype) {
    c.prototype.aLink$getter = function() { return DOM$EnsureDartNull(this.aLink); };
    c.prototype.aLink$setter = function(value) { this.aLink = value; };
    c.prototype.background$getter = function() { return DOM$EnsureDartNull(this.background); };
    c.prototype.background$setter = function(value) { this.background = value; };
    c.prototype.bgColor$getter = function() { return DOM$EnsureDartNull(this.bgColor); };
    c.prototype.bgColor$setter = function(value) { this.bgColor = value; };
    c.prototype.link$getter = function() { return DOM$EnsureDartNull(this.link); };
    c.prototype.link$setter = function(value) { this.link = value; };
    c.prototype.text$getter = function() { return DOM$EnsureDartNull(this.text); };
    c.prototype.text$setter = function(value) { this.text = value; };
    c.prototype.vLink$getter = function() { return DOM$EnsureDartNull(this.vLink); };
    c.prototype.vLink$setter = function(value) { this.vLink = value; };
  }
  c.$implements$HTMLBodyElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLButtonElement(c) {
  if (c.prototype) {
    c.prototype.accessKey$getter = function() { return DOM$EnsureDartNull(this.accessKey); };
    c.prototype.accessKey$setter = function(value) { this.accessKey = value; };
    c.prototype.autofocus$getter = function() { return DOM$EnsureDartNull(this.autofocus); };
    c.prototype.autofocus$setter = function(value) { this.autofocus = value; };
    c.prototype.disabled$getter = function() { return DOM$EnsureDartNull(this.disabled); };
    c.prototype.disabled$setter = function(value) { this.disabled = value; };
    c.prototype.form$getter = function() { return DOM$EnsureDartNull(this.form); };
    c.prototype.formAction$getter = function() { return DOM$EnsureDartNull(this.formAction); };
    c.prototype.formAction$setter = function(value) { this.formAction = value; };
    c.prototype.formEnctype$getter = function() { return DOM$EnsureDartNull(this.formEnctype); };
    c.prototype.formEnctype$setter = function(value) { this.formEnctype = value; };
    c.prototype.formMethod$getter = function() { return DOM$EnsureDartNull(this.formMethod); };
    c.prototype.formMethod$setter = function(value) { this.formMethod = value; };
    c.prototype.formNoValidate$getter = function() { return DOM$EnsureDartNull(this.formNoValidate); };
    c.prototype.formNoValidate$setter = function(value) { this.formNoValidate = value; };
    c.prototype.formTarget$getter = function() { return DOM$EnsureDartNull(this.formTarget); };
    c.prototype.formTarget$setter = function(value) { this.formTarget = value; };
    c.prototype.labels$getter = function() { return DOM$EnsureDartNull(this.labels); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.validationMessage$getter = function() { return DOM$EnsureDartNull(this.validationMessage); };
    c.prototype.validity$getter = function() { return DOM$EnsureDartNull(this.validity); };
    c.prototype.value$getter = function() { return DOM$EnsureDartNull(this.value); };
    c.prototype.value$setter = function(value) { this.value = value; };
    c.prototype.willValidate$getter = function() { return DOM$EnsureDartNull(this.willValidate); };
  }
  DOM$fixMembers(c, [
    'checkValidity',
    'click',
    'setCustomValidity']);
  c.$implements$HTMLButtonElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLCanvasElement(c) {
  if (c.prototype) {
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.height$setter = function(value) { this.height = value; };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.width$setter = function(value) { this.width = value; };
  }
  DOM$fixMembers(c, [
    'getContext',
    'toDataURL']);
  c.$implements$HTMLCanvasElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLCollection(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
    c.prototype.INDEX$operator = function(k) { return DOM$EnsureDartNull(this[k]); };
    c.prototype.ASSIGN_INDEX$operator = function(k, v) { this[k] = v; };
  }
  DOM$fixMembers(c, [
    'item',
    'namedItem']);
  c.$implements$HTMLCollection$Dart = 1;
}
function DOM$fixClass$HTMLDListElement(c) {
  if (c.prototype) {
    c.prototype.compact$getter = function() { return DOM$EnsureDartNull(this.compact); };
    c.prototype.compact$setter = function(value) { this.compact = value; };
  }
  c.$implements$HTMLDListElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLDataListElement(c) {
  if (c.prototype) {
    c.prototype.options$getter = function() { return DOM$EnsureDartNull(this.options); };
  }
  c.$implements$HTMLDataListElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLDetailsElement(c) {
  if (c.prototype) {
    c.prototype.open$getter = function() { return DOM$EnsureDartNull(this.open); };
    c.prototype.open$setter = function(value) { this.open = value; };
  }
  c.$implements$HTMLDetailsElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLDirectoryElement(c) {
  if (c.prototype) {
    c.prototype.compact$getter = function() { return DOM$EnsureDartNull(this.compact); };
    c.prototype.compact$setter = function(value) { this.compact = value; };
  }
  c.$implements$HTMLDirectoryElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLDivElement(c) {
  if (c.prototype) {
    c.prototype.align$getter = function() { return DOM$EnsureDartNull(this.align); };
    c.prototype.align$setter = function(value) { this.align = value; };
  }
  c.$implements$HTMLDivElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLDocument(c) {
  if (c.prototype) {
    c.prototype.activeElement$getter = function() { return DOM$EnsureDartNull(this.activeElement); };
    c.prototype.alinkColor$getter = function() { return DOM$EnsureDartNull(this.alinkColor); };
    c.prototype.alinkColor$setter = function(value) { this.alinkColor = value; };
    c.prototype.all$getter = function() { return DOM$EnsureDartNull(this.all); };
    c.prototype.all$setter = function(value) { this.all = value; };
    c.prototype.bgColor$getter = function() { return DOM$EnsureDartNull(this.bgColor); };
    c.prototype.bgColor$setter = function(value) { this.bgColor = value; };
    c.prototype.compatMode$getter = function() { return DOM$EnsureDartNull(this.compatMode); };
    c.prototype.designMode$getter = function() { return DOM$EnsureDartNull(this.designMode); };
    c.prototype.designMode$setter = function(value) { this.designMode = value; };
    c.prototype.dir$getter = function() { return DOM$EnsureDartNull(this.dir); };
    c.prototype.dir$setter = function(value) { this.dir = value; };
    c.prototype.embeds$getter = function() { return DOM$EnsureDartNull(this.embeds); };
    c.prototype.fgColor$getter = function() { return DOM$EnsureDartNull(this.fgColor); };
    c.prototype.fgColor$setter = function(value) { this.fgColor = value; };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.linkColor$getter = function() { return DOM$EnsureDartNull(this.linkColor); };
    c.prototype.linkColor$setter = function(value) { this.linkColor = value; };
    c.prototype.plugins$getter = function() { return DOM$EnsureDartNull(this.plugins); };
    c.prototype.scripts$getter = function() { return DOM$EnsureDartNull(this.scripts); };
    c.prototype.vlinkColor$getter = function() { return DOM$EnsureDartNull(this.vlinkColor); };
    c.prototype.vlinkColor$setter = function(value) { this.vlinkColor = value; };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
  }
  DOM$fixMembers(c, [
    'captureEvents',
    'clear',
    'close',
    'hasFocus',
    'open',
    'releaseEvents',
    'write',
    'writeln']);
  c.$implements$HTMLDocument$Dart = 1;
  c.$implements$Document$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
}
function DOM$fixClass$HTMLElement(c) {
  if (c.prototype) {
    c.prototype.children$getter = function() { return DOM$EnsureDartNull(this.children); };
    c.prototype.classList$getter = function() { return DOM$EnsureDartNull(this.classList); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.className$setter = function(value) { this.className = value; };
    c.prototype.contentEditable$getter = function() { return DOM$EnsureDartNull(this.contentEditable); };
    c.prototype.contentEditable$setter = function(value) { this.contentEditable = value; };
    c.prototype.dir$getter = function() { return DOM$EnsureDartNull(this.dir); };
    c.prototype.dir$setter = function(value) { this.dir = value; };
    c.prototype.draggable$getter = function() { return DOM$EnsureDartNull(this.draggable); };
    c.prototype.draggable$setter = function(value) { this.draggable = value; };
    c.prototype.hidden$getter = function() { return DOM$EnsureDartNull(this.hidden); };
    c.prototype.hidden$setter = function(value) { this.hidden = value; };
    c.prototype.id$getter = function() { return DOM$EnsureDartNull(this.id); };
    c.prototype.id$setter = function(value) { this.id = value; };
    c.prototype.innerHTML$getter = function() { return DOM$EnsureDartNull(this.innerHTML); };
    c.prototype.innerHTML$setter = function(value) { this.innerHTML = value; };
    c.prototype.innerText$getter = function() { return DOM$EnsureDartNull(this.innerText); };
    c.prototype.innerText$setter = function(value) { this.innerText = value; };
    c.prototype.isContentEditable$getter = function() { return DOM$EnsureDartNull(this.isContentEditable); };
    c.prototype.itemId$getter = function() { return DOM$EnsureDartNull(this.itemId); };
    c.prototype.itemId$setter = function(value) { this.itemId = value; };
    c.prototype.itemProp$getter = function() { return DOM$EnsureDartNull(this.itemProp); };
    c.prototype.itemRef$getter = function() { return DOM$EnsureDartNull(this.itemRef); };
    c.prototype.itemScope$getter = function() { return DOM$EnsureDartNull(this.itemScope); };
    c.prototype.itemScope$setter = function(value) { this.itemScope = value; };
    c.prototype.itemType$getter = function() { return DOM$EnsureDartNull(this.itemType); };
    c.prototype.itemValue$getter = function() { return DOM$EnsureDartNull(this.itemValue); };
    c.prototype.itemValue$setter = function(value) { this.itemValue = value; };
    c.prototype.lang$getter = function() { return DOM$EnsureDartNull(this.lang); };
    c.prototype.lang$setter = function(value) { this.lang = value; };
    c.prototype.outerHTML$getter = function() { return DOM$EnsureDartNull(this.outerHTML); };
    c.prototype.outerHTML$setter = function(value) { this.outerHTML = value; };
    c.prototype.outerText$getter = function() { return DOM$EnsureDartNull(this.outerText); };
    c.prototype.outerText$setter = function(value) { this.outerText = value; };
    c.prototype.spellcheck$getter = function() { return DOM$EnsureDartNull(this.spellcheck); };
    c.prototype.spellcheck$setter = function(value) { this.spellcheck = value; };
    c.prototype.tabIndex$getter = function() { return DOM$EnsureDartNull(this.tabIndex); };
    c.prototype.tabIndex$setter = function(value) { this.tabIndex = value; };
    c.prototype.title$getter = function() { return DOM$EnsureDartNull(this.title); };
    c.prototype.title$setter = function(value) { this.title = value; };
    c.prototype.webkitdropzone$getter = function() { return DOM$EnsureDartNull(this.webkitdropzone); };
    c.prototype.webkitdropzone$setter = function(value) { this.webkitdropzone = value; };
  }
  DOM$fixMembers(c, [
    'insertAdjacentElement',
    'insertAdjacentHTML',
    'insertAdjacentText']);
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLEmbedElement(c) {
  if (c.prototype) {
    c.prototype.align$getter = function() { return DOM$EnsureDartNull(this.align); };
    c.prototype.align$setter = function(value) { this.align = value; };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.height$setter = function(value) { this.height = value; };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
    c.prototype.src$getter = function() { return DOM$EnsureDartNull(this.src); };
    c.prototype.src$setter = function(value) { this.src = value; };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.type$setter = function(value) { this.type = value; };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.width$setter = function(value) { this.width = value; };
  }
  c.$implements$HTMLEmbedElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLFieldSetElement(c) {
  if (c.prototype) {
    c.prototype.form$getter = function() { return DOM$EnsureDartNull(this.form); };
    c.prototype.validationMessage$getter = function() { return DOM$EnsureDartNull(this.validationMessage); };
    c.prototype.validity$getter = function() { return DOM$EnsureDartNull(this.validity); };
    c.prototype.willValidate$getter = function() { return DOM$EnsureDartNull(this.willValidate); };
  }
  DOM$fixMembers(c, [
    'checkValidity',
    'setCustomValidity']);
  c.$implements$HTMLFieldSetElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLFontElement(c) {
  if (c.prototype) {
    c.prototype.color$getter = function() { return DOM$EnsureDartNull(this.color); };
    c.prototype.color$setter = function(value) { this.color = value; };
    c.prototype.face$getter = function() { return DOM$EnsureDartNull(this.face); };
    c.prototype.face$setter = function(value) { this.face = value; };
    c.prototype.size$getter = function() { return DOM$EnsureDartNull(this.size); };
    c.prototype.size$setter = function(value) { this.size = value; };
  }
  c.$implements$HTMLFontElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLFormElement(c) {
  if (c.prototype) {
    c.prototype.acceptCharset$getter = function() { return DOM$EnsureDartNull(this.acceptCharset); };
    c.prototype.acceptCharset$setter = function(value) { this.acceptCharset = value; };
    c.prototype.action$getter = function() { return DOM$EnsureDartNull(this.action); };
    c.prototype.action$setter = function(value) { this.action = value; };
    c.prototype.autocomplete$getter = function() { return DOM$EnsureDartNull(this.autocomplete); };
    c.prototype.autocomplete$setter = function(value) { this.autocomplete = value; };
    c.prototype.elements$getter = function() { return DOM$EnsureDartNull(this.elements); };
    c.prototype.encoding$getter = function() { return DOM$EnsureDartNull(this.encoding); };
    c.prototype.encoding$setter = function(value) { this.encoding = value; };
    c.prototype.enctype$getter = function() { return DOM$EnsureDartNull(this.enctype); };
    c.prototype.enctype$setter = function(value) { this.enctype = value; };
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
    c.prototype.method$getter = function() { return DOM$EnsureDartNull(this.method); };
    c.prototype.method$setter = function(value) { this.method = value; };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
    c.prototype.noValidate$getter = function() { return DOM$EnsureDartNull(this.noValidate); };
    c.prototype.noValidate$setter = function(value) { this.noValidate = value; };
    c.prototype.target$getter = function() { return DOM$EnsureDartNull(this.target); };
    c.prototype.target$setter = function(value) { this.target = value; };
  }
  DOM$fixMembers(c, [
    'checkValidity',
    'reset']);
  c.prototype.submit$member = function() {
    return DOM$EnsureDartNull(this.submitFromJavaScript.apply(this, arguments));
  };
  c.$implements$HTMLFormElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLFrameElement(c) {
  if (c.prototype) {
    c.prototype.contentDocument$getter = function() { return DOM$EnsureDartNull(this.contentDocument); };
    c.prototype.contentWindow$getter = function() { return DOM$EnsureDartNull(this.contentWindow); };
    c.prototype.frameBorder$getter = function() { return DOM$EnsureDartNull(this.frameBorder); };
    c.prototype.frameBorder$setter = function(value) { this.frameBorder = value; };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.location$getter = function() { return DOM$EnsureDartNull(this.location); };
    c.prototype.location$setter = function(value) { this.location = value; };
    c.prototype.longDesc$getter = function() { return DOM$EnsureDartNull(this.longDesc); };
    c.prototype.longDesc$setter = function(value) { this.longDesc = value; };
    c.prototype.marginHeight$getter = function() { return DOM$EnsureDartNull(this.marginHeight); };
    c.prototype.marginHeight$setter = function(value) { this.marginHeight = value; };
    c.prototype.marginWidth$getter = function() { return DOM$EnsureDartNull(this.marginWidth); };
    c.prototype.marginWidth$setter = function(value) { this.marginWidth = value; };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
    c.prototype.noResize$getter = function() { return DOM$EnsureDartNull(this.noResize); };
    c.prototype.noResize$setter = function(value) { this.noResize = value; };
    c.prototype.scrolling$getter = function() { return DOM$EnsureDartNull(this.scrolling); };
    c.prototype.scrolling$setter = function(value) { this.scrolling = value; };
    c.prototype.src$getter = function() { return DOM$EnsureDartNull(this.src); };
    c.prototype.src$setter = function(value) { this.src = value; };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
  }
  c.$implements$HTMLFrameElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLFrameSetElement(c) {
  if (c.prototype) {
    c.prototype.cols$getter = function() { return DOM$EnsureDartNull(this.cols); };
    c.prototype.cols$setter = function(value) { this.cols = value; };
    c.prototype.rows$getter = function() { return DOM$EnsureDartNull(this.rows); };
    c.prototype.rows$setter = function(value) { this.rows = value; };
  }
  c.$implements$HTMLFrameSetElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLHRElement(c) {
  if (c.prototype) {
    c.prototype.align$getter = function() { return DOM$EnsureDartNull(this.align); };
    c.prototype.align$setter = function(value) { this.align = value; };
    c.prototype.noShade$getter = function() { return DOM$EnsureDartNull(this.noShade); };
    c.prototype.noShade$setter = function(value) { this.noShade = value; };
    c.prototype.size$getter = function() { return DOM$EnsureDartNull(this.size); };
    c.prototype.size$setter = function(value) { this.size = value; };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.width$setter = function(value) { this.width = value; };
  }
  c.$implements$HTMLHRElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLHeadElement(c) {
  if (c.prototype) {
    c.prototype.profile$getter = function() { return DOM$EnsureDartNull(this.profile); };
    c.prototype.profile$setter = function(value) { this.profile = value; };
  }
  c.$implements$HTMLHeadElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLHeadingElement(c) {
  if (c.prototype) {
    c.prototype.align$getter = function() { return DOM$EnsureDartNull(this.align); };
    c.prototype.align$setter = function(value) { this.align = value; };
  }
  c.$implements$HTMLHeadingElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLHtmlElement(c) {
  if (c.prototype) {
    c.prototype.manifest$getter = function() { return DOM$EnsureDartNull(this.manifest); };
    c.prototype.manifest$setter = function(value) { this.manifest = value; };
    c.prototype.version$getter = function() { return DOM$EnsureDartNull(this.version); };
    c.prototype.version$setter = function(value) { this.version = value; };
  }
  c.$implements$HTMLHtmlElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLIFrameElement(c) {
  if (c.prototype) {
    c.prototype.align$getter = function() { return DOM$EnsureDartNull(this.align); };
    c.prototype.align$setter = function(value) { this.align = value; };
    c.prototype.contentDocument$getter = function() { return DOM$EnsureDartNull(this.contentDocument); };
    c.prototype.contentWindow$getter = function() { return DOM$EnsureDartNull(this.contentWindow); };
    c.prototype.frameBorder$getter = function() { return DOM$EnsureDartNull(this.frameBorder); };
    c.prototype.frameBorder$setter = function(value) { this.frameBorder = value; };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.height$setter = function(value) { this.height = value; };
    c.prototype.longDesc$getter = function() { return DOM$EnsureDartNull(this.longDesc); };
    c.prototype.longDesc$setter = function(value) { this.longDesc = value; };
    c.prototype.marginHeight$getter = function() { return DOM$EnsureDartNull(this.marginHeight); };
    c.prototype.marginHeight$setter = function(value) { this.marginHeight = value; };
    c.prototype.marginWidth$getter = function() { return DOM$EnsureDartNull(this.marginWidth); };
    c.prototype.marginWidth$setter = function(value) { this.marginWidth = value; };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
    c.prototype.sandbox$getter = function() { return DOM$EnsureDartNull(this.sandbox); };
    c.prototype.sandbox$setter = function(value) { this.sandbox = value; };
    c.prototype.scrolling$getter = function() { return DOM$EnsureDartNull(this.scrolling); };
    c.prototype.scrolling$setter = function(value) { this.scrolling = value; };
    c.prototype.src$getter = function() { return DOM$EnsureDartNull(this.src); };
    c.prototype.src$setter = function(value) { this.src = value; };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.width$setter = function(value) { this.width = value; };
  }
  c.$implements$HTMLIFrameElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLImageElement(c) {
  if (c.prototype) {
    c.prototype.align$getter = function() { return DOM$EnsureDartNull(this.align); };
    c.prototype.align$setter = function(value) { this.align = value; };
    c.prototype.alt$getter = function() { return DOM$EnsureDartNull(this.alt); };
    c.prototype.alt$setter = function(value) { this.alt = value; };
    c.prototype.border$getter = function() { return DOM$EnsureDartNull(this.border); };
    c.prototype.border$setter = function(value) { this.border = value; };
    c.prototype.complete$getter = function() { return DOM$EnsureDartNull(this.complete); };
    c.prototype.crossOrigin$getter = function() { return DOM$EnsureDartNull(this.crossOrigin); };
    c.prototype.crossOrigin$setter = function(value) { this.crossOrigin = value; };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.height$setter = function(value) { this.height = value; };
    c.prototype.hspace$getter = function() { return DOM$EnsureDartNull(this.hspace); };
    c.prototype.hspace$setter = function(value) { this.hspace = value; };
    c.prototype.isMap$getter = function() { return DOM$EnsureDartNull(this.isMap); };
    c.prototype.isMap$setter = function(value) { this.isMap = value; };
    c.prototype.longDesc$getter = function() { return DOM$EnsureDartNull(this.longDesc); };
    c.prototype.longDesc$setter = function(value) { this.longDesc = value; };
    c.prototype.lowsrc$getter = function() { return DOM$EnsureDartNull(this.lowsrc); };
    c.prototype.lowsrc$setter = function(value) { this.lowsrc = value; };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
    c.prototype.naturalHeight$getter = function() { return DOM$EnsureDartNull(this.naturalHeight); };
    c.prototype.naturalWidth$getter = function() { return DOM$EnsureDartNull(this.naturalWidth); };
    c.prototype.src$getter = function() { return DOM$EnsureDartNull(this.src); };
    c.prototype.src$setter = function(value) { this.src = value; };
    c.prototype.useMap$getter = function() { return DOM$EnsureDartNull(this.useMap); };
    c.prototype.useMap$setter = function(value) { this.useMap = value; };
    c.prototype.vspace$getter = function() { return DOM$EnsureDartNull(this.vspace); };
    c.prototype.vspace$setter = function(value) { this.vspace = value; };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.width$setter = function(value) { this.width = value; };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
  }
  c.$implements$HTMLImageElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLInputElement(c) {
  if (c.prototype) {
    c.prototype.accept$getter = function() { return DOM$EnsureDartNull(this.accept); };
    c.prototype.accept$setter = function(value) { this.accept = value; };
    c.prototype.accessKey$getter = function() { return DOM$EnsureDartNull(this.accessKey); };
    c.prototype.accessKey$setter = function(value) { this.accessKey = value; };
    c.prototype.align$getter = function() { return DOM$EnsureDartNull(this.align); };
    c.prototype.align$setter = function(value) { this.align = value; };
    c.prototype.alt$getter = function() { return DOM$EnsureDartNull(this.alt); };
    c.prototype.alt$setter = function(value) { this.alt = value; };
    c.prototype.autocomplete$getter = function() { return DOM$EnsureDartNull(this.autocomplete); };
    c.prototype.autocomplete$setter = function(value) { this.autocomplete = value; };
    c.prototype.autofocus$getter = function() { return DOM$EnsureDartNull(this.autofocus); };
    c.prototype.autofocus$setter = function(value) { this.autofocus = value; };
    c.prototype.checked$getter = function() { return DOM$EnsureDartNull(this.checked); };
    c.prototype.checked$setter = function(value) { this.checked = value; };
    c.prototype.defaultChecked$getter = function() { return DOM$EnsureDartNull(this.defaultChecked); };
    c.prototype.defaultChecked$setter = function(value) { this.defaultChecked = value; };
    c.prototype.defaultValue$getter = function() { return DOM$EnsureDartNull(this.defaultValue); };
    c.prototype.defaultValue$setter = function(value) { this.defaultValue = value; };
    c.prototype.disabled$getter = function() { return DOM$EnsureDartNull(this.disabled); };
    c.prototype.disabled$setter = function(value) { this.disabled = value; };
    c.prototype.files$getter = function() { return DOM$EnsureDartNull(this.files); };
    c.prototype.form$getter = function() { return DOM$EnsureDartNull(this.form); };
    c.prototype.formAction$getter = function() { return DOM$EnsureDartNull(this.formAction); };
    c.prototype.formAction$setter = function(value) { this.formAction = value; };
    c.prototype.formEnctype$getter = function() { return DOM$EnsureDartNull(this.formEnctype); };
    c.prototype.formEnctype$setter = function(value) { this.formEnctype = value; };
    c.prototype.formMethod$getter = function() { return DOM$EnsureDartNull(this.formMethod); };
    c.prototype.formMethod$setter = function(value) { this.formMethod = value; };
    c.prototype.formNoValidate$getter = function() { return DOM$EnsureDartNull(this.formNoValidate); };
    c.prototype.formNoValidate$setter = function(value) { this.formNoValidate = value; };
    c.prototype.formTarget$getter = function() { return DOM$EnsureDartNull(this.formTarget); };
    c.prototype.formTarget$setter = function(value) { this.formTarget = value; };
    c.prototype.incremental$getter = function() { return DOM$EnsureDartNull(this.incremental); };
    c.prototype.incremental$setter = function(value) { this.incremental = value; };
    c.prototype.indeterminate$getter = function() { return DOM$EnsureDartNull(this.indeterminate); };
    c.prototype.indeterminate$setter = function(value) { this.indeterminate = value; };
    c.prototype.labels$getter = function() { return DOM$EnsureDartNull(this.labels); };
    c.prototype.list$getter = function() { return DOM$EnsureDartNull(this.list); };
    c.prototype.max$getter = function() { return DOM$EnsureDartNull(this.max); };
    c.prototype.max$setter = function(value) { this.max = value; };
    c.prototype.maxLength$getter = function() { return DOM$EnsureDartNull(this.maxLength); };
    c.prototype.maxLength$setter = function(value) { this.maxLength = value; };
    c.prototype.min$getter = function() { return DOM$EnsureDartNull(this.min); };
    c.prototype.min$setter = function(value) { this.min = value; };
    c.prototype.multiple$getter = function() { return DOM$EnsureDartNull(this.multiple); };
    c.prototype.multiple$setter = function(value) { this.multiple = value; };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
    c.prototype.pattern$getter = function() { return DOM$EnsureDartNull(this.pattern); };
    c.prototype.pattern$setter = function(value) { this.pattern = value; };
    c.prototype.placeholder$getter = function() { return DOM$EnsureDartNull(this.placeholder); };
    c.prototype.placeholder$setter = function(value) { this.placeholder = value; };
    c.prototype.readOnly$getter = function() { return DOM$EnsureDartNull(this.readOnly); };
    c.prototype.readOnly$setter = function(value) { this.readOnly = value; };
    c.prototype.required$getter = function() { return DOM$EnsureDartNull(this.required); };
    c.prototype.required$setter = function(value) { this.required = value; };
    c.prototype.selectedOption$getter = function() { return DOM$EnsureDartNull(this.selectedOption); };
    c.prototype.selectionDirection$getter = function() { return DOM$EnsureDartNull(this.selectionDirection); };
    c.prototype.selectionDirection$setter = function(value) { this.selectionDirection = value; };
    c.prototype.selectionEnd$getter = function() { return DOM$EnsureDartNull(this.selectionEnd); };
    c.prototype.selectionEnd$setter = function(value) { this.selectionEnd = value; };
    c.prototype.selectionStart$getter = function() { return DOM$EnsureDartNull(this.selectionStart); };
    c.prototype.selectionStart$setter = function(value) { this.selectionStart = value; };
    c.prototype.size$getter = function() { return DOM$EnsureDartNull(this.size); };
    c.prototype.size$setter = function(value) { this.size = value; };
    c.prototype.src$getter = function() { return DOM$EnsureDartNull(this.src); };
    c.prototype.src$setter = function(value) { this.src = value; };
    c.prototype.step$getter = function() { return DOM$EnsureDartNull(this.step); };
    c.prototype.step$setter = function(value) { this.step = value; };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.type$setter = function(value) { this.type = value; };
    c.prototype.useMap$getter = function() { return DOM$EnsureDartNull(this.useMap); };
    c.prototype.useMap$setter = function(value) { this.useMap = value; };
    c.prototype.validationMessage$getter = function() { return DOM$EnsureDartNull(this.validationMessage); };
    c.prototype.validity$getter = function() { return DOM$EnsureDartNull(this.validity); };
    c.prototype.value$getter = function() { return DOM$EnsureDartNull(this.value); };
    c.prototype.value$setter = function(value) { this.value = value; };
    c.prototype.valueAsDate$getter = function() { return DOM$EnsureDartNull(this.valueAsDate); };
    c.prototype.valueAsDate$setter = function(value) { this.valueAsDate = value; };
    c.prototype.valueAsNumber$getter = function() { return DOM$EnsureDartNull(this.valueAsNumber); };
    c.prototype.valueAsNumber$setter = function(value) { this.valueAsNumber = value; };
    c.prototype.webkitGrammar$getter = function() { return DOM$EnsureDartNull(this.webkitGrammar); };
    c.prototype.webkitGrammar$setter = function(value) { this.webkitGrammar = value; };
    c.prototype.webkitSpeech$getter = function() { return DOM$EnsureDartNull(this.webkitSpeech); };
    c.prototype.webkitSpeech$setter = function(value) { this.webkitSpeech = value; };
    c.prototype.webkitdirectory$getter = function() { return DOM$EnsureDartNull(this.webkitdirectory); };
    c.prototype.webkitdirectory$setter = function(value) { this.webkitdirectory = value; };
    c.prototype.willValidate$getter = function() { return DOM$EnsureDartNull(this.willValidate); };
  }
  DOM$fixMembers(c, [
    'checkValidity',
    'click',
    'select',
    'setCustomValidity',
    'setSelectionRange',
    'stepDown',
    'stepUp']);
  c.$implements$HTMLInputElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLIsIndexElement(c) {
  if (c.prototype) {
    c.prototype.form$getter = function() { return DOM$EnsureDartNull(this.form); };
    c.prototype.prompt$getter = function() { return DOM$EnsureDartNull(this.prompt); };
    c.prototype.prompt$setter = function(value) { this.prompt = value; };
  }
  c.$implements$HTMLIsIndexElement$Dart = 1;
  c.$implements$HTMLInputElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLKeygenElement(c) {
  if (c.prototype) {
    c.prototype.autofocus$getter = function() { return DOM$EnsureDartNull(this.autofocus); };
    c.prototype.autofocus$setter = function(value) { this.autofocus = value; };
    c.prototype.challenge$getter = function() { return DOM$EnsureDartNull(this.challenge); };
    c.prototype.challenge$setter = function(value) { this.challenge = value; };
    c.prototype.disabled$getter = function() { return DOM$EnsureDartNull(this.disabled); };
    c.prototype.disabled$setter = function(value) { this.disabled = value; };
    c.prototype.form$getter = function() { return DOM$EnsureDartNull(this.form); };
    c.prototype.keytype$getter = function() { return DOM$EnsureDartNull(this.keytype); };
    c.prototype.keytype$setter = function(value) { this.keytype = value; };
    c.prototype.labels$getter = function() { return DOM$EnsureDartNull(this.labels); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.validationMessage$getter = function() { return DOM$EnsureDartNull(this.validationMessage); };
    c.prototype.validity$getter = function() { return DOM$EnsureDartNull(this.validity); };
    c.prototype.willValidate$getter = function() { return DOM$EnsureDartNull(this.willValidate); };
  }
  DOM$fixMembers(c, [
    'checkValidity',
    'setCustomValidity']);
  c.$implements$HTMLKeygenElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLLIElement(c) {
  if (c.prototype) {
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.type$setter = function(value) { this.type = value; };
    c.prototype.value$getter = function() { return DOM$EnsureDartNull(this.value); };
    c.prototype.value$setter = function(value) { this.value = value; };
  }
  c.$implements$HTMLLIElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLLabelElement(c) {
  if (c.prototype) {
    c.prototype.accessKey$getter = function() { return DOM$EnsureDartNull(this.accessKey); };
    c.prototype.accessKey$setter = function(value) { this.accessKey = value; };
    c.prototype.control$getter = function() { return DOM$EnsureDartNull(this.control); };
    c.prototype.form$getter = function() { return DOM$EnsureDartNull(this.form); };
    c.prototype.htmlFor$getter = function() { return DOM$EnsureDartNull(this.htmlFor); };
    c.prototype.htmlFor$setter = function(value) { this.htmlFor = value; };
  }
  c.$implements$HTMLLabelElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLLegendElement(c) {
  if (c.prototype) {
    c.prototype.accessKey$getter = function() { return DOM$EnsureDartNull(this.accessKey); };
    c.prototype.accessKey$setter = function(value) { this.accessKey = value; };
    c.prototype.align$getter = function() { return DOM$EnsureDartNull(this.align); };
    c.prototype.align$setter = function(value) { this.align = value; };
    c.prototype.form$getter = function() { return DOM$EnsureDartNull(this.form); };
  }
  c.$implements$HTMLLegendElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLLinkElement(c) {
  if (c.prototype) {
    c.prototype.charset$getter = function() { return DOM$EnsureDartNull(this.charset); };
    c.prototype.charset$setter = function(value) { this.charset = value; };
    c.prototype.disabled$getter = function() { return DOM$EnsureDartNull(this.disabled); };
    c.prototype.disabled$setter = function(value) { this.disabled = value; };
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.href$setter = function(value) { this.href = value; };
    c.prototype.hreflang$getter = function() { return DOM$EnsureDartNull(this.hreflang); };
    c.prototype.hreflang$setter = function(value) { this.hreflang = value; };
    c.prototype.media$getter = function() { return DOM$EnsureDartNull(this.media); };
    c.prototype.media$setter = function(value) { this.media = value; };
    c.prototype.rel$getter = function() { return DOM$EnsureDartNull(this.rel); };
    c.prototype.rel$setter = function(value) { this.rel = value; };
    c.prototype.rev$getter = function() { return DOM$EnsureDartNull(this.rev); };
    c.prototype.rev$setter = function(value) { this.rev = value; };
    c.prototype.sheet$getter = function() { return DOM$EnsureDartNull(this.sheet); };
    c.prototype.sizes$getter = function() { return DOM$EnsureDartNull(this.sizes); };
    c.prototype.sizes$setter = function(value) { this.sizes = value; };
    c.prototype.target$getter = function() { return DOM$EnsureDartNull(this.target); };
    c.prototype.target$setter = function(value) { this.target = value; };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.type$setter = function(value) { this.type = value; };
  }
  c.$implements$HTMLLinkElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLMapElement(c) {
  if (c.prototype) {
    c.prototype.areas$getter = function() { return DOM$EnsureDartNull(this.areas); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
  }
  c.$implements$HTMLMapElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLMarqueeElement(c) {
  if (c.prototype) {
    c.prototype.behavior$getter = function() { return DOM$EnsureDartNull(this.behavior); };
    c.prototype.behavior$setter = function(value) { this.behavior = value; };
    c.prototype.bgColor$getter = function() { return DOM$EnsureDartNull(this.bgColor); };
    c.prototype.bgColor$setter = function(value) { this.bgColor = value; };
    c.prototype.direction$getter = function() { return DOM$EnsureDartNull(this.direction); };
    c.prototype.direction$setter = function(value) { this.direction = value; };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.height$setter = function(value) { this.height = value; };
    c.prototype.hspace$getter = function() { return DOM$EnsureDartNull(this.hspace); };
    c.prototype.hspace$setter = function(value) { this.hspace = value; };
    c.prototype.loop$getter = function() { return DOM$EnsureDartNull(this.loop); };
    c.prototype.loop$setter = function(value) { this.loop = value; };
    c.prototype.scrollAmount$getter = function() { return DOM$EnsureDartNull(this.scrollAmount); };
    c.prototype.scrollAmount$setter = function(value) { this.scrollAmount = value; };
    c.prototype.scrollDelay$getter = function() { return DOM$EnsureDartNull(this.scrollDelay); };
    c.prototype.scrollDelay$setter = function(value) { this.scrollDelay = value; };
    c.prototype.trueSpeed$getter = function() { return DOM$EnsureDartNull(this.trueSpeed); };
    c.prototype.trueSpeed$setter = function(value) { this.trueSpeed = value; };
    c.prototype.vspace$getter = function() { return DOM$EnsureDartNull(this.vspace); };
    c.prototype.vspace$setter = function(value) { this.vspace = value; };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.width$setter = function(value) { this.width = value; };
  }
  DOM$fixMembers(c, [
    'start',
    'stop']);
  c.$implements$HTMLMarqueeElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLMediaElement(c) {
  if (c.prototype) {
    c.prototype.autoplay$getter = function() { return DOM$EnsureDartNull(this.autoplay); };
    c.prototype.autoplay$setter = function(value) { this.autoplay = value; };
    c.prototype.buffered$getter = function() { return DOM$EnsureDartNull(this.buffered); };
    c.prototype.controls$getter = function() { return DOM$EnsureDartNull(this.controls); };
    c.prototype.controls$setter = function(value) { this.controls = value; };
    c.prototype.currentSrc$getter = function() { return DOM$EnsureDartNull(this.currentSrc); };
    c.prototype.currentTime$getter = function() { return DOM$EnsureDartNull(this.currentTime); };
    c.prototype.currentTime$setter = function(value) { this.currentTime = value; };
    c.prototype.defaultMuted$getter = function() { return DOM$EnsureDartNull(this.defaultMuted); };
    c.prototype.defaultMuted$setter = function(value) { this.defaultMuted = value; };
    c.prototype.defaultPlaybackRate$getter = function() { return DOM$EnsureDartNull(this.defaultPlaybackRate); };
    c.prototype.defaultPlaybackRate$setter = function(value) { this.defaultPlaybackRate = value; };
    c.prototype.duration$getter = function() { return DOM$EnsureDartNull(this.duration); };
    c.prototype.ended$getter = function() { return DOM$EnsureDartNull(this.ended); };
    c.prototype.error$getter = function() { return DOM$EnsureDartNull(this.error); };
    c.prototype.initialTime$getter = function() { return DOM$EnsureDartNull(this.initialTime); };
    c.prototype.loop$getter = function() { return DOM$EnsureDartNull(this.loop); };
    c.prototype.loop$setter = function(value) { this.loop = value; };
    c.prototype.muted$getter = function() { return DOM$EnsureDartNull(this.muted); };
    c.prototype.muted$setter = function(value) { this.muted = value; };
    c.prototype.networkState$getter = function() { return DOM$EnsureDartNull(this.networkState); };
    c.prototype.paused$getter = function() { return DOM$EnsureDartNull(this.paused); };
    c.prototype.playbackRate$getter = function() { return DOM$EnsureDartNull(this.playbackRate); };
    c.prototype.playbackRate$setter = function(value) { this.playbackRate = value; };
    c.prototype.played$getter = function() { return DOM$EnsureDartNull(this.played); };
    c.prototype.preload$getter = function() { return DOM$EnsureDartNull(this.preload); };
    c.prototype.preload$setter = function(value) { this.preload = value; };
    c.prototype.readyState$getter = function() { return DOM$EnsureDartNull(this.readyState); };
    c.prototype.seekable$getter = function() { return DOM$EnsureDartNull(this.seekable); };
    c.prototype.seeking$getter = function() { return DOM$EnsureDartNull(this.seeking); };
    c.prototype.src$getter = function() { return DOM$EnsureDartNull(this.src); };
    c.prototype.src$setter = function(value) { this.src = value; };
    c.prototype.startTime$getter = function() { return DOM$EnsureDartNull(this.startTime); };
    c.prototype.volume$getter = function() { return DOM$EnsureDartNull(this.volume); };
    c.prototype.volume$setter = function(value) { this.volume = value; };
    c.prototype.webkitAudioDecodedByteCount$getter = function() { return DOM$EnsureDartNull(this.webkitAudioDecodedByteCount); };
    c.prototype.webkitClosedCaptionsVisible$getter = function() { return DOM$EnsureDartNull(this.webkitClosedCaptionsVisible); };
    c.prototype.webkitClosedCaptionsVisible$setter = function(value) { this.webkitClosedCaptionsVisible = value; };
    c.prototype.webkitHasClosedCaptions$getter = function() { return DOM$EnsureDartNull(this.webkitHasClosedCaptions); };
    c.prototype.webkitPreservesPitch$getter = function() { return DOM$EnsureDartNull(this.webkitPreservesPitch); };
    c.prototype.webkitPreservesPitch$setter = function(value) { this.webkitPreservesPitch = value; };
    c.prototype.webkitVideoDecodedByteCount$getter = function() { return DOM$EnsureDartNull(this.webkitVideoDecodedByteCount); };
  }
  DOM$fixMembers(c, [
    'canPlayType',
    'load',
    'pause',
    'play']);
  c.$implements$HTMLMediaElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLMenuElement(c) {
  if (c.prototype) {
    c.prototype.compact$getter = function() { return DOM$EnsureDartNull(this.compact); };
    c.prototype.compact$setter = function(value) { this.compact = value; };
  }
  c.$implements$HTMLMenuElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLMetaElement(c) {
  if (c.prototype) {
    c.prototype.content$getter = function() { return DOM$EnsureDartNull(this.content); };
    c.prototype.content$setter = function(value) { this.content = value; };
    c.prototype.httpEquiv$getter = function() { return DOM$EnsureDartNull(this.httpEquiv); };
    c.prototype.httpEquiv$setter = function(value) { this.httpEquiv = value; };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
    c.prototype.scheme$getter = function() { return DOM$EnsureDartNull(this.scheme); };
    c.prototype.scheme$setter = function(value) { this.scheme = value; };
  }
  c.$implements$HTMLMetaElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLMeterElement(c) {
  if (c.prototype) {
    c.prototype.form$getter = function() { return DOM$EnsureDartNull(this.form); };
    c.prototype.high$getter = function() { return DOM$EnsureDartNull(this.high); };
    c.prototype.high$setter = function(value) { this.high = value; };
    c.prototype.labels$getter = function() { return DOM$EnsureDartNull(this.labels); };
    c.prototype.low$getter = function() { return DOM$EnsureDartNull(this.low); };
    c.prototype.low$setter = function(value) { this.low = value; };
    c.prototype.max$getter = function() { return DOM$EnsureDartNull(this.max); };
    c.prototype.max$setter = function(value) { this.max = value; };
    c.prototype.min$getter = function() { return DOM$EnsureDartNull(this.min); };
    c.prototype.min$setter = function(value) { this.min = value; };
    c.prototype.optimum$getter = function() { return DOM$EnsureDartNull(this.optimum); };
    c.prototype.optimum$setter = function(value) { this.optimum = value; };
    c.prototype.value$getter = function() { return DOM$EnsureDartNull(this.value); };
    c.prototype.value$setter = function(value) { this.value = value; };
  }
  c.$implements$HTMLMeterElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLModElement(c) {
  if (c.prototype) {
    c.prototype.cite$getter = function() { return DOM$EnsureDartNull(this.cite); };
    c.prototype.cite$setter = function(value) { this.cite = value; };
    c.prototype.dateTime$getter = function() { return DOM$EnsureDartNull(this.dateTime); };
    c.prototype.dateTime$setter = function(value) { this.dateTime = value; };
  }
  c.$implements$HTMLModElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLOListElement(c) {
  if (c.prototype) {
    c.prototype.compact$getter = function() { return DOM$EnsureDartNull(this.compact); };
    c.prototype.compact$setter = function(value) { this.compact = value; };
    c.prototype.start$getter = function() { return DOM$EnsureDartNull(this.start); };
    c.prototype.start$setter = function(value) { this.start = value; };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.type$setter = function(value) { this.type = value; };
  }
  c.$implements$HTMLOListElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLObjectElement(c) {
  if (c.prototype) {
    c.prototype.align$getter = function() { return DOM$EnsureDartNull(this.align); };
    c.prototype.align$setter = function(value) { this.align = value; };
    c.prototype.archive$getter = function() { return DOM$EnsureDartNull(this.archive); };
    c.prototype.archive$setter = function(value) { this.archive = value; };
    c.prototype.border$getter = function() { return DOM$EnsureDartNull(this.border); };
    c.prototype.border$setter = function(value) { this.border = value; };
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
    c.prototype.code$setter = function(value) { this.code = value; };
    c.prototype.codeBase$getter = function() { return DOM$EnsureDartNull(this.codeBase); };
    c.prototype.codeBase$setter = function(value) { this.codeBase = value; };
    c.prototype.codeType$getter = function() { return DOM$EnsureDartNull(this.codeType); };
    c.prototype.codeType$setter = function(value) { this.codeType = value; };
    c.prototype.contentDocument$getter = function() { return DOM$EnsureDartNull(this.contentDocument); };
    c.prototype.data$getter = function() { return DOM$EnsureDartNull(this.data); };
    c.prototype.data$setter = function(value) { this.data = value; };
    c.prototype.declare$getter = function() { return DOM$EnsureDartNull(this.declare); };
    c.prototype.declare$setter = function(value) { this.declare = value; };
    c.prototype.form$getter = function() { return DOM$EnsureDartNull(this.form); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.height$setter = function(value) { this.height = value; };
    c.prototype.hspace$getter = function() { return DOM$EnsureDartNull(this.hspace); };
    c.prototype.hspace$setter = function(value) { this.hspace = value; };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
    c.prototype.standby$getter = function() { return DOM$EnsureDartNull(this.standby); };
    c.prototype.standby$setter = function(value) { this.standby = value; };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.type$setter = function(value) { this.type = value; };
    c.prototype.useMap$getter = function() { return DOM$EnsureDartNull(this.useMap); };
    c.prototype.useMap$setter = function(value) { this.useMap = value; };
    c.prototype.validationMessage$getter = function() { return DOM$EnsureDartNull(this.validationMessage); };
    c.prototype.validity$getter = function() { return DOM$EnsureDartNull(this.validity); };
    c.prototype.vspace$getter = function() { return DOM$EnsureDartNull(this.vspace); };
    c.prototype.vspace$setter = function(value) { this.vspace = value; };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.width$setter = function(value) { this.width = value; };
    c.prototype.willValidate$getter = function() { return DOM$EnsureDartNull(this.willValidate); };
  }
  DOM$fixMembers(c, [
    'checkValidity',
    'setCustomValidity']);
  c.$implements$HTMLObjectElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLOptGroupElement(c) {
  if (c.prototype) {
    c.prototype.disabled$getter = function() { return DOM$EnsureDartNull(this.disabled); };
    c.prototype.disabled$setter = function(value) { this.disabled = value; };
    c.prototype.label$getter = function() { return DOM$EnsureDartNull(this.label); };
    c.prototype.label$setter = function(value) { this.label = value; };
  }
  c.$implements$HTMLOptGroupElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLOptionElement(c) {
  if (c.prototype) {
    c.prototype.defaultSelected$getter = function() { return DOM$EnsureDartNull(this.defaultSelected); };
    c.prototype.defaultSelected$setter = function(value) { this.defaultSelected = value; };
    c.prototype.disabled$getter = function() { return DOM$EnsureDartNull(this.disabled); };
    c.prototype.disabled$setter = function(value) { this.disabled = value; };
    c.prototype.form$getter = function() { return DOM$EnsureDartNull(this.form); };
    c.prototype.index$getter = function() { return DOM$EnsureDartNull(this.index); };
    c.prototype.label$getter = function() { return DOM$EnsureDartNull(this.label); };
    c.prototype.label$setter = function(value) { this.label = value; };
    c.prototype.selected$getter = function() { return DOM$EnsureDartNull(this.selected); };
    c.prototype.selected$setter = function(value) { this.selected = value; };
    c.prototype.text$getter = function() { return DOM$EnsureDartNull(this.text); };
    c.prototype.text$setter = function(value) { this.text = value; };
    c.prototype.value$getter = function() { return DOM$EnsureDartNull(this.value); };
    c.prototype.value$setter = function(value) { this.value = value; };
  }
  c.$implements$HTMLOptionElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLOptionsCollection(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
    c.prototype.length$setter = function(value) { this.length = value; };
    c.prototype.selectedIndex$getter = function() { return DOM$EnsureDartNull(this.selectedIndex); };
    c.prototype.selectedIndex$setter = function(value) { this.selectedIndex = value; };
  }
  DOM$fixMembers(c, ['remove']);
  c.$implements$HTMLOptionsCollection$Dart = 1;
  c.$implements$HTMLCollection$Dart = 1;
}
function DOM$fixClass$HTMLOutputElement(c) {
  if (c.prototype) {
    c.prototype.defaultValue$getter = function() { return DOM$EnsureDartNull(this.defaultValue); };
    c.prototype.defaultValue$setter = function(value) { this.defaultValue = value; };
    c.prototype.form$getter = function() { return DOM$EnsureDartNull(this.form); };
    c.prototype.htmlFor$getter = function() { return DOM$EnsureDartNull(this.htmlFor); };
    c.prototype.htmlFor$setter = function(value) { this.htmlFor = value; };
    c.prototype.labels$getter = function() { return DOM$EnsureDartNull(this.labels); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.validationMessage$getter = function() { return DOM$EnsureDartNull(this.validationMessage); };
    c.prototype.validity$getter = function() { return DOM$EnsureDartNull(this.validity); };
    c.prototype.value$getter = function() { return DOM$EnsureDartNull(this.value); };
    c.prototype.value$setter = function(value) { this.value = value; };
    c.prototype.willValidate$getter = function() { return DOM$EnsureDartNull(this.willValidate); };
  }
  DOM$fixMembers(c, [
    'checkValidity',
    'setCustomValidity']);
  c.$implements$HTMLOutputElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLParagraphElement(c) {
  if (c.prototype) {
    c.prototype.align$getter = function() { return DOM$EnsureDartNull(this.align); };
    c.prototype.align$setter = function(value) { this.align = value; };
  }
  c.$implements$HTMLParagraphElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLParamElement(c) {
  if (c.prototype) {
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.type$setter = function(value) { this.type = value; };
    c.prototype.value$getter = function() { return DOM$EnsureDartNull(this.value); };
    c.prototype.value$setter = function(value) { this.value = value; };
    c.prototype.valueType$getter = function() { return DOM$EnsureDartNull(this.valueType); };
    c.prototype.valueType$setter = function(value) { this.valueType = value; };
  }
  c.$implements$HTMLParamElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLPreElement(c) {
  if (c.prototype) {
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.width$setter = function(value) { this.width = value; };
    c.prototype.wrap$getter = function() { return DOM$EnsureDartNull(this.wrap); };
    c.prototype.wrap$setter = function(value) { this.wrap = value; };
  }
  c.$implements$HTMLPreElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLProgressElement(c) {
  if (c.prototype) {
    c.prototype.form$getter = function() { return DOM$EnsureDartNull(this.form); };
    c.prototype.labels$getter = function() { return DOM$EnsureDartNull(this.labels); };
    c.prototype.max$getter = function() { return DOM$EnsureDartNull(this.max); };
    c.prototype.max$setter = function(value) { this.max = value; };
    c.prototype.position$getter = function() { return DOM$EnsureDartNull(this.position); };
    c.prototype.value$getter = function() { return DOM$EnsureDartNull(this.value); };
    c.prototype.value$setter = function(value) { this.value = value; };
  }
  c.$implements$HTMLProgressElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLQuoteElement(c) {
  if (c.prototype) {
    c.prototype.cite$getter = function() { return DOM$EnsureDartNull(this.cite); };
    c.prototype.cite$setter = function(value) { this.cite = value; };
  }
  c.$implements$HTMLQuoteElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLScriptElement(c) {
  if (c.prototype) {
    c.prototype.async$getter = function() { return DOM$EnsureDartNull(this.async); };
    c.prototype.async$setter = function(value) { this.async = value; };
    c.prototype.charset$getter = function() { return DOM$EnsureDartNull(this.charset); };
    c.prototype.charset$setter = function(value) { this.charset = value; };
    c.prototype.defer$getter = function() { return DOM$EnsureDartNull(this.defer); };
    c.prototype.defer$setter = function(value) { this.defer = value; };
    c.prototype.event$getter = function() { return DOM$EnsureDartNull(this.event); };
    c.prototype.event$setter = function(value) { this.event = value; };
    c.prototype.htmlFor$getter = function() { return DOM$EnsureDartNull(this.htmlFor); };
    c.prototype.htmlFor$setter = function(value) { this.htmlFor = value; };
    c.prototype.src$getter = function() { return DOM$EnsureDartNull(this.src); };
    c.prototype.src$setter = function(value) { this.src = value; };
    c.prototype.text$getter = function() { return DOM$EnsureDartNull(this.text); };
    c.prototype.text$setter = function(value) { this.text = value; };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.type$setter = function(value) { this.type = value; };
  }
  c.$implements$HTMLScriptElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLSelectElement(c) {
  if (c.prototype) {
    c.prototype.autofocus$getter = function() { return DOM$EnsureDartNull(this.autofocus); };
    c.prototype.autofocus$setter = function(value) { this.autofocus = value; };
    c.prototype.disabled$getter = function() { return DOM$EnsureDartNull(this.disabled); };
    c.prototype.disabled$setter = function(value) { this.disabled = value; };
    c.prototype.form$getter = function() { return DOM$EnsureDartNull(this.form); };
    c.prototype.labels$getter = function() { return DOM$EnsureDartNull(this.labels); };
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
    c.prototype.length$setter = function(value) { this.length = value; };
    c.prototype.multiple$getter = function() { return DOM$EnsureDartNull(this.multiple); };
    c.prototype.multiple$setter = function(value) { this.multiple = value; };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
    c.prototype.options$getter = function() { return DOM$EnsureDartNull(this.options); };
    c.prototype.required$getter = function() { return DOM$EnsureDartNull(this.required); };
    c.prototype.required$setter = function(value) { this.required = value; };
    c.prototype.selectedIndex$getter = function() { return DOM$EnsureDartNull(this.selectedIndex); };
    c.prototype.selectedIndex$setter = function(value) { this.selectedIndex = value; };
    c.prototype.size$getter = function() { return DOM$EnsureDartNull(this.size); };
    c.prototype.size$setter = function(value) { this.size = value; };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.validationMessage$getter = function() { return DOM$EnsureDartNull(this.validationMessage); };
    c.prototype.validity$getter = function() { return DOM$EnsureDartNull(this.validity); };
    c.prototype.value$getter = function() { return DOM$EnsureDartNull(this.value); };
    c.prototype.value$setter = function(value) { this.value = value; };
    c.prototype.willValidate$getter = function() { return DOM$EnsureDartNull(this.willValidate); };
  }
  DOM$fixMembers(c, [
    'add',
    'checkValidity',
    'item',
    'namedItem',
    'remove',
    'setCustomValidity']);
  c.$implements$HTMLSelectElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLSourceElement(c) {
  if (c.prototype) {
    c.prototype.media$getter = function() { return DOM$EnsureDartNull(this.media); };
    c.prototype.media$setter = function(value) { this.media = value; };
    c.prototype.src$getter = function() { return DOM$EnsureDartNull(this.src); };
    c.prototype.src$setter = function(value) { this.src = value; };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.type$setter = function(value) { this.type = value; };
  }
  c.$implements$HTMLSourceElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLSpanElement(c) {
  if (c.prototype) {
  }
  c.$implements$HTMLSpanElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLStyleElement(c) {
  if (c.prototype) {
    c.prototype.disabled$getter = function() { return DOM$EnsureDartNull(this.disabled); };
    c.prototype.disabled$setter = function(value) { this.disabled = value; };
    c.prototype.media$getter = function() { return DOM$EnsureDartNull(this.media); };
    c.prototype.media$setter = function(value) { this.media = value; };
    c.prototype.sheet$getter = function() { return DOM$EnsureDartNull(this.sheet); };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.type$setter = function(value) { this.type = value; };
  }
  c.$implements$HTMLStyleElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLTableCaptionElement(c) {
  if (c.prototype) {
    c.prototype.align$getter = function() { return DOM$EnsureDartNull(this.align); };
    c.prototype.align$setter = function(value) { this.align = value; };
  }
  c.$implements$HTMLTableCaptionElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLTableCellElement(c) {
  if (c.prototype) {
    c.prototype.abbr$getter = function() { return DOM$EnsureDartNull(this.abbr); };
    c.prototype.abbr$setter = function(value) { this.abbr = value; };
    c.prototype.align$getter = function() { return DOM$EnsureDartNull(this.align); };
    c.prototype.align$setter = function(value) { this.align = value; };
    c.prototype.axis$getter = function() { return DOM$EnsureDartNull(this.axis); };
    c.prototype.axis$setter = function(value) { this.axis = value; };
    c.prototype.bgColor$getter = function() { return DOM$EnsureDartNull(this.bgColor); };
    c.prototype.bgColor$setter = function(value) { this.bgColor = value; };
    c.prototype.cellIndex$getter = function() { return DOM$EnsureDartNull(this.cellIndex); };
    c.prototype.ch$getter = function() { return DOM$EnsureDartNull(this.ch); };
    c.prototype.ch$setter = function(value) { this.ch = value; };
    c.prototype.chOff$getter = function() { return DOM$EnsureDartNull(this.chOff); };
    c.prototype.chOff$setter = function(value) { this.chOff = value; };
    c.prototype.colSpan$getter = function() { return DOM$EnsureDartNull(this.colSpan); };
    c.prototype.colSpan$setter = function(value) { this.colSpan = value; };
    c.prototype.headers$getter = function() { return DOM$EnsureDartNull(this.headers); };
    c.prototype.headers$setter = function(value) { this.headers = value; };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.height$setter = function(value) { this.height = value; };
    c.prototype.noWrap$getter = function() { return DOM$EnsureDartNull(this.noWrap); };
    c.prototype.noWrap$setter = function(value) { this.noWrap = value; };
    c.prototype.rowSpan$getter = function() { return DOM$EnsureDartNull(this.rowSpan); };
    c.prototype.rowSpan$setter = function(value) { this.rowSpan = value; };
    c.prototype.scope$getter = function() { return DOM$EnsureDartNull(this.scope); };
    c.prototype.scope$setter = function(value) { this.scope = value; };
    c.prototype.vAlign$getter = function() { return DOM$EnsureDartNull(this.vAlign); };
    c.prototype.vAlign$setter = function(value) { this.vAlign = value; };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.width$setter = function(value) { this.width = value; };
  }
  c.$implements$HTMLTableCellElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLTableColElement(c) {
  if (c.prototype) {
    c.prototype.align$getter = function() { return DOM$EnsureDartNull(this.align); };
    c.prototype.align$setter = function(value) { this.align = value; };
    c.prototype.ch$getter = function() { return DOM$EnsureDartNull(this.ch); };
    c.prototype.ch$setter = function(value) { this.ch = value; };
    c.prototype.chOff$getter = function() { return DOM$EnsureDartNull(this.chOff); };
    c.prototype.chOff$setter = function(value) { this.chOff = value; };
    c.prototype.span$getter = function() { return DOM$EnsureDartNull(this.span); };
    c.prototype.span$setter = function(value) { this.span = value; };
    c.prototype.vAlign$getter = function() { return DOM$EnsureDartNull(this.vAlign); };
    c.prototype.vAlign$setter = function(value) { this.vAlign = value; };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.width$setter = function(value) { this.width = value; };
  }
  c.$implements$HTMLTableColElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLTableElement(c) {
  if (c.prototype) {
    c.prototype.align$getter = function() { return DOM$EnsureDartNull(this.align); };
    c.prototype.align$setter = function(value) { this.align = value; };
    c.prototype.bgColor$getter = function() { return DOM$EnsureDartNull(this.bgColor); };
    c.prototype.bgColor$setter = function(value) { this.bgColor = value; };
    c.prototype.border$getter = function() { return DOM$EnsureDartNull(this.border); };
    c.prototype.border$setter = function(value) { this.border = value; };
    c.prototype.caption$getter = function() { return DOM$EnsureDartNull(this.caption); };
    c.prototype.caption$setter = function(value) { this.caption = value; };
    c.prototype.cellPadding$getter = function() { return DOM$EnsureDartNull(this.cellPadding); };
    c.prototype.cellPadding$setter = function(value) { this.cellPadding = value; };
    c.prototype.cellSpacing$getter = function() { return DOM$EnsureDartNull(this.cellSpacing); };
    c.prototype.cellSpacing$setter = function(value) { this.cellSpacing = value; };
    c.prototype.frame$getter = function() { return DOM$EnsureDartNull(this.frame); };
    c.prototype.frame$setter = function(value) { this.frame = value; };
    c.prototype.rows$getter = function() { return DOM$EnsureDartNull(this.rows); };
    c.prototype.rules$getter = function() { return DOM$EnsureDartNull(this.rules); };
    c.prototype.rules$setter = function(value) { this.rules = value; };
    c.prototype.summary$getter = function() { return DOM$EnsureDartNull(this.summary); };
    c.prototype.summary$setter = function(value) { this.summary = value; };
    c.prototype.tBodies$getter = function() { return DOM$EnsureDartNull(this.tBodies); };
    c.prototype.tFoot$getter = function() { return DOM$EnsureDartNull(this.tFoot); };
    c.prototype.tFoot$setter = function(value) { this.tFoot = value; };
    c.prototype.tHead$getter = function() { return DOM$EnsureDartNull(this.tHead); };
    c.prototype.tHead$setter = function(value) { this.tHead = value; };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.width$setter = function(value) { this.width = value; };
  }
  DOM$fixMembers(c, [
    'createCaption',
    'createTFoot',
    'createTHead',
    'deleteCaption',
    'deleteRow',
    'deleteTFoot',
    'deleteTHead',
    'insertRow']);
  c.$implements$HTMLTableElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLTableRowElement(c) {
  if (c.prototype) {
    c.prototype.align$getter = function() { return DOM$EnsureDartNull(this.align); };
    c.prototype.align$setter = function(value) { this.align = value; };
    c.prototype.bgColor$getter = function() { return DOM$EnsureDartNull(this.bgColor); };
    c.prototype.bgColor$setter = function(value) { this.bgColor = value; };
    c.prototype.cells$getter = function() { return DOM$EnsureDartNull(this.cells); };
    c.prototype.ch$getter = function() { return DOM$EnsureDartNull(this.ch); };
    c.prototype.ch$setter = function(value) { this.ch = value; };
    c.prototype.chOff$getter = function() { return DOM$EnsureDartNull(this.chOff); };
    c.prototype.chOff$setter = function(value) { this.chOff = value; };
    c.prototype.rowIndex$getter = function() { return DOM$EnsureDartNull(this.rowIndex); };
    c.prototype.sectionRowIndex$getter = function() { return DOM$EnsureDartNull(this.sectionRowIndex); };
    c.prototype.vAlign$getter = function() { return DOM$EnsureDartNull(this.vAlign); };
    c.prototype.vAlign$setter = function(value) { this.vAlign = value; };
  }
  DOM$fixMembers(c, [
    'deleteCell',
    'insertCell']);
  c.$implements$HTMLTableRowElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLTableSectionElement(c) {
  if (c.prototype) {
    c.prototype.align$getter = function() { return DOM$EnsureDartNull(this.align); };
    c.prototype.align$setter = function(value) { this.align = value; };
    c.prototype.ch$getter = function() { return DOM$EnsureDartNull(this.ch); };
    c.prototype.ch$setter = function(value) { this.ch = value; };
    c.prototype.chOff$getter = function() { return DOM$EnsureDartNull(this.chOff); };
    c.prototype.chOff$setter = function(value) { this.chOff = value; };
    c.prototype.rows$getter = function() { return DOM$EnsureDartNull(this.rows); };
    c.prototype.vAlign$getter = function() { return DOM$EnsureDartNull(this.vAlign); };
    c.prototype.vAlign$setter = function(value) { this.vAlign = value; };
  }
  DOM$fixMembers(c, [
    'deleteRow',
    'insertRow']);
  c.$implements$HTMLTableSectionElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLTextAreaElement(c) {
  if (c.prototype) {
    c.prototype.accessKey$getter = function() { return DOM$EnsureDartNull(this.accessKey); };
    c.prototype.accessKey$setter = function(value) { this.accessKey = value; };
    c.prototype.autofocus$getter = function() { return DOM$EnsureDartNull(this.autofocus); };
    c.prototype.autofocus$setter = function(value) { this.autofocus = value; };
    c.prototype.cols$getter = function() { return DOM$EnsureDartNull(this.cols); };
    c.prototype.cols$setter = function(value) { this.cols = value; };
    c.prototype.defaultValue$getter = function() { return DOM$EnsureDartNull(this.defaultValue); };
    c.prototype.defaultValue$setter = function(value) { this.defaultValue = value; };
    c.prototype.disabled$getter = function() { return DOM$EnsureDartNull(this.disabled); };
    c.prototype.disabled$setter = function(value) { this.disabled = value; };
    c.prototype.form$getter = function() { return DOM$EnsureDartNull(this.form); };
    c.prototype.labels$getter = function() { return DOM$EnsureDartNull(this.labels); };
    c.prototype.maxLength$getter = function() { return DOM$EnsureDartNull(this.maxLength); };
    c.prototype.maxLength$setter = function(value) { this.maxLength = value; };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
    c.prototype.placeholder$getter = function() { return DOM$EnsureDartNull(this.placeholder); };
    c.prototype.placeholder$setter = function(value) { this.placeholder = value; };
    c.prototype.readOnly$getter = function() { return DOM$EnsureDartNull(this.readOnly); };
    c.prototype.readOnly$setter = function(value) { this.readOnly = value; };
    c.prototype.required$getter = function() { return DOM$EnsureDartNull(this.required); };
    c.prototype.required$setter = function(value) { this.required = value; };
    c.prototype.rows$getter = function() { return DOM$EnsureDartNull(this.rows); };
    c.prototype.rows$setter = function(value) { this.rows = value; };
    c.prototype.selectionDirection$getter = function() { return DOM$EnsureDartNull(this.selectionDirection); };
    c.prototype.selectionDirection$setter = function(value) { this.selectionDirection = value; };
    c.prototype.selectionEnd$getter = function() { return DOM$EnsureDartNull(this.selectionEnd); };
    c.prototype.selectionEnd$setter = function(value) { this.selectionEnd = value; };
    c.prototype.selectionStart$getter = function() { return DOM$EnsureDartNull(this.selectionStart); };
    c.prototype.selectionStart$setter = function(value) { this.selectionStart = value; };
    c.prototype.textLength$getter = function() { return DOM$EnsureDartNull(this.textLength); };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.validationMessage$getter = function() { return DOM$EnsureDartNull(this.validationMessage); };
    c.prototype.validity$getter = function() { return DOM$EnsureDartNull(this.validity); };
    c.prototype.value$getter = function() { return DOM$EnsureDartNull(this.value); };
    c.prototype.value$setter = function(value) { this.value = value; };
    c.prototype.willValidate$getter = function() { return DOM$EnsureDartNull(this.willValidate); };
    c.prototype.wrap$getter = function() { return DOM$EnsureDartNull(this.wrap); };
    c.prototype.wrap$setter = function(value) { this.wrap = value; };
  }
  DOM$fixMembers(c, [
    'checkValidity',
    'select',
    'setCustomValidity',
    'setSelectionRange']);
  c.$implements$HTMLTextAreaElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLTitleElement(c) {
  if (c.prototype) {
    c.prototype.text$getter = function() { return DOM$EnsureDartNull(this.text); };
    c.prototype.text$setter = function(value) { this.text = value; };
  }
  c.$implements$HTMLTitleElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLTrackElement(c) {
  if (c.prototype) {
    c.prototype.isDefault$getter = function() { return DOM$EnsureDartNull(this.isDefault); };
    c.prototype.isDefault$setter = function(value) { this.isDefault = value; };
    c.prototype.kind$getter = function() { return DOM$EnsureDartNull(this.kind); };
    c.prototype.kind$setter = function(value) { this.kind = value; };
    c.prototype.label$getter = function() { return DOM$EnsureDartNull(this.label); };
    c.prototype.label$setter = function(value) { this.label = value; };
    c.prototype.src$getter = function() { return DOM$EnsureDartNull(this.src); };
    c.prototype.src$setter = function(value) { this.src = value; };
    c.prototype.srclang$getter = function() { return DOM$EnsureDartNull(this.srclang); };
    c.prototype.srclang$setter = function(value) { this.srclang = value; };
    c.prototype.track$getter = function() { return DOM$EnsureDartNull(this.track); };
  }
  c.$implements$HTMLTrackElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLUListElement(c) {
  if (c.prototype) {
    c.prototype.compact$getter = function() { return DOM$EnsureDartNull(this.compact); };
    c.prototype.compact$setter = function(value) { this.compact = value; };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.type$setter = function(value) { this.type = value; };
  }
  c.$implements$HTMLUListElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLUnknownElement(c) {
  if (c.prototype) {
  }
  c.$implements$HTMLUnknownElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HTMLVideoElement(c) {
  if (c.prototype) {
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.height$setter = function(value) { this.height = value; };
    c.prototype.poster$getter = function() { return DOM$EnsureDartNull(this.poster); };
    c.prototype.poster$setter = function(value) { this.poster = value; };
    c.prototype.videoHeight$getter = function() { return DOM$EnsureDartNull(this.videoHeight); };
    c.prototype.videoWidth$getter = function() { return DOM$EnsureDartNull(this.videoWidth); };
    c.prototype.webkitDecodedFrameCount$getter = function() { return DOM$EnsureDartNull(this.webkitDecodedFrameCount); };
    c.prototype.webkitDisplayingFullscreen$getter = function() { return DOM$EnsureDartNull(this.webkitDisplayingFullscreen); };
    c.prototype.webkitDroppedFrameCount$getter = function() { return DOM$EnsureDartNull(this.webkitDroppedFrameCount); };
    c.prototype.webkitSupportsFullscreen$getter = function() { return DOM$EnsureDartNull(this.webkitSupportsFullscreen); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.width$setter = function(value) { this.width = value; };
  }
  DOM$fixMembers(c, [
    'webkitEnterFullScreen',
    'webkitEnterFullscreen',
    'webkitExitFullScreen',
    'webkitExitFullscreen']);
  c.$implements$HTMLVideoElement$Dart = 1;
  c.$implements$HTMLMediaElement$Dart = 1;
  c.$implements$HTMLElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$HashChangeEvent(c) {
  if (c.prototype) {
    c.prototype.newURL$getter = function() { return DOM$EnsureDartNull(this.newURL); };
    c.prototype.oldURL$getter = function() { return DOM$EnsureDartNull(this.oldURL); };
  }
  DOM$fixMembers(c, ['initHashChangeEvent']);
  c.$implements$HashChangeEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$History(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, [
    'back',
    'forward',
    'go',
    'pushState',
    'replaceState']);
  c.$implements$History$Dart = 1;
}
function DOM$fixClass$IDBAny(c) {
  if (c.prototype) {
  }
  c.$implements$IDBAny$Dart = 1;
}
function DOM$fixClass$IDBCursor(c) {
  if (c.prototype) {
    c.prototype.direction$getter = function() { return DOM$EnsureDartNull(this.direction); };
    c.prototype.key$getter = function() { return DOM$EnsureDartNull(this.key); };
    c.prototype.primaryKey$getter = function() { return DOM$EnsureDartNull(this.primaryKey); };
    c.prototype.source$getter = function() { return DOM$EnsureDartNull(this.source); };
  }
  DOM$fixMembers(c, [
    'continueFunction',
    'update']);
  c.prototype.delete$member = function() {
    return DOM$EnsureDartNull(this.deleteFunction.apply(this, arguments));
  };
  c.$implements$IDBCursor$Dart = 1;
}
function DOM$fixClass$IDBCursorWithValue(c) {
  if (c.prototype) {
    c.prototype.value$getter = function() { return DOM$EnsureDartNull(this.value); };
  }
  c.$implements$IDBCursorWithValue$Dart = 1;
  c.$implements$IDBCursor$Dart = 1;
}
function DOM$fixClass$IDBDatabase(c) {
  if (c.prototype) {
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.version$getter = function() { return DOM$EnsureDartNull(this.version); };
  }
  DOM$fixMembers(c, [
    'addEventListener',
    'close',
    'createObjectStore',
    'deleteObjectStore',
    'dispatchEvent',
    'removeEventListener',
    'setVersion',
    'transaction']);
  c.$implements$IDBDatabase$Dart = 1;
}
function DOM$fixClass$IDBDatabaseError(c) {
  if (c.prototype) {
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
    c.prototype.code$setter = function(value) { this.code = value; };
    c.prototype.message$getter = function() { return DOM$EnsureDartNull(this.message); };
    c.prototype.message$setter = function(value) { this.message = value; };
  }
  c.$implements$IDBDatabaseError$Dart = 1;
}
function DOM$fixClass$IDBDatabaseException(c) {
  if (c.prototype) {
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
    c.prototype.message$getter = function() { return DOM$EnsureDartNull(this.message); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
  }
  DOM$fixMembers(c, ['toString']);
  c.$implements$IDBDatabaseException$Dart = 1;
}
function DOM$fixClass$IDBFactory(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'cmp',
    'deleteDatabase',
    'getDatabaseNames',
    'open']);
  c.$implements$IDBFactory$Dart = 1;
}
function DOM$fixClass$IDBIndex(c) {
  if (c.prototype) {
    c.prototype.keyPath$getter = function() { return DOM$EnsureDartNull(this.keyPath); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.objectStore$getter = function() { return DOM$EnsureDartNull(this.objectStore); };
    c.prototype.unique$getter = function() { return DOM$EnsureDartNull(this.unique); };
  }
  DOM$fixMembers(c, [
    'getKey',
    'openCursor',
    'openKeyCursor']);
  c.prototype.getObject$member = function() {
    return DOM$EnsureDartNull(this.get.apply(this, arguments));
  };
  c.$implements$IDBIndex$Dart = 1;
}
function DOM$fixClass$IDBKey(c) {
  if (c.prototype) {
  }
  c.$implements$IDBKey$Dart = 1;
}
function DOM$fixClass$IDBKeyRange(c) {
  if (c.prototype) {
    c.prototype.lower$getter = function() { return DOM$EnsureDartNull(this.lower); };
    c.prototype.lowerOpen$getter = function() { return DOM$EnsureDartNull(this.lowerOpen); };
    c.prototype.upper$getter = function() { return DOM$EnsureDartNull(this.upper); };
    c.prototype.upperOpen$getter = function() { return DOM$EnsureDartNull(this.upperOpen); };
  }
  DOM$fixMembers(c, [
    'bound',
    'lowerBound',
    'only',
    'upperBound']);
  c.$implements$IDBKeyRange$Dart = 1;
}
function DOM$fixClass$IDBObjectStore(c) {
  if (c.prototype) {
    c.prototype.keyPath$getter = function() { return DOM$EnsureDartNull(this.keyPath); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.transaction$getter = function() { return DOM$EnsureDartNull(this.transaction); };
  }
  DOM$fixMembers(c, [
    'add',
    'clear',
    'createIndex',
    'deleteIndex',
    'index',
    'openCursor',
    'put']);
  c.prototype.delete$member = function() {
    return DOM$EnsureDartNull(this.deleteFunction.apply(this, arguments));
  };
  c.prototype.getObject$member = function() {
    return DOM$EnsureDartNull(this.get.apply(this, arguments));
  };
  c.$implements$IDBObjectStore$Dart = 1;
}
function DOM$fixClass$IDBRequest(c) {
  if (c.prototype) {
    c.prototype.errorCode$getter = function() { return DOM$EnsureDartNull(this.errorCode); };
    c.prototype.readyState$getter = function() { return DOM$EnsureDartNull(this.readyState); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.source$getter = function() { return DOM$EnsureDartNull(this.source); };
    c.prototype.transaction$getter = function() { return DOM$EnsureDartNull(this.transaction); };
    c.prototype.webkitErrorMessage$getter = function() { return DOM$EnsureDartNull(this.webkitErrorMessage); };
  }
  DOM$fixMembers(c, [
    'addEventListener',
    'dispatchEvent',
    'removeEventListener']);
  c.$implements$IDBRequest$Dart = 1;
}
function DOM$fixClass$IDBTransaction(c) {
  if (c.prototype) {
    c.prototype.db$getter = function() { return DOM$EnsureDartNull(this.db); };
    c.prototype.mode$getter = function() { return DOM$EnsureDartNull(this.mode); };
  }
  DOM$fixMembers(c, [
    'abort',
    'addEventListener',
    'dispatchEvent',
    'objectStore',
    'removeEventListener']);
  c.$implements$IDBTransaction$Dart = 1;
}
function DOM$fixClass$IDBVersionChangeEvent(c) {
  if (c.prototype) {
    c.prototype.version$getter = function() { return DOM$EnsureDartNull(this.version); };
  }
  c.$implements$IDBVersionChangeEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$IDBVersionChangeRequest(c) {
  if (c.prototype) {
  }
  c.$implements$IDBVersionChangeRequest$Dart = 1;
  c.$implements$IDBRequest$Dart = 1;
}
function DOM$fixClass$ImageData(c) {
  if (c.prototype) {
    c.prototype.data$getter = function() { return DOM$fixValue$CanvasPixelArray(this.data); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
  }
  c.$implements$ImageData$Dart = 1;
}
function DOM$fixClassOnDemand$ImageData(c) {
  if (c.DOM$initialized === true)
    return;
  c.DOM$initialized = true;
  DOM$fixClass$ImageData(c);
}
function DOM$fixValue$ImageData(value) {
  if (value == null)
    return DOM$EnsureDartNull(value);
  if (typeof value != "object")
    return value;
  var constructor = value.constructor;
  if (constructor == null)
    return value;
  DOM$fixClassOnDemand$ImageData(constructor);
  return value;
}
function DOM$fixClass$InjectedScriptHost(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'clearConsoleMessages',
    'copyText',
    'databaseId',
    'evaluate',
    'inspect',
    'inspectedNode',
    'internalConstructorName',
    'isHTMLAllCollection',
    'storageId',
    'type']);
  c.$implements$InjectedScriptHost$Dart = 1;
}
function DOM$fixClass$InspectorFrontendHost(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'bringToFront',
    'closeWindow',
    'copyText',
    'disconnectFromBackend',
    'hiddenPanels',
    'inspectedURLChanged',
    'loaded',
    'localizedStringsURL',
    'moveWindowBy',
    'platform',
    'port',
    'recordActionTaken',
    'recordPanelShown',
    'recordSettingChanged',
    'requestAttachWindow',
    'requestDetachWindow',
    'saveAs',
    'sendMessageToBackend',
    'setAttachedWindowHeight',
    'setExtensionAPI',
    'showContextMenu']);
  c.$implements$InspectorFrontendHost$Dart = 1;
}
function DOM$fixClass$Int16Array(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, ['subarray']);
  c.$implements$Int16Array$Dart = 1;
  c.$implements$ArrayBufferView$Dart = 1;
}
function DOM$fixClass$Int32Array(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, ['subarray']);
  c.$implements$Int32Array$Dart = 1;
  c.$implements$ArrayBufferView$Dart = 1;
}
function DOM$fixClass$Int8Array(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, ['subarray']);
  c.$implements$Int8Array$Dart = 1;
  c.$implements$ArrayBufferView$Dart = 1;
}
function DOM$fixClass$JavaScriptCallFrame(c) {
  if (c.prototype) {
    c.prototype.caller$getter = function() { return DOM$EnsureDartNull(this.caller); };
    c.prototype.column$getter = function() { return DOM$EnsureDartNull(this.column); };
    c.prototype.functionName$getter = function() { return DOM$EnsureDartNull(this.functionName); };
    c.prototype.line$getter = function() { return DOM$EnsureDartNull(this.line); };
    c.prototype.scopeChain$getter = function() { return DOM$EnsureDartNull(this.scopeChain); };
    c.prototype.sourceID$getter = function() { return DOM$EnsureDartNull(this.sourceID); };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
  }
  DOM$fixMembers(c, [
    'evaluate',
    'scopeType']);
  c.$implements$JavaScriptCallFrame$Dart = 1;
}
function DOM$fixClass$KeyboardEvent(c) {
  if (c.prototype) {
    c.prototype.altGraphKey$getter = function() { return DOM$EnsureDartNull(this.altGraphKey); };
    c.prototype.altKey$getter = function() { return DOM$EnsureDartNull(this.altKey); };
    c.prototype.ctrlKey$getter = function() { return DOM$EnsureDartNull(this.ctrlKey); };
    c.prototype.keyIdentifier$getter = function() { return DOM$EnsureDartNull(this.keyIdentifier); };
    c.prototype.keyLocation$getter = function() { return DOM$EnsureDartNull(this.keyLocation); };
    c.prototype.metaKey$getter = function() { return DOM$EnsureDartNull(this.metaKey); };
    c.prototype.shiftKey$getter = function() { return DOM$EnsureDartNull(this.shiftKey); };
  }
  DOM$fixMembers(c, ['initKeyboardEvent']);
  c.$implements$KeyboardEvent$Dart = 1;
  c.$implements$UIEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$Location(c) {
  if (c.prototype) {
    c.prototype.hash$getter = function() { return DOM$EnsureDartNull(this.hash); };
    c.prototype.hash$setter = function(value) { this.hash = value; };
    c.prototype.host$getter = function() { return DOM$EnsureDartNull(this.host); };
    c.prototype.host$setter = function(value) { this.host = value; };
    c.prototype.hostname$getter = function() { return DOM$EnsureDartNull(this.hostname); };
    c.prototype.hostname$setter = function(value) { this.hostname = value; };
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.href$setter = function(value) { this.href = value; };
    c.prototype.origin$getter = function() { return DOM$EnsureDartNull(this.origin); };
    c.prototype.pathname$getter = function() { return DOM$EnsureDartNull(this.pathname); };
    c.prototype.pathname$setter = function(value) { this.pathname = value; };
    c.prototype.port$getter = function() { return DOM$EnsureDartNull(this.port); };
    c.prototype.port$setter = function(value) { this.port = value; };
    c.prototype.protocol$getter = function() { return DOM$EnsureDartNull(this.protocol); };
    c.prototype.protocol$setter = function(value) { this.protocol = value; };
    c.prototype.search$getter = function() { return DOM$EnsureDartNull(this.search); };
    c.prototype.search$setter = function(value) { this.search = value; };
  }
  DOM$fixMembers(c, [
    'assign',
    'getParameter',
    'reload',
    'replace']);
  c.prototype.toString$member = function() {
    return DOM$EnsureDartNull(this.toStringFunction.apply(this, arguments));
  };
  c.$implements$Location$Dart = 1;
}
function DOM$fixClass$MediaError(c) {
  if (c.prototype) {
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
  }
  c.$implements$MediaError$Dart = 1;
}
function DOM$fixClass$MediaList(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
    c.prototype.mediaText$getter = function() { return DOM$EnsureDartNull(this.mediaText); };
    c.prototype.mediaText$setter = function(value) { this.mediaText = value; };
    c.prototype.INDEX$operator = function(k) { return DOM$EnsureDartNull(this[k]); };
    c.prototype.ASSIGN_INDEX$operator = function(k, v) { this[k] = v; };
  }
  DOM$fixMembers(c, [
    'appendMedium',
    'deleteMedium',
    'item']);
  c.$implements$MediaList$Dart = 1;
}
function DOM$fixClass$MediaQueryList(c) {
  if (c.prototype) {
    c.prototype.matches$getter = function() { return DOM$EnsureDartNull(this.matches); };
    c.prototype.media$getter = function() { return DOM$EnsureDartNull(this.media); };
  }
  DOM$fixMembers(c, [
    'addListener',
    'removeListener']);
  c.$implements$MediaQueryList$Dart = 1;
}
function DOM$fixClass$MediaQueryListListener(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['queryChanged']);
  c.$implements$MediaQueryListListener$Dart = 1;
}
function DOM$fixClass$MemoryInfo(c) {
  if (c.prototype) {
    c.prototype.jsHeapSizeLimit$getter = function() { return DOM$EnsureDartNull(this.jsHeapSizeLimit); };
    c.prototype.totalJSHeapSize$getter = function() { return DOM$EnsureDartNull(this.totalJSHeapSize); };
    c.prototype.usedJSHeapSize$getter = function() { return DOM$EnsureDartNull(this.usedJSHeapSize); };
  }
  c.$implements$MemoryInfo$Dart = 1;
}
function DOM$fixClass$MessageChannel(c) {
  if (c.prototype) {
    c.prototype.port1$getter = function() { return DOM$EnsureDartNull(this.port1); };
    c.prototype.port2$getter = function() { return DOM$EnsureDartNull(this.port2); };
  }
  c.$implements$MessageChannel$Dart = 1;
}
function DOM$fixClass$MessageEvent(c) {
  if (c.prototype) {
    c.prototype.data$getter = function() { return DOM$EnsureDartNull(this.data); };
    c.prototype.lastEventId$getter = function() { return DOM$EnsureDartNull(this.lastEventId); };
    c.prototype.origin$getter = function() { return DOM$EnsureDartNull(this.origin); };
    c.prototype.ports$getter = function() { return DOM$EnsureDartNull(this.ports); };
    c.prototype.source$getter = function() { return DOM$EnsureDartNull(this.source); };
  }
  DOM$fixMembers(c, [
    'initMessageEvent',
    'webkitInitMessageEvent']);
  c.$implements$MessageEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$MessagePort(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'addEventListener',
    'close',
    'dispatchEvent',
    'postMessage',
    'removeEventListener',
    'start',
    'webkitPostMessage']);
  c.$implements$MessagePort$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$Metadata(c) {
  if (c.prototype) {
    c.prototype.modificationTime$getter = function() { return DOM$EnsureDartNull(this.modificationTime); };
  }
  c.$implements$Metadata$Dart = 1;
}
function DOM$fixClass$MetadataCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$MetadataCallback$Dart = 1;
}
function DOM$fixClass$MouseEvent(c) {
  if (c.prototype) {
    c.prototype.altKey$getter = function() { return DOM$EnsureDartNull(this.altKey); };
    c.prototype.button$getter = function() { return DOM$EnsureDartNull(this.button); };
    c.prototype.clientX$getter = function() { return DOM$EnsureDartNull(this.clientX); };
    c.prototype.clientY$getter = function() { return DOM$EnsureDartNull(this.clientY); };
    c.prototype.ctrlKey$getter = function() { return DOM$EnsureDartNull(this.ctrlKey); };
    c.prototype.dataTransfer$getter = function() { return DOM$EnsureDartNull(this.dataTransfer); };
    c.prototype.fromElement$getter = function() { return DOM$EnsureDartNull(this.fromElement); };
    c.prototype.metaKey$getter = function() { return DOM$EnsureDartNull(this.metaKey); };
    c.prototype.offsetX$getter = function() { return DOM$EnsureDartNull(this.offsetX); };
    c.prototype.offsetY$getter = function() { return DOM$EnsureDartNull(this.offsetY); };
    c.prototype.relatedTarget$getter = function() { return DOM$EnsureDartNull(this.relatedTarget); };
    c.prototype.screenX$getter = function() { return DOM$EnsureDartNull(this.screenX); };
    c.prototype.screenY$getter = function() { return DOM$EnsureDartNull(this.screenY); };
    c.prototype.shiftKey$getter = function() { return DOM$EnsureDartNull(this.shiftKey); };
    c.prototype.toElement$getter = function() { return DOM$EnsureDartNull(this.toElement); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
  }
  DOM$fixMembers(c, ['initMouseEvent']);
  c.$implements$MouseEvent$Dart = 1;
  c.$implements$UIEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$MutationCallback(c) {
  if (c.prototype) {
  }
  c.$implements$MutationCallback$Dart = 1;
}
function DOM$fixClass$MutationEvent(c) {
  if (c.prototype) {
    c.prototype.attrChange$getter = function() { return DOM$EnsureDartNull(this.attrChange); };
    c.prototype.attrName$getter = function() { return DOM$EnsureDartNull(this.attrName); };
    c.prototype.newValue$getter = function() { return DOM$EnsureDartNull(this.newValue); };
    c.prototype.prevValue$getter = function() { return DOM$EnsureDartNull(this.prevValue); };
    c.prototype.relatedNode$getter = function() { return DOM$EnsureDartNull(this.relatedNode); };
  }
  DOM$fixMembers(c, ['initMutationEvent']);
  c.$implements$MutationEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$MutationRecord(c) {
  if (c.prototype) {
    c.prototype.addedNodes$getter = function() { return DOM$EnsureDartNull(this.addedNodes); };
    c.prototype.attributeName$getter = function() { return DOM$EnsureDartNull(this.attributeName); };
    c.prototype.attributeNamespace$getter = function() { return DOM$EnsureDartNull(this.attributeNamespace); };
    c.prototype.nextSibling$getter = function() { return DOM$EnsureDartNull(this.nextSibling); };
    c.prototype.oldValue$getter = function() { return DOM$EnsureDartNull(this.oldValue); };
    c.prototype.previousSibling$getter = function() { return DOM$EnsureDartNull(this.previousSibling); };
    c.prototype.removedNodes$getter = function() { return DOM$EnsureDartNull(this.removedNodes); };
    c.prototype.target$getter = function() { return DOM$EnsureDartNull(this.target); };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
  }
  c.$implements$MutationRecord$Dart = 1;
}
function DOM$fixClass$NamedNodeMap(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
    c.prototype.INDEX$operator = function(k) { return DOM$EnsureDartNull(this[k]); };
    c.prototype.ASSIGN_INDEX$operator = function(k, v) { this[k] = v; };
  }
  DOM$fixMembers(c, [
    'getNamedItem',
    'getNamedItemNS',
    'item',
    'removeNamedItem',
    'removeNamedItemNS',
    'setNamedItem',
    'setNamedItemNS']);
  c.$implements$NamedNodeMap$Dart = 1;
}
function DOM$fixClass$Navigator(c) {
  if (c.prototype) {
    c.prototype.appCodeName$getter = function() { return DOM$EnsureDartNull(this.appCodeName); };
    c.prototype.appName$getter = function() { return DOM$EnsureDartNull(this.appName); };
    c.prototype.appVersion$getter = function() { return DOM$EnsureDartNull(this.appVersion); };
    c.prototype.cookieEnabled$getter = function() { return DOM$EnsureDartNull(this.cookieEnabled); };
    c.prototype.language$getter = function() { return DOM$EnsureDartNull(this.language); };
    c.prototype.mimeTypes$getter = function() { return DOM$EnsureDartNull(this.mimeTypes); };
    c.prototype.onLine$getter = function() { return DOM$EnsureDartNull(this.onLine); };
    c.prototype.platform$getter = function() { return DOM$EnsureDartNull(this.platform); };
    c.prototype.plugins$getter = function() { return DOM$EnsureDartNull(this.plugins); };
    c.prototype.product$getter = function() { return DOM$EnsureDartNull(this.product); };
    c.prototype.productSub$getter = function() { return DOM$EnsureDartNull(this.productSub); };
    c.prototype.userAgent$getter = function() { return DOM$EnsureDartNull(this.userAgent); };
    c.prototype.vendor$getter = function() { return DOM$EnsureDartNull(this.vendor); };
    c.prototype.vendorSub$getter = function() { return DOM$EnsureDartNull(this.vendorSub); };
  }
  DOM$fixMembers(c, [
    'getStorageUpdates',
    'javaEnabled']);
  c.$implements$Navigator$Dart = 1;
}
function DOM$fixClass$NavigatorUserMediaError(c) {
  if (c.prototype) {
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
  }
  c.$implements$NavigatorUserMediaError$Dart = 1;
}
function DOM$fixClass$NavigatorUserMediaErrorCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$NavigatorUserMediaErrorCallback$Dart = 1;
}
function DOM$fixClass$NavigatorUserMediaSuccessCallback(c) {
  if (c.prototype) {
  }
  c.$implements$NavigatorUserMediaSuccessCallback$Dart = 1;
}
function DOM$fixClass$Node(c) {
  if (c.prototype) {
    c.prototype.attributes$getter = function() { return DOM$EnsureDartNull(this.attributes); };
    c.prototype.baseURI$getter = function() { return DOM$EnsureDartNull(this.baseURI); };
    c.prototype.childNodes$getter = function() { return DOM$EnsureDartNull(this.childNodes); };
    c.prototype.firstChild$getter = function() { return DOM$EnsureDartNull(this.firstChild); };
    c.prototype.lastChild$getter = function() { return DOM$EnsureDartNull(this.lastChild); };
    c.prototype.localName$getter = function() { return DOM$EnsureDartNull(this.localName); };
    c.prototype.namespaceURI$getter = function() { return DOM$EnsureDartNull(this.namespaceURI); };
    c.prototype.nextSibling$getter = function() { return DOM$EnsureDartNull(this.nextSibling); };
    c.prototype.nodeName$getter = function() { return DOM$EnsureDartNull(this.nodeName); };
    c.prototype.nodeType$getter = function() { return DOM$EnsureDartNull(this.nodeType); };
    c.prototype.nodeValue$getter = function() { return DOM$EnsureDartNull(this.nodeValue); };
    c.prototype.nodeValue$setter = function(value) { this.nodeValue = value; };
    c.prototype.ownerDocument$getter = function() { return DOM$EnsureDartNull(this.ownerDocument); };
    c.prototype.parentElement$getter = function() { return DOM$EnsureDartNull(this.parentElement); };
    c.prototype.parentNode$getter = function() { return DOM$EnsureDartNull(this.parentNode); };
    c.prototype.prefix$getter = function() { return DOM$EnsureDartNull(this.prefix); };
    c.prototype.prefix$setter = function(value) { this.prefix = value; };
    c.prototype.previousSibling$getter = function() { return DOM$EnsureDartNull(this.previousSibling); };
    c.prototype.textContent$getter = function() { return DOM$EnsureDartNull(this.textContent); };
    c.prototype.textContent$setter = function(value) { this.textContent = value; };
  }
  DOM$fixMembers(c, [
    'addEventListener',
    'appendChild',
    'cloneNode',
    'compareDocumentPosition',
    'contains',
    'dispatchEvent',
    'hasAttributes',
    'hasChildNodes',
    'insertBefore',
    'isDefaultNamespace',
    'isEqualNode',
    'isSameNode',
    'isSupported',
    'lookupNamespaceURI',
    'lookupPrefix',
    'normalize',
    'removeChild',
    'removeEventListener',
    'replaceChild']);
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$NodeFilter(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['acceptNode']);
  c.$implements$NodeFilter$Dart = 1;
}
function DOM$fixClass$NodeIterator(c) {
  if (c.prototype) {
    c.prototype.expandEntityReferences$getter = function() { return DOM$EnsureDartNull(this.expandEntityReferences); };
    c.prototype.filter$getter = function() { return DOM$EnsureDartNull(this.filter); };
    c.prototype.pointerBeforeReferenceNode$getter = function() { return DOM$EnsureDartNull(this.pointerBeforeReferenceNode); };
    c.prototype.referenceNode$getter = function() { return DOM$EnsureDartNull(this.referenceNode); };
    c.prototype.root$getter = function() { return DOM$EnsureDartNull(this.root); };
    c.prototype.whatToShow$getter = function() { return DOM$EnsureDartNull(this.whatToShow); };
  }
  DOM$fixMembers(c, [
    'detach',
    'nextNode',
    'previousNode']);
  c.$implements$NodeIterator$Dart = 1;
}
function DOM$fixClass$NodeList(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
    c.prototype.INDEX$operator = function(k) { return DOM$EnsureDartNull(this[k]); };
    c.prototype.ASSIGN_INDEX$operator = function(k, v) { this[k] = v; };
  }
  DOM$fixMembers(c, ['item']);
  c.$implements$NodeList$Dart = 1;
}
function DOM$fixClass$NodeSelector(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'querySelector',
    'querySelectorAll']);
  c.$implements$NodeSelector$Dart = 1;
}
function DOM$fixClass$Notation(c) {
  if (c.prototype) {
    c.prototype.publicId$getter = function() { return DOM$EnsureDartNull(this.publicId); };
    c.prototype.systemId$getter = function() { return DOM$EnsureDartNull(this.systemId); };
  }
  c.$implements$Notation$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$Notification(c) {
  if (c.prototype) {
    c.prototype.dir$getter = function() { return DOM$EnsureDartNull(this.dir); };
    c.prototype.dir$setter = function(value) { this.dir = value; };
    c.prototype.replaceId$getter = function() { return DOM$EnsureDartNull(this.replaceId); };
    c.prototype.replaceId$setter = function(value) { this.replaceId = value; };
  }
  DOM$fixMembers(c, [
    'addEventListener',
    'cancel',
    'dispatchEvent',
    'removeEventListener',
    'show']);
  c.$implements$Notification$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClassOnDemand$Notification(c) {
  if (c.DOM$initialized === true)
    return;
  c.DOM$initialized = true;
  DOM$fixClass$Notification(c);
}
function DOM$fixValue$Notification(value) {
  if (value == null)
    return DOM$EnsureDartNull(value);
  if (typeof value != "object")
    return value;
  var constructor = value.constructor;
  if (constructor == null)
    return value;
  DOM$fixClassOnDemand$Notification(constructor);
  return value;
}
function DOM$fixClass$NotificationCenter(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'checkPermission',
    'requestPermission']);
  c.prototype.createHTMLNotification$member = function() {
    return DOM$fixValue$Notification(this.createHTMLNotification.apply(this, arguments));
  };
  c.prototype.createNotification$member = function() {
    return DOM$fixValue$Notification(this.createNotification.apply(this, arguments));
  };
  c.$implements$NotificationCenter$Dart = 1;
}
function DOM$fixClassOnDemand$NotificationCenter(c) {
  if (c.DOM$initialized === true)
    return;
  c.DOM$initialized = true;
  DOM$fixClass$NotificationCenter(c);
}
function DOM$fixValue$NotificationCenter(value) {
  if (value == null)
    return DOM$EnsureDartNull(value);
  if (typeof value != "object")
    return value;
  var constructor = value.constructor;
  if (constructor == null)
    return value;
  DOM$fixClassOnDemand$NotificationCenter(constructor);
  return value;
}
function DOM$fixClass$OESStandardDerivatives(c) {
  if (c.prototype) {
  }
  c.$implements$OESStandardDerivatives$Dart = 1;
}
function DOM$fixClass$OESTextureFloat(c) {
  if (c.prototype) {
  }
  c.$implements$OESTextureFloat$Dart = 1;
}
function DOM$fixClass$OESVertexArrayObject(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'bindVertexArrayOES',
    'createVertexArrayOES',
    'deleteVertexArrayOES',
    'isVertexArrayOES']);
  c.$implements$OESVertexArrayObject$Dart = 1;
}
function DOM$fixClass$OperationNotAllowedException(c) {
  if (c.prototype) {
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
    c.prototype.message$getter = function() { return DOM$EnsureDartNull(this.message); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
  }
  DOM$fixMembers(c, ['toString']);
  c.$implements$OperationNotAllowedException$Dart = 1;
}
function DOM$fixClass$OverflowEvent(c) {
  if (c.prototype) {
    c.prototype.horizontalOverflow$getter = function() { return DOM$EnsureDartNull(this.horizontalOverflow); };
    c.prototype.orient$getter = function() { return DOM$EnsureDartNull(this.orient); };
    c.prototype.verticalOverflow$getter = function() { return DOM$EnsureDartNull(this.verticalOverflow); };
  }
  DOM$fixMembers(c, ['initOverflowEvent']);
  c.$implements$OverflowEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$PageTransitionEvent(c) {
  if (c.prototype) {
    c.prototype.persisted$getter = function() { return DOM$EnsureDartNull(this.persisted); };
  }
  DOM$fixMembers(c, ['initPageTransitionEvent']);
  c.$implements$PageTransitionEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$Performance(c) {
  if (c.prototype) {
    c.prototype.memory$getter = function() { return DOM$EnsureDartNull(this.memory); };
    c.prototype.navigation$getter = function() { return DOM$EnsureDartNull(this.navigation); };
    c.prototype.timing$getter = function() { return DOM$EnsureDartNull(this.timing); };
  }
  c.$implements$Performance$Dart = 1;
}
function DOM$fixClass$PerformanceNavigation(c) {
  if (c.prototype) {
    c.prototype.redirectCount$getter = function() { return DOM$EnsureDartNull(this.redirectCount); };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
  }
  c.$implements$PerformanceNavigation$Dart = 1;
}
function DOM$fixClass$PerformanceTiming(c) {
  if (c.prototype) {
    c.prototype.connectEnd$getter = function() { return DOM$EnsureDartNull(this.connectEnd); };
    c.prototype.connectStart$getter = function() { return DOM$EnsureDartNull(this.connectStart); };
    c.prototype.domComplete$getter = function() { return DOM$EnsureDartNull(this.domComplete); };
    c.prototype.domContentLoadedEventEnd$getter = function() { return DOM$EnsureDartNull(this.domContentLoadedEventEnd); };
    c.prototype.domContentLoadedEventStart$getter = function() { return DOM$EnsureDartNull(this.domContentLoadedEventStart); };
    c.prototype.domInteractive$getter = function() { return DOM$EnsureDartNull(this.domInteractive); };
    c.prototype.domLoading$getter = function() { return DOM$EnsureDartNull(this.domLoading); };
    c.prototype.domainLookupEnd$getter = function() { return DOM$EnsureDartNull(this.domainLookupEnd); };
    c.prototype.domainLookupStart$getter = function() { return DOM$EnsureDartNull(this.domainLookupStart); };
    c.prototype.fetchStart$getter = function() { return DOM$EnsureDartNull(this.fetchStart); };
    c.prototype.loadEventEnd$getter = function() { return DOM$EnsureDartNull(this.loadEventEnd); };
    c.prototype.loadEventStart$getter = function() { return DOM$EnsureDartNull(this.loadEventStart); };
    c.prototype.navigationStart$getter = function() { return DOM$EnsureDartNull(this.navigationStart); };
    c.prototype.redirectEnd$getter = function() { return DOM$EnsureDartNull(this.redirectEnd); };
    c.prototype.redirectStart$getter = function() { return DOM$EnsureDartNull(this.redirectStart); };
    c.prototype.requestStart$getter = function() { return DOM$EnsureDartNull(this.requestStart); };
    c.prototype.responseEnd$getter = function() { return DOM$EnsureDartNull(this.responseEnd); };
    c.prototype.responseStart$getter = function() { return DOM$EnsureDartNull(this.responseStart); };
    c.prototype.secureConnectionStart$getter = function() { return DOM$EnsureDartNull(this.secureConnectionStart); };
    c.prototype.unloadEventEnd$getter = function() { return DOM$EnsureDartNull(this.unloadEventEnd); };
    c.prototype.unloadEventStart$getter = function() { return DOM$EnsureDartNull(this.unloadEventStart); };
  }
  c.$implements$PerformanceTiming$Dart = 1;
}
function DOM$fixClass$PopStateEvent(c) {
  if (c.prototype) {
    c.prototype.state$getter = function() { return DOM$EnsureDartNull(this.state); };
  }
  DOM$fixMembers(c, ['initPopStateEvent']);
  c.$implements$PopStateEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$PositionCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$PositionCallback$Dart = 1;
}
function DOM$fixClass$PositionError(c) {
  if (c.prototype) {
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
    c.prototype.message$getter = function() { return DOM$EnsureDartNull(this.message); };
  }
  c.$implements$PositionError$Dart = 1;
}
function DOM$fixClass$PositionErrorCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$PositionErrorCallback$Dart = 1;
}
function DOM$fixClass$ProcessingInstruction(c) {
  if (c.prototype) {
    c.prototype.data$getter = function() { return DOM$EnsureDartNull(this.data); };
    c.prototype.data$setter = function(value) { this.data = value; };
    c.prototype.sheet$getter = function() { return DOM$EnsureDartNull(this.sheet); };
    c.prototype.target$getter = function() { return DOM$EnsureDartNull(this.target); };
  }
  c.$implements$ProcessingInstruction$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$ProgressEvent(c) {
  if (c.prototype) {
    c.prototype.lengthComputable$getter = function() { return DOM$EnsureDartNull(this.lengthComputable); };
    c.prototype.loaded$getter = function() { return DOM$EnsureDartNull(this.loaded); };
    c.prototype.total$getter = function() { return DOM$EnsureDartNull(this.total); };
  }
  DOM$fixMembers(c, ['initProgressEvent']);
  c.$implements$ProgressEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$RGBColor(c) {
  if (c.prototype) {
    c.prototype.blue$getter = function() { return DOM$EnsureDartNull(this.blue); };
    c.prototype.green$getter = function() { return DOM$EnsureDartNull(this.green); };
    c.prototype.red$getter = function() { return DOM$EnsureDartNull(this.red); };
  }
  c.$implements$RGBColor$Dart = 1;
}
function DOM$fixClass$Range(c) {
  if (c.prototype) {
    c.prototype.collapsed$getter = function() { return DOM$EnsureDartNull(this.collapsed); };
    c.prototype.commonAncestorContainer$getter = function() { return DOM$EnsureDartNull(this.commonAncestorContainer); };
    c.prototype.endContainer$getter = function() { return DOM$EnsureDartNull(this.endContainer); };
    c.prototype.endOffset$getter = function() { return DOM$EnsureDartNull(this.endOffset); };
    c.prototype.startContainer$getter = function() { return DOM$EnsureDartNull(this.startContainer); };
    c.prototype.startOffset$getter = function() { return DOM$EnsureDartNull(this.startOffset); };
  }
  DOM$fixMembers(c, [
    'cloneContents',
    'cloneRange',
    'collapse',
    'compareNode',
    'comparePoint',
    'createContextualFragment',
    'deleteContents',
    'detach',
    'expand',
    'extractContents',
    'getBoundingClientRect',
    'getClientRects',
    'insertNode',
    'intersectsNode',
    'isPointInRange',
    'selectNode',
    'selectNodeContents',
    'setEnd',
    'setEndAfter',
    'setEndBefore',
    'setStart',
    'setStartAfter',
    'setStartBefore',
    'surroundContents',
    'toString']);
  c.$implements$Range$Dart = 1;
}
function DOM$fixClass$RangeException(c) {
  if (c.prototype) {
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
    c.prototype.message$getter = function() { return DOM$EnsureDartNull(this.message); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
  }
  DOM$fixMembers(c, ['toString']);
  c.$implements$RangeException$Dart = 1;
}
function DOM$fixClass$Rect(c) {
  if (c.prototype) {
    c.prototype.bottom$getter = function() { return DOM$EnsureDartNull(this.bottom); };
    c.prototype.left$getter = function() { return DOM$EnsureDartNull(this.left); };
    c.prototype.right$getter = function() { return DOM$EnsureDartNull(this.right); };
    c.prototype.top$getter = function() { return DOM$EnsureDartNull(this.top); };
  }
  c.$implements$Rect$Dart = 1;
}
function DOM$fixClass$SQLError(c) {
  if (c.prototype) {
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
    c.prototype.message$getter = function() { return DOM$EnsureDartNull(this.message); };
  }
  c.$implements$SQLError$Dart = 1;
}
function DOM$fixClass$SQLException(c) {
  if (c.prototype) {
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
    c.prototype.message$getter = function() { return DOM$EnsureDartNull(this.message); };
  }
  c.$implements$SQLException$Dart = 1;
}
function DOM$fixClass$SQLResultSet(c) {
  if (c.prototype) {
    c.prototype.insertId$getter = function() { return DOM$EnsureDartNull(this.insertId); };
    c.prototype.rows$getter = function() { return DOM$EnsureDartNull(this.rows); };
    c.prototype.rowsAffected$getter = function() { return DOM$EnsureDartNull(this.rowsAffected); };
  }
  c.$implements$SQLResultSet$Dart = 1;
}
function DOM$fixClass$SQLResultSetRowList(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, ['item']);
  c.$implements$SQLResultSetRowList$Dart = 1;
}
function DOM$fixClass$SQLStatementCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$SQLStatementCallback$Dart = 1;
}
function DOM$fixClass$SQLStatementErrorCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$SQLStatementErrorCallback$Dart = 1;
}
function DOM$fixClass$SQLTransaction(c) {
  if (c.prototype) {
  }
  c.$implements$SQLTransaction$Dart = 1;
}
function DOM$fixClass$SQLTransactionCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$SQLTransactionCallback$Dart = 1;
}
function DOM$fixClass$SQLTransactionErrorCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$SQLTransactionErrorCallback$Dart = 1;
}
function DOM$fixClass$SQLTransactionSync(c) {
  if (c.prototype) {
  }
  c.$implements$SQLTransactionSync$Dart = 1;
}
function DOM$fixClass$SQLTransactionSyncCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$SQLTransactionSyncCallback$Dart = 1;
}
function DOM$fixClass$SVGAElement(c) {
  if (c.prototype) {
    c.prototype.target$getter = function() { return DOM$EnsureDartNull(this.target); };
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.transform$getter = function() { return DOM$EnsureDartNull(this.transform); };
    c.prototype.farthestViewportElement$getter = function() { return DOM$EnsureDartNull(this.farthestViewportElement); };
    c.prototype.nearestViewportElement$getter = function() { return DOM$EnsureDartNull(this.nearestViewportElement); };
  }
  DOM$fixMembers(c, [
    'hasExtension',
    'getPresentationAttribute',
    'getBBox',
    'getCTM',
    'getScreenCTM',
    'getTransformToElement']);
  c.$implements$SVGAElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGURIReference$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGTransformable$Dart = 1;
  c.$implements$SVGLocatable$Dart = 1;
}
function DOM$fixClass$SVGAltGlyphDefElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGAltGlyphDefElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGAltGlyphElement(c) {
  if (c.prototype) {
    c.prototype.format$getter = function() { return DOM$EnsureDartNull(this.format); };
    c.prototype.format$setter = function(value) { this.format = value; };
    c.prototype.glyphRef$getter = function() { return DOM$EnsureDartNull(this.glyphRef); };
    c.prototype.glyphRef$setter = function(value) { this.glyphRef = value; };
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
  }
  c.$implements$SVGAltGlyphElement$Dart = 1;
  c.$implements$SVGTextPositioningElement$Dart = 1;
  c.$implements$SVGTextContentElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGURIReference$Dart = 1;
}
function DOM$fixClass$SVGAltGlyphItemElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGAltGlyphItemElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGAngle(c) {
  if (c.prototype) {
    c.prototype.unitType$getter = function() { return DOM$EnsureDartNull(this.unitType); };
    c.prototype.value$getter = function() { return DOM$EnsureDartNull(this.value); };
    c.prototype.value$setter = function(value) { this.value = value; };
    c.prototype.valueAsString$getter = function() { return DOM$EnsureDartNull(this.valueAsString); };
    c.prototype.valueAsString$setter = function(value) { this.valueAsString = value; };
    c.prototype.valueInSpecifiedUnits$getter = function() { return DOM$EnsureDartNull(this.valueInSpecifiedUnits); };
    c.prototype.valueInSpecifiedUnits$setter = function(value) { this.valueInSpecifiedUnits = value; };
  }
  DOM$fixMembers(c, [
    'convertToSpecifiedUnits',
    'newValueSpecifiedUnits']);
  c.$implements$SVGAngle$Dart = 1;
}
function DOM$fixClass$SVGAnimateColorElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGAnimateColorElement$Dart = 1;
  c.$implements$SVGAnimationElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$ElementTimeControl$Dart = 1;
}
function DOM$fixClass$SVGAnimateElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGAnimateElement$Dart = 1;
  c.$implements$SVGAnimationElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$ElementTimeControl$Dart = 1;
}
function DOM$fixClass$SVGAnimateMotionElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGAnimateMotionElement$Dart = 1;
  c.$implements$SVGAnimationElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$ElementTimeControl$Dart = 1;
}
function DOM$fixClass$SVGAnimateTransformElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGAnimateTransformElement$Dart = 1;
  c.$implements$SVGAnimationElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$ElementTimeControl$Dart = 1;
}
function DOM$fixClass$SVGAnimatedAngle(c) {
  if (c.prototype) {
    c.prototype.animVal$getter = function() { return DOM$EnsureDartNull(this.animVal); };
    c.prototype.baseVal$getter = function() { return DOM$EnsureDartNull(this.baseVal); };
  }
  c.$implements$SVGAnimatedAngle$Dart = 1;
}
function DOM$fixClass$SVGAnimatedBoolean(c) {
  if (c.prototype) {
    c.prototype.animVal$getter = function() { return DOM$EnsureDartNull(this.animVal); };
    c.prototype.baseVal$getter = function() { return DOM$EnsureDartNull(this.baseVal); };
    c.prototype.baseVal$setter = function(value) { this.baseVal = value; };
  }
  c.$implements$SVGAnimatedBoolean$Dart = 1;
}
function DOM$fixClass$SVGAnimatedEnumeration(c) {
  if (c.prototype) {
    c.prototype.animVal$getter = function() { return DOM$EnsureDartNull(this.animVal); };
    c.prototype.baseVal$getter = function() { return DOM$EnsureDartNull(this.baseVal); };
    c.prototype.baseVal$setter = function(value) { this.baseVal = value; };
  }
  c.$implements$SVGAnimatedEnumeration$Dart = 1;
}
function DOM$fixClass$SVGAnimatedInteger(c) {
  if (c.prototype) {
    c.prototype.animVal$getter = function() { return DOM$EnsureDartNull(this.animVal); };
    c.prototype.baseVal$getter = function() { return DOM$EnsureDartNull(this.baseVal); };
    c.prototype.baseVal$setter = function(value) { this.baseVal = value; };
  }
  c.$implements$SVGAnimatedInteger$Dart = 1;
}
function DOM$fixClass$SVGAnimatedLength(c) {
  if (c.prototype) {
    c.prototype.animVal$getter = function() { return DOM$EnsureDartNull(this.animVal); };
    c.prototype.baseVal$getter = function() { return DOM$EnsureDartNull(this.baseVal); };
  }
  c.$implements$SVGAnimatedLength$Dart = 1;
}
function DOM$fixClass$SVGAnimatedLengthList(c) {
  if (c.prototype) {
    c.prototype.animVal$getter = function() { return DOM$EnsureDartNull(this.animVal); };
    c.prototype.baseVal$getter = function() { return DOM$EnsureDartNull(this.baseVal); };
  }
  c.$implements$SVGAnimatedLengthList$Dart = 1;
}
function DOM$fixClass$SVGAnimatedNumber(c) {
  if (c.prototype) {
    c.prototype.animVal$getter = function() { return DOM$EnsureDartNull(this.animVal); };
    c.prototype.baseVal$getter = function() { return DOM$EnsureDartNull(this.baseVal); };
    c.prototype.baseVal$setter = function(value) { this.baseVal = value; };
  }
  c.$implements$SVGAnimatedNumber$Dart = 1;
}
function DOM$fixClass$SVGAnimatedNumberList(c) {
  if (c.prototype) {
    c.prototype.animVal$getter = function() { return DOM$EnsureDartNull(this.animVal); };
    c.prototype.baseVal$getter = function() { return DOM$EnsureDartNull(this.baseVal); };
  }
  c.$implements$SVGAnimatedNumberList$Dart = 1;
}
function DOM$fixClass$SVGAnimatedPreserveAspectRatio(c) {
  if (c.prototype) {
    c.prototype.animVal$getter = function() { return DOM$EnsureDartNull(this.animVal); };
    c.prototype.baseVal$getter = function() { return DOM$EnsureDartNull(this.baseVal); };
  }
  c.$implements$SVGAnimatedPreserveAspectRatio$Dart = 1;
}
function DOM$fixClass$SVGAnimatedRect(c) {
  if (c.prototype) {
    c.prototype.animVal$getter = function() { return DOM$EnsureDartNull(this.animVal); };
    c.prototype.baseVal$getter = function() { return DOM$EnsureDartNull(this.baseVal); };
  }
  c.$implements$SVGAnimatedRect$Dart = 1;
}
function DOM$fixClass$SVGAnimatedString(c) {
  if (c.prototype) {
    c.prototype.animVal$getter = function() { return DOM$EnsureDartNull(this.animVal); };
    c.prototype.baseVal$getter = function() { return DOM$EnsureDartNull(this.baseVal); };
    c.prototype.baseVal$setter = function(value) { this.baseVal = value; };
  }
  c.$implements$SVGAnimatedString$Dart = 1;
}
function DOM$fixClass$SVGAnimatedTransformList(c) {
  if (c.prototype) {
    c.prototype.animVal$getter = function() { return DOM$EnsureDartNull(this.animVal); };
    c.prototype.baseVal$getter = function() { return DOM$EnsureDartNull(this.baseVal); };
  }
  c.$implements$SVGAnimatedTransformList$Dart = 1;
}
function DOM$fixClass$SVGAnimationElement(c) {
  if (c.prototype) {
    c.prototype.targetElement$getter = function() { return DOM$EnsureDartNull(this.targetElement); };
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
  }
  DOM$fixMembers(c, [
    'getCurrentTime',
    'getSimpleDuration',
    'getStartTime',
    'hasExtension',
    'beginElement',
    'beginElementAt',
    'endElement',
    'endElementAt']);
  c.$implements$SVGAnimationElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$ElementTimeControl$Dart = 1;
}
function DOM$fixClass$SVGCircleElement(c) {
  if (c.prototype) {
    c.prototype.cx$getter = function() { return DOM$EnsureDartNull(this.cx); };
    c.prototype.cy$getter = function() { return DOM$EnsureDartNull(this.cy); };
    c.prototype.r$getter = function() { return DOM$EnsureDartNull(this.r); };
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.transform$getter = function() { return DOM$EnsureDartNull(this.transform); };
    c.prototype.farthestViewportElement$getter = function() { return DOM$EnsureDartNull(this.farthestViewportElement); };
    c.prototype.nearestViewportElement$getter = function() { return DOM$EnsureDartNull(this.nearestViewportElement); };
  }
  DOM$fixMembers(c, [
    'hasExtension',
    'getPresentationAttribute',
    'getBBox',
    'getCTM',
    'getScreenCTM',
    'getTransformToElement']);
  c.$implements$SVGCircleElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGTransformable$Dart = 1;
  c.$implements$SVGLocatable$Dart = 1;
}
function DOM$fixClass$SVGClipPathElement(c) {
  if (c.prototype) {
    c.prototype.clipPathUnits$getter = function() { return DOM$EnsureDartNull(this.clipPathUnits); };
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.transform$getter = function() { return DOM$EnsureDartNull(this.transform); };
    c.prototype.farthestViewportElement$getter = function() { return DOM$EnsureDartNull(this.farthestViewportElement); };
    c.prototype.nearestViewportElement$getter = function() { return DOM$EnsureDartNull(this.nearestViewportElement); };
  }
  DOM$fixMembers(c, [
    'hasExtension',
    'getPresentationAttribute',
    'getBBox',
    'getCTM',
    'getScreenCTM',
    'getTransformToElement']);
  c.$implements$SVGClipPathElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGTransformable$Dart = 1;
  c.$implements$SVGLocatable$Dart = 1;
}
function DOM$fixClass$SVGColor(c) {
  if (c.prototype) {
    c.prototype.colorType$getter = function() { return DOM$EnsureDartNull(this.colorType); };
    c.prototype.rgbColor$getter = function() { return DOM$EnsureDartNull(this.rgbColor); };
  }
  DOM$fixMembers(c, [
    'setColor',
    'setRGBColor',
    'setRGBColorICCColor']);
  c.$implements$SVGColor$Dart = 1;
  c.$implements$CSSValue$Dart = 1;
}
function DOM$fixClass$SVGComponentTransferFunctionElement(c) {
  if (c.prototype) {
    c.prototype.amplitude$getter = function() { return DOM$EnsureDartNull(this.amplitude); };
    c.prototype.exponent$getter = function() { return DOM$EnsureDartNull(this.exponent); };
    c.prototype.intercept$getter = function() { return DOM$EnsureDartNull(this.intercept); };
    c.prototype.offset$getter = function() { return DOM$EnsureDartNull(this.offset); };
    c.prototype.slope$getter = function() { return DOM$EnsureDartNull(this.slope); };
    c.prototype.tableValues$getter = function() { return DOM$EnsureDartNull(this.tableValues); };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
  }
  c.$implements$SVGComponentTransferFunctionElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGCursorElement(c) {
  if (c.prototype) {
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
  }
  DOM$fixMembers(c, ['hasExtension']);
  c.$implements$SVGCursorElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGURIReference$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
}
function DOM$fixClass$SVGDefsElement(c) {
  if (c.prototype) {
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.transform$getter = function() { return DOM$EnsureDartNull(this.transform); };
    c.prototype.farthestViewportElement$getter = function() { return DOM$EnsureDartNull(this.farthestViewportElement); };
    c.prototype.nearestViewportElement$getter = function() { return DOM$EnsureDartNull(this.nearestViewportElement); };
  }
  DOM$fixMembers(c, [
    'hasExtension',
    'getPresentationAttribute',
    'getBBox',
    'getCTM',
    'getScreenCTM',
    'getTransformToElement']);
  c.$implements$SVGDefsElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGTransformable$Dart = 1;
  c.$implements$SVGLocatable$Dart = 1;
}
function DOM$fixClass$SVGDescElement(c) {
  if (c.prototype) {
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGDescElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGDocument(c) {
  if (c.prototype) {
    c.prototype.rootElement$getter = function() { return DOM$EnsureDartNull(this.rootElement); };
  }
  DOM$fixMembers(c, ['createEvent']);
  c.$implements$SVGDocument$Dart = 1;
  c.$implements$Document$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
}
function DOM$fixClass$SVGElement(c) {
  if (c.prototype) {
    c.prototype.id$getter = function() { return DOM$EnsureDartNull(this.id); };
    c.prototype.id$setter = function(value) { this.id = value; };
    c.prototype.ownerSVGElement$getter = function() { return DOM$EnsureDartNull(this.ownerSVGElement); };
    c.prototype.viewportElement$getter = function() { return DOM$EnsureDartNull(this.viewportElement); };
    c.prototype.xmlbase$getter = function() { return DOM$EnsureDartNull(this.xmlbase); };
    c.prototype.xmlbase$setter = function(value) { this.xmlbase = value; };
  }
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGElementInstance(c) {
  if (c.prototype) {
    c.prototype.childNodes$getter = function() { return DOM$EnsureDartNull(this.childNodes); };
    c.prototype.correspondingElement$getter = function() { return DOM$EnsureDartNull(this.correspondingElement); };
    c.prototype.correspondingUseElement$getter = function() { return DOM$EnsureDartNull(this.correspondingUseElement); };
    c.prototype.firstChild$getter = function() { return DOM$EnsureDartNull(this.firstChild); };
    c.prototype.lastChild$getter = function() { return DOM$EnsureDartNull(this.lastChild); };
    c.prototype.nextSibling$getter = function() { return DOM$EnsureDartNull(this.nextSibling); };
    c.prototype.parentNode$getter = function() { return DOM$EnsureDartNull(this.parentNode); };
    c.prototype.previousSibling$getter = function() { return DOM$EnsureDartNull(this.previousSibling); };
  }
  DOM$fixMembers(c, [
    'addEventListener',
    'dispatchEvent',
    'removeEventListener']);
  c.$implements$SVGElementInstance$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$SVGElementInstanceList(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, ['item']);
  c.$implements$SVGElementInstanceList$Dart = 1;
}
function DOM$fixClass$SVGEllipseElement(c) {
  if (c.prototype) {
    c.prototype.cx$getter = function() { return DOM$EnsureDartNull(this.cx); };
    c.prototype.cy$getter = function() { return DOM$EnsureDartNull(this.cy); };
    c.prototype.rx$getter = function() { return DOM$EnsureDartNull(this.rx); };
    c.prototype.ry$getter = function() { return DOM$EnsureDartNull(this.ry); };
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.transform$getter = function() { return DOM$EnsureDartNull(this.transform); };
    c.prototype.farthestViewportElement$getter = function() { return DOM$EnsureDartNull(this.farthestViewportElement); };
    c.prototype.nearestViewportElement$getter = function() { return DOM$EnsureDartNull(this.nearestViewportElement); };
  }
  DOM$fixMembers(c, [
    'hasExtension',
    'getPresentationAttribute',
    'getBBox',
    'getCTM',
    'getScreenCTM',
    'getTransformToElement']);
  c.$implements$SVGEllipseElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGTransformable$Dart = 1;
  c.$implements$SVGLocatable$Dart = 1;
}
function DOM$fixClass$SVGException(c) {
  if (c.prototype) {
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
    c.prototype.message$getter = function() { return DOM$EnsureDartNull(this.message); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
  }
  DOM$fixMembers(c, ['toString']);
  c.$implements$SVGException$Dart = 1;
}
function DOM$fixClass$SVGExternalResourcesRequired(c) {
  if (c.prototype) {
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
  }
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
}
function DOM$fixClass$SVGFEBlendElement(c) {
  if (c.prototype) {
    c.prototype.in1$getter = function() { return DOM$EnsureDartNull(this.in1); };
    c.prototype.in2$getter = function() { return DOM$EnsureDartNull(this.in2); };
    c.prototype.mode$getter = function() { return DOM$EnsureDartNull(this.mode); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGFEBlendElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGFilterPrimitiveStandardAttributes$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFEColorMatrixElement(c) {
  if (c.prototype) {
    c.prototype.in1$getter = function() { return DOM$EnsureDartNull(this.in1); };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.values$getter = function() { return DOM$EnsureDartNull(this.values); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGFEColorMatrixElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGFilterPrimitiveStandardAttributes$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFEComponentTransferElement(c) {
  if (c.prototype) {
    c.prototype.in1$getter = function() { return DOM$EnsureDartNull(this.in1); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGFEComponentTransferElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGFilterPrimitiveStandardAttributes$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFECompositeElement(c) {
  if (c.prototype) {
    c.prototype.in1$getter = function() { return DOM$EnsureDartNull(this.in1); };
    c.prototype.in2$getter = function() { return DOM$EnsureDartNull(this.in2); };
    c.prototype.k1$getter = function() { return DOM$EnsureDartNull(this.k1); };
    c.prototype.k2$getter = function() { return DOM$EnsureDartNull(this.k2); };
    c.prototype.k3$getter = function() { return DOM$EnsureDartNull(this.k3); };
    c.prototype.k4$getter = function() { return DOM$EnsureDartNull(this.k4); };
    c.prototype.operator$getter = function() { return DOM$EnsureDartNull(this.operator); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGFECompositeElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGFilterPrimitiveStandardAttributes$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFEConvolveMatrixElement(c) {
  if (c.prototype) {
    c.prototype.bias$getter = function() { return DOM$EnsureDartNull(this.bias); };
    c.prototype.divisor$getter = function() { return DOM$EnsureDartNull(this.divisor); };
    c.prototype.edgeMode$getter = function() { return DOM$EnsureDartNull(this.edgeMode); };
    c.prototype.in1$getter = function() { return DOM$EnsureDartNull(this.in1); };
    c.prototype.kernelMatrix$getter = function() { return DOM$EnsureDartNull(this.kernelMatrix); };
    c.prototype.kernelUnitLengthX$getter = function() { return DOM$EnsureDartNull(this.kernelUnitLengthX); };
    c.prototype.kernelUnitLengthY$getter = function() { return DOM$EnsureDartNull(this.kernelUnitLengthY); };
    c.prototype.orderX$getter = function() { return DOM$EnsureDartNull(this.orderX); };
    c.prototype.orderY$getter = function() { return DOM$EnsureDartNull(this.orderY); };
    c.prototype.preserveAlpha$getter = function() { return DOM$EnsureDartNull(this.preserveAlpha); };
    c.prototype.targetX$getter = function() { return DOM$EnsureDartNull(this.targetX); };
    c.prototype.targetY$getter = function() { return DOM$EnsureDartNull(this.targetY); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGFEConvolveMatrixElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGFilterPrimitiveStandardAttributes$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFEDiffuseLightingElement(c) {
  if (c.prototype) {
    c.prototype.diffuseConstant$getter = function() { return DOM$EnsureDartNull(this.diffuseConstant); };
    c.prototype.in1$getter = function() { return DOM$EnsureDartNull(this.in1); };
    c.prototype.kernelUnitLengthX$getter = function() { return DOM$EnsureDartNull(this.kernelUnitLengthX); };
    c.prototype.kernelUnitLengthY$getter = function() { return DOM$EnsureDartNull(this.kernelUnitLengthY); };
    c.prototype.surfaceScale$getter = function() { return DOM$EnsureDartNull(this.surfaceScale); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGFEDiffuseLightingElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGFilterPrimitiveStandardAttributes$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFEDisplacementMapElement(c) {
  if (c.prototype) {
    c.prototype.in1$getter = function() { return DOM$EnsureDartNull(this.in1); };
    c.prototype.in2$getter = function() { return DOM$EnsureDartNull(this.in2); };
    c.prototype.scale$getter = function() { return DOM$EnsureDartNull(this.scale); };
    c.prototype.xChannelSelector$getter = function() { return DOM$EnsureDartNull(this.xChannelSelector); };
    c.prototype.yChannelSelector$getter = function() { return DOM$EnsureDartNull(this.yChannelSelector); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGFEDisplacementMapElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGFilterPrimitiveStandardAttributes$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFEDistantLightElement(c) {
  if (c.prototype) {
    c.prototype.azimuth$getter = function() { return DOM$EnsureDartNull(this.azimuth); };
    c.prototype.elevation$getter = function() { return DOM$EnsureDartNull(this.elevation); };
  }
  c.$implements$SVGFEDistantLightElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGFEDropShadowElement(c) {
  if (c.prototype) {
    c.prototype.dx$getter = function() { return DOM$EnsureDartNull(this.dx); };
    c.prototype.dy$getter = function() { return DOM$EnsureDartNull(this.dy); };
    c.prototype.in1$getter = function() { return DOM$EnsureDartNull(this.in1); };
    c.prototype.stdDeviationX$getter = function() { return DOM$EnsureDartNull(this.stdDeviationX); };
    c.prototype.stdDeviationY$getter = function() { return DOM$EnsureDartNull(this.stdDeviationY); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, [
    'setStdDeviation',
    'getPresentationAttribute']);
  c.$implements$SVGFEDropShadowElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGFilterPrimitiveStandardAttributes$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFEFloodElement(c) {
  if (c.prototype) {
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGFEFloodElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGFilterPrimitiveStandardAttributes$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFEFuncAElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGFEFuncAElement$Dart = 1;
  c.$implements$SVGComponentTransferFunctionElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGFEFuncBElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGFEFuncBElement$Dart = 1;
  c.$implements$SVGComponentTransferFunctionElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGFEFuncGElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGFEFuncGElement$Dart = 1;
  c.$implements$SVGComponentTransferFunctionElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGFEFuncRElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGFEFuncRElement$Dart = 1;
  c.$implements$SVGComponentTransferFunctionElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGFEGaussianBlurElement(c) {
  if (c.prototype) {
    c.prototype.in1$getter = function() { return DOM$EnsureDartNull(this.in1); };
    c.prototype.stdDeviationX$getter = function() { return DOM$EnsureDartNull(this.stdDeviationX); };
    c.prototype.stdDeviationY$getter = function() { return DOM$EnsureDartNull(this.stdDeviationY); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, [
    'setStdDeviation',
    'getPresentationAttribute']);
  c.$implements$SVGFEGaussianBlurElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGFilterPrimitiveStandardAttributes$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFEImageElement(c) {
  if (c.prototype) {
    c.prototype.preserveAspectRatio$getter = function() { return DOM$EnsureDartNull(this.preserveAspectRatio); };
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGFEImageElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGURIReference$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGFilterPrimitiveStandardAttributes$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFEMergeElement(c) {
  if (c.prototype) {
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGFEMergeElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGFilterPrimitiveStandardAttributes$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFEMergeNodeElement(c) {
  if (c.prototype) {
    c.prototype.in1$getter = function() { return DOM$EnsureDartNull(this.in1); };
  }
  c.$implements$SVGFEMergeNodeElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGFEMorphologyElement(c) {
  if (c.prototype) {
    c.prototype.in1$getter = function() { return DOM$EnsureDartNull(this.in1); };
    c.prototype.operator$getter = function() { return DOM$EnsureDartNull(this.operator); };
    c.prototype.radiusX$getter = function() { return DOM$EnsureDartNull(this.radiusX); };
    c.prototype.radiusY$getter = function() { return DOM$EnsureDartNull(this.radiusY); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, [
    'setRadius',
    'getPresentationAttribute']);
  c.$implements$SVGFEMorphologyElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGFilterPrimitiveStandardAttributes$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFEOffsetElement(c) {
  if (c.prototype) {
    c.prototype.dx$getter = function() { return DOM$EnsureDartNull(this.dx); };
    c.prototype.dy$getter = function() { return DOM$EnsureDartNull(this.dy); };
    c.prototype.in1$getter = function() { return DOM$EnsureDartNull(this.in1); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGFEOffsetElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGFilterPrimitiveStandardAttributes$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFEPointLightElement(c) {
  if (c.prototype) {
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.z$getter = function() { return DOM$EnsureDartNull(this.z); };
  }
  c.$implements$SVGFEPointLightElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGFESpecularLightingElement(c) {
  if (c.prototype) {
    c.prototype.in1$getter = function() { return DOM$EnsureDartNull(this.in1); };
    c.prototype.specularConstant$getter = function() { return DOM$EnsureDartNull(this.specularConstant); };
    c.prototype.specularExponent$getter = function() { return DOM$EnsureDartNull(this.specularExponent); };
    c.prototype.surfaceScale$getter = function() { return DOM$EnsureDartNull(this.surfaceScale); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGFESpecularLightingElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGFilterPrimitiveStandardAttributes$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFESpotLightElement(c) {
  if (c.prototype) {
    c.prototype.limitingConeAngle$getter = function() { return DOM$EnsureDartNull(this.limitingConeAngle); };
    c.prototype.pointsAtX$getter = function() { return DOM$EnsureDartNull(this.pointsAtX); };
    c.prototype.pointsAtY$getter = function() { return DOM$EnsureDartNull(this.pointsAtY); };
    c.prototype.pointsAtZ$getter = function() { return DOM$EnsureDartNull(this.pointsAtZ); };
    c.prototype.specularExponent$getter = function() { return DOM$EnsureDartNull(this.specularExponent); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.z$getter = function() { return DOM$EnsureDartNull(this.z); };
  }
  c.$implements$SVGFESpotLightElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGFETileElement(c) {
  if (c.prototype) {
    c.prototype.in1$getter = function() { return DOM$EnsureDartNull(this.in1); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGFETileElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGFilterPrimitiveStandardAttributes$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFETurbulenceElement(c) {
  if (c.prototype) {
    c.prototype.baseFrequencyX$getter = function() { return DOM$EnsureDartNull(this.baseFrequencyX); };
    c.prototype.baseFrequencyY$getter = function() { return DOM$EnsureDartNull(this.baseFrequencyY); };
    c.prototype.numOctaves$getter = function() { return DOM$EnsureDartNull(this.numOctaves); };
    c.prototype.seed$getter = function() { return DOM$EnsureDartNull(this.seed); };
    c.prototype.stitchTiles$getter = function() { return DOM$EnsureDartNull(this.stitchTiles); };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGFETurbulenceElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGFilterPrimitiveStandardAttributes$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFilterElement(c) {
  if (c.prototype) {
    c.prototype.filterResX$getter = function() { return DOM$EnsureDartNull(this.filterResX); };
    c.prototype.filterResY$getter = function() { return DOM$EnsureDartNull(this.filterResY); };
    c.prototype.filterUnits$getter = function() { return DOM$EnsureDartNull(this.filterUnits); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.primitiveUnits$getter = function() { return DOM$EnsureDartNull(this.primitiveUnits); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, [
    'setFilterRes',
    'getPresentationAttribute']);
  c.$implements$SVGFilterElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGURIReference$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFilterPrimitiveStandardAttributes(c) {
  if (c.prototype) {
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.result$getter = function() { return DOM$EnsureDartNull(this.result); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
  }
  c.$implements$SVGFilterPrimitiveStandardAttributes$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGFitToViewBox(c) {
  if (c.prototype) {
    c.prototype.preserveAspectRatio$getter = function() { return DOM$EnsureDartNull(this.preserveAspectRatio); };
    c.prototype.viewBox$getter = function() { return DOM$EnsureDartNull(this.viewBox); };
  }
  c.$implements$SVGFitToViewBox$Dart = 1;
}
function DOM$fixClass$SVGFontElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGFontElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGFontFaceElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGFontFaceElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGFontFaceFormatElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGFontFaceFormatElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGFontFaceNameElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGFontFaceNameElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGFontFaceSrcElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGFontFaceSrcElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGFontFaceUriElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGFontFaceUriElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGForeignObjectElement(c) {
  if (c.prototype) {
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.transform$getter = function() { return DOM$EnsureDartNull(this.transform); };
    c.prototype.farthestViewportElement$getter = function() { return DOM$EnsureDartNull(this.farthestViewportElement); };
    c.prototype.nearestViewportElement$getter = function() { return DOM$EnsureDartNull(this.nearestViewportElement); };
  }
  DOM$fixMembers(c, [
    'hasExtension',
    'getPresentationAttribute',
    'getBBox',
    'getCTM',
    'getScreenCTM',
    'getTransformToElement']);
  c.$implements$SVGForeignObjectElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGTransformable$Dart = 1;
  c.$implements$SVGLocatable$Dart = 1;
}
function DOM$fixClass$SVGGElement(c) {
  if (c.prototype) {
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.transform$getter = function() { return DOM$EnsureDartNull(this.transform); };
    c.prototype.farthestViewportElement$getter = function() { return DOM$EnsureDartNull(this.farthestViewportElement); };
    c.prototype.nearestViewportElement$getter = function() { return DOM$EnsureDartNull(this.nearestViewportElement); };
  }
  DOM$fixMembers(c, [
    'hasExtension',
    'getPresentationAttribute',
    'getBBox',
    'getCTM',
    'getScreenCTM',
    'getTransformToElement']);
  c.$implements$SVGGElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGTransformable$Dart = 1;
  c.$implements$SVGLocatable$Dart = 1;
}
function DOM$fixClass$SVGGlyphElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGGlyphElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGGlyphRefElement(c) {
  if (c.prototype) {
    c.prototype.dx$getter = function() { return DOM$EnsureDartNull(this.dx); };
    c.prototype.dx$setter = function(value) { this.dx = value; };
    c.prototype.dy$getter = function() { return DOM$EnsureDartNull(this.dy); };
    c.prototype.dy$setter = function(value) { this.dy = value; };
    c.prototype.format$getter = function() { return DOM$EnsureDartNull(this.format); };
    c.prototype.format$setter = function(value) { this.format = value; };
    c.prototype.glyphRef$getter = function() { return DOM$EnsureDartNull(this.glyphRef); };
    c.prototype.glyphRef$setter = function(value) { this.glyphRef = value; };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGGlyphRefElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGURIReference$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGGradientElement(c) {
  if (c.prototype) {
    c.prototype.gradientTransform$getter = function() { return DOM$EnsureDartNull(this.gradientTransform); };
    c.prototype.gradientUnits$getter = function() { return DOM$EnsureDartNull(this.gradientUnits); };
    c.prototype.spreadMethod$getter = function() { return DOM$EnsureDartNull(this.spreadMethod); };
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGGradientElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGURIReference$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGHKernElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGHKernElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGImageElement(c) {
  if (c.prototype) {
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.preserveAspectRatio$getter = function() { return DOM$EnsureDartNull(this.preserveAspectRatio); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.transform$getter = function() { return DOM$EnsureDartNull(this.transform); };
    c.prototype.farthestViewportElement$getter = function() { return DOM$EnsureDartNull(this.farthestViewportElement); };
    c.prototype.nearestViewportElement$getter = function() { return DOM$EnsureDartNull(this.nearestViewportElement); };
  }
  DOM$fixMembers(c, [
    'hasExtension',
    'getPresentationAttribute',
    'getBBox',
    'getCTM',
    'getScreenCTM',
    'getTransformToElement']);
  c.$implements$SVGImageElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGURIReference$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGTransformable$Dart = 1;
  c.$implements$SVGLocatable$Dart = 1;
}
function DOM$fixClass$SVGLangSpace(c) {
  if (c.prototype) {
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
  }
  c.$implements$SVGLangSpace$Dart = 1;
}
function DOM$fixClass$SVGLength(c) {
  if (c.prototype) {
    c.prototype.unitType$getter = function() { return DOM$EnsureDartNull(this.unitType); };
    c.prototype.value$getter = function() { return DOM$EnsureDartNull(this.value); };
    c.prototype.value$setter = function(value) { this.value = value; };
    c.prototype.valueAsString$getter = function() { return DOM$EnsureDartNull(this.valueAsString); };
    c.prototype.valueAsString$setter = function(value) { this.valueAsString = value; };
    c.prototype.valueInSpecifiedUnits$getter = function() { return DOM$EnsureDartNull(this.valueInSpecifiedUnits); };
    c.prototype.valueInSpecifiedUnits$setter = function(value) { this.valueInSpecifiedUnits = value; };
  }
  DOM$fixMembers(c, [
    'convertToSpecifiedUnits',
    'newValueSpecifiedUnits']);
  c.$implements$SVGLength$Dart = 1;
}
function DOM$fixClass$SVGLengthList(c) {
  if (c.prototype) {
    c.prototype.numberOfItems$getter = function() { return DOM$EnsureDartNull(this.numberOfItems); };
  }
  DOM$fixMembers(c, [
    'appendItem',
    'clear',
    'getItem',
    'initialize',
    'insertItemBefore',
    'removeItem',
    'replaceItem']);
  c.$implements$SVGLengthList$Dart = 1;
}
function DOM$fixClass$SVGLineElement(c) {
  if (c.prototype) {
    c.prototype.x1$getter = function() { return DOM$EnsureDartNull(this.x1); };
    c.prototype.x2$getter = function() { return DOM$EnsureDartNull(this.x2); };
    c.prototype.y1$getter = function() { return DOM$EnsureDartNull(this.y1); };
    c.prototype.y2$getter = function() { return DOM$EnsureDartNull(this.y2); };
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.transform$getter = function() { return DOM$EnsureDartNull(this.transform); };
    c.prototype.farthestViewportElement$getter = function() { return DOM$EnsureDartNull(this.farthestViewportElement); };
    c.prototype.nearestViewportElement$getter = function() { return DOM$EnsureDartNull(this.nearestViewportElement); };
  }
  DOM$fixMembers(c, [
    'hasExtension',
    'getPresentationAttribute',
    'getBBox',
    'getCTM',
    'getScreenCTM',
    'getTransformToElement']);
  c.$implements$SVGLineElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGTransformable$Dart = 1;
  c.$implements$SVGLocatable$Dart = 1;
}
function DOM$fixClass$SVGLinearGradientElement(c) {
  if (c.prototype) {
    c.prototype.x1$getter = function() { return DOM$EnsureDartNull(this.x1); };
    c.prototype.x2$getter = function() { return DOM$EnsureDartNull(this.x2); };
    c.prototype.y1$getter = function() { return DOM$EnsureDartNull(this.y1); };
    c.prototype.y2$getter = function() { return DOM$EnsureDartNull(this.y2); };
  }
  c.$implements$SVGLinearGradientElement$Dart = 1;
  c.$implements$SVGGradientElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGURIReference$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGLocatable(c) {
  if (c.prototype) {
    c.prototype.farthestViewportElement$getter = function() { return DOM$EnsureDartNull(this.farthestViewportElement); };
    c.prototype.nearestViewportElement$getter = function() { return DOM$EnsureDartNull(this.nearestViewportElement); };
  }
  DOM$fixMembers(c, [
    'getBBox',
    'getCTM',
    'getScreenCTM',
    'getTransformToElement']);
  c.$implements$SVGLocatable$Dart = 1;
}
function DOM$fixClass$SVGMPathElement(c) {
  if (c.prototype) {
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
  }
  c.$implements$SVGMPathElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGURIReference$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
}
function DOM$fixClass$SVGMarkerElement(c) {
  if (c.prototype) {
    c.prototype.markerHeight$getter = function() { return DOM$EnsureDartNull(this.markerHeight); };
    c.prototype.markerUnits$getter = function() { return DOM$EnsureDartNull(this.markerUnits); };
    c.prototype.markerWidth$getter = function() { return DOM$EnsureDartNull(this.markerWidth); };
    c.prototype.orientAngle$getter = function() { return DOM$EnsureDartNull(this.orientAngle); };
    c.prototype.orientType$getter = function() { return DOM$EnsureDartNull(this.orientType); };
    c.prototype.refX$getter = function() { return DOM$EnsureDartNull(this.refX); };
    c.prototype.refY$getter = function() { return DOM$EnsureDartNull(this.refY); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.preserveAspectRatio$getter = function() { return DOM$EnsureDartNull(this.preserveAspectRatio); };
    c.prototype.viewBox$getter = function() { return DOM$EnsureDartNull(this.viewBox); };
  }
  DOM$fixMembers(c, [
    'setOrientToAngle',
    'setOrientToAuto',
    'getPresentationAttribute']);
  c.$implements$SVGMarkerElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGFitToViewBox$Dart = 1;
}
function DOM$fixClass$SVGMaskElement(c) {
  if (c.prototype) {
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.maskContentUnits$getter = function() { return DOM$EnsureDartNull(this.maskContentUnits); };
    c.prototype.maskUnits$getter = function() { return DOM$EnsureDartNull(this.maskUnits); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, [
    'hasExtension',
    'getPresentationAttribute']);
  c.$implements$SVGMaskElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGMatrix(c) {
  if (c.prototype) {
    c.prototype.a$getter = function() { return DOM$EnsureDartNull(this.a); };
    c.prototype.a$setter = function(value) { this.a = value; };
    c.prototype.b$getter = function() { return DOM$EnsureDartNull(this.b); };
    c.prototype.b$setter = function(value) { this.b = value; };
    c.prototype.c$getter = function() { return DOM$EnsureDartNull(this.c); };
    c.prototype.c$setter = function(value) { this.c = value; };
    c.prototype.d$getter = function() { return DOM$EnsureDartNull(this.d); };
    c.prototype.d$setter = function(value) { this.d = value; };
    c.prototype.e$getter = function() { return DOM$EnsureDartNull(this.e); };
    c.prototype.e$setter = function(value) { this.e = value; };
    c.prototype.f$getter = function() { return DOM$EnsureDartNull(this.f); };
    c.prototype.f$setter = function(value) { this.f = value; };
  }
  DOM$fixMembers(c, [
    'flipX',
    'flipY',
    'inverse',
    'multiply',
    'rotate',
    'rotateFromVector',
    'scale',
    'scaleNonUniform',
    'skewX',
    'skewY',
    'translate']);
  c.$implements$SVGMatrix$Dart = 1;
}
function DOM$fixClass$SVGMetadataElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGMetadataElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGMissingGlyphElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGMissingGlyphElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGNumber(c) {
  if (c.prototype) {
    c.prototype.value$getter = function() { return DOM$EnsureDartNull(this.value); };
    c.prototype.value$setter = function(value) { this.value = value; };
  }
  c.$implements$SVGNumber$Dart = 1;
}
function DOM$fixClass$SVGNumberList(c) {
  if (c.prototype) {
    c.prototype.numberOfItems$getter = function() { return DOM$EnsureDartNull(this.numberOfItems); };
  }
  DOM$fixMembers(c, [
    'appendItem',
    'clear',
    'getItem',
    'initialize',
    'insertItemBefore',
    'removeItem',
    'replaceItem']);
  c.$implements$SVGNumberList$Dart = 1;
}
function DOM$fixClass$SVGPaint(c) {
  if (c.prototype) {
    c.prototype.paintType$getter = function() { return DOM$EnsureDartNull(this.paintType); };
    c.prototype.uri$getter = function() { return DOM$EnsureDartNull(this.uri); };
  }
  DOM$fixMembers(c, [
    'setPaint',
    'setUri']);
  c.$implements$SVGPaint$Dart = 1;
  c.$implements$SVGColor$Dart = 1;
  c.$implements$CSSValue$Dart = 1;
}
function DOM$fixClass$SVGPathElement(c) {
  if (c.prototype) {
    c.prototype.animatedNormalizedPathSegList$getter = function() { return DOM$EnsureDartNull(this.animatedNormalizedPathSegList); };
    c.prototype.animatedPathSegList$getter = function() { return DOM$EnsureDartNull(this.animatedPathSegList); };
    c.prototype.normalizedPathSegList$getter = function() { return DOM$EnsureDartNull(this.normalizedPathSegList); };
    c.prototype.pathLength$getter = function() { return DOM$EnsureDartNull(this.pathLength); };
    c.prototype.pathSegList$getter = function() { return DOM$EnsureDartNull(this.pathSegList); };
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.transform$getter = function() { return DOM$EnsureDartNull(this.transform); };
    c.prototype.farthestViewportElement$getter = function() { return DOM$EnsureDartNull(this.farthestViewportElement); };
    c.prototype.nearestViewportElement$getter = function() { return DOM$EnsureDartNull(this.nearestViewportElement); };
  }
  DOM$fixMembers(c, [
    'createSVGPathSegArcAbs',
    'createSVGPathSegArcRel',
    'createSVGPathSegClosePath',
    'createSVGPathSegCurvetoCubicAbs',
    'createSVGPathSegCurvetoCubicRel',
    'createSVGPathSegCurvetoCubicSmoothAbs',
    'createSVGPathSegCurvetoCubicSmoothRel',
    'createSVGPathSegCurvetoQuadraticAbs',
    'createSVGPathSegCurvetoQuadraticRel',
    'createSVGPathSegCurvetoQuadraticSmoothAbs',
    'createSVGPathSegCurvetoQuadraticSmoothRel',
    'createSVGPathSegLinetoAbs',
    'createSVGPathSegLinetoHorizontalAbs',
    'createSVGPathSegLinetoHorizontalRel',
    'createSVGPathSegLinetoRel',
    'createSVGPathSegLinetoVerticalAbs',
    'createSVGPathSegLinetoVerticalRel',
    'createSVGPathSegMovetoAbs',
    'createSVGPathSegMovetoRel',
    'getPathSegAtLength',
    'getPointAtLength',
    'getTotalLength',
    'hasExtension',
    'getPresentationAttribute',
    'getBBox',
    'getCTM',
    'getScreenCTM',
    'getTransformToElement']);
  c.$implements$SVGPathElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGTransformable$Dart = 1;
  c.$implements$SVGLocatable$Dart = 1;
}
function DOM$fixClass$SVGPathSeg(c) {
  if (c.prototype) {
    c.prototype.pathSegType$getter = function() { return DOM$EnsureDartNull(this.pathSegType); };
    c.prototype.pathSegTypeAsLetter$getter = function() { return DOM$EnsureDartNull(this.pathSegTypeAsLetter); };
  }
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegArcAbs(c) {
  if (c.prototype) {
    c.prototype.angle$getter = function() { return DOM$EnsureDartNull(this.angle); };
    c.prototype.angle$setter = function(value) { this.angle = value; };
    c.prototype.largeArcFlag$getter = function() { return DOM$EnsureDartNull(this.largeArcFlag); };
    c.prototype.largeArcFlag$setter = function(value) { this.largeArcFlag = value; };
    c.prototype.r1$getter = function() { return DOM$EnsureDartNull(this.r1); };
    c.prototype.r1$setter = function(value) { this.r1 = value; };
    c.prototype.r2$getter = function() { return DOM$EnsureDartNull(this.r2); };
    c.prototype.r2$setter = function(value) { this.r2 = value; };
    c.prototype.sweepFlag$getter = function() { return DOM$EnsureDartNull(this.sweepFlag); };
    c.prototype.sweepFlag$setter = function(value) { this.sweepFlag = value; };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
  }
  c.$implements$SVGPathSegArcAbs$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegArcRel(c) {
  if (c.prototype) {
    c.prototype.angle$getter = function() { return DOM$EnsureDartNull(this.angle); };
    c.prototype.angle$setter = function(value) { this.angle = value; };
    c.prototype.largeArcFlag$getter = function() { return DOM$EnsureDartNull(this.largeArcFlag); };
    c.prototype.largeArcFlag$setter = function(value) { this.largeArcFlag = value; };
    c.prototype.r1$getter = function() { return DOM$EnsureDartNull(this.r1); };
    c.prototype.r1$setter = function(value) { this.r1 = value; };
    c.prototype.r2$getter = function() { return DOM$EnsureDartNull(this.r2); };
    c.prototype.r2$setter = function(value) { this.r2 = value; };
    c.prototype.sweepFlag$getter = function() { return DOM$EnsureDartNull(this.sweepFlag); };
    c.prototype.sweepFlag$setter = function(value) { this.sweepFlag = value; };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
  }
  c.$implements$SVGPathSegArcRel$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegClosePath(c) {
  if (c.prototype) {
  }
  c.$implements$SVGPathSegClosePath$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegCurvetoCubicAbs(c) {
  if (c.prototype) {
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
    c.prototype.x1$getter = function() { return DOM$EnsureDartNull(this.x1); };
    c.prototype.x1$setter = function(value) { this.x1 = value; };
    c.prototype.x2$getter = function() { return DOM$EnsureDartNull(this.x2); };
    c.prototype.x2$setter = function(value) { this.x2 = value; };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
    c.prototype.y1$getter = function() { return DOM$EnsureDartNull(this.y1); };
    c.prototype.y1$setter = function(value) { this.y1 = value; };
    c.prototype.y2$getter = function() { return DOM$EnsureDartNull(this.y2); };
    c.prototype.y2$setter = function(value) { this.y2 = value; };
  }
  c.$implements$SVGPathSegCurvetoCubicAbs$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegCurvetoCubicRel(c) {
  if (c.prototype) {
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
    c.prototype.x1$getter = function() { return DOM$EnsureDartNull(this.x1); };
    c.prototype.x1$setter = function(value) { this.x1 = value; };
    c.prototype.x2$getter = function() { return DOM$EnsureDartNull(this.x2); };
    c.prototype.x2$setter = function(value) { this.x2 = value; };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
    c.prototype.y1$getter = function() { return DOM$EnsureDartNull(this.y1); };
    c.prototype.y1$setter = function(value) { this.y1 = value; };
    c.prototype.y2$getter = function() { return DOM$EnsureDartNull(this.y2); };
    c.prototype.y2$setter = function(value) { this.y2 = value; };
  }
  c.$implements$SVGPathSegCurvetoCubicRel$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegCurvetoCubicSmoothAbs(c) {
  if (c.prototype) {
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
    c.prototype.x2$getter = function() { return DOM$EnsureDartNull(this.x2); };
    c.prototype.x2$setter = function(value) { this.x2 = value; };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
    c.prototype.y2$getter = function() { return DOM$EnsureDartNull(this.y2); };
    c.prototype.y2$setter = function(value) { this.y2 = value; };
  }
  c.$implements$SVGPathSegCurvetoCubicSmoothAbs$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegCurvetoCubicSmoothRel(c) {
  if (c.prototype) {
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
    c.prototype.x2$getter = function() { return DOM$EnsureDartNull(this.x2); };
    c.prototype.x2$setter = function(value) { this.x2 = value; };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
    c.prototype.y2$getter = function() { return DOM$EnsureDartNull(this.y2); };
    c.prototype.y2$setter = function(value) { this.y2 = value; };
  }
  c.$implements$SVGPathSegCurvetoCubicSmoothRel$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegCurvetoQuadraticAbs(c) {
  if (c.prototype) {
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
    c.prototype.x1$getter = function() { return DOM$EnsureDartNull(this.x1); };
    c.prototype.x1$setter = function(value) { this.x1 = value; };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
    c.prototype.y1$getter = function() { return DOM$EnsureDartNull(this.y1); };
    c.prototype.y1$setter = function(value) { this.y1 = value; };
  }
  c.$implements$SVGPathSegCurvetoQuadraticAbs$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegCurvetoQuadraticRel(c) {
  if (c.prototype) {
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
    c.prototype.x1$getter = function() { return DOM$EnsureDartNull(this.x1); };
    c.prototype.x1$setter = function(value) { this.x1 = value; };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
    c.prototype.y1$getter = function() { return DOM$EnsureDartNull(this.y1); };
    c.prototype.y1$setter = function(value) { this.y1 = value; };
  }
  c.$implements$SVGPathSegCurvetoQuadraticRel$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegCurvetoQuadraticSmoothAbs(c) {
  if (c.prototype) {
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
  }
  c.$implements$SVGPathSegCurvetoQuadraticSmoothAbs$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegCurvetoQuadraticSmoothRel(c) {
  if (c.prototype) {
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
  }
  c.$implements$SVGPathSegCurvetoQuadraticSmoothRel$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegLinetoAbs(c) {
  if (c.prototype) {
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
  }
  c.$implements$SVGPathSegLinetoAbs$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegLinetoHorizontalAbs(c) {
  if (c.prototype) {
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
  }
  c.$implements$SVGPathSegLinetoHorizontalAbs$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegLinetoHorizontalRel(c) {
  if (c.prototype) {
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
  }
  c.$implements$SVGPathSegLinetoHorizontalRel$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegLinetoRel(c) {
  if (c.prototype) {
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
  }
  c.$implements$SVGPathSegLinetoRel$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegLinetoVerticalAbs(c) {
  if (c.prototype) {
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
  }
  c.$implements$SVGPathSegLinetoVerticalAbs$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegLinetoVerticalRel(c) {
  if (c.prototype) {
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
  }
  c.$implements$SVGPathSegLinetoVerticalRel$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegList(c) {
  if (c.prototype) {
    c.prototype.numberOfItems$getter = function() { return DOM$EnsureDartNull(this.numberOfItems); };
  }
  DOM$fixMembers(c, [
    'appendItem',
    'clear',
    'getItem',
    'initialize',
    'insertItemBefore',
    'removeItem',
    'replaceItem']);
  c.$implements$SVGPathSegList$Dart = 1;
}
function DOM$fixClass$SVGPathSegMovetoAbs(c) {
  if (c.prototype) {
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
  }
  c.$implements$SVGPathSegMovetoAbs$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPathSegMovetoRel(c) {
  if (c.prototype) {
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
  }
  c.$implements$SVGPathSegMovetoRel$Dart = 1;
  c.$implements$SVGPathSeg$Dart = 1;
}
function DOM$fixClass$SVGPatternElement(c) {
  if (c.prototype) {
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.patternContentUnits$getter = function() { return DOM$EnsureDartNull(this.patternContentUnits); };
    c.prototype.patternTransform$getter = function() { return DOM$EnsureDartNull(this.patternTransform); };
    c.prototype.patternUnits$getter = function() { return DOM$EnsureDartNull(this.patternUnits); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.preserveAspectRatio$getter = function() { return DOM$EnsureDartNull(this.preserveAspectRatio); };
    c.prototype.viewBox$getter = function() { return DOM$EnsureDartNull(this.viewBox); };
  }
  DOM$fixMembers(c, [
    'hasExtension',
    'getPresentationAttribute']);
  c.$implements$SVGPatternElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGURIReference$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGFitToViewBox$Dart = 1;
}
function DOM$fixClass$SVGPoint(c) {
  if (c.prototype) {
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
  }
  DOM$fixMembers(c, ['matrixTransform']);
  c.$implements$SVGPoint$Dart = 1;
}
function DOM$fixClass$SVGPointList(c) {
  if (c.prototype) {
    c.prototype.numberOfItems$getter = function() { return DOM$EnsureDartNull(this.numberOfItems); };
  }
  DOM$fixMembers(c, [
    'appendItem',
    'clear',
    'getItem',
    'initialize',
    'insertItemBefore',
    'removeItem',
    'replaceItem']);
  c.$implements$SVGPointList$Dart = 1;
}
function DOM$fixClass$SVGPolygonElement(c) {
  if (c.prototype) {
    c.prototype.animatedPoints$getter = function() { return DOM$EnsureDartNull(this.animatedPoints); };
    c.prototype.points$getter = function() { return DOM$EnsureDartNull(this.points); };
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.transform$getter = function() { return DOM$EnsureDartNull(this.transform); };
    c.prototype.farthestViewportElement$getter = function() { return DOM$EnsureDartNull(this.farthestViewportElement); };
    c.prototype.nearestViewportElement$getter = function() { return DOM$EnsureDartNull(this.nearestViewportElement); };
  }
  DOM$fixMembers(c, [
    'hasExtension',
    'getPresentationAttribute',
    'getBBox',
    'getCTM',
    'getScreenCTM',
    'getTransformToElement']);
  c.$implements$SVGPolygonElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGTransformable$Dart = 1;
  c.$implements$SVGLocatable$Dart = 1;
}
function DOM$fixClass$SVGPolylineElement(c) {
  if (c.prototype) {
    c.prototype.animatedPoints$getter = function() { return DOM$EnsureDartNull(this.animatedPoints); };
    c.prototype.points$getter = function() { return DOM$EnsureDartNull(this.points); };
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.transform$getter = function() { return DOM$EnsureDartNull(this.transform); };
    c.prototype.farthestViewportElement$getter = function() { return DOM$EnsureDartNull(this.farthestViewportElement); };
    c.prototype.nearestViewportElement$getter = function() { return DOM$EnsureDartNull(this.nearestViewportElement); };
  }
  DOM$fixMembers(c, [
    'hasExtension',
    'getPresentationAttribute',
    'getBBox',
    'getCTM',
    'getScreenCTM',
    'getTransformToElement']);
  c.$implements$SVGPolylineElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGTransformable$Dart = 1;
  c.$implements$SVGLocatable$Dart = 1;
}
function DOM$fixClass$SVGPreserveAspectRatio(c) {
  if (c.prototype) {
    c.prototype.align$getter = function() { return DOM$EnsureDartNull(this.align); };
    c.prototype.align$setter = function(value) { this.align = value; };
    c.prototype.meetOrSlice$getter = function() { return DOM$EnsureDartNull(this.meetOrSlice); };
    c.prototype.meetOrSlice$setter = function(value) { this.meetOrSlice = value; };
  }
  c.$implements$SVGPreserveAspectRatio$Dart = 1;
}
function DOM$fixClass$SVGRadialGradientElement(c) {
  if (c.prototype) {
    c.prototype.cx$getter = function() { return DOM$EnsureDartNull(this.cx); };
    c.prototype.cy$getter = function() { return DOM$EnsureDartNull(this.cy); };
    c.prototype.fx$getter = function() { return DOM$EnsureDartNull(this.fx); };
    c.prototype.fy$getter = function() { return DOM$EnsureDartNull(this.fy); };
    c.prototype.r$getter = function() { return DOM$EnsureDartNull(this.r); };
  }
  c.$implements$SVGRadialGradientElement$Dart = 1;
  c.$implements$SVGGradientElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGURIReference$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGRect(c) {
  if (c.prototype) {
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.height$setter = function(value) { this.height = value; };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.width$setter = function(value) { this.width = value; };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
  }
  c.$implements$SVGRect$Dart = 1;
}
function DOM$fixClass$SVGRectElement(c) {
  if (c.prototype) {
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.rx$getter = function() { return DOM$EnsureDartNull(this.rx); };
    c.prototype.ry$getter = function() { return DOM$EnsureDartNull(this.ry); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.transform$getter = function() { return DOM$EnsureDartNull(this.transform); };
    c.prototype.farthestViewportElement$getter = function() { return DOM$EnsureDartNull(this.farthestViewportElement); };
    c.prototype.nearestViewportElement$getter = function() { return DOM$EnsureDartNull(this.nearestViewportElement); };
  }
  DOM$fixMembers(c, [
    'hasExtension',
    'getPresentationAttribute',
    'getBBox',
    'getCTM',
    'getScreenCTM',
    'getTransformToElement']);
  c.$implements$SVGRectElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGTransformable$Dart = 1;
  c.$implements$SVGLocatable$Dart = 1;
}
function DOM$fixClass$SVGRenderingIntent(c) {
  if (c.prototype) {
  }
  c.$implements$SVGRenderingIntent$Dart = 1;
}
function DOM$fixClass$SVGSVGElement(c) {
  if (c.prototype) {
    c.prototype.contentScriptType$getter = function() { return DOM$EnsureDartNull(this.contentScriptType); };
    c.prototype.contentScriptType$setter = function(value) { this.contentScriptType = value; };
    c.prototype.contentStyleType$getter = function() { return DOM$EnsureDartNull(this.contentStyleType); };
    c.prototype.contentStyleType$setter = function(value) { this.contentStyleType = value; };
    c.prototype.currentScale$getter = function() { return DOM$EnsureDartNull(this.currentScale); };
    c.prototype.currentScale$setter = function(value) { this.currentScale = value; };
    c.prototype.currentTranslate$getter = function() { return DOM$EnsureDartNull(this.currentTranslate); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.pixelUnitToMillimeterX$getter = function() { return DOM$EnsureDartNull(this.pixelUnitToMillimeterX); };
    c.prototype.pixelUnitToMillimeterY$getter = function() { return DOM$EnsureDartNull(this.pixelUnitToMillimeterY); };
    c.prototype.screenPixelToMillimeterX$getter = function() { return DOM$EnsureDartNull(this.screenPixelToMillimeterX); };
    c.prototype.screenPixelToMillimeterY$getter = function() { return DOM$EnsureDartNull(this.screenPixelToMillimeterY); };
    c.prototype.useCurrentView$getter = function() { return DOM$EnsureDartNull(this.useCurrentView); };
    c.prototype.useCurrentView$setter = function(value) { this.useCurrentView = value; };
    c.prototype.viewport$getter = function() { return DOM$EnsureDartNull(this.viewport); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.farthestViewportElement$getter = function() { return DOM$EnsureDartNull(this.farthestViewportElement); };
    c.prototype.nearestViewportElement$getter = function() { return DOM$EnsureDartNull(this.nearestViewportElement); };
    c.prototype.preserveAspectRatio$getter = function() { return DOM$EnsureDartNull(this.preserveAspectRatio); };
    c.prototype.viewBox$getter = function() { return DOM$EnsureDartNull(this.viewBox); };
    c.prototype.zoomAndPan$getter = function() { return DOM$EnsureDartNull(this.zoomAndPan); };
    c.prototype.zoomAndPan$setter = function(value) { this.zoomAndPan = value; };
  }
  DOM$fixMembers(c, [
    'animationsPaused',
    'checkEnclosure',
    'checkIntersection',
    'createSVGAngle',
    'createSVGLength',
    'createSVGMatrix',
    'createSVGNumber',
    'createSVGPoint',
    'createSVGRect',
    'createSVGTransform',
    'createSVGTransformFromMatrix',
    'deselectAll',
    'forceRedraw',
    'getCurrentTime',
    'getElementById',
    'getEnclosureList',
    'getIntersectionList',
    'pauseAnimations',
    'setCurrentTime',
    'suspendRedraw',
    'unpauseAnimations',
    'unsuspendRedraw',
    'unsuspendRedrawAll',
    'hasExtension',
    'getPresentationAttribute',
    'getBBox',
    'getCTM',
    'getScreenCTM',
    'getTransformToElement']);
  c.$implements$SVGSVGElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGLocatable$Dart = 1;
  c.$implements$SVGFitToViewBox$Dart = 1;
  c.$implements$SVGZoomAndPan$Dart = 1;
}
function DOM$fixClass$SVGScriptElement(c) {
  if (c.prototype) {
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.type$setter = function(value) { this.type = value; };
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
  }
  c.$implements$SVGScriptElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGURIReference$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
}
function DOM$fixClass$SVGSetElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGSetElement$Dart = 1;
  c.$implements$SVGAnimationElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$ElementTimeControl$Dart = 1;
}
function DOM$fixClass$SVGStopElement(c) {
  if (c.prototype) {
    c.prototype.offset$getter = function() { return DOM$EnsureDartNull(this.offset); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGStopElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGStringList(c) {
  if (c.prototype) {
    c.prototype.numberOfItems$getter = function() { return DOM$EnsureDartNull(this.numberOfItems); };
  }
  DOM$fixMembers(c, [
    'appendItem',
    'clear',
    'getItem',
    'initialize',
    'insertItemBefore',
    'removeItem',
    'replaceItem']);
  c.$implements$SVGStringList$Dart = 1;
}
function DOM$fixClass$SVGStylable(c) {
  if (c.prototype) {
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGStyleElement(c) {
  if (c.prototype) {
    c.prototype.media$getter = function() { return DOM$EnsureDartNull(this.media); };
    c.prototype.media$setter = function(value) { this.media = value; };
    c.prototype.title$getter = function() { return DOM$EnsureDartNull(this.title); };
    c.prototype.title$setter = function(value) { this.title = value; };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
    c.prototype.type$setter = function(value) { this.type = value; };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
  }
  c.$implements$SVGStyleElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
}
function DOM$fixClass$SVGSwitchElement(c) {
  if (c.prototype) {
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.transform$getter = function() { return DOM$EnsureDartNull(this.transform); };
    c.prototype.farthestViewportElement$getter = function() { return DOM$EnsureDartNull(this.farthestViewportElement); };
    c.prototype.nearestViewportElement$getter = function() { return DOM$EnsureDartNull(this.nearestViewportElement); };
  }
  DOM$fixMembers(c, [
    'hasExtension',
    'getPresentationAttribute',
    'getBBox',
    'getCTM',
    'getScreenCTM',
    'getTransformToElement']);
  c.$implements$SVGSwitchElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGTransformable$Dart = 1;
  c.$implements$SVGLocatable$Dart = 1;
}
function DOM$fixClass$SVGSymbolElement(c) {
  if (c.prototype) {
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.preserveAspectRatio$getter = function() { return DOM$EnsureDartNull(this.preserveAspectRatio); };
    c.prototype.viewBox$getter = function() { return DOM$EnsureDartNull(this.viewBox); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGSymbolElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGFitToViewBox$Dart = 1;
}
function DOM$fixClass$SVGTRefElement(c) {
  if (c.prototype) {
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
  }
  c.$implements$SVGTRefElement$Dart = 1;
  c.$implements$SVGTextPositioningElement$Dart = 1;
  c.$implements$SVGTextContentElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGURIReference$Dart = 1;
}
function DOM$fixClass$SVGTSpanElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGTSpanElement$Dart = 1;
  c.$implements$SVGTextPositioningElement$Dart = 1;
  c.$implements$SVGTextContentElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGTests(c) {
  if (c.prototype) {
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
  }
  DOM$fixMembers(c, ['hasExtension']);
  c.$implements$SVGTests$Dart = 1;
}
function DOM$fixClass$SVGTextContentElement(c) {
  if (c.prototype) {
    c.prototype.lengthAdjust$getter = function() { return DOM$EnsureDartNull(this.lengthAdjust); };
    c.prototype.textLength$getter = function() { return DOM$EnsureDartNull(this.textLength); };
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, [
    'getCharNumAtPosition',
    'getComputedTextLength',
    'getEndPositionOfChar',
    'getExtentOfChar',
    'getNumberOfChars',
    'getRotationOfChar',
    'getStartPositionOfChar',
    'getSubStringLength',
    'selectSubString',
    'hasExtension',
    'getPresentationAttribute']);
  c.$implements$SVGTextContentElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGTextElement(c) {
  if (c.prototype) {
    c.prototype.transform$getter = function() { return DOM$EnsureDartNull(this.transform); };
    c.prototype.farthestViewportElement$getter = function() { return DOM$EnsureDartNull(this.farthestViewportElement); };
    c.prototype.nearestViewportElement$getter = function() { return DOM$EnsureDartNull(this.nearestViewportElement); };
  }
  DOM$fixMembers(c, [
    'getBBox',
    'getCTM',
    'getScreenCTM',
    'getTransformToElement']);
  c.$implements$SVGTextElement$Dart = 1;
  c.$implements$SVGTextPositioningElement$Dart = 1;
  c.$implements$SVGTextContentElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGTransformable$Dart = 1;
  c.$implements$SVGLocatable$Dart = 1;
}
function DOM$fixClass$SVGTextPathElement(c) {
  if (c.prototype) {
    c.prototype.method$getter = function() { return DOM$EnsureDartNull(this.method); };
    c.prototype.spacing$getter = function() { return DOM$EnsureDartNull(this.spacing); };
    c.prototype.startOffset$getter = function() { return DOM$EnsureDartNull(this.startOffset); };
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
  }
  c.$implements$SVGTextPathElement$Dart = 1;
  c.$implements$SVGTextContentElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGURIReference$Dart = 1;
}
function DOM$fixClass$SVGTextPositioningElement(c) {
  if (c.prototype) {
    c.prototype.dx$getter = function() { return DOM$EnsureDartNull(this.dx); };
    c.prototype.dy$getter = function() { return DOM$EnsureDartNull(this.dy); };
    c.prototype.rotate$getter = function() { return DOM$EnsureDartNull(this.rotate); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
  }
  c.$implements$SVGTextPositioningElement$Dart = 1;
  c.$implements$SVGTextContentElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGTitleElement(c) {
  if (c.prototype) {
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  DOM$fixMembers(c, ['getPresentationAttribute']);
  c.$implements$SVGTitleElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
}
function DOM$fixClass$SVGTransform(c) {
  if (c.prototype) {
    c.prototype.angle$getter = function() { return DOM$EnsureDartNull(this.angle); };
    c.prototype.matrix$getter = function() { return DOM$EnsureDartNull(this.matrix); };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
  }
  DOM$fixMembers(c, [
    'setMatrix',
    'setRotate',
    'setScale',
    'setSkewX',
    'setSkewY',
    'setTranslate']);
  c.$implements$SVGTransform$Dart = 1;
}
function DOM$fixClass$SVGTransformList(c) {
  if (c.prototype) {
    c.prototype.numberOfItems$getter = function() { return DOM$EnsureDartNull(this.numberOfItems); };
  }
  DOM$fixMembers(c, [
    'appendItem',
    'clear',
    'consolidate',
    'createSVGTransformFromMatrix',
    'getItem',
    'initialize',
    'insertItemBefore',
    'removeItem',
    'replaceItem']);
  c.$implements$SVGTransformList$Dart = 1;
}
function DOM$fixClass$SVGTransformable(c) {
  if (c.prototype) {
    c.prototype.transform$getter = function() { return DOM$EnsureDartNull(this.transform); };
  }
  c.$implements$SVGTransformable$Dart = 1;
  c.$implements$SVGLocatable$Dart = 1;
}
function DOM$fixClass$SVGURIReference(c) {
  if (c.prototype) {
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
  }
  c.$implements$SVGURIReference$Dart = 1;
}
function DOM$fixClass$SVGUnitTypes(c) {
  if (c.prototype) {
  }
  c.$implements$SVGUnitTypes$Dart = 1;
}
function DOM$fixClass$SVGUseElement(c) {
  if (c.prototype) {
    c.prototype.animatedInstanceRoot$getter = function() { return DOM$EnsureDartNull(this.animatedInstanceRoot); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.instanceRoot$getter = function() { return DOM$EnsureDartNull(this.instanceRoot); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.requiredExtensions$getter = function() { return DOM$EnsureDartNull(this.requiredExtensions); };
    c.prototype.requiredFeatures$getter = function() { return DOM$EnsureDartNull(this.requiredFeatures); };
    c.prototype.systemLanguage$getter = function() { return DOM$EnsureDartNull(this.systemLanguage); };
    c.prototype.xmllang$getter = function() { return DOM$EnsureDartNull(this.xmllang); };
    c.prototype.xmllang$setter = function(value) { this.xmllang = value; };
    c.prototype.xmlspace$getter = function() { return DOM$EnsureDartNull(this.xmlspace); };
    c.prototype.xmlspace$setter = function(value) { this.xmlspace = value; };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.className$getter = function() { return DOM$EnsureDartNull(this.className); };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
    c.prototype.transform$getter = function() { return DOM$EnsureDartNull(this.transform); };
    c.prototype.farthestViewportElement$getter = function() { return DOM$EnsureDartNull(this.farthestViewportElement); };
    c.prototype.nearestViewportElement$getter = function() { return DOM$EnsureDartNull(this.nearestViewportElement); };
  }
  DOM$fixMembers(c, [
    'hasExtension',
    'getPresentationAttribute',
    'getBBox',
    'getCTM',
    'getScreenCTM',
    'getTransformToElement']);
  c.$implements$SVGUseElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGURIReference$Dart = 1;
  c.$implements$SVGTests$Dart = 1;
  c.$implements$SVGLangSpace$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGStylable$Dart = 1;
  c.$implements$SVGTransformable$Dart = 1;
  c.$implements$SVGLocatable$Dart = 1;
}
function DOM$fixClass$SVGVKernElement(c) {
  if (c.prototype) {
  }
  c.$implements$SVGVKernElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
}
function DOM$fixClass$SVGViewElement(c) {
  if (c.prototype) {
    c.prototype.viewTarget$getter = function() { return DOM$EnsureDartNull(this.viewTarget); };
    c.prototype.externalResourcesRequired$getter = function() { return DOM$EnsureDartNull(this.externalResourcesRequired); };
    c.prototype.preserveAspectRatio$getter = function() { return DOM$EnsureDartNull(this.preserveAspectRatio); };
    c.prototype.viewBox$getter = function() { return DOM$EnsureDartNull(this.viewBox); };
    c.prototype.zoomAndPan$getter = function() { return DOM$EnsureDartNull(this.zoomAndPan); };
    c.prototype.zoomAndPan$setter = function(value) { this.zoomAndPan = value; };
  }
  c.$implements$SVGViewElement$Dart = 1;
  c.$implements$SVGElement$Dart = 1;
  c.$implements$Element$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
  c.$implements$NodeSelector$Dart = 1;
  c.$implements$ElementTraversal$Dart = 1;
  c.$implements$SVGExternalResourcesRequired$Dart = 1;
  c.$implements$SVGFitToViewBox$Dart = 1;
  c.$implements$SVGZoomAndPan$Dart = 1;
}
function DOM$fixClass$SVGViewSpec(c) {
  if (c.prototype) {
    c.prototype.preserveAspectRatioString$getter = function() { return DOM$EnsureDartNull(this.preserveAspectRatioString); };
    c.prototype.transform$getter = function() { return DOM$EnsureDartNull(this.transform); };
    c.prototype.transformString$getter = function() { return DOM$EnsureDartNull(this.transformString); };
    c.prototype.viewBoxString$getter = function() { return DOM$EnsureDartNull(this.viewBoxString); };
    c.prototype.viewTarget$getter = function() { return DOM$EnsureDartNull(this.viewTarget); };
    c.prototype.viewTargetString$getter = function() { return DOM$EnsureDartNull(this.viewTargetString); };
    c.prototype.preserveAspectRatio$getter = function() { return DOM$EnsureDartNull(this.preserveAspectRatio); };
    c.prototype.viewBox$getter = function() { return DOM$EnsureDartNull(this.viewBox); };
  }
  c.$implements$SVGViewSpec$Dart = 1;
  c.$implements$SVGZoomAndPan$Dart = 1;
  c.$implements$SVGFitToViewBox$Dart = 1;
}
function DOM$fixClass$SVGZoomAndPan(c) {
  if (c.prototype) {
    c.prototype.zoomAndPan$getter = function() { return DOM$EnsureDartNull(this.zoomAndPan); };
    c.prototype.zoomAndPan$setter = function(value) { this.zoomAndPan = value; };
  }
  c.$implements$SVGZoomAndPan$Dart = 1;
}
function DOM$fixClass$SVGZoomEvent(c) {
  if (c.prototype) {
    c.prototype.newScale$getter = function() { return DOM$EnsureDartNull(this.newScale); };
    c.prototype.newTranslate$getter = function() { return DOM$EnsureDartNull(this.newTranslate); };
    c.prototype.previousScale$getter = function() { return DOM$EnsureDartNull(this.previousScale); };
    c.prototype.previousTranslate$getter = function() { return DOM$EnsureDartNull(this.previousTranslate); };
    c.prototype.zoomRectScreen$getter = function() { return DOM$EnsureDartNull(this.zoomRectScreen); };
  }
  c.$implements$SVGZoomEvent$Dart = 1;
  c.$implements$UIEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$Screen(c) {
  if (c.prototype) {
    c.prototype.availHeight$getter = function() { return DOM$EnsureDartNull(this.availHeight); };
    c.prototype.availLeft$getter = function() { return DOM$EnsureDartNull(this.availLeft); };
    c.prototype.availTop$getter = function() { return DOM$EnsureDartNull(this.availTop); };
    c.prototype.availWidth$getter = function() { return DOM$EnsureDartNull(this.availWidth); };
    c.prototype.colorDepth$getter = function() { return DOM$EnsureDartNull(this.colorDepth); };
    c.prototype.height$getter = function() { return DOM$EnsureDartNull(this.height); };
    c.prototype.pixelDepth$getter = function() { return DOM$EnsureDartNull(this.pixelDepth); };
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
  }
  c.$implements$Screen$Dart = 1;
}
function DOM$fixClass$ScriptProfile(c) {
  if (c.prototype) {
    c.prototype.head$getter = function() { return DOM$EnsureDartNull(this.head); };
    c.prototype.title$getter = function() { return DOM$EnsureDartNull(this.title); };
    c.prototype.uid$getter = function() { return DOM$EnsureDartNull(this.uid); };
  }
  c.$implements$ScriptProfile$Dart = 1;
}
function DOM$fixClass$ScriptProfileNode(c) {
  if (c.prototype) {
    c.prototype.callUID$getter = function() { return DOM$EnsureDartNull(this.callUID); };
    c.prototype.children$getter = function() { return DOM$EnsureDartNull(this.children); };
    c.prototype.functionName$getter = function() { return DOM$EnsureDartNull(this.functionName); };
    c.prototype.lineNumber$getter = function() { return DOM$EnsureDartNull(this.lineNumber); };
    c.prototype.numberOfCalls$getter = function() { return DOM$EnsureDartNull(this.numberOfCalls); };
    c.prototype.selfTime$getter = function() { return DOM$EnsureDartNull(this.selfTime); };
    c.prototype.totalTime$getter = function() { return DOM$EnsureDartNull(this.totalTime); };
    c.prototype.url$getter = function() { return DOM$EnsureDartNull(this.url); };
    c.prototype.visible$getter = function() { return DOM$EnsureDartNull(this.visible); };
  }
  c.$implements$ScriptProfileNode$Dart = 1;
}
function DOM$fixClass$SharedWorker(c) {
  if (c.prototype) {
    c.prototype.port$getter = function() { return DOM$EnsureDartNull(this.port); };
  }
  c.$implements$SharedWorker$Dart = 1;
  c.$implements$AbstractWorker$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$SharedWorkercontext(c) {
  if (c.prototype) {
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
  }
  c.$implements$SharedWorkercontext$Dart = 1;
  c.$implements$WorkerContext$Dart = 1;
}
function DOM$fixClass$SpeechInputEvent(c) {
  if (c.prototype) {
    c.prototype.results$getter = function() { return DOM$EnsureDartNull(this.results); };
  }
  c.$implements$SpeechInputEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$SpeechInputResult(c) {
  if (c.prototype) {
    c.prototype.confidence$getter = function() { return DOM$EnsureDartNull(this.confidence); };
    c.prototype.utterance$getter = function() { return DOM$EnsureDartNull(this.utterance); };
  }
  c.$implements$SpeechInputResult$Dart = 1;
}
function DOM$fixClass$SpeechInputResultList(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, ['item']);
  c.$implements$SpeechInputResultList$Dart = 1;
}
function DOM$fixClass$Storage(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, [
    'clear',
    'getItem',
    'key',
    'removeItem',
    'setItem']);
  c.$implements$Storage$Dart = 1;
}
function DOM$fixClass$StorageEvent(c) {
  if (c.prototype) {
    c.prototype.key$getter = function() { return DOM$EnsureDartNull(this.key); };
    c.prototype.newValue$getter = function() { return DOM$EnsureDartNull(this.newValue); };
    c.prototype.oldValue$getter = function() { return DOM$EnsureDartNull(this.oldValue); };
    c.prototype.storageArea$getter = function() { return DOM$EnsureDartNull(this.storageArea); };
    c.prototype.url$getter = function() { return DOM$EnsureDartNull(this.url); };
  }
  DOM$fixMembers(c, ['initStorageEvent']);
  c.$implements$StorageEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$StorageInfo(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'queryUsageAndQuota',
    'requestQuota']);
  c.$implements$StorageInfo$Dart = 1;
}
function DOM$fixClass$StorageInfoErrorCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$StorageInfoErrorCallback$Dart = 1;
}
function DOM$fixClass$StorageInfoQuotaCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$StorageInfoQuotaCallback$Dart = 1;
}
function DOM$fixClass$StorageInfoUsageCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$StorageInfoUsageCallback$Dart = 1;
}
function DOM$fixClass$StringCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$StringCallback$Dart = 1;
}
function DOM$fixClass$StyleMedia(c) {
  if (c.prototype) {
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
  }
  DOM$fixMembers(c, ['matchMedium']);
  c.$implements$StyleMedia$Dart = 1;
}
function DOM$fixClass$StyleSheet(c) {
  if (c.prototype) {
    c.prototype.disabled$getter = function() { return DOM$EnsureDartNull(this.disabled); };
    c.prototype.disabled$setter = function(value) { this.disabled = value; };
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.media$getter = function() { return DOM$EnsureDartNull(this.media); };
    c.prototype.ownerNode$getter = function() { return DOM$EnsureDartNull(this.ownerNode); };
    c.prototype.parentStyleSheet$getter = function() { return DOM$EnsureDartNull(this.parentStyleSheet); };
    c.prototype.title$getter = function() { return DOM$EnsureDartNull(this.title); };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
  }
  c.$implements$StyleSheet$Dart = 1;
}
function DOM$fixClass$StyleSheetList(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
    c.prototype.INDEX$operator = function(k) { return DOM$EnsureDartNull(this[k]); };
    c.prototype.ASSIGN_INDEX$operator = function(k, v) { this[k] = v; };
  }
  DOM$fixMembers(c, ['item']);
  c.$implements$StyleSheetList$Dart = 1;
}
function DOM$fixClass$Text(c) {
  if (c.prototype) {
    c.prototype.wholeText$getter = function() { return DOM$EnsureDartNull(this.wholeText); };
  }
  DOM$fixMembers(c, [
    'replaceWholeText',
    'splitText']);
  c.$implements$Text$Dart = 1;
  c.$implements$CharacterData$Dart = 1;
  c.$implements$Node$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$TextEvent(c) {
  if (c.prototype) {
    c.prototype.data$getter = function() { return DOM$EnsureDartNull(this.data); };
  }
  DOM$fixMembers(c, ['initTextEvent']);
  c.$implements$TextEvent$Dart = 1;
  c.$implements$UIEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$TextMetrics(c) {
  if (c.prototype) {
    c.prototype.width$getter = function() { return DOM$EnsureDartNull(this.width); };
  }
  c.$implements$TextMetrics$Dart = 1;
}
function DOM$fixClass$TextTrack(c) {
  if (c.prototype) {
    c.prototype.activeCues$getter = function() { return DOM$EnsureDartNull(this.activeCues); };
    c.prototype.cues$getter = function() { return DOM$EnsureDartNull(this.cues); };
    c.prototype.kind$getter = function() { return DOM$EnsureDartNull(this.kind); };
    c.prototype.label$getter = function() { return DOM$EnsureDartNull(this.label); };
    c.prototype.language$getter = function() { return DOM$EnsureDartNull(this.language); };
    c.prototype.mode$getter = function() { return DOM$EnsureDartNull(this.mode); };
    c.prototype.mode$setter = function(value) { this.mode = value; };
    c.prototype.readyState$getter = function() { return DOM$EnsureDartNull(this.readyState); };
  }
  DOM$fixMembers(c, [
    'addCue',
    'removeCue']);
  c.$implements$TextTrack$Dart = 1;
}
function DOM$fixClass$TextTrackCue(c) {
  if (c.prototype) {
    c.prototype.alignment$getter = function() { return DOM$EnsureDartNull(this.alignment); };
    c.prototype.direction$getter = function() { return DOM$EnsureDartNull(this.direction); };
    c.prototype.endTime$getter = function() { return DOM$EnsureDartNull(this.endTime); };
    c.prototype.id$getter = function() { return DOM$EnsureDartNull(this.id); };
    c.prototype.linePosition$getter = function() { return DOM$EnsureDartNull(this.linePosition); };
    c.prototype.pauseOnExit$getter = function() { return DOM$EnsureDartNull(this.pauseOnExit); };
    c.prototype.size$getter = function() { return DOM$EnsureDartNull(this.size); };
    c.prototype.snapToLines$getter = function() { return DOM$EnsureDartNull(this.snapToLines); };
    c.prototype.startTime$getter = function() { return DOM$EnsureDartNull(this.startTime); };
    c.prototype.textPosition$getter = function() { return DOM$EnsureDartNull(this.textPosition); };
    c.prototype.track$getter = function() { return DOM$EnsureDartNull(this.track); };
  }
  DOM$fixMembers(c, [
    'getCueAsHTML',
    'getCueAsSource']);
  c.$implements$TextTrackCue$Dart = 1;
}
function DOM$fixClass$TextTrackCueList(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, [
    'getCueById',
    'item']);
  c.$implements$TextTrackCueList$Dart = 1;
}
function DOM$fixClass$TimeRanges(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, [
    'end',
    'start']);
  c.$implements$TimeRanges$Dart = 1;
}
function DOM$fixClass$Touch(c) {
  if (c.prototype) {
    c.prototype.clientX$getter = function() { return DOM$EnsureDartNull(this.clientX); };
    c.prototype.clientY$getter = function() { return DOM$EnsureDartNull(this.clientY); };
    c.prototype.identifier$getter = function() { return DOM$EnsureDartNull(this.identifier); };
    c.prototype.pageX$getter = function() { return DOM$EnsureDartNull(this.pageX); };
    c.prototype.pageY$getter = function() { return DOM$EnsureDartNull(this.pageY); };
    c.prototype.screenX$getter = function() { return DOM$EnsureDartNull(this.screenX); };
    c.prototype.screenY$getter = function() { return DOM$EnsureDartNull(this.screenY); };
    c.prototype.target$getter = function() { return DOM$EnsureDartNull(this.target); };
    c.prototype.webkitForce$getter = function() { return DOM$EnsureDartNull(this.webkitForce); };
    c.prototype.webkitRadiusX$getter = function() { return DOM$EnsureDartNull(this.webkitRadiusX); };
    c.prototype.webkitRadiusY$getter = function() { return DOM$EnsureDartNull(this.webkitRadiusY); };
    c.prototype.webkitRotationAngle$getter = function() { return DOM$EnsureDartNull(this.webkitRotationAngle); };
  }
  c.$implements$Touch$Dart = 1;
}
function DOM$fixClassOnDemand$Touch(c) {
  if (c.DOM$initialized === true)
    return;
  c.DOM$initialized = true;
  DOM$fixClass$Touch(c);
}
function DOM$fixValue$Touch(value) {
  if (value == null)
    return DOM$EnsureDartNull(value);
  if (typeof value != "object")
    return value;
  var constructor = value.constructor;
  if (constructor == null)
    return value;
  DOM$fixClassOnDemand$Touch(constructor);
  return value;
}
function DOM$fixClass$TouchEvent(c) {
  if (c.prototype) {
    c.prototype.altKey$getter = function() { return DOM$EnsureDartNull(this.altKey); };
    c.prototype.changedTouches$getter = function() { return DOM$fixValue$TouchList(this.changedTouches); };
    c.prototype.ctrlKey$getter = function() { return DOM$EnsureDartNull(this.ctrlKey); };
    c.prototype.metaKey$getter = function() { return DOM$EnsureDartNull(this.metaKey); };
    c.prototype.shiftKey$getter = function() { return DOM$EnsureDartNull(this.shiftKey); };
    c.prototype.targetTouches$getter = function() { return DOM$fixValue$TouchList(this.targetTouches); };
    c.prototype.touches$getter = function() { return DOM$fixValue$TouchList(this.touches); };
  }
  DOM$fixMembers(c, ['initTouchEvent']);
  c.$implements$TouchEvent$Dart = 1;
  c.$implements$UIEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$TouchList(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
    c.prototype.INDEX$operator = function(k) { return DOM$fixValue$Touch(this[k]); };
    c.prototype.ASSIGN_INDEX$operator = function(k, v) { this[k] = v; };
  }
  c.prototype.item$member = function() {
    return DOM$fixValue$Touch(this.item.apply(this, arguments));
  };
  c.$implements$TouchList$Dart = 1;
}
function DOM$fixClassOnDemand$TouchList(c) {
  if (c.DOM$initialized === true)
    return;
  c.DOM$initialized = true;
  DOM$fixClass$TouchList(c);
}
function DOM$fixValue$TouchList(value) {
  if (value == null)
    return DOM$EnsureDartNull(value);
  if (typeof value != "object")
    return value;
  var constructor = value.constructor;
  if (constructor == null)
    return value;
  DOM$fixClassOnDemand$TouchList(constructor);
  return value;
}
function DOM$fixClass$TreeWalker(c) {
  if (c.prototype) {
    c.prototype.currentNode$getter = function() { return DOM$EnsureDartNull(this.currentNode); };
    c.prototype.currentNode$setter = function(value) { this.currentNode = value; };
    c.prototype.expandEntityReferences$getter = function() { return DOM$EnsureDartNull(this.expandEntityReferences); };
    c.prototype.filter$getter = function() { return DOM$EnsureDartNull(this.filter); };
    c.prototype.root$getter = function() { return DOM$EnsureDartNull(this.root); };
    c.prototype.whatToShow$getter = function() { return DOM$EnsureDartNull(this.whatToShow); };
  }
  DOM$fixMembers(c, [
    'firstChild',
    'lastChild',
    'nextNode',
    'nextSibling',
    'parentNode',
    'previousNode',
    'previousSibling']);
  c.$implements$TreeWalker$Dart = 1;
}
function DOM$fixClass$UIEvent(c) {
  if (c.prototype) {
    c.prototype.charCode$getter = function() { return DOM$EnsureDartNull(this.charCode); };
    c.prototype.detail$getter = function() { return DOM$EnsureDartNull(this.detail); };
    c.prototype.keyCode$getter = function() { return DOM$EnsureDartNull(this.keyCode); };
    c.prototype.layerX$getter = function() { return DOM$EnsureDartNull(this.layerX); };
    c.prototype.layerY$getter = function() { return DOM$EnsureDartNull(this.layerY); };
    c.prototype.pageX$getter = function() { return DOM$EnsureDartNull(this.pageX); };
    c.prototype.pageY$getter = function() { return DOM$EnsureDartNull(this.pageY); };
    c.prototype.view$getter = function() { return DOM$EnsureDartNull(this.view); };
    c.prototype.which$getter = function() { return DOM$EnsureDartNull(this.which); };
  }
  DOM$fixMembers(c, ['initUIEvent']);
  c.$implements$UIEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$Uint16Array(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, ['subarray']);
  c.$implements$Uint16Array$Dart = 1;
  c.$implements$ArrayBufferView$Dart = 1;
}
function DOM$fixClass$Uint32Array(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, ['subarray']);
  c.$implements$Uint32Array$Dart = 1;
  c.$implements$ArrayBufferView$Dart = 1;
}
function DOM$fixClass$Uint8Array(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, ['subarray']);
  c.$implements$Uint8Array$Dart = 1;
  c.$implements$ArrayBufferView$Dart = 1;
}
function DOM$fixClass$ValidityState(c) {
  if (c.prototype) {
    c.prototype.customError$getter = function() { return DOM$EnsureDartNull(this.customError); };
    c.prototype.patternMismatch$getter = function() { return DOM$EnsureDartNull(this.patternMismatch); };
    c.prototype.rangeOverflow$getter = function() { return DOM$EnsureDartNull(this.rangeOverflow); };
    c.prototype.rangeUnderflow$getter = function() { return DOM$EnsureDartNull(this.rangeUnderflow); };
    c.prototype.stepMismatch$getter = function() { return DOM$EnsureDartNull(this.stepMismatch); };
    c.prototype.tooLong$getter = function() { return DOM$EnsureDartNull(this.tooLong); };
    c.prototype.typeMismatch$getter = function() { return DOM$EnsureDartNull(this.typeMismatch); };
    c.prototype.valid$getter = function() { return DOM$EnsureDartNull(this.valid); };
    c.prototype.valueMissing$getter = function() { return DOM$EnsureDartNull(this.valueMissing); };
  }
  c.$implements$ValidityState$Dart = 1;
}
function DOM$fixClass$VoidCallback(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['handleEvent']);
  c.$implements$VoidCallback$Dart = 1;
}
function DOM$fixClass$WebGLActiveInfo(c) {
  if (c.prototype) {
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.size$getter = function() { return DOM$EnsureDartNull(this.size); };
    c.prototype.type$getter = function() { return DOM$EnsureDartNull(this.type); };
  }
  c.$implements$WebGLActiveInfo$Dart = 1;
}
function DOM$fixClass$WebGLBuffer(c) {
  if (c.prototype) {
  }
  c.$implements$WebGLBuffer$Dart = 1;
}
function DOM$fixClass$WebGLContextAttributes(c) {
  if (c.prototype) {
    c.prototype.alpha$getter = function() { return DOM$EnsureDartNull(this.alpha); };
    c.prototype.alpha$setter = function(value) { this.alpha = value; };
    c.prototype.antialias$getter = function() { return DOM$EnsureDartNull(this.antialias); };
    c.prototype.antialias$setter = function(value) { this.antialias = value; };
    c.prototype.depth$getter = function() { return DOM$EnsureDartNull(this.depth); };
    c.prototype.depth$setter = function(value) { this.depth = value; };
    c.prototype.premultipliedAlpha$getter = function() { return DOM$EnsureDartNull(this.premultipliedAlpha); };
    c.prototype.premultipliedAlpha$setter = function(value) { this.premultipliedAlpha = value; };
    c.prototype.preserveDrawingBuffer$getter = function() { return DOM$EnsureDartNull(this.preserveDrawingBuffer); };
    c.prototype.preserveDrawingBuffer$setter = function(value) { this.preserveDrawingBuffer = value; };
    c.prototype.stencil$getter = function() { return DOM$EnsureDartNull(this.stencil); };
    c.prototype.stencil$setter = function(value) { this.stencil = value; };
  }
  c.$implements$WebGLContextAttributes$Dart = 1;
}
function DOM$fixClass$WebGLContextEvent(c) {
  if (c.prototype) {
    c.prototype.statusMessage$getter = function() { return DOM$EnsureDartNull(this.statusMessage); };
  }
  c.$implements$WebGLContextEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$WebGLDebugRendererInfo(c) {
  if (c.prototype) {
  }
  c.$implements$WebGLDebugRendererInfo$Dart = 1;
}
function DOM$fixClass$WebGLDebugShaders(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['getTranslatedShaderSource']);
  c.$implements$WebGLDebugShaders$Dart = 1;
}
function DOM$fixClass$WebGLFramebuffer(c) {
  if (c.prototype) {
  }
  c.$implements$WebGLFramebuffer$Dart = 1;
}
function DOM$fixClass$WebGLProgram(c) {
  if (c.prototype) {
  }
  c.$implements$WebGLProgram$Dart = 1;
}
function DOM$fixClass$WebGLRenderbuffer(c) {
  if (c.prototype) {
  }
  c.$implements$WebGLRenderbuffer$Dart = 1;
}
function DOM$fixClass$WebGLRenderingContext(c) {
  if (c.prototype) {
    c.prototype.drawingBufferHeight$getter = function() { return DOM$EnsureDartNull(this.drawingBufferHeight); };
    c.prototype.drawingBufferWidth$getter = function() { return DOM$EnsureDartNull(this.drawingBufferWidth); };
  }
  DOM$fixMembers(c, [
    'activeTexture',
    'attachShader',
    'bindAttribLocation',
    'bindBuffer',
    'bindFramebuffer',
    'bindRenderbuffer',
    'bindTexture',
    'blendColor',
    'blendEquation',
    'blendEquationSeparate',
    'blendFunc',
    'blendFuncSeparate',
    'bufferData',
    'bufferSubData',
    'checkFramebufferStatus',
    'clear',
    'clearColor',
    'clearDepth',
    'clearStencil',
    'colorMask',
    'compileShader',
    'copyTexImage2D',
    'copyTexSubImage2D',
    'createBuffer',
    'createFramebuffer',
    'createProgram',
    'createRenderbuffer',
    'createShader',
    'createTexture',
    'cullFace',
    'deleteBuffer',
    'deleteFramebuffer',
    'deleteProgram',
    'deleteRenderbuffer',
    'deleteShader',
    'deleteTexture',
    'depthFunc',
    'depthMask',
    'depthRange',
    'detachShader',
    'disable',
    'disableVertexAttribArray',
    'drawArrays',
    'drawElements',
    'enable',
    'enableVertexAttribArray',
    'finish',
    'flush',
    'framebufferRenderbuffer',
    'framebufferTexture2D',
    'frontFace',
    'generateMipmap',
    'getActiveAttrib',
    'getActiveUniform',
    'getAttachedShaders',
    'getAttribLocation',
    'getBufferParameter',
    'getContextAttributes',
    'getError',
    'getExtension',
    'getFramebufferAttachmentParameter',
    'getParameter',
    'getProgramInfoLog',
    'getProgramParameter',
    'getRenderbufferParameter',
    'getShaderInfoLog',
    'getShaderParameter',
    'getShaderSource',
    'getSupportedExtensions',
    'getTexParameter',
    'getUniform',
    'getUniformLocation',
    'getVertexAttrib',
    'getVertexAttribOffset',
    'hint',
    'isBuffer',
    'isContextLost',
    'isEnabled',
    'isFramebuffer',
    'isProgram',
    'isRenderbuffer',
    'isShader',
    'isTexture',
    'lineWidth',
    'linkProgram',
    'pixelStorei',
    'polygonOffset',
    'readPixels',
    'releaseShaderCompiler',
    'renderbufferStorage',
    'sampleCoverage',
    'scissor',
    'shaderSource',
    'stencilFunc',
    'stencilFuncSeparate',
    'stencilMask',
    'stencilMaskSeparate',
    'stencilOp',
    'stencilOpSeparate',
    'texImage2D',
    'texParameterf',
    'texParameteri',
    'texSubImage2D',
    'uniform1f',
    'uniform1fv',
    'uniform1i',
    'uniform1iv',
    'uniform2f',
    'uniform2fv',
    'uniform2i',
    'uniform2iv',
    'uniform3f',
    'uniform3fv',
    'uniform3i',
    'uniform3iv',
    'uniform4f',
    'uniform4fv',
    'uniform4i',
    'uniform4iv',
    'uniformMatrix2fv',
    'uniformMatrix3fv',
    'uniformMatrix4fv',
    'useProgram',
    'validateProgram',
    'vertexAttrib1f',
    'vertexAttrib1fv',
    'vertexAttrib2f',
    'vertexAttrib2fv',
    'vertexAttrib3f',
    'vertexAttrib3fv',
    'vertexAttrib4f',
    'vertexAttrib4fv',
    'vertexAttribPointer',
    'viewport']);
  c.$implements$WebGLRenderingContext$Dart = 1;
  c.$implements$CanvasRenderingContext$Dart = 1;
}
function DOM$fixClass$WebGLShader(c) {
  if (c.prototype) {
  }
  c.$implements$WebGLShader$Dart = 1;
}
function DOM$fixClass$WebGLTexture(c) {
  if (c.prototype) {
  }
  c.$implements$WebGLTexture$Dart = 1;
}
function DOM$fixClass$WebGLUniformLocation(c) {
  if (c.prototype) {
  }
  c.$implements$WebGLUniformLocation$Dart = 1;
}
function DOM$fixClass$WebGLVertexArrayObjectOES(c) {
  if (c.prototype) {
  }
  c.$implements$WebGLVertexArrayObjectOES$Dart = 1;
}
function DOM$fixClass$WebKitAnimation(c) {
  if (c.prototype) {
    c.prototype.delay$getter = function() { return DOM$EnsureDartNull(this.delay); };
    c.prototype.direction$getter = function() { return DOM$EnsureDartNull(this.direction); };
    c.prototype.duration$getter = function() { return DOM$EnsureDartNull(this.duration); };
    c.prototype.elapsedTime$getter = function() { return DOM$EnsureDartNull(this.elapsedTime); };
    c.prototype.elapsedTime$setter = function(value) { this.elapsedTime = value; };
    c.prototype.ended$getter = function() { return DOM$EnsureDartNull(this.ended); };
    c.prototype.fillMode$getter = function() { return DOM$EnsureDartNull(this.fillMode); };
    c.prototype.iterationCount$getter = function() { return DOM$EnsureDartNull(this.iterationCount); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.paused$getter = function() { return DOM$EnsureDartNull(this.paused); };
  }
  DOM$fixMembers(c, [
    'pause',
    'play']);
  c.$implements$WebKitAnimation$Dart = 1;
}
function DOM$fixClass$WebKitAnimationEvent(c) {
  if (c.prototype) {
    c.prototype.animationName$getter = function() { return DOM$EnsureDartNull(this.animationName); };
    c.prototype.elapsedTime$getter = function() { return DOM$EnsureDartNull(this.elapsedTime); };
  }
  DOM$fixMembers(c, ['initWebKitAnimationEvent']);
  c.$implements$WebKitAnimationEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$WebKitAnimationList(c) {
  if (c.prototype) {
    c.prototype.length$getter = function() { return DOM$EnsureDartNull(this.length); };
  }
  DOM$fixMembers(c, ['item']);
  c.$implements$WebKitAnimationList$Dart = 1;
}
function DOM$fixClass$WebKitBlobBuilder(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'append',
    'getBlob']);
  c.$implements$WebKitBlobBuilder$Dart = 1;
}
function DOM$fixClass$WebKitCSSFilterValue(c) {
  if (c.prototype) {
    c.prototype.operationType$getter = function() { return DOM$EnsureDartNull(this.operationType); };
  }
  c.$implements$WebKitCSSFilterValue$Dart = 1;
  c.$implements$CSSValueList$Dart = 1;
  c.$implements$CSSValue$Dart = 1;
}
function DOM$fixClass$WebKitCSSKeyframeRule(c) {
  if (c.prototype) {
    c.prototype.keyText$getter = function() { return DOM$EnsureDartNull(this.keyText); };
    c.prototype.keyText$setter = function(value) { this.keyText = value; };
    c.prototype.style$getter = function() { return DOM$EnsureDartNull(this.style); };
  }
  c.$implements$WebKitCSSKeyframeRule$Dart = 1;
  c.$implements$CSSRule$Dart = 1;
}
function DOM$fixClass$WebKitCSSKeyframesRule(c) {
  if (c.prototype) {
    c.prototype.cssRules$getter = function() { return DOM$EnsureDartNull(this.cssRules); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
    c.prototype.name$setter = function(value) { this.name = value; };
  }
  DOM$fixMembers(c, [
    'deleteRule',
    'findRule',
    'insertRule']);
  c.$implements$WebKitCSSKeyframesRule$Dart = 1;
  c.$implements$CSSRule$Dart = 1;
}
function DOM$fixClass$WebKitCSSMatrix(c) {
  if (c.prototype) {
    c.prototype.a$getter = function() { return DOM$EnsureDartNull(this.a); };
    c.prototype.a$setter = function(value) { this.a = value; };
    c.prototype.b$getter = function() { return DOM$EnsureDartNull(this.b); };
    c.prototype.b$setter = function(value) { this.b = value; };
    c.prototype.c$getter = function() { return DOM$EnsureDartNull(this.c); };
    c.prototype.c$setter = function(value) { this.c = value; };
    c.prototype.d$getter = function() { return DOM$EnsureDartNull(this.d); };
    c.prototype.d$setter = function(value) { this.d = value; };
    c.prototype.e$getter = function() { return DOM$EnsureDartNull(this.e); };
    c.prototype.e$setter = function(value) { this.e = value; };
    c.prototype.f$getter = function() { return DOM$EnsureDartNull(this.f); };
    c.prototype.f$setter = function(value) { this.f = value; };
    c.prototype.m11$getter = function() { return DOM$EnsureDartNull(this.m11); };
    c.prototype.m11$setter = function(value) { this.m11 = value; };
    c.prototype.m12$getter = function() { return DOM$EnsureDartNull(this.m12); };
    c.prototype.m12$setter = function(value) { this.m12 = value; };
    c.prototype.m13$getter = function() { return DOM$EnsureDartNull(this.m13); };
    c.prototype.m13$setter = function(value) { this.m13 = value; };
    c.prototype.m14$getter = function() { return DOM$EnsureDartNull(this.m14); };
    c.prototype.m14$setter = function(value) { this.m14 = value; };
    c.prototype.m21$getter = function() { return DOM$EnsureDartNull(this.m21); };
    c.prototype.m21$setter = function(value) { this.m21 = value; };
    c.prototype.m22$getter = function() { return DOM$EnsureDartNull(this.m22); };
    c.prototype.m22$setter = function(value) { this.m22 = value; };
    c.prototype.m23$getter = function() { return DOM$EnsureDartNull(this.m23); };
    c.prototype.m23$setter = function(value) { this.m23 = value; };
    c.prototype.m24$getter = function() { return DOM$EnsureDartNull(this.m24); };
    c.prototype.m24$setter = function(value) { this.m24 = value; };
    c.prototype.m31$getter = function() { return DOM$EnsureDartNull(this.m31); };
    c.prototype.m31$setter = function(value) { this.m31 = value; };
    c.prototype.m32$getter = function() { return DOM$EnsureDartNull(this.m32); };
    c.prototype.m32$setter = function(value) { this.m32 = value; };
    c.prototype.m33$getter = function() { return DOM$EnsureDartNull(this.m33); };
    c.prototype.m33$setter = function(value) { this.m33 = value; };
    c.prototype.m34$getter = function() { return DOM$EnsureDartNull(this.m34); };
    c.prototype.m34$setter = function(value) { this.m34 = value; };
    c.prototype.m41$getter = function() { return DOM$EnsureDartNull(this.m41); };
    c.prototype.m41$setter = function(value) { this.m41 = value; };
    c.prototype.m42$getter = function() { return DOM$EnsureDartNull(this.m42); };
    c.prototype.m42$setter = function(value) { this.m42 = value; };
    c.prototype.m43$getter = function() { return DOM$EnsureDartNull(this.m43); };
    c.prototype.m43$setter = function(value) { this.m43 = value; };
    c.prototype.m44$getter = function() { return DOM$EnsureDartNull(this.m44); };
    c.prototype.m44$setter = function(value) { this.m44 = value; };
  }
  DOM$fixMembers(c, [
    'inverse',
    'multiply',
    'rotate',
    'rotateAxisAngle',
    'scale',
    'setMatrixValue',
    'skewX',
    'skewY',
    'toString',
    'translate']);
  c.$implements$WebKitCSSMatrix$Dart = 1;
}
function DOM$fixClass$WebKitCSSTransformValue(c) {
  if (c.prototype) {
    c.prototype.operationType$getter = function() { return DOM$EnsureDartNull(this.operationType); };
  }
  c.$implements$WebKitCSSTransformValue$Dart = 1;
  c.$implements$CSSValueList$Dart = 1;
  c.$implements$CSSValue$Dart = 1;
}
function DOM$fixClass$WebKitFlags(c) {
  if (c.prototype) {
    c.prototype.create$getter = function() { return DOM$EnsureDartNull(this.create); };
    c.prototype.create$setter = function(value) { this.create = value; };
    c.prototype.exclusive$getter = function() { return DOM$EnsureDartNull(this.exclusive); };
    c.prototype.exclusive$setter = function(value) { this.exclusive = value; };
  }
  c.$implements$WebKitFlags$Dart = 1;
}
function DOM$fixClass$WebKitLoseContext(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'loseContext',
    'restoreContext']);
  c.$implements$WebKitLoseContext$Dart = 1;
}
function DOM$fixClass$WebKitMutationObserver(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['disconnect']);
  c.$implements$WebKitMutationObserver$Dart = 1;
}
function DOM$fixClass$WebKitPoint(c) {
  if (c.prototype) {
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.x$setter = function(value) { this.x = value; };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
    c.prototype.y$setter = function(value) { this.y = value; };
  }
  c.$implements$WebKitPoint$Dart = 1;
}
function DOM$fixClass$WebKitTransitionEvent(c) {
  if (c.prototype) {
    c.prototype.elapsedTime$getter = function() { return DOM$EnsureDartNull(this.elapsedTime); };
    c.prototype.propertyName$getter = function() { return DOM$EnsureDartNull(this.propertyName); };
  }
  DOM$fixMembers(c, ['initWebKitTransitionEvent']);
  c.$implements$WebKitTransitionEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$WebSocket(c) {
  if (c.prototype) {
    c.prototype.URL$getter = function() { return DOM$EnsureDartNull(this.URL); };
    c.prototype.binaryType$getter = function() { return DOM$EnsureDartNull(this.binaryType); };
    c.prototype.binaryType$setter = function(value) { this.binaryType = value; };
    c.prototype.bufferedAmount$getter = function() { return DOM$EnsureDartNull(this.bufferedAmount); };
    c.prototype.extensions$getter = function() { return DOM$EnsureDartNull(this.extensions); };
    c.prototype.protocol$getter = function() { return DOM$EnsureDartNull(this.protocol); };
    c.prototype.readyState$getter = function() { return DOM$EnsureDartNull(this.readyState); };
  }
  DOM$fixMembers(c, [
    'addEventListener',
    'close',
    'dispatchEvent',
    'removeEventListener',
    'send']);
  c.$implements$WebSocket$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$WheelEvent(c) {
  if (c.prototype) {
    c.prototype.altKey$getter = function() { return DOM$EnsureDartNull(this.altKey); };
    c.prototype.clientX$getter = function() { return DOM$EnsureDartNull(this.clientX); };
    c.prototype.clientY$getter = function() { return DOM$EnsureDartNull(this.clientY); };
    c.prototype.ctrlKey$getter = function() { return DOM$EnsureDartNull(this.ctrlKey); };
    c.prototype.metaKey$getter = function() { return DOM$EnsureDartNull(this.metaKey); };
    c.prototype.offsetX$getter = function() { return DOM$EnsureDartNull(this.offsetX); };
    c.prototype.offsetY$getter = function() { return DOM$EnsureDartNull(this.offsetY); };
    c.prototype.screenX$getter = function() { return DOM$EnsureDartNull(this.screenX); };
    c.prototype.screenY$getter = function() { return DOM$EnsureDartNull(this.screenY); };
    c.prototype.shiftKey$getter = function() { return DOM$EnsureDartNull(this.shiftKey); };
    c.prototype.webkitDirectionInvertedFromDevice$getter = function() { return DOM$EnsureDartNull(this.webkitDirectionInvertedFromDevice); };
    c.prototype.wheelDelta$getter = function() { return DOM$EnsureDartNull(this.wheelDelta); };
    c.prototype.wheelDeltaX$getter = function() { return DOM$EnsureDartNull(this.wheelDeltaX); };
    c.prototype.wheelDeltaY$getter = function() { return DOM$EnsureDartNull(this.wheelDeltaY); };
    c.prototype.x$getter = function() { return DOM$EnsureDartNull(this.x); };
    c.prototype.y$getter = function() { return DOM$EnsureDartNull(this.y); };
  }
  DOM$fixMembers(c, ['initWebKitWheelEvent']);
  c.$implements$WheelEvent$Dart = 1;
  c.$implements$UIEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$Worker(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'postMessage',
    'terminate',
    'webkitPostMessage']);
  c.$implements$Worker$Dart = 1;
  c.$implements$AbstractWorker$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$WorkerContext(c) {
  if (c.prototype) {
    c.prototype.location$getter = function() { return DOM$EnsureDartNull(this.location); };
    c.prototype.location$setter = function(value) { this.location = value; };
    c.prototype.navigator$getter = function() { return DOM$EnsureDartNull(this.navigator); };
    c.prototype.navigator$setter = function(value) { this.navigator = value; };
    c.prototype.self$getter = function() { return DOM$EnsureDartNull(this.self); };
    c.prototype.self$setter = function(value) { this.self = value; };
    c.prototype.webkitNotifications$getter = function() { return DOM$fixValue$NotificationCenter(this.webkitNotifications); };
    c.prototype.webkitURL$getter = function() { return DOM$EnsureDartNull(this.webkitURL); };
  }
  DOM$fixMembers(c, [
    'addEventListener',
    'clearInterval',
    'clearTimeout',
    'close',
    'dispatchEvent',
    'importScripts',
    'removeEventListener',
    'setInterval',
    'setTimeout']);
  c.$implements$WorkerContext$Dart = 1;
}
function DOM$fixClass$WorkerLocation(c) {
  if (c.prototype) {
    c.prototype.hash$getter = function() { return DOM$EnsureDartNull(this.hash); };
    c.prototype.host$getter = function() { return DOM$EnsureDartNull(this.host); };
    c.prototype.hostname$getter = function() { return DOM$EnsureDartNull(this.hostname); };
    c.prototype.href$getter = function() { return DOM$EnsureDartNull(this.href); };
    c.prototype.pathname$getter = function() { return DOM$EnsureDartNull(this.pathname); };
    c.prototype.port$getter = function() { return DOM$EnsureDartNull(this.port); };
    c.prototype.protocol$getter = function() { return DOM$EnsureDartNull(this.protocol); };
    c.prototype.search$getter = function() { return DOM$EnsureDartNull(this.search); };
  }
  DOM$fixMembers(c, ['toString']);
  c.$implements$WorkerLocation$Dart = 1;
}
function DOM$fixClass$WorkerNavigator(c) {
  if (c.prototype) {
    c.prototype.appName$getter = function() { return DOM$EnsureDartNull(this.appName); };
    c.prototype.appVersion$getter = function() { return DOM$EnsureDartNull(this.appVersion); };
    c.prototype.onLine$getter = function() { return DOM$EnsureDartNull(this.onLine); };
    c.prototype.platform$getter = function() { return DOM$EnsureDartNull(this.platform); };
    c.prototype.userAgent$getter = function() { return DOM$EnsureDartNull(this.userAgent); };
  }
  c.$implements$WorkerNavigator$Dart = 1;
}
function DOM$fixClass$XMLHttpRequest(c) {
  if (c.prototype) {
    c.prototype.asBlob$getter = function() { return DOM$EnsureDartNull(this.asBlob); };
    c.prototype.asBlob$setter = function(value) { this.asBlob = value; };
    c.prototype.readyState$getter = function() { return DOM$EnsureDartNull(this.readyState); };
    c.prototype.responseBlob$getter = function() { return DOM$EnsureDartNull(this.responseBlob); };
    c.prototype.responseText$getter = function() { return DOM$EnsureDartNull(this.responseText); };
    c.prototype.responseType$getter = function() { return DOM$EnsureDartNull(this.responseType); };
    c.prototype.responseType$setter = function(value) { this.responseType = value; };
    c.prototype.responseXML$getter = function() { return DOM$EnsureDartNull(this.responseXML); };
    c.prototype.status$getter = function() { return DOM$EnsureDartNull(this.status); };
    c.prototype.statusText$getter = function() { return DOM$EnsureDartNull(this.statusText); };
    c.prototype.upload$getter = function() { return DOM$EnsureDartNull(this.upload); };
    c.prototype.withCredentials$getter = function() { return DOM$EnsureDartNull(this.withCredentials); };
    c.prototype.withCredentials$setter = function(value) { this.withCredentials = value; };
  }
  DOM$fixMembers(c, [
    'abort',
    'addEventListener',
    'dispatchEvent',
    'getAllResponseHeaders',
    'getResponseHeader',
    'open',
    'overrideMimeType',
    'removeEventListener',
    'send',
    'setRequestHeader']);
  c.$implements$XMLHttpRequest$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$XMLHttpRequestException(c) {
  if (c.prototype) {
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
    c.prototype.message$getter = function() { return DOM$EnsureDartNull(this.message); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
  }
  DOM$fixMembers(c, ['toString']);
  c.$implements$XMLHttpRequestException$Dart = 1;
}
function DOM$fixClass$XMLHttpRequestProgressEvent(c) {
  if (c.prototype) {
    c.prototype.position$getter = function() { return DOM$EnsureDartNull(this.position); };
    c.prototype.totalSize$getter = function() { return DOM$EnsureDartNull(this.totalSize); };
  }
  c.$implements$XMLHttpRequestProgressEvent$Dart = 1;
  c.$implements$ProgressEvent$Dart = 1;
  c.$implements$Event$Dart = 1;
}
function DOM$fixClass$XMLHttpRequestUpload(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'addEventListener',
    'dispatchEvent',
    'removeEventListener']);
  c.$implements$XMLHttpRequestUpload$Dart = 1;
  c.$implements$EventTarget$Dart = 1;
}
function DOM$fixClass$XMLSerializer(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['serializeToString']);
  c.$implements$XMLSerializer$Dart = 1;
}
function DOM$fixClass$XPathEvaluator(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'createExpression',
    'createNSResolver',
    'evaluate']);
  c.$implements$XPathEvaluator$Dart = 1;
}
function DOM$fixClass$XPathException(c) {
  if (c.prototype) {
    c.prototype.code$getter = function() { return DOM$EnsureDartNull(this.code); };
    c.prototype.message$getter = function() { return DOM$EnsureDartNull(this.message); };
    c.prototype.name$getter = function() { return DOM$EnsureDartNull(this.name); };
  }
  DOM$fixMembers(c, ['toString']);
  c.$implements$XPathException$Dart = 1;
}
function DOM$fixClass$XPathExpression(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['evaluate']);
  c.$implements$XPathExpression$Dart = 1;
}
function DOM$fixClass$XPathNSResolver(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, ['lookupNamespaceURI']);
  c.$implements$XPathNSResolver$Dart = 1;
}
function DOM$fixClass$XPathResult(c) {
  if (c.prototype) {
    c.prototype.booleanValue$getter = function() { return DOM$EnsureDartNull(this.booleanValue); };
    c.prototype.invalidIteratorState$getter = function() { return DOM$EnsureDartNull(this.invalidIteratorState); };
    c.prototype.numberValue$getter = function() { return DOM$EnsureDartNull(this.numberValue); };
    c.prototype.resultType$getter = function() { return DOM$EnsureDartNull(this.resultType); };
    c.prototype.singleNodeValue$getter = function() { return DOM$EnsureDartNull(this.singleNodeValue); };
    c.prototype.snapshotLength$getter = function() { return DOM$EnsureDartNull(this.snapshotLength); };
    c.prototype.stringValue$getter = function() { return DOM$EnsureDartNull(this.stringValue); };
  }
  DOM$fixMembers(c, [
    'iterateNext',
    'snapshotItem']);
  c.$implements$XPathResult$Dart = 1;
}
function DOM$fixClass$XSLTProcessor(c) {
  if (c.prototype) {
  }
  DOM$fixMembers(c, [
    'clearParameters',
    'getParameter',
    'importStylesheet',
    'removeParameter',
    'reset',
    'setParameter',
    'transformToDocument',
    'transformToFragment']);
  c.$implements$XSLTProcessor$Dart = 1;
}

function DOM$FixBindings(w) {

  // Have we been called to augment the prototypes on this window before?
  if (w.HTMLIFrameElement.prototype &&
     w.HTMLIFrameElement.prototype.contentWindow$getter) {
    return;
  }

  // TODO(vsm): Clean this up.  This is a workaround for Firefox 3.6 where
  // the Location prototype cannot be modified.
  // TODO(jacobr): unify the hacks for Navigator and Location.
  var tmpLocation = w.Location;
  if (w.location) {
    if (tmpLocation) {
      try {
        delete tmpLocation.prototype.get$dart$test;
      } catch (e) {
        w.Location = { prototype: w.location };
      }
    } else {
      w.Location = { prototype: w.location.__proto__ };
    }
  }
  // TODO(vsm): Clean this up.  This is a workaround for Firefox 3.6 where
  // the Navigator prototype cannot be modified.
  if (navigator.userAgent.indexOf("Firefox") != -1) {
    w.Navigator = { prototype: w.navigator };
  }
var _;
  if ((_ = w.AbstractWorker)) {
    w.AbstractWorker$Dart = _;
    DOM$fixClass$AbstractWorker(_);
  }
  if ((_ = w.ArrayBuffer)) {
    w.ArrayBuffer$Dart = _;
    DOM$fixClass$ArrayBuffer(_);
  }
  if ((_ = w.ArrayBufferView)) {
    w.ArrayBufferView$Dart = _;
    DOM$fixClass$ArrayBufferView(_);
  }
  if ((_ = w.Attr)) {
    w.Attr$Dart = _;
    DOM$fixClass$Attr(_);
  }
  if (!w.BarInfo && (_ = w.toolbar) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.BarInfo = _;
  }
  if ((_ = w.BarInfo)) {
    w.BarInfo$Dart = _;
    DOM$fixClass$BarInfo(_);
  }
  if ((_ = w.BeforeLoadEvent)) {
    w.BeforeLoadEvent$Dart = _;
    DOM$fixClass$BeforeLoadEvent(_);
  }
  if ((_ = w.Blob)) {
    w.Blob$Dart = _;
    DOM$fixClass$Blob(_);
  }
  if ((_ = w.CDATASection)) {
    w.CDATASection$Dart = _;
    DOM$fixClass$CDATASection(_);
  }
  if ((_ = w.CSSCharsetRule)) {
    w.CSSCharsetRule$Dart = _;
    DOM$fixClass$CSSCharsetRule(_);
  }
  if ((_ = w.CSSFontFaceRule)) {
    w.CSSFontFaceRule$Dart = _;
    DOM$fixClass$CSSFontFaceRule(_);
  }
  if ((_ = w.CSSImportRule)) {
    w.CSSImportRule$Dart = _;
    DOM$fixClass$CSSImportRule(_);
  }
  if ((_ = w.CSSMediaRule)) {
    w.CSSMediaRule$Dart = _;
    DOM$fixClass$CSSMediaRule(_);
  }
  if ((_ = w.CSSPageRule)) {
    w.CSSPageRule$Dart = _;
    DOM$fixClass$CSSPageRule(_);
  }
  if ((_ = w.CSSPrimitiveValue)) {
    w.CSSPrimitiveValue$Dart = _;
    DOM$fixClass$CSSPrimitiveValue(_);
  }
  if ((_ = w.CSSRule)) {
    w.CSSRule$Dart = _;
    DOM$fixClass$CSSRule(_);
  }
  if ((_ = w.CSSRuleList)) {
    w.CSSRuleList$Dart = _;
    DOM$fixClass$CSSRuleList(_);
  }
  if ((_ = w.CSSStyleDeclaration)) {
    w.CSSStyleDeclaration$Dart = _;
    DOM$fixClass$CSSStyleDeclaration(_);
  }
  if ((_ = w.CSSStyleRule)) {
    w.CSSStyleRule$Dart = _;
    DOM$fixClass$CSSStyleRule(_);
  }
  if ((_ = w.CSSStyleSheet)) {
    w.CSSStyleSheet$Dart = _;
    DOM$fixClass$CSSStyleSheet(_);
  }
  if ((_ = w.CSSUnknownRule)) {
    w.CSSUnknownRule$Dart = _;
    DOM$fixClass$CSSUnknownRule(_);
  }
  if ((_ = w.CSSValue)) {
    w.CSSValue$Dart = _;
    DOM$fixClass$CSSValue(_);
  }
  if ((_ = w.CSSValueList)) {
    w.CSSValueList$Dart = _;
    DOM$fixClass$CSSValueList(_);
  }
  if ((_ = w.CanvasGradient)) {
    w.CanvasGradient$Dart = _;
    DOM$fixClass$CanvasGradient(_);
  }
  if ((_ = w.CanvasPattern)) {
    w.CanvasPattern$Dart = _;
    DOM$fixClass$CanvasPattern(_);
  }
  if ((_ = w.CanvasPixelArray)) {
    w.CanvasPixelArray$Dart = _;
    DOM$fixClassOnDemand$CanvasPixelArray(_);
  }
  if ((_ = w.CanvasRenderingContext)) {
    w.CanvasRenderingContext$Dart = _;
    DOM$fixClass$CanvasRenderingContext(_);
  }
  if ((_ = w.CanvasRenderingContext2D)) {
    w.CanvasRenderingContext2D$Dart = _;
    DOM$fixClass$CanvasRenderingContext2D(_);
  }
  if ((_ = w.CharacterData)) {
    w.CharacterData$Dart = _;
    DOM$fixClass$CharacterData(_);
  }
  if ((_ = w.ClientRect)) {
    w.ClientRect$Dart = _;
    DOM$fixClass$ClientRect(_);
  }
  if ((_ = w.ClientRectList)) {
    w.ClientRectList$Dart = _;
    DOM$fixClass$ClientRectList(_);
  }
  if ((_ = w.Clipboard)) {
    w.Clipboard$Dart = _;
    DOM$fixClass$Clipboard(_);
  }
  if ((_ = w.CloseEvent)) {
    w.CloseEvent$Dart = _;
    DOM$fixClass$CloseEvent(_);
  }
  if ((_ = w.Comment)) {
    w.Comment$Dart = _;
    DOM$fixClass$Comment(_);
  }
  if ((_ = w.CompositionEvent)) {
    w.CompositionEvent$Dart = _;
    DOM$fixClass$CompositionEvent(_);
  }
  if (!w.Console && (_ = w.console) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.Console = _;
  }
  if ((_ = w.Console)) {
    w.Console$Dart = _;
    DOM$fixClass$Console(_);
  }
  if ((_ = w.Coordinates)) {
    w.Coordinates$Dart = _;
    DOM$fixClass$Coordinates(_);
  }
  if ((_ = w.Counter)) {
    w.Counter$Dart = _;
    DOM$fixClass$Counter(_);
  }
  if (!w.Crypto && (_ = w.crypto) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.Crypto = _;
  }
  if ((_ = w.Crypto)) {
    w.Crypto$Dart = _;
    DOM$fixClass$Crypto(_);
  }
  if ((_ = w.CustomEvent)) {
    w.CustomEvent$Dart = _;
    DOM$fixClass$CustomEvent(_);
  }
  if (!w.DOMApplicationCache && (_ = w.applicationCache) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.DOMApplicationCache = _;
  }
  if ((_ = w.DOMApplicationCache)) {
    w.DOMApplicationCache$Dart = _;
    DOM$fixClass$DOMApplicationCache(_);
  }
  if ((_ = w.DOMException)) {
    w.DOMException$Dart = _;
    DOM$fixClass$DOMException(_);
  }
  if ((_ = w.DOMFileSystem)) {
    w.DOMFileSystem$Dart = _;
    DOM$fixClass$DOMFileSystem(_);
  }
  if ((_ = w.DOMFileSystemSync)) {
    w.DOMFileSystemSync$Dart = _;
    DOM$fixClass$DOMFileSystemSync(_);
  }
  if ((_ = w.DOMFormData)) {
    w.DOMFormData$Dart = _;
    DOM$fixClass$DOMFormData(_);
  }
  if ((_ = w.DOMImplementation)) {
    w.DOMImplementation$Dart = _;
    DOM$fixClass$DOMImplementation(_);
  }
  if ((_ = w.DOMMimeType)) {
    w.DOMMimeType$Dart = _;
    DOM$fixClass$DOMMimeType(_);
  }
  if ((_ = w.DOMMimeTypeArray)) {
    w.DOMMimeTypeArray$Dart = _;
    DOM$fixClass$DOMMimeTypeArray(_);
  }
  if ((_ = w.DOMParser)) {
    w.DOMParser$Dart = _;
    DOM$fixClass$DOMParser(_);
  }
  if ((_ = w.DOMPlugin)) {
    w.DOMPlugin$Dart = _;
    DOM$fixClass$DOMPlugin(_);
  }
  if ((_ = w.DOMPluginArray)) {
    w.DOMPluginArray$Dart = _;
    DOM$fixClass$DOMPluginArray(_);
  }
  if ((_ = w.DOMSelection)) {
    w.DOMSelection$Dart = _;
    DOM$fixClass$DOMSelection(_);
  }
  if ((_ = w.DOMSettableTokenList)) {
    w.DOMSettableTokenList$Dart = _;
    DOM$fixClass$DOMSettableTokenList(_);
  }
  if ((_ = w.DOMTokenList)) {
    w.DOMTokenList$Dart = _;
    DOM$fixClass$DOMTokenList(_);
  }
  if (!w.DOMURL && (_ = w.webkitURL) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.DOMURL = _;
  }
  if ((_ = w.DOMURL)) {
    w.DOMURL$Dart = _;
    DOM$fixClass$DOMURL(_);
  }
  if (!w.DOMWindow && (_ = w.window) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.DOMWindow = _;
  }
  if ((_ = w.DOMWindow)) {
    w.DOMWindow$Dart = _;
    DOM$fixClass$DOMWindow(_);
  }
  if ((_ = w.DataTransferItem)) {
    w.DataTransferItem$Dart = _;
    DOM$fixClass$DataTransferItem(_);
  }
  if ((_ = w.DataTransferItemList)) {
    w.DataTransferItemList$Dart = _;
    DOM$fixClass$DataTransferItemList(_);
  }
  if ((_ = w.DataView)) {
    w.DataView$Dart = _;
    DOM$fixClass$DataView(_);
  }
  if ((_ = w.Database)) {
    w.Database$Dart = _;
    DOM$fixClass$Database(_);
  }
  if ((_ = w.DatabaseCallback)) {
    w.DatabaseCallback$Dart = _;
    DOM$fixClass$DatabaseCallback(_);
  }
  if ((_ = w.DatabaseSync)) {
    w.DatabaseSync$Dart = _;
    DOM$fixClass$DatabaseSync(_);
  }
  if ((_ = w.DedicatedWorkerContext)) {
    w.DedicatedWorkerContext$Dart = _;
    DOM$fixClass$DedicatedWorkerContext(_);
  }
  if ((_ = w.DeviceMotionEvent)) {
    w.DeviceMotionEvent$Dart = _;
    DOM$fixClass$DeviceMotionEvent(_);
  }
  if ((_ = w.DeviceOrientationEvent)) {
    w.DeviceOrientationEvent$Dart = _;
    DOM$fixClass$DeviceOrientationEvent(_);
  }
  if ((_ = w.DirectoryEntry)) {
    w.DirectoryEntry$Dart = _;
    DOM$fixClass$DirectoryEntry(_);
  }
  if ((_ = w.DirectoryEntrySync)) {
    w.DirectoryEntrySync$Dart = _;
    DOM$fixClass$DirectoryEntrySync(_);
  }
  if ((_ = w.DirectoryReader)) {
    w.DirectoryReader$Dart = _;
    DOM$fixClass$DirectoryReader(_);
  }
  if ((_ = w.DirectoryReaderSync)) {
    w.DirectoryReaderSync$Dart = _;
    DOM$fixClass$DirectoryReaderSync(_);
  }
  if (!w.Document && (_ = w.document) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.Document = _;
  }
  if ((_ = w.Document)) {
    w.Document$Dart = _;
    DOM$fixClass$Document(_);
  }
  if ((_ = w.DocumentFragment)) {
    w.DocumentFragment$Dart = _;
    DOM$fixClass$DocumentFragment(_);
  }
  if ((_ = w.DocumentType)) {
    w.DocumentType$Dart = _;
    DOM$fixClass$DocumentType(_);
  }
  if (!w.Element && (_ = w.frameElement) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.Element = _;
  }
  if ((_ = w.Element)) {
    w.Element$Dart = _;
    DOM$fixClass$Element(_);
  }
  if ((_ = w.ElementTimeControl)) {
    w.ElementTimeControl$Dart = _;
    DOM$fixClass$ElementTimeControl(_);
  }
  if ((_ = w.ElementTraversal)) {
    w.ElementTraversal$Dart = _;
    DOM$fixClass$ElementTraversal(_);
  }
  if ((_ = w.Entity)) {
    w.Entity$Dart = _;
    DOM$fixClass$Entity(_);
  }
  if ((_ = w.EntityReference)) {
    w.EntityReference$Dart = _;
    DOM$fixClass$EntityReference(_);
  }
  if ((_ = w.EntriesCallback)) {
    w.EntriesCallback$Dart = _;
    DOM$fixClass$EntriesCallback(_);
  }
  if ((_ = w.Entry)) {
    w.Entry$Dart = _;
    DOM$fixClass$Entry(_);
  }
  if ((_ = w.EntryArray)) {
    w.EntryArray$Dart = _;
    DOM$fixClass$EntryArray(_);
  }
  if ((_ = w.EntryArraySync)) {
    w.EntryArraySync$Dart = _;
    DOM$fixClass$EntryArraySync(_);
  }
  if ((_ = w.EntryCallback)) {
    w.EntryCallback$Dart = _;
    DOM$fixClass$EntryCallback(_);
  }
  if ((_ = w.EntrySync)) {
    w.EntrySync$Dart = _;
    DOM$fixClass$EntrySync(_);
  }
  if ((_ = w.ErrorCallback)) {
    w.ErrorCallback$Dart = _;
    DOM$fixClass$ErrorCallback(_);
  }
  if ((_ = w.ErrorEvent)) {
    w.ErrorEvent$Dart = _;
    DOM$fixClass$ErrorEvent(_);
  }
  if (!w.Event && (_ = w.event) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.Event = _;
  }
  if ((_ = w.Event)) {
    w.Event$Dart = _;
    DOM$fixClass$Event(_);
  }
  if ((_ = w.EventException)) {
    w.EventException$Dart = _;
    DOM$fixClass$EventException(_);
  }
  if ((_ = w.EventSource)) {
    w.EventSource$Dart = _;
    DOM$fixClass$EventSource(_);
  }
  if ((_ = w.EventTarget)) {
    w.EventTarget$Dart = _;
    DOM$fixClass$EventTarget(_);
  }
  if ((_ = w.File)) {
    w.File$Dart = _;
    DOM$fixClass$File(_);
  }
  if ((_ = w.FileCallback)) {
    w.FileCallback$Dart = _;
    DOM$fixClass$FileCallback(_);
  }
  if ((_ = w.FileEntry)) {
    w.FileEntry$Dart = _;
    DOM$fixClass$FileEntry(_);
  }
  if ((_ = w.FileEntrySync)) {
    w.FileEntrySync$Dart = _;
    DOM$fixClass$FileEntrySync(_);
  }
  if ((_ = w.FileError)) {
    w.FileError$Dart = _;
    DOM$fixClass$FileError(_);
  }
  if ((_ = w.FileException)) {
    w.FileException$Dart = _;
    DOM$fixClass$FileException(_);
  }
  if ((_ = w.FileList)) {
    w.FileList$Dart = _;
    DOM$fixClass$FileList(_);
  }
  if ((_ = w.FileReader)) {
    w.FileReader$Dart = _;
    DOM$fixClass$FileReader(_);
  }
  if ((_ = w.FileReaderSync)) {
    w.FileReaderSync$Dart = _;
    DOM$fixClass$FileReaderSync(_);
  }
  if ((_ = w.FileSystemCallback)) {
    w.FileSystemCallback$Dart = _;
    DOM$fixClass$FileSystemCallback(_);
  }
  if ((_ = w.FileWriter)) {
    w.FileWriter$Dart = _;
    DOM$fixClass$FileWriter(_);
  }
  if ((_ = w.FileWriterCallback)) {
    w.FileWriterCallback$Dart = _;
    DOM$fixClass$FileWriterCallback(_);
  }
  if ((_ = w.FileWriterSync)) {
    w.FileWriterSync$Dart = _;
    DOM$fixClass$FileWriterSync(_);
  }
  if ((_ = w.Float32Array)) {
    w.Float32Array$Dart = _;
    DOM$fixClass$Float32Array(_);
  }
  if ((_ = w.Float64Array)) {
    w.Float64Array$Dart = _;
    DOM$fixClass$Float64Array(_);
  }
  if ((_ = w.Geolocation)) {
    w.Geolocation$Dart = _;
    DOM$fixClass$Geolocation(_);
  }
  if ((_ = w.Geoposition)) {
    w.Geoposition$Dart = _;
    DOM$fixClass$Geoposition(_);
  }
  if ((_ = w.HTMLAllCollection)) {
    w.HTMLAllCollection$Dart = _;
    DOM$fixClass$HTMLAllCollection(_);
  }
  if ((_ = w.HTMLAnchorElement)) {
    w.HTMLAnchorElement$Dart = _;
    DOM$fixClass$HTMLAnchorElement(_);
  }
  if ((_ = w.HTMLAppletElement)) {
    w.HTMLAppletElement$Dart = _;
    DOM$fixClass$HTMLAppletElement(_);
  }
  if ((_ = w.HTMLAreaElement)) {
    w.HTMLAreaElement$Dart = _;
    DOM$fixClass$HTMLAreaElement(_);
  }
  if ((_ = w.HTMLAudioElement)) {
    w.HTMLAudioElement$Dart = _;
    DOM$fixClass$HTMLAudioElement(_);
  }
  if ((_ = w.HTMLBRElement)) {
    w.HTMLBRElement$Dart = _;
    DOM$fixClass$HTMLBRElement(_);
  }
  if ((_ = w.HTMLBaseElement)) {
    w.HTMLBaseElement$Dart = _;
    DOM$fixClass$HTMLBaseElement(_);
  }
  if ((_ = w.HTMLBaseFontElement)) {
    w.HTMLBaseFontElement$Dart = _;
    DOM$fixClass$HTMLBaseFontElement(_);
  }
  if ((_ = w.HTMLBodyElement)) {
    w.HTMLBodyElement$Dart = _;
    DOM$fixClass$HTMLBodyElement(_);
  }
  if ((_ = w.HTMLButtonElement)) {
    w.HTMLButtonElement$Dart = _;
    DOM$fixClass$HTMLButtonElement(_);
  }
  if ((_ = w.HTMLCanvasElement)) {
    w.HTMLCanvasElement$Dart = _;
    DOM$fixClass$HTMLCanvasElement(_);
  }
  if ((_ = w.HTMLCollection)) {
    w.HTMLCollection$Dart = _;
    DOM$fixClass$HTMLCollection(_);
  }
  if ((_ = w.HTMLDListElement)) {
    w.HTMLDListElement$Dart = _;
    DOM$fixClass$HTMLDListElement(_);
  }
  if ((_ = w.HTMLDataListElement)) {
    w.HTMLDataListElement$Dart = _;
    DOM$fixClass$HTMLDataListElement(_);
  }
  if ((_ = w.HTMLDetailsElement)) {
    w.HTMLDetailsElement$Dart = _;
    DOM$fixClass$HTMLDetailsElement(_);
  }
  if ((_ = w.HTMLDirectoryElement)) {
    w.HTMLDirectoryElement$Dart = _;
    DOM$fixClass$HTMLDirectoryElement(_);
  }
  if ((_ = w.HTMLDivElement)) {
    w.HTMLDivElement$Dart = _;
    DOM$fixClass$HTMLDivElement(_);
  }
  if ((_ = w.HTMLDocument)) {
    w.HTMLDocument$Dart = _;
    DOM$fixClass$HTMLDocument(_);
  }
  if ((_ = w.HTMLElement)) {
    w.HTMLElement$Dart = _;
    DOM$fixClass$HTMLElement(_);
  }
  if ((_ = w.HTMLEmbedElement)) {
    w.HTMLEmbedElement$Dart = _;
    DOM$fixClass$HTMLEmbedElement(_);
  }
  if ((_ = w.HTMLFieldSetElement)) {
    w.HTMLFieldSetElement$Dart = _;
    DOM$fixClass$HTMLFieldSetElement(_);
  }
  if ((_ = w.HTMLFontElement)) {
    w.HTMLFontElement$Dart = _;
    DOM$fixClass$HTMLFontElement(_);
  }
  if ((_ = w.HTMLFormElement)) {
    w.HTMLFormElement$Dart = _;
    DOM$fixClass$HTMLFormElement(_);
  }
  if ((_ = w.HTMLFrameElement)) {
    w.HTMLFrameElement$Dart = _;
    DOM$fixClass$HTMLFrameElement(_);
  }
  if ((_ = w.HTMLFrameSetElement)) {
    w.HTMLFrameSetElement$Dart = _;
    DOM$fixClass$HTMLFrameSetElement(_);
  }
  if ((_ = w.HTMLHRElement)) {
    w.HTMLHRElement$Dart = _;
    DOM$fixClass$HTMLHRElement(_);
  }
  if ((_ = w.HTMLHeadElement)) {
    w.HTMLHeadElement$Dart = _;
    DOM$fixClass$HTMLHeadElement(_);
  }
  if ((_ = w.HTMLHeadingElement)) {
    w.HTMLHeadingElement$Dart = _;
    DOM$fixClass$HTMLHeadingElement(_);
  }
  if ((_ = w.HTMLHtmlElement)) {
    w.HTMLHtmlElement$Dart = _;
    DOM$fixClass$HTMLHtmlElement(_);
  }
  if ((_ = w.HTMLIFrameElement)) {
    w.HTMLIFrameElement$Dart = _;
    DOM$fixClass$HTMLIFrameElement(_);
  }
  if ((_ = w.HTMLImageElement)) {
    w.HTMLImageElement$Dart = _;
    DOM$fixClass$HTMLImageElement(_);
  }
  if ((_ = w.HTMLInputElement)) {
    w.HTMLInputElement$Dart = _;
    DOM$fixClass$HTMLInputElement(_);
  }
  if ((_ = w.HTMLIsIndexElement)) {
    w.HTMLIsIndexElement$Dart = _;
    DOM$fixClass$HTMLIsIndexElement(_);
  }
  if ((_ = w.HTMLKeygenElement)) {
    w.HTMLKeygenElement$Dart = _;
    DOM$fixClass$HTMLKeygenElement(_);
  }
  if ((_ = w.HTMLLIElement)) {
    w.HTMLLIElement$Dart = _;
    DOM$fixClass$HTMLLIElement(_);
  }
  if ((_ = w.HTMLLabelElement)) {
    w.HTMLLabelElement$Dart = _;
    DOM$fixClass$HTMLLabelElement(_);
  }
  if ((_ = w.HTMLLegendElement)) {
    w.HTMLLegendElement$Dart = _;
    DOM$fixClass$HTMLLegendElement(_);
  }
  if ((_ = w.HTMLLinkElement)) {
    w.HTMLLinkElement$Dart = _;
    DOM$fixClass$HTMLLinkElement(_);
  }
  if ((_ = w.HTMLMapElement)) {
    w.HTMLMapElement$Dart = _;
    DOM$fixClass$HTMLMapElement(_);
  }
  if ((_ = w.HTMLMarqueeElement)) {
    w.HTMLMarqueeElement$Dart = _;
    DOM$fixClass$HTMLMarqueeElement(_);
  }
  if ((_ = w.HTMLMediaElement)) {
    w.HTMLMediaElement$Dart = _;
    DOM$fixClass$HTMLMediaElement(_);
  }
  if ((_ = w.HTMLMenuElement)) {
    w.HTMLMenuElement$Dart = _;
    DOM$fixClass$HTMLMenuElement(_);
  }
  if ((_ = w.HTMLMetaElement)) {
    w.HTMLMetaElement$Dart = _;
    DOM$fixClass$HTMLMetaElement(_);
  }
  if ((_ = w.HTMLMeterElement)) {
    w.HTMLMeterElement$Dart = _;
    DOM$fixClass$HTMLMeterElement(_);
  }
  if ((_ = w.HTMLModElement)) {
    w.HTMLModElement$Dart = _;
    DOM$fixClass$HTMLModElement(_);
  }
  if ((_ = w.HTMLOListElement)) {
    w.HTMLOListElement$Dart = _;
    DOM$fixClass$HTMLOListElement(_);
  }
  if ((_ = w.HTMLObjectElement)) {
    w.HTMLObjectElement$Dart = _;
    DOM$fixClass$HTMLObjectElement(_);
  }
  if ((_ = w.HTMLOptGroupElement)) {
    w.HTMLOptGroupElement$Dart = _;
    DOM$fixClass$HTMLOptGroupElement(_);
  }
  if ((_ = w.HTMLOptionElement)) {
    w.HTMLOptionElement$Dart = _;
    DOM$fixClass$HTMLOptionElement(_);
  }
  if ((_ = w.HTMLOptionsCollection)) {
    w.HTMLOptionsCollection$Dart = _;
    DOM$fixClass$HTMLOptionsCollection(_);
  }
  if ((_ = w.HTMLOutputElement)) {
    w.HTMLOutputElement$Dart = _;
    DOM$fixClass$HTMLOutputElement(_);
  }
  if ((_ = w.HTMLParagraphElement)) {
    w.HTMLParagraphElement$Dart = _;
    DOM$fixClass$HTMLParagraphElement(_);
  }
  if ((_ = w.HTMLParamElement)) {
    w.HTMLParamElement$Dart = _;
    DOM$fixClass$HTMLParamElement(_);
  }
  if ((_ = w.HTMLPreElement)) {
    w.HTMLPreElement$Dart = _;
    DOM$fixClass$HTMLPreElement(_);
  }
  if ((_ = w.HTMLProgressElement)) {
    w.HTMLProgressElement$Dart = _;
    DOM$fixClass$HTMLProgressElement(_);
  }
  if ((_ = w.HTMLQuoteElement)) {
    w.HTMLQuoteElement$Dart = _;
    DOM$fixClass$HTMLQuoteElement(_);
  }
  if ((_ = w.HTMLScriptElement)) {
    w.HTMLScriptElement$Dart = _;
    DOM$fixClass$HTMLScriptElement(_);
  }
  if ((_ = w.HTMLSelectElement)) {
    w.HTMLSelectElement$Dart = _;
    DOM$fixClass$HTMLSelectElement(_);
  }
  if ((_ = w.HTMLSourceElement)) {
    w.HTMLSourceElement$Dart = _;
    DOM$fixClass$HTMLSourceElement(_);
  }
  if ((_ = w.HTMLSpanElement)) {
    w.HTMLSpanElement$Dart = _;
    DOM$fixClass$HTMLSpanElement(_);
  }
  if ((_ = w.HTMLStyleElement)) {
    w.HTMLStyleElement$Dart = _;
    DOM$fixClass$HTMLStyleElement(_);
  }
  if ((_ = w.HTMLTableCaptionElement)) {
    w.HTMLTableCaptionElement$Dart = _;
    DOM$fixClass$HTMLTableCaptionElement(_);
  }
  if ((_ = w.HTMLTableCellElement)) {
    w.HTMLTableCellElement$Dart = _;
    DOM$fixClass$HTMLTableCellElement(_);
  }
  if ((_ = w.HTMLTableColElement)) {
    w.HTMLTableColElement$Dart = _;
    DOM$fixClass$HTMLTableColElement(_);
  }
  if ((_ = w.HTMLTableElement)) {
    w.HTMLTableElement$Dart = _;
    DOM$fixClass$HTMLTableElement(_);
  }
  if ((_ = w.HTMLTableRowElement)) {
    w.HTMLTableRowElement$Dart = _;
    DOM$fixClass$HTMLTableRowElement(_);
  }
  if ((_ = w.HTMLTableSectionElement)) {
    w.HTMLTableSectionElement$Dart = _;
    DOM$fixClass$HTMLTableSectionElement(_);
  }
  if ((_ = w.HTMLTextAreaElement)) {
    w.HTMLTextAreaElement$Dart = _;
    DOM$fixClass$HTMLTextAreaElement(_);
  }
  if ((_ = w.HTMLTitleElement)) {
    w.HTMLTitleElement$Dart = _;
    DOM$fixClass$HTMLTitleElement(_);
  }
  if ((_ = w.HTMLTrackElement)) {
    w.HTMLTrackElement$Dart = _;
    DOM$fixClass$HTMLTrackElement(_);
  }
  if ((_ = w.HTMLUListElement)) {
    w.HTMLUListElement$Dart = _;
    DOM$fixClass$HTMLUListElement(_);
  }
  if ((_ = w.HTMLUnknownElement)) {
    w.HTMLUnknownElement$Dart = _;
    DOM$fixClass$HTMLUnknownElement(_);
  }
  if ((_ = w.HTMLVideoElement)) {
    w.HTMLVideoElement$Dart = _;
    DOM$fixClass$HTMLVideoElement(_);
  }
  if ((_ = w.HashChangeEvent)) {
    w.HashChangeEvent$Dart = _;
    DOM$fixClass$HashChangeEvent(_);
  }
  if (!w.History && (_ = w.history) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.History = _;
  }
  if ((_ = w.History)) {
    w.History$Dart = _;
    DOM$fixClass$History(_);
  }
  if ((_ = w.IDBAny)) {
    w.IDBAny$Dart = _;
    DOM$fixClass$IDBAny(_);
  }
  if ((_ = w.IDBCursor)) {
    w.IDBCursor$Dart = _;
    DOM$fixClass$IDBCursor(_);
  }
  if ((_ = w.IDBCursorWithValue)) {
    w.IDBCursorWithValue$Dart = _;
    DOM$fixClass$IDBCursorWithValue(_);
  }
  if ((_ = w.IDBDatabase)) {
    w.IDBDatabase$Dart = _;
    DOM$fixClass$IDBDatabase(_);
  }
  if ((_ = w.IDBDatabaseError)) {
    w.IDBDatabaseError$Dart = _;
    DOM$fixClass$IDBDatabaseError(_);
  }
  if ((_ = w.IDBDatabaseException)) {
    w.IDBDatabaseException$Dart = _;
    DOM$fixClass$IDBDatabaseException(_);
  }
  if ((_ = w.IDBFactory)) {
    w.IDBFactory$Dart = _;
    DOM$fixClass$IDBFactory(_);
  }
  if ((_ = w.IDBIndex)) {
    w.IDBIndex$Dart = _;
    DOM$fixClass$IDBIndex(_);
  }
  if ((_ = w.IDBKey)) {
    w.IDBKey$Dart = _;
    DOM$fixClass$IDBKey(_);
  }
  if ((_ = w.IDBKeyRange)) {
    w.IDBKeyRange$Dart = _;
    DOM$fixClass$IDBKeyRange(_);
  }
  if ((_ = w.IDBObjectStore)) {
    w.IDBObjectStore$Dart = _;
    DOM$fixClass$IDBObjectStore(_);
  }
  if ((_ = w.IDBRequest)) {
    w.IDBRequest$Dart = _;
    DOM$fixClass$IDBRequest(_);
  }
  if ((_ = w.IDBTransaction)) {
    w.IDBTransaction$Dart = _;
    DOM$fixClass$IDBTransaction(_);
  }
  if ((_ = w.IDBVersionChangeEvent)) {
    w.IDBVersionChangeEvent$Dart = _;
    DOM$fixClass$IDBVersionChangeEvent(_);
  }
  if ((_ = w.IDBVersionChangeRequest)) {
    w.IDBVersionChangeRequest$Dart = _;
    DOM$fixClass$IDBVersionChangeRequest(_);
  }
  if ((_ = w.ImageData)) {
    w.ImageData$Dart = _;
    DOM$fixClassOnDemand$ImageData(_);
  }
  if ((_ = w.InjectedScriptHost)) {
    w.InjectedScriptHost$Dart = _;
    DOM$fixClass$InjectedScriptHost(_);
  }
  if ((_ = w.InspectorFrontendHost)) {
    w.InspectorFrontendHost$Dart = _;
    DOM$fixClass$InspectorFrontendHost(_);
  }
  if ((_ = w.Int16Array)) {
    w.Int16Array$Dart = _;
    DOM$fixClass$Int16Array(_);
  }
  if ((_ = w.Int32Array)) {
    w.Int32Array$Dart = _;
    DOM$fixClass$Int32Array(_);
  }
  if ((_ = w.Int8Array)) {
    w.Int8Array$Dart = _;
    DOM$fixClass$Int8Array(_);
  }
  if ((_ = w.JavaScriptCallFrame)) {
    w.JavaScriptCallFrame$Dart = _;
    DOM$fixClass$JavaScriptCallFrame(_);
  }
  if ((_ = w.KeyboardEvent)) {
    w.KeyboardEvent$Dart = _;
    DOM$fixClass$KeyboardEvent(_);
  }
  if (!w.Location && (_ = w.location) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.Location = _;
  }
  if ((_ = w.Location)) {
    w.Location$Dart = _;
    DOM$fixClass$Location(_);
  }
  if ((_ = w.MediaError)) {
    w.MediaError$Dart = _;
    DOM$fixClass$MediaError(_);
  }
  if ((_ = w.MediaList)) {
    w.MediaList$Dart = _;
    DOM$fixClass$MediaList(_);
  }
  if ((_ = w.MediaQueryList)) {
    w.MediaQueryList$Dart = _;
    DOM$fixClass$MediaQueryList(_);
  }
  if ((_ = w.MediaQueryListListener)) {
    w.MediaQueryListListener$Dart = _;
    DOM$fixClass$MediaQueryListListener(_);
  }
  if ((_ = w.MemoryInfo)) {
    w.MemoryInfo$Dart = _;
    DOM$fixClass$MemoryInfo(_);
  }
  if ((_ = w.MessageChannel)) {
    w.MessageChannel$Dart = _;
    DOM$fixClass$MessageChannel(_);
  }
  if ((_ = w.MessageEvent)) {
    w.MessageEvent$Dart = _;
    DOM$fixClass$MessageEvent(_);
  }
  if ((_ = w.MessagePort)) {
    w.MessagePort$Dart = _;
    DOM$fixClass$MessagePort(_);
  }
  if ((_ = w.Metadata)) {
    w.Metadata$Dart = _;
    DOM$fixClass$Metadata(_);
  }
  if ((_ = w.MetadataCallback)) {
    w.MetadataCallback$Dart = _;
    DOM$fixClass$MetadataCallback(_);
  }
  if ((_ = w.MouseEvent)) {
    w.MouseEvent$Dart = _;
    DOM$fixClass$MouseEvent(_);
  }
  if ((_ = w.MutationCallback)) {
    w.MutationCallback$Dart = _;
    DOM$fixClass$MutationCallback(_);
  }
  if ((_ = w.MutationEvent)) {
    w.MutationEvent$Dart = _;
    DOM$fixClass$MutationEvent(_);
  }
  if ((_ = w.MutationRecord)) {
    w.MutationRecord$Dart = _;
    DOM$fixClass$MutationRecord(_);
  }
  if ((_ = w.NamedNodeMap)) {
    w.NamedNodeMap$Dart = _;
    DOM$fixClass$NamedNodeMap(_);
  }
  if (!w.Navigator && (_ = w.navigator) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.Navigator = _;
  }
  if ((_ = w.Navigator)) {
    w.Navigator$Dart = _;
    DOM$fixClass$Navigator(_);
  }
  if ((_ = w.NavigatorUserMediaError)) {
    w.NavigatorUserMediaError$Dart = _;
    DOM$fixClass$NavigatorUserMediaError(_);
  }
  if ((_ = w.NavigatorUserMediaErrorCallback)) {
    w.NavigatorUserMediaErrorCallback$Dart = _;
    DOM$fixClass$NavigatorUserMediaErrorCallback(_);
  }
  if ((_ = w.NavigatorUserMediaSuccessCallback)) {
    w.NavigatorUserMediaSuccessCallback$Dart = _;
    DOM$fixClass$NavigatorUserMediaSuccessCallback(_);
  }
  if ((_ = w.Node)) {
    w.Node$Dart = _;
    DOM$fixClass$Node(_);
  }
  if ((_ = w.NodeFilter)) {
    w.NodeFilter$Dart = _;
    DOM$fixClass$NodeFilter(_);
  }
  if ((_ = w.NodeIterator)) {
    w.NodeIterator$Dart = _;
    DOM$fixClass$NodeIterator(_);
  }
  if ((_ = w.NodeList)) {
    w.NodeList$Dart = _;
    DOM$fixClass$NodeList(_);
  }
  if ((_ = w.NodeSelector)) {
    w.NodeSelector$Dart = _;
    DOM$fixClass$NodeSelector(_);
  }
  if ((_ = w.Notation)) {
    w.Notation$Dart = _;
    DOM$fixClass$Notation(_);
  }
  if ((_ = w.Notification)) {
    w.Notification$Dart = _;
    DOM$fixClassOnDemand$Notification(_);
  }
  if (!w.NotificationCenter && (_ = w.webkitNotifications) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.NotificationCenter = _;
  }
  if ((_ = w.NotificationCenter)) {
    w.NotificationCenter$Dart = _;
    DOM$fixClassOnDemand$NotificationCenter(_);
  }
  if ((_ = w.OESStandardDerivatives)) {
    w.OESStandardDerivatives$Dart = _;
    DOM$fixClass$OESStandardDerivatives(_);
  }
  if ((_ = w.OESTextureFloat)) {
    w.OESTextureFloat$Dart = _;
    DOM$fixClass$OESTextureFloat(_);
  }
  if ((_ = w.OESVertexArrayObject)) {
    w.OESVertexArrayObject$Dart = _;
    DOM$fixClass$OESVertexArrayObject(_);
  }
  if ((_ = w.OperationNotAllowedException)) {
    w.OperationNotAllowedException$Dart = _;
    DOM$fixClass$OperationNotAllowedException(_);
  }
  if ((_ = w.OverflowEvent)) {
    w.OverflowEvent$Dart = _;
    DOM$fixClass$OverflowEvent(_);
  }
  if ((_ = w.PageTransitionEvent)) {
    w.PageTransitionEvent$Dart = _;
    DOM$fixClass$PageTransitionEvent(_);
  }
  if (!w.Performance && (_ = w.performance) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.Performance = _;
  }
  if ((_ = w.Performance)) {
    w.Performance$Dart = _;
    DOM$fixClass$Performance(_);
  }
  if (!w.PerformanceNavigation && (_ = w.performance) && (_ = _.navigation) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.PerformanceNavigation = _;
  }
  if ((_ = w.PerformanceNavigation)) {
    w.PerformanceNavigation$Dart = _;
    DOM$fixClass$PerformanceNavigation(_);
  }
  if (!w.PerformanceTiming && (_ = w.performance) && (_ = _.timing) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.PerformanceTiming = _;
  }
  if ((_ = w.PerformanceTiming)) {
    w.PerformanceTiming$Dart = _;
    DOM$fixClass$PerformanceTiming(_);
  }
  if ((_ = w.PopStateEvent)) {
    w.PopStateEvent$Dart = _;
    DOM$fixClass$PopStateEvent(_);
  }
  if ((_ = w.PositionCallback)) {
    w.PositionCallback$Dart = _;
    DOM$fixClass$PositionCallback(_);
  }
  if ((_ = w.PositionError)) {
    w.PositionError$Dart = _;
    DOM$fixClass$PositionError(_);
  }
  if ((_ = w.PositionErrorCallback)) {
    w.PositionErrorCallback$Dart = _;
    DOM$fixClass$PositionErrorCallback(_);
  }
  if ((_ = w.ProcessingInstruction)) {
    w.ProcessingInstruction$Dart = _;
    DOM$fixClass$ProcessingInstruction(_);
  }
  if ((_ = w.ProgressEvent)) {
    w.ProgressEvent$Dart = _;
    DOM$fixClass$ProgressEvent(_);
  }
  if ((_ = w.RGBColor)) {
    w.RGBColor$Dart = _;
    DOM$fixClass$RGBColor(_);
  }
  if ((_ = w.Range)) {
    w.Range$Dart = _;
    DOM$fixClass$Range(_);
  }
  if ((_ = w.RangeException)) {
    w.RangeException$Dart = _;
    DOM$fixClass$RangeException(_);
  }
  if ((_ = w.Rect)) {
    w.Rect$Dart = _;
    DOM$fixClass$Rect(_);
  }
  if ((_ = w.SQLError)) {
    w.SQLError$Dart = _;
    DOM$fixClass$SQLError(_);
  }
  if ((_ = w.SQLException)) {
    w.SQLException$Dart = _;
    DOM$fixClass$SQLException(_);
  }
  if ((_ = w.SQLResultSet)) {
    w.SQLResultSet$Dart = _;
    DOM$fixClass$SQLResultSet(_);
  }
  if ((_ = w.SQLResultSetRowList)) {
    w.SQLResultSetRowList$Dart = _;
    DOM$fixClass$SQLResultSetRowList(_);
  }
  if ((_ = w.SQLStatementCallback)) {
    w.SQLStatementCallback$Dart = _;
    DOM$fixClass$SQLStatementCallback(_);
  }
  if ((_ = w.SQLStatementErrorCallback)) {
    w.SQLStatementErrorCallback$Dart = _;
    DOM$fixClass$SQLStatementErrorCallback(_);
  }
  if ((_ = w.SQLTransaction)) {
    w.SQLTransaction$Dart = _;
    DOM$fixClass$SQLTransaction(_);
  }
  if ((_ = w.SQLTransactionCallback)) {
    w.SQLTransactionCallback$Dart = _;
    DOM$fixClass$SQLTransactionCallback(_);
  }
  if ((_ = w.SQLTransactionErrorCallback)) {
    w.SQLTransactionErrorCallback$Dart = _;
    DOM$fixClass$SQLTransactionErrorCallback(_);
  }
  if ((_ = w.SQLTransactionSync)) {
    w.SQLTransactionSync$Dart = _;
    DOM$fixClass$SQLTransactionSync(_);
  }
  if ((_ = w.SQLTransactionSyncCallback)) {
    w.SQLTransactionSyncCallback$Dart = _;
    DOM$fixClass$SQLTransactionSyncCallback(_);
  }
  if ((_ = w.SVGAElement)) {
    w.SVGAElement$Dart = _;
    DOM$fixClass$SVGAElement(_);
  }
  if ((_ = w.SVGAltGlyphDefElement)) {
    w.SVGAltGlyphDefElement$Dart = _;
    DOM$fixClass$SVGAltGlyphDefElement(_);
  }
  if ((_ = w.SVGAltGlyphElement)) {
    w.SVGAltGlyphElement$Dart = _;
    DOM$fixClass$SVGAltGlyphElement(_);
  }
  if ((_ = w.SVGAltGlyphItemElement)) {
    w.SVGAltGlyphItemElement$Dart = _;
    DOM$fixClass$SVGAltGlyphItemElement(_);
  }
  if ((_ = w.SVGAngle)) {
    w.SVGAngle$Dart = _;
    DOM$fixClass$SVGAngle(_);
  }
  if ((_ = w.SVGAnimateColorElement)) {
    w.SVGAnimateColorElement$Dart = _;
    DOM$fixClass$SVGAnimateColorElement(_);
  }
  if ((_ = w.SVGAnimateElement)) {
    w.SVGAnimateElement$Dart = _;
    DOM$fixClass$SVGAnimateElement(_);
  }
  if ((_ = w.SVGAnimateMotionElement)) {
    w.SVGAnimateMotionElement$Dart = _;
    DOM$fixClass$SVGAnimateMotionElement(_);
  }
  if ((_ = w.SVGAnimateTransformElement)) {
    w.SVGAnimateTransformElement$Dart = _;
    DOM$fixClass$SVGAnimateTransformElement(_);
  }
  if ((_ = w.SVGAnimatedAngle)) {
    w.SVGAnimatedAngle$Dart = _;
    DOM$fixClass$SVGAnimatedAngle(_);
  }
  if ((_ = w.SVGAnimatedBoolean)) {
    w.SVGAnimatedBoolean$Dart = _;
    DOM$fixClass$SVGAnimatedBoolean(_);
  }
  if ((_ = w.SVGAnimatedEnumeration)) {
    w.SVGAnimatedEnumeration$Dart = _;
    DOM$fixClass$SVGAnimatedEnumeration(_);
  }
  if ((_ = w.SVGAnimatedInteger)) {
    w.SVGAnimatedInteger$Dart = _;
    DOM$fixClass$SVGAnimatedInteger(_);
  }
  if ((_ = w.SVGAnimatedLength)) {
    w.SVGAnimatedLength$Dart = _;
    DOM$fixClass$SVGAnimatedLength(_);
  }
  if ((_ = w.SVGAnimatedLengthList)) {
    w.SVGAnimatedLengthList$Dart = _;
    DOM$fixClass$SVGAnimatedLengthList(_);
  }
  if ((_ = w.SVGAnimatedNumber)) {
    w.SVGAnimatedNumber$Dart = _;
    DOM$fixClass$SVGAnimatedNumber(_);
  }
  if ((_ = w.SVGAnimatedNumberList)) {
    w.SVGAnimatedNumberList$Dart = _;
    DOM$fixClass$SVGAnimatedNumberList(_);
  }
  if ((_ = w.SVGAnimatedPreserveAspectRatio)) {
    w.SVGAnimatedPreserveAspectRatio$Dart = _;
    DOM$fixClass$SVGAnimatedPreserveAspectRatio(_);
  }
  if ((_ = w.SVGAnimatedRect)) {
    w.SVGAnimatedRect$Dart = _;
    DOM$fixClass$SVGAnimatedRect(_);
  }
  if ((_ = w.SVGAnimatedString)) {
    w.SVGAnimatedString$Dart = _;
    DOM$fixClass$SVGAnimatedString(_);
  }
  if ((_ = w.SVGAnimatedTransformList)) {
    w.SVGAnimatedTransformList$Dart = _;
    DOM$fixClass$SVGAnimatedTransformList(_);
  }
  if ((_ = w.SVGAnimationElement)) {
    w.SVGAnimationElement$Dart = _;
    DOM$fixClass$SVGAnimationElement(_);
  }
  if ((_ = w.SVGCircleElement)) {
    w.SVGCircleElement$Dart = _;
    DOM$fixClass$SVGCircleElement(_);
  }
  if ((_ = w.SVGClipPathElement)) {
    w.SVGClipPathElement$Dart = _;
    DOM$fixClass$SVGClipPathElement(_);
  }
  if ((_ = w.SVGColor)) {
    w.SVGColor$Dart = _;
    DOM$fixClass$SVGColor(_);
  }
  if ((_ = w.SVGComponentTransferFunctionElement)) {
    w.SVGComponentTransferFunctionElement$Dart = _;
    DOM$fixClass$SVGComponentTransferFunctionElement(_);
  }
  if ((_ = w.SVGCursorElement)) {
    w.SVGCursorElement$Dart = _;
    DOM$fixClass$SVGCursorElement(_);
  }
  if ((_ = w.SVGDefsElement)) {
    w.SVGDefsElement$Dart = _;
    DOM$fixClass$SVGDefsElement(_);
  }
  if ((_ = w.SVGDescElement)) {
    w.SVGDescElement$Dart = _;
    DOM$fixClass$SVGDescElement(_);
  }
  if ((_ = w.SVGDocument)) {
    w.SVGDocument$Dart = _;
    DOM$fixClass$SVGDocument(_);
  }
  if ((_ = w.SVGElement)) {
    w.SVGElement$Dart = _;
    DOM$fixClass$SVGElement(_);
  }
  if ((_ = w.SVGElementInstance)) {
    w.SVGElementInstance$Dart = _;
    DOM$fixClass$SVGElementInstance(_);
  }
  if ((_ = w.SVGElementInstanceList)) {
    w.SVGElementInstanceList$Dart = _;
    DOM$fixClass$SVGElementInstanceList(_);
  }
  if ((_ = w.SVGEllipseElement)) {
    w.SVGEllipseElement$Dart = _;
    DOM$fixClass$SVGEllipseElement(_);
  }
  if ((_ = w.SVGException)) {
    w.SVGException$Dart = _;
    DOM$fixClass$SVGException(_);
  }
  if ((_ = w.SVGExternalResourcesRequired)) {
    w.SVGExternalResourcesRequired$Dart = _;
    DOM$fixClass$SVGExternalResourcesRequired(_);
  }
  if ((_ = w.SVGFEBlendElement)) {
    w.SVGFEBlendElement$Dart = _;
    DOM$fixClass$SVGFEBlendElement(_);
  }
  if ((_ = w.SVGFEColorMatrixElement)) {
    w.SVGFEColorMatrixElement$Dart = _;
    DOM$fixClass$SVGFEColorMatrixElement(_);
  }
  if ((_ = w.SVGFEComponentTransferElement)) {
    w.SVGFEComponentTransferElement$Dart = _;
    DOM$fixClass$SVGFEComponentTransferElement(_);
  }
  if ((_ = w.SVGFECompositeElement)) {
    w.SVGFECompositeElement$Dart = _;
    DOM$fixClass$SVGFECompositeElement(_);
  }
  if ((_ = w.SVGFEConvolveMatrixElement)) {
    w.SVGFEConvolveMatrixElement$Dart = _;
    DOM$fixClass$SVGFEConvolveMatrixElement(_);
  }
  if ((_ = w.SVGFEDiffuseLightingElement)) {
    w.SVGFEDiffuseLightingElement$Dart = _;
    DOM$fixClass$SVGFEDiffuseLightingElement(_);
  }
  if ((_ = w.SVGFEDisplacementMapElement)) {
    w.SVGFEDisplacementMapElement$Dart = _;
    DOM$fixClass$SVGFEDisplacementMapElement(_);
  }
  if ((_ = w.SVGFEDistantLightElement)) {
    w.SVGFEDistantLightElement$Dart = _;
    DOM$fixClass$SVGFEDistantLightElement(_);
  }
  if ((_ = w.SVGFEDropShadowElement)) {
    w.SVGFEDropShadowElement$Dart = _;
    DOM$fixClass$SVGFEDropShadowElement(_);
  }
  if ((_ = w.SVGFEFloodElement)) {
    w.SVGFEFloodElement$Dart = _;
    DOM$fixClass$SVGFEFloodElement(_);
  }
  if ((_ = w.SVGFEFuncAElement)) {
    w.SVGFEFuncAElement$Dart = _;
    DOM$fixClass$SVGFEFuncAElement(_);
  }
  if ((_ = w.SVGFEFuncBElement)) {
    w.SVGFEFuncBElement$Dart = _;
    DOM$fixClass$SVGFEFuncBElement(_);
  }
  if ((_ = w.SVGFEFuncGElement)) {
    w.SVGFEFuncGElement$Dart = _;
    DOM$fixClass$SVGFEFuncGElement(_);
  }
  if ((_ = w.SVGFEFuncRElement)) {
    w.SVGFEFuncRElement$Dart = _;
    DOM$fixClass$SVGFEFuncRElement(_);
  }
  if ((_ = w.SVGFEGaussianBlurElement)) {
    w.SVGFEGaussianBlurElement$Dart = _;
    DOM$fixClass$SVGFEGaussianBlurElement(_);
  }
  if ((_ = w.SVGFEImageElement)) {
    w.SVGFEImageElement$Dart = _;
    DOM$fixClass$SVGFEImageElement(_);
  }
  if ((_ = w.SVGFEMergeElement)) {
    w.SVGFEMergeElement$Dart = _;
    DOM$fixClass$SVGFEMergeElement(_);
  }
  if ((_ = w.SVGFEMergeNodeElement)) {
    w.SVGFEMergeNodeElement$Dart = _;
    DOM$fixClass$SVGFEMergeNodeElement(_);
  }
  if ((_ = w.SVGFEMorphologyElement)) {
    w.SVGFEMorphologyElement$Dart = _;
    DOM$fixClass$SVGFEMorphologyElement(_);
  }
  if ((_ = w.SVGFEOffsetElement)) {
    w.SVGFEOffsetElement$Dart = _;
    DOM$fixClass$SVGFEOffsetElement(_);
  }
  if ((_ = w.SVGFEPointLightElement)) {
    w.SVGFEPointLightElement$Dart = _;
    DOM$fixClass$SVGFEPointLightElement(_);
  }
  if ((_ = w.SVGFESpecularLightingElement)) {
    w.SVGFESpecularLightingElement$Dart = _;
    DOM$fixClass$SVGFESpecularLightingElement(_);
  }
  if ((_ = w.SVGFESpotLightElement)) {
    w.SVGFESpotLightElement$Dart = _;
    DOM$fixClass$SVGFESpotLightElement(_);
  }
  if ((_ = w.SVGFETileElement)) {
    w.SVGFETileElement$Dart = _;
    DOM$fixClass$SVGFETileElement(_);
  }
  if ((_ = w.SVGFETurbulenceElement)) {
    w.SVGFETurbulenceElement$Dart = _;
    DOM$fixClass$SVGFETurbulenceElement(_);
  }
  if ((_ = w.SVGFilterElement)) {
    w.SVGFilterElement$Dart = _;
    DOM$fixClass$SVGFilterElement(_);
  }
  if ((_ = w.SVGFilterPrimitiveStandardAttributes)) {
    w.SVGFilterPrimitiveStandardAttributes$Dart = _;
    DOM$fixClass$SVGFilterPrimitiveStandardAttributes(_);
  }
  if ((_ = w.SVGFitToViewBox)) {
    w.SVGFitToViewBox$Dart = _;
    DOM$fixClass$SVGFitToViewBox(_);
  }
  if ((_ = w.SVGFontElement)) {
    w.SVGFontElement$Dart = _;
    DOM$fixClass$SVGFontElement(_);
  }
  if ((_ = w.SVGFontFaceElement)) {
    w.SVGFontFaceElement$Dart = _;
    DOM$fixClass$SVGFontFaceElement(_);
  }
  if ((_ = w.SVGFontFaceFormatElement)) {
    w.SVGFontFaceFormatElement$Dart = _;
    DOM$fixClass$SVGFontFaceFormatElement(_);
  }
  if ((_ = w.SVGFontFaceNameElement)) {
    w.SVGFontFaceNameElement$Dart = _;
    DOM$fixClass$SVGFontFaceNameElement(_);
  }
  if ((_ = w.SVGFontFaceSrcElement)) {
    w.SVGFontFaceSrcElement$Dart = _;
    DOM$fixClass$SVGFontFaceSrcElement(_);
  }
  if ((_ = w.SVGFontFaceUriElement)) {
    w.SVGFontFaceUriElement$Dart = _;
    DOM$fixClass$SVGFontFaceUriElement(_);
  }
  if ((_ = w.SVGForeignObjectElement)) {
    w.SVGForeignObjectElement$Dart = _;
    DOM$fixClass$SVGForeignObjectElement(_);
  }
  if ((_ = w.SVGGElement)) {
    w.SVGGElement$Dart = _;
    DOM$fixClass$SVGGElement(_);
  }
  if ((_ = w.SVGGlyphElement)) {
    w.SVGGlyphElement$Dart = _;
    DOM$fixClass$SVGGlyphElement(_);
  }
  if ((_ = w.SVGGlyphRefElement)) {
    w.SVGGlyphRefElement$Dart = _;
    DOM$fixClass$SVGGlyphRefElement(_);
  }
  if ((_ = w.SVGGradientElement)) {
    w.SVGGradientElement$Dart = _;
    DOM$fixClass$SVGGradientElement(_);
  }
  if ((_ = w.SVGHKernElement)) {
    w.SVGHKernElement$Dart = _;
    DOM$fixClass$SVGHKernElement(_);
  }
  if ((_ = w.SVGImageElement)) {
    w.SVGImageElement$Dart = _;
    DOM$fixClass$SVGImageElement(_);
  }
  if ((_ = w.SVGLangSpace)) {
    w.SVGLangSpace$Dart = _;
    DOM$fixClass$SVGLangSpace(_);
  }
  if ((_ = w.SVGLength)) {
    w.SVGLength$Dart = _;
    DOM$fixClass$SVGLength(_);
  }
  if ((_ = w.SVGLengthList)) {
    w.SVGLengthList$Dart = _;
    DOM$fixClass$SVGLengthList(_);
  }
  if ((_ = w.SVGLineElement)) {
    w.SVGLineElement$Dart = _;
    DOM$fixClass$SVGLineElement(_);
  }
  if ((_ = w.SVGLinearGradientElement)) {
    w.SVGLinearGradientElement$Dart = _;
    DOM$fixClass$SVGLinearGradientElement(_);
  }
  if ((_ = w.SVGLocatable)) {
    w.SVGLocatable$Dart = _;
    DOM$fixClass$SVGLocatable(_);
  }
  if ((_ = w.SVGMPathElement)) {
    w.SVGMPathElement$Dart = _;
    DOM$fixClass$SVGMPathElement(_);
  }
  if ((_ = w.SVGMarkerElement)) {
    w.SVGMarkerElement$Dart = _;
    DOM$fixClass$SVGMarkerElement(_);
  }
  if ((_ = w.SVGMaskElement)) {
    w.SVGMaskElement$Dart = _;
    DOM$fixClass$SVGMaskElement(_);
  }
  if ((_ = w.SVGMatrix)) {
    w.SVGMatrix$Dart = _;
    DOM$fixClass$SVGMatrix(_);
  }
  if ((_ = w.SVGMetadataElement)) {
    w.SVGMetadataElement$Dart = _;
    DOM$fixClass$SVGMetadataElement(_);
  }
  if ((_ = w.SVGMissingGlyphElement)) {
    w.SVGMissingGlyphElement$Dart = _;
    DOM$fixClass$SVGMissingGlyphElement(_);
  }
  if ((_ = w.SVGNumber)) {
    w.SVGNumber$Dart = _;
    DOM$fixClass$SVGNumber(_);
  }
  if ((_ = w.SVGNumberList)) {
    w.SVGNumberList$Dart = _;
    DOM$fixClass$SVGNumberList(_);
  }
  if ((_ = w.SVGPaint)) {
    w.SVGPaint$Dart = _;
    DOM$fixClass$SVGPaint(_);
  }
  if ((_ = w.SVGPathElement)) {
    w.SVGPathElement$Dart = _;
    DOM$fixClass$SVGPathElement(_);
  }
  if ((_ = w.SVGPathSeg)) {
    w.SVGPathSeg$Dart = _;
    DOM$fixClass$SVGPathSeg(_);
  }
  if ((_ = w.SVGPathSegArcAbs)) {
    w.SVGPathSegArcAbs$Dart = _;
    DOM$fixClass$SVGPathSegArcAbs(_);
  }
  if ((_ = w.SVGPathSegArcRel)) {
    w.SVGPathSegArcRel$Dart = _;
    DOM$fixClass$SVGPathSegArcRel(_);
  }
  if ((_ = w.SVGPathSegClosePath)) {
    w.SVGPathSegClosePath$Dart = _;
    DOM$fixClass$SVGPathSegClosePath(_);
  }
  if ((_ = w.SVGPathSegCurvetoCubicAbs)) {
    w.SVGPathSegCurvetoCubicAbs$Dart = _;
    DOM$fixClass$SVGPathSegCurvetoCubicAbs(_);
  }
  if ((_ = w.SVGPathSegCurvetoCubicRel)) {
    w.SVGPathSegCurvetoCubicRel$Dart = _;
    DOM$fixClass$SVGPathSegCurvetoCubicRel(_);
  }
  if ((_ = w.SVGPathSegCurvetoCubicSmoothAbs)) {
    w.SVGPathSegCurvetoCubicSmoothAbs$Dart = _;
    DOM$fixClass$SVGPathSegCurvetoCubicSmoothAbs(_);
  }
  if ((_ = w.SVGPathSegCurvetoCubicSmoothRel)) {
    w.SVGPathSegCurvetoCubicSmoothRel$Dart = _;
    DOM$fixClass$SVGPathSegCurvetoCubicSmoothRel(_);
  }
  if ((_ = w.SVGPathSegCurvetoQuadraticAbs)) {
    w.SVGPathSegCurvetoQuadraticAbs$Dart = _;
    DOM$fixClass$SVGPathSegCurvetoQuadraticAbs(_);
  }
  if ((_ = w.SVGPathSegCurvetoQuadraticRel)) {
    w.SVGPathSegCurvetoQuadraticRel$Dart = _;
    DOM$fixClass$SVGPathSegCurvetoQuadraticRel(_);
  }
  if ((_ = w.SVGPathSegCurvetoQuadraticSmoothAbs)) {
    w.SVGPathSegCurvetoQuadraticSmoothAbs$Dart = _;
    DOM$fixClass$SVGPathSegCurvetoQuadraticSmoothAbs(_);
  }
  if ((_ = w.SVGPathSegCurvetoQuadraticSmoothRel)) {
    w.SVGPathSegCurvetoQuadraticSmoothRel$Dart = _;
    DOM$fixClass$SVGPathSegCurvetoQuadraticSmoothRel(_);
  }
  if ((_ = w.SVGPathSegLinetoAbs)) {
    w.SVGPathSegLinetoAbs$Dart = _;
    DOM$fixClass$SVGPathSegLinetoAbs(_);
  }
  if ((_ = w.SVGPathSegLinetoHorizontalAbs)) {
    w.SVGPathSegLinetoHorizontalAbs$Dart = _;
    DOM$fixClass$SVGPathSegLinetoHorizontalAbs(_);
  }
  if ((_ = w.SVGPathSegLinetoHorizontalRel)) {
    w.SVGPathSegLinetoHorizontalRel$Dart = _;
    DOM$fixClass$SVGPathSegLinetoHorizontalRel(_);
  }
  if ((_ = w.SVGPathSegLinetoRel)) {
    w.SVGPathSegLinetoRel$Dart = _;
    DOM$fixClass$SVGPathSegLinetoRel(_);
  }
  if ((_ = w.SVGPathSegLinetoVerticalAbs)) {
    w.SVGPathSegLinetoVerticalAbs$Dart = _;
    DOM$fixClass$SVGPathSegLinetoVerticalAbs(_);
  }
  if ((_ = w.SVGPathSegLinetoVerticalRel)) {
    w.SVGPathSegLinetoVerticalRel$Dart = _;
    DOM$fixClass$SVGPathSegLinetoVerticalRel(_);
  }
  if ((_ = w.SVGPathSegList)) {
    w.SVGPathSegList$Dart = _;
    DOM$fixClass$SVGPathSegList(_);
  }
  if ((_ = w.SVGPathSegMovetoAbs)) {
    w.SVGPathSegMovetoAbs$Dart = _;
    DOM$fixClass$SVGPathSegMovetoAbs(_);
  }
  if ((_ = w.SVGPathSegMovetoRel)) {
    w.SVGPathSegMovetoRel$Dart = _;
    DOM$fixClass$SVGPathSegMovetoRel(_);
  }
  if ((_ = w.SVGPatternElement)) {
    w.SVGPatternElement$Dart = _;
    DOM$fixClass$SVGPatternElement(_);
  }
  if ((_ = w.SVGPoint)) {
    w.SVGPoint$Dart = _;
    DOM$fixClass$SVGPoint(_);
  }
  if ((_ = w.SVGPointList)) {
    w.SVGPointList$Dart = _;
    DOM$fixClass$SVGPointList(_);
  }
  if ((_ = w.SVGPolygonElement)) {
    w.SVGPolygonElement$Dart = _;
    DOM$fixClass$SVGPolygonElement(_);
  }
  if ((_ = w.SVGPolylineElement)) {
    w.SVGPolylineElement$Dart = _;
    DOM$fixClass$SVGPolylineElement(_);
  }
  if ((_ = w.SVGPreserveAspectRatio)) {
    w.SVGPreserveAspectRatio$Dart = _;
    DOM$fixClass$SVGPreserveAspectRatio(_);
  }
  if ((_ = w.SVGRadialGradientElement)) {
    w.SVGRadialGradientElement$Dart = _;
    DOM$fixClass$SVGRadialGradientElement(_);
  }
  if ((_ = w.SVGRect)) {
    w.SVGRect$Dart = _;
    DOM$fixClass$SVGRect(_);
  }
  if ((_ = w.SVGRectElement)) {
    w.SVGRectElement$Dart = _;
    DOM$fixClass$SVGRectElement(_);
  }
  if ((_ = w.SVGRenderingIntent)) {
    w.SVGRenderingIntent$Dart = _;
    DOM$fixClass$SVGRenderingIntent(_);
  }
  if ((_ = w.SVGSVGElement)) {
    w.SVGSVGElement$Dart = _;
    DOM$fixClass$SVGSVGElement(_);
  }
  if ((_ = w.SVGScriptElement)) {
    w.SVGScriptElement$Dart = _;
    DOM$fixClass$SVGScriptElement(_);
  }
  if ((_ = w.SVGSetElement)) {
    w.SVGSetElement$Dart = _;
    DOM$fixClass$SVGSetElement(_);
  }
  if ((_ = w.SVGStopElement)) {
    w.SVGStopElement$Dart = _;
    DOM$fixClass$SVGStopElement(_);
  }
  if ((_ = w.SVGStringList)) {
    w.SVGStringList$Dart = _;
    DOM$fixClass$SVGStringList(_);
  }
  if ((_ = w.SVGStylable)) {
    w.SVGStylable$Dart = _;
    DOM$fixClass$SVGStylable(_);
  }
  if ((_ = w.SVGStyleElement)) {
    w.SVGStyleElement$Dart = _;
    DOM$fixClass$SVGStyleElement(_);
  }
  if ((_ = w.SVGSwitchElement)) {
    w.SVGSwitchElement$Dart = _;
    DOM$fixClass$SVGSwitchElement(_);
  }
  if ((_ = w.SVGSymbolElement)) {
    w.SVGSymbolElement$Dart = _;
    DOM$fixClass$SVGSymbolElement(_);
  }
  if ((_ = w.SVGTRefElement)) {
    w.SVGTRefElement$Dart = _;
    DOM$fixClass$SVGTRefElement(_);
  }
  if ((_ = w.SVGTSpanElement)) {
    w.SVGTSpanElement$Dart = _;
    DOM$fixClass$SVGTSpanElement(_);
  }
  if ((_ = w.SVGTests)) {
    w.SVGTests$Dart = _;
    DOM$fixClass$SVGTests(_);
  }
  if ((_ = w.SVGTextContentElement)) {
    w.SVGTextContentElement$Dart = _;
    DOM$fixClass$SVGTextContentElement(_);
  }
  if ((_ = w.SVGTextElement)) {
    w.SVGTextElement$Dart = _;
    DOM$fixClass$SVGTextElement(_);
  }
  if ((_ = w.SVGTextPathElement)) {
    w.SVGTextPathElement$Dart = _;
    DOM$fixClass$SVGTextPathElement(_);
  }
  if ((_ = w.SVGTextPositioningElement)) {
    w.SVGTextPositioningElement$Dart = _;
    DOM$fixClass$SVGTextPositioningElement(_);
  }
  if ((_ = w.SVGTitleElement)) {
    w.SVGTitleElement$Dart = _;
    DOM$fixClass$SVGTitleElement(_);
  }
  if ((_ = w.SVGTransform)) {
    w.SVGTransform$Dart = _;
    DOM$fixClass$SVGTransform(_);
  }
  if ((_ = w.SVGTransformList)) {
    w.SVGTransformList$Dart = _;
    DOM$fixClass$SVGTransformList(_);
  }
  if ((_ = w.SVGTransformable)) {
    w.SVGTransformable$Dart = _;
    DOM$fixClass$SVGTransformable(_);
  }
  if ((_ = w.SVGURIReference)) {
    w.SVGURIReference$Dart = _;
    DOM$fixClass$SVGURIReference(_);
  }
  if ((_ = w.SVGUnitTypes)) {
    w.SVGUnitTypes$Dart = _;
    DOM$fixClass$SVGUnitTypes(_);
  }
  if ((_ = w.SVGUseElement)) {
    w.SVGUseElement$Dart = _;
    DOM$fixClass$SVGUseElement(_);
  }
  if ((_ = w.SVGVKernElement)) {
    w.SVGVKernElement$Dart = _;
    DOM$fixClass$SVGVKernElement(_);
  }
  if ((_ = w.SVGViewElement)) {
    w.SVGViewElement$Dart = _;
    DOM$fixClass$SVGViewElement(_);
  }
  if ((_ = w.SVGViewSpec)) {
    w.SVGViewSpec$Dart = _;
    DOM$fixClass$SVGViewSpec(_);
  }
  if ((_ = w.SVGZoomAndPan)) {
    w.SVGZoomAndPan$Dart = _;
    DOM$fixClass$SVGZoomAndPan(_);
  }
  if ((_ = w.SVGZoomEvent)) {
    w.SVGZoomEvent$Dart = _;
    DOM$fixClass$SVGZoomEvent(_);
  }
  if (!w.Screen && (_ = w.screen) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.Screen = _;
  }
  if ((_ = w.Screen)) {
    w.Screen$Dart = _;
    DOM$fixClass$Screen(_);
  }
  if ((_ = w.ScriptProfile)) {
    w.ScriptProfile$Dart = _;
    DOM$fixClass$ScriptProfile(_);
  }
  if ((_ = w.ScriptProfileNode)) {
    w.ScriptProfileNode$Dart = _;
    DOM$fixClass$ScriptProfileNode(_);
  }
  if ((_ = w.SharedWorker)) {
    w.SharedWorker$Dart = _;
    DOM$fixClass$SharedWorker(_);
  }
  if ((_ = w.SharedWorkercontext)) {
    w.SharedWorkercontext$Dart = _;
    DOM$fixClass$SharedWorkercontext(_);
  }
  if ((_ = w.SpeechInputEvent)) {
    w.SpeechInputEvent$Dart = _;
    DOM$fixClass$SpeechInputEvent(_);
  }
  if ((_ = w.SpeechInputResult)) {
    w.SpeechInputResult$Dart = _;
    DOM$fixClass$SpeechInputResult(_);
  }
  if ((_ = w.SpeechInputResultList)) {
    w.SpeechInputResultList$Dart = _;
    DOM$fixClass$SpeechInputResultList(_);
  }
  if (!w.Storage && (_ = w.sessionStorage) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.Storage = _;
  }
  if ((_ = w.Storage)) {
    w.Storage$Dart = _;
    DOM$fixClass$Storage(_);
  }
  if ((_ = w.StorageEvent)) {
    w.StorageEvent$Dart = _;
    DOM$fixClass$StorageEvent(_);
  }
  if ((_ = w.StorageInfo)) {
    w.StorageInfo$Dart = _;
    DOM$fixClass$StorageInfo(_);
  }
  if ((_ = w.StorageInfoErrorCallback)) {
    w.StorageInfoErrorCallback$Dart = _;
    DOM$fixClass$StorageInfoErrorCallback(_);
  }
  if ((_ = w.StorageInfoQuotaCallback)) {
    w.StorageInfoQuotaCallback$Dart = _;
    DOM$fixClass$StorageInfoQuotaCallback(_);
  }
  if ((_ = w.StorageInfoUsageCallback)) {
    w.StorageInfoUsageCallback$Dart = _;
    DOM$fixClass$StorageInfoUsageCallback(_);
  }
  if ((_ = w.StringCallback)) {
    w.StringCallback$Dart = _;
    DOM$fixClass$StringCallback(_);
  }
  if (!w.StyleMedia && (_ = w.styleMedia) && (_ = _.__proto__) && (_ = {prototype: _})) {
    w.StyleMedia = _;
  }
  if ((_ = w.StyleMedia)) {
    w.StyleMedia$Dart = _;
    DOM$fixClass$StyleMedia(_);
  }
  if ((_ = w.StyleSheet)) {
    w.StyleSheet$Dart = _;
    DOM$fixClass$StyleSheet(_);
  }
  if ((_ = w.StyleSheetList)) {
    w.StyleSheetList$Dart = _;
    DOM$fixClass$StyleSheetList(_);
  }
  if ((_ = w.Text)) {
    w.Text$Dart = _;
    DOM$fixClass$Text(_);
  }
  if ((_ = w.TextEvent)) {
    w.TextEvent$Dart = _;
    DOM$fixClass$TextEvent(_);
  }
  if ((_ = w.TextMetrics)) {
    w.TextMetrics$Dart = _;
    DOM$fixClass$TextMetrics(_);
  }
  if ((_ = w.TextTrack)) {
    w.TextTrack$Dart = _;
    DOM$fixClass$TextTrack(_);
  }
  if ((_ = w.TextTrackCue)) {
    w.TextTrackCue$Dart = _;
    DOM$fixClass$TextTrackCue(_);
  }
  if ((_ = w.TextTrackCueList)) {
    w.TextTrackCueList$Dart = _;
    DOM$fixClass$TextTrackCueList(_);
  }
  if ((_ = w.TimeRanges)) {
    w.TimeRanges$Dart = _;
    DOM$fixClass$TimeRanges(_);
  }
  if ((_ = w.Touch)) {
    w.Touch$Dart = _;
    DOM$fixClassOnDemand$Touch(_);
  }
  if ((_ = w.TouchEvent)) {
    w.TouchEvent$Dart = _;
    DOM$fixClass$TouchEvent(_);
  }
  if ((_ = w.TouchList)) {
    w.TouchList$Dart = _;
    DOM$fixClassOnDemand$TouchList(_);
  }
  if ((_ = w.TreeWalker)) {
    w.TreeWalker$Dart = _;
    DOM$fixClass$TreeWalker(_);
  }
  if ((_ = w.UIEvent)) {
    w.UIEvent$Dart = _;
    DOM$fixClass$UIEvent(_);
  }
  if ((_ = w.Uint16Array)) {
    w.Uint16Array$Dart = _;
    DOM$fixClass$Uint16Array(_);
  }
  if ((_ = w.Uint32Array)) {
    w.Uint32Array$Dart = _;
    DOM$fixClass$Uint32Array(_);
  }
  if ((_ = w.Uint8Array)) {
    w.Uint8Array$Dart = _;
    DOM$fixClass$Uint8Array(_);
  }
  if ((_ = w.ValidityState)) {
    w.ValidityState$Dart = _;
    DOM$fixClass$ValidityState(_);
  }
  if ((_ = w.VoidCallback)) {
    w.VoidCallback$Dart = _;
    DOM$fixClass$VoidCallback(_);
  }
  if ((_ = w.WebGLActiveInfo)) {
    w.WebGLActiveInfo$Dart = _;
    DOM$fixClass$WebGLActiveInfo(_);
  }
  if ((_ = w.WebGLBuffer)) {
    w.WebGLBuffer$Dart = _;
    DOM$fixClass$WebGLBuffer(_);
  }
  if ((_ = w.WebGLContextAttributes)) {
    w.WebGLContextAttributes$Dart = _;
    DOM$fixClass$WebGLContextAttributes(_);
  }
  if ((_ = w.WebGLContextEvent)) {
    w.WebGLContextEvent$Dart = _;
    DOM$fixClass$WebGLContextEvent(_);
  }
  if ((_ = w.WebGLDebugRendererInfo)) {
    w.WebGLDebugRendererInfo$Dart = _;
    DOM$fixClass$WebGLDebugRendererInfo(_);
  }
  if ((_ = w.WebGLDebugShaders)) {
    w.WebGLDebugShaders$Dart = _;
    DOM$fixClass$WebGLDebugShaders(_);
  }
  if ((_ = w.WebGLFramebuffer)) {
    w.WebGLFramebuffer$Dart = _;
    DOM$fixClass$WebGLFramebuffer(_);
  }
  if ((_ = w.WebGLProgram)) {
    w.WebGLProgram$Dart = _;
    DOM$fixClass$WebGLProgram(_);
  }
  if ((_ = w.WebGLRenderbuffer)) {
    w.WebGLRenderbuffer$Dart = _;
    DOM$fixClass$WebGLRenderbuffer(_);
  }
  if ((_ = w.WebGLRenderingContext)) {
    w.WebGLRenderingContext$Dart = _;
    DOM$fixClass$WebGLRenderingContext(_);
  }
  if ((_ = w.WebGLShader)) {
    w.WebGLShader$Dart = _;
    DOM$fixClass$WebGLShader(_);
  }
  if ((_ = w.WebGLTexture)) {
    w.WebGLTexture$Dart = _;
    DOM$fixClass$WebGLTexture(_);
  }
  if ((_ = w.WebGLUniformLocation)) {
    w.WebGLUniformLocation$Dart = _;
    DOM$fixClass$WebGLUniformLocation(_);
  }
  if ((_ = w.WebGLVertexArrayObjectOES)) {
    w.WebGLVertexArrayObjectOES$Dart = _;
    DOM$fixClass$WebGLVertexArrayObjectOES(_);
  }
  if ((_ = w.WebKitAnimation)) {
    w.WebKitAnimation$Dart = _;
    DOM$fixClass$WebKitAnimation(_);
  }
  if ((_ = w.WebKitAnimationEvent)) {
    w.WebKitAnimationEvent$Dart = _;
    DOM$fixClass$WebKitAnimationEvent(_);
  }
  if ((_ = w.WebKitAnimationList)) {
    w.WebKitAnimationList$Dart = _;
    DOM$fixClass$WebKitAnimationList(_);
  }
  if ((_ = w.WebKitBlobBuilder)) {
    w.WebKitBlobBuilder$Dart = _;
    DOM$fixClass$WebKitBlobBuilder(_);
  }
  if ((_ = w.WebKitCSSFilterValue)) {
    w.WebKitCSSFilterValue$Dart = _;
    DOM$fixClass$WebKitCSSFilterValue(_);
  }
  if ((_ = w.WebKitCSSKeyframeRule)) {
    w.WebKitCSSKeyframeRule$Dart = _;
    DOM$fixClass$WebKitCSSKeyframeRule(_);
  }
  if ((_ = w.WebKitCSSKeyframesRule)) {
    w.WebKitCSSKeyframesRule$Dart = _;
    DOM$fixClass$WebKitCSSKeyframesRule(_);
  }
  if ((_ = w.WebKitCSSMatrix)) {
    w.WebKitCSSMatrix$Dart = _;
    DOM$fixClass$WebKitCSSMatrix(_);
  }
  if ((_ = w.WebKitCSSTransformValue)) {
    w.WebKitCSSTransformValue$Dart = _;
    DOM$fixClass$WebKitCSSTransformValue(_);
  }
  if ((_ = w.WebKitFlags)) {
    w.WebKitFlags$Dart = _;
    DOM$fixClass$WebKitFlags(_);
  }
  if ((_ = w.WebKitLoseContext)) {
    w.WebKitLoseContext$Dart = _;
    DOM$fixClass$WebKitLoseContext(_);
  }
  if ((_ = w.WebKitMutationObserver)) {
    w.WebKitMutationObserver$Dart = _;
    DOM$fixClass$WebKitMutationObserver(_);
  }
  if ((_ = w.WebKitPoint)) {
    w.WebKitPoint$Dart = _;
    DOM$fixClass$WebKitPoint(_);
  }
  if ((_ = w.WebKitTransitionEvent)) {
    w.WebKitTransitionEvent$Dart = _;
    DOM$fixClass$WebKitTransitionEvent(_);
  }
  if ((_ = w.WebSocket)) {
    w.WebSocket$Dart = _;
    DOM$fixClass$WebSocket(_);
  }
  if ((_ = w.WheelEvent)) {
    w.WheelEvent$Dart = _;
    DOM$fixClass$WheelEvent(_);
  }
  if ((_ = w.Worker)) {
    w.Worker$Dart = _;
    DOM$fixClass$Worker(_);
  }
  if ((_ = w.WorkerContext)) {
    w.WorkerContext$Dart = _;
    DOM$fixClass$WorkerContext(_);
  }
  if ((_ = w.WorkerLocation)) {
    w.WorkerLocation$Dart = _;
    DOM$fixClass$WorkerLocation(_);
  }
  if ((_ = w.WorkerNavigator)) {
    w.WorkerNavigator$Dart = _;
    DOM$fixClass$WorkerNavigator(_);
  }
  if ((_ = w.XMLHttpRequest)) {
    w.XMLHttpRequest$Dart = _;
    DOM$fixClass$XMLHttpRequest(_);
  }
  if ((_ = w.XMLHttpRequestException)) {
    w.XMLHttpRequestException$Dart = _;
    DOM$fixClass$XMLHttpRequestException(_);
  }
  if ((_ = w.XMLHttpRequestProgressEvent)) {
    w.XMLHttpRequestProgressEvent$Dart = _;
    DOM$fixClass$XMLHttpRequestProgressEvent(_);
  }
  if ((_ = w.XMLHttpRequestUpload)) {
    w.XMLHttpRequestUpload$Dart = _;
    DOM$fixClass$XMLHttpRequestUpload(_);
  }
  if ((_ = w.XMLSerializer)) {
    w.XMLSerializer$Dart = _;
    DOM$fixClass$XMLSerializer(_);
  }
  if ((_ = w.XPathEvaluator)) {
    w.XPathEvaluator$Dart = _;
    DOM$fixClass$XPathEvaluator(_);
  }
  if ((_ = w.XPathException)) {
    w.XPathException$Dart = _;
    DOM$fixClass$XPathException(_);
  }
  if ((_ = w.XPathExpression)) {
    w.XPathExpression$Dart = _;
    DOM$fixClass$XPathExpression(_);
  }
  if ((_ = w.XPathNSResolver)) {
    w.XPathNSResolver$Dart = _;
    DOM$fixClass$XPathNSResolver(_);
  }
  if ((_ = w.XPathResult)) {
    w.XPathResult$Dart = _;
    DOM$fixClass$XPathResult(_);
  }
  if ((_ = w.XSLTProcessor)) {
    w.XSLTProcessor$Dart = _;
    DOM$fixClass$XSLTProcessor(_);
  }

  if (tmpLocation) {
    w.Location = tmpLocation;
  }

  // Chrome still uses initWebKitWheelEvent.
  if (w && w.WheelEvent && w.WheelEvent.prototype &&
      !w.WheelEvent.prototype.initWheelEvent) {
    w.WheelEvent.prototype.initWheelEvent = function() {
      return this.initWebKitWheelEvent.apply(this, arguments);
    };
  }


  // Special implementations that fix the prototypes in a new context on the
  // fly.
  // TODO(sra): HTMLFrameElement, HTMLObjectElement
  if (w.HTMLIFrameElement) {
    w.HTMLIFrameElement$Dart = w.HTMLIFrameElement;
    w.HTMLIFrameElement.prototype.contentDocument$getter = function() {
      this.contentWindow$getter();  // Fix bindings in context
      return DOM$EnsureDartNull(this.contentDocument);
    };
    w.HTMLIFrameElement.prototype.contentWindow$getter = function() {
      var window = this.contentWindow;
      if (window) {
        DOM$FixBindings(window);
      }
      return DOM$EnsureDartNull(window);
    };
  }
} // end of DOM$FixBindings

if (this.window) {
  DOM$FixBindings(this.window);

  this.arguments = window;
}

// Declared in src/GlobalProperties.dart
function native__NativeDomGlobalProperties_getWindow() {
  // TODO: Should the window be obtained from an isolate?
  return window;
}

// Declared in src/GlobalProperties.dart
function native__NativeDomGlobalProperties_getDocument() {
  // TODO: Should the window be obtained from an isolate?
  return window.document;
}
