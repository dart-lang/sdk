// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _blink;

// _Utils native entry points
Native_Utils_window() native "Utils_window";

Native_Utils_forwardingPrint(message) native "Utils_forwardingPrint";

Native_Utils_spawnDomUri(uri) native "Utils_spawnDomUri";

Native_Utils_register(document, tag, customType, extendsTagName) native "Utils_register";

Native_Utils_createElement(document, tagName) native "Utils_createElement";

Native_Utils_initializeCustomElement(element) native "Utils_initializeCustomElement";

Native_Utils_changeElementWrapper(element, type) native "Utils_changeElementWrapper";

// _DOMWindowCrossFrame native entry points
Native_DOMWindowCrossFrame_get_history(_DOMWindowCrossFrame) native "WindowCrossFrame_history_Getter";

Native_DOMWindowCrossFrame_get_location(_DOMWindowCrossFrame) native "WindowCrossFrame_location_Getter";

Native_DOMWindowCrossFrame_get_closed(_DOMWindowCrossFrame) native "WindowCrossFrame_closed_Getter";

Native_DOMWindowCrossFrame_get_opener(_DOMWindowCrossFrame) native "WindowCrossFrame_opener_Getter";

Native_DOMWindowCrossFrame_get_parent(_DOMWindowCrossFrame) native "WindowCrossFrame_parent_Getter";

Native_DOMWindowCrossFrame_get_top(_DOMWindowCrossFrame) native "WindowCrossFrame_top_Getter";

Native_DOMWindowCrossFrame_close(_DOMWindowCrossFrame) native "WindowCrossFrame_close_Callback";

Native_DOMWindowCrossFrame_postMessage(_DOMWindowCrossFrame, message, targetOrigin, [messagePorts]) native "WindowCrossFrame_postMessage_Callback";

// _HistoryCrossFrame native entry points
Native_HistoryCrossFrame_back(_HistoryCrossFrame) native "HistoryCrossFrame_back_Callback";

Native_HistoryCrossFrame_forward(_HistoryCrossFrame) native "HistoryCrossFrame_forward_Callback";

Native_HistoryCrossFrame_go(_HistoryCrossFrame, distance) native "HistoryCrossFrame_go_Callback";

// _LocationCrossFrame native entry points
Native_LocationCrossFrame_set_href(_LocationCrossFrame, h) native "LocationCrossFrame_href_Setter";

// _DOMStringMap native entry  points
Native_DOMStringMap_containsKey(_DOMStringMap, key) native "DOMStringMap_containsKey_Callback";

Native_DOMStringMap_item(_DOMStringMap, key) native "DOMStringMap_item_Callback";

Native_DOMStringMap_setItem(_DOMStringMap, key, value) native "DOMStringMap_setItem_Callback";

Native_DOMStringMap_remove(_DOMStringMap, key) native "DOMStringMap_remove_Callback";

Native_DOMStringMap_get_keys(_DOMStringMap) native "DOMStringMap_getKeys_Callback";
