// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

/**
 * @fileoverview Dart externs for DOM runtime.
 * @externs
 */

if (false) {

var dart_dom_externs = function(){};

// Fields placed on DOM objects and JavaScript constructor functions.
dart_dom_externs.prototype._dart;
dart_dom_externs.prototype._dart_class;
dart_dom_externs.prototype._dart_localStorage;

// Fields placed on Dart objects by native code.
dart_dom_externs.prototype.$dom;

// Externs missing from JavaScript back-end.
Window.prototype.webkitRequestAnimationFrame;
Window.prototype.webkitCancelRequestAnimationFrame;
Window.prototype.webkitConvertPointFromPageToNode;
Window.prototype.webkitConvertPointFromNodeToPage;

// Externs for DOM objects.
var dom_externs = function(){};

dom_externs.URL;                        // attribute Document.URL, attribute EventSource.URL, attribute WebSocket.URL
dom_externs.a;                          // attribute SVGMatrix.a, attribute WebKitCSSMatrix.a
dom_externs.aLink;                      // attribute HTMLBodyElement.aLink
dom_externs.abbr;                       // attribute HTMLTableCellElement.abbr
dom_externs.abort;                      // operation FileReader.abort, operation FileWriter.abort, operation IDBTransaction.abort, operation XMLHttpRequest.abort
dom_externs.accept;                     // attribute HTMLInputElement.accept
dom_externs.acceptCharset;              // attribute HTMLFormElement.acceptCharset
dom_externs.acceptNode;                 // operation NodeFilter.acceptNode
dom_externs.accessKey;                  // attribute HTMLAnchorElement.accessKey, attribute HTMLAreaElement.accessKey, attribute HTMLButtonElement.accessKey, attribute HTMLInputElement.accessKey, attribute HTMLLabelElement.accessKey, attribute HTMLLegendElement.accessKey, attribute HTMLTextAreaElement.accessKey
dom_externs.accuracy;                   // attribute Coordinates.accuracy
dom_externs.action;                     // attribute HTMLFormElement.action
dom_externs.activeCues;                 // attribute TextTrack.activeCues
dom_externs.activeElement;              // attribute HTMLDocument.activeElement
dom_externs.activeTexture;              // operation WebGLRenderingContext.activeTexture
dom_externs.add;                        // operation DOMTokenList.add, operation DataTransferItemList.add, operation HTMLSelectElement.add, operation IDBObjectStore.add
dom_externs.addColorStop;               // operation CanvasGradient.addColorStop
dom_externs.addCue;                     // operation TextTrack.addCue
dom_externs.addEventListener;           // operation AbstractWorker.addEventListener, operation DOMApplicationCache.addEventListener, operation DOMWindow.addEventListener, operation EventSource.addEventListener, operation EventTarget.addEventListener, operation IDBDatabase.addEventListener, operation IDBRequest.addEventListener, operation IDBTransaction.addEventListener, operation MessagePort.addEventListener, operation Node.addEventListener, operation Notification.addEventListener, operation SVGElementInstance.addEventListener, operation WebSocket.addEventListener, operation WorkerContext.addEventListener, operation XMLHttpRequest.addEventListener, operation XMLHttpRequestUpload.addEventListener
dom_externs.addListener;                // operation MediaQueryList.addListener
dom_externs.addRange;                   // operation DOMSelection.addRange
dom_externs.addRule;                    // operation CSSStyleSheet.addRule
dom_externs.addedNodes;                 // attribute MutationRecord.addedNodes
dom_externs.adoptNode;                  // operation Document.adoptNode
dom_externs.alert;                      // operation DOMWindow.alert
dom_externs.align;                      // attribute HTMLAppletElement.align, attribute HTMLDivElement.align, attribute HTMLEmbedElement.align, attribute HTMLHRElement.align, attribute HTMLHeadingElement.align, attribute HTMLIFrameElement.align, attribute HTMLImageElement.align, attribute HTMLInputElement.align, attribute HTMLLegendElement.align, attribute HTMLObjectElement.align, attribute HTMLParagraphElement.align, attribute HTMLTableCaptionElement.align, attribute HTMLTableCellElement.align, attribute HTMLTableColElement.align, attribute HTMLTableElement.align, attribute HTMLTableRowElement.align, attribute HTMLTableSectionElement.align, attribute SVGPreserveAspectRatio.align
dom_externs.alignment;                  // attribute TextTrackCue.alignment
dom_externs.alinkColor;                 // attribute HTMLDocument.alinkColor
dom_externs.all;                        // attribute HTMLDocument.all
dom_externs.alpha;                      // attribute DeviceOrientationEvent.alpha, attribute WebGLContextAttributes.alpha
dom_externs.alt;                        // attribute HTMLAppletElement.alt, attribute HTMLAreaElement.alt, attribute HTMLImageElement.alt, attribute HTMLInputElement.alt
dom_externs.altGraphKey;                // attribute KeyboardEvent.altGraphKey
dom_externs.altKey;                     // attribute KeyboardEvent.altKey, attribute MouseEvent.altKey, attribute TouchEvent.altKey, attribute WheelEvent.altKey
dom_externs.altitude;                   // attribute Coordinates.altitude
dom_externs.altitudeAccuracy;           // attribute Coordinates.altitudeAccuracy
dom_externs.amplitude;                  // attribute SVGComponentTransferFunctionElement.amplitude
dom_externs.anchorNode;                 // attribute DOMSelection.anchorNode
dom_externs.anchorOffset;               // attribute DOMSelection.anchorOffset
dom_externs.anchors;                    // attribute Document.anchors
dom_externs.angle;                      // attribute SVGPathSegArcAbs.angle, attribute SVGPathSegArcRel.angle, attribute SVGTransform.angle
dom_externs.animVal;                    // attribute SVGAnimatedAngle.animVal, attribute SVGAnimatedBoolean.animVal, attribute SVGAnimatedEnumeration.animVal, attribute SVGAnimatedInteger.animVal, attribute SVGAnimatedLength.animVal, attribute SVGAnimatedLengthList.animVal, attribute SVGAnimatedNumber.animVal, attribute SVGAnimatedNumberList.animVal, attribute SVGAnimatedPreserveAspectRatio.animVal, attribute SVGAnimatedRect.animVal, attribute SVGAnimatedString.animVal, attribute SVGAnimatedTransformList.animVal
dom_externs.animatedInstanceRoot;       // attribute SVGUseElement.animatedInstanceRoot
dom_externs.animatedNormalizedPathSegList;  // attribute SVGPathElement.animatedNormalizedPathSegList
dom_externs.animatedPathSegList;        // attribute SVGPathElement.animatedPathSegList
dom_externs.animatedPoints;             // attribute SVGPolygonElement.animatedPoints, attribute SVGPolylineElement.animatedPoints
dom_externs.animationName;              // attribute WebKitAnimationEvent.animationName
dom_externs.animationsPaused;           // operation SVGSVGElement.animationsPaused
dom_externs.antialias;                  // attribute WebGLContextAttributes.antialias
dom_externs.appCodeName;                // attribute Navigator.appCodeName
dom_externs.appName;                    // attribute Navigator.appName, attribute WorkerNavigator.appName
dom_externs.appVersion;                 // attribute Navigator.appVersion, attribute WorkerNavigator.appVersion
dom_externs.append;                     // operation DOMFormData.append, operation WebKitBlobBuilder.append
dom_externs.appendChild;                // operation Node.appendChild
dom_externs.appendData;                 // operation CharacterData.appendData
dom_externs.appendItem;                 // operation SVGLengthList.appendItem, operation SVGNumberList.appendItem, operation SVGPathSegList.appendItem, operation SVGPointList.appendItem, operation SVGStringList.appendItem, operation SVGTransformList.appendItem
dom_externs.appendMedium;               // operation MediaList.appendMedium
dom_externs.applets;                    // attribute Document.applets
dom_externs.applicationCache;           // attribute DOMWindow.applicationCache
dom_externs.arc;                        // operation CanvasRenderingContext2D.arc
dom_externs.arcTo;                      // operation CanvasRenderingContext2D.arcTo
dom_externs.archive;                    // attribute HTMLAppletElement.archive, attribute HTMLObjectElement.archive
dom_externs.areas;                      // attribute HTMLMapElement.areas
dom_externs.asBlob;                     // attribute XMLHttpRequest.asBlob
dom_externs.assertCondition;            // operation Console.assertCondition
dom_externs.assign;                     // operation Location.assign
dom_externs.async;                      // attribute HTMLScriptElement.async
dom_externs.atob;                       // operation DOMWindow.atob
dom_externs.attachShader;               // operation WebGLRenderingContext.attachShader
dom_externs.attrChange;                 // attribute MutationEvent.attrChange
dom_externs.attrName;                   // attribute MutationEvent.attrName
dom_externs.attributeName;              // attribute MutationRecord.attributeName
dom_externs.attributeNamespace;         // attribute MutationRecord.attributeNamespace
dom_externs.attributes;                 // attribute Node.attributes
dom_externs.autocomplete;               // attribute HTMLFormElement.autocomplete, attribute HTMLInputElement.autocomplete
dom_externs.autofocus;                  // attribute HTMLButtonElement.autofocus, attribute HTMLInputElement.autofocus, attribute HTMLKeygenElement.autofocus, attribute HTMLSelectElement.autofocus, attribute HTMLTextAreaElement.autofocus
dom_externs.autoplay;                   // attribute HTMLMediaElement.autoplay
dom_externs.availHeight;                // attribute Screen.availHeight
dom_externs.availLeft;                  // attribute Screen.availLeft
dom_externs.availTop;                   // attribute Screen.availTop
dom_externs.availWidth;                 // attribute Screen.availWidth
dom_externs.axis;                       // attribute HTMLTableCellElement.axis
dom_externs.azimuth;                    // attribute SVGFEDistantLightElement.azimuth
dom_externs.b;                          // attribute SVGMatrix.b, attribute WebKitCSSMatrix.b
dom_externs.back;                       // operation History.back
dom_externs.background;                 // attribute HTMLBodyElement.background
dom_externs.baseFrequencyX;             // attribute SVGFETurbulenceElement.baseFrequencyX
dom_externs.baseFrequencyY;             // attribute SVGFETurbulenceElement.baseFrequencyY
dom_externs.baseNode;                   // attribute DOMSelection.baseNode
dom_externs.baseOffset;                 // attribute DOMSelection.baseOffset
dom_externs.baseURI;                    // attribute Node.baseURI
dom_externs.baseVal;                    // attribute SVGAnimatedAngle.baseVal, attribute SVGAnimatedBoolean.baseVal, attribute SVGAnimatedEnumeration.baseVal, attribute SVGAnimatedInteger.baseVal, attribute SVGAnimatedLength.baseVal, attribute SVGAnimatedLengthList.baseVal, attribute SVGAnimatedNumber.baseVal, attribute SVGAnimatedNumberList.baseVal, attribute SVGAnimatedPreserveAspectRatio.baseVal, attribute SVGAnimatedRect.baseVal, attribute SVGAnimatedString.baseVal, attribute SVGAnimatedTransformList.baseVal
dom_externs.beginElement;               // operation ElementTimeControl.beginElement, operation SVGAnimationElement.beginElement
dom_externs.beginElementAt;             // operation ElementTimeControl.beginElementAt, operation SVGAnimationElement.beginElementAt
dom_externs.beginPath;                  // operation CanvasRenderingContext2D.beginPath
dom_externs.behavior;                   // attribute HTMLMarqueeElement.behavior
dom_externs.beta;                       // attribute DeviceOrientationEvent.beta
dom_externs.bezierCurveTo;              // operation CanvasRenderingContext2D.bezierCurveTo
dom_externs.bgColor;                    // attribute HTMLBodyElement.bgColor, attribute HTMLDocument.bgColor, attribute HTMLMarqueeElement.bgColor, attribute HTMLTableCellElement.bgColor, attribute HTMLTableElement.bgColor, attribute HTMLTableRowElement.bgColor
dom_externs.bias;                       // attribute SVGFEConvolveMatrixElement.bias
dom_externs.binaryType;                 // attribute WebSocket.binaryType
dom_externs.bindAttribLocation;         // operation WebGLRenderingContext.bindAttribLocation
dom_externs.bindBuffer;                 // operation WebGLRenderingContext.bindBuffer
dom_externs.bindFramebuffer;            // operation WebGLRenderingContext.bindFramebuffer
dom_externs.bindRenderbuffer;           // operation WebGLRenderingContext.bindRenderbuffer
dom_externs.bindTexture;                // operation WebGLRenderingContext.bindTexture
dom_externs.bindVertexArrayOES;         // operation OESVertexArrayObject.bindVertexArrayOES
dom_externs.blendColor;                 // operation WebGLRenderingContext.blendColor
dom_externs.blendEquation;              // operation WebGLRenderingContext.blendEquation
dom_externs.blendEquationSeparate;      // operation WebGLRenderingContext.blendEquationSeparate
dom_externs.blendFunc;                  // operation WebGLRenderingContext.blendFunc
dom_externs.blendFuncSeparate;          // operation WebGLRenderingContext.blendFuncSeparate
dom_externs.blue;                       // attribute RGBColor.blue
dom_externs.blur;                       // operation DOMWindow.blur, operation Element.blur
dom_externs.body;                       // attribute Document.body
dom_externs.booleanValue;               // attribute XPathResult.booleanValue
dom_externs.border;                     // attribute HTMLImageElement.border, attribute HTMLObjectElement.border, attribute HTMLTableElement.border
dom_externs.bottom;                     // attribute ClientRect.bottom, attribute Rect.bottom
dom_externs.bound;                      // operation IDBKeyRange.bound
dom_externs.bringToFront;               // operation InspectorFrontendHost.bringToFront
dom_externs.btoa;                       // operation DOMWindow.btoa
dom_externs.bubbles;                    // attribute Event.bubbles
dom_externs.buffer;                     // attribute ArrayBufferView.buffer
dom_externs.bufferData;                 // operation WebGLRenderingContext.bufferData
dom_externs.bufferSubData;              // operation WebGLRenderingContext.bufferSubData
dom_externs.buffered;                   // attribute HTMLMediaElement.buffered
dom_externs.bufferedAmount;             // attribute WebSocket.bufferedAmount
dom_externs.button;                     // attribute MouseEvent.button
dom_externs.byteLength;                 // attribute ArrayBuffer.byteLength, attribute ArrayBufferView.byteLength
dom_externs.byteOffset;                 // attribute ArrayBufferView.byteOffset
dom_externs.c;                          // attribute SVGMatrix.c, attribute WebKitCSSMatrix.c
dom_externs.callUID;                    // attribute ScriptProfileNode.callUID
dom_externs.caller;                     // attribute JavaScriptCallFrame.caller
dom_externs.canPlayType;                // operation HTMLMediaElement.canPlayType
dom_externs.cancel;                     // operation Notification.cancel
dom_externs.cancelBubble;               // attribute Event.cancelBubble
dom_externs.cancelable;                 // attribute Event.cancelable
dom_externs.canvas;                     // attribute CanvasRenderingContext.canvas
dom_externs.caption;                    // attribute HTMLTableElement.caption
dom_externs.captureEvents;              // operation DOMWindow.captureEvents, operation HTMLDocument.captureEvents
dom_externs.caretRangeFromPoint;        // operation Document.caretRangeFromPoint
dom_externs.cellIndex;                  // attribute HTMLTableCellElement.cellIndex
dom_externs.cellPadding;                // attribute HTMLTableElement.cellPadding
dom_externs.cellSpacing;                // attribute HTMLTableElement.cellSpacing
dom_externs.cells;                      // attribute HTMLTableRowElement.cells
dom_externs.ch;                         // attribute HTMLTableCellElement.ch, attribute HTMLTableColElement.ch, attribute HTMLTableRowElement.ch, attribute HTMLTableSectionElement.ch
dom_externs.chOff;                      // attribute HTMLTableCellElement.chOff, attribute HTMLTableColElement.chOff, attribute HTMLTableRowElement.chOff, attribute HTMLTableSectionElement.chOff
dom_externs.challenge;                  // attribute HTMLKeygenElement.challenge
dom_externs.changeVersion;              // operation Database.changeVersion, operation DatabaseSync.changeVersion
dom_externs.changedTouches;             // attribute TouchEvent.changedTouches
dom_externs.charCode;                   // attribute UIEvent.charCode
dom_externs.characterSet;               // attribute Document.characterSet
dom_externs.charset;                    // attribute Document.charset, attribute HTMLAnchorElement.charset, attribute HTMLLinkElement.charset, attribute HTMLScriptElement.charset
dom_externs.checkEnclosure;             // operation SVGSVGElement.checkEnclosure
dom_externs.checkFramebufferStatus;     // operation WebGLRenderingContext.checkFramebufferStatus
dom_externs.checkIntersection;          // operation SVGSVGElement.checkIntersection
dom_externs.checkPermission;            // operation NotificationCenter.checkPermission
dom_externs.checkValidity;              // operation HTMLButtonElement.checkValidity, operation HTMLFieldSetElement.checkValidity, operation HTMLFormElement.checkValidity, operation HTMLInputElement.checkValidity, operation HTMLKeygenElement.checkValidity, operation HTMLObjectElement.checkValidity, operation HTMLOutputElement.checkValidity, operation HTMLSelectElement.checkValidity, operation HTMLTextAreaElement.checkValidity
dom_externs.checked;                    // attribute HTMLInputElement.checked
dom_externs.childElementCount;          // attribute Element.childElementCount, attribute ElementTraversal.childElementCount
dom_externs.childNodes;                 // attribute Node.childNodes, attribute SVGElementInstance.childNodes
dom_externs.children;                   // attribute HTMLElement.children, attribute ScriptProfileNode.children
dom_externs.cite;                       // attribute HTMLModElement.cite, attribute HTMLQuoteElement.cite
dom_externs.classList;                  // attribute HTMLElement.classList
dom_externs.className;                  // attribute HTMLElement.className, attribute SVGAElement.className, attribute SVGCircleElement.className, attribute SVGClipPathElement.className, attribute SVGDefsElement.className, attribute SVGDescElement.className, attribute SVGEllipseElement.className, attribute SVGFEBlendElement.className, attribute SVGFEColorMatrixElement.className, attribute SVGFEComponentTransferElement.className, attribute SVGFECompositeElement.className, attribute SVGFEConvolveMatrixElement.className, attribute SVGFEDiffuseLightingElement.className, attribute SVGFEDisplacementMapElement.className, attribute SVGFEDropShadowElement.className, attribute SVGFEFloodElement.className, attribute SVGFEGaussianBlurElement.className, attribute SVGFEImageElement.className, attribute SVGFEMergeElement.className, attribute SVGFEMorphologyElement.className, attribute SVGFEOffsetElement.className, attribute SVGFESpecularLightingElement.className, attribute SVGFETileElement.className, attribute SVGFETurbulenceElement.className, attribute SVGFilterElement.className, attribute SVGForeignObjectElement.className, attribute SVGGElement.className, attribute SVGGlyphRefElement.className, attribute SVGGradientElement.className, attribute SVGImageElement.className, attribute SVGLineElement.className, attribute SVGMarkerElement.className, attribute SVGMaskElement.className, attribute SVGPathElement.className, attribute SVGPatternElement.className, attribute SVGPolygonElement.className, attribute SVGPolylineElement.className, attribute SVGRectElement.className, attribute SVGSVGElement.className, attribute SVGStopElement.className, attribute SVGStylable.className, attribute SVGSwitchElement.className, attribute SVGSymbolElement.className, attribute SVGTextContentElement.className, attribute SVGTitleElement.className, attribute SVGUseElement.className
dom_externs.clear;                      // operation DataTransferItemList.clear, attribute HTMLBRElement.clear, operation HTMLDocument.clear, operation IDBObjectStore.clear, operation SVGLengthList.clear, operation SVGNumberList.clear, operation SVGPathSegList.clear, operation SVGPointList.clear, operation SVGStringList.clear, operation SVGTransformList.clear, operation Storage.clear, operation WebGLRenderingContext.clear
dom_externs.clearColor;                 // operation WebGLRenderingContext.clearColor
dom_externs.clearConsoleMessages;       // operation InjectedScriptHost.clearConsoleMessages
dom_externs.clearData;                  // operation Clipboard.clearData
dom_externs.clearDepth;                 // operation WebGLRenderingContext.clearDepth
dom_externs.clearInterval;              // operation DOMWindow.clearInterval, operation WorkerContext.clearInterval
dom_externs.clearParameters;            // operation XSLTProcessor.clearParameters
dom_externs.clearRect;                  // operation CanvasRenderingContext2D.clearRect
dom_externs.clearShadow;                // operation CanvasRenderingContext2D.clearShadow
dom_externs.clearStencil;               // operation WebGLRenderingContext.clearStencil
dom_externs.clearTimeout;               // operation DOMWindow.clearTimeout, operation WorkerContext.clearTimeout
dom_externs.clearWatch;                 // operation Geolocation.clearWatch
dom_externs.click;                      // operation HTMLButtonElement.click, operation HTMLInputElement.click
dom_externs.clientHeight;               // attribute Element.clientHeight
dom_externs.clientInformation;          // attribute DOMWindow.clientInformation
dom_externs.clientLeft;                 // attribute Element.clientLeft
dom_externs.clientTop;                  // attribute Element.clientTop
dom_externs.clientWidth;                // attribute Element.clientWidth
dom_externs.clientX;                    // attribute MouseEvent.clientX, attribute Touch.clientX, attribute WheelEvent.clientX
dom_externs.clientY;                    // attribute MouseEvent.clientY, attribute Touch.clientY, attribute WheelEvent.clientY
dom_externs.clip;                       // operation CanvasRenderingContext2D.clip
dom_externs.clipPathUnits;              // attribute SVGClipPathElement.clipPathUnits
dom_externs.clipboardData;              // attribute Event.clipboardData
dom_externs.cloneContents;              // operation Range.cloneContents
dom_externs.cloneNode;                  // operation Node.cloneNode
dom_externs.cloneRange;                 // operation Range.cloneRange
dom_externs.close;                      // operation DOMWindow.close, operation EventSource.close, operation HTMLDocument.close, operation IDBDatabase.close, operation MessagePort.close, operation WebSocket.close, operation WorkerContext.close
dom_externs.closePath;                  // operation CanvasRenderingContext2D.closePath
dom_externs.closeWindow;                // operation InspectorFrontendHost.closeWindow
dom_externs.closed;                     // attribute DOMWindow.closed
dom_externs.cmp;                        // operation IDBFactory.cmp
dom_externs.code;                       // attribute CloseEvent.code, attribute DOMException.code, attribute EventException.code, attribute FileError.code, attribute FileException.code, attribute HTMLAppletElement.code, attribute HTMLObjectElement.code, attribute IDBDatabaseError.code, attribute IDBDatabaseException.code, attribute MediaError.code, attribute NavigatorUserMediaError.code, attribute OperationNotAllowedException.code, attribute PositionError.code, attribute RangeException.code, attribute SQLError.code, attribute SQLException.code, attribute SVGException.code, attribute XMLHttpRequestException.code, attribute XPathException.code
dom_externs.codeBase;                   // attribute HTMLAppletElement.codeBase, attribute HTMLObjectElement.codeBase
dom_externs.codeType;                   // attribute HTMLObjectElement.codeType
dom_externs.colSpan;                    // attribute HTMLTableCellElement.colSpan
dom_externs.collapse;                   // operation DOMSelection.collapse, operation Range.collapse
dom_externs.collapseToEnd;              // operation DOMSelection.collapseToEnd
dom_externs.collapseToStart;            // operation DOMSelection.collapseToStart
dom_externs.collapsed;                  // attribute Range.collapsed
dom_externs.color;                      // attribute HTMLBaseFontElement.color, attribute HTMLFontElement.color
dom_externs.colorDepth;                 // attribute Screen.colorDepth
dom_externs.colorMask;                  // operation WebGLRenderingContext.colorMask
dom_externs.colorType;                  // attribute SVGColor.colorType
dom_externs.cols;                       // attribute HTMLFrameSetElement.cols, attribute HTMLTextAreaElement.cols
dom_externs.column;                     // attribute JavaScriptCallFrame.column
dom_externs.commonAncestorContainer;    // attribute Range.commonAncestorContainer
dom_externs.compact;                    // attribute HTMLDListElement.compact, attribute HTMLDirectoryElement.compact, attribute HTMLMenuElement.compact, attribute HTMLOListElement.compact, attribute HTMLUListElement.compact
dom_externs.compareDocumentPosition;    // operation Node.compareDocumentPosition
dom_externs.compareNode;                // operation Range.compareNode
dom_externs.comparePoint;               // operation Range.comparePoint
dom_externs.compatMode;                 // attribute Document.compatMode, attribute HTMLDocument.compatMode
dom_externs.compileShader;              // operation WebGLRenderingContext.compileShader
dom_externs.complete;                   // attribute HTMLImageElement.complete
dom_externs.confidence;                 // attribute SpeechInputResult.confidence
dom_externs.confirm;                    // operation DOMWindow.confirm
dom_externs.connectEnd;                 // attribute PerformanceTiming.connectEnd
dom_externs.connectStart;               // attribute PerformanceTiming.connectStart
dom_externs.console;                    // attribute DOMWindow.console
dom_externs.consolidate;                // operation SVGTransformList.consolidate
dom_externs.contains;                   // operation DOMTokenList.contains, operation Node.contains
dom_externs.containsNode;               // operation DOMSelection.containsNode
dom_externs.content;                    // attribute HTMLMetaElement.content
dom_externs.contentDocument;            // attribute HTMLFrameElement.contentDocument, attribute HTMLIFrameElement.contentDocument, attribute HTMLObjectElement.contentDocument
dom_externs.contentEditable;            // attribute HTMLElement.contentEditable
dom_externs.contentScriptType;          // attribute SVGSVGElement.contentScriptType
dom_externs.contentStyleType;           // attribute SVGSVGElement.contentStyleType
dom_externs.contentWindow;              // attribute HTMLFrameElement.contentWindow, attribute HTMLIFrameElement.contentWindow
dom_externs.continueFunction;           // operation IDBCursor.continueFunction
dom_externs.control;                    // attribute HTMLLabelElement.control
dom_externs.controls;                   // attribute HTMLMediaElement.controls
dom_externs.convertToSpecifiedUnits;    // operation SVGAngle.convertToSpecifiedUnits, operation SVGLength.convertToSpecifiedUnits
dom_externs.cookie;                     // attribute Document.cookie
dom_externs.cookieEnabled;              // attribute Navigator.cookieEnabled
dom_externs.coords;                     // attribute Geoposition.coords, attribute HTMLAnchorElement.coords, attribute HTMLAreaElement.coords
dom_externs.copyTexImage2D;             // operation WebGLRenderingContext.copyTexImage2D
dom_externs.copyTexSubImage2D;          // operation WebGLRenderingContext.copyTexSubImage2D
dom_externs.copyText;                   // operation InjectedScriptHost.copyText, operation InspectorFrontendHost.copyText
dom_externs.copyTo;                     // operation Entry.copyTo, operation EntrySync.copyTo
dom_externs.correspondingElement;       // attribute SVGElementInstance.correspondingElement
dom_externs.correspondingUseElement;    // attribute SVGElementInstance.correspondingUseElement
dom_externs.count;                      // operation Console.count
dom_externs.create;                     // attribute WebKitFlags.create
dom_externs.createAttribute;            // operation Document.createAttribute
dom_externs.createAttributeNS;          // operation Document.createAttributeNS
dom_externs.createBuffer;               // operation WebGLRenderingContext.createBuffer
dom_externs.createCDATASection;         // operation Document.createCDATASection
dom_externs.createCSSStyleSheet;        // operation DOMImplementation.createCSSStyleSheet
dom_externs.createCaption;              // operation HTMLTableElement.createCaption
dom_externs.createComment;              // operation Document.createComment
dom_externs.createContextualFragment;   // operation Range.createContextualFragment
dom_externs.createDocument;             // operation DOMImplementation.createDocument
dom_externs.createDocumentFragment;     // operation Document.createDocumentFragment
dom_externs.createDocumentType;         // operation DOMImplementation.createDocumentType
dom_externs.createElement;              // operation Document.createElement
dom_externs.createElementNS;            // operation Document.createElementNS
dom_externs.createEntityReference;      // operation Document.createEntityReference
dom_externs.createEvent;                // operation Document.createEvent, operation SVGDocument.createEvent
dom_externs.createExpression;           // operation Document.createExpression, operation XPathEvaluator.createExpression
dom_externs.createFramebuffer;          // operation WebGLRenderingContext.createFramebuffer
dom_externs.createHTMLDocument;         // operation DOMImplementation.createHTMLDocument
dom_externs.createHTMLNotification;     // operation NotificationCenter.createHTMLNotification
dom_externs.createImageData;            // operation CanvasRenderingContext2D.createImageData
dom_externs.createIndex;                // operation IDBObjectStore.createIndex
dom_externs.createLinearGradient;       // operation CanvasRenderingContext2D.createLinearGradient
dom_externs.createNSResolver;           // operation Document.createNSResolver, operation XPathEvaluator.createNSResolver
dom_externs.createNodeIterator;         // operation Document.createNodeIterator
dom_externs.createNotification;         // operation NotificationCenter.createNotification
dom_externs.createObjectStore;          // operation IDBDatabase.createObjectStore
dom_externs.createObjectURL;            // operation DOMURL.createObjectURL
dom_externs.createPattern;              // operation CanvasRenderingContext2D.createPattern
dom_externs.createProcessingInstruction;  // operation Document.createProcessingInstruction
dom_externs.createProgram;              // operation WebGLRenderingContext.createProgram
dom_externs.createRadialGradient;       // operation CanvasRenderingContext2D.createRadialGradient
dom_externs.createRange;                // operation Document.createRange
dom_externs.createReader;               // operation DirectoryEntry.createReader, operation DirectoryEntrySync.createReader
dom_externs.createRenderbuffer;         // operation WebGLRenderingContext.createRenderbuffer
dom_externs.createSVGAngle;             // operation SVGSVGElement.createSVGAngle
dom_externs.createSVGLength;            // operation SVGSVGElement.createSVGLength
dom_externs.createSVGMatrix;            // operation SVGSVGElement.createSVGMatrix
dom_externs.createSVGNumber;            // operation SVGSVGElement.createSVGNumber
dom_externs.createSVGPathSegArcAbs;     // operation SVGPathElement.createSVGPathSegArcAbs
dom_externs.createSVGPathSegArcRel;     // operation SVGPathElement.createSVGPathSegArcRel
dom_externs.createSVGPathSegClosePath;  // operation SVGPathElement.createSVGPathSegClosePath
dom_externs.createSVGPathSegCurvetoCubicAbs;  // operation SVGPathElement.createSVGPathSegCurvetoCubicAbs
dom_externs.createSVGPathSegCurvetoCubicRel;  // operation SVGPathElement.createSVGPathSegCurvetoCubicRel
dom_externs.createSVGPathSegCurvetoCubicSmoothAbs;  // operation SVGPathElement.createSVGPathSegCurvetoCubicSmoothAbs
dom_externs.createSVGPathSegCurvetoCubicSmoothRel;  // operation SVGPathElement.createSVGPathSegCurvetoCubicSmoothRel
dom_externs.createSVGPathSegCurvetoQuadraticAbs;  // operation SVGPathElement.createSVGPathSegCurvetoQuadraticAbs
dom_externs.createSVGPathSegCurvetoQuadraticRel;  // operation SVGPathElement.createSVGPathSegCurvetoQuadraticRel
dom_externs.createSVGPathSegCurvetoQuadraticSmoothAbs;  // operation SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothAbs
dom_externs.createSVGPathSegCurvetoQuadraticSmoothRel;  // operation SVGPathElement.createSVGPathSegCurvetoQuadraticSmoothRel
dom_externs.createSVGPathSegLinetoAbs;  // operation SVGPathElement.createSVGPathSegLinetoAbs
dom_externs.createSVGPathSegLinetoHorizontalAbs;  // operation SVGPathElement.createSVGPathSegLinetoHorizontalAbs
dom_externs.createSVGPathSegLinetoHorizontalRel;  // operation SVGPathElement.createSVGPathSegLinetoHorizontalRel
dom_externs.createSVGPathSegLinetoRel;  // operation SVGPathElement.createSVGPathSegLinetoRel
dom_externs.createSVGPathSegLinetoVerticalAbs;  // operation SVGPathElement.createSVGPathSegLinetoVerticalAbs
dom_externs.createSVGPathSegLinetoVerticalRel;  // operation SVGPathElement.createSVGPathSegLinetoVerticalRel
dom_externs.createSVGPathSegMovetoAbs;  // operation SVGPathElement.createSVGPathSegMovetoAbs
dom_externs.createSVGPathSegMovetoRel;  // operation SVGPathElement.createSVGPathSegMovetoRel
dom_externs.createSVGPoint;             // operation SVGSVGElement.createSVGPoint
dom_externs.createSVGRect;              // operation SVGSVGElement.createSVGRect
dom_externs.createSVGTransform;         // operation SVGSVGElement.createSVGTransform
dom_externs.createSVGTransformFromMatrix;  // operation SVGSVGElement.createSVGTransformFromMatrix, operation SVGTransformList.createSVGTransformFromMatrix
dom_externs.createShader;               // operation WebGLRenderingContext.createShader
dom_externs.createTFoot;                // operation HTMLTableElement.createTFoot
dom_externs.createTHead;                // operation HTMLTableElement.createTHead
dom_externs.createTextNode;             // operation Document.createTextNode
dom_externs.createTexture;              // operation WebGLRenderingContext.createTexture
dom_externs.createTreeWalker;           // operation Document.createTreeWalker
dom_externs.createVertexArrayOES;       // operation OESVertexArrayObject.createVertexArrayOES
dom_externs.createWriter;               // operation FileEntry.createWriter, operation FileEntrySync.createWriter
dom_externs.crossOrigin;                // attribute HTMLImageElement.crossOrigin
dom_externs.crypto;                     // attribute DOMWindow.crypto
dom_externs.cssRules;                   // attribute CSSMediaRule.cssRules, attribute CSSStyleSheet.cssRules, attribute WebKitCSSKeyframesRule.cssRules
dom_externs.cssText;                    // attribute CSSRule.cssText, attribute CSSStyleDeclaration.cssText, attribute CSSValue.cssText
dom_externs.cssValueType;               // attribute CSSValue.cssValueType
dom_externs.ctrlKey;                    // attribute KeyboardEvent.ctrlKey, attribute MouseEvent.ctrlKey, attribute TouchEvent.ctrlKey, attribute WheelEvent.ctrlKey
dom_externs.cues;                       // attribute TextTrack.cues
dom_externs.cullFace;                   // operation WebGLRenderingContext.cullFace
dom_externs.currentNode;                // attribute TreeWalker.currentNode
dom_externs.currentScale;               // attribute SVGSVGElement.currentScale
dom_externs.currentSrc;                 // attribute HTMLMediaElement.currentSrc
dom_externs.currentTarget;              // attribute Event.currentTarget
dom_externs.currentTime;                // attribute HTMLMediaElement.currentTime
dom_externs.currentTranslate;           // attribute SVGSVGElement.currentTranslate
dom_externs.customError;                // attribute ValidityState.customError
dom_externs.cx;                         // attribute SVGCircleElement.cx, attribute SVGEllipseElement.cx, attribute SVGRadialGradientElement.cx
dom_externs.cy;                         // attribute SVGCircleElement.cy, attribute SVGEllipseElement.cy, attribute SVGRadialGradientElement.cy
dom_externs.d;                          // attribute SVGMatrix.d, attribute WebKitCSSMatrix.d
dom_externs.data;                       // attribute CharacterData.data, attribute CompositionEvent.data, attribute HTMLObjectElement.data, attribute ImageData.data, attribute MessageEvent.data, attribute ProcessingInstruction.data, attribute TextEvent.data
dom_externs.dataTransfer;               // attribute MouseEvent.dataTransfer
dom_externs.databaseId;                 // operation InjectedScriptHost.databaseId
dom_externs.dateTime;                   // attribute HTMLModElement.dateTime
dom_externs.db;                         // attribute IDBTransaction.db
dom_externs.debug;                      // operation Console.debug
dom_externs.declare;                    // attribute HTMLObjectElement.declare
dom_externs.defaultCharset;             // attribute Document.defaultCharset
dom_externs.defaultChecked;             // attribute HTMLInputElement.defaultChecked
dom_externs.defaultMuted;               // attribute HTMLMediaElement.defaultMuted
dom_externs.defaultPlaybackRate;        // attribute HTMLMediaElement.defaultPlaybackRate
dom_externs.defaultPrevented;           // attribute Event.defaultPrevented
dom_externs.defaultSelected;            // attribute HTMLOptionElement.defaultSelected
dom_externs.defaultStatus;              // attribute DOMWindow.defaultStatus
dom_externs.defaultValue;               // attribute HTMLInputElement.defaultValue, attribute HTMLOutputElement.defaultValue, attribute HTMLTextAreaElement.defaultValue
dom_externs.defaultView;                // attribute Document.defaultView
dom_externs.defaultstatus;              // attribute DOMWindow.defaultstatus
dom_externs.defer;                      // attribute HTMLScriptElement.defer
dom_externs.delay;                      // attribute WebKitAnimation.delay
dom_externs.deleteBuffer;               // operation WebGLRenderingContext.deleteBuffer
dom_externs.deleteCaption;              // operation HTMLTableElement.deleteCaption
dom_externs.deleteCell;                 // operation HTMLTableRowElement.deleteCell
dom_externs.deleteContents;             // operation Range.deleteContents
dom_externs.deleteData;                 // operation CharacterData.deleteData
dom_externs.deleteDatabase;             // operation IDBFactory.deleteDatabase
dom_externs.deleteFramebuffer;          // operation WebGLRenderingContext.deleteFramebuffer
dom_externs.deleteFromDocument;         // operation DOMSelection.deleteFromDocument
dom_externs.deleteFunction;             // operation IDBCursor.deleteFunction, operation IDBObjectStore.deleteFunction
dom_externs.deleteIndex;                // operation IDBObjectStore.deleteIndex
dom_externs.deleteMedium;               // operation MediaList.deleteMedium
dom_externs.deleteObjectStore;          // operation IDBDatabase.deleteObjectStore
dom_externs.deleteProgram;              // operation WebGLRenderingContext.deleteProgram
dom_externs.deleteRenderbuffer;         // operation WebGLRenderingContext.deleteRenderbuffer
dom_externs.deleteRow;                  // operation HTMLTableElement.deleteRow, operation HTMLTableSectionElement.deleteRow
dom_externs.deleteRule;                 // operation CSSMediaRule.deleteRule, operation CSSStyleSheet.deleteRule, operation WebKitCSSKeyframesRule.deleteRule
dom_externs.deleteShader;               // operation WebGLRenderingContext.deleteShader
dom_externs.deleteTFoot;                // operation HTMLTableElement.deleteTFoot
dom_externs.deleteTHead;                // operation HTMLTableElement.deleteTHead
dom_externs.deleteTexture;              // operation WebGLRenderingContext.deleteTexture
dom_externs.deleteVertexArrayOES;       // operation OESVertexArrayObject.deleteVertexArrayOES
dom_externs.depth;                      // attribute WebGLContextAttributes.depth
dom_externs.depthFunc;                  // operation WebGLRenderingContext.depthFunc
dom_externs.depthMask;                  // operation WebGLRenderingContext.depthMask
dom_externs.depthRange;                 // operation WebGLRenderingContext.depthRange
dom_externs.description;                // attribute DOMMimeType.description, attribute DOMPlugin.description
dom_externs.deselectAll;                // operation SVGSVGElement.deselectAll
dom_externs.designMode;                 // attribute HTMLDocument.designMode
dom_externs.detach;                     // operation NodeIterator.detach, operation Range.detach
dom_externs.detachShader;               // operation WebGLRenderingContext.detachShader
dom_externs.detail;                     // attribute CustomEvent.detail, attribute UIEvent.detail
dom_externs.devicePixelRatio;           // attribute DOMWindow.devicePixelRatio
dom_externs.diffuseConstant;            // attribute SVGFEDiffuseLightingElement.diffuseConstant
dom_externs.dir;                        // operation Console.dir, attribute HTMLDocument.dir, attribute HTMLElement.dir, attribute Notification.dir
dom_externs.direction;                  // attribute HTMLMarqueeElement.direction, attribute IDBCursor.direction, attribute TextTrackCue.direction, attribute WebKitAnimation.direction
dom_externs.dirxml;                     // operation Console.dirxml
dom_externs.disable;                    // operation WebGLRenderingContext.disable
dom_externs.disableVertexAttribArray;   // operation WebGLRenderingContext.disableVertexAttribArray
dom_externs.disabled;                   // attribute HTMLButtonElement.disabled, attribute HTMLInputElement.disabled, attribute HTMLKeygenElement.disabled, attribute HTMLLinkElement.disabled, attribute HTMLOptGroupElement.disabled, attribute HTMLOptionElement.disabled, attribute HTMLSelectElement.disabled, attribute HTMLStyleElement.disabled, attribute HTMLTextAreaElement.disabled, attribute StyleSheet.disabled
dom_externs.disconnect;                 // operation WebKitMutationObserver.disconnect
dom_externs.disconnectFromBackend;      // operation InspectorFrontendHost.disconnectFromBackend
dom_externs.dispatchEvent;              // operation AbstractWorker.dispatchEvent, operation DOMApplicationCache.dispatchEvent, operation DOMWindow.dispatchEvent, operation EventSource.dispatchEvent, operation EventTarget.dispatchEvent, operation IDBDatabase.dispatchEvent, operation IDBRequest.dispatchEvent, operation IDBTransaction.dispatchEvent, operation MessagePort.dispatchEvent, operation Node.dispatchEvent, operation Notification.dispatchEvent, operation SVGElementInstance.dispatchEvent, operation WebSocket.dispatchEvent, operation WorkerContext.dispatchEvent, operation XMLHttpRequest.dispatchEvent, operation XMLHttpRequestUpload.dispatchEvent
dom_externs.divisor;                    // attribute SVGFEConvolveMatrixElement.divisor
dom_externs.doctype;                    // attribute Document.doctype
dom_externs.document;                   // attribute DOMWindow.document
dom_externs.documentElement;            // attribute Document.documentElement
dom_externs.documentURI;                // attribute Document.documentURI
dom_externs.domComplete;                // attribute PerformanceTiming.domComplete
dom_externs.domContentLoadedEventEnd;   // attribute PerformanceTiming.domContentLoadedEventEnd
dom_externs.domContentLoadedEventStart;  // attribute PerformanceTiming.domContentLoadedEventStart
dom_externs.domInteractive;             // attribute PerformanceTiming.domInteractive
dom_externs.domLoading;                 // attribute PerformanceTiming.domLoading
dom_externs.domain;                     // attribute Document.domain
dom_externs.domainLookupEnd;            // attribute PerformanceTiming.domainLookupEnd
dom_externs.domainLookupStart;          // attribute PerformanceTiming.domainLookupStart
dom_externs.download;                   // attribute HTMLAnchorElement.download
dom_externs.draggable;                  // attribute HTMLElement.draggable
dom_externs.drawArrays;                 // operation WebGLRenderingContext.drawArrays
dom_externs.drawElements;               // operation WebGLRenderingContext.drawElements
dom_externs.drawImage;                  // operation CanvasRenderingContext2D.drawImage
dom_externs.drawImageFromRect;          // operation CanvasRenderingContext2D.drawImageFromRect
dom_externs.drawingBufferHeight;        // attribute WebGLRenderingContext.drawingBufferHeight
dom_externs.drawingBufferWidth;         // attribute WebGLRenderingContext.drawingBufferWidth
dom_externs.dropEffect;                 // attribute Clipboard.dropEffect
dom_externs.duration;                   // attribute HTMLMediaElement.duration, attribute WebKitAnimation.duration
dom_externs.dx;                         // attribute SVGFEDropShadowElement.dx, attribute SVGFEOffsetElement.dx, attribute SVGGlyphRefElement.dx, attribute SVGTextPositioningElement.dx
dom_externs.dy;                         // attribute SVGFEDropShadowElement.dy, attribute SVGFEOffsetElement.dy, attribute SVGGlyphRefElement.dy, attribute SVGTextPositioningElement.dy
dom_externs.e;                          // attribute SVGMatrix.e, attribute WebKitCSSMatrix.e
dom_externs.edgeMode;                   // attribute SVGFEConvolveMatrixElement.edgeMode
dom_externs.effectAllowed;              // attribute Clipboard.effectAllowed
dom_externs.elapsedTime;                // attribute WebKitAnimation.elapsedTime, attribute WebKitAnimationEvent.elapsedTime, attribute WebKitTransitionEvent.elapsedTime
dom_externs.elementFromPoint;           // operation Document.elementFromPoint
dom_externs.elements;                   // attribute HTMLFormElement.elements
dom_externs.elevation;                  // attribute SVGFEDistantLightElement.elevation
dom_externs.embeds;                     // attribute HTMLDocument.embeds
dom_externs.empty;                      // operation DOMSelection.empty
dom_externs.enable;                     // operation WebGLRenderingContext.enable
dom_externs.enableVertexAttribArray;    // operation WebGLRenderingContext.enableVertexAttribArray
dom_externs.enabledPlugin;              // attribute DOMMimeType.enabledPlugin
dom_externs.encoding;                   // attribute CSSCharsetRule.encoding, attribute HTMLFormElement.encoding
dom_externs.enctype;                    // attribute HTMLFormElement.enctype
dom_externs.end;                        // operation TimeRanges.end
dom_externs.endContainer;               // attribute Range.endContainer
dom_externs.endElement;                 // operation ElementTimeControl.endElement, operation SVGAnimationElement.endElement
dom_externs.endElementAt;               // operation ElementTimeControl.endElementAt, operation SVGAnimationElement.endElementAt
dom_externs.endOffset;                  // attribute Range.endOffset
dom_externs.endTime;                    // attribute TextTrackCue.endTime
dom_externs.ended;                      // attribute HTMLMediaElement.ended, attribute WebKitAnimation.ended
dom_externs.entities;                   // attribute DocumentType.entities
dom_externs.error;                      // operation Console.error, attribute FileReader.error, attribute FileWriter.error, attribute HTMLMediaElement.error
dom_externs.errorCode;                  // attribute IDBRequest.errorCode
dom_externs.evaluate;                   // operation Document.evaluate, operation InjectedScriptHost.evaluate, operation JavaScriptCallFrame.evaluate, operation XPathEvaluator.evaluate, operation XPathExpression.evaluate
dom_externs.event;                      // attribute DOMWindow.event, attribute HTMLScriptElement.event
dom_externs.eventPhase;                 // attribute Event.eventPhase
dom_externs.exclusive;                  // attribute WebKitFlags.exclusive
dom_externs.execCommand;                // operation Document.execCommand
dom_externs.expand;                     // operation Range.expand
dom_externs.expandEntityReferences;     // attribute NodeIterator.expandEntityReferences, attribute TreeWalker.expandEntityReferences
dom_externs.exponent;                   // attribute SVGComponentTransferFunctionElement.exponent
dom_externs.extend;                     // operation DOMSelection.extend
dom_externs.extensions;                 // attribute WebSocket.extensions
dom_externs.extentNode;                 // attribute DOMSelection.extentNode
dom_externs.extentOffset;               // attribute DOMSelection.extentOffset
dom_externs.externalResourcesRequired;  // attribute SVGAElement.externalResourcesRequired, attribute SVGAnimationElement.externalResourcesRequired, attribute SVGCircleElement.externalResourcesRequired, attribute SVGClipPathElement.externalResourcesRequired, attribute SVGCursorElement.externalResourcesRequired, attribute SVGDefsElement.externalResourcesRequired, attribute SVGEllipseElement.externalResourcesRequired, attribute SVGExternalResourcesRequired.externalResourcesRequired, attribute SVGFEImageElement.externalResourcesRequired, attribute SVGFilterElement.externalResourcesRequired, attribute SVGForeignObjectElement.externalResourcesRequired, attribute SVGGElement.externalResourcesRequired, attribute SVGGradientElement.externalResourcesRequired, attribute SVGImageElement.externalResourcesRequired, attribute SVGLineElement.externalResourcesRequired, attribute SVGMPathElement.externalResourcesRequired, attribute SVGMarkerElement.externalResourcesRequired, attribute SVGMaskElement.externalResourcesRequired, attribute SVGPathElement.externalResourcesRequired, attribute SVGPatternElement.externalResourcesRequired, attribute SVGPolygonElement.externalResourcesRequired, attribute SVGPolylineElement.externalResourcesRequired, attribute SVGRectElement.externalResourcesRequired, attribute SVGSVGElement.externalResourcesRequired, attribute SVGScriptElement.externalResourcesRequired, attribute SVGSwitchElement.externalResourcesRequired, attribute SVGSymbolElement.externalResourcesRequired, attribute SVGTextContentElement.externalResourcesRequired, attribute SVGUseElement.externalResourcesRequired, attribute SVGViewElement.externalResourcesRequired
dom_externs.extractContents;            // operation Range.extractContents
dom_externs.f;                          // attribute SVGMatrix.f, attribute WebKitCSSMatrix.f
dom_externs.face;                       // attribute HTMLBaseFontElement.face, attribute HTMLFontElement.face
dom_externs.farthestViewportElement;    // attribute SVGAElement.farthestViewportElement, attribute SVGCircleElement.farthestViewportElement, attribute SVGClipPathElement.farthestViewportElement, attribute SVGDefsElement.farthestViewportElement, attribute SVGEllipseElement.farthestViewportElement, attribute SVGForeignObjectElement.farthestViewportElement, attribute SVGGElement.farthestViewportElement, attribute SVGImageElement.farthestViewportElement, attribute SVGLineElement.farthestViewportElement, attribute SVGLocatable.farthestViewportElement, attribute SVGPathElement.farthestViewportElement, attribute SVGPolygonElement.farthestViewportElement, attribute SVGPolylineElement.farthestViewportElement, attribute SVGRectElement.farthestViewportElement, attribute SVGSVGElement.farthestViewportElement, attribute SVGSwitchElement.farthestViewportElement, attribute SVGTextElement.farthestViewportElement, attribute SVGUseElement.farthestViewportElement
dom_externs.fetchStart;                 // attribute PerformanceTiming.fetchStart
dom_externs.fgColor;                    // attribute HTMLDocument.fgColor
dom_externs.file;                       // operation FileEntry.file, operation FileEntrySync.file
dom_externs.fileName;                   // attribute File.fileName
dom_externs.fileSize;                   // attribute File.fileSize
dom_externs.filename;                   // attribute DOMPlugin.filename, attribute ErrorEvent.filename
dom_externs.files;                      // attribute Clipboard.files, attribute HTMLInputElement.files
dom_externs.filesystem;                 // attribute Entry.filesystem, attribute EntrySync.filesystem
dom_externs.fill;                       // operation CanvasRenderingContext2D.fill
dom_externs.fillMode;                   // attribute WebKitAnimation.fillMode
dom_externs.fillRect;                   // operation CanvasRenderingContext2D.fillRect
dom_externs.fillStyle;                  // attribute CanvasRenderingContext2D.fillStyle
dom_externs.fillText;                   // operation CanvasRenderingContext2D.fillText
dom_externs.filter;                     // attribute NodeIterator.filter, attribute TreeWalker.filter
dom_externs.filterResX;                 // attribute SVGFilterElement.filterResX
dom_externs.filterResY;                 // attribute SVGFilterElement.filterResY
dom_externs.filterUnits;                // attribute SVGFilterElement.filterUnits
dom_externs.find;                       // operation DOMWindow.find
dom_externs.findRule;                   // operation WebKitCSSKeyframesRule.findRule
dom_externs.finish;                     // operation WebGLRenderingContext.finish
dom_externs.firstChild;                 // attribute Node.firstChild, attribute SVGElementInstance.firstChild, operation TreeWalker.firstChild
dom_externs.firstElementChild;          // attribute Element.firstElementChild, attribute ElementTraversal.firstElementChild
dom_externs.flipX;                      // operation SVGMatrix.flipX
dom_externs.flipY;                      // operation SVGMatrix.flipY
dom_externs.flush;                      // operation WebGLRenderingContext.flush
dom_externs.focus;                      // operation DOMWindow.focus, operation Element.focus
dom_externs.focusNode;                  // attribute DOMSelection.focusNode
dom_externs.focusOffset;                // attribute DOMSelection.focusOffset
dom_externs.font;                       // attribute CanvasRenderingContext2D.font
dom_externs.forceRedraw;                // operation SVGSVGElement.forceRedraw
dom_externs.form;                       // attribute HTMLButtonElement.form, attribute HTMLFieldSetElement.form, attribute HTMLInputElement.form, attribute HTMLIsIndexElement.form, attribute HTMLKeygenElement.form, attribute HTMLLabelElement.form, attribute HTMLLegendElement.form, attribute HTMLMeterElement.form, attribute HTMLObjectElement.form, attribute HTMLOptionElement.form, attribute HTMLOutputElement.form, attribute HTMLProgressElement.form, attribute HTMLSelectElement.form, attribute HTMLTextAreaElement.form
dom_externs.formAction;                 // attribute HTMLButtonElement.formAction, attribute HTMLInputElement.formAction
dom_externs.formEnctype;                // attribute HTMLButtonElement.formEnctype, attribute HTMLInputElement.formEnctype
dom_externs.formMethod;                 // attribute HTMLButtonElement.formMethod, attribute HTMLInputElement.formMethod
dom_externs.formNoValidate;             // attribute HTMLButtonElement.formNoValidate, attribute HTMLInputElement.formNoValidate
dom_externs.formTarget;                 // attribute HTMLButtonElement.formTarget, attribute HTMLInputElement.formTarget
dom_externs.format;                     // attribute SVGAltGlyphElement.format, attribute SVGGlyphRefElement.format
dom_externs.forms;                      // attribute Document.forms
dom_externs.forward;                    // operation History.forward
dom_externs.frame;                      // attribute HTMLTableElement.frame
dom_externs.frameBorder;                // attribute HTMLFrameElement.frameBorder, attribute HTMLIFrameElement.frameBorder
dom_externs.frameElement;               // attribute DOMWindow.frameElement
dom_externs.framebufferRenderbuffer;    // operation WebGLRenderingContext.framebufferRenderbuffer
dom_externs.framebufferTexture2D;       // operation WebGLRenderingContext.framebufferTexture2D
dom_externs.frames;                     // attribute DOMWindow.frames
dom_externs.fromElement;                // attribute MouseEvent.fromElement
dom_externs.frontFace;                  // operation WebGLRenderingContext.frontFace
dom_externs.fullPath;                   // attribute Entry.fullPath, attribute EntrySync.fullPath
dom_externs.functionName;               // attribute JavaScriptCallFrame.functionName, attribute ScriptProfileNode.functionName
dom_externs.fx;                         // attribute SVGRadialGradientElement.fx
dom_externs.fy;                         // attribute SVGRadialGradientElement.fy
dom_externs.gamma;                      // attribute DeviceOrientationEvent.gamma
dom_externs.generateMipmap;             // operation WebGLRenderingContext.generateMipmap
dom_externs.get;                        // operation IDBIndex.get, operation IDBObjectStore.get
dom_externs.getActiveAttrib;            // operation WebGLRenderingContext.getActiveAttrib
dom_externs.getActiveUniform;           // operation WebGLRenderingContext.getActiveUniform
dom_externs.getAllResponseHeaders;      // operation XMLHttpRequest.getAllResponseHeaders
dom_externs.getAsFile;                  // operation DataTransferItem.getAsFile
dom_externs.getAsString;                // operation DataTransferItem.getAsString
dom_externs.getAttachedShaders;         // operation WebGLRenderingContext.getAttachedShaders
dom_externs.getAttribLocation;          // operation WebGLRenderingContext.getAttribLocation
dom_externs.getAttribute;               // operation Element.getAttribute
dom_externs.getAttributeNS;             // operation Element.getAttributeNS
dom_externs.getAttributeNode;           // operation Element.getAttributeNode
dom_externs.getAttributeNodeNS;         // operation Element.getAttributeNodeNS
dom_externs.getBBox;                    // operation SVGAElement.getBBox, operation SVGCircleElement.getBBox, operation SVGClipPathElement.getBBox, operation SVGDefsElement.getBBox, operation SVGEllipseElement.getBBox, operation SVGForeignObjectElement.getBBox, operation SVGGElement.getBBox, operation SVGImageElement.getBBox, operation SVGLineElement.getBBox, operation SVGLocatable.getBBox, operation SVGPathElement.getBBox, operation SVGPolygonElement.getBBox, operation SVGPolylineElement.getBBox, operation SVGRectElement.getBBox, operation SVGSVGElement.getBBox, operation SVGSwitchElement.getBBox, operation SVGTextElement.getBBox, operation SVGUseElement.getBBox
dom_externs.getBlob;                    // operation WebKitBlobBuilder.getBlob
dom_externs.getBoundingClientRect;      // operation Element.getBoundingClientRect, operation Range.getBoundingClientRect
dom_externs.getBufferParameter;         // operation WebGLRenderingContext.getBufferParameter
dom_externs.getCSSCanvasContext;        // operation Document.getCSSCanvasContext
dom_externs.getCTM;                     // operation SVGAElement.getCTM, operation SVGCircleElement.getCTM, operation SVGClipPathElement.getCTM, operation SVGDefsElement.getCTM, operation SVGEllipseElement.getCTM, operation SVGForeignObjectElement.getCTM, operation SVGGElement.getCTM, operation SVGImageElement.getCTM, operation SVGLineElement.getCTM, operation SVGLocatable.getCTM, operation SVGPathElement.getCTM, operation SVGPolygonElement.getCTM, operation SVGPolylineElement.getCTM, operation SVGRectElement.getCTM, operation SVGSVGElement.getCTM, operation SVGSwitchElement.getCTM, operation SVGTextElement.getCTM, operation SVGUseElement.getCTM
dom_externs.getCharNumAtPosition;       // operation SVGTextContentElement.getCharNumAtPosition
dom_externs.getClientRects;             // operation Element.getClientRects, operation Range.getClientRects
dom_externs.getComputedStyle;           // operation DOMWindow.getComputedStyle
dom_externs.getComputedTextLength;      // operation SVGTextContentElement.getComputedTextLength
dom_externs.getContext;                 // operation HTMLCanvasElement.getContext
dom_externs.getContextAttributes;       // operation WebGLRenderingContext.getContextAttributes
dom_externs.getCounterValue;            // operation CSSPrimitiveValue.getCounterValue
dom_externs.getCueAsHTML;               // operation TextTrackCue.getCueAsHTML
dom_externs.getCueAsSource;             // operation TextTrackCue.getCueAsSource
dom_externs.getCueById;                 // operation TextTrackCueList.getCueById
dom_externs.getCurrentPosition;         // operation Geolocation.getCurrentPosition
dom_externs.getCurrentTime;             // operation SVGAnimationElement.getCurrentTime, operation SVGSVGElement.getCurrentTime
dom_externs.getData;                    // operation Clipboard.getData
dom_externs.getDatabaseNames;           // operation IDBFactory.getDatabaseNames
dom_externs.getDirectory;               // operation DirectoryEntry.getDirectory, operation DirectoryEntrySync.getDirectory
dom_externs.getElementById;             // operation Document.getElementById, operation SVGSVGElement.getElementById
dom_externs.getElementsByClassName;     // operation Document.getElementsByClassName, operation Element.getElementsByClassName
dom_externs.getElementsByName;          // operation Document.getElementsByName
dom_externs.getElementsByTagName;       // operation Document.getElementsByTagName, operation Element.getElementsByTagName
dom_externs.getElementsByTagNameNS;     // operation Document.getElementsByTagNameNS, operation Element.getElementsByTagNameNS
dom_externs.getEnclosureList;           // operation SVGSVGElement.getEnclosureList
dom_externs.getEndPositionOfChar;       // operation SVGTextContentElement.getEndPositionOfChar
dom_externs.getError;                   // operation WebGLRenderingContext.getError
dom_externs.getExtension;               // operation WebGLRenderingContext.getExtension
dom_externs.getExtentOfChar;            // operation SVGTextContentElement.getExtentOfChar
dom_externs.getFile;                    // operation DirectoryEntry.getFile, operation DirectoryEntrySync.getFile
dom_externs.getFloat32;                 // operation DataView.getFloat32
dom_externs.getFloat64;                 // operation DataView.getFloat64
dom_externs.getFloatValue;              // operation CSSPrimitiveValue.getFloatValue
dom_externs.getFramebufferAttachmentParameter;  // operation WebGLRenderingContext.getFramebufferAttachmentParameter
dom_externs.getImageData;               // operation CanvasRenderingContext2D.getImageData
dom_externs.getInt16;                   // operation DataView.getInt16
dom_externs.getInt32;                   // operation DataView.getInt32
dom_externs.getInt8;                    // operation DataView.getInt8
dom_externs.getIntersectionList;        // operation SVGSVGElement.getIntersectionList
dom_externs.getItem;                    // operation SVGLengthList.getItem, operation SVGNumberList.getItem, operation SVGPathSegList.getItem, operation SVGPointList.getItem, operation SVGStringList.getItem, operation SVGTransformList.getItem, operation Storage.getItem
dom_externs.getKey;                     // operation IDBIndex.getKey
dom_externs.getMatchedCSSRules;         // operation DOMWindow.getMatchedCSSRules
dom_externs.getMetadata;                // operation Entry.getMetadata, operation EntrySync.getMetadata
dom_externs.getNamedItem;               // operation NamedNodeMap.getNamedItem
dom_externs.getNamedItemNS;             // operation NamedNodeMap.getNamedItemNS
dom_externs.getNumberOfChars;           // operation SVGTextContentElement.getNumberOfChars
dom_externs.getOverrideStyle;           // operation Document.getOverrideStyle
dom_externs.getParameter;               // operation HTMLAnchorElement.getParameter, operation Location.getParameter, operation WebGLRenderingContext.getParameter, operation XSLTProcessor.getParameter
dom_externs.getParent;                  // operation Entry.getParent, operation EntrySync.getParent
dom_externs.getPathSegAtLength;         // operation SVGPathElement.getPathSegAtLength
dom_externs.getPointAtLength;           // operation SVGPathElement.getPointAtLength
dom_externs.getPresentationAttribute;   // operation SVGAElement.getPresentationAttribute, operation SVGCircleElement.getPresentationAttribute, operation SVGClipPathElement.getPresentationAttribute, operation SVGDefsElement.getPresentationAttribute, operation SVGDescElement.getPresentationAttribute, operation SVGEllipseElement.getPresentationAttribute, operation SVGFEBlendElement.getPresentationAttribute, operation SVGFEColorMatrixElement.getPresentationAttribute, operation SVGFEComponentTransferElement.getPresentationAttribute, operation SVGFECompositeElement.getPresentationAttribute, operation SVGFEConvolveMatrixElement.getPresentationAttribute, operation SVGFEDiffuseLightingElement.getPresentationAttribute, operation SVGFEDisplacementMapElement.getPresentationAttribute, operation SVGFEDropShadowElement.getPresentationAttribute, operation SVGFEFloodElement.getPresentationAttribute, operation SVGFEGaussianBlurElement.getPresentationAttribute, operation SVGFEImageElement.getPresentationAttribute, operation SVGFEMergeElement.getPresentationAttribute, operation SVGFEMorphologyElement.getPresentationAttribute, operation SVGFEOffsetElement.getPresentationAttribute, operation SVGFESpecularLightingElement.getPresentationAttribute, operation SVGFETileElement.getPresentationAttribute, operation SVGFETurbulenceElement.getPresentationAttribute, operation SVGFilterElement.getPresentationAttribute, operation SVGForeignObjectElement.getPresentationAttribute, operation SVGGElement.getPresentationAttribute, operation SVGGlyphRefElement.getPresentationAttribute, operation SVGGradientElement.getPresentationAttribute, operation SVGImageElement.getPresentationAttribute, operation SVGLineElement.getPresentationAttribute, operation SVGMarkerElement.getPresentationAttribute, operation SVGMaskElement.getPresentationAttribute, operation SVGPathElement.getPresentationAttribute, operation SVGPatternElement.getPresentationAttribute, operation SVGPolygonElement.getPresentationAttribute, operation SVGPolylineElement.getPresentationAttribute, operation SVGRectElement.getPresentationAttribute, operation SVGSVGElement.getPresentationAttribute, operation SVGStopElement.getPresentationAttribute, operation SVGStylable.getPresentationAttribute, operation SVGSwitchElement.getPresentationAttribute, operation SVGSymbolElement.getPresentationAttribute, operation SVGTextContentElement.getPresentationAttribute, operation SVGTitleElement.getPresentationAttribute, operation SVGUseElement.getPresentationAttribute
dom_externs.getProgramInfoLog;          // operation WebGLRenderingContext.getProgramInfoLog
dom_externs.getProgramParameter;        // operation WebGLRenderingContext.getProgramParameter
dom_externs.getPropertyCSSValue;        // operation CSSStyleDeclaration.getPropertyCSSValue
dom_externs.getPropertyPriority;        // operation CSSStyleDeclaration.getPropertyPriority
dom_externs.getPropertyShorthand;       // operation CSSStyleDeclaration.getPropertyShorthand
dom_externs.getPropertyValue;           // operation CSSStyleDeclaration.getPropertyValue
dom_externs.getRGBColorValue;           // operation CSSPrimitiveValue.getRGBColorValue
dom_externs.getRandomValues;            // operation Crypto.getRandomValues
dom_externs.getRangeAt;                 // operation DOMSelection.getRangeAt
dom_externs.getRectValue;               // operation CSSPrimitiveValue.getRectValue
dom_externs.getRenderbufferParameter;   // operation WebGLRenderingContext.getRenderbufferParameter
dom_externs.getResponseHeader;          // operation XMLHttpRequest.getResponseHeader
dom_externs.getRotationOfChar;          // operation SVGTextContentElement.getRotationOfChar
dom_externs.getScreenCTM;               // operation SVGAElement.getScreenCTM, operation SVGCircleElement.getScreenCTM, operation SVGClipPathElement.getScreenCTM, operation SVGDefsElement.getScreenCTM, operation SVGEllipseElement.getScreenCTM, operation SVGForeignObjectElement.getScreenCTM, operation SVGGElement.getScreenCTM, operation SVGImageElement.getScreenCTM, operation SVGLineElement.getScreenCTM, operation SVGLocatable.getScreenCTM, operation SVGPathElement.getScreenCTM, operation SVGPolygonElement.getScreenCTM, operation SVGPolylineElement.getScreenCTM, operation SVGRectElement.getScreenCTM, operation SVGSVGElement.getScreenCTM, operation SVGSwitchElement.getScreenCTM, operation SVGTextElement.getScreenCTM, operation SVGUseElement.getScreenCTM
dom_externs.getSelection;               // operation DOMWindow.getSelection, operation Document.getSelection
dom_externs.getShaderInfoLog;           // operation WebGLRenderingContext.getShaderInfoLog
dom_externs.getShaderParameter;         // operation WebGLRenderingContext.getShaderParameter
dom_externs.getShaderSource;            // operation WebGLRenderingContext.getShaderSource
dom_externs.getSimpleDuration;          // operation SVGAnimationElement.getSimpleDuration
dom_externs.getStartPositionOfChar;     // operation SVGTextContentElement.getStartPositionOfChar
dom_externs.getStartTime;               // operation SVGAnimationElement.getStartTime
dom_externs.getStorageUpdates;          // operation Navigator.getStorageUpdates
dom_externs.getStringValue;             // operation CSSPrimitiveValue.getStringValue
dom_externs.getSubStringLength;         // operation SVGTextContentElement.getSubStringLength
dom_externs.getSupportedExtensions;     // operation WebGLRenderingContext.getSupportedExtensions
dom_externs.getTexParameter;            // operation WebGLRenderingContext.getTexParameter
dom_externs.getTotalLength;             // operation SVGPathElement.getTotalLength
dom_externs.getTransformToElement;      // operation SVGAElement.getTransformToElement, operation SVGCircleElement.getTransformToElement, operation SVGClipPathElement.getTransformToElement, operation SVGDefsElement.getTransformToElement, operation SVGEllipseElement.getTransformToElement, operation SVGForeignObjectElement.getTransformToElement, operation SVGGElement.getTransformToElement, operation SVGImageElement.getTransformToElement, operation SVGLineElement.getTransformToElement, operation SVGLocatable.getTransformToElement, operation SVGPathElement.getTransformToElement, operation SVGPolygonElement.getTransformToElement, operation SVGPolylineElement.getTransformToElement, operation SVGRectElement.getTransformToElement, operation SVGSVGElement.getTransformToElement, operation SVGSwitchElement.getTransformToElement, operation SVGTextElement.getTransformToElement, operation SVGUseElement.getTransformToElement
dom_externs.getTranslatedShaderSource;  // operation WebGLDebugShaders.getTranslatedShaderSource
dom_externs.getUint16;                  // operation DataView.getUint16
dom_externs.getUint32;                  // operation DataView.getUint32
dom_externs.getUint8;                   // operation DataView.getUint8
dom_externs.getUniform;                 // operation WebGLRenderingContext.getUniform
dom_externs.getUniformLocation;         // operation WebGLRenderingContext.getUniformLocation
dom_externs.getVertexAttrib;            // operation WebGLRenderingContext.getVertexAttrib
dom_externs.getVertexAttribOffset;      // operation WebGLRenderingContext.getVertexAttribOffset
dom_externs.globalAlpha;                // attribute CanvasRenderingContext2D.globalAlpha
dom_externs.globalCompositeOperation;   // attribute CanvasRenderingContext2D.globalCompositeOperation
dom_externs.glyphRef;                   // attribute SVGAltGlyphElement.glyphRef, attribute SVGGlyphRefElement.glyphRef
dom_externs.go;                         // operation History.go
dom_externs.gradientTransform;          // attribute SVGGradientElement.gradientTransform
dom_externs.gradientUnits;              // attribute SVGGradientElement.gradientUnits
dom_externs.green;                      // attribute RGBColor.green
dom_externs.group;                      // operation Console.group
dom_externs.groupCollapsed;             // operation Console.groupCollapsed
dom_externs.groupEnd;                   // operation Console.groupEnd
dom_externs.handleEvent;                // operation DatabaseCallback.handleEvent, operation EntriesCallback.handleEvent, operation EntryCallback.handleEvent, operation ErrorCallback.handleEvent, operation FileCallback.handleEvent, operation FileSystemCallback.handleEvent, operation FileWriterCallback.handleEvent, operation MetadataCallback.handleEvent, operation NavigatorUserMediaErrorCallback.handleEvent, operation PositionCallback.handleEvent, operation PositionErrorCallback.handleEvent, operation SQLStatementCallback.handleEvent, operation SQLStatementErrorCallback.handleEvent, operation SQLTransactionCallback.handleEvent, operation SQLTransactionErrorCallback.handleEvent, operation SQLTransactionSyncCallback.handleEvent, operation StorageInfoErrorCallback.handleEvent, operation StorageInfoQuotaCallback.handleEvent, operation StorageInfoUsageCallback.handleEvent, operation StringCallback.handleEvent, operation VoidCallback.handleEvent
dom_externs.hasAttribute;               // operation Element.hasAttribute
dom_externs.hasAttributeNS;             // operation Element.hasAttributeNS
dom_externs.hasAttributes;              // operation Node.hasAttributes
dom_externs.hasChildNodes;              // operation Node.hasChildNodes
dom_externs.hasExtension;               // operation SVGAElement.hasExtension, operation SVGAnimationElement.hasExtension, operation SVGCircleElement.hasExtension, operation SVGClipPathElement.hasExtension, operation SVGCursorElement.hasExtension, operation SVGDefsElement.hasExtension, operation SVGEllipseElement.hasExtension, operation SVGForeignObjectElement.hasExtension, operation SVGGElement.hasExtension, operation SVGImageElement.hasExtension, operation SVGLineElement.hasExtension, operation SVGMaskElement.hasExtension, operation SVGPathElement.hasExtension, operation SVGPatternElement.hasExtension, operation SVGPolygonElement.hasExtension, operation SVGPolylineElement.hasExtension, operation SVGRectElement.hasExtension, operation SVGSVGElement.hasExtension, operation SVGSwitchElement.hasExtension, operation SVGTests.hasExtension, operation SVGTextContentElement.hasExtension, operation SVGUseElement.hasExtension
dom_externs.hasFeature;                 // operation DOMImplementation.hasFeature
dom_externs.hasFocus;                   // operation HTMLDocument.hasFocus
dom_externs.hash;                       // attribute HTMLAnchorElement.hash, attribute HTMLAreaElement.hash, attribute Location.hash, attribute WorkerLocation.hash
dom_externs.head;                       // attribute Document.head, attribute ScriptProfile.head
dom_externs.headers;                    // attribute HTMLTableCellElement.headers
dom_externs.heading;                    // attribute Coordinates.heading
dom_externs.height;                     // attribute ClientRect.height, attribute HTMLAppletElement.height, attribute HTMLCanvasElement.height, attribute HTMLDocument.height, attribute HTMLEmbedElement.height, attribute HTMLFrameElement.height, attribute HTMLIFrameElement.height, attribute HTMLImageElement.height, attribute HTMLMarqueeElement.height, attribute HTMLObjectElement.height, attribute HTMLTableCellElement.height, attribute HTMLVideoElement.height, attribute ImageData.height, attribute SVGFEBlendElement.height, attribute SVGFEColorMatrixElement.height, attribute SVGFEComponentTransferElement.height, attribute SVGFECompositeElement.height, attribute SVGFEConvolveMatrixElement.height, attribute SVGFEDiffuseLightingElement.height, attribute SVGFEDisplacementMapElement.height, attribute SVGFEDropShadowElement.height, attribute SVGFEFloodElement.height, attribute SVGFEGaussianBlurElement.height, attribute SVGFEImageElement.height, attribute SVGFEMergeElement.height, attribute SVGFEMorphologyElement.height, attribute SVGFEOffsetElement.height, attribute SVGFESpecularLightingElement.height, attribute SVGFETileElement.height, attribute SVGFETurbulenceElement.height, attribute SVGFilterElement.height, attribute SVGFilterPrimitiveStandardAttributes.height, attribute SVGForeignObjectElement.height, attribute SVGImageElement.height, attribute SVGMaskElement.height, attribute SVGPatternElement.height, attribute SVGRect.height, attribute SVGRectElement.height, attribute SVGSVGElement.height, attribute SVGUseElement.height, attribute Screen.height
dom_externs.hidden;                     // attribute HTMLElement.hidden
dom_externs.hiddenPanels;               // operation InspectorFrontendHost.hiddenPanels
dom_externs.high;                       // attribute HTMLMeterElement.high
dom_externs.hint;                       // operation WebGLRenderingContext.hint
dom_externs.history;                    // attribute DOMWindow.history
dom_externs.horizontalOverflow;         // attribute OverflowEvent.horizontalOverflow
dom_externs.host;                       // attribute HTMLAnchorElement.host, attribute HTMLAreaElement.host, attribute Location.host, attribute WorkerLocation.host
dom_externs.hostname;                   // attribute HTMLAnchorElement.hostname, attribute HTMLAreaElement.hostname, attribute Location.hostname, attribute WorkerLocation.hostname
dom_externs.href;                       // attribute CSSImportRule.href, attribute HTMLAnchorElement.href, attribute HTMLAreaElement.href, attribute HTMLBaseElement.href, attribute HTMLLinkElement.href, attribute Location.href, attribute SVGAElement.href, attribute SVGAltGlyphElement.href, attribute SVGCursorElement.href, attribute SVGFEImageElement.href, attribute SVGFilterElement.href, attribute SVGGlyphRefElement.href, attribute SVGGradientElement.href, attribute SVGImageElement.href, attribute SVGMPathElement.href, attribute SVGPatternElement.href, attribute SVGScriptElement.href, attribute SVGTRefElement.href, attribute SVGTextPathElement.href, attribute SVGURIReference.href, attribute SVGUseElement.href, attribute StyleSheet.href, attribute WorkerLocation.href
dom_externs.hreflang;                   // attribute HTMLAnchorElement.hreflang, attribute HTMLLinkElement.hreflang
dom_externs.hspace;                     // attribute HTMLAppletElement.hspace, attribute HTMLImageElement.hspace, attribute HTMLMarqueeElement.hspace, attribute HTMLObjectElement.hspace
dom_externs.htmlFor;                    // attribute HTMLLabelElement.htmlFor, attribute HTMLOutputElement.htmlFor, attribute HTMLScriptElement.htmlFor
dom_externs.httpEquiv;                  // attribute HTMLMetaElement.httpEquiv
dom_externs.id;                         // attribute HTMLElement.id, attribute SVGElement.id, attribute TextTrackCue.id
dom_externs.identifier;                 // attribute Counter.identifier, attribute Touch.identifier
dom_externs.images;                     // attribute Document.images
dom_externs.implementation;             // attribute Document.implementation
dom_externs.importNode;                 // operation Document.importNode
dom_externs.importScripts;              // operation WorkerContext.importScripts
dom_externs.importStylesheet;           // operation XSLTProcessor.importStylesheet
dom_externs.in1;                        // attribute SVGFEBlendElement.in1, attribute SVGFEColorMatrixElement.in1, attribute SVGFEComponentTransferElement.in1, attribute SVGFECompositeElement.in1, attribute SVGFEConvolveMatrixElement.in1, attribute SVGFEDiffuseLightingElement.in1, attribute SVGFEDisplacementMapElement.in1, attribute SVGFEDropShadowElement.in1, attribute SVGFEGaussianBlurElement.in1, attribute SVGFEMergeNodeElement.in1, attribute SVGFEMorphologyElement.in1, attribute SVGFEOffsetElement.in1, attribute SVGFESpecularLightingElement.in1, attribute SVGFETileElement.in1
dom_externs.in2;                        // attribute SVGFEBlendElement.in2, attribute SVGFECompositeElement.in2, attribute SVGFEDisplacementMapElement.in2
dom_externs.incremental;                // attribute HTMLInputElement.incremental
dom_externs.indeterminate;              // attribute HTMLInputElement.indeterminate
dom_externs.index;                      // attribute HTMLOptionElement.index, operation IDBObjectStore.index
dom_externs.info;                       // operation Console.info
dom_externs.initBeforeLoadEvent;        // operation BeforeLoadEvent.initBeforeLoadEvent
dom_externs.initCloseEvent;             // operation CloseEvent.initCloseEvent
dom_externs.initCompositionEvent;       // operation CompositionEvent.initCompositionEvent
dom_externs.initCustomEvent;            // operation CustomEvent.initCustomEvent
dom_externs.initDeviceOrientationEvent;  // operation DeviceOrientationEvent.initDeviceOrientationEvent
dom_externs.initErrorEvent;             // operation ErrorEvent.initErrorEvent
dom_externs.initEvent;                  // operation Event.initEvent
dom_externs.initHashChangeEvent;        // operation HashChangeEvent.initHashChangeEvent
dom_externs.initKeyboardEvent;          // operation KeyboardEvent.initKeyboardEvent
dom_externs.initMessageEvent;           // operation MessageEvent.initMessageEvent
dom_externs.initMouseEvent;             // operation MouseEvent.initMouseEvent
dom_externs.initMutationEvent;          // operation MutationEvent.initMutationEvent
dom_externs.initOverflowEvent;          // operation OverflowEvent.initOverflowEvent
dom_externs.initPageTransitionEvent;    // operation PageTransitionEvent.initPageTransitionEvent
dom_externs.initPopStateEvent;          // operation PopStateEvent.initPopStateEvent
dom_externs.initProgressEvent;          // operation ProgressEvent.initProgressEvent
dom_externs.initStorageEvent;           // operation StorageEvent.initStorageEvent
dom_externs.initTextEvent;              // operation TextEvent.initTextEvent
dom_externs.initTouchEvent;             // operation TouchEvent.initTouchEvent
dom_externs.initUIEvent;                // operation UIEvent.initUIEvent
dom_externs.initWebKitAnimationEvent;   // operation WebKitAnimationEvent.initWebKitAnimationEvent
dom_externs.initWebKitTransitionEvent;  // operation WebKitTransitionEvent.initWebKitTransitionEvent
dom_externs.initWebKitWheelEvent;       // operation WheelEvent.initWebKitWheelEvent
dom_externs.initialTime;                // attribute HTMLMediaElement.initialTime
dom_externs.initialize;                 // operation SVGLengthList.initialize, operation SVGNumberList.initialize, operation SVGPathSegList.initialize, operation SVGPointList.initialize, operation SVGStringList.initialize, operation SVGTransformList.initialize
dom_externs.innerHTML;                  // attribute HTMLElement.innerHTML
dom_externs.innerHeight;                // attribute DOMWindow.innerHeight
dom_externs.innerText;                  // attribute HTMLElement.innerText
dom_externs.innerWidth;                 // attribute DOMWindow.innerWidth
dom_externs.inputEncoding;              // attribute Document.inputEncoding
dom_externs.insertAdjacentElement;      // operation HTMLElement.insertAdjacentElement
dom_externs.insertAdjacentHTML;         // operation HTMLElement.insertAdjacentHTML
dom_externs.insertAdjacentText;         // operation HTMLElement.insertAdjacentText
dom_externs.insertBefore;               // operation Node.insertBefore
dom_externs.insertCell;                 // operation HTMLTableRowElement.insertCell
dom_externs.insertData;                 // operation CharacterData.insertData
dom_externs.insertId;                   // attribute SQLResultSet.insertId
dom_externs.insertItemBefore;           // operation SVGLengthList.insertItemBefore, operation SVGNumberList.insertItemBefore, operation SVGPathSegList.insertItemBefore, operation SVGPointList.insertItemBefore, operation SVGStringList.insertItemBefore, operation SVGTransformList.insertItemBefore
dom_externs.insertNode;                 // operation Range.insertNode
dom_externs.insertRow;                  // operation HTMLTableElement.insertRow, operation HTMLTableSectionElement.insertRow
dom_externs.insertRule;                 // operation CSSMediaRule.insertRule, operation CSSStyleSheet.insertRule, operation WebKitCSSKeyframesRule.insertRule
dom_externs.inspect;                    // operation InjectedScriptHost.inspect
dom_externs.inspectedNode;              // operation InjectedScriptHost.inspectedNode
dom_externs.inspectedURLChanged;        // operation InspectorFrontendHost.inspectedURLChanged
dom_externs.instanceRoot;               // attribute SVGUseElement.instanceRoot
dom_externs.intercept;                  // attribute SVGComponentTransferFunctionElement.intercept
dom_externs.internalConstructorName;    // operation InjectedScriptHost.internalConstructorName
dom_externs.internalSubset;             // attribute DocumentType.internalSubset
dom_externs.intersectsNode;             // operation Range.intersectsNode
dom_externs.interval;                   // attribute DeviceMotionEvent.interval
dom_externs.invalidIteratorState;       // attribute XPathResult.invalidIteratorState
dom_externs.inverse;                    // operation SVGMatrix.inverse, operation WebKitCSSMatrix.inverse
dom_externs.isBuffer;                   // operation WebGLRenderingContext.isBuffer
dom_externs.isCollapsed;                // attribute DOMSelection.isCollapsed
dom_externs.isContentEditable;          // attribute HTMLElement.isContentEditable
dom_externs.isContextLost;              // operation WebGLRenderingContext.isContextLost
dom_externs.isDefault;                  // attribute HTMLTrackElement.isDefault
dom_externs.isDefaultNamespace;         // operation Node.isDefaultNamespace
dom_externs.isDirectory;                // attribute Entry.isDirectory, attribute EntrySync.isDirectory
dom_externs.isEnabled;                  // operation WebGLRenderingContext.isEnabled
dom_externs.isEqualNode;                // operation Node.isEqualNode
dom_externs.isFile;                     // attribute Entry.isFile, attribute EntrySync.isFile
dom_externs.isFramebuffer;              // operation WebGLRenderingContext.isFramebuffer
dom_externs.isHTMLAllCollection;        // operation InjectedScriptHost.isHTMLAllCollection
dom_externs.isId;                       // attribute Attr.isId
dom_externs.isMap;                      // attribute HTMLImageElement.isMap
dom_externs.isPointInPath;              // operation CanvasRenderingContext2D.isPointInPath
dom_externs.isPointInRange;             // operation Range.isPointInRange
dom_externs.isProgram;                  // operation WebGLRenderingContext.isProgram
dom_externs.isPropertyImplicit;         // operation CSSStyleDeclaration.isPropertyImplicit
dom_externs.isRenderbuffer;             // operation WebGLRenderingContext.isRenderbuffer
dom_externs.isSameNode;                 // operation Node.isSameNode
dom_externs.isShader;                   // operation WebGLRenderingContext.isShader
dom_externs.isSupported;                // operation Node.isSupported
dom_externs.isTexture;                  // operation WebGLRenderingContext.isTexture
dom_externs.isVertexArrayOES;           // operation OESVertexArrayObject.isVertexArrayOES
dom_externs.item;                       // operation CSSRuleList.item, operation CSSStyleDeclaration.item, operation CSSValueList.item, operation CanvasPixelArray.item, operation ClientRectList.item, operation DOMMimeTypeArray.item, operation DOMPlugin.item, operation DOMPluginArray.item, operation DOMTokenList.item, operation DataTransferItemList.item, operation EntryArray.item, operation EntryArraySync.item, operation FileList.item, operation HTMLAllCollection.item, operation HTMLCollection.item, operation HTMLSelectElement.item, operation MediaList.item, operation NamedNodeMap.item, operation NodeList.item, operation SQLResultSetRowList.item, operation SVGElementInstanceList.item, operation SpeechInputResultList.item, operation StyleSheetList.item, operation TextTrackCueList.item, operation TouchList.item, operation WebKitAnimationList.item
dom_externs.itemId;                     // attribute HTMLElement.itemId
dom_externs.itemProp;                   // attribute HTMLElement.itemProp
dom_externs.itemRef;                    // attribute HTMLElement.itemRef
dom_externs.itemScope;                  // attribute HTMLElement.itemScope
dom_externs.itemType;                   // attribute HTMLElement.itemType
dom_externs.itemValue;                  // attribute HTMLElement.itemValue
dom_externs.items;                      // attribute Clipboard.items
dom_externs.iterateNext;                // operation XPathResult.iterateNext
dom_externs.iterationCount;             // attribute WebKitAnimation.iterationCount
dom_externs.javaEnabled;                // operation Navigator.javaEnabled
dom_externs.jsHeapSizeLimit;            // attribute MemoryInfo.jsHeapSizeLimit
dom_externs.k1;                         // attribute SVGFECompositeElement.k1
dom_externs.k2;                         // attribute SVGFECompositeElement.k2
dom_externs.k3;                         // attribute SVGFECompositeElement.k3
dom_externs.k4;                         // attribute SVGFECompositeElement.k4
dom_externs.kernelMatrix;               // attribute SVGFEConvolveMatrixElement.kernelMatrix
dom_externs.kernelUnitLengthX;          // attribute SVGFEConvolveMatrixElement.kernelUnitLengthX, attribute SVGFEDiffuseLightingElement.kernelUnitLengthX
dom_externs.kernelUnitLengthY;          // attribute SVGFEConvolveMatrixElement.kernelUnitLengthY, attribute SVGFEDiffuseLightingElement.kernelUnitLengthY
dom_externs.key;                        // attribute IDBCursor.key, operation Storage.key, attribute StorageEvent.key
dom_externs.keyCode;                    // attribute UIEvent.keyCode
dom_externs.keyIdentifier;              // attribute KeyboardEvent.keyIdentifier
dom_externs.keyLocation;                // attribute KeyboardEvent.keyLocation
dom_externs.keyPath;                    // attribute IDBIndex.keyPath, attribute IDBObjectStore.keyPath
dom_externs.keyText;                    // attribute WebKitCSSKeyframeRule.keyText
dom_externs.keytype;                    // attribute HTMLKeygenElement.keytype
dom_externs.kind;                       // attribute DataTransferItem.kind, attribute HTMLTrackElement.kind, attribute TextTrack.kind
dom_externs.label;                      // attribute HTMLOptGroupElement.label, attribute HTMLOptionElement.label, attribute HTMLTrackElement.label, attribute TextTrack.label
dom_externs.labels;                     // attribute HTMLButtonElement.labels, attribute HTMLInputElement.labels, attribute HTMLKeygenElement.labels, attribute HTMLMeterElement.labels, attribute HTMLOutputElement.labels, attribute HTMLProgressElement.labels, attribute HTMLSelectElement.labels, attribute HTMLTextAreaElement.labels
dom_externs.lang;                       // attribute HTMLElement.lang
dom_externs.language;                   // attribute Navigator.language, attribute TextTrack.language
dom_externs.largeArcFlag;               // attribute SVGPathSegArcAbs.largeArcFlag, attribute SVGPathSegArcRel.largeArcFlag
dom_externs.lastChild;                  // attribute Node.lastChild, attribute SVGElementInstance.lastChild, operation TreeWalker.lastChild
dom_externs.lastElementChild;           // attribute Element.lastElementChild, attribute ElementTraversal.lastElementChild
dom_externs.lastEventId;                // attribute MessageEvent.lastEventId
dom_externs.lastModified;               // attribute Document.lastModified
dom_externs.lastModifiedDate;           // attribute File.lastModifiedDate
dom_externs.latitude;                   // attribute Coordinates.latitude
dom_externs.layerX;                     // attribute UIEvent.layerX
dom_externs.layerY;                     // attribute UIEvent.layerY
dom_externs.left;                       // attribute ClientRect.left, attribute Rect.left
dom_externs.length;                     // attribute CSSRuleList.length, attribute CSSStyleDeclaration.length, attribute CSSValueList.length, attribute CanvasPixelArray.length, attribute CharacterData.length, attribute ClientRectList.length, attribute DOMMimeTypeArray.length, attribute DOMPlugin.length, attribute DOMPluginArray.length, attribute DOMTokenList.length, attribute DOMWindow.length, attribute DataTransferItemList.length, attribute EntryArray.length, attribute EntryArraySync.length, attribute FileList.length, attribute FileWriter.length, attribute FileWriterSync.length, attribute Float32Array.length, attribute Float64Array.length, attribute HTMLAllCollection.length, attribute HTMLCollection.length, attribute HTMLFormElement.length, attribute HTMLOptionsCollection.length, attribute HTMLSelectElement.length, attribute History.length, attribute Int16Array.length, attribute Int32Array.length, attribute Int8Array.length, attribute MediaList.length, attribute NamedNodeMap.length, attribute NodeList.length, attribute SQLResultSetRowList.length, attribute SVGElementInstanceList.length, attribute SpeechInputResultList.length, attribute Storage.length, attribute StyleSheetList.length, attribute TextTrackCueList.length, attribute TimeRanges.length, attribute TouchList.length, attribute Uint16Array.length, attribute Uint32Array.length, attribute Uint8Array.length, attribute WebKitAnimationList.length
dom_externs.lengthAdjust;               // attribute SVGTextContentElement.lengthAdjust
dom_externs.lengthComputable;           // attribute ProgressEvent.lengthComputable
dom_externs.limitingConeAngle;          // attribute SVGFESpotLightElement.limitingConeAngle
dom_externs.line;                       // attribute JavaScriptCallFrame.line
dom_externs.lineCap;                    // attribute CanvasRenderingContext2D.lineCap
dom_externs.lineJoin;                   // attribute CanvasRenderingContext2D.lineJoin
dom_externs.lineNumber;                 // attribute ScriptProfileNode.lineNumber
dom_externs.linePosition;               // attribute TextTrackCue.linePosition
dom_externs.lineTo;                     // operation CanvasRenderingContext2D.lineTo
dom_externs.lineWidth;                  // attribute CanvasRenderingContext2D.lineWidth, operation WebGLRenderingContext.lineWidth
dom_externs.lineno;                     // attribute ErrorEvent.lineno
dom_externs.link;                       // attribute HTMLBodyElement.link
dom_externs.linkColor;                  // attribute HTMLDocument.linkColor
dom_externs.linkProgram;                // operation WebGLRenderingContext.linkProgram
dom_externs.links;                      // attribute Document.links
dom_externs.list;                       // attribute HTMLInputElement.list
dom_externs.listStyle;                  // attribute Counter.listStyle
dom_externs.load;                       // operation HTMLMediaElement.load
dom_externs.loadEventEnd;               // attribute PerformanceTiming.loadEventEnd
dom_externs.loadEventStart;             // attribute PerformanceTiming.loadEventStart
dom_externs.loaded;                     // operation InspectorFrontendHost.loaded, attribute ProgressEvent.loaded
dom_externs.localName;                  // attribute Node.localName
dom_externs.localizedStringsURL;        // operation InspectorFrontendHost.localizedStringsURL
dom_externs.location;                   // attribute DOMWindow.location, attribute Document.location, attribute HTMLFrameElement.location, attribute WorkerContext.location
dom_externs.locationbar;                // attribute DOMWindow.locationbar
dom_externs.log;                        // operation Console.log
dom_externs.longDesc;                   // attribute HTMLFrameElement.longDesc, attribute HTMLIFrameElement.longDesc, attribute HTMLImageElement.longDesc
dom_externs.longitude;                  // attribute Coordinates.longitude
dom_externs.lookupNamespaceURI;         // operation Node.lookupNamespaceURI, operation XPathNSResolver.lookupNamespaceURI
dom_externs.lookupPrefix;               // operation Node.lookupPrefix
dom_externs.loop;                       // attribute HTMLMarqueeElement.loop, attribute HTMLMediaElement.loop
dom_externs.loseContext;                // operation WebKitLoseContext.loseContext
dom_externs.low;                        // attribute HTMLMeterElement.low
dom_externs.lower;                      // attribute IDBKeyRange.lower
dom_externs.lowerBound;                 // operation IDBKeyRange.lowerBound
dom_externs.lowerOpen;                  // attribute IDBKeyRange.lowerOpen
dom_externs.lowsrc;                     // attribute HTMLImageElement.lowsrc
dom_externs.m11;                        // attribute WebKitCSSMatrix.m11
dom_externs.m12;                        // attribute WebKitCSSMatrix.m12
dom_externs.m13;                        // attribute WebKitCSSMatrix.m13
dom_externs.m14;                        // attribute WebKitCSSMatrix.m14
dom_externs.m21;                        // attribute WebKitCSSMatrix.m21
dom_externs.m22;                        // attribute WebKitCSSMatrix.m22
dom_externs.m23;                        // attribute WebKitCSSMatrix.m23
dom_externs.m24;                        // attribute WebKitCSSMatrix.m24
dom_externs.m31;                        // attribute WebKitCSSMatrix.m31
dom_externs.m32;                        // attribute WebKitCSSMatrix.m32
dom_externs.m33;                        // attribute WebKitCSSMatrix.m33
dom_externs.m34;                        // attribute WebKitCSSMatrix.m34
dom_externs.m41;                        // attribute WebKitCSSMatrix.m41
dom_externs.m42;                        // attribute WebKitCSSMatrix.m42
dom_externs.m43;                        // attribute WebKitCSSMatrix.m43
dom_externs.m44;                        // attribute WebKitCSSMatrix.m44
dom_externs.manifest;                   // attribute HTMLHtmlElement.manifest
dom_externs.marginHeight;               // attribute HTMLFrameElement.marginHeight, attribute HTMLIFrameElement.marginHeight
dom_externs.marginWidth;                // attribute HTMLFrameElement.marginWidth, attribute HTMLIFrameElement.marginWidth
dom_externs.markTimeline;               // operation Console.markTimeline
dom_externs.markerHeight;               // attribute SVGMarkerElement.markerHeight
dom_externs.markerUnits;                // attribute SVGMarkerElement.markerUnits
dom_externs.markerWidth;                // attribute SVGMarkerElement.markerWidth
dom_externs.maskContentUnits;           // attribute SVGMaskElement.maskContentUnits
dom_externs.maskUnits;                  // attribute SVGMaskElement.maskUnits
dom_externs.matchMedia;                 // operation DOMWindow.matchMedia
dom_externs.matchMedium;                // operation StyleMedia.matchMedium
dom_externs.matches;                    // attribute MediaQueryList.matches
dom_externs.matrix;                     // attribute SVGTransform.matrix
dom_externs.matrixTransform;            // operation SVGPoint.matrixTransform
dom_externs.max;                        // attribute HTMLInputElement.max, attribute HTMLMeterElement.max, attribute HTMLProgressElement.max
dom_externs.maxLength;                  // attribute HTMLInputElement.maxLength, attribute HTMLTextAreaElement.maxLength
dom_externs.measureText;                // operation CanvasRenderingContext2D.measureText
dom_externs.media;                      // attribute CSSImportRule.media, attribute CSSMediaRule.media, attribute HTMLLinkElement.media, attribute HTMLSourceElement.media, attribute HTMLStyleElement.media, attribute MediaQueryList.media, attribute SVGStyleElement.media, attribute StyleSheet.media
dom_externs.mediaText;                  // attribute MediaList.mediaText
dom_externs.meetOrSlice;                // attribute SVGPreserveAspectRatio.meetOrSlice
dom_externs.memory;                     // attribute Console.memory, attribute Performance.memory
dom_externs.menubar;                    // attribute DOMWindow.menubar
dom_externs.message;                    // attribute DOMException.message, attribute ErrorEvent.message, attribute EventException.message, attribute FileException.message, attribute IDBDatabaseError.message, attribute IDBDatabaseException.message, attribute OperationNotAllowedException.message, attribute PositionError.message, attribute RangeException.message, attribute SQLError.message, attribute SQLException.message, attribute SVGException.message, attribute XMLHttpRequestException.message, attribute XPathException.message
dom_externs.metaKey;                    // attribute KeyboardEvent.metaKey, attribute MouseEvent.metaKey, attribute TouchEvent.metaKey, attribute WheelEvent.metaKey
dom_externs.method;                     // attribute HTMLFormElement.method, attribute SVGTextPathElement.method
dom_externs.mimeTypes;                  // attribute Navigator.mimeTypes
dom_externs.min;                        // attribute HTMLInputElement.min, attribute HTMLMeterElement.min
dom_externs.miterLimit;                 // attribute CanvasRenderingContext2D.miterLimit
dom_externs.mode;                       // attribute IDBTransaction.mode, attribute SVGFEBlendElement.mode, attribute TextTrack.mode
dom_externs.modificationTime;           // attribute Metadata.modificationTime
dom_externs.modify;                     // operation DOMSelection.modify
dom_externs.moveBy;                     // operation DOMWindow.moveBy
dom_externs.moveTo;                     // operation CanvasRenderingContext2D.moveTo, operation DOMWindow.moveTo, operation Entry.moveTo, operation EntrySync.moveTo
dom_externs.moveWindowBy;               // operation InspectorFrontendHost.moveWindowBy
dom_externs.multiple;                   // attribute HTMLInputElement.multiple, attribute HTMLSelectElement.multiple
dom_externs.multiply;                   // operation SVGMatrix.multiply, operation WebKitCSSMatrix.multiply
dom_externs.muted;                      // attribute HTMLMediaElement.muted
dom_externs.name;                       // attribute Attr.name, attribute DOMException.name, attribute DOMFileSystem.name, attribute DOMFileSystemSync.name, attribute DOMPlugin.name, attribute DOMWindow.name, attribute DocumentType.name, attribute Entry.name, attribute EntrySync.name, attribute EventException.name, attribute File.name, attribute FileException.name, attribute HTMLAnchorElement.name, attribute HTMLAppletElement.name, attribute HTMLButtonElement.name, attribute HTMLEmbedElement.name, attribute HTMLFormElement.name, attribute HTMLFrameElement.name, attribute HTMLIFrameElement.name, attribute HTMLImageElement.name, attribute HTMLInputElement.name, attribute HTMLKeygenElement.name, attribute HTMLMapElement.name, attribute HTMLMetaElement.name, attribute HTMLObjectElement.name, attribute HTMLOutputElement.name, attribute HTMLParamElement.name, attribute HTMLSelectElement.name, attribute HTMLTextAreaElement.name, attribute IDBDatabase.name, attribute IDBDatabaseException.name, attribute IDBIndex.name, attribute IDBObjectStore.name, attribute OperationNotAllowedException.name, attribute RangeException.name, attribute SVGException.name, attribute SharedWorkercontext.name, attribute WebGLActiveInfo.name, attribute WebKitAnimation.name, attribute WebKitCSSKeyframesRule.name, attribute XMLHttpRequestException.name, attribute XPathException.name
dom_externs.namedItem;                  // operation DOMMimeTypeArray.namedItem, operation DOMPlugin.namedItem, operation DOMPluginArray.namedItem, operation HTMLAllCollection.namedItem, operation HTMLCollection.namedItem, operation HTMLSelectElement.namedItem
dom_externs.namespaceURI;               // attribute Node.namespaceURI
dom_externs.naturalHeight;              // attribute HTMLImageElement.naturalHeight
dom_externs.naturalWidth;               // attribute HTMLImageElement.naturalWidth
dom_externs.navigation;                 // attribute Performance.navigation
dom_externs.navigationStart;            // attribute PerformanceTiming.navigationStart
dom_externs.navigator;                  // attribute DOMWindow.navigator, attribute WorkerContext.navigator
dom_externs.nearestViewportElement;     // attribute SVGAElement.nearestViewportElement, attribute SVGCircleElement.nearestViewportElement, attribute SVGClipPathElement.nearestViewportElement, attribute SVGDefsElement.nearestViewportElement, attribute SVGEllipseElement.nearestViewportElement, attribute SVGForeignObjectElement.nearestViewportElement, attribute SVGGElement.nearestViewportElement, attribute SVGImageElement.nearestViewportElement, attribute SVGLineElement.nearestViewportElement, attribute SVGLocatable.nearestViewportElement, attribute SVGPathElement.nearestViewportElement, attribute SVGPolygonElement.nearestViewportElement, attribute SVGPolylineElement.nearestViewportElement, attribute SVGRectElement.nearestViewportElement, attribute SVGSVGElement.nearestViewportElement, attribute SVGSwitchElement.nearestViewportElement, attribute SVGTextElement.nearestViewportElement, attribute SVGUseElement.nearestViewportElement
dom_externs.networkState;               // attribute HTMLMediaElement.networkState
dom_externs.newScale;                   // attribute SVGZoomEvent.newScale
dom_externs.newTranslate;               // attribute SVGZoomEvent.newTranslate
dom_externs.newURL;                     // attribute HashChangeEvent.newURL
dom_externs.newValue;                   // attribute MutationEvent.newValue, attribute StorageEvent.newValue
dom_externs.newValueSpecifiedUnits;     // operation SVGAngle.newValueSpecifiedUnits, operation SVGLength.newValueSpecifiedUnits
dom_externs.nextElementSibling;         // attribute Element.nextElementSibling, attribute ElementTraversal.nextElementSibling
dom_externs.nextNode;                   // operation NodeIterator.nextNode, operation TreeWalker.nextNode
dom_externs.nextSibling;                // attribute MutationRecord.nextSibling, attribute Node.nextSibling, attribute SVGElementInstance.nextSibling, operation TreeWalker.nextSibling
dom_externs.noHref;                     // attribute HTMLAreaElement.noHref
dom_externs.noResize;                   // attribute HTMLFrameElement.noResize
dom_externs.noShade;                    // attribute HTMLHRElement.noShade
dom_externs.noValidate;                 // attribute HTMLFormElement.noValidate
dom_externs.noWrap;                     // attribute HTMLTableCellElement.noWrap
dom_externs.nodeName;                   // attribute Node.nodeName
dom_externs.nodeType;                   // attribute Node.nodeType
dom_externs.nodeValue;                  // attribute Node.nodeValue
dom_externs.normalize;                  // operation Node.normalize
dom_externs.normalizedPathSegList;      // attribute SVGPathElement.normalizedPathSegList
dom_externs.notationName;               // attribute Entity.notationName
dom_externs.notations;                  // attribute DocumentType.notations
dom_externs.numOctaves;                 // attribute SVGFETurbulenceElement.numOctaves
dom_externs.numberOfCalls;              // attribute ScriptProfileNode.numberOfCalls
dom_externs.numberOfItems;              // attribute SVGLengthList.numberOfItems, attribute SVGNumberList.numberOfItems, attribute SVGPathSegList.numberOfItems, attribute SVGPointList.numberOfItems, attribute SVGStringList.numberOfItems, attribute SVGTransformList.numberOfItems
dom_externs.numberValue;                // attribute XPathResult.numberValue
dom_externs.object;                     // attribute HTMLAppletElement.object
dom_externs.objectStore;                // attribute IDBIndex.objectStore, operation IDBTransaction.objectStore
dom_externs.offscreenBuffering;         // attribute DOMWindow.offscreenBuffering
dom_externs.offset;                     // attribute SVGComponentTransferFunctionElement.offset, attribute SVGStopElement.offset
dom_externs.offsetHeight;               // attribute Element.offsetHeight
dom_externs.offsetLeft;                 // attribute Element.offsetLeft
dom_externs.offsetParent;               // attribute Element.offsetParent
dom_externs.offsetTop;                  // attribute Element.offsetTop
dom_externs.offsetWidth;                // attribute Element.offsetWidth
dom_externs.offsetX;                    // attribute MouseEvent.offsetX, attribute WheelEvent.offsetX
dom_externs.offsetY;                    // attribute MouseEvent.offsetY, attribute WheelEvent.offsetY
dom_externs.oldURL;                     // attribute HashChangeEvent.oldURL
dom_externs.oldValue;                   // attribute MutationRecord.oldValue, attribute StorageEvent.oldValue
dom_externs.onLine;                     // attribute Navigator.onLine, attribute WorkerNavigator.onLine
dom_externs.onabort;                    // attribute DOMWindow.onabort, attribute Document.onabort, attribute Element.onabort, attribute FileReader.onabort, attribute FileWriter.onabort, attribute IDBDatabase.onabort, attribute IDBTransaction.onabort, attribute SVGElementInstance.onabort, attribute XMLHttpRequest.onabort, attribute XMLHttpRequestUpload.onabort
dom_externs.onbeforecopy;               // attribute Document.onbeforecopy, attribute Element.onbeforecopy, attribute SVGElementInstance.onbeforecopy
dom_externs.onbeforecut;                // attribute Document.onbeforecut, attribute Element.onbeforecut, attribute SVGElementInstance.onbeforecut
dom_externs.onbeforepaste;              // attribute Document.onbeforepaste, attribute Element.onbeforepaste, attribute SVGElementInstance.onbeforepaste
dom_externs.onbeforeunload;             // attribute DOMWindow.onbeforeunload, attribute HTMLBodyElement.onbeforeunload, attribute HTMLFrameSetElement.onbeforeunload
dom_externs.onblocked;                  // attribute IDBVersionChangeRequest.onblocked
dom_externs.onblur;                     // attribute DOMWindow.onblur, attribute Document.onblur, attribute Element.onblur, attribute HTMLBodyElement.onblur, attribute HTMLFrameSetElement.onblur, attribute SVGElementInstance.onblur
dom_externs.oncached;                   // attribute DOMApplicationCache.oncached
dom_externs.oncanplay;                  // attribute DOMWindow.oncanplay
dom_externs.oncanplaythrough;           // attribute DOMWindow.oncanplaythrough
dom_externs.onchange;                   // attribute DOMWindow.onchange, attribute Document.onchange, attribute Element.onchange, attribute SVGElementInstance.onchange
dom_externs.onchecking;                 // attribute DOMApplicationCache.onchecking
dom_externs.onclick;                    // attribute DOMWindow.onclick, attribute Document.onclick, attribute Element.onclick, attribute Notification.onclick, attribute SVGElementInstance.onclick
dom_externs.onclose;                    // attribute Notification.onclose, attribute WebSocket.onclose
dom_externs.oncomplete;                 // attribute IDBTransaction.oncomplete
dom_externs.onconnect;                  // attribute SharedWorkercontext.onconnect
dom_externs.oncontextmenu;              // attribute DOMWindow.oncontextmenu, attribute Document.oncontextmenu, attribute Element.oncontextmenu, attribute SVGElementInstance.oncontextmenu
dom_externs.oncopy;                     // attribute Document.oncopy, attribute Element.oncopy, attribute SVGElementInstance.oncopy
dom_externs.oncut;                      // attribute Document.oncut, attribute Element.oncut, attribute SVGElementInstance.oncut
dom_externs.ondblclick;                 // attribute DOMWindow.ondblclick, attribute Document.ondblclick, attribute Element.ondblclick, attribute SVGElementInstance.ondblclick
dom_externs.ondevicemotion;             // attribute DOMWindow.ondevicemotion
dom_externs.ondeviceorientation;        // attribute DOMWindow.ondeviceorientation
dom_externs.ondisplay;                  // attribute Notification.ondisplay
dom_externs.ondownloading;              // attribute DOMApplicationCache.ondownloading
dom_externs.ondrag;                     // attribute DOMWindow.ondrag, attribute Document.ondrag, attribute Element.ondrag, attribute SVGElementInstance.ondrag
dom_externs.ondragend;                  // attribute DOMWindow.ondragend, attribute Document.ondragend, attribute Element.ondragend, attribute SVGElementInstance.ondragend
dom_externs.ondragenter;                // attribute DOMWindow.ondragenter, attribute Document.ondragenter, attribute Element.ondragenter, attribute SVGElementInstance.ondragenter
dom_externs.ondragleave;                // attribute DOMWindow.ondragleave, attribute Document.ondragleave, attribute Element.ondragleave, attribute SVGElementInstance.ondragleave
dom_externs.ondragover;                 // attribute DOMWindow.ondragover, attribute Document.ondragover, attribute Element.ondragover, attribute SVGElementInstance.ondragover
dom_externs.ondragstart;                // attribute DOMWindow.ondragstart, attribute Document.ondragstart, attribute Element.ondragstart, attribute SVGElementInstance.ondragstart
dom_externs.ondrop;                     // attribute DOMWindow.ondrop, attribute Document.ondrop, attribute Element.ondrop, attribute SVGElementInstance.ondrop
dom_externs.ondurationchange;           // attribute DOMWindow.ondurationchange
dom_externs.onemptied;                  // attribute DOMWindow.onemptied
dom_externs.onended;                    // attribute DOMWindow.onended
dom_externs.onerror;                    // attribute AbstractWorker.onerror, attribute DOMApplicationCache.onerror, attribute DOMWindow.onerror, attribute Document.onerror, attribute Element.onerror, attribute EventSource.onerror, attribute FileReader.onerror, attribute FileWriter.onerror, attribute HTMLBodyElement.onerror, attribute HTMLFrameSetElement.onerror, attribute IDBDatabase.onerror, attribute IDBRequest.onerror, attribute IDBTransaction.onerror, attribute Notification.onerror, attribute SVGElementInstance.onerror, attribute WebSocket.onerror, attribute WorkerContext.onerror, attribute XMLHttpRequest.onerror, attribute XMLHttpRequestUpload.onerror
dom_externs.onfocus;                    // attribute DOMWindow.onfocus, attribute Document.onfocus, attribute Element.onfocus, attribute HTMLBodyElement.onfocus, attribute HTMLFrameSetElement.onfocus, attribute SVGElementInstance.onfocus
dom_externs.onhashchange;               // attribute DOMWindow.onhashchange, attribute HTMLBodyElement.onhashchange, attribute HTMLFrameSetElement.onhashchange
dom_externs.oninput;                    // attribute DOMWindow.oninput, attribute Document.oninput, attribute Element.oninput, attribute SVGElementInstance.oninput
dom_externs.oninvalid;                  // attribute DOMWindow.oninvalid, attribute Document.oninvalid, attribute Element.oninvalid
dom_externs.onkeydown;                  // attribute DOMWindow.onkeydown, attribute Document.onkeydown, attribute Element.onkeydown, attribute SVGElementInstance.onkeydown
dom_externs.onkeypress;                 // attribute DOMWindow.onkeypress, attribute Document.onkeypress, attribute Element.onkeypress, attribute SVGElementInstance.onkeypress
dom_externs.onkeyup;                    // attribute DOMWindow.onkeyup, attribute Document.onkeyup, attribute Element.onkeyup, attribute SVGElementInstance.onkeyup
dom_externs.onload;                     // attribute DOMWindow.onload, attribute Document.onload, attribute Element.onload, attribute FileReader.onload, attribute HTMLBodyElement.onload, attribute HTMLFrameSetElement.onload, attribute SVGElementInstance.onload, attribute XMLHttpRequest.onload, attribute XMLHttpRequestUpload.onload
dom_externs.onloadeddata;               // attribute DOMWindow.onloadeddata
dom_externs.onloadedmetadata;           // attribute DOMWindow.onloadedmetadata
dom_externs.onloadend;                  // attribute FileReader.onloadend
dom_externs.onloadstart;                // attribute DOMWindow.onloadstart, attribute FileReader.onloadstart, attribute XMLHttpRequest.onloadstart, attribute XMLHttpRequestUpload.onloadstart
dom_externs.only;                       // operation IDBKeyRange.only
dom_externs.onmessage;                  // attribute DOMWindow.onmessage, attribute DedicatedWorkerContext.onmessage, attribute EventSource.onmessage, attribute HTMLBodyElement.onmessage, attribute HTMLFrameSetElement.onmessage, attribute MessagePort.onmessage, attribute WebSocket.onmessage, attribute Worker.onmessage
dom_externs.onmousedown;                // attribute DOMWindow.onmousedown, attribute Document.onmousedown, attribute Element.onmousedown, attribute SVGElementInstance.onmousedown
dom_externs.onmousemove;                // attribute DOMWindow.onmousemove, attribute Document.onmousemove, attribute Element.onmousemove, attribute SVGElementInstance.onmousemove
dom_externs.onmouseout;                 // attribute DOMWindow.onmouseout, attribute Document.onmouseout, attribute Element.onmouseout, attribute SVGElementInstance.onmouseout
dom_externs.onmouseover;                // attribute DOMWindow.onmouseover, attribute Document.onmouseover, attribute Element.onmouseover, attribute SVGElementInstance.onmouseover
dom_externs.onmouseup;                  // attribute DOMWindow.onmouseup, attribute Document.onmouseup, attribute Element.onmouseup, attribute SVGElementInstance.onmouseup
dom_externs.onmousewheel;               // attribute DOMWindow.onmousewheel, attribute Document.onmousewheel, attribute Element.onmousewheel, attribute SVGElementInstance.onmousewheel
dom_externs.onnoupdate;                 // attribute DOMApplicationCache.onnoupdate
dom_externs.onobsolete;                 // attribute DOMApplicationCache.onobsolete
dom_externs.onoffline;                  // attribute DOMWindow.onoffline, attribute HTMLBodyElement.onoffline, attribute HTMLFrameSetElement.onoffline
dom_externs.ononline;                   // attribute DOMWindow.ononline, attribute HTMLBodyElement.ononline, attribute HTMLFrameSetElement.ononline
dom_externs.onopen;                     // attribute EventSource.onopen, attribute WebSocket.onopen
dom_externs.onorientationchange;        // attribute HTMLBodyElement.onorientationchange, attribute HTMLFrameSetElement.onorientationchange
dom_externs.onpagehide;                 // attribute DOMWindow.onpagehide
dom_externs.onpageshow;                 // attribute DOMWindow.onpageshow
dom_externs.onpaste;                    // attribute Document.onpaste, attribute Element.onpaste, attribute SVGElementInstance.onpaste
dom_externs.onpause;                    // attribute DOMWindow.onpause
dom_externs.onplay;                     // attribute DOMWindow.onplay
dom_externs.onplaying;                  // attribute DOMWindow.onplaying
dom_externs.onpopstate;                 // attribute DOMWindow.onpopstate, attribute HTMLBodyElement.onpopstate, attribute HTMLFrameSetElement.onpopstate
dom_externs.onprogress;                 // attribute DOMApplicationCache.onprogress, attribute DOMWindow.onprogress, attribute FileReader.onprogress, attribute FileWriter.onprogress, attribute XMLHttpRequest.onprogress, attribute XMLHttpRequestUpload.onprogress
dom_externs.onratechange;               // attribute DOMWindow.onratechange
dom_externs.onreadystatechange;         // attribute Document.onreadystatechange, attribute XMLHttpRequest.onreadystatechange
dom_externs.onreset;                    // attribute DOMWindow.onreset, attribute Document.onreset, attribute Element.onreset, attribute SVGElementInstance.onreset
dom_externs.onresize;                   // attribute DOMWindow.onresize, attribute HTMLBodyElement.onresize, attribute HTMLFrameSetElement.onresize, attribute SVGElementInstance.onresize
dom_externs.onscroll;                   // attribute DOMWindow.onscroll, attribute Document.onscroll, attribute Element.onscroll, attribute SVGElementInstance.onscroll
dom_externs.onsearch;                   // attribute DOMWindow.onsearch, attribute Document.onsearch, attribute Element.onsearch, attribute SVGElementInstance.onsearch
dom_externs.onseeked;                   // attribute DOMWindow.onseeked
dom_externs.onseeking;                  // attribute DOMWindow.onseeking
dom_externs.onselect;                   // attribute DOMWindow.onselect, attribute Document.onselect, attribute Element.onselect, attribute SVGElementInstance.onselect
dom_externs.onselectionchange;          // attribute Document.onselectionchange
dom_externs.onselectstart;              // attribute Document.onselectstart, attribute Element.onselectstart, attribute SVGElementInstance.onselectstart
dom_externs.onstalled;                  // attribute DOMWindow.onstalled
dom_externs.onstorage;                  // attribute DOMWindow.onstorage, attribute HTMLBodyElement.onstorage, attribute HTMLFrameSetElement.onstorage
dom_externs.onsubmit;                   // attribute DOMWindow.onsubmit, attribute Document.onsubmit, attribute Element.onsubmit, attribute SVGElementInstance.onsubmit
dom_externs.onsuccess;                  // attribute IDBRequest.onsuccess
dom_externs.onsuspend;                  // attribute DOMWindow.onsuspend
dom_externs.ontimeupdate;               // attribute DOMWindow.ontimeupdate
dom_externs.ontouchcancel;              // attribute DOMWindow.ontouchcancel, attribute Document.ontouchcancel, attribute Element.ontouchcancel
dom_externs.ontouchend;                 // attribute DOMWindow.ontouchend, attribute Document.ontouchend, attribute Element.ontouchend
dom_externs.ontouchmove;                // attribute DOMWindow.ontouchmove, attribute Document.ontouchmove, attribute Element.ontouchmove
dom_externs.ontouchstart;               // attribute DOMWindow.ontouchstart, attribute Document.ontouchstart, attribute Element.ontouchstart
dom_externs.onunload;                   // attribute DOMWindow.onunload, attribute HTMLBodyElement.onunload, attribute HTMLFrameSetElement.onunload, attribute SVGElementInstance.onunload
dom_externs.onupdateready;              // attribute DOMApplicationCache.onupdateready
dom_externs.onversionchange;            // attribute IDBDatabase.onversionchange
dom_externs.onvolumechange;             // attribute DOMWindow.onvolumechange
dom_externs.onwaiting;                  // attribute DOMWindow.onwaiting
dom_externs.onwebkitanimationend;       // attribute DOMWindow.onwebkitanimationend
dom_externs.onwebkitanimationiteration;  // attribute DOMWindow.onwebkitanimationiteration
dom_externs.onwebkitanimationstart;     // attribute DOMWindow.onwebkitanimationstart
dom_externs.onwebkitfullscreenchange;   // attribute Document.onwebkitfullscreenchange, attribute Element.onwebkitfullscreenchange
dom_externs.onwebkitspeechchange;       // attribute HTMLInputElement.onwebkitspeechchange
dom_externs.onwebkittransitionend;      // attribute DOMWindow.onwebkittransitionend
dom_externs.onwrite;                    // attribute FileWriter.onwrite
dom_externs.onwriteend;                 // attribute FileWriter.onwriteend
dom_externs.onwritestart;               // attribute FileWriter.onwritestart
dom_externs.open;                       // operation DOMWindow.open, attribute HTMLDetailsElement.open, operation HTMLDocument.open, operation IDBFactory.open, operation XMLHttpRequest.open
dom_externs.openCursor;                 // operation IDBIndex.openCursor, operation IDBObjectStore.openCursor
dom_externs.openKeyCursor;              // operation IDBIndex.openKeyCursor
dom_externs.opener;                     // attribute DOMWindow.opener
dom_externs.operationType;              // attribute WebKitCSSFilterValue.operationType, attribute WebKitCSSTransformValue.operationType
dom_externs.operator;                   // attribute SVGFECompositeElement.operator, attribute SVGFEMorphologyElement.operator
dom_externs.optimum;                    // attribute HTMLMeterElement.optimum
dom_externs.options;                    // attribute HTMLDataListElement.options, attribute HTMLSelectElement.options
dom_externs.orderX;                     // attribute SVGFEConvolveMatrixElement.orderX
dom_externs.orderY;                     // attribute SVGFEConvolveMatrixElement.orderY
dom_externs.orient;                     // attribute OverflowEvent.orient
dom_externs.orientAngle;                // attribute SVGMarkerElement.orientAngle
dom_externs.orientType;                 // attribute SVGMarkerElement.orientType
dom_externs.origin;                     // attribute HTMLAnchorElement.origin, attribute Location.origin, attribute MessageEvent.origin
dom_externs.outerHTML;                  // attribute HTMLElement.outerHTML
dom_externs.outerHeight;                // attribute DOMWindow.outerHeight
dom_externs.outerText;                  // attribute HTMLElement.outerText
dom_externs.outerWidth;                 // attribute DOMWindow.outerWidth
dom_externs.overrideMimeType;           // operation XMLHttpRequest.overrideMimeType
dom_externs.ownerDocument;              // attribute Node.ownerDocument
dom_externs.ownerElement;               // attribute Attr.ownerElement
dom_externs.ownerNode;                  // attribute StyleSheet.ownerNode
dom_externs.ownerRule;                  // attribute CSSStyleSheet.ownerRule
dom_externs.ownerSVGElement;            // attribute SVGElement.ownerSVGElement
dom_externs.pageX;                      // attribute Touch.pageX, attribute UIEvent.pageX
dom_externs.pageXOffset;                // attribute DOMWindow.pageXOffset
dom_externs.pageY;                      // attribute Touch.pageY, attribute UIEvent.pageY
dom_externs.pageYOffset;                // attribute DOMWindow.pageYOffset
dom_externs.paintType;                  // attribute SVGPaint.paintType
dom_externs.parent;                     // attribute DOMWindow.parent
dom_externs.parentElement;              // attribute Node.parentElement
dom_externs.parentNode;                 // attribute Node.parentNode, attribute SVGElementInstance.parentNode, operation TreeWalker.parentNode
dom_externs.parentRule;                 // attribute CSSRule.parentRule, attribute CSSStyleDeclaration.parentRule
dom_externs.parentStyleSheet;           // attribute CSSRule.parentStyleSheet, attribute StyleSheet.parentStyleSheet
dom_externs.parseFromString;            // operation DOMParser.parseFromString
dom_externs.pathLength;                 // attribute SVGPathElement.pathLength
dom_externs.pathSegList;                // attribute SVGPathElement.pathSegList
dom_externs.pathSegType;                // attribute SVGPathSeg.pathSegType
dom_externs.pathSegTypeAsLetter;        // attribute SVGPathSeg.pathSegTypeAsLetter
dom_externs.pathname;                   // attribute HTMLAnchorElement.pathname, attribute HTMLAreaElement.pathname, attribute Location.pathname, attribute WorkerLocation.pathname
dom_externs.pattern;                    // attribute HTMLInputElement.pattern
dom_externs.patternContentUnits;        // attribute SVGPatternElement.patternContentUnits
dom_externs.patternMismatch;            // attribute ValidityState.patternMismatch
dom_externs.patternTransform;           // attribute SVGPatternElement.patternTransform
dom_externs.patternUnits;               // attribute SVGPatternElement.patternUnits
dom_externs.pause;                      // operation HTMLMediaElement.pause, operation WebKitAnimation.pause
dom_externs.pauseAnimations;            // operation SVGSVGElement.pauseAnimations
dom_externs.pauseOnExit;                // attribute TextTrackCue.pauseOnExit
dom_externs.paused;                     // attribute HTMLMediaElement.paused, attribute WebKitAnimation.paused
dom_externs.performance;                // attribute DOMWindow.performance
dom_externs.persisted;                  // attribute PageTransitionEvent.persisted
dom_externs.personalbar;                // attribute DOMWindow.personalbar
dom_externs.ping;                       // attribute HTMLAnchorElement.ping, attribute HTMLAreaElement.ping
dom_externs.pixelDepth;                 // attribute Screen.pixelDepth
dom_externs.pixelStorei;                // operation WebGLRenderingContext.pixelStorei
dom_externs.pixelUnitToMillimeterX;     // attribute SVGSVGElement.pixelUnitToMillimeterX
dom_externs.pixelUnitToMillimeterY;     // attribute SVGSVGElement.pixelUnitToMillimeterY
dom_externs.placeholder;                // attribute HTMLInputElement.placeholder, attribute HTMLTextAreaElement.placeholder
dom_externs.platform;                   // operation InspectorFrontendHost.platform, attribute Navigator.platform, attribute WorkerNavigator.platform
dom_externs.play;                       // operation HTMLMediaElement.play, operation WebKitAnimation.play
dom_externs.playbackRate;               // attribute HTMLMediaElement.playbackRate
dom_externs.played;                     // attribute HTMLMediaElement.played
dom_externs.plugins;                    // attribute HTMLDocument.plugins, attribute Navigator.plugins
dom_externs.pointerBeforeReferenceNode;  // attribute NodeIterator.pointerBeforeReferenceNode
dom_externs.points;                     // attribute SVGPolygonElement.points, attribute SVGPolylineElement.points
dom_externs.pointsAtX;                  // attribute SVGFESpotLightElement.pointsAtX
dom_externs.pointsAtY;                  // attribute SVGFESpotLightElement.pointsAtY
dom_externs.pointsAtZ;                  // attribute SVGFESpotLightElement.pointsAtZ
dom_externs.polygonOffset;              // operation WebGLRenderingContext.polygonOffset
dom_externs.port;                       // attribute HTMLAnchorElement.port, attribute HTMLAreaElement.port, operation InspectorFrontendHost.port, attribute Location.port, attribute SharedWorker.port, attribute WorkerLocation.port
dom_externs.port1;                      // attribute MessageChannel.port1
dom_externs.port2;                      // attribute MessageChannel.port2
dom_externs.ports;                      // attribute MessageEvent.ports
dom_externs.position;                   // attribute FileWriter.position, attribute FileWriterSync.position, attribute HTMLProgressElement.position, attribute XMLHttpRequestProgressEvent.position
dom_externs.postMessage;                // operation DOMWindow.postMessage, operation DedicatedWorkerContext.postMessage, operation MessagePort.postMessage, operation Worker.postMessage
dom_externs.poster;                     // attribute HTMLVideoElement.poster
dom_externs.preferredStylesheetSet;     // attribute Document.preferredStylesheetSet
dom_externs.prefix;                     // attribute Node.prefix
dom_externs.preload;                    // attribute HTMLMediaElement.preload
dom_externs.premultipliedAlpha;         // attribute WebGLContextAttributes.premultipliedAlpha
dom_externs.preserveAlpha;              // attribute SVGFEConvolveMatrixElement.preserveAlpha
dom_externs.preserveAspectRatio;        // attribute SVGFEImageElement.preserveAspectRatio, attribute SVGFitToViewBox.preserveAspectRatio, attribute SVGImageElement.preserveAspectRatio, attribute SVGMarkerElement.preserveAspectRatio, attribute SVGPatternElement.preserveAspectRatio, attribute SVGSVGElement.preserveAspectRatio, attribute SVGSymbolElement.preserveAspectRatio, attribute SVGViewElement.preserveAspectRatio, attribute SVGViewSpec.preserveAspectRatio
dom_externs.preserveAspectRatioString;  // attribute SVGViewSpec.preserveAspectRatioString
dom_externs.preserveDrawingBuffer;      // attribute WebGLContextAttributes.preserveDrawingBuffer
dom_externs.prevValue;                  // attribute MutationEvent.prevValue
dom_externs.preventDefault;             // operation Event.preventDefault
dom_externs.previousElementSibling;     // attribute Element.previousElementSibling, attribute ElementTraversal.previousElementSibling
dom_externs.previousNode;               // operation NodeIterator.previousNode, operation TreeWalker.previousNode
dom_externs.previousScale;              // attribute SVGZoomEvent.previousScale
dom_externs.previousSibling;            // attribute MutationRecord.previousSibling, attribute Node.previousSibling, attribute SVGElementInstance.previousSibling, operation TreeWalker.previousSibling
dom_externs.previousTranslate;          // attribute SVGZoomEvent.previousTranslate
dom_externs.primaryKey;                 // attribute IDBCursor.primaryKey
dom_externs.primitiveType;              // attribute CSSPrimitiveValue.primitiveType
dom_externs.primitiveUnits;             // attribute SVGFilterElement.primitiveUnits
dom_externs.print;                      // operation DOMWindow.print
dom_externs.product;                    // attribute Navigator.product
dom_externs.productSub;                 // attribute Navigator.productSub
dom_externs.profile;                    // attribute HTMLHeadElement.profile
dom_externs.prompt;                     // operation DOMWindow.prompt, attribute HTMLIsIndexElement.prompt
dom_externs.propertyName;               // attribute WebKitTransitionEvent.propertyName
dom_externs.protocol;                   // attribute HTMLAnchorElement.protocol, attribute HTMLAreaElement.protocol, attribute Location.protocol, attribute WebSocket.protocol, attribute WorkerLocation.protocol
dom_externs.publicId;                   // attribute DocumentType.publicId, attribute Entity.publicId, attribute Notation.publicId
dom_externs.pushState;                  // operation History.pushState
dom_externs.put;                        // operation IDBObjectStore.put
dom_externs.putImageData;               // operation CanvasRenderingContext2D.putImageData
dom_externs.quadraticCurveTo;           // operation CanvasRenderingContext2D.quadraticCurveTo
dom_externs.queryChanged;               // operation MediaQueryListListener.queryChanged
dom_externs.queryCommandEnabled;        // operation Document.queryCommandEnabled
dom_externs.queryCommandIndeterm;       // operation Document.queryCommandIndeterm
dom_externs.queryCommandState;          // operation Document.queryCommandState
dom_externs.queryCommandSupported;      // operation Document.queryCommandSupported
dom_externs.queryCommandValue;          // operation Document.queryCommandValue
dom_externs.querySelector;              // operation Document.querySelector, operation DocumentFragment.querySelector, operation Element.querySelector, operation NodeSelector.querySelector
dom_externs.querySelectorAll;           // operation Document.querySelectorAll, operation DocumentFragment.querySelectorAll, operation Element.querySelectorAll, operation NodeSelector.querySelectorAll
dom_externs.queryUsageAndQuota;         // operation StorageInfo.queryUsageAndQuota
dom_externs.r;                          // attribute SVGCircleElement.r, attribute SVGRadialGradientElement.r
dom_externs.r1;                         // attribute SVGPathSegArcAbs.r1, attribute SVGPathSegArcRel.r1
dom_externs.r2;                         // attribute SVGPathSegArcAbs.r2, attribute SVGPathSegArcRel.r2
dom_externs.radiusX;                    // attribute SVGFEMorphologyElement.radiusX
dom_externs.radiusY;                    // attribute SVGFEMorphologyElement.radiusY
dom_externs.rangeCount;                 // attribute DOMSelection.rangeCount
dom_externs.rangeOverflow;              // attribute ValidityState.rangeOverflow
dom_externs.rangeUnderflow;             // attribute ValidityState.rangeUnderflow
dom_externs.readAsArrayBuffer;          // operation FileReader.readAsArrayBuffer, operation FileReaderSync.readAsArrayBuffer
dom_externs.readAsBinaryString;         // operation FileReader.readAsBinaryString, operation FileReaderSync.readAsBinaryString
dom_externs.readAsDataURL;              // operation FileReader.readAsDataURL, operation FileReaderSync.readAsDataURL
dom_externs.readAsText;                 // operation FileReader.readAsText, operation FileReaderSync.readAsText
dom_externs.readEntries;                // operation DirectoryReader.readEntries, operation DirectoryReaderSync.readEntries
dom_externs.readOnly;                   // attribute HTMLInputElement.readOnly, attribute HTMLTextAreaElement.readOnly
dom_externs.readPixels;                 // operation WebGLRenderingContext.readPixels
dom_externs.readTransaction;            // operation Database.readTransaction, operation DatabaseSync.readTransaction
dom_externs.readyState;                 // attribute Document.readyState, attribute EventSource.readyState, attribute FileReader.readyState, attribute FileWriter.readyState, attribute HTMLMediaElement.readyState, attribute IDBRequest.readyState, attribute TextTrack.readyState, attribute WebSocket.readyState, attribute XMLHttpRequest.readyState
dom_externs.reason;                     // attribute CloseEvent.reason
dom_externs.recordActionTaken;          // operation InspectorFrontendHost.recordActionTaken
dom_externs.recordPanelShown;           // operation InspectorFrontendHost.recordPanelShown
dom_externs.recordSettingChanged;       // operation InspectorFrontendHost.recordSettingChanged
dom_externs.rect;                       // operation CanvasRenderingContext2D.rect
dom_externs.red;                        // attribute RGBColor.red
dom_externs.redirectCount;              // attribute PerformanceNavigation.redirectCount
dom_externs.redirectEnd;                // attribute PerformanceTiming.redirectEnd
dom_externs.redirectStart;              // attribute PerformanceTiming.redirectStart
dom_externs.refX;                       // attribute SVGMarkerElement.refX
dom_externs.refY;                       // attribute SVGMarkerElement.refY
dom_externs.referenceNode;              // attribute NodeIterator.referenceNode
dom_externs.referrer;                   // attribute Document.referrer
dom_externs.refresh;                    // operation DOMPluginArray.refresh
dom_externs.rel;                        // attribute HTMLAnchorElement.rel, attribute HTMLLinkElement.rel
dom_externs.relatedNode;                // attribute MutationEvent.relatedNode
dom_externs.relatedTarget;              // attribute MouseEvent.relatedTarget
dom_externs.releaseEvents;              // operation DOMWindow.releaseEvents, operation HTMLDocument.releaseEvents
dom_externs.releaseShaderCompiler;      // operation WebGLRenderingContext.releaseShaderCompiler
dom_externs.reload;                     // operation Location.reload
dom_externs.remove;                     // operation DOMTokenList.remove, operation Entry.remove, operation EntrySync.remove, operation HTMLOptionsCollection.remove, operation HTMLSelectElement.remove
dom_externs.removeAllRanges;            // operation DOMSelection.removeAllRanges
dom_externs.removeAttribute;            // operation Element.removeAttribute
dom_externs.removeAttributeNS;          // operation Element.removeAttributeNS
dom_externs.removeAttributeNode;        // operation Element.removeAttributeNode
dom_externs.removeChild;                // operation Node.removeChild
dom_externs.removeCue;                  // operation TextTrack.removeCue
dom_externs.removeEventListener;        // operation AbstractWorker.removeEventListener, operation DOMApplicationCache.removeEventListener, operation DOMWindow.removeEventListener, operation EventSource.removeEventListener, operation EventTarget.removeEventListener, operation IDBDatabase.removeEventListener, operation IDBRequest.removeEventListener, operation IDBTransaction.removeEventListener, operation MessagePort.removeEventListener, operation Node.removeEventListener, operation Notification.removeEventListener, operation SVGElementInstance.removeEventListener, operation WebSocket.removeEventListener, operation WorkerContext.removeEventListener, operation XMLHttpRequest.removeEventListener, operation XMLHttpRequestUpload.removeEventListener
dom_externs.removeItem;                 // operation SVGLengthList.removeItem, operation SVGNumberList.removeItem, operation SVGPathSegList.removeItem, operation SVGPointList.removeItem, operation SVGStringList.removeItem, operation SVGTransformList.removeItem, operation Storage.removeItem
dom_externs.removeListener;             // operation MediaQueryList.removeListener
dom_externs.removeNamedItem;            // operation NamedNodeMap.removeNamedItem
dom_externs.removeNamedItemNS;          // operation NamedNodeMap.removeNamedItemNS
dom_externs.removeParameter;            // operation XSLTProcessor.removeParameter
dom_externs.removeProperty;             // operation CSSStyleDeclaration.removeProperty
dom_externs.removeRecursively;          // operation DirectoryEntry.removeRecursively, operation DirectoryEntrySync.removeRecursively
dom_externs.removeRule;                 // operation CSSStyleSheet.removeRule
dom_externs.removedNodes;               // attribute MutationRecord.removedNodes
dom_externs.renderbufferStorage;        // operation WebGLRenderingContext.renderbufferStorage
dom_externs.replace;                    // operation Location.replace
dom_externs.replaceChild;               // operation Node.replaceChild
dom_externs.replaceData;                // operation CharacterData.replaceData
dom_externs.replaceId;                  // attribute Notification.replaceId
dom_externs.replaceItem;                // operation SVGLengthList.replaceItem, operation SVGNumberList.replaceItem, operation SVGPathSegList.replaceItem, operation SVGPointList.replaceItem, operation SVGStringList.replaceItem, operation SVGTransformList.replaceItem
dom_externs.replaceState;               // operation History.replaceState
dom_externs.replaceWholeText;           // operation Text.replaceWholeText
dom_externs.requestAttachWindow;        // operation InspectorFrontendHost.requestAttachWindow
dom_externs.requestDetachWindow;        // operation InspectorFrontendHost.requestDetachWindow
dom_externs.requestPermission;          // operation NotificationCenter.requestPermission
dom_externs.requestQuota;               // operation StorageInfo.requestQuota
dom_externs.requestStart;               // attribute PerformanceTiming.requestStart
dom_externs.required;                   // attribute HTMLInputElement.required, attribute HTMLSelectElement.required, attribute HTMLTextAreaElement.required
dom_externs.requiredExtensions;         // attribute SVGAElement.requiredExtensions, attribute SVGAnimationElement.requiredExtensions, attribute SVGCircleElement.requiredExtensions, attribute SVGClipPathElement.requiredExtensions, attribute SVGCursorElement.requiredExtensions, attribute SVGDefsElement.requiredExtensions, attribute SVGEllipseElement.requiredExtensions, attribute SVGForeignObjectElement.requiredExtensions, attribute SVGGElement.requiredExtensions, attribute SVGImageElement.requiredExtensions, attribute SVGLineElement.requiredExtensions, attribute SVGMaskElement.requiredExtensions, attribute SVGPathElement.requiredExtensions, attribute SVGPatternElement.requiredExtensions, attribute SVGPolygonElement.requiredExtensions, attribute SVGPolylineElement.requiredExtensions, attribute SVGRectElement.requiredExtensions, attribute SVGSVGElement.requiredExtensions, attribute SVGSwitchElement.requiredExtensions, attribute SVGTests.requiredExtensions, attribute SVGTextContentElement.requiredExtensions, attribute SVGUseElement.requiredExtensions
dom_externs.requiredFeatures;           // attribute SVGAElement.requiredFeatures, attribute SVGAnimationElement.requiredFeatures, attribute SVGCircleElement.requiredFeatures, attribute SVGClipPathElement.requiredFeatures, attribute SVGCursorElement.requiredFeatures, attribute SVGDefsElement.requiredFeatures, attribute SVGEllipseElement.requiredFeatures, attribute SVGForeignObjectElement.requiredFeatures, attribute SVGGElement.requiredFeatures, attribute SVGImageElement.requiredFeatures, attribute SVGLineElement.requiredFeatures, attribute SVGMaskElement.requiredFeatures, attribute SVGPathElement.requiredFeatures, attribute SVGPatternElement.requiredFeatures, attribute SVGPolygonElement.requiredFeatures, attribute SVGPolylineElement.requiredFeatures, attribute SVGRectElement.requiredFeatures, attribute SVGSVGElement.requiredFeatures, attribute SVGSwitchElement.requiredFeatures, attribute SVGTests.requiredFeatures, attribute SVGTextContentElement.requiredFeatures, attribute SVGUseElement.requiredFeatures
dom_externs.reset;                      // operation HTMLFormElement.reset, operation XSLTProcessor.reset
dom_externs.resizeBy;                   // operation DOMWindow.resizeBy
dom_externs.resizeTo;                   // operation DOMWindow.resizeTo
dom_externs.responseBlob;               // attribute XMLHttpRequest.responseBlob
dom_externs.responseEnd;                // attribute PerformanceTiming.responseEnd
dom_externs.responseStart;              // attribute PerformanceTiming.responseStart
dom_externs.responseText;               // attribute XMLHttpRequest.responseText
dom_externs.responseType;               // attribute XMLHttpRequest.responseType
dom_externs.responseXML;                // attribute XMLHttpRequest.responseXML
dom_externs.restore;                    // operation CanvasRenderingContext2D.restore
dom_externs.restoreContext;             // operation WebKitLoseContext.restoreContext
dom_externs.result;                     // attribute FileReader.result, attribute IDBRequest.result, attribute SVGFEBlendElement.result, attribute SVGFEColorMatrixElement.result, attribute SVGFEComponentTransferElement.result, attribute SVGFECompositeElement.result, attribute SVGFEConvolveMatrixElement.result, attribute SVGFEDiffuseLightingElement.result, attribute SVGFEDisplacementMapElement.result, attribute SVGFEDropShadowElement.result, attribute SVGFEFloodElement.result, attribute SVGFEGaussianBlurElement.result, attribute SVGFEImageElement.result, attribute SVGFEMergeElement.result, attribute SVGFEMorphologyElement.result, attribute SVGFEOffsetElement.result, attribute SVGFESpecularLightingElement.result, attribute SVGFETileElement.result, attribute SVGFETurbulenceElement.result, attribute SVGFilterPrimitiveStandardAttributes.result
dom_externs.resultType;                 // attribute XPathResult.resultType
dom_externs.results;                    // attribute SpeechInputEvent.results
dom_externs.returnValue;                // attribute Event.returnValue
dom_externs.rev;                        // attribute HTMLAnchorElement.rev, attribute HTMLLinkElement.rev
dom_externs.revokeObjectURL;            // operation DOMURL.revokeObjectURL
dom_externs.rgbColor;                   // attribute SVGColor.rgbColor
dom_externs.right;                      // attribute ClientRect.right, attribute Rect.right
dom_externs.root;                       // attribute DOMFileSystem.root, attribute DOMFileSystemSync.root, attribute NodeIterator.root, attribute TreeWalker.root
dom_externs.rootElement;                // attribute SVGDocument.rootElement
dom_externs.rotate;                     // operation CanvasRenderingContext2D.rotate, operation SVGMatrix.rotate, attribute SVGTextPositioningElement.rotate, operation WebKitCSSMatrix.rotate
dom_externs.rotateAxisAngle;            // operation WebKitCSSMatrix.rotateAxisAngle
dom_externs.rotateFromVector;           // operation SVGMatrix.rotateFromVector
dom_externs.rowIndex;                   // attribute HTMLTableRowElement.rowIndex
dom_externs.rowSpan;                    // attribute HTMLTableCellElement.rowSpan
dom_externs.rows;                       // attribute HTMLFrameSetElement.rows, attribute HTMLTableElement.rows, attribute HTMLTableSectionElement.rows, attribute HTMLTextAreaElement.rows, attribute SQLResultSet.rows
dom_externs.rowsAffected;               // attribute SQLResultSet.rowsAffected
dom_externs.rules;                      // attribute CSSStyleSheet.rules, attribute HTMLTableElement.rules
dom_externs.rx;                         // attribute SVGEllipseElement.rx, attribute SVGRectElement.rx
dom_externs.ry;                         // attribute SVGEllipseElement.ry, attribute SVGRectElement.ry
dom_externs.sampleCoverage;             // operation WebGLRenderingContext.sampleCoverage
dom_externs.sandbox;                    // attribute HTMLIFrameElement.sandbox
dom_externs.save;                       // operation CanvasRenderingContext2D.save
dom_externs.saveAs;                     // operation InspectorFrontendHost.saveAs
dom_externs.scale;                      // operation CanvasRenderingContext2D.scale, attribute SVGFEDisplacementMapElement.scale, operation SVGMatrix.scale, operation WebKitCSSMatrix.scale
dom_externs.scaleNonUniform;            // operation SVGMatrix.scaleNonUniform
dom_externs.scheme;                     // attribute HTMLMetaElement.scheme
dom_externs.scissor;                    // operation WebGLRenderingContext.scissor
dom_externs.scope;                      // attribute HTMLTableCellElement.scope
dom_externs.scopeChain;                 // attribute JavaScriptCallFrame.scopeChain
dom_externs.scopeType;                  // operation JavaScriptCallFrame.scopeType
dom_externs.screen;                     // attribute DOMWindow.screen
dom_externs.screenLeft;                 // attribute DOMWindow.screenLeft
dom_externs.screenPixelToMillimeterX;   // attribute SVGSVGElement.screenPixelToMillimeterX
dom_externs.screenPixelToMillimeterY;   // attribute SVGSVGElement.screenPixelToMillimeterY
dom_externs.screenTop;                  // attribute DOMWindow.screenTop
dom_externs.screenX;                    // attribute DOMWindow.screenX, attribute MouseEvent.screenX, attribute Touch.screenX, attribute WheelEvent.screenX
dom_externs.screenY;                    // attribute DOMWindow.screenY, attribute MouseEvent.screenY, attribute Touch.screenY, attribute WheelEvent.screenY
dom_externs.scripts;                    // attribute HTMLDocument.scripts
dom_externs.scroll;                     // operation DOMWindow.scroll
dom_externs.scrollAmount;               // attribute HTMLMarqueeElement.scrollAmount
dom_externs.scrollBy;                   // operation DOMWindow.scrollBy
dom_externs.scrollByLines;              // operation Element.scrollByLines
dom_externs.scrollByPages;              // operation Element.scrollByPages
dom_externs.scrollDelay;                // attribute HTMLMarqueeElement.scrollDelay
dom_externs.scrollHeight;               // attribute Element.scrollHeight
dom_externs.scrollIntoView;             // operation Element.scrollIntoView
dom_externs.scrollIntoViewIfNeeded;     // operation Element.scrollIntoViewIfNeeded
dom_externs.scrollLeft;                 // attribute Element.scrollLeft
dom_externs.scrollTo;                   // operation DOMWindow.scrollTo
dom_externs.scrollTop;                  // attribute Element.scrollTop
dom_externs.scrollWidth;                // attribute Element.scrollWidth
dom_externs.scrollX;                    // attribute DOMWindow.scrollX
dom_externs.scrollY;                    // attribute DOMWindow.scrollY
dom_externs.scrollbars;                 // attribute DOMWindow.scrollbars
dom_externs.scrolling;                  // attribute HTMLFrameElement.scrolling, attribute HTMLIFrameElement.scrolling
dom_externs.search;                     // attribute HTMLAnchorElement.search, attribute HTMLAreaElement.search, attribute Location.search, attribute WorkerLocation.search
dom_externs.sectionRowIndex;            // attribute HTMLTableRowElement.sectionRowIndex
dom_externs.secureConnectionStart;      // attribute PerformanceTiming.secureConnectionStart
dom_externs.seed;                       // attribute SVGFETurbulenceElement.seed
dom_externs.seek;                       // operation FileWriter.seek, operation FileWriterSync.seek
dom_externs.seekable;                   // attribute HTMLMediaElement.seekable
dom_externs.seeking;                    // attribute HTMLMediaElement.seeking
dom_externs.select;                     // operation HTMLInputElement.select, operation HTMLTextAreaElement.select
dom_externs.selectAllChildren;          // operation DOMSelection.selectAllChildren
dom_externs.selectNode;                 // operation Range.selectNode
dom_externs.selectNodeContents;         // operation Range.selectNodeContents
dom_externs.selectSubString;            // operation SVGTextContentElement.selectSubString
dom_externs.selected;                   // attribute HTMLOptionElement.selected
dom_externs.selectedIndex;              // attribute HTMLOptionsCollection.selectedIndex, attribute HTMLSelectElement.selectedIndex
dom_externs.selectedOption;             // attribute HTMLInputElement.selectedOption
dom_externs.selectedStylesheetSet;      // attribute Document.selectedStylesheetSet
dom_externs.selectionDirection;         // attribute HTMLInputElement.selectionDirection, attribute HTMLTextAreaElement.selectionDirection
dom_externs.selectionEnd;               // attribute HTMLInputElement.selectionEnd, attribute HTMLTextAreaElement.selectionEnd
dom_externs.selectionStart;             // attribute HTMLInputElement.selectionStart, attribute HTMLTextAreaElement.selectionStart
dom_externs.selectorText;               // attribute CSSPageRule.selectorText, attribute CSSStyleRule.selectorText
dom_externs.self;                       // attribute DOMWindow.self, attribute WorkerContext.self
dom_externs.selfTime;                   // attribute ScriptProfileNode.selfTime
dom_externs.send;                       // operation WebSocket.send, operation XMLHttpRequest.send
dom_externs.sendMessageToBackend;       // operation InspectorFrontendHost.sendMessageToBackend
dom_externs.separator;                  // attribute Counter.separator
dom_externs.serializeToString;          // operation XMLSerializer.serializeToString
dom_externs.sessionStorage;             // attribute DOMWindow.sessionStorage
dom_externs.setAlpha;                   // operation CanvasRenderingContext2D.setAlpha
dom_externs.setAttachedWindowHeight;    // operation InspectorFrontendHost.setAttachedWindowHeight
dom_externs.setAttribute;               // operation Element.setAttribute
dom_externs.setAttributeNS;             // operation Element.setAttributeNS
dom_externs.setAttributeNode;           // operation Element.setAttributeNode
dom_externs.setAttributeNodeNS;         // operation Element.setAttributeNodeNS
dom_externs.setBaseAndExtent;           // operation DOMSelection.setBaseAndExtent
dom_externs.setColor;                   // operation SVGColor.setColor
dom_externs.setCompositeOperation;      // operation CanvasRenderingContext2D.setCompositeOperation
dom_externs.setCurrentTime;             // operation SVGSVGElement.setCurrentTime
dom_externs.setCustomValidity;          // operation HTMLButtonElement.setCustomValidity, operation HTMLFieldSetElement.setCustomValidity, operation HTMLInputElement.setCustomValidity, operation HTMLKeygenElement.setCustomValidity, operation HTMLObjectElement.setCustomValidity, operation HTMLOutputElement.setCustomValidity, operation HTMLSelectElement.setCustomValidity, operation HTMLTextAreaElement.setCustomValidity
dom_externs.setData;                    // operation Clipboard.setData
dom_externs.setDragImage;               // operation Clipboard.setDragImage
dom_externs.setEnd;                     // operation Range.setEnd
dom_externs.setEndAfter;                // operation Range.setEndAfter
dom_externs.setEndBefore;               // operation Range.setEndBefore
dom_externs.setExtensionAPI;            // operation InspectorFrontendHost.setExtensionAPI
dom_externs.setFillColor;               // operation CanvasRenderingContext2D.setFillColor
dom_externs.setFilterRes;               // operation SVGFilterElement.setFilterRes
dom_externs.setFloat32;                 // operation DataView.setFloat32
dom_externs.setFloat64;                 // operation DataView.setFloat64
dom_externs.setFloatValue;              // operation CSSPrimitiveValue.setFloatValue
dom_externs.setInt16;                   // operation DataView.setInt16
dom_externs.setInt32;                   // operation DataView.setInt32
dom_externs.setInt8;                    // operation DataView.setInt8
dom_externs.setInterval;                // operation DOMWindow.setInterval, operation WorkerContext.setInterval
dom_externs.setItem;                    // operation Storage.setItem
dom_externs.setLineCap;                 // operation CanvasRenderingContext2D.setLineCap
dom_externs.setLineJoin;                // operation CanvasRenderingContext2D.setLineJoin
dom_externs.setLineWidth;               // operation CanvasRenderingContext2D.setLineWidth
dom_externs.setMatrix;                  // operation SVGTransform.setMatrix
dom_externs.setMatrixValue;             // operation WebKitCSSMatrix.setMatrixValue
dom_externs.setMiterLimit;              // operation CanvasRenderingContext2D.setMiterLimit
dom_externs.setNamedItem;               // operation NamedNodeMap.setNamedItem
dom_externs.setNamedItemNS;             // operation NamedNodeMap.setNamedItemNS
dom_externs.setOrientToAngle;           // operation SVGMarkerElement.setOrientToAngle
dom_externs.setOrientToAuto;            // operation SVGMarkerElement.setOrientToAuto
dom_externs.setPaint;                   // operation SVGPaint.setPaint
dom_externs.setParameter;               // operation XSLTProcessor.setParameter
dom_externs.setPosition;                // operation DOMSelection.setPosition
dom_externs.setProperty;                // operation CSSStyleDeclaration.setProperty
dom_externs.setRGBColor;                // operation SVGColor.setRGBColor
dom_externs.setRGBColorICCColor;        // operation SVGColor.setRGBColorICCColor
dom_externs.setRadius;                  // operation SVGFEMorphologyElement.setRadius
dom_externs.setRequestHeader;           // operation XMLHttpRequest.setRequestHeader
dom_externs.setRotate;                  // operation SVGTransform.setRotate
dom_externs.setScale;                   // operation SVGTransform.setScale
dom_externs.setSelectionRange;          // operation HTMLInputElement.setSelectionRange, operation HTMLTextAreaElement.setSelectionRange
dom_externs.setShadow;                  // operation CanvasRenderingContext2D.setShadow
dom_externs.setSkewX;                   // operation SVGTransform.setSkewX
dom_externs.setSkewY;                   // operation SVGTransform.setSkewY
dom_externs.setStart;                   // operation Range.setStart
dom_externs.setStartAfter;              // operation Range.setStartAfter
dom_externs.setStartBefore;             // operation Range.setStartBefore
dom_externs.setStdDeviation;            // operation SVGFEDropShadowElement.setStdDeviation, operation SVGFEGaussianBlurElement.setStdDeviation
dom_externs.setStringValue;             // operation CSSPrimitiveValue.setStringValue
dom_externs.setStrokeColor;             // operation CanvasRenderingContext2D.setStrokeColor
dom_externs.setTimeout;                 // operation DOMWindow.setTimeout, operation WorkerContext.setTimeout
dom_externs.setTransform;               // operation CanvasRenderingContext2D.setTransform
dom_externs.setTranslate;               // operation SVGTransform.setTranslate
dom_externs.setUint16;                  // operation DataView.setUint16
dom_externs.setUint32;                  // operation DataView.setUint32
dom_externs.setUint8;                   // operation DataView.setUint8
dom_externs.setUri;                     // operation SVGPaint.setUri
dom_externs.setVersion;                 // operation IDBDatabase.setVersion
dom_externs.shaderSource;               // operation WebGLRenderingContext.shaderSource
dom_externs.shadowBlur;                 // attribute CanvasRenderingContext2D.shadowBlur
dom_externs.shadowColor;                // attribute CanvasRenderingContext2D.shadowColor
dom_externs.shadowOffsetX;              // attribute CanvasRenderingContext2D.shadowOffsetX
dom_externs.shadowOffsetY;              // attribute CanvasRenderingContext2D.shadowOffsetY
dom_externs.shape;                      // attribute HTMLAnchorElement.shape, attribute HTMLAreaElement.shape
dom_externs.sheet;                      // attribute HTMLLinkElement.sheet, attribute HTMLStyleElement.sheet, attribute ProcessingInstruction.sheet
dom_externs.shiftKey;                   // attribute KeyboardEvent.shiftKey, attribute MouseEvent.shiftKey, attribute TouchEvent.shiftKey, attribute WheelEvent.shiftKey
dom_externs.show;                       // operation Notification.show
dom_externs.showContextMenu;            // operation InspectorFrontendHost.showContextMenu
dom_externs.showModalDialog;            // operation DOMWindow.showModalDialog
dom_externs.singleNodeValue;            // attribute XPathResult.singleNodeValue
dom_externs.size;                       // attribute Blob.size, attribute HTMLBaseFontElement.size, attribute HTMLFontElement.size, attribute HTMLHRElement.size, attribute HTMLInputElement.size, attribute HTMLSelectElement.size, attribute TextTrackCue.size, attribute WebGLActiveInfo.size
dom_externs.sizes;                      // attribute HTMLLinkElement.sizes
dom_externs.skewX;                      // operation SVGMatrix.skewX, operation WebKitCSSMatrix.skewX
dom_externs.skewY;                      // operation SVGMatrix.skewY, operation WebKitCSSMatrix.skewY
dom_externs.slice;                      // operation ArrayBuffer.slice
dom_externs.slope;                      // attribute SVGComponentTransferFunctionElement.slope
dom_externs.snapToLines;                // attribute TextTrackCue.snapToLines
dom_externs.snapshotItem;               // operation XPathResult.snapshotItem
dom_externs.snapshotLength;             // attribute XPathResult.snapshotLength
dom_externs.source;                     // attribute IDBCursor.source, attribute IDBRequest.source, attribute MessageEvent.source
dom_externs.sourceID;                   // attribute JavaScriptCallFrame.sourceID
dom_externs.spacing;                    // attribute SVGTextPathElement.spacing
dom_externs.span;                       // attribute HTMLTableColElement.span
dom_externs.specified;                  // attribute Attr.specified
dom_externs.specularConstant;           // attribute SVGFESpecularLightingElement.specularConstant
dom_externs.specularExponent;           // attribute SVGFESpecularLightingElement.specularExponent, attribute SVGFESpotLightElement.specularExponent
dom_externs.speed;                      // attribute Coordinates.speed
dom_externs.spellcheck;                 // attribute HTMLElement.spellcheck
dom_externs.splitText;                  // operation Text.splitText
dom_externs.spreadMethod;               // attribute SVGGradientElement.spreadMethod
dom_externs.src;                        // attribute HTMLEmbedElement.src, attribute HTMLFrameElement.src, attribute HTMLIFrameElement.src, attribute HTMLImageElement.src, attribute HTMLInputElement.src, attribute HTMLMediaElement.src, attribute HTMLScriptElement.src, attribute HTMLSourceElement.src, attribute HTMLTrackElement.src
dom_externs.srcElement;                 // attribute Event.srcElement
dom_externs.srclang;                    // attribute HTMLTrackElement.srclang
dom_externs.standby;                    // attribute HTMLObjectElement.standby
dom_externs.start;                      // operation HTMLMarqueeElement.start, attribute HTMLOListElement.start, operation MessagePort.start, operation TimeRanges.start
dom_externs.startContainer;             // attribute Range.startContainer
dom_externs.startOffset;                // attribute Range.startOffset, attribute SVGTextPathElement.startOffset
dom_externs.startTime;                  // attribute HTMLMediaElement.startTime, attribute TextTrackCue.startTime
dom_externs.state;                      // attribute PopStateEvent.state
dom_externs.status;                     // attribute DOMApplicationCache.status, attribute DOMWindow.status, attribute XMLHttpRequest.status
dom_externs.statusMessage;              // attribute WebGLContextEvent.statusMessage
dom_externs.statusText;                 // attribute XMLHttpRequest.statusText
dom_externs.statusbar;                  // attribute DOMWindow.statusbar
dom_externs.stdDeviationX;              // attribute SVGFEDropShadowElement.stdDeviationX, attribute SVGFEGaussianBlurElement.stdDeviationX
dom_externs.stdDeviationY;              // attribute SVGFEDropShadowElement.stdDeviationY, attribute SVGFEGaussianBlurElement.stdDeviationY
dom_externs.stencil;                    // attribute WebGLContextAttributes.stencil
dom_externs.stencilFunc;                // operation WebGLRenderingContext.stencilFunc
dom_externs.stencilFuncSeparate;        // operation WebGLRenderingContext.stencilFuncSeparate
dom_externs.stencilMask;                // operation WebGLRenderingContext.stencilMask
dom_externs.stencilMaskSeparate;        // operation WebGLRenderingContext.stencilMaskSeparate
dom_externs.stencilOp;                  // operation WebGLRenderingContext.stencilOp
dom_externs.stencilOpSeparate;          // operation WebGLRenderingContext.stencilOpSeparate
dom_externs.step;                       // attribute HTMLInputElement.step
dom_externs.stepDown;                   // operation HTMLInputElement.stepDown
dom_externs.stepMismatch;               // attribute ValidityState.stepMismatch
dom_externs.stepUp;                     // operation HTMLInputElement.stepUp
dom_externs.stitchTiles;                // attribute SVGFETurbulenceElement.stitchTiles
dom_externs.stop;                       // operation DOMWindow.stop, operation HTMLMarqueeElement.stop
dom_externs.stopImmediatePropagation;   // operation Event.stopImmediatePropagation
dom_externs.stopPropagation;            // operation Event.stopPropagation
dom_externs.storageArea;                // attribute StorageEvent.storageArea
dom_externs.storageId;                  // operation InjectedScriptHost.storageId
dom_externs.stringValue;                // attribute XPathResult.stringValue
dom_externs.stroke;                     // operation CanvasRenderingContext2D.stroke
dom_externs.strokeRect;                 // operation CanvasRenderingContext2D.strokeRect
dom_externs.strokeStyle;                // attribute CanvasRenderingContext2D.strokeStyle
dom_externs.strokeText;                 // operation CanvasRenderingContext2D.strokeText
dom_externs.style;                      // attribute CSSFontFaceRule.style, attribute CSSPageRule.style, attribute CSSStyleRule.style, attribute Element.style, attribute SVGAElement.style, attribute SVGCircleElement.style, attribute SVGClipPathElement.style, attribute SVGDefsElement.style, attribute SVGDescElement.style, attribute SVGEllipseElement.style, attribute SVGFEBlendElement.style, attribute SVGFEColorMatrixElement.style, attribute SVGFEComponentTransferElement.style, attribute SVGFECompositeElement.style, attribute SVGFEConvolveMatrixElement.style, attribute SVGFEDiffuseLightingElement.style, attribute SVGFEDisplacementMapElement.style, attribute SVGFEDropShadowElement.style, attribute SVGFEFloodElement.style, attribute SVGFEGaussianBlurElement.style, attribute SVGFEImageElement.style, attribute SVGFEMergeElement.style, attribute SVGFEMorphologyElement.style, attribute SVGFEOffsetElement.style, attribute SVGFESpecularLightingElement.style, attribute SVGFETileElement.style, attribute SVGFETurbulenceElement.style, attribute SVGFilterElement.style, attribute SVGForeignObjectElement.style, attribute SVGGElement.style, attribute SVGGlyphRefElement.style, attribute SVGGradientElement.style, attribute SVGImageElement.style, attribute SVGLineElement.style, attribute SVGMarkerElement.style, attribute SVGMaskElement.style, attribute SVGPathElement.style, attribute SVGPatternElement.style, attribute SVGPolygonElement.style, attribute SVGPolylineElement.style, attribute SVGRectElement.style, attribute SVGSVGElement.style, attribute SVGStopElement.style, attribute SVGStylable.style, attribute SVGSwitchElement.style, attribute SVGSymbolElement.style, attribute SVGTextContentElement.style, attribute SVGTitleElement.style, attribute SVGUseElement.style, attribute WebKitCSSKeyframeRule.style
dom_externs.styleMedia;                 // attribute DOMWindow.styleMedia
dom_externs.styleSheet;                 // attribute CSSImportRule.styleSheet
dom_externs.styleSheets;                // attribute Document.styleSheets
dom_externs.subarray;                   // operation Float32Array.subarray, operation Float64Array.subarray, operation Int16Array.subarray, operation Int32Array.subarray, operation Int8Array.subarray, operation Uint16Array.subarray, operation Uint32Array.subarray, operation Uint8Array.subarray
dom_externs.submitFromJavaScript;       // operation HTMLFormElement.submitFromJavaScript
dom_externs.substringData;              // operation CharacterData.substringData
dom_externs.suffixes;                   // attribute DOMMimeType.suffixes
dom_externs.summary;                    // attribute HTMLTableElement.summary
dom_externs.surfaceScale;               // attribute SVGFEDiffuseLightingElement.surfaceScale, attribute SVGFESpecularLightingElement.surfaceScale
dom_externs.surroundContents;           // operation Range.surroundContents
dom_externs.suspendRedraw;              // operation SVGSVGElement.suspendRedraw
dom_externs.swapCache;                  // operation DOMApplicationCache.swapCache
dom_externs.sweepFlag;                  // attribute SVGPathSegArcAbs.sweepFlag, attribute SVGPathSegArcRel.sweepFlag
dom_externs.systemId;                   // attribute DocumentType.systemId, attribute Entity.systemId, attribute Notation.systemId
dom_externs.systemLanguage;             // attribute SVGAElement.systemLanguage, attribute SVGAnimationElement.systemLanguage, attribute SVGCircleElement.systemLanguage, attribute SVGClipPathElement.systemLanguage, attribute SVGCursorElement.systemLanguage, attribute SVGDefsElement.systemLanguage, attribute SVGEllipseElement.systemLanguage, attribute SVGForeignObjectElement.systemLanguage, attribute SVGGElement.systemLanguage, attribute SVGImageElement.systemLanguage, attribute SVGLineElement.systemLanguage, attribute SVGMaskElement.systemLanguage, attribute SVGPathElement.systemLanguage, attribute SVGPatternElement.systemLanguage, attribute SVGPolygonElement.systemLanguage, attribute SVGPolylineElement.systemLanguage, attribute SVGRectElement.systemLanguage, attribute SVGSVGElement.systemLanguage, attribute SVGSwitchElement.systemLanguage, attribute SVGTests.systemLanguage, attribute SVGTextContentElement.systemLanguage, attribute SVGUseElement.systemLanguage
dom_externs.tBodies;                    // attribute HTMLTableElement.tBodies
dom_externs.tFoot;                      // attribute HTMLTableElement.tFoot
dom_externs.tHead;                      // attribute HTMLTableElement.tHead
dom_externs.tabIndex;                   // attribute HTMLElement.tabIndex
dom_externs.tableValues;                // attribute SVGComponentTransferFunctionElement.tableValues
dom_externs.tagName;                    // attribute Element.tagName
dom_externs.tags;                       // operation HTMLAllCollection.tags
dom_externs.target;                     // attribute Event.target, attribute HTMLAnchorElement.target, attribute HTMLAreaElement.target, attribute HTMLBaseElement.target, attribute HTMLFormElement.target, attribute HTMLLinkElement.target, attribute MutationRecord.target, attribute ProcessingInstruction.target, attribute SVGAElement.target, attribute Touch.target
dom_externs.targetElement;              // attribute SVGAnimationElement.targetElement
dom_externs.targetTouches;              // attribute TouchEvent.targetTouches
dom_externs.targetX;                    // attribute SVGFEConvolveMatrixElement.targetX
dom_externs.targetY;                    // attribute SVGFEConvolveMatrixElement.targetY
dom_externs.terminate;                  // operation Worker.terminate
dom_externs.texImage2D;                 // operation WebGLRenderingContext.texImage2D
dom_externs.texParameterf;              // operation WebGLRenderingContext.texParameterf
dom_externs.texParameteri;              // operation WebGLRenderingContext.texParameteri
dom_externs.texSubImage2D;              // operation WebGLRenderingContext.texSubImage2D
dom_externs.text;                       // attribute HTMLAnchorElement.text, attribute HTMLBodyElement.text, attribute HTMLOptionElement.text, attribute HTMLScriptElement.text, attribute HTMLTitleElement.text
dom_externs.textAlign;                  // attribute CanvasRenderingContext2D.textAlign
dom_externs.textBaseline;               // attribute CanvasRenderingContext2D.textBaseline
dom_externs.textContent;                // attribute Node.textContent
dom_externs.textLength;                 // attribute HTMLTextAreaElement.textLength, attribute SVGTextContentElement.textLength
dom_externs.textPosition;               // attribute TextTrackCue.textPosition
dom_externs.time;                       // operation Console.time
dom_externs.timeEnd;                    // operation Console.timeEnd
dom_externs.timeStamp;                  // operation Console.timeStamp, attribute Event.timeStamp
dom_externs.timestamp;                  // attribute Geoposition.timestamp
dom_externs.timing;                     // attribute Performance.timing
dom_externs.title;                      // attribute Document.title, attribute HTMLElement.title, attribute SVGStyleElement.title, attribute ScriptProfile.title, attribute StyleSheet.title
dom_externs.toDataURL;                  // operation HTMLCanvasElement.toDataURL
dom_externs.toElement;                  // attribute MouseEvent.toElement
dom_externs.toString;                   // operation DOMException.toString, operation DOMSelection.toString, operation DOMTokenList.toString, operation EventException.toString, operation FileException.toString, operation HTMLAnchorElement.toString, operation IDBDatabaseException.toString, operation OperationNotAllowedException.toString, operation Range.toString, operation RangeException.toString, operation SVGException.toString, operation WebKitCSSMatrix.toString, operation WorkerLocation.toString, operation XMLHttpRequestException.toString, operation XPathException.toString
dom_externs.toStringFunction;           // operation Location.toStringFunction
dom_externs.toURL;                      // operation Entry.toURL, operation EntrySync.toURL
dom_externs.toggle;                     // operation DOMTokenList.toggle
dom_externs.tooLong;                    // attribute ValidityState.tooLong
dom_externs.toolbar;                    // attribute DOMWindow.toolbar
dom_externs.top;                        // attribute ClientRect.top, attribute DOMWindow.top, attribute Rect.top
dom_externs.total;                      // attribute ProgressEvent.total
dom_externs.totalJSHeapSize;            // attribute MemoryInfo.totalJSHeapSize
dom_externs.totalSize;                  // attribute XMLHttpRequestProgressEvent.totalSize
dom_externs.totalTime;                  // attribute ScriptProfileNode.totalTime
dom_externs.touches;                    // attribute TouchEvent.touches
dom_externs.trace;                      // operation Console.trace
dom_externs.track;                      // attribute HTMLTrackElement.track, attribute TextTrackCue.track
dom_externs.transaction;                // operation Database.transaction, operation DatabaseSync.transaction, operation IDBDatabase.transaction, attribute IDBObjectStore.transaction, attribute IDBRequest.transaction
dom_externs.transform;                  // operation CanvasRenderingContext2D.transform, attribute SVGAElement.transform, attribute SVGCircleElement.transform, attribute SVGClipPathElement.transform, attribute SVGDefsElement.transform, attribute SVGEllipseElement.transform, attribute SVGForeignObjectElement.transform, attribute SVGGElement.transform, attribute SVGImageElement.transform, attribute SVGLineElement.transform, attribute SVGPathElement.transform, attribute SVGPolygonElement.transform, attribute SVGPolylineElement.transform, attribute SVGRectElement.transform, attribute SVGSwitchElement.transform, attribute SVGTextElement.transform, attribute SVGTransformable.transform, attribute SVGUseElement.transform, attribute SVGViewSpec.transform
dom_externs.transformString;            // attribute SVGViewSpec.transformString
dom_externs.transformToDocument;        // operation XSLTProcessor.transformToDocument
dom_externs.transformToFragment;        // operation XSLTProcessor.transformToFragment
dom_externs.translate;                  // operation CanvasRenderingContext2D.translate, operation SVGMatrix.translate, operation WebKitCSSMatrix.translate
dom_externs.trueSpeed;                  // attribute HTMLMarqueeElement.trueSpeed
dom_externs.truncate;                   // operation FileWriter.truncate, operation FileWriterSync.truncate
dom_externs.type;                       // attribute Blob.type, attribute CSSRule.type, attribute DOMMimeType.type, attribute DOMSelection.type, attribute DataTransferItem.type, attribute Event.type, attribute HTMLAnchorElement.type, attribute HTMLButtonElement.type, attribute HTMLEmbedElement.type, attribute HTMLInputElement.type, attribute HTMLKeygenElement.type, attribute HTMLLIElement.type, attribute HTMLLinkElement.type, attribute HTMLOListElement.type, attribute HTMLObjectElement.type, attribute HTMLOutputElement.type, attribute HTMLParamElement.type, attribute HTMLScriptElement.type, attribute HTMLSelectElement.type, attribute HTMLSourceElement.type, attribute HTMLStyleElement.type, attribute HTMLTextAreaElement.type, attribute HTMLUListElement.type, operation InjectedScriptHost.type, attribute JavaScriptCallFrame.type, attribute MutationRecord.type, attribute PerformanceNavigation.type, attribute SVGComponentTransferFunctionElement.type, attribute SVGFEColorMatrixElement.type, attribute SVGFETurbulenceElement.type, attribute SVGScriptElement.type, attribute SVGStyleElement.type, attribute SVGTransform.type, attribute StyleMedia.type, attribute StyleSheet.type, attribute WebGLActiveInfo.type
dom_externs.typeMismatch;               // attribute ValidityState.typeMismatch
dom_externs.types;                      // attribute Clipboard.types
dom_externs.uid;                        // attribute ScriptProfile.uid
dom_externs.uniform1f;                  // operation WebGLRenderingContext.uniform1f
dom_externs.uniform1fv;                 // operation WebGLRenderingContext.uniform1fv
dom_externs.uniform1i;                  // operation WebGLRenderingContext.uniform1i
dom_externs.uniform1iv;                 // operation WebGLRenderingContext.uniform1iv
dom_externs.uniform2f;                  // operation WebGLRenderingContext.uniform2f
dom_externs.uniform2fv;                 // operation WebGLRenderingContext.uniform2fv
dom_externs.uniform2i;                  // operation WebGLRenderingContext.uniform2i
dom_externs.uniform2iv;                 // operation WebGLRenderingContext.uniform2iv
dom_externs.uniform3f;                  // operation WebGLRenderingContext.uniform3f
dom_externs.uniform3fv;                 // operation WebGLRenderingContext.uniform3fv
dom_externs.uniform3i;                  // operation WebGLRenderingContext.uniform3i
dom_externs.uniform3iv;                 // operation WebGLRenderingContext.uniform3iv
dom_externs.uniform4f;                  // operation WebGLRenderingContext.uniform4f
dom_externs.uniform4fv;                 // operation WebGLRenderingContext.uniform4fv
dom_externs.uniform4i;                  // operation WebGLRenderingContext.uniform4i
dom_externs.uniform4iv;                 // operation WebGLRenderingContext.uniform4iv
dom_externs.uniformMatrix2fv;           // operation WebGLRenderingContext.uniformMatrix2fv
dom_externs.uniformMatrix3fv;           // operation WebGLRenderingContext.uniformMatrix3fv
dom_externs.uniformMatrix4fv;           // operation WebGLRenderingContext.uniformMatrix4fv
dom_externs.unique;                     // attribute IDBIndex.unique
dom_externs.unitType;                   // attribute SVGAngle.unitType, attribute SVGLength.unitType
dom_externs.unloadEventEnd;             // attribute PerformanceTiming.unloadEventEnd
dom_externs.unloadEventStart;           // attribute PerformanceTiming.unloadEventStart
dom_externs.unpauseAnimations;          // operation SVGSVGElement.unpauseAnimations
dom_externs.unsuspendRedraw;            // operation SVGSVGElement.unsuspendRedraw
dom_externs.unsuspendRedrawAll;         // operation SVGSVGElement.unsuspendRedrawAll
dom_externs.update;                     // operation DOMApplicationCache.update, operation IDBCursor.update
dom_externs.upload;                     // attribute XMLHttpRequest.upload
dom_externs.upper;                      // attribute IDBKeyRange.upper
dom_externs.upperBound;                 // operation IDBKeyRange.upperBound
dom_externs.upperOpen;                  // attribute IDBKeyRange.upperOpen
dom_externs.uri;                        // attribute SVGPaint.uri
dom_externs.url;                        // attribute BeforeLoadEvent.url, attribute ScriptProfileNode.url, attribute StorageEvent.url
dom_externs.useCurrentView;             // attribute SVGSVGElement.useCurrentView
dom_externs.useMap;                     // attribute HTMLImageElement.useMap, attribute HTMLInputElement.useMap, attribute HTMLObjectElement.useMap
dom_externs.useProgram;                 // operation WebGLRenderingContext.useProgram
dom_externs.usedJSHeapSize;             // attribute MemoryInfo.usedJSHeapSize
dom_externs.userAgent;                  // attribute Navigator.userAgent, attribute WorkerNavigator.userAgent
dom_externs.utterance;                  // attribute SpeechInputResult.utterance
dom_externs.vAlign;                     // attribute HTMLTableCellElement.vAlign, attribute HTMLTableColElement.vAlign, attribute HTMLTableRowElement.vAlign, attribute HTMLTableSectionElement.vAlign
dom_externs.vLink;                      // attribute HTMLBodyElement.vLink
dom_externs.valid;                      // attribute ValidityState.valid
dom_externs.validateProgram;            // operation WebGLRenderingContext.validateProgram
dom_externs.validationMessage;          // attribute HTMLButtonElement.validationMessage, attribute HTMLFieldSetElement.validationMessage, attribute HTMLInputElement.validationMessage, attribute HTMLKeygenElement.validationMessage, attribute HTMLObjectElement.validationMessage, attribute HTMLOutputElement.validationMessage, attribute HTMLSelectElement.validationMessage, attribute HTMLTextAreaElement.validationMessage
dom_externs.validity;                   // attribute HTMLButtonElement.validity, attribute HTMLFieldSetElement.validity, attribute HTMLInputElement.validity, attribute HTMLKeygenElement.validity, attribute HTMLObjectElement.validity, attribute HTMLOutputElement.validity, attribute HTMLSelectElement.validity, attribute HTMLTextAreaElement.validity
dom_externs.value;                      // attribute Attr.value, attribute DOMSettableTokenList.value, attribute HTMLButtonElement.value, attribute HTMLInputElement.value, attribute HTMLLIElement.value, attribute HTMLMeterElement.value, attribute HTMLOptionElement.value, attribute HTMLOutputElement.value, attribute HTMLParamElement.value, attribute HTMLProgressElement.value, attribute HTMLSelectElement.value, attribute HTMLTextAreaElement.value, attribute IDBCursorWithValue.value, attribute SVGAngle.value, attribute SVGLength.value, attribute SVGNumber.value
dom_externs.valueAsDate;                // attribute HTMLInputElement.valueAsDate
dom_externs.valueAsNumber;              // attribute HTMLInputElement.valueAsNumber
dom_externs.valueAsString;              // attribute SVGAngle.valueAsString, attribute SVGLength.valueAsString
dom_externs.valueInSpecifiedUnits;      // attribute SVGAngle.valueInSpecifiedUnits, attribute SVGLength.valueInSpecifiedUnits
dom_externs.valueMissing;               // attribute ValidityState.valueMissing
dom_externs.valueType;                  // attribute HTMLParamElement.valueType
dom_externs.values;                     // attribute SVGFEColorMatrixElement.values
dom_externs.vendor;                     // attribute Navigator.vendor
dom_externs.vendorSub;                  // attribute Navigator.vendorSub
dom_externs.version;                    // attribute Database.version, attribute DatabaseSync.version, attribute HTMLHtmlElement.version, attribute IDBDatabase.version, attribute IDBVersionChangeEvent.version
dom_externs.vertexAttrib1f;             // operation WebGLRenderingContext.vertexAttrib1f
dom_externs.vertexAttrib1fv;            // operation WebGLRenderingContext.vertexAttrib1fv
dom_externs.vertexAttrib2f;             // operation WebGLRenderingContext.vertexAttrib2f
dom_externs.vertexAttrib2fv;            // operation WebGLRenderingContext.vertexAttrib2fv
dom_externs.vertexAttrib3f;             // operation WebGLRenderingContext.vertexAttrib3f
dom_externs.vertexAttrib3fv;            // operation WebGLRenderingContext.vertexAttrib3fv
dom_externs.vertexAttrib4f;             // operation WebGLRenderingContext.vertexAttrib4f
dom_externs.vertexAttrib4fv;            // operation WebGLRenderingContext.vertexAttrib4fv
dom_externs.vertexAttribPointer;        // operation WebGLRenderingContext.vertexAttribPointer
dom_externs.verticalOverflow;           // attribute OverflowEvent.verticalOverflow
dom_externs.videoHeight;                // attribute HTMLVideoElement.videoHeight
dom_externs.videoWidth;                 // attribute HTMLVideoElement.videoWidth
dom_externs.view;                       // attribute UIEvent.view
dom_externs.viewBox;                    // attribute SVGFitToViewBox.viewBox, attribute SVGMarkerElement.viewBox, attribute SVGPatternElement.viewBox, attribute SVGSVGElement.viewBox, attribute SVGSymbolElement.viewBox, attribute SVGViewElement.viewBox, attribute SVGViewSpec.viewBox
dom_externs.viewBoxString;              // attribute SVGViewSpec.viewBoxString
dom_externs.viewTarget;                 // attribute SVGViewElement.viewTarget, attribute SVGViewSpec.viewTarget
dom_externs.viewTargetString;           // attribute SVGViewSpec.viewTargetString
dom_externs.viewport;                   // attribute SVGSVGElement.viewport, operation WebGLRenderingContext.viewport
dom_externs.viewportElement;            // attribute SVGElement.viewportElement
dom_externs.visible;                    // attribute BarInfo.visible, attribute ScriptProfileNode.visible
dom_externs.vlinkColor;                 // attribute HTMLDocument.vlinkColor
dom_externs.volume;                     // attribute HTMLMediaElement.volume
dom_externs.vspace;                     // attribute HTMLAppletElement.vspace, attribute HTMLImageElement.vspace, attribute HTMLMarqueeElement.vspace, attribute HTMLObjectElement.vspace
dom_externs.warn;                       // operation Console.warn
dom_externs.wasClean;                   // attribute CloseEvent.wasClean
dom_externs.watchPosition;              // operation Geolocation.watchPosition
dom_externs.webkitAudioDecodedByteCount;  // attribute HTMLMediaElement.webkitAudioDecodedByteCount
dom_externs.webkitCancelRequestAnimationFrame;  // operation DOMWindow.webkitCancelRequestAnimationFrame
dom_externs.webkitClosedCaptionsVisible;  // attribute HTMLMediaElement.webkitClosedCaptionsVisible
dom_externs.webkitConvertPointFromNodeToPage;  // operation DOMWindow.webkitConvertPointFromNodeToPage
dom_externs.webkitConvertPointFromPageToNode;  // operation DOMWindow.webkitConvertPointFromPageToNode
dom_externs.webkitDecodedFrameCount;    // attribute HTMLVideoElement.webkitDecodedFrameCount
dom_externs.webkitDirectionInvertedFromDevice;  // attribute WheelEvent.webkitDirectionInvertedFromDevice
dom_externs.webkitDisplayingFullscreen;  // attribute HTMLVideoElement.webkitDisplayingFullscreen
dom_externs.webkitDroppedFrameCount;    // attribute HTMLVideoElement.webkitDroppedFrameCount
dom_externs.webkitEnterFullScreen;      // operation HTMLVideoElement.webkitEnterFullScreen
dom_externs.webkitEnterFullscreen;      // operation HTMLVideoElement.webkitEnterFullscreen
dom_externs.webkitErrorMessage;         // attribute IDBRequest.webkitErrorMessage
dom_externs.webkitExitFullScreen;       // operation HTMLVideoElement.webkitExitFullScreen
dom_externs.webkitExitFullscreen;       // operation HTMLVideoElement.webkitExitFullscreen
dom_externs.webkitForce;                // attribute Touch.webkitForce
dom_externs.webkitGrammar;              // attribute HTMLInputElement.webkitGrammar
dom_externs.webkitHasClosedCaptions;    // attribute HTMLMediaElement.webkitHasClosedCaptions
dom_externs.webkitHidden;               // attribute Document.webkitHidden
dom_externs.webkitInitMessageEvent;     // operation MessageEvent.webkitInitMessageEvent
dom_externs.webkitLineDash;             // attribute CanvasRenderingContext2D.webkitLineDash
dom_externs.webkitLineDashOffset;       // attribute CanvasRenderingContext2D.webkitLineDashOffset
dom_externs.webkitMatchesSelector;      // operation Element.webkitMatchesSelector
dom_externs.webkitNotifications;        // attribute DOMWindow.webkitNotifications, attribute WorkerContext.webkitNotifications
dom_externs.webkitPostMessage;          // operation DOMWindow.webkitPostMessage, operation DedicatedWorkerContext.webkitPostMessage, operation MessagePort.webkitPostMessage, operation Worker.webkitPostMessage
dom_externs.webkitPreservesPitch;       // attribute HTMLMediaElement.webkitPreservesPitch
dom_externs.webkitRadiusX;              // attribute Touch.webkitRadiusX
dom_externs.webkitRadiusY;              // attribute Touch.webkitRadiusY
dom_externs.webkitRequestAnimationFrame;  // operation DOMWindow.webkitRequestAnimationFrame
dom_externs.webkitRotationAngle;        // attribute Touch.webkitRotationAngle
dom_externs.webkitSpeech;               // attribute HTMLInputElement.webkitSpeech
dom_externs.webkitSupportsFullscreen;   // attribute HTMLVideoElement.webkitSupportsFullscreen
dom_externs.webkitURL;                  // attribute DOMWindow.webkitURL, attribute WorkerContext.webkitURL
dom_externs.webkitVideoDecodedByteCount;  // attribute HTMLMediaElement.webkitVideoDecodedByteCount
dom_externs.webkitVisibilityState;      // attribute Document.webkitVisibilityState
dom_externs.webkitdirectory;            // attribute HTMLInputElement.webkitdirectory
dom_externs.webkitdropzone;             // attribute HTMLElement.webkitdropzone
dom_externs.whatToShow;                 // attribute NodeIterator.whatToShow, attribute TreeWalker.whatToShow
dom_externs.wheelDelta;                 // attribute WheelEvent.wheelDelta
dom_externs.wheelDeltaX;                // attribute WheelEvent.wheelDeltaX
dom_externs.wheelDeltaY;                // attribute WheelEvent.wheelDeltaY
dom_externs.which;                      // attribute UIEvent.which
dom_externs.wholeText;                  // attribute Text.wholeText
dom_externs.width;                      // attribute ClientRect.width, attribute HTMLAppletElement.width, attribute HTMLCanvasElement.width, attribute HTMLDocument.width, attribute HTMLEmbedElement.width, attribute HTMLFrameElement.width, attribute HTMLHRElement.width, attribute HTMLIFrameElement.width, attribute HTMLImageElement.width, attribute HTMLMarqueeElement.width, attribute HTMLObjectElement.width, attribute HTMLPreElement.width, attribute HTMLTableCellElement.width, attribute HTMLTableColElement.width, attribute HTMLTableElement.width, attribute HTMLVideoElement.width, attribute ImageData.width, attribute SVGFEBlendElement.width, attribute SVGFEColorMatrixElement.width, attribute SVGFEComponentTransferElement.width, attribute SVGFECompositeElement.width, attribute SVGFEConvolveMatrixElement.width, attribute SVGFEDiffuseLightingElement.width, attribute SVGFEDisplacementMapElement.width, attribute SVGFEDropShadowElement.width, attribute SVGFEFloodElement.width, attribute SVGFEGaussianBlurElement.width, attribute SVGFEImageElement.width, attribute SVGFEMergeElement.width, attribute SVGFEMorphologyElement.width, attribute SVGFEOffsetElement.width, attribute SVGFESpecularLightingElement.width, attribute SVGFETileElement.width, attribute SVGFETurbulenceElement.width, attribute SVGFilterElement.width, attribute SVGFilterPrimitiveStandardAttributes.width, attribute SVGForeignObjectElement.width, attribute SVGImageElement.width, attribute SVGMaskElement.width, attribute SVGPatternElement.width, attribute SVGRect.width, attribute SVGRectElement.width, attribute SVGSVGElement.width, attribute SVGUseElement.width, attribute Screen.width, attribute TextMetrics.width
dom_externs.willValidate;               // attribute HTMLButtonElement.willValidate, attribute HTMLFieldSetElement.willValidate, attribute HTMLInputElement.willValidate, attribute HTMLKeygenElement.willValidate, attribute HTMLObjectElement.willValidate, attribute HTMLOutputElement.willValidate, attribute HTMLSelectElement.willValidate, attribute HTMLTextAreaElement.willValidate
dom_externs.window;                     // attribute DOMWindow.window
dom_externs.withCredentials;            // attribute XMLHttpRequest.withCredentials
dom_externs.wrap;                       // attribute HTMLPreElement.wrap, attribute HTMLTextAreaElement.wrap
dom_externs.write;                      // operation FileWriter.write, operation FileWriterSync.write, operation HTMLDocument.write
dom_externs.writeln;                    // operation HTMLDocument.writeln
dom_externs.x;                          // attribute HTMLImageElement.x, attribute MouseEvent.x, attribute SVGCursorElement.x, attribute SVGFEBlendElement.x, attribute SVGFEColorMatrixElement.x, attribute SVGFEComponentTransferElement.x, attribute SVGFECompositeElement.x, attribute SVGFEConvolveMatrixElement.x, attribute SVGFEDiffuseLightingElement.x, attribute SVGFEDisplacementMapElement.x, attribute SVGFEDropShadowElement.x, attribute SVGFEFloodElement.x, attribute SVGFEGaussianBlurElement.x, attribute SVGFEImageElement.x, attribute SVGFEMergeElement.x, attribute SVGFEMorphologyElement.x, attribute SVGFEOffsetElement.x, attribute SVGFEPointLightElement.x, attribute SVGFESpecularLightingElement.x, attribute SVGFESpotLightElement.x, attribute SVGFETileElement.x, attribute SVGFETurbulenceElement.x, attribute SVGFilterElement.x, attribute SVGFilterPrimitiveStandardAttributes.x, attribute SVGForeignObjectElement.x, attribute SVGGlyphRefElement.x, attribute SVGImageElement.x, attribute SVGMaskElement.x, attribute SVGPathSegArcAbs.x, attribute SVGPathSegArcRel.x, attribute SVGPathSegCurvetoCubicAbs.x, attribute SVGPathSegCurvetoCubicRel.x, attribute SVGPathSegCurvetoCubicSmoothAbs.x, attribute SVGPathSegCurvetoCubicSmoothRel.x, attribute SVGPathSegCurvetoQuadraticAbs.x, attribute SVGPathSegCurvetoQuadraticRel.x, attribute SVGPathSegCurvetoQuadraticSmoothAbs.x, attribute SVGPathSegCurvetoQuadraticSmoothRel.x, attribute SVGPathSegLinetoAbs.x, attribute SVGPathSegLinetoHorizontalAbs.x, attribute SVGPathSegLinetoHorizontalRel.x, attribute SVGPathSegLinetoRel.x, attribute SVGPathSegMovetoAbs.x, attribute SVGPathSegMovetoRel.x, attribute SVGPatternElement.x, attribute SVGPoint.x, attribute SVGRect.x, attribute SVGRectElement.x, attribute SVGSVGElement.x, attribute SVGTextPositioningElement.x, attribute SVGUseElement.x, attribute WebKitPoint.x, attribute WheelEvent.x
dom_externs.x1;                         // attribute SVGLineElement.x1, attribute SVGLinearGradientElement.x1, attribute SVGPathSegCurvetoCubicAbs.x1, attribute SVGPathSegCurvetoCubicRel.x1, attribute SVGPathSegCurvetoQuadraticAbs.x1, attribute SVGPathSegCurvetoQuadraticRel.x1
dom_externs.x2;                         // attribute SVGLineElement.x2, attribute SVGLinearGradientElement.x2, attribute SVGPathSegCurvetoCubicAbs.x2, attribute SVGPathSegCurvetoCubicRel.x2, attribute SVGPathSegCurvetoCubicSmoothAbs.x2, attribute SVGPathSegCurvetoCubicSmoothRel.x2
dom_externs.xChannelSelector;           // attribute SVGFEDisplacementMapElement.xChannelSelector
dom_externs.xmlEncoding;                // attribute Document.xmlEncoding
dom_externs.xmlStandalone;              // attribute Document.xmlStandalone
dom_externs.xmlVersion;                 // attribute Document.xmlVersion
dom_externs.xmlbase;                    // attribute SVGElement.xmlbase
dom_externs.xmllang;                    // attribute SVGAElement.xmllang, attribute SVGCircleElement.xmllang, attribute SVGClipPathElement.xmllang, attribute SVGDefsElement.xmllang, attribute SVGDescElement.xmllang, attribute SVGEllipseElement.xmllang, attribute SVGFEImageElement.xmllang, attribute SVGFilterElement.xmllang, attribute SVGForeignObjectElement.xmllang, attribute SVGGElement.xmllang, attribute SVGImageElement.xmllang, attribute SVGLangSpace.xmllang, attribute SVGLineElement.xmllang, attribute SVGMarkerElement.xmllang, attribute SVGMaskElement.xmllang, attribute SVGPathElement.xmllang, attribute SVGPatternElement.xmllang, attribute SVGPolygonElement.xmllang, attribute SVGPolylineElement.xmllang, attribute SVGRectElement.xmllang, attribute SVGSVGElement.xmllang, attribute SVGStyleElement.xmllang, attribute SVGSwitchElement.xmllang, attribute SVGSymbolElement.xmllang, attribute SVGTextContentElement.xmllang, attribute SVGTitleElement.xmllang, attribute SVGUseElement.xmllang
dom_externs.xmlspace;                   // attribute SVGAElement.xmlspace, attribute SVGCircleElement.xmlspace, attribute SVGClipPathElement.xmlspace, attribute SVGDefsElement.xmlspace, attribute SVGDescElement.xmlspace, attribute SVGEllipseElement.xmlspace, attribute SVGFEImageElement.xmlspace, attribute SVGFilterElement.xmlspace, attribute SVGForeignObjectElement.xmlspace, attribute SVGGElement.xmlspace, attribute SVGImageElement.xmlspace, attribute SVGLangSpace.xmlspace, attribute SVGLineElement.xmlspace, attribute SVGMarkerElement.xmlspace, attribute SVGMaskElement.xmlspace, attribute SVGPathElement.xmlspace, attribute SVGPatternElement.xmlspace, attribute SVGPolygonElement.xmlspace, attribute SVGPolylineElement.xmlspace, attribute SVGRectElement.xmlspace, attribute SVGSVGElement.xmlspace, attribute SVGStyleElement.xmlspace, attribute SVGSwitchElement.xmlspace, attribute SVGSymbolElement.xmlspace, attribute SVGTextContentElement.xmlspace, attribute SVGTitleElement.xmlspace, attribute SVGUseElement.xmlspace
dom_externs.y;                          // attribute HTMLImageElement.y, attribute MouseEvent.y, attribute SVGCursorElement.y, attribute SVGFEBlendElement.y, attribute SVGFEColorMatrixElement.y, attribute SVGFEComponentTransferElement.y, attribute SVGFECompositeElement.y, attribute SVGFEConvolveMatrixElement.y, attribute SVGFEDiffuseLightingElement.y, attribute SVGFEDisplacementMapElement.y, attribute SVGFEDropShadowElement.y, attribute SVGFEFloodElement.y, attribute SVGFEGaussianBlurElement.y, attribute SVGFEImageElement.y, attribute SVGFEMergeElement.y, attribute SVGFEMorphologyElement.y, attribute SVGFEOffsetElement.y, attribute SVGFEPointLightElement.y, attribute SVGFESpecularLightingElement.y, attribute SVGFESpotLightElement.y, attribute SVGFETileElement.y, attribute SVGFETurbulenceElement.y, attribute SVGFilterElement.y, attribute SVGFilterPrimitiveStandardAttributes.y, attribute SVGForeignObjectElement.y, attribute SVGGlyphRefElement.y, attribute SVGImageElement.y, attribute SVGMaskElement.y, attribute SVGPathSegArcAbs.y, attribute SVGPathSegArcRel.y, attribute SVGPathSegCurvetoCubicAbs.y, attribute SVGPathSegCurvetoCubicRel.y, attribute SVGPathSegCurvetoCubicSmoothAbs.y, attribute SVGPathSegCurvetoCubicSmoothRel.y, attribute SVGPathSegCurvetoQuadraticAbs.y, attribute SVGPathSegCurvetoQuadraticRel.y, attribute SVGPathSegCurvetoQuadraticSmoothAbs.y, attribute SVGPathSegCurvetoQuadraticSmoothRel.y, attribute SVGPathSegLinetoAbs.y, attribute SVGPathSegLinetoRel.y, attribute SVGPathSegLinetoVerticalAbs.y, attribute SVGPathSegLinetoVerticalRel.y, attribute SVGPathSegMovetoAbs.y, attribute SVGPathSegMovetoRel.y, attribute SVGPatternElement.y, attribute SVGPoint.y, attribute SVGRect.y, attribute SVGRectElement.y, attribute SVGSVGElement.y, attribute SVGTextPositioningElement.y, attribute SVGUseElement.y, attribute WebKitPoint.y, attribute WheelEvent.y
dom_externs.y1;                         // attribute SVGLineElement.y1, attribute SVGLinearGradientElement.y1, attribute SVGPathSegCurvetoCubicAbs.y1, attribute SVGPathSegCurvetoCubicRel.y1, attribute SVGPathSegCurvetoQuadraticAbs.y1, attribute SVGPathSegCurvetoQuadraticRel.y1
dom_externs.y2;                         // attribute SVGLineElement.y2, attribute SVGLinearGradientElement.y2, attribute SVGPathSegCurvetoCubicAbs.y2, attribute SVGPathSegCurvetoCubicRel.y2, attribute SVGPathSegCurvetoCubicSmoothAbs.y2, attribute SVGPathSegCurvetoCubicSmoothRel.y2
dom_externs.yChannelSelector;           // attribute SVGFEDisplacementMapElement.yChannelSelector
dom_externs.z;                          // attribute SVGFEPointLightElement.z, attribute SVGFESpotLightElement.z
dom_externs.zoomAndPan;                 // attribute SVGSVGElement.zoomAndPan, attribute SVGViewElement.zoomAndPan, attribute SVGZoomAndPan.zoomAndPan
dom_externs.zoomRectScreen;             // attribute SVGZoomEvent.zoomRectScreen


}
