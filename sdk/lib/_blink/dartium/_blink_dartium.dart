// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.
library dart.dom._blink;

import 'dart:js' as js;

// This is a place to put custom renames if we need them.
final resolverMap = {
};

dynamic resolver(String s) {
  if (s == "ANGLEInstancedArrays") return BlinkANGLEInstancedArrays.instance;
  if (s == "AnalyserNode") return BlinkAnalyserNode.instance;
  if (s == "Animation") return BlinkAnimation.instance;
  if (s == "AnimationEffect") return BlinkAnimationEffect.instance;
  if (s == "AnimationNode") return BlinkAnimationNode.instance;
  if (s == "AnimationPlayer") return BlinkAnimationPlayer.instance;
  if (s == "AnimationPlayerEvent") return BlinkAnimationPlayerEvent.instance;
  if (s == "AnimationTimeline") return BlinkAnimationTimeline.instance;
  if (s == "ApplicationCache") return BlinkApplicationCache.instance;
  if (s == "ApplicationCacheErrorEvent") return BlinkApplicationCacheErrorEvent.instance;
  if (s == "Attr") return BlinkAttr.instance;
  if (s == "AudioBuffer") return BlinkAudioBuffer.instance;
  if (s == "AudioBufferSourceNode") return BlinkAudioBufferSourceNode.instance;
  if (s == "AudioContext") return BlinkAudioContext.instance;
  if (s == "AudioDestinationNode") return BlinkAudioDestinationNode.instance;
  if (s == "AudioListener") return BlinkAudioListener.instance;
  if (s == "AudioNode") return BlinkAudioNode.instance;
  if (s == "AudioParam") return BlinkAudioParam.instance;
  if (s == "AudioProcessingEvent") return BlinkAudioProcessingEvent.instance;
  if (s == "AudioSourceNode") return BlinkAudioSourceNode.instance;
  if (s == "AudioTrack") return BlinkAudioTrack.instance;
  if (s == "AudioTrackList") return BlinkAudioTrackList.instance;
  if (s == "AutocompleteErrorEvent") return BlinkAutocompleteErrorEvent.instance;
  if (s == "BarProp") return BlinkBarProp.instance;
  if (s == "BatteryManager") return BlinkBatteryManager.instance;
  if (s == "BeforeUnloadEvent") return BlinkBeforeUnloadEvent.instance;
  if (s == "BiquadFilterNode") return BlinkBiquadFilterNode.instance;
  if (s == "Blob") return BlinkBlob.instance;
  if (s == "Body") return BlinkBody.instance;
  if (s == "CDATASection") return BlinkCDATASection.instance;
  if (s == "CSS") return BlinkCSS.instance;
  if (s == "CSSCharsetRule") return BlinkCSSCharsetRule.instance;
  if (s == "CSSFontFaceRule") return BlinkCSSFontFaceRule.instance;
  if (s == "CSSImportRule") return BlinkCSSImportRule.instance;
  if (s == "CSSKeyframeRule") return BlinkCSSKeyframeRule.instance;
  if (s == "CSSKeyframesRule") return BlinkCSSKeyframesRule.instance;
  if (s == "CSSMediaRule") return BlinkCSSMediaRule.instance;
  if (s == "CSSPageRule") return BlinkCSSPageRule.instance;
  if (s == "CSSPrimitiveValue") return BlinkCSSPrimitiveValue.instance;
  if (s == "CSSRule") return BlinkCSSRule.instance;
  if (s == "CSSRuleList") return BlinkCSSRuleList.instance;
  if (s == "CSSStyleDeclaration") return BlinkCSSStyleDeclaration.instance;
  if (s == "CSSStyleRule") return BlinkCSSStyleRule.instance;
  if (s == "CSSStyleSheet") return BlinkCSSStyleSheet.instance;
  if (s == "CSSSupportsRule") return BlinkCSSSupportsRule.instance;
  if (s == "CSSUnknownRule") return BlinkCSSUnknownRule.instance;
  if (s == "CSSValue") return BlinkCSSValue.instance;
  if (s == "CSSValueList") return BlinkCSSValueList.instance;
  if (s == "CSSViewportRule") return BlinkCSSViewportRule.instance;
  if (s == "Cache") return BlinkCache.instance;
  if (s == "CacheStorage") return BlinkCacheStorage.instance;
  if (s == "Canvas2DContextAttributes") return BlinkCanvas2DContextAttributes.instance;
  if (s == "CanvasGradient") return BlinkCanvasGradient.instance;
  if (s == "CanvasPattern") return BlinkCanvasPattern.instance;
  if (s == "CanvasRenderingContext2D") return BlinkCanvasRenderingContext2D.instance;
  if (s == "ChannelMergerNode") return BlinkChannelMergerNode.instance;
  if (s == "ChannelSplitterNode") return BlinkChannelSplitterNode.instance;
  if (s == "CharacterData") return BlinkCharacterData.instance;
  if (s == "CircularGeofencingRegion") return BlinkCircularGeofencingRegion.instance;
  if (s == "ClientRect") return BlinkClientRect.instance;
  if (s == "ClientRectList") return BlinkClientRectList.instance;
  if (s == "CloseEvent") return BlinkCloseEvent.instance;
  if (s == "Comment") return BlinkComment.instance;
  if (s == "CompositionEvent") return BlinkCompositionEvent.instance;
  if (s == "Console") return BlinkConsole.instance;
  if (s == "ConsoleBase") return BlinkConsoleBase.instance;
  if (s == "ConvolverNode") return BlinkConvolverNode.instance;
  if (s == "Coordinates") return BlinkCoordinates.instance;
  if (s == "Counter") return BlinkCounter.instance;
  if (s == "Credential") return BlinkCredential.instance;
  if (s == "CredentialsContainer") return BlinkCredentialsContainer.instance;
  if (s == "Crypto") return BlinkCrypto.instance;
  if (s == "CryptoKey") return BlinkCryptoKey.instance;
  if (s == "CustomEvent") return BlinkCustomEvent.instance;
  if (s == "DOMError") return BlinkDOMError.instance;
  if (s == "DOMException") return BlinkDOMException.instance;
  if (s == "DOMFileSystem") return BlinkDOMFileSystem.instance;
  if (s == "DOMFileSystemSync") return BlinkDOMFileSystemSync.instance;
  if (s == "DOMImplementation") return BlinkDOMImplementation.instance;
  if (s == "DOMMatrix") return BlinkDOMMatrix.instance;
  if (s == "DOMMatrixReadOnly") return BlinkDOMMatrixReadOnly.instance;
  if (s == "DOMParser") return BlinkDOMParser.instance;
  if (s == "DOMPoint") return BlinkDOMPoint.instance;
  if (s == "DOMPointReadOnly") return BlinkDOMPointReadOnly.instance;
  if (s == "DOMRect") return BlinkDOMRect.instance;
  if (s == "DOMRectReadOnly") return BlinkDOMRectReadOnly.instance;
  if (s == "DOMSettableTokenList") return BlinkDOMSettableTokenList.instance;
  if (s == "DOMStringList") return BlinkDOMStringList.instance;
  if (s == "DOMStringMap") return BlinkDOMStringMap.instance;
  if (s == "DOMTokenList") return BlinkDOMTokenList.instance;
  if (s == "DataTransfer") return BlinkDataTransfer.instance;
  if (s == "DataTransferItem") return BlinkDataTransferItem.instance;
  if (s == "DataTransferItemList") return BlinkDataTransferItemList.instance;
  if (s == "Database") return BlinkDatabase.instance;
  if (s == "DedicatedWorkerGlobalScope") return BlinkDedicatedWorkerGlobalScope.instance;
  if (s == "DelayNode") return BlinkDelayNode.instance;
  if (s == "DeprecatedStorageInfo") return BlinkDeprecatedStorageInfo.instance;
  if (s == "DeprecatedStorageQuota") return BlinkDeprecatedStorageQuota.instance;
  if (s == "DeviceAcceleration") return BlinkDeviceAcceleration.instance;
  if (s == "DeviceLightEvent") return BlinkDeviceLightEvent.instance;
  if (s == "DeviceMotionEvent") return BlinkDeviceMotionEvent.instance;
  if (s == "DeviceOrientationEvent") return BlinkDeviceOrientationEvent.instance;
  if (s == "DeviceRotationRate") return BlinkDeviceRotationRate.instance;
  if (s == "DirectoryEntry") return BlinkDirectoryEntry.instance;
  if (s == "DirectoryEntrySync") return BlinkDirectoryEntrySync.instance;
  if (s == "DirectoryReader") return BlinkDirectoryReader.instance;
  if (s == "DirectoryReaderSync") return BlinkDirectoryReaderSync.instance;
  if (s == "Document") return BlinkDocument.instance;
  if (s == "DocumentFragment") return BlinkDocumentFragment.instance;
  if (s == "DocumentType") return BlinkDocumentType.instance;
  if (s == "DynamicsCompressorNode") return BlinkDynamicsCompressorNode.instance;
  if (s == "EXTBlendMinMax") return BlinkEXTBlendMinMax.instance;
  if (s == "EXTFragDepth") return BlinkEXTFragDepth.instance;
  if (s == "EXTShaderTextureLOD") return BlinkEXTShaderTextureLOD.instance;
  if (s == "EXTTextureFilterAnisotropic") return BlinkEXTTextureFilterAnisotropic.instance;
  if (s == "Element") return BlinkElement.instance;
  if (s == "Entry") return BlinkEntry.instance;
  if (s == "EntrySync") return BlinkEntrySync.instance;
  if (s == "ErrorEvent") return BlinkErrorEvent.instance;
  if (s == "Event") return BlinkEvent.instance;
  if (s == "EventSource") return BlinkEventSource.instance;
  if (s == "EventTarget") return BlinkEventTarget.instance;
  if (s == "ExtendableEvent") return BlinkExtendableEvent.instance;
  if (s == "FederatedCredential") return BlinkFederatedCredential.instance;
  if (s == "FetchEvent") return BlinkFetchEvent.instance;
  if (s == "File") return BlinkFile.instance;
  if (s == "FileEntry") return BlinkFileEntry.instance;
  if (s == "FileEntrySync") return BlinkFileEntrySync.instance;
  if (s == "FileError") return BlinkFileError.instance;
  if (s == "FileList") return BlinkFileList.instance;
  if (s == "FileReader") return BlinkFileReader.instance;
  if (s == "FileReaderSync") return BlinkFileReaderSync.instance;
  if (s == "FileWriter") return BlinkFileWriter.instance;
  if (s == "FileWriterSync") return BlinkFileWriterSync.instance;
  if (s == "FocusEvent") return BlinkFocusEvent.instance;
  if (s == "FontFace") return BlinkFontFace.instance;
  if (s == "FontFaceSet") return BlinkFontFaceSet.instance;
  if (s == "FontFaceSetLoadEvent") return BlinkFontFaceSetLoadEvent.instance;
  if (s == "FormData") return BlinkFormData.instance;
  if (s == "GainNode") return BlinkGainNode.instance;
  if (s == "Gamepad") return BlinkGamepad.instance;
  if (s == "GamepadButton") return BlinkGamepadButton.instance;
  if (s == "GamepadEvent") return BlinkGamepadEvent.instance;
  if (s == "GamepadList") return BlinkGamepadList.instance;
  if (s == "Geofencing") return BlinkGeofencing.instance;
  if (s == "GeofencingRegion") return BlinkGeofencingRegion.instance;
  if (s == "Geolocation") return BlinkGeolocation.instance;
  if (s == "Geoposition") return BlinkGeoposition.instance;
  if (s == "HTMLAllCollection") return BlinkHTMLAllCollection.instance;
  if (s == "HTMLAnchorElement") return BlinkHTMLAnchorElement.instance;
  if (s == "HTMLAppletElement") return BlinkHTMLAppletElement.instance;
  if (s == "HTMLAreaElement") return BlinkHTMLAreaElement.instance;
  if (s == "HTMLAudioElement") return BlinkHTMLAudioElement.instance;
  if (s == "HTMLBRElement") return BlinkHTMLBRElement.instance;
  if (s == "HTMLBaseElement") return BlinkHTMLBaseElement.instance;
  if (s == "HTMLBodyElement") return BlinkHTMLBodyElement.instance;
  if (s == "HTMLButtonElement") return BlinkHTMLButtonElement.instance;
  if (s == "HTMLCanvasElement") return BlinkHTMLCanvasElement.instance;
  if (s == "HTMLCollection") return BlinkHTMLCollection.instance;
  if (s == "HTMLContentElement") return BlinkHTMLContentElement.instance;
  if (s == "HTMLDListElement") return BlinkHTMLDListElement.instance;
  if (s == "HTMLDataListElement") return BlinkHTMLDataListElement.instance;
  if (s == "HTMLDetailsElement") return BlinkHTMLDetailsElement.instance;
  if (s == "HTMLDialogElement") return BlinkHTMLDialogElement.instance;
  if (s == "HTMLDirectoryElement") return BlinkHTMLDirectoryElement.instance;
  if (s == "HTMLDivElement") return BlinkHTMLDivElement.instance;
  if (s == "HTMLDocument") return BlinkHTMLDocument.instance;
  if (s == "HTMLElement") return BlinkHTMLElement.instance;
  if (s == "HTMLEmbedElement") return BlinkHTMLEmbedElement.instance;
  if (s == "HTMLFieldSetElement") return BlinkHTMLFieldSetElement.instance;
  if (s == "HTMLFontElement") return BlinkHTMLFontElement.instance;
  if (s == "HTMLFormControlsCollection") return BlinkHTMLFormControlsCollection.instance;
  if (s == "HTMLFormElement") return BlinkHTMLFormElement.instance;
  if (s == "HTMLFrameElement") return BlinkHTMLFrameElement.instance;
  if (s == "HTMLFrameSetElement") return BlinkHTMLFrameSetElement.instance;
  if (s == "HTMLHRElement") return BlinkHTMLHRElement.instance;
  if (s == "HTMLHeadElement") return BlinkHTMLHeadElement.instance;
  if (s == "HTMLHeadingElement") return BlinkHTMLHeadingElement.instance;
  if (s == "HTMLHtmlElement") return BlinkHTMLHtmlElement.instance;
  if (s == "HTMLIFrameElement") return BlinkHTMLIFrameElement.instance;
  if (s == "HTMLImageElement") return BlinkHTMLImageElement.instance;
  if (s == "HTMLInputElement") return BlinkHTMLInputElement.instance;
  if (s == "HTMLKeygenElement") return BlinkHTMLKeygenElement.instance;
  if (s == "HTMLLIElement") return BlinkHTMLLIElement.instance;
  if (s == "HTMLLabelElement") return BlinkHTMLLabelElement.instance;
  if (s == "HTMLLegendElement") return BlinkHTMLLegendElement.instance;
  if (s == "HTMLLinkElement") return BlinkHTMLLinkElement.instance;
  if (s == "HTMLMapElement") return BlinkHTMLMapElement.instance;
  if (s == "HTMLMarqueeElement") return BlinkHTMLMarqueeElement.instance;
  if (s == "HTMLMediaElement") return BlinkHTMLMediaElement.instance;
  if (s == "HTMLMenuElement") return BlinkHTMLMenuElement.instance;
  if (s == "HTMLMenuItemElement") return BlinkHTMLMenuItemElement.instance;
  if (s == "HTMLMetaElement") return BlinkHTMLMetaElement.instance;
  if (s == "HTMLMeterElement") return BlinkHTMLMeterElement.instance;
  if (s == "HTMLModElement") return BlinkHTMLModElement.instance;
  if (s == "HTMLOListElement") return BlinkHTMLOListElement.instance;
  if (s == "HTMLObjectElement") return BlinkHTMLObjectElement.instance;
  if (s == "HTMLOptGroupElement") return BlinkHTMLOptGroupElement.instance;
  if (s == "HTMLOptionElement") return BlinkHTMLOptionElement.instance;
  if (s == "HTMLOptionsCollection") return BlinkHTMLOptionsCollection.instance;
  if (s == "HTMLOutputElement") return BlinkHTMLOutputElement.instance;
  if (s == "HTMLParagraphElement") return BlinkHTMLParagraphElement.instance;
  if (s == "HTMLParamElement") return BlinkHTMLParamElement.instance;
  if (s == "HTMLPictureElement") return BlinkHTMLPictureElement.instance;
  if (s == "HTMLPreElement") return BlinkHTMLPreElement.instance;
  if (s == "HTMLProgressElement") return BlinkHTMLProgressElement.instance;
  if (s == "HTMLQuoteElement") return BlinkHTMLQuoteElement.instance;
  if (s == "HTMLScriptElement") return BlinkHTMLScriptElement.instance;
  if (s == "HTMLSelectElement") return BlinkHTMLSelectElement.instance;
  if (s == "HTMLShadowElement") return BlinkHTMLShadowElement.instance;
  if (s == "HTMLSourceElement") return BlinkHTMLSourceElement.instance;
  if (s == "HTMLSpanElement") return BlinkHTMLSpanElement.instance;
  if (s == "HTMLStyleElement") return BlinkHTMLStyleElement.instance;
  if (s == "HTMLTableCaptionElement") return BlinkHTMLTableCaptionElement.instance;
  if (s == "HTMLTableCellElement") return BlinkHTMLTableCellElement.instance;
  if (s == "HTMLTableColElement") return BlinkHTMLTableColElement.instance;
  if (s == "HTMLTableElement") return BlinkHTMLTableElement.instance;
  if (s == "HTMLTableRowElement") return BlinkHTMLTableRowElement.instance;
  if (s == "HTMLTableSectionElement") return BlinkHTMLTableSectionElement.instance;
  if (s == "HTMLTemplateElement") return BlinkHTMLTemplateElement.instance;
  if (s == "HTMLTextAreaElement") return BlinkHTMLTextAreaElement.instance;
  if (s == "HTMLTitleElement") return BlinkHTMLTitleElement.instance;
  if (s == "HTMLTrackElement") return BlinkHTMLTrackElement.instance;
  if (s == "HTMLUListElement") return BlinkHTMLUListElement.instance;
  if (s == "HTMLUnknownElement") return BlinkHTMLUnknownElement.instance;
  if (s == "HTMLVideoElement") return BlinkHTMLVideoElement.instance;
  if (s == "HashChangeEvent") return BlinkHashChangeEvent.instance;
  if (s == "Headers") return BlinkHeaders.instance;
  if (s == "History") return BlinkHistory.instance;
  if (s == "IDBCursor") return BlinkIDBCursor.instance;
  if (s == "IDBCursorWithValue") return BlinkIDBCursorWithValue.instance;
  if (s == "IDBDatabase") return BlinkIDBDatabase.instance;
  if (s == "IDBFactory") return BlinkIDBFactory.instance;
  if (s == "IDBIndex") return BlinkIDBIndex.instance;
  if (s == "IDBKeyRange") return BlinkIDBKeyRange.instance;
  if (s == "IDBObjectStore") return BlinkIDBObjectStore.instance;
  if (s == "IDBOpenDBRequest") return BlinkIDBOpenDBRequest.instance;
  if (s == "IDBRequest") return BlinkIDBRequest.instance;
  if (s == "IDBTransaction") return BlinkIDBTransaction.instance;
  if (s == "IDBVersionChangeEvent") return BlinkIDBVersionChangeEvent.instance;
  if (s == "ImageBitmap") return BlinkImageBitmap.instance;
  if (s == "ImageData") return BlinkImageData.instance;
  if (s == "InjectedScriptHost") return BlinkInjectedScriptHost.instance;
  if (s == "InputMethodContext") return BlinkInputMethodContext.instance;
  if (s == "InspectorFrontendHost") return BlinkInspectorFrontendHost.instance;
  if (s == "InspectorOverlayHost") return BlinkInspectorOverlayHost.instance;
  if (s == "InstallEvent") return BlinkInstallEvent.instance;
  if (s == "Iterator") return BlinkIterator.instance;
  if (s == "JavaScriptCallFrame") return BlinkJavaScriptCallFrame.instance;
  if (s == "KeyboardEvent") return BlinkKeyboardEvent.instance;
  if (s == "LocalCredential") return BlinkLocalCredential.instance;
  if (s == "Location") return BlinkLocation.instance;
  if (s == "MIDIAccess") return BlinkMIDIAccess.instance;
  if (s == "MIDIConnectionEvent") return BlinkMIDIConnectionEvent.instance;
  if (s == "MIDIInput") return BlinkMIDIInput.instance;
  if (s == "MIDIInputMap") return BlinkMIDIInputMap.instance;
  if (s == "MIDIMessageEvent") return BlinkMIDIMessageEvent.instance;
  if (s == "MIDIOutput") return BlinkMIDIOutput.instance;
  if (s == "MIDIOutputMap") return BlinkMIDIOutputMap.instance;
  if (s == "MIDIPort") return BlinkMIDIPort.instance;
  if (s == "MediaController") return BlinkMediaController.instance;
  if (s == "MediaDeviceInfo") return BlinkMediaDeviceInfo.instance;
  if (s == "MediaElementAudioSourceNode") return BlinkMediaElementAudioSourceNode.instance;
  if (s == "MediaError") return BlinkMediaError.instance;
  if (s == "MediaKeyError") return BlinkMediaKeyError.instance;
  if (s == "MediaKeyEvent") return BlinkMediaKeyEvent.instance;
  if (s == "MediaKeyMessageEvent") return BlinkMediaKeyMessageEvent.instance;
  if (s == "MediaKeyNeededEvent") return BlinkMediaKeyNeededEvent.instance;
  if (s == "MediaKeySession") return BlinkMediaKeySession.instance;
  if (s == "MediaKeys") return BlinkMediaKeys.instance;
  if (s == "MediaList") return BlinkMediaList.instance;
  if (s == "MediaQueryList") return BlinkMediaQueryList.instance;
  if (s == "MediaQueryListEvent") return BlinkMediaQueryListEvent.instance;
  if (s == "MediaSource") return BlinkMediaSource.instance;
  if (s == "MediaStream") return BlinkMediaStream.instance;
  if (s == "MediaStreamAudioDestinationNode") return BlinkMediaStreamAudioDestinationNode.instance;
  if (s == "MediaStreamAudioSourceNode") return BlinkMediaStreamAudioSourceNode.instance;
  if (s == "MediaStreamEvent") return BlinkMediaStreamEvent.instance;
  if (s == "MediaStreamTrack") return BlinkMediaStreamTrack.instance;
  if (s == "MediaStreamTrackEvent") return BlinkMediaStreamTrackEvent.instance;
  if (s == "MemoryInfo") return BlinkMemoryInfo.instance;
  if (s == "MessageChannel") return BlinkMessageChannel.instance;
  if (s == "MessageEvent") return BlinkMessageEvent.instance;
  if (s == "MessagePort") return BlinkMessagePort.instance;
  if (s == "Metadata") return BlinkMetadata.instance;
  if (s == "MimeType") return BlinkMimeType.instance;
  if (s == "MimeTypeArray") return BlinkMimeTypeArray.instance;
  if (s == "MouseEvent") return BlinkMouseEvent.instance;
  if (s == "MutationEvent") return BlinkMutationEvent.instance;
  if (s == "MutationObserver") return BlinkMutationObserver.instance;
  if (s == "MutationRecord") return BlinkMutationRecord.instance;
  if (s == "NamedNodeMap") return BlinkNamedNodeMap.instance;
  if (s == "Navigator") return BlinkNavigator.instance;
  if (s == "NavigatorUserMediaError") return BlinkNavigatorUserMediaError.instance;
  if (s == "NetworkInformation") return BlinkNetworkInformation.instance;
  if (s == "Node") return BlinkNode.instance;
  if (s == "NodeFilter") return BlinkNodeFilter.instance;
  if (s == "NodeIterator") return BlinkNodeIterator.instance;
  if (s == "NodeList") return BlinkNodeList.instance;
  if (s == "Notification") return BlinkNotification.instance;
  if (s == "OESElementIndexUint") return BlinkOESElementIndexUint.instance;
  if (s == "OESStandardDerivatives") return BlinkOESStandardDerivatives.instance;
  if (s == "OESTextureFloat") return BlinkOESTextureFloat.instance;
  if (s == "OESTextureFloatLinear") return BlinkOESTextureFloatLinear.instance;
  if (s == "OESTextureHalfFloat") return BlinkOESTextureHalfFloat.instance;
  if (s == "OESTextureHalfFloatLinear") return BlinkOESTextureHalfFloatLinear.instance;
  if (s == "OESVertexArrayObject") return BlinkOESVertexArrayObject.instance;
  if (s == "OfflineAudioCompletionEvent") return BlinkOfflineAudioCompletionEvent.instance;
  if (s == "OfflineAudioContext") return BlinkOfflineAudioContext.instance;
  if (s == "OscillatorNode") return BlinkOscillatorNode.instance;
  if (s == "OverflowEvent") return BlinkOverflowEvent.instance;
  if (s == "PagePopupController") return BlinkPagePopupController.instance;
  if (s == "PageTransitionEvent") return BlinkPageTransitionEvent.instance;
  if (s == "PannerNode") return BlinkPannerNode.instance;
  if (s == "Path2D") return BlinkPath2D.instance;
  if (s == "Performance") return BlinkPerformance.instance;
  if (s == "PerformanceEntry") return BlinkPerformanceEntry.instance;
  if (s == "PerformanceMark") return BlinkPerformanceMark.instance;
  if (s == "PerformanceMeasure") return BlinkPerformanceMeasure.instance;
  if (s == "PerformanceNavigation") return BlinkPerformanceNavigation.instance;
  if (s == "PerformanceResourceTiming") return BlinkPerformanceResourceTiming.instance;
  if (s == "PerformanceTiming") return BlinkPerformanceTiming.instance;
  if (s == "PeriodicWave") return BlinkPeriodicWave.instance;
  if (s == "Plugin") return BlinkPlugin.instance;
  if (s == "PluginArray") return BlinkPluginArray.instance;
  if (s == "PluginPlaceholderElement") return BlinkPluginPlaceholderElement.instance;
  if (s == "PopStateEvent") return BlinkPopStateEvent.instance;
  if (s == "PositionError") return BlinkPositionError.instance;
  if (s == "Presentation") return BlinkPresentation.instance;
  if (s == "ProcessingInstruction") return BlinkProcessingInstruction.instance;
  if (s == "ProgressEvent") return BlinkProgressEvent.instance;
  if (s == "PushEvent") return BlinkPushEvent.instance;
  if (s == "PushManager") return BlinkPushManager.instance;
  if (s == "PushRegistration") return BlinkPushRegistration.instance;
  if (s == "RGBColor") return BlinkRGBColor.instance;
  if (s == "RTCDTMFSender") return BlinkRTCDTMFSender.instance;
  if (s == "RTCDTMFToneChangeEvent") return BlinkRTCDTMFToneChangeEvent.instance;
  if (s == "RTCDataChannel") return BlinkRTCDataChannel.instance;
  if (s == "RTCDataChannelEvent") return BlinkRTCDataChannelEvent.instance;
  if (s == "RTCIceCandidate") return BlinkRTCIceCandidate.instance;
  if (s == "RTCIceCandidateEvent") return BlinkRTCIceCandidateEvent.instance;
  if (s == "RTCPeerConnection") return BlinkRTCPeerConnection.instance;
  if (s == "RTCSessionDescription") return BlinkRTCSessionDescription.instance;
  if (s == "RTCStatsReport") return BlinkRTCStatsReport.instance;
  if (s == "RTCStatsResponse") return BlinkRTCStatsResponse.instance;
  if (s == "RadioNodeList") return BlinkRadioNodeList.instance;
  if (s == "Range") return BlinkRange.instance;
  if (s == "ReadableStream") return BlinkReadableStream.instance;
  if (s == "Rect") return BlinkRect.instance;
  if (s == "RelatedEvent") return BlinkRelatedEvent.instance;
  if (s == "Request") return BlinkRequest.instance;
  if (s == "ResourceProgressEvent") return BlinkResourceProgressEvent.instance;
  if (s == "Response") return BlinkResponse.instance;
  if (s == "SQLError") return BlinkSQLError.instance;
  if (s == "SQLResultSet") return BlinkSQLResultSet.instance;
  if (s == "SQLResultSetRowList") return BlinkSQLResultSetRowList.instance;
  if (s == "SQLTransaction") return BlinkSQLTransaction.instance;
  if (s == "SVGAElement") return BlinkSVGAElement.instance;
  if (s == "SVGAltGlyphDefElement") return BlinkSVGAltGlyphDefElement.instance;
  if (s == "SVGAltGlyphElement") return BlinkSVGAltGlyphElement.instance;
  if (s == "SVGAltGlyphItemElement") return BlinkSVGAltGlyphItemElement.instance;
  if (s == "SVGAngle") return BlinkSVGAngle.instance;
  if (s == "SVGAnimateElement") return BlinkSVGAnimateElement.instance;
  if (s == "SVGAnimateMotionElement") return BlinkSVGAnimateMotionElement.instance;
  if (s == "SVGAnimateTransformElement") return BlinkSVGAnimateTransformElement.instance;
  if (s == "SVGAnimatedAngle") return BlinkSVGAnimatedAngle.instance;
  if (s == "SVGAnimatedBoolean") return BlinkSVGAnimatedBoolean.instance;
  if (s == "SVGAnimatedEnumeration") return BlinkSVGAnimatedEnumeration.instance;
  if (s == "SVGAnimatedInteger") return BlinkSVGAnimatedInteger.instance;
  if (s == "SVGAnimatedLength") return BlinkSVGAnimatedLength.instance;
  if (s == "SVGAnimatedLengthList") return BlinkSVGAnimatedLengthList.instance;
  if (s == "SVGAnimatedNumber") return BlinkSVGAnimatedNumber.instance;
  if (s == "SVGAnimatedNumberList") return BlinkSVGAnimatedNumberList.instance;
  if (s == "SVGAnimatedPreserveAspectRatio") return BlinkSVGAnimatedPreserveAspectRatio.instance;
  if (s == "SVGAnimatedRect") return BlinkSVGAnimatedRect.instance;
  if (s == "SVGAnimatedString") return BlinkSVGAnimatedString.instance;
  if (s == "SVGAnimatedTransformList") return BlinkSVGAnimatedTransformList.instance;
  if (s == "SVGAnimationElement") return BlinkSVGAnimationElement.instance;
  if (s == "SVGCircleElement") return BlinkSVGCircleElement.instance;
  if (s == "SVGClipPathElement") return BlinkSVGClipPathElement.instance;
  if (s == "SVGComponentTransferFunctionElement") return BlinkSVGComponentTransferFunctionElement.instance;
  if (s == "SVGCursorElement") return BlinkSVGCursorElement.instance;
  if (s == "SVGDefsElement") return BlinkSVGDefsElement.instance;
  if (s == "SVGDescElement") return BlinkSVGDescElement.instance;
  if (s == "SVGDiscardElement") return BlinkSVGDiscardElement.instance;
  if (s == "SVGElement") return BlinkSVGElement.instance;
  if (s == "SVGEllipseElement") return BlinkSVGEllipseElement.instance;
  if (s == "SVGFEBlendElement") return BlinkSVGFEBlendElement.instance;
  if (s == "SVGFEColorMatrixElement") return BlinkSVGFEColorMatrixElement.instance;
  if (s == "SVGFEComponentTransferElement") return BlinkSVGFEComponentTransferElement.instance;
  if (s == "SVGFECompositeElement") return BlinkSVGFECompositeElement.instance;
  if (s == "SVGFEConvolveMatrixElement") return BlinkSVGFEConvolveMatrixElement.instance;
  if (s == "SVGFEDiffuseLightingElement") return BlinkSVGFEDiffuseLightingElement.instance;
  if (s == "SVGFEDisplacementMapElement") return BlinkSVGFEDisplacementMapElement.instance;
  if (s == "SVGFEDistantLightElement") return BlinkSVGFEDistantLightElement.instance;
  if (s == "SVGFEDropShadowElement") return BlinkSVGFEDropShadowElement.instance;
  if (s == "SVGFEFloodElement") return BlinkSVGFEFloodElement.instance;
  if (s == "SVGFEFuncAElement") return BlinkSVGFEFuncAElement.instance;
  if (s == "SVGFEFuncBElement") return BlinkSVGFEFuncBElement.instance;
  if (s == "SVGFEFuncGElement") return BlinkSVGFEFuncGElement.instance;
  if (s == "SVGFEFuncRElement") return BlinkSVGFEFuncRElement.instance;
  if (s == "SVGFEGaussianBlurElement") return BlinkSVGFEGaussianBlurElement.instance;
  if (s == "SVGFEImageElement") return BlinkSVGFEImageElement.instance;
  if (s == "SVGFEMergeElement") return BlinkSVGFEMergeElement.instance;
  if (s == "SVGFEMergeNodeElement") return BlinkSVGFEMergeNodeElement.instance;
  if (s == "SVGFEMorphologyElement") return BlinkSVGFEMorphologyElement.instance;
  if (s == "SVGFEOffsetElement") return BlinkSVGFEOffsetElement.instance;
  if (s == "SVGFEPointLightElement") return BlinkSVGFEPointLightElement.instance;
  if (s == "SVGFESpecularLightingElement") return BlinkSVGFESpecularLightingElement.instance;
  if (s == "SVGFESpotLightElement") return BlinkSVGFESpotLightElement.instance;
  if (s == "SVGFETileElement") return BlinkSVGFETileElement.instance;
  if (s == "SVGFETurbulenceElement") return BlinkSVGFETurbulenceElement.instance;
  if (s == "SVGFilterElement") return BlinkSVGFilterElement.instance;
  if (s == "SVGFontElement") return BlinkSVGFontElement.instance;
  if (s == "SVGFontFaceElement") return BlinkSVGFontFaceElement.instance;
  if (s == "SVGFontFaceFormatElement") return BlinkSVGFontFaceFormatElement.instance;
  if (s == "SVGFontFaceNameElement") return BlinkSVGFontFaceNameElement.instance;
  if (s == "SVGFontFaceSrcElement") return BlinkSVGFontFaceSrcElement.instance;
  if (s == "SVGFontFaceUriElement") return BlinkSVGFontFaceUriElement.instance;
  if (s == "SVGForeignObjectElement") return BlinkSVGForeignObjectElement.instance;
  if (s == "SVGGElement") return BlinkSVGGElement.instance;
  if (s == "SVGGeometryElement") return BlinkSVGGeometryElement.instance;
  if (s == "SVGGlyphElement") return BlinkSVGGlyphElement.instance;
  if (s == "SVGGlyphRefElement") return BlinkSVGGlyphRefElement.instance;
  if (s == "SVGGradientElement") return BlinkSVGGradientElement.instance;
  if (s == "SVGGraphicsElement") return BlinkSVGGraphicsElement.instance;
  if (s == "SVGHKernElement") return BlinkSVGHKernElement.instance;
  if (s == "SVGImageElement") return BlinkSVGImageElement.instance;
  if (s == "SVGLength") return BlinkSVGLength.instance;
  if (s == "SVGLengthList") return BlinkSVGLengthList.instance;
  if (s == "SVGLineElement") return BlinkSVGLineElement.instance;
  if (s == "SVGLinearGradientElement") return BlinkSVGLinearGradientElement.instance;
  if (s == "SVGMPathElement") return BlinkSVGMPathElement.instance;
  if (s == "SVGMarkerElement") return BlinkSVGMarkerElement.instance;
  if (s == "SVGMaskElement") return BlinkSVGMaskElement.instance;
  if (s == "SVGMatrix") return BlinkSVGMatrix.instance;
  if (s == "SVGMetadataElement") return BlinkSVGMetadataElement.instance;
  if (s == "SVGMissingGlyphElement") return BlinkSVGMissingGlyphElement.instance;
  if (s == "SVGNumber") return BlinkSVGNumber.instance;
  if (s == "SVGNumberList") return BlinkSVGNumberList.instance;
  if (s == "SVGPathElement") return BlinkSVGPathElement.instance;
  if (s == "SVGPathSeg") return BlinkSVGPathSeg.instance;
  if (s == "SVGPathSegArcAbs") return BlinkSVGPathSegArcAbs.instance;
  if (s == "SVGPathSegArcRel") return BlinkSVGPathSegArcRel.instance;
  if (s == "SVGPathSegClosePath") return BlinkSVGPathSegClosePath.instance;
  if (s == "SVGPathSegCurvetoCubicAbs") return BlinkSVGPathSegCurvetoCubicAbs.instance;
  if (s == "SVGPathSegCurvetoCubicRel") return BlinkSVGPathSegCurvetoCubicRel.instance;
  if (s == "SVGPathSegCurvetoCubicSmoothAbs") return BlinkSVGPathSegCurvetoCubicSmoothAbs.instance;
  if (s == "SVGPathSegCurvetoCubicSmoothRel") return BlinkSVGPathSegCurvetoCubicSmoothRel.instance;
  if (s == "SVGPathSegCurvetoQuadraticAbs") return BlinkSVGPathSegCurvetoQuadraticAbs.instance;
  if (s == "SVGPathSegCurvetoQuadraticRel") return BlinkSVGPathSegCurvetoQuadraticRel.instance;
  if (s == "SVGPathSegCurvetoQuadraticSmoothAbs") return BlinkSVGPathSegCurvetoQuadraticSmoothAbs.instance;
  if (s == "SVGPathSegCurvetoQuadraticSmoothRel") return BlinkSVGPathSegCurvetoQuadraticSmoothRel.instance;
  if (s == "SVGPathSegLinetoAbs") return BlinkSVGPathSegLinetoAbs.instance;
  if (s == "SVGPathSegLinetoHorizontalAbs") return BlinkSVGPathSegLinetoHorizontalAbs.instance;
  if (s == "SVGPathSegLinetoHorizontalRel") return BlinkSVGPathSegLinetoHorizontalRel.instance;
  if (s == "SVGPathSegLinetoRel") return BlinkSVGPathSegLinetoRel.instance;
  if (s == "SVGPathSegLinetoVerticalAbs") return BlinkSVGPathSegLinetoVerticalAbs.instance;
  if (s == "SVGPathSegLinetoVerticalRel") return BlinkSVGPathSegLinetoVerticalRel.instance;
  if (s == "SVGPathSegList") return BlinkSVGPathSegList.instance;
  if (s == "SVGPathSegMovetoAbs") return BlinkSVGPathSegMovetoAbs.instance;
  if (s == "SVGPathSegMovetoRel") return BlinkSVGPathSegMovetoRel.instance;
  if (s == "SVGPatternElement") return BlinkSVGPatternElement.instance;
  if (s == "SVGPoint") return BlinkSVGPoint.instance;
  if (s == "SVGPointList") return BlinkSVGPointList.instance;
  if (s == "SVGPolygonElement") return BlinkSVGPolygonElement.instance;
  if (s == "SVGPolylineElement") return BlinkSVGPolylineElement.instance;
  if (s == "SVGPreserveAspectRatio") return BlinkSVGPreserveAspectRatio.instance;
  if (s == "SVGRadialGradientElement") return BlinkSVGRadialGradientElement.instance;
  if (s == "SVGRect") return BlinkSVGRect.instance;
  if (s == "SVGRectElement") return BlinkSVGRectElement.instance;
  if (s == "SVGRenderingIntent") return BlinkSVGRenderingIntent.instance;
  if (s == "SVGSVGElement") return BlinkSVGSVGElement.instance;
  if (s == "SVGScriptElement") return BlinkSVGScriptElement.instance;
  if (s == "SVGSetElement") return BlinkSVGSetElement.instance;
  if (s == "SVGStopElement") return BlinkSVGStopElement.instance;
  if (s == "SVGStringList") return BlinkSVGStringList.instance;
  if (s == "SVGStyleElement") return BlinkSVGStyleElement.instance;
  if (s == "SVGSwitchElement") return BlinkSVGSwitchElement.instance;
  if (s == "SVGSymbolElement") return BlinkSVGSymbolElement.instance;
  if (s == "SVGTSpanElement") return BlinkSVGTSpanElement.instance;
  if (s == "SVGTextContentElement") return BlinkSVGTextContentElement.instance;
  if (s == "SVGTextElement") return BlinkSVGTextElement.instance;
  if (s == "SVGTextPathElement") return BlinkSVGTextPathElement.instance;
  if (s == "SVGTextPositioningElement") return BlinkSVGTextPositioningElement.instance;
  if (s == "SVGTitleElement") return BlinkSVGTitleElement.instance;
  if (s == "SVGTransform") return BlinkSVGTransform.instance;
  if (s == "SVGTransformList") return BlinkSVGTransformList.instance;
  if (s == "SVGUnitTypes") return BlinkSVGUnitTypes.instance;
  if (s == "SVGUseElement") return BlinkSVGUseElement.instance;
  if (s == "SVGVKernElement") return BlinkSVGVKernElement.instance;
  if (s == "SVGViewElement") return BlinkSVGViewElement.instance;
  if (s == "SVGViewSpec") return BlinkSVGViewSpec.instance;
  if (s == "SVGZoomEvent") return BlinkSVGZoomEvent.instance;
  if (s == "Screen") return BlinkScreen.instance;
  if (s == "ScreenOrientation") return BlinkScreenOrientation.instance;
  if (s == "ScriptProcessorNode") return BlinkScriptProcessorNode.instance;
  if (s == "SecurityPolicyViolationEvent") return BlinkSecurityPolicyViolationEvent.instance;
  if (s == "Selection") return BlinkSelection.instance;
  if (s == "ServiceWorker") return BlinkServiceWorker.instance;
  if (s == "ServiceWorkerClient") return BlinkServiceWorkerClient.instance;
  if (s == "ServiceWorkerClients") return BlinkServiceWorkerClients.instance;
  if (s == "ServiceWorkerContainer") return BlinkServiceWorkerContainer.instance;
  if (s == "ServiceWorkerGlobalScope") return BlinkServiceWorkerGlobalScope.instance;
  if (s == "ServiceWorkerRegistration") return BlinkServiceWorkerRegistration.instance;
  if (s == "ShadowRoot") return BlinkShadowRoot.instance;
  if (s == "SharedWorker") return BlinkSharedWorker.instance;
  if (s == "SharedWorkerGlobalScope") return BlinkSharedWorkerGlobalScope.instance;
  if (s == "SourceBuffer") return BlinkSourceBuffer.instance;
  if (s == "SourceBufferList") return BlinkSourceBufferList.instance;
  if (s == "SourceInfo") return BlinkSourceInfo.instance;
  if (s == "SpeechGrammar") return BlinkSpeechGrammar.instance;
  if (s == "SpeechGrammarList") return BlinkSpeechGrammarList.instance;
  if (s == "SpeechRecognition") return BlinkSpeechRecognition.instance;
  if (s == "SpeechRecognitionAlternative") return BlinkSpeechRecognitionAlternative.instance;
  if (s == "SpeechRecognitionError") return BlinkSpeechRecognitionError.instance;
  if (s == "SpeechRecognitionEvent") return BlinkSpeechRecognitionEvent.instance;
  if (s == "SpeechRecognitionResult") return BlinkSpeechRecognitionResult.instance;
  if (s == "SpeechRecognitionResultList") return BlinkSpeechRecognitionResultList.instance;
  if (s == "SpeechSynthesis") return BlinkSpeechSynthesis.instance;
  if (s == "SpeechSynthesisEvent") return BlinkSpeechSynthesisEvent.instance;
  if (s == "SpeechSynthesisUtterance") return BlinkSpeechSynthesisUtterance.instance;
  if (s == "SpeechSynthesisVoice") return BlinkSpeechSynthesisVoice.instance;
  if (s == "Storage") return BlinkStorage.instance;
  if (s == "StorageEvent") return BlinkStorageEvent.instance;
  if (s == "StorageInfo") return BlinkStorageInfo.instance;
  if (s == "StorageQuota") return BlinkStorageQuota.instance;
  if (s == "Stream") return BlinkStream.instance;
  if (s == "StyleMedia") return BlinkStyleMedia.instance;
  if (s == "StyleSheet") return BlinkStyleSheet.instance;
  if (s == "StyleSheetList") return BlinkStyleSheetList.instance;
  if (s == "SubtleCrypto") return BlinkSubtleCrypto.instance;
  if (s == "Text") return BlinkText.instance;
  if (s == "TextDecoder") return BlinkTextDecoder.instance;
  if (s == "TextEncoder") return BlinkTextEncoder.instance;
  if (s == "TextEvent") return BlinkTextEvent.instance;
  if (s == "TextMetrics") return BlinkTextMetrics.instance;
  if (s == "TextTrack") return BlinkTextTrack.instance;
  if (s == "TextTrackCue") return BlinkTextTrackCue.instance;
  if (s == "TextTrackCueList") return BlinkTextTrackCueList.instance;
  if (s == "TextTrackList") return BlinkTextTrackList.instance;
  if (s == "TimeRanges") return BlinkTimeRanges.instance;
  if (s == "Timing") return BlinkTiming.instance;
  if (s == "Touch") return BlinkTouch.instance;
  if (s == "TouchEvent") return BlinkTouchEvent.instance;
  if (s == "TouchList") return BlinkTouchList.instance;
  if (s == "TrackEvent") return BlinkTrackEvent.instance;
  if (s == "TransitionEvent") return BlinkTransitionEvent.instance;
  if (s == "TreeWalker") return BlinkTreeWalker.instance;
  if (s == "UIEvent") return BlinkUIEvent.instance;
  if (s == "URL") return BlinkURL.instance;
  if (s == "VTTCue") return BlinkVTTCue.instance;
  if (s == "VTTRegion") return BlinkVTTRegion.instance;
  if (s == "VTTRegionList") return BlinkVTTRegionList.instance;
  if (s == "ValidityState") return BlinkValidityState.instance;
  if (s == "VideoPlaybackQuality") return BlinkVideoPlaybackQuality.instance;
  if (s == "VideoTrack") return BlinkVideoTrack.instance;
  if (s == "VideoTrackList") return BlinkVideoTrackList.instance;
  if (s == "WaveShaperNode") return BlinkWaveShaperNode.instance;
  if (s == "WebGLActiveInfo") return BlinkWebGLActiveInfo.instance;
  if (s == "WebGLBuffer") return BlinkWebGLBuffer.instance;
  if (s == "WebGLCompressedTextureATC") return BlinkWebGLCompressedTextureATC.instance;
  if (s == "WebGLCompressedTextureETC1") return BlinkWebGLCompressedTextureETC1.instance;
  if (s == "WebGLCompressedTexturePVRTC") return BlinkWebGLCompressedTexturePVRTC.instance;
  if (s == "WebGLCompressedTextureS3TC") return BlinkWebGLCompressedTextureS3TC.instance;
  if (s == "WebGLContextAttributes") return BlinkWebGLContextAttributes.instance;
  if (s == "WebGLContextEvent") return BlinkWebGLContextEvent.instance;
  if (s == "WebGLDebugRendererInfo") return BlinkWebGLDebugRendererInfo.instance;
  if (s == "WebGLDebugShaders") return BlinkWebGLDebugShaders.instance;
  if (s == "WebGLDepthTexture") return BlinkWebGLDepthTexture.instance;
  if (s == "WebGLDrawBuffers") return BlinkWebGLDrawBuffers.instance;
  if (s == "WebGLFramebuffer") return BlinkWebGLFramebuffer.instance;
  if (s == "WebGLLoseContext") return BlinkWebGLLoseContext.instance;
  if (s == "WebGLProgram") return BlinkWebGLProgram.instance;
  if (s == "WebGLRenderbuffer") return BlinkWebGLRenderbuffer.instance;
  if (s == "WebGLRenderingContext") return BlinkWebGLRenderingContext.instance;
  if (s == "WebGLShader") return BlinkWebGLShader.instance;
  if (s == "WebGLShaderPrecisionFormat") return BlinkWebGLShaderPrecisionFormat.instance;
  if (s == "WebGLTexture") return BlinkWebGLTexture.instance;
  if (s == "WebGLUniformLocation") return BlinkWebGLUniformLocation.instance;
  if (s == "WebGLVertexArrayObjectOES") return BlinkWebGLVertexArrayObjectOES.instance;
  if (s == "WebKitAnimationEvent") return BlinkWebKitAnimationEvent.instance;
  if (s == "WebKitCSSFilterRule") return BlinkWebKitCSSFilterRule.instance;
  if (s == "WebKitCSSFilterValue") return BlinkWebKitCSSFilterValue.instance;
  if (s == "WebKitCSSMatrix") return BlinkWebKitCSSMatrix.instance;
  if (s == "WebKitCSSTransformValue") return BlinkWebKitCSSTransformValue.instance;
  if (s == "WebKitGamepad") return BlinkWebKitGamepad.instance;
  if (s == "WebKitGamepadList") return BlinkWebKitGamepadList.instance;
  if (s == "WebSocket") return BlinkWebSocket.instance;
  if (s == "WheelEvent") return BlinkWheelEvent.instance;
  if (s == "Window") return BlinkWindow.instance;
  if (s == "Worker") return BlinkWorker.instance;
  if (s == "WorkerConsole") return BlinkWorkerConsole.instance;
  if (s == "WorkerGlobalScope") return BlinkWorkerGlobalScope.instance;
  if (s == "WorkerLocation") return BlinkWorkerLocation.instance;
  if (s == "WorkerNavigator") return BlinkWorkerNavigator.instance;
  if (s == "WorkerPerformance") return BlinkWorkerPerformance.instance;
  if (s == "XMLDocument") return BlinkXMLDocument.instance;
  if (s == "XMLHttpRequest") return BlinkXMLHttpRequest.instance;
  if (s == "XMLHttpRequestEventTarget") return BlinkXMLHttpRequestEventTarget.instance;
  if (s == "XMLHttpRequestProgressEvent") return BlinkXMLHttpRequestProgressEvent.instance;
  if (s == "XMLHttpRequestUpload") return BlinkXMLHttpRequestUpload.instance;
  if (s == "XMLSerializer") return BlinkXMLSerializer.instance;
  if (s == "XPathEvaluator") return BlinkXPathEvaluator.instance;
  if (s == "XPathExpression") return BlinkXPathExpression.instance;
  if (s == "XPathNSResolver") return BlinkXPathNSResolver.instance;
  if (s == "XPathResult") return BlinkXPathResult.instance;
  if (s == "XSLTProcessor") return BlinkXSLTProcessor.instance;
  // Failed to find it, check for custom renames
  dynamic obj = resolverMap[s];
  if (obj != null) return obj;
  throw("No such interface exposed in blink: ${s}");
}

class BlinkANGLEInstancedArrays {
  static final instance = new BlinkANGLEInstancedArrays();

  drawArraysInstancedANGLE_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("drawArraysInstancedANGLE", [__arg_0, __arg_1]);

  drawArraysInstancedANGLE_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("drawArraysInstancedANGLE", [__arg_0, __arg_1, __arg_2]);

  drawArraysInstancedANGLE_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("drawArraysInstancedANGLE", [__arg_0, __arg_1, __arg_2, __arg_3]);

  drawElementsInstancedANGLE_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("drawElementsInstancedANGLE", [__arg_0, __arg_1, __arg_2]);

  drawElementsInstancedANGLE_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("drawElementsInstancedANGLE", [__arg_0, __arg_1, __arg_2, __arg_3]);

  drawElementsInstancedANGLE_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("drawElementsInstancedANGLE", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  vertexAttribDivisorANGLE_Callback_0_(mthis) => mthis.callMethod("vertexAttribDivisorANGLE", []);

  vertexAttribDivisorANGLE_Callback_1_(mthis, __arg_0) => mthis.callMethod("vertexAttribDivisorANGLE", [__arg_0]);

  vertexAttribDivisorANGLE_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("vertexAttribDivisorANGLE", [__arg_0, __arg_1]);

}

class BlinkAnalyserNode extends BlinkAudioNode {
  static final instance = new BlinkAnalyserNode();

  fftSize_Getter_(mthis) => mthis["fftSize"];

  fftSize_Setter_(mthis, __arg_0) => mthis["fftSize"] = __arg_0;

  frequencyBinCount_Getter_(mthis) => mthis["frequencyBinCount"];

  getByteFrequencyData_Callback_0_(mthis) => mthis.callMethod("getByteFrequencyData", []);

  getByteFrequencyData_Callback_1_(mthis, __arg_0) => mthis.callMethod("getByteFrequencyData", [__arg_0]);

  getByteTimeDomainData_Callback_0_(mthis) => mthis.callMethod("getByteTimeDomainData", []);

  getByteTimeDomainData_Callback_1_(mthis, __arg_0) => mthis.callMethod("getByteTimeDomainData", [__arg_0]);

  getFloatFrequencyData_Callback_0_(mthis) => mthis.callMethod("getFloatFrequencyData", []);

  getFloatFrequencyData_Callback_1_(mthis, __arg_0) => mthis.callMethod("getFloatFrequencyData", [__arg_0]);

  getFloatTimeDomainData_Callback_0_(mthis) => mthis.callMethod("getFloatTimeDomainData", []);

  getFloatTimeDomainData_Callback_1_(mthis, __arg_0) => mthis.callMethod("getFloatTimeDomainData", [__arg_0]);

  maxDecibels_Getter_(mthis) => mthis["maxDecibels"];

  maxDecibels_Setter_(mthis, __arg_0) => mthis["maxDecibels"] = __arg_0;

  minDecibels_Getter_(mthis) => mthis["minDecibels"];

  minDecibels_Setter_(mthis, __arg_0) => mthis["minDecibels"] = __arg_0;

  smoothingTimeConstant_Getter_(mthis) => mthis["smoothingTimeConstant"];

  smoothingTimeConstant_Setter_(mthis, __arg_0) => mthis["smoothingTimeConstant"] = __arg_0;

}

class BlinkAnimation extends BlinkAnimationNode {
  static final instance = new BlinkAnimation();

  constructorCallback_0_() => new js.JsObject(js.context["Animation"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["Animation"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["Animation"], [__arg_0, __arg_1]);

  constructorCallback_3_(__arg_0, __arg_1, __arg_2) => new js.JsObject(js.context["Animation"], [__arg_0, __arg_1, __arg_2]);

}

class BlinkAnimationEffect {
  static final instance = new BlinkAnimationEffect();

}

class BlinkAnimationNode {
  static final instance = new BlinkAnimationNode();

  activeDuration_Getter_(mthis) => mthis["activeDuration"];

  currentIteration_Getter_(mthis) => mthis["currentIteration"];

  duration_Getter_(mthis) => mthis["duration"];

  endTime_Getter_(mthis) => mthis["endTime"];

  localTime_Getter_(mthis) => mthis["localTime"];

  player_Getter_(mthis) => mthis["player"];

  startTime_Getter_(mthis) => mthis["startTime"];

  timing_Getter_(mthis) => mthis["timing"];

}

class BlinkAnimationPlayer extends BlinkEventTarget {
  static final instance = new BlinkAnimationPlayer();

  cancel_Callback_0_(mthis) => mthis.callMethod("cancel", []);

  currentTime_Getter_(mthis) => mthis["currentTime"];

  currentTime_Setter_(mthis, __arg_0) => mthis["currentTime"] = __arg_0;

  finish_Callback_0_(mthis) => mthis.callMethod("finish", []);

  onfinish_Getter_(mthis) => mthis["onfinish"];

  onfinish_Setter_(mthis, __arg_0) => mthis["onfinish"] = __arg_0;

  pause_Callback_0_(mthis) => mthis.callMethod("pause", []);

  playState_Getter_(mthis) => mthis["playState"];

  play_Callback_0_(mthis) => mthis.callMethod("play", []);

  playbackRate_Getter_(mthis) => mthis["playbackRate"];

  playbackRate_Setter_(mthis, __arg_0) => mthis["playbackRate"] = __arg_0;

  reverse_Callback_0_(mthis) => mthis.callMethod("reverse", []);

  source_Getter_(mthis) => mthis["source"];

  source_Setter_(mthis, __arg_0) => mthis["source"] = __arg_0;

  startTime_Getter_(mthis) => mthis["startTime"];

  startTime_Setter_(mthis, __arg_0) => mthis["startTime"] = __arg_0;

}

class BlinkAnimationPlayerEvent extends BlinkEvent {
  static final instance = new BlinkAnimationPlayerEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["AnimationPlayerEvent"], [__arg_0, __arg_1]);

  currentTime_Getter_(mthis) => mthis["currentTime"];

  timelineTime_Getter_(mthis) => mthis["timelineTime"];

}

class BlinkAnimationTimeline {
  static final instance = new BlinkAnimationTimeline();

  currentTime_Getter_(mthis) => mthis["currentTime"];

  getAnimationPlayers_Callback_0_(mthis) => mthis.callMethod("getAnimationPlayers", []);

  play_Callback_0_(mthis) => mthis.callMethod("play", []);

  play_Callback_1_(mthis, __arg_0) => mthis.callMethod("play", [__arg_0]);

}

class BlinkApplicationCache extends BlinkEventTarget {
  static final instance = new BlinkApplicationCache();

  abort_Callback_0_(mthis) => mthis.callMethod("abort", []);

  oncached_Getter_(mthis) => mthis["oncached"];

  oncached_Setter_(mthis, __arg_0) => mthis["oncached"] = __arg_0;

  onchecking_Getter_(mthis) => mthis["onchecking"];

  onchecking_Setter_(mthis, __arg_0) => mthis["onchecking"] = __arg_0;

  ondownloading_Getter_(mthis) => mthis["ondownloading"];

  ondownloading_Setter_(mthis, __arg_0) => mthis["ondownloading"] = __arg_0;

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onnoupdate_Getter_(mthis) => mthis["onnoupdate"];

  onnoupdate_Setter_(mthis, __arg_0) => mthis["onnoupdate"] = __arg_0;

  onobsolete_Getter_(mthis) => mthis["onobsolete"];

  onobsolete_Setter_(mthis, __arg_0) => mthis["onobsolete"] = __arg_0;

  onprogress_Getter_(mthis) => mthis["onprogress"];

  onprogress_Setter_(mthis, __arg_0) => mthis["onprogress"] = __arg_0;

  onupdateready_Getter_(mthis) => mthis["onupdateready"];

  onupdateready_Setter_(mthis, __arg_0) => mthis["onupdateready"] = __arg_0;

  status_Getter_(mthis) => mthis["status"];

  swapCache_Callback_0_(mthis) => mthis.callMethod("swapCache", []);

  update_Callback_0_(mthis) => mthis.callMethod("update", []);

}

class BlinkApplicationCacheErrorEvent extends BlinkEvent {
  static final instance = new BlinkApplicationCacheErrorEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["ApplicationCacheErrorEvent"], [__arg_0, __arg_1]);

  message_Getter_(mthis) => mthis["message"];

  reason_Getter_(mthis) => mthis["reason"];

  status_Getter_(mthis) => mthis["status"];

  url_Getter_(mthis) => mthis["url"];

}

class BlinkAttr extends BlinkNode {
  static final instance = new BlinkAttr();

  localName_Getter_(mthis) => mthis["localName"];

  name_Getter_(mthis) => mthis["name"];

  namespaceURI_Getter_(mthis) => mthis["namespaceURI"];

  nodeValue_Getter_(mthis) => mthis["nodeValue"];

  nodeValue_Setter_(mthis, __arg_0) => mthis["nodeValue"] = __arg_0;

  ownerElement_Getter_(mthis) => mthis["ownerElement"];

  prefix_Getter_(mthis) => mthis["prefix"];

  specified_Getter_(mthis) => mthis["specified"];

  textContent_Getter_(mthis) => mthis["textContent"];

  textContent_Setter_(mthis, __arg_0) => mthis["textContent"] = __arg_0;

  value_Getter_(mthis) => mthis["value"];

  value_Setter_(mthis, __arg_0) => mthis["value"] = __arg_0;

}

class BlinkAudioBuffer {
  static final instance = new BlinkAudioBuffer();

  duration_Getter_(mthis) => mthis["duration"];

  getChannelData_Callback_0_(mthis) => mthis.callMethod("getChannelData", []);

  getChannelData_Callback_1_(mthis, __arg_0) => mthis.callMethod("getChannelData", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

  numberOfChannels_Getter_(mthis) => mthis["numberOfChannels"];

  sampleRate_Getter_(mthis) => mthis["sampleRate"];

}

class BlinkAudioBufferSourceNode extends BlinkAudioSourceNode {
  static final instance = new BlinkAudioBufferSourceNode();

  buffer_Getter_(mthis) => mthis["buffer"];

  buffer_Setter_(mthis, __arg_0) => mthis["buffer"] = __arg_0;

  loopEnd_Getter_(mthis) => mthis["loopEnd"];

  loopEnd_Setter_(mthis, __arg_0) => mthis["loopEnd"] = __arg_0;

  loopStart_Getter_(mthis) => mthis["loopStart"];

  loopStart_Setter_(mthis, __arg_0) => mthis["loopStart"] = __arg_0;

  loop_Getter_(mthis) => mthis["loop"];

  loop_Setter_(mthis, __arg_0) => mthis["loop"] = __arg_0;

  onended_Getter_(mthis) => mthis["onended"];

  onended_Setter_(mthis, __arg_0) => mthis["onended"] = __arg_0;

  playbackRate_Getter_(mthis) => mthis["playbackRate"];

  start_Callback_0_(mthis) => mthis.callMethod("start", []);

  start_Callback_1_(mthis, __arg_0) => mthis.callMethod("start", [__arg_0]);

  start_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("start", [__arg_0, __arg_1]);

  start_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("start", [__arg_0, __arg_1, __arg_2]);

  stop_Callback_0_(mthis) => mthis.callMethod("stop", []);

  stop_Callback_1_(mthis, __arg_0) => mthis.callMethod("stop", [__arg_0]);

}

class BlinkAudioContext extends BlinkEventTarget {
  static final instance = new BlinkAudioContext();

  constructorCallback_0_() => new js.JsObject(js.context["AudioContext"], []);

  createAnalyser_Callback_0_(mthis) => mthis.callMethod("createAnalyser", []);

  createBiquadFilter_Callback_0_(mthis) => mthis.callMethod("createBiquadFilter", []);

  createBufferSource_Callback_0_(mthis) => mthis.callMethod("createBufferSource", []);

  createBuffer_Callback_1_(mthis, __arg_0) => mthis.callMethod("createBuffer", [__arg_0]);

  createBuffer_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createBuffer", [__arg_0, __arg_1]);

  createBuffer_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("createBuffer", [__arg_0, __arg_1, __arg_2]);

  createChannelMerger_Callback_0_(mthis) => mthis.callMethod("createChannelMerger", []);

  createChannelMerger_Callback_1_(mthis, __arg_0) => mthis.callMethod("createChannelMerger", [__arg_0]);

  createChannelSplitter_Callback_0_(mthis) => mthis.callMethod("createChannelSplitter", []);

  createChannelSplitter_Callback_1_(mthis, __arg_0) => mthis.callMethod("createChannelSplitter", [__arg_0]);

  createConvolver_Callback_0_(mthis) => mthis.callMethod("createConvolver", []);

  createDelay_Callback_0_(mthis) => mthis.callMethod("createDelay", []);

  createDelay_Callback_1_(mthis, __arg_0) => mthis.callMethod("createDelay", [__arg_0]);

  createDynamicsCompressor_Callback_0_(mthis) => mthis.callMethod("createDynamicsCompressor", []);

  createGain_Callback_0_(mthis) => mthis.callMethod("createGain", []);

  createMediaElementSource_Callback_0_(mthis) => mthis.callMethod("createMediaElementSource", []);

  createMediaElementSource_Callback_1_(mthis, __arg_0) => mthis.callMethod("createMediaElementSource", [__arg_0]);

  createMediaStreamDestination_Callback_0_(mthis) => mthis.callMethod("createMediaStreamDestination", []);

  createMediaStreamSource_Callback_0_(mthis) => mthis.callMethod("createMediaStreamSource", []);

  createMediaStreamSource_Callback_1_(mthis, __arg_0) => mthis.callMethod("createMediaStreamSource", [__arg_0]);

  createOscillator_Callback_0_(mthis) => mthis.callMethod("createOscillator", []);

  createPanner_Callback_0_(mthis) => mthis.callMethod("createPanner", []);

  createPeriodicWave_Callback_0_(mthis) => mthis.callMethod("createPeriodicWave", []);

  createPeriodicWave_Callback_1_(mthis, __arg_0) => mthis.callMethod("createPeriodicWave", [__arg_0]);

  createPeriodicWave_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createPeriodicWave", [__arg_0, __arg_1]);

  createScriptProcessor_Callback_0_(mthis) => mthis.callMethod("createScriptProcessor", []);

  createScriptProcessor_Callback_1_(mthis, __arg_0) => mthis.callMethod("createScriptProcessor", [__arg_0]);

  createScriptProcessor_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createScriptProcessor", [__arg_0, __arg_1]);

  createScriptProcessor_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("createScriptProcessor", [__arg_0, __arg_1, __arg_2]);

  createWaveShaper_Callback_0_(mthis) => mthis.callMethod("createWaveShaper", []);

  currentTime_Getter_(mthis) => mthis["currentTime"];

  decodeAudioData_Callback_0_(mthis) => mthis.callMethod("decodeAudioData", []);

  decodeAudioData_Callback_1_(mthis, __arg_0) => mthis.callMethod("decodeAudioData", [__arg_0]);

  decodeAudioData_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("decodeAudioData", [__arg_0, __arg_1]);

  decodeAudioData_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("decodeAudioData", [__arg_0, __arg_1, __arg_2]);

  destination_Getter_(mthis) => mthis["destination"];

  listener_Getter_(mthis) => mthis["listener"];

  oncomplete_Getter_(mthis) => mthis["oncomplete"];

  oncomplete_Setter_(mthis, __arg_0) => mthis["oncomplete"] = __arg_0;

  sampleRate_Getter_(mthis) => mthis["sampleRate"];

  startRendering_Callback_0_(mthis) => mthis.callMethod("startRendering", []);

}

class BlinkAudioDestinationNode extends BlinkAudioNode {
  static final instance = new BlinkAudioDestinationNode();

  maxChannelCount_Getter_(mthis) => mthis["maxChannelCount"];

}

class BlinkAudioListener {
  static final instance = new BlinkAudioListener();

  dopplerFactor_Getter_(mthis) => mthis["dopplerFactor"];

  dopplerFactor_Setter_(mthis, __arg_0) => mthis["dopplerFactor"] = __arg_0;

  setOrientation_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("setOrientation", [__arg_0, __arg_1, __arg_2, __arg_3]);

  setOrientation_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("setOrientation", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  setOrientation_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("setOrientation", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  setPosition_Callback_1_(mthis, __arg_0) => mthis.callMethod("setPosition", [__arg_0]);

  setPosition_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setPosition", [__arg_0, __arg_1]);

  setPosition_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setPosition", [__arg_0, __arg_1, __arg_2]);

  setVelocity_Callback_1_(mthis, __arg_0) => mthis.callMethod("setVelocity", [__arg_0]);

  setVelocity_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setVelocity", [__arg_0, __arg_1]);

  setVelocity_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setVelocity", [__arg_0, __arg_1, __arg_2]);

  speedOfSound_Getter_(mthis) => mthis["speedOfSound"];

  speedOfSound_Setter_(mthis, __arg_0) => mthis["speedOfSound"] = __arg_0;

}

class BlinkAudioNode extends BlinkEventTarget {
  static final instance = new BlinkAudioNode();

  channelCountMode_Getter_(mthis) => mthis["channelCountMode"];

  channelCountMode_Setter_(mthis, __arg_0) => mthis["channelCountMode"] = __arg_0;

  channelCount_Getter_(mthis) => mthis["channelCount"];

  channelCount_Setter_(mthis, __arg_0) => mthis["channelCount"] = __arg_0;

  channelInterpretation_Getter_(mthis) => mthis["channelInterpretation"];

  channelInterpretation_Setter_(mthis, __arg_0) => mthis["channelInterpretation"] = __arg_0;

  connect_Callback_0_(mthis) => mthis.callMethod("connect", []);

  connect_Callback_1_(mthis, __arg_0) => mthis.callMethod("connect", [__arg_0]);

  connect_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("connect", [__arg_0, __arg_1]);

  connect_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("connect", [__arg_0, __arg_1, __arg_2]);

  context_Getter_(mthis) => mthis["context"];

  disconnect_Callback_0_(mthis) => mthis.callMethod("disconnect", []);

  disconnect_Callback_1_(mthis, __arg_0) => mthis.callMethod("disconnect", [__arg_0]);

  numberOfInputs_Getter_(mthis) => mthis["numberOfInputs"];

  numberOfOutputs_Getter_(mthis) => mthis["numberOfOutputs"];

}

class BlinkAudioParam {
  static final instance = new BlinkAudioParam();

  cancelScheduledValues_Callback_0_(mthis) => mthis.callMethod("cancelScheduledValues", []);

  cancelScheduledValues_Callback_1_(mthis, __arg_0) => mthis.callMethod("cancelScheduledValues", [__arg_0]);

  defaultValue_Getter_(mthis) => mthis["defaultValue"];

  exponentialRampToValueAtTime_Callback_0_(mthis) => mthis.callMethod("exponentialRampToValueAtTime", []);

  exponentialRampToValueAtTime_Callback_1_(mthis, __arg_0) => mthis.callMethod("exponentialRampToValueAtTime", [__arg_0]);

  exponentialRampToValueAtTime_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("exponentialRampToValueAtTime", [__arg_0, __arg_1]);

  linearRampToValueAtTime_Callback_0_(mthis) => mthis.callMethod("linearRampToValueAtTime", []);

  linearRampToValueAtTime_Callback_1_(mthis, __arg_0) => mthis.callMethod("linearRampToValueAtTime", [__arg_0]);

  linearRampToValueAtTime_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("linearRampToValueAtTime", [__arg_0, __arg_1]);

  setTargetAtTime_Callback_1_(mthis, __arg_0) => mthis.callMethod("setTargetAtTime", [__arg_0]);

  setTargetAtTime_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setTargetAtTime", [__arg_0, __arg_1]);

  setTargetAtTime_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setTargetAtTime", [__arg_0, __arg_1, __arg_2]);

  setValueAtTime_Callback_0_(mthis) => mthis.callMethod("setValueAtTime", []);

  setValueAtTime_Callback_1_(mthis, __arg_0) => mthis.callMethod("setValueAtTime", [__arg_0]);

  setValueAtTime_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setValueAtTime", [__arg_0, __arg_1]);

  setValueCurveAtTime_Callback_1_(mthis, __arg_0) => mthis.callMethod("setValueCurveAtTime", [__arg_0]);

  setValueCurveAtTime_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setValueCurveAtTime", [__arg_0, __arg_1]);

  setValueCurveAtTime_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setValueCurveAtTime", [__arg_0, __arg_1, __arg_2]);

  value_Getter_(mthis) => mthis["value"];

  value_Setter_(mthis, __arg_0) => mthis["value"] = __arg_0;

}

class BlinkAudioProcessingEvent extends BlinkEvent {
  static final instance = new BlinkAudioProcessingEvent();

  inputBuffer_Getter_(mthis) => mthis["inputBuffer"];

  outputBuffer_Getter_(mthis) => mthis["outputBuffer"];

  playbackTime_Getter_(mthis) => mthis["playbackTime"];

}

class BlinkAudioSourceNode extends BlinkAudioNode {
  static final instance = new BlinkAudioSourceNode();

}

class BlinkAudioTrack {
  static final instance = new BlinkAudioTrack();

  enabled_Getter_(mthis) => mthis["enabled"];

  enabled_Setter_(mthis, __arg_0) => mthis["enabled"] = __arg_0;

  id_Getter_(mthis) => mthis["id"];

  kind_Getter_(mthis) => mthis["kind"];

  label_Getter_(mthis) => mthis["label"];

  language_Getter_(mthis) => mthis["language"];

}

class BlinkAudioTrackList extends BlinkEventTarget {
  static final instance = new BlinkAudioTrackList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  getTrackById_Callback_0_(mthis) => mthis.callMethod("getTrackById", []);

  getTrackById_Callback_1_(mthis, __arg_0) => mthis.callMethod("getTrackById", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

  onaddtrack_Getter_(mthis) => mthis["onaddtrack"];

  onaddtrack_Setter_(mthis, __arg_0) => mthis["onaddtrack"] = __arg_0;

  onchange_Getter_(mthis) => mthis["onchange"];

  onchange_Setter_(mthis, __arg_0) => mthis["onchange"] = __arg_0;

  onremovetrack_Getter_(mthis) => mthis["onremovetrack"];

  onremovetrack_Setter_(mthis, __arg_0) => mthis["onremovetrack"] = __arg_0;

}

class BlinkAutocompleteErrorEvent extends BlinkEvent {
  static final instance = new BlinkAutocompleteErrorEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["AutocompleteErrorEvent"], [__arg_0, __arg_1]);

  reason_Getter_(mthis) => mthis["reason"];

}

class BlinkBarProp {
  static final instance = new BlinkBarProp();

  visible_Getter_(mthis) => mthis["visible"];

}

class BlinkBatteryManager extends BlinkEventTarget {
  static final instance = new BlinkBatteryManager();

  chargingTime_Getter_(mthis) => mthis["chargingTime"];

  charging_Getter_(mthis) => mthis["charging"];

  dischargingTime_Getter_(mthis) => mthis["dischargingTime"];

  level_Getter_(mthis) => mthis["level"];

  onchargingchange_Getter_(mthis) => mthis["onchargingchange"];

  onchargingchange_Setter_(mthis, __arg_0) => mthis["onchargingchange"] = __arg_0;

  onchargingtimechange_Getter_(mthis) => mthis["onchargingtimechange"];

  onchargingtimechange_Setter_(mthis, __arg_0) => mthis["onchargingtimechange"] = __arg_0;

  ondischargingtimechange_Getter_(mthis) => mthis["ondischargingtimechange"];

  ondischargingtimechange_Setter_(mthis, __arg_0) => mthis["ondischargingtimechange"] = __arg_0;

  onlevelchange_Getter_(mthis) => mthis["onlevelchange"];

  onlevelchange_Setter_(mthis, __arg_0) => mthis["onlevelchange"] = __arg_0;

}

class BlinkBeforeUnloadEvent extends BlinkEvent {
  static final instance = new BlinkBeforeUnloadEvent();

  returnValue_Getter_(mthis) => mthis["returnValue"];

  returnValue_Setter_(mthis, __arg_0) => mthis["returnValue"] = __arg_0;

}

class BlinkBiquadFilterNode extends BlinkAudioNode {
  static final instance = new BlinkBiquadFilterNode();

  Q_Getter_(mthis) => mthis["Q"];

  detune_Getter_(mthis) => mthis["detune"];

  frequency_Getter_(mthis) => mthis["frequency"];

  gain_Getter_(mthis) => mthis["gain"];

  getFrequencyResponse_Callback_1_(mthis, __arg_0) => mthis.callMethod("getFrequencyResponse", [__arg_0]);

  getFrequencyResponse_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getFrequencyResponse", [__arg_0, __arg_1]);

  getFrequencyResponse_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("getFrequencyResponse", [__arg_0, __arg_1, __arg_2]);

  type_Getter_(mthis) => mthis["type"];

  type_Setter_(mthis, __arg_0) => mthis["type"] = __arg_0;

}

class BlinkBlob {
  static final instance = new BlinkBlob();

  close_Callback_0_(mthis) => mthis.callMethod("close", []);

  constructorCallback_0_() => new js.JsObject(js.context["Blob"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["Blob"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["Blob"], [__arg_0, __arg_1]);

  size_Getter_(mthis) => mthis["size"];

  slice_Callback_0_(mthis) => mthis.callMethod("slice", []);

  slice_Callback_1_(mthis, __arg_0) => mthis.callMethod("slice", [__arg_0]);

  slice_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("slice", [__arg_0, __arg_1]);

  slice_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("slice", [__arg_0, __arg_1, __arg_2]);

  type_Getter_(mthis) => mthis["type"];

}

class BlinkBody {
  static final instance = new BlinkBody();

  arrayBuffer_Callback_0_(mthis) => mthis.callMethod("arrayBuffer", []);

  blob_Callback_0_(mthis) => mthis.callMethod("blob", []);

  bodyUsed_Getter_(mthis) => mthis["bodyUsed"];

  json_Callback_0_(mthis) => mthis.callMethod("json", []);

  text_Callback_0_(mthis) => mthis.callMethod("text", []);

}

class BlinkCDATASection extends BlinkText {
  static final instance = new BlinkCDATASection();

}

class BlinkCSS {
  static final instance = new BlinkCSS();

  supports_Callback_0_(mthis) => mthis.callMethod("supports", []);

  supports_Callback_1_(mthis, __arg_0) => mthis.callMethod("supports", [__arg_0]);

  supports_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("supports", [__arg_0, __arg_1]);

}

class BlinkCSSCharsetRule extends BlinkCSSRule {
  static final instance = new BlinkCSSCharsetRule();

  encoding_Getter_(mthis) => mthis["encoding"];

  encoding_Setter_(mthis, __arg_0) => mthis["encoding"] = __arg_0;

}

class BlinkCSSFontFaceRule extends BlinkCSSRule {
  static final instance = new BlinkCSSFontFaceRule();

  style_Getter_(mthis) => mthis["style"];

}

class BlinkCSSImportRule extends BlinkCSSRule {
  static final instance = new BlinkCSSImportRule();

  href_Getter_(mthis) => mthis["href"];

  media_Getter_(mthis) => mthis["media"];

  styleSheet_Getter_(mthis) => mthis["styleSheet"];

}

class BlinkCSSKeyframeRule extends BlinkCSSRule {
  static final instance = new BlinkCSSKeyframeRule();

  keyText_Getter_(mthis) => mthis["keyText"];

  keyText_Setter_(mthis, __arg_0) => mthis["keyText"] = __arg_0;

  style_Getter_(mthis) => mthis["style"];

}

class BlinkCSSKeyframesRule extends BlinkCSSRule {
  static final instance = new BlinkCSSKeyframesRule();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  cssRules_Getter_(mthis) => mthis["cssRules"];

  deleteRule_Callback_0_(mthis) => mthis.callMethod("deleteRule", []);

  deleteRule_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteRule", [__arg_0]);

  findRule_Callback_0_(mthis) => mthis.callMethod("findRule", []);

  findRule_Callback_1_(mthis, __arg_0) => mthis.callMethod("findRule", [__arg_0]);

  insertRule_Callback_0_(mthis) => mthis.callMethod("insertRule", []);

  insertRule_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertRule", [__arg_0]);

  name_Getter_(mthis) => mthis["name"];

  name_Setter_(mthis, __arg_0) => mthis["name"] = __arg_0;

}

class BlinkCSSMediaRule extends BlinkCSSRule {
  static final instance = new BlinkCSSMediaRule();

  cssRules_Getter_(mthis) => mthis["cssRules"];

  deleteRule_Callback_0_(mthis) => mthis.callMethod("deleteRule", []);

  deleteRule_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteRule", [__arg_0]);

  insertRule_Callback_0_(mthis) => mthis.callMethod("insertRule", []);

  insertRule_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertRule", [__arg_0]);

  insertRule_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("insertRule", [__arg_0, __arg_1]);

  media_Getter_(mthis) => mthis["media"];

}

class BlinkCSSPageRule extends BlinkCSSRule {
  static final instance = new BlinkCSSPageRule();

  selectorText_Getter_(mthis) => mthis["selectorText"];

  selectorText_Setter_(mthis, __arg_0) => mthis["selectorText"] = __arg_0;

  style_Getter_(mthis) => mthis["style"];

}

class BlinkCSSPrimitiveValue extends BlinkCSSValue {
  static final instance = new BlinkCSSPrimitiveValue();

  getCounterValue_Callback_0_(mthis) => mthis.callMethod("getCounterValue", []);

  getFloatValue_Callback_0_(mthis) => mthis.callMethod("getFloatValue", []);

  getFloatValue_Callback_1_(mthis, __arg_0) => mthis.callMethod("getFloatValue", [__arg_0]);

  getRGBColorValue_Callback_0_(mthis) => mthis.callMethod("getRGBColorValue", []);

  getRectValue_Callback_0_(mthis) => mthis.callMethod("getRectValue", []);

  getStringValue_Callback_0_(mthis) => mthis.callMethod("getStringValue", []);

  primitiveType_Getter_(mthis) => mthis["primitiveType"];

  setFloatValue_Callback_0_(mthis) => mthis.callMethod("setFloatValue", []);

  setFloatValue_Callback_1_(mthis, __arg_0) => mthis.callMethod("setFloatValue", [__arg_0]);

  setFloatValue_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setFloatValue", [__arg_0, __arg_1]);

  setStringValue_Callback_0_(mthis) => mthis.callMethod("setStringValue", []);

  setStringValue_Callback_1_(mthis, __arg_0) => mthis.callMethod("setStringValue", [__arg_0]);

  setStringValue_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setStringValue", [__arg_0, __arg_1]);

}

class BlinkCSSRule {
  static final instance = new BlinkCSSRule();

  cssText_Getter_(mthis) => mthis["cssText"];

  cssText_Setter_(mthis, __arg_0) => mthis["cssText"] = __arg_0;

  parentRule_Getter_(mthis) => mthis["parentRule"];

  parentStyleSheet_Getter_(mthis) => mthis["parentStyleSheet"];

  type_Getter_(mthis) => mthis["type"];

}

class BlinkCSSRuleList {
  static final instance = new BlinkCSSRuleList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

}

class BlinkCSSStyleDeclaration {
  static final instance = new BlinkCSSStyleDeclaration();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  $__propertyQuery___Callback_1_(mthis, __arg_0) => mthis[__arg_0];

  $__setter___Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("__setter__", [__arg_0, __arg_1]);

  cssText_Getter_(mthis) => mthis["cssText"];

  cssText_Setter_(mthis, __arg_0) => mthis["cssText"] = __arg_0;

  getPropertyPriority_Callback_0_(mthis) => mthis.callMethod("getPropertyPriority", []);

  getPropertyPriority_Callback_1_(mthis, __arg_0) => mthis.callMethod("getPropertyPriority", [__arg_0]);

  getPropertyValue_Callback_0_(mthis) => mthis.callMethod("getPropertyValue", []);

  getPropertyValue_Callback_1_(mthis, __arg_0) => mthis.callMethod("getPropertyValue", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

  parentRule_Getter_(mthis) => mthis["parentRule"];

  removeProperty_Callback_0_(mthis) => mthis.callMethod("removeProperty", []);

  removeProperty_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeProperty", [__arg_0]);

  setProperty_Callback_0_(mthis) => mthis.callMethod("setProperty", []);

  setProperty_Callback_1_(mthis, __arg_0) => mthis.callMethod("setProperty", [__arg_0]);

  setProperty_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setProperty", [__arg_0, __arg_1]);

  setProperty_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setProperty", [__arg_0, __arg_1, __arg_2]);

}

class BlinkCSSStyleRule extends BlinkCSSRule {
  static final instance = new BlinkCSSStyleRule();

  selectorText_Getter_(mthis) => mthis["selectorText"];

  selectorText_Setter_(mthis, __arg_0) => mthis["selectorText"] = __arg_0;

  style_Getter_(mthis) => mthis["style"];

}

class BlinkCSSStyleSheet extends BlinkStyleSheet {
  static final instance = new BlinkCSSStyleSheet();

  addRule_Callback_0_(mthis) => mthis.callMethod("addRule", []);

  addRule_Callback_1_(mthis, __arg_0) => mthis.callMethod("addRule", [__arg_0]);

  addRule_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("addRule", [__arg_0, __arg_1]);

  addRule_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("addRule", [__arg_0, __arg_1, __arg_2]);

  cssRules_Getter_(mthis) => mthis["cssRules"];

  deleteRule_Callback_0_(mthis) => mthis.callMethod("deleteRule", []);

  deleteRule_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteRule", [__arg_0]);

  insertRule_Callback_0_(mthis) => mthis.callMethod("insertRule", []);

  insertRule_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertRule", [__arg_0]);

  insertRule_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("insertRule", [__arg_0, __arg_1]);

  ownerRule_Getter_(mthis) => mthis["ownerRule"];

  removeRule_Callback_0_(mthis) => mthis.callMethod("removeRule", []);

  removeRule_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeRule", [__arg_0]);

  rules_Getter_(mthis) => mthis["rules"];

}

class BlinkCSSSupportsRule extends BlinkCSSRule {
  static final instance = new BlinkCSSSupportsRule();

  conditionText_Getter_(mthis) => mthis["conditionText"];

  cssRules_Getter_(mthis) => mthis["cssRules"];

  deleteRule_Callback_0_(mthis) => mthis.callMethod("deleteRule", []);

  deleteRule_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteRule", [__arg_0]);

  insertRule_Callback_0_(mthis) => mthis.callMethod("insertRule", []);

  insertRule_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertRule", [__arg_0]);

  insertRule_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("insertRule", [__arg_0, __arg_1]);

}

class BlinkCSSUnknownRule extends BlinkCSSRule {
  static final instance = new BlinkCSSUnknownRule();

}

class BlinkCSSValue {
  static final instance = new BlinkCSSValue();

  cssText_Getter_(mthis) => mthis["cssText"];

  cssText_Setter_(mthis, __arg_0) => mthis["cssText"] = __arg_0;

  cssValueType_Getter_(mthis) => mthis["cssValueType"];

}

class BlinkCSSValueList extends BlinkCSSValue {
  static final instance = new BlinkCSSValueList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

}

class BlinkCSSViewportRule extends BlinkCSSRule {
  static final instance = new BlinkCSSViewportRule();

  style_Getter_(mthis) => mthis["style"];

}

class BlinkCache {
  static final instance = new BlinkCache();

  addAll_Callback_0_(mthis) => mthis.callMethod("addAll", []);

  addAll_Callback_1_(mthis, __arg_0) => mthis.callMethod("addAll", [__arg_0]);

  add_Callback_0_(mthis) => mthis.callMethod("add", []);

  add_Callback_1_(mthis, __arg_0) => mthis.callMethod("add", [__arg_0]);

  delete_Callback_0_(mthis) => mthis.callMethod("delete", []);

  delete_Callback_1_(mthis, __arg_0) => mthis.callMethod("delete", [__arg_0]);

  delete_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("delete", [__arg_0, __arg_1]);

  keys_Callback_0_(mthis) => mthis.callMethod("keys", []);

  keys_Callback_1_(mthis, __arg_0) => mthis.callMethod("keys", [__arg_0]);

  keys_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("keys", [__arg_0, __arg_1]);

  matchAll_Callback_0_(mthis) => mthis.callMethod("matchAll", []);

  matchAll_Callback_1_(mthis, __arg_0) => mthis.callMethod("matchAll", [__arg_0]);

  matchAll_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("matchAll", [__arg_0, __arg_1]);

  match_Callback_0_(mthis) => mthis.callMethod("match", []);

  match_Callback_1_(mthis, __arg_0) => mthis.callMethod("match", [__arg_0]);

  match_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("match", [__arg_0, __arg_1]);

  put_Callback_0_(mthis) => mthis.callMethod("put", []);

  put_Callback_1_(mthis, __arg_0) => mthis.callMethod("put", [__arg_0]);

  put_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("put", [__arg_0, __arg_1]);

}

class BlinkCacheStorage {
  static final instance = new BlinkCacheStorage();

  create_Callback_0_(mthis) => mthis.callMethod("create", []);

  create_Callback_1_(mthis, __arg_0) => mthis.callMethod("create", [__arg_0]);

  delete_Callback_0_(mthis) => mthis.callMethod("delete", []);

  delete_Callback_1_(mthis, __arg_0) => mthis.callMethod("delete", [__arg_0]);

  get_Callback_0_(mthis) => mthis.callMethod("get", []);

  get_Callback_1_(mthis, __arg_0) => mthis.callMethod("get", [__arg_0]);

  has_Callback_0_(mthis) => mthis.callMethod("has", []);

  has_Callback_1_(mthis, __arg_0) => mthis.callMethod("has", [__arg_0]);

  keys_Callback_0_(mthis) => mthis.callMethod("keys", []);

}

class BlinkCanvas2DContextAttributes {
  static final instance = new BlinkCanvas2DContextAttributes();

  alpha_Getter_(mthis) => mthis["alpha"];

  alpha_Setter_(mthis, __arg_0) => mthis["alpha"] = __arg_0;

  storage_Getter_(mthis) => mthis["storage"];

  storage_Setter_(mthis, __arg_0) => mthis["storage"] = __arg_0;

}

class BlinkCanvasGradient {
  static final instance = new BlinkCanvasGradient();

  addColorStop_Callback_0_(mthis) => mthis.callMethod("addColorStop", []);

  addColorStop_Callback_1_(mthis, __arg_0) => mthis.callMethod("addColorStop", [__arg_0]);

  addColorStop_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("addColorStop", [__arg_0, __arg_1]);

}

class BlinkCanvasPattern {
  static final instance = new BlinkCanvasPattern();

  setTransform_Callback_0_(mthis) => mthis.callMethod("setTransform", []);

  setTransform_Callback_1_(mthis, __arg_0) => mthis.callMethod("setTransform", [__arg_0]);

}

class BlinkCanvasRenderingContext2D {
  static final instance = new BlinkCanvasRenderingContext2D();

  addHitRegion_Callback_0_(mthis) => mthis.callMethod("addHitRegion", []);

  addHitRegion_Callback_1_(mthis, __arg_0) => mthis.callMethod("addHitRegion", [__arg_0]);

  arcTo_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("arcTo", [__arg_0, __arg_1, __arg_2]);

  arcTo_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("arcTo", [__arg_0, __arg_1, __arg_2, __arg_3]);

  arcTo_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("arcTo", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  arc_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("arc", [__arg_0, __arg_1, __arg_2]);

  arc_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("arc", [__arg_0, __arg_1, __arg_2, __arg_3]);

  arc_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("arc", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  arc_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("arc", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  beginPath_Callback_0_(mthis) => mthis.callMethod("beginPath", []);

  bezierCurveTo_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("bezierCurveTo", [__arg_0, __arg_1, __arg_2, __arg_3]);

  bezierCurveTo_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("bezierCurveTo", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  bezierCurveTo_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("bezierCurveTo", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  canvas_Getter_(mthis) => mthis["canvas"];

  clearHitRegions_Callback_0_(mthis) => mthis.callMethod("clearHitRegions", []);

  clearRect_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("clearRect", [__arg_0, __arg_1]);

  clearRect_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("clearRect", [__arg_0, __arg_1, __arg_2]);

  clearRect_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("clearRect", [__arg_0, __arg_1, __arg_2, __arg_3]);

  clip_Callback_0_(mthis) => mthis.callMethod("clip", []);

  clip_Callback_1_(mthis, __arg_0) => mthis.callMethod("clip", [__arg_0]);

  clip_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("clip", [__arg_0, __arg_1]);

  closePath_Callback_0_(mthis) => mthis.callMethod("closePath", []);

  createImageData_Callback_0_(mthis) => mthis.callMethod("createImageData", []);

  createImageData_Callback_1_(mthis, __arg_0) => mthis.callMethod("createImageData", [__arg_0]);

  createImageData_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createImageData", [__arg_0, __arg_1]);

  createLinearGradient_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createLinearGradient", [__arg_0, __arg_1]);

  createLinearGradient_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("createLinearGradient", [__arg_0, __arg_1, __arg_2]);

  createLinearGradient_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("createLinearGradient", [__arg_0, __arg_1, __arg_2, __arg_3]);

  createPattern_Callback_0_(mthis) => mthis.callMethod("createPattern", []);

  createPattern_Callback_1_(mthis, __arg_0) => mthis.callMethod("createPattern", [__arg_0]);

  createPattern_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createPattern", [__arg_0, __arg_1]);

  createRadialGradient_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("createRadialGradient", [__arg_0, __arg_1, __arg_2, __arg_3]);

  createRadialGradient_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("createRadialGradient", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  createRadialGradient_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("createRadialGradient", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  currentTransform_Getter_(mthis) => mthis["currentTransform"];

  currentTransform_Setter_(mthis, __arg_0) => mthis["currentTransform"] = __arg_0;

  direction_Getter_(mthis) => mthis["direction"];

  direction_Setter_(mthis, __arg_0) => mthis["direction"] = __arg_0;

  drawFocusIfNeeded_Callback_0_(mthis) => mthis.callMethod("drawFocusIfNeeded", []);

  drawFocusIfNeeded_Callback_1_(mthis, __arg_0) => mthis.callMethod("drawFocusIfNeeded", [__arg_0]);

  drawFocusIfNeeded_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("drawFocusIfNeeded", [__arg_0, __arg_1]);

  drawImage_Callback_1_(mthis, __arg_0) => mthis.callMethod("drawImage", [__arg_0]);

  drawImage_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("drawImage", [__arg_0, __arg_1]);

  drawImage_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("drawImage", [__arg_0, __arg_1, __arg_2]);

  drawImage_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("drawImage", [__arg_0, __arg_1, __arg_2, __arg_3]);

  drawImage_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("drawImage", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  drawImage_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("drawImage", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  drawImage_Callback_8_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7) => mthis.callMethod("drawImage", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7]);

  drawImage_Callback_9_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8) => mthis.callMethod("drawImage", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8]);

  ellipse_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("ellipse", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  ellipse_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("ellipse", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  ellipse_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("ellipse", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  ellipse_Callback_8_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7) => mthis.callMethod("ellipse", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7]);

  fillRect_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("fillRect", [__arg_0, __arg_1]);

  fillRect_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("fillRect", [__arg_0, __arg_1, __arg_2]);

  fillRect_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("fillRect", [__arg_0, __arg_1, __arg_2, __arg_3]);

  fillStyle_Getter_(mthis) => mthis["fillStyle"];

  fillStyle_Setter_(mthis, __arg_0) => mthis["fillStyle"] = __arg_0;

  fillText_Callback_1_(mthis, __arg_0) => mthis.callMethod("fillText", [__arg_0]);

  fillText_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("fillText", [__arg_0, __arg_1]);

  fillText_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("fillText", [__arg_0, __arg_1, __arg_2]);

  fillText_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("fillText", [__arg_0, __arg_1, __arg_2, __arg_3]);

  fill_Callback_0_(mthis) => mthis.callMethod("fill", []);

  fill_Callback_1_(mthis, __arg_0) => mthis.callMethod("fill", [__arg_0]);

  fill_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("fill", [__arg_0, __arg_1]);

  font_Getter_(mthis) => mthis["font"];

  font_Setter_(mthis, __arg_0) => mthis["font"] = __arg_0;

  getContextAttributes_Callback_0_(mthis) => mthis.callMethod("getContextAttributes", []);

  getImageData_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getImageData", [__arg_0, __arg_1]);

  getImageData_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("getImageData", [__arg_0, __arg_1, __arg_2]);

  getImageData_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("getImageData", [__arg_0, __arg_1, __arg_2, __arg_3]);

  getLineDash_Callback_0_(mthis) => mthis.callMethod("getLineDash", []);

  globalAlpha_Getter_(mthis) => mthis["globalAlpha"];

  globalAlpha_Setter_(mthis, __arg_0) => mthis["globalAlpha"] = __arg_0;

  globalCompositeOperation_Getter_(mthis) => mthis["globalCompositeOperation"];

  globalCompositeOperation_Setter_(mthis, __arg_0) => mthis["globalCompositeOperation"] = __arg_0;

  imageSmoothingEnabled_Getter_(mthis) => mthis["imageSmoothingEnabled"];

  imageSmoothingEnabled_Setter_(mthis, __arg_0) => mthis["imageSmoothingEnabled"] = __arg_0;

  isContextLost_Callback_0_(mthis) => mthis.callMethod("isContextLost", []);

  isPointInPath_Callback_0_(mthis) => mthis.callMethod("isPointInPath", []);

  isPointInPath_Callback_1_(mthis, __arg_0) => mthis.callMethod("isPointInPath", [__arg_0]);

  isPointInPath_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("isPointInPath", [__arg_0, __arg_1]);

  isPointInPath_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("isPointInPath", [__arg_0, __arg_1, __arg_2]);

  isPointInPath_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("isPointInPath", [__arg_0, __arg_1, __arg_2, __arg_3]);

  isPointInStroke_Callback_0_(mthis) => mthis.callMethod("isPointInStroke", []);

  isPointInStroke_Callback_1_(mthis, __arg_0) => mthis.callMethod("isPointInStroke", [__arg_0]);

  isPointInStroke_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("isPointInStroke", [__arg_0, __arg_1]);

  isPointInStroke_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("isPointInStroke", [__arg_0, __arg_1, __arg_2]);

  lineCap_Getter_(mthis) => mthis["lineCap"];

  lineCap_Setter_(mthis, __arg_0) => mthis["lineCap"] = __arg_0;

  lineDashOffset_Getter_(mthis) => mthis["lineDashOffset"];

  lineDashOffset_Setter_(mthis, __arg_0) => mthis["lineDashOffset"] = __arg_0;

  lineJoin_Getter_(mthis) => mthis["lineJoin"];

  lineJoin_Setter_(mthis, __arg_0) => mthis["lineJoin"] = __arg_0;

  lineTo_Callback_0_(mthis) => mthis.callMethod("lineTo", []);

  lineTo_Callback_1_(mthis, __arg_0) => mthis.callMethod("lineTo", [__arg_0]);

  lineTo_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("lineTo", [__arg_0, __arg_1]);

  lineWidth_Getter_(mthis) => mthis["lineWidth"];

  lineWidth_Setter_(mthis, __arg_0) => mthis["lineWidth"] = __arg_0;

  measureText_Callback_0_(mthis) => mthis.callMethod("measureText", []);

  measureText_Callback_1_(mthis, __arg_0) => mthis.callMethod("measureText", [__arg_0]);

  miterLimit_Getter_(mthis) => mthis["miterLimit"];

  miterLimit_Setter_(mthis, __arg_0) => mthis["miterLimit"] = __arg_0;

  moveTo_Callback_0_(mthis) => mthis.callMethod("moveTo", []);

  moveTo_Callback_1_(mthis, __arg_0) => mthis.callMethod("moveTo", [__arg_0]);

  moveTo_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("moveTo", [__arg_0, __arg_1]);

  putImageData_Callback_1_(mthis, __arg_0) => mthis.callMethod("putImageData", [__arg_0]);

  putImageData_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("putImageData", [__arg_0, __arg_1]);

  putImageData_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("putImageData", [__arg_0, __arg_1, __arg_2]);

  putImageData_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("putImageData", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  putImageData_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("putImageData", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  putImageData_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("putImageData", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  quadraticCurveTo_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("quadraticCurveTo", [__arg_0, __arg_1]);

  quadraticCurveTo_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("quadraticCurveTo", [__arg_0, __arg_1, __arg_2]);

  quadraticCurveTo_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("quadraticCurveTo", [__arg_0, __arg_1, __arg_2, __arg_3]);

  rect_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("rect", [__arg_0, __arg_1]);

  rect_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("rect", [__arg_0, __arg_1, __arg_2]);

  rect_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("rect", [__arg_0, __arg_1, __arg_2, __arg_3]);

  removeHitRegion_Callback_0_(mthis) => mthis.callMethod("removeHitRegion", []);

  removeHitRegion_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeHitRegion", [__arg_0]);

  resetTransform_Callback_0_(mthis) => mthis.callMethod("resetTransform", []);

  restore_Callback_0_(mthis) => mthis.callMethod("restore", []);

  rotate_Callback_0_(mthis) => mthis.callMethod("rotate", []);

  rotate_Callback_1_(mthis, __arg_0) => mthis.callMethod("rotate", [__arg_0]);

  save_Callback_0_(mthis) => mthis.callMethod("save", []);

  scale_Callback_0_(mthis) => mthis.callMethod("scale", []);

  scale_Callback_1_(mthis, __arg_0) => mthis.callMethod("scale", [__arg_0]);

  scale_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("scale", [__arg_0, __arg_1]);

  scrollPathIntoView_Callback_0_(mthis) => mthis.callMethod("scrollPathIntoView", []);

  scrollPathIntoView_Callback_1_(mthis, __arg_0) => mthis.callMethod("scrollPathIntoView", [__arg_0]);

  setLineDash_Callback_0_(mthis) => mthis.callMethod("setLineDash", []);

  setLineDash_Callback_1_(mthis, __arg_0) => mthis.callMethod("setLineDash", [__arg_0]);

  setTransform_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("setTransform", [__arg_0, __arg_1, __arg_2, __arg_3]);

  setTransform_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("setTransform", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  setTransform_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("setTransform", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  shadowBlur_Getter_(mthis) => mthis["shadowBlur"];

  shadowBlur_Setter_(mthis, __arg_0) => mthis["shadowBlur"] = __arg_0;

  shadowColor_Getter_(mthis) => mthis["shadowColor"];

  shadowColor_Setter_(mthis, __arg_0) => mthis["shadowColor"] = __arg_0;

  shadowOffsetX_Getter_(mthis) => mthis["shadowOffsetX"];

  shadowOffsetX_Setter_(mthis, __arg_0) => mthis["shadowOffsetX"] = __arg_0;

  shadowOffsetY_Getter_(mthis) => mthis["shadowOffsetY"];

  shadowOffsetY_Setter_(mthis, __arg_0) => mthis["shadowOffsetY"] = __arg_0;

  strokeRect_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("strokeRect", [__arg_0, __arg_1]);

  strokeRect_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("strokeRect", [__arg_0, __arg_1, __arg_2]);

  strokeRect_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("strokeRect", [__arg_0, __arg_1, __arg_2, __arg_3]);

  strokeStyle_Getter_(mthis) => mthis["strokeStyle"];

  strokeStyle_Setter_(mthis, __arg_0) => mthis["strokeStyle"] = __arg_0;

  strokeText_Callback_1_(mthis, __arg_0) => mthis.callMethod("strokeText", [__arg_0]);

  strokeText_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("strokeText", [__arg_0, __arg_1]);

  strokeText_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("strokeText", [__arg_0, __arg_1, __arg_2]);

  strokeText_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("strokeText", [__arg_0, __arg_1, __arg_2, __arg_3]);

  stroke_Callback_0_(mthis) => mthis.callMethod("stroke", []);

  stroke_Callback_1_(mthis, __arg_0) => mthis.callMethod("stroke", [__arg_0]);

  textAlign_Getter_(mthis) => mthis["textAlign"];

  textAlign_Setter_(mthis, __arg_0) => mthis["textAlign"] = __arg_0;

  textBaseline_Getter_(mthis) => mthis["textBaseline"];

  textBaseline_Setter_(mthis, __arg_0) => mthis["textBaseline"] = __arg_0;

  transform_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("transform", [__arg_0, __arg_1, __arg_2, __arg_3]);

  transform_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("transform", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  transform_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("transform", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  translate_Callback_0_(mthis) => mthis.callMethod("translate", []);

  translate_Callback_1_(mthis, __arg_0) => mthis.callMethod("translate", [__arg_0]);

  translate_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("translate", [__arg_0, __arg_1]);

}

class BlinkChannelMergerNode extends BlinkAudioNode {
  static final instance = new BlinkChannelMergerNode();

}

class BlinkChannelSplitterNode extends BlinkAudioNode {
  static final instance = new BlinkChannelSplitterNode();

}

class BlinkCharacterData extends BlinkNode {
  static final instance = new BlinkCharacterData();

  appendData_Callback_0_(mthis) => mthis.callMethod("appendData", []);

  appendData_Callback_1_(mthis, __arg_0) => mthis.callMethod("appendData", [__arg_0]);

  data_Getter_(mthis) => mthis["data"];

  data_Setter_(mthis, __arg_0) => mthis["data"] = __arg_0;

  deleteData_Callback_0_(mthis) => mthis.callMethod("deleteData", []);

  deleteData_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteData", [__arg_0]);

  deleteData_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("deleteData", [__arg_0, __arg_1]);

  insertData_Callback_0_(mthis) => mthis.callMethod("insertData", []);

  insertData_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertData", [__arg_0]);

  insertData_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("insertData", [__arg_0, __arg_1]);

  length_Getter_(mthis) => mthis["length"];

  nextElementSibling_Getter_(mthis) => mthis["nextElementSibling"];

  previousElementSibling_Getter_(mthis) => mthis["previousElementSibling"];

  replaceData_Callback_1_(mthis, __arg_0) => mthis.callMethod("replaceData", [__arg_0]);

  replaceData_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("replaceData", [__arg_0, __arg_1]);

  replaceData_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("replaceData", [__arg_0, __arg_1, __arg_2]);

  substringData_Callback_0_(mthis) => mthis.callMethod("substringData", []);

  substringData_Callback_1_(mthis, __arg_0) => mthis.callMethod("substringData", [__arg_0]);

  substringData_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("substringData", [__arg_0, __arg_1]);

}

class BlinkCircularGeofencingRegion extends BlinkGeofencingRegion {
  static final instance = new BlinkCircularGeofencingRegion();

  constructorCallback_0_() => new js.JsObject(js.context["CircularGeofencingRegion"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["CircularGeofencingRegion"], [__arg_0]);

  latitude_Getter_(mthis) => mthis["latitude"];

  longitude_Getter_(mthis) => mthis["longitude"];

  radius_Getter_(mthis) => mthis["radius"];

}

class BlinkClientRect {
  static final instance = new BlinkClientRect();

  bottom_Getter_(mthis) => mthis["bottom"];

  height_Getter_(mthis) => mthis["height"];

  left_Getter_(mthis) => mthis["left"];

  right_Getter_(mthis) => mthis["right"];

  top_Getter_(mthis) => mthis["top"];

  width_Getter_(mthis) => mthis["width"];

}

class BlinkClientRectList {
  static final instance = new BlinkClientRectList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

}

class BlinkCloseEvent extends BlinkEvent {
  static final instance = new BlinkCloseEvent();

  code_Getter_(mthis) => mthis["code"];

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["CloseEvent"], [__arg_0, __arg_1]);

  reason_Getter_(mthis) => mthis["reason"];

  wasClean_Getter_(mthis) => mthis["wasClean"];

}

class BlinkComment extends BlinkCharacterData {
  static final instance = new BlinkComment();

  constructorCallback_0_() => new js.JsObject(js.context["Comment"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["Comment"], [__arg_0]);

}

class BlinkCompositionEvent extends BlinkUIEvent {
  static final instance = new BlinkCompositionEvent();

  activeSegmentEnd_Getter_(mthis) => mthis["activeSegmentEnd"];

  activeSegmentStart_Getter_(mthis) => mthis["activeSegmentStart"];

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["CompositionEvent"], [__arg_0, __arg_1]);

  data_Getter_(mthis) => mthis["data"];

  getSegments_Callback_0_(mthis) => mthis.callMethod("getSegments", []);

  initCompositionEvent_Callback_0_(mthis) => mthis.callMethod("initCompositionEvent", []);

  initCompositionEvent_Callback_1_(mthis, __arg_0) => mthis.callMethod("initCompositionEvent", [__arg_0]);

  initCompositionEvent_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("initCompositionEvent", [__arg_0, __arg_1]);

  initCompositionEvent_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("initCompositionEvent", [__arg_0, __arg_1, __arg_2]);

  initCompositionEvent_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("initCompositionEvent", [__arg_0, __arg_1, __arg_2, __arg_3]);

  initCompositionEvent_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("initCompositionEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

}

class BlinkConsole extends BlinkConsoleBase {
  static final instance = new BlinkConsole();

  memory_Getter_(mthis) => mthis["memory"];

}

class BlinkConsoleBase {
  static final instance = new BlinkConsoleBase();

  assert_Callback_0_(mthis) => mthis.callMethod("assert", []);

  assert_Callback_1_(mthis, __arg_0) => mthis.callMethod("assert", [__arg_0]);

  clear_Callback_0_(mthis) => mthis.callMethod("clear", []);

  clear_Callback_1_(mthis, __arg_0) => mthis.callMethod("clear", [__arg_0]);

  count_Callback_0_(mthis) => mthis.callMethod("count", []);

  count_Callback_1_(mthis, __arg_0) => mthis.callMethod("count", [__arg_0]);

  debug_Callback_0_(mthis) => mthis.callMethod("debug", []);

  debug_Callback_1_(mthis, __arg_0) => mthis.callMethod("debug", [__arg_0]);

  dir_Callback_0_(mthis) => mthis.callMethod("dir", []);

  dir_Callback_1_(mthis, __arg_0) => mthis.callMethod("dir", [__arg_0]);

  dirxml_Callback_0_(mthis) => mthis.callMethod("dirxml", []);

  dirxml_Callback_1_(mthis, __arg_0) => mthis.callMethod("dirxml", [__arg_0]);

  error_Callback_0_(mthis) => mthis.callMethod("error", []);

  error_Callback_1_(mthis, __arg_0) => mthis.callMethod("error", [__arg_0]);

  groupCollapsed_Callback_0_(mthis) => mthis.callMethod("groupCollapsed", []);

  groupCollapsed_Callback_1_(mthis, __arg_0) => mthis.callMethod("groupCollapsed", [__arg_0]);

  groupEnd_Callback_0_(mthis) => mthis.callMethod("groupEnd", []);

  group_Callback_0_(mthis) => mthis.callMethod("group", []);

  group_Callback_1_(mthis, __arg_0) => mthis.callMethod("group", [__arg_0]);

  info_Callback_0_(mthis) => mthis.callMethod("info", []);

  info_Callback_1_(mthis, __arg_0) => mthis.callMethod("info", [__arg_0]);

  log_Callback_0_(mthis) => mthis.callMethod("log", []);

  log_Callback_1_(mthis, __arg_0) => mthis.callMethod("log", [__arg_0]);

  markTimeline_Callback_0_(mthis) => mthis.callMethod("markTimeline", []);

  markTimeline_Callback_1_(mthis, __arg_0) => mthis.callMethod("markTimeline", [__arg_0]);

  profileEnd_Callback_0_(mthis) => mthis.callMethod("profileEnd", []);

  profileEnd_Callback_1_(mthis, __arg_0) => mthis.callMethod("profileEnd", [__arg_0]);

  profile_Callback_0_(mthis) => mthis.callMethod("profile", []);

  profile_Callback_1_(mthis, __arg_0) => mthis.callMethod("profile", [__arg_0]);

  table_Callback_0_(mthis) => mthis.callMethod("table", []);

  table_Callback_1_(mthis, __arg_0) => mthis.callMethod("table", [__arg_0]);

  timeEnd_Callback_0_(mthis) => mthis.callMethod("timeEnd", []);

  timeEnd_Callback_1_(mthis, __arg_0) => mthis.callMethod("timeEnd", [__arg_0]);

  timeStamp_Callback_0_(mthis) => mthis.callMethod("timeStamp", []);

  timeStamp_Callback_1_(mthis, __arg_0) => mthis.callMethod("timeStamp", [__arg_0]);

  time_Callback_0_(mthis) => mthis.callMethod("time", []);

  time_Callback_1_(mthis, __arg_0) => mthis.callMethod("time", [__arg_0]);

  timelineEnd_Callback_0_(mthis) => mthis.callMethod("timelineEnd", []);

  timelineEnd_Callback_1_(mthis, __arg_0) => mthis.callMethod("timelineEnd", [__arg_0]);

  timeline_Callback_0_(mthis) => mthis.callMethod("timeline", []);

  timeline_Callback_1_(mthis, __arg_0) => mthis.callMethod("timeline", [__arg_0]);

  trace_Callback_0_(mthis) => mthis.callMethod("trace", []);

  trace_Callback_1_(mthis, __arg_0) => mthis.callMethod("trace", [__arg_0]);

  warn_Callback_0_(mthis) => mthis.callMethod("warn", []);

  warn_Callback_1_(mthis, __arg_0) => mthis.callMethod("warn", [__arg_0]);

}

class BlinkConvolverNode extends BlinkAudioNode {
  static final instance = new BlinkConvolverNode();

  buffer_Getter_(mthis) => mthis["buffer"];

  buffer_Setter_(mthis, __arg_0) => mthis["buffer"] = __arg_0;

  normalize_Getter_(mthis) => mthis["normalize"];

  normalize_Setter_(mthis, __arg_0) => mthis["normalize"] = __arg_0;

}

class BlinkCoordinates {
  static final instance = new BlinkCoordinates();

  accuracy_Getter_(mthis) => mthis["accuracy"];

  altitudeAccuracy_Getter_(mthis) => mthis["altitudeAccuracy"];

  altitude_Getter_(mthis) => mthis["altitude"];

  heading_Getter_(mthis) => mthis["heading"];

  latitude_Getter_(mthis) => mthis["latitude"];

  longitude_Getter_(mthis) => mthis["longitude"];

  speed_Getter_(mthis) => mthis["speed"];

}

class BlinkCounter {
  static final instance = new BlinkCounter();

  identifier_Getter_(mthis) => mthis["identifier"];

  listStyle_Getter_(mthis) => mthis["listStyle"];

  separator_Getter_(mthis) => mthis["separator"];

}

class BlinkCredential {
  static final instance = new BlinkCredential();

  avatarURL_Getter_(mthis) => mthis["avatarURL"];

  id_Getter_(mthis) => mthis["id"];

  name_Getter_(mthis) => mthis["name"];

}

class BlinkCredentialsContainer {
  static final instance = new BlinkCredentialsContainer();

  notifyFailedSignIn_Callback_0_(mthis) => mthis.callMethod("notifyFailedSignIn", []);

  notifyFailedSignIn_Callback_1_(mthis, __arg_0) => mthis.callMethod("notifyFailedSignIn", [__arg_0]);

  notifySignedIn_Callback_0_(mthis) => mthis.callMethod("notifySignedIn", []);

  notifySignedIn_Callback_1_(mthis, __arg_0) => mthis.callMethod("notifySignedIn", [__arg_0]);

  notifySignedOut_Callback_0_(mthis) => mthis.callMethod("notifySignedOut", []);

  request_Callback_0_(mthis) => mthis.callMethod("request", []);

  request_Callback_1_(mthis, __arg_0) => mthis.callMethod("request", [__arg_0]);

}

class BlinkCrypto {
  static final instance = new BlinkCrypto();

  getRandomValues_Callback_0_(mthis) => mthis.callMethod("getRandomValues", []);

  getRandomValues_Callback_1_(mthis, __arg_0) => mthis.callMethod("getRandomValues", [__arg_0]);

  subtle_Getter_(mthis) => mthis["subtle"];

}

class BlinkCryptoKey {
  static final instance = new BlinkCryptoKey();

  algorithm_Getter_(mthis) => mthis["algorithm"];

  extractable_Getter_(mthis) => mthis["extractable"];

  type_Getter_(mthis) => mthis["type"];

  usages_Getter_(mthis) => mthis["usages"];

}

class BlinkCustomEvent extends BlinkEvent {
  static final instance = new BlinkCustomEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["CustomEvent"], [__arg_0, __arg_1]);

  detail_Getter_(mthis) => mthis["detail"];

  initCustomEvent_Callback_0_(mthis) => mthis.callMethod("initCustomEvent", []);

  initCustomEvent_Callback_1_(mthis, __arg_0) => mthis.callMethod("initCustomEvent", [__arg_0]);

  initCustomEvent_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("initCustomEvent", [__arg_0, __arg_1]);

  initCustomEvent_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("initCustomEvent", [__arg_0, __arg_1, __arg_2]);

  initCustomEvent_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("initCustomEvent", [__arg_0, __arg_1, __arg_2, __arg_3]);

}

class BlinkDOMError {
  static final instance = new BlinkDOMError();

  constructorCallback_0_() => new js.JsObject(js.context["DOMError"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["DOMError"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["DOMError"], [__arg_0, __arg_1]);

  message_Getter_(mthis) => mthis["message"];

  name_Getter_(mthis) => mthis["name"];

}

class BlinkDOMException {
  static final instance = new BlinkDOMException();

  message_Getter_(mthis) => mthis["message"];

  name_Getter_(mthis) => mthis["name"];

  toString_Callback_0_(mthis) => mthis.callMethod("toString", []);

}

class BlinkDOMFileSystem {
  static final instance = new BlinkDOMFileSystem();

  name_Getter_(mthis) => mthis["name"];

  root_Getter_(mthis) => mthis["root"];

}

class BlinkDOMFileSystemSync {
  static final instance = new BlinkDOMFileSystemSync();

  name_Getter_(mthis) => mthis["name"];

  root_Getter_(mthis) => mthis["root"];

}

class BlinkDOMImplementation {
  static final instance = new BlinkDOMImplementation();

  createDocumentType_Callback_1_(mthis, __arg_0) => mthis.callMethod("createDocumentType", [__arg_0]);

  createDocumentType_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createDocumentType", [__arg_0, __arg_1]);

  createDocumentType_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("createDocumentType", [__arg_0, __arg_1, __arg_2]);

  createDocument_Callback_0_(mthis) => mthis.callMethod("createDocument", []);

  createDocument_Callback_1_(mthis, __arg_0) => mthis.callMethod("createDocument", [__arg_0]);

  createDocument_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createDocument", [__arg_0, __arg_1]);

  createDocument_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("createDocument", [__arg_0, __arg_1, __arg_2]);

  createHTMLDocument_Callback_0_(mthis) => mthis.callMethod("createHTMLDocument", []);

  createHTMLDocument_Callback_1_(mthis, __arg_0) => mthis.callMethod("createHTMLDocument", [__arg_0]);

  hasFeature_Callback_0_(mthis) => mthis.callMethod("hasFeature", []);

  hasFeature_Callback_1_(mthis, __arg_0) => mthis.callMethod("hasFeature", [__arg_0]);

  hasFeature_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("hasFeature", [__arg_0, __arg_1]);

}

class BlinkDOMMatrix extends BlinkDOMMatrixReadOnly {
  static final instance = new BlinkDOMMatrix();

  a_Getter_(mthis) => mthis["a"];

  a_Setter_(mthis, __arg_0) => mthis["a"] = __arg_0;

  b_Getter_(mthis) => mthis["b"];

  b_Setter_(mthis, __arg_0) => mthis["b"] = __arg_0;

  c_Getter_(mthis) => mthis["c"];

  c_Setter_(mthis, __arg_0) => mthis["c"] = __arg_0;

  constructorCallback_0_() => new js.JsObject(js.context["DOMMatrix"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["DOMMatrix"], [__arg_0]);

  d_Getter_(mthis) => mthis["d"];

  d_Setter_(mthis, __arg_0) => mthis["d"] = __arg_0;

  e_Getter_(mthis) => mthis["e"];

  e_Setter_(mthis, __arg_0) => mthis["e"] = __arg_0;

  f_Getter_(mthis) => mthis["f"];

  f_Setter_(mthis, __arg_0) => mthis["f"] = __arg_0;

  m11_Getter_(mthis) => mthis["m11"];

  m11_Setter_(mthis, __arg_0) => mthis["m11"] = __arg_0;

  m12_Getter_(mthis) => mthis["m12"];

  m12_Setter_(mthis, __arg_0) => mthis["m12"] = __arg_0;

  m13_Getter_(mthis) => mthis["m13"];

  m13_Setter_(mthis, __arg_0) => mthis["m13"] = __arg_0;

  m14_Getter_(mthis) => mthis["m14"];

  m14_Setter_(mthis, __arg_0) => mthis["m14"] = __arg_0;

  m21_Getter_(mthis) => mthis["m21"];

  m21_Setter_(mthis, __arg_0) => mthis["m21"] = __arg_0;

  m22_Getter_(mthis) => mthis["m22"];

  m22_Setter_(mthis, __arg_0) => mthis["m22"] = __arg_0;

  m23_Getter_(mthis) => mthis["m23"];

  m23_Setter_(mthis, __arg_0) => mthis["m23"] = __arg_0;

  m24_Getter_(mthis) => mthis["m24"];

  m24_Setter_(mthis, __arg_0) => mthis["m24"] = __arg_0;

  m31_Getter_(mthis) => mthis["m31"];

  m31_Setter_(mthis, __arg_0) => mthis["m31"] = __arg_0;

  m32_Getter_(mthis) => mthis["m32"];

  m32_Setter_(mthis, __arg_0) => mthis["m32"] = __arg_0;

  m33_Getter_(mthis) => mthis["m33"];

  m33_Setter_(mthis, __arg_0) => mthis["m33"] = __arg_0;

  m34_Getter_(mthis) => mthis["m34"];

  m34_Setter_(mthis, __arg_0) => mthis["m34"] = __arg_0;

  m41_Getter_(mthis) => mthis["m41"];

  m41_Setter_(mthis, __arg_0) => mthis["m41"] = __arg_0;

  m42_Getter_(mthis) => mthis["m42"];

  m42_Setter_(mthis, __arg_0) => mthis["m42"] = __arg_0;

  m43_Getter_(mthis) => mthis["m43"];

  m43_Setter_(mthis, __arg_0) => mthis["m43"] = __arg_0;

  m44_Getter_(mthis) => mthis["m44"];

  m44_Setter_(mthis, __arg_0) => mthis["m44"] = __arg_0;

  multiplySelf_Callback_0_(mthis) => mthis.callMethod("multiplySelf", []);

  multiplySelf_Callback_1_(mthis, __arg_0) => mthis.callMethod("multiplySelf", [__arg_0]);

  preMultiplySelf_Callback_0_(mthis) => mthis.callMethod("preMultiplySelf", []);

  preMultiplySelf_Callback_1_(mthis, __arg_0) => mthis.callMethod("preMultiplySelf", [__arg_0]);

  scale3dSelf_Callback_0_(mthis) => mthis.callMethod("scale3dSelf", []);

  scale3dSelf_Callback_1_(mthis, __arg_0) => mthis.callMethod("scale3dSelf", [__arg_0]);

  scale3dSelf_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("scale3dSelf", [__arg_0, __arg_1]);

  scale3dSelf_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("scale3dSelf", [__arg_0, __arg_1, __arg_2]);

  scale3dSelf_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("scale3dSelf", [__arg_0, __arg_1, __arg_2, __arg_3]);

  scaleNonUniformSelf_Callback_0_(mthis) => mthis.callMethod("scaleNonUniformSelf", []);

  scaleNonUniformSelf_Callback_1_(mthis, __arg_0) => mthis.callMethod("scaleNonUniformSelf", [__arg_0]);

  scaleNonUniformSelf_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("scaleNonUniformSelf", [__arg_0, __arg_1]);

  scaleNonUniformSelf_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("scaleNonUniformSelf", [__arg_0, __arg_1, __arg_2]);

  scaleNonUniformSelf_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("scaleNonUniformSelf", [__arg_0, __arg_1, __arg_2, __arg_3]);

  scaleNonUniformSelf_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("scaleNonUniformSelf", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  scaleNonUniformSelf_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("scaleNonUniformSelf", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  scaleSelf_Callback_0_(mthis) => mthis.callMethod("scaleSelf", []);

  scaleSelf_Callback_1_(mthis, __arg_0) => mthis.callMethod("scaleSelf", [__arg_0]);

  scaleSelf_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("scaleSelf", [__arg_0, __arg_1]);

  scaleSelf_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("scaleSelf", [__arg_0, __arg_1, __arg_2]);

  translateSelf_Callback_0_(mthis) => mthis.callMethod("translateSelf", []);

  translateSelf_Callback_1_(mthis, __arg_0) => mthis.callMethod("translateSelf", [__arg_0]);

  translateSelf_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("translateSelf", [__arg_0, __arg_1]);

  translateSelf_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("translateSelf", [__arg_0, __arg_1, __arg_2]);

}

class BlinkDOMMatrixReadOnly {
  static final instance = new BlinkDOMMatrixReadOnly();

  a_Getter_(mthis) => mthis["a"];

  b_Getter_(mthis) => mthis["b"];

  c_Getter_(mthis) => mthis["c"];

  d_Getter_(mthis) => mthis["d"];

  e_Getter_(mthis) => mthis["e"];

  f_Getter_(mthis) => mthis["f"];

  is2D_Getter_(mthis) => mthis["is2D"];

  isIdentity_Getter_(mthis) => mthis["isIdentity"];

  m11_Getter_(mthis) => mthis["m11"];

  m12_Getter_(mthis) => mthis["m12"];

  m13_Getter_(mthis) => mthis["m13"];

  m14_Getter_(mthis) => mthis["m14"];

  m21_Getter_(mthis) => mthis["m21"];

  m22_Getter_(mthis) => mthis["m22"];

  m23_Getter_(mthis) => mthis["m23"];

  m24_Getter_(mthis) => mthis["m24"];

  m31_Getter_(mthis) => mthis["m31"];

  m32_Getter_(mthis) => mthis["m32"];

  m33_Getter_(mthis) => mthis["m33"];

  m34_Getter_(mthis) => mthis["m34"];

  m41_Getter_(mthis) => mthis["m41"];

  m42_Getter_(mthis) => mthis["m42"];

  m43_Getter_(mthis) => mthis["m43"];

  m44_Getter_(mthis) => mthis["m44"];

  multiply_Callback_0_(mthis) => mthis.callMethod("multiply", []);

  multiply_Callback_1_(mthis, __arg_0) => mthis.callMethod("multiply", [__arg_0]);

  scale3d_Callback_0_(mthis) => mthis.callMethod("scale3d", []);

  scale3d_Callback_1_(mthis, __arg_0) => mthis.callMethod("scale3d", [__arg_0]);

  scale3d_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("scale3d", [__arg_0, __arg_1]);

  scale3d_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("scale3d", [__arg_0, __arg_1, __arg_2]);

  scale3d_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("scale3d", [__arg_0, __arg_1, __arg_2, __arg_3]);

  scaleNonUniform_Callback_0_(mthis) => mthis.callMethod("scaleNonUniform", []);

  scaleNonUniform_Callback_1_(mthis, __arg_0) => mthis.callMethod("scaleNonUniform", [__arg_0]);

  scaleNonUniform_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("scaleNonUniform", [__arg_0, __arg_1]);

  scaleNonUniform_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("scaleNonUniform", [__arg_0, __arg_1, __arg_2]);

  scaleNonUniform_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("scaleNonUniform", [__arg_0, __arg_1, __arg_2, __arg_3]);

  scaleNonUniform_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("scaleNonUniform", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  scaleNonUniform_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("scaleNonUniform", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  scale_Callback_0_(mthis) => mthis.callMethod("scale", []);

  scale_Callback_1_(mthis, __arg_0) => mthis.callMethod("scale", [__arg_0]);

  scale_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("scale", [__arg_0, __arg_1]);

  scale_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("scale", [__arg_0, __arg_1, __arg_2]);

  toFloat32Array_Callback_0_(mthis) => mthis.callMethod("toFloat32Array", []);

  toFloat64Array_Callback_0_(mthis) => mthis.callMethod("toFloat64Array", []);

  translate_Callback_0_(mthis) => mthis.callMethod("translate", []);

  translate_Callback_1_(mthis, __arg_0) => mthis.callMethod("translate", [__arg_0]);

  translate_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("translate", [__arg_0, __arg_1]);

  translate_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("translate", [__arg_0, __arg_1, __arg_2]);

}

class BlinkDOMParser {
  static final instance = new BlinkDOMParser();

  constructorCallback_0_() => new js.JsObject(js.context["DOMParser"], []);

  parseFromString_Callback_0_(mthis) => mthis.callMethod("parseFromString", []);

  parseFromString_Callback_1_(mthis, __arg_0) => mthis.callMethod("parseFromString", [__arg_0]);

  parseFromString_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("parseFromString", [__arg_0, __arg_1]);

}

class BlinkDOMPoint extends BlinkDOMPointReadOnly {
  static final instance = new BlinkDOMPoint();

  constructorCallback_0_() => new js.JsObject(js.context["DOMPoint"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["DOMPoint"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["DOMPoint"], [__arg_0, __arg_1]);

  constructorCallback_3_(__arg_0, __arg_1, __arg_2) => new js.JsObject(js.context["DOMPoint"], [__arg_0, __arg_1, __arg_2]);

  constructorCallback_4_(__arg_0, __arg_1, __arg_2, __arg_3) => new js.JsObject(js.context["DOMPoint"], [__arg_0, __arg_1, __arg_2, __arg_3]);

  w_Getter_(mthis) => mthis["w"];

  w_Setter_(mthis, __arg_0) => mthis["w"] = __arg_0;

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

  z_Getter_(mthis) => mthis["z"];

  z_Setter_(mthis, __arg_0) => mthis["z"] = __arg_0;

}

class BlinkDOMPointReadOnly {
  static final instance = new BlinkDOMPointReadOnly();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["DOMPointReadOnly"], [__arg_0, __arg_1]);

  constructorCallback_3_(__arg_0, __arg_1, __arg_2) => new js.JsObject(js.context["DOMPointReadOnly"], [__arg_0, __arg_1, __arg_2]);

  constructorCallback_4_(__arg_0, __arg_1, __arg_2, __arg_3) => new js.JsObject(js.context["DOMPointReadOnly"], [__arg_0, __arg_1, __arg_2, __arg_3]);

  w_Getter_(mthis) => mthis["w"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

  z_Getter_(mthis) => mthis["z"];

}

class BlinkDOMRect extends BlinkDOMRectReadOnly {
  static final instance = new BlinkDOMRect();

  constructorCallback_0_() => new js.JsObject(js.context["DOMRect"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["DOMRect"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["DOMRect"], [__arg_0, __arg_1]);

  constructorCallback_3_(__arg_0, __arg_1, __arg_2) => new js.JsObject(js.context["DOMRect"], [__arg_0, __arg_1, __arg_2]);

  constructorCallback_4_(__arg_0, __arg_1, __arg_2, __arg_3) => new js.JsObject(js.context["DOMRect"], [__arg_0, __arg_1, __arg_2, __arg_3]);

  height_Getter_(mthis) => mthis["height"];

  height_Setter_(mthis, __arg_0) => mthis["height"] = __arg_0;

  width_Getter_(mthis) => mthis["width"];

  width_Setter_(mthis, __arg_0) => mthis["width"] = __arg_0;

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkDOMRectReadOnly {
  static final instance = new BlinkDOMRectReadOnly();

  bottom_Getter_(mthis) => mthis["bottom"];

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["DOMRectReadOnly"], [__arg_0, __arg_1]);

  constructorCallback_3_(__arg_0, __arg_1, __arg_2) => new js.JsObject(js.context["DOMRectReadOnly"], [__arg_0, __arg_1, __arg_2]);

  constructorCallback_4_(__arg_0, __arg_1, __arg_2, __arg_3) => new js.JsObject(js.context["DOMRectReadOnly"], [__arg_0, __arg_1, __arg_2, __arg_3]);

  height_Getter_(mthis) => mthis["height"];

  left_Getter_(mthis) => mthis["left"];

  right_Getter_(mthis) => mthis["right"];

  top_Getter_(mthis) => mthis["top"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkDOMSettableTokenList extends BlinkDOMTokenList {
  static final instance = new BlinkDOMSettableTokenList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  value_Getter_(mthis) => mthis["value"];

  value_Setter_(mthis, __arg_0) => mthis["value"] = __arg_0;

}

class BlinkDOMStringList {
  static final instance = new BlinkDOMStringList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  contains_Callback_0_(mthis) => mthis.callMethod("contains", []);

  contains_Callback_1_(mthis, __arg_0) => mthis.callMethod("contains", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

}

class BlinkDOMStringMap {
  static final instance = new BlinkDOMStringMap();

  $__delete___Callback_1_(mthis, __arg_0) => mthis.callMethod("__delete__", [__arg_0]);

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  $__setter___Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("__setter__", [__arg_0, __arg_1]);

}

class BlinkDOMTokenList {
  static final instance = new BlinkDOMTokenList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  add_Callback_0_(mthis) => mthis.callMethod("add", []);

  add_Callback_1_(mthis, __arg_0) => mthis.callMethod("add", [__arg_0]);

  contains_Callback_0_(mthis) => mthis.callMethod("contains", []);

  contains_Callback_1_(mthis, __arg_0) => mthis.callMethod("contains", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

  remove_Callback_0_(mthis) => mthis.callMethod("remove", []);

  remove_Callback_1_(mthis, __arg_0) => mthis.callMethod("remove", [__arg_0]);

  toggle_Callback_0_(mthis) => mthis.callMethod("toggle", []);

  toggle_Callback_1_(mthis, __arg_0) => mthis.callMethod("toggle", [__arg_0]);

  toggle_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("toggle", [__arg_0, __arg_1]);

}

class BlinkDataTransfer {
  static final instance = new BlinkDataTransfer();

  clearData_Callback_0_(mthis) => mthis.callMethod("clearData", []);

  clearData_Callback_1_(mthis, __arg_0) => mthis.callMethod("clearData", [__arg_0]);

  dropEffect_Getter_(mthis) => mthis["dropEffect"];

  dropEffect_Setter_(mthis, __arg_0) => mthis["dropEffect"] = __arg_0;

  effectAllowed_Getter_(mthis) => mthis["effectAllowed"];

  effectAllowed_Setter_(mthis, __arg_0) => mthis["effectAllowed"] = __arg_0;

  files_Getter_(mthis) => mthis["files"];

  getData_Callback_0_(mthis) => mthis.callMethod("getData", []);

  getData_Callback_1_(mthis, __arg_0) => mthis.callMethod("getData", [__arg_0]);

  items_Getter_(mthis) => mthis["items"];

  setData_Callback_0_(mthis) => mthis.callMethod("setData", []);

  setData_Callback_1_(mthis, __arg_0) => mthis.callMethod("setData", [__arg_0]);

  setData_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setData", [__arg_0, __arg_1]);

  setDragImage_Callback_1_(mthis, __arg_0) => mthis.callMethod("setDragImage", [__arg_0]);

  setDragImage_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setDragImage", [__arg_0, __arg_1]);

  setDragImage_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setDragImage", [__arg_0, __arg_1, __arg_2]);

  types_Getter_(mthis) => mthis["types"];

}

class BlinkDataTransferItem {
  static final instance = new BlinkDataTransferItem();

  getAsFile_Callback_0_(mthis) => mthis.callMethod("getAsFile", []);

  getAsString_Callback_0_(mthis) => mthis.callMethod("getAsString", []);

  getAsString_Callback_1_(mthis, __arg_0) => mthis.callMethod("getAsString", [__arg_0]);

  kind_Getter_(mthis) => mthis["kind"];

  type_Getter_(mthis) => mthis["type"];

  webkitGetAsEntry_Callback_0_(mthis) => mthis.callMethod("webkitGetAsEntry", []);

}

class BlinkDataTransferItemList {
  static final instance = new BlinkDataTransferItemList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  add_Callback_0_(mthis) => mthis.callMethod("add", []);

  add_Callback_1_(mthis, __arg_0) => mthis.callMethod("add", [__arg_0]);

  add_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("add", [__arg_0, __arg_1]);

  clear_Callback_0_(mthis) => mthis.callMethod("clear", []);

  length_Getter_(mthis) => mthis["length"];

  remove_Callback_0_(mthis) => mthis.callMethod("remove", []);

  remove_Callback_1_(mthis, __arg_0) => mthis.callMethod("remove", [__arg_0]);

}

class BlinkDatabase {
  static final instance = new BlinkDatabase();

  changeVersion_Callback_0_(mthis) => mthis.callMethod("changeVersion", []);

  changeVersion_Callback_1_(mthis, __arg_0) => mthis.callMethod("changeVersion", [__arg_0]);

  changeVersion_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("changeVersion", [__arg_0, __arg_1]);

  changeVersion_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("changeVersion", [__arg_0, __arg_1, __arg_2]);

  changeVersion_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("changeVersion", [__arg_0, __arg_1, __arg_2, __arg_3]);

  changeVersion_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("changeVersion", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  readTransaction_Callback_0_(mthis) => mthis.callMethod("readTransaction", []);

  readTransaction_Callback_1_(mthis, __arg_0) => mthis.callMethod("readTransaction", [__arg_0]);

  readTransaction_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("readTransaction", [__arg_0, __arg_1]);

  readTransaction_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("readTransaction", [__arg_0, __arg_1, __arg_2]);

  transaction_Callback_0_(mthis) => mthis.callMethod("transaction", []);

  transaction_Callback_1_(mthis, __arg_0) => mthis.callMethod("transaction", [__arg_0]);

  transaction_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("transaction", [__arg_0, __arg_1]);

  transaction_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("transaction", [__arg_0, __arg_1, __arg_2]);

  version_Getter_(mthis) => mthis["version"];

}

class BlinkDedicatedWorkerGlobalScope extends BlinkWorkerGlobalScope {
  static final instance = new BlinkDedicatedWorkerGlobalScope();

  onmessage_Getter_(mthis) => mthis["onmessage"];

  onmessage_Setter_(mthis, __arg_0) => mthis["onmessage"] = __arg_0;

  postMessage_Callback_0_(mthis) => mthis.callMethod("postMessage", []);

  postMessage_Callback_1_(mthis, __arg_0) => mthis.callMethod("postMessage", [__arg_0]);

  postMessage_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("postMessage", [__arg_0, __arg_1]);

}

class BlinkDelayNode extends BlinkAudioNode {
  static final instance = new BlinkDelayNode();

  delayTime_Getter_(mthis) => mthis["delayTime"];

}

class BlinkDeprecatedStorageInfo {
  static final instance = new BlinkDeprecatedStorageInfo();

  queryUsageAndQuota_Callback_0_(mthis) => mthis.callMethod("queryUsageAndQuota", []);

  queryUsageAndQuota_Callback_1_(mthis, __arg_0) => mthis.callMethod("queryUsageAndQuota", [__arg_0]);

  queryUsageAndQuota_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("queryUsageAndQuota", [__arg_0, __arg_1]);

  queryUsageAndQuota_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("queryUsageAndQuota", [__arg_0, __arg_1, __arg_2]);

  requestQuota_Callback_0_(mthis) => mthis.callMethod("requestQuota", []);

  requestQuota_Callback_1_(mthis, __arg_0) => mthis.callMethod("requestQuota", [__arg_0]);

  requestQuota_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("requestQuota", [__arg_0, __arg_1]);

  requestQuota_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("requestQuota", [__arg_0, __arg_1, __arg_2]);

  requestQuota_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("requestQuota", [__arg_0, __arg_1, __arg_2, __arg_3]);

}

class BlinkDeprecatedStorageQuota {
  static final instance = new BlinkDeprecatedStorageQuota();

  queryUsageAndQuota_Callback_0_(mthis) => mthis.callMethod("queryUsageAndQuota", []);

  queryUsageAndQuota_Callback_1_(mthis, __arg_0) => mthis.callMethod("queryUsageAndQuota", [__arg_0]);

  queryUsageAndQuota_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("queryUsageAndQuota", [__arg_0, __arg_1]);

  requestQuota_Callback_0_(mthis) => mthis.callMethod("requestQuota", []);

  requestQuota_Callback_1_(mthis, __arg_0) => mthis.callMethod("requestQuota", [__arg_0]);

  requestQuota_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("requestQuota", [__arg_0, __arg_1]);

  requestQuota_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("requestQuota", [__arg_0, __arg_1, __arg_2]);

}

class BlinkDeviceAcceleration {
  static final instance = new BlinkDeviceAcceleration();

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

  z_Getter_(mthis) => mthis["z"];

}

class BlinkDeviceLightEvent extends BlinkEvent {
  static final instance = new BlinkDeviceLightEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["DeviceLightEvent"], [__arg_0, __arg_1]);

  value_Getter_(mthis) => mthis["value"];

}

class BlinkDeviceMotionEvent extends BlinkEvent {
  static final instance = new BlinkDeviceMotionEvent();

  accelerationIncludingGravity_Getter_(mthis) => mthis["accelerationIncludingGravity"];

  acceleration_Getter_(mthis) => mthis["acceleration"];

  initDeviceMotionEvent_Callback_0_(mthis) => mthis.callMethod("initDeviceMotionEvent", []);

  initDeviceMotionEvent_Callback_1_(mthis, __arg_0) => mthis.callMethod("initDeviceMotionEvent", [__arg_0]);

  initDeviceMotionEvent_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("initDeviceMotionEvent", [__arg_0, __arg_1]);

  initDeviceMotionEvent_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("initDeviceMotionEvent", [__arg_0, __arg_1, __arg_2]);

  initDeviceMotionEvent_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("initDeviceMotionEvent", [__arg_0, __arg_1, __arg_2, __arg_3]);

  initDeviceMotionEvent_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("initDeviceMotionEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  initDeviceMotionEvent_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("initDeviceMotionEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  initDeviceMotionEvent_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("initDeviceMotionEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  interval_Getter_(mthis) => mthis["interval"];

  rotationRate_Getter_(mthis) => mthis["rotationRate"];

}

class BlinkDeviceOrientationEvent extends BlinkEvent {
  static final instance = new BlinkDeviceOrientationEvent();

  absolute_Getter_(mthis) => mthis["absolute"];

  alpha_Getter_(mthis) => mthis["alpha"];

  beta_Getter_(mthis) => mthis["beta"];

  gamma_Getter_(mthis) => mthis["gamma"];

  initDeviceOrientationEvent_Callback_0_(mthis) => mthis.callMethod("initDeviceOrientationEvent", []);

  initDeviceOrientationEvent_Callback_1_(mthis, __arg_0) => mthis.callMethod("initDeviceOrientationEvent", [__arg_0]);

  initDeviceOrientationEvent_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("initDeviceOrientationEvent", [__arg_0, __arg_1]);

  initDeviceOrientationEvent_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("initDeviceOrientationEvent", [__arg_0, __arg_1, __arg_2]);

  initDeviceOrientationEvent_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("initDeviceOrientationEvent", [__arg_0, __arg_1, __arg_2, __arg_3]);

  initDeviceOrientationEvent_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("initDeviceOrientationEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  initDeviceOrientationEvent_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("initDeviceOrientationEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  initDeviceOrientationEvent_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("initDeviceOrientationEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

}

class BlinkDeviceRotationRate {
  static final instance = new BlinkDeviceRotationRate();

  alpha_Getter_(mthis) => mthis["alpha"];

  beta_Getter_(mthis) => mthis["beta"];

  gamma_Getter_(mthis) => mthis["gamma"];

}

class BlinkDirectoryEntry extends BlinkEntry {
  static final instance = new BlinkDirectoryEntry();

  createReader_Callback_0_(mthis) => mthis.callMethod("createReader", []);

  getDirectory_Callback_0_(mthis) => mthis.callMethod("getDirectory", []);

  getDirectory_Callback_1_(mthis, __arg_0) => mthis.callMethod("getDirectory", [__arg_0]);

  getDirectory_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getDirectory", [__arg_0, __arg_1]);

  getDirectory_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("getDirectory", [__arg_0, __arg_1, __arg_2]);

  getDirectory_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("getDirectory", [__arg_0, __arg_1, __arg_2, __arg_3]);

  getFile_Callback_0_(mthis) => mthis.callMethod("getFile", []);

  getFile_Callback_1_(mthis, __arg_0) => mthis.callMethod("getFile", [__arg_0]);

  getFile_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getFile", [__arg_0, __arg_1]);

  getFile_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("getFile", [__arg_0, __arg_1, __arg_2]);

  getFile_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("getFile", [__arg_0, __arg_1, __arg_2, __arg_3]);

  removeRecursively_Callback_0_(mthis) => mthis.callMethod("removeRecursively", []);

  removeRecursively_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeRecursively", [__arg_0]);

  removeRecursively_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("removeRecursively", [__arg_0, __arg_1]);

}

class BlinkDirectoryEntrySync extends BlinkEntrySync {
  static final instance = new BlinkDirectoryEntrySync();

  createReader_Callback_0_(mthis) => mthis.callMethod("createReader", []);

  getDirectory_Callback_0_(mthis) => mthis.callMethod("getDirectory", []);

  getDirectory_Callback_1_(mthis, __arg_0) => mthis.callMethod("getDirectory", [__arg_0]);

  getDirectory_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getDirectory", [__arg_0, __arg_1]);

  getFile_Callback_0_(mthis) => mthis.callMethod("getFile", []);

  getFile_Callback_1_(mthis, __arg_0) => mthis.callMethod("getFile", [__arg_0]);

  getFile_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getFile", [__arg_0, __arg_1]);

  removeRecursively_Callback_0_(mthis) => mthis.callMethod("removeRecursively", []);

}

class BlinkDirectoryReader {
  static final instance = new BlinkDirectoryReader();

  readEntries_Callback_0_(mthis) => mthis.callMethod("readEntries", []);

  readEntries_Callback_1_(mthis, __arg_0) => mthis.callMethod("readEntries", [__arg_0]);

  readEntries_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("readEntries", [__arg_0, __arg_1]);

}

class BlinkDirectoryReaderSync {
  static final instance = new BlinkDirectoryReaderSync();

  readEntries_Callback_0_(mthis) => mthis.callMethod("readEntries", []);

}

class BlinkDocument extends BlinkNode {
  static final instance = new BlinkDocument();

  URL_Getter_(mthis) => mthis["URL"];

  activeElement_Getter_(mthis) => mthis["activeElement"];

  adoptNode_Callback_0_(mthis) => mthis.callMethod("adoptNode", []);

  adoptNode_Callback_1_(mthis, __arg_0) => mthis.callMethod("adoptNode", [__arg_0]);

  anchors_Getter_(mthis) => mthis["anchors"];

  body_Getter_(mthis) => mthis["body"];

  body_Setter_(mthis, __arg_0) => mthis["body"] = __arg_0;

  caretRangeFromPoint_Callback_0_(mthis) => mthis.callMethod("caretRangeFromPoint", []);

  caretRangeFromPoint_Callback_1_(mthis, __arg_0) => mthis.callMethod("caretRangeFromPoint", [__arg_0]);

  caretRangeFromPoint_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("caretRangeFromPoint", [__arg_0, __arg_1]);

  characterSet_Getter_(mthis) => mthis["characterSet"];

  charset_Getter_(mthis) => mthis["charset"];

  charset_Setter_(mthis, __arg_0) => mthis["charset"] = __arg_0;

  childElementCount_Getter_(mthis) => mthis["childElementCount"];

  children_Getter_(mthis) => mthis["children"];

  compatMode_Getter_(mthis) => mthis["compatMode"];

  contentType_Getter_(mthis) => mthis["contentType"];

  cookie_Getter_(mthis) => mthis["cookie"];

  cookie_Setter_(mthis, __arg_0) => mthis["cookie"] = __arg_0;

  createCDATASection_Callback_0_(mthis) => mthis.callMethod("createCDATASection", []);

  createCDATASection_Callback_1_(mthis, __arg_0) => mthis.callMethod("createCDATASection", [__arg_0]);

  createDocumentFragment_Callback_0_(mthis) => mthis.callMethod("createDocumentFragment", []);

  createElementNS_Callback_0_(mthis) => mthis.callMethod("createElementNS", []);

  createElementNS_Callback_1_(mthis, __arg_0) => mthis.callMethod("createElementNS", [__arg_0]);

  createElementNS_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createElementNS", [__arg_0, __arg_1]);

  createElementNS_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("createElementNS", [__arg_0, __arg_1, __arg_2]);

  createElement_Callback_0_(mthis) => mthis.callMethod("createElement", []);

  createElement_Callback_1_(mthis, __arg_0) => mthis.callMethod("createElement", [__arg_0]);

  createElement_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createElement", [__arg_0, __arg_1]);

  createEvent_Callback_0_(mthis) => mthis.callMethod("createEvent", []);

  createEvent_Callback_1_(mthis, __arg_0) => mthis.callMethod("createEvent", [__arg_0]);

  createNodeIterator_Callback_0_(mthis) => mthis.callMethod("createNodeIterator", []);

  createNodeIterator_Callback_1_(mthis, __arg_0) => mthis.callMethod("createNodeIterator", [__arg_0]);

  createNodeIterator_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createNodeIterator", [__arg_0, __arg_1]);

  createNodeIterator_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("createNodeIterator", [__arg_0, __arg_1, __arg_2]);

  createRange_Callback_0_(mthis) => mthis.callMethod("createRange", []);

  createTextNode_Callback_0_(mthis) => mthis.callMethod("createTextNode", []);

  createTextNode_Callback_1_(mthis, __arg_0) => mthis.callMethod("createTextNode", [__arg_0]);

  createTouchList_Callback_0_(mthis) => mthis.callMethod("createTouchList", []);

  createTouchList_Callback_1_(mthis, __arg_0) => mthis.callMethod("createTouchList", [__arg_0]);

  createTouch_Callback_0_(mthis) => mthis.callMethod("createTouch", []);

  createTouch_Callback_1_(mthis, __arg_0) => mthis.callMethod("createTouch", [__arg_0]);

  createTouch_Callback_10_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9) => mthis.callMethod("createTouch", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9]);

  createTouch_Callback_11_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9, __arg_10) => mthis.callMethod("createTouch", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9, __arg_10]);

  createTouch_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createTouch", [__arg_0, __arg_1]);

  createTouch_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("createTouch", [__arg_0, __arg_1, __arg_2]);

  createTouch_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("createTouch", [__arg_0, __arg_1, __arg_2, __arg_3]);

  createTouch_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("createTouch", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  createTouch_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("createTouch", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  createTouch_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("createTouch", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  createTouch_Callback_8_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7) => mthis.callMethod("createTouch", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7]);

  createTouch_Callback_9_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8) => mthis.callMethod("createTouch", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8]);

  createTreeWalker_Callback_0_(mthis) => mthis.callMethod("createTreeWalker", []);

  createTreeWalker_Callback_1_(mthis, __arg_0) => mthis.callMethod("createTreeWalker", [__arg_0]);

  createTreeWalker_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createTreeWalker", [__arg_0, __arg_1]);

  createTreeWalker_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("createTreeWalker", [__arg_0, __arg_1, __arg_2]);

  currentScript_Getter_(mthis) => mthis["currentScript"];

  defaultCharset_Getter_(mthis) => mthis["defaultCharset"];

  defaultView_Getter_(mthis) => mthis["defaultView"];

  doctype_Getter_(mthis) => mthis["doctype"];

  documentElement_Getter_(mthis) => mthis["documentElement"];

  documentURI_Getter_(mthis) => mthis["documentURI"];

  domain_Getter_(mthis) => mthis["domain"];

  domain_Setter_(mthis, __arg_0) => mthis["domain"] = __arg_0;

  elementFromPoint_Callback_0_(mthis) => mthis.callMethod("elementFromPoint", []);

  elementFromPoint_Callback_1_(mthis, __arg_0) => mthis.callMethod("elementFromPoint", [__arg_0]);

  elementFromPoint_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("elementFromPoint", [__arg_0, __arg_1]);

  embeds_Getter_(mthis) => mthis["embeds"];

  execCommand_Callback_0_(mthis) => mthis.callMethod("execCommand", []);

  execCommand_Callback_1_(mthis, __arg_0) => mthis.callMethod("execCommand", [__arg_0]);

  execCommand_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("execCommand", [__arg_0, __arg_1]);

  execCommand_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("execCommand", [__arg_0, __arg_1, __arg_2]);

  exitFullscreen_Callback_0_(mthis) => mthis.callMethod("exitFullscreen", []);

  exitPointerLock_Callback_0_(mthis) => mthis.callMethod("exitPointerLock", []);

  firstElementChild_Getter_(mthis) => mthis["firstElementChild"];

  fonts_Getter_(mthis) => mthis["fonts"];

  forms_Getter_(mthis) => mthis["forms"];

  fullscreenElement_Getter_(mthis) => mthis["fullscreenElement"];

  fullscreenEnabled_Getter_(mthis) => mthis["fullscreenEnabled"];

  getCSSCanvasContext_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getCSSCanvasContext", [__arg_0, __arg_1]);

  getCSSCanvasContext_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("getCSSCanvasContext", [__arg_0, __arg_1, __arg_2]);

  getCSSCanvasContext_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("getCSSCanvasContext", [__arg_0, __arg_1, __arg_2, __arg_3]);

  getElementById_Callback_0_(mthis) => mthis.callMethod("getElementById", []);

  getElementById_Callback_1_(mthis, __arg_0) => mthis.callMethod("getElementById", [__arg_0]);

  getElementsByClassName_Callback_0_(mthis) => mthis.callMethod("getElementsByClassName", []);

  getElementsByClassName_Callback_1_(mthis, __arg_0) => mthis.callMethod("getElementsByClassName", [__arg_0]);

  getElementsByName_Callback_0_(mthis) => mthis.callMethod("getElementsByName", []);

  getElementsByName_Callback_1_(mthis, __arg_0) => mthis.callMethod("getElementsByName", [__arg_0]);

  getElementsByTagName_Callback_0_(mthis) => mthis.callMethod("getElementsByTagName", []);

  getElementsByTagName_Callback_1_(mthis, __arg_0) => mthis.callMethod("getElementsByTagName", [__arg_0]);

  head_Getter_(mthis) => mthis["head"];

  hidden_Getter_(mthis) => mthis["hidden"];

  implementation_Getter_(mthis) => mthis["implementation"];

  importNode_Callback_0_(mthis) => mthis.callMethod("importNode", []);

  importNode_Callback_1_(mthis, __arg_0) => mthis.callMethod("importNode", [__arg_0]);

  importNode_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("importNode", [__arg_0, __arg_1]);

  inputEncoding_Getter_(mthis) => mthis["inputEncoding"];

  lastElementChild_Getter_(mthis) => mthis["lastElementChild"];

  lastModified_Getter_(mthis) => mthis["lastModified"];

  links_Getter_(mthis) => mthis["links"];

  onabort_Getter_(mthis) => mthis["onabort"];

  onabort_Setter_(mthis, __arg_0) => mthis["onabort"] = __arg_0;

  onautocomplete_Getter_(mthis) => mthis["onautocomplete"];

  onautocomplete_Setter_(mthis, __arg_0) => mthis["onautocomplete"] = __arg_0;

  onautocompleteerror_Getter_(mthis) => mthis["onautocompleteerror"];

  onautocompleteerror_Setter_(mthis, __arg_0) => mthis["onautocompleteerror"] = __arg_0;

  onbeforecopy_Getter_(mthis) => mthis["onbeforecopy"];

  onbeforecopy_Setter_(mthis, __arg_0) => mthis["onbeforecopy"] = __arg_0;

  onbeforecut_Getter_(mthis) => mthis["onbeforecut"];

  onbeforecut_Setter_(mthis, __arg_0) => mthis["onbeforecut"] = __arg_0;

  onbeforepaste_Getter_(mthis) => mthis["onbeforepaste"];

  onbeforepaste_Setter_(mthis, __arg_0) => mthis["onbeforepaste"] = __arg_0;

  onblur_Getter_(mthis) => mthis["onblur"];

  onblur_Setter_(mthis, __arg_0) => mthis["onblur"] = __arg_0;

  oncancel_Getter_(mthis) => mthis["oncancel"];

  oncancel_Setter_(mthis, __arg_0) => mthis["oncancel"] = __arg_0;

  oncanplay_Getter_(mthis) => mthis["oncanplay"];

  oncanplay_Setter_(mthis, __arg_0) => mthis["oncanplay"] = __arg_0;

  oncanplaythrough_Getter_(mthis) => mthis["oncanplaythrough"];

  oncanplaythrough_Setter_(mthis, __arg_0) => mthis["oncanplaythrough"] = __arg_0;

  onchange_Getter_(mthis) => mthis["onchange"];

  onchange_Setter_(mthis, __arg_0) => mthis["onchange"] = __arg_0;

  onclick_Getter_(mthis) => mthis["onclick"];

  onclick_Setter_(mthis, __arg_0) => mthis["onclick"] = __arg_0;

  onclose_Getter_(mthis) => mthis["onclose"];

  onclose_Setter_(mthis, __arg_0) => mthis["onclose"] = __arg_0;

  oncontextmenu_Getter_(mthis) => mthis["oncontextmenu"];

  oncontextmenu_Setter_(mthis, __arg_0) => mthis["oncontextmenu"] = __arg_0;

  oncopy_Getter_(mthis) => mthis["oncopy"];

  oncopy_Setter_(mthis, __arg_0) => mthis["oncopy"] = __arg_0;

  oncuechange_Getter_(mthis) => mthis["oncuechange"];

  oncuechange_Setter_(mthis, __arg_0) => mthis["oncuechange"] = __arg_0;

  oncut_Getter_(mthis) => mthis["oncut"];

  oncut_Setter_(mthis, __arg_0) => mthis["oncut"] = __arg_0;

  ondblclick_Getter_(mthis) => mthis["ondblclick"];

  ondblclick_Setter_(mthis, __arg_0) => mthis["ondblclick"] = __arg_0;

  ondrag_Getter_(mthis) => mthis["ondrag"];

  ondrag_Setter_(mthis, __arg_0) => mthis["ondrag"] = __arg_0;

  ondragend_Getter_(mthis) => mthis["ondragend"];

  ondragend_Setter_(mthis, __arg_0) => mthis["ondragend"] = __arg_0;

  ondragenter_Getter_(mthis) => mthis["ondragenter"];

  ondragenter_Setter_(mthis, __arg_0) => mthis["ondragenter"] = __arg_0;

  ondragleave_Getter_(mthis) => mthis["ondragleave"];

  ondragleave_Setter_(mthis, __arg_0) => mthis["ondragleave"] = __arg_0;

  ondragover_Getter_(mthis) => mthis["ondragover"];

  ondragover_Setter_(mthis, __arg_0) => mthis["ondragover"] = __arg_0;

  ondragstart_Getter_(mthis) => mthis["ondragstart"];

  ondragstart_Setter_(mthis, __arg_0) => mthis["ondragstart"] = __arg_0;

  ondrop_Getter_(mthis) => mthis["ondrop"];

  ondrop_Setter_(mthis, __arg_0) => mthis["ondrop"] = __arg_0;

  ondurationchange_Getter_(mthis) => mthis["ondurationchange"];

  ondurationchange_Setter_(mthis, __arg_0) => mthis["ondurationchange"] = __arg_0;

  onemptied_Getter_(mthis) => mthis["onemptied"];

  onemptied_Setter_(mthis, __arg_0) => mthis["onemptied"] = __arg_0;

  onended_Getter_(mthis) => mthis["onended"];

  onended_Setter_(mthis, __arg_0) => mthis["onended"] = __arg_0;

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onfocus_Getter_(mthis) => mthis["onfocus"];

  onfocus_Setter_(mthis, __arg_0) => mthis["onfocus"] = __arg_0;

  onfullscreenchange_Getter_(mthis) => mthis["onfullscreenchange"];

  onfullscreenchange_Setter_(mthis, __arg_0) => mthis["onfullscreenchange"] = __arg_0;

  onfullscreenerror_Getter_(mthis) => mthis["onfullscreenerror"];

  onfullscreenerror_Setter_(mthis, __arg_0) => mthis["onfullscreenerror"] = __arg_0;

  oninput_Getter_(mthis) => mthis["oninput"];

  oninput_Setter_(mthis, __arg_0) => mthis["oninput"] = __arg_0;

  oninvalid_Getter_(mthis) => mthis["oninvalid"];

  oninvalid_Setter_(mthis, __arg_0) => mthis["oninvalid"] = __arg_0;

  onkeydown_Getter_(mthis) => mthis["onkeydown"];

  onkeydown_Setter_(mthis, __arg_0) => mthis["onkeydown"] = __arg_0;

  onkeypress_Getter_(mthis) => mthis["onkeypress"];

  onkeypress_Setter_(mthis, __arg_0) => mthis["onkeypress"] = __arg_0;

  onkeyup_Getter_(mthis) => mthis["onkeyup"];

  onkeyup_Setter_(mthis, __arg_0) => mthis["onkeyup"] = __arg_0;

  onload_Getter_(mthis) => mthis["onload"];

  onload_Setter_(mthis, __arg_0) => mthis["onload"] = __arg_0;

  onloadeddata_Getter_(mthis) => mthis["onloadeddata"];

  onloadeddata_Setter_(mthis, __arg_0) => mthis["onloadeddata"] = __arg_0;

  onloadedmetadata_Getter_(mthis) => mthis["onloadedmetadata"];

  onloadedmetadata_Setter_(mthis, __arg_0) => mthis["onloadedmetadata"] = __arg_0;

  onloadstart_Getter_(mthis) => mthis["onloadstart"];

  onloadstart_Setter_(mthis, __arg_0) => mthis["onloadstart"] = __arg_0;

  onmousedown_Getter_(mthis) => mthis["onmousedown"];

  onmousedown_Setter_(mthis, __arg_0) => mthis["onmousedown"] = __arg_0;

  onmouseenter_Getter_(mthis) => mthis["onmouseenter"];

  onmouseenter_Setter_(mthis, __arg_0) => mthis["onmouseenter"] = __arg_0;

  onmouseleave_Getter_(mthis) => mthis["onmouseleave"];

  onmouseleave_Setter_(mthis, __arg_0) => mthis["onmouseleave"] = __arg_0;

  onmousemove_Getter_(mthis) => mthis["onmousemove"];

  onmousemove_Setter_(mthis, __arg_0) => mthis["onmousemove"] = __arg_0;

  onmouseout_Getter_(mthis) => mthis["onmouseout"];

  onmouseout_Setter_(mthis, __arg_0) => mthis["onmouseout"] = __arg_0;

  onmouseover_Getter_(mthis) => mthis["onmouseover"];

  onmouseover_Setter_(mthis, __arg_0) => mthis["onmouseover"] = __arg_0;

  onmouseup_Getter_(mthis) => mthis["onmouseup"];

  onmouseup_Setter_(mthis, __arg_0) => mthis["onmouseup"] = __arg_0;

  onmousewheel_Getter_(mthis) => mthis["onmousewheel"];

  onmousewheel_Setter_(mthis, __arg_0) => mthis["onmousewheel"] = __arg_0;

  onpaste_Getter_(mthis) => mthis["onpaste"];

  onpaste_Setter_(mthis, __arg_0) => mthis["onpaste"] = __arg_0;

  onpause_Getter_(mthis) => mthis["onpause"];

  onpause_Setter_(mthis, __arg_0) => mthis["onpause"] = __arg_0;

  onplay_Getter_(mthis) => mthis["onplay"];

  onplay_Setter_(mthis, __arg_0) => mthis["onplay"] = __arg_0;

  onplaying_Getter_(mthis) => mthis["onplaying"];

  onplaying_Setter_(mthis, __arg_0) => mthis["onplaying"] = __arg_0;

  onpointerlockchange_Getter_(mthis) => mthis["onpointerlockchange"];

  onpointerlockchange_Setter_(mthis, __arg_0) => mthis["onpointerlockchange"] = __arg_0;

  onpointerlockerror_Getter_(mthis) => mthis["onpointerlockerror"];

  onpointerlockerror_Setter_(mthis, __arg_0) => mthis["onpointerlockerror"] = __arg_0;

  onprogress_Getter_(mthis) => mthis["onprogress"];

  onprogress_Setter_(mthis, __arg_0) => mthis["onprogress"] = __arg_0;

  onratechange_Getter_(mthis) => mthis["onratechange"];

  onratechange_Setter_(mthis, __arg_0) => mthis["onratechange"] = __arg_0;

  onreadystatechange_Getter_(mthis) => mthis["onreadystatechange"];

  onreadystatechange_Setter_(mthis, __arg_0) => mthis["onreadystatechange"] = __arg_0;

  onreset_Getter_(mthis) => mthis["onreset"];

  onreset_Setter_(mthis, __arg_0) => mthis["onreset"] = __arg_0;

  onresize_Getter_(mthis) => mthis["onresize"];

  onresize_Setter_(mthis, __arg_0) => mthis["onresize"] = __arg_0;

  onscroll_Getter_(mthis) => mthis["onscroll"];

  onscroll_Setter_(mthis, __arg_0) => mthis["onscroll"] = __arg_0;

  onsearch_Getter_(mthis) => mthis["onsearch"];

  onsearch_Setter_(mthis, __arg_0) => mthis["onsearch"] = __arg_0;

  onsecuritypolicyviolation_Getter_(mthis) => mthis["onsecuritypolicyviolation"];

  onsecuritypolicyviolation_Setter_(mthis, __arg_0) => mthis["onsecuritypolicyviolation"] = __arg_0;

  onseeked_Getter_(mthis) => mthis["onseeked"];

  onseeked_Setter_(mthis, __arg_0) => mthis["onseeked"] = __arg_0;

  onseeking_Getter_(mthis) => mthis["onseeking"];

  onseeking_Setter_(mthis, __arg_0) => mthis["onseeking"] = __arg_0;

  onselect_Getter_(mthis) => mthis["onselect"];

  onselect_Setter_(mthis, __arg_0) => mthis["onselect"] = __arg_0;

  onselectionchange_Getter_(mthis) => mthis["onselectionchange"];

  onselectionchange_Setter_(mthis, __arg_0) => mthis["onselectionchange"] = __arg_0;

  onselectstart_Getter_(mthis) => mthis["onselectstart"];

  onselectstart_Setter_(mthis, __arg_0) => mthis["onselectstart"] = __arg_0;

  onshow_Getter_(mthis) => mthis["onshow"];

  onshow_Setter_(mthis, __arg_0) => mthis["onshow"] = __arg_0;

  onstalled_Getter_(mthis) => mthis["onstalled"];

  onstalled_Setter_(mthis, __arg_0) => mthis["onstalled"] = __arg_0;

  onsubmit_Getter_(mthis) => mthis["onsubmit"];

  onsubmit_Setter_(mthis, __arg_0) => mthis["onsubmit"] = __arg_0;

  onsuspend_Getter_(mthis) => mthis["onsuspend"];

  onsuspend_Setter_(mthis, __arg_0) => mthis["onsuspend"] = __arg_0;

  ontimeupdate_Getter_(mthis) => mthis["ontimeupdate"];

  ontimeupdate_Setter_(mthis, __arg_0) => mthis["ontimeupdate"] = __arg_0;

  ontoggle_Getter_(mthis) => mthis["ontoggle"];

  ontoggle_Setter_(mthis, __arg_0) => mthis["ontoggle"] = __arg_0;

  ontouchcancel_Getter_(mthis) => mthis["ontouchcancel"];

  ontouchcancel_Setter_(mthis, __arg_0) => mthis["ontouchcancel"] = __arg_0;

  ontouchend_Getter_(mthis) => mthis["ontouchend"];

  ontouchend_Setter_(mthis, __arg_0) => mthis["ontouchend"] = __arg_0;

  ontouchmove_Getter_(mthis) => mthis["ontouchmove"];

  ontouchmove_Setter_(mthis, __arg_0) => mthis["ontouchmove"] = __arg_0;

  ontouchstart_Getter_(mthis) => mthis["ontouchstart"];

  ontouchstart_Setter_(mthis, __arg_0) => mthis["ontouchstart"] = __arg_0;

  onvolumechange_Getter_(mthis) => mthis["onvolumechange"];

  onvolumechange_Setter_(mthis, __arg_0) => mthis["onvolumechange"] = __arg_0;

  onwaiting_Getter_(mthis) => mthis["onwaiting"];

  onwaiting_Setter_(mthis, __arg_0) => mthis["onwaiting"] = __arg_0;

  onwebkitfullscreenchange_Getter_(mthis) => mthis["onwebkitfullscreenchange"];

  onwebkitfullscreenchange_Setter_(mthis, __arg_0) => mthis["onwebkitfullscreenchange"] = __arg_0;

  onwebkitfullscreenerror_Getter_(mthis) => mthis["onwebkitfullscreenerror"];

  onwebkitfullscreenerror_Setter_(mthis, __arg_0) => mthis["onwebkitfullscreenerror"] = __arg_0;

  onwheel_Getter_(mthis) => mthis["onwheel"];

  onwheel_Setter_(mthis, __arg_0) => mthis["onwheel"] = __arg_0;

  plugins_Getter_(mthis) => mthis["plugins"];

  pointerLockElement_Getter_(mthis) => mthis["pointerLockElement"];

  preferredStylesheetSet_Getter_(mthis) => mthis["preferredStylesheetSet"];

  queryCommandEnabled_Callback_0_(mthis) => mthis.callMethod("queryCommandEnabled", []);

  queryCommandEnabled_Callback_1_(mthis, __arg_0) => mthis.callMethod("queryCommandEnabled", [__arg_0]);

  queryCommandIndeterm_Callback_0_(mthis) => mthis.callMethod("queryCommandIndeterm", []);

  queryCommandIndeterm_Callback_1_(mthis, __arg_0) => mthis.callMethod("queryCommandIndeterm", [__arg_0]);

  queryCommandState_Callback_0_(mthis) => mthis.callMethod("queryCommandState", []);

  queryCommandState_Callback_1_(mthis, __arg_0) => mthis.callMethod("queryCommandState", [__arg_0]);

  queryCommandSupported_Callback_0_(mthis) => mthis.callMethod("queryCommandSupported", []);

  queryCommandSupported_Callback_1_(mthis, __arg_0) => mthis.callMethod("queryCommandSupported", [__arg_0]);

  queryCommandValue_Callback_0_(mthis) => mthis.callMethod("queryCommandValue", []);

  queryCommandValue_Callback_1_(mthis, __arg_0) => mthis.callMethod("queryCommandValue", [__arg_0]);

  querySelectorAll_Callback_0_(mthis) => mthis.callMethod("querySelectorAll", []);

  querySelectorAll_Callback_1_(mthis, __arg_0) => mthis.callMethod("querySelectorAll", [__arg_0]);

  querySelector_Callback_0_(mthis) => mthis.callMethod("querySelector", []);

  querySelector_Callback_1_(mthis, __arg_0) => mthis.callMethod("querySelector", [__arg_0]);

  readyState_Getter_(mthis) => mthis["readyState"];

  referrer_Getter_(mthis) => mthis["referrer"];

  registerElement_Callback_0_(mthis) => mthis.callMethod("registerElement", []);

  registerElement_Callback_1_(mthis, __arg_0) => mthis.callMethod("registerElement", [__arg_0]);

  registerElement_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("registerElement", [__arg_0, __arg_1]);

  rootElement_Getter_(mthis) => mthis["rootElement"];

  scripts_Getter_(mthis) => mthis["scripts"];

  selectedStylesheetSet_Getter_(mthis) => mthis["selectedStylesheetSet"];

  selectedStylesheetSet_Setter_(mthis, __arg_0) => mthis["selectedStylesheetSet"] = __arg_0;

  styleSheets_Getter_(mthis) => mthis["styleSheets"];

  timeline_Getter_(mthis) => mthis["timeline"];

  title_Getter_(mthis) => mthis["title"];

  title_Setter_(mthis, __arg_0) => mthis["title"] = __arg_0;

  transformDocumentToTreeView_Callback_0_(mthis) => mthis.callMethod("transformDocumentToTreeView", []);

  transformDocumentToTreeView_Callback_1_(mthis, __arg_0) => mthis.callMethod("transformDocumentToTreeView", [__arg_0]);

  visibilityState_Getter_(mthis) => mthis["visibilityState"];

  webkitCancelFullScreen_Callback_0_(mthis) => mthis.callMethod("webkitCancelFullScreen", []);

  webkitExitFullscreen_Callback_0_(mthis) => mthis.callMethod("webkitExitFullscreen", []);

  webkitFullscreenElement_Getter_(mthis) => mthis["webkitFullscreenElement"];

  webkitFullscreenEnabled_Getter_(mthis) => mthis["webkitFullscreenEnabled"];

  webkitHidden_Getter_(mthis) => mthis["webkitHidden"];

  webkitIsFullScreen_Getter_(mthis) => mthis["webkitIsFullScreen"];

  webkitVisibilityState_Getter_(mthis) => mthis["webkitVisibilityState"];

  xmlEncoding_Getter_(mthis) => mthis["xmlEncoding"];

}

class BlinkDocumentFragment extends BlinkNode {
  static final instance = new BlinkDocumentFragment();

  childElementCount_Getter_(mthis) => mthis["childElementCount"];

  constructorCallback_0_() => new js.JsObject(js.context["DocumentFragment"], []);

  firstElementChild_Getter_(mthis) => mthis["firstElementChild"];

  getElementById_Callback_0_(mthis) => mthis.callMethod("getElementById", []);

  getElementById_Callback_1_(mthis, __arg_0) => mthis.callMethod("getElementById", [__arg_0]);

  lastElementChild_Getter_(mthis) => mthis["lastElementChild"];

  querySelectorAll_Callback_0_(mthis) => mthis.callMethod("querySelectorAll", []);

  querySelectorAll_Callback_1_(mthis, __arg_0) => mthis.callMethod("querySelectorAll", [__arg_0]);

  querySelector_Callback_0_(mthis) => mthis.callMethod("querySelector", []);

  querySelector_Callback_1_(mthis, __arg_0) => mthis.callMethod("querySelector", [__arg_0]);

}

class BlinkDocumentType extends BlinkNode {
  static final instance = new BlinkDocumentType();

}

class BlinkDynamicsCompressorNode extends BlinkAudioNode {
  static final instance = new BlinkDynamicsCompressorNode();

  attack_Getter_(mthis) => mthis["attack"];

  knee_Getter_(mthis) => mthis["knee"];

  ratio_Getter_(mthis) => mthis["ratio"];

  reduction_Getter_(mthis) => mthis["reduction"];

  release_Getter_(mthis) => mthis["release"];

  threshold_Getter_(mthis) => mthis["threshold"];

}

class BlinkEXTBlendMinMax {
  static final instance = new BlinkEXTBlendMinMax();

}

class BlinkEXTFragDepth {
  static final instance = new BlinkEXTFragDepth();

}

class BlinkEXTShaderTextureLOD {
  static final instance = new BlinkEXTShaderTextureLOD();

}

class BlinkEXTTextureFilterAnisotropic {
  static final instance = new BlinkEXTTextureFilterAnisotropic();

}

class BlinkElement extends BlinkNode {
  static final instance = new BlinkElement();

  animate_Callback_0_(mthis) => mthis.callMethod("animate", []);

  animate_Callback_1_(mthis, __arg_0) => mthis.callMethod("animate", [__arg_0]);

  animate_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("animate", [__arg_0, __arg_1]);

  attributes_Getter_(mthis) => mthis["attributes"];

  blur_Callback_0_(mthis) => mthis.callMethod("blur", []);

  childElementCount_Getter_(mthis) => mthis["childElementCount"];

  children_Getter_(mthis) => mthis["children"];

  classList_Getter_(mthis) => mthis["classList"];

  className_Getter_(mthis) => mthis["className"];

  className_Setter_(mthis, __arg_0) => mthis["className"] = __arg_0;

  clientHeight_Getter_(mthis) => mthis["clientHeight"];

  clientLeft_Getter_(mthis) => mthis["clientLeft"];

  clientTop_Getter_(mthis) => mthis["clientTop"];

  clientWidth_Getter_(mthis) => mthis["clientWidth"];

  createShadowRoot_Callback_0_(mthis) => mthis.callMethod("createShadowRoot", []);

  firstElementChild_Getter_(mthis) => mthis["firstElementChild"];

  focus_Callback_0_(mthis) => mthis.callMethod("focus", []);

  getAnimationPlayers_Callback_0_(mthis) => mthis.callMethod("getAnimationPlayers", []);

  getAttributeNS_Callback_0_(mthis) => mthis.callMethod("getAttributeNS", []);

  getAttributeNS_Callback_1_(mthis, __arg_0) => mthis.callMethod("getAttributeNS", [__arg_0]);

  getAttributeNS_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getAttributeNS", [__arg_0, __arg_1]);

  getAttribute_Callback_0_(mthis) => mthis.callMethod("getAttribute", []);

  getAttribute_Callback_1_(mthis, __arg_0) => mthis.callMethod("getAttribute", [__arg_0]);

  getBoundingClientRect_Callback_0_(mthis) => mthis.callMethod("getBoundingClientRect", []);

  getClientRects_Callback_0_(mthis) => mthis.callMethod("getClientRects", []);

  getDestinationInsertionPoints_Callback_0_(mthis) => mthis.callMethod("getDestinationInsertionPoints", []);

  getElementsByClassName_Callback_0_(mthis) => mthis.callMethod("getElementsByClassName", []);

  getElementsByClassName_Callback_1_(mthis, __arg_0) => mthis.callMethod("getElementsByClassName", [__arg_0]);

  getElementsByTagName_Callback_0_(mthis) => mthis.callMethod("getElementsByTagName", []);

  getElementsByTagName_Callback_1_(mthis, __arg_0) => mthis.callMethod("getElementsByTagName", [__arg_0]);

  hasAttributeNS_Callback_0_(mthis) => mthis.callMethod("hasAttributeNS", []);

  hasAttributeNS_Callback_1_(mthis, __arg_0) => mthis.callMethod("hasAttributeNS", [__arg_0]);

  hasAttributeNS_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("hasAttributeNS", [__arg_0, __arg_1]);

  hasAttribute_Callback_0_(mthis) => mthis.callMethod("hasAttribute", []);

  hasAttribute_Callback_1_(mthis, __arg_0) => mthis.callMethod("hasAttribute", [__arg_0]);

  hasAttributes_Callback_0_(mthis) => mthis.callMethod("hasAttributes", []);

  id_Getter_(mthis) => mthis["id"];

  id_Setter_(mthis, __arg_0) => mthis["id"] = __arg_0;

  innerHTML_Getter_(mthis) => mthis["innerHTML"];

  innerHTML_Setter_(mthis, __arg_0) => mthis["innerHTML"] = __arg_0;

  insertAdjacentElement_Callback_0_(mthis) => mthis.callMethod("insertAdjacentElement", []);

  insertAdjacentElement_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertAdjacentElement", [__arg_0]);

  insertAdjacentElement_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("insertAdjacentElement", [__arg_0, __arg_1]);

  insertAdjacentHTML_Callback_0_(mthis) => mthis.callMethod("insertAdjacentHTML", []);

  insertAdjacentHTML_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertAdjacentHTML", [__arg_0]);

  insertAdjacentHTML_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("insertAdjacentHTML", [__arg_0, __arg_1]);

  insertAdjacentText_Callback_0_(mthis) => mthis.callMethod("insertAdjacentText", []);

  insertAdjacentText_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertAdjacentText", [__arg_0]);

  insertAdjacentText_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("insertAdjacentText", [__arg_0, __arg_1]);

  lastElementChild_Getter_(mthis) => mthis["lastElementChild"];

  localName_Getter_(mthis) => mthis["localName"];

  matches_Callback_0_(mthis) => mthis.callMethod("matches", []);

  matches_Callback_1_(mthis, __arg_0) => mthis.callMethod("matches", [__arg_0]);

  namespaceURI_Getter_(mthis) => mthis["namespaceURI"];

  nextElementSibling_Getter_(mthis) => mthis["nextElementSibling"];

  offsetHeight_Getter_(mthis) => mthis["offsetHeight"];

  offsetLeft_Getter_(mthis) => mthis["offsetLeft"];

  offsetParent_Getter_(mthis) => mthis["offsetParent"];

  offsetTop_Getter_(mthis) => mthis["offsetTop"];

  offsetWidth_Getter_(mthis) => mthis["offsetWidth"];

  onbeforecopy_Getter_(mthis) => mthis["onbeforecopy"];

  onbeforecopy_Setter_(mthis, __arg_0) => mthis["onbeforecopy"] = __arg_0;

  onbeforecut_Getter_(mthis) => mthis["onbeforecut"];

  onbeforecut_Setter_(mthis, __arg_0) => mthis["onbeforecut"] = __arg_0;

  onbeforepaste_Getter_(mthis) => mthis["onbeforepaste"];

  onbeforepaste_Setter_(mthis, __arg_0) => mthis["onbeforepaste"] = __arg_0;

  oncopy_Getter_(mthis) => mthis["oncopy"];

  oncopy_Setter_(mthis, __arg_0) => mthis["oncopy"] = __arg_0;

  oncut_Getter_(mthis) => mthis["oncut"];

  oncut_Setter_(mthis, __arg_0) => mthis["oncut"] = __arg_0;

  onpaste_Getter_(mthis) => mthis["onpaste"];

  onpaste_Setter_(mthis, __arg_0) => mthis["onpaste"] = __arg_0;

  onsearch_Getter_(mthis) => mthis["onsearch"];

  onsearch_Setter_(mthis, __arg_0) => mthis["onsearch"] = __arg_0;

  onselectstart_Getter_(mthis) => mthis["onselectstart"];

  onselectstart_Setter_(mthis, __arg_0) => mthis["onselectstart"] = __arg_0;

  ontouchcancel_Getter_(mthis) => mthis["ontouchcancel"];

  ontouchcancel_Setter_(mthis, __arg_0) => mthis["ontouchcancel"] = __arg_0;

  ontouchend_Getter_(mthis) => mthis["ontouchend"];

  ontouchend_Setter_(mthis, __arg_0) => mthis["ontouchend"] = __arg_0;

  ontouchmove_Getter_(mthis) => mthis["ontouchmove"];

  ontouchmove_Setter_(mthis, __arg_0) => mthis["ontouchmove"] = __arg_0;

  ontouchstart_Getter_(mthis) => mthis["ontouchstart"];

  ontouchstart_Setter_(mthis, __arg_0) => mthis["ontouchstart"] = __arg_0;

  onwebkitfullscreenchange_Getter_(mthis) => mthis["onwebkitfullscreenchange"];

  onwebkitfullscreenchange_Setter_(mthis, __arg_0) => mthis["onwebkitfullscreenchange"] = __arg_0;

  onwebkitfullscreenerror_Getter_(mthis) => mthis["onwebkitfullscreenerror"];

  onwebkitfullscreenerror_Setter_(mthis, __arg_0) => mthis["onwebkitfullscreenerror"] = __arg_0;

  onwheel_Getter_(mthis) => mthis["onwheel"];

  onwheel_Setter_(mthis, __arg_0) => mthis["onwheel"] = __arg_0;

  outerHTML_Getter_(mthis) => mthis["outerHTML"];

  outerHTML_Setter_(mthis, __arg_0) => mthis["outerHTML"] = __arg_0;

  prefix_Getter_(mthis) => mthis["prefix"];

  prefix_Setter_(mthis, __arg_0) => mthis["prefix"] = __arg_0;

  previousElementSibling_Getter_(mthis) => mthis["previousElementSibling"];

  querySelectorAll_Callback_0_(mthis) => mthis.callMethod("querySelectorAll", []);

  querySelectorAll_Callback_1_(mthis, __arg_0) => mthis.callMethod("querySelectorAll", [__arg_0]);

  querySelector_Callback_0_(mthis) => mthis.callMethod("querySelector", []);

  querySelector_Callback_1_(mthis, __arg_0) => mthis.callMethod("querySelector", [__arg_0]);

  removeAttributeNS_Callback_0_(mthis) => mthis.callMethod("removeAttributeNS", []);

  removeAttributeNS_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeAttributeNS", [__arg_0]);

  removeAttributeNS_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("removeAttributeNS", [__arg_0, __arg_1]);

  removeAttribute_Callback_0_(mthis) => mthis.callMethod("removeAttribute", []);

  removeAttribute_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeAttribute", [__arg_0]);

  remove_Callback_0_(mthis) => mthis.callMethod("remove", []);

  requestFullscreen_Callback_0_(mthis) => mthis.callMethod("requestFullscreen", []);

  requestPointerLock_Callback_0_(mthis) => mthis.callMethod("requestPointerLock", []);

  scrollHeight_Getter_(mthis) => mthis["scrollHeight"];

  scrollIntoViewIfNeeded_Callback_0_(mthis) => mthis.callMethod("scrollIntoViewIfNeeded", []);

  scrollIntoViewIfNeeded_Callback_1_(mthis, __arg_0) => mthis.callMethod("scrollIntoViewIfNeeded", [__arg_0]);

  scrollIntoView_Callback_0_(mthis) => mthis.callMethod("scrollIntoView", []);

  scrollIntoView_Callback_1_(mthis, __arg_0) => mthis.callMethod("scrollIntoView", [__arg_0]);

  scrollLeft_Getter_(mthis) => mthis["scrollLeft"];

  scrollLeft_Setter_(mthis, __arg_0) => mthis["scrollLeft"] = __arg_0;

  scrollTop_Getter_(mthis) => mthis["scrollTop"];

  scrollTop_Setter_(mthis, __arg_0) => mthis["scrollTop"] = __arg_0;

  scrollWidth_Getter_(mthis) => mthis["scrollWidth"];

  setAttributeNS_Callback_1_(mthis, __arg_0) => mthis.callMethod("setAttributeNS", [__arg_0]);

  setAttributeNS_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setAttributeNS", [__arg_0, __arg_1]);

  setAttributeNS_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setAttributeNS", [__arg_0, __arg_1, __arg_2]);

  setAttribute_Callback_0_(mthis) => mthis.callMethod("setAttribute", []);

  setAttribute_Callback_1_(mthis, __arg_0) => mthis.callMethod("setAttribute", [__arg_0]);

  setAttribute_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setAttribute", [__arg_0, __arg_1]);

  shadowRoot_Getter_(mthis) => mthis["shadowRoot"];

  style_Getter_(mthis) => mthis["style"];

  tagName_Getter_(mthis) => mthis["tagName"];

  webkitRequestFullScreen_Callback_0_(mthis) => mthis.callMethod("webkitRequestFullScreen", []);

  webkitRequestFullScreen_Callback_1_(mthis, __arg_0) => mthis.callMethod("webkitRequestFullScreen", [__arg_0]);

  webkitRequestFullscreen_Callback_0_(mthis) => mthis.callMethod("webkitRequestFullscreen", []);

}

class BlinkEntry {
  static final instance = new BlinkEntry();

  copyTo_Callback_0_(mthis) => mthis.callMethod("copyTo", []);

  copyTo_Callback_1_(mthis, __arg_0) => mthis.callMethod("copyTo", [__arg_0]);

  copyTo_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("copyTo", [__arg_0, __arg_1]);

  copyTo_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("copyTo", [__arg_0, __arg_1, __arg_2]);

  copyTo_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("copyTo", [__arg_0, __arg_1, __arg_2, __arg_3]);

  filesystem_Getter_(mthis) => mthis["filesystem"];

  fullPath_Getter_(mthis) => mthis["fullPath"];

  getMetadata_Callback_0_(mthis) => mthis.callMethod("getMetadata", []);

  getMetadata_Callback_1_(mthis, __arg_0) => mthis.callMethod("getMetadata", [__arg_0]);

  getMetadata_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getMetadata", [__arg_0, __arg_1]);

  getParent_Callback_0_(mthis) => mthis.callMethod("getParent", []);

  getParent_Callback_1_(mthis, __arg_0) => mthis.callMethod("getParent", [__arg_0]);

  getParent_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getParent", [__arg_0, __arg_1]);

  isDirectory_Getter_(mthis) => mthis["isDirectory"];

  isFile_Getter_(mthis) => mthis["isFile"];

  moveTo_Callback_0_(mthis) => mthis.callMethod("moveTo", []);

  moveTo_Callback_1_(mthis, __arg_0) => mthis.callMethod("moveTo", [__arg_0]);

  moveTo_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("moveTo", [__arg_0, __arg_1]);

  moveTo_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("moveTo", [__arg_0, __arg_1, __arg_2]);

  moveTo_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("moveTo", [__arg_0, __arg_1, __arg_2, __arg_3]);

  name_Getter_(mthis) => mthis["name"];

  remove_Callback_0_(mthis) => mthis.callMethod("remove", []);

  remove_Callback_1_(mthis, __arg_0) => mthis.callMethod("remove", [__arg_0]);

  remove_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("remove", [__arg_0, __arg_1]);

  toURL_Callback_0_(mthis) => mthis.callMethod("toURL", []);

}

class BlinkEntrySync {
  static final instance = new BlinkEntrySync();

  copyTo_Callback_0_(mthis) => mthis.callMethod("copyTo", []);

  copyTo_Callback_1_(mthis, __arg_0) => mthis.callMethod("copyTo", [__arg_0]);

  copyTo_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("copyTo", [__arg_0, __arg_1]);

  filesystem_Getter_(mthis) => mthis["filesystem"];

  fullPath_Getter_(mthis) => mthis["fullPath"];

  getMetadata_Callback_0_(mthis) => mthis.callMethod("getMetadata", []);

  getParent_Callback_0_(mthis) => mthis.callMethod("getParent", []);

  isDirectory_Getter_(mthis) => mthis["isDirectory"];

  isFile_Getter_(mthis) => mthis["isFile"];

  moveTo_Callback_0_(mthis) => mthis.callMethod("moveTo", []);

  moveTo_Callback_1_(mthis, __arg_0) => mthis.callMethod("moveTo", [__arg_0]);

  moveTo_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("moveTo", [__arg_0, __arg_1]);

  name_Getter_(mthis) => mthis["name"];

  remove_Callback_0_(mthis) => mthis.callMethod("remove", []);

  toURL_Callback_0_(mthis) => mthis.callMethod("toURL", []);

}

class BlinkErrorEvent extends BlinkEvent {
  static final instance = new BlinkErrorEvent();

  colno_Getter_(mthis) => mthis["colno"];

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["ErrorEvent"], [__arg_0, __arg_1]);

  error_Getter_(mthis) => mthis["error"];

  filename_Getter_(mthis) => mthis["filename"];

  lineno_Getter_(mthis) => mthis["lineno"];

  message_Getter_(mthis) => mthis["message"];

}

class BlinkEvent {
  static final instance = new BlinkEvent();

  bubbles_Getter_(mthis) => mthis["bubbles"];

  cancelBubble_Getter_(mthis) => mthis["cancelBubble"];

  cancelBubble_Setter_(mthis, __arg_0) => mthis["cancelBubble"] = __arg_0;

  cancelable_Getter_(mthis) => mthis["cancelable"];

  clipboardData_Getter_(mthis) => mthis["clipboardData"];

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["Event"], [__arg_0, __arg_1]);

  currentTarget_Getter_(mthis) => mthis["currentTarget"];

  defaultPrevented_Getter_(mthis) => mthis["defaultPrevented"];

  eventPhase_Getter_(mthis) => mthis["eventPhase"];

  initEvent_Callback_0_(mthis) => mthis.callMethod("initEvent", []);

  initEvent_Callback_1_(mthis, __arg_0) => mthis.callMethod("initEvent", [__arg_0]);

  initEvent_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("initEvent", [__arg_0, __arg_1]);

  initEvent_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("initEvent", [__arg_0, __arg_1, __arg_2]);

  path_Getter_(mthis) => mthis["path"];

  preventDefault_Callback_0_(mthis) => mthis.callMethod("preventDefault", []);

  returnValue_Getter_(mthis) => mthis["returnValue"];

  returnValue_Setter_(mthis, __arg_0) => mthis["returnValue"] = __arg_0;

  stopImmediatePropagation_Callback_0_(mthis) => mthis.callMethod("stopImmediatePropagation", []);

  stopPropagation_Callback_0_(mthis) => mthis.callMethod("stopPropagation", []);

  target_Getter_(mthis) => mthis["target"];

  timeStamp_Getter_(mthis) => mthis["timeStamp"];

  type_Getter_(mthis) => mthis["type"];

}

class BlinkEventSource extends BlinkEventTarget {
  static final instance = new BlinkEventSource();

  close_Callback_0_(mthis) => mthis.callMethod("close", []);

  constructorCallback_0_() => new js.JsObject(js.context["EventSource"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["EventSource"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["EventSource"], [__arg_0, __arg_1]);

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onmessage_Getter_(mthis) => mthis["onmessage"];

  onmessage_Setter_(mthis, __arg_0) => mthis["onmessage"] = __arg_0;

  onopen_Getter_(mthis) => mthis["onopen"];

  onopen_Setter_(mthis, __arg_0) => mthis["onopen"] = __arg_0;

  readyState_Getter_(mthis) => mthis["readyState"];

  url_Getter_(mthis) => mthis["url"];

  withCredentials_Getter_(mthis) => mthis["withCredentials"];

}

class BlinkEventTarget {
  static final instance = new BlinkEventTarget();

  addEventListener_Callback_0_(mthis) => mthis.callMethod("addEventListener", []);

  addEventListener_Callback_1_(mthis, __arg_0) => mthis.callMethod("addEventListener", [__arg_0]);

  addEventListener_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("addEventListener", [__arg_0, __arg_1]);

  addEventListener_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("addEventListener", [__arg_0, __arg_1, __arg_2]);

  dispatchEvent_Callback_0_(mthis) => mthis.callMethod("dispatchEvent", []);

  dispatchEvent_Callback_1_(mthis, __arg_0) => mthis.callMethod("dispatchEvent", [__arg_0]);

  removeEventListener_Callback_0_(mthis) => mthis.callMethod("removeEventListener", []);

  removeEventListener_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeEventListener", [__arg_0]);

  removeEventListener_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("removeEventListener", [__arg_0, __arg_1]);

  removeEventListener_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("removeEventListener", [__arg_0, __arg_1, __arg_2]);

}

class BlinkExtendableEvent extends BlinkEvent {
  static final instance = new BlinkExtendableEvent();

  waitUntil_Callback_0_(mthis) => mthis.callMethod("waitUntil", []);

  waitUntil_Callback_1_(mthis, __arg_0) => mthis.callMethod("waitUntil", [__arg_0]);

}

class BlinkFederatedCredential extends BlinkCredential {
  static final instance = new BlinkFederatedCredential();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["FederatedCredential"], [__arg_0, __arg_1]);

  constructorCallback_3_(__arg_0, __arg_1, __arg_2) => new js.JsObject(js.context["FederatedCredential"], [__arg_0, __arg_1, __arg_2]);

  constructorCallback_4_(__arg_0, __arg_1, __arg_2, __arg_3) => new js.JsObject(js.context["FederatedCredential"], [__arg_0, __arg_1, __arg_2, __arg_3]);

  federation_Getter_(mthis) => mthis["federation"];

}

class BlinkFetchEvent extends BlinkEvent {
  static final instance = new BlinkFetchEvent();

  isReload_Getter_(mthis) => mthis["isReload"];

  request_Getter_(mthis) => mthis["request"];

  respondWith_Callback_0_(mthis) => mthis.callMethod("respondWith", []);

  respondWith_Callback_1_(mthis, __arg_0) => mthis.callMethod("respondWith", [__arg_0]);

}

class BlinkFile extends BlinkBlob {
  static final instance = new BlinkFile();

  constructorCallback_0_() => new js.JsObject(js.context["File"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["File"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["File"], [__arg_0, __arg_1]);

  constructorCallback_3_(__arg_0, __arg_1, __arg_2) => new js.JsObject(js.context["File"], [__arg_0, __arg_1, __arg_2]);

  lastModifiedDate_Getter_(mthis) => mthis["lastModifiedDate"];

  lastModified_Getter_(mthis) => mthis["lastModified"];

  name_Getter_(mthis) => mthis["name"];

  webkitRelativePath_Getter_(mthis) => mthis["webkitRelativePath"];

}

class BlinkFileEntry extends BlinkEntry {
  static final instance = new BlinkFileEntry();

  createWriter_Callback_0_(mthis) => mthis.callMethod("createWriter", []);

  createWriter_Callback_1_(mthis, __arg_0) => mthis.callMethod("createWriter", [__arg_0]);

  createWriter_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createWriter", [__arg_0, __arg_1]);

  file_Callback_0_(mthis) => mthis.callMethod("file", []);

  file_Callback_1_(mthis, __arg_0) => mthis.callMethod("file", [__arg_0]);

  file_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("file", [__arg_0, __arg_1]);

}

class BlinkFileEntrySync extends BlinkEntrySync {
  static final instance = new BlinkFileEntrySync();

  createWriter_Callback_0_(mthis) => mthis.callMethod("createWriter", []);

  file_Callback_0_(mthis) => mthis.callMethod("file", []);

}

class BlinkFileError extends BlinkDOMError {
  static final instance = new BlinkFileError();

  code_Getter_(mthis) => mthis["code"];

}

class BlinkFileList {
  static final instance = new BlinkFileList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

}

class BlinkFileReader extends BlinkEventTarget {
  static final instance = new BlinkFileReader();

  abort_Callback_0_(mthis) => mthis.callMethod("abort", []);

  constructorCallback_0_() => new js.JsObject(js.context["FileReader"], []);

  error_Getter_(mthis) => mthis["error"];

  onabort_Getter_(mthis) => mthis["onabort"];

  onabort_Setter_(mthis, __arg_0) => mthis["onabort"] = __arg_0;

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onload_Getter_(mthis) => mthis["onload"];

  onload_Setter_(mthis, __arg_0) => mthis["onload"] = __arg_0;

  onloadend_Getter_(mthis) => mthis["onloadend"];

  onloadend_Setter_(mthis, __arg_0) => mthis["onloadend"] = __arg_0;

  onloadstart_Getter_(mthis) => mthis["onloadstart"];

  onloadstart_Setter_(mthis, __arg_0) => mthis["onloadstart"] = __arg_0;

  onprogress_Getter_(mthis) => mthis["onprogress"];

  onprogress_Setter_(mthis, __arg_0) => mthis["onprogress"] = __arg_0;

  readAsArrayBuffer_Callback_0_(mthis) => mthis.callMethod("readAsArrayBuffer", []);

  readAsArrayBuffer_Callback_1_(mthis, __arg_0) => mthis.callMethod("readAsArrayBuffer", [__arg_0]);

  readAsBinaryString_Callback_0_(mthis) => mthis.callMethod("readAsBinaryString", []);

  readAsBinaryString_Callback_1_(mthis, __arg_0) => mthis.callMethod("readAsBinaryString", [__arg_0]);

  readAsDataURL_Callback_0_(mthis) => mthis.callMethod("readAsDataURL", []);

  readAsDataURL_Callback_1_(mthis, __arg_0) => mthis.callMethod("readAsDataURL", [__arg_0]);

  readAsText_Callback_0_(mthis) => mthis.callMethod("readAsText", []);

  readAsText_Callback_1_(mthis, __arg_0) => mthis.callMethod("readAsText", [__arg_0]);

  readAsText_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("readAsText", [__arg_0, __arg_1]);

  readyState_Getter_(mthis) => mthis["readyState"];

  result_Getter_(mthis) => mthis["result"];

}

class BlinkFileReaderSync {
  static final instance = new BlinkFileReaderSync();

  constructorCallback_0_() => new js.JsObject(js.context["FileReaderSync"], []);

  readAsArrayBuffer_Callback_0_(mthis) => mthis.callMethod("readAsArrayBuffer", []);

  readAsArrayBuffer_Callback_1_(mthis, __arg_0) => mthis.callMethod("readAsArrayBuffer", [__arg_0]);

  readAsBinaryString_Callback_0_(mthis) => mthis.callMethod("readAsBinaryString", []);

  readAsBinaryString_Callback_1_(mthis, __arg_0) => mthis.callMethod("readAsBinaryString", [__arg_0]);

  readAsDataURL_Callback_0_(mthis) => mthis.callMethod("readAsDataURL", []);

  readAsDataURL_Callback_1_(mthis, __arg_0) => mthis.callMethod("readAsDataURL", [__arg_0]);

  readAsText_Callback_0_(mthis) => mthis.callMethod("readAsText", []);

  readAsText_Callback_1_(mthis, __arg_0) => mthis.callMethod("readAsText", [__arg_0]);

  readAsText_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("readAsText", [__arg_0, __arg_1]);

}

class BlinkFileWriter extends BlinkEventTarget {
  static final instance = new BlinkFileWriter();

  abort_Callback_0_(mthis) => mthis.callMethod("abort", []);

  error_Getter_(mthis) => mthis["error"];

  length_Getter_(mthis) => mthis["length"];

  onabort_Getter_(mthis) => mthis["onabort"];

  onabort_Setter_(mthis, __arg_0) => mthis["onabort"] = __arg_0;

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onprogress_Getter_(mthis) => mthis["onprogress"];

  onprogress_Setter_(mthis, __arg_0) => mthis["onprogress"] = __arg_0;

  onwrite_Getter_(mthis) => mthis["onwrite"];

  onwrite_Setter_(mthis, __arg_0) => mthis["onwrite"] = __arg_0;

  onwriteend_Getter_(mthis) => mthis["onwriteend"];

  onwriteend_Setter_(mthis, __arg_0) => mthis["onwriteend"] = __arg_0;

  onwritestart_Getter_(mthis) => mthis["onwritestart"];

  onwritestart_Setter_(mthis, __arg_0) => mthis["onwritestart"] = __arg_0;

  position_Getter_(mthis) => mthis["position"];

  readyState_Getter_(mthis) => mthis["readyState"];

  seek_Callback_0_(mthis) => mthis.callMethod("seek", []);

  seek_Callback_1_(mthis, __arg_0) => mthis.callMethod("seek", [__arg_0]);

  truncate_Callback_0_(mthis) => mthis.callMethod("truncate", []);

  truncate_Callback_1_(mthis, __arg_0) => mthis.callMethod("truncate", [__arg_0]);

  write_Callback_0_(mthis) => mthis.callMethod("write", []);

  write_Callback_1_(mthis, __arg_0) => mthis.callMethod("write", [__arg_0]);

}

class BlinkFileWriterSync {
  static final instance = new BlinkFileWriterSync();

  length_Getter_(mthis) => mthis["length"];

  position_Getter_(mthis) => mthis["position"];

  seek_Callback_0_(mthis) => mthis.callMethod("seek", []);

  seek_Callback_1_(mthis, __arg_0) => mthis.callMethod("seek", [__arg_0]);

  truncate_Callback_0_(mthis) => mthis.callMethod("truncate", []);

  truncate_Callback_1_(mthis, __arg_0) => mthis.callMethod("truncate", [__arg_0]);

  write_Callback_0_(mthis) => mthis.callMethod("write", []);

  write_Callback_1_(mthis, __arg_0) => mthis.callMethod("write", [__arg_0]);

}

class BlinkFocusEvent extends BlinkUIEvent {
  static final instance = new BlinkFocusEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["FocusEvent"], [__arg_0, __arg_1]);

  relatedTarget_Getter_(mthis) => mthis["relatedTarget"];

}

class BlinkFontFace {
  static final instance = new BlinkFontFace();

  constructorCallback_0_() => new js.JsObject(js.context["FontFace"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["FontFace"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["FontFace"], [__arg_0, __arg_1]);

  constructorCallback_3_(__arg_0, __arg_1, __arg_2) => new js.JsObject(js.context["FontFace"], [__arg_0, __arg_1, __arg_2]);

  family_Getter_(mthis) => mthis["family"];

  family_Setter_(mthis, __arg_0) => mthis["family"] = __arg_0;

  featureSettings_Getter_(mthis) => mthis["featureSettings"];

  featureSettings_Setter_(mthis, __arg_0) => mthis["featureSettings"] = __arg_0;

  load_Callback_0_(mthis) => mthis.callMethod("load", []);

  loaded_Getter_(mthis) => mthis["loaded"];

  status_Getter_(mthis) => mthis["status"];

  stretch_Getter_(mthis) => mthis["stretch"];

  stretch_Setter_(mthis, __arg_0) => mthis["stretch"] = __arg_0;

  style_Getter_(mthis) => mthis["style"];

  style_Setter_(mthis, __arg_0) => mthis["style"] = __arg_0;

  unicodeRange_Getter_(mthis) => mthis["unicodeRange"];

  unicodeRange_Setter_(mthis, __arg_0) => mthis["unicodeRange"] = __arg_0;

  variant_Getter_(mthis) => mthis["variant"];

  variant_Setter_(mthis, __arg_0) => mthis["variant"] = __arg_0;

  weight_Getter_(mthis) => mthis["weight"];

  weight_Setter_(mthis, __arg_0) => mthis["weight"] = __arg_0;

}

class BlinkFontFaceSet extends BlinkEventTarget {
  static final instance = new BlinkFontFaceSet();

  add_Callback_0_(mthis) => mthis.callMethod("add", []);

  add_Callback_1_(mthis, __arg_0) => mthis.callMethod("add", [__arg_0]);

  check_Callback_0_(mthis) => mthis.callMethod("check", []);

  check_Callback_1_(mthis, __arg_0) => mthis.callMethod("check", [__arg_0]);

  check_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("check", [__arg_0, __arg_1]);

  clear_Callback_0_(mthis) => mthis.callMethod("clear", []);

  delete_Callback_0_(mthis) => mthis.callMethod("delete", []);

  delete_Callback_1_(mthis, __arg_0) => mthis.callMethod("delete", [__arg_0]);

  forEach_Callback_0_(mthis) => mthis.callMethod("forEach", []);

  forEach_Callback_1_(mthis, __arg_0) => mthis.callMethod("forEach", [__arg_0]);

  forEach_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("forEach", [__arg_0, __arg_1]);

  has_Callback_0_(mthis) => mthis.callMethod("has", []);

  has_Callback_1_(mthis, __arg_0) => mthis.callMethod("has", [__arg_0]);

  onloading_Getter_(mthis) => mthis["onloading"];

  onloading_Setter_(mthis, __arg_0) => mthis["onloading"] = __arg_0;

  onloadingdone_Getter_(mthis) => mthis["onloadingdone"];

  onloadingdone_Setter_(mthis, __arg_0) => mthis["onloadingdone"] = __arg_0;

  onloadingerror_Getter_(mthis) => mthis["onloadingerror"];

  onloadingerror_Setter_(mthis, __arg_0) => mthis["onloadingerror"] = __arg_0;

  size_Getter_(mthis) => mthis["size"];

  status_Getter_(mthis) => mthis["status"];

}

class BlinkFontFaceSetLoadEvent extends BlinkEvent {
  static final instance = new BlinkFontFaceSetLoadEvent();

  fontfaces_Getter_(mthis) => mthis["fontfaces"];

}

class BlinkFormData {
  static final instance = new BlinkFormData();

  append_Callback_0_(mthis) => mthis.callMethod("append", []);

  append_Callback_1_(mthis, __arg_0) => mthis.callMethod("append", [__arg_0]);

  append_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("append", [__arg_0, __arg_1]);

  append_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("append", [__arg_0, __arg_1, __arg_2]);

  constructorCallback_0_() => new js.JsObject(js.context["FormData"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["FormData"], [__arg_0]);

}

class BlinkGainNode extends BlinkAudioNode {
  static final instance = new BlinkGainNode();

  gain_Getter_(mthis) => mthis["gain"];

}

class BlinkGamepad {
  static final instance = new BlinkGamepad();

  axes_Getter_(mthis) => mthis["axes"];

  connected_Getter_(mthis) => mthis["connected"];

  id_Getter_(mthis) => mthis["id"];

  index_Getter_(mthis) => mthis["index"];

  mapping_Getter_(mthis) => mthis["mapping"];

  timestamp_Getter_(mthis) => mthis["timestamp"];

}

class BlinkGamepadButton {
  static final instance = new BlinkGamepadButton();

  pressed_Getter_(mthis) => mthis["pressed"];

  value_Getter_(mthis) => mthis["value"];

}

class BlinkGamepadEvent extends BlinkEvent {
  static final instance = new BlinkGamepadEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["GamepadEvent"], [__arg_0, __arg_1]);

  gamepad_Getter_(mthis) => mthis["gamepad"];

}

class BlinkGamepadList {
  static final instance = new BlinkGamepadList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

}

class BlinkGeofencing {
  static final instance = new BlinkGeofencing();

  getRegisteredRegions_Callback_0_(mthis) => mthis.callMethod("getRegisteredRegions", []);

  registerRegion_Callback_0_(mthis) => mthis.callMethod("registerRegion", []);

  registerRegion_Callback_1_(mthis, __arg_0) => mthis.callMethod("registerRegion", [__arg_0]);

  unregisterRegion_Callback_0_(mthis) => mthis.callMethod("unregisterRegion", []);

  unregisterRegion_Callback_1_(mthis, __arg_0) => mthis.callMethod("unregisterRegion", [__arg_0]);

}

class BlinkGeofencingRegion {
  static final instance = new BlinkGeofencingRegion();

  id_Getter_(mthis) => mthis["id"];

}

class BlinkGeolocation {
  static final instance = new BlinkGeolocation();

  clearWatch_Callback_0_(mthis) => mthis.callMethod("clearWatch", []);

  clearWatch_Callback_1_(mthis, __arg_0) => mthis.callMethod("clearWatch", [__arg_0]);

  getCurrentPosition_Callback_0_(mthis) => mthis.callMethod("getCurrentPosition", []);

  getCurrentPosition_Callback_1_(mthis, __arg_0) => mthis.callMethod("getCurrentPosition", [__arg_0]);

  getCurrentPosition_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getCurrentPosition", [__arg_0, __arg_1]);

  getCurrentPosition_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("getCurrentPosition", [__arg_0, __arg_1, __arg_2]);

  watchPosition_Callback_0_(mthis) => mthis.callMethod("watchPosition", []);

  watchPosition_Callback_1_(mthis, __arg_0) => mthis.callMethod("watchPosition", [__arg_0]);

  watchPosition_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("watchPosition", [__arg_0, __arg_1]);

  watchPosition_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("watchPosition", [__arg_0, __arg_1, __arg_2]);

}

class BlinkGeoposition {
  static final instance = new BlinkGeoposition();

  coords_Getter_(mthis) => mthis["coords"];

  timestamp_Getter_(mthis) => mthis["timestamp"];

}

class BlinkHTMLAllCollection {
  static final instance = new BlinkHTMLAllCollection();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

  namedItem_Callback_0_(mthis) => mthis.callMethod("namedItem", []);

  namedItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("namedItem", [__arg_0]);

}

class BlinkHTMLAnchorElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLAnchorElement();

  download_Getter_(mthis) => mthis["download"];

  download_Setter_(mthis, __arg_0) => mthis["download"] = __arg_0;

  hash_Getter_(mthis) => mthis["hash"];

  hash_Setter_(mthis, __arg_0) => mthis["hash"] = __arg_0;

  host_Getter_(mthis) => mthis["host"];

  host_Setter_(mthis, __arg_0) => mthis["host"] = __arg_0;

  hostname_Getter_(mthis) => mthis["hostname"];

  hostname_Setter_(mthis, __arg_0) => mthis["hostname"] = __arg_0;

  href_Getter_(mthis) => mthis["href"];

  href_Setter_(mthis, __arg_0) => mthis["href"] = __arg_0;

  hreflang_Getter_(mthis) => mthis["hreflang"];

  hreflang_Setter_(mthis, __arg_0) => mthis["hreflang"] = __arg_0;

  integrity_Getter_(mthis) => mthis["integrity"];

  integrity_Setter_(mthis, __arg_0) => mthis["integrity"] = __arg_0;

  name_Getter_(mthis) => mthis["name"];

  name_Setter_(mthis, __arg_0) => mthis["name"] = __arg_0;

  origin_Getter_(mthis) => mthis["origin"];

  password_Getter_(mthis) => mthis["password"];

  password_Setter_(mthis, __arg_0) => mthis["password"] = __arg_0;

  pathname_Getter_(mthis) => mthis["pathname"];

  pathname_Setter_(mthis, __arg_0) => mthis["pathname"] = __arg_0;

  ping_Getter_(mthis) => mthis["ping"];

  ping_Setter_(mthis, __arg_0) => mthis["ping"] = __arg_0;

  port_Getter_(mthis) => mthis["port"];

  port_Setter_(mthis, __arg_0) => mthis["port"] = __arg_0;

  protocol_Getter_(mthis) => mthis["protocol"];

  protocol_Setter_(mthis, __arg_0) => mthis["protocol"] = __arg_0;

  rel_Getter_(mthis) => mthis["rel"];

  rel_Setter_(mthis, __arg_0) => mthis["rel"] = __arg_0;

  search_Getter_(mthis) => mthis["search"];

  search_Setter_(mthis, __arg_0) => mthis["search"] = __arg_0;

  target_Getter_(mthis) => mthis["target"];

  target_Setter_(mthis, __arg_0) => mthis["target"] = __arg_0;

  toString_Callback_0_(mthis) => mthis.callMethod("toString", []);

  type_Getter_(mthis) => mthis["type"];

  type_Setter_(mthis, __arg_0) => mthis["type"] = __arg_0;

  username_Getter_(mthis) => mthis["username"];

  username_Setter_(mthis, __arg_0) => mthis["username"] = __arg_0;

}

class BlinkHTMLAppletElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLAppletElement();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  $__setter___Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("__setter__", [__arg_0, __arg_1]);

}

class BlinkHTMLAreaElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLAreaElement();

  alt_Getter_(mthis) => mthis["alt"];

  alt_Setter_(mthis, __arg_0) => mthis["alt"] = __arg_0;

  coords_Getter_(mthis) => mthis["coords"];

  coords_Setter_(mthis, __arg_0) => mthis["coords"] = __arg_0;

  hash_Getter_(mthis) => mthis["hash"];

  hash_Setter_(mthis, __arg_0) => mthis["hash"] = __arg_0;

  host_Getter_(mthis) => mthis["host"];

  host_Setter_(mthis, __arg_0) => mthis["host"] = __arg_0;

  hostname_Getter_(mthis) => mthis["hostname"];

  hostname_Setter_(mthis, __arg_0) => mthis["hostname"] = __arg_0;

  href_Getter_(mthis) => mthis["href"];

  href_Setter_(mthis, __arg_0) => mthis["href"] = __arg_0;

  origin_Getter_(mthis) => mthis["origin"];

  password_Getter_(mthis) => mthis["password"];

  password_Setter_(mthis, __arg_0) => mthis["password"] = __arg_0;

  pathname_Getter_(mthis) => mthis["pathname"];

  pathname_Setter_(mthis, __arg_0) => mthis["pathname"] = __arg_0;

  ping_Getter_(mthis) => mthis["ping"];

  ping_Setter_(mthis, __arg_0) => mthis["ping"] = __arg_0;

  port_Getter_(mthis) => mthis["port"];

  port_Setter_(mthis, __arg_0) => mthis["port"] = __arg_0;

  protocol_Getter_(mthis) => mthis["protocol"];

  protocol_Setter_(mthis, __arg_0) => mthis["protocol"] = __arg_0;

  search_Getter_(mthis) => mthis["search"];

  search_Setter_(mthis, __arg_0) => mthis["search"] = __arg_0;

  shape_Getter_(mthis) => mthis["shape"];

  shape_Setter_(mthis, __arg_0) => mthis["shape"] = __arg_0;

  target_Getter_(mthis) => mthis["target"];

  target_Setter_(mthis, __arg_0) => mthis["target"] = __arg_0;

  toString_Callback_0_(mthis) => mthis.callMethod("toString", []);

  username_Getter_(mthis) => mthis["username"];

  username_Setter_(mthis, __arg_0) => mthis["username"] = __arg_0;

}

class BlinkHTMLAudioElement extends BlinkHTMLMediaElement {
  static final instance = new BlinkHTMLAudioElement();

  constructorCallback_0_() => new js.JsObject(js.context["Audio"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["Audio"], [__arg_0]);

}

class BlinkHTMLBRElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLBRElement();

}

class BlinkHTMLBaseElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLBaseElement();

  href_Getter_(mthis) => mthis["href"];

  href_Setter_(mthis, __arg_0) => mthis["href"] = __arg_0;

  target_Getter_(mthis) => mthis["target"];

  target_Setter_(mthis, __arg_0) => mthis["target"] = __arg_0;

}

class BlinkHTMLBodyElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLBodyElement();

  onbeforeunload_Getter_(mthis) => mthis["onbeforeunload"];

  onbeforeunload_Setter_(mthis, __arg_0) => mthis["onbeforeunload"] = __arg_0;

  onblur_Getter_(mthis) => mthis["onblur"];

  onblur_Setter_(mthis, __arg_0) => mthis["onblur"] = __arg_0;

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onfocus_Getter_(mthis) => mthis["onfocus"];

  onfocus_Setter_(mthis, __arg_0) => mthis["onfocus"] = __arg_0;

  onhashchange_Getter_(mthis) => mthis["onhashchange"];

  onhashchange_Setter_(mthis, __arg_0) => mthis["onhashchange"] = __arg_0;

  onlanguagechange_Getter_(mthis) => mthis["onlanguagechange"];

  onlanguagechange_Setter_(mthis, __arg_0) => mthis["onlanguagechange"] = __arg_0;

  onload_Getter_(mthis) => mthis["onload"];

  onload_Setter_(mthis, __arg_0) => mthis["onload"] = __arg_0;

  onmessage_Getter_(mthis) => mthis["onmessage"];

  onmessage_Setter_(mthis, __arg_0) => mthis["onmessage"] = __arg_0;

  onoffline_Getter_(mthis) => mthis["onoffline"];

  onoffline_Setter_(mthis, __arg_0) => mthis["onoffline"] = __arg_0;

  ononline_Getter_(mthis) => mthis["ononline"];

  ononline_Setter_(mthis, __arg_0) => mthis["ononline"] = __arg_0;

  onorientationchange_Getter_(mthis) => mthis["onorientationchange"];

  onorientationchange_Setter_(mthis, __arg_0) => mthis["onorientationchange"] = __arg_0;

  onpagehide_Getter_(mthis) => mthis["onpagehide"];

  onpagehide_Setter_(mthis, __arg_0) => mthis["onpagehide"] = __arg_0;

  onpageshow_Getter_(mthis) => mthis["onpageshow"];

  onpageshow_Setter_(mthis, __arg_0) => mthis["onpageshow"] = __arg_0;

  onpopstate_Getter_(mthis) => mthis["onpopstate"];

  onpopstate_Setter_(mthis, __arg_0) => mthis["onpopstate"] = __arg_0;

  onresize_Getter_(mthis) => mthis["onresize"];

  onresize_Setter_(mthis, __arg_0) => mthis["onresize"] = __arg_0;

  onscroll_Getter_(mthis) => mthis["onscroll"];

  onscroll_Setter_(mthis, __arg_0) => mthis["onscroll"] = __arg_0;

  onstorage_Getter_(mthis) => mthis["onstorage"];

  onstorage_Setter_(mthis, __arg_0) => mthis["onstorage"] = __arg_0;

  onunload_Getter_(mthis) => mthis["onunload"];

  onunload_Setter_(mthis, __arg_0) => mthis["onunload"] = __arg_0;

}

class BlinkHTMLButtonElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLButtonElement();

  autofocus_Getter_(mthis) => mthis["autofocus"];

  autofocus_Setter_(mthis, __arg_0) => mthis["autofocus"] = __arg_0;

  checkValidity_Callback_0_(mthis) => mthis.callMethod("checkValidity", []);

  disabled_Getter_(mthis) => mthis["disabled"];

  disabled_Setter_(mthis, __arg_0) => mthis["disabled"] = __arg_0;

  formAction_Getter_(mthis) => mthis["formAction"];

  formAction_Setter_(mthis, __arg_0) => mthis["formAction"] = __arg_0;

  formEnctype_Getter_(mthis) => mthis["formEnctype"];

  formEnctype_Setter_(mthis, __arg_0) => mthis["formEnctype"] = __arg_0;

  formMethod_Getter_(mthis) => mthis["formMethod"];

  formMethod_Setter_(mthis, __arg_0) => mthis["formMethod"] = __arg_0;

  formNoValidate_Getter_(mthis) => mthis["formNoValidate"];

  formNoValidate_Setter_(mthis, __arg_0) => mthis["formNoValidate"] = __arg_0;

  formTarget_Getter_(mthis) => mthis["formTarget"];

  formTarget_Setter_(mthis, __arg_0) => mthis["formTarget"] = __arg_0;

  form_Getter_(mthis) => mthis["form"];

  labels_Getter_(mthis) => mthis["labels"];

  name_Getter_(mthis) => mthis["name"];

  name_Setter_(mthis, __arg_0) => mthis["name"] = __arg_0;

  setCustomValidity_Callback_0_(mthis) => mthis.callMethod("setCustomValidity", []);

  setCustomValidity_Callback_1_(mthis, __arg_0) => mthis.callMethod("setCustomValidity", [__arg_0]);

  type_Getter_(mthis) => mthis["type"];

  type_Setter_(mthis, __arg_0) => mthis["type"] = __arg_0;

  validationMessage_Getter_(mthis) => mthis["validationMessage"];

  validity_Getter_(mthis) => mthis["validity"];

  value_Getter_(mthis) => mthis["value"];

  value_Setter_(mthis, __arg_0) => mthis["value"] = __arg_0;

  willValidate_Getter_(mthis) => mthis["willValidate"];

}

class BlinkHTMLCanvasElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLCanvasElement();

  getContext_Callback_0_(mthis) => mthis.callMethod("getContext", []);

  getContext_Callback_1_(mthis, __arg_0) => mthis.callMethod("getContext", [__arg_0]);

  getContext_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getContext", [__arg_0, __arg_1]);

  height_Getter_(mthis) => mthis["height"];

  height_Setter_(mthis, __arg_0) => mthis["height"] = __arg_0;

  toDataURL_Callback_0_(mthis) => mthis.callMethod("toDataURL", []);

  toDataURL_Callback_1_(mthis, __arg_0) => mthis.callMethod("toDataURL", [__arg_0]);

  toDataURL_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("toDataURL", [__arg_0, __arg_1]);

  width_Getter_(mthis) => mthis["width"];

  width_Setter_(mthis, __arg_0) => mthis["width"] = __arg_0;

}

class BlinkHTMLCollection {
  static final instance = new BlinkHTMLCollection();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

  namedItem_Callback_0_(mthis) => mthis.callMethod("namedItem", []);

  namedItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("namedItem", [__arg_0]);

}

class BlinkHTMLContentElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLContentElement();

  getDistributedNodes_Callback_0_(mthis) => mthis.callMethod("getDistributedNodes", []);

  select_Getter_(mthis) => mthis["select"];

  select_Setter_(mthis, __arg_0) => mthis["select"] = __arg_0;

}

class BlinkHTMLDListElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLDListElement();

}

class BlinkHTMLDataListElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLDataListElement();

  options_Getter_(mthis) => mthis["options"];

}

class BlinkHTMLDetailsElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLDetailsElement();

  open_Getter_(mthis) => mthis["open"];

  open_Setter_(mthis, __arg_0) => mthis["open"] = __arg_0;

}

class BlinkHTMLDialogElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLDialogElement();

  close_Callback_0_(mthis) => mthis.callMethod("close", []);

  close_Callback_1_(mthis, __arg_0) => mthis.callMethod("close", [__arg_0]);

  open_Getter_(mthis) => mthis["open"];

  open_Setter_(mthis, __arg_0) => mthis["open"] = __arg_0;

  returnValue_Getter_(mthis) => mthis["returnValue"];

  returnValue_Setter_(mthis, __arg_0) => mthis["returnValue"] = __arg_0;

  showModal_Callback_0_(mthis) => mthis.callMethod("showModal", []);

  show_Callback_0_(mthis) => mthis.callMethod("show", []);

}

class BlinkHTMLDirectoryElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLDirectoryElement();

}

class BlinkHTMLDivElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLDivElement();

}

class BlinkHTMLDocument extends BlinkDocument {
  static final instance = new BlinkHTMLDocument();

  alinkColor_Getter_(mthis) => mthis["alinkColor"];

  alinkColor_Setter_(mthis, __arg_0) => mthis["alinkColor"] = __arg_0;

  bgColor_Getter_(mthis) => mthis["bgColor"];

  bgColor_Setter_(mthis, __arg_0) => mthis["bgColor"] = __arg_0;

  captureEvents_Callback_0_(mthis) => mthis.callMethod("captureEvents", []);

  clear_Callback_0_(mthis) => mthis.callMethod("clear", []);

  close_Callback_0_(mthis) => mthis.callMethod("close", []);

  compatMode_Getter_(mthis) => mthis["compatMode"];

  fgColor_Getter_(mthis) => mthis["fgColor"];

  fgColor_Setter_(mthis, __arg_0) => mthis["fgColor"] = __arg_0;

  linkColor_Getter_(mthis) => mthis["linkColor"];

  linkColor_Setter_(mthis, __arg_0) => mthis["linkColor"] = __arg_0;

  open_Callback_0_(mthis) => mthis.callMethod("open", []);

  releaseEvents_Callback_0_(mthis) => mthis.callMethod("releaseEvents", []);

  vlinkColor_Getter_(mthis) => mthis["vlinkColor"];

  vlinkColor_Setter_(mthis, __arg_0) => mthis["vlinkColor"] = __arg_0;

  write_Callback_0_(mthis) => mthis.callMethod("write", []);

  write_Callback_1_(mthis, __arg_0) => mthis.callMethod("write", [__arg_0]);

  writeln_Callback_0_(mthis) => mthis.callMethod("writeln", []);

  writeln_Callback_1_(mthis, __arg_0) => mthis.callMethod("writeln", [__arg_0]);

}

class BlinkHTMLElement extends BlinkElement {
  static final instance = new BlinkHTMLElement();

  accessKey_Getter_(mthis) => mthis["accessKey"];

  accessKey_Setter_(mthis, __arg_0) => mthis["accessKey"] = __arg_0;

  click_Callback_0_(mthis) => mthis.callMethod("click", []);

  contentEditable_Getter_(mthis) => mthis["contentEditable"];

  contentEditable_Setter_(mthis, __arg_0) => mthis["contentEditable"] = __arg_0;

  contextMenu_Getter_(mthis) => mthis["contextMenu"];

  contextMenu_Setter_(mthis, __arg_0) => mthis["contextMenu"] = __arg_0;

  dir_Getter_(mthis) => mthis["dir"];

  dir_Setter_(mthis, __arg_0) => mthis["dir"] = __arg_0;

  draggable_Getter_(mthis) => mthis["draggable"];

  draggable_Setter_(mthis, __arg_0) => mthis["draggable"] = __arg_0;

  hidden_Getter_(mthis) => mthis["hidden"];

  hidden_Setter_(mthis, __arg_0) => mthis["hidden"] = __arg_0;

  innerText_Getter_(mthis) => mthis["innerText"];

  innerText_Setter_(mthis, __arg_0) => mthis["innerText"] = __arg_0;

  inputMethodContext_Getter_(mthis) => mthis["inputMethodContext"];

  isContentEditable_Getter_(mthis) => mthis["isContentEditable"];

  lang_Getter_(mthis) => mthis["lang"];

  lang_Setter_(mthis, __arg_0) => mthis["lang"] = __arg_0;

  onabort_Getter_(mthis) => mthis["onabort"];

  onabort_Setter_(mthis, __arg_0) => mthis["onabort"] = __arg_0;

  onautocomplete_Getter_(mthis) => mthis["onautocomplete"];

  onautocomplete_Setter_(mthis, __arg_0) => mthis["onautocomplete"] = __arg_0;

  onautocompleteerror_Getter_(mthis) => mthis["onautocompleteerror"];

  onautocompleteerror_Setter_(mthis, __arg_0) => mthis["onautocompleteerror"] = __arg_0;

  onblur_Getter_(mthis) => mthis["onblur"];

  onblur_Setter_(mthis, __arg_0) => mthis["onblur"] = __arg_0;

  oncancel_Getter_(mthis) => mthis["oncancel"];

  oncancel_Setter_(mthis, __arg_0) => mthis["oncancel"] = __arg_0;

  oncanplay_Getter_(mthis) => mthis["oncanplay"];

  oncanplay_Setter_(mthis, __arg_0) => mthis["oncanplay"] = __arg_0;

  oncanplaythrough_Getter_(mthis) => mthis["oncanplaythrough"];

  oncanplaythrough_Setter_(mthis, __arg_0) => mthis["oncanplaythrough"] = __arg_0;

  onchange_Getter_(mthis) => mthis["onchange"];

  onchange_Setter_(mthis, __arg_0) => mthis["onchange"] = __arg_0;

  onclick_Getter_(mthis) => mthis["onclick"];

  onclick_Setter_(mthis, __arg_0) => mthis["onclick"] = __arg_0;

  onclose_Getter_(mthis) => mthis["onclose"];

  onclose_Setter_(mthis, __arg_0) => mthis["onclose"] = __arg_0;

  oncontextmenu_Getter_(mthis) => mthis["oncontextmenu"];

  oncontextmenu_Setter_(mthis, __arg_0) => mthis["oncontextmenu"] = __arg_0;

  oncuechange_Getter_(mthis) => mthis["oncuechange"];

  oncuechange_Setter_(mthis, __arg_0) => mthis["oncuechange"] = __arg_0;

  ondblclick_Getter_(mthis) => mthis["ondblclick"];

  ondblclick_Setter_(mthis, __arg_0) => mthis["ondblclick"] = __arg_0;

  ondrag_Getter_(mthis) => mthis["ondrag"];

  ondrag_Setter_(mthis, __arg_0) => mthis["ondrag"] = __arg_0;

  ondragend_Getter_(mthis) => mthis["ondragend"];

  ondragend_Setter_(mthis, __arg_0) => mthis["ondragend"] = __arg_0;

  ondragenter_Getter_(mthis) => mthis["ondragenter"];

  ondragenter_Setter_(mthis, __arg_0) => mthis["ondragenter"] = __arg_0;

  ondragleave_Getter_(mthis) => mthis["ondragleave"];

  ondragleave_Setter_(mthis, __arg_0) => mthis["ondragleave"] = __arg_0;

  ondragover_Getter_(mthis) => mthis["ondragover"];

  ondragover_Setter_(mthis, __arg_0) => mthis["ondragover"] = __arg_0;

  ondragstart_Getter_(mthis) => mthis["ondragstart"];

  ondragstart_Setter_(mthis, __arg_0) => mthis["ondragstart"] = __arg_0;

  ondrop_Getter_(mthis) => mthis["ondrop"];

  ondrop_Setter_(mthis, __arg_0) => mthis["ondrop"] = __arg_0;

  ondurationchange_Getter_(mthis) => mthis["ondurationchange"];

  ondurationchange_Setter_(mthis, __arg_0) => mthis["ondurationchange"] = __arg_0;

  onemptied_Getter_(mthis) => mthis["onemptied"];

  onemptied_Setter_(mthis, __arg_0) => mthis["onemptied"] = __arg_0;

  onended_Getter_(mthis) => mthis["onended"];

  onended_Setter_(mthis, __arg_0) => mthis["onended"] = __arg_0;

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onfocus_Getter_(mthis) => mthis["onfocus"];

  onfocus_Setter_(mthis, __arg_0) => mthis["onfocus"] = __arg_0;

  oninput_Getter_(mthis) => mthis["oninput"];

  oninput_Setter_(mthis, __arg_0) => mthis["oninput"] = __arg_0;

  oninvalid_Getter_(mthis) => mthis["oninvalid"];

  oninvalid_Setter_(mthis, __arg_0) => mthis["oninvalid"] = __arg_0;

  onkeydown_Getter_(mthis) => mthis["onkeydown"];

  onkeydown_Setter_(mthis, __arg_0) => mthis["onkeydown"] = __arg_0;

  onkeypress_Getter_(mthis) => mthis["onkeypress"];

  onkeypress_Setter_(mthis, __arg_0) => mthis["onkeypress"] = __arg_0;

  onkeyup_Getter_(mthis) => mthis["onkeyup"];

  onkeyup_Setter_(mthis, __arg_0) => mthis["onkeyup"] = __arg_0;

  onload_Getter_(mthis) => mthis["onload"];

  onload_Setter_(mthis, __arg_0) => mthis["onload"] = __arg_0;

  onloadeddata_Getter_(mthis) => mthis["onloadeddata"];

  onloadeddata_Setter_(mthis, __arg_0) => mthis["onloadeddata"] = __arg_0;

  onloadedmetadata_Getter_(mthis) => mthis["onloadedmetadata"];

  onloadedmetadata_Setter_(mthis, __arg_0) => mthis["onloadedmetadata"] = __arg_0;

  onloadstart_Getter_(mthis) => mthis["onloadstart"];

  onloadstart_Setter_(mthis, __arg_0) => mthis["onloadstart"] = __arg_0;

  onmousedown_Getter_(mthis) => mthis["onmousedown"];

  onmousedown_Setter_(mthis, __arg_0) => mthis["onmousedown"] = __arg_0;

  onmouseenter_Getter_(mthis) => mthis["onmouseenter"];

  onmouseenter_Setter_(mthis, __arg_0) => mthis["onmouseenter"] = __arg_0;

  onmouseleave_Getter_(mthis) => mthis["onmouseleave"];

  onmouseleave_Setter_(mthis, __arg_0) => mthis["onmouseleave"] = __arg_0;

  onmousemove_Getter_(mthis) => mthis["onmousemove"];

  onmousemove_Setter_(mthis, __arg_0) => mthis["onmousemove"] = __arg_0;

  onmouseout_Getter_(mthis) => mthis["onmouseout"];

  onmouseout_Setter_(mthis, __arg_0) => mthis["onmouseout"] = __arg_0;

  onmouseover_Getter_(mthis) => mthis["onmouseover"];

  onmouseover_Setter_(mthis, __arg_0) => mthis["onmouseover"] = __arg_0;

  onmouseup_Getter_(mthis) => mthis["onmouseup"];

  onmouseup_Setter_(mthis, __arg_0) => mthis["onmouseup"] = __arg_0;

  onmousewheel_Getter_(mthis) => mthis["onmousewheel"];

  onmousewheel_Setter_(mthis, __arg_0) => mthis["onmousewheel"] = __arg_0;

  onpause_Getter_(mthis) => mthis["onpause"];

  onpause_Setter_(mthis, __arg_0) => mthis["onpause"] = __arg_0;

  onplay_Getter_(mthis) => mthis["onplay"];

  onplay_Setter_(mthis, __arg_0) => mthis["onplay"] = __arg_0;

  onplaying_Getter_(mthis) => mthis["onplaying"];

  onplaying_Setter_(mthis, __arg_0) => mthis["onplaying"] = __arg_0;

  onprogress_Getter_(mthis) => mthis["onprogress"];

  onprogress_Setter_(mthis, __arg_0) => mthis["onprogress"] = __arg_0;

  onratechange_Getter_(mthis) => mthis["onratechange"];

  onratechange_Setter_(mthis, __arg_0) => mthis["onratechange"] = __arg_0;

  onreset_Getter_(mthis) => mthis["onreset"];

  onreset_Setter_(mthis, __arg_0) => mthis["onreset"] = __arg_0;

  onresize_Getter_(mthis) => mthis["onresize"];

  onresize_Setter_(mthis, __arg_0) => mthis["onresize"] = __arg_0;

  onscroll_Getter_(mthis) => mthis["onscroll"];

  onscroll_Setter_(mthis, __arg_0) => mthis["onscroll"] = __arg_0;

  onseeked_Getter_(mthis) => mthis["onseeked"];

  onseeked_Setter_(mthis, __arg_0) => mthis["onseeked"] = __arg_0;

  onseeking_Getter_(mthis) => mthis["onseeking"];

  onseeking_Setter_(mthis, __arg_0) => mthis["onseeking"] = __arg_0;

  onselect_Getter_(mthis) => mthis["onselect"];

  onselect_Setter_(mthis, __arg_0) => mthis["onselect"] = __arg_0;

  onshow_Getter_(mthis) => mthis["onshow"];

  onshow_Setter_(mthis, __arg_0) => mthis["onshow"] = __arg_0;

  onstalled_Getter_(mthis) => mthis["onstalled"];

  onstalled_Setter_(mthis, __arg_0) => mthis["onstalled"] = __arg_0;

  onsubmit_Getter_(mthis) => mthis["onsubmit"];

  onsubmit_Setter_(mthis, __arg_0) => mthis["onsubmit"] = __arg_0;

  onsuspend_Getter_(mthis) => mthis["onsuspend"];

  onsuspend_Setter_(mthis, __arg_0) => mthis["onsuspend"] = __arg_0;

  ontimeupdate_Getter_(mthis) => mthis["ontimeupdate"];

  ontimeupdate_Setter_(mthis, __arg_0) => mthis["ontimeupdate"] = __arg_0;

  ontoggle_Getter_(mthis) => mthis["ontoggle"];

  ontoggle_Setter_(mthis, __arg_0) => mthis["ontoggle"] = __arg_0;

  onvolumechange_Getter_(mthis) => mthis["onvolumechange"];

  onvolumechange_Setter_(mthis, __arg_0) => mthis["onvolumechange"] = __arg_0;

  onwaiting_Getter_(mthis) => mthis["onwaiting"];

  onwaiting_Setter_(mthis, __arg_0) => mthis["onwaiting"] = __arg_0;

  outerText_Getter_(mthis) => mthis["outerText"];

  outerText_Setter_(mthis, __arg_0) => mthis["outerText"] = __arg_0;

  spellcheck_Getter_(mthis) => mthis["spellcheck"];

  spellcheck_Setter_(mthis, __arg_0) => mthis["spellcheck"] = __arg_0;

  tabIndex_Getter_(mthis) => mthis["tabIndex"];

  tabIndex_Setter_(mthis, __arg_0) => mthis["tabIndex"] = __arg_0;

  title_Getter_(mthis) => mthis["title"];

  title_Setter_(mthis, __arg_0) => mthis["title"] = __arg_0;

  translate_Getter_(mthis) => mthis["translate"];

  translate_Setter_(mthis, __arg_0) => mthis["translate"] = __arg_0;

  webkitdropzone_Getter_(mthis) => mthis["webkitdropzone"];

  webkitdropzone_Setter_(mthis, __arg_0) => mthis["webkitdropzone"] = __arg_0;

}

class BlinkHTMLEmbedElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLEmbedElement();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  $__setter___Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("__setter__", [__arg_0, __arg_1]);

  align_Getter_(mthis) => mthis["align"];

  align_Setter_(mthis, __arg_0) => mthis["align"] = __arg_0;

  getSVGDocument_Callback_0_(mthis) => mthis.callMethod("getSVGDocument", []);

  height_Getter_(mthis) => mthis["height"];

  height_Setter_(mthis, __arg_0) => mthis["height"] = __arg_0;

  integrity_Getter_(mthis) => mthis["integrity"];

  integrity_Setter_(mthis, __arg_0) => mthis["integrity"] = __arg_0;

  name_Getter_(mthis) => mthis["name"];

  name_Setter_(mthis, __arg_0) => mthis["name"] = __arg_0;

  src_Getter_(mthis) => mthis["src"];

  src_Setter_(mthis, __arg_0) => mthis["src"] = __arg_0;

  type_Getter_(mthis) => mthis["type"];

  type_Setter_(mthis, __arg_0) => mthis["type"] = __arg_0;

  width_Getter_(mthis) => mthis["width"];

  width_Setter_(mthis, __arg_0) => mthis["width"] = __arg_0;

}

class BlinkHTMLFieldSetElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLFieldSetElement();

  checkValidity_Callback_0_(mthis) => mthis.callMethod("checkValidity", []);

  disabled_Getter_(mthis) => mthis["disabled"];

  disabled_Setter_(mthis, __arg_0) => mthis["disabled"] = __arg_0;

  elements_Getter_(mthis) => mthis["elements"];

  form_Getter_(mthis) => mthis["form"];

  name_Getter_(mthis) => mthis["name"];

  name_Setter_(mthis, __arg_0) => mthis["name"] = __arg_0;

  setCustomValidity_Callback_0_(mthis) => mthis.callMethod("setCustomValidity", []);

  setCustomValidity_Callback_1_(mthis, __arg_0) => mthis.callMethod("setCustomValidity", [__arg_0]);

  type_Getter_(mthis) => mthis["type"];

  validationMessage_Getter_(mthis) => mthis["validationMessage"];

  validity_Getter_(mthis) => mthis["validity"];

  willValidate_Getter_(mthis) => mthis["willValidate"];

}

class BlinkHTMLFontElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLFontElement();

}

class BlinkHTMLFormControlsCollection extends BlinkHTMLCollection {
  static final instance = new BlinkHTMLFormControlsCollection();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  namedItem_Callback_0_(mthis) => mthis.callMethod("namedItem", []);

  namedItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("namedItem", [__arg_0]);

}

class BlinkHTMLFormElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLFormElement();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  acceptCharset_Getter_(mthis) => mthis["acceptCharset"];

  acceptCharset_Setter_(mthis, __arg_0) => mthis["acceptCharset"] = __arg_0;

  action_Getter_(mthis) => mthis["action"];

  action_Setter_(mthis, __arg_0) => mthis["action"] = __arg_0;

  autocomplete_Getter_(mthis) => mthis["autocomplete"];

  autocomplete_Setter_(mthis, __arg_0) => mthis["autocomplete"] = __arg_0;

  checkValidity_Callback_0_(mthis) => mthis.callMethod("checkValidity", []);

  elements_Getter_(mthis) => mthis["elements"];

  encoding_Getter_(mthis) => mthis["encoding"];

  encoding_Setter_(mthis, __arg_0) => mthis["encoding"] = __arg_0;

  enctype_Getter_(mthis) => mthis["enctype"];

  enctype_Setter_(mthis, __arg_0) => mthis["enctype"] = __arg_0;

  length_Getter_(mthis) => mthis["length"];

  method_Getter_(mthis) => mthis["method"];

  method_Setter_(mthis, __arg_0) => mthis["method"] = __arg_0;

  name_Getter_(mthis) => mthis["name"];

  name_Setter_(mthis, __arg_0) => mthis["name"] = __arg_0;

  noValidate_Getter_(mthis) => mthis["noValidate"];

  noValidate_Setter_(mthis, __arg_0) => mthis["noValidate"] = __arg_0;

  requestAutocomplete_Callback_0_(mthis) => mthis.callMethod("requestAutocomplete", []);

  reset_Callback_0_(mthis) => mthis.callMethod("reset", []);

  submit_Callback_0_(mthis) => mthis.callMethod("submit", []);

  target_Getter_(mthis) => mthis["target"];

  target_Setter_(mthis, __arg_0) => mthis["target"] = __arg_0;

}

class BlinkHTMLFrameElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLFrameElement();

}

class BlinkHTMLFrameSetElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLFrameSetElement();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

}

class BlinkHTMLHRElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLHRElement();

  color_Getter_(mthis) => mthis["color"];

  color_Setter_(mthis, __arg_0) => mthis["color"] = __arg_0;

}

class BlinkHTMLHeadElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLHeadElement();

}

class BlinkHTMLHeadingElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLHeadingElement();

}

class BlinkHTMLHtmlElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLHtmlElement();

}

class BlinkHTMLIFrameElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLIFrameElement();

  allowFullscreen_Getter_(mthis) => mthis["allowFullscreen"];

  allowFullscreen_Setter_(mthis, __arg_0) => mthis["allowFullscreen"] = __arg_0;

  contentDocument_Getter_(mthis) => mthis["contentDocument"];

  contentWindow_Getter_(mthis) => mthis["contentWindow"];

  getSVGDocument_Callback_0_(mthis) => mthis.callMethod("getSVGDocument", []);

  height_Getter_(mthis) => mthis["height"];

  height_Setter_(mthis, __arg_0) => mthis["height"] = __arg_0;

  integrity_Getter_(mthis) => mthis["integrity"];

  integrity_Setter_(mthis, __arg_0) => mthis["integrity"] = __arg_0;

  name_Getter_(mthis) => mthis["name"];

  name_Setter_(mthis, __arg_0) => mthis["name"] = __arg_0;

  sandbox_Getter_(mthis) => mthis["sandbox"];

  sandbox_Setter_(mthis, __arg_0) => mthis["sandbox"] = __arg_0;

  src_Getter_(mthis) => mthis["src"];

  src_Setter_(mthis, __arg_0) => mthis["src"] = __arg_0;

  srcdoc_Getter_(mthis) => mthis["srcdoc"];

  srcdoc_Setter_(mthis, __arg_0) => mthis["srcdoc"] = __arg_0;

  width_Getter_(mthis) => mthis["width"];

  width_Setter_(mthis, __arg_0) => mthis["width"] = __arg_0;

}

class BlinkHTMLImageElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLImageElement();

  alt_Getter_(mthis) => mthis["alt"];

  alt_Setter_(mthis, __arg_0) => mthis["alt"] = __arg_0;

  border_Getter_(mthis) => mthis["border"];

  border_Setter_(mthis, __arg_0) => mthis["border"] = __arg_0;

  complete_Getter_(mthis) => mthis["complete"];

  constructorCallback_0_() => new js.JsObject(js.context["Image"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["Image"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["Image"], [__arg_0, __arg_1]);

  crossOrigin_Getter_(mthis) => mthis["crossOrigin"];

  crossOrigin_Setter_(mthis, __arg_0) => mthis["crossOrigin"] = __arg_0;

  currentSrc_Getter_(mthis) => mthis["currentSrc"];

  height_Getter_(mthis) => mthis["height"];

  height_Setter_(mthis, __arg_0) => mthis["height"] = __arg_0;

  integrity_Getter_(mthis) => mthis["integrity"];

  integrity_Setter_(mthis, __arg_0) => mthis["integrity"] = __arg_0;

  isMap_Getter_(mthis) => mthis["isMap"];

  isMap_Setter_(mthis, __arg_0) => mthis["isMap"] = __arg_0;

  lowsrc_Getter_(mthis) => mthis["lowsrc"];

  lowsrc_Setter_(mthis, __arg_0) => mthis["lowsrc"] = __arg_0;

  naturalHeight_Getter_(mthis) => mthis["naturalHeight"];

  naturalWidth_Getter_(mthis) => mthis["naturalWidth"];

  sizes_Getter_(mthis) => mthis["sizes"];

  sizes_Setter_(mthis, __arg_0) => mthis["sizes"] = __arg_0;

  src_Getter_(mthis) => mthis["src"];

  src_Setter_(mthis, __arg_0) => mthis["src"] = __arg_0;

  srcset_Getter_(mthis) => mthis["srcset"];

  srcset_Setter_(mthis, __arg_0) => mthis["srcset"] = __arg_0;

  useMap_Getter_(mthis) => mthis["useMap"];

  useMap_Setter_(mthis, __arg_0) => mthis["useMap"] = __arg_0;

  width_Getter_(mthis) => mthis["width"];

  width_Setter_(mthis, __arg_0) => mthis["width"] = __arg_0;

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkHTMLInputElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLInputElement();

  accept_Getter_(mthis) => mthis["accept"];

  accept_Setter_(mthis, __arg_0) => mthis["accept"] = __arg_0;

  alt_Getter_(mthis) => mthis["alt"];

  alt_Setter_(mthis, __arg_0) => mthis["alt"] = __arg_0;

  autocomplete_Getter_(mthis) => mthis["autocomplete"];

  autocomplete_Setter_(mthis, __arg_0) => mthis["autocomplete"] = __arg_0;

  autofocus_Getter_(mthis) => mthis["autofocus"];

  autofocus_Setter_(mthis, __arg_0) => mthis["autofocus"] = __arg_0;

  capture_Getter_(mthis) => mthis["capture"];

  capture_Setter_(mthis, __arg_0) => mthis["capture"] = __arg_0;

  checkValidity_Callback_0_(mthis) => mthis.callMethod("checkValidity", []);

  checked_Getter_(mthis) => mthis["checked"];

  checked_Setter_(mthis, __arg_0) => mthis["checked"] = __arg_0;

  defaultChecked_Getter_(mthis) => mthis["defaultChecked"];

  defaultChecked_Setter_(mthis, __arg_0) => mthis["defaultChecked"] = __arg_0;

  defaultValue_Getter_(mthis) => mthis["defaultValue"];

  defaultValue_Setter_(mthis, __arg_0) => mthis["defaultValue"] = __arg_0;

  dirName_Getter_(mthis) => mthis["dirName"];

  dirName_Setter_(mthis, __arg_0) => mthis["dirName"] = __arg_0;

  disabled_Getter_(mthis) => mthis["disabled"];

  disabled_Setter_(mthis, __arg_0) => mthis["disabled"] = __arg_0;

  files_Getter_(mthis) => mthis["files"];

  files_Setter_(mthis, __arg_0) => mthis["files"] = __arg_0;

  formAction_Getter_(mthis) => mthis["formAction"];

  formAction_Setter_(mthis, __arg_0) => mthis["formAction"] = __arg_0;

  formEnctype_Getter_(mthis) => mthis["formEnctype"];

  formEnctype_Setter_(mthis, __arg_0) => mthis["formEnctype"] = __arg_0;

  formMethod_Getter_(mthis) => mthis["formMethod"];

  formMethod_Setter_(mthis, __arg_0) => mthis["formMethod"] = __arg_0;

  formNoValidate_Getter_(mthis) => mthis["formNoValidate"];

  formNoValidate_Setter_(mthis, __arg_0) => mthis["formNoValidate"] = __arg_0;

  formTarget_Getter_(mthis) => mthis["formTarget"];

  formTarget_Setter_(mthis, __arg_0) => mthis["formTarget"] = __arg_0;

  form_Getter_(mthis) => mthis["form"];

  height_Getter_(mthis) => mthis["height"];

  height_Setter_(mthis, __arg_0) => mthis["height"] = __arg_0;

  incremental_Getter_(mthis) => mthis["incremental"];

  incremental_Setter_(mthis, __arg_0) => mthis["incremental"] = __arg_0;

  indeterminate_Getter_(mthis) => mthis["indeterminate"];

  indeterminate_Setter_(mthis, __arg_0) => mthis["indeterminate"] = __arg_0;

  inputMode_Getter_(mthis) => mthis["inputMode"];

  inputMode_Setter_(mthis, __arg_0) => mthis["inputMode"] = __arg_0;

  labels_Getter_(mthis) => mthis["labels"];

  list_Getter_(mthis) => mthis["list"];

  maxLength_Getter_(mthis) => mthis["maxLength"];

  maxLength_Setter_(mthis, __arg_0) => mthis["maxLength"] = __arg_0;

  max_Getter_(mthis) => mthis["max"];

  max_Setter_(mthis, __arg_0) => mthis["max"] = __arg_0;

  min_Getter_(mthis) => mthis["min"];

  min_Setter_(mthis, __arg_0) => mthis["min"] = __arg_0;

  multiple_Getter_(mthis) => mthis["multiple"];

  multiple_Setter_(mthis, __arg_0) => mthis["multiple"] = __arg_0;

  name_Getter_(mthis) => mthis["name"];

  name_Setter_(mthis, __arg_0) => mthis["name"] = __arg_0;

  pattern_Getter_(mthis) => mthis["pattern"];

  pattern_Setter_(mthis, __arg_0) => mthis["pattern"] = __arg_0;

  placeholder_Getter_(mthis) => mthis["placeholder"];

  placeholder_Setter_(mthis, __arg_0) => mthis["placeholder"] = __arg_0;

  readOnly_Getter_(mthis) => mthis["readOnly"];

  readOnly_Setter_(mthis, __arg_0) => mthis["readOnly"] = __arg_0;

  required_Getter_(mthis) => mthis["required"];

  required_Setter_(mthis, __arg_0) => mthis["required"] = __arg_0;

  select_Callback_0_(mthis) => mthis.callMethod("select", []);

  selectionDirection_Getter_(mthis) => mthis["selectionDirection"];

  selectionDirection_Setter_(mthis, __arg_0) => mthis["selectionDirection"] = __arg_0;

  selectionEnd_Getter_(mthis) => mthis["selectionEnd"];

  selectionEnd_Setter_(mthis, __arg_0) => mthis["selectionEnd"] = __arg_0;

  selectionStart_Getter_(mthis) => mthis["selectionStart"];

  selectionStart_Setter_(mthis, __arg_0) => mthis["selectionStart"] = __arg_0;

  setCustomValidity_Callback_0_(mthis) => mthis.callMethod("setCustomValidity", []);

  setCustomValidity_Callback_1_(mthis, __arg_0) => mthis.callMethod("setCustomValidity", [__arg_0]);

  setRangeText_Callback_0_(mthis) => mthis.callMethod("setRangeText", []);

  setRangeText_Callback_1_(mthis, __arg_0) => mthis.callMethod("setRangeText", [__arg_0]);

  setRangeText_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setRangeText", [__arg_0, __arg_1]);

  setRangeText_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setRangeText", [__arg_0, __arg_1, __arg_2]);

  setRangeText_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("setRangeText", [__arg_0, __arg_1, __arg_2, __arg_3]);

  setSelectionRange_Callback_0_(mthis) => mthis.callMethod("setSelectionRange", []);

  setSelectionRange_Callback_1_(mthis, __arg_0) => mthis.callMethod("setSelectionRange", [__arg_0]);

  setSelectionRange_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setSelectionRange", [__arg_0, __arg_1]);

  setSelectionRange_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setSelectionRange", [__arg_0, __arg_1, __arg_2]);

  size_Getter_(mthis) => mthis["size"];

  size_Setter_(mthis, __arg_0) => mthis["size"] = __arg_0;

  src_Getter_(mthis) => mthis["src"];

  src_Setter_(mthis, __arg_0) => mthis["src"] = __arg_0;

  stepDown_Callback_0_(mthis) => mthis.callMethod("stepDown", []);

  stepDown_Callback_1_(mthis, __arg_0) => mthis.callMethod("stepDown", [__arg_0]);

  stepUp_Callback_0_(mthis) => mthis.callMethod("stepUp", []);

  stepUp_Callback_1_(mthis, __arg_0) => mthis.callMethod("stepUp", [__arg_0]);

  step_Getter_(mthis) => mthis["step"];

  step_Setter_(mthis, __arg_0) => mthis["step"] = __arg_0;

  type_Getter_(mthis) => mthis["type"];

  type_Setter_(mthis, __arg_0) => mthis["type"] = __arg_0;

  useMap_Getter_(mthis) => mthis["useMap"];

  useMap_Setter_(mthis, __arg_0) => mthis["useMap"] = __arg_0;

  validationMessage_Getter_(mthis) => mthis["validationMessage"];

  validity_Getter_(mthis) => mthis["validity"];

  valueAsDate_Getter_(mthis) => mthis["valueAsDate"];

  valueAsDate_Setter_(mthis, __arg_0) => mthis["valueAsDate"] = __arg_0;

  valueAsNumber_Getter_(mthis) => mthis["valueAsNumber"];

  valueAsNumber_Setter_(mthis, __arg_0) => mthis["valueAsNumber"] = __arg_0;

  value_Getter_(mthis) => mthis["value"];

  value_Setter_(mthis, __arg_0) => mthis["value"] = __arg_0;

  webkitEntries_Getter_(mthis) => mthis["webkitEntries"];

  webkitdirectory_Getter_(mthis) => mthis["webkitdirectory"];

  webkitdirectory_Setter_(mthis, __arg_0) => mthis["webkitdirectory"] = __arg_0;

  width_Getter_(mthis) => mthis["width"];

  width_Setter_(mthis, __arg_0) => mthis["width"] = __arg_0;

  willValidate_Getter_(mthis) => mthis["willValidate"];

}

class BlinkHTMLKeygenElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLKeygenElement();

  autofocus_Getter_(mthis) => mthis["autofocus"];

  autofocus_Setter_(mthis, __arg_0) => mthis["autofocus"] = __arg_0;

  challenge_Getter_(mthis) => mthis["challenge"];

  challenge_Setter_(mthis, __arg_0) => mthis["challenge"] = __arg_0;

  checkValidity_Callback_0_(mthis) => mthis.callMethod("checkValidity", []);

  disabled_Getter_(mthis) => mthis["disabled"];

  disabled_Setter_(mthis, __arg_0) => mthis["disabled"] = __arg_0;

  form_Getter_(mthis) => mthis["form"];

  keytype_Getter_(mthis) => mthis["keytype"];

  keytype_Setter_(mthis, __arg_0) => mthis["keytype"] = __arg_0;

  labels_Getter_(mthis) => mthis["labels"];

  name_Getter_(mthis) => mthis["name"];

  name_Setter_(mthis, __arg_0) => mthis["name"] = __arg_0;

  setCustomValidity_Callback_0_(mthis) => mthis.callMethod("setCustomValidity", []);

  setCustomValidity_Callback_1_(mthis, __arg_0) => mthis.callMethod("setCustomValidity", [__arg_0]);

  type_Getter_(mthis) => mthis["type"];

  validationMessage_Getter_(mthis) => mthis["validationMessage"];

  validity_Getter_(mthis) => mthis["validity"];

  willValidate_Getter_(mthis) => mthis["willValidate"];

}

class BlinkHTMLLIElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLLIElement();

  type_Getter_(mthis) => mthis["type"];

  type_Setter_(mthis, __arg_0) => mthis["type"] = __arg_0;

  value_Getter_(mthis) => mthis["value"];

  value_Setter_(mthis, __arg_0) => mthis["value"] = __arg_0;

}

class BlinkHTMLLabelElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLLabelElement();

  control_Getter_(mthis) => mthis["control"];

  form_Getter_(mthis) => mthis["form"];

  htmlFor_Getter_(mthis) => mthis["htmlFor"];

  htmlFor_Setter_(mthis, __arg_0) => mthis["htmlFor"] = __arg_0;

}

class BlinkHTMLLegendElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLLegendElement();

  form_Getter_(mthis) => mthis["form"];

}

class BlinkHTMLLinkElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLLinkElement();

  crossOrigin_Getter_(mthis) => mthis["crossOrigin"];

  crossOrigin_Setter_(mthis, __arg_0) => mthis["crossOrigin"] = __arg_0;

  disabled_Getter_(mthis) => mthis["disabled"];

  disabled_Setter_(mthis, __arg_0) => mthis["disabled"] = __arg_0;

  href_Getter_(mthis) => mthis["href"];

  href_Setter_(mthis, __arg_0) => mthis["href"] = __arg_0;

  hreflang_Getter_(mthis) => mthis["hreflang"];

  hreflang_Setter_(mthis, __arg_0) => mthis["hreflang"] = __arg_0;

  import_Getter_(mthis) => mthis["import"];

  integrity_Getter_(mthis) => mthis["integrity"];

  integrity_Setter_(mthis, __arg_0) => mthis["integrity"] = __arg_0;

  media_Getter_(mthis) => mthis["media"];

  media_Setter_(mthis, __arg_0) => mthis["media"] = __arg_0;

  rel_Getter_(mthis) => mthis["rel"];

  rel_Setter_(mthis, __arg_0) => mthis["rel"] = __arg_0;

  sheet_Getter_(mthis) => mthis["sheet"];

  sizes_Getter_(mthis) => mthis["sizes"];

  sizes_Setter_(mthis, __arg_0) => mthis["sizes"] = __arg_0;

  type_Getter_(mthis) => mthis["type"];

  type_Setter_(mthis, __arg_0) => mthis["type"] = __arg_0;

}

class BlinkHTMLMapElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLMapElement();

  areas_Getter_(mthis) => mthis["areas"];

  name_Getter_(mthis) => mthis["name"];

  name_Setter_(mthis, __arg_0) => mthis["name"] = __arg_0;

}

class BlinkHTMLMarqueeElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLMarqueeElement();

}

class BlinkHTMLMediaElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLMediaElement();

  addTextTrack_Callback_0_(mthis) => mthis.callMethod("addTextTrack", []);

  addTextTrack_Callback_1_(mthis, __arg_0) => mthis.callMethod("addTextTrack", [__arg_0]);

  addTextTrack_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("addTextTrack", [__arg_0, __arg_1]);

  addTextTrack_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("addTextTrack", [__arg_0, __arg_1, __arg_2]);

  audioTracks_Getter_(mthis) => mthis["audioTracks"];

  autoplay_Getter_(mthis) => mthis["autoplay"];

  autoplay_Setter_(mthis, __arg_0) => mthis["autoplay"] = __arg_0;

  buffered_Getter_(mthis) => mthis["buffered"];

  canPlayType_Callback_0_(mthis) => mthis.callMethod("canPlayType", []);

  canPlayType_Callback_1_(mthis, __arg_0) => mthis.callMethod("canPlayType", [__arg_0]);

  canPlayType_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("canPlayType", [__arg_0, __arg_1]);

  controller_Getter_(mthis) => mthis["controller"];

  controller_Setter_(mthis, __arg_0) => mthis["controller"] = __arg_0;

  controls_Getter_(mthis) => mthis["controls"];

  controls_Setter_(mthis, __arg_0) => mthis["controls"] = __arg_0;

  crossOrigin_Getter_(mthis) => mthis["crossOrigin"];

  crossOrigin_Setter_(mthis, __arg_0) => mthis["crossOrigin"] = __arg_0;

  currentSrc_Getter_(mthis) => mthis["currentSrc"];

  currentTime_Getter_(mthis) => mthis["currentTime"];

  currentTime_Setter_(mthis, __arg_0) => mthis["currentTime"] = __arg_0;

  defaultMuted_Getter_(mthis) => mthis["defaultMuted"];

  defaultMuted_Setter_(mthis, __arg_0) => mthis["defaultMuted"] = __arg_0;

  defaultPlaybackRate_Getter_(mthis) => mthis["defaultPlaybackRate"];

  defaultPlaybackRate_Setter_(mthis, __arg_0) => mthis["defaultPlaybackRate"] = __arg_0;

  duration_Getter_(mthis) => mthis["duration"];

  ended_Getter_(mthis) => mthis["ended"];

  error_Getter_(mthis) => mthis["error"];

  integrity_Getter_(mthis) => mthis["integrity"];

  integrity_Setter_(mthis, __arg_0) => mthis["integrity"] = __arg_0;

  load_Callback_0_(mthis) => mthis.callMethod("load", []);

  loop_Getter_(mthis) => mthis["loop"];

  loop_Setter_(mthis, __arg_0) => mthis["loop"] = __arg_0;

  mediaGroup_Getter_(mthis) => mthis["mediaGroup"];

  mediaGroup_Setter_(mthis, __arg_0) => mthis["mediaGroup"] = __arg_0;

  mediaKeys_Getter_(mthis) => mthis["mediaKeys"];

  muted_Getter_(mthis) => mthis["muted"];

  muted_Setter_(mthis, __arg_0) => mthis["muted"] = __arg_0;

  networkState_Getter_(mthis) => mthis["networkState"];

  onneedkey_Getter_(mthis) => mthis["onneedkey"];

  onneedkey_Setter_(mthis, __arg_0) => mthis["onneedkey"] = __arg_0;

  onwebkitkeyadded_Getter_(mthis) => mthis["onwebkitkeyadded"];

  onwebkitkeyadded_Setter_(mthis, __arg_0) => mthis["onwebkitkeyadded"] = __arg_0;

  onwebkitkeyerror_Getter_(mthis) => mthis["onwebkitkeyerror"];

  onwebkitkeyerror_Setter_(mthis, __arg_0) => mthis["onwebkitkeyerror"] = __arg_0;

  onwebkitkeymessage_Getter_(mthis) => mthis["onwebkitkeymessage"];

  onwebkitkeymessage_Setter_(mthis, __arg_0) => mthis["onwebkitkeymessage"] = __arg_0;

  onwebkitneedkey_Getter_(mthis) => mthis["onwebkitneedkey"];

  onwebkitneedkey_Setter_(mthis, __arg_0) => mthis["onwebkitneedkey"] = __arg_0;

  pause_Callback_0_(mthis) => mthis.callMethod("pause", []);

  paused_Getter_(mthis) => mthis["paused"];

  play_Callback_0_(mthis) => mthis.callMethod("play", []);

  playbackRate_Getter_(mthis) => mthis["playbackRate"];

  playbackRate_Setter_(mthis, __arg_0) => mthis["playbackRate"] = __arg_0;

  played_Getter_(mthis) => mthis["played"];

  preload_Getter_(mthis) => mthis["preload"];

  preload_Setter_(mthis, __arg_0) => mthis["preload"] = __arg_0;

  readyState_Getter_(mthis) => mthis["readyState"];

  seekable_Getter_(mthis) => mthis["seekable"];

  seeking_Getter_(mthis) => mthis["seeking"];

  setMediaKeys_Callback_0_(mthis) => mthis.callMethod("setMediaKeys", []);

  setMediaKeys_Callback_1_(mthis, __arg_0) => mthis.callMethod("setMediaKeys", [__arg_0]);

  src_Getter_(mthis) => mthis["src"];

  src_Setter_(mthis, __arg_0) => mthis["src"] = __arg_0;

  textTracks_Getter_(mthis) => mthis["textTracks"];

  videoTracks_Getter_(mthis) => mthis["videoTracks"];

  volume_Getter_(mthis) => mthis["volume"];

  volume_Setter_(mthis, __arg_0) => mthis["volume"] = __arg_0;

  webkitAddKey_Callback_0_(mthis) => mthis.callMethod("webkitAddKey", []);

  webkitAddKey_Callback_1_(mthis, __arg_0) => mthis.callMethod("webkitAddKey", [__arg_0]);

  webkitAddKey_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("webkitAddKey", [__arg_0, __arg_1]);

  webkitAddKey_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("webkitAddKey", [__arg_0, __arg_1, __arg_2]);

  webkitAddKey_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("webkitAddKey", [__arg_0, __arg_1, __arg_2, __arg_3]);

  webkitAudioDecodedByteCount_Getter_(mthis) => mthis["webkitAudioDecodedByteCount"];

  webkitCancelKeyRequest_Callback_0_(mthis) => mthis.callMethod("webkitCancelKeyRequest", []);

  webkitCancelKeyRequest_Callback_1_(mthis, __arg_0) => mthis.callMethod("webkitCancelKeyRequest", [__arg_0]);

  webkitCancelKeyRequest_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("webkitCancelKeyRequest", [__arg_0, __arg_1]);

  webkitGenerateKeyRequest_Callback_0_(mthis) => mthis.callMethod("webkitGenerateKeyRequest", []);

  webkitGenerateKeyRequest_Callback_1_(mthis, __arg_0) => mthis.callMethod("webkitGenerateKeyRequest", [__arg_0]);

  webkitGenerateKeyRequest_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("webkitGenerateKeyRequest", [__arg_0, __arg_1]);

  webkitVideoDecodedByteCount_Getter_(mthis) => mthis["webkitVideoDecodedByteCount"];

}

class BlinkHTMLMenuElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLMenuElement();

  label_Getter_(mthis) => mthis["label"];

  label_Setter_(mthis, __arg_0) => mthis["label"] = __arg_0;

  type_Getter_(mthis) => mthis["type"];

  type_Setter_(mthis, __arg_0) => mthis["type"] = __arg_0;

}

class BlinkHTMLMenuItemElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLMenuItemElement();

  checked_Getter_(mthis) => mthis["checked"];

  checked_Setter_(mthis, __arg_0) => mthis["checked"] = __arg_0;

  default_Getter_(mthis) => mthis["default"];

  default_Setter_(mthis, __arg_0) => mthis["default"] = __arg_0;

  disabled_Getter_(mthis) => mthis["disabled"];

  disabled_Setter_(mthis, __arg_0) => mthis["disabled"] = __arg_0;

  label_Getter_(mthis) => mthis["label"];

  label_Setter_(mthis, __arg_0) => mthis["label"] = __arg_0;

  type_Getter_(mthis) => mthis["type"];

  type_Setter_(mthis, __arg_0) => mthis["type"] = __arg_0;

}

class BlinkHTMLMetaElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLMetaElement();

  content_Getter_(mthis) => mthis["content"];

  content_Setter_(mthis, __arg_0) => mthis["content"] = __arg_0;

  httpEquiv_Getter_(mthis) => mthis["httpEquiv"];

  httpEquiv_Setter_(mthis, __arg_0) => mthis["httpEquiv"] = __arg_0;

  name_Getter_(mthis) => mthis["name"];

  name_Setter_(mthis, __arg_0) => mthis["name"] = __arg_0;

}

class BlinkHTMLMeterElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLMeterElement();

  high_Getter_(mthis) => mthis["high"];

  high_Setter_(mthis, __arg_0) => mthis["high"] = __arg_0;

  labels_Getter_(mthis) => mthis["labels"];

  low_Getter_(mthis) => mthis["low"];

  low_Setter_(mthis, __arg_0) => mthis["low"] = __arg_0;

  max_Getter_(mthis) => mthis["max"];

  max_Setter_(mthis, __arg_0) => mthis["max"] = __arg_0;

  min_Getter_(mthis) => mthis["min"];

  min_Setter_(mthis, __arg_0) => mthis["min"] = __arg_0;

  optimum_Getter_(mthis) => mthis["optimum"];

  optimum_Setter_(mthis, __arg_0) => mthis["optimum"] = __arg_0;

  value_Getter_(mthis) => mthis["value"];

  value_Setter_(mthis, __arg_0) => mthis["value"] = __arg_0;

}

class BlinkHTMLModElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLModElement();

  cite_Getter_(mthis) => mthis["cite"];

  cite_Setter_(mthis, __arg_0) => mthis["cite"] = __arg_0;

  dateTime_Getter_(mthis) => mthis["dateTime"];

  dateTime_Setter_(mthis, __arg_0) => mthis["dateTime"] = __arg_0;

}

class BlinkHTMLOListElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLOListElement();

  reversed_Getter_(mthis) => mthis["reversed"];

  reversed_Setter_(mthis, __arg_0) => mthis["reversed"] = __arg_0;

  start_Getter_(mthis) => mthis["start"];

  start_Setter_(mthis, __arg_0) => mthis["start"] = __arg_0;

  type_Getter_(mthis) => mthis["type"];

  type_Setter_(mthis, __arg_0) => mthis["type"] = __arg_0;

}

class BlinkHTMLObjectElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLObjectElement();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  $__setter___Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("__setter__", [__arg_0, __arg_1]);

  checkValidity_Callback_0_(mthis) => mthis.callMethod("checkValidity", []);

  code_Getter_(mthis) => mthis["code"];

  code_Setter_(mthis, __arg_0) => mthis["code"] = __arg_0;

  contentDocument_Getter_(mthis) => mthis["contentDocument"];

  data_Getter_(mthis) => mthis["data"];

  data_Setter_(mthis, __arg_0) => mthis["data"] = __arg_0;

  form_Getter_(mthis) => mthis["form"];

  getSVGDocument_Callback_0_(mthis) => mthis.callMethod("getSVGDocument", []);

  height_Getter_(mthis) => mthis["height"];

  height_Setter_(mthis, __arg_0) => mthis["height"] = __arg_0;

  integrity_Getter_(mthis) => mthis["integrity"];

  integrity_Setter_(mthis, __arg_0) => mthis["integrity"] = __arg_0;

  name_Getter_(mthis) => mthis["name"];

  name_Setter_(mthis, __arg_0) => mthis["name"] = __arg_0;

  setCustomValidity_Callback_0_(mthis) => mthis.callMethod("setCustomValidity", []);

  setCustomValidity_Callback_1_(mthis, __arg_0) => mthis.callMethod("setCustomValidity", [__arg_0]);

  type_Getter_(mthis) => mthis["type"];

  type_Setter_(mthis, __arg_0) => mthis["type"] = __arg_0;

  useMap_Getter_(mthis) => mthis["useMap"];

  useMap_Setter_(mthis, __arg_0) => mthis["useMap"] = __arg_0;

  validationMessage_Getter_(mthis) => mthis["validationMessage"];

  validity_Getter_(mthis) => mthis["validity"];

  width_Getter_(mthis) => mthis["width"];

  width_Setter_(mthis, __arg_0) => mthis["width"] = __arg_0;

  willValidate_Getter_(mthis) => mthis["willValidate"];

}

class BlinkHTMLOptGroupElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLOptGroupElement();

  disabled_Getter_(mthis) => mthis["disabled"];

  disabled_Setter_(mthis, __arg_0) => mthis["disabled"] = __arg_0;

  label_Getter_(mthis) => mthis["label"];

  label_Setter_(mthis, __arg_0) => mthis["label"] = __arg_0;

}

class BlinkHTMLOptionElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLOptionElement();

  constructorCallback_0_() => new js.JsObject(js.context["Option"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["Option"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["Option"], [__arg_0, __arg_1]);

  constructorCallback_3_(__arg_0, __arg_1, __arg_2) => new js.JsObject(js.context["Option"], [__arg_0, __arg_1, __arg_2]);

  constructorCallback_4_(__arg_0, __arg_1, __arg_2, __arg_3) => new js.JsObject(js.context["Option"], [__arg_0, __arg_1, __arg_2, __arg_3]);

  defaultSelected_Getter_(mthis) => mthis["defaultSelected"];

  defaultSelected_Setter_(mthis, __arg_0) => mthis["defaultSelected"] = __arg_0;

  disabled_Getter_(mthis) => mthis["disabled"];

  disabled_Setter_(mthis, __arg_0) => mthis["disabled"] = __arg_0;

  form_Getter_(mthis) => mthis["form"];

  index_Getter_(mthis) => mthis["index"];

  label_Getter_(mthis) => mthis["label"];

  label_Setter_(mthis, __arg_0) => mthis["label"] = __arg_0;

  selected_Getter_(mthis) => mthis["selected"];

  selected_Setter_(mthis, __arg_0) => mthis["selected"] = __arg_0;

  value_Getter_(mthis) => mthis["value"];

  value_Setter_(mthis, __arg_0) => mthis["value"] = __arg_0;

}

class BlinkHTMLOptionsCollection extends BlinkHTMLCollection {
  static final instance = new BlinkHTMLOptionsCollection();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  $__setter___Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("__setter__", [__arg_0, __arg_1]);

}

class BlinkHTMLOutputElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLOutputElement();

  checkValidity_Callback_0_(mthis) => mthis.callMethod("checkValidity", []);

  defaultValue_Getter_(mthis) => mthis["defaultValue"];

  defaultValue_Setter_(mthis, __arg_0) => mthis["defaultValue"] = __arg_0;

  form_Getter_(mthis) => mthis["form"];

  htmlFor_Getter_(mthis) => mthis["htmlFor"];

  htmlFor_Setter_(mthis, __arg_0) => mthis["htmlFor"] = __arg_0;

  labels_Getter_(mthis) => mthis["labels"];

  name_Getter_(mthis) => mthis["name"];

  name_Setter_(mthis, __arg_0) => mthis["name"] = __arg_0;

  setCustomValidity_Callback_0_(mthis) => mthis.callMethod("setCustomValidity", []);

  setCustomValidity_Callback_1_(mthis, __arg_0) => mthis.callMethod("setCustomValidity", [__arg_0]);

  type_Getter_(mthis) => mthis["type"];

  validationMessage_Getter_(mthis) => mthis["validationMessage"];

  validity_Getter_(mthis) => mthis["validity"];

  value_Getter_(mthis) => mthis["value"];

  value_Setter_(mthis, __arg_0) => mthis["value"] = __arg_0;

  willValidate_Getter_(mthis) => mthis["willValidate"];

}

class BlinkHTMLParagraphElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLParagraphElement();

}

class BlinkHTMLParamElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLParamElement();

  name_Getter_(mthis) => mthis["name"];

  name_Setter_(mthis, __arg_0) => mthis["name"] = __arg_0;

  value_Getter_(mthis) => mthis["value"];

  value_Setter_(mthis, __arg_0) => mthis["value"] = __arg_0;

}

class BlinkHTMLPictureElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLPictureElement();

}

class BlinkHTMLPreElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLPreElement();

}

class BlinkHTMLProgressElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLProgressElement();

  labels_Getter_(mthis) => mthis["labels"];

  max_Getter_(mthis) => mthis["max"];

  max_Setter_(mthis, __arg_0) => mthis["max"] = __arg_0;

  position_Getter_(mthis) => mthis["position"];

  value_Getter_(mthis) => mthis["value"];

  value_Setter_(mthis, __arg_0) => mthis["value"] = __arg_0;

}

class BlinkHTMLQuoteElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLQuoteElement();

  cite_Getter_(mthis) => mthis["cite"];

  cite_Setter_(mthis, __arg_0) => mthis["cite"] = __arg_0;

}

class BlinkHTMLScriptElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLScriptElement();

  async_Getter_(mthis) => mthis["async"];

  async_Setter_(mthis, __arg_0) => mthis["async"] = __arg_0;

  charset_Getter_(mthis) => mthis["charset"];

  charset_Setter_(mthis, __arg_0) => mthis["charset"] = __arg_0;

  crossOrigin_Getter_(mthis) => mthis["crossOrigin"];

  crossOrigin_Setter_(mthis, __arg_0) => mthis["crossOrigin"] = __arg_0;

  defer_Getter_(mthis) => mthis["defer"];

  defer_Setter_(mthis, __arg_0) => mthis["defer"] = __arg_0;

  event_Getter_(mthis) => mthis["event"];

  event_Setter_(mthis, __arg_0) => mthis["event"] = __arg_0;

  htmlFor_Getter_(mthis) => mthis["htmlFor"];

  htmlFor_Setter_(mthis, __arg_0) => mthis["htmlFor"] = __arg_0;

  integrity_Getter_(mthis) => mthis["integrity"];

  integrity_Setter_(mthis, __arg_0) => mthis["integrity"] = __arg_0;

  nonce_Getter_(mthis) => mthis["nonce"];

  nonce_Setter_(mthis, __arg_0) => mthis["nonce"] = __arg_0;

  src_Getter_(mthis) => mthis["src"];

  src_Setter_(mthis, __arg_0) => mthis["src"] = __arg_0;

  type_Getter_(mthis) => mthis["type"];

  type_Setter_(mthis, __arg_0) => mthis["type"] = __arg_0;

}

class BlinkHTMLSelectElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLSelectElement();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  $__setter___Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("__setter__", [__arg_0, __arg_1]);

  add_Callback_0_(mthis) => mthis.callMethod("add", []);

  add_Callback_1_(mthis, __arg_0) => mthis.callMethod("add", [__arg_0]);

  add_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("add", [__arg_0, __arg_1]);

  autofocus_Getter_(mthis) => mthis["autofocus"];

  autofocus_Setter_(mthis, __arg_0) => mthis["autofocus"] = __arg_0;

  checkValidity_Callback_0_(mthis) => mthis.callMethod("checkValidity", []);

  disabled_Getter_(mthis) => mthis["disabled"];

  disabled_Setter_(mthis, __arg_0) => mthis["disabled"] = __arg_0;

  form_Getter_(mthis) => mthis["form"];

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  labels_Getter_(mthis) => mthis["labels"];

  length_Getter_(mthis) => mthis["length"];

  length_Setter_(mthis, __arg_0) => mthis["length"] = __arg_0;

  multiple_Getter_(mthis) => mthis["multiple"];

  multiple_Setter_(mthis, __arg_0) => mthis["multiple"] = __arg_0;

  name_Getter_(mthis) => mthis["name"];

  name_Setter_(mthis, __arg_0) => mthis["name"] = __arg_0;

  namedItem_Callback_0_(mthis) => mthis.callMethod("namedItem", []);

  namedItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("namedItem", [__arg_0]);

  required_Getter_(mthis) => mthis["required"];

  required_Setter_(mthis, __arg_0) => mthis["required"] = __arg_0;

  selectedIndex_Getter_(mthis) => mthis["selectedIndex"];

  selectedIndex_Setter_(mthis, __arg_0) => mthis["selectedIndex"] = __arg_0;

  setCustomValidity_Callback_0_(mthis) => mthis.callMethod("setCustomValidity", []);

  setCustomValidity_Callback_1_(mthis, __arg_0) => mthis.callMethod("setCustomValidity", [__arg_0]);

  size_Getter_(mthis) => mthis["size"];

  size_Setter_(mthis, __arg_0) => mthis["size"] = __arg_0;

  type_Getter_(mthis) => mthis["type"];

  validationMessage_Getter_(mthis) => mthis["validationMessage"];

  validity_Getter_(mthis) => mthis["validity"];

  value_Getter_(mthis) => mthis["value"];

  value_Setter_(mthis, __arg_0) => mthis["value"] = __arg_0;

  willValidate_Getter_(mthis) => mthis["willValidate"];

}

class BlinkHTMLShadowElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLShadowElement();

  getDistributedNodes_Callback_0_(mthis) => mthis.callMethod("getDistributedNodes", []);

}

class BlinkHTMLSourceElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLSourceElement();

  integrity_Getter_(mthis) => mthis["integrity"];

  integrity_Setter_(mthis, __arg_0) => mthis["integrity"] = __arg_0;

  media_Getter_(mthis) => mthis["media"];

  media_Setter_(mthis, __arg_0) => mthis["media"] = __arg_0;

  sizes_Getter_(mthis) => mthis["sizes"];

  sizes_Setter_(mthis, __arg_0) => mthis["sizes"] = __arg_0;

  src_Getter_(mthis) => mthis["src"];

  src_Setter_(mthis, __arg_0) => mthis["src"] = __arg_0;

  srcset_Getter_(mthis) => mthis["srcset"];

  srcset_Setter_(mthis, __arg_0) => mthis["srcset"] = __arg_0;

  type_Getter_(mthis) => mthis["type"];

  type_Setter_(mthis, __arg_0) => mthis["type"] = __arg_0;

}

class BlinkHTMLSpanElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLSpanElement();

}

class BlinkHTMLStyleElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLStyleElement();

  disabled_Getter_(mthis) => mthis["disabled"];

  disabled_Setter_(mthis, __arg_0) => mthis["disabled"] = __arg_0;

  media_Getter_(mthis) => mthis["media"];

  media_Setter_(mthis, __arg_0) => mthis["media"] = __arg_0;

  sheet_Getter_(mthis) => mthis["sheet"];

  type_Getter_(mthis) => mthis["type"];

  type_Setter_(mthis, __arg_0) => mthis["type"] = __arg_0;

}

class BlinkHTMLTableCaptionElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLTableCaptionElement();

}

class BlinkHTMLTableCellElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLTableCellElement();

  cellIndex_Getter_(mthis) => mthis["cellIndex"];

  colSpan_Getter_(mthis) => mthis["colSpan"];

  colSpan_Setter_(mthis, __arg_0) => mthis["colSpan"] = __arg_0;

  headers_Getter_(mthis) => mthis["headers"];

  headers_Setter_(mthis, __arg_0) => mthis["headers"] = __arg_0;

  rowSpan_Getter_(mthis) => mthis["rowSpan"];

  rowSpan_Setter_(mthis, __arg_0) => mthis["rowSpan"] = __arg_0;

}

class BlinkHTMLTableColElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLTableColElement();

  span_Getter_(mthis) => mthis["span"];

  span_Setter_(mthis, __arg_0) => mthis["span"] = __arg_0;

}

class BlinkHTMLTableElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLTableElement();

  border_Getter_(mthis) => mthis["border"];

  border_Setter_(mthis, __arg_0) => mthis["border"] = __arg_0;

  caption_Getter_(mthis) => mthis["caption"];

  caption_Setter_(mthis, __arg_0) => mthis["caption"] = __arg_0;

  createCaption_Callback_0_(mthis) => mthis.callMethod("createCaption", []);

  createTBody_Callback_0_(mthis) => mthis.callMethod("createTBody", []);

  createTFoot_Callback_0_(mthis) => mthis.callMethod("createTFoot", []);

  createTHead_Callback_0_(mthis) => mthis.callMethod("createTHead", []);

  deleteCaption_Callback_0_(mthis) => mthis.callMethod("deleteCaption", []);

  deleteRow_Callback_0_(mthis) => mthis.callMethod("deleteRow", []);

  deleteRow_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteRow", [__arg_0]);

  deleteTFoot_Callback_0_(mthis) => mthis.callMethod("deleteTFoot", []);

  deleteTHead_Callback_0_(mthis) => mthis.callMethod("deleteTHead", []);

  insertRow_Callback_0_(mthis) => mthis.callMethod("insertRow", []);

  insertRow_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertRow", [__arg_0]);

  rows_Getter_(mthis) => mthis["rows"];

  tBodies_Getter_(mthis) => mthis["tBodies"];

  tFoot_Getter_(mthis) => mthis["tFoot"];

  tFoot_Setter_(mthis, __arg_0) => mthis["tFoot"] = __arg_0;

  tHead_Getter_(mthis) => mthis["tHead"];

  tHead_Setter_(mthis, __arg_0) => mthis["tHead"] = __arg_0;

}

class BlinkHTMLTableRowElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLTableRowElement();

  cells_Getter_(mthis) => mthis["cells"];

  deleteCell_Callback_0_(mthis) => mthis.callMethod("deleteCell", []);

  deleteCell_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteCell", [__arg_0]);

  insertCell_Callback_0_(mthis) => mthis.callMethod("insertCell", []);

  insertCell_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertCell", [__arg_0]);

  rowIndex_Getter_(mthis) => mthis["rowIndex"];

  sectionRowIndex_Getter_(mthis) => mthis["sectionRowIndex"];

}

class BlinkHTMLTableSectionElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLTableSectionElement();

  deleteRow_Callback_0_(mthis) => mthis.callMethod("deleteRow", []);

  deleteRow_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteRow", [__arg_0]);

  insertRow_Callback_0_(mthis) => mthis.callMethod("insertRow", []);

  insertRow_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertRow", [__arg_0]);

  rows_Getter_(mthis) => mthis["rows"];

}

class BlinkHTMLTemplateElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLTemplateElement();

  content_Getter_(mthis) => mthis["content"];

}

class BlinkHTMLTextAreaElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLTextAreaElement();

  autofocus_Getter_(mthis) => mthis["autofocus"];

  autofocus_Setter_(mthis, __arg_0) => mthis["autofocus"] = __arg_0;

  checkValidity_Callback_0_(mthis) => mthis.callMethod("checkValidity", []);

  cols_Getter_(mthis) => mthis["cols"];

  cols_Setter_(mthis, __arg_0) => mthis["cols"] = __arg_0;

  defaultValue_Getter_(mthis) => mthis["defaultValue"];

  defaultValue_Setter_(mthis, __arg_0) => mthis["defaultValue"] = __arg_0;

  dirName_Getter_(mthis) => mthis["dirName"];

  dirName_Setter_(mthis, __arg_0) => mthis["dirName"] = __arg_0;

  disabled_Getter_(mthis) => mthis["disabled"];

  disabled_Setter_(mthis, __arg_0) => mthis["disabled"] = __arg_0;

  form_Getter_(mthis) => mthis["form"];

  inputMode_Getter_(mthis) => mthis["inputMode"];

  inputMode_Setter_(mthis, __arg_0) => mthis["inputMode"] = __arg_0;

  labels_Getter_(mthis) => mthis["labels"];

  maxLength_Getter_(mthis) => mthis["maxLength"];

  maxLength_Setter_(mthis, __arg_0) => mthis["maxLength"] = __arg_0;

  name_Getter_(mthis) => mthis["name"];

  name_Setter_(mthis, __arg_0) => mthis["name"] = __arg_0;

  placeholder_Getter_(mthis) => mthis["placeholder"];

  placeholder_Setter_(mthis, __arg_0) => mthis["placeholder"] = __arg_0;

  readOnly_Getter_(mthis) => mthis["readOnly"];

  readOnly_Setter_(mthis, __arg_0) => mthis["readOnly"] = __arg_0;

  required_Getter_(mthis) => mthis["required"];

  required_Setter_(mthis, __arg_0) => mthis["required"] = __arg_0;

  rows_Getter_(mthis) => mthis["rows"];

  rows_Setter_(mthis, __arg_0) => mthis["rows"] = __arg_0;

  select_Callback_0_(mthis) => mthis.callMethod("select", []);

  selectionDirection_Getter_(mthis) => mthis["selectionDirection"];

  selectionDirection_Setter_(mthis, __arg_0) => mthis["selectionDirection"] = __arg_0;

  selectionEnd_Getter_(mthis) => mthis["selectionEnd"];

  selectionEnd_Setter_(mthis, __arg_0) => mthis["selectionEnd"] = __arg_0;

  selectionStart_Getter_(mthis) => mthis["selectionStart"];

  selectionStart_Setter_(mthis, __arg_0) => mthis["selectionStart"] = __arg_0;

  setCustomValidity_Callback_0_(mthis) => mthis.callMethod("setCustomValidity", []);

  setCustomValidity_Callback_1_(mthis, __arg_0) => mthis.callMethod("setCustomValidity", [__arg_0]);

  setRangeText_Callback_0_(mthis) => mthis.callMethod("setRangeText", []);

  setRangeText_Callback_1_(mthis, __arg_0) => mthis.callMethod("setRangeText", [__arg_0]);

  setRangeText_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setRangeText", [__arg_0, __arg_1]);

  setRangeText_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setRangeText", [__arg_0, __arg_1, __arg_2]);

  setRangeText_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("setRangeText", [__arg_0, __arg_1, __arg_2, __arg_3]);

  setSelectionRange_Callback_0_(mthis) => mthis.callMethod("setSelectionRange", []);

  setSelectionRange_Callback_1_(mthis, __arg_0) => mthis.callMethod("setSelectionRange", [__arg_0]);

  setSelectionRange_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setSelectionRange", [__arg_0, __arg_1]);

  setSelectionRange_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setSelectionRange", [__arg_0, __arg_1, __arg_2]);

  textLength_Getter_(mthis) => mthis["textLength"];

  type_Getter_(mthis) => mthis["type"];

  validationMessage_Getter_(mthis) => mthis["validationMessage"];

  validity_Getter_(mthis) => mthis["validity"];

  value_Getter_(mthis) => mthis["value"];

  value_Setter_(mthis, __arg_0) => mthis["value"] = __arg_0;

  willValidate_Getter_(mthis) => mthis["willValidate"];

  wrap_Getter_(mthis) => mthis["wrap"];

  wrap_Setter_(mthis, __arg_0) => mthis["wrap"] = __arg_0;

}

class BlinkHTMLTitleElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLTitleElement();

}

class BlinkHTMLTrackElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLTrackElement();

  default_Getter_(mthis) => mthis["default"];

  default_Setter_(mthis, __arg_0) => mthis["default"] = __arg_0;

  integrity_Getter_(mthis) => mthis["integrity"];

  integrity_Setter_(mthis, __arg_0) => mthis["integrity"] = __arg_0;

  kind_Getter_(mthis) => mthis["kind"];

  kind_Setter_(mthis, __arg_0) => mthis["kind"] = __arg_0;

  label_Getter_(mthis) => mthis["label"];

  label_Setter_(mthis, __arg_0) => mthis["label"] = __arg_0;

  readyState_Getter_(mthis) => mthis["readyState"];

  src_Getter_(mthis) => mthis["src"];

  src_Setter_(mthis, __arg_0) => mthis["src"] = __arg_0;

  srclang_Getter_(mthis) => mthis["srclang"];

  srclang_Setter_(mthis, __arg_0) => mthis["srclang"] = __arg_0;

  track_Getter_(mthis) => mthis["track"];

}

class BlinkHTMLUListElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLUListElement();

}

class BlinkHTMLUnknownElement extends BlinkHTMLElement {
  static final instance = new BlinkHTMLUnknownElement();

}

class BlinkHTMLVideoElement extends BlinkHTMLMediaElement {
  static final instance = new BlinkHTMLVideoElement();

  getVideoPlaybackQuality_Callback_0_(mthis) => mthis.callMethod("getVideoPlaybackQuality", []);

  height_Getter_(mthis) => mthis["height"];

  height_Setter_(mthis, __arg_0) => mthis["height"] = __arg_0;

  poster_Getter_(mthis) => mthis["poster"];

  poster_Setter_(mthis, __arg_0) => mthis["poster"] = __arg_0;

  videoHeight_Getter_(mthis) => mthis["videoHeight"];

  videoWidth_Getter_(mthis) => mthis["videoWidth"];

  webkitDecodedFrameCount_Getter_(mthis) => mthis["webkitDecodedFrameCount"];

  webkitDisplayingFullscreen_Getter_(mthis) => mthis["webkitDisplayingFullscreen"];

  webkitDroppedFrameCount_Getter_(mthis) => mthis["webkitDroppedFrameCount"];

  webkitEnterFullScreen_Callback_0_(mthis) => mthis.callMethod("webkitEnterFullScreen", []);

  webkitEnterFullscreen_Callback_0_(mthis) => mthis.callMethod("webkitEnterFullscreen", []);

  webkitExitFullScreen_Callback_0_(mthis) => mthis.callMethod("webkitExitFullScreen", []);

  webkitExitFullscreen_Callback_0_(mthis) => mthis.callMethod("webkitExitFullscreen", []);

  webkitSupportsFullscreen_Getter_(mthis) => mthis["webkitSupportsFullscreen"];

  width_Getter_(mthis) => mthis["width"];

  width_Setter_(mthis, __arg_0) => mthis["width"] = __arg_0;

}

class BlinkHashChangeEvent extends BlinkEvent {
  static final instance = new BlinkHashChangeEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["HashChangeEvent"], [__arg_0, __arg_1]);

  initHashChangeEvent_Callback_0_(mthis) => mthis.callMethod("initHashChangeEvent", []);

  initHashChangeEvent_Callback_1_(mthis, __arg_0) => mthis.callMethod("initHashChangeEvent", [__arg_0]);

  initHashChangeEvent_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("initHashChangeEvent", [__arg_0, __arg_1]);

  initHashChangeEvent_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("initHashChangeEvent", [__arg_0, __arg_1, __arg_2]);

  initHashChangeEvent_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("initHashChangeEvent", [__arg_0, __arg_1, __arg_2, __arg_3]);

  initHashChangeEvent_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("initHashChangeEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  newURL_Getter_(mthis) => mthis["newURL"];

  oldURL_Getter_(mthis) => mthis["oldURL"];

}

class BlinkHeaders {
  static final instance = new BlinkHeaders();

  append_Callback_0_(mthis) => mthis.callMethod("append", []);

  append_Callback_1_(mthis, __arg_0) => mthis.callMethod("append", [__arg_0]);

  append_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("append", [__arg_0, __arg_1]);

  constructorCallback_0_() => new js.JsObject(js.context["Headers"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["Headers"], [__arg_0]);

  delete_Callback_0_(mthis) => mthis.callMethod("delete", []);

  delete_Callback_1_(mthis, __arg_0) => mthis.callMethod("delete", [__arg_0]);

  forEach_Callback_0_(mthis) => mthis.callMethod("forEach", []);

  forEach_Callback_1_(mthis, __arg_0) => mthis.callMethod("forEach", [__arg_0]);

  forEach_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("forEach", [__arg_0, __arg_1]);

  getAll_Callback_0_(mthis) => mthis.callMethod("getAll", []);

  getAll_Callback_1_(mthis, __arg_0) => mthis.callMethod("getAll", [__arg_0]);

  get_Callback_0_(mthis) => mthis.callMethod("get", []);

  get_Callback_1_(mthis, __arg_0) => mthis.callMethod("get", [__arg_0]);

  has_Callback_0_(mthis) => mthis.callMethod("has", []);

  has_Callback_1_(mthis, __arg_0) => mthis.callMethod("has", [__arg_0]);

  set_Callback_0_(mthis) => mthis.callMethod("set", []);

  set_Callback_1_(mthis, __arg_0) => mthis.callMethod("set", [__arg_0]);

  set_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("set", [__arg_0, __arg_1]);

  size_Getter_(mthis) => mthis["size"];

}

class BlinkHistory {
  static final instance = new BlinkHistory();

  back_Callback_0_(mthis) => mthis.callMethod("back", []);

  forward_Callback_0_(mthis) => mthis.callMethod("forward", []);

  go_Callback_0_(mthis) => mthis.callMethod("go", []);

  go_Callback_1_(mthis, __arg_0) => mthis.callMethod("go", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

  pushState_Callback_0_(mthis) => mthis.callMethod("pushState", []);

  pushState_Callback_1_(mthis, __arg_0) => mthis.callMethod("pushState", [__arg_0]);

  pushState_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("pushState", [__arg_0, __arg_1]);

  pushState_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("pushState", [__arg_0, __arg_1, __arg_2]);

  replaceState_Callback_0_(mthis) => mthis.callMethod("replaceState", []);

  replaceState_Callback_1_(mthis, __arg_0) => mthis.callMethod("replaceState", [__arg_0]);

  replaceState_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("replaceState", [__arg_0, __arg_1]);

  replaceState_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("replaceState", [__arg_0, __arg_1, __arg_2]);

  state_Getter_(mthis) => mthis["state"];

}

class BlinkIDBCursor {
  static final instance = new BlinkIDBCursor();

  advance_Callback_0_(mthis) => mthis.callMethod("advance", []);

  advance_Callback_1_(mthis, __arg_0) => mthis.callMethod("advance", [__arg_0]);

  continuePrimaryKey_Callback_0_(mthis) => mthis.callMethod("continuePrimaryKey", []);

  continuePrimaryKey_Callback_1_(mthis, __arg_0) => mthis.callMethod("continuePrimaryKey", [__arg_0]);

  continuePrimaryKey_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("continuePrimaryKey", [__arg_0, __arg_1]);

  continue_Callback_0_(mthis) => mthis.callMethod("continue", []);

  continue_Callback_1_(mthis, __arg_0) => mthis.callMethod("continue", [__arg_0]);

  delete_Callback_0_(mthis) => mthis.callMethod("delete", []);

  direction_Getter_(mthis) => mthis["direction"];

  key_Getter_(mthis) => mthis["key"];

  primaryKey_Getter_(mthis) => mthis["primaryKey"];

  source_Getter_(mthis) => mthis["source"];

  update_Callback_0_(mthis) => mthis.callMethod("update", []);

  update_Callback_1_(mthis, __arg_0) => mthis.callMethod("update", [__arg_0]);

}

class BlinkIDBCursorWithValue extends BlinkIDBCursor {
  static final instance = new BlinkIDBCursorWithValue();

  value_Getter_(mthis) => mthis["value"];

}

class BlinkIDBDatabase extends BlinkEventTarget {
  static final instance = new BlinkIDBDatabase();

  close_Callback_0_(mthis) => mthis.callMethod("close", []);

  createObjectStore_Callback_0_(mthis) => mthis.callMethod("createObjectStore", []);

  createObjectStore_Callback_1_(mthis, __arg_0) => mthis.callMethod("createObjectStore", [__arg_0]);

  createObjectStore_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createObjectStore", [__arg_0, __arg_1]);

  deleteObjectStore_Callback_0_(mthis) => mthis.callMethod("deleteObjectStore", []);

  deleteObjectStore_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteObjectStore", [__arg_0]);

  name_Getter_(mthis) => mthis["name"];

  objectStoreNames_Getter_(mthis) => mthis["objectStoreNames"];

  onabort_Getter_(mthis) => mthis["onabort"];

  onabort_Setter_(mthis, __arg_0) => mthis["onabort"] = __arg_0;

  onclose_Getter_(mthis) => mthis["onclose"];

  onclose_Setter_(mthis, __arg_0) => mthis["onclose"] = __arg_0;

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onversionchange_Getter_(mthis) => mthis["onversionchange"];

  onversionchange_Setter_(mthis, __arg_0) => mthis["onversionchange"] = __arg_0;

  transaction_Callback_0_(mthis) => mthis.callMethod("transaction", []);

  transaction_Callback_1_(mthis, __arg_0) => mthis.callMethod("transaction", [__arg_0]);

  transaction_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("transaction", [__arg_0, __arg_1]);

  version_Getter_(mthis) => mthis["version"];

}

class BlinkIDBFactory {
  static final instance = new BlinkIDBFactory();

  cmp_Callback_0_(mthis) => mthis.callMethod("cmp", []);

  cmp_Callback_1_(mthis, __arg_0) => mthis.callMethod("cmp", [__arg_0]);

  cmp_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("cmp", [__arg_0, __arg_1]);

  deleteDatabase_Callback_0_(mthis) => mthis.callMethod("deleteDatabase", []);

  deleteDatabase_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteDatabase", [__arg_0]);

  open_Callback_0_(mthis) => mthis.callMethod("open", []);

  open_Callback_1_(mthis, __arg_0) => mthis.callMethod("open", [__arg_0]);

  open_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("open", [__arg_0, __arg_1]);

  webkitGetDatabaseNames_Callback_0_(mthis) => mthis.callMethod("webkitGetDatabaseNames", []);

}

class BlinkIDBIndex {
  static final instance = new BlinkIDBIndex();

  count_Callback_0_(mthis) => mthis.callMethod("count", []);

  count_Callback_1_(mthis, __arg_0) => mthis.callMethod("count", [__arg_0]);

  getKey_Callback_0_(mthis) => mthis.callMethod("getKey", []);

  getKey_Callback_1_(mthis, __arg_0) => mthis.callMethod("getKey", [__arg_0]);

  get_Callback_0_(mthis) => mthis.callMethod("get", []);

  get_Callback_1_(mthis, __arg_0) => mthis.callMethod("get", [__arg_0]);

  keyPath_Getter_(mthis) => mthis["keyPath"];

  multiEntry_Getter_(mthis) => mthis["multiEntry"];

  name_Getter_(mthis) => mthis["name"];

  objectStore_Getter_(mthis) => mthis["objectStore"];

  openCursor_Callback_0_(mthis) => mthis.callMethod("openCursor", []);

  openCursor_Callback_1_(mthis, __arg_0) => mthis.callMethod("openCursor", [__arg_0]);

  openCursor_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("openCursor", [__arg_0, __arg_1]);

  openKeyCursor_Callback_0_(mthis) => mthis.callMethod("openKeyCursor", []);

  openKeyCursor_Callback_1_(mthis, __arg_0) => mthis.callMethod("openKeyCursor", [__arg_0]);

  openKeyCursor_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("openKeyCursor", [__arg_0, __arg_1]);

  unique_Getter_(mthis) => mthis["unique"];

}

class BlinkIDBKeyRange {
  static final instance = new BlinkIDBKeyRange();

  bound_Callback_0_() => js.context["IDBKeyRange"].callMethod("bound", []);

  bound_Callback_1_(__arg_0) => js.context["IDBKeyRange"].callMethod("bound", [__arg_0]);

  bound_Callback_2_(__arg_0, __arg_1) => js.context["IDBKeyRange"].callMethod("bound", [__arg_0, __arg_1]);

  bound_Callback_3_(__arg_0, __arg_1, __arg_2) => js.context["IDBKeyRange"].callMethod("bound", [__arg_0, __arg_1, __arg_2]);

  bound_Callback_4_(__arg_0, __arg_1, __arg_2, __arg_3) => js.context["IDBKeyRange"].callMethod("bound", [__arg_0, __arg_1, __arg_2, __arg_3]);

  lowerBound_Callback_0_() => js.context["IDBKeyRange"].callMethod("lowerBound", []);

  lowerBound_Callback_1_(__arg_0) => js.context["IDBKeyRange"].callMethod("lowerBound", [__arg_0]);

  lowerBound_Callback_2_(__arg_0, __arg_1) => js.context["IDBKeyRange"].callMethod("lowerBound", [__arg_0, __arg_1]);

  lowerOpen_Getter_(mthis) => mthis["lowerOpen"];

  lower_Getter_(mthis) => mthis["lower"];

  only_Callback_0_() => js.context["IDBKeyRange"].callMethod("only", []);

  only_Callback_1_(__arg_0) => js.context["IDBKeyRange"].callMethod("only", [__arg_0]);

  upperBound_Callback_0_() => js.context["IDBKeyRange"].callMethod("upperBound", []);

  upperBound_Callback_1_(__arg_0) => js.context["IDBKeyRange"].callMethod("upperBound", [__arg_0]);

  upperBound_Callback_2_(__arg_0, __arg_1) => js.context["IDBKeyRange"].callMethod("upperBound", [__arg_0, __arg_1]);

  upperOpen_Getter_(mthis) => mthis["upperOpen"];

  upper_Getter_(mthis) => mthis["upper"];

}

class BlinkIDBObjectStore {
  static final instance = new BlinkIDBObjectStore();

  add_Callback_0_(mthis) => mthis.callMethod("add", []);

  add_Callback_1_(mthis, __arg_0) => mthis.callMethod("add", [__arg_0]);

  add_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("add", [__arg_0, __arg_1]);

  autoIncrement_Getter_(mthis) => mthis["autoIncrement"];

  clear_Callback_0_(mthis) => mthis.callMethod("clear", []);

  count_Callback_0_(mthis) => mthis.callMethod("count", []);

  count_Callback_1_(mthis, __arg_0) => mthis.callMethod("count", [__arg_0]);

  createIndex_Callback_0_(mthis) => mthis.callMethod("createIndex", []);

  createIndex_Callback_1_(mthis, __arg_0) => mthis.callMethod("createIndex", [__arg_0]);

  createIndex_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createIndex", [__arg_0, __arg_1]);

  createIndex_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("createIndex", [__arg_0, __arg_1, __arg_2]);

  deleteIndex_Callback_0_(mthis) => mthis.callMethod("deleteIndex", []);

  deleteIndex_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteIndex", [__arg_0]);

  delete_Callback_0_(mthis) => mthis.callMethod("delete", []);

  delete_Callback_1_(mthis, __arg_0) => mthis.callMethod("delete", [__arg_0]);

  get_Callback_0_(mthis) => mthis.callMethod("get", []);

  get_Callback_1_(mthis, __arg_0) => mthis.callMethod("get", [__arg_0]);

  indexNames_Getter_(mthis) => mthis["indexNames"];

  index_Callback_0_(mthis) => mthis.callMethod("index", []);

  index_Callback_1_(mthis, __arg_0) => mthis.callMethod("index", [__arg_0]);

  keyPath_Getter_(mthis) => mthis["keyPath"];

  name_Getter_(mthis) => mthis["name"];

  openCursor_Callback_0_(mthis) => mthis.callMethod("openCursor", []);

  openCursor_Callback_1_(mthis, __arg_0) => mthis.callMethod("openCursor", [__arg_0]);

  openCursor_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("openCursor", [__arg_0, __arg_1]);

  openKeyCursor_Callback_0_(mthis) => mthis.callMethod("openKeyCursor", []);

  openKeyCursor_Callback_1_(mthis, __arg_0) => mthis.callMethod("openKeyCursor", [__arg_0]);

  openKeyCursor_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("openKeyCursor", [__arg_0, __arg_1]);

  put_Callback_0_(mthis) => mthis.callMethod("put", []);

  put_Callback_1_(mthis, __arg_0) => mthis.callMethod("put", [__arg_0]);

  put_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("put", [__arg_0, __arg_1]);

  transaction_Getter_(mthis) => mthis["transaction"];

}

class BlinkIDBOpenDBRequest extends BlinkIDBRequest {
  static final instance = new BlinkIDBOpenDBRequest();

  onblocked_Getter_(mthis) => mthis["onblocked"];

  onblocked_Setter_(mthis, __arg_0) => mthis["onblocked"] = __arg_0;

  onupgradeneeded_Getter_(mthis) => mthis["onupgradeneeded"];

  onupgradeneeded_Setter_(mthis, __arg_0) => mthis["onupgradeneeded"] = __arg_0;

}

class BlinkIDBRequest extends BlinkEventTarget {
  static final instance = new BlinkIDBRequest();

  error_Getter_(mthis) => mthis["error"];

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onsuccess_Getter_(mthis) => mthis["onsuccess"];

  onsuccess_Setter_(mthis, __arg_0) => mthis["onsuccess"] = __arg_0;

  readyState_Getter_(mthis) => mthis["readyState"];

  result_Getter_(mthis) => mthis["result"];

  source_Getter_(mthis) => mthis["source"];

  transaction_Getter_(mthis) => mthis["transaction"];

}

class BlinkIDBTransaction extends BlinkEventTarget {
  static final instance = new BlinkIDBTransaction();

  abort_Callback_0_(mthis) => mthis.callMethod("abort", []);

  db_Getter_(mthis) => mthis["db"];

  error_Getter_(mthis) => mthis["error"];

  mode_Getter_(mthis) => mthis["mode"];

  objectStore_Callback_0_(mthis) => mthis.callMethod("objectStore", []);

  objectStore_Callback_1_(mthis, __arg_0) => mthis.callMethod("objectStore", [__arg_0]);

  onabort_Getter_(mthis) => mthis["onabort"];

  onabort_Setter_(mthis, __arg_0) => mthis["onabort"] = __arg_0;

  oncomplete_Getter_(mthis) => mthis["oncomplete"];

  oncomplete_Setter_(mthis, __arg_0) => mthis["oncomplete"] = __arg_0;

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

}

class BlinkIDBVersionChangeEvent extends BlinkEvent {
  static final instance = new BlinkIDBVersionChangeEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["IDBVersionChangeEvent"], [__arg_0, __arg_1]);

  dataLossMessage_Getter_(mthis) => mthis["dataLossMessage"];

  dataLoss_Getter_(mthis) => mthis["dataLoss"];

  newVersion_Getter_(mthis) => mthis["newVersion"];

  oldVersion_Getter_(mthis) => mthis["oldVersion"];

}

class BlinkImageBitmap {
  static final instance = new BlinkImageBitmap();

  height_Getter_(mthis) => mthis["height"];

  width_Getter_(mthis) => mthis["width"];

}

class BlinkImageData {
  static final instance = new BlinkImageData();

  constructorCallback_0_() => new js.JsObject(js.context["ImageData"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["ImageData"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["ImageData"], [__arg_0, __arg_1]);

  constructorCallback_3_(__arg_0, __arg_1, __arg_2) => new js.JsObject(js.context["ImageData"], [__arg_0, __arg_1, __arg_2]);

  data_Getter_(mthis) => mthis["data"];

  height_Getter_(mthis) => mthis["height"];

  width_Getter_(mthis) => mthis["width"];

}

class BlinkInjectedScriptHost {
  static final instance = new BlinkInjectedScriptHost();

  callFunction_Callback_0_(mthis) => mthis.callMethod("callFunction", []);

  callFunction_Callback_1_(mthis, __arg_0) => mthis.callMethod("callFunction", [__arg_0]);

  callFunction_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("callFunction", [__arg_0, __arg_1]);

  callFunction_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("callFunction", [__arg_0, __arg_1, __arg_2]);

  clearConsoleMessages_Callback_0_(mthis) => mthis.callMethod("clearConsoleMessages", []);

  collectionEntries_Callback_0_(mthis) => mthis.callMethod("collectionEntries", []);

  collectionEntries_Callback_1_(mthis, __arg_0) => mthis.callMethod("collectionEntries", [__arg_0]);

  debugFunction_Callback_0_(mthis) => mthis.callMethod("debugFunction", []);

  debugFunction_Callback_1_(mthis, __arg_0) => mthis.callMethod("debugFunction", [__arg_0]);

  eval_Callback_0_(mthis) => mthis.callMethod("eval", []);

  eval_Callback_1_(mthis, __arg_0) => mthis.callMethod("eval", [__arg_0]);

  evaluateWithExceptionDetails_Callback_0_(mthis) => mthis.callMethod("evaluateWithExceptionDetails", []);

  evaluateWithExceptionDetails_Callback_1_(mthis, __arg_0) => mthis.callMethod("evaluateWithExceptionDetails", [__arg_0]);

  functionDetails_Callback_0_(mthis) => mthis.callMethod("functionDetails", []);

  functionDetails_Callback_1_(mthis, __arg_0) => mthis.callMethod("functionDetails", [__arg_0]);

  getEventListeners_Callback_0_(mthis) => mthis.callMethod("getEventListeners", []);

  getEventListeners_Callback_1_(mthis, __arg_0) => mthis.callMethod("getEventListeners", [__arg_0]);

  getInternalProperties_Callback_0_(mthis) => mthis.callMethod("getInternalProperties", []);

  getInternalProperties_Callback_1_(mthis, __arg_0) => mthis.callMethod("getInternalProperties", [__arg_0]);

  inspect_Callback_0_(mthis) => mthis.callMethod("inspect", []);

  inspect_Callback_1_(mthis, __arg_0) => mthis.callMethod("inspect", [__arg_0]);

  inspect_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("inspect", [__arg_0, __arg_1]);

  inspectedObject_Callback_0_(mthis) => mthis.callMethod("inspectedObject", []);

  inspectedObject_Callback_1_(mthis, __arg_0) => mthis.callMethod("inspectedObject", [__arg_0]);

  internalConstructorName_Callback_0_(mthis) => mthis.callMethod("internalConstructorName", []);

  internalConstructorName_Callback_1_(mthis, __arg_0) => mthis.callMethod("internalConstructorName", [__arg_0]);

  isHTMLAllCollection_Callback_0_(mthis) => mthis.callMethod("isHTMLAllCollection", []);

  isHTMLAllCollection_Callback_1_(mthis, __arg_0) => mthis.callMethod("isHTMLAllCollection", [__arg_0]);

  monitorFunction_Callback_0_(mthis) => mthis.callMethod("monitorFunction", []);

  monitorFunction_Callback_1_(mthis, __arg_0) => mthis.callMethod("monitorFunction", [__arg_0]);

  setFunctionVariableValue_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setFunctionVariableValue", [__arg_0, __arg_1]);

  setFunctionVariableValue_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setFunctionVariableValue", [__arg_0, __arg_1, __arg_2]);

  setFunctionVariableValue_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("setFunctionVariableValue", [__arg_0, __arg_1, __arg_2, __arg_3]);

  setNonEnumProperty_Callback_1_(mthis, __arg_0) => mthis.callMethod("setNonEnumProperty", [__arg_0]);

  setNonEnumProperty_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setNonEnumProperty", [__arg_0, __arg_1]);

  setNonEnumProperty_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setNonEnumProperty", [__arg_0, __arg_1, __arg_2]);

  subtype_Callback_0_(mthis) => mthis.callMethod("subtype", []);

  subtype_Callback_1_(mthis, __arg_0) => mthis.callMethod("subtype", [__arg_0]);

  suppressWarningsAndCallFunction_Callback_0_(mthis) => mthis.callMethod("suppressWarningsAndCallFunction", []);

  suppressWarningsAndCallFunction_Callback_1_(mthis, __arg_0) => mthis.callMethod("suppressWarningsAndCallFunction", [__arg_0]);

  suppressWarningsAndCallFunction_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("suppressWarningsAndCallFunction", [__arg_0, __arg_1]);

  suppressWarningsAndCallFunction_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("suppressWarningsAndCallFunction", [__arg_0, __arg_1, __arg_2]);

  undebugFunction_Callback_0_(mthis) => mthis.callMethod("undebugFunction", []);

  undebugFunction_Callback_1_(mthis, __arg_0) => mthis.callMethod("undebugFunction", [__arg_0]);

  unmonitorFunction_Callback_0_(mthis) => mthis.callMethod("unmonitorFunction", []);

  unmonitorFunction_Callback_1_(mthis, __arg_0) => mthis.callMethod("unmonitorFunction", [__arg_0]);

}

class BlinkInputMethodContext extends BlinkEventTarget {
  static final instance = new BlinkInputMethodContext();

  compositionEndOffset_Getter_(mthis) => mthis["compositionEndOffset"];

  compositionStartOffset_Getter_(mthis) => mthis["compositionStartOffset"];

  confirmComposition_Callback_0_(mthis) => mthis.callMethod("confirmComposition", []);

  locale_Getter_(mthis) => mthis["locale"];

  oncandidatewindowhide_Getter_(mthis) => mthis["oncandidatewindowhide"];

  oncandidatewindowhide_Setter_(mthis, __arg_0) => mthis["oncandidatewindowhide"] = __arg_0;

  oncandidatewindowshow_Getter_(mthis) => mthis["oncandidatewindowshow"];

  oncandidatewindowshow_Setter_(mthis, __arg_0) => mthis["oncandidatewindowshow"] = __arg_0;

  oncandidatewindowupdate_Getter_(mthis) => mthis["oncandidatewindowupdate"];

  oncandidatewindowupdate_Setter_(mthis, __arg_0) => mthis["oncandidatewindowupdate"] = __arg_0;

  target_Getter_(mthis) => mthis["target"];

}

class BlinkInspectorFrontendHost {
  static final instance = new BlinkInspectorFrontendHost();

  copyText_Callback_0_(mthis) => mthis.callMethod("copyText", []);

  copyText_Callback_1_(mthis, __arg_0) => mthis.callMethod("copyText", [__arg_0]);

  getSelectionBackgroundColor_Callback_0_(mthis) => mthis.callMethod("getSelectionBackgroundColor", []);

  getSelectionForegroundColor_Callback_0_(mthis) => mthis.callMethod("getSelectionForegroundColor", []);

  isHostedMode_Callback_0_(mthis) => mthis.callMethod("isHostedMode", []);

  isUnderTest_Callback_0_(mthis) => mthis.callMethod("isUnderTest", []);

  isolatedFileSystem_Callback_0_(mthis) => mthis.callMethod("isolatedFileSystem", []);

  isolatedFileSystem_Callback_1_(mthis, __arg_0) => mthis.callMethod("isolatedFileSystem", [__arg_0]);

  isolatedFileSystem_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("isolatedFileSystem", [__arg_0, __arg_1]);

  platform_Callback_0_(mthis) => mthis.callMethod("platform", []);

  port_Callback_0_(mthis) => mthis.callMethod("port", []);

  recordActionTaken_Callback_0_(mthis) => mthis.callMethod("recordActionTaken", []);

  recordActionTaken_Callback_1_(mthis, __arg_0) => mthis.callMethod("recordActionTaken", [__arg_0]);

  recordPanelShown_Callback_0_(mthis) => mthis.callMethod("recordPanelShown", []);

  recordPanelShown_Callback_1_(mthis, __arg_0) => mthis.callMethod("recordPanelShown", [__arg_0]);

  sendMessageToBackend_Callback_0_(mthis) => mthis.callMethod("sendMessageToBackend", []);

  sendMessageToBackend_Callback_1_(mthis, __arg_0) => mthis.callMethod("sendMessageToBackend", [__arg_0]);

  sendMessageToEmbedder_Callback_0_(mthis) => mthis.callMethod("sendMessageToEmbedder", []);

  sendMessageToEmbedder_Callback_1_(mthis, __arg_0) => mthis.callMethod("sendMessageToEmbedder", [__arg_0]);

  setInjectedScriptForOrigin_Callback_0_(mthis) => mthis.callMethod("setInjectedScriptForOrigin", []);

  setInjectedScriptForOrigin_Callback_1_(mthis, __arg_0) => mthis.callMethod("setInjectedScriptForOrigin", [__arg_0]);

  setInjectedScriptForOrigin_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setInjectedScriptForOrigin", [__arg_0, __arg_1]);

  setZoomFactor_Callback_0_(mthis) => mthis.callMethod("setZoomFactor", []);

  setZoomFactor_Callback_1_(mthis, __arg_0) => mthis.callMethod("setZoomFactor", [__arg_0]);

  showContextMenuAtPoint_Callback_1_(mthis, __arg_0) => mthis.callMethod("showContextMenuAtPoint", [__arg_0]);

  showContextMenuAtPoint_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("showContextMenuAtPoint", [__arg_0, __arg_1]);

  showContextMenuAtPoint_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("showContextMenuAtPoint", [__arg_0, __arg_1, __arg_2]);

  showContextMenu_Callback_0_(mthis) => mthis.callMethod("showContextMenu", []);

  showContextMenu_Callback_1_(mthis, __arg_0) => mthis.callMethod("showContextMenu", [__arg_0]);

  showContextMenu_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("showContextMenu", [__arg_0, __arg_1]);

  upgradeDraggedFileSystemPermissions_Callback_0_(mthis) => mthis.callMethod("upgradeDraggedFileSystemPermissions", []);

  upgradeDraggedFileSystemPermissions_Callback_1_(mthis, __arg_0) => mthis.callMethod("upgradeDraggedFileSystemPermissions", [__arg_0]);

  zoomFactor_Callback_0_(mthis) => mthis.callMethod("zoomFactor", []);

}

class BlinkInspectorOverlayHost {
  static final instance = new BlinkInspectorOverlayHost();

  resume_Callback_0_(mthis) => mthis.callMethod("resume", []);

  stepOver_Callback_0_(mthis) => mthis.callMethod("stepOver", []);

}

class BlinkInstallEvent extends BlinkExtendableEvent {
  static final instance = new BlinkInstallEvent();

  reloadAll_Callback_0_(mthis) => mthis.callMethod("reloadAll", []);

  replace_Callback_0_(mthis) => mthis.callMethod("replace", []);

}

class BlinkIterator {
  static final instance = new BlinkIterator();

  next_Callback_0_(mthis) => mthis.callMethod("next", []);

  next_Callback_1_(mthis, __arg_0) => mthis.callMethod("next", [__arg_0]);

}

class BlinkJavaScriptCallFrame {
  static final instance = new BlinkJavaScriptCallFrame();

  caller_Getter_(mthis) => mthis["caller"];

  column_Getter_(mthis) => mthis["column"];

  evaluateWithExceptionDetails_Callback_0_(mthis) => mthis.callMethod("evaluateWithExceptionDetails", []);

  evaluateWithExceptionDetails_Callback_1_(mthis, __arg_0) => mthis.callMethod("evaluateWithExceptionDetails", [__arg_0]);

  functionName_Getter_(mthis) => mthis["functionName"];

  isAtReturn_Getter_(mthis) => mthis["isAtReturn"];

  line_Getter_(mthis) => mthis["line"];

  restart_Callback_0_(mthis) => mthis.callMethod("restart", []);

  returnValue_Getter_(mthis) => mthis["returnValue"];

  scopeChain_Getter_(mthis) => mthis["scopeChain"];

  scopeType_Callback_0_(mthis) => mthis.callMethod("scopeType", []);

  scopeType_Callback_1_(mthis, __arg_0) => mthis.callMethod("scopeType", [__arg_0]);

  setVariableValue_Callback_0_(mthis) => mthis.callMethod("setVariableValue", []);

  setVariableValue_Callback_1_(mthis, __arg_0) => mthis.callMethod("setVariableValue", [__arg_0]);

  setVariableValue_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setVariableValue", [__arg_0, __arg_1]);

  setVariableValue_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setVariableValue", [__arg_0, __arg_1, __arg_2]);

  sourceID_Getter_(mthis) => mthis["sourceID"];

  stepInPositions_Getter_(mthis) => mthis["stepInPositions"];

  thisObject_Getter_(mthis) => mthis["thisObject"];

  type_Getter_(mthis) => mthis["type"];

}

class BlinkKeyboardEvent extends BlinkUIEvent {
  static final instance = new BlinkKeyboardEvent();

  altKey_Getter_(mthis) => mthis["altKey"];

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["KeyboardEvent"], [__arg_0, __arg_1]);

  ctrlKey_Getter_(mthis) => mthis["ctrlKey"];

  getModifierState_Callback_0_(mthis) => mthis.callMethod("getModifierState", []);

  getModifierState_Callback_1_(mthis, __arg_0) => mthis.callMethod("getModifierState", [__arg_0]);

  initKeyboardEvent_Callback_0_(mthis) => mthis.callMethod("initKeyboardEvent", []);

  initKeyboardEvent_Callback_1_(mthis, __arg_0) => mthis.callMethod("initKeyboardEvent", [__arg_0]);

  initKeyboardEvent_Callback_10_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9) => mthis.callMethod("initKeyboardEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9]);

  initKeyboardEvent_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("initKeyboardEvent", [__arg_0, __arg_1]);

  initKeyboardEvent_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("initKeyboardEvent", [__arg_0, __arg_1, __arg_2]);

  initKeyboardEvent_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("initKeyboardEvent", [__arg_0, __arg_1, __arg_2, __arg_3]);

  initKeyboardEvent_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("initKeyboardEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  initKeyboardEvent_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("initKeyboardEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  initKeyboardEvent_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("initKeyboardEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  initKeyboardEvent_Callback_8_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7) => mthis.callMethod("initKeyboardEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7]);

  initKeyboardEvent_Callback_9_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8) => mthis.callMethod("initKeyboardEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8]);

  keyIdentifier_Getter_(mthis) => mthis["keyIdentifier"];

  keyLocation_Getter_(mthis) => mthis["keyLocation"];

  location_Getter_(mthis) => mthis["location"];

  metaKey_Getter_(mthis) => mthis["metaKey"];

  repeat_Getter_(mthis) => mthis["repeat"];

  shiftKey_Getter_(mthis) => mthis["shiftKey"];

}

class BlinkLocalCredential extends BlinkCredential {
  static final instance = new BlinkLocalCredential();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["LocalCredential"], [__arg_0, __arg_1]);

  constructorCallback_3_(__arg_0, __arg_1, __arg_2) => new js.JsObject(js.context["LocalCredential"], [__arg_0, __arg_1, __arg_2]);

  constructorCallback_4_(__arg_0, __arg_1, __arg_2, __arg_3) => new js.JsObject(js.context["LocalCredential"], [__arg_0, __arg_1, __arg_2, __arg_3]);

  password_Getter_(mthis) => mthis["password"];

}

class BlinkLocation {
  static final instance = new BlinkLocation();

  ancestorOrigins_Getter_(mthis) => mthis["ancestorOrigins"];

  assign_Callback_0_(mthis) => mthis.callMethod("assign", []);

  assign_Callback_1_(mthis, __arg_0) => mthis.callMethod("assign", [__arg_0]);

  hash_Getter_(mthis) => mthis["hash"];

  hash_Setter_(mthis, __arg_0) => mthis["hash"] = __arg_0;

  host_Getter_(mthis) => mthis["host"];

  host_Setter_(mthis, __arg_0) => mthis["host"] = __arg_0;

  hostname_Getter_(mthis) => mthis["hostname"];

  hostname_Setter_(mthis, __arg_0) => mthis["hostname"] = __arg_0;

  href_Getter_(mthis) => mthis["href"];

  href_Setter_(mthis, __arg_0) => mthis["href"] = __arg_0;

  origin_Getter_(mthis) => mthis["origin"];

  pathname_Getter_(mthis) => mthis["pathname"];

  pathname_Setter_(mthis, __arg_0) => mthis["pathname"] = __arg_0;

  port_Getter_(mthis) => mthis["port"];

  port_Setter_(mthis, __arg_0) => mthis["port"] = __arg_0;

  protocol_Getter_(mthis) => mthis["protocol"];

  protocol_Setter_(mthis, __arg_0) => mthis["protocol"] = __arg_0;

  reload_Callback_0_(mthis) => mthis.callMethod("reload", []);

  replace_Callback_0_(mthis) => mthis.callMethod("replace", []);

  replace_Callback_1_(mthis, __arg_0) => mthis.callMethod("replace", [__arg_0]);

  search_Getter_(mthis) => mthis["search"];

  search_Setter_(mthis, __arg_0) => mthis["search"] = __arg_0;

  toString_Callback_0_(mthis) => mthis.callMethod("toString", []);

}

class BlinkMIDIAccess extends BlinkEventTarget {
  static final instance = new BlinkMIDIAccess();

  inputs_Getter_(mthis) => mthis["inputs"];

  onconnect_Getter_(mthis) => mthis["onconnect"];

  onconnect_Setter_(mthis, __arg_0) => mthis["onconnect"] = __arg_0;

  ondisconnect_Getter_(mthis) => mthis["ondisconnect"];

  ondisconnect_Setter_(mthis, __arg_0) => mthis["ondisconnect"] = __arg_0;

  outputs_Getter_(mthis) => mthis["outputs"];

  sysexEnabled_Getter_(mthis) => mthis["sysexEnabled"];

}

class BlinkMIDIConnectionEvent extends BlinkEvent {
  static final instance = new BlinkMIDIConnectionEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["MIDIConnectionEvent"], [__arg_0, __arg_1]);

  port_Getter_(mthis) => mthis["port"];

}

class BlinkMIDIInput extends BlinkMIDIPort {
  static final instance = new BlinkMIDIInput();

  onmidimessage_Getter_(mthis) => mthis["onmidimessage"];

  onmidimessage_Setter_(mthis, __arg_0) => mthis["onmidimessage"] = __arg_0;

}

class BlinkMIDIInputMap {
  static final instance = new BlinkMIDIInputMap();

  entries_Callback_0_(mthis) => mthis.callMethod("entries", []);

  get_Callback_0_(mthis) => mthis.callMethod("get", []);

  get_Callback_1_(mthis, __arg_0) => mthis.callMethod("get", [__arg_0]);

  has_Callback_0_(mthis) => mthis.callMethod("has", []);

  has_Callback_1_(mthis, __arg_0) => mthis.callMethod("has", [__arg_0]);

  keys_Callback_0_(mthis) => mthis.callMethod("keys", []);

  size_Getter_(mthis) => mthis["size"];

  values_Callback_0_(mthis) => mthis.callMethod("values", []);

}

class BlinkMIDIMessageEvent extends BlinkEvent {
  static final instance = new BlinkMIDIMessageEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["MIDIMessageEvent"], [__arg_0, __arg_1]);

  data_Getter_(mthis) => mthis["data"];

  receivedTime_Getter_(mthis) => mthis["receivedTime"];

}

class BlinkMIDIOutput extends BlinkMIDIPort {
  static final instance = new BlinkMIDIOutput();

  send_Callback_0_(mthis) => mthis.callMethod("send", []);

  send_Callback_1_(mthis, __arg_0) => mthis.callMethod("send", [__arg_0]);

  send_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("send", [__arg_0, __arg_1]);

}

class BlinkMIDIOutputMap {
  static final instance = new BlinkMIDIOutputMap();

  entries_Callback_0_(mthis) => mthis.callMethod("entries", []);

  get_Callback_0_(mthis) => mthis.callMethod("get", []);

  get_Callback_1_(mthis, __arg_0) => mthis.callMethod("get", [__arg_0]);

  has_Callback_0_(mthis) => mthis.callMethod("has", []);

  has_Callback_1_(mthis, __arg_0) => mthis.callMethod("has", [__arg_0]);

  keys_Callback_0_(mthis) => mthis.callMethod("keys", []);

  size_Getter_(mthis) => mthis["size"];

  values_Callback_0_(mthis) => mthis.callMethod("values", []);

}

class BlinkMIDIPort extends BlinkEventTarget {
  static final instance = new BlinkMIDIPort();

  id_Getter_(mthis) => mthis["id"];

  manufacturer_Getter_(mthis) => mthis["manufacturer"];

  name_Getter_(mthis) => mthis["name"];

  ondisconnect_Getter_(mthis) => mthis["ondisconnect"];

  ondisconnect_Setter_(mthis, __arg_0) => mthis["ondisconnect"] = __arg_0;

  type_Getter_(mthis) => mthis["type"];

  version_Getter_(mthis) => mthis["version"];

}

class BlinkMediaController extends BlinkEventTarget {
  static final instance = new BlinkMediaController();

  buffered_Getter_(mthis) => mthis["buffered"];

  constructorCallback_0_() => new js.JsObject(js.context["MediaController"], []);

  currentTime_Getter_(mthis) => mthis["currentTime"];

  currentTime_Setter_(mthis, __arg_0) => mthis["currentTime"] = __arg_0;

  defaultPlaybackRate_Getter_(mthis) => mthis["defaultPlaybackRate"];

  defaultPlaybackRate_Setter_(mthis, __arg_0) => mthis["defaultPlaybackRate"] = __arg_0;

  duration_Getter_(mthis) => mthis["duration"];

  muted_Getter_(mthis) => mthis["muted"];

  muted_Setter_(mthis, __arg_0) => mthis["muted"] = __arg_0;

  pause_Callback_0_(mthis) => mthis.callMethod("pause", []);

  paused_Getter_(mthis) => mthis["paused"];

  play_Callback_0_(mthis) => mthis.callMethod("play", []);

  playbackRate_Getter_(mthis) => mthis["playbackRate"];

  playbackRate_Setter_(mthis, __arg_0) => mthis["playbackRate"] = __arg_0;

  playbackState_Getter_(mthis) => mthis["playbackState"];

  played_Getter_(mthis) => mthis["played"];

  seekable_Getter_(mthis) => mthis["seekable"];

  unpause_Callback_0_(mthis) => mthis.callMethod("unpause", []);

  volume_Getter_(mthis) => mthis["volume"];

  volume_Setter_(mthis, __arg_0) => mthis["volume"] = __arg_0;

}

class BlinkMediaDeviceInfo {
  static final instance = new BlinkMediaDeviceInfo();

  deviceId_Getter_(mthis) => mthis["deviceId"];

  groupId_Getter_(mthis) => mthis["groupId"];

  kind_Getter_(mthis) => mthis["kind"];

  label_Getter_(mthis) => mthis["label"];

}

class BlinkMediaElementAudioSourceNode extends BlinkAudioSourceNode {
  static final instance = new BlinkMediaElementAudioSourceNode();

  mediaElement_Getter_(mthis) => mthis["mediaElement"];

}

class BlinkMediaError {
  static final instance = new BlinkMediaError();

  code_Getter_(mthis) => mthis["code"];

}

class BlinkMediaKeyError {
  static final instance = new BlinkMediaKeyError();

  code_Getter_(mthis) => mthis["code"];

  systemCode_Getter_(mthis) => mthis["systemCode"];

}

class BlinkMediaKeyEvent extends BlinkEvent {
  static final instance = new BlinkMediaKeyEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["MediaKeyEvent"], [__arg_0, __arg_1]);

  defaultURL_Getter_(mthis) => mthis["defaultURL"];

  errorCode_Getter_(mthis) => mthis["errorCode"];

  initData_Getter_(mthis) => mthis["initData"];

  keySystem_Getter_(mthis) => mthis["keySystem"];

  message_Getter_(mthis) => mthis["message"];

  sessionId_Getter_(mthis) => mthis["sessionId"];

  systemCode_Getter_(mthis) => mthis["systemCode"];

}

class BlinkMediaKeyMessageEvent extends BlinkEvent {
  static final instance = new BlinkMediaKeyMessageEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["MediaKeyMessageEvent"], [__arg_0, __arg_1]);

  destinationURL_Getter_(mthis) => mthis["destinationURL"];

  message_Getter_(mthis) => mthis["message"];

}

class BlinkMediaKeyNeededEvent extends BlinkEvent {
  static final instance = new BlinkMediaKeyNeededEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["MediaKeyNeededEvent"], [__arg_0, __arg_1]);

  contentType_Getter_(mthis) => mthis["contentType"];

  initData_Getter_(mthis) => mthis["initData"];

}

class BlinkMediaKeySession extends BlinkEventTarget {
  static final instance = new BlinkMediaKeySession();

  closed_Getter_(mthis) => mthis["closed"];

  error_Getter_(mthis) => mthis["error"];

  generateRequest_Callback_0_(mthis) => mthis.callMethod("generateRequest", []);

  generateRequest_Callback_1_(mthis, __arg_0) => mthis.callMethod("generateRequest", [__arg_0]);

  generateRequest_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("generateRequest", [__arg_0, __arg_1]);

  keySystem_Getter_(mthis) => mthis["keySystem"];

  release_Callback_0_(mthis) => mthis.callMethod("release", []);

  sessionId_Getter_(mthis) => mthis["sessionId"];

  update_Callback_0_(mthis) => mthis.callMethod("update", []);

  update_Callback_1_(mthis, __arg_0) => mthis.callMethod("update", [__arg_0]);

}

class BlinkMediaKeys {
  static final instance = new BlinkMediaKeys();

  createSession_Callback_0_(mthis) => mthis.callMethod("createSession", []);

  createSession_Callback_1_(mthis, __arg_0) => mthis.callMethod("createSession", [__arg_0]);

  create_Callback_0_() => js.context["MediaKeys"].callMethod("create", []);

  create_Callback_1_(__arg_0) => js.context["MediaKeys"].callMethod("create", [__arg_0]);

  isTypeSupported_Callback_0_() => js.context["MediaKeys"].callMethod("isTypeSupported", []);

  isTypeSupported_Callback_1_(__arg_0) => js.context["MediaKeys"].callMethod("isTypeSupported", [__arg_0]);

  isTypeSupported_Callback_2_(__arg_0, __arg_1) => js.context["MediaKeys"].callMethod("isTypeSupported", [__arg_0, __arg_1]);

  keySystem_Getter_(mthis) => mthis["keySystem"];

}

class BlinkMediaList {
  static final instance = new BlinkMediaList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  appendMedium_Callback_0_(mthis) => mthis.callMethod("appendMedium", []);

  appendMedium_Callback_1_(mthis, __arg_0) => mthis.callMethod("appendMedium", [__arg_0]);

  deleteMedium_Callback_0_(mthis) => mthis.callMethod("deleteMedium", []);

  deleteMedium_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteMedium", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

  mediaText_Getter_(mthis) => mthis["mediaText"];

  mediaText_Setter_(mthis, __arg_0) => mthis["mediaText"] = __arg_0;

}

class BlinkMediaQueryList extends BlinkEventTarget {
  static final instance = new BlinkMediaQueryList();

  addListener_Callback_0_(mthis) => mthis.callMethod("addListener", []);

  addListener_Callback_1_(mthis, __arg_0) => mthis.callMethod("addListener", [__arg_0]);

  matches_Getter_(mthis) => mthis["matches"];

  media_Getter_(mthis) => mthis["media"];

  onchange_Getter_(mthis) => mthis["onchange"];

  onchange_Setter_(mthis, __arg_0) => mthis["onchange"] = __arg_0;

  removeListener_Callback_0_(mthis) => mthis.callMethod("removeListener", []);

  removeListener_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeListener", [__arg_0]);

}

class BlinkMediaQueryListEvent extends BlinkEvent {
  static final instance = new BlinkMediaQueryListEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["MediaQueryListEvent"], [__arg_0, __arg_1]);

  matches_Getter_(mthis) => mthis["matches"];

  media_Getter_(mthis) => mthis["media"];

}

class BlinkMediaSource extends BlinkEventTarget {
  static final instance = new BlinkMediaSource();

  activeSourceBuffers_Getter_(mthis) => mthis["activeSourceBuffers"];

  addSourceBuffer_Callback_0_(mthis) => mthis.callMethod("addSourceBuffer", []);

  addSourceBuffer_Callback_1_(mthis, __arg_0) => mthis.callMethod("addSourceBuffer", [__arg_0]);

  constructorCallback_0_() => new js.JsObject(js.context["MediaSource"], []);

  duration_Getter_(mthis) => mthis["duration"];

  duration_Setter_(mthis, __arg_0) => mthis["duration"] = __arg_0;

  endOfStream_Callback_0_(mthis) => mthis.callMethod("endOfStream", []);

  endOfStream_Callback_1_(mthis, __arg_0) => mthis.callMethod("endOfStream", [__arg_0]);

  isTypeSupported_Callback_0_() => js.context["MediaSource"].callMethod("isTypeSupported", []);

  isTypeSupported_Callback_1_(__arg_0) => js.context["MediaSource"].callMethod("isTypeSupported", [__arg_0]);

  readyState_Getter_(mthis) => mthis["readyState"];

  removeSourceBuffer_Callback_0_(mthis) => mthis.callMethod("removeSourceBuffer", []);

  removeSourceBuffer_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeSourceBuffer", [__arg_0]);

  sourceBuffers_Getter_(mthis) => mthis["sourceBuffers"];

}

class BlinkMediaStream extends BlinkEventTarget {
  static final instance = new BlinkMediaStream();

  addTrack_Callback_0_(mthis) => mthis.callMethod("addTrack", []);

  addTrack_Callback_1_(mthis, __arg_0) => mthis.callMethod("addTrack", [__arg_0]);

  clone_Callback_0_(mthis) => mthis.callMethod("clone", []);

  constructorCallback_0_() => new js.JsObject(js.context["MediaStream"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["MediaStream"], [__arg_0]);

  ended_Getter_(mthis) => mthis["ended"];

  getAudioTracks_Callback_0_(mthis) => mthis.callMethod("getAudioTracks", []);

  getTrackById_Callback_0_(mthis) => mthis.callMethod("getTrackById", []);

  getTrackById_Callback_1_(mthis, __arg_0) => mthis.callMethod("getTrackById", [__arg_0]);

  getTracks_Callback_0_(mthis) => mthis.callMethod("getTracks", []);

  getVideoTracks_Callback_0_(mthis) => mthis.callMethod("getVideoTracks", []);

  id_Getter_(mthis) => mthis["id"];

  label_Getter_(mthis) => mthis["label"];

  onaddtrack_Getter_(mthis) => mthis["onaddtrack"];

  onaddtrack_Setter_(mthis, __arg_0) => mthis["onaddtrack"] = __arg_0;

  onended_Getter_(mthis) => mthis["onended"];

  onended_Setter_(mthis, __arg_0) => mthis["onended"] = __arg_0;

  onremovetrack_Getter_(mthis) => mthis["onremovetrack"];

  onremovetrack_Setter_(mthis, __arg_0) => mthis["onremovetrack"] = __arg_0;

  removeTrack_Callback_0_(mthis) => mthis.callMethod("removeTrack", []);

  removeTrack_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeTrack", [__arg_0]);

  stop_Callback_0_(mthis) => mthis.callMethod("stop", []);

}

class BlinkMediaStreamAudioDestinationNode extends BlinkAudioNode {
  static final instance = new BlinkMediaStreamAudioDestinationNode();

  stream_Getter_(mthis) => mthis["stream"];

}

class BlinkMediaStreamAudioSourceNode extends BlinkAudioSourceNode {
  static final instance = new BlinkMediaStreamAudioSourceNode();

  mediaStream_Getter_(mthis) => mthis["mediaStream"];

}

class BlinkMediaStreamEvent extends BlinkEvent {
  static final instance = new BlinkMediaStreamEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["MediaStreamEvent"], [__arg_0, __arg_1]);

  stream_Getter_(mthis) => mthis["stream"];

}

class BlinkMediaStreamTrack extends BlinkEventTarget {
  static final instance = new BlinkMediaStreamTrack();

  clone_Callback_0_(mthis) => mthis.callMethod("clone", []);

  enabled_Getter_(mthis) => mthis["enabled"];

  enabled_Setter_(mthis, __arg_0) => mthis["enabled"] = __arg_0;

  getSources_Callback_0_() => js.context["MediaStreamTrack"].callMethod("getSources", []);

  getSources_Callback_1_(__arg_0) => js.context["MediaStreamTrack"].callMethod("getSources", [__arg_0]);

  id_Getter_(mthis) => mthis["id"];

  kind_Getter_(mthis) => mthis["kind"];

  label_Getter_(mthis) => mthis["label"];

  muted_Getter_(mthis) => mthis["muted"];

  onended_Getter_(mthis) => mthis["onended"];

  onended_Setter_(mthis, __arg_0) => mthis["onended"] = __arg_0;

  onmute_Getter_(mthis) => mthis["onmute"];

  onmute_Setter_(mthis, __arg_0) => mthis["onmute"] = __arg_0;

  onunmute_Getter_(mthis) => mthis["onunmute"];

  onunmute_Setter_(mthis, __arg_0) => mthis["onunmute"] = __arg_0;

  readyState_Getter_(mthis) => mthis["readyState"];

  stop_Callback_0_(mthis) => mthis.callMethod("stop", []);

}

class BlinkMediaStreamTrackEvent extends BlinkEvent {
  static final instance = new BlinkMediaStreamTrackEvent();

  track_Getter_(mthis) => mthis["track"];

}

class BlinkMemoryInfo {
  static final instance = new BlinkMemoryInfo();

  jsHeapSizeLimit_Getter_(mthis) => mthis["jsHeapSizeLimit"];

  totalJSHeapSize_Getter_(mthis) => mthis["totalJSHeapSize"];

  usedJSHeapSize_Getter_(mthis) => mthis["usedJSHeapSize"];

}

class BlinkMessageChannel {
  static final instance = new BlinkMessageChannel();

  constructorCallback_0_() => new js.JsObject(js.context["MessageChannel"], []);

  port1_Getter_(mthis) => mthis["port1"];

  port2_Getter_(mthis) => mthis["port2"];

}

class BlinkMessageEvent extends BlinkEvent {
  static final instance = new BlinkMessageEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["MessageEvent"], [__arg_0, __arg_1]);

  data_Getter_(mthis) => mthis["data"];

  initMessageEvent_Callback_0_(mthis) => mthis.callMethod("initMessageEvent", []);

  initMessageEvent_Callback_1_(mthis, __arg_0) => mthis.callMethod("initMessageEvent", [__arg_0]);

  initMessageEvent_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("initMessageEvent", [__arg_0, __arg_1]);

  initMessageEvent_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("initMessageEvent", [__arg_0, __arg_1, __arg_2]);

  initMessageEvent_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("initMessageEvent", [__arg_0, __arg_1, __arg_2, __arg_3]);

  initMessageEvent_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("initMessageEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  initMessageEvent_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("initMessageEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  initMessageEvent_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("initMessageEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  initMessageEvent_Callback_8_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7) => mthis.callMethod("initMessageEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7]);

  lastEventId_Getter_(mthis) => mthis["lastEventId"];

  origin_Getter_(mthis) => mthis["origin"];

  source_Getter_(mthis) => mthis["source"];

}

class BlinkMessagePort extends BlinkEventTarget {
  static final instance = new BlinkMessagePort();

  close_Callback_0_(mthis) => mthis.callMethod("close", []);

  onmessage_Getter_(mthis) => mthis["onmessage"];

  onmessage_Setter_(mthis, __arg_0) => mthis["onmessage"] = __arg_0;

  postMessage_Callback_0_(mthis) => mthis.callMethod("postMessage", []);

  postMessage_Callback_1_(mthis, __arg_0) => mthis.callMethod("postMessage", [__arg_0]);

  postMessage_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("postMessage", [__arg_0, __arg_1]);

  start_Callback_0_(mthis) => mthis.callMethod("start", []);

}

class BlinkMetadata {
  static final instance = new BlinkMetadata();

  modificationTime_Getter_(mthis) => mthis["modificationTime"];

  size_Getter_(mthis) => mthis["size"];

}

class BlinkMimeType {
  static final instance = new BlinkMimeType();

  description_Getter_(mthis) => mthis["description"];

  enabledPlugin_Getter_(mthis) => mthis["enabledPlugin"];

  suffixes_Getter_(mthis) => mthis["suffixes"];

  type_Getter_(mthis) => mthis["type"];

}

class BlinkMimeTypeArray {
  static final instance = new BlinkMimeTypeArray();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

  namedItem_Callback_0_(mthis) => mthis.callMethod("namedItem", []);

  namedItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("namedItem", [__arg_0]);

}

class BlinkMouseEvent extends BlinkUIEvent {
  static final instance = new BlinkMouseEvent();

  altKey_Getter_(mthis) => mthis["altKey"];

  button_Getter_(mthis) => mthis["button"];

  clientX_Getter_(mthis) => mthis["clientX"];

  clientY_Getter_(mthis) => mthis["clientY"];

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["MouseEvent"], [__arg_0, __arg_1]);

  ctrlKey_Getter_(mthis) => mthis["ctrlKey"];

  dataTransfer_Getter_(mthis) => mthis["dataTransfer"];

  fromElement_Getter_(mthis) => mthis["fromElement"];

  initMouseEvent_Callback_0_(mthis) => mthis.callMethod("initMouseEvent", []);

  initMouseEvent_Callback_1_(mthis, __arg_0) => mthis.callMethod("initMouseEvent", [__arg_0]);

  initMouseEvent_Callback_10_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9) => mthis.callMethod("initMouseEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9]);

  initMouseEvent_Callback_11_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9, __arg_10) => mthis.callMethod("initMouseEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9, __arg_10]);

  initMouseEvent_Callback_12_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9, __arg_10, __arg_11) => mthis.callMethod("initMouseEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9, __arg_10, __arg_11]);

  initMouseEvent_Callback_13_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9, __arg_10, __arg_11, __arg_12) => mthis.callMethod("initMouseEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9, __arg_10, __arg_11, __arg_12]);

  initMouseEvent_Callback_14_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9, __arg_10, __arg_11, __arg_12, __arg_13) => mthis.callMethod("initMouseEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9, __arg_10, __arg_11, __arg_12, __arg_13]);

  initMouseEvent_Callback_15_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9, __arg_10, __arg_11, __arg_12, __arg_13, __arg_14) => mthis.callMethod("initMouseEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9, __arg_10, __arg_11, __arg_12, __arg_13, __arg_14]);

  initMouseEvent_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("initMouseEvent", [__arg_0, __arg_1]);

  initMouseEvent_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("initMouseEvent", [__arg_0, __arg_1, __arg_2]);

  initMouseEvent_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("initMouseEvent", [__arg_0, __arg_1, __arg_2, __arg_3]);

  initMouseEvent_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("initMouseEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  initMouseEvent_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("initMouseEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  initMouseEvent_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("initMouseEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  initMouseEvent_Callback_8_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7) => mthis.callMethod("initMouseEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7]);

  initMouseEvent_Callback_9_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8) => mthis.callMethod("initMouseEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8]);

  metaKey_Getter_(mthis) => mthis["metaKey"];

  movementX_Getter_(mthis) => mthis["movementX"];

  movementY_Getter_(mthis) => mthis["movementY"];

  offsetX_Getter_(mthis) => mthis["offsetX"];

  offsetY_Getter_(mthis) => mthis["offsetY"];

  region_Getter_(mthis) => mthis["region"];

  relatedTarget_Getter_(mthis) => mthis["relatedTarget"];

  screenX_Getter_(mthis) => mthis["screenX"];

  screenY_Getter_(mthis) => mthis["screenY"];

  shiftKey_Getter_(mthis) => mthis["shiftKey"];

  toElement_Getter_(mthis) => mthis["toElement"];

  webkitMovementX_Getter_(mthis) => mthis["webkitMovementX"];

  webkitMovementY_Getter_(mthis) => mthis["webkitMovementY"];

}

class BlinkMutationEvent extends BlinkEvent {
  static final instance = new BlinkMutationEvent();

  attrChange_Getter_(mthis) => mthis["attrChange"];

  attrName_Getter_(mthis) => mthis["attrName"];

  initMutationEvent_Callback_0_(mthis) => mthis.callMethod("initMutationEvent", []);

  initMutationEvent_Callback_1_(mthis, __arg_0) => mthis.callMethod("initMutationEvent", [__arg_0]);

  initMutationEvent_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("initMutationEvent", [__arg_0, __arg_1]);

  initMutationEvent_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("initMutationEvent", [__arg_0, __arg_1, __arg_2]);

  initMutationEvent_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("initMutationEvent", [__arg_0, __arg_1, __arg_2, __arg_3]);

  initMutationEvent_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("initMutationEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  initMutationEvent_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("initMutationEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  initMutationEvent_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("initMutationEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  initMutationEvent_Callback_8_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7) => mthis.callMethod("initMutationEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7]);

  newValue_Getter_(mthis) => mthis["newValue"];

  prevValue_Getter_(mthis) => mthis["prevValue"];

  relatedNode_Getter_(mthis) => mthis["relatedNode"];

}

class BlinkMutationObserver {
  static final instance = new BlinkMutationObserver();

  constructorCallback_0_() => new js.JsObject(js.context["MutationObserver"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["MutationObserver"], [__arg_0]);

  disconnect_Callback_0_(mthis) => mthis.callMethod("disconnect", []);

  observe_Callback_0_(mthis) => mthis.callMethod("observe", []);

  observe_Callback_1_(mthis, __arg_0) => mthis.callMethod("observe", [__arg_0]);

  observe_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("observe", [__arg_0, __arg_1]);

  takeRecords_Callback_0_(mthis) => mthis.callMethod("takeRecords", []);

}

class BlinkMutationRecord {
  static final instance = new BlinkMutationRecord();

  addedNodes_Getter_(mthis) => mthis["addedNodes"];

  attributeName_Getter_(mthis) => mthis["attributeName"];

  attributeNamespace_Getter_(mthis) => mthis["attributeNamespace"];

  nextSibling_Getter_(mthis) => mthis["nextSibling"];

  oldValue_Getter_(mthis) => mthis["oldValue"];

  previousSibling_Getter_(mthis) => mthis["previousSibling"];

  removedNodes_Getter_(mthis) => mthis["removedNodes"];

  target_Getter_(mthis) => mthis["target"];

  type_Getter_(mthis) => mthis["type"];

}

class BlinkNamedNodeMap {
  static final instance = new BlinkNamedNodeMap();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  getNamedItemNS_Callback_0_(mthis) => mthis.callMethod("getNamedItemNS", []);

  getNamedItemNS_Callback_1_(mthis, __arg_0) => mthis.callMethod("getNamedItemNS", [__arg_0]);

  getNamedItemNS_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getNamedItemNS", [__arg_0, __arg_1]);

  getNamedItem_Callback_0_(mthis) => mthis.callMethod("getNamedItem", []);

  getNamedItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("getNamedItem", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

  removeNamedItemNS_Callback_0_(mthis) => mthis.callMethod("removeNamedItemNS", []);

  removeNamedItemNS_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeNamedItemNS", [__arg_0]);

  removeNamedItemNS_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("removeNamedItemNS", [__arg_0, __arg_1]);

  removeNamedItem_Callback_0_(mthis) => mthis.callMethod("removeNamedItem", []);

  removeNamedItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeNamedItem", [__arg_0]);

  setNamedItemNS_Callback_0_(mthis) => mthis.callMethod("setNamedItemNS", []);

  setNamedItemNS_Callback_1_(mthis, __arg_0) => mthis.callMethod("setNamedItemNS", [__arg_0]);

  setNamedItem_Callback_0_(mthis) => mthis.callMethod("setNamedItem", []);

  setNamedItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("setNamedItem", [__arg_0]);

}

class BlinkNavigator {
  static final instance = new BlinkNavigator();

  appCodeName_Getter_(mthis) => mthis["appCodeName"];

  appName_Getter_(mthis) => mthis["appName"];

  appVersion_Getter_(mthis) => mthis["appVersion"];

  connection_Getter_(mthis) => mthis["connection"];

  cookieEnabled_Getter_(mthis) => mthis["cookieEnabled"];

  credentials_Getter_(mthis) => mthis["credentials"];

  dartEnabled_Getter_(mthis) => mthis["dartEnabled"];

  doNotTrack_Getter_(mthis) => mthis["doNotTrack"];

  geofencing_Getter_(mthis) => mthis["geofencing"];

  geolocation_Getter_(mthis) => mthis["geolocation"];

  getBattery_Callback_0_(mthis) => mthis.callMethod("getBattery", []);

  getGamepads_Callback_0_(mthis) => mthis.callMethod("getGamepads", []);

  getStorageUpdates_Callback_0_(mthis) => mthis.callMethod("getStorageUpdates", []);

  hardwareConcurrency_Getter_(mthis) => mthis["hardwareConcurrency"];

  isProtocolHandlerRegistered_Callback_0_(mthis) => mthis.callMethod("isProtocolHandlerRegistered", []);

  isProtocolHandlerRegistered_Callback_1_(mthis, __arg_0) => mthis.callMethod("isProtocolHandlerRegistered", [__arg_0]);

  isProtocolHandlerRegistered_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("isProtocolHandlerRegistered", [__arg_0, __arg_1]);

  javaEnabled_Callback_0_(mthis) => mthis.callMethod("javaEnabled", []);

  language_Getter_(mthis) => mthis["language"];

  languages_Getter_(mthis) => mthis["languages"];

  maxTouchPoints_Getter_(mthis) => mthis["maxTouchPoints"];

  mimeTypes_Getter_(mthis) => mthis["mimeTypes"];

  onLine_Getter_(mthis) => mthis["onLine"];

  platform_Getter_(mthis) => mthis["platform"];

  plugins_Getter_(mthis) => mthis["plugins"];

  presentation_Getter_(mthis) => mthis["presentation"];

  productSub_Getter_(mthis) => mthis["productSub"];

  product_Getter_(mthis) => mthis["product"];

  push_Getter_(mthis) => mthis["push"];

  registerProtocolHandler_Callback_1_(mthis, __arg_0) => mthis.callMethod("registerProtocolHandler", [__arg_0]);

  registerProtocolHandler_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("registerProtocolHandler", [__arg_0, __arg_1]);

  registerProtocolHandler_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("registerProtocolHandler", [__arg_0, __arg_1, __arg_2]);

  sendBeacon_Callback_0_(mthis) => mthis.callMethod("sendBeacon", []);

  sendBeacon_Callback_1_(mthis, __arg_0) => mthis.callMethod("sendBeacon", [__arg_0]);

  sendBeacon_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("sendBeacon", [__arg_0, __arg_1]);

  serviceWorker_Getter_(mthis) => mthis["serviceWorker"];

  storageQuota_Getter_(mthis) => mthis["storageQuota"];

  unregisterProtocolHandler_Callback_0_(mthis) => mthis.callMethod("unregisterProtocolHandler", []);

  unregisterProtocolHandler_Callback_1_(mthis, __arg_0) => mthis.callMethod("unregisterProtocolHandler", [__arg_0]);

  unregisterProtocolHandler_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("unregisterProtocolHandler", [__arg_0, __arg_1]);

  userAgent_Getter_(mthis) => mthis["userAgent"];

  vendorSub_Getter_(mthis) => mthis["vendorSub"];

  vendor_Getter_(mthis) => mthis["vendor"];

  vibrate_Callback_0_(mthis) => mthis.callMethod("vibrate", []);

  vibrate_Callback_1_(mthis, __arg_0) => mthis.callMethod("vibrate", [__arg_0]);

  webkitGetGamepads_Callback_0_(mthis) => mthis.callMethod("webkitGetGamepads", []);

  webkitGetUserMedia_Callback_1_(mthis, __arg_0) => mthis.callMethod("webkitGetUserMedia", [__arg_0]);

  webkitGetUserMedia_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("webkitGetUserMedia", [__arg_0, __arg_1]);

  webkitGetUserMedia_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("webkitGetUserMedia", [__arg_0, __arg_1, __arg_2]);

  webkitPersistentStorage_Getter_(mthis) => mthis["webkitPersistentStorage"];

  webkitTemporaryStorage_Getter_(mthis) => mthis["webkitTemporaryStorage"];

}

class BlinkNavigatorUserMediaError {
  static final instance = new BlinkNavigatorUserMediaError();

  constraintName_Getter_(mthis) => mthis["constraintName"];

  message_Getter_(mthis) => mthis["message"];

  name_Getter_(mthis) => mthis["name"];

}

class BlinkNetworkInformation extends BlinkEventTarget {
  static final instance = new BlinkNetworkInformation();

  ontypechange_Getter_(mthis) => mthis["ontypechange"];

  ontypechange_Setter_(mthis, __arg_0) => mthis["ontypechange"] = __arg_0;

  type_Getter_(mthis) => mthis["type"];

}

class BlinkNode extends BlinkEventTarget {
  static final instance = new BlinkNode();

  appendChild_Callback_0_(mthis) => mthis.callMethod("appendChild", []);

  appendChild_Callback_1_(mthis, __arg_0) => mthis.callMethod("appendChild", [__arg_0]);

  baseURI_Getter_(mthis) => mthis["baseURI"];

  childNodes_Getter_(mthis) => mthis["childNodes"];

  cloneNode_Callback_0_(mthis) => mthis.callMethod("cloneNode", []);

  cloneNode_Callback_1_(mthis, __arg_0) => mthis.callMethod("cloneNode", [__arg_0]);

  contains_Callback_0_(mthis) => mthis.callMethod("contains", []);

  contains_Callback_1_(mthis, __arg_0) => mthis.callMethod("contains", [__arg_0]);

  firstChild_Getter_(mthis) => mthis["firstChild"];

  hasChildNodes_Callback_0_(mthis) => mthis.callMethod("hasChildNodes", []);

  insertBefore_Callback_0_(mthis) => mthis.callMethod("insertBefore", []);

  insertBefore_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertBefore", [__arg_0]);

  insertBefore_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("insertBefore", [__arg_0, __arg_1]);

  lastChild_Getter_(mthis) => mthis["lastChild"];

  localName_Getter_(mthis) => mthis["localName"];

  namespaceURI_Getter_(mthis) => mthis["namespaceURI"];

  nextSibling_Getter_(mthis) => mthis["nextSibling"];

  nodeName_Getter_(mthis) => mthis["nodeName"];

  nodeType_Getter_(mthis) => mthis["nodeType"];

  nodeValue_Getter_(mthis) => mthis["nodeValue"];

  nodeValue_Setter_(mthis, __arg_0) => mthis["nodeValue"] = __arg_0;

  ownerDocument_Getter_(mthis) => mthis["ownerDocument"];

  parentElement_Getter_(mthis) => mthis["parentElement"];

  parentNode_Getter_(mthis) => mthis["parentNode"];

  previousSibling_Getter_(mthis) => mthis["previousSibling"];

  removeChild_Callback_0_(mthis) => mthis.callMethod("removeChild", []);

  removeChild_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeChild", [__arg_0]);

  replaceChild_Callback_0_(mthis) => mthis.callMethod("replaceChild", []);

  replaceChild_Callback_1_(mthis, __arg_0) => mthis.callMethod("replaceChild", [__arg_0]);

  replaceChild_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("replaceChild", [__arg_0, __arg_1]);

  textContent_Getter_(mthis) => mthis["textContent"];

  textContent_Setter_(mthis, __arg_0) => mthis["textContent"] = __arg_0;

}

class BlinkNodeFilter {
  static final instance = new BlinkNodeFilter();

}

class BlinkNodeIterator {
  static final instance = new BlinkNodeIterator();

  detach_Callback_0_(mthis) => mthis.callMethod("detach", []);

  nextNode_Callback_0_(mthis) => mthis.callMethod("nextNode", []);

  pointerBeforeReferenceNode_Getter_(mthis) => mthis["pointerBeforeReferenceNode"];

  previousNode_Callback_0_(mthis) => mthis.callMethod("previousNode", []);

  referenceNode_Getter_(mthis) => mthis["referenceNode"];

  root_Getter_(mthis) => mthis["root"];

  whatToShow_Getter_(mthis) => mthis["whatToShow"];

}

class BlinkNodeList {
  static final instance = new BlinkNodeList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

}

class BlinkNotification extends BlinkEventTarget {
  static final instance = new BlinkNotification();

  body_Getter_(mthis) => mthis["body"];

  close_Callback_0_(mthis) => mthis.callMethod("close", []);

  constructorCallback_0_() => new js.JsObject(js.context["Notification"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["Notification"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["Notification"], [__arg_0, __arg_1]);

  dir_Getter_(mthis) => mthis["dir"];

  icon_Getter_(mthis) => mthis["icon"];

  lang_Getter_(mthis) => mthis["lang"];

  onclick_Getter_(mthis) => mthis["onclick"];

  onclick_Setter_(mthis, __arg_0) => mthis["onclick"] = __arg_0;

  onclose_Getter_(mthis) => mthis["onclose"];

  onclose_Setter_(mthis, __arg_0) => mthis["onclose"] = __arg_0;

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onshow_Getter_(mthis) => mthis["onshow"];

  onshow_Setter_(mthis, __arg_0) => mthis["onshow"] = __arg_0;

  permission_Getter_() => mthis["permission"];

  requestPermission_Callback_0_() => js.context["Notification"].callMethod("requestPermission", []);

  requestPermission_Callback_1_(__arg_0) => js.context["Notification"].callMethod("requestPermission", [__arg_0]);

  tag_Getter_(mthis) => mthis["tag"];

  title_Getter_(mthis) => mthis["title"];

}

class BlinkOESElementIndexUint {
  static final instance = new BlinkOESElementIndexUint();

}

class BlinkOESStandardDerivatives {
  static final instance = new BlinkOESStandardDerivatives();

}

class BlinkOESTextureFloat {
  static final instance = new BlinkOESTextureFloat();

}

class BlinkOESTextureFloatLinear {
  static final instance = new BlinkOESTextureFloatLinear();

}

class BlinkOESTextureHalfFloat {
  static final instance = new BlinkOESTextureHalfFloat();

}

class BlinkOESTextureHalfFloatLinear {
  static final instance = new BlinkOESTextureHalfFloatLinear();

}

class BlinkOESVertexArrayObject {
  static final instance = new BlinkOESVertexArrayObject();

  bindVertexArrayOES_Callback_0_(mthis) => mthis.callMethod("bindVertexArrayOES", []);

  bindVertexArrayOES_Callback_1_(mthis, __arg_0) => mthis.callMethod("bindVertexArrayOES", [__arg_0]);

  createVertexArrayOES_Callback_0_(mthis) => mthis.callMethod("createVertexArrayOES", []);

  deleteVertexArrayOES_Callback_0_(mthis) => mthis.callMethod("deleteVertexArrayOES", []);

  deleteVertexArrayOES_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteVertexArrayOES", [__arg_0]);

  isVertexArrayOES_Callback_0_(mthis) => mthis.callMethod("isVertexArrayOES", []);

  isVertexArrayOES_Callback_1_(mthis, __arg_0) => mthis.callMethod("isVertexArrayOES", [__arg_0]);

}

class BlinkOfflineAudioCompletionEvent extends BlinkEvent {
  static final instance = new BlinkOfflineAudioCompletionEvent();

  renderedBuffer_Getter_(mthis) => mthis["renderedBuffer"];

}

class BlinkOfflineAudioContext extends BlinkAudioContext {
  static final instance = new BlinkOfflineAudioContext();

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["OfflineAudioContext"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["OfflineAudioContext"], [__arg_0, __arg_1]);

  constructorCallback_3_(__arg_0, __arg_1, __arg_2) => new js.JsObject(js.context["OfflineAudioContext"], [__arg_0, __arg_1, __arg_2]);

}

class BlinkOscillatorNode extends BlinkAudioSourceNode {
  static final instance = new BlinkOscillatorNode();

  detune_Getter_(mthis) => mthis["detune"];

  frequency_Getter_(mthis) => mthis["frequency"];

  noteOff_Callback_0_(mthis) => mthis.callMethod("noteOff", []);

  noteOff_Callback_1_(mthis, __arg_0) => mthis.callMethod("noteOff", [__arg_0]);

  noteOn_Callback_0_(mthis) => mthis.callMethod("noteOn", []);

  noteOn_Callback_1_(mthis, __arg_0) => mthis.callMethod("noteOn", [__arg_0]);

  onended_Getter_(mthis) => mthis["onended"];

  onended_Setter_(mthis, __arg_0) => mthis["onended"] = __arg_0;

  setPeriodicWave_Callback_0_(mthis) => mthis.callMethod("setPeriodicWave", []);

  setPeriodicWave_Callback_1_(mthis, __arg_0) => mthis.callMethod("setPeriodicWave", [__arg_0]);

  start_Callback_0_(mthis) => mthis.callMethod("start", []);

  start_Callback_1_(mthis, __arg_0) => mthis.callMethod("start", [__arg_0]);

  stop_Callback_0_(mthis) => mthis.callMethod("stop", []);

  stop_Callback_1_(mthis, __arg_0) => mthis.callMethod("stop", [__arg_0]);

  type_Getter_(mthis) => mthis["type"];

  type_Setter_(mthis, __arg_0) => mthis["type"] = __arg_0;

}

class BlinkOverflowEvent extends BlinkEvent {
  static final instance = new BlinkOverflowEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["OverflowEvent"], [__arg_0, __arg_1]);

  horizontalOverflow_Getter_(mthis) => mthis["horizontalOverflow"];

  orient_Getter_(mthis) => mthis["orient"];

  verticalOverflow_Getter_(mthis) => mthis["verticalOverflow"];

}

class BlinkPagePopupController {
  static final instance = new BlinkPagePopupController();

  closePopup_Callback_0_(mthis) => mthis.callMethod("closePopup", []);

  formatMonth_Callback_0_(mthis) => mthis.callMethod("formatMonth", []);

  formatMonth_Callback_1_(mthis, __arg_0) => mthis.callMethod("formatMonth", [__arg_0]);

  formatMonth_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("formatMonth", [__arg_0, __arg_1]);

  formatShortMonth_Callback_0_(mthis) => mthis.callMethod("formatShortMonth", []);

  formatShortMonth_Callback_1_(mthis, __arg_0) => mthis.callMethod("formatShortMonth", [__arg_0]);

  formatShortMonth_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("formatShortMonth", [__arg_0, __arg_1]);

  formatWeek_Callback_1_(mthis, __arg_0) => mthis.callMethod("formatWeek", [__arg_0]);

  formatWeek_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("formatWeek", [__arg_0, __arg_1]);

  formatWeek_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("formatWeek", [__arg_0, __arg_1, __arg_2]);

  histogramEnumeration_Callback_1_(mthis, __arg_0) => mthis.callMethod("histogramEnumeration", [__arg_0]);

  histogramEnumeration_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("histogramEnumeration", [__arg_0, __arg_1]);

  histogramEnumeration_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("histogramEnumeration", [__arg_0, __arg_1, __arg_2]);

  localizeNumberString_Callback_0_(mthis) => mthis.callMethod("localizeNumberString", []);

  localizeNumberString_Callback_1_(mthis, __arg_0) => mthis.callMethod("localizeNumberString", [__arg_0]);

  setValueAndClosePopup_Callback_0_(mthis) => mthis.callMethod("setValueAndClosePopup", []);

  setValueAndClosePopup_Callback_1_(mthis, __arg_0) => mthis.callMethod("setValueAndClosePopup", [__arg_0]);

  setValueAndClosePopup_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setValueAndClosePopup", [__arg_0, __arg_1]);

  setValue_Callback_0_(mthis) => mthis.callMethod("setValue", []);

  setValue_Callback_1_(mthis, __arg_0) => mthis.callMethod("setValue", [__arg_0]);

}

class BlinkPageTransitionEvent extends BlinkEvent {
  static final instance = new BlinkPageTransitionEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["PageTransitionEvent"], [__arg_0, __arg_1]);

  persisted_Getter_(mthis) => mthis["persisted"];

}

class BlinkPannerNode extends BlinkAudioNode {
  static final instance = new BlinkPannerNode();

  coneInnerAngle_Getter_(mthis) => mthis["coneInnerAngle"];

  coneInnerAngle_Setter_(mthis, __arg_0) => mthis["coneInnerAngle"] = __arg_0;

  coneOuterAngle_Getter_(mthis) => mthis["coneOuterAngle"];

  coneOuterAngle_Setter_(mthis, __arg_0) => mthis["coneOuterAngle"] = __arg_0;

  coneOuterGain_Getter_(mthis) => mthis["coneOuterGain"];

  coneOuterGain_Setter_(mthis, __arg_0) => mthis["coneOuterGain"] = __arg_0;

  distanceModel_Getter_(mthis) => mthis["distanceModel"];

  distanceModel_Setter_(mthis, __arg_0) => mthis["distanceModel"] = __arg_0;

  maxDistance_Getter_(mthis) => mthis["maxDistance"];

  maxDistance_Setter_(mthis, __arg_0) => mthis["maxDistance"] = __arg_0;

  panningModel_Getter_(mthis) => mthis["panningModel"];

  panningModel_Setter_(mthis, __arg_0) => mthis["panningModel"] = __arg_0;

  refDistance_Getter_(mthis) => mthis["refDistance"];

  refDistance_Setter_(mthis, __arg_0) => mthis["refDistance"] = __arg_0;

  rolloffFactor_Getter_(mthis) => mthis["rolloffFactor"];

  rolloffFactor_Setter_(mthis, __arg_0) => mthis["rolloffFactor"] = __arg_0;

  setOrientation_Callback_1_(mthis, __arg_0) => mthis.callMethod("setOrientation", [__arg_0]);

  setOrientation_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setOrientation", [__arg_0, __arg_1]);

  setOrientation_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setOrientation", [__arg_0, __arg_1, __arg_2]);

  setPosition_Callback_1_(mthis, __arg_0) => mthis.callMethod("setPosition", [__arg_0]);

  setPosition_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setPosition", [__arg_0, __arg_1]);

  setPosition_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setPosition", [__arg_0, __arg_1, __arg_2]);

  setVelocity_Callback_1_(mthis, __arg_0) => mthis.callMethod("setVelocity", [__arg_0]);

  setVelocity_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setVelocity", [__arg_0, __arg_1]);

  setVelocity_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setVelocity", [__arg_0, __arg_1, __arg_2]);

}

class BlinkPath2D {
  static final instance = new BlinkPath2D();

  addPath_Callback_0_(mthis) => mthis.callMethod("addPath", []);

  addPath_Callback_1_(mthis, __arg_0) => mthis.callMethod("addPath", [__arg_0]);

  addPath_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("addPath", [__arg_0, __arg_1]);

  arcTo_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("arcTo", [__arg_0, __arg_1, __arg_2]);

  arcTo_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("arcTo", [__arg_0, __arg_1, __arg_2, __arg_3]);

  arcTo_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("arcTo", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  arc_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("arc", [__arg_0, __arg_1, __arg_2]);

  arc_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("arc", [__arg_0, __arg_1, __arg_2, __arg_3]);

  arc_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("arc", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  arc_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("arc", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  bezierCurveTo_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("bezierCurveTo", [__arg_0, __arg_1, __arg_2, __arg_3]);

  bezierCurveTo_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("bezierCurveTo", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  bezierCurveTo_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("bezierCurveTo", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  closePath_Callback_0_(mthis) => mthis.callMethod("closePath", []);

  constructorCallback_0_() => new js.JsObject(js.context["Path2D"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["Path2D"], [__arg_0]);

  ellipse_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("ellipse", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  ellipse_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("ellipse", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  ellipse_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("ellipse", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  ellipse_Callback_8_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7) => mthis.callMethod("ellipse", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7]);

  lineTo_Callback_0_(mthis) => mthis.callMethod("lineTo", []);

  lineTo_Callback_1_(mthis, __arg_0) => mthis.callMethod("lineTo", [__arg_0]);

  lineTo_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("lineTo", [__arg_0, __arg_1]);

  moveTo_Callback_0_(mthis) => mthis.callMethod("moveTo", []);

  moveTo_Callback_1_(mthis, __arg_0) => mthis.callMethod("moveTo", [__arg_0]);

  moveTo_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("moveTo", [__arg_0, __arg_1]);

  quadraticCurveTo_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("quadraticCurveTo", [__arg_0, __arg_1]);

  quadraticCurveTo_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("quadraticCurveTo", [__arg_0, __arg_1, __arg_2]);

  quadraticCurveTo_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("quadraticCurveTo", [__arg_0, __arg_1, __arg_2, __arg_3]);

  rect_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("rect", [__arg_0, __arg_1]);

  rect_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("rect", [__arg_0, __arg_1, __arg_2]);

  rect_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("rect", [__arg_0, __arg_1, __arg_2, __arg_3]);

}

class BlinkPerformance extends BlinkEventTarget {
  static final instance = new BlinkPerformance();

  clearMarks_Callback_0_(mthis) => mthis.callMethod("clearMarks", []);

  clearMarks_Callback_1_(mthis, __arg_0) => mthis.callMethod("clearMarks", [__arg_0]);

  clearMeasures_Callback_0_(mthis) => mthis.callMethod("clearMeasures", []);

  clearMeasures_Callback_1_(mthis, __arg_0) => mthis.callMethod("clearMeasures", [__arg_0]);

  getEntriesByName_Callback_0_(mthis) => mthis.callMethod("getEntriesByName", []);

  getEntriesByName_Callback_1_(mthis, __arg_0) => mthis.callMethod("getEntriesByName", [__arg_0]);

  getEntriesByName_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getEntriesByName", [__arg_0, __arg_1]);

  getEntriesByType_Callback_0_(mthis) => mthis.callMethod("getEntriesByType", []);

  getEntriesByType_Callback_1_(mthis, __arg_0) => mthis.callMethod("getEntriesByType", [__arg_0]);

  getEntries_Callback_0_(mthis) => mthis.callMethod("getEntries", []);

  mark_Callback_0_(mthis) => mthis.callMethod("mark", []);

  mark_Callback_1_(mthis, __arg_0) => mthis.callMethod("mark", [__arg_0]);

  measure_Callback_0_(mthis) => mthis.callMethod("measure", []);

  measure_Callback_1_(mthis, __arg_0) => mthis.callMethod("measure", [__arg_0]);

  measure_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("measure", [__arg_0, __arg_1]);

  measure_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("measure", [__arg_0, __arg_1, __arg_2]);

  memory_Getter_(mthis) => mthis["memory"];

  navigation_Getter_(mthis) => mthis["navigation"];

  now_Callback_0_(mthis) => mthis.callMethod("now", []);

  onwebkitresourcetimingbufferfull_Getter_(mthis) => mthis["onwebkitresourcetimingbufferfull"];

  onwebkitresourcetimingbufferfull_Setter_(mthis, __arg_0) => mthis["onwebkitresourcetimingbufferfull"] = __arg_0;

  timing_Getter_(mthis) => mthis["timing"];

  webkitClearResourceTimings_Callback_0_(mthis) => mthis.callMethod("webkitClearResourceTimings", []);

  webkitSetResourceTimingBufferSize_Callback_0_(mthis) => mthis.callMethod("webkitSetResourceTimingBufferSize", []);

  webkitSetResourceTimingBufferSize_Callback_1_(mthis, __arg_0) => mthis.callMethod("webkitSetResourceTimingBufferSize", [__arg_0]);

}

class BlinkPerformanceEntry {
  static final instance = new BlinkPerformanceEntry();

  duration_Getter_(mthis) => mthis["duration"];

  entryType_Getter_(mthis) => mthis["entryType"];

  name_Getter_(mthis) => mthis["name"];

  startTime_Getter_(mthis) => mthis["startTime"];

}

class BlinkPerformanceMark extends BlinkPerformanceEntry {
  static final instance = new BlinkPerformanceMark();

}

class BlinkPerformanceMeasure extends BlinkPerformanceEntry {
  static final instance = new BlinkPerformanceMeasure();

}

class BlinkPerformanceNavigation {
  static final instance = new BlinkPerformanceNavigation();

  redirectCount_Getter_(mthis) => mthis["redirectCount"];

  type_Getter_(mthis) => mthis["type"];

}

class BlinkPerformanceResourceTiming extends BlinkPerformanceEntry {
  static final instance = new BlinkPerformanceResourceTiming();

  connectEnd_Getter_(mthis) => mthis["connectEnd"];

  connectStart_Getter_(mthis) => mthis["connectStart"];

  domainLookupEnd_Getter_(mthis) => mthis["domainLookupEnd"];

  domainLookupStart_Getter_(mthis) => mthis["domainLookupStart"];

  fetchStart_Getter_(mthis) => mthis["fetchStart"];

  initiatorType_Getter_(mthis) => mthis["initiatorType"];

  redirectEnd_Getter_(mthis) => mthis["redirectEnd"];

  redirectStart_Getter_(mthis) => mthis["redirectStart"];

  requestStart_Getter_(mthis) => mthis["requestStart"];

  responseEnd_Getter_(mthis) => mthis["responseEnd"];

  responseStart_Getter_(mthis) => mthis["responseStart"];

  secureConnectionStart_Getter_(mthis) => mthis["secureConnectionStart"];

}

class BlinkPerformanceTiming {
  static final instance = new BlinkPerformanceTiming();

  connectEnd_Getter_(mthis) => mthis["connectEnd"];

  connectStart_Getter_(mthis) => mthis["connectStart"];

  domComplete_Getter_(mthis) => mthis["domComplete"];

  domContentLoadedEventEnd_Getter_(mthis) => mthis["domContentLoadedEventEnd"];

  domContentLoadedEventStart_Getter_(mthis) => mthis["domContentLoadedEventStart"];

  domInteractive_Getter_(mthis) => mthis["domInteractive"];

  domLoading_Getter_(mthis) => mthis["domLoading"];

  domainLookupEnd_Getter_(mthis) => mthis["domainLookupEnd"];

  domainLookupStart_Getter_(mthis) => mthis["domainLookupStart"];

  fetchStart_Getter_(mthis) => mthis["fetchStart"];

  loadEventEnd_Getter_(mthis) => mthis["loadEventEnd"];

  loadEventStart_Getter_(mthis) => mthis["loadEventStart"];

  navigationStart_Getter_(mthis) => mthis["navigationStart"];

  redirectEnd_Getter_(mthis) => mthis["redirectEnd"];

  redirectStart_Getter_(mthis) => mthis["redirectStart"];

  requestStart_Getter_(mthis) => mthis["requestStart"];

  responseEnd_Getter_(mthis) => mthis["responseEnd"];

  responseStart_Getter_(mthis) => mthis["responseStart"];

  secureConnectionStart_Getter_(mthis) => mthis["secureConnectionStart"];

  unloadEventEnd_Getter_(mthis) => mthis["unloadEventEnd"];

  unloadEventStart_Getter_(mthis) => mthis["unloadEventStart"];

}

class BlinkPeriodicWave {
  static final instance = new BlinkPeriodicWave();

}

class BlinkPlugin {
  static final instance = new BlinkPlugin();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  description_Getter_(mthis) => mthis["description"];

  filename_Getter_(mthis) => mthis["filename"];

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

  name_Getter_(mthis) => mthis["name"];

  namedItem_Callback_0_(mthis) => mthis.callMethod("namedItem", []);

  namedItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("namedItem", [__arg_0]);

}

class BlinkPluginArray {
  static final instance = new BlinkPluginArray();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

  namedItem_Callback_0_(mthis) => mthis.callMethod("namedItem", []);

  namedItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("namedItem", [__arg_0]);

  refresh_Callback_0_(mthis) => mthis.callMethod("refresh", []);

  refresh_Callback_1_(mthis, __arg_0) => mthis.callMethod("refresh", [__arg_0]);

}

class BlinkPluginPlaceholderElement extends BlinkHTMLDivElement {
  static final instance = new BlinkPluginPlaceholderElement();

  createdCallback_Callback_0_(mthis) => mthis.callMethod("createdCallback", []);

  message_Getter_(mthis) => mthis["message"];

  message_Setter_(mthis, __arg_0) => mthis["message"] = __arg_0;

}

class BlinkPopStateEvent extends BlinkEvent {
  static final instance = new BlinkPopStateEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["PopStateEvent"], [__arg_0, __arg_1]);

  state_Getter_(mthis) => mthis["state"];

}

class BlinkPositionError {
  static final instance = new BlinkPositionError();

  code_Getter_(mthis) => mthis["code"];

  message_Getter_(mthis) => mthis["message"];

}

class BlinkPresentation extends BlinkEventTarget {
  static final instance = new BlinkPresentation();

  onavailablechange_Getter_(mthis) => mthis["onavailablechange"];

  onavailablechange_Setter_(mthis, __arg_0) => mthis["onavailablechange"] = __arg_0;

}

class BlinkProcessingInstruction extends BlinkCharacterData {
  static final instance = new BlinkProcessingInstruction();

  sheet_Getter_(mthis) => mthis["sheet"];

  target_Getter_(mthis) => mthis["target"];

}

class BlinkProgressEvent extends BlinkEvent {
  static final instance = new BlinkProgressEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["ProgressEvent"], [__arg_0, __arg_1]);

  lengthComputable_Getter_(mthis) => mthis["lengthComputable"];

  loaded_Getter_(mthis) => mthis["loaded"];

  total_Getter_(mthis) => mthis["total"];

}

class BlinkPushEvent extends BlinkEvent {
  static final instance = new BlinkPushEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["PushEvent"], [__arg_0, __arg_1]);

  data_Getter_(mthis) => mthis["data"];

}

class BlinkPushManager {
  static final instance = new BlinkPushManager();

  register_Callback_0_(mthis) => mthis.callMethod("register", []);

  register_Callback_1_(mthis, __arg_0) => mthis.callMethod("register", [__arg_0]);

}

class BlinkPushRegistration {
  static final instance = new BlinkPushRegistration();

  pushEndpoint_Getter_(mthis) => mthis["pushEndpoint"];

  pushRegistrationId_Getter_(mthis) => mthis["pushRegistrationId"];

}

class BlinkRGBColor {
  static final instance = new BlinkRGBColor();

  blue_Getter_(mthis) => mthis["blue"];

  green_Getter_(mthis) => mthis["green"];

  red_Getter_(mthis) => mthis["red"];

}

class BlinkRTCDTMFSender extends BlinkEventTarget {
  static final instance = new BlinkRTCDTMFSender();

  canInsertDTMF_Getter_(mthis) => mthis["canInsertDTMF"];

  duration_Getter_(mthis) => mthis["duration"];

  insertDTMF_Callback_0_(mthis) => mthis.callMethod("insertDTMF", []);

  insertDTMF_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertDTMF", [__arg_0]);

  insertDTMF_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("insertDTMF", [__arg_0, __arg_1]);

  insertDTMF_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("insertDTMF", [__arg_0, __arg_1, __arg_2]);

  interToneGap_Getter_(mthis) => mthis["interToneGap"];

  ontonechange_Getter_(mthis) => mthis["ontonechange"];

  ontonechange_Setter_(mthis, __arg_0) => mthis["ontonechange"] = __arg_0;

  toneBuffer_Getter_(mthis) => mthis["toneBuffer"];

  track_Getter_(mthis) => mthis["track"];

}

class BlinkRTCDTMFToneChangeEvent extends BlinkEvent {
  static final instance = new BlinkRTCDTMFToneChangeEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["RTCDTMFToneChangeEvent"], [__arg_0, __arg_1]);

  tone_Getter_(mthis) => mthis["tone"];

}

class BlinkRTCDataChannel extends BlinkEventTarget {
  static final instance = new BlinkRTCDataChannel();

  binaryType_Getter_(mthis) => mthis["binaryType"];

  binaryType_Setter_(mthis, __arg_0) => mthis["binaryType"] = __arg_0;

  bufferedAmount_Getter_(mthis) => mthis["bufferedAmount"];

  close_Callback_0_(mthis) => mthis.callMethod("close", []);

  id_Getter_(mthis) => mthis["id"];

  label_Getter_(mthis) => mthis["label"];

  maxRetransmitTime_Getter_(mthis) => mthis["maxRetransmitTime"];

  maxRetransmits_Getter_(mthis) => mthis["maxRetransmits"];

  negotiated_Getter_(mthis) => mthis["negotiated"];

  onclose_Getter_(mthis) => mthis["onclose"];

  onclose_Setter_(mthis, __arg_0) => mthis["onclose"] = __arg_0;

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onmessage_Getter_(mthis) => mthis["onmessage"];

  onmessage_Setter_(mthis, __arg_0) => mthis["onmessage"] = __arg_0;

  onopen_Getter_(mthis) => mthis["onopen"];

  onopen_Setter_(mthis, __arg_0) => mthis["onopen"] = __arg_0;

  ordered_Getter_(mthis) => mthis["ordered"];

  protocol_Getter_(mthis) => mthis["protocol"];

  readyState_Getter_(mthis) => mthis["readyState"];

  reliable_Getter_(mthis) => mthis["reliable"];

  send_Callback_0_(mthis) => mthis.callMethod("send", []);

  send_Callback_1_(mthis, __arg_0) => mthis.callMethod("send", [__arg_0]);

}

class BlinkRTCDataChannelEvent extends BlinkEvent {
  static final instance = new BlinkRTCDataChannelEvent();

  channel_Getter_(mthis) => mthis["channel"];

}

class BlinkRTCIceCandidate {
  static final instance = new BlinkRTCIceCandidate();

  candidate_Getter_(mthis) => mthis["candidate"];

  candidate_Setter_(mthis, __arg_0) => mthis["candidate"] = __arg_0;

  constructorCallback_0_() => new js.JsObject(js.context["RTCIceCandidate"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["RTCIceCandidate"], [__arg_0]);

  sdpMLineIndex_Getter_(mthis) => mthis["sdpMLineIndex"];

  sdpMLineIndex_Setter_(mthis, __arg_0) => mthis["sdpMLineIndex"] = __arg_0;

  sdpMid_Getter_(mthis) => mthis["sdpMid"];

  sdpMid_Setter_(mthis, __arg_0) => mthis["sdpMid"] = __arg_0;

}

class BlinkRTCIceCandidateEvent extends BlinkEvent {
  static final instance = new BlinkRTCIceCandidateEvent();

  candidate_Getter_(mthis) => mthis["candidate"];

}

class BlinkRTCPeerConnection extends BlinkEventTarget {
  static final instance = new BlinkRTCPeerConnection();

  addIceCandidate_Callback_1_(mthis, __arg_0) => mthis.callMethod("addIceCandidate", [__arg_0]);

  addIceCandidate_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("addIceCandidate", [__arg_0, __arg_1]);

  addIceCandidate_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("addIceCandidate", [__arg_0, __arg_1, __arg_2]);

  addStream_Callback_0_(mthis) => mthis.callMethod("addStream", []);

  addStream_Callback_1_(mthis, __arg_0) => mthis.callMethod("addStream", [__arg_0]);

  addStream_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("addStream", [__arg_0, __arg_1]);

  close_Callback_0_(mthis) => mthis.callMethod("close", []);

  constructorCallback_0_() => new js.JsObject(js.context["webkitRTCPeerConnection"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["webkitRTCPeerConnection"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["webkitRTCPeerConnection"], [__arg_0, __arg_1]);

  createAnswer_Callback_0_(mthis) => mthis.callMethod("createAnswer", []);

  createAnswer_Callback_1_(mthis, __arg_0) => mthis.callMethod("createAnswer", [__arg_0]);

  createAnswer_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createAnswer", [__arg_0, __arg_1]);

  createAnswer_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("createAnswer", [__arg_0, __arg_1, __arg_2]);

  createDTMFSender_Callback_0_(mthis) => mthis.callMethod("createDTMFSender", []);

  createDTMFSender_Callback_1_(mthis, __arg_0) => mthis.callMethod("createDTMFSender", [__arg_0]);

  createDataChannel_Callback_0_(mthis) => mthis.callMethod("createDataChannel", []);

  createDataChannel_Callback_1_(mthis, __arg_0) => mthis.callMethod("createDataChannel", [__arg_0]);

  createDataChannel_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createDataChannel", [__arg_0, __arg_1]);

  createOffer_Callback_0_(mthis) => mthis.callMethod("createOffer", []);

  createOffer_Callback_1_(mthis, __arg_0) => mthis.callMethod("createOffer", [__arg_0]);

  createOffer_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createOffer", [__arg_0, __arg_1]);

  createOffer_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("createOffer", [__arg_0, __arg_1, __arg_2]);

  getLocalStreams_Callback_0_(mthis) => mthis.callMethod("getLocalStreams", []);

  getRemoteStreams_Callback_0_(mthis) => mthis.callMethod("getRemoteStreams", []);

  getStats_Callback_0_(mthis) => mthis.callMethod("getStats", []);

  getStats_Callback_1_(mthis, __arg_0) => mthis.callMethod("getStats", [__arg_0]);

  getStats_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getStats", [__arg_0, __arg_1]);

  getStreamById_Callback_0_(mthis) => mthis.callMethod("getStreamById", []);

  getStreamById_Callback_1_(mthis, __arg_0) => mthis.callMethod("getStreamById", [__arg_0]);

  iceConnectionState_Getter_(mthis) => mthis["iceConnectionState"];

  iceGatheringState_Getter_(mthis) => mthis["iceGatheringState"];

  localDescription_Getter_(mthis) => mthis["localDescription"];

  onaddstream_Getter_(mthis) => mthis["onaddstream"];

  onaddstream_Setter_(mthis, __arg_0) => mthis["onaddstream"] = __arg_0;

  ondatachannel_Getter_(mthis) => mthis["ondatachannel"];

  ondatachannel_Setter_(mthis, __arg_0) => mthis["ondatachannel"] = __arg_0;

  onicecandidate_Getter_(mthis) => mthis["onicecandidate"];

  onicecandidate_Setter_(mthis, __arg_0) => mthis["onicecandidate"] = __arg_0;

  oniceconnectionstatechange_Getter_(mthis) => mthis["oniceconnectionstatechange"];

  oniceconnectionstatechange_Setter_(mthis, __arg_0) => mthis["oniceconnectionstatechange"] = __arg_0;

  onnegotiationneeded_Getter_(mthis) => mthis["onnegotiationneeded"];

  onnegotiationneeded_Setter_(mthis, __arg_0) => mthis["onnegotiationneeded"] = __arg_0;

  onremovestream_Getter_(mthis) => mthis["onremovestream"];

  onremovestream_Setter_(mthis, __arg_0) => mthis["onremovestream"] = __arg_0;

  onsignalingstatechange_Getter_(mthis) => mthis["onsignalingstatechange"];

  onsignalingstatechange_Setter_(mthis, __arg_0) => mthis["onsignalingstatechange"] = __arg_0;

  remoteDescription_Getter_(mthis) => mthis["remoteDescription"];

  removeStream_Callback_0_(mthis) => mthis.callMethod("removeStream", []);

  removeStream_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeStream", [__arg_0]);

  setLocalDescription_Callback_0_(mthis) => mthis.callMethod("setLocalDescription", []);

  setLocalDescription_Callback_1_(mthis, __arg_0) => mthis.callMethod("setLocalDescription", [__arg_0]);

  setLocalDescription_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setLocalDescription", [__arg_0, __arg_1]);

  setLocalDescription_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setLocalDescription", [__arg_0, __arg_1, __arg_2]);

  setRemoteDescription_Callback_0_(mthis) => mthis.callMethod("setRemoteDescription", []);

  setRemoteDescription_Callback_1_(mthis, __arg_0) => mthis.callMethod("setRemoteDescription", [__arg_0]);

  setRemoteDescription_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setRemoteDescription", [__arg_0, __arg_1]);

  setRemoteDescription_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setRemoteDescription", [__arg_0, __arg_1, __arg_2]);

  signalingState_Getter_(mthis) => mthis["signalingState"];

  updateIce_Callback_0_(mthis) => mthis.callMethod("updateIce", []);

  updateIce_Callback_1_(mthis, __arg_0) => mthis.callMethod("updateIce", [__arg_0]);

  updateIce_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("updateIce", [__arg_0, __arg_1]);

}

class BlinkRTCSessionDescription {
  static final instance = new BlinkRTCSessionDescription();

  constructorCallback_0_() => new js.JsObject(js.context["RTCSessionDescription"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["RTCSessionDescription"], [__arg_0]);

  sdp_Getter_(mthis) => mthis["sdp"];

  sdp_Setter_(mthis, __arg_0) => mthis["sdp"] = __arg_0;

  type_Getter_(mthis) => mthis["type"];

  type_Setter_(mthis, __arg_0) => mthis["type"] = __arg_0;

}

class BlinkRTCStatsReport {
  static final instance = new BlinkRTCStatsReport();

  id_Getter_(mthis) => mthis["id"];

  local_Getter_(mthis) => mthis["local"];

  names_Callback_0_(mthis) => mthis.callMethod("names", []);

  remote_Getter_(mthis) => mthis["remote"];

  stat_Callback_0_(mthis) => mthis.callMethod("stat", []);

  stat_Callback_1_(mthis, __arg_0) => mthis.callMethod("stat", [__arg_0]);

  timestamp_Getter_(mthis) => mthis["timestamp"];

  type_Getter_(mthis) => mthis["type"];

}

class BlinkRTCStatsResponse {
  static final instance = new BlinkRTCStatsResponse();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  namedItem_Callback_0_(mthis) => mthis.callMethod("namedItem", []);

  namedItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("namedItem", [__arg_0]);

  result_Callback_0_(mthis) => mthis.callMethod("result", []);

}

class BlinkRadioNodeList extends BlinkNodeList {
  static final instance = new BlinkRadioNodeList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  value_Getter_(mthis) => mthis["value"];

  value_Setter_(mthis, __arg_0) => mthis["value"] = __arg_0;

}

class BlinkRange {
  static final instance = new BlinkRange();

  cloneContents_Callback_0_(mthis) => mthis.callMethod("cloneContents", []);

  cloneRange_Callback_0_(mthis) => mthis.callMethod("cloneRange", []);

  collapse_Callback_0_(mthis) => mthis.callMethod("collapse", []);

  collapse_Callback_1_(mthis, __arg_0) => mthis.callMethod("collapse", [__arg_0]);

  collapsed_Getter_(mthis) => mthis["collapsed"];

  commonAncestorContainer_Getter_(mthis) => mthis["commonAncestorContainer"];

  compareBoundaryPoints_Callback_0_(mthis) => mthis.callMethod("compareBoundaryPoints", []);

  compareBoundaryPoints_Callback_1_(mthis, __arg_0) => mthis.callMethod("compareBoundaryPoints", [__arg_0]);

  compareBoundaryPoints_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("compareBoundaryPoints", [__arg_0, __arg_1]);

  compareNode_Callback_0_(mthis) => mthis.callMethod("compareNode", []);

  compareNode_Callback_1_(mthis, __arg_0) => mthis.callMethod("compareNode", [__arg_0]);

  comparePoint_Callback_0_(mthis) => mthis.callMethod("comparePoint", []);

  comparePoint_Callback_1_(mthis, __arg_0) => mthis.callMethod("comparePoint", [__arg_0]);

  comparePoint_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("comparePoint", [__arg_0, __arg_1]);

  constructorCallback_0_() => new js.JsObject(js.context["Range"], []);

  createContextualFragment_Callback_0_(mthis) => mthis.callMethod("createContextualFragment", []);

  createContextualFragment_Callback_1_(mthis, __arg_0) => mthis.callMethod("createContextualFragment", [__arg_0]);

  deleteContents_Callback_0_(mthis) => mthis.callMethod("deleteContents", []);

  detach_Callback_0_(mthis) => mthis.callMethod("detach", []);

  endContainer_Getter_(mthis) => mthis["endContainer"];

  endOffset_Getter_(mthis) => mthis["endOffset"];

  expand_Callback_0_(mthis) => mthis.callMethod("expand", []);

  expand_Callback_1_(mthis, __arg_0) => mthis.callMethod("expand", [__arg_0]);

  extractContents_Callback_0_(mthis) => mthis.callMethod("extractContents", []);

  getBoundingClientRect_Callback_0_(mthis) => mthis.callMethod("getBoundingClientRect", []);

  getClientRects_Callback_0_(mthis) => mthis.callMethod("getClientRects", []);

  insertNode_Callback_0_(mthis) => mthis.callMethod("insertNode", []);

  insertNode_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertNode", [__arg_0]);

  intersectsNode_Callback_0_(mthis) => mthis.callMethod("intersectsNode", []);

  intersectsNode_Callback_1_(mthis, __arg_0) => mthis.callMethod("intersectsNode", [__arg_0]);

  isPointInRange_Callback_0_(mthis) => mthis.callMethod("isPointInRange", []);

  isPointInRange_Callback_1_(mthis, __arg_0) => mthis.callMethod("isPointInRange", [__arg_0]);

  isPointInRange_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("isPointInRange", [__arg_0, __arg_1]);

  selectNodeContents_Callback_0_(mthis) => mthis.callMethod("selectNodeContents", []);

  selectNodeContents_Callback_1_(mthis, __arg_0) => mthis.callMethod("selectNodeContents", [__arg_0]);

  selectNode_Callback_0_(mthis) => mthis.callMethod("selectNode", []);

  selectNode_Callback_1_(mthis, __arg_0) => mthis.callMethod("selectNode", [__arg_0]);

  setEndAfter_Callback_0_(mthis) => mthis.callMethod("setEndAfter", []);

  setEndAfter_Callback_1_(mthis, __arg_0) => mthis.callMethod("setEndAfter", [__arg_0]);

  setEndBefore_Callback_0_(mthis) => mthis.callMethod("setEndBefore", []);

  setEndBefore_Callback_1_(mthis, __arg_0) => mthis.callMethod("setEndBefore", [__arg_0]);

  setEnd_Callback_0_(mthis) => mthis.callMethod("setEnd", []);

  setEnd_Callback_1_(mthis, __arg_0) => mthis.callMethod("setEnd", [__arg_0]);

  setEnd_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setEnd", [__arg_0, __arg_1]);

  setStartAfter_Callback_0_(mthis) => mthis.callMethod("setStartAfter", []);

  setStartAfter_Callback_1_(mthis, __arg_0) => mthis.callMethod("setStartAfter", [__arg_0]);

  setStartBefore_Callback_0_(mthis) => mthis.callMethod("setStartBefore", []);

  setStartBefore_Callback_1_(mthis, __arg_0) => mthis.callMethod("setStartBefore", [__arg_0]);

  setStart_Callback_0_(mthis) => mthis.callMethod("setStart", []);

  setStart_Callback_1_(mthis, __arg_0) => mthis.callMethod("setStart", [__arg_0]);

  setStart_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setStart", [__arg_0, __arg_1]);

  startContainer_Getter_(mthis) => mthis["startContainer"];

  startOffset_Getter_(mthis) => mthis["startOffset"];

  surroundContents_Callback_0_(mthis) => mthis.callMethod("surroundContents", []);

  surroundContents_Callback_1_(mthis, __arg_0) => mthis.callMethod("surroundContents", [__arg_0]);

}

class BlinkReadableStream {
  static final instance = new BlinkReadableStream();

  cancel_Callback_0_(mthis) => mthis.callMethod("cancel", []);

  cancel_Callback_1_(mthis, __arg_0) => mthis.callMethod("cancel", [__arg_0]);

  closed_Getter_(mthis) => mthis["closed"];

  read_Callback_0_(mthis) => mthis.callMethod("read", []);

  state_Getter_(mthis) => mthis["state"];

  wait_Callback_0_(mthis) => mthis.callMethod("wait", []);

}

class BlinkRect {
  static final instance = new BlinkRect();

  bottom_Getter_(mthis) => mthis["bottom"];

  left_Getter_(mthis) => mthis["left"];

  right_Getter_(mthis) => mthis["right"];

  top_Getter_(mthis) => mthis["top"];

}

class BlinkRelatedEvent extends BlinkEvent {
  static final instance = new BlinkRelatedEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["RelatedEvent"], [__arg_0, __arg_1]);

  relatedTarget_Getter_(mthis) => mthis["relatedTarget"];

}

class BlinkRequest {
  static final instance = new BlinkRequest();

  arrayBuffer_Callback_0_(mthis) => mthis.callMethod("arrayBuffer", []);

  blob_Callback_0_(mthis) => mthis.callMethod("blob", []);

  bodyUsed_Getter_(mthis) => mthis["bodyUsed"];

  clone_Callback_0_(mthis) => mthis.callMethod("clone", []);

  constructorCallback_0_() => new js.JsObject(js.context["Request"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["Request"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["Request"], [__arg_0, __arg_1]);

  credentials_Getter_(mthis) => mthis["credentials"];

  headers_Getter_(mthis) => mthis["headers"];

  json_Callback_0_(mthis) => mthis.callMethod("json", []);

  method_Getter_(mthis) => mthis["method"];

  mode_Getter_(mthis) => mthis["mode"];

  referrer_Getter_(mthis) => mthis["referrer"];

  text_Callback_0_(mthis) => mthis.callMethod("text", []);

  url_Getter_(mthis) => mthis["url"];

}

class BlinkResourceProgressEvent extends BlinkProgressEvent {
  static final instance = new BlinkResourceProgressEvent();

  url_Getter_(mthis) => mthis["url"];

}

class BlinkResponse {
  static final instance = new BlinkResponse();

  arrayBuffer_Callback_0_(mthis) => mthis.callMethod("arrayBuffer", []);

  blob_Callback_0_(mthis) => mthis.callMethod("blob", []);

  bodyUsed_Getter_(mthis) => mthis["bodyUsed"];

  clone_Callback_0_(mthis) => mthis.callMethod("clone", []);

  constructorCallback_0_() => new js.JsObject(js.context["Response"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["Response"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["Response"], [__arg_0, __arg_1]);

  headers_Getter_(mthis) => mthis["headers"];

  json_Callback_0_(mthis) => mthis.callMethod("json", []);

  statusText_Getter_(mthis) => mthis["statusText"];

  status_Getter_(mthis) => mthis["status"];

  text_Callback_0_(mthis) => mthis.callMethod("text", []);

  type_Getter_(mthis) => mthis["type"];

  url_Getter_(mthis) => mthis["url"];

}

class BlinkSQLError {
  static final instance = new BlinkSQLError();

  code_Getter_(mthis) => mthis["code"];

  message_Getter_(mthis) => mthis["message"];

}

class BlinkSQLResultSet {
  static final instance = new BlinkSQLResultSet();

  insertId_Getter_(mthis) => mthis["insertId"];

  rowsAffected_Getter_(mthis) => mthis["rowsAffected"];

  rows_Getter_(mthis) => mthis["rows"];

}

class BlinkSQLResultSetRowList {
  static final instance = new BlinkSQLResultSetRowList();

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

}

class BlinkSQLTransaction {
  static final instance = new BlinkSQLTransaction();

  executeSql_Callback_0_(mthis) => mthis.callMethod("executeSql", []);

  executeSql_Callback_1_(mthis, __arg_0) => mthis.callMethod("executeSql", [__arg_0]);

  executeSql_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("executeSql", [__arg_0, __arg_1]);

  executeSql_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("executeSql", [__arg_0, __arg_1, __arg_2]);

  executeSql_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("executeSql", [__arg_0, __arg_1, __arg_2, __arg_3]);

}

class BlinkSVGAElement extends BlinkSVGGraphicsElement {
  static final instance = new BlinkSVGAElement();

  href_Getter_(mthis) => mthis["href"];

  target_Getter_(mthis) => mthis["target"];

}

class BlinkSVGAltGlyphDefElement extends BlinkSVGElement {
  static final instance = new BlinkSVGAltGlyphDefElement();

}

class BlinkSVGAltGlyphElement extends BlinkSVGTextPositioningElement {
  static final instance = new BlinkSVGAltGlyphElement();

  format_Getter_(mthis) => mthis["format"];

  format_Setter_(mthis, __arg_0) => mthis["format"] = __arg_0;

  glyphRef_Getter_(mthis) => mthis["glyphRef"];

  glyphRef_Setter_(mthis, __arg_0) => mthis["glyphRef"] = __arg_0;

  href_Getter_(mthis) => mthis["href"];

}

class BlinkSVGAltGlyphItemElement extends BlinkSVGElement {
  static final instance = new BlinkSVGAltGlyphItemElement();

}

class BlinkSVGAngle {
  static final instance = new BlinkSVGAngle();

  convertToSpecifiedUnits_Callback_0_(mthis) => mthis.callMethod("convertToSpecifiedUnits", []);

  convertToSpecifiedUnits_Callback_1_(mthis, __arg_0) => mthis.callMethod("convertToSpecifiedUnits", [__arg_0]);

  newValueSpecifiedUnits_Callback_0_(mthis) => mthis.callMethod("newValueSpecifiedUnits", []);

  newValueSpecifiedUnits_Callback_1_(mthis, __arg_0) => mthis.callMethod("newValueSpecifiedUnits", [__arg_0]);

  newValueSpecifiedUnits_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("newValueSpecifiedUnits", [__arg_0, __arg_1]);

  unitType_Getter_(mthis) => mthis["unitType"];

  valueAsString_Getter_(mthis) => mthis["valueAsString"];

  valueAsString_Setter_(mthis, __arg_0) => mthis["valueAsString"] = __arg_0;

  valueInSpecifiedUnits_Getter_(mthis) => mthis["valueInSpecifiedUnits"];

  valueInSpecifiedUnits_Setter_(mthis, __arg_0) => mthis["valueInSpecifiedUnits"] = __arg_0;

  value_Getter_(mthis) => mthis["value"];

  value_Setter_(mthis, __arg_0) => mthis["value"] = __arg_0;

}

class BlinkSVGAnimateElement extends BlinkSVGAnimationElement {
  static final instance = new BlinkSVGAnimateElement();

}

class BlinkSVGAnimateMotionElement extends BlinkSVGAnimationElement {
  static final instance = new BlinkSVGAnimateMotionElement();

}

class BlinkSVGAnimateTransformElement extends BlinkSVGAnimationElement {
  static final instance = new BlinkSVGAnimateTransformElement();

}

class BlinkSVGAnimatedAngle {
  static final instance = new BlinkSVGAnimatedAngle();

  animVal_Getter_(mthis) => mthis["animVal"];

  baseVal_Getter_(mthis) => mthis["baseVal"];

}

class BlinkSVGAnimatedBoolean {
  static final instance = new BlinkSVGAnimatedBoolean();

  animVal_Getter_(mthis) => mthis["animVal"];

  baseVal_Getter_(mthis) => mthis["baseVal"];

  baseVal_Setter_(mthis, __arg_0) => mthis["baseVal"] = __arg_0;

}

class BlinkSVGAnimatedEnumeration {
  static final instance = new BlinkSVGAnimatedEnumeration();

  animVal_Getter_(mthis) => mthis["animVal"];

  baseVal_Getter_(mthis) => mthis["baseVal"];

  baseVal_Setter_(mthis, __arg_0) => mthis["baseVal"] = __arg_0;

}

class BlinkSVGAnimatedInteger {
  static final instance = new BlinkSVGAnimatedInteger();

  animVal_Getter_(mthis) => mthis["animVal"];

  baseVal_Getter_(mthis) => mthis["baseVal"];

  baseVal_Setter_(mthis, __arg_0) => mthis["baseVal"] = __arg_0;

}

class BlinkSVGAnimatedLength {
  static final instance = new BlinkSVGAnimatedLength();

  animVal_Getter_(mthis) => mthis["animVal"];

  baseVal_Getter_(mthis) => mthis["baseVal"];

}

class BlinkSVGAnimatedLengthList {
  static final instance = new BlinkSVGAnimatedLengthList();

  animVal_Getter_(mthis) => mthis["animVal"];

  baseVal_Getter_(mthis) => mthis["baseVal"];

}

class BlinkSVGAnimatedNumber {
  static final instance = new BlinkSVGAnimatedNumber();

  animVal_Getter_(mthis) => mthis["animVal"];

  baseVal_Getter_(mthis) => mthis["baseVal"];

  baseVal_Setter_(mthis, __arg_0) => mthis["baseVal"] = __arg_0;

}

class BlinkSVGAnimatedNumberList {
  static final instance = new BlinkSVGAnimatedNumberList();

  animVal_Getter_(mthis) => mthis["animVal"];

  baseVal_Getter_(mthis) => mthis["baseVal"];

}

class BlinkSVGAnimatedPreserveAspectRatio {
  static final instance = new BlinkSVGAnimatedPreserveAspectRatio();

  animVal_Getter_(mthis) => mthis["animVal"];

  baseVal_Getter_(mthis) => mthis["baseVal"];

}

class BlinkSVGAnimatedRect {
  static final instance = new BlinkSVGAnimatedRect();

  animVal_Getter_(mthis) => mthis["animVal"];

  baseVal_Getter_(mthis) => mthis["baseVal"];

}

class BlinkSVGAnimatedString {
  static final instance = new BlinkSVGAnimatedString();

  animVal_Getter_(mthis) => mthis["animVal"];

  baseVal_Getter_(mthis) => mthis["baseVal"];

  baseVal_Setter_(mthis, __arg_0) => mthis["baseVal"] = __arg_0;

}

class BlinkSVGAnimatedTransformList {
  static final instance = new BlinkSVGAnimatedTransformList();

  animVal_Getter_(mthis) => mthis["animVal"];

  baseVal_Getter_(mthis) => mthis["baseVal"];

}

class BlinkSVGAnimationElement extends BlinkSVGElement {
  static final instance = new BlinkSVGAnimationElement();

  beginElementAt_Callback_0_(mthis) => mthis.callMethod("beginElementAt", []);

  beginElementAt_Callback_1_(mthis, __arg_0) => mthis.callMethod("beginElementAt", [__arg_0]);

  beginElement_Callback_0_(mthis) => mthis.callMethod("beginElement", []);

  endElementAt_Callback_0_(mthis) => mthis.callMethod("endElementAt", []);

  endElementAt_Callback_1_(mthis, __arg_0) => mthis.callMethod("endElementAt", [__arg_0]);

  endElement_Callback_0_(mthis) => mthis.callMethod("endElement", []);

  getCurrentTime_Callback_0_(mthis) => mthis.callMethod("getCurrentTime", []);

  getSimpleDuration_Callback_0_(mthis) => mthis.callMethod("getSimpleDuration", []);

  getStartTime_Callback_0_(mthis) => mthis.callMethod("getStartTime", []);

  hasExtension_Callback_0_(mthis) => mthis.callMethod("hasExtension", []);

  hasExtension_Callback_1_(mthis, __arg_0) => mthis.callMethod("hasExtension", [__arg_0]);

  onbegin_Getter_(mthis) => mthis["onbegin"];

  onbegin_Setter_(mthis, __arg_0) => mthis["onbegin"] = __arg_0;

  onend_Getter_(mthis) => mthis["onend"];

  onend_Setter_(mthis, __arg_0) => mthis["onend"] = __arg_0;

  onrepeat_Getter_(mthis) => mthis["onrepeat"];

  onrepeat_Setter_(mthis, __arg_0) => mthis["onrepeat"] = __arg_0;

  requiredExtensions_Getter_(mthis) => mthis["requiredExtensions"];

  requiredFeatures_Getter_(mthis) => mthis["requiredFeatures"];

  systemLanguage_Getter_(mthis) => mthis["systemLanguage"];

  targetElement_Getter_(mthis) => mthis["targetElement"];

}

class BlinkSVGCircleElement extends BlinkSVGGeometryElement {
  static final instance = new BlinkSVGCircleElement();

  cx_Getter_(mthis) => mthis["cx"];

  cy_Getter_(mthis) => mthis["cy"];

  r_Getter_(mthis) => mthis["r"];

}

class BlinkSVGClipPathElement extends BlinkSVGGraphicsElement {
  static final instance = new BlinkSVGClipPathElement();

  clipPathUnits_Getter_(mthis) => mthis["clipPathUnits"];

}

class BlinkSVGComponentTransferFunctionElement extends BlinkSVGElement {
  static final instance = new BlinkSVGComponentTransferFunctionElement();

  amplitude_Getter_(mthis) => mthis["amplitude"];

  exponent_Getter_(mthis) => mthis["exponent"];

  intercept_Getter_(mthis) => mthis["intercept"];

  offset_Getter_(mthis) => mthis["offset"];

  slope_Getter_(mthis) => mthis["slope"];

  tableValues_Getter_(mthis) => mthis["tableValues"];

  type_Getter_(mthis) => mthis["type"];

}

class BlinkSVGCursorElement extends BlinkSVGElement {
  static final instance = new BlinkSVGCursorElement();

  hasExtension_Callback_0_(mthis) => mthis.callMethod("hasExtension", []);

  hasExtension_Callback_1_(mthis, __arg_0) => mthis.callMethod("hasExtension", [__arg_0]);

  href_Getter_(mthis) => mthis["href"];

  requiredExtensions_Getter_(mthis) => mthis["requiredExtensions"];

  requiredFeatures_Getter_(mthis) => mthis["requiredFeatures"];

  systemLanguage_Getter_(mthis) => mthis["systemLanguage"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGDefsElement extends BlinkSVGGraphicsElement {
  static final instance = new BlinkSVGDefsElement();

}

class BlinkSVGDescElement extends BlinkSVGElement {
  static final instance = new BlinkSVGDescElement();

}

class BlinkSVGDiscardElement extends BlinkSVGElement {
  static final instance = new BlinkSVGDiscardElement();

}

class BlinkSVGElement extends BlinkElement {
  static final instance = new BlinkSVGElement();

  className_Getter_(mthis) => mthis["className"];

  onabort_Getter_(mthis) => mthis["onabort"];

  onabort_Setter_(mthis, __arg_0) => mthis["onabort"] = __arg_0;

  onautocomplete_Getter_(mthis) => mthis["onautocomplete"];

  onautocomplete_Setter_(mthis, __arg_0) => mthis["onautocomplete"] = __arg_0;

  onautocompleteerror_Getter_(mthis) => mthis["onautocompleteerror"];

  onautocompleteerror_Setter_(mthis, __arg_0) => mthis["onautocompleteerror"] = __arg_0;

  onblur_Getter_(mthis) => mthis["onblur"];

  onblur_Setter_(mthis, __arg_0) => mthis["onblur"] = __arg_0;

  oncancel_Getter_(mthis) => mthis["oncancel"];

  oncancel_Setter_(mthis, __arg_0) => mthis["oncancel"] = __arg_0;

  oncanplay_Getter_(mthis) => mthis["oncanplay"];

  oncanplay_Setter_(mthis, __arg_0) => mthis["oncanplay"] = __arg_0;

  oncanplaythrough_Getter_(mthis) => mthis["oncanplaythrough"];

  oncanplaythrough_Setter_(mthis, __arg_0) => mthis["oncanplaythrough"] = __arg_0;

  onchange_Getter_(mthis) => mthis["onchange"];

  onchange_Setter_(mthis, __arg_0) => mthis["onchange"] = __arg_0;

  onclick_Getter_(mthis) => mthis["onclick"];

  onclick_Setter_(mthis, __arg_0) => mthis["onclick"] = __arg_0;

  onclose_Getter_(mthis) => mthis["onclose"];

  onclose_Setter_(mthis, __arg_0) => mthis["onclose"] = __arg_0;

  oncontextmenu_Getter_(mthis) => mthis["oncontextmenu"];

  oncontextmenu_Setter_(mthis, __arg_0) => mthis["oncontextmenu"] = __arg_0;

  oncuechange_Getter_(mthis) => mthis["oncuechange"];

  oncuechange_Setter_(mthis, __arg_0) => mthis["oncuechange"] = __arg_0;

  ondblclick_Getter_(mthis) => mthis["ondblclick"];

  ondblclick_Setter_(mthis, __arg_0) => mthis["ondblclick"] = __arg_0;

  ondrag_Getter_(mthis) => mthis["ondrag"];

  ondrag_Setter_(mthis, __arg_0) => mthis["ondrag"] = __arg_0;

  ondragend_Getter_(mthis) => mthis["ondragend"];

  ondragend_Setter_(mthis, __arg_0) => mthis["ondragend"] = __arg_0;

  ondragenter_Getter_(mthis) => mthis["ondragenter"];

  ondragenter_Setter_(mthis, __arg_0) => mthis["ondragenter"] = __arg_0;

  ondragleave_Getter_(mthis) => mthis["ondragleave"];

  ondragleave_Setter_(mthis, __arg_0) => mthis["ondragleave"] = __arg_0;

  ondragover_Getter_(mthis) => mthis["ondragover"];

  ondragover_Setter_(mthis, __arg_0) => mthis["ondragover"] = __arg_0;

  ondragstart_Getter_(mthis) => mthis["ondragstart"];

  ondragstart_Setter_(mthis, __arg_0) => mthis["ondragstart"] = __arg_0;

  ondrop_Getter_(mthis) => mthis["ondrop"];

  ondrop_Setter_(mthis, __arg_0) => mthis["ondrop"] = __arg_0;

  ondurationchange_Getter_(mthis) => mthis["ondurationchange"];

  ondurationchange_Setter_(mthis, __arg_0) => mthis["ondurationchange"] = __arg_0;

  onemptied_Getter_(mthis) => mthis["onemptied"];

  onemptied_Setter_(mthis, __arg_0) => mthis["onemptied"] = __arg_0;

  onended_Getter_(mthis) => mthis["onended"];

  onended_Setter_(mthis, __arg_0) => mthis["onended"] = __arg_0;

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onfocus_Getter_(mthis) => mthis["onfocus"];

  onfocus_Setter_(mthis, __arg_0) => mthis["onfocus"] = __arg_0;

  oninput_Getter_(mthis) => mthis["oninput"];

  oninput_Setter_(mthis, __arg_0) => mthis["oninput"] = __arg_0;

  oninvalid_Getter_(mthis) => mthis["oninvalid"];

  oninvalid_Setter_(mthis, __arg_0) => mthis["oninvalid"] = __arg_0;

  onkeydown_Getter_(mthis) => mthis["onkeydown"];

  onkeydown_Setter_(mthis, __arg_0) => mthis["onkeydown"] = __arg_0;

  onkeypress_Getter_(mthis) => mthis["onkeypress"];

  onkeypress_Setter_(mthis, __arg_0) => mthis["onkeypress"] = __arg_0;

  onkeyup_Getter_(mthis) => mthis["onkeyup"];

  onkeyup_Setter_(mthis, __arg_0) => mthis["onkeyup"] = __arg_0;

  onload_Getter_(mthis) => mthis["onload"];

  onload_Setter_(mthis, __arg_0) => mthis["onload"] = __arg_0;

  onloadeddata_Getter_(mthis) => mthis["onloadeddata"];

  onloadeddata_Setter_(mthis, __arg_0) => mthis["onloadeddata"] = __arg_0;

  onloadedmetadata_Getter_(mthis) => mthis["onloadedmetadata"];

  onloadedmetadata_Setter_(mthis, __arg_0) => mthis["onloadedmetadata"] = __arg_0;

  onloadstart_Getter_(mthis) => mthis["onloadstart"];

  onloadstart_Setter_(mthis, __arg_0) => mthis["onloadstart"] = __arg_0;

  onmousedown_Getter_(mthis) => mthis["onmousedown"];

  onmousedown_Setter_(mthis, __arg_0) => mthis["onmousedown"] = __arg_0;

  onmouseenter_Getter_(mthis) => mthis["onmouseenter"];

  onmouseenter_Setter_(mthis, __arg_0) => mthis["onmouseenter"] = __arg_0;

  onmouseleave_Getter_(mthis) => mthis["onmouseleave"];

  onmouseleave_Setter_(mthis, __arg_0) => mthis["onmouseleave"] = __arg_0;

  onmousemove_Getter_(mthis) => mthis["onmousemove"];

  onmousemove_Setter_(mthis, __arg_0) => mthis["onmousemove"] = __arg_0;

  onmouseout_Getter_(mthis) => mthis["onmouseout"];

  onmouseout_Setter_(mthis, __arg_0) => mthis["onmouseout"] = __arg_0;

  onmouseover_Getter_(mthis) => mthis["onmouseover"];

  onmouseover_Setter_(mthis, __arg_0) => mthis["onmouseover"] = __arg_0;

  onmouseup_Getter_(mthis) => mthis["onmouseup"];

  onmouseup_Setter_(mthis, __arg_0) => mthis["onmouseup"] = __arg_0;

  onmousewheel_Getter_(mthis) => mthis["onmousewheel"];

  onmousewheel_Setter_(mthis, __arg_0) => mthis["onmousewheel"] = __arg_0;

  onpause_Getter_(mthis) => mthis["onpause"];

  onpause_Setter_(mthis, __arg_0) => mthis["onpause"] = __arg_0;

  onplay_Getter_(mthis) => mthis["onplay"];

  onplay_Setter_(mthis, __arg_0) => mthis["onplay"] = __arg_0;

  onplaying_Getter_(mthis) => mthis["onplaying"];

  onplaying_Setter_(mthis, __arg_0) => mthis["onplaying"] = __arg_0;

  onprogress_Getter_(mthis) => mthis["onprogress"];

  onprogress_Setter_(mthis, __arg_0) => mthis["onprogress"] = __arg_0;

  onratechange_Getter_(mthis) => mthis["onratechange"];

  onratechange_Setter_(mthis, __arg_0) => mthis["onratechange"] = __arg_0;

  onreset_Getter_(mthis) => mthis["onreset"];

  onreset_Setter_(mthis, __arg_0) => mthis["onreset"] = __arg_0;

  onresize_Getter_(mthis) => mthis["onresize"];

  onresize_Setter_(mthis, __arg_0) => mthis["onresize"] = __arg_0;

  onscroll_Getter_(mthis) => mthis["onscroll"];

  onscroll_Setter_(mthis, __arg_0) => mthis["onscroll"] = __arg_0;

  onseeked_Getter_(mthis) => mthis["onseeked"];

  onseeked_Setter_(mthis, __arg_0) => mthis["onseeked"] = __arg_0;

  onseeking_Getter_(mthis) => mthis["onseeking"];

  onseeking_Setter_(mthis, __arg_0) => mthis["onseeking"] = __arg_0;

  onselect_Getter_(mthis) => mthis["onselect"];

  onselect_Setter_(mthis, __arg_0) => mthis["onselect"] = __arg_0;

  onshow_Getter_(mthis) => mthis["onshow"];

  onshow_Setter_(mthis, __arg_0) => mthis["onshow"] = __arg_0;

  onstalled_Getter_(mthis) => mthis["onstalled"];

  onstalled_Setter_(mthis, __arg_0) => mthis["onstalled"] = __arg_0;

  onsubmit_Getter_(mthis) => mthis["onsubmit"];

  onsubmit_Setter_(mthis, __arg_0) => mthis["onsubmit"] = __arg_0;

  onsuspend_Getter_(mthis) => mthis["onsuspend"];

  onsuspend_Setter_(mthis, __arg_0) => mthis["onsuspend"] = __arg_0;

  ontimeupdate_Getter_(mthis) => mthis["ontimeupdate"];

  ontimeupdate_Setter_(mthis, __arg_0) => mthis["ontimeupdate"] = __arg_0;

  ontoggle_Getter_(mthis) => mthis["ontoggle"];

  ontoggle_Setter_(mthis, __arg_0) => mthis["ontoggle"] = __arg_0;

  onvolumechange_Getter_(mthis) => mthis["onvolumechange"];

  onvolumechange_Setter_(mthis, __arg_0) => mthis["onvolumechange"] = __arg_0;

  onwaiting_Getter_(mthis) => mthis["onwaiting"];

  onwaiting_Setter_(mthis, __arg_0) => mthis["onwaiting"] = __arg_0;

  ownerSVGElement_Getter_(mthis) => mthis["ownerSVGElement"];

  style_Getter_(mthis) => mthis["style"];

  tabIndex_Getter_(mthis) => mthis["tabIndex"];

  tabIndex_Setter_(mthis, __arg_0) => mthis["tabIndex"] = __arg_0;

  viewportElement_Getter_(mthis) => mthis["viewportElement"];

  xmlbase_Getter_(mthis) => mthis["xmlbase"];

  xmlbase_Setter_(mthis, __arg_0) => mthis["xmlbase"] = __arg_0;

  xmllang_Getter_(mthis) => mthis["xmllang"];

  xmllang_Setter_(mthis, __arg_0) => mthis["xmllang"] = __arg_0;

  xmlspace_Getter_(mthis) => mthis["xmlspace"];

  xmlspace_Setter_(mthis, __arg_0) => mthis["xmlspace"] = __arg_0;

}

class BlinkSVGEllipseElement extends BlinkSVGGeometryElement {
  static final instance = new BlinkSVGEllipseElement();

  cx_Getter_(mthis) => mthis["cx"];

  cy_Getter_(mthis) => mthis["cy"];

  rx_Getter_(mthis) => mthis["rx"];

  ry_Getter_(mthis) => mthis["ry"];

}

class BlinkSVGFEBlendElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFEBlendElement();

  height_Getter_(mthis) => mthis["height"];

  in1_Getter_(mthis) => mthis["in1"];

  in2_Getter_(mthis) => mthis["in2"];

  mode_Getter_(mthis) => mthis["mode"];

  result_Getter_(mthis) => mthis["result"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGFEColorMatrixElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFEColorMatrixElement();

  height_Getter_(mthis) => mthis["height"];

  in1_Getter_(mthis) => mthis["in1"];

  result_Getter_(mthis) => mthis["result"];

  type_Getter_(mthis) => mthis["type"];

  values_Getter_(mthis) => mthis["values"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGFEComponentTransferElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFEComponentTransferElement();

  height_Getter_(mthis) => mthis["height"];

  in1_Getter_(mthis) => mthis["in1"];

  result_Getter_(mthis) => mthis["result"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGFECompositeElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFECompositeElement();

  height_Getter_(mthis) => mthis["height"];

  in1_Getter_(mthis) => mthis["in1"];

  in2_Getter_(mthis) => mthis["in2"];

  k1_Getter_(mthis) => mthis["k1"];

  k2_Getter_(mthis) => mthis["k2"];

  k3_Getter_(mthis) => mthis["k3"];

  k4_Getter_(mthis) => mthis["k4"];

  operator_Getter_(mthis) => mthis["operator"];

  result_Getter_(mthis) => mthis["result"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGFEConvolveMatrixElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFEConvolveMatrixElement();

  bias_Getter_(mthis) => mthis["bias"];

  divisor_Getter_(mthis) => mthis["divisor"];

  edgeMode_Getter_(mthis) => mthis["edgeMode"];

  height_Getter_(mthis) => mthis["height"];

  in1_Getter_(mthis) => mthis["in1"];

  kernelMatrix_Getter_(mthis) => mthis["kernelMatrix"];

  kernelUnitLengthX_Getter_(mthis) => mthis["kernelUnitLengthX"];

  kernelUnitLengthY_Getter_(mthis) => mthis["kernelUnitLengthY"];

  orderX_Getter_(mthis) => mthis["orderX"];

  orderY_Getter_(mthis) => mthis["orderY"];

  preserveAlpha_Getter_(mthis) => mthis["preserveAlpha"];

  result_Getter_(mthis) => mthis["result"];

  targetX_Getter_(mthis) => mthis["targetX"];

  targetY_Getter_(mthis) => mthis["targetY"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGFEDiffuseLightingElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFEDiffuseLightingElement();

  diffuseConstant_Getter_(mthis) => mthis["diffuseConstant"];

  height_Getter_(mthis) => mthis["height"];

  in1_Getter_(mthis) => mthis["in1"];

  kernelUnitLengthX_Getter_(mthis) => mthis["kernelUnitLengthX"];

  kernelUnitLengthY_Getter_(mthis) => mthis["kernelUnitLengthY"];

  result_Getter_(mthis) => mthis["result"];

  surfaceScale_Getter_(mthis) => mthis["surfaceScale"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGFEDisplacementMapElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFEDisplacementMapElement();

  height_Getter_(mthis) => mthis["height"];

  in1_Getter_(mthis) => mthis["in1"];

  in2_Getter_(mthis) => mthis["in2"];

  result_Getter_(mthis) => mthis["result"];

  scale_Getter_(mthis) => mthis["scale"];

  width_Getter_(mthis) => mthis["width"];

  xChannelSelector_Getter_(mthis) => mthis["xChannelSelector"];

  x_Getter_(mthis) => mthis["x"];

  yChannelSelector_Getter_(mthis) => mthis["yChannelSelector"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGFEDistantLightElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFEDistantLightElement();

  azimuth_Getter_(mthis) => mthis["azimuth"];

  elevation_Getter_(mthis) => mthis["elevation"];

}

class BlinkSVGFEDropShadowElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFEDropShadowElement();

  dx_Getter_(mthis) => mthis["dx"];

  dy_Getter_(mthis) => mthis["dy"];

  height_Getter_(mthis) => mthis["height"];

  in1_Getter_(mthis) => mthis["in1"];

  result_Getter_(mthis) => mthis["result"];

  setStdDeviation_Callback_0_(mthis) => mthis.callMethod("setStdDeviation", []);

  setStdDeviation_Callback_1_(mthis, __arg_0) => mthis.callMethod("setStdDeviation", [__arg_0]);

  setStdDeviation_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setStdDeviation", [__arg_0, __arg_1]);

  stdDeviationX_Getter_(mthis) => mthis["stdDeviationX"];

  stdDeviationY_Getter_(mthis) => mthis["stdDeviationY"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGFEFloodElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFEFloodElement();

  height_Getter_(mthis) => mthis["height"];

  result_Getter_(mthis) => mthis["result"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGFEFuncAElement extends BlinkSVGComponentTransferFunctionElement {
  static final instance = new BlinkSVGFEFuncAElement();

}

class BlinkSVGFEFuncBElement extends BlinkSVGComponentTransferFunctionElement {
  static final instance = new BlinkSVGFEFuncBElement();

}

class BlinkSVGFEFuncGElement extends BlinkSVGComponentTransferFunctionElement {
  static final instance = new BlinkSVGFEFuncGElement();

}

class BlinkSVGFEFuncRElement extends BlinkSVGComponentTransferFunctionElement {
  static final instance = new BlinkSVGFEFuncRElement();

}

class BlinkSVGFEGaussianBlurElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFEGaussianBlurElement();

  height_Getter_(mthis) => mthis["height"];

  in1_Getter_(mthis) => mthis["in1"];

  result_Getter_(mthis) => mthis["result"];

  setStdDeviation_Callback_0_(mthis) => mthis.callMethod("setStdDeviation", []);

  setStdDeviation_Callback_1_(mthis, __arg_0) => mthis.callMethod("setStdDeviation", [__arg_0]);

  setStdDeviation_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setStdDeviation", [__arg_0, __arg_1]);

  stdDeviationX_Getter_(mthis) => mthis["stdDeviationX"];

  stdDeviationY_Getter_(mthis) => mthis["stdDeviationY"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGFEImageElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFEImageElement();

  height_Getter_(mthis) => mthis["height"];

  href_Getter_(mthis) => mthis["href"];

  preserveAspectRatio_Getter_(mthis) => mthis["preserveAspectRatio"];

  result_Getter_(mthis) => mthis["result"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGFEMergeElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFEMergeElement();

  height_Getter_(mthis) => mthis["height"];

  result_Getter_(mthis) => mthis["result"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGFEMergeNodeElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFEMergeNodeElement();

  in1_Getter_(mthis) => mthis["in1"];

}

class BlinkSVGFEMorphologyElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFEMorphologyElement();

  height_Getter_(mthis) => mthis["height"];

  in1_Getter_(mthis) => mthis["in1"];

  operator_Getter_(mthis) => mthis["operator"];

  radiusX_Getter_(mthis) => mthis["radiusX"];

  radiusY_Getter_(mthis) => mthis["radiusY"];

  result_Getter_(mthis) => mthis["result"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGFEOffsetElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFEOffsetElement();

  dx_Getter_(mthis) => mthis["dx"];

  dy_Getter_(mthis) => mthis["dy"];

  height_Getter_(mthis) => mthis["height"];

  in1_Getter_(mthis) => mthis["in1"];

  result_Getter_(mthis) => mthis["result"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGFEPointLightElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFEPointLightElement();

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

  z_Getter_(mthis) => mthis["z"];

}

class BlinkSVGFESpecularLightingElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFESpecularLightingElement();

  height_Getter_(mthis) => mthis["height"];

  in1_Getter_(mthis) => mthis["in1"];

  result_Getter_(mthis) => mthis["result"];

  specularConstant_Getter_(mthis) => mthis["specularConstant"];

  specularExponent_Getter_(mthis) => mthis["specularExponent"];

  surfaceScale_Getter_(mthis) => mthis["surfaceScale"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGFESpotLightElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFESpotLightElement();

  limitingConeAngle_Getter_(mthis) => mthis["limitingConeAngle"];

  pointsAtX_Getter_(mthis) => mthis["pointsAtX"];

  pointsAtY_Getter_(mthis) => mthis["pointsAtY"];

  pointsAtZ_Getter_(mthis) => mthis["pointsAtZ"];

  specularExponent_Getter_(mthis) => mthis["specularExponent"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

  z_Getter_(mthis) => mthis["z"];

}

class BlinkSVGFETileElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFETileElement();

  height_Getter_(mthis) => mthis["height"];

  in1_Getter_(mthis) => mthis["in1"];

  result_Getter_(mthis) => mthis["result"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGFETurbulenceElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFETurbulenceElement();

  baseFrequencyX_Getter_(mthis) => mthis["baseFrequencyX"];

  baseFrequencyY_Getter_(mthis) => mthis["baseFrequencyY"];

  height_Getter_(mthis) => mthis["height"];

  numOctaves_Getter_(mthis) => mthis["numOctaves"];

  result_Getter_(mthis) => mthis["result"];

  seed_Getter_(mthis) => mthis["seed"];

  stitchTiles_Getter_(mthis) => mthis["stitchTiles"];

  type_Getter_(mthis) => mthis["type"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGFilterElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFilterElement();

  filterResX_Getter_(mthis) => mthis["filterResX"];

  filterResY_Getter_(mthis) => mthis["filterResY"];

  filterUnits_Getter_(mthis) => mthis["filterUnits"];

  height_Getter_(mthis) => mthis["height"];

  href_Getter_(mthis) => mthis["href"];

  primitiveUnits_Getter_(mthis) => mthis["primitiveUnits"];

  setFilterRes_Callback_0_(mthis) => mthis.callMethod("setFilterRes", []);

  setFilterRes_Callback_1_(mthis, __arg_0) => mthis.callMethod("setFilterRes", [__arg_0]);

  setFilterRes_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setFilterRes", [__arg_0, __arg_1]);

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGFontElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFontElement();

}

class BlinkSVGFontFaceElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFontFaceElement();

}

class BlinkSVGFontFaceFormatElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFontFaceFormatElement();

}

class BlinkSVGFontFaceNameElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFontFaceNameElement();

}

class BlinkSVGFontFaceSrcElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFontFaceSrcElement();

}

class BlinkSVGFontFaceUriElement extends BlinkSVGElement {
  static final instance = new BlinkSVGFontFaceUriElement();

}

class BlinkSVGForeignObjectElement extends BlinkSVGGraphicsElement {
  static final instance = new BlinkSVGForeignObjectElement();

  height_Getter_(mthis) => mthis["height"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGGElement extends BlinkSVGGraphicsElement {
  static final instance = new BlinkSVGGElement();

}

class BlinkSVGGeometryElement extends BlinkSVGGraphicsElement {
  static final instance = new BlinkSVGGeometryElement();

  isPointInFill_Callback_0_(mthis) => mthis.callMethod("isPointInFill", []);

  isPointInFill_Callback_1_(mthis, __arg_0) => mthis.callMethod("isPointInFill", [__arg_0]);

  isPointInStroke_Callback_0_(mthis) => mthis.callMethod("isPointInStroke", []);

  isPointInStroke_Callback_1_(mthis, __arg_0) => mthis.callMethod("isPointInStroke", [__arg_0]);

}

class BlinkSVGGlyphElement extends BlinkSVGElement {
  static final instance = new BlinkSVGGlyphElement();

}

class BlinkSVGGlyphRefElement extends BlinkSVGElement {
  static final instance = new BlinkSVGGlyphRefElement();

  dx_Getter_(mthis) => mthis["dx"];

  dx_Setter_(mthis, __arg_0) => mthis["dx"] = __arg_0;

  dy_Getter_(mthis) => mthis["dy"];

  dy_Setter_(mthis, __arg_0) => mthis["dy"] = __arg_0;

  format_Getter_(mthis) => mthis["format"];

  format_Setter_(mthis, __arg_0) => mthis["format"] = __arg_0;

  glyphRef_Getter_(mthis) => mthis["glyphRef"];

  glyphRef_Setter_(mthis, __arg_0) => mthis["glyphRef"] = __arg_0;

  href_Getter_(mthis) => mthis["href"];

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGGradientElement extends BlinkSVGElement {
  static final instance = new BlinkSVGGradientElement();

  gradientTransform_Getter_(mthis) => mthis["gradientTransform"];

  gradientUnits_Getter_(mthis) => mthis["gradientUnits"];

  href_Getter_(mthis) => mthis["href"];

  spreadMethod_Getter_(mthis) => mthis["spreadMethod"];

}

class BlinkSVGGraphicsElement extends BlinkSVGElement {
  static final instance = new BlinkSVGGraphicsElement();

  farthestViewportElement_Getter_(mthis) => mthis["farthestViewportElement"];

  getBBox_Callback_0_(mthis) => mthis.callMethod("getBBox", []);

  getCTM_Callback_0_(mthis) => mthis.callMethod("getCTM", []);

  getScreenCTM_Callback_0_(mthis) => mthis.callMethod("getScreenCTM", []);

  getTransformToElement_Callback_0_(mthis) => mthis.callMethod("getTransformToElement", []);

  getTransformToElement_Callback_1_(mthis, __arg_0) => mthis.callMethod("getTransformToElement", [__arg_0]);

  hasExtension_Callback_0_(mthis) => mthis.callMethod("hasExtension", []);

  hasExtension_Callback_1_(mthis, __arg_0) => mthis.callMethod("hasExtension", [__arg_0]);

  nearestViewportElement_Getter_(mthis) => mthis["nearestViewportElement"];

  requiredExtensions_Getter_(mthis) => mthis["requiredExtensions"];

  requiredFeatures_Getter_(mthis) => mthis["requiredFeatures"];

  systemLanguage_Getter_(mthis) => mthis["systemLanguage"];

  transform_Getter_(mthis) => mthis["transform"];

}

class BlinkSVGHKernElement extends BlinkSVGElement {
  static final instance = new BlinkSVGHKernElement();

}

class BlinkSVGImageElement extends BlinkSVGGraphicsElement {
  static final instance = new BlinkSVGImageElement();

  height_Getter_(mthis) => mthis["height"];

  href_Getter_(mthis) => mthis["href"];

  preserveAspectRatio_Getter_(mthis) => mthis["preserveAspectRatio"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGLength {
  static final instance = new BlinkSVGLength();

  convertToSpecifiedUnits_Callback_0_(mthis) => mthis.callMethod("convertToSpecifiedUnits", []);

  convertToSpecifiedUnits_Callback_1_(mthis, __arg_0) => mthis.callMethod("convertToSpecifiedUnits", [__arg_0]);

  newValueSpecifiedUnits_Callback_0_(mthis) => mthis.callMethod("newValueSpecifiedUnits", []);

  newValueSpecifiedUnits_Callback_1_(mthis, __arg_0) => mthis.callMethod("newValueSpecifiedUnits", [__arg_0]);

  newValueSpecifiedUnits_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("newValueSpecifiedUnits", [__arg_0, __arg_1]);

  unitType_Getter_(mthis) => mthis["unitType"];

  valueAsString_Getter_(mthis) => mthis["valueAsString"];

  valueAsString_Setter_(mthis, __arg_0) => mthis["valueAsString"] = __arg_0;

  valueInSpecifiedUnits_Getter_(mthis) => mthis["valueInSpecifiedUnits"];

  valueInSpecifiedUnits_Setter_(mthis, __arg_0) => mthis["valueInSpecifiedUnits"] = __arg_0;

  value_Getter_(mthis) => mthis["value"];

  value_Setter_(mthis, __arg_0) => mthis["value"] = __arg_0;

}

class BlinkSVGLengthList {
  static final instance = new BlinkSVGLengthList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  $__setter___Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("__setter__", [__arg_0, __arg_1]);

  appendItem_Callback_0_(mthis) => mthis.callMethod("appendItem", []);

  appendItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("appendItem", [__arg_0]);

  clear_Callback_0_(mthis) => mthis.callMethod("clear", []);

  getItem_Callback_0_(mthis) => mthis.callMethod("getItem", []);

  getItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("getItem", [__arg_0]);

  initialize_Callback_0_(mthis) => mthis.callMethod("initialize", []);

  initialize_Callback_1_(mthis, __arg_0) => mthis.callMethod("initialize", [__arg_0]);

  insertItemBefore_Callback_0_(mthis) => mthis.callMethod("insertItemBefore", []);

  insertItemBefore_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertItemBefore", [__arg_0]);

  insertItemBefore_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("insertItemBefore", [__arg_0, __arg_1]);

  length_Getter_(mthis) => mthis["length"];

  numberOfItems_Getter_(mthis) => mthis["numberOfItems"];

  removeItem_Callback_0_(mthis) => mthis.callMethod("removeItem", []);

  removeItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeItem", [__arg_0]);

  replaceItem_Callback_0_(mthis) => mthis.callMethod("replaceItem", []);

  replaceItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("replaceItem", [__arg_0]);

  replaceItem_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("replaceItem", [__arg_0, __arg_1]);

}

class BlinkSVGLineElement extends BlinkSVGGeometryElement {
  static final instance = new BlinkSVGLineElement();

  x1_Getter_(mthis) => mthis["x1"];

  x2_Getter_(mthis) => mthis["x2"];

  y1_Getter_(mthis) => mthis["y1"];

  y2_Getter_(mthis) => mthis["y2"];

}

class BlinkSVGLinearGradientElement extends BlinkSVGGradientElement {
  static final instance = new BlinkSVGLinearGradientElement();

  x1_Getter_(mthis) => mthis["x1"];

  x2_Getter_(mthis) => mthis["x2"];

  y1_Getter_(mthis) => mthis["y1"];

  y2_Getter_(mthis) => mthis["y2"];

}

class BlinkSVGMPathElement extends BlinkSVGElement {
  static final instance = new BlinkSVGMPathElement();

  href_Getter_(mthis) => mthis["href"];

}

class BlinkSVGMarkerElement extends BlinkSVGElement {
  static final instance = new BlinkSVGMarkerElement();

  markerHeight_Getter_(mthis) => mthis["markerHeight"];

  markerUnits_Getter_(mthis) => mthis["markerUnits"];

  markerWidth_Getter_(mthis) => mthis["markerWidth"];

  orientAngle_Getter_(mthis) => mthis["orientAngle"];

  orientType_Getter_(mthis) => mthis["orientType"];

  preserveAspectRatio_Getter_(mthis) => mthis["preserveAspectRatio"];

  refX_Getter_(mthis) => mthis["refX"];

  refY_Getter_(mthis) => mthis["refY"];

  setOrientToAngle_Callback_0_(mthis) => mthis.callMethod("setOrientToAngle", []);

  setOrientToAngle_Callback_1_(mthis, __arg_0) => mthis.callMethod("setOrientToAngle", [__arg_0]);

  setOrientToAuto_Callback_0_(mthis) => mthis.callMethod("setOrientToAuto", []);

  viewBox_Getter_(mthis) => mthis["viewBox"];

}

class BlinkSVGMaskElement extends BlinkSVGElement {
  static final instance = new BlinkSVGMaskElement();

  hasExtension_Callback_0_(mthis) => mthis.callMethod("hasExtension", []);

  hasExtension_Callback_1_(mthis, __arg_0) => mthis.callMethod("hasExtension", [__arg_0]);

  height_Getter_(mthis) => mthis["height"];

  maskContentUnits_Getter_(mthis) => mthis["maskContentUnits"];

  maskUnits_Getter_(mthis) => mthis["maskUnits"];

  requiredExtensions_Getter_(mthis) => mthis["requiredExtensions"];

  requiredFeatures_Getter_(mthis) => mthis["requiredFeatures"];

  systemLanguage_Getter_(mthis) => mthis["systemLanguage"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGMatrix {
  static final instance = new BlinkSVGMatrix();

  a_Getter_(mthis) => mthis["a"];

  a_Setter_(mthis, __arg_0) => mthis["a"] = __arg_0;

  b_Getter_(mthis) => mthis["b"];

  b_Setter_(mthis, __arg_0) => mthis["b"] = __arg_0;

  c_Getter_(mthis) => mthis["c"];

  c_Setter_(mthis, __arg_0) => mthis["c"] = __arg_0;

  d_Getter_(mthis) => mthis["d"];

  d_Setter_(mthis, __arg_0) => mthis["d"] = __arg_0;

  e_Getter_(mthis) => mthis["e"];

  e_Setter_(mthis, __arg_0) => mthis["e"] = __arg_0;

  f_Getter_(mthis) => mthis["f"];

  f_Setter_(mthis, __arg_0) => mthis["f"] = __arg_0;

  flipX_Callback_0_(mthis) => mthis.callMethod("flipX", []);

  flipY_Callback_0_(mthis) => mthis.callMethod("flipY", []);

  inverse_Callback_0_(mthis) => mthis.callMethod("inverse", []);

  multiply_Callback_0_(mthis) => mthis.callMethod("multiply", []);

  multiply_Callback_1_(mthis, __arg_0) => mthis.callMethod("multiply", [__arg_0]);

  rotateFromVector_Callback_0_(mthis) => mthis.callMethod("rotateFromVector", []);

  rotateFromVector_Callback_1_(mthis, __arg_0) => mthis.callMethod("rotateFromVector", [__arg_0]);

  rotateFromVector_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("rotateFromVector", [__arg_0, __arg_1]);

  rotate_Callback_0_(mthis) => mthis.callMethod("rotate", []);

  rotate_Callback_1_(mthis, __arg_0) => mthis.callMethod("rotate", [__arg_0]);

  scaleNonUniform_Callback_0_(mthis) => mthis.callMethod("scaleNonUniform", []);

  scaleNonUniform_Callback_1_(mthis, __arg_0) => mthis.callMethod("scaleNonUniform", [__arg_0]);

  scaleNonUniform_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("scaleNonUniform", [__arg_0, __arg_1]);

  scale_Callback_0_(mthis) => mthis.callMethod("scale", []);

  scale_Callback_1_(mthis, __arg_0) => mthis.callMethod("scale", [__arg_0]);

  skewX_Callback_0_(mthis) => mthis.callMethod("skewX", []);

  skewX_Callback_1_(mthis, __arg_0) => mthis.callMethod("skewX", [__arg_0]);

  skewY_Callback_0_(mthis) => mthis.callMethod("skewY", []);

  skewY_Callback_1_(mthis, __arg_0) => mthis.callMethod("skewY", [__arg_0]);

  translate_Callback_0_(mthis) => mthis.callMethod("translate", []);

  translate_Callback_1_(mthis, __arg_0) => mthis.callMethod("translate", [__arg_0]);

  translate_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("translate", [__arg_0, __arg_1]);

}

class BlinkSVGMetadataElement extends BlinkSVGElement {
  static final instance = new BlinkSVGMetadataElement();

}

class BlinkSVGMissingGlyphElement extends BlinkSVGElement {
  static final instance = new BlinkSVGMissingGlyphElement();

}

class BlinkSVGNumber {
  static final instance = new BlinkSVGNumber();

  value_Getter_(mthis) => mthis["value"];

  value_Setter_(mthis, __arg_0) => mthis["value"] = __arg_0;

}

class BlinkSVGNumberList {
  static final instance = new BlinkSVGNumberList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  $__setter___Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("__setter__", [__arg_0, __arg_1]);

  appendItem_Callback_0_(mthis) => mthis.callMethod("appendItem", []);

  appendItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("appendItem", [__arg_0]);

  clear_Callback_0_(mthis) => mthis.callMethod("clear", []);

  getItem_Callback_0_(mthis) => mthis.callMethod("getItem", []);

  getItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("getItem", [__arg_0]);

  initialize_Callback_0_(mthis) => mthis.callMethod("initialize", []);

  initialize_Callback_1_(mthis, __arg_0) => mthis.callMethod("initialize", [__arg_0]);

  insertItemBefore_Callback_0_(mthis) => mthis.callMethod("insertItemBefore", []);

  insertItemBefore_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertItemBefore", [__arg_0]);

  insertItemBefore_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("insertItemBefore", [__arg_0, __arg_1]);

  length_Getter_(mthis) => mthis["length"];

  numberOfItems_Getter_(mthis) => mthis["numberOfItems"];

  removeItem_Callback_0_(mthis) => mthis.callMethod("removeItem", []);

  removeItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeItem", [__arg_0]);

  replaceItem_Callback_0_(mthis) => mthis.callMethod("replaceItem", []);

  replaceItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("replaceItem", [__arg_0]);

  replaceItem_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("replaceItem", [__arg_0, __arg_1]);

}

class BlinkSVGPathElement extends BlinkSVGGeometryElement {
  static final instance = new BlinkSVGPathElement();

  animatedNormalizedPathSegList_Getter_(mthis) => mthis["animatedNormalizedPathSegList"];

  animatedPathSegList_Getter_(mthis) => mthis["animatedPathSegList"];

  createSVGPathSegArcAbs_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("createSVGPathSegArcAbs", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  createSVGPathSegArcAbs_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("createSVGPathSegArcAbs", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  createSVGPathSegArcAbs_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("createSVGPathSegArcAbs", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  createSVGPathSegArcRel_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("createSVGPathSegArcRel", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  createSVGPathSegArcRel_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("createSVGPathSegArcRel", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  createSVGPathSegArcRel_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("createSVGPathSegArcRel", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  createSVGPathSegClosePath_Callback_0_(mthis) => mthis.callMethod("createSVGPathSegClosePath", []);

  createSVGPathSegCurvetoCubicAbs_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("createSVGPathSegCurvetoCubicAbs", [__arg_0, __arg_1, __arg_2, __arg_3]);

  createSVGPathSegCurvetoCubicAbs_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("createSVGPathSegCurvetoCubicAbs", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  createSVGPathSegCurvetoCubicAbs_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("createSVGPathSegCurvetoCubicAbs", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  createSVGPathSegCurvetoCubicRel_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("createSVGPathSegCurvetoCubicRel", [__arg_0, __arg_1, __arg_2, __arg_3]);

  createSVGPathSegCurvetoCubicRel_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("createSVGPathSegCurvetoCubicRel", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  createSVGPathSegCurvetoCubicRel_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("createSVGPathSegCurvetoCubicRel", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  createSVGPathSegCurvetoCubicSmoothAbs_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createSVGPathSegCurvetoCubicSmoothAbs", [__arg_0, __arg_1]);

  createSVGPathSegCurvetoCubicSmoothAbs_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("createSVGPathSegCurvetoCubicSmoothAbs", [__arg_0, __arg_1, __arg_2]);

  createSVGPathSegCurvetoCubicSmoothAbs_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("createSVGPathSegCurvetoCubicSmoothAbs", [__arg_0, __arg_1, __arg_2, __arg_3]);

  createSVGPathSegCurvetoCubicSmoothRel_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createSVGPathSegCurvetoCubicSmoothRel", [__arg_0, __arg_1]);

  createSVGPathSegCurvetoCubicSmoothRel_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("createSVGPathSegCurvetoCubicSmoothRel", [__arg_0, __arg_1, __arg_2]);

  createSVGPathSegCurvetoCubicSmoothRel_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("createSVGPathSegCurvetoCubicSmoothRel", [__arg_0, __arg_1, __arg_2, __arg_3]);

  createSVGPathSegCurvetoQuadraticAbs_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createSVGPathSegCurvetoQuadraticAbs", [__arg_0, __arg_1]);

  createSVGPathSegCurvetoQuadraticAbs_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("createSVGPathSegCurvetoQuadraticAbs", [__arg_0, __arg_1, __arg_2]);

  createSVGPathSegCurvetoQuadraticAbs_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("createSVGPathSegCurvetoQuadraticAbs", [__arg_0, __arg_1, __arg_2, __arg_3]);

  createSVGPathSegCurvetoQuadraticRel_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createSVGPathSegCurvetoQuadraticRel", [__arg_0, __arg_1]);

  createSVGPathSegCurvetoQuadraticRel_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("createSVGPathSegCurvetoQuadraticRel", [__arg_0, __arg_1, __arg_2]);

  createSVGPathSegCurvetoQuadraticRel_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("createSVGPathSegCurvetoQuadraticRel", [__arg_0, __arg_1, __arg_2, __arg_3]);

  createSVGPathSegCurvetoQuadraticSmoothAbs_Callback_0_(mthis) => mthis.callMethod("createSVGPathSegCurvetoQuadraticSmoothAbs", []);

  createSVGPathSegCurvetoQuadraticSmoothAbs_Callback_1_(mthis, __arg_0) => mthis.callMethod("createSVGPathSegCurvetoQuadraticSmoothAbs", [__arg_0]);

  createSVGPathSegCurvetoQuadraticSmoothAbs_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createSVGPathSegCurvetoQuadraticSmoothAbs", [__arg_0, __arg_1]);

  createSVGPathSegCurvetoQuadraticSmoothRel_Callback_0_(mthis) => mthis.callMethod("createSVGPathSegCurvetoQuadraticSmoothRel", []);

  createSVGPathSegCurvetoQuadraticSmoothRel_Callback_1_(mthis, __arg_0) => mthis.callMethod("createSVGPathSegCurvetoQuadraticSmoothRel", [__arg_0]);

  createSVGPathSegCurvetoQuadraticSmoothRel_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createSVGPathSegCurvetoQuadraticSmoothRel", [__arg_0, __arg_1]);

  createSVGPathSegLinetoAbs_Callback_0_(mthis) => mthis.callMethod("createSVGPathSegLinetoAbs", []);

  createSVGPathSegLinetoAbs_Callback_1_(mthis, __arg_0) => mthis.callMethod("createSVGPathSegLinetoAbs", [__arg_0]);

  createSVGPathSegLinetoAbs_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createSVGPathSegLinetoAbs", [__arg_0, __arg_1]);

  createSVGPathSegLinetoHorizontalAbs_Callback_0_(mthis) => mthis.callMethod("createSVGPathSegLinetoHorizontalAbs", []);

  createSVGPathSegLinetoHorizontalAbs_Callback_1_(mthis, __arg_0) => mthis.callMethod("createSVGPathSegLinetoHorizontalAbs", [__arg_0]);

  createSVGPathSegLinetoHorizontalRel_Callback_0_(mthis) => mthis.callMethod("createSVGPathSegLinetoHorizontalRel", []);

  createSVGPathSegLinetoHorizontalRel_Callback_1_(mthis, __arg_0) => mthis.callMethod("createSVGPathSegLinetoHorizontalRel", [__arg_0]);

  createSVGPathSegLinetoRel_Callback_0_(mthis) => mthis.callMethod("createSVGPathSegLinetoRel", []);

  createSVGPathSegLinetoRel_Callback_1_(mthis, __arg_0) => mthis.callMethod("createSVGPathSegLinetoRel", [__arg_0]);

  createSVGPathSegLinetoRel_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createSVGPathSegLinetoRel", [__arg_0, __arg_1]);

  createSVGPathSegLinetoVerticalAbs_Callback_0_(mthis) => mthis.callMethod("createSVGPathSegLinetoVerticalAbs", []);

  createSVGPathSegLinetoVerticalAbs_Callback_1_(mthis, __arg_0) => mthis.callMethod("createSVGPathSegLinetoVerticalAbs", [__arg_0]);

  createSVGPathSegLinetoVerticalRel_Callback_0_(mthis) => mthis.callMethod("createSVGPathSegLinetoVerticalRel", []);

  createSVGPathSegLinetoVerticalRel_Callback_1_(mthis, __arg_0) => mthis.callMethod("createSVGPathSegLinetoVerticalRel", [__arg_0]);

  createSVGPathSegMovetoAbs_Callback_0_(mthis) => mthis.callMethod("createSVGPathSegMovetoAbs", []);

  createSVGPathSegMovetoAbs_Callback_1_(mthis, __arg_0) => mthis.callMethod("createSVGPathSegMovetoAbs", [__arg_0]);

  createSVGPathSegMovetoAbs_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createSVGPathSegMovetoAbs", [__arg_0, __arg_1]);

  createSVGPathSegMovetoRel_Callback_0_(mthis) => mthis.callMethod("createSVGPathSegMovetoRel", []);

  createSVGPathSegMovetoRel_Callback_1_(mthis, __arg_0) => mthis.callMethod("createSVGPathSegMovetoRel", [__arg_0]);

  createSVGPathSegMovetoRel_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createSVGPathSegMovetoRel", [__arg_0, __arg_1]);

  getPathSegAtLength_Callback_0_(mthis) => mthis.callMethod("getPathSegAtLength", []);

  getPathSegAtLength_Callback_1_(mthis, __arg_0) => mthis.callMethod("getPathSegAtLength", [__arg_0]);

  getPointAtLength_Callback_0_(mthis) => mthis.callMethod("getPointAtLength", []);

  getPointAtLength_Callback_1_(mthis, __arg_0) => mthis.callMethod("getPointAtLength", [__arg_0]);

  getTotalLength_Callback_0_(mthis) => mthis.callMethod("getTotalLength", []);

  normalizedPathSegList_Getter_(mthis) => mthis["normalizedPathSegList"];

  pathLength_Getter_(mthis) => mthis["pathLength"];

  pathSegList_Getter_(mthis) => mthis["pathSegList"];

}

class BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSeg();

  pathSegTypeAsLetter_Getter_(mthis) => mthis["pathSegTypeAsLetter"];

  pathSegType_Getter_(mthis) => mthis["pathSegType"];

}

class BlinkSVGPathSegArcAbs extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegArcAbs();

  angle_Getter_(mthis) => mthis["angle"];

  angle_Setter_(mthis, __arg_0) => mthis["angle"] = __arg_0;

  largeArcFlag_Getter_(mthis) => mthis["largeArcFlag"];

  largeArcFlag_Setter_(mthis, __arg_0) => mthis["largeArcFlag"] = __arg_0;

  r1_Getter_(mthis) => mthis["r1"];

  r1_Setter_(mthis, __arg_0) => mthis["r1"] = __arg_0;

  r2_Getter_(mthis) => mthis["r2"];

  r2_Setter_(mthis, __arg_0) => mthis["r2"] = __arg_0;

  sweepFlag_Getter_(mthis) => mthis["sweepFlag"];

  sweepFlag_Setter_(mthis, __arg_0) => mthis["sweepFlag"] = __arg_0;

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGPathSegArcRel extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegArcRel();

  angle_Getter_(mthis) => mthis["angle"];

  angle_Setter_(mthis, __arg_0) => mthis["angle"] = __arg_0;

  largeArcFlag_Getter_(mthis) => mthis["largeArcFlag"];

  largeArcFlag_Setter_(mthis, __arg_0) => mthis["largeArcFlag"] = __arg_0;

  r1_Getter_(mthis) => mthis["r1"];

  r1_Setter_(mthis, __arg_0) => mthis["r1"] = __arg_0;

  r2_Getter_(mthis) => mthis["r2"];

  r2_Setter_(mthis, __arg_0) => mthis["r2"] = __arg_0;

  sweepFlag_Getter_(mthis) => mthis["sweepFlag"];

  sweepFlag_Setter_(mthis, __arg_0) => mthis["sweepFlag"] = __arg_0;

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGPathSegClosePath extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegClosePath();

}

class BlinkSVGPathSegCurvetoCubicAbs extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegCurvetoCubicAbs();

  x1_Getter_(mthis) => mthis["x1"];

  x1_Setter_(mthis, __arg_0) => mthis["x1"] = __arg_0;

  x2_Getter_(mthis) => mthis["x2"];

  x2_Setter_(mthis, __arg_0) => mthis["x2"] = __arg_0;

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y1_Getter_(mthis) => mthis["y1"];

  y1_Setter_(mthis, __arg_0) => mthis["y1"] = __arg_0;

  y2_Getter_(mthis) => mthis["y2"];

  y2_Setter_(mthis, __arg_0) => mthis["y2"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGPathSegCurvetoCubicRel extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegCurvetoCubicRel();

  x1_Getter_(mthis) => mthis["x1"];

  x1_Setter_(mthis, __arg_0) => mthis["x1"] = __arg_0;

  x2_Getter_(mthis) => mthis["x2"];

  x2_Setter_(mthis, __arg_0) => mthis["x2"] = __arg_0;

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y1_Getter_(mthis) => mthis["y1"];

  y1_Setter_(mthis, __arg_0) => mthis["y1"] = __arg_0;

  y2_Getter_(mthis) => mthis["y2"];

  y2_Setter_(mthis, __arg_0) => mthis["y2"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGPathSegCurvetoCubicSmoothAbs extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegCurvetoCubicSmoothAbs();

  x2_Getter_(mthis) => mthis["x2"];

  x2_Setter_(mthis, __arg_0) => mthis["x2"] = __arg_0;

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y2_Getter_(mthis) => mthis["y2"];

  y2_Setter_(mthis, __arg_0) => mthis["y2"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGPathSegCurvetoCubicSmoothRel extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegCurvetoCubicSmoothRel();

  x2_Getter_(mthis) => mthis["x2"];

  x2_Setter_(mthis, __arg_0) => mthis["x2"] = __arg_0;

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y2_Getter_(mthis) => mthis["y2"];

  y2_Setter_(mthis, __arg_0) => mthis["y2"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGPathSegCurvetoQuadraticAbs extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegCurvetoQuadraticAbs();

  x1_Getter_(mthis) => mthis["x1"];

  x1_Setter_(mthis, __arg_0) => mthis["x1"] = __arg_0;

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y1_Getter_(mthis) => mthis["y1"];

  y1_Setter_(mthis, __arg_0) => mthis["y1"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGPathSegCurvetoQuadraticRel extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegCurvetoQuadraticRel();

  x1_Getter_(mthis) => mthis["x1"];

  x1_Setter_(mthis, __arg_0) => mthis["x1"] = __arg_0;

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y1_Getter_(mthis) => mthis["y1"];

  y1_Setter_(mthis, __arg_0) => mthis["y1"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGPathSegCurvetoQuadraticSmoothAbs extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegCurvetoQuadraticSmoothAbs();

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGPathSegCurvetoQuadraticSmoothRel extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegCurvetoQuadraticSmoothRel();

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGPathSegLinetoAbs extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegLinetoAbs();

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGPathSegLinetoHorizontalAbs extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegLinetoHorizontalAbs();

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

}

class BlinkSVGPathSegLinetoHorizontalRel extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegLinetoHorizontalRel();

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

}

class BlinkSVGPathSegLinetoRel extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegLinetoRel();

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGPathSegLinetoVerticalAbs extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegLinetoVerticalAbs();

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGPathSegLinetoVerticalRel extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegLinetoVerticalRel();

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGPathSegList {
  static final instance = new BlinkSVGPathSegList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  $__setter___Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("__setter__", [__arg_0, __arg_1]);

  appendItem_Callback_0_(mthis) => mthis.callMethod("appendItem", []);

  appendItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("appendItem", [__arg_0]);

  clear_Callback_0_(mthis) => mthis.callMethod("clear", []);

  getItem_Callback_0_(mthis) => mthis.callMethod("getItem", []);

  getItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("getItem", [__arg_0]);

  initialize_Callback_0_(mthis) => mthis.callMethod("initialize", []);

  initialize_Callback_1_(mthis, __arg_0) => mthis.callMethod("initialize", [__arg_0]);

  insertItemBefore_Callback_0_(mthis) => mthis.callMethod("insertItemBefore", []);

  insertItemBefore_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertItemBefore", [__arg_0]);

  insertItemBefore_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("insertItemBefore", [__arg_0, __arg_1]);

  length_Getter_(mthis) => mthis["length"];

  numberOfItems_Getter_(mthis) => mthis["numberOfItems"];

  removeItem_Callback_0_(mthis) => mthis.callMethod("removeItem", []);

  removeItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeItem", [__arg_0]);

  replaceItem_Callback_0_(mthis) => mthis.callMethod("replaceItem", []);

  replaceItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("replaceItem", [__arg_0]);

  replaceItem_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("replaceItem", [__arg_0, __arg_1]);

}

class BlinkSVGPathSegMovetoAbs extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegMovetoAbs();

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGPathSegMovetoRel extends BlinkSVGPathSeg {
  static final instance = new BlinkSVGPathSegMovetoRel();

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGPatternElement extends BlinkSVGElement {
  static final instance = new BlinkSVGPatternElement();

  hasExtension_Callback_0_(mthis) => mthis.callMethod("hasExtension", []);

  hasExtension_Callback_1_(mthis, __arg_0) => mthis.callMethod("hasExtension", [__arg_0]);

  height_Getter_(mthis) => mthis["height"];

  href_Getter_(mthis) => mthis["href"];

  patternContentUnits_Getter_(mthis) => mthis["patternContentUnits"];

  patternTransform_Getter_(mthis) => mthis["patternTransform"];

  patternUnits_Getter_(mthis) => mthis["patternUnits"];

  preserveAspectRatio_Getter_(mthis) => mthis["preserveAspectRatio"];

  requiredExtensions_Getter_(mthis) => mthis["requiredExtensions"];

  requiredFeatures_Getter_(mthis) => mthis["requiredFeatures"];

  systemLanguage_Getter_(mthis) => mthis["systemLanguage"];

  viewBox_Getter_(mthis) => mthis["viewBox"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGPoint {
  static final instance = new BlinkSVGPoint();

  matrixTransform_Callback_0_(mthis) => mthis.callMethod("matrixTransform", []);

  matrixTransform_Callback_1_(mthis, __arg_0) => mthis.callMethod("matrixTransform", [__arg_0]);

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGPointList {
  static final instance = new BlinkSVGPointList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  $__setter___Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("__setter__", [__arg_0, __arg_1]);

  appendItem_Callback_0_(mthis) => mthis.callMethod("appendItem", []);

  appendItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("appendItem", [__arg_0]);

  clear_Callback_0_(mthis) => mthis.callMethod("clear", []);

  getItem_Callback_0_(mthis) => mthis.callMethod("getItem", []);

  getItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("getItem", [__arg_0]);

  initialize_Callback_0_(mthis) => mthis.callMethod("initialize", []);

  initialize_Callback_1_(mthis, __arg_0) => mthis.callMethod("initialize", [__arg_0]);

  insertItemBefore_Callback_0_(mthis) => mthis.callMethod("insertItemBefore", []);

  insertItemBefore_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertItemBefore", [__arg_0]);

  insertItemBefore_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("insertItemBefore", [__arg_0, __arg_1]);

  length_Getter_(mthis) => mthis["length"];

  numberOfItems_Getter_(mthis) => mthis["numberOfItems"];

  removeItem_Callback_0_(mthis) => mthis.callMethod("removeItem", []);

  removeItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeItem", [__arg_0]);

  replaceItem_Callback_0_(mthis) => mthis.callMethod("replaceItem", []);

  replaceItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("replaceItem", [__arg_0]);

  replaceItem_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("replaceItem", [__arg_0, __arg_1]);

}

class BlinkSVGPolygonElement extends BlinkSVGGeometryElement {
  static final instance = new BlinkSVGPolygonElement();

  animatedPoints_Getter_(mthis) => mthis["animatedPoints"];

  points_Getter_(mthis) => mthis["points"];

}

class BlinkSVGPolylineElement extends BlinkSVGGeometryElement {
  static final instance = new BlinkSVGPolylineElement();

  animatedPoints_Getter_(mthis) => mthis["animatedPoints"];

  points_Getter_(mthis) => mthis["points"];

}

class BlinkSVGPreserveAspectRatio {
  static final instance = new BlinkSVGPreserveAspectRatio();

  align_Getter_(mthis) => mthis["align"];

  align_Setter_(mthis, __arg_0) => mthis["align"] = __arg_0;

  meetOrSlice_Getter_(mthis) => mthis["meetOrSlice"];

  meetOrSlice_Setter_(mthis, __arg_0) => mthis["meetOrSlice"] = __arg_0;

}

class BlinkSVGRadialGradientElement extends BlinkSVGGradientElement {
  static final instance = new BlinkSVGRadialGradientElement();

  cx_Getter_(mthis) => mthis["cx"];

  cy_Getter_(mthis) => mthis["cy"];

  fr_Getter_(mthis) => mthis["fr"];

  fx_Getter_(mthis) => mthis["fx"];

  fy_Getter_(mthis) => mthis["fy"];

  r_Getter_(mthis) => mthis["r"];

}

class BlinkSVGRect {
  static final instance = new BlinkSVGRect();

  height_Getter_(mthis) => mthis["height"];

  height_Setter_(mthis, __arg_0) => mthis["height"] = __arg_0;

  width_Getter_(mthis) => mthis["width"];

  width_Setter_(mthis, __arg_0) => mthis["width"] = __arg_0;

  x_Getter_(mthis) => mthis["x"];

  x_Setter_(mthis, __arg_0) => mthis["x"] = __arg_0;

  y_Getter_(mthis) => mthis["y"];

  y_Setter_(mthis, __arg_0) => mthis["y"] = __arg_0;

}

class BlinkSVGRectElement extends BlinkSVGGeometryElement {
  static final instance = new BlinkSVGRectElement();

  height_Getter_(mthis) => mthis["height"];

  rx_Getter_(mthis) => mthis["rx"];

  ry_Getter_(mthis) => mthis["ry"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGRenderingIntent {
  static final instance = new BlinkSVGRenderingIntent();

}

class BlinkSVGSVGElement extends BlinkSVGGraphicsElement {
  static final instance = new BlinkSVGSVGElement();

  animationsPaused_Callback_0_(mthis) => mthis.callMethod("animationsPaused", []);

  checkEnclosure_Callback_0_(mthis) => mthis.callMethod("checkEnclosure", []);

  checkEnclosure_Callback_1_(mthis, __arg_0) => mthis.callMethod("checkEnclosure", [__arg_0]);

  checkEnclosure_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("checkEnclosure", [__arg_0, __arg_1]);

  checkIntersection_Callback_0_(mthis) => mthis.callMethod("checkIntersection", []);

  checkIntersection_Callback_1_(mthis, __arg_0) => mthis.callMethod("checkIntersection", [__arg_0]);

  checkIntersection_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("checkIntersection", [__arg_0, __arg_1]);

  createSVGAngle_Callback_0_(mthis) => mthis.callMethod("createSVGAngle", []);

  createSVGLength_Callback_0_(mthis) => mthis.callMethod("createSVGLength", []);

  createSVGMatrix_Callback_0_(mthis) => mthis.callMethod("createSVGMatrix", []);

  createSVGNumber_Callback_0_(mthis) => mthis.callMethod("createSVGNumber", []);

  createSVGPoint_Callback_0_(mthis) => mthis.callMethod("createSVGPoint", []);

  createSVGRect_Callback_0_(mthis) => mthis.callMethod("createSVGRect", []);

  createSVGTransformFromMatrix_Callback_0_(mthis) => mthis.callMethod("createSVGTransformFromMatrix", []);

  createSVGTransformFromMatrix_Callback_1_(mthis, __arg_0) => mthis.callMethod("createSVGTransformFromMatrix", [__arg_0]);

  createSVGTransform_Callback_0_(mthis) => mthis.callMethod("createSVGTransform", []);

  currentScale_Getter_(mthis) => mthis["currentScale"];

  currentScale_Setter_(mthis, __arg_0) => mthis["currentScale"] = __arg_0;

  currentTranslate_Getter_(mthis) => mthis["currentTranslate"];

  currentView_Getter_(mthis) => mthis["currentView"];

  deselectAll_Callback_0_(mthis) => mthis.callMethod("deselectAll", []);

  forceRedraw_Callback_0_(mthis) => mthis.callMethod("forceRedraw", []);

  getCurrentTime_Callback_0_(mthis) => mthis.callMethod("getCurrentTime", []);

  getElementById_Callback_0_(mthis) => mthis.callMethod("getElementById", []);

  getElementById_Callback_1_(mthis, __arg_0) => mthis.callMethod("getElementById", [__arg_0]);

  getEnclosureList_Callback_0_(mthis) => mthis.callMethod("getEnclosureList", []);

  getEnclosureList_Callback_1_(mthis, __arg_0) => mthis.callMethod("getEnclosureList", [__arg_0]);

  getEnclosureList_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getEnclosureList", [__arg_0, __arg_1]);

  getIntersectionList_Callback_0_(mthis) => mthis.callMethod("getIntersectionList", []);

  getIntersectionList_Callback_1_(mthis, __arg_0) => mthis.callMethod("getIntersectionList", [__arg_0]);

  getIntersectionList_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getIntersectionList", [__arg_0, __arg_1]);

  height_Getter_(mthis) => mthis["height"];

  pauseAnimations_Callback_0_(mthis) => mthis.callMethod("pauseAnimations", []);

  pixelUnitToMillimeterX_Getter_(mthis) => mthis["pixelUnitToMillimeterX"];

  pixelUnitToMillimeterY_Getter_(mthis) => mthis["pixelUnitToMillimeterY"];

  preserveAspectRatio_Getter_(mthis) => mthis["preserveAspectRatio"];

  screenPixelToMillimeterX_Getter_(mthis) => mthis["screenPixelToMillimeterX"];

  screenPixelToMillimeterY_Getter_(mthis) => mthis["screenPixelToMillimeterY"];

  setCurrentTime_Callback_0_(mthis) => mthis.callMethod("setCurrentTime", []);

  setCurrentTime_Callback_1_(mthis, __arg_0) => mthis.callMethod("setCurrentTime", [__arg_0]);

  suspendRedraw_Callback_0_(mthis) => mthis.callMethod("suspendRedraw", []);

  suspendRedraw_Callback_1_(mthis, __arg_0) => mthis.callMethod("suspendRedraw", [__arg_0]);

  unpauseAnimations_Callback_0_(mthis) => mthis.callMethod("unpauseAnimations", []);

  unsuspendRedrawAll_Callback_0_(mthis) => mthis.callMethod("unsuspendRedrawAll", []);

  unsuspendRedraw_Callback_0_(mthis) => mthis.callMethod("unsuspendRedraw", []);

  unsuspendRedraw_Callback_1_(mthis, __arg_0) => mthis.callMethod("unsuspendRedraw", [__arg_0]);

  useCurrentView_Getter_(mthis) => mthis["useCurrentView"];

  viewBox_Getter_(mthis) => mthis["viewBox"];

  viewport_Getter_(mthis) => mthis["viewport"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

  zoomAndPan_Getter_(mthis) => mthis["zoomAndPan"];

  zoomAndPan_Setter_(mthis, __arg_0) => mthis["zoomAndPan"] = __arg_0;

}

class BlinkSVGScriptElement extends BlinkSVGElement {
  static final instance = new BlinkSVGScriptElement();

  href_Getter_(mthis) => mthis["href"];

  type_Getter_(mthis) => mthis["type"];

  type_Setter_(mthis, __arg_0) => mthis["type"] = __arg_0;

}

class BlinkSVGSetElement extends BlinkSVGAnimationElement {
  static final instance = new BlinkSVGSetElement();

}

class BlinkSVGStopElement extends BlinkSVGElement {
  static final instance = new BlinkSVGStopElement();

  offset_Getter_(mthis) => mthis["offset"];

}

class BlinkSVGStringList {
  static final instance = new BlinkSVGStringList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  $__setter___Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("__setter__", [__arg_0, __arg_1]);

  appendItem_Callback_0_(mthis) => mthis.callMethod("appendItem", []);

  appendItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("appendItem", [__arg_0]);

  clear_Callback_0_(mthis) => mthis.callMethod("clear", []);

  getItem_Callback_0_(mthis) => mthis.callMethod("getItem", []);

  getItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("getItem", [__arg_0]);

  initialize_Callback_0_(mthis) => mthis.callMethod("initialize", []);

  initialize_Callback_1_(mthis, __arg_0) => mthis.callMethod("initialize", [__arg_0]);

  insertItemBefore_Callback_0_(mthis) => mthis.callMethod("insertItemBefore", []);

  insertItemBefore_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertItemBefore", [__arg_0]);

  insertItemBefore_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("insertItemBefore", [__arg_0, __arg_1]);

  length_Getter_(mthis) => mthis["length"];

  numberOfItems_Getter_(mthis) => mthis["numberOfItems"];

  removeItem_Callback_0_(mthis) => mthis.callMethod("removeItem", []);

  removeItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeItem", [__arg_0]);

  replaceItem_Callback_0_(mthis) => mthis.callMethod("replaceItem", []);

  replaceItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("replaceItem", [__arg_0]);

  replaceItem_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("replaceItem", [__arg_0, __arg_1]);

}

class BlinkSVGStyleElement extends BlinkSVGElement {
  static final instance = new BlinkSVGStyleElement();

  disabled_Getter_(mthis) => mthis["disabled"];

  disabled_Setter_(mthis, __arg_0) => mthis["disabled"] = __arg_0;

  media_Getter_(mthis) => mthis["media"];

  media_Setter_(mthis, __arg_0) => mthis["media"] = __arg_0;

  sheet_Getter_(mthis) => mthis["sheet"];

  title_Getter_(mthis) => mthis["title"];

  title_Setter_(mthis, __arg_0) => mthis["title"] = __arg_0;

  type_Getter_(mthis) => mthis["type"];

  type_Setter_(mthis, __arg_0) => mthis["type"] = __arg_0;

}

class BlinkSVGSwitchElement extends BlinkSVGGraphicsElement {
  static final instance = new BlinkSVGSwitchElement();

}

class BlinkSVGSymbolElement extends BlinkSVGElement {
  static final instance = new BlinkSVGSymbolElement();

  preserveAspectRatio_Getter_(mthis) => mthis["preserveAspectRatio"];

  viewBox_Getter_(mthis) => mthis["viewBox"];

}

class BlinkSVGTSpanElement extends BlinkSVGTextPositioningElement {
  static final instance = new BlinkSVGTSpanElement();

}

class BlinkSVGTextContentElement extends BlinkSVGGraphicsElement {
  static final instance = new BlinkSVGTextContentElement();

  getCharNumAtPosition_Callback_0_(mthis) => mthis.callMethod("getCharNumAtPosition", []);

  getCharNumAtPosition_Callback_1_(mthis, __arg_0) => mthis.callMethod("getCharNumAtPosition", [__arg_0]);

  getComputedTextLength_Callback_0_(mthis) => mthis.callMethod("getComputedTextLength", []);

  getEndPositionOfChar_Callback_0_(mthis) => mthis.callMethod("getEndPositionOfChar", []);

  getEndPositionOfChar_Callback_1_(mthis, __arg_0) => mthis.callMethod("getEndPositionOfChar", [__arg_0]);

  getExtentOfChar_Callback_0_(mthis) => mthis.callMethod("getExtentOfChar", []);

  getExtentOfChar_Callback_1_(mthis, __arg_0) => mthis.callMethod("getExtentOfChar", [__arg_0]);

  getNumberOfChars_Callback_0_(mthis) => mthis.callMethod("getNumberOfChars", []);

  getRotationOfChar_Callback_0_(mthis) => mthis.callMethod("getRotationOfChar", []);

  getRotationOfChar_Callback_1_(mthis, __arg_0) => mthis.callMethod("getRotationOfChar", [__arg_0]);

  getStartPositionOfChar_Callback_0_(mthis) => mthis.callMethod("getStartPositionOfChar", []);

  getStartPositionOfChar_Callback_1_(mthis, __arg_0) => mthis.callMethod("getStartPositionOfChar", [__arg_0]);

  getSubStringLength_Callback_0_(mthis) => mthis.callMethod("getSubStringLength", []);

  getSubStringLength_Callback_1_(mthis, __arg_0) => mthis.callMethod("getSubStringLength", [__arg_0]);

  getSubStringLength_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getSubStringLength", [__arg_0, __arg_1]);

  lengthAdjust_Getter_(mthis) => mthis["lengthAdjust"];

  selectSubString_Callback_0_(mthis) => mthis.callMethod("selectSubString", []);

  selectSubString_Callback_1_(mthis, __arg_0) => mthis.callMethod("selectSubString", [__arg_0]);

  selectSubString_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("selectSubString", [__arg_0, __arg_1]);

  textLength_Getter_(mthis) => mthis["textLength"];

}

class BlinkSVGTextElement extends BlinkSVGTextPositioningElement {
  static final instance = new BlinkSVGTextElement();

}

class BlinkSVGTextPathElement extends BlinkSVGTextContentElement {
  static final instance = new BlinkSVGTextPathElement();

  href_Getter_(mthis) => mthis["href"];

  method_Getter_(mthis) => mthis["method"];

  spacing_Getter_(mthis) => mthis["spacing"];

  startOffset_Getter_(mthis) => mthis["startOffset"];

}

class BlinkSVGTextPositioningElement extends BlinkSVGTextContentElement {
  static final instance = new BlinkSVGTextPositioningElement();

  dx_Getter_(mthis) => mthis["dx"];

  dy_Getter_(mthis) => mthis["dy"];

  rotate_Getter_(mthis) => mthis["rotate"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGTitleElement extends BlinkSVGElement {
  static final instance = new BlinkSVGTitleElement();

}

class BlinkSVGTransform {
  static final instance = new BlinkSVGTransform();

  angle_Getter_(mthis) => mthis["angle"];

  matrix_Getter_(mthis) => mthis["matrix"];

  setMatrix_Callback_0_(mthis) => mthis.callMethod("setMatrix", []);

  setMatrix_Callback_1_(mthis, __arg_0) => mthis.callMethod("setMatrix", [__arg_0]);

  setRotate_Callback_1_(mthis, __arg_0) => mthis.callMethod("setRotate", [__arg_0]);

  setRotate_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setRotate", [__arg_0, __arg_1]);

  setRotate_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setRotate", [__arg_0, __arg_1, __arg_2]);

  setScale_Callback_0_(mthis) => mthis.callMethod("setScale", []);

  setScale_Callback_1_(mthis, __arg_0) => mthis.callMethod("setScale", [__arg_0]);

  setScale_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setScale", [__arg_0, __arg_1]);

  setSkewX_Callback_0_(mthis) => mthis.callMethod("setSkewX", []);

  setSkewX_Callback_1_(mthis, __arg_0) => mthis.callMethod("setSkewX", [__arg_0]);

  setSkewY_Callback_0_(mthis) => mthis.callMethod("setSkewY", []);

  setSkewY_Callback_1_(mthis, __arg_0) => mthis.callMethod("setSkewY", [__arg_0]);

  setTranslate_Callback_0_(mthis) => mthis.callMethod("setTranslate", []);

  setTranslate_Callback_1_(mthis, __arg_0) => mthis.callMethod("setTranslate", [__arg_0]);

  setTranslate_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setTranslate", [__arg_0, __arg_1]);

  type_Getter_(mthis) => mthis["type"];

}

class BlinkSVGTransformList {
  static final instance = new BlinkSVGTransformList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  $__setter___Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("__setter__", [__arg_0, __arg_1]);

  appendItem_Callback_0_(mthis) => mthis.callMethod("appendItem", []);

  appendItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("appendItem", [__arg_0]);

  clear_Callback_0_(mthis) => mthis.callMethod("clear", []);

  consolidate_Callback_0_(mthis) => mthis.callMethod("consolidate", []);

  createSVGTransformFromMatrix_Callback_0_(mthis) => mthis.callMethod("createSVGTransformFromMatrix", []);

  createSVGTransformFromMatrix_Callback_1_(mthis, __arg_0) => mthis.callMethod("createSVGTransformFromMatrix", [__arg_0]);

  getItem_Callback_0_(mthis) => mthis.callMethod("getItem", []);

  getItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("getItem", [__arg_0]);

  initialize_Callback_0_(mthis) => mthis.callMethod("initialize", []);

  initialize_Callback_1_(mthis, __arg_0) => mthis.callMethod("initialize", [__arg_0]);

  insertItemBefore_Callback_0_(mthis) => mthis.callMethod("insertItemBefore", []);

  insertItemBefore_Callback_1_(mthis, __arg_0) => mthis.callMethod("insertItemBefore", [__arg_0]);

  insertItemBefore_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("insertItemBefore", [__arg_0, __arg_1]);

  length_Getter_(mthis) => mthis["length"];

  numberOfItems_Getter_(mthis) => mthis["numberOfItems"];

  removeItem_Callback_0_(mthis) => mthis.callMethod("removeItem", []);

  removeItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeItem", [__arg_0]);

  replaceItem_Callback_0_(mthis) => mthis.callMethod("replaceItem", []);

  replaceItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("replaceItem", [__arg_0]);

  replaceItem_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("replaceItem", [__arg_0, __arg_1]);

}

class BlinkSVGUnitTypes {
  static final instance = new BlinkSVGUnitTypes();

}

class BlinkSVGUseElement extends BlinkSVGGraphicsElement {
  static final instance = new BlinkSVGUseElement();

  height_Getter_(mthis) => mthis["height"];

  href_Getter_(mthis) => mthis["href"];

  width_Getter_(mthis) => mthis["width"];

  x_Getter_(mthis) => mthis["x"];

  y_Getter_(mthis) => mthis["y"];

}

class BlinkSVGVKernElement extends BlinkSVGElement {
  static final instance = new BlinkSVGVKernElement();

}

class BlinkSVGViewElement extends BlinkSVGElement {
  static final instance = new BlinkSVGViewElement();

  preserveAspectRatio_Getter_(mthis) => mthis["preserveAspectRatio"];

  viewBox_Getter_(mthis) => mthis["viewBox"];

  viewTarget_Getter_(mthis) => mthis["viewTarget"];

  zoomAndPan_Getter_(mthis) => mthis["zoomAndPan"];

  zoomAndPan_Setter_(mthis, __arg_0) => mthis["zoomAndPan"] = __arg_0;

}

class BlinkSVGViewSpec {
  static final instance = new BlinkSVGViewSpec();

  preserveAspectRatioString_Getter_(mthis) => mthis["preserveAspectRatioString"];

  preserveAspectRatio_Getter_(mthis) => mthis["preserveAspectRatio"];

  transformString_Getter_(mthis) => mthis["transformString"];

  transform_Getter_(mthis) => mthis["transform"];

  viewBoxString_Getter_(mthis) => mthis["viewBoxString"];

  viewBox_Getter_(mthis) => mthis["viewBox"];

  viewTargetString_Getter_(mthis) => mthis["viewTargetString"];

  viewTarget_Getter_(mthis) => mthis["viewTarget"];

  zoomAndPan_Getter_(mthis) => mthis["zoomAndPan"];

  zoomAndPan_Setter_(mthis, __arg_0) => mthis["zoomAndPan"] = __arg_0;

}

class BlinkSVGZoomEvent extends BlinkUIEvent {
  static final instance = new BlinkSVGZoomEvent();

  newScale_Getter_(mthis) => mthis["newScale"];

  newTranslate_Getter_(mthis) => mthis["newTranslate"];

  previousScale_Getter_(mthis) => mthis["previousScale"];

  previousTranslate_Getter_(mthis) => mthis["previousTranslate"];

  zoomRectScreen_Getter_(mthis) => mthis["zoomRectScreen"];

}

class BlinkScreen {
  static final instance = new BlinkScreen();

  availHeight_Getter_(mthis) => mthis["availHeight"];

  availLeft_Getter_(mthis) => mthis["availLeft"];

  availTop_Getter_(mthis) => mthis["availTop"];

  availWidth_Getter_(mthis) => mthis["availWidth"];

  colorDepth_Getter_(mthis) => mthis["colorDepth"];

  height_Getter_(mthis) => mthis["height"];

  orientation_Getter_(mthis) => mthis["orientation"];

  pixelDepth_Getter_(mthis) => mthis["pixelDepth"];

  width_Getter_(mthis) => mthis["width"];

}

class BlinkScreenOrientation extends BlinkEventTarget {
  static final instance = new BlinkScreenOrientation();

  angle_Getter_(mthis) => mthis["angle"];

  lock_Callback_0_(mthis) => mthis.callMethod("lock", []);

  lock_Callback_1_(mthis, __arg_0) => mthis.callMethod("lock", [__arg_0]);

  onchange_Getter_(mthis) => mthis["onchange"];

  onchange_Setter_(mthis, __arg_0) => mthis["onchange"] = __arg_0;

  type_Getter_(mthis) => mthis["type"];

  unlock_Callback_0_(mthis) => mthis.callMethod("unlock", []);

}

class BlinkScriptProcessorNode extends BlinkAudioNode {
  static final instance = new BlinkScriptProcessorNode();

  bufferSize_Getter_(mthis) => mthis["bufferSize"];

  onaudioprocess_Getter_(mthis) => mthis["onaudioprocess"];

  onaudioprocess_Setter_(mthis, __arg_0) => mthis["onaudioprocess"] = __arg_0;

  setEventListener_Callback_0_(mthis) => mthis.callMethod("setEventListener", []);

  setEventListener_Callback_1_(mthis, __arg_0) => mthis.callMethod("setEventListener", [__arg_0]);

}

class BlinkSecurityPolicyViolationEvent extends BlinkEvent {
  static final instance = new BlinkSecurityPolicyViolationEvent();

  blockedURI_Getter_(mthis) => mthis["blockedURI"];

  columnNumber_Getter_(mthis) => mthis["columnNumber"];

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["SecurityPolicyViolationEvent"], [__arg_0, __arg_1]);

  documentURI_Getter_(mthis) => mthis["documentURI"];

  effectiveDirective_Getter_(mthis) => mthis["effectiveDirective"];

  lineNumber_Getter_(mthis) => mthis["lineNumber"];

  originalPolicy_Getter_(mthis) => mthis["originalPolicy"];

  referrer_Getter_(mthis) => mthis["referrer"];

  sourceFile_Getter_(mthis) => mthis["sourceFile"];

  statusCode_Getter_(mthis) => mthis["statusCode"];

  violatedDirective_Getter_(mthis) => mthis["violatedDirective"];

}

class BlinkSelection {
  static final instance = new BlinkSelection();

  addRange_Callback_0_(mthis) => mthis.callMethod("addRange", []);

  addRange_Callback_1_(mthis, __arg_0) => mthis.callMethod("addRange", [__arg_0]);

  anchorNode_Getter_(mthis) => mthis["anchorNode"];

  anchorOffset_Getter_(mthis) => mthis["anchorOffset"];

  baseNode_Getter_(mthis) => mthis["baseNode"];

  baseOffset_Getter_(mthis) => mthis["baseOffset"];

  collapseToEnd_Callback_0_(mthis) => mthis.callMethod("collapseToEnd", []);

  collapseToStart_Callback_0_(mthis) => mthis.callMethod("collapseToStart", []);

  collapse_Callback_0_(mthis) => mthis.callMethod("collapse", []);

  collapse_Callback_1_(mthis, __arg_0) => mthis.callMethod("collapse", [__arg_0]);

  collapse_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("collapse", [__arg_0, __arg_1]);

  containsNode_Callback_0_(mthis) => mthis.callMethod("containsNode", []);

  containsNode_Callback_1_(mthis, __arg_0) => mthis.callMethod("containsNode", [__arg_0]);

  containsNode_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("containsNode", [__arg_0, __arg_1]);

  deleteFromDocument_Callback_0_(mthis) => mthis.callMethod("deleteFromDocument", []);

  empty_Callback_0_(mthis) => mthis.callMethod("empty", []);

  extend_Callback_0_(mthis) => mthis.callMethod("extend", []);

  extend_Callback_1_(mthis, __arg_0) => mthis.callMethod("extend", [__arg_0]);

  extend_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("extend", [__arg_0, __arg_1]);

  extentNode_Getter_(mthis) => mthis["extentNode"];

  extentOffset_Getter_(mthis) => mthis["extentOffset"];

  focusNode_Getter_(mthis) => mthis["focusNode"];

  focusOffset_Getter_(mthis) => mthis["focusOffset"];

  getRangeAt_Callback_0_(mthis) => mthis.callMethod("getRangeAt", []);

  getRangeAt_Callback_1_(mthis, __arg_0) => mthis.callMethod("getRangeAt", [__arg_0]);

  isCollapsed_Getter_(mthis) => mthis["isCollapsed"];

  modify_Callback_0_(mthis) => mthis.callMethod("modify", []);

  modify_Callback_1_(mthis, __arg_0) => mthis.callMethod("modify", [__arg_0]);

  modify_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("modify", [__arg_0, __arg_1]);

  modify_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("modify", [__arg_0, __arg_1, __arg_2]);

  rangeCount_Getter_(mthis) => mthis["rangeCount"];

  removeAllRanges_Callback_0_(mthis) => mthis.callMethod("removeAllRanges", []);

  selectAllChildren_Callback_0_(mthis) => mthis.callMethod("selectAllChildren", []);

  selectAllChildren_Callback_1_(mthis, __arg_0) => mthis.callMethod("selectAllChildren", [__arg_0]);

  setBaseAndExtent_Callback_0_(mthis) => mthis.callMethod("setBaseAndExtent", []);

  setBaseAndExtent_Callback_1_(mthis, __arg_0) => mthis.callMethod("setBaseAndExtent", [__arg_0]);

  setBaseAndExtent_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setBaseAndExtent", [__arg_0, __arg_1]);

  setBaseAndExtent_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setBaseAndExtent", [__arg_0, __arg_1, __arg_2]);

  setBaseAndExtent_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("setBaseAndExtent", [__arg_0, __arg_1, __arg_2, __arg_3]);

  setPosition_Callback_0_(mthis) => mthis.callMethod("setPosition", []);

  setPosition_Callback_1_(mthis, __arg_0) => mthis.callMethod("setPosition", [__arg_0]);

  setPosition_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setPosition", [__arg_0, __arg_1]);

  type_Getter_(mthis) => mthis["type"];

}

class BlinkServiceWorker extends BlinkEventTarget {
  static final instance = new BlinkServiceWorker();

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onstatechange_Getter_(mthis) => mthis["onstatechange"];

  onstatechange_Setter_(mthis, __arg_0) => mthis["onstatechange"] = __arg_0;

  postMessage_Callback_0_(mthis) => mthis.callMethod("postMessage", []);

  postMessage_Callback_1_(mthis, __arg_0) => mthis.callMethod("postMessage", [__arg_0]);

  postMessage_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("postMessage", [__arg_0, __arg_1]);

  scriptURL_Getter_(mthis) => mthis["scriptURL"];

  state_Getter_(mthis) => mthis["state"];

  terminate_Callback_0_(mthis) => mthis.callMethod("terminate", []);

}

class BlinkServiceWorkerClient {
  static final instance = new BlinkServiceWorkerClient();

  id_Getter_(mthis) => mthis["id"];

  postMessage_Callback_0_(mthis) => mthis.callMethod("postMessage", []);

  postMessage_Callback_1_(mthis, __arg_0) => mthis.callMethod("postMessage", [__arg_0]);

  postMessage_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("postMessage", [__arg_0, __arg_1]);

}

class BlinkServiceWorkerClients {
  static final instance = new BlinkServiceWorkerClients();

  getAll_Callback_0_(mthis) => mthis.callMethod("getAll", []);

  getAll_Callback_1_(mthis, __arg_0) => mthis.callMethod("getAll", [__arg_0]);

}

class BlinkServiceWorkerContainer {
  static final instance = new BlinkServiceWorkerContainer();

  controller_Getter_(mthis) => mthis["controller"];

  getRegistration_Callback_0_(mthis) => mthis.callMethod("getRegistration", []);

  getRegistration_Callback_1_(mthis, __arg_0) => mthis.callMethod("getRegistration", [__arg_0]);

  ready_Getter_(mthis) => mthis["ready"];

  register_Callback_0_(mthis) => mthis.callMethod("register", []);

  register_Callback_1_(mthis, __arg_0) => mthis.callMethod("register", [__arg_0]);

  register_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("register", [__arg_0, __arg_1]);

}

class BlinkServiceWorkerGlobalScope extends BlinkWorkerGlobalScope {
  static final instance = new BlinkServiceWorkerGlobalScope();

  caches_Getter_(mthis) => mthis["caches"];

  clients_Getter_(mthis) => mthis["clients"];

  close_Callback_0_(mthis) => mthis.callMethod("close", []);

  fetch_Callback_0_(mthis) => mthis.callMethod("fetch", []);

  fetch_Callback_1_(mthis, __arg_0) => mthis.callMethod("fetch", [__arg_0]);

  fetch_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("fetch", [__arg_0, __arg_1]);

  onactivate_Getter_(mthis) => mthis["onactivate"];

  onactivate_Setter_(mthis, __arg_0) => mthis["onactivate"] = __arg_0;

  onfetch_Getter_(mthis) => mthis["onfetch"];

  onfetch_Setter_(mthis, __arg_0) => mthis["onfetch"] = __arg_0;

  oninstall_Getter_(mthis) => mthis["oninstall"];

  oninstall_Setter_(mthis, __arg_0) => mthis["oninstall"] = __arg_0;

  onmessage_Getter_(mthis) => mthis["onmessage"];

  onmessage_Setter_(mthis, __arg_0) => mthis["onmessage"] = __arg_0;

  onpush_Getter_(mthis) => mthis["onpush"];

  onpush_Setter_(mthis, __arg_0) => mthis["onpush"] = __arg_0;

  onsync_Getter_(mthis) => mthis["onsync"];

  onsync_Setter_(mthis, __arg_0) => mthis["onsync"] = __arg_0;

  scope_Getter_(mthis) => mthis["scope"];

}

class BlinkServiceWorkerRegistration extends BlinkEventTarget {
  static final instance = new BlinkServiceWorkerRegistration();

  active_Getter_(mthis) => mthis["active"];

  installing_Getter_(mthis) => mthis["installing"];

  onupdatefound_Getter_(mthis) => mthis["onupdatefound"];

  onupdatefound_Setter_(mthis, __arg_0) => mthis["onupdatefound"] = __arg_0;

  scope_Getter_(mthis) => mthis["scope"];

  unregister_Callback_0_(mthis) => mthis.callMethod("unregister", []);

  waiting_Getter_(mthis) => mthis["waiting"];

}

class BlinkShadowRoot extends BlinkDocumentFragment {
  static final instance = new BlinkShadowRoot();

  activeElement_Getter_(mthis) => mthis["activeElement"];

  cloneNode_Callback_0_(mthis) => mthis.callMethod("cloneNode", []);

  cloneNode_Callback_1_(mthis, __arg_0) => mthis.callMethod("cloneNode", [__arg_0]);

  elementFromPoint_Callback_0_(mthis) => mthis.callMethod("elementFromPoint", []);

  elementFromPoint_Callback_1_(mthis, __arg_0) => mthis.callMethod("elementFromPoint", [__arg_0]);

  elementFromPoint_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("elementFromPoint", [__arg_0, __arg_1]);

  getElementById_Callback_0_(mthis) => mthis.callMethod("getElementById", []);

  getElementById_Callback_1_(mthis, __arg_0) => mthis.callMethod("getElementById", [__arg_0]);

  getElementsByClassName_Callback_0_(mthis) => mthis.callMethod("getElementsByClassName", []);

  getElementsByClassName_Callback_1_(mthis, __arg_0) => mthis.callMethod("getElementsByClassName", [__arg_0]);

  getElementsByTagName_Callback_0_(mthis) => mthis.callMethod("getElementsByTagName", []);

  getElementsByTagName_Callback_1_(mthis, __arg_0) => mthis.callMethod("getElementsByTagName", [__arg_0]);

  getSelection_Callback_0_(mthis) => mthis.callMethod("getSelection", []);

  host_Getter_(mthis) => mthis["host"];

  innerHTML_Getter_(mthis) => mthis["innerHTML"];

  innerHTML_Setter_(mthis, __arg_0) => mthis["innerHTML"] = __arg_0;

  olderShadowRoot_Getter_(mthis) => mthis["olderShadowRoot"];

  styleSheets_Getter_(mthis) => mthis["styleSheets"];

}

class BlinkSharedWorker extends BlinkEventTarget {
  static final instance = new BlinkSharedWorker();

  constructorCallback_0_() => new js.JsObject(js.context["SharedWorker"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["SharedWorker"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["SharedWorker"], [__arg_0, __arg_1]);

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  port_Getter_(mthis) => mthis["port"];

  workerStart_Getter_(mthis) => mthis["workerStart"];

}

class BlinkSharedWorkerGlobalScope extends BlinkWorkerGlobalScope {
  static final instance = new BlinkSharedWorkerGlobalScope();

  name_Getter_(mthis) => mthis["name"];

  onconnect_Getter_(mthis) => mthis["onconnect"];

  onconnect_Setter_(mthis, __arg_0) => mthis["onconnect"] = __arg_0;

}

class BlinkSourceBuffer extends BlinkEventTarget {
  static final instance = new BlinkSourceBuffer();

  abort_Callback_0_(mthis) => mthis.callMethod("abort", []);

  appendBuffer_Callback_0_(mthis) => mthis.callMethod("appendBuffer", []);

  appendBuffer_Callback_1_(mthis, __arg_0) => mthis.callMethod("appendBuffer", [__arg_0]);

  appendStream_Callback_0_(mthis) => mthis.callMethod("appendStream", []);

  appendStream_Callback_1_(mthis, __arg_0) => mthis.callMethod("appendStream", [__arg_0]);

  appendStream_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("appendStream", [__arg_0, __arg_1]);

  appendWindowEnd_Getter_(mthis) => mthis["appendWindowEnd"];

  appendWindowEnd_Setter_(mthis, __arg_0) => mthis["appendWindowEnd"] = __arg_0;

  appendWindowStart_Getter_(mthis) => mthis["appendWindowStart"];

  appendWindowStart_Setter_(mthis, __arg_0) => mthis["appendWindowStart"] = __arg_0;

  buffered_Getter_(mthis) => mthis["buffered"];

  mode_Getter_(mthis) => mthis["mode"];

  mode_Setter_(mthis, __arg_0) => mthis["mode"] = __arg_0;

  remove_Callback_0_(mthis) => mthis.callMethod("remove", []);

  remove_Callback_1_(mthis, __arg_0) => mthis.callMethod("remove", [__arg_0]);

  remove_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("remove", [__arg_0, __arg_1]);

  timestampOffset_Getter_(mthis) => mthis["timestampOffset"];

  timestampOffset_Setter_(mthis, __arg_0) => mthis["timestampOffset"] = __arg_0;

  updating_Getter_(mthis) => mthis["updating"];

}

class BlinkSourceBufferList extends BlinkEventTarget {
  static final instance = new BlinkSourceBufferList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

}

class BlinkSourceInfo {
  static final instance = new BlinkSourceInfo();

  facing_Getter_(mthis) => mthis["facing"];

  id_Getter_(mthis) => mthis["id"];

  kind_Getter_(mthis) => mthis["kind"];

  label_Getter_(mthis) => mthis["label"];

}

class BlinkSpeechGrammar {
  static final instance = new BlinkSpeechGrammar();

  constructorCallback_0_() => new js.JsObject(js.context["SpeechGrammar"], []);

  src_Getter_(mthis) => mthis["src"];

  src_Setter_(mthis, __arg_0) => mthis["src"] = __arg_0;

  weight_Getter_(mthis) => mthis["weight"];

  weight_Setter_(mthis, __arg_0) => mthis["weight"] = __arg_0;

}

class BlinkSpeechGrammarList {
  static final instance = new BlinkSpeechGrammarList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  addFromString_Callback_0_(mthis) => mthis.callMethod("addFromString", []);

  addFromString_Callback_1_(mthis, __arg_0) => mthis.callMethod("addFromString", [__arg_0]);

  addFromString_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("addFromString", [__arg_0, __arg_1]);

  addFromUri_Callback_0_(mthis) => mthis.callMethod("addFromUri", []);

  addFromUri_Callback_1_(mthis, __arg_0) => mthis.callMethod("addFromUri", [__arg_0]);

  addFromUri_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("addFromUri", [__arg_0, __arg_1]);

  constructorCallback_0_() => new js.JsObject(js.context["SpeechGrammarList"], []);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

}

class BlinkSpeechRecognition extends BlinkEventTarget {
  static final instance = new BlinkSpeechRecognition();

  abort_Callback_0_(mthis) => mthis.callMethod("abort", []);

  constructorCallback_0_() => new js.JsObject(js.context["SpeechRecognition"], []);

  continuous_Getter_(mthis) => mthis["continuous"];

  continuous_Setter_(mthis, __arg_0) => mthis["continuous"] = __arg_0;

  grammars_Getter_(mthis) => mthis["grammars"];

  grammars_Setter_(mthis, __arg_0) => mthis["grammars"] = __arg_0;

  interimResults_Getter_(mthis) => mthis["interimResults"];

  interimResults_Setter_(mthis, __arg_0) => mthis["interimResults"] = __arg_0;

  lang_Getter_(mthis) => mthis["lang"];

  lang_Setter_(mthis, __arg_0) => mthis["lang"] = __arg_0;

  maxAlternatives_Getter_(mthis) => mthis["maxAlternatives"];

  maxAlternatives_Setter_(mthis, __arg_0) => mthis["maxAlternatives"] = __arg_0;

  onaudioend_Getter_(mthis) => mthis["onaudioend"];

  onaudioend_Setter_(mthis, __arg_0) => mthis["onaudioend"] = __arg_0;

  onaudiostart_Getter_(mthis) => mthis["onaudiostart"];

  onaudiostart_Setter_(mthis, __arg_0) => mthis["onaudiostart"] = __arg_0;

  onend_Getter_(mthis) => mthis["onend"];

  onend_Setter_(mthis, __arg_0) => mthis["onend"] = __arg_0;

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onnomatch_Getter_(mthis) => mthis["onnomatch"];

  onnomatch_Setter_(mthis, __arg_0) => mthis["onnomatch"] = __arg_0;

  onresult_Getter_(mthis) => mthis["onresult"];

  onresult_Setter_(mthis, __arg_0) => mthis["onresult"] = __arg_0;

  onsoundend_Getter_(mthis) => mthis["onsoundend"];

  onsoundend_Setter_(mthis, __arg_0) => mthis["onsoundend"] = __arg_0;

  onsoundstart_Getter_(mthis) => mthis["onsoundstart"];

  onsoundstart_Setter_(mthis, __arg_0) => mthis["onsoundstart"] = __arg_0;

  onspeechend_Getter_(mthis) => mthis["onspeechend"];

  onspeechend_Setter_(mthis, __arg_0) => mthis["onspeechend"] = __arg_0;

  onspeechstart_Getter_(mthis) => mthis["onspeechstart"];

  onspeechstart_Setter_(mthis, __arg_0) => mthis["onspeechstart"] = __arg_0;

  onstart_Getter_(mthis) => mthis["onstart"];

  onstart_Setter_(mthis, __arg_0) => mthis["onstart"] = __arg_0;

  start_Callback_0_(mthis) => mthis.callMethod("start", []);

  stop_Callback_0_(mthis) => mthis.callMethod("stop", []);

}

class BlinkSpeechRecognitionAlternative {
  static final instance = new BlinkSpeechRecognitionAlternative();

  confidence_Getter_(mthis) => mthis["confidence"];

  transcript_Getter_(mthis) => mthis["transcript"];

}

class BlinkSpeechRecognitionError extends BlinkEvent {
  static final instance = new BlinkSpeechRecognitionError();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["SpeechRecognitionError"], [__arg_0, __arg_1]);

  error_Getter_(mthis) => mthis["error"];

  message_Getter_(mthis) => mthis["message"];

}

class BlinkSpeechRecognitionEvent extends BlinkEvent {
  static final instance = new BlinkSpeechRecognitionEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["SpeechRecognitionEvent"], [__arg_0, __arg_1]);

  emma_Getter_(mthis) => mthis["emma"];

  interpretation_Getter_(mthis) => mthis["interpretation"];

  resultIndex_Getter_(mthis) => mthis["resultIndex"];

  results_Getter_(mthis) => mthis["results"];

}

class BlinkSpeechRecognitionResult {
  static final instance = new BlinkSpeechRecognitionResult();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  isFinal_Getter_(mthis) => mthis["isFinal"];

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

}

class BlinkSpeechRecognitionResultList {
  static final instance = new BlinkSpeechRecognitionResultList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

}

class BlinkSpeechSynthesis extends BlinkEventTarget {
  static final instance = new BlinkSpeechSynthesis();

  cancel_Callback_0_(mthis) => mthis.callMethod("cancel", []);

  getVoices_Callback_0_(mthis) => mthis.callMethod("getVoices", []);

  onvoiceschanged_Getter_(mthis) => mthis["onvoiceschanged"];

  onvoiceschanged_Setter_(mthis, __arg_0) => mthis["onvoiceschanged"] = __arg_0;

  pause_Callback_0_(mthis) => mthis.callMethod("pause", []);

  paused_Getter_(mthis) => mthis["paused"];

  pending_Getter_(mthis) => mthis["pending"];

  resume_Callback_0_(mthis) => mthis.callMethod("resume", []);

  speak_Callback_0_(mthis) => mthis.callMethod("speak", []);

  speak_Callback_1_(mthis, __arg_0) => mthis.callMethod("speak", [__arg_0]);

  speaking_Getter_(mthis) => mthis["speaking"];

}

class BlinkSpeechSynthesisEvent extends BlinkEvent {
  static final instance = new BlinkSpeechSynthesisEvent();

  charIndex_Getter_(mthis) => mthis["charIndex"];

  elapsedTime_Getter_(mthis) => mthis["elapsedTime"];

  name_Getter_(mthis) => mthis["name"];

}

class BlinkSpeechSynthesisUtterance extends BlinkEventTarget {
  static final instance = new BlinkSpeechSynthesisUtterance();

  constructorCallback_0_() => new js.JsObject(js.context["SpeechSynthesisUtterance"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["SpeechSynthesisUtterance"], [__arg_0]);

  lang_Getter_(mthis) => mthis["lang"];

  lang_Setter_(mthis, __arg_0) => mthis["lang"] = __arg_0;

  onboundary_Getter_(mthis) => mthis["onboundary"];

  onboundary_Setter_(mthis, __arg_0) => mthis["onboundary"] = __arg_0;

  onend_Getter_(mthis) => mthis["onend"];

  onend_Setter_(mthis, __arg_0) => mthis["onend"] = __arg_0;

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onmark_Getter_(mthis) => mthis["onmark"];

  onmark_Setter_(mthis, __arg_0) => mthis["onmark"] = __arg_0;

  onpause_Getter_(mthis) => mthis["onpause"];

  onpause_Setter_(mthis, __arg_0) => mthis["onpause"] = __arg_0;

  onresume_Getter_(mthis) => mthis["onresume"];

  onresume_Setter_(mthis, __arg_0) => mthis["onresume"] = __arg_0;

  onstart_Getter_(mthis) => mthis["onstart"];

  onstart_Setter_(mthis, __arg_0) => mthis["onstart"] = __arg_0;

  pitch_Getter_(mthis) => mthis["pitch"];

  pitch_Setter_(mthis, __arg_0) => mthis["pitch"] = __arg_0;

  rate_Getter_(mthis) => mthis["rate"];

  rate_Setter_(mthis, __arg_0) => mthis["rate"] = __arg_0;

  text_Getter_(mthis) => mthis["text"];

  text_Setter_(mthis, __arg_0) => mthis["text"] = __arg_0;

  voice_Getter_(mthis) => mthis["voice"];

  voice_Setter_(mthis, __arg_0) => mthis["voice"] = __arg_0;

  volume_Getter_(mthis) => mthis["volume"];

  volume_Setter_(mthis, __arg_0) => mthis["volume"] = __arg_0;

}

class BlinkSpeechSynthesisVoice {
  static final instance = new BlinkSpeechSynthesisVoice();

  default_Getter_(mthis) => mthis["default"];

  lang_Getter_(mthis) => mthis["lang"];

  localService_Getter_(mthis) => mthis["localService"];

  name_Getter_(mthis) => mthis["name"];

  voiceURI_Getter_(mthis) => mthis["voiceURI"];

}

class BlinkStorage {
  static final instance = new BlinkStorage();

  $__delete___Callback_1_(mthis, __arg_0) => mthis.callMethod("__delete__", [__arg_0]);

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  $__setter___Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("__setter__", [__arg_0, __arg_1]);

  clear_Callback_0_(mthis) => mthis.callMethod("clear", []);

  getItem_Callback_0_(mthis) => mthis.callMethod("getItem", []);

  getItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("getItem", [__arg_0]);

  key_Callback_0_(mthis) => mthis.callMethod("key", []);

  key_Callback_1_(mthis, __arg_0) => mthis.callMethod("key", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

  removeItem_Callback_0_(mthis) => mthis.callMethod("removeItem", []);

  removeItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeItem", [__arg_0]);

  setItem_Callback_0_(mthis) => mthis.callMethod("setItem", []);

  setItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("setItem", [__arg_0]);

  setItem_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setItem", [__arg_0, __arg_1]);

}

class BlinkStorageEvent extends BlinkEvent {
  static final instance = new BlinkStorageEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["StorageEvent"], [__arg_0, __arg_1]);

  initStorageEvent_Callback_0_(mthis) => mthis.callMethod("initStorageEvent", []);

  initStorageEvent_Callback_1_(mthis, __arg_0) => mthis.callMethod("initStorageEvent", [__arg_0]);

  initStorageEvent_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("initStorageEvent", [__arg_0, __arg_1]);

  initStorageEvent_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("initStorageEvent", [__arg_0, __arg_1, __arg_2]);

  initStorageEvent_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("initStorageEvent", [__arg_0, __arg_1, __arg_2, __arg_3]);

  initStorageEvent_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("initStorageEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  initStorageEvent_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("initStorageEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  initStorageEvent_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("initStorageEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  initStorageEvent_Callback_8_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7) => mthis.callMethod("initStorageEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7]);

  key_Getter_(mthis) => mthis["key"];

  newValue_Getter_(mthis) => mthis["newValue"];

  oldValue_Getter_(mthis) => mthis["oldValue"];

  storageArea_Getter_(mthis) => mthis["storageArea"];

  url_Getter_(mthis) => mthis["url"];

}

class BlinkStorageInfo {
  static final instance = new BlinkStorageInfo();

  quota_Getter_(mthis) => mthis["quota"];

  usage_Getter_(mthis) => mthis["usage"];

}

class BlinkStorageQuota {
  static final instance = new BlinkStorageQuota();

  queryInfo_Callback_0_(mthis) => mthis.callMethod("queryInfo", []);

  queryInfo_Callback_1_(mthis, __arg_0) => mthis.callMethod("queryInfo", [__arg_0]);

  requestPersistentQuota_Callback_0_(mthis) => mthis.callMethod("requestPersistentQuota", []);

  requestPersistentQuota_Callback_1_(mthis, __arg_0) => mthis.callMethod("requestPersistentQuota", [__arg_0]);

  supportedTypes_Getter_(mthis) => mthis["supportedTypes"];

}

class BlinkStream {
  static final instance = new BlinkStream();

  type_Getter_(mthis) => mthis["type"];

}

class BlinkStyleMedia {
  static final instance = new BlinkStyleMedia();

  matchMedium_Callback_0_(mthis) => mthis.callMethod("matchMedium", []);

  matchMedium_Callback_1_(mthis, __arg_0) => mthis.callMethod("matchMedium", [__arg_0]);

  type_Getter_(mthis) => mthis["type"];

}

class BlinkStyleSheet {
  static final instance = new BlinkStyleSheet();

  disabled_Getter_(mthis) => mthis["disabled"];

  disabled_Setter_(mthis, __arg_0) => mthis["disabled"] = __arg_0;

  href_Getter_(mthis) => mthis["href"];

  media_Getter_(mthis) => mthis["media"];

  ownerNode_Getter_(mthis) => mthis["ownerNode"];

  parentStyleSheet_Getter_(mthis) => mthis["parentStyleSheet"];

  title_Getter_(mthis) => mthis["title"];

  type_Getter_(mthis) => mthis["type"];

}

class BlinkStyleSheetList {
  static final instance = new BlinkStyleSheetList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

}

class BlinkSubtleCrypto {
  static final instance = new BlinkSubtleCrypto();

  decrypt_Callback_1_(mthis, __arg_0) => mthis.callMethod("decrypt", [__arg_0]);

  decrypt_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("decrypt", [__arg_0, __arg_1]);

  decrypt_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("decrypt", [__arg_0, __arg_1, __arg_2]);

  digest_Callback_0_(mthis) => mthis.callMethod("digest", []);

  digest_Callback_1_(mthis, __arg_0) => mthis.callMethod("digest", [__arg_0]);

  digest_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("digest", [__arg_0, __arg_1]);

  encrypt_Callback_1_(mthis, __arg_0) => mthis.callMethod("encrypt", [__arg_0]);

  encrypt_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("encrypt", [__arg_0, __arg_1]);

  encrypt_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("encrypt", [__arg_0, __arg_1, __arg_2]);

  exportKey_Callback_0_(mthis) => mthis.callMethod("exportKey", []);

  exportKey_Callback_1_(mthis, __arg_0) => mthis.callMethod("exportKey", [__arg_0]);

  exportKey_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("exportKey", [__arg_0, __arg_1]);

  generateKey_Callback_1_(mthis, __arg_0) => mthis.callMethod("generateKey", [__arg_0]);

  generateKey_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("generateKey", [__arg_0, __arg_1]);

  generateKey_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("generateKey", [__arg_0, __arg_1, __arg_2]);

  importKey_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("importKey", [__arg_0, __arg_1, __arg_2]);

  importKey_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("importKey", [__arg_0, __arg_1, __arg_2, __arg_3]);

  importKey_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("importKey", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  sign_Callback_1_(mthis, __arg_0) => mthis.callMethod("sign", [__arg_0]);

  sign_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("sign", [__arg_0, __arg_1]);

  sign_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("sign", [__arg_0, __arg_1, __arg_2]);

  unwrapKey_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("unwrapKey", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  unwrapKey_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("unwrapKey", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  unwrapKey_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("unwrapKey", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  verify_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("verify", [__arg_0, __arg_1]);

  verify_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("verify", [__arg_0, __arg_1, __arg_2]);

  verify_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("verify", [__arg_0, __arg_1, __arg_2, __arg_3]);

  wrapKey_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("wrapKey", [__arg_0, __arg_1]);

  wrapKey_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("wrapKey", [__arg_0, __arg_1, __arg_2]);

  wrapKey_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("wrapKey", [__arg_0, __arg_1, __arg_2, __arg_3]);

}

class BlinkText extends BlinkCharacterData {
  static final instance = new BlinkText();

  constructorCallback_0_() => new js.JsObject(js.context["Text"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["Text"], [__arg_0]);

  getDestinationInsertionPoints_Callback_0_(mthis) => mthis.callMethod("getDestinationInsertionPoints", []);

  replaceWholeText_Callback_0_(mthis) => mthis.callMethod("replaceWholeText", []);

  replaceWholeText_Callback_1_(mthis, __arg_0) => mthis.callMethod("replaceWholeText", [__arg_0]);

  splitText_Callback_0_(mthis) => mthis.callMethod("splitText", []);

  splitText_Callback_1_(mthis, __arg_0) => mthis.callMethod("splitText", [__arg_0]);

  wholeText_Getter_(mthis) => mthis["wholeText"];

}

class BlinkTextDecoder {
  static final instance = new BlinkTextDecoder();

  constructorCallback_0_() => new js.JsObject(js.context["TextDecoder"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["TextDecoder"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["TextDecoder"], [__arg_0, __arg_1]);

  decode_Callback_0_(mthis) => mthis.callMethod("decode", []);

  decode_Callback_1_(mthis, __arg_0) => mthis.callMethod("decode", [__arg_0]);

  decode_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("decode", [__arg_0, __arg_1]);

  encoding_Getter_(mthis) => mthis["encoding"];

  fatal_Getter_(mthis) => mthis["fatal"];

  ignoreBOM_Getter_(mthis) => mthis["ignoreBOM"];

}

class BlinkTextEncoder {
  static final instance = new BlinkTextEncoder();

  constructorCallback_0_() => new js.JsObject(js.context["TextEncoder"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["TextEncoder"], [__arg_0]);

  encode_Callback_0_(mthis) => mthis.callMethod("encode", []);

  encode_Callback_1_(mthis, __arg_0) => mthis.callMethod("encode", [__arg_0]);

  encoding_Getter_(mthis) => mthis["encoding"];

}

class BlinkTextEvent extends BlinkUIEvent {
  static final instance = new BlinkTextEvent();

  data_Getter_(mthis) => mthis["data"];

  initTextEvent_Callback_0_(mthis) => mthis.callMethod("initTextEvent", []);

  initTextEvent_Callback_1_(mthis, __arg_0) => mthis.callMethod("initTextEvent", [__arg_0]);

  initTextEvent_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("initTextEvent", [__arg_0, __arg_1]);

  initTextEvent_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("initTextEvent", [__arg_0, __arg_1, __arg_2]);

  initTextEvent_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("initTextEvent", [__arg_0, __arg_1, __arg_2, __arg_3]);

  initTextEvent_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("initTextEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

}

class BlinkTextMetrics {
  static final instance = new BlinkTextMetrics();

  actualBoundingBoxAscent_Getter_(mthis) => mthis["actualBoundingBoxAscent"];

  actualBoundingBoxDescent_Getter_(mthis) => mthis["actualBoundingBoxDescent"];

  actualBoundingBoxLeft_Getter_(mthis) => mthis["actualBoundingBoxLeft"];

  actualBoundingBoxRight_Getter_(mthis) => mthis["actualBoundingBoxRight"];

  alphabeticBaseline_Getter_(mthis) => mthis["alphabeticBaseline"];

  emHeightAscent_Getter_(mthis) => mthis["emHeightAscent"];

  emHeightDescent_Getter_(mthis) => mthis["emHeightDescent"];

  fontBoundingBoxAscent_Getter_(mthis) => mthis["fontBoundingBoxAscent"];

  fontBoundingBoxDescent_Getter_(mthis) => mthis["fontBoundingBoxDescent"];

  hangingBaseline_Getter_(mthis) => mthis["hangingBaseline"];

  ideographicBaseline_Getter_(mthis) => mthis["ideographicBaseline"];

  width_Getter_(mthis) => mthis["width"];

}

class BlinkTextTrack extends BlinkEventTarget {
  static final instance = new BlinkTextTrack();

  activeCues_Getter_(mthis) => mthis["activeCues"];

  addCue_Callback_0_(mthis) => mthis.callMethod("addCue", []);

  addCue_Callback_1_(mthis, __arg_0) => mthis.callMethod("addCue", [__arg_0]);

  addRegion_Callback_0_(mthis) => mthis.callMethod("addRegion", []);

  addRegion_Callback_1_(mthis, __arg_0) => mthis.callMethod("addRegion", [__arg_0]);

  cues_Getter_(mthis) => mthis["cues"];

  id_Getter_(mthis) => mthis["id"];

  kind_Getter_(mthis) => mthis["kind"];

  label_Getter_(mthis) => mthis["label"];

  language_Getter_(mthis) => mthis["language"];

  mode_Getter_(mthis) => mthis["mode"];

  mode_Setter_(mthis, __arg_0) => mthis["mode"] = __arg_0;

  oncuechange_Getter_(mthis) => mthis["oncuechange"];

  oncuechange_Setter_(mthis, __arg_0) => mthis["oncuechange"] = __arg_0;

  regions_Getter_(mthis) => mthis["regions"];

  removeCue_Callback_0_(mthis) => mthis.callMethod("removeCue", []);

  removeCue_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeCue", [__arg_0]);

  removeRegion_Callback_0_(mthis) => mthis.callMethod("removeRegion", []);

  removeRegion_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeRegion", [__arg_0]);

}

class BlinkTextTrackCue extends BlinkEventTarget {
  static final instance = new BlinkTextTrackCue();

  endTime_Getter_(mthis) => mthis["endTime"];

  endTime_Setter_(mthis, __arg_0) => mthis["endTime"] = __arg_0;

  id_Getter_(mthis) => mthis["id"];

  id_Setter_(mthis, __arg_0) => mthis["id"] = __arg_0;

  onenter_Getter_(mthis) => mthis["onenter"];

  onenter_Setter_(mthis, __arg_0) => mthis["onenter"] = __arg_0;

  onexit_Getter_(mthis) => mthis["onexit"];

  onexit_Setter_(mthis, __arg_0) => mthis["onexit"] = __arg_0;

  pauseOnExit_Getter_(mthis) => mthis["pauseOnExit"];

  pauseOnExit_Setter_(mthis, __arg_0) => mthis["pauseOnExit"] = __arg_0;

  startTime_Getter_(mthis) => mthis["startTime"];

  startTime_Setter_(mthis, __arg_0) => mthis["startTime"] = __arg_0;

  track_Getter_(mthis) => mthis["track"];

}

class BlinkTextTrackCueList {
  static final instance = new BlinkTextTrackCueList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  getCueById_Callback_0_(mthis) => mthis.callMethod("getCueById", []);

  getCueById_Callback_1_(mthis, __arg_0) => mthis.callMethod("getCueById", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

}

class BlinkTextTrackList extends BlinkEventTarget {
  static final instance = new BlinkTextTrackList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  getTrackById_Callback_0_(mthis) => mthis.callMethod("getTrackById", []);

  getTrackById_Callback_1_(mthis, __arg_0) => mthis.callMethod("getTrackById", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

  onaddtrack_Getter_(mthis) => mthis["onaddtrack"];

  onaddtrack_Setter_(mthis, __arg_0) => mthis["onaddtrack"] = __arg_0;

  onchange_Getter_(mthis) => mthis["onchange"];

  onchange_Setter_(mthis, __arg_0) => mthis["onchange"] = __arg_0;

  onremovetrack_Getter_(mthis) => mthis["onremovetrack"];

  onremovetrack_Setter_(mthis, __arg_0) => mthis["onremovetrack"] = __arg_0;

}

class BlinkTimeRanges {
  static final instance = new BlinkTimeRanges();

  end_Callback_0_(mthis) => mthis.callMethod("end", []);

  end_Callback_1_(mthis, __arg_0) => mthis.callMethod("end", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

  start_Callback_0_(mthis) => mthis.callMethod("start", []);

  start_Callback_1_(mthis, __arg_0) => mthis.callMethod("start", [__arg_0]);

}

class BlinkTiming {
  static final instance = new BlinkTiming();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  $__setter___Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("__setter__", [__arg_0, __arg_1]);

  delay_Getter_(mthis) => mthis["delay"];

  delay_Setter_(mthis, __arg_0) => mthis["delay"] = __arg_0;

  direction_Getter_(mthis) => mthis["direction"];

  direction_Setter_(mthis, __arg_0) => mthis["direction"] = __arg_0;

  easing_Getter_(mthis) => mthis["easing"];

  easing_Setter_(mthis, __arg_0) => mthis["easing"] = __arg_0;

  endDelay_Getter_(mthis) => mthis["endDelay"];

  endDelay_Setter_(mthis, __arg_0) => mthis["endDelay"] = __arg_0;

  fill_Getter_(mthis) => mthis["fill"];

  fill_Setter_(mthis, __arg_0) => mthis["fill"] = __arg_0;

  iterationStart_Getter_(mthis) => mthis["iterationStart"];

  iterationStart_Setter_(mthis, __arg_0) => mthis["iterationStart"] = __arg_0;

  iterations_Getter_(mthis) => mthis["iterations"];

  iterations_Setter_(mthis, __arg_0) => mthis["iterations"] = __arg_0;

  playbackRate_Getter_(mthis) => mthis["playbackRate"];

  playbackRate_Setter_(mthis, __arg_0) => mthis["playbackRate"] = __arg_0;

}

class BlinkTouch {
  static final instance = new BlinkTouch();

  clientX_Getter_(mthis) => mthis["clientX"];

  clientY_Getter_(mthis) => mthis["clientY"];

  force_Getter_(mthis) => mthis["force"];

  identifier_Getter_(mthis) => mthis["identifier"];

  pageX_Getter_(mthis) => mthis["pageX"];

  pageY_Getter_(mthis) => mthis["pageY"];

  radiusX_Getter_(mthis) => mthis["radiusX"];

  radiusY_Getter_(mthis) => mthis["radiusY"];

  screenX_Getter_(mthis) => mthis["screenX"];

  screenY_Getter_(mthis) => mthis["screenY"];

  target_Getter_(mthis) => mthis["target"];

  webkitForce_Getter_(mthis) => mthis["webkitForce"];

  webkitRadiusX_Getter_(mthis) => mthis["webkitRadiusX"];

  webkitRadiusY_Getter_(mthis) => mthis["webkitRadiusY"];

  webkitRotationAngle_Getter_(mthis) => mthis["webkitRotationAngle"];

}

class BlinkTouchEvent extends BlinkUIEvent {
  static final instance = new BlinkTouchEvent();

  altKey_Getter_(mthis) => mthis["altKey"];

  changedTouches_Getter_(mthis) => mthis["changedTouches"];

  ctrlKey_Getter_(mthis) => mthis["ctrlKey"];

  initTouchEvent_Callback_0_(mthis) => mthis.callMethod("initTouchEvent", []);

  initTouchEvent_Callback_1_(mthis, __arg_0) => mthis.callMethod("initTouchEvent", [__arg_0]);

  initTouchEvent_Callback_10_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9) => mthis.callMethod("initTouchEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9]);

  initTouchEvent_Callback_11_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9, __arg_10) => mthis.callMethod("initTouchEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9, __arg_10]);

  initTouchEvent_Callback_12_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9, __arg_10, __arg_11) => mthis.callMethod("initTouchEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9, __arg_10, __arg_11]);

  initTouchEvent_Callback_13_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9, __arg_10, __arg_11, __arg_12) => mthis.callMethod("initTouchEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8, __arg_9, __arg_10, __arg_11, __arg_12]);

  initTouchEvent_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("initTouchEvent", [__arg_0, __arg_1]);

  initTouchEvent_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("initTouchEvent", [__arg_0, __arg_1, __arg_2]);

  initTouchEvent_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("initTouchEvent", [__arg_0, __arg_1, __arg_2, __arg_3]);

  initTouchEvent_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("initTouchEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  initTouchEvent_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("initTouchEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  initTouchEvent_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("initTouchEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  initTouchEvent_Callback_8_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7) => mthis.callMethod("initTouchEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7]);

  initTouchEvent_Callback_9_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8) => mthis.callMethod("initTouchEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8]);

  metaKey_Getter_(mthis) => mthis["metaKey"];

  shiftKey_Getter_(mthis) => mthis["shiftKey"];

  targetTouches_Getter_(mthis) => mthis["targetTouches"];

  touches_Getter_(mthis) => mthis["touches"];

}

class BlinkTouchList {
  static final instance = new BlinkTouchList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

}

class BlinkTrackEvent extends BlinkEvent {
  static final instance = new BlinkTrackEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["TrackEvent"], [__arg_0, __arg_1]);

  track_Getter_(mthis) => mthis["track"];

}

class BlinkTransitionEvent extends BlinkEvent {
  static final instance = new BlinkTransitionEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["TransitionEvent"], [__arg_0, __arg_1]);

  elapsedTime_Getter_(mthis) => mthis["elapsedTime"];

  propertyName_Getter_(mthis) => mthis["propertyName"];

  pseudoElement_Getter_(mthis) => mthis["pseudoElement"];

}

class BlinkTreeWalker {
  static final instance = new BlinkTreeWalker();

  currentNode_Getter_(mthis) => mthis["currentNode"];

  currentNode_Setter_(mthis, __arg_0) => mthis["currentNode"] = __arg_0;

  expandEntityReferences_Getter_(mthis) => mthis["expandEntityReferences"];

  filter_Getter_(mthis) => mthis["filter"];

  firstChild_Callback_0_(mthis) => mthis.callMethod("firstChild", []);

  lastChild_Callback_0_(mthis) => mthis.callMethod("lastChild", []);

  nextNode_Callback_0_(mthis) => mthis.callMethod("nextNode", []);

  nextSibling_Callback_0_(mthis) => mthis.callMethod("nextSibling", []);

  parentNode_Callback_0_(mthis) => mthis.callMethod("parentNode", []);

  previousNode_Callback_0_(mthis) => mthis.callMethod("previousNode", []);

  previousSibling_Callback_0_(mthis) => mthis.callMethod("previousSibling", []);

  root_Getter_(mthis) => mthis["root"];

  whatToShow_Getter_(mthis) => mthis["whatToShow"];

}

class BlinkUIEvent extends BlinkEvent {
  static final instance = new BlinkUIEvent();

  charCode_Getter_(mthis) => mthis["charCode"];

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["UIEvent"], [__arg_0, __arg_1]);

  detail_Getter_(mthis) => mthis["detail"];

  initUIEvent_Callback_0_(mthis) => mthis.callMethod("initUIEvent", []);

  initUIEvent_Callback_1_(mthis, __arg_0) => mthis.callMethod("initUIEvent", [__arg_0]);

  initUIEvent_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("initUIEvent", [__arg_0, __arg_1]);

  initUIEvent_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("initUIEvent", [__arg_0, __arg_1, __arg_2]);

  initUIEvent_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("initUIEvent", [__arg_0, __arg_1, __arg_2, __arg_3]);

  initUIEvent_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("initUIEvent", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  keyCode_Getter_(mthis) => mthis["keyCode"];

  layerX_Getter_(mthis) => mthis["layerX"];

  layerY_Getter_(mthis) => mthis["layerY"];

  pageX_Getter_(mthis) => mthis["pageX"];

  pageY_Getter_(mthis) => mthis["pageY"];

  view_Getter_(mthis) => mthis["view"];

  which_Getter_(mthis) => mthis["which"];

}

class BlinkURL {
  static final instance = new BlinkURL();

  constructorCallback_0_() => new js.JsObject(js.context["URL"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["URL"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["URL"], [__arg_0, __arg_1]);

  createObjectURL_Callback_0_() => js.context["URL"].callMethod("createObjectURL", []);

  createObjectURL_Callback_1_(__arg_0) => js.context["URL"].callMethod("createObjectURL", [__arg_0]);

  hash_Getter_(mthis) => mthis["hash"];

  hash_Setter_(mthis, __arg_0) => mthis["hash"] = __arg_0;

  host_Getter_(mthis) => mthis["host"];

  host_Setter_(mthis, __arg_0) => mthis["host"] = __arg_0;

  hostname_Getter_(mthis) => mthis["hostname"];

  hostname_Setter_(mthis, __arg_0) => mthis["hostname"] = __arg_0;

  href_Getter_(mthis) => mthis["href"];

  href_Setter_(mthis, __arg_0) => mthis["href"] = __arg_0;

  origin_Getter_(mthis) => mthis["origin"];

  password_Getter_(mthis) => mthis["password"];

  password_Setter_(mthis, __arg_0) => mthis["password"] = __arg_0;

  pathname_Getter_(mthis) => mthis["pathname"];

  pathname_Setter_(mthis, __arg_0) => mthis["pathname"] = __arg_0;

  port_Getter_(mthis) => mthis["port"];

  port_Setter_(mthis, __arg_0) => mthis["port"] = __arg_0;

  protocol_Getter_(mthis) => mthis["protocol"];

  protocol_Setter_(mthis, __arg_0) => mthis["protocol"] = __arg_0;

  revokeObjectURL_Callback_0_() => js.context["URL"].callMethod("revokeObjectURL", []);

  revokeObjectURL_Callback_1_(__arg_0) => js.context["URL"].callMethod("revokeObjectURL", [__arg_0]);

  search_Getter_(mthis) => mthis["search"];

  search_Setter_(mthis, __arg_0) => mthis["search"] = __arg_0;

  toString_Callback_0_(mthis) => mthis.callMethod("toString", []);

  username_Getter_(mthis) => mthis["username"];

  username_Setter_(mthis, __arg_0) => mthis["username"] = __arg_0;

}

class BlinkVTTCue extends BlinkTextTrackCue {
  static final instance = new BlinkVTTCue();

  align_Getter_(mthis) => mthis["align"];

  align_Setter_(mthis, __arg_0) => mthis["align"] = __arg_0;

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["VTTCue"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["VTTCue"], [__arg_0, __arg_1]);

  constructorCallback_3_(__arg_0, __arg_1, __arg_2) => new js.JsObject(js.context["VTTCue"], [__arg_0, __arg_1, __arg_2]);

  getCueAsHTML_Callback_0_(mthis) => mthis.callMethod("getCueAsHTML", []);

  line_Getter_(mthis) => mthis["line"];

  line_Setter_(mthis, __arg_0) => mthis["line"] = __arg_0;

  position_Getter_(mthis) => mthis["position"];

  position_Setter_(mthis, __arg_0) => mthis["position"] = __arg_0;

  regionId_Getter_(mthis) => mthis["regionId"];

  regionId_Setter_(mthis, __arg_0) => mthis["regionId"] = __arg_0;

  size_Getter_(mthis) => mthis["size"];

  size_Setter_(mthis, __arg_0) => mthis["size"] = __arg_0;

  snapToLines_Getter_(mthis) => mthis["snapToLines"];

  snapToLines_Setter_(mthis, __arg_0) => mthis["snapToLines"] = __arg_0;

  text_Getter_(mthis) => mthis["text"];

  text_Setter_(mthis, __arg_0) => mthis["text"] = __arg_0;

  vertical_Getter_(mthis) => mthis["vertical"];

  vertical_Setter_(mthis, __arg_0) => mthis["vertical"] = __arg_0;

}

class BlinkVTTRegion {
  static final instance = new BlinkVTTRegion();

  constructorCallback_0_() => new js.JsObject(js.context["VTTRegion"], []);

  height_Getter_(mthis) => mthis["height"];

  height_Setter_(mthis, __arg_0) => mthis["height"] = __arg_0;

  id_Getter_(mthis) => mthis["id"];

  id_Setter_(mthis, __arg_0) => mthis["id"] = __arg_0;

  regionAnchorX_Getter_(mthis) => mthis["regionAnchorX"];

  regionAnchorX_Setter_(mthis, __arg_0) => mthis["regionAnchorX"] = __arg_0;

  regionAnchorY_Getter_(mthis) => mthis["regionAnchorY"];

  regionAnchorY_Setter_(mthis, __arg_0) => mthis["regionAnchorY"] = __arg_0;

  scroll_Getter_(mthis) => mthis["scroll"];

  scroll_Setter_(mthis, __arg_0) => mthis["scroll"] = __arg_0;

  track_Getter_(mthis) => mthis["track"];

  viewportAnchorX_Getter_(mthis) => mthis["viewportAnchorX"];

  viewportAnchorX_Setter_(mthis, __arg_0) => mthis["viewportAnchorX"] = __arg_0;

  viewportAnchorY_Getter_(mthis) => mthis["viewportAnchorY"];

  viewportAnchorY_Setter_(mthis, __arg_0) => mthis["viewportAnchorY"] = __arg_0;

  width_Getter_(mthis) => mthis["width"];

  width_Setter_(mthis, __arg_0) => mthis["width"] = __arg_0;

}

class BlinkVTTRegionList {
  static final instance = new BlinkVTTRegionList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  getRegionById_Callback_0_(mthis) => mthis.callMethod("getRegionById", []);

  getRegionById_Callback_1_(mthis, __arg_0) => mthis.callMethod("getRegionById", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

}

class BlinkValidityState {
  static final instance = new BlinkValidityState();

  badInput_Getter_(mthis) => mthis["badInput"];

  customError_Getter_(mthis) => mthis["customError"];

  patternMismatch_Getter_(mthis) => mthis["patternMismatch"];

  rangeOverflow_Getter_(mthis) => mthis["rangeOverflow"];

  rangeUnderflow_Getter_(mthis) => mthis["rangeUnderflow"];

  stepMismatch_Getter_(mthis) => mthis["stepMismatch"];

  tooLong_Getter_(mthis) => mthis["tooLong"];

  typeMismatch_Getter_(mthis) => mthis["typeMismatch"];

  valid_Getter_(mthis) => mthis["valid"];

  valueMissing_Getter_(mthis) => mthis["valueMissing"];

}

class BlinkVideoPlaybackQuality {
  static final instance = new BlinkVideoPlaybackQuality();

  corruptedVideoFrames_Getter_(mthis) => mthis["corruptedVideoFrames"];

  creationTime_Getter_(mthis) => mthis["creationTime"];

  droppedVideoFrames_Getter_(mthis) => mthis["droppedVideoFrames"];

  totalVideoFrames_Getter_(mthis) => mthis["totalVideoFrames"];

}

class BlinkVideoTrack {
  static final instance = new BlinkVideoTrack();

  id_Getter_(mthis) => mthis["id"];

  kind_Getter_(mthis) => mthis["kind"];

  label_Getter_(mthis) => mthis["label"];

  language_Getter_(mthis) => mthis["language"];

  selected_Getter_(mthis) => mthis["selected"];

  selected_Setter_(mthis, __arg_0) => mthis["selected"] = __arg_0;

}

class BlinkVideoTrackList extends BlinkEventTarget {
  static final instance = new BlinkVideoTrackList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  getTrackById_Callback_0_(mthis) => mthis.callMethod("getTrackById", []);

  getTrackById_Callback_1_(mthis, __arg_0) => mthis.callMethod("getTrackById", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

  onaddtrack_Getter_(mthis) => mthis["onaddtrack"];

  onaddtrack_Setter_(mthis, __arg_0) => mthis["onaddtrack"] = __arg_0;

  onchange_Getter_(mthis) => mthis["onchange"];

  onchange_Setter_(mthis, __arg_0) => mthis["onchange"] = __arg_0;

  onremovetrack_Getter_(mthis) => mthis["onremovetrack"];

  onremovetrack_Setter_(mthis, __arg_0) => mthis["onremovetrack"] = __arg_0;

  selectedIndex_Getter_(mthis) => mthis["selectedIndex"];

}

class BlinkWaveShaperNode extends BlinkAudioNode {
  static final instance = new BlinkWaveShaperNode();

  curve_Getter_(mthis) => mthis["curve"];

  curve_Setter_(mthis, __arg_0) => mthis["curve"] = __arg_0;

  oversample_Getter_(mthis) => mthis["oversample"];

  oversample_Setter_(mthis, __arg_0) => mthis["oversample"] = __arg_0;

}

class BlinkWebGLActiveInfo {
  static final instance = new BlinkWebGLActiveInfo();

  name_Getter_(mthis) => mthis["name"];

  size_Getter_(mthis) => mthis["size"];

  type_Getter_(mthis) => mthis["type"];

}

class BlinkWebGLBuffer {
  static final instance = new BlinkWebGLBuffer();

}

class BlinkWebGLCompressedTextureATC {
  static final instance = new BlinkWebGLCompressedTextureATC();

}

class BlinkWebGLCompressedTextureETC1 {
  static final instance = new BlinkWebGLCompressedTextureETC1();

}

class BlinkWebGLCompressedTexturePVRTC {
  static final instance = new BlinkWebGLCompressedTexturePVRTC();

}

class BlinkWebGLCompressedTextureS3TC {
  static final instance = new BlinkWebGLCompressedTextureS3TC();

}

class BlinkWebGLContextAttributes {
  static final instance = new BlinkWebGLContextAttributes();

  alpha_Getter_(mthis) => mthis["alpha"];

  alpha_Setter_(mthis, __arg_0) => mthis["alpha"] = __arg_0;

  antialias_Getter_(mthis) => mthis["antialias"];

  antialias_Setter_(mthis, __arg_0) => mthis["antialias"] = __arg_0;

  depth_Getter_(mthis) => mthis["depth"];

  depth_Setter_(mthis, __arg_0) => mthis["depth"] = __arg_0;

  failIfMajorPerformanceCaveat_Getter_(mthis) => mthis["failIfMajorPerformanceCaveat"];

  failIfMajorPerformanceCaveat_Setter_(mthis, __arg_0) => mthis["failIfMajorPerformanceCaveat"] = __arg_0;

  premultipliedAlpha_Getter_(mthis) => mthis["premultipliedAlpha"];

  premultipliedAlpha_Setter_(mthis, __arg_0) => mthis["premultipliedAlpha"] = __arg_0;

  preserveDrawingBuffer_Getter_(mthis) => mthis["preserveDrawingBuffer"];

  preserveDrawingBuffer_Setter_(mthis, __arg_0) => mthis["preserveDrawingBuffer"] = __arg_0;

  stencil_Getter_(mthis) => mthis["stencil"];

  stencil_Setter_(mthis, __arg_0) => mthis["stencil"] = __arg_0;

}

class BlinkWebGLContextEvent extends BlinkEvent {
  static final instance = new BlinkWebGLContextEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["WebGLContextEvent"], [__arg_0, __arg_1]);

  statusMessage_Getter_(mthis) => mthis["statusMessage"];

}

class BlinkWebGLDebugRendererInfo {
  static final instance = new BlinkWebGLDebugRendererInfo();

}

class BlinkWebGLDebugShaders {
  static final instance = new BlinkWebGLDebugShaders();

  getTranslatedShaderSource_Callback_0_(mthis) => mthis.callMethod("getTranslatedShaderSource", []);

  getTranslatedShaderSource_Callback_1_(mthis, __arg_0) => mthis.callMethod("getTranslatedShaderSource", [__arg_0]);

}

class BlinkWebGLDepthTexture {
  static final instance = new BlinkWebGLDepthTexture();

}

class BlinkWebGLDrawBuffers {
  static final instance = new BlinkWebGLDrawBuffers();

  drawBuffersWEBGL_Callback_0_(mthis) => mthis.callMethod("drawBuffersWEBGL", []);

  drawBuffersWEBGL_Callback_1_(mthis, __arg_0) => mthis.callMethod("drawBuffersWEBGL", [__arg_0]);

}

class BlinkWebGLFramebuffer {
  static final instance = new BlinkWebGLFramebuffer();

}

class BlinkWebGLLoseContext {
  static final instance = new BlinkWebGLLoseContext();

  loseContext_Callback_0_(mthis) => mthis.callMethod("loseContext", []);

  restoreContext_Callback_0_(mthis) => mthis.callMethod("restoreContext", []);

}

class BlinkWebGLProgram {
  static final instance = new BlinkWebGLProgram();

}

class BlinkWebGLRenderbuffer {
  static final instance = new BlinkWebGLRenderbuffer();

}

class BlinkWebGLRenderingContext {
  static final instance = new BlinkWebGLRenderingContext();

  activeTexture_Callback_0_(mthis) => mthis.callMethod("activeTexture", []);

  activeTexture_Callback_1_(mthis, __arg_0) => mthis.callMethod("activeTexture", [__arg_0]);

  attachShader_Callback_0_(mthis) => mthis.callMethod("attachShader", []);

  attachShader_Callback_1_(mthis, __arg_0) => mthis.callMethod("attachShader", [__arg_0]);

  attachShader_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("attachShader", [__arg_0, __arg_1]);

  bindAttribLocation_Callback_1_(mthis, __arg_0) => mthis.callMethod("bindAttribLocation", [__arg_0]);

  bindAttribLocation_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("bindAttribLocation", [__arg_0, __arg_1]);

  bindAttribLocation_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("bindAttribLocation", [__arg_0, __arg_1, __arg_2]);

  bindBuffer_Callback_0_(mthis) => mthis.callMethod("bindBuffer", []);

  bindBuffer_Callback_1_(mthis, __arg_0) => mthis.callMethod("bindBuffer", [__arg_0]);

  bindBuffer_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("bindBuffer", [__arg_0, __arg_1]);

  bindFramebuffer_Callback_0_(mthis) => mthis.callMethod("bindFramebuffer", []);

  bindFramebuffer_Callback_1_(mthis, __arg_0) => mthis.callMethod("bindFramebuffer", [__arg_0]);

  bindFramebuffer_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("bindFramebuffer", [__arg_0, __arg_1]);

  bindRenderbuffer_Callback_0_(mthis) => mthis.callMethod("bindRenderbuffer", []);

  bindRenderbuffer_Callback_1_(mthis, __arg_0) => mthis.callMethod("bindRenderbuffer", [__arg_0]);

  bindRenderbuffer_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("bindRenderbuffer", [__arg_0, __arg_1]);

  bindTexture_Callback_0_(mthis) => mthis.callMethod("bindTexture", []);

  bindTexture_Callback_1_(mthis, __arg_0) => mthis.callMethod("bindTexture", [__arg_0]);

  bindTexture_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("bindTexture", [__arg_0, __arg_1]);

  blendColor_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("blendColor", [__arg_0, __arg_1]);

  blendColor_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("blendColor", [__arg_0, __arg_1, __arg_2]);

  blendColor_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("blendColor", [__arg_0, __arg_1, __arg_2, __arg_3]);

  blendEquationSeparate_Callback_0_(mthis) => mthis.callMethod("blendEquationSeparate", []);

  blendEquationSeparate_Callback_1_(mthis, __arg_0) => mthis.callMethod("blendEquationSeparate", [__arg_0]);

  blendEquationSeparate_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("blendEquationSeparate", [__arg_0, __arg_1]);

  blendEquation_Callback_0_(mthis) => mthis.callMethod("blendEquation", []);

  blendEquation_Callback_1_(mthis, __arg_0) => mthis.callMethod("blendEquation", [__arg_0]);

  blendFuncSeparate_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("blendFuncSeparate", [__arg_0, __arg_1]);

  blendFuncSeparate_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("blendFuncSeparate", [__arg_0, __arg_1, __arg_2]);

  blendFuncSeparate_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("blendFuncSeparate", [__arg_0, __arg_1, __arg_2, __arg_3]);

  blendFunc_Callback_0_(mthis) => mthis.callMethod("blendFunc", []);

  blendFunc_Callback_1_(mthis, __arg_0) => mthis.callMethod("blendFunc", [__arg_0]);

  blendFunc_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("blendFunc", [__arg_0, __arg_1]);

  bufferData_Callback_1_(mthis, __arg_0) => mthis.callMethod("bufferData", [__arg_0]);

  bufferData_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("bufferData", [__arg_0, __arg_1]);

  bufferData_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("bufferData", [__arg_0, __arg_1, __arg_2]);

  bufferSubData_Callback_1_(mthis, __arg_0) => mthis.callMethod("bufferSubData", [__arg_0]);

  bufferSubData_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("bufferSubData", [__arg_0, __arg_1]);

  bufferSubData_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("bufferSubData", [__arg_0, __arg_1, __arg_2]);

  canvas_Getter_(mthis) => mthis["canvas"];

  checkFramebufferStatus_Callback_0_(mthis) => mthis.callMethod("checkFramebufferStatus", []);

  checkFramebufferStatus_Callback_1_(mthis, __arg_0) => mthis.callMethod("checkFramebufferStatus", [__arg_0]);

  clearColor_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("clearColor", [__arg_0, __arg_1]);

  clearColor_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("clearColor", [__arg_0, __arg_1, __arg_2]);

  clearColor_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("clearColor", [__arg_0, __arg_1, __arg_2, __arg_3]);

  clearDepth_Callback_0_(mthis) => mthis.callMethod("clearDepth", []);

  clearDepth_Callback_1_(mthis, __arg_0) => mthis.callMethod("clearDepth", [__arg_0]);

  clearStencil_Callback_0_(mthis) => mthis.callMethod("clearStencil", []);

  clearStencil_Callback_1_(mthis, __arg_0) => mthis.callMethod("clearStencil", [__arg_0]);

  clear_Callback_0_(mthis) => mthis.callMethod("clear", []);

  clear_Callback_1_(mthis, __arg_0) => mthis.callMethod("clear", [__arg_0]);

  colorMask_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("colorMask", [__arg_0, __arg_1]);

  colorMask_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("colorMask", [__arg_0, __arg_1, __arg_2]);

  colorMask_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("colorMask", [__arg_0, __arg_1, __arg_2, __arg_3]);

  compileShader_Callback_0_(mthis) => mthis.callMethod("compileShader", []);

  compileShader_Callback_1_(mthis, __arg_0) => mthis.callMethod("compileShader", [__arg_0]);

  compressedTexImage2D_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("compressedTexImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  compressedTexImage2D_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("compressedTexImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  compressedTexImage2D_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("compressedTexImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  compressedTexSubImage2D_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("compressedTexSubImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  compressedTexSubImage2D_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("compressedTexSubImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  compressedTexSubImage2D_Callback_8_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7) => mthis.callMethod("compressedTexSubImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7]);

  copyTexImage2D_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("copyTexImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  copyTexImage2D_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("copyTexImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  copyTexImage2D_Callback_8_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7) => mthis.callMethod("copyTexImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7]);

  copyTexSubImage2D_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("copyTexSubImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  copyTexSubImage2D_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("copyTexSubImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  copyTexSubImage2D_Callback_8_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7) => mthis.callMethod("copyTexSubImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7]);

  createBuffer_Callback_0_(mthis) => mthis.callMethod("createBuffer", []);

  createFramebuffer_Callback_0_(mthis) => mthis.callMethod("createFramebuffer", []);

  createProgram_Callback_0_(mthis) => mthis.callMethod("createProgram", []);

  createRenderbuffer_Callback_0_(mthis) => mthis.callMethod("createRenderbuffer", []);

  createShader_Callback_0_(mthis) => mthis.callMethod("createShader", []);

  createShader_Callback_1_(mthis, __arg_0) => mthis.callMethod("createShader", [__arg_0]);

  createTexture_Callback_0_(mthis) => mthis.callMethod("createTexture", []);

  cullFace_Callback_0_(mthis) => mthis.callMethod("cullFace", []);

  cullFace_Callback_1_(mthis, __arg_0) => mthis.callMethod("cullFace", [__arg_0]);

  deleteBuffer_Callback_0_(mthis) => mthis.callMethod("deleteBuffer", []);

  deleteBuffer_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteBuffer", [__arg_0]);

  deleteFramebuffer_Callback_0_(mthis) => mthis.callMethod("deleteFramebuffer", []);

  deleteFramebuffer_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteFramebuffer", [__arg_0]);

  deleteProgram_Callback_0_(mthis) => mthis.callMethod("deleteProgram", []);

  deleteProgram_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteProgram", [__arg_0]);

  deleteRenderbuffer_Callback_0_(mthis) => mthis.callMethod("deleteRenderbuffer", []);

  deleteRenderbuffer_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteRenderbuffer", [__arg_0]);

  deleteShader_Callback_0_(mthis) => mthis.callMethod("deleteShader", []);

  deleteShader_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteShader", [__arg_0]);

  deleteTexture_Callback_0_(mthis) => mthis.callMethod("deleteTexture", []);

  deleteTexture_Callback_1_(mthis, __arg_0) => mthis.callMethod("deleteTexture", [__arg_0]);

  depthFunc_Callback_0_(mthis) => mthis.callMethod("depthFunc", []);

  depthFunc_Callback_1_(mthis, __arg_0) => mthis.callMethod("depthFunc", [__arg_0]);

  depthMask_Callback_0_(mthis) => mthis.callMethod("depthMask", []);

  depthMask_Callback_1_(mthis, __arg_0) => mthis.callMethod("depthMask", [__arg_0]);

  depthRange_Callback_0_(mthis) => mthis.callMethod("depthRange", []);

  depthRange_Callback_1_(mthis, __arg_0) => mthis.callMethod("depthRange", [__arg_0]);

  depthRange_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("depthRange", [__arg_0, __arg_1]);

  detachShader_Callback_0_(mthis) => mthis.callMethod("detachShader", []);

  detachShader_Callback_1_(mthis, __arg_0) => mthis.callMethod("detachShader", [__arg_0]);

  detachShader_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("detachShader", [__arg_0, __arg_1]);

  disableVertexAttribArray_Callback_0_(mthis) => mthis.callMethod("disableVertexAttribArray", []);

  disableVertexAttribArray_Callback_1_(mthis, __arg_0) => mthis.callMethod("disableVertexAttribArray", [__arg_0]);

  disable_Callback_0_(mthis) => mthis.callMethod("disable", []);

  disable_Callback_1_(mthis, __arg_0) => mthis.callMethod("disable", [__arg_0]);

  drawArrays_Callback_1_(mthis, __arg_0) => mthis.callMethod("drawArrays", [__arg_0]);

  drawArrays_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("drawArrays", [__arg_0, __arg_1]);

  drawArrays_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("drawArrays", [__arg_0, __arg_1, __arg_2]);

  drawElements_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("drawElements", [__arg_0, __arg_1]);

  drawElements_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("drawElements", [__arg_0, __arg_1, __arg_2]);

  drawElements_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("drawElements", [__arg_0, __arg_1, __arg_2, __arg_3]);

  drawingBufferHeight_Getter_(mthis) => mthis["drawingBufferHeight"];

  drawingBufferWidth_Getter_(mthis) => mthis["drawingBufferWidth"];

  enableVertexAttribArray_Callback_0_(mthis) => mthis.callMethod("enableVertexAttribArray", []);

  enableVertexAttribArray_Callback_1_(mthis, __arg_0) => mthis.callMethod("enableVertexAttribArray", [__arg_0]);

  enable_Callback_0_(mthis) => mthis.callMethod("enable", []);

  enable_Callback_1_(mthis, __arg_0) => mthis.callMethod("enable", [__arg_0]);

  finish_Callback_0_(mthis) => mthis.callMethod("finish", []);

  flush_Callback_0_(mthis) => mthis.callMethod("flush", []);

  framebufferRenderbuffer_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("framebufferRenderbuffer", [__arg_0, __arg_1]);

  framebufferRenderbuffer_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("framebufferRenderbuffer", [__arg_0, __arg_1, __arg_2]);

  framebufferRenderbuffer_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("framebufferRenderbuffer", [__arg_0, __arg_1, __arg_2, __arg_3]);

  framebufferTexture2D_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("framebufferTexture2D", [__arg_0, __arg_1, __arg_2]);

  framebufferTexture2D_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("framebufferTexture2D", [__arg_0, __arg_1, __arg_2, __arg_3]);

  framebufferTexture2D_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("framebufferTexture2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  frontFace_Callback_0_(mthis) => mthis.callMethod("frontFace", []);

  frontFace_Callback_1_(mthis, __arg_0) => mthis.callMethod("frontFace", [__arg_0]);

  generateMipmap_Callback_0_(mthis) => mthis.callMethod("generateMipmap", []);

  generateMipmap_Callback_1_(mthis, __arg_0) => mthis.callMethod("generateMipmap", [__arg_0]);

  getActiveAttrib_Callback_0_(mthis) => mthis.callMethod("getActiveAttrib", []);

  getActiveAttrib_Callback_1_(mthis, __arg_0) => mthis.callMethod("getActiveAttrib", [__arg_0]);

  getActiveAttrib_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getActiveAttrib", [__arg_0, __arg_1]);

  getActiveUniform_Callback_0_(mthis) => mthis.callMethod("getActiveUniform", []);

  getActiveUniform_Callback_1_(mthis, __arg_0) => mthis.callMethod("getActiveUniform", [__arg_0]);

  getActiveUniform_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getActiveUniform", [__arg_0, __arg_1]);

  getAttachedShaders_Callback_0_(mthis) => mthis.callMethod("getAttachedShaders", []);

  getAttachedShaders_Callback_1_(mthis, __arg_0) => mthis.callMethod("getAttachedShaders", [__arg_0]);

  getAttribLocation_Callback_0_(mthis) => mthis.callMethod("getAttribLocation", []);

  getAttribLocation_Callback_1_(mthis, __arg_0) => mthis.callMethod("getAttribLocation", [__arg_0]);

  getAttribLocation_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getAttribLocation", [__arg_0, __arg_1]);

  getBufferParameter_Callback_0_(mthis) => mthis.callMethod("getBufferParameter", []);

  getBufferParameter_Callback_1_(mthis, __arg_0) => mthis.callMethod("getBufferParameter", [__arg_0]);

  getBufferParameter_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getBufferParameter", [__arg_0, __arg_1]);

  getContextAttributes_Callback_0_(mthis) => mthis.callMethod("getContextAttributes", []);

  getError_Callback_0_(mthis) => mthis.callMethod("getError", []);

  getExtension_Callback_0_(mthis) => mthis.callMethod("getExtension", []);

  getExtension_Callback_1_(mthis, __arg_0) => mthis.callMethod("getExtension", [__arg_0]);

  getFramebufferAttachmentParameter_Callback_1_(mthis, __arg_0) => mthis.callMethod("getFramebufferAttachmentParameter", [__arg_0]);

  getFramebufferAttachmentParameter_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getFramebufferAttachmentParameter", [__arg_0, __arg_1]);

  getFramebufferAttachmentParameter_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("getFramebufferAttachmentParameter", [__arg_0, __arg_1, __arg_2]);

  getParameter_Callback_0_(mthis) => mthis.callMethod("getParameter", []);

  getParameter_Callback_1_(mthis, __arg_0) => mthis.callMethod("getParameter", [__arg_0]);

  getProgramInfoLog_Callback_0_(mthis) => mthis.callMethod("getProgramInfoLog", []);

  getProgramInfoLog_Callback_1_(mthis, __arg_0) => mthis.callMethod("getProgramInfoLog", [__arg_0]);

  getProgramParameter_Callback_0_(mthis) => mthis.callMethod("getProgramParameter", []);

  getProgramParameter_Callback_1_(mthis, __arg_0) => mthis.callMethod("getProgramParameter", [__arg_0]);

  getProgramParameter_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getProgramParameter", [__arg_0, __arg_1]);

  getRenderbufferParameter_Callback_0_(mthis) => mthis.callMethod("getRenderbufferParameter", []);

  getRenderbufferParameter_Callback_1_(mthis, __arg_0) => mthis.callMethod("getRenderbufferParameter", [__arg_0]);

  getRenderbufferParameter_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getRenderbufferParameter", [__arg_0, __arg_1]);

  getShaderInfoLog_Callback_0_(mthis) => mthis.callMethod("getShaderInfoLog", []);

  getShaderInfoLog_Callback_1_(mthis, __arg_0) => mthis.callMethod("getShaderInfoLog", [__arg_0]);

  getShaderParameter_Callback_0_(mthis) => mthis.callMethod("getShaderParameter", []);

  getShaderParameter_Callback_1_(mthis, __arg_0) => mthis.callMethod("getShaderParameter", [__arg_0]);

  getShaderParameter_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getShaderParameter", [__arg_0, __arg_1]);

  getShaderPrecisionFormat_Callback_0_(mthis) => mthis.callMethod("getShaderPrecisionFormat", []);

  getShaderPrecisionFormat_Callback_1_(mthis, __arg_0) => mthis.callMethod("getShaderPrecisionFormat", [__arg_0]);

  getShaderPrecisionFormat_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getShaderPrecisionFormat", [__arg_0, __arg_1]);

  getShaderSource_Callback_0_(mthis) => mthis.callMethod("getShaderSource", []);

  getShaderSource_Callback_1_(mthis, __arg_0) => mthis.callMethod("getShaderSource", [__arg_0]);

  getSupportedExtensions_Callback_0_(mthis) => mthis.callMethod("getSupportedExtensions", []);

  getTexParameter_Callback_0_(mthis) => mthis.callMethod("getTexParameter", []);

  getTexParameter_Callback_1_(mthis, __arg_0) => mthis.callMethod("getTexParameter", [__arg_0]);

  getTexParameter_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getTexParameter", [__arg_0, __arg_1]);

  getUniformLocation_Callback_0_(mthis) => mthis.callMethod("getUniformLocation", []);

  getUniformLocation_Callback_1_(mthis, __arg_0) => mthis.callMethod("getUniformLocation", [__arg_0]);

  getUniformLocation_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getUniformLocation", [__arg_0, __arg_1]);

  getUniform_Callback_0_(mthis) => mthis.callMethod("getUniform", []);

  getUniform_Callback_1_(mthis, __arg_0) => mthis.callMethod("getUniform", [__arg_0]);

  getUniform_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getUniform", [__arg_0, __arg_1]);

  getVertexAttribOffset_Callback_0_(mthis) => mthis.callMethod("getVertexAttribOffset", []);

  getVertexAttribOffset_Callback_1_(mthis, __arg_0) => mthis.callMethod("getVertexAttribOffset", [__arg_0]);

  getVertexAttribOffset_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getVertexAttribOffset", [__arg_0, __arg_1]);

  getVertexAttrib_Callback_0_(mthis) => mthis.callMethod("getVertexAttrib", []);

  getVertexAttrib_Callback_1_(mthis, __arg_0) => mthis.callMethod("getVertexAttrib", [__arg_0]);

  getVertexAttrib_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getVertexAttrib", [__arg_0, __arg_1]);

  hint_Callback_0_(mthis) => mthis.callMethod("hint", []);

  hint_Callback_1_(mthis, __arg_0) => mthis.callMethod("hint", [__arg_0]);

  hint_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("hint", [__arg_0, __arg_1]);

  isBuffer_Callback_0_(mthis) => mthis.callMethod("isBuffer", []);

  isBuffer_Callback_1_(mthis, __arg_0) => mthis.callMethod("isBuffer", [__arg_0]);

  isContextLost_Callback_0_(mthis) => mthis.callMethod("isContextLost", []);

  isEnabled_Callback_0_(mthis) => mthis.callMethod("isEnabled", []);

  isEnabled_Callback_1_(mthis, __arg_0) => mthis.callMethod("isEnabled", [__arg_0]);

  isFramebuffer_Callback_0_(mthis) => mthis.callMethod("isFramebuffer", []);

  isFramebuffer_Callback_1_(mthis, __arg_0) => mthis.callMethod("isFramebuffer", [__arg_0]);

  isProgram_Callback_0_(mthis) => mthis.callMethod("isProgram", []);

  isProgram_Callback_1_(mthis, __arg_0) => mthis.callMethod("isProgram", [__arg_0]);

  isRenderbuffer_Callback_0_(mthis) => mthis.callMethod("isRenderbuffer", []);

  isRenderbuffer_Callback_1_(mthis, __arg_0) => mthis.callMethod("isRenderbuffer", [__arg_0]);

  isShader_Callback_0_(mthis) => mthis.callMethod("isShader", []);

  isShader_Callback_1_(mthis, __arg_0) => mthis.callMethod("isShader", [__arg_0]);

  isTexture_Callback_0_(mthis) => mthis.callMethod("isTexture", []);

  isTexture_Callback_1_(mthis, __arg_0) => mthis.callMethod("isTexture", [__arg_0]);

  lineWidth_Callback_0_(mthis) => mthis.callMethod("lineWidth", []);

  lineWidth_Callback_1_(mthis, __arg_0) => mthis.callMethod("lineWidth", [__arg_0]);

  linkProgram_Callback_0_(mthis) => mthis.callMethod("linkProgram", []);

  linkProgram_Callback_1_(mthis, __arg_0) => mthis.callMethod("linkProgram", [__arg_0]);

  pixelStorei_Callback_0_(mthis) => mthis.callMethod("pixelStorei", []);

  pixelStorei_Callback_1_(mthis, __arg_0) => mthis.callMethod("pixelStorei", [__arg_0]);

  pixelStorei_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("pixelStorei", [__arg_0, __arg_1]);

  polygonOffset_Callback_0_(mthis) => mthis.callMethod("polygonOffset", []);

  polygonOffset_Callback_1_(mthis, __arg_0) => mthis.callMethod("polygonOffset", [__arg_0]);

  polygonOffset_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("polygonOffset", [__arg_0, __arg_1]);

  readPixels_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("readPixels", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  readPixels_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("readPixels", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  readPixels_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("readPixels", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  renderbufferStorage_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("renderbufferStorage", [__arg_0, __arg_1]);

  renderbufferStorage_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("renderbufferStorage", [__arg_0, __arg_1, __arg_2]);

  renderbufferStorage_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("renderbufferStorage", [__arg_0, __arg_1, __arg_2, __arg_3]);

  sampleCoverage_Callback_0_(mthis) => mthis.callMethod("sampleCoverage", []);

  sampleCoverage_Callback_1_(mthis, __arg_0) => mthis.callMethod("sampleCoverage", [__arg_0]);

  sampleCoverage_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("sampleCoverage", [__arg_0, __arg_1]);

  scissor_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("scissor", [__arg_0, __arg_1]);

  scissor_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("scissor", [__arg_0, __arg_1, __arg_2]);

  scissor_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("scissor", [__arg_0, __arg_1, __arg_2, __arg_3]);

  shaderSource_Callback_0_(mthis) => mthis.callMethod("shaderSource", []);

  shaderSource_Callback_1_(mthis, __arg_0) => mthis.callMethod("shaderSource", [__arg_0]);

  shaderSource_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("shaderSource", [__arg_0, __arg_1]);

  stencilFuncSeparate_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("stencilFuncSeparate", [__arg_0, __arg_1]);

  stencilFuncSeparate_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("stencilFuncSeparate", [__arg_0, __arg_1, __arg_2]);

  stencilFuncSeparate_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("stencilFuncSeparate", [__arg_0, __arg_1, __arg_2, __arg_3]);

  stencilFunc_Callback_1_(mthis, __arg_0) => mthis.callMethod("stencilFunc", [__arg_0]);

  stencilFunc_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("stencilFunc", [__arg_0, __arg_1]);

  stencilFunc_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("stencilFunc", [__arg_0, __arg_1, __arg_2]);

  stencilMaskSeparate_Callback_0_(mthis) => mthis.callMethod("stencilMaskSeparate", []);

  stencilMaskSeparate_Callback_1_(mthis, __arg_0) => mthis.callMethod("stencilMaskSeparate", [__arg_0]);

  stencilMaskSeparate_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("stencilMaskSeparate", [__arg_0, __arg_1]);

  stencilMask_Callback_0_(mthis) => mthis.callMethod("stencilMask", []);

  stencilMask_Callback_1_(mthis, __arg_0) => mthis.callMethod("stencilMask", [__arg_0]);

  stencilOpSeparate_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("stencilOpSeparate", [__arg_0, __arg_1]);

  stencilOpSeparate_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("stencilOpSeparate", [__arg_0, __arg_1, __arg_2]);

  stencilOpSeparate_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("stencilOpSeparate", [__arg_0, __arg_1, __arg_2, __arg_3]);

  stencilOp_Callback_1_(mthis, __arg_0) => mthis.callMethod("stencilOp", [__arg_0]);

  stencilOp_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("stencilOp", [__arg_0, __arg_1]);

  stencilOp_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("stencilOp", [__arg_0, __arg_1, __arg_2]);

  texImage2D_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("texImage2D", [__arg_0, __arg_1, __arg_2, __arg_3]);

  texImage2D_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("texImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  texImage2D_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("texImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  texImage2D_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("texImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  texImage2D_Callback_8_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7) => mthis.callMethod("texImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7]);

  texImage2D_Callback_9_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8) => mthis.callMethod("texImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8]);

  texParameterf_Callback_1_(mthis, __arg_0) => mthis.callMethod("texParameterf", [__arg_0]);

  texParameterf_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("texParameterf", [__arg_0, __arg_1]);

  texParameterf_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("texParameterf", [__arg_0, __arg_1, __arg_2]);

  texParameteri_Callback_1_(mthis, __arg_0) => mthis.callMethod("texParameteri", [__arg_0]);

  texParameteri_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("texParameteri", [__arg_0, __arg_1]);

  texParameteri_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("texParameteri", [__arg_0, __arg_1, __arg_2]);

  texSubImage2D_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("texSubImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  texSubImage2D_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("texSubImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  texSubImage2D_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("texSubImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  texSubImage2D_Callback_8_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7) => mthis.callMethod("texSubImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7]);

  texSubImage2D_Callback_9_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8) => mthis.callMethod("texSubImage2D", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6, __arg_7, __arg_8]);

  uniform1f_Callback_0_(mthis) => mthis.callMethod("uniform1f", []);

  uniform1f_Callback_1_(mthis, __arg_0) => mthis.callMethod("uniform1f", [__arg_0]);

  uniform1f_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("uniform1f", [__arg_0, __arg_1]);

  uniform1fv_Callback_0_(mthis) => mthis.callMethod("uniform1fv", []);

  uniform1fv_Callback_1_(mthis, __arg_0) => mthis.callMethod("uniform1fv", [__arg_0]);

  uniform1fv_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("uniform1fv", [__arg_0, __arg_1]);

  uniform1i_Callback_0_(mthis) => mthis.callMethod("uniform1i", []);

  uniform1i_Callback_1_(mthis, __arg_0) => mthis.callMethod("uniform1i", [__arg_0]);

  uniform1i_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("uniform1i", [__arg_0, __arg_1]);

  uniform1iv_Callback_0_(mthis) => mthis.callMethod("uniform1iv", []);

  uniform1iv_Callback_1_(mthis, __arg_0) => mthis.callMethod("uniform1iv", [__arg_0]);

  uniform1iv_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("uniform1iv", [__arg_0, __arg_1]);

  uniform2f_Callback_1_(mthis, __arg_0) => mthis.callMethod("uniform2f", [__arg_0]);

  uniform2f_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("uniform2f", [__arg_0, __arg_1]);

  uniform2f_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("uniform2f", [__arg_0, __arg_1, __arg_2]);

  uniform2fv_Callback_0_(mthis) => mthis.callMethod("uniform2fv", []);

  uniform2fv_Callback_1_(mthis, __arg_0) => mthis.callMethod("uniform2fv", [__arg_0]);

  uniform2fv_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("uniform2fv", [__arg_0, __arg_1]);

  uniform2i_Callback_1_(mthis, __arg_0) => mthis.callMethod("uniform2i", [__arg_0]);

  uniform2i_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("uniform2i", [__arg_0, __arg_1]);

  uniform2i_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("uniform2i", [__arg_0, __arg_1, __arg_2]);

  uniform2iv_Callback_0_(mthis) => mthis.callMethod("uniform2iv", []);

  uniform2iv_Callback_1_(mthis, __arg_0) => mthis.callMethod("uniform2iv", [__arg_0]);

  uniform2iv_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("uniform2iv", [__arg_0, __arg_1]);

  uniform3f_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("uniform3f", [__arg_0, __arg_1]);

  uniform3f_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("uniform3f", [__arg_0, __arg_1, __arg_2]);

  uniform3f_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("uniform3f", [__arg_0, __arg_1, __arg_2, __arg_3]);

  uniform3fv_Callback_0_(mthis) => mthis.callMethod("uniform3fv", []);

  uniform3fv_Callback_1_(mthis, __arg_0) => mthis.callMethod("uniform3fv", [__arg_0]);

  uniform3fv_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("uniform3fv", [__arg_0, __arg_1]);

  uniform3i_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("uniform3i", [__arg_0, __arg_1]);

  uniform3i_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("uniform3i", [__arg_0, __arg_1, __arg_2]);

  uniform3i_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("uniform3i", [__arg_0, __arg_1, __arg_2, __arg_3]);

  uniform3iv_Callback_0_(mthis) => mthis.callMethod("uniform3iv", []);

  uniform3iv_Callback_1_(mthis, __arg_0) => mthis.callMethod("uniform3iv", [__arg_0]);

  uniform3iv_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("uniform3iv", [__arg_0, __arg_1]);

  uniform4f_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("uniform4f", [__arg_0, __arg_1, __arg_2]);

  uniform4f_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("uniform4f", [__arg_0, __arg_1, __arg_2, __arg_3]);

  uniform4f_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("uniform4f", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  uniform4fv_Callback_0_(mthis) => mthis.callMethod("uniform4fv", []);

  uniform4fv_Callback_1_(mthis, __arg_0) => mthis.callMethod("uniform4fv", [__arg_0]);

  uniform4fv_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("uniform4fv", [__arg_0, __arg_1]);

  uniform4i_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("uniform4i", [__arg_0, __arg_1, __arg_2]);

  uniform4i_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("uniform4i", [__arg_0, __arg_1, __arg_2, __arg_3]);

  uniform4i_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("uniform4i", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  uniform4iv_Callback_0_(mthis) => mthis.callMethod("uniform4iv", []);

  uniform4iv_Callback_1_(mthis, __arg_0) => mthis.callMethod("uniform4iv", [__arg_0]);

  uniform4iv_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("uniform4iv", [__arg_0, __arg_1]);

  uniformMatrix2fv_Callback_1_(mthis, __arg_0) => mthis.callMethod("uniformMatrix2fv", [__arg_0]);

  uniformMatrix2fv_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("uniformMatrix2fv", [__arg_0, __arg_1]);

  uniformMatrix2fv_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("uniformMatrix2fv", [__arg_0, __arg_1, __arg_2]);

  uniformMatrix3fv_Callback_1_(mthis, __arg_0) => mthis.callMethod("uniformMatrix3fv", [__arg_0]);

  uniformMatrix3fv_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("uniformMatrix3fv", [__arg_0, __arg_1]);

  uniformMatrix3fv_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("uniformMatrix3fv", [__arg_0, __arg_1, __arg_2]);

  uniformMatrix4fv_Callback_1_(mthis, __arg_0) => mthis.callMethod("uniformMatrix4fv", [__arg_0]);

  uniformMatrix4fv_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("uniformMatrix4fv", [__arg_0, __arg_1]);

  uniformMatrix4fv_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("uniformMatrix4fv", [__arg_0, __arg_1, __arg_2]);

  useProgram_Callback_0_(mthis) => mthis.callMethod("useProgram", []);

  useProgram_Callback_1_(mthis, __arg_0) => mthis.callMethod("useProgram", [__arg_0]);

  validateProgram_Callback_0_(mthis) => mthis.callMethod("validateProgram", []);

  validateProgram_Callback_1_(mthis, __arg_0) => mthis.callMethod("validateProgram", [__arg_0]);

  vertexAttrib1f_Callback_0_(mthis) => mthis.callMethod("vertexAttrib1f", []);

  vertexAttrib1f_Callback_1_(mthis, __arg_0) => mthis.callMethod("vertexAttrib1f", [__arg_0]);

  vertexAttrib1f_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("vertexAttrib1f", [__arg_0, __arg_1]);

  vertexAttrib1fv_Callback_0_(mthis) => mthis.callMethod("vertexAttrib1fv", []);

  vertexAttrib1fv_Callback_1_(mthis, __arg_0) => mthis.callMethod("vertexAttrib1fv", [__arg_0]);

  vertexAttrib1fv_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("vertexAttrib1fv", [__arg_0, __arg_1]);

  vertexAttrib2f_Callback_1_(mthis, __arg_0) => mthis.callMethod("vertexAttrib2f", [__arg_0]);

  vertexAttrib2f_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("vertexAttrib2f", [__arg_0, __arg_1]);

  vertexAttrib2f_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("vertexAttrib2f", [__arg_0, __arg_1, __arg_2]);

  vertexAttrib2fv_Callback_0_(mthis) => mthis.callMethod("vertexAttrib2fv", []);

  vertexAttrib2fv_Callback_1_(mthis, __arg_0) => mthis.callMethod("vertexAttrib2fv", [__arg_0]);

  vertexAttrib2fv_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("vertexAttrib2fv", [__arg_0, __arg_1]);

  vertexAttrib3f_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("vertexAttrib3f", [__arg_0, __arg_1]);

  vertexAttrib3f_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("vertexAttrib3f", [__arg_0, __arg_1, __arg_2]);

  vertexAttrib3f_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("vertexAttrib3f", [__arg_0, __arg_1, __arg_2, __arg_3]);

  vertexAttrib3fv_Callback_0_(mthis) => mthis.callMethod("vertexAttrib3fv", []);

  vertexAttrib3fv_Callback_1_(mthis, __arg_0) => mthis.callMethod("vertexAttrib3fv", [__arg_0]);

  vertexAttrib3fv_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("vertexAttrib3fv", [__arg_0, __arg_1]);

  vertexAttrib4f_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("vertexAttrib4f", [__arg_0, __arg_1, __arg_2]);

  vertexAttrib4f_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("vertexAttrib4f", [__arg_0, __arg_1, __arg_2, __arg_3]);

  vertexAttrib4f_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("vertexAttrib4f", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  vertexAttrib4fv_Callback_0_(mthis) => mthis.callMethod("vertexAttrib4fv", []);

  vertexAttrib4fv_Callback_1_(mthis, __arg_0) => mthis.callMethod("vertexAttrib4fv", [__arg_0]);

  vertexAttrib4fv_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("vertexAttrib4fv", [__arg_0, __arg_1]);

  vertexAttribPointer_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("vertexAttribPointer", [__arg_0, __arg_1, __arg_2, __arg_3]);

  vertexAttribPointer_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("vertexAttribPointer", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  vertexAttribPointer_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("vertexAttribPointer", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  viewport_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("viewport", [__arg_0, __arg_1]);

  viewport_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("viewport", [__arg_0, __arg_1, __arg_2]);

  viewport_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("viewport", [__arg_0, __arg_1, __arg_2, __arg_3]);

}

class BlinkWebGLShader {
  static final instance = new BlinkWebGLShader();

}

class BlinkWebGLShaderPrecisionFormat {
  static final instance = new BlinkWebGLShaderPrecisionFormat();

  precision_Getter_(mthis) => mthis["precision"];

  rangeMax_Getter_(mthis) => mthis["rangeMax"];

  rangeMin_Getter_(mthis) => mthis["rangeMin"];

}

class BlinkWebGLTexture {
  static final instance = new BlinkWebGLTexture();

}

class BlinkWebGLUniformLocation {
  static final instance = new BlinkWebGLUniformLocation();

}

class BlinkWebGLVertexArrayObjectOES {
  static final instance = new BlinkWebGLVertexArrayObjectOES();

}

class BlinkWebKitAnimationEvent extends BlinkEvent {
  static final instance = new BlinkWebKitAnimationEvent();

  animationName_Getter_(mthis) => mthis["animationName"];

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["WebKitAnimationEvent"], [__arg_0, __arg_1]);

  elapsedTime_Getter_(mthis) => mthis["elapsedTime"];

}

class BlinkWebKitCSSFilterRule extends BlinkCSSRule {
  static final instance = new BlinkWebKitCSSFilterRule();

  style_Getter_(mthis) => mthis["style"];

}

class BlinkWebKitCSSFilterValue extends BlinkCSSValueList {
  static final instance = new BlinkWebKitCSSFilterValue();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  operationType_Getter_(mthis) => mthis["operationType"];

}

class BlinkWebKitCSSMatrix {
  static final instance = new BlinkWebKitCSSMatrix();

  a_Getter_(mthis) => mthis["a"];

  a_Setter_(mthis, __arg_0) => mthis["a"] = __arg_0;

  b_Getter_(mthis) => mthis["b"];

  b_Setter_(mthis, __arg_0) => mthis["b"] = __arg_0;

  c_Getter_(mthis) => mthis["c"];

  c_Setter_(mthis, __arg_0) => mthis["c"] = __arg_0;

  constructorCallback_0_() => new js.JsObject(js.context["WebKitCSSMatrix"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["WebKitCSSMatrix"], [__arg_0]);

  d_Getter_(mthis) => mthis["d"];

  d_Setter_(mthis, __arg_0) => mthis["d"] = __arg_0;

  e_Getter_(mthis) => mthis["e"];

  e_Setter_(mthis, __arg_0) => mthis["e"] = __arg_0;

  f_Getter_(mthis) => mthis["f"];

  f_Setter_(mthis, __arg_0) => mthis["f"] = __arg_0;

  inverse_Callback_0_(mthis) => mthis.callMethod("inverse", []);

  m11_Getter_(mthis) => mthis["m11"];

  m11_Setter_(mthis, __arg_0) => mthis["m11"] = __arg_0;

  m12_Getter_(mthis) => mthis["m12"];

  m12_Setter_(mthis, __arg_0) => mthis["m12"] = __arg_0;

  m13_Getter_(mthis) => mthis["m13"];

  m13_Setter_(mthis, __arg_0) => mthis["m13"] = __arg_0;

  m14_Getter_(mthis) => mthis["m14"];

  m14_Setter_(mthis, __arg_0) => mthis["m14"] = __arg_0;

  m21_Getter_(mthis) => mthis["m21"];

  m21_Setter_(mthis, __arg_0) => mthis["m21"] = __arg_0;

  m22_Getter_(mthis) => mthis["m22"];

  m22_Setter_(mthis, __arg_0) => mthis["m22"] = __arg_0;

  m23_Getter_(mthis) => mthis["m23"];

  m23_Setter_(mthis, __arg_0) => mthis["m23"] = __arg_0;

  m24_Getter_(mthis) => mthis["m24"];

  m24_Setter_(mthis, __arg_0) => mthis["m24"] = __arg_0;

  m31_Getter_(mthis) => mthis["m31"];

  m31_Setter_(mthis, __arg_0) => mthis["m31"] = __arg_0;

  m32_Getter_(mthis) => mthis["m32"];

  m32_Setter_(mthis, __arg_0) => mthis["m32"] = __arg_0;

  m33_Getter_(mthis) => mthis["m33"];

  m33_Setter_(mthis, __arg_0) => mthis["m33"] = __arg_0;

  m34_Getter_(mthis) => mthis["m34"];

  m34_Setter_(mthis, __arg_0) => mthis["m34"] = __arg_0;

  m41_Getter_(mthis) => mthis["m41"];

  m41_Setter_(mthis, __arg_0) => mthis["m41"] = __arg_0;

  m42_Getter_(mthis) => mthis["m42"];

  m42_Setter_(mthis, __arg_0) => mthis["m42"] = __arg_0;

  m43_Getter_(mthis) => mthis["m43"];

  m43_Setter_(mthis, __arg_0) => mthis["m43"] = __arg_0;

  m44_Getter_(mthis) => mthis["m44"];

  m44_Setter_(mthis, __arg_0) => mthis["m44"] = __arg_0;

  multiply_Callback_0_(mthis) => mthis.callMethod("multiply", []);

  multiply_Callback_1_(mthis, __arg_0) => mthis.callMethod("multiply", [__arg_0]);

  rotateAxisAngle_Callback_0_(mthis) => mthis.callMethod("rotateAxisAngle", []);

  rotateAxisAngle_Callback_1_(mthis, __arg_0) => mthis.callMethod("rotateAxisAngle", [__arg_0]);

  rotateAxisAngle_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("rotateAxisAngle", [__arg_0, __arg_1]);

  rotateAxisAngle_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("rotateAxisAngle", [__arg_0, __arg_1, __arg_2]);

  rotateAxisAngle_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("rotateAxisAngle", [__arg_0, __arg_1, __arg_2, __arg_3]);

  rotate_Callback_0_(mthis) => mthis.callMethod("rotate", []);

  rotate_Callback_1_(mthis, __arg_0) => mthis.callMethod("rotate", [__arg_0]);

  rotate_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("rotate", [__arg_0, __arg_1]);

  rotate_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("rotate", [__arg_0, __arg_1, __arg_2]);

  scale_Callback_0_(mthis) => mthis.callMethod("scale", []);

  scale_Callback_1_(mthis, __arg_0) => mthis.callMethod("scale", [__arg_0]);

  scale_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("scale", [__arg_0, __arg_1]);

  scale_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("scale", [__arg_0, __arg_1, __arg_2]);

  setMatrixValue_Callback_0_(mthis) => mthis.callMethod("setMatrixValue", []);

  setMatrixValue_Callback_1_(mthis, __arg_0) => mthis.callMethod("setMatrixValue", [__arg_0]);

  skewX_Callback_0_(mthis) => mthis.callMethod("skewX", []);

  skewX_Callback_1_(mthis, __arg_0) => mthis.callMethod("skewX", [__arg_0]);

  skewY_Callback_0_(mthis) => mthis.callMethod("skewY", []);

  skewY_Callback_1_(mthis, __arg_0) => mthis.callMethod("skewY", [__arg_0]);

  translate_Callback_0_(mthis) => mthis.callMethod("translate", []);

  translate_Callback_1_(mthis, __arg_0) => mthis.callMethod("translate", [__arg_0]);

  translate_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("translate", [__arg_0, __arg_1]);

  translate_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("translate", [__arg_0, __arg_1, __arg_2]);

}

class BlinkWebKitCSSTransformValue extends BlinkCSSValueList {
  static final instance = new BlinkWebKitCSSTransformValue();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  operationType_Getter_(mthis) => mthis["operationType"];

}

class BlinkWebKitGamepad {
  static final instance = new BlinkWebKitGamepad();

  axes_Getter_(mthis) => mthis["axes"];

  buttons_Getter_(mthis) => mthis["buttons"];

  connected_Getter_(mthis) => mthis["connected"];

  id_Getter_(mthis) => mthis["id"];

  index_Getter_(mthis) => mthis["index"];

  mapping_Getter_(mthis) => mthis["mapping"];

  timestamp_Getter_(mthis) => mthis["timestamp"];

}

class BlinkWebKitGamepadList {
  static final instance = new BlinkWebKitGamepadList();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  item_Callback_0_(mthis) => mthis.callMethod("item", []);

  item_Callback_1_(mthis, __arg_0) => mthis.callMethod("item", [__arg_0]);

  length_Getter_(mthis) => mthis["length"];

}

class BlinkWebSocket extends BlinkEventTarget {
  static final instance = new BlinkWebSocket();

  URL_Getter_(mthis) => mthis["URL"];

  binaryType_Getter_(mthis) => mthis["binaryType"];

  binaryType_Setter_(mthis, __arg_0) => mthis["binaryType"] = __arg_0;

  bufferedAmount_Getter_(mthis) => mthis["bufferedAmount"];

  close_Callback_0_(mthis) => mthis.callMethod("close", []);

  close_Callback_1_(mthis, __arg_0) => mthis.callMethod("close", [__arg_0]);

  close_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("close", [__arg_0, __arg_1]);

  constructorCallback_0_() => new js.JsObject(js.context["WebSocket"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["WebSocket"], [__arg_0]);

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["WebSocket"], [__arg_0, __arg_1]);

  extensions_Getter_(mthis) => mthis["extensions"];

  onclose_Getter_(mthis) => mthis["onclose"];

  onclose_Setter_(mthis, __arg_0) => mthis["onclose"] = __arg_0;

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onmessage_Getter_(mthis) => mthis["onmessage"];

  onmessage_Setter_(mthis, __arg_0) => mthis["onmessage"] = __arg_0;

  onopen_Getter_(mthis) => mthis["onopen"];

  onopen_Setter_(mthis, __arg_0) => mthis["onopen"] = __arg_0;

  protocol_Getter_(mthis) => mthis["protocol"];

  readyState_Getter_(mthis) => mthis["readyState"];

  send_Callback_0_(mthis) => mthis.callMethod("send", []);

  send_Callback_1_(mthis, __arg_0) => mthis.callMethod("send", [__arg_0]);

  url_Getter_(mthis) => mthis["url"];

}

class BlinkWheelEvent extends BlinkMouseEvent {
  static final instance = new BlinkWheelEvent();

  constructorCallback_2_(__arg_0, __arg_1) => new js.JsObject(js.context["WheelEvent"], [__arg_0, __arg_1]);

  deltaMode_Getter_(mthis) => mthis["deltaMode"];

  deltaX_Getter_(mthis) => mthis["deltaX"];

  deltaY_Getter_(mthis) => mthis["deltaY"];

  deltaZ_Getter_(mthis) => mthis["deltaZ"];

  wheelDeltaX_Getter_(mthis) => mthis["wheelDeltaX"];

  wheelDeltaY_Getter_(mthis) => mthis["wheelDeltaY"];

}

class BlinkWindow extends BlinkEventTarget {
  static final instance = new BlinkWindow();

  $__getter___Callback_1_(mthis, __arg_0) => mthis.callMethod("__getter__", [__arg_0]);

  CSS_Getter_(mthis) => mthis["CSS"];

  alert_Callback_0_(mthis) => mthis.callMethod("alert", []);

  alert_Callback_1_(mthis, __arg_0) => mthis.callMethod("alert", [__arg_0]);

  applicationCache_Getter_(mthis) => mthis["applicationCache"];

  atob_Callback_0_(mthis) => mthis.callMethod("atob", []);

  atob_Callback_1_(mthis, __arg_0) => mthis.callMethod("atob", [__arg_0]);

  blur_Callback_0_(mthis) => mthis.callMethod("blur", []);

  btoa_Callback_0_(mthis) => mthis.callMethod("btoa", []);

  btoa_Callback_1_(mthis, __arg_0) => mthis.callMethod("btoa", [__arg_0]);

  cancelAnimationFrame_Callback_0_(mthis) => mthis.callMethod("cancelAnimationFrame", []);

  cancelAnimationFrame_Callback_1_(mthis, __arg_0) => mthis.callMethod("cancelAnimationFrame", [__arg_0]);

  captureEvents_Callback_0_(mthis) => mthis.callMethod("captureEvents", []);

  clearInterval_Callback_0_(mthis) => mthis.callMethod("clearInterval", []);

  clearInterval_Callback_1_(mthis, __arg_0) => mthis.callMethod("clearInterval", [__arg_0]);

  clearTimeout_Callback_0_(mthis) => mthis.callMethod("clearTimeout", []);

  clearTimeout_Callback_1_(mthis, __arg_0) => mthis.callMethod("clearTimeout", [__arg_0]);

  close_Callback_0_(mthis) => mthis.callMethod("close", []);

  closed_Getter_(mthis) => mthis["closed"];

  confirm_Callback_0_(mthis) => mthis.callMethod("confirm", []);

  confirm_Callback_1_(mthis, __arg_0) => mthis.callMethod("confirm", [__arg_0]);

  console_Getter_(mthis) => mthis["console"];

  crypto_Getter_(mthis) => mthis["crypto"];

  defaultStatus_Getter_(mthis) => mthis["defaultStatus"];

  defaultStatus_Setter_(mthis, __arg_0) => mthis["defaultStatus"] = __arg_0;

  defaultstatus_Getter_(mthis) => mthis["defaultstatus"];

  defaultstatus_Setter_(mthis, __arg_0) => mthis["defaultstatus"] = __arg_0;

  devicePixelRatio_Getter_(mthis) => mthis["devicePixelRatio"];

  document_Getter_(mthis) => mthis["document"];

  event_Getter_(mthis) => mthis["event"];

  event_Setter_(mthis, __arg_0) => mthis["event"] = __arg_0;

  find_Callback_0_(mthis) => mthis.callMethod("find", []);

  find_Callback_1_(mthis, __arg_0) => mthis.callMethod("find", [__arg_0]);

  find_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("find", [__arg_0, __arg_1]);

  find_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("find", [__arg_0, __arg_1, __arg_2]);

  find_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("find", [__arg_0, __arg_1, __arg_2, __arg_3]);

  find_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("find", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  find_Callback_6_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5) => mthis.callMethod("find", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5]);

  find_Callback_7_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6) => mthis.callMethod("find", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4, __arg_5, __arg_6]);

  focus_Callback_0_(mthis) => mthis.callMethod("focus", []);

  frameElement_Getter_(mthis) => mthis["frameElement"];

  frames_Getter_(mthis) => mthis["frames"];

  getComputedStyle_Callback_0_(mthis) => mthis.callMethod("getComputedStyle", []);

  getComputedStyle_Callback_1_(mthis, __arg_0) => mthis.callMethod("getComputedStyle", [__arg_0]);

  getComputedStyle_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getComputedStyle", [__arg_0, __arg_1]);

  getMatchedCSSRules_Callback_0_(mthis) => mthis.callMethod("getMatchedCSSRules", []);

  getMatchedCSSRules_Callback_1_(mthis, __arg_0) => mthis.callMethod("getMatchedCSSRules", [__arg_0]);

  getMatchedCSSRules_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getMatchedCSSRules", [__arg_0, __arg_1]);

  getSelection_Callback_0_(mthis) => mthis.callMethod("getSelection", []);

  history_Getter_(mthis) => mthis["history"];

  indexedDB_Getter_(mthis) => mthis["indexedDB"];

  innerHeight_Getter_(mthis) => mthis["innerHeight"];

  innerWidth_Getter_(mthis) => mthis["innerWidth"];

  length_Getter_(mthis) => mthis["length"];

  localStorage_Getter_(mthis) => mthis["localStorage"];

  location_Getter_(mthis) => mthis["location"];

  location_Setter_(mthis, __arg_0) => mthis["location"] = __arg_0;

  locationbar_Getter_(mthis) => mthis["locationbar"];

  matchMedia_Callback_0_(mthis) => mthis.callMethod("matchMedia", []);

  matchMedia_Callback_1_(mthis, __arg_0) => mthis.callMethod("matchMedia", [__arg_0]);

  menubar_Getter_(mthis) => mthis["menubar"];

  moveBy_Callback_0_(mthis) => mthis.callMethod("moveBy", []);

  moveBy_Callback_1_(mthis, __arg_0) => mthis.callMethod("moveBy", [__arg_0]);

  moveBy_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("moveBy", [__arg_0, __arg_1]);

  moveTo_Callback_0_(mthis) => mthis.callMethod("moveTo", []);

  moveTo_Callback_1_(mthis, __arg_0) => mthis.callMethod("moveTo", [__arg_0]);

  moveTo_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("moveTo", [__arg_0, __arg_1]);

  name_Getter_(mthis) => mthis["name"];

  name_Setter_(mthis, __arg_0) => mthis["name"] = __arg_0;

  navigator_Getter_(mthis) => mthis["navigator"];

  offscreenBuffering_Getter_(mthis) => mthis["offscreenBuffering"];

  onabort_Getter_(mthis) => mthis["onabort"];

  onabort_Setter_(mthis, __arg_0) => mthis["onabort"] = __arg_0;

  onanimationend_Getter_(mthis) => mthis["onanimationend"];

  onanimationend_Setter_(mthis, __arg_0) => mthis["onanimationend"] = __arg_0;

  onanimationiteration_Getter_(mthis) => mthis["onanimationiteration"];

  onanimationiteration_Setter_(mthis, __arg_0) => mthis["onanimationiteration"] = __arg_0;

  onanimationstart_Getter_(mthis) => mthis["onanimationstart"];

  onanimationstart_Setter_(mthis, __arg_0) => mthis["onanimationstart"] = __arg_0;

  onautocomplete_Getter_(mthis) => mthis["onautocomplete"];

  onautocomplete_Setter_(mthis, __arg_0) => mthis["onautocomplete"] = __arg_0;

  onautocompleteerror_Getter_(mthis) => mthis["onautocompleteerror"];

  onautocompleteerror_Setter_(mthis, __arg_0) => mthis["onautocompleteerror"] = __arg_0;

  onbeforeunload_Getter_(mthis) => mthis["onbeforeunload"];

  onbeforeunload_Setter_(mthis, __arg_0) => mthis["onbeforeunload"] = __arg_0;

  onblur_Getter_(mthis) => mthis["onblur"];

  onblur_Setter_(mthis, __arg_0) => mthis["onblur"] = __arg_0;

  oncancel_Getter_(mthis) => mthis["oncancel"];

  oncancel_Setter_(mthis, __arg_0) => mthis["oncancel"] = __arg_0;

  oncanplay_Getter_(mthis) => mthis["oncanplay"];

  oncanplay_Setter_(mthis, __arg_0) => mthis["oncanplay"] = __arg_0;

  oncanplaythrough_Getter_(mthis) => mthis["oncanplaythrough"];

  oncanplaythrough_Setter_(mthis, __arg_0) => mthis["oncanplaythrough"] = __arg_0;

  onchange_Getter_(mthis) => mthis["onchange"];

  onchange_Setter_(mthis, __arg_0) => mthis["onchange"] = __arg_0;

  onclick_Getter_(mthis) => mthis["onclick"];

  onclick_Setter_(mthis, __arg_0) => mthis["onclick"] = __arg_0;

  onclose_Getter_(mthis) => mthis["onclose"];

  onclose_Setter_(mthis, __arg_0) => mthis["onclose"] = __arg_0;

  oncontextmenu_Getter_(mthis) => mthis["oncontextmenu"];

  oncontextmenu_Setter_(mthis, __arg_0) => mthis["oncontextmenu"] = __arg_0;

  oncuechange_Getter_(mthis) => mthis["oncuechange"];

  oncuechange_Setter_(mthis, __arg_0) => mthis["oncuechange"] = __arg_0;

  ondblclick_Getter_(mthis) => mthis["ondblclick"];

  ondblclick_Setter_(mthis, __arg_0) => mthis["ondblclick"] = __arg_0;

  ondevicelight_Getter_(mthis) => mthis["ondevicelight"];

  ondevicelight_Setter_(mthis, __arg_0) => mthis["ondevicelight"] = __arg_0;

  ondevicemotion_Getter_(mthis) => mthis["ondevicemotion"];

  ondevicemotion_Setter_(mthis, __arg_0) => mthis["ondevicemotion"] = __arg_0;

  ondeviceorientation_Getter_(mthis) => mthis["ondeviceorientation"];

  ondeviceorientation_Setter_(mthis, __arg_0) => mthis["ondeviceorientation"] = __arg_0;

  ondrag_Getter_(mthis) => mthis["ondrag"];

  ondrag_Setter_(mthis, __arg_0) => mthis["ondrag"] = __arg_0;

  ondragend_Getter_(mthis) => mthis["ondragend"];

  ondragend_Setter_(mthis, __arg_0) => mthis["ondragend"] = __arg_0;

  ondragenter_Getter_(mthis) => mthis["ondragenter"];

  ondragenter_Setter_(mthis, __arg_0) => mthis["ondragenter"] = __arg_0;

  ondragleave_Getter_(mthis) => mthis["ondragleave"];

  ondragleave_Setter_(mthis, __arg_0) => mthis["ondragleave"] = __arg_0;

  ondragover_Getter_(mthis) => mthis["ondragover"];

  ondragover_Setter_(mthis, __arg_0) => mthis["ondragover"] = __arg_0;

  ondragstart_Getter_(mthis) => mthis["ondragstart"];

  ondragstart_Setter_(mthis, __arg_0) => mthis["ondragstart"] = __arg_0;

  ondrop_Getter_(mthis) => mthis["ondrop"];

  ondrop_Setter_(mthis, __arg_0) => mthis["ondrop"] = __arg_0;

  ondurationchange_Getter_(mthis) => mthis["ondurationchange"];

  ondurationchange_Setter_(mthis, __arg_0) => mthis["ondurationchange"] = __arg_0;

  onemptied_Getter_(mthis) => mthis["onemptied"];

  onemptied_Setter_(mthis, __arg_0) => mthis["onemptied"] = __arg_0;

  onended_Getter_(mthis) => mthis["onended"];

  onended_Setter_(mthis, __arg_0) => mthis["onended"] = __arg_0;

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onfocus_Getter_(mthis) => mthis["onfocus"];

  onfocus_Setter_(mthis, __arg_0) => mthis["onfocus"] = __arg_0;

  onhashchange_Getter_(mthis) => mthis["onhashchange"];

  onhashchange_Setter_(mthis, __arg_0) => mthis["onhashchange"] = __arg_0;

  oninput_Getter_(mthis) => mthis["oninput"];

  oninput_Setter_(mthis, __arg_0) => mthis["oninput"] = __arg_0;

  oninvalid_Getter_(mthis) => mthis["oninvalid"];

  oninvalid_Setter_(mthis, __arg_0) => mthis["oninvalid"] = __arg_0;

  onkeydown_Getter_(mthis) => mthis["onkeydown"];

  onkeydown_Setter_(mthis, __arg_0) => mthis["onkeydown"] = __arg_0;

  onkeypress_Getter_(mthis) => mthis["onkeypress"];

  onkeypress_Setter_(mthis, __arg_0) => mthis["onkeypress"] = __arg_0;

  onkeyup_Getter_(mthis) => mthis["onkeyup"];

  onkeyup_Setter_(mthis, __arg_0) => mthis["onkeyup"] = __arg_0;

  onlanguagechange_Getter_(mthis) => mthis["onlanguagechange"];

  onlanguagechange_Setter_(mthis, __arg_0) => mthis["onlanguagechange"] = __arg_0;

  onload_Getter_(mthis) => mthis["onload"];

  onload_Setter_(mthis, __arg_0) => mthis["onload"] = __arg_0;

  onloadeddata_Getter_(mthis) => mthis["onloadeddata"];

  onloadeddata_Setter_(mthis, __arg_0) => mthis["onloadeddata"] = __arg_0;

  onloadedmetadata_Getter_(mthis) => mthis["onloadedmetadata"];

  onloadedmetadata_Setter_(mthis, __arg_0) => mthis["onloadedmetadata"] = __arg_0;

  onloadstart_Getter_(mthis) => mthis["onloadstart"];

  onloadstart_Setter_(mthis, __arg_0) => mthis["onloadstart"] = __arg_0;

  onmessage_Getter_(mthis) => mthis["onmessage"];

  onmessage_Setter_(mthis, __arg_0) => mthis["onmessage"] = __arg_0;

  onmousedown_Getter_(mthis) => mthis["onmousedown"];

  onmousedown_Setter_(mthis, __arg_0) => mthis["onmousedown"] = __arg_0;

  onmouseenter_Getter_(mthis) => mthis["onmouseenter"];

  onmouseenter_Setter_(mthis, __arg_0) => mthis["onmouseenter"] = __arg_0;

  onmouseleave_Getter_(mthis) => mthis["onmouseleave"];

  onmouseleave_Setter_(mthis, __arg_0) => mthis["onmouseleave"] = __arg_0;

  onmousemove_Getter_(mthis) => mthis["onmousemove"];

  onmousemove_Setter_(mthis, __arg_0) => mthis["onmousemove"] = __arg_0;

  onmouseout_Getter_(mthis) => mthis["onmouseout"];

  onmouseout_Setter_(mthis, __arg_0) => mthis["onmouseout"] = __arg_0;

  onmouseover_Getter_(mthis) => mthis["onmouseover"];

  onmouseover_Setter_(mthis, __arg_0) => mthis["onmouseover"] = __arg_0;

  onmouseup_Getter_(mthis) => mthis["onmouseup"];

  onmouseup_Setter_(mthis, __arg_0) => mthis["onmouseup"] = __arg_0;

  onmousewheel_Getter_(mthis) => mthis["onmousewheel"];

  onmousewheel_Setter_(mthis, __arg_0) => mthis["onmousewheel"] = __arg_0;

  onoffline_Getter_(mthis) => mthis["onoffline"];

  onoffline_Setter_(mthis, __arg_0) => mthis["onoffline"] = __arg_0;

  ononline_Getter_(mthis) => mthis["ononline"];

  ononline_Setter_(mthis, __arg_0) => mthis["ononline"] = __arg_0;

  onorientationchange_Getter_(mthis) => mthis["onorientationchange"];

  onorientationchange_Setter_(mthis, __arg_0) => mthis["onorientationchange"] = __arg_0;

  onpagehide_Getter_(mthis) => mthis["onpagehide"];

  onpagehide_Setter_(mthis, __arg_0) => mthis["onpagehide"] = __arg_0;

  onpageshow_Getter_(mthis) => mthis["onpageshow"];

  onpageshow_Setter_(mthis, __arg_0) => mthis["onpageshow"] = __arg_0;

  onpause_Getter_(mthis) => mthis["onpause"];

  onpause_Setter_(mthis, __arg_0) => mthis["onpause"] = __arg_0;

  onplay_Getter_(mthis) => mthis["onplay"];

  onplay_Setter_(mthis, __arg_0) => mthis["onplay"] = __arg_0;

  onplaying_Getter_(mthis) => mthis["onplaying"];

  onplaying_Setter_(mthis, __arg_0) => mthis["onplaying"] = __arg_0;

  onpopstate_Getter_(mthis) => mthis["onpopstate"];

  onpopstate_Setter_(mthis, __arg_0) => mthis["onpopstate"] = __arg_0;

  onprogress_Getter_(mthis) => mthis["onprogress"];

  onprogress_Setter_(mthis, __arg_0) => mthis["onprogress"] = __arg_0;

  onratechange_Getter_(mthis) => mthis["onratechange"];

  onratechange_Setter_(mthis, __arg_0) => mthis["onratechange"] = __arg_0;

  onreset_Getter_(mthis) => mthis["onreset"];

  onreset_Setter_(mthis, __arg_0) => mthis["onreset"] = __arg_0;

  onresize_Getter_(mthis) => mthis["onresize"];

  onresize_Setter_(mthis, __arg_0) => mthis["onresize"] = __arg_0;

  onscroll_Getter_(mthis) => mthis["onscroll"];

  onscroll_Setter_(mthis, __arg_0) => mthis["onscroll"] = __arg_0;

  onsearch_Getter_(mthis) => mthis["onsearch"];

  onsearch_Setter_(mthis, __arg_0) => mthis["onsearch"] = __arg_0;

  onseeked_Getter_(mthis) => mthis["onseeked"];

  onseeked_Setter_(mthis, __arg_0) => mthis["onseeked"] = __arg_0;

  onseeking_Getter_(mthis) => mthis["onseeking"];

  onseeking_Setter_(mthis, __arg_0) => mthis["onseeking"] = __arg_0;

  onselect_Getter_(mthis) => mthis["onselect"];

  onselect_Setter_(mthis, __arg_0) => mthis["onselect"] = __arg_0;

  onshow_Getter_(mthis) => mthis["onshow"];

  onshow_Setter_(mthis, __arg_0) => mthis["onshow"] = __arg_0;

  onstalled_Getter_(mthis) => mthis["onstalled"];

  onstalled_Setter_(mthis, __arg_0) => mthis["onstalled"] = __arg_0;

  onstorage_Getter_(mthis) => mthis["onstorage"];

  onstorage_Setter_(mthis, __arg_0) => mthis["onstorage"] = __arg_0;

  onsubmit_Getter_(mthis) => mthis["onsubmit"];

  onsubmit_Setter_(mthis, __arg_0) => mthis["onsubmit"] = __arg_0;

  onsuspend_Getter_(mthis) => mthis["onsuspend"];

  onsuspend_Setter_(mthis, __arg_0) => mthis["onsuspend"] = __arg_0;

  ontimeupdate_Getter_(mthis) => mthis["ontimeupdate"];

  ontimeupdate_Setter_(mthis, __arg_0) => mthis["ontimeupdate"] = __arg_0;

  ontoggle_Getter_(mthis) => mthis["ontoggle"];

  ontoggle_Setter_(mthis, __arg_0) => mthis["ontoggle"] = __arg_0;

  ontouchcancel_Getter_(mthis) => mthis["ontouchcancel"];

  ontouchcancel_Setter_(mthis, __arg_0) => mthis["ontouchcancel"] = __arg_0;

  ontouchend_Getter_(mthis) => mthis["ontouchend"];

  ontouchend_Setter_(mthis, __arg_0) => mthis["ontouchend"] = __arg_0;

  ontouchmove_Getter_(mthis) => mthis["ontouchmove"];

  ontouchmove_Setter_(mthis, __arg_0) => mthis["ontouchmove"] = __arg_0;

  ontouchstart_Getter_(mthis) => mthis["ontouchstart"];

  ontouchstart_Setter_(mthis, __arg_0) => mthis["ontouchstart"] = __arg_0;

  ontransitionend_Getter_(mthis) => mthis["ontransitionend"];

  ontransitionend_Setter_(mthis, __arg_0) => mthis["ontransitionend"] = __arg_0;

  onunload_Getter_(mthis) => mthis["onunload"];

  onunload_Setter_(mthis, __arg_0) => mthis["onunload"] = __arg_0;

  onvolumechange_Getter_(mthis) => mthis["onvolumechange"];

  onvolumechange_Setter_(mthis, __arg_0) => mthis["onvolumechange"] = __arg_0;

  onwaiting_Getter_(mthis) => mthis["onwaiting"];

  onwaiting_Setter_(mthis, __arg_0) => mthis["onwaiting"] = __arg_0;

  onwebkitanimationend_Getter_(mthis) => mthis["onwebkitanimationend"];

  onwebkitanimationend_Setter_(mthis, __arg_0) => mthis["onwebkitanimationend"] = __arg_0;

  onwebkitanimationiteration_Getter_(mthis) => mthis["onwebkitanimationiteration"];

  onwebkitanimationiteration_Setter_(mthis, __arg_0) => mthis["onwebkitanimationiteration"] = __arg_0;

  onwebkitanimationstart_Getter_(mthis) => mthis["onwebkitanimationstart"];

  onwebkitanimationstart_Setter_(mthis, __arg_0) => mthis["onwebkitanimationstart"] = __arg_0;

  onwebkittransitionend_Getter_(mthis) => mthis["onwebkittransitionend"];

  onwebkittransitionend_Setter_(mthis, __arg_0) => mthis["onwebkittransitionend"] = __arg_0;

  onwheel_Getter_(mthis) => mthis["onwheel"];

  onwheel_Setter_(mthis, __arg_0) => mthis["onwheel"] = __arg_0;

  openDatabase_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("openDatabase", [__arg_0, __arg_1]);

  openDatabase_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("openDatabase", [__arg_0, __arg_1, __arg_2]);

  openDatabase_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("openDatabase", [__arg_0, __arg_1, __arg_2, __arg_3]);

  openDatabase_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("openDatabase", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  open_Callback_0_(mthis) => mthis.callMethod("open", []);

  open_Callback_1_(mthis, __arg_0) => mthis.callMethod("open", [__arg_0]);

  open_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("open", [__arg_0, __arg_1]);

  open_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("open", [__arg_0, __arg_1, __arg_2]);

  opener_Getter_(mthis) => mthis["opener"];

  opener_Setter_(mthis, __arg_0) => mthis["opener"] = __arg_0;

  orientation_Getter_(mthis) => mthis["orientation"];

  outerHeight_Getter_(mthis) => mthis["outerHeight"];

  outerWidth_Getter_(mthis) => mthis["outerWidth"];

  pageXOffset_Getter_(mthis) => mthis["pageXOffset"];

  pageYOffset_Getter_(mthis) => mthis["pageYOffset"];

  parent_Getter_(mthis) => mthis["parent"];

  performance_Getter_(mthis) => mthis["performance"];

  personalbar_Getter_(mthis) => mthis["personalbar"];

  postMessage_Callback_0_(mthis) => mthis.callMethod("postMessage", []);

  postMessage_Callback_1_(mthis, __arg_0) => mthis.callMethod("postMessage", [__arg_0]);

  postMessage_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("postMessage", [__arg_0, __arg_1]);

  postMessage_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("postMessage", [__arg_0, __arg_1, __arg_2]);

  print_Callback_0_(mthis) => mthis.callMethod("print", []);

  releaseEvents_Callback_0_(mthis) => mthis.callMethod("releaseEvents", []);

  requestAnimationFrame_Callback_0_(mthis) => mthis.callMethod("requestAnimationFrame", []);

  requestAnimationFrame_Callback_1_(mthis, __arg_0) => mthis.callMethod("requestAnimationFrame", [__arg_0]);

  resizeBy_Callback_0_(mthis) => mthis.callMethod("resizeBy", []);

  resizeBy_Callback_1_(mthis, __arg_0) => mthis.callMethod("resizeBy", [__arg_0]);

  resizeBy_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("resizeBy", [__arg_0, __arg_1]);

  resizeTo_Callback_0_(mthis) => mthis.callMethod("resizeTo", []);

  resizeTo_Callback_1_(mthis, __arg_0) => mthis.callMethod("resizeTo", [__arg_0]);

  resizeTo_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("resizeTo", [__arg_0, __arg_1]);

  screenLeft_Getter_(mthis) => mthis["screenLeft"];

  screenTop_Getter_(mthis) => mthis["screenTop"];

  screenX_Getter_(mthis) => mthis["screenX"];

  screenY_Getter_(mthis) => mthis["screenY"];

  screen_Getter_(mthis) => mthis["screen"];

  scrollBy_Callback_0_(mthis) => mthis.callMethod("scrollBy", []);

  scrollBy_Callback_1_(mthis, __arg_0) => mthis.callMethod("scrollBy", [__arg_0]);

  scrollBy_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("scrollBy", [__arg_0, __arg_1]);

  scrollBy_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("scrollBy", [__arg_0, __arg_1, __arg_2]);

  scrollTo_Callback_0_(mthis) => mthis.callMethod("scrollTo", []);

  scrollTo_Callback_1_(mthis, __arg_0) => mthis.callMethod("scrollTo", [__arg_0]);

  scrollTo_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("scrollTo", [__arg_0, __arg_1]);

  scrollTo_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("scrollTo", [__arg_0, __arg_1, __arg_2]);

  scrollX_Getter_(mthis) => mthis["scrollX"];

  scrollY_Getter_(mthis) => mthis["scrollY"];

  scroll_Callback_0_(mthis) => mthis.callMethod("scroll", []);

  scroll_Callback_1_(mthis, __arg_0) => mthis.callMethod("scroll", [__arg_0]);

  scroll_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("scroll", [__arg_0, __arg_1]);

  scroll_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("scroll", [__arg_0, __arg_1, __arg_2]);

  scrollbars_Getter_(mthis) => mthis["scrollbars"];

  self_Getter_(mthis) => mthis["self"];

  sessionStorage_Getter_(mthis) => mthis["sessionStorage"];

  setInterval_Callback_0_(mthis) => mthis.callMethod("setInterval", []);

  setInterval_Callback_1_(mthis, __arg_0) => mthis.callMethod("setInterval", [__arg_0]);

  setInterval_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setInterval", [__arg_0, __arg_1]);

  setTimeout_Callback_0_(mthis) => mthis.callMethod("setTimeout", []);

  setTimeout_Callback_1_(mthis, __arg_0) => mthis.callMethod("setTimeout", [__arg_0]);

  setTimeout_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setTimeout", [__arg_0, __arg_1]);

  showModalDialog_Callback_0_(mthis) => mthis.callMethod("showModalDialog", []);

  showModalDialog_Callback_1_(mthis, __arg_0) => mthis.callMethod("showModalDialog", [__arg_0]);

  showModalDialog_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("showModalDialog", [__arg_0, __arg_1]);

  showModalDialog_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("showModalDialog", [__arg_0, __arg_1, __arg_2]);

  speechSynthesis_Getter_(mthis) => mthis["speechSynthesis"];

  status_Getter_(mthis) => mthis["status"];

  status_Setter_(mthis, __arg_0) => mthis["status"] = __arg_0;

  statusbar_Getter_(mthis) => mthis["statusbar"];

  stop_Callback_0_(mthis) => mthis.callMethod("stop", []);

  styleMedia_Getter_(mthis) => mthis["styleMedia"];

  toolbar_Getter_(mthis) => mthis["toolbar"];

  top_Getter_(mthis) => mthis["top"];

  webkitRequestFileSystem_Callback_1_(mthis, __arg_0) => mthis.callMethod("webkitRequestFileSystem", [__arg_0]);

  webkitRequestFileSystem_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("webkitRequestFileSystem", [__arg_0, __arg_1]);

  webkitRequestFileSystem_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("webkitRequestFileSystem", [__arg_0, __arg_1, __arg_2]);

  webkitRequestFileSystem_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("webkitRequestFileSystem", [__arg_0, __arg_1, __arg_2, __arg_3]);

  webkitResolveLocalFileSystemURL_Callback_0_(mthis) => mthis.callMethod("webkitResolveLocalFileSystemURL", []);

  webkitResolveLocalFileSystemURL_Callback_1_(mthis, __arg_0) => mthis.callMethod("webkitResolveLocalFileSystemURL", [__arg_0]);

  webkitResolveLocalFileSystemURL_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("webkitResolveLocalFileSystemURL", [__arg_0, __arg_1]);

  webkitResolveLocalFileSystemURL_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("webkitResolveLocalFileSystemURL", [__arg_0, __arg_1, __arg_2]);

  webkitStorageInfo_Getter_(mthis) => mthis["webkitStorageInfo"];

  window_Getter_(mthis) => mthis["window"];

}

class BlinkWorker extends BlinkEventTarget {
  static final instance = new BlinkWorker();

  constructorCallback_0_() => new js.JsObject(js.context["Worker"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["Worker"], [__arg_0]);

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onmessage_Getter_(mthis) => mthis["onmessage"];

  onmessage_Setter_(mthis, __arg_0) => mthis["onmessage"] = __arg_0;

  postMessage_Callback_0_(mthis) => mthis.callMethod("postMessage", []);

  postMessage_Callback_1_(mthis, __arg_0) => mthis.callMethod("postMessage", [__arg_0]);

  postMessage_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("postMessage", [__arg_0, __arg_1]);

  terminate_Callback_0_(mthis) => mthis.callMethod("terminate", []);

}

class BlinkWorkerConsole extends BlinkConsoleBase {
  static final instance = new BlinkWorkerConsole();

}

class BlinkWorkerGlobalScope extends BlinkEventTarget {
  static final instance = new BlinkWorkerGlobalScope();

  atob_Callback_0_(mthis) => mthis.callMethod("atob", []);

  atob_Callback_1_(mthis, __arg_0) => mthis.callMethod("atob", [__arg_0]);

  btoa_Callback_0_(mthis) => mthis.callMethod("btoa", []);

  btoa_Callback_1_(mthis, __arg_0) => mthis.callMethod("btoa", [__arg_0]);

  clearInterval_Callback_0_(mthis) => mthis.callMethod("clearInterval", []);

  clearInterval_Callback_1_(mthis, __arg_0) => mthis.callMethod("clearInterval", [__arg_0]);

  clearTimeout_Callback_0_(mthis) => mthis.callMethod("clearTimeout", []);

  clearTimeout_Callback_1_(mthis, __arg_0) => mthis.callMethod("clearTimeout", [__arg_0]);

  close_Callback_0_(mthis) => mthis.callMethod("close", []);

  console_Getter_(mthis) => mthis["console"];

  createImageBitmap_Callback_0_(mthis) => mthis.callMethod("createImageBitmap", []);

  createImageBitmap_Callback_1_(mthis, __arg_0) => mthis.callMethod("createImageBitmap", [__arg_0]);

  createImageBitmap_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("createImageBitmap", [__arg_0, __arg_1, __arg_2]);

  createImageBitmap_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("createImageBitmap", [__arg_0, __arg_1, __arg_2, __arg_3]);

  createImageBitmap_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("createImageBitmap", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  crypto_Getter_(mthis) => mthis["crypto"];

  importScripts_Callback_0_(mthis) => mthis.callMethod("importScripts", []);

  importScripts_Callback_1_(mthis, __arg_0) => mthis.callMethod("importScripts", [__arg_0]);

  indexedDB_Getter_(mthis) => mthis["indexedDB"];

  location_Getter_(mthis) => mthis["location"];

  navigator_Getter_(mthis) => mthis["navigator"];

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  performance_Getter_(mthis) => mthis["performance"];

  self_Getter_(mthis) => mthis["self"];

  setInterval_Callback_0_(mthis) => mthis.callMethod("setInterval", []);

  setInterval_Callback_1_(mthis, __arg_0) => mthis.callMethod("setInterval", [__arg_0]);

  setInterval_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setInterval", [__arg_0, __arg_1]);

  setTimeout_Callback_0_(mthis) => mthis.callMethod("setTimeout", []);

  setTimeout_Callback_1_(mthis, __arg_0) => mthis.callMethod("setTimeout", [__arg_0]);

  setTimeout_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setTimeout", [__arg_0, __arg_1]);

  webkitRequestFileSystemSync_Callback_0_(mthis) => mthis.callMethod("webkitRequestFileSystemSync", []);

  webkitRequestFileSystemSync_Callback_1_(mthis, __arg_0) => mthis.callMethod("webkitRequestFileSystemSync", [__arg_0]);

  webkitRequestFileSystemSync_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("webkitRequestFileSystemSync", [__arg_0, __arg_1]);

  webkitRequestFileSystem_Callback_0_(mthis) => mthis.callMethod("webkitRequestFileSystem", []);

  webkitRequestFileSystem_Callback_1_(mthis, __arg_0) => mthis.callMethod("webkitRequestFileSystem", [__arg_0]);

  webkitRequestFileSystem_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("webkitRequestFileSystem", [__arg_0, __arg_1]);

  webkitRequestFileSystem_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("webkitRequestFileSystem", [__arg_0, __arg_1, __arg_2]);

  webkitRequestFileSystem_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("webkitRequestFileSystem", [__arg_0, __arg_1, __arg_2, __arg_3]);

  webkitResolveLocalFileSystemSyncURL_Callback_0_(mthis) => mthis.callMethod("webkitResolveLocalFileSystemSyncURL", []);

  webkitResolveLocalFileSystemSyncURL_Callback_1_(mthis, __arg_0) => mthis.callMethod("webkitResolveLocalFileSystemSyncURL", [__arg_0]);

  webkitResolveLocalFileSystemURL_Callback_0_(mthis) => mthis.callMethod("webkitResolveLocalFileSystemURL", []);

  webkitResolveLocalFileSystemURL_Callback_1_(mthis, __arg_0) => mthis.callMethod("webkitResolveLocalFileSystemURL", [__arg_0]);

  webkitResolveLocalFileSystemURL_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("webkitResolveLocalFileSystemURL", [__arg_0, __arg_1]);

  webkitResolveLocalFileSystemURL_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("webkitResolveLocalFileSystemURL", [__arg_0, __arg_1, __arg_2]);

}

class BlinkWorkerLocation {
  static final instance = new BlinkWorkerLocation();

  hash_Getter_(mthis) => mthis["hash"];

  host_Getter_(mthis) => mthis["host"];

  hostname_Getter_(mthis) => mthis["hostname"];

  href_Getter_(mthis) => mthis["href"];

  origin_Getter_(mthis) => mthis["origin"];

  pathname_Getter_(mthis) => mthis["pathname"];

  port_Getter_(mthis) => mthis["port"];

  protocol_Getter_(mthis) => mthis["protocol"];

  search_Getter_(mthis) => mthis["search"];

  toString_Callback_0_(mthis) => mthis.callMethod("toString", []);

}

class BlinkWorkerNavigator {
  static final instance = new BlinkWorkerNavigator();

  appCodeName_Getter_(mthis) => mthis["appCodeName"];

  appName_Getter_(mthis) => mthis["appName"];

  appVersion_Getter_(mthis) => mthis["appVersion"];

  connection_Getter_(mthis) => mthis["connection"];

  dartEnabled_Getter_(mthis) => mthis["dartEnabled"];

  geofencing_Getter_(mthis) => mthis["geofencing"];

  hardwareConcurrency_Getter_(mthis) => mthis["hardwareConcurrency"];

  onLine_Getter_(mthis) => mthis["onLine"];

  platform_Getter_(mthis) => mthis["platform"];

  product_Getter_(mthis) => mthis["product"];

  userAgent_Getter_(mthis) => mthis["userAgent"];

  webkitPersistentStorage_Getter_(mthis) => mthis["webkitPersistentStorage"];

  webkitTemporaryStorage_Getter_(mthis) => mthis["webkitTemporaryStorage"];

}

class BlinkWorkerPerformance {
  static final instance = new BlinkWorkerPerformance();

  memory_Getter_(mthis) => mthis["memory"];

  now_Callback_0_(mthis) => mthis.callMethod("now", []);

}

class BlinkXMLDocument extends BlinkDocument {
  static final instance = new BlinkXMLDocument();

}

class BlinkXMLHttpRequest extends BlinkXMLHttpRequestEventTarget {
  static final instance = new BlinkXMLHttpRequest();

  abort_Callback_0_(mthis) => mthis.callMethod("abort", []);

  constructorCallback_0_() => new js.JsObject(js.context["XMLHttpRequest"], []);

  constructorCallback_1_(__arg_0) => new js.JsObject(js.context["XMLHttpRequest"], [__arg_0]);

  getAllResponseHeaders_Callback_0_(mthis) => mthis.callMethod("getAllResponseHeaders", []);

  getResponseHeader_Callback_0_(mthis) => mthis.callMethod("getResponseHeader", []);

  getResponseHeader_Callback_1_(mthis, __arg_0) => mthis.callMethod("getResponseHeader", [__arg_0]);

  onreadystatechange_Getter_(mthis) => mthis["onreadystatechange"];

  onreadystatechange_Setter_(mthis, __arg_0) => mthis["onreadystatechange"] = __arg_0;

  open_Callback_0_(mthis) => mthis.callMethod("open", []);

  open_Callback_1_(mthis, __arg_0) => mthis.callMethod("open", [__arg_0]);

  open_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("open", [__arg_0, __arg_1]);

  open_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("open", [__arg_0, __arg_1, __arg_2]);

  open_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("open", [__arg_0, __arg_1, __arg_2, __arg_3]);

  open_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("open", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

  overrideMimeType_Callback_0_(mthis) => mthis.callMethod("overrideMimeType", []);

  overrideMimeType_Callback_1_(mthis, __arg_0) => mthis.callMethod("overrideMimeType", [__arg_0]);

  readyState_Getter_(mthis) => mthis["readyState"];

  responseText_Getter_(mthis) => mthis["responseText"];

  responseType_Getter_(mthis) => mthis["responseType"];

  responseType_Setter_(mthis, __arg_0) => mthis["responseType"] = __arg_0;

  responseURL_Getter_(mthis) => mthis["responseURL"];

  responseXML_Getter_(mthis) => mthis["responseXML"];

  response_Getter_(mthis) => mthis["response"];

  send_Callback_0_(mthis) => mthis.callMethod("send", []);

  send_Callback_1_(mthis, __arg_0) => mthis.callMethod("send", [__arg_0]);

  setRequestHeader_Callback_0_(mthis) => mthis.callMethod("setRequestHeader", []);

  setRequestHeader_Callback_1_(mthis, __arg_0) => mthis.callMethod("setRequestHeader", [__arg_0]);

  setRequestHeader_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setRequestHeader", [__arg_0, __arg_1]);

  statusText_Getter_(mthis) => mthis["statusText"];

  status_Getter_(mthis) => mthis["status"];

  timeout_Getter_(mthis) => mthis["timeout"];

  timeout_Setter_(mthis, __arg_0) => mthis["timeout"] = __arg_0;

  upload_Getter_(mthis) => mthis["upload"];

  withCredentials_Getter_(mthis) => mthis["withCredentials"];

  withCredentials_Setter_(mthis, __arg_0) => mthis["withCredentials"] = __arg_0;

}

class BlinkXMLHttpRequestEventTarget extends BlinkEventTarget {
  static final instance = new BlinkXMLHttpRequestEventTarget();

  onabort_Getter_(mthis) => mthis["onabort"];

  onabort_Setter_(mthis, __arg_0) => mthis["onabort"] = __arg_0;

  onerror_Getter_(mthis) => mthis["onerror"];

  onerror_Setter_(mthis, __arg_0) => mthis["onerror"] = __arg_0;

  onload_Getter_(mthis) => mthis["onload"];

  onload_Setter_(mthis, __arg_0) => mthis["onload"] = __arg_0;

  onloadend_Getter_(mthis) => mthis["onloadend"];

  onloadend_Setter_(mthis, __arg_0) => mthis["onloadend"] = __arg_0;

  onloadstart_Getter_(mthis) => mthis["onloadstart"];

  onloadstart_Setter_(mthis, __arg_0) => mthis["onloadstart"] = __arg_0;

  onprogress_Getter_(mthis) => mthis["onprogress"];

  onprogress_Setter_(mthis, __arg_0) => mthis["onprogress"] = __arg_0;

  ontimeout_Getter_(mthis) => mthis["ontimeout"];

  ontimeout_Setter_(mthis, __arg_0) => mthis["ontimeout"] = __arg_0;

}

class BlinkXMLHttpRequestProgressEvent extends BlinkProgressEvent {
  static final instance = new BlinkXMLHttpRequestProgressEvent();

  position_Getter_(mthis) => mthis["position"];

  totalSize_Getter_(mthis) => mthis["totalSize"];

}

class BlinkXMLHttpRequestUpload extends BlinkXMLHttpRequestEventTarget {
  static final instance = new BlinkXMLHttpRequestUpload();

}

class BlinkXMLSerializer {
  static final instance = new BlinkXMLSerializer();

  constructorCallback_0_() => new js.JsObject(js.context["XMLSerializer"], []);

  serializeToString_Callback_0_(mthis) => mthis.callMethod("serializeToString", []);

  serializeToString_Callback_1_(mthis, __arg_0) => mthis.callMethod("serializeToString", [__arg_0]);

}

class BlinkXPathEvaluator {
  static final instance = new BlinkXPathEvaluator();

  constructorCallback_0_() => new js.JsObject(js.context["XPathEvaluator"], []);

  createExpression_Callback_0_(mthis) => mthis.callMethod("createExpression", []);

  createExpression_Callback_1_(mthis, __arg_0) => mthis.callMethod("createExpression", [__arg_0]);

  createExpression_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("createExpression", [__arg_0, __arg_1]);

  createNSResolver_Callback_0_(mthis) => mthis.callMethod("createNSResolver", []);

  createNSResolver_Callback_1_(mthis, __arg_0) => mthis.callMethod("createNSResolver", [__arg_0]);

  evaluate_Callback_0_(mthis) => mthis.callMethod("evaluate", []);

  evaluate_Callback_1_(mthis, __arg_0) => mthis.callMethod("evaluate", [__arg_0]);

  evaluate_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("evaluate", [__arg_0, __arg_1]);

  evaluate_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("evaluate", [__arg_0, __arg_1, __arg_2]);

  evaluate_Callback_4_(mthis, __arg_0, __arg_1, __arg_2, __arg_3) => mthis.callMethod("evaluate", [__arg_0, __arg_1, __arg_2, __arg_3]);

  evaluate_Callback_5_(mthis, __arg_0, __arg_1, __arg_2, __arg_3, __arg_4) => mthis.callMethod("evaluate", [__arg_0, __arg_1, __arg_2, __arg_3, __arg_4]);

}

class BlinkXPathExpression {
  static final instance = new BlinkXPathExpression();

  evaluate_Callback_0_(mthis) => mthis.callMethod("evaluate", []);

  evaluate_Callback_1_(mthis, __arg_0) => mthis.callMethod("evaluate", [__arg_0]);

  evaluate_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("evaluate", [__arg_0, __arg_1]);

  evaluate_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("evaluate", [__arg_0, __arg_1, __arg_2]);

}

class BlinkXPathNSResolver {
  static final instance = new BlinkXPathNSResolver();

  lookupNamespaceURI_Callback_0_(mthis) => mthis.callMethod("lookupNamespaceURI", []);

  lookupNamespaceURI_Callback_1_(mthis, __arg_0) => mthis.callMethod("lookupNamespaceURI", [__arg_0]);

}

class BlinkXPathResult {
  static final instance = new BlinkXPathResult();

  booleanValue_Getter_(mthis) => mthis["booleanValue"];

  invalidIteratorState_Getter_(mthis) => mthis["invalidIteratorState"];

  iterateNext_Callback_0_(mthis) => mthis.callMethod("iterateNext", []);

  numberValue_Getter_(mthis) => mthis["numberValue"];

  resultType_Getter_(mthis) => mthis["resultType"];

  singleNodeValue_Getter_(mthis) => mthis["singleNodeValue"];

  snapshotItem_Callback_0_(mthis) => mthis.callMethod("snapshotItem", []);

  snapshotItem_Callback_1_(mthis, __arg_0) => mthis.callMethod("snapshotItem", [__arg_0]);

  snapshotLength_Getter_(mthis) => mthis["snapshotLength"];

  stringValue_Getter_(mthis) => mthis["stringValue"];

}

class BlinkXSLTProcessor {
  static final instance = new BlinkXSLTProcessor();

  clearParameters_Callback_0_(mthis) => mthis.callMethod("clearParameters", []);

  constructorCallback_0_() => new js.JsObject(js.context["XSLTProcessor"], []);

  getParameter_Callback_0_(mthis) => mthis.callMethod("getParameter", []);

  getParameter_Callback_1_(mthis, __arg_0) => mthis.callMethod("getParameter", [__arg_0]);

  getParameter_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("getParameter", [__arg_0, __arg_1]);

  importStylesheet_Callback_0_(mthis) => mthis.callMethod("importStylesheet", []);

  importStylesheet_Callback_1_(mthis, __arg_0) => mthis.callMethod("importStylesheet", [__arg_0]);

  removeParameter_Callback_0_(mthis) => mthis.callMethod("removeParameter", []);

  removeParameter_Callback_1_(mthis, __arg_0) => mthis.callMethod("removeParameter", [__arg_0]);

  removeParameter_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("removeParameter", [__arg_0, __arg_1]);

  reset_Callback_0_(mthis) => mthis.callMethod("reset", []);

  setParameter_Callback_1_(mthis, __arg_0) => mthis.callMethod("setParameter", [__arg_0]);

  setParameter_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("setParameter", [__arg_0, __arg_1]);

  setParameter_Callback_3_(mthis, __arg_0, __arg_1, __arg_2) => mthis.callMethod("setParameter", [__arg_0, __arg_1, __arg_2]);

  transformToDocument_Callback_0_(mthis) => mthis.callMethod("transformToDocument", []);

  transformToDocument_Callback_1_(mthis, __arg_0) => mthis.callMethod("transformToDocument", [__arg_0]);

  transformToFragment_Callback_0_(mthis) => mthis.callMethod("transformToFragment", []);

  transformToFragment_Callback_1_(mthis, __arg_0) => mthis.callMethod("transformToFragment", [__arg_0]);

  transformToFragment_Callback_2_(mthis, __arg_0, __arg_1) => mthis.callMethod("transformToFragment", [__arg_0, __arg_1]);

}


// _Utils native entry points
class Blink_Utils {
  static window() native "Utils_window";

  static forwardingPrint(message) native "Utils_forwardingPrint";

  static spawnDomUri(uri) native "Utils_spawnDomUri";

  static void spawnDomHelper(Function f, int replyTo) native "Utils_spawnDomHelper";

  static register(document, tag, customType, extendsTagName) native "Utils_register";

  static createElement(document, tagName) native "Utils_createElement";

  static constructElement(element_type, jsObject) native "Utils_constructor_create";

  static initializeCustomElement(element) native "Utils_initializeCustomElement";

  static changeElementWrapper(element, type) native "Utils_changeElementWrapper";
}

class Blink_DOMWindowCrossFrame {
  // FIXME: Return to using explicit cross frame entry points after roll to M35
  static get_history(_DOMWindowCrossFrame) native "Window_history_cross_frame_Getter";

  static get_location(_DOMWindowCrossFrame) native "Window_location_cross_frame_Getter";

  static get_closed(_DOMWindowCrossFrame) native "Window_closed_Getter";

  static get_opener(_DOMWindowCrossFrame) native "Window_opener_Getter";

  static get_parent(_DOMWindowCrossFrame) native "Window_parent_Getter";

  static get_top(_DOMWindowCrossFrame) native "Window_top_Getter";

  static close(_DOMWindowCrossFrame) native "Window_close_Callback";

  static postMessage(_DOMWindowCrossFrame, message, targetOrigin, [messagePorts]) native "Window_postMessage_Callback";
}

class Blink_HistoryCrossFrame {
  // _HistoryCrossFrame native entry points
  static back(_HistoryCrossFrame) native "History_back_Callback";

  static forward(_HistoryCrossFrame) native "History_forward_Callback";

  static go(_HistoryCrossFrame, distance) native "History_go_Callback";
}

class Blink_LocationCrossFrame {
  // _LocationCrossFrame native entry points
  static set_href(_LocationCrossFrame, h) native "Location_href_Setter";
}

class Blink_DOMStringMap {
  // _DOMStringMap native entry  points
  static containsKey(_DOMStringMap, key) native "DOMStringMap_containsKey_Callback";

  static item(_DOMStringMap, key) native "DOMStringMap_item_Callback";

  static setItem(_DOMStringMap, key, value) native "DOMStringMap_setItem_Callback";

  static remove(_DOMStringMap, key) native "DOMStringMap_remove_Callback";

  static get_keys(_DOMStringMap) native "DOMStringMap_getKeys_Callback";
}
