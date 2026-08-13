# Editor Services

This document describes a common interface for service methods that editors/IDEs
may provide over DTD.

For a full list of common services, see [common_services](./dtd_common_services.md).

# Methods

Callers of these methods should monitor the
[`Service` stream](./dtd_protocol.md#service-methods) to ensure they are
available before calling them (it is not guaranteed that all editors provide
all methods).


## navigateToCode
`Success navigateToCode(NavigateToCodeParams)`

Instructs the editor to open and navigate to a file (and optional line/column).


## getActiveLocation
`ActiveLocation getActiveLocation()`

Asks the editor for information about the current open file and text cursor
location.


## getDevices
`GetDevicesResult getDevices()`

Requests the list of available devices from the editor. Devices can include
connected mobile devices, web browsers and the desktop device. The `supported`
flag can be used to tell whether a particular device is enabled in the current
workspace.

Callers of this method should first subscribe to the [`deviceXXX`](#deviceAdded)
events to be notified when devices are added/removed/updated.


## getDebugSessions
`GetDebugSessionsResult getDebugSessions()`

Requests a list of active debug sessions from the editor.

Callers of this method should first subscribe to the
[`debugSessionXXX`](#debugSessionStarted) events to be notified when debug
sessions are started/stopped/updated.


## selectDevice
`Success selectDevice(SelectDeviceParams)`

Instructs the editor to select a specific device (or no device). Callers should
not assume the active device has changed until they receive a `deviceSelected`
event.


## enablePlatformType
`Success enablePlatformType(EnablePlatformTypeParams)`

Instructs the editor to enable a `platformType` for the current workspace. This
may trigger a prompt to the user followed by executing commands (such as
`flutter create`). Callers should not assume the platform is enabled until they
receive a `deviceUpdated` event that shows `supported=true` for the devices of
that type.


## hotReload
`Success hotReload(HotReloadParams)`

Instructs the editor to trigger a hot reload for the provided debug session.


## hotRestart
`Success hotRestart(HotRestartParams)`

Instructs the editor to trigger a hot restart for the provided debug session.


## openDevToolsPage
`Success openDevToolsPage(OpenDevToolsPageParams)`

Instructs the editor to open DevTools at the given page for the provided debug
session.


# Events

The following events are sent over the `Editor` stream. See `streamListen` in
[dtd_protocol](./dtd_protocol.md) for information on subscribing to streams.


## activeLocationChanged
`ActiveLocationChangedEvent`

An event sent by an editor when the document/location where the user is
active (or the document itself) changes.

Only the active document is tracked, even if multiple documents are
open/visible at the same time. A new event replaces the active document and
previous selections from an earlier event.

Edits to the document are considered location changes even if the line/column
remain the same because they they are locations in a different document version.

This event may be debounced by the editor to avoid sending frequent events
during typing.


## deviceAdded
`DeviceAddedEvent`

An event sent by an editor when a new device becomes available.


## deviceRemoved
`DeviceRemovedEvent`

An event sent by an editor when a device is no longer available.


## deviceChanged
`DeviceChangedEvent`

An event sent by an editor when an existing device is updated.

The ID in this event always matches an existing device (that is, the ID never
changes, or it would be considered a removal/add).


## deviceSelected
`DeviceSelectedEvent`

An event sent by an editor when the current selected device was changed.

This could be as a result of the client itself calling the `selectDevice`
method or because the device changed for another reason (such as the user
selecting a device in the editor directly, or the previously selected device
is being removed).


## debugSessionStarted
`DebugSessionStartedEvent`

An event sent by an editor when a new debug session is started.


## debugSessionStopped
`DebugSessionStoppedEvent`

An event sent by an editor when a debug session ends.


## debugSessionChanged
`DebugSessionChangedEvent`

An event sent by an editor when a debug session is changed.

This could happen when a VM Service URI becomes available for a session
launched in debug mode, for example.


## themeChanged
`ThemeChangedEvent`

An event sent by an editor when its theme has changed.

This could happen when a user changes their settings to toggle between light
and dark mode or increase/decrease font size.

# Type Definitions

```dart
/// Represents an active location in an editor.
///
/// If there is no active document, `textDocument` will be `null`.
///
/// Otherwise, `selections` will contain at least one location for where the
/// text cursor(s) are.
class ActiveLocation {
  /// An identifier that represents the active document.
  ///
  /// `null` is there is no active document.
  OptionalVersionedTextDocumentIdentifier? textDocument;

  /// The set of selections in the document.
  ///
  /// There will always be at least one selection if there is an active document
  /// (textDocument != null), but there may also be more if a user has multiple
  /// selections active.
  ///
  /// The first selection is always the primary selection for actions that only
  /// support one location.
  List<EditorSelection> selections;
}

/// An event sent by an editor when the document/location where the user is
/// active changes.
///
/// Only the active document is tracked, even if multiple documents are
/// open/visible at the same time. A new event replaces the active document and
/// previous selections from an earlier event.
/// This event may be debounced by the editor to avoid sending frequent events
/// during typing.
class ActiveLocationChangedEvent extends ActiveLocation {}

/// An event sent by an editor when a debug session is changed.
///
/// This could be happen when a VM Service URI becomes available for a session
/// launched in debug mode, for example.
class DebugSessionChangedEvent {
  EditorDebugSession debugSession;
}

/// An event sent by an editor when a new debug session is started.
class DebugSessionStartedEvent {
  EditorDebugSession debugSession;
}

/// An event sent by an editor when a debug session ends.
class DebugSessionStoppedEvent {
  String debugSessionId;
}

/// An event sent by an editor when a new device becomes available.
class DeviceAddedEvent {
  EditorDevice device;
}

/// An event sent by an editor when an existing device is updated.
///
/// The ID in this event always matches an existing device (that is, the ID
/// never changes, or it would be considered a removal/add).
interface class DeviceChangedEvent {
  EditorDevice device;
}

/// An event sent by an editor when a device is no longer available.
class DeviceRemovedEvent {
  String deviceId;
}

/// An event sent by an editor when the current selected device was changed.
///
/// This could be as a result of the client itself calling the `selectDevice`
/// method or because the device changed for another reason (such as the user
/// selecting a device in the editor directly, or the previously selected device
/// is being removed).
class DeviceSelectedEvent {
  /// The ID of the device being selected, or `null` if the current device is
  /// being unselected without a new device being selected.
  String? deviceId;
}

/// An event sent by an editor when theme settings have changed.
class ThemeChangedEvent {
  Theme theme;
}

/// A debug session running in the editor.
class EditorDebugSession {
  String id;
  String name;
  String? vmServiceUri;
  String? flutterMode;
  String? flutterDeviceId;
  String? debuggerType;
  String? projectRootPath;
}

/// A device that is available in the editor.
class EditorDevice {
  String id;
  String name;
  String? category;
  bool emulator;
  String? emulatorId;
  bool ephemeral;
  String platform;
  String? platformType;

  /// Whether this device is supported for projects in the current workspace.
  ///
  /// If `false`, the `enablePlatformType` method can be used to ask the editor
  /// to enable it (which will trigger a `deviceChanged` event after the changes
  /// are made).
  bool supported;
}


/// A position inside a document.
class EditorPosition {
  /// The zero-based line number of this position.
  int line;

  /// The zero-based character number of this position.
  int character;
}

/// A selection inside a document.
class EditorSelection {
  /// The start/anchor position of a selection.
  ///
  /// This will be the same as [active] if this is just a single position and
  /// not a selection.
  ///
  /// This position may be before, after, or the same as [active] depending on
  /// the selection.
  EditorPosition anchor;

  /// The end/active position of a selection.
  EditorPosition active;
}

/// Parameters for the `enablePlatformTypeParams` request.
class EnablePlatformTypeParams {
  /// The `platformType` to enable.
  ///
  /// This should be taken from an [EditorDevice] that has `supported=false`.
  String platformType;
}

/// The result of a `getDebugSessions` request.
class GetDebugSessionsResult {
  /// The current active debug sessions.
  final List<EditorDebugSession> debugSessions;
}

/// The result of a `getDevices` request.
class GetDevicesResult {
  /// The current available devices.
  List<EditorDevice> devices;

  /// The ID of the device that is currently selected, if any.
  String? selectedDeviceId;
}

/// Parameters for the `hotReload` request.
class HotReloadParams {
  /// The ID of the debug session to hot reload.
  String debugSessionId;
}

/// Parameters for the `hotRestart` request.
class HotRestartParams {
  /// The ID of the debug session to hot restart.
  String debugSessionId;
}

/// Parameters for the `navigateToCode` request.
class NavigateToCodeParams {
  /// The URI of the location to navigate to. Only `file://` URIs are supported
  /// unless the service registration's `capabilities` indicate other schemes
  /// are supported.
  ///
  /// Editors should return error code 144 if a caller passes a URI with an
  /// unsupported scheme.
  String uri;

  /// Optional 1-based line number to navigate to.
  int? line;

  /// Optional 1-based column number to navigate to.
  int? column;
}

/// Parameters for the `openDevToolsPage` request.
class OpenDevToolsPageParams {
  /// The debug session to to provide to DevTools.
  String? debugSessionId;

  /// The DevTools page to open.
  String? page;

  /// Whether to force opening in an external browser even if user preferences
  /// are usually to be embedded.
  bool? forceExternal;

  /// Whether the target page requires a debug session.
  ///
  /// If so and [debugSessionId] is not supplied, the editor must provide a
  /// debug session (which it may prompt the user to select).
  bool? requiresDebugSession;

  /// Whether the target page prefers (but does not require) a debug session.
  ///
  /// Unlike [requiresDebugSession], editors may skip prompting for/providing a
  /// debug session unless there is already a single session that is the obvious
  /// target.
  bool? prefersDebugSession;
}

/// Parameters for the `selectDevice` request.
class SelectDeviceParams {
  /// The ID of the device to select (or `null` to unselect the current device).
  String? deviceId;
}

/// The description of an editor's theme.
class Theme {
  bool isDarkMode;
  String? backgroundColor;
  String? foregroundColor;
  int? fontSize;
}

/// An identifier for a document with an optional version number.
class OptionalVersionedTextDocumentIdentifier {
  /// The URI that represents the document.
  ///
  /// This URI could be of any scheme and clients should ignore those they do
  /// not understand. It is always a URI and never a bare file path.
  ///
  /// Clients should take care to handle paths that should be case-insensitive
  /// or include escaping. In particular, Windows drive letters may be cased
  /// inconsistently and the colon may be escaped as `%3a` or `%3A`.
  ///
  /// Examples:
  ///
  /// - file:///c:/foo/bar/baz.dart
  /// - file:///C%3A/foo/bar/baz.dart
  /// - file:///foo/bar/baz.dart
  /// - dart-macro+file:///c:/foo/bar/baz.dart
  /// - dart-macro+file:///C%3A/foo/bar/baz.dart
  /// - dart-macro+file:///foo/bar/baz.dart
  /// - vsls:///foo/bar/baz.dart
  String uri;

  /// The current version of this document, if the document is versioned. The
  /// version is used to to ensure locations within a document are only applied
  /// to the correct version of that document but not all editors provide it.
  int? version;
}
```
