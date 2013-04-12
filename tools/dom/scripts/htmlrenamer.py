#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
import logging
import monitored
import re

html_interface_renames = monitored.Dict('htmlrenamer.html_interface_renames', {
    'CDATASection': 'CDataSection',
    'Clipboard': 'DataTransfer',
    'Database': 'SqlDatabase', # Avoid conflict with Index DB's Database.
    'DatabaseSync': 'SqlDatabaseSync',
    'DOMApplicationCache': 'ApplicationCache',
    'DOMCoreException': 'DomException',
    'DOMFileSystem': 'FileSystem',
    'DOMFormData': 'FormData',
    'DOMURL': 'Url',
    'DOMWindow': 'Window',
    'EntryCallback': '_EntryCallback',
    'EntriesCallback': '_EntriesCallback',
    'ErrorCallback': '_ErrorCallback',
    'FileCallback': '_FileCallback',
    'FileSystemCallback': '_FileSystemCallback',
    'FileWriterCallback': '_FileWriterCallback',
    'HTMLDocument' : 'HtmlDocument',
    'IDBFactory': 'IdbFactory', # Manual to avoid name conflicts.
    'NamedNodeMap': '_NamedNodeMap',
    'NavigatorUserMediaErrorCallback': '_NavigatorUserMediaErrorCallback',
    'NavigatorUserMediaSuccessCallback': '_NavigatorUserMediaSuccessCallback',
    'NotificationPermissionCallback': '_NotificationPermissionCallback',
    'PositionCallback': '_PositionCallback',
    'PositionErrorCallback': '_PositionErrorCallback',
    'RTCDTMFSender': 'RtcDtmfSender',
    'RTCDTMFToneChangeEvent': 'RtcDtmfToneChangeEvent',
    'RTCErrorCallback': '_RtcErrorCallback',
    'RTCSessionDescriptionCallback': '_RtcSessionDescriptionCallback',
    'StringCallback': '_StringCallback',
    'SVGDocument': 'SvgDocument', # Manual to avoid name conflicts.
    'SVGElement': 'SvgElement', # Manual to avoid name conflicts.
    'SVGException': 'SvgException', # Manual of avoid conflict with Exception.
    'SVGGradientElement': '_GradientElement',
    'SVGSVGElement': 'SvgSvgElement', # Manual to avoid name conflicts.
    'WebGLVertexArrayObjectOES': 'VertexArrayObject',
    'WebKitAnimationEvent': 'AnimationEvent',
    'WebKitCSSKeyframeRule': 'CssKeyframeRule',
    'WebKitCSSKeyframesRule': 'CssKeyframesRule',
    'WebKitCSSTransformValue': 'CssTransformValue',
    'WebKitPoint': '_DomPoint',
    'WebKitTransitionEvent': '_WebKitTransitionEvent',
    'XMLHttpRequest': 'HttpRequest',
    'XMLHttpRequestException': 'HttpRequestException',
    'XMLHttpRequestProgressEvent': 'HttpRequestProgressEvent',
    'XMLHttpRequestUpload': 'HttpRequestUpload',
})

# Interfaces that are suppressed, but need to still exist for Dartium and to
# properly wrap DOM objects if/when encountered.
_removed_html_interfaces = [
  'CSSPrimitiveValue',
  'CSSValue',
  'Counter',
  'DOMFileSystemSync', # Workers
  'DatabaseSync', # Workers
  'DedicatedWorkerContext', # Workers
  'DirectoryEntrySync', # Workers
  'DirectoryReaderSync', # Workers
  'EntrySync', # Workers
  'FileEntrySync', # Workers
  'FileReaderSync', # Workers
  'FileWriterSync', # Workers
  'HTMLAppletElement',
  'HTMLBaseFontElement',
  'HTMLDirectoryElement',
  'HTMLFontElement',
  'HTMLFrameElement',
  'HTMLFrameSetElement',
  'HTMLMarqueeElement',
  'IDBAny',
  'RGBColor',
  'Rect',
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
  'SharedWorker', # Workers
  'SharedWorkerContext', # Workers
  'WebKitCSSFilterValue',
  'WebKitCSSMatrix',
  'WebKitCSSMixFunctionValue',
  'WebKitCSSTransformValue',
  'WorkerContext', # Workers
  'WorkerLocation', # Workers
  'WorkerNavigator', # Workers
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
  'DOMWindow.webkitRequestFileSystem',
  'DOMWindow.webkitResolveLocalFileSystemURL',
  'Entry.copyTo',
  'Entry.getMetadata',
  'Entry.getParent',
  'Entry.moveTo',
  'Entry.remove',
  'FileEntry.createWriter',
  'FileEntry.file',
  'Notification.requestPermission',
  'NotificationCenter.requestPermission',
  'RTCPeerConnection.setLocalDescription',
  'RTCPeerConnection.setRemoteDescription',
  'StorageInfo.requestQuota',
  'WorkerContext.webkitResolveLocalFileSystemURL',
  'WorkerContext.webkitRequestFileSystem',
])

# Members from the standard dom that should not be exposed publicly in dart:html
# but need to be exposed internally to implement dart:html on top of a standard
# browser.
_private_html_members = monitored.Set('htmlrenamer._private_html_members', [
  'CanvasRenderingContext2D.arc',
  'CanvasRenderingContext2D.drawImage',
  'CompositionEvent.initCompositionEvent',
  'CustomEvent.initCustomEvent',
  'DeviceOrientationEvent.initDeviceOrientationEvent',
  'Document.createElement',
  'Document.createElementNS',
  'Document.createEvent',
  'Document.createRange',
  'Document.createTextNode',
  'Document.createTouch',
  'Document.createTouchList',
  'Document.querySelectorAll',

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
  'Document.webkitExitPointerLock',
  'Document.webkitFullscreenElement',
  'Document.webkitFullscreenEnabled',
  'Document.webkitHidden',
  'Document.webkitIsFullScreen',
  'Document.webkitPointerLockElement',
  'Document.webkitVisibilityState',

  'DocumentFragment.querySelector',
  'DocumentFragment.querySelectorAll',
  'Element.childElementCount',
  'Element.children',
  'Element.className',
  'Element.firstElementChild',
  'Element.getAttribute',
  'Element.getAttributeNS',
  'Element.getElementsByTagName',
  'Element.hasAttribute',
  'Element.hasAttributeNS',
  'Element.lastElementChild',
  'Element.querySelectorAll',
  'Element.removeAttribute',
  'Element.removeAttributeNS',
  'Element.scrollIntoView',
  'Element.scrollIntoViewIfNeeded',
  'Element.setAttributeNS',
  'Element.setAttribute',
  'Element.setAttributeNS',
  'ElementTraversal.childElementCount',
  'ElementTraversal.firstElementChild',
  'ElementTraversal.lastElementChild',
  'Event.initEvent',
  'EventTarget.addEventListener',
  'EventTarget.removeEventListener',
  'Geolocation.clearWatch',
  'Geolocation.getCurrentPosition',
  'Geolocation.watchPosition',
  'HashChangeEvent.initHashChangeEvent',
  'HTMLTableElement.createCaption',
  'HTMLTableElement.createTBody',
  'HTMLTableElement.createTFoot',
  'HTMLTableElement.createTHead',
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
  'MessageEvent.initMessageEvent',
  'MouseEvent.initMouseEvent',
  'MouseEvent.clientX',
  'MouseEvent.clientY',
  'MouseEvent.webkitMovementX',
  'MouseEvent.webkitMovementY',
  'MouseEvent.offsetX',
  'MouseEvent.offsetY',
  'MouseEvent.screenX',
  'MouseEvent.screenY',
  'MutationEvent.initMutationEvent',
  'Node.attributes',
  'Node.childNodes',
  'Node.firstChild',
  'Node.lastChild',
  'Node.namespaceURI',
  'Node.removeChild',
  'Node.replaceChild',
  'Screen.availHeight',
  'Screen.availLeft',
  'Screen.availTop',
  'Screen.availWidth',
  'Storage.clear',
  'Storage.getItem',
  'Storage.key',
  'Storage.length',
  'Storage.removeItem',
  'Storage.setItem',
  'StorageEvent.initStorageEvent',
  'TextEvent.initTextEvent',
  'Touch.clientX',
  'Touch.clientY',
  'Touch.pageX',
  'Touch.pageY',
  'Touch.screenX',
  'Touch.screenY',
  'TouchEvent.initTouchEvent',
  'UIEvent.charCode',
  'UIEvent.initUIEvent',
  'UIEvent.keyCode',
  'UIEvent.layerX',
  'UIEvent.layerY',
  'UIEvent.pageX',
  'UIEvent.pageY',
  'WheelEvent.wheelDeltaX',
  'WheelEvent.wheelDeltaY',
  'WheelEvent.initWebKitWheelEvent',
  'DOMWindow.getComputedStyle',
])

# Members from the standard dom that exist in the dart:html library with
# identical functionality but with cleaner names.
renamed_html_members = monitored.Dict('htmlrenamer.renamed_html_members', {
    'DirectoryEntry.getDirectory': '_getDirectory',
    'DirectoryEntry.getFile': '_getFile',
    'Document.createCDATASection': 'createCDataSection',
    'Document.defaultView': 'window',
    'Document.querySelector': 'query',
    'DOMURL.createObjectURL': 'createObjectUrl',
    'DOMURL.revokeObjectURL': 'revokeObjectUrl',
    'DOMWindow.clearTimeout': '_clearTimeout',
    'DOMWindow.clearInterval': '_clearInterval',
    'DOMWindow.setTimeout': '_setTimeout',
    'DOMWindow.setInterval': '_setInterval',
    'DOMWindow.webkitConvertPointFromNodeToPage': '_convertPointFromNodeToPage',
    'DOMWindow.webkitConvertPointFromPageToNode': '_convertPointFromPageToNode',
    'DOMWindow.webkitNotifications': 'notifications',
    'DOMWindow.webkitRequestFileSystem': '_requestFileSystem',
    'DOMWindow.webkitResolveLocalFileSystemURL': 'resolveLocalFileSystemUrl',
    'Element.querySelector': 'query',
    'Element.webkitCreateShadowRoot': 'createShadowRoot',
    'Element.webkitMatchesSelector' : 'matches',
    'Navigator.webkitGetUserMedia': '_getUserMedia',
    'Node.appendChild': 'append',
    'Node.cloneNode': 'clone',
    'Node.nextSibling': 'nextNode',
    'Node.ownerDocument': 'document',
    'Node.parentElement': 'parent',
    'Node.previousSibling': 'previousNode',
    'Node.textContent': 'text',
    'RTCPeerConnection.createAnswer': '_createAnswer',
    'RTCPeerConnection.createOffer': '_createOffer',
    'StorageInfo.queryUsageAndQuota': '_queryUsageAndQuota',
    'SVGElement.className': '$dom_svgClassName',
    'SVGStopElement.offset': 'gradientOffset',
    #'WorkerContext.webkitRequestFileSystem': '_requestFileSystem', # Workers
    #'WorkerContext.webkitRequestFileSystemSync': '_requestFileSystemSync', # Workers
})

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
# TODO(jacobr): cleanup and augment this list.
_removed_html_members = monitored.Set('htmlrenamer._removed_html_members', [
    'Attr.*',
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
    'CanvasRenderingContext2D.webkitLineDash',
    'CanvasRenderingContext2D.webkitLineDashOffset',
    'CharacterData.remove',
    'DOMWindow.call:blur',
    'DOMWindow.call:focus',
    'DOMWindow.clientInformation',
    'DOMWindow.get:frames',
    'DOMWindow.get:length',
    'DOMWindow.on:beforeUnload',
    'DOMWindow.prompt',
    'DOMWindow.webkitCancelAnimationFrame',
    'DOMWindow.webkitCancelRequestAnimationFrame',
    'DOMWindow.webkitIndexedDB',
    'DOMWindow.webkitRequestAnimationFrame',
    'Document.adoptNode',
    'Document.alinkColor',
    'Document.all',
    'Document.applets',
    'Document.bgColor',
    'Document.captureEvents',
    'Document.clear',
    'Document.createAttribute',
    'Document.createAttributeNS',
    'Document.createComment',
    'Document.createEntityReference',
    'Document.createExpression',
    'Document.createNSResolver',
    'Document.createNodeIterator',
    'Document.createProcessingInstruction',
    'Document.createTreeWalker',
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
    'Document.get:height',
    'Document.get:inputEncoding',
    'Document.get:links',
    'Document.get:plugins',
    'Document.get:scripts',
    'Document.get:width',
    'Document.get:xmlEncoding',
    'Document.getElementsByTagNameNS',
    'Document.getOverrideStyle',
    'Document.getSelection',
    'Document.images',
    'Document.importNode',
    'Document.linkColor',
    'Document.location',
    'Document.open',
    'Document.releaseEvents',
    'Document.set:domain',
    'Document.vlinkColor',
    'Document.webkitCurrentFullScreenElement',
    'Document.webkitFullScreenKeyboardInputAllowed',
    'Document.write',
    'Document.writeln',
    'Document.xmlStandalone',
    'Document.xmlVersion',
    'DocumentType.*',
    'DOMCoreException.code',
    'DOMCoreException.ABORT_ERR',
    'DOMCoreException.DATA_CLONE_ERR',
    'DOMCoreException.DOMSTRING_SIZE_ERR',
    'DOMCoreException.HIERARCHY_REQUEST_ERR',
    'DOMCoreException.INDEX_SIZE_ERR',
    'DOMCoreException.INUSE_ATTRIBUTE_ERR',
    'DOMCoreException.INVALID_ACCESS_ERR',
    'DOMCoreException.INVALID_CHARACTER_ERR',
    'DOMCoreException.INVALID_MODIFICATION_ERR',
    'DOMCoreException.INVALID_NODE_TYPE_ERR',
    'DOMCoreException.INVALID_STATE_ERR',
    'DOMCoreException.NAMESPACE_ERR',
    'DOMCoreException.NETWORK_ERR',
    'DOMCoreException.NOT_FOUND_ERR',
    'DOMCoreException.NOT_SUPPORTED_ERR',
    'DOMCoreException.NO_DATA_ALLOWED_ERR',
    'DOMCoreException.NO_MODIFICATION_ALLOWED_ERR',
    'DOMCoreException.QUOTA_EXCEEDED_ERR',
    'DOMCoreException.SECURITY_ERR',
    'DOMCoreException.SYNTAX_ERR',
    'DOMCoreException.TIMEOUT_ERR',
    'DOMCoreException.TYPE_MISMATCH_ERR',
    'DOMCoreException.URL_MISMATCH_ERR',
    'DOMCoreException.VALIDATION_ERR',
    'DOMCoreException.WRONG_DOCUMENT_ERR',
    'Element.accessKey',
    'Element.dataset',
    'Element.get:classList',
    'Element.getAttributeNode',
    'Element.getAttributeNodeNS',
    'Element.getElementsByTagNameNS',
    'Element.innerText',
    'Element.outerText',
    'Element.removeAttributeNode',
    'Element.set:outerHTML',
    'Element.setAttributeNode',
    'Element.setAttributeNodeNS',
    'Event.returnValue',
    'Event.srcElement',
    'EventSource.URL',
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
    'MessageEvent.webkitInitMessageEvent',
    'MouseEvent.x',
    'MouseEvent.y',
    'Node.compareDocumentPosition',
    'Node.get:ATTRIBUTE_NODE',
    'Node.get:CDATA_SECTION_NODE',
    'Node.get:COMMENT_NODE',
    'Node.get:DOCUMENT_FRAGMENT_NODE',
    'Node.get:DOCUMENT_NODE',
    'Node.get:DOCUMENT_POSITION_CONTAINED_BY',
    'Node.get:DOCUMENT_POSITION_CONTAINS',
    'Node.get:DOCUMENT_POSITION_DISCONNECTED',
    'Node.get:DOCUMENT_POSITION_FOLLOWING',
    'Node.get:DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC',
    'Node.get:DOCUMENT_POSITION_PRECEDING',
    'Node.get:DOCUMENT_TYPE_NODE',
    'Node.get:ELEMENT_NODE',
    'Node.get:ENTITY_NODE',
    'Node.get:ENTITY_REFERENCE_NODE',
    'Node.get:NOTATION_NODE',
    'Node.get:PROCESSING_INSTRUCTION_NODE',
    'Node.get:TEXT_NODE',
    'Node.get:baseURI',
    'Node.get:nodeName',
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
    'NodeList.item',
    'ShadowRoot.getElementsByTagNameNS',
    'SVGStyledElement.getPresentationAttribute',
    'WheelEvent.wheelDelta',
    'WorkerContext.webkitIndexedDB',
# TODO(jacobr): should these be removed?
    'Document.close',
    'Document.hasFocus',
    ])

# Manual dart: library name lookup.
_library_names = monitored.Dict('htmlrenamer._library_names', {
  'DOMWindow': 'html',
  'Navigator': 'html',
  'WorkerContext': 'html',
})

class HtmlRenamer(object):
  def __init__(self, database):
    self._database = database

  def RenameInterface(self, interface):
    if 'Callback' in interface.ext_attrs:
      if interface.id in _removed_html_interfaces:
        return None

    if interface.id in html_interface_renames:
      return html_interface_renames[interface.id]
    elif interface.id.startswith('HTML'):
      if any(interface.id in ['Element', 'Document']
             for interface in self._database.Hierarchy(interface)):
        return interface.id[len('HTML'):]
    return self.DartifyTypeName(interface.id)


  def RenameMember(self, interface_name, member_node, member, member_prefix='',
      dartify_name=True):
    """
    Returns the name of the member in the HTML library or None if the member is
    suppressed in the HTML library
    """
    interface = self._database.GetInterface(interface_name)

    if self.ShouldSuppressMember(interface, member, member_prefix):
      return None

    if 'CheckSecurityForNode' in member_node.ext_attrs:
      return None

    name = self._FindMatch(interface, member, member_prefix,
        renamed_html_members)

    target_name = renamed_html_members[name] if name else member
    if self._FindMatch(interface, member, member_prefix, _private_html_members):
      if not target_name.startswith('$dom_'):  # e.g. $dom_svgClassName
        target_name = '$dom_' + target_name

    if not name and target_name.startswith('webkit'):
      target_name = member[len('webkit'):]
      target_name = target_name[:1].lower() + target_name[1:]

    if dartify_name:
      target_name = self._DartifyMemberName(target_name)
    return target_name

  def ShouldSuppressMember(self, interface, member, member_prefix=''):
    """ Returns true if the member should be suppressed."""
    if self._FindMatch(interface, member, member_prefix,
        _removed_html_members):
      return True
    if interface.id in _removed_html_interfaces:
      return True
    return False

  def ShouldSuppressInterface(self, interface):
    """ Returns true if the interface should be suppressed."""
    if interface.id in _removed_html_interfaces:
      return True

  def _FindMatch(self, interface, member, member_prefix, candidates):
    for interface in self._database.Hierarchy(interface):
      member_name = interface.id + '.' + member
      if member_name in candidates:
        return member_name
      member_name = interface.id + '.' + member_prefix + member
      if member_name in candidates:
        return member_name
      member_name = interface.id + '.*'
      if member_name in candidates:
        return member_name

  def GetLibraryName(self, interface):
    # Some types have attributes merged in from many other interfaces.
    if interface.id in _library_names:
      return _library_names[interface.id]

    # TODO(ager, blois): The conditional has been removed from indexed db,
    # so we can no longer determine the library based on the conditionals.
    if interface.id.startswith("IDB"):
      return 'indexed_db'

    if 'Conditional' in interface.ext_attrs:
      if 'WEB_AUDIO' in interface.ext_attrs['Conditional']:
        return 'web_audio'
      if 'SVG' in interface.ext_attrs['Conditional']:
        return 'svg'
      if 'INDEXED_DATABASE' in interface.ext_attrs['Conditional']:
        return 'indexed_db'
      if 'SQL_DATABASE' in interface.ext_attrs['Conditional']:
        return 'web_sql'
      if 'WEBGL' in interface.ext_attrs['Conditional']:
        return 'web_gl'

    return 'html'

  def DartifyTypeName(self, type_name):
    """Converts a DOM name to a Dart-friendly class name. """

    if type_name in html_interface_renames:
      return html_interface_renames[type_name]

    # Strip off any standard prefixes.
    name = re.sub(r'^SVG', '', type_name)
    name = re.sub(r'^IDB', '', name)
    name = re.sub(r'^WebGL', '', name)

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
