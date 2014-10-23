#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
import logging
import monitored
import re

typed_array_renames = {
    'ArrayBuffer': 'ByteBuffer',
    'ArrayBufferView': 'TypedData',
    'DataView': 'ByteData',
    'Float32Array': 'Float32List',
    'Float64Array': 'Float64List',
    'Int8Array': 'Int8List',
    'Int16Array': 'Int16List',
    'Int32Array': 'Int32List',
    'Uint8Array': 'Uint8List',
    'Uint8ClampedArray': 'Uint8ClampedList',
    'Uint16Array': 'Uint16List',
    'Uint32Array': 'Uint32List',
}

html_interface_renames = monitored.Dict('htmlrenamer.html_interface_renames',
                                        dict({
    'Attr': '_Attr',
    'CDATASection': 'CDataSection',
    'Clipboard': 'DataTransfer',
    'Database': 'SqlDatabase', # Avoid conflict with Index DB's Database.
    'DatabaseSync': 'SqlDatabaseSync',
    'DOMFileSystem': 'FileSystem',
    'WebKitPoint': '_DomPoint',
    'DOMRect': '_DomRect',
    'Entity': '_Entity', # Not sure if we want to expose this yet, may conflict with other libs.
    'EntryCallback': '_EntryCallback',
    'EntriesCallback': '_EntriesCallback',
    'ErrorCallback': '_ErrorCallback',
    'FileCallback': '_FileCallback',
    'FileSystemCallback': '_FileSystemCallback',
    'FileWriterCallback': '_FileWriterCallback',
    'HTMLDocument' : 'HtmlDocument',
    'HTMLElement' : 'HtmlElement',
    'HTMLHtmlElement' : 'HtmlHtmlElement',
    'IDBFactory': 'IdbFactory', # Manual to avoid name conflicts.
    'Key': 'CryptoKey',
    'NamedNodeMap': '_NamedNodeMap',
    'NavigatorUserMediaErrorCallback': '_NavigatorUserMediaErrorCallback',
    'NavigatorUserMediaSuccessCallback': '_NavigatorUserMediaSuccessCallback',
    'NotificationPermissionCallback': '_NotificationPermissionCallback',
    'PositionCallback': '_PositionCallback',
    'PositionErrorCallback': '_PositionErrorCallback',
    'Request': '_Request',
    'RTCDTMFSender': 'RtcDtmfSender',
    'RTCDTMFToneChangeEvent': 'RtcDtmfToneChangeEvent',
    'RTCErrorCallback': '_RtcErrorCallback',
    'RTCSessionDescriptionCallback': '_RtcSessionDescriptionCallback',
    'SVGDocument': 'SvgDocument', # Manual to avoid name conflicts.
    'SVGElement': 'SvgElement', # Manual to avoid name conflicts.
    'SVGGradientElement': '_GradientElement',
    'SVGSVGElement': 'SvgSvgElement', # Manual to avoid name conflicts.
    'Stream': 'FileStream',
    'StringCallback': '_StringCallback',
    'WebGLVertexArrayObjectOES': 'VertexArrayObject',
    'WindowTimers': '_WindowTimers',
    'XMLHttpRequest': 'HttpRequest',
    'XMLHttpRequestUpload': 'HttpRequestUpload',
    'XMLHttpRequestEventTarget': 'HttpRequestEventTarget',
}, **typed_array_renames))

# Interfaces that are suppressed, but need to still exist for Dartium and to
# properly wrap DOM objects if/when encountered.
_removed_html_interfaces = [
  'Cache', # TODO: Symbol conflicts with Angular: dartbug.com/20937
  'CanvasPathMethods',
  'CDataSection',
  'CSSPrimitiveValue',
  'CSSUnknownRule',
  'CSSValue',
  'Counter',
  'DOMFileSystemSync', # Workers
  'DatabaseSync', # Workers
  'DataView', # Typed arrays
  'DirectoryEntrySync', # Workers
  'DirectoryReaderSync', # Workers
  'DocumentType',
  'EntrySync', # Workers
  'FileEntrySync', # Workers
  'FileReaderSync', # Workers
  'FileWriterSync', # Workers
  'HTMLAllCollection',
  'HTMLAppletElement',
  'HTMLBaseFontElement',
  'HTMLDirectoryElement',
  'HTMLFontElement',
  'HTMLFrameElement',
  'HTMLFrameSetElement',
  'HTMLMarqueeElement',
  'IDBAny',
  'MutationEvent',
  'Notation',
  'NotificationCenter',
  'PagePopupController',
  'RGBColor',
  'RadioNodeList',  # Folded onto NodeList in dart2js.
  'Rect',
  'Response', # TODO: Symbol conflicts with Angular: dartbug.com/20937
  'ServiceWorker',
  'SQLTransactionSync', # Workers
  'SQLTransactionSyncCallback', # Workers
  'SVGAltGlyphDefElement', # Webkit only.
  'SVGAltGlyphItemElement', # Webkit only.
  'SVGAnimateColorElement', # Deprecated. Use AnimateElement instead.
  'SVGColor',
  'SVGComponentTransferFunctionElement', # Currently not supported anywhere.
  'SVGCursorElement', # Webkit only.
  'SVGFEDropShadowElement', # Webkit only for the following:
  'SVGFontElement',
  'SVGFontFaceElement',
  'SVGFontFaceFormatElement',
  'SVGFontFaceNameElement',
  'SVGFontFaceSrcElement',
  'SVGFontFaceUriElement',
  'SVGGlyphElement',
  'SVGGlyphRefElement',
  'SVGHKernElement',
  'SVGMPathElement',
  'SVGPaint',
  'SVGMissingGlyphElement',
  'SVGTRefElement',
  'SVGVKernElement',
  'SubtleCrypto',
  'WebKitCSSFilterValue',
  'WebKitCSSMatrix',
  'WebKitCSSMixFunctionValue',
  'WebKitCSSTransformValue',
  'WebKitMediaSource',
  'WebKitNotification',
  'WebGLRenderingContextBase',
  'WebKitSourceBuffer',
  'WebKitSourceBufferList',
  'WorkerLocation', # Workers
  'WorkerNavigator', # Workers
  'XMLHttpRequestProgressEvent',
]

for interface in _removed_html_interfaces:
  html_interface_renames[interface] = '_' + interface

convert_to_future_members = monitored.Set(
    'htmlrenamer.converted_to_future_members', [
  'DataTransferItem.getAsString',
  'DirectoryEntry.getDirectory',
  'DirectoryEntry.getFile',
  'DirectoryEntry.removeRecursively',
  'DirectoryReader.readEntries',
  'Entry.copyTo',
  'Entry.getMetadata',
  'Entry.getParent',
  'Entry.moveTo',
  'Entry.remove',
  'FileEntry.createWriter',
  'FileEntry.file',
  'FontLoader.notifyWhenFontsReady',
  'MediaStreamTrack.getSources',
  'Notification.requestPermission',
  'NotificationCenter.requestPermission',
  'RTCPeerConnection.setLocalDescription',
  'RTCPeerConnection.setRemoteDescription',
  'StorageInfo.requestQuota',
  'StorageQuota.requestQuota',
  'Window.webkitRequestFileSystem',
  'Window.webkitResolveLocalFileSystemURL',
  'WorkerGlobalScope.webkitRequestFileSystem',
  'WorkerGlobalScope.webkitResolveLocalFileSystemURL',
])

# Classes where we have customized constructors, but we need to keep the old
# constructor for dispatch purposes.
custom_html_constructors = monitored.Set(
    'htmlrenamer.custom_html_constructors', [
  'HTMLOptionElement',
  'MutationObserver',
])

# Members from the standard dom that should not be exposed publicly in dart:html
# but need to be exposed internally to implement dart:html on top of a standard
# browser. They are exposed simply by placing an underscore in front of the
# name.
private_html_members = monitored.Set('htmlrenamer.private_html_members', [
  'AudioContext.decodeAudioData',
  'AudioNode.connect',
  'Cache.add',
  'Cache.delete',
  'Cache.keys',
  'Cache.match',
  'Cache.matchAll',
  'Cache.put',
  'CanvasRenderingContext2D.arc',
  'CanvasRenderingContext2D.drawImage',
  'CanvasRenderingContext2D.getLineDash',
  'CSSStyleDeclaration.getPropertyValue',
  'CSSStyleDeclaration.setProperty',
  'CSSStyleDeclaration.var',
  'CompositionEvent.initCompositionEvent',
  'CustomEvent.detail',
  'CustomEvent.initCustomEvent',
  'DeviceOrientationEvent.initDeviceOrientationEvent',
  'Document.createElement',
  'Document.createEvent',
  'Document.createNodeIterator',
  'Document.createTextNode',
  'Document.createTouch',
  'Document.createTouchList',
  'Document.createTreeWalker',
  'Document.querySelectorAll',
  'DocumentFragment.querySelectorAll',

  # Moved to HTMLDocument.
  'Document.body',
  'Document.caretRangeFromPoint',
  'Document.elementFromPoint',
  'Document.getCSSCanvasContext',
  'Document.head',
  'Document.lastModified',
  'Document.preferredStylesheetSet',
  'Document.referrer',
  'Document.selectedStylesheetSet',
  'Document.styleSheets',
  'Document.title',
  'Document.webkitCancelFullScreen',
  'Document.webkitExitFullscreen',
  'Document.webkitFullscreenElement',
  'Document.webkitFullscreenEnabled',
  'Document.webkitHidden',
  'Document.webkitIsFullScreen',
  'Document.webkitPointerLockElement',
  'Document.webkitVisibilityState',

  'Element.children',
  'Element.childElementCount',
  'Element.firstElementChild',
  'Element.getElementsByTagName',
  'Element.scrollIntoView',
  'Element.scrollIntoViewIfNeeded',
  'Element.removeAttribute',
  'Element.removeAttributeNS',
  'Element.hasAttribute',
  'Element.hasAttributeNS',
  'Element.innerHTML',
  'Element.querySelectorAll',
  # TODO(vsm): These have been converted from int to double in Chrome 36.
  # Special case them so we run on 34, 35, and 36.
  'Element.offsetLeft',
  'Element.offsetTop',
  'Element.offsetWidth',
  'Element.offsetHeight',
  'Element.clientLeft',
  'Element.clientTop',
  'Element.clientWidth',
  'Element.clientHeight',
  'Element.scrollLeft',
  'Element.scrollTop',
  'Element.scrollWidth',
  'Element.scrollHeight',

  'Event.initEvent',
  'EventTarget.addEventListener',
  'EventTarget.removeEventListener',
  'FileReader.result',
  'Geolocation.clearWatch',
  'Geolocation.getCurrentPosition',
  'Geolocation.watchPosition',
  'HashChangeEvent.initHashChangeEvent',
  'HTMLCanvasElement.toDataURL',
  'HTMLTableElement.createCaption',
  'HTMLTableElement.createTFoot',
  'HTMLTableElement.createTHead',
  'HTMLTableElement.createTBody',
  'HTMLTableElement.insertRow',
  'HTMLTableElement.rows',
  'HTMLTableElement.tBodies',
  'HTMLTableRowElement.cells',
  'HTMLTableRowElement.insertCell',
  'HTMLTableSectionElement.insertRow',
  'HTMLTableSectionElement.rows',
  'IDBCursor.delete',
  'IDBCursor.update',
  'IDBDatabase.createObjectStore',
  'IDBFactory.deleteDatabase',
  'IDBFactory.webkitGetDatabaseNames',
  'IDBFactory.open',
  'IDBIndex.count',
  'IDBIndex.get',
  'IDBIndex.getKey',
  'IDBIndex.openCursor',
  'IDBIndex.openKeyCursor',
  'IDBObjectStore.add',
  'IDBObjectStore.clear',
  'IDBObjectStore.count',
  'IDBObjectStore.createIndex',
  'IDBObjectStore.delete',
  'IDBObjectStore.get',
  'IDBObjectStore.openCursor',
  'IDBObjectStore.put',
  'KeyboardEvent.initKeyboardEvent',
  'KeyboardEvent.keyIdentifier',
  'MediaKeys.createSession',
  'MediaKeySession.update',
  'MessageEvent.initMessageEvent',
  'MouseEvent.initMouseEvent',
  'MouseEvent.clientX',
  'MouseEvent.clientY',
  'MouseEvent.movementX',
  'MouseEvent.movementY',
  'MouseEvent.webkitMovementX',
  'MouseEvent.webkitMovementY',
  'MouseEvent.offsetX',
  'MouseEvent.offsetY',
  'MouseEvent.screenX',
  'MouseEvent.screenY',
  'MutationEvent.initMutationEvent',
  'MutationObserver.observe',
  'Node.attributes',
  'Node.localName',
  'Node.namespaceURI',
  'Node.removeChild',
  'Node.replaceChild',
  'ParentNode.childElementCount',
  'ParentNode.children',
  'ParentNode.firstElementChild',
  'ParentNode.lastElementChild',
  'RTCPeerConnection.createAnswer',
  'RTCPeerConnection.createOffer',
  'RTCPeerConnection.getStats',
  'Screen.availHeight',
  'Screen.availLeft',
  'Screen.availTop',
  'Screen.availWidth',
  'ServiceWorkerGlobalScope.fetch',
  'ShadowRoot.resetStyleInheritance',
  'Storage.clear',
  'Storage.getItem',
  'Storage.key',
  'Storage.length',
  'Storage.removeItem',
  'Storage.setItem',
  'StorageEvent.initStorageEvent',
  'SubtleCrypto.encrypt',
  'SubtleCrypto.decrypt',
  'SubtleCrypto.sign',
  'SubtleCrypto.digest',
  'SubtleCrypto.importKey',
  'SubtleCrypto.unwrapKey',
  'ShadowRoot.applyAuthorStyles',

  'TextEvent.initTextEvent',
  # TODO(leafp): These have been converted from int to double in Chrome 37.
  # client, page, and screen were already special cased, adding radiusX/radiusY.
  # See impl_Touch.darttemplate for impedance matching code
  'Touch.clientX',
  'Touch.clientY',
  'Touch.pageX',
  'Touch.pageY',
  'Touch.screenX',
  'Touch.screenY',
  'Touch.radiusX',
  'Touch.radiusY',
  'TouchEvent.initTouchEvent',
  'UIEvent.charCode',
  'UIEvent.initUIEvent',
  'UIEvent.keyCode',
  'UIEvent.layerX',
  'UIEvent.layerY',
  'UIEvent.pageX',
  'UIEvent.pageY',
  'WheelEvent.initWebKitWheelEvent',
  'WheelEvent.deltaX',
  'WheelEvent.deltaY',
  'WorkerGlobalScope.webkitNotifications',
  'Window.getComputedStyle',
  'Window.clearInterval',
  'Window.clearTimeout',
  'WindowTimers.clearInterval',
  'WindowTimers.clearTimeout',
  'WindowTimers.setInterval',
  'WindowTimers.setTimeout',
  'Window.moveTo',
  'Window.requestAnimationFrame',
  'Window.setInterval',
  'Window.setTimeout',
])

# Members from the standard dom that exist in the dart:html library with
# identical functionality but with cleaner names.
renamed_html_members = monitored.Dict('htmlrenamer.renamed_html_members', {
    'CSSKeyframesRule.insertRule': 'appendRule',
    'DirectoryEntry.getDirectory': '_getDirectory',
    'DirectoryEntry.getFile': '_getFile',
    'Document.createCDATASection': 'createCDataSection',
    'Document.defaultView': 'window',
    'Window.CSS': 'css',
    'Window.webkitNotifications': 'notifications',
    'Window.webkitRequestFileSystem': '_requestFileSystem',
    'Window.webkitResolveLocalFileSystemURL': 'resolveLocalFileSystemUrl',
    'Navigator.webkitGetUserMedia': '_getUserMedia',
    'Node.appendChild': 'append',
    'Node.cloneNode': 'clone',
    'Node.nextSibling': 'nextNode',
    'Node.parentElement': 'parent',
    'Node.previousSibling': 'previousNode',
    'Node.textContent': 'text',
    'SVGElement.className': '_svgClassName',
    'SVGStopElement.offset': 'gradientOffset',
    'URL.createObjectURL': 'createObjectUrl',
    'URL.revokeObjectURL': 'revokeObjectUrl',
    #'WorkerContext.webkitRequestFileSystem': '_requestFileSystem',
    #'WorkerContext.webkitRequestFileSystemSync': '_requestFileSystemSync',
})

# Members that have multiple definitions, but their types are vary, so we rename
# them to make them distinct.
renamed_overloads = monitored.Dict('htmldartgenerator.renamed_overloads', {
  'AudioContext.createBuffer(ArrayBuffer buffer, boolean mixToMono)':
      'createBufferFromBuffer',
  'CSS.supports(DOMString conditionText)': 'supportsCondition',
  'CanvasRenderingContext2D.createPattern(HTMLImageElement image, '
      'DOMString repetitionType)': 'createPatternFromImage',
  'DataTransferItemList.add(File file)': 'addFile',
  'DataTransferItemList.add(DOMString data, DOMString type)': 'addData',
  'FormData.append(DOMString name, Blob value, DOMString filename)':
      'appendBlob',
  'IDBDatabase.transaction(DOMStringList storeNames, IDBTransactionMode mode)':
      'transactionStores',
  'IDBDatabase.transaction(sequence<DOMString> storeNames, IDBTransactionMode mode)':
      'transactionList',
  'IDBDatabase.transaction(DOMString storeName, IDBTransactionMode mode)':
      'transactionStore',
  'RTCDataChannel.send(ArrayBuffer data)': 'sendByteBuffer',
  'RTCDataChannel.send(ArrayBufferView data)': 'sendTypedData',
  'RTCDataChannel.send(Blob data)': 'sendBlob',
  'RTCDataChannel.send(DOMString data)': 'sendString',
  'SourceBuffer.appendBuffer(ArrayBufferView data)': 'appendTypedData',
  'URL.createObjectURL(MediaSource source)':
      'createObjectUrlFromSource',
  'URL.createObjectURL(WebKitMediaSource source)':
      '_createObjectUrlFromWebKitSource',
  'URL.createObjectURL(MediaStream stream)': 'createObjectUrlFromStream',
  'URL.createObjectURL(Blob blob)': 'createObjectUrlFromBlob',
  'WebGLRenderingContextBase.texImage2D(unsigned long target, long level, '
      'unsigned long internalformat, unsigned long format, unsigned long '
      'type, ImageData pixels)': 'texImage2DImageData',
  'WebGLRenderingContextBase.texImage2D(unsigned long target, long level, '
      'unsigned long internalformat, unsigned long format, unsigned long '
      'type, HTMLImageElement image)': 'texImage2DImage',
  'WebGLRenderingContextBase.texImage2D(unsigned long target, long level, '
      'unsigned long internalformat, unsigned long format, unsigned long '
      'type, HTMLCanvasElement canvas)': 'texImage2DCanvas',
  'WebGLRenderingContextBase.texImage2D(unsigned long target, long level, '
      'unsigned long internalformat, unsigned long format, unsigned long '
      'type, HTMLVideoElement video)': 'texImage2DVideo',
  'WebGLRenderingContextBase.texSubImage2D(unsigned long target, long level, '
      'long xoffset, long yoffset, unsigned long format, unsigned long type, '
      'ImageData pixels)': 'texSubImage2DImageData',
  'WebGLRenderingContextBase.texSubImage2D(unsigned long target, long level, '
      'long xoffset, long yoffset, unsigned long format, unsigned long type, '
      'HTMLImageElement image)': 'texSubImage2DImage',
  'WebGLRenderingContextBase.texSubImage2D(unsigned long target, long level, '
      'long xoffset, long yoffset, unsigned long format, unsigned long type, '
      'HTMLCanvasElement canvas)': 'texSubImage2DCanvas',
  'WebGLRenderingContextBase.texSubImage2D(unsigned long target, long level, '
      'long xoffset, long yoffset, unsigned long format, unsigned long type, '
      'HTMLVideoElement video)': 'texSubImage2DVideo',
  'WebGLRenderingContextBase.bufferData(unsigned long target, '
      'ArrayBuffer data, unsigned long usage)': 'bufferByteData',
  'WebGLRenderingContextBase.bufferData(unsigned long target, '
      'ArrayBufferView data, unsigned long usage)': 'bufferDataTyped',
  'WebGLRenderingContextBase.bufferSubData(unsigned long target, '
      'long long offset, ArrayBuffer data)': 'bufferSubByteData',
  'WebGLRenderingContextBase.bufferSubData(unsigned long target, '
      'long long offset, ArrayBufferView data)': 'bufferSubDataTyped',
  'WebSocket.send(ArrayBuffer data)': 'sendByteBuffer',
  'WebSocket.send(ArrayBufferView data)': 'sendTypedData',
  'WebSocket.send(DOMString data)': 'sendString',
  'WebSocket.send(Blob data)': 'sendBlob'
})

# Members that have multiple definitions, but their types are identical (only
# number of arguments vary), so we do not rename them as a _raw method.
keep_overloaded_members = monitored.Set(
    'htmldartgenerator.keep_overloaded_members', [
  'AudioBufferSourceNode.start',
  'CanvasRenderingContext2D.putImageData',
  'CanvasRenderingContext2D.webkitPutImageDataHD',
  'DataTransferItemList.add',
  'Document.createElement',
  'Document.createElementNS',
  'HTMLInputElement.setRangeText',
  'HTMLTextAreaElement.setRangeText',
  'IDBDatabase.transaction',
  'RTCDataChannel.send',
  'URL.createObjectURL',
  'WebSocket.send',
  'XMLHttpRequest.send'
])

# Members that can be overloaded.
overloaded_and_renamed = monitored.Set(
    'htmldartgenerator.overloaded_and_renamed', [
  'CanvasRenderingContext2D.clip',
  'CanvasRenderingContext2D.drawFocusIfNeeded',
  'CanvasRenderingContext2D.fill',
  'CanvasRenderingContext2D.isPointInPath',
  'CanvasRenderingContext2D.isPointInStroke',
  'CanvasRenderingContext2D.stroke',
  'Navigator.sendBeacon',
  'WebGLRenderingContextBase.bufferData',
  'WebGLRenderingContextBase.bufferSubData',
  'WebGLRenderingContextBase.texImage2D',
  'WebGLRenderingContextBase.texSubImage2D',
])

for member in convert_to_future_members:
  if member in renamed_html_members:
    renamed_html_members[member] = '_' + renamed_html_members[member]
  else:
    renamed_html_members[member] = '_' + member[member.find('.') + 1 :]

# Members and classes from the dom that should be removed completely from
# dart:html.  These could be expressed in the IDL instead but expressing this
# as a simple table instead is more concise.
# Syntax is: ClassName.(get\:|set\:|call\:|on\:)?MemberName
# Using get: and set: is optional and should only be used when a getter needs
# to be suppressed but not the setter, etc.
# Prepending ClassName with = will only match against direct class, not for
# subclasses.
# TODO(jacobr): cleanup and augment this list.
removed_html_members = monitored.Set('htmlrenamer.removed_html_members', [
    'AudioBufferSourceNode.looping', # TODO(vsm): Use deprecated IDL annotation
    'CSSStyleDeclaration.getPropertyCSSValue',
    'CanvasRenderingContext2D.clearShadow',
    'CanvasRenderingContext2D.drawImageFromRect',
    'CanvasRenderingContext2D.setAlpha',
    'CanvasRenderingContext2D.setCompositeOperation',
    'CanvasRenderingContext2D.setFillColor',
    'CanvasRenderingContext2D.setLineCap',
    'CanvasRenderingContext2D.setLineJoin',
    'CanvasRenderingContext2D.setLineWidth',
    'CanvasRenderingContext2D.setMiterLimit',
    'CanvasRenderingContext2D.setShadow',
    'CanvasRenderingContext2D.setStrokeColor',
    'CharacterData.remove',
    'Window.call:blur',
    'Window.call:focus',
    'Window.clientInformation',
    'Window.createImageBitmap',
    'Window.get:frames',
    'Window.get:length',
    'Window.on:beforeUnload',
    'Window.on:webkitTransitionEnd',
    'Window.pagePopupController',
    'Window.prompt',
    'Window.webkitCancelAnimationFrame',
    'Window.webkitCancelRequestAnimationFrame',
    'Window.webkitIndexedDB',
    'Window.webkitRequestAnimationFrame',
    'Document.alinkColor',
    'Document.all',
    'Document.applets',
    'Document.bgColor',
    'Document.clear',
    'Document.createAttribute',
    'Document.createAttributeNS',
    'Document.createComment',
    'Document.createExpression',
    'Document.createNSResolver',
    'Document.createProcessingInstruction',
    'Document.designMode',
    'Document.dir',
    'Document.evaluate',
    'Document.fgColor',
    'Document.get:URL',
    'Document.get:anchors',
    'Document.get:characterSet',
    'Document.get:compatMode',
    'Document.get:defaultCharset',
    'Document.get:doctype',
    'Document.get:documentURI',
    'Document.get:embeds',
    'Document.get:forms',
    'Document.get:inputEncoding',
    'Document.get:links',
    'Document.get:plugins',
    'Document.get:scripts',
    'Document.get:xmlEncoding',
    'Document.getElementsByTagNameNS',
    'Document.getOverrideStyle',
    'Document.getSelection',
    'Document.images',
    'Document.linkColor',
    'Document.location',
    'Document.on:wheel',
    'Document.open',
    'Document.register',
    'Document.set:domain',
    'Document.vlinkColor',
    'Document.webkitCurrentFullScreenElement',
    'Document.webkitFullScreenKeyboardInputAllowed',
    'Document.write',
    'Document.writeln',
    'Document.xmlStandalone',
    'Document.xmlVersion',
    'DocumentFragment.children',
    'DocumentType.*',
    'DOMException.code',
    'DOMException.ABORT_ERR',
    'DOMException.DATA_CLONE_ERR',
    'DOMException.DOMSTRING_SIZE_ERR',
    'DOMException.HIERARCHY_REQUEST_ERR',
    'DOMException.INDEX_SIZE_ERR',
    'DOMException.INUSE_ATTRIBUTE_ERR',
    'DOMException.INVALID_ACCESS_ERR',
    'DOMException.INVALID_CHARACTER_ERR',
    'DOMException.INVALID_MODIFICATION_ERR',
    'DOMException.INVALID_NODE_TYPE_ERR',
    'DOMException.INVALID_STATE_ERR',
    'DOMException.NAMESPACE_ERR',
    'DOMException.NETWORK_ERR',
    'DOMException.NOT_FOUND_ERR',
    'DOMException.NOT_SUPPORTED_ERR',
    'DOMException.NO_DATA_ALLOWED_ERR',
    'DOMException.NO_MODIFICATION_ALLOWED_ERR',
    'DOMException.QUOTA_EXCEEDED_ERR',
    'DOMException.SECURITY_ERR',
    'DOMException.SYNTAX_ERR',
    'DOMException.TIMEOUT_ERR',
    'DOMException.TYPE_MISMATCH_ERR',
    'DOMException.URL_MISMATCH_ERR',
    'DOMException.VALIDATION_ERR',
    'DOMException.WRONG_DOCUMENT_ERR',
    'Element.accessKey',
    'Element.dataset',
    'Element.get:classList',
    'Element.getAttributeNode',
    'Element.getAttributeNodeNS',
    'Element.getElementsByTagNameNS',
    'Element.innerText',
    'Element.on:wheel',
    'Element.outerText',
    'Element.removeAttributeNode',
    'Element.set:outerHTML',
    'Element.setAttributeNode',
    'Element.setAttributeNodeNS',
    'Element.webkitCreateShadowRoot',
    'Element.webkitMatchesSelector',
    'Element.webkitPseudo',
    'Element.webkitShadowRoot',
    '=Event.returnValue', # Only suppress on Event, allow for BeforeUnloadEvnt.
    'Event.srcElement',
    'EventSource.URL',
    'FontFace.ready',
    'FontFaceSet.load',
    'FontFaceSet.ready',
    'HTMLAnchorElement.charset',
    'HTMLAnchorElement.coords',
    'HTMLAnchorElement.rev',
    'HTMLAnchorElement.shape',
    'HTMLAnchorElement.text',
    'HTMLAppletElement.*',
    'HTMLAreaElement.noHref',
    'HTMLBRElement.clear',
    'HTMLBaseFontElement.*',
    'HTMLBodyElement.aLink',
    'HTMLBodyElement.background',
    'HTMLBodyElement.bgColor',
    'HTMLBodyElement.link',
    'HTMLBodyElement.on:beforeUnload',
    'HTMLBodyElement.text',
    'HTMLBodyElement.vLink',
    'HTMLDListElement.compact',
    'HTMLDirectoryElement.*',
    'HTMLDivElement.align',
    'HTMLFontElement.*',
    'HTMLFormControlsCollection.__getter__',
    'HTMLFormElement.get:elements',
    'HTMLFrameElement.*',
    'HTMLFrameSetElement.*',
    'HTMLHRElement.align',
    'HTMLHRElement.noShade',
    'HTMLHRElement.size',
    'HTMLHRElement.width',
    'HTMLHeadElement.profile',
    'HTMLHeadingElement.align',
    'HTMLHtmlElement.manifest',
    'HTMLHtmlElement.version',
    'HTMLIFrameElement.align',
    'HTMLIFrameElement.frameBorder',
    'HTMLIFrameElement.longDesc',
    'HTMLIFrameElement.marginHeight',
    'HTMLIFrameElement.marginWidth',
    'HTMLIFrameElement.scrolling',
    'HTMLImageElement.align',
    'HTMLImageElement.hspace',
    'HTMLImageElement.longDesc',
    'HTMLImageElement.name',
    'HTMLImageElement.vspace',
    'HTMLInputElement.align',
    'HTMLLegendElement.align',
    'HTMLLinkElement.charset',
    'HTMLLinkElement.rev',
    'HTMLLinkElement.target',
    'HTMLMarqueeElement.*',
    'HTMLMenuElement.compact',
    'HTMLMetaElement.scheme',
    'HTMLOListElement.compact',
    'HTMLObjectElement.align',
    'HTMLObjectElement.archive',
    'HTMLObjectElement.border',
    'HTMLObjectElement.codeBase',
    'HTMLObjectElement.codeType',
    'HTMLObjectElement.declare',
    'HTMLObjectElement.hspace',
    'HTMLObjectElement.standby',
    'HTMLObjectElement.vspace',
    'HTMLOptionElement.text',
    'HTMLOptionsCollection.*',
    'HTMLParagraphElement.align',
    'HTMLParamElement.type',
    'HTMLParamElement.valueType',
    'HTMLPreElement.width',
    'HTMLScriptElement.text',
    'HTMLSelectElement.options',
    'HTMLSelectElement.selectedOptions',
    'HTMLTableCaptionElement.align',
    'HTMLTableCellElement.abbr',
    'HTMLTableCellElement.align',
    'HTMLTableCellElement.axis',
    'HTMLTableCellElement.bgColor',
    'HTMLTableCellElement.ch',
    'HTMLTableCellElement.chOff',
    'HTMLTableCellElement.height',
    'HTMLTableCellElement.noWrap',
    'HTMLTableCellElement.scope',
    'HTMLTableCellElement.vAlign',
    'HTMLTableCellElement.width',
    'HTMLTableColElement.align',
    'HTMLTableColElement.ch',
    'HTMLTableColElement.chOff',
    'HTMLTableColElement.vAlign',
    'HTMLTableColElement.width',
    'HTMLTableElement.align',
    'HTMLTableElement.bgColor',
    'HTMLTableElement.cellPadding',
    'HTMLTableElement.cellSpacing',
    'HTMLTableElement.frame',
    'HTMLTableElement.rules',
    'HTMLTableElement.summary',
    'HTMLTableElement.width',
    'HTMLTableRowElement.align',
    'HTMLTableRowElement.bgColor',
    'HTMLTableRowElement.ch',
    'HTMLTableRowElement.chOff',
    'HTMLTableRowElement.vAlign',
    'HTMLTableSectionElement.align',
    'HTMLTableSectionElement.ch',
    'HTMLTableSectionElement.chOff',
    'HTMLTableSectionElement.vAlign',
    'HTMLTitleElement.text',
    'HTMLUListElement.compact',
    'HTMLUListElement.type',
    'Location.valueOf',
    'MessageEvent.ports',
    'MessageEvent.webkitInitMessageEvent',
    'MouseEvent.x',
    'MouseEvent.y',
    'Navigator.registerServiceWorker',
    'Navigator.unregisterServiceWorker',
    'Node.compareDocumentPosition',
    'Node.get:DOCUMENT_POSITION_CONTAINED_BY',
    'Node.get:DOCUMENT_POSITION_CONTAINS',
    'Node.get:DOCUMENT_POSITION_DISCONNECTED',
    'Node.get:DOCUMENT_POSITION_FOLLOWING',
    'Node.get:DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC',
    'Node.get:DOCUMENT_POSITION_PRECEDING',
    'Node.get:prefix',
    'Node.hasAttributes',
    'Node.isDefaultNamespace',
    'Node.isEqualNode',
    'Node.isSameNode',
    'Node.isSupported',
    'Node.lookupNamespaceURI',
    'Node.lookupPrefix',
    'Node.normalize',
    'Node.set:nodeValue',
    'NodeFilter.acceptNode',
    'NodeIterator.expandEntityReferences',
    'NodeIterator.filter',
    'NodeList.item',
    'Performance.webkitClearMarks',
    'Performance.webkitClearMeasures',
    'Performance.webkitGetEntries',
    'Performance.webkitGetEntriesByName',
    'Performance.webkitGetEntriesByType',
    'Performance.webkitMark',
    'Performance.webkitMeasure',
    'ShadowRoot.getElementsByTagNameNS',
    'SVGElement.getPresentationAttribute',
    'SVGElementInstance.on:wheel',
    'Touch.get:webkitRadiusX',
    'Touch.get:webkitRadiusY',
    'Touch.get:webkitForce',
    'WheelEvent.wheelDelta',
    'Window.on:wheel',
    'WindowEventHandlers.on:beforeUnload',
    'WorkerGlobalScope.webkitIndexedDB',
# TODO(jacobr): should these be removed?
    'Document.close',
    'Document.hasFocus',
    ])

# Manual dart: library name lookup.
_library_names = monitored.Dict('htmlrenamer._library_names', {
  'ANGLEInstancedArrays': 'web_gl',
  'Database': 'web_sql',
  'Navigator': 'html',
  'Window': 'html',
})

_library_ids = monitored.Dict('htmlrenamer._library_names', {
  'ANGLEInstancedArrays': 'WebGl',
  'Database': 'WebSql',
  'Navigator': 'Html',
  'Window': 'Html',
})

class HtmlRenamer(object):
  def __init__(self, database, metadata):
    self._database = database
    self._metadata = metadata

  def RenameInterface(self, interface):
    if 'Callback' in interface.ext_attrs:
      if interface.id in _removed_html_interfaces:
        return None

    candidate = self.RenameInterfaceId(interface.id)
    if candidate:
      return candidate

    if interface.id.startswith('HTML'):
      if any(interface.id in ['Element', 'Document']
             for interface in self._database.Hierarchy(interface)):
        return interface.id[len('HTML'):]
    return self._DartifyName(interface.javascript_binding_name)

  def RenameInterfaceId(self, interface_id):
    if interface_id in html_interface_renames:
      return html_interface_renames[interface_id]
    return None;


  def RenameMember(self, interface_name, member_node, member, member_prefix='',
      dartify_name=True):
    """
    Returns the name of the member in the HTML library or None if the member is
    suppressed in the HTML library
    """
    interface = self._database.GetInterface(interface_name)

    if not member:
      if 'ImplementedAs' in member_node.ext_attrs:
        member = member_node.ext_attrs['ImplementedAs']

    if self.ShouldSuppressMember(interface, member, member_prefix):
      return None

    if 'CheckSecurity' in member_node.ext_attrs:
      return None

    name = self._FindMatch(interface, member, member_prefix,
        renamed_html_members)

    target_name = renamed_html_members[name] if name else member
    if self._FindMatch(interface, member, member_prefix, private_html_members):
      if not target_name.startswith('_'):  # e.g. _svgClassName
        target_name = '_' + target_name

    if not name and target_name.startswith('webkit'):
      target_name = member[len('webkit'):]
      target_name = target_name[:1].lower() + target_name[1:]

    if dartify_name:
      target_name = self._DartifyMemberName(target_name)
    return target_name

  def ShouldSuppressMember(self, interface, member, member_prefix=''):
    """ Returns true if the member should be suppressed."""
    if self._FindMatch(interface, member, member_prefix, removed_html_members):
      return True
    if interface.id in _removed_html_interfaces:
      return True
    metadata_member = member
    if member_prefix == 'on:':
      metadata_member = 'on' + metadata_member.lower()
    if self._metadata.IsSuppressed(interface, metadata_member):
      return True
    return False

  def ShouldSuppressInterface(self, interface):
    """ Returns true if the interface should be suppressed."""
    if interface.id in _removed_html_interfaces:
      return True

  def _FindMatch(self, interface, member, member_prefix, candidates):
    def find_match(interface_id):
      member_name = interface_id + '.' + member
      if member_name in candidates:
        return member_name
      member_name = interface_id + '.' + member_prefix + member
      if member_name in candidates:
        return member_name
      member_name = interface_id + '.*'
      if member_name in candidates:
        return member_name

    # Check direct matches first
    match = find_match('=%s' % interface.id)
    if match:
      return match

    for interface in self._database.Hierarchy(interface):
      match = find_match(interface.id)
      if match:
        return match

  def GetLibraryName(self, interface):
    # Some types have attributes merged in from many other interfaces.
    if interface.id in _library_names:
      return _library_names[interface.id]

    # TODO(ager, blois): The conditional has been removed from indexed db,
    # so we can no longer determine the library based on the conditionals.
    if interface.id.startswith("IDB"):
      return 'indexed_db'
    if interface.id.startswith("SQL"):
      return 'web_sql'
    if interface.id.startswith("SVG"):
      return 'svg'
    if interface.id.startswith("WebGL") or interface.id.startswith("OES") \
        or interface.id.startswith("EXT"):
      return 'web_gl'

    if 'Conditional' in interface.ext_attrs:
      if 'WEB_AUDIO' in interface.ext_attrs['Conditional']:
        return 'web_audio'
      if 'INDEXED_DATABASE' in interface.ext_attrs['Conditional']:
        return 'indexed_db'
      if 'SQL_DATABASE' in interface.ext_attrs['Conditional']:
        return 'web_sql'

    if interface.id in typed_array_renames:
      return 'typed_data'

    return 'html'

  def GetLibraryId(self, interface):
    # Some types have attributes merged in from many other interfaces.
    if interface.id in _library_ids:
      return _library_ids[interface.id]

    # TODO(ager, blois): The conditional has been removed from indexed db,
    # so we can no longer determine the library based on the conditionals.
    if interface.id.startswith("IDB"):
      return 'IndexedDb'
    if interface.id.startswith("SQL"):
      return 'WebSql'
    if interface.id.startswith("SVG"):
      return 'Svg'
    if interface.id.startswith("WebGL") or interface.id.startswith("OES") \
        or interface.id.startswith("EXT"):
      return 'WebGl'

    if 'Conditional' in interface.ext_attrs:
      if 'WEB_AUDIO' in interface.ext_attrs['Conditional']:
        return 'WebAudio'
      if 'INDEXED_DATABASE' in interface.ext_attrs['Conditional']:
        return 'IndexedDb'
      if 'SQL_DATABASE' in interface.ext_attrs['Conditional']:
        return 'WebSql'

    if interface.id in typed_array_renames:
      return 'TypedData'

    return 'Html'

  def DartifyTypeName(self, type_name):
    """Converts a DOM name to a Dart-friendly class name. """

    if type_name in html_interface_renames:
      return html_interface_renames[type_name]

    return self._DartifyName(type_name)

  def _DartifyName(self, dart_name):
    # Strip off any standard prefixes.
    name = re.sub(r'^SVG', '', dart_name)
    name = re.sub(r'^IDB', '', name)
    name = re.sub(r'^WebGL', '', name)
    name = re.sub(r'^WebKit', '', name)

    return self._CamelCaseName(name)

  def _DartifyMemberName(self, member_name):
    # Strip off any OpenGL ES suffixes.
    name = re.sub(r'OES$', '', member_name)
    return self._CamelCaseName(name)

  def _CamelCaseName(self, name):

    def toLower(match):
      return match.group(1) + match.group(2).lower() + match.group(3)

    # We're looking for a sequence of letters which start with capital letter
    # then a series of caps and finishes with either the end of the string or
    # a capital letter.
    # The [0-9] check is for names such as 2D or 3D
    # The following test cases should match as:
    #   WebKitCSSFilterValue: WebKit(C)(SS)(F)ilterValue
    #   XPathNSResolver: (X)()(P)ath(N)(S)(R)esolver (no change)
    #   IFrameElement: (I)()(F)rameElement (no change)
    return re.sub(r'([A-Z])([A-Z]{2,})([A-Z]|$)', toLower, name)
