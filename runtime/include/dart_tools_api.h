// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_INCLUDE_DART_TOOLS_API_H_
#define RUNTIME_INCLUDE_DART_TOOLS_API_H_

#include "dart_api.h"

/** \mainpage Dart Tools Embedding API Reference
 *
 * This reference describes the Dart embedding API for tools. Tools include
 * a debugger, service protocol, and timeline.
 *
 * NOTE: The APIs described in this file are unstable and subject to change.
 *
 * This reference is generated from the header include/dart_tools_api.h.
 */

/*
 * ========
 * Debugger
 * ========
 */

/**
 * ILLEGAL_ISOLATE_ID is a number guaranteed never to be associated with a
 * valid isolate.
 */
#define ILLEGAL_ISOLATE_ID ILLEGAL_PORT


/*
 * =======
 * Service
 * =======
 */

/**
 * A service request callback function.
 *
 * These callbacks, registered by the embedder, are called when the VM receives
 * a service request it can't handle and the service request command name
 * matches one of the embedder registered handlers.
 *
 * The return value of the callback indicates whether the response
 * should be used as a regular result or an error result.
 * Specifically, if the callback returns true, a regular JSON-RPC
 * response is built in the following way:
 *
 * {
 *   "jsonrpc": "2.0",
 *   "result": <json_object>,
 *   "id": <some sequence id>,
 * }
 *
 * If the callback returns false, a JSON-RPC error is built like this:
 *
 * {
 *   "jsonrpc": "2.0",
 *   "error": <json_object>,
 *   "id": <some sequence id>,
 * }
 *
 * \param method The rpc method name.
 * \param param_keys Service requests can have key-value pair parameters. The
 *   keys and values are flattened and stored in arrays.
 * \param param_values The values associated with the keys.
 * \param num_params The length of the param_keys and param_values arrays.
 * \param user_data The user_data pointer registered with this handler.
 * \param result A C string containing a valid JSON object. The returned
 *   pointer will be freed by the VM by calling free.
 *
 * \return True if the result is a regular JSON-RPC response, false if the
 *   result is a JSON-RPC error.
 */
typedef bool (*Dart_ServiceRequestCallback)(const char* method,
                                            const char** param_keys,
                                            const char** param_values,
                                            intptr_t num_params,
                                            void* user_data,
                                            const char** json_object);

/**
 * Register a Dart_ServiceRequestCallback to be called to handle
 * requests for the named rpc on a specific isolate. The callback will
 * be invoked with the current isolate set to the request target.
 *
 * \param method The name of the method that this callback is responsible for.
 * \param callback The callback to invoke.
 * \param user_data The user data passed to the callback.
 *
 * NOTE: If multiple callbacks with the same name are registered, only
 * the last callback registered will be remembered.
 */
DART_EXPORT void Dart_RegisterIsolateServiceRequestCallback(
    const char* method,
    Dart_ServiceRequestCallback callback,
    void* user_data);

/**
 * Register a Dart_ServiceRequestCallback to be called to handle
 * requests for the named rpc. The callback will be invoked without a
 * current isolate.
 *
 * \param method The name of the command that this callback is responsible for.
 * \param callback The callback to invoke.
 * \param user_data The user data passed to the callback.
 *
 * NOTE: If multiple callbacks with the same name are registered, only
 * the last callback registered will be remembered.
 */
DART_EXPORT void Dart_RegisterRootServiceRequestCallback(
    const char* method,
    Dart_ServiceRequestCallback callback,
    void* user_data);

/**
 * Embedder information which can be requested by the VM for internal or
 * reporting purposes.
 *
 * The pointers in this structure are not going to be cached or freed by the VM.
 */

 #define DART_EMBEDDER_INFORMATION_CURRENT_VERSION (0x00000001)

typedef struct {
  int32_t version;
  const char* name;  // [optional] The name of the embedder
  int64_t current_rss;  // [optional] the current RSS of the embedder
  int64_t max_rss;  // [optional] the maximum RSS of the embedder
} Dart_EmbedderInformation;

/**
 * Callback provided by the embedder that is used by the vm to request
 * information.
 *
 * \return Returns a pointer to a Dart_EmbedderInformation structure.
 * The embedder keeps the ownership of the structure and any field in it.
 * The embedder must ensure that the structure will remain valid until the
 * next invokation of the callback.
 */
typedef void (*Dart_EmbedderInformationCallback)(
    Dart_EmbedderInformation* info);

/**
 * Register a Dart_ServiceRequestCallback to be called to handle
 * requests for the named rpc. The callback will be invoked without a
 * current isolate.
 *
 * \param method The name of the command that this callback is responsible for.
 * \param callback The callback to invoke.
 * \param user_data The user data passed to the callback.
 *
 * NOTE: If multiple callbacks with the same name are registered, only
 * the last callback registered will be remembered.
 */
DART_EXPORT void Dart_SetEmbedderInformationCallback(
    Dart_EmbedderInformationCallback callback);

/*
 * ========
 * Event Streams
 * ========
 */

/**
 * A callback invoked when the VM service gets a request to listen to
 * some stream.
 *
 * \return Returns true iff the embedder supports the named stream id.
 */
typedef bool (*Dart_ServiceStreamListenCallback)(const char* stream_id);

/**
 * A callback invoked when the VM service gets a request to cancel
 * some stream.
 */
typedef void (*Dart_ServiceStreamCancelCallback)(const char* stream_id);

/**
 * Adds VM service stream callbacks.
 *
 * \param listen_callback A function pointer to a listen callback function.
 *   A listen callback function should not be already set when this function
 *   is called. A NULL value removes the existing listen callback function
 *   if any.
 *
 * \param cancel_callback A function pointer to a cancel callback function.
 *   A cancel callback function should not be already set when this function
 *   is called. A NULL value removes the existing cancel callback function
 *   if any.
 *
 * \return Success if the callbacks were added.  Otherwise, returns an
 *   error handle.
 */
DART_EXPORT Dart_Handle Dart_SetServiceStreamCallbacks(
    Dart_ServiceStreamListenCallback listen_callback,
    Dart_ServiceStreamCancelCallback cancel_callback);

/**
 * Sends a data event to clients of the VM Service.
 *
 * A data event is used to pass an array of bytes to subscribed VM
 * Service clients.  For example, in the standalone embedder, this is
 * function used to provide WriteEvents on the Stdout and Stderr
 * streams.
 *
 * If the embedder passes in a stream id for which no client is
 * subscribed, then the event is ignored.
 *
 * \param stream_id The id of the stream on which to post the event.
 *
 * \param event_kind A string identifying what kind of event this is.
 *   For example, 'WriteEvent'.
 *
 * \param bytes A pointer to an array of bytes.
 *
 * \param bytes_length The length of the byte array.
 *
 * \return Success if the arguments are well formed.  Otherwise, returns an
 *   error handle.
 */
DART_EXPORT Dart_Handle Dart_ServiceSendDataEvent(const char* stream_id,
                                                  const char* event_kind,
                                                  const uint8_t* bytes,
                                                  intptr_t bytes_length);

/*
 * ========
 * Reload support
 * ========
 *
 * These functions are used to implement reloading in the Dart VM.
 * This is an experimental feature, so embedders should be prepared
 * for these functions to change.
 */

/**
 * A callback which determines whether the file at some url has been
 * modified since some time.  If the file cannot be found, true should
 * be returned.
 */
typedef bool (*Dart_FileModifiedCallback)(const char* url, int64_t since);

DART_EXPORT Dart_Handle
Dart_SetFileModifiedCallback(Dart_FileModifiedCallback file_modified_callback);

/**
 * Returns true if isolate is currently reloading.
 */
DART_EXPORT bool Dart_IsReloading();

/*
 * ========
 * Timeline
 * ========
 */

/**
 * Returns a timestamp in microseconds. This timestamp is suitable for
 * passing into the timeline system.
 *
 * \return A timestamp that can be passed to the timeline system.
 */
DART_EXPORT int64_t Dart_TimelineGetMicros();

/** Timeline stream for Dart API calls */
#define DART_TIMELINE_STREAM_API (1 << 0)
/** Timeline stream for compiler events */
#define DART_TIMELINE_STREAM_COMPILER (1 << 1)
/** Timeline stream for Dart provided events */
#define DART_TIMELINE_STREAM_DART (1 << 2)
/** Timeline stream for debugger provided events */
#define DART_TIMELINE_STREAM_DEBUGGER (1 << 3)
/** Timeline stream for embedder provided events */
#define DART_TIMELINE_STREAM_EMBEDDER (1 << 4)
/** Timeline stream for GC events */
#define DART_TIMELINE_STREAM_GC (1 << 5)
/** Timeline stream for isolate events */
#define DART_TIMELINE_STREAM_ISOLATE (1 << 6)
/** Timeline stream for VM events */
#define DART_TIMELINE_STREAM_VM (1 << 7)

/** All timeline streams */
#define DART_TIMELINE_STREAM_ALL                                               \
  (DART_TIMELINE_STREAM_API | DART_TIMELINE_STREAM_COMPILER |                  \
   DART_TIMELINE_STREAM_DART | DART_TIMELINE_STREAM_DEBUGGER |                 \
   DART_TIMELINE_STREAM_EMBEDDER | DART_TIMELINE_STREAM_GC |                   \
   DART_TIMELINE_STREAM_ISOLATE | DART_TIMELINE_STREAM_VM)

/** Disable all timeline stream recording */
#define DART_TIMELINE_STREAM_DISABLE 0

/**
 * Start recording timeline events for the entire VM (including all isolates).
 *
 * \param stream_mask A bitmask of streams that should be recorded.
 *
 * NOTE: Calling with 0 disables recording of all streams.
 */
DART_EXPORT void Dart_GlobalTimelineSetRecordedStreams(int64_t stream_mask);

typedef enum {
  /** Indicates a new stream is being output */
  Dart_StreamConsumer_kStart = 0,
  /** Data for the current stream */
  Dart_StreamConsumer_kData = 1,
  /** Indicates stream is finished */
  Dart_StreamConsumer_kFinish = 2,
} Dart_StreamConsumer_State;

/**
 * A stream consumer callback function.
 *
 * This function will be called repeatedly until there is no more data in a
 * stream and there are no more streams.
 *
 * \param state Indicates a new stream, data, or a finished stream.
 * \param stream_name A name for this stream. Not guaranteed to be meaningful.
 * \param buffer A pointer to the stream data.
 * \param buffer_length The number of bytes at buffer that should be consumed.
 * \param stream_callback_data The pointer passed in when requesting the stream.
 *
 * At the start of each stream state will be DART_STREAM_CONSUMER_STATE_START
 * and buffer will be NULL.
 *
 * For each chunk of data the state will be DART_STREAM_CONSUMER_STATE_DATA
 * and buffer will not be NULL.
 *
 * At the end of each stream state will be DART_STREAM_CONSUMER_STATE_FINISH
 * and buffer will be NULL.
 */
typedef void (*Dart_StreamConsumer)(Dart_StreamConsumer_State state,
                                    const char* stream_name,
                                    const uint8_t* buffer,
                                    intptr_t buffer_length,
                                    void* stream_callback_data);

/**
 * Get the timeline for entire VM (including all isolates).
 *
 * NOTE: The timeline retrieved from this API call may not include the most
 * recent events.
 *
 * \param consumer A Dart_StreamConsumer.
 * \param user_data User data passed into consumer.
 *
 * NOTE: The trace-event format is documented here: https://goo.gl/hDZw5M
 *
 * \return True if a stream was output.
 */
DART_EXPORT bool Dart_GlobalTimelineGetTrace(Dart_StreamConsumer consumer,
                                             void* user_data);

typedef enum {
  Dart_Timeline_Event_Begin,          // Phase = 'B'.
  Dart_Timeline_Event_End,            // Phase = 'E'.
  Dart_Timeline_Event_Instant,        // Phase = 'i'.
  Dart_Timeline_Event_Duration,       // Phase = 'X'.
  Dart_Timeline_Event_Async_Begin,    // Phase = 'b'.
  Dart_Timeline_Event_Async_End,      // Phase = 'e'.
  Dart_Timeline_Event_Async_Instant,  // Phase = 'n'.
  Dart_Timeline_Event_Counter,        // Phase = 'C'.
  Dart_Timeline_Event_Flow_Begin,     // Phase = 's'.
  Dart_Timeline_Event_Flow_Step,      // Phase = 't'.
  Dart_Timeline_Event_Flow_End,       // Phase = 'f'.
} Dart_Timeline_Event_Type;

/**
 * Add a timeline event to the embedder stream.
 *
 * \param label The name of the evnet.
 * \param timestamp0 The first timestamp of the event.
 * \param timestamp1_or_async_id The second timestamp of the event or
 *     the async id.
 * \param argument_count The number of argument names and values.
 * \param argument_names An array of names of the arguments.
 * \param argument_values An array of values of the arguments.
 */
DART_EXPORT void Dart_TimelineEvent(const char* label,
                                    int64_t timestamp0,
                                    int64_t timestamp1_or_async_id,
                                    Dart_Timeline_Event_Type type,
                                    intptr_t argument_count,
                                    const char** argument_names,
                                    const char** argument_values);

/**
 * Associates a name with the current thread. This name will be used to name
 * threads in the timeline. Can only be called after a call to Dart_Initialize.
 *
 * \param name The name of the thread.
 */
DART_EXPORT void Dart_SetThreadName(const char* name);

/**
 * Called by the VM to let the embedder know when to start recording into the
 * timeline. Can be called from any thread.
 */
typedef void (*Dart_EmbedderTimelineStartRecording)();

/**
 * Called by the VM to let the embedder know when to stop recording into the
 * timeline. Can be called from any thread.
 */
typedef void (*Dart_EmbedderTimelineStopRecording)();

/**
 * Sets the embedder timeline callbacks. These callbacks are used by the VM
 * to notify the embedder of timeline recording state changes.
 *
 * \param start_recording See Dart_EmbedderTimelineStartRecording.
 * \param stop_recording See Dart_EmbedderTimelineStopRecording.
 *
 * NOTE: To avoid races, this should be called before Dart_Initialize.
 */
DART_EXPORT void Dart_SetEmbedderTimelineCallbacks(
    Dart_EmbedderTimelineStartRecording start_recording,
    Dart_EmbedderTimelineStopRecording stop_recording);

#endif  // RUNTIME_INCLUDE_DART_TOOLS_API_H_
