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
    'Iterator': 'DomIterator',
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
    'WebGL2RenderingContext': 'RenderingContext2',
    'WebGL2RenderingContextBase': 'RenderingContextBase2',
    'WindowTimers': '_WindowTimers',
    'XMLHttpRequest': 'HttpRequest',
    'XMLHttpRequestUpload': 'HttpRequestUpload',
    'XMLHttpRequestEventTarget': 'HttpRequestEventTarget',
}, **typed_array_renames))

# Interfaces that are suppressed, but need to still exist for Dartium and to
# properly wrap DOM objects if/when encountered.
_removed_html_interfaces = [
  'Bluetooth',
  'BluetoothAdvertisingData',
  'BluetoothCharacteristicProperties',
  'BluetoothDevice',
  'BluetoothRemoteGATTCharacteristic',
  'BluetoothRemoteGATTServer',
  'BluetoothRemoteGATTService',
  'BluetoothUUID',
  'Cache', # TODO: Symbol conflicts with Angular: dartbug.com/20937
  'CanvasPathMethods',
  'CDataSection',
  'CSSPrimitiveValue',
  'CSSUnknownRule',
  'CSSValue',
  'Counter',
  'DOMFileSystemSync', # Workers
  'DatabaseSync', # Workers
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
  'NFC',
  'Notation',
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
  'USB',
  'USBAlternateInterface',
  'USBConfiguration',
  'USBConnectionEvent',
  'USBDevice',
  'USBEndpoint',
  'USBInTransferResult',
  'USBInterface',
  'USBIsochronousInTransferPacket',
  'USBIsochronousInTransferResult',
  'USBIsochronousOutTransferPacket',
  'USBIsochronousOutTransferResult',
  'USBOutTransferResult',
  'WebKitCSSFilterValue',
  'WebKitCSSMatrix',
  'WebKitCSSMixFunctionValue',
  'WebKitCSSTransformValue',
  'WebKitMediaSource',
  'WebKitNotification',
  'WebGLRenderingContextBase',
  'WebGL2RenderingContextBase',
  'WebKitSourceBuffer',
  'WebKitSourceBufferList',
  'WorkerLocation', # Workers
  'WorkerNavigator', # Workers
  'Worklet', # Rendering Workers
  'WorkletGlobalScope', # Rendering Workers
  'XMLHttpRequestProgressEvent',
  # Obsolete event for NaCl.
  'ResourceProgressEvent',
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
  'CompositionEvent',       # 45 Roll hide default constructor use Dart's custom
  'CustomEvent',            # 45 Roll hide default constructor use Dart's custom
  'Event',                  # 45 Roll hide default constructor use Dart's custom
  'HashChangeEvent',        # 45 Roll hide default constructor use Dart's custom
  'HTMLAudioElement',
  'HTMLOptionElement',
  'KeyboardEvent',          # 45 Roll hide default constructor use Dart's custom
  'MessageEvent',           # 45 Roll hide default constructor use Dart's custom
  'MouseEvent',             # 45 Roll hide default constructor use Dart's custom
  'MutationObserver',
  'StorageEvent',           # 45 Roll hide default constructor use Dart's custom
  'UIEvent',                # 45 Roll hide default constructor use Dart's custom
  'WheelEvent',             # 45 Roll hide default constructor use Dart's custom
])

# Members from the standard dom that should not be exposed publicly in dart:html
# but need to be exposed internally to implement dart:html on top of a standard
# browser. They are exposed simply by placing an underscore in front of the
# name.
private_html_members = monitored.Set('htmlrenamer.private_html_members', [
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
  'Crypto.getRandomValues',
  'CSSStyleDeclaration.getPropertyValue',
  'CSSStyleDeclaration.setProperty',
  'CSSStyleDeclaration.var',
  'CompositionEvent.initCompositionEvent',
  'CustomEvent.detail',
  'CustomEvent.initCustomEvent',
  'DeviceOrientationEvent.initDeviceOrientationEvent',
  'Document.createElement',
  'Document.createElementNS',
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
   # Not prefixed.
  'Document.webkitFullscreenElement',
  'Document.webkitFullscreenEnabled',
  'Document.webkitHidden',
  'Document.webkitIsFullScreen',
  'Document.webkitVisibilityState',
   # Not prefixed but requires custom implementation for cross-browser compatibility.
  'Document.visibilityState',

  'Element.animate',
  'Element.children',
  'Element.childElementCount',
  'Element.firstElementChild',
  'Element.getElementsByTagName',
  'Element.insertAdjacentHTML',
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
  'MouseEvent.offsetX',
  'MouseEvent.offsetY',
  'MouseEvent.screenX',
  'MouseEvent.screenY',
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
  'ParentNode.querySelectorAll',
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
  'UIEvent.initUIEvent',
  'UIEvent.layerX',
  'UIEvent.layerY',
  'UIEvent.pageX',
  'UIEvent.pageY',
  'UIEvent.which',
  'KeyboardEvent.charCode',
  'KeyboardEvent.keyCode',
  'KeyboardEvent.which',

  'WebGLRenderingContext.readPixels',
  'WebGL2RenderingContext.readPixels',  
  'WheelEvent.initWebKitWheelEvent',
  'WheelEvent.deltaX',
  'WheelEvent.deltaY',
  'WorkerGlobalScope.webkitNotifications',
  'Window.getComputedStyle',
  'Window.clearInterval',
  'Window.clearTimeout',
  # TODO(tll): These have been converted from int to double in Chrome 39 for
  #            subpixel precision.  Special case for backward compatibility.
  'Window.scrollX',
  'Window.scrollY',
  'Window.pageXOffset',
  'Window.pageYOffset',

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
    'ConsoleBase.assert': 'assertCondition', 'CSSKeyframesRule.insertRule':
    'appendRule', 'DirectoryEntry.getDirectory': '_getDirectory',
    'DirectoryEntry.getFile': '_getFile', 'Document.createCDATASection':
    'createCDataSection', 'Document.defaultView': 'window', 'Window.CSS': 'css',
    'Window.webkitNotifications': 'notifications',
    'Window.webkitRequestFileSystem': '_requestFileSystem',
    'Window.webkitResolveLocalFileSystemURL': 'resolveLocalFileSystemUrl',
    'Navigator.webkitGetUserMedia': '_getUserMedia', 'Node.appendChild':
    'append', 'Node.cloneNode': 'clone', 'Node.nextSibling': 'nextNode',
    'Node.parentElement': 'parent', 'Node.previousSibling': 'previousNode',
    'Node.textContent': 'text', 'SVGElement.className': '_svgClassName',
    'SVGStopElement.offset': 'gradientOffset', 'URL.createObjectURL':
    'createObjectUrl', 'URL.revokeObjectURL': 'revokeObjectUrl',
    #'WorkerContext.webkitRequestFileSystem': '_requestFileSystem',
    #'WorkerContext.webkitRequestFileSystemSync': '_requestFileSystemSync',

    # OfflineAudioContext.suspend has an signature incompatible with shadowed
    # base class method AudioContext.suspend.
    'OfflineAudioContext.suspend': 'suspendFor',
})

# Members that have multiple definitions, but their types are vary, so we rename
# them to make them distinct.
renamed_overloads = monitored.Dict('htmldartgenerator.renamed_overloads', {
  'AudioContext.createBuffer(ArrayBuffer buffer, boolean mixToMono)':
      'createBufferFromBuffer',
  'CSS.supports(DOMString conditionText)': 'supportsCondition',
  'DataTransferItemList.add(File file)': 'addFile',
  'DataTransferItemList.add(DOMString data, DOMString type)': 'addData',
  'FormData.append(DOMString name, Blob value, DOMString filename)':
      'appendBlob',
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
  'WebSocket.send(ArrayBuffer data)': 'sendByteBuffer',
  'WebSocket.send(ArrayBufferView data)': 'sendTypedData',
  'WebSocket.send(DOMString data)': 'sendString',
  'WebSocket.send(Blob data)': 'sendBlob',
  'Window.setInterval(DOMString handler, long timeout, any arguments)': '_setInterval_String',
  'Window.setTimeout(DOMString handler, long timeout, any arguments)': '_setTimeout_String',
  'WindowTimers.setInterval(DOMString handler, long timeout, any arguments)': '_setInterval_String',
  'WindowTimers.setTimeout(DOMString handler, long timeout, any arguments)': '_setTimeout_String',
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
    'Attr.textContent', # Not needed as it is the same as Node.textContent.
    'AudioContext.decodeAudioData',
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
    # Disable the webKit version, imageSmoothingEnabled is exposed.
    'CanvasRenderingContext2D.webkitImageSmoothingEnabled',
    'CharacterData.remove',
    'ChildNode.replaceWith',
    'CSSStyleDeclaration.__getter__',
    'CSSStyleDeclaration.__setter__',
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
    'Document.append',
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
    'Document.prepend',
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
    'Element.append',
    'Element.dataset',
    'Element.get:classList',
    'Element.getAttributeNode',
    'Element.getAttributeNodeNS',
    'Element.getElementsByTagNameNS',
    'Element.innerText',
    # TODO(terry): All offset* attributes are in both HTMLElement and Element
    #              (it's a Chrome bug with a FIXME note to correct - sometime).
    #              Until corrected these Element attributes must be ignored.
    'Element.offsetParent',
    'Element.offsetTop',
    'Element.offsetLeft',
    'Element.offsetWidth',
    'Element.offsetHeight',
    'Element.on:wheel',
    'Element.outerText',
    'Element.prepend',
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
    'IDBDatabase.transaction', # We do this in a template without the generated implementation at all.
    'Location.valueOf',
    'MessageEvent.data',
    'MessageEvent.ports',
    'MessageEvent.webkitInitMessageEvent',
    'MouseEvent.webkitMovementX',
    'MouseEvent.webkitMovementY',
    'MouseEvent.x',
    'MouseEvent.y',
    'Navigator.bluetooth',
    'Navigator.registerServiceWorker',
    'Navigator.unregisterServiceWorker',
    'Navigator.isProtocolHandlerRegistered',
    'Navigator.unregisterProtocolHandler',
    'Navigator.usb',
    'Node.compareDocumentPosition',
    'Node.get:DOCUMENT_POSITION_CONTAINED_BY',
    'Node.get:DOCUMENT_POSITION_CONTAINS',
    'Node.get:DOCUMENT_POSITION_DISCONNECTED',
    'Node.get:DOCUMENT_POSITION_FOLLOWING',
    'Node.get:DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC',
    'Node.get:DOCUMENT_POSITION_PRECEDING',
    'Node.get:childNodes',
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
    'ParentNode.append',
    'ParentNode.prepend',
    'RTCPeerConnection.generateCertificate',
    'ServiceWorkerMessageEvent.data',
    'ShadowRoot.getElementsByTagNameNS',
    'SVGElement.getPresentationAttribute',
    'SVGElementInstance.on:wheel',
    'Touch.get:webkitRadiusX',
    'Touch.get:webkitRadiusY',
    'Touch.get:webkitForce',
    'Touch.get:webkitRotationAngle',
    'WheelEvent.wheelDelta',
    'WheelEvent.wheelDeltaX',
    'WheelEvent.wheelDeltaY',
    'Window.on:wheel',
    'WindowEventHandlers.on:beforeUnload',
    'WorkerGlobalScope.webkitIndexedDB',
    'XMLHttpRequest.open',
# TODO(jacobr): should these be removed?
    'Document.close',
    'Document.hasFocus',
    ])

# Manual dart: library name lookup.
_library_names = monitored.Dict('htmlrenamer._library_names', {
  'ANGLEInstancedArrays': 'web_gl',
  'CHROMIUMSubscribeUniform': 'web_gl',
  'Database': 'web_sql',
  'Navigator': 'html',
  'Window': 'html',
  'AnalyserNode': 'web_audio',
  'AudioBufferCallback': 'web_audio',
  'AudioBuffer': 'web_audio',
  'AudioBufferSourceNode': 'web_audio',
  'AudioContext': 'web_audio',
  'AudioDestinationNode': 'web_audio',
  'AudioListener': 'web_audio',
  'AudioNode': 'web_audio',
  'AudioParam': 'web_audio',
  'AudioProcessingEvent': 'web_audio',
  'AudioSourceNode': 'web_audio',
  'BiquadFilterNode': 'web_audio',
  'ChannelMergerNode': 'web_audio',
  'ChannelSplitterNode': 'web_audio',
  'ConvolverNode': 'web_audio',
  'DelayNode': 'web_audio',
  'DynamicsCompressorNode': 'web_audio',
  'GainNode': 'web_audio',
  'IIRFilterNode': 'web_audio',
  'MediaElementAudioSourceNode': 'web_audio',
  'MediaStreamAudioDestinationNode': 'web_audio',
  'MediaStreamAudioSourceNode': 'web_audio',
  'OfflineAudioCompletionEvent': 'web_audio',
  'OfflineAudioContext': 'web_audio',
  'OscillatorNode': 'web_audio',
  'PannerNode': 'web_audio',
  'PeriodicWave': 'web_audio',
  'ScriptProcessorNode': 'web_audio',
  'StereoPannerNode': 'web_audio',
  'WaveShaperNode': 'web_audio',
  'WindowWebAudio': 'web_audio',
})

_library_ids = monitored.Dict('htmlrenamer._library_names', {
  'ANGLEInstancedArrays': 'WebGl',
  'CHROMIUMSubscribeUniform': 'WebGl',
  'Database': 'WebSql',
  'Navigator': 'Html',
  'Window': 'Html',
  'AnalyserNode': 'WebAudio',
  'AudioBufferCallback': 'WebAudio',
  'AudioBuffer': 'WebAudio',
  'AudioBufferSourceNode': 'WebAudio',
  'AudioContext': 'WebAudio',
  'AudioDestinationNode': 'WebAudio',
  'AudioListener': 'WebAudio',
  'AudioNode': 'WebAudio',
  'AudioParam': 'WebAudio',
  'AudioProcessingEvent': 'WebAudio',
  'AudioSourceNode': 'WebAudio',
  'BiquadFilterNode': 'WebAudio',
  'ChannelMergerNode': 'WebAudio',
  'ChannelSplitterNode': 'WebAudio',
  'ConvolverNode': 'WebAudio',
  'DelayNode': 'WebAudio',
  'DynamicsCompressorNode': 'WebAudio',
  'GainNode': 'WebAudio',
  'IIRFilterNode': 'WebAudio',
  'MediaElementAudioSourceNode': 'WebAudio',
  'MediaStreamAudioDestinationNode': 'WebAudio',
  'MediaStreamAudioSourceNode': 'WebAudio',
  'OfflineAudioCompletionEvent': 'WebAudio',
  'OfflineAudioContext': 'WebAudio',
  'OscillatorNode': 'WebAudio',
  'PannerNode': 'WebAudio',
  'PeriodicWave': 'WebAudio',
  'ScriptProcessorNode': 'WebAudio',
  'StereoPannerNode': 'WebAudio',
  'WaveShaperNode': 'WebAudio',
  'WindowWebAudio': 'WebAudio',
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

  def isPrivate(self, interface, member):
    return self._FindMatch(interface, member, '', private_html_members)

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

    # Support for IDL conditional has been removed from indexed db, web_sql,
    # svg and web_gl so we can no longer determine the library based on conditional.
    # Use interface prefix to do that.  web_audio interfaces have no common prefix
    # - all audio interfaces added to _library_names/_library_ids.
    if interface.id.startswith("IDB"):
      return 'indexed_db'
    if interface.id.startswith("SQL"):
      return 'web_sql'
    if interface.id.startswith("SVG"):
      return 'svg'
    if interface.id.startswith("WebGL") or interface.id.startswith("OES") \
        or interface.id.startswith("EXT"):
      return 'web_gl'

    if interface.id in typed_array_renames:
      return 'typed_data'

    return 'html'

  def GetLibraryId(self, interface):
    # Some types have attributes merged in from many other interfaces.
    if interface.id in _library_ids:
      return _library_ids[interface.id]

    # Support for IDL conditional has been removed from indexed db, web_sql,
    # svg and web_gl so we can no longer determine the library based on conditional.
    # Use interface prefix to do that.  web_audio interfaces have no common prefix
    # - all audio interfaces added to _library_names/_library_ids.
    if interface.id.startswith("IDB"):
      return 'IndexedDb'
    if interface.id.startswith("SQL"):
      return 'WebSql'
    if interface.id.startswith("SVG"):
      return 'Svg'
    if interface.id.startswith("WebGL") or interface.id.startswith("OES") \
        or interface.id.startswith("EXT"):
      return 'WebGl'

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
