// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED) && !defined(DART_IO_SECURE_SOCKET_DISABLED)

#include "platform/globals.h"
#if TARGET_OS_IOS

#include "bin/secure_socket.h"
#include "bin/secure_socket_ios.h"

#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/syslimits.h>
#include <stdio.h>
#include <string.h>

#include <CoreFoundation/CoreFoundation.h>
#include <Security/SecureTransport.h>
#include <Security/Security.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/lockers.h"
#include "bin/log.h"
#include "bin/socket.h"
#include "bin/thread.h"
#include "bin/utils.h"

#include "platform/text_buffer.h"
#include "platform/utils.h"

#include "include/dart_api.h"

// Return the error from the containing function if handle is an error handle.
#define RETURN_IF_ERROR(handle)                                                \
  {                                                                            \
    Dart_Handle __handle = handle;                                             \
    if (Dart_IsError((__handle))) {                                            \
      return __handle;                                                         \
    }                                                                          \
  }

namespace dart {
namespace bin {

static const int kSSLFilterNativeFieldIndex = 0;
static const int kSecurityContextNativeFieldIndex = 0;
static const int kX509NativeFieldIndex = 0;

static const bool SSL_LOG_STATUS = false;
static const bool SSL_LOG_DATA = false;
static const bool SSL_LOG_CERTS = false;
static const int SSL_ERROR_MESSAGE_BUFFER_SIZE = 1000;
static const intptr_t PEM_BUFSIZE = 1024;

static char* CFStringRefToCString(CFStringRef cfstring) {
  CFIndex len = CFStringGetLength(cfstring);
  CFIndex max_len =
      CFStringGetMaximumSizeForEncoding(len, kCFStringEncodingUTF8) + 1;
  char* result = reinterpret_cast<char*>(Dart_ScopeAllocate(max_len));
  ASSERT(result != NULL);
  bool success =
      CFStringGetCString(cfstring, result, max_len, kCFStringEncodingUTF8);
  return success ? result : NULL;
}


// Handle an error reported from the SecureTransport library.
static void ThrowIOException(OSStatus status,
                             const char* exception_type,
                             const char* message) {
  TextBuffer status_message(SSL_ERROR_MESSAGE_BUFFER_SIZE);
  status_message.Printf("OSStatus = %ld: https://www.osstatus.com",
                        static_cast<intptr_t>(status));
  OSError os_error_struct(status, status_message.buf(), OSError::kBoringSSL);
  Dart_Handle os_error = DartUtils::NewDartOSError(&os_error_struct);
  Dart_Handle exception =
      DartUtils::NewDartIOException(exception_type, message, os_error);
  ASSERT(!Dart_IsError(exception));
  Dart_ThrowException(exception);
  UNREACHABLE();
}


static void CheckStatus(OSStatus status,
                        const char* type,
                        const char* message) {
  if (status == noErr) {
    return;
  }
  ThrowIOException(status, type, message);
}


static SSLFilter* GetFilter(Dart_NativeArguments args) {
  SSLFilter* filter;
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  ASSERT(Dart_IsInstance(dart_this));
  ThrowIfError(
      Dart_GetNativeInstanceField(dart_this, kSSLFilterNativeFieldIndex,
                                  reinterpret_cast<intptr_t*>(&filter)));
  return filter;
}


static void DeleteFilter(void* isolate_data,
                         Dart_WeakPersistentHandle handle,
                         void* context_pointer) {
  SSLFilter* filter = reinterpret_cast<SSLFilter*>(context_pointer);
  filter->Release();
}


static Dart_Handle SetFilter(Dart_NativeArguments args, SSLFilter* filter) {
  ASSERT(filter != NULL);
  const int approximate_size_of_filter = 1500;
  Dart_Handle dart_this = Dart_GetNativeArgument(args, 0);
  RETURN_IF_ERROR(dart_this);
  ASSERT(Dart_IsInstance(dart_this));
  Dart_Handle err =
      Dart_SetNativeInstanceField(dart_this, kSSLFilterNativeFieldIndex,
                                  reinterpret_cast<intptr_t>(filter));
  RETURN_IF_ERROR(err);
  Dart_NewWeakPersistentHandle(dart_this, reinterpret_cast<void*>(filter),
                               approximate_size_of_filter, DeleteFilter);
  return Dart_Null();
}


static SSLCertContext* GetSecurityContext(Dart_NativeArguments args) {
  SSLCertContext* context;
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  ASSERT(Dart_IsInstance(dart_this));
  ThrowIfError(
      Dart_GetNativeInstanceField(dart_this, kSecurityContextNativeFieldIndex,
                                  reinterpret_cast<intptr_t*>(&context)));
  return context;
}


static void DeleteCertContext(void* isolate_data,
                              Dart_WeakPersistentHandle handle,
                              void* context_pointer) {
  SSLCertContext* context = static_cast<SSLCertContext*>(context_pointer);
  context->Release();
}


static Dart_Handle SetSecurityContext(Dart_NativeArguments args,
                                      SSLCertContext* context) {
  const int approximate_size_of_context = 1500;
  Dart_Handle dart_this = Dart_GetNativeArgument(args, 0);
  RETURN_IF_ERROR(dart_this);
  ASSERT(Dart_IsInstance(dart_this));
  Dart_Handle err =
      Dart_SetNativeInstanceField(dart_this, kSecurityContextNativeFieldIndex,
                                  reinterpret_cast<intptr_t>(context));
  RETURN_IF_ERROR(err);
  Dart_NewWeakPersistentHandle(dart_this, context, approximate_size_of_context,
                               DeleteCertContext);
  return Dart_Null();
}


static SecCertificateRef GetX509Certificate(Dart_NativeArguments args) {
  SecCertificateRef certificate;
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  ASSERT(Dart_IsInstance(dart_this));
  ThrowIfError(
      Dart_GetNativeInstanceField(dart_this, kX509NativeFieldIndex,
                                  reinterpret_cast<intptr_t*>(&certificate)));
  return certificate;
}


static void ReleaseCertificate(void* isolate_data,
                               Dart_WeakPersistentHandle handle,
                               void* context_pointer) {
  SecCertificateRef cert = reinterpret_cast<SecCertificateRef>(context_pointer);
  CFRelease(cert);
}


static Dart_Handle WrappedX509Certificate(SecCertificateRef certificate) {
  const intptr_t approximate_size_of_certificate = 1500;
  if (certificate == NULL) {
    return Dart_Null();
  }
  Dart_Handle x509_type =
      DartUtils::GetDartType(DartUtils::kIOLibURL, "X509Certificate");
  if (Dart_IsError(x509_type)) {
    return x509_type;
  }
  Dart_Handle arguments[] = {NULL};

  Dart_Handle result =
      Dart_New(x509_type, DartUtils::NewString("_"), 0, arguments);
  if (Dart_IsError(result)) {
    return result;
  }
  ASSERT(Dart_IsInstance(result));

  // CFRetain in case the returned Dart object outlives the SecurityContext.
  // CFRelease is in the Dart object's finalizer
  CFRetain(certificate);
  Dart_NewWeakPersistentHandle(result, reinterpret_cast<void*>(certificate),
                               approximate_size_of_certificate,
                               ReleaseCertificate);

  Dart_Handle status = Dart_SetNativeInstanceField(
      result, kX509NativeFieldIndex, reinterpret_cast<intptr_t>(certificate));
  if (Dart_IsError(status)) {
    return status;
  }
  return result;
}


static const char* GetPasswordArgument(Dart_NativeArguments args,
                                       intptr_t index) {
  Dart_Handle password_object =
      ThrowIfError(Dart_GetNativeArgument(args, index));
  const char* password = NULL;
  if (Dart_IsString(password_object)) {
    ThrowIfError(Dart_StringToCString(password_object, &password));
    if (strlen(password) > PEM_BUFSIZE - 1) {
      Dart_ThrowException(DartUtils::NewDartArgumentError(
          "Password length is greater than 1023 bytes."));
    }
  } else if (Dart_IsNull(password_object)) {
    password = "";
  } else {
    Dart_ThrowException(
        DartUtils::NewDartArgumentError("Password is not a String or null"));
  }
  return password;
}


static OSStatus TryPKCS12Import(CFDataRef cfdata,
                                CFStringRef password,
                                CFArrayRef* out_certs,
                                SecIdentityRef* out_identity) {
  const void* keys[] = {kSecImportExportPassphrase};
  const void* values[] = {password};
  CFDictionaryRef params =
      CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
  CFArrayRef items = NULL;
  OSStatus status = SecPKCS12Import(cfdata, params, &items);
  CFRelease(params);

  if (status != noErr) {
    if (SSL_LOG_STATUS) {
      Log::PrintErr("SecPKCS12Import: status = %ld",
                    static_cast<intptr_t>(status));
      return status;
    }
  }

  CFIndex items_length = (items == NULL) ? 0 : CFArrayGetCount(items);
  if (SSL_LOG_CERTS) {
    Log::PrintErr("TryPKCS12Import succeeded, count = %ld\n", items_length);
  }

  // Empty list indicates a decoding failure of some sort.
  if ((items != NULL) && (items_length == 0)) {
    CFRelease(items);
    return errSSLBadCert;
  }

  CFMutableArrayRef result_certs =
      CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
  SecIdentityRef result_identity = NULL;

  for (CFIndex i = 0; i < items_length; i++) {
    CFTypeRef item =
        reinterpret_cast<CFTypeRef>(CFArrayGetValueAtIndex(items, i));
    ASSERT(CFGetTypeID(item) == CFDictionaryGetTypeID());
    CFDictionaryRef dict = reinterpret_cast<CFDictionaryRef>(item);

    //  Trust.
    CFTypeRef trust_item = CFDictionaryGetValue(dict, kSecImportItemTrust);
    if (trust_item != NULL) {
      ASSERT(CFGetTypeID(trust_item) == SecTrustGetTypeID());
      if (SSL_LOG_CERTS) {
        Log::PrintErr("\titem %ld has a trust object\n", i);
      }
      // TODO(zra): Is this useful for anything?
    }

    // Identity.
    CFTypeRef identity_item =
        CFDictionaryGetValue(dict, kSecImportItemIdentity);
    if (identity_item != NULL) {
      ASSERT(CFGetTypeID(identity_item) == SecIdentityGetTypeID());
      if (SSL_LOG_CERTS) {
        Log::PrintErr("\titem %ld has an identity object\n", i);
      }
      // Only extract the first identity we find.
      if (result_identity == NULL) {
        result_identity =
            reinterpret_cast<SecIdentityRef>(const_cast<void*>(identity_item));
        CFRetain(result_identity);
      }
    }

    // Certificates.
    CFTypeRef cert_items = CFDictionaryGetValue(dict, kSecImportItemCertChain);
    if (cert_items != NULL) {
      ASSERT(CFGetTypeID(cert_items) == CFArrayGetTypeID());
      CFArrayRef certs = reinterpret_cast<CFArrayRef>(cert_items);
      if (SSL_LOG_CERTS) {
        CFIndex count = CFArrayGetCount(certs);
        Log::PrintErr("\titem %ld has a cert chain %ld certs long\n", i, count);
      }
      CFArrayAppendArray(result_certs, certs,
                         CFRangeMake(0, CFArrayGetCount(certs)));
    }
  }

  if (out_certs == NULL) {
    if (result_certs != NULL) {
      CFRelease(result_certs);
    }
  } else {
    *out_certs = result_certs;
  }

  if (out_identity == NULL) {
    if (result_identity != NULL) {
      CFRelease(result_identity);
    }
  } else {
    *out_identity = result_identity;
  }

  // On failure, don't return any objects.
  ASSERT((status == noErr) ||
         ((result_certs == NULL) && (result_identity == NULL)));
  return status;
}


static OSStatus ExtractSecItems(uint8_t* buffer,
                                intptr_t length,
                                const char* password,
                                CFArrayRef* out_certs,
                                SecIdentityRef* out_identity) {
  ASSERT(buffer != NULL);
  ASSERT(password != NULL);
  OSStatus status = noErr;

  CFDataRef cfdata =
      CFDataCreateWithBytesNoCopy(NULL, buffer, length, kCFAllocatorNull);
  CFStringRef cfpassword = CFStringCreateWithCStringNoCopy(
      NULL, password, kCFStringEncodingUTF8, kCFAllocatorNull);
  ASSERT(cfdata != NULL);
  ASSERT(cfpassword != NULL);

  status = TryPKCS12Import(cfdata, cfpassword, out_certs, out_identity);

  CFRelease(cfdata);
  CFRelease(cfpassword);
  return status;
}


void FUNCTION_NAME(SecureSocket_Init)(Dart_NativeArguments args) {
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  SSLFilter* filter = new SSLFilter();  // Deleted in DeleteFilter finalizer.
  Dart_Handle err = SetFilter(args, filter);
  if (Dart_IsError(err)) {
    filter->Release();
    Dart_PropagateError(err);
  }
  err = filter->Init(dart_this);
  if (Dart_IsError(err)) {
    // The finalizer was set up by SetFilter. It will delete `filter` if there
    // is an error.
    filter->Destroy();
    Dart_PropagateError(err);
  }
}


void FUNCTION_NAME(SecureSocket_Connect)(Dart_NativeArguments args) {
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  Dart_Handle host_name_object = ThrowIfError(Dart_GetNativeArgument(args, 1));
  Dart_Handle context_object = ThrowIfError(Dart_GetNativeArgument(args, 2));
  bool is_server = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 3));
  bool request_client_certificate =
      DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 4));
  bool require_client_certificate =
      DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 5));

  const char* host_name = NULL;
  // TODO(whesse): Is truncating a Dart string containing \0 what we want?
  ThrowIfError(Dart_StringToCString(host_name_object, &host_name));

  SSLCertContext* context = NULL;
  if (!Dart_IsNull(context_object)) {
    ThrowIfError(Dart_GetNativeInstanceField(
        context_object, kSecurityContextNativeFieldIndex,
        reinterpret_cast<intptr_t*>(&context)));
  }

  GetFilter(args)->Connect(dart_this, host_name, context, is_server,
                           request_client_certificate,
                           require_client_certificate);
}


void FUNCTION_NAME(SecureSocket_Destroy)(Dart_NativeArguments args) {
  SSLFilter* filter = GetFilter(args);
  // The SSLFilter is deleted in the finalizer for the Dart object created by
  // SetFilter. There is no need to NULL-out the native field for the SSLFilter
  // here because the SSLFilter won't be deleted until the finalizer for the
  // Dart object runs while the Dart object is being GCd. This approach avoids a
  // leak if Destroy isn't called, and avoids a NULL-dereference if Destroy is
  // called more than once.
  filter->Destroy();
}


void FUNCTION_NAME(SecureSocket_Handshake)(Dart_NativeArguments args) {
  OSStatus status = GetFilter(args)->CheckHandshake();
  CheckStatus(status, "HandshakeException", "Handshake error");
}


void FUNCTION_NAME(SecureSocket_GetSelectedProtocol)(
    Dart_NativeArguments args) {
  Dart_SetReturnValue(args, Dart_Null());
}


void FUNCTION_NAME(SecureSocket_Renegotiate)(Dart_NativeArguments args) {
  bool use_session_cache =
      DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 1));
  bool request_client_certificate =
      DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 2));
  bool require_client_certificate =
      DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 3));
  GetFilter(args)->Renegotiate(use_session_cache, request_client_certificate,
                               require_client_certificate);
}


void FUNCTION_NAME(SecureSocket_RegisterHandshakeCompleteCallback)(
    Dart_NativeArguments args) {
  Dart_Handle handshake_complete =
      ThrowIfError(Dart_GetNativeArgument(args, 1));
  if (!Dart_IsClosure(handshake_complete)) {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "Illegal argument to RegisterHandshakeCompleteCallback"));
  }
  GetFilter(args)->RegisterHandshakeCompleteCallback(handshake_complete);
}


void FUNCTION_NAME(SecureSocket_RegisterBadCertificateCallback)(
    Dart_NativeArguments args) {
  Dart_Handle callback = ThrowIfError(Dart_GetNativeArgument(args, 1));
  if (!Dart_IsClosure(callback) && !Dart_IsNull(callback)) {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "Illegal argument to RegisterBadCertificateCallback"));
  }
  GetFilter(args)->RegisterBadCertificateCallback(callback);
}


void FUNCTION_NAME(SecureSocket_PeerCertificate)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, GetFilter(args)->PeerCertificate());
}


void FUNCTION_NAME(SecureSocket_FilterPointer)(Dart_NativeArguments args) {
  SSLFilter* filter = GetFilter(args);
  // This filter pointer is passed to the IO Service thread. The IO Service
  // thread must Release() the pointer when it is done with it.
  filter->Retain();
  intptr_t filter_pointer = reinterpret_cast<intptr_t>(filter);
  Dart_SetReturnValue(args, Dart_NewInteger(filter_pointer));
}


void FUNCTION_NAME(SecurityContext_Allocate)(Dart_NativeArguments args) {
  SSLCertContext* cert_context = new SSLCertContext();
  // cert_context deleted in DeleteCertContext finalizer.
  Dart_Handle err = SetSecurityContext(args, cert_context);
  if (Dart_IsError(err)) {
    cert_context->Release();
    Dart_PropagateError(err);
  }
}


void FUNCTION_NAME(SecurityContext_UsePrivateKeyBytes)(
    Dart_NativeArguments args) {
  SSLCertContext* context = GetSecurityContext(args);
  const char* password = GetPasswordArgument(args, 2);

  OSStatus status;
  CFArrayRef cert_chain = NULL;
  SecIdentityRef identity = NULL;
  {
    ScopedMemBuffer buffer(ThrowIfError(Dart_GetNativeArgument(args, 1)));
    status = ExtractSecItems(buffer.get(), buffer.length(), password,
                             &cert_chain, &identity);
  }

  // Set the context fields. Repeated calls to usePrivateKeyBytes are an error.
  bool set_failure = false;
  if ((identity != NULL) && !context->set_identity(identity)) {
    CFRelease(identity);
    if (cert_chain != NULL) {
      CFRelease(cert_chain);
    }
    set_failure = true;
  }

  // We can't have set a cert_chain without also having set an identity.
  // That is, if context->set_identity() succeeds, then it is impossible for
  // context->set_cert_chain() to fail. This is because SecPKCS12Import never
  // returns a cert chain without also returning a private key.
  ASSERT(set_failure || (context->cert_chain() == NULL));
  if (!set_failure && (cert_chain != NULL)) {
    context->set_cert_chain(cert_chain);
  }

  if (set_failure) {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "usePrivateKeyBytes has already been called on the given context."));
  }
  CheckStatus(status, "TlsException", "Failure in usePrivateKeyBytes");
}


void FUNCTION_NAME(SecurityContext_SetTrustedCertificatesBytes)(
    Dart_NativeArguments args) {
  SSLCertContext* context = GetSecurityContext(args);

  OSStatus status = noErr;
  SecCertificateRef cert = NULL;
  {
    ScopedMemBuffer buffer(ThrowIfError(Dart_GetNativeArgument(args, 1)));
    CFDataRef cfdata = CFDataCreateWithBytesNoCopy(
        NULL, buffer.get(), buffer.length(), kCFAllocatorNull);
    cert = SecCertificateCreateWithData(NULL, cfdata);
    CFRelease(cfdata);
  }

  // Add the certs to the context.
  if (cert != NULL) {
    context->add_trusted_cert(cert);
  } else {
    status = errSSLBadCert;
  }
  CheckStatus(status, "TlsException", "Failure in setTrustedCertificatesBytes");
}


void FUNCTION_NAME(SecurityContext_AlpnSupported)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, Dart_NewBoolean(false));
}


void FUNCTION_NAME(SecurityContext_TrustBuiltinRoots)(
    Dart_NativeArguments args) {
  SSLCertContext* context = GetSecurityContext(args);
  context->set_trust_builtin(true);
}


void FUNCTION_NAME(SecurityContext_UseCertificateChainBytes)(
    Dart_NativeArguments args) {
  // This is a no-op on iOS. We get the cert chain along with the private key
  // in UsePrivateyKeyBytes().
}


void FUNCTION_NAME(SecurityContext_SetClientAuthoritiesBytes)(
    Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartUnsupportedError(
      "SecurityContext.setClientAuthoritiesBytes is not supported on this "
      "platform."));
}


void FUNCTION_NAME(SecurityContext_SetAlpnProtocols)(
    Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartUnsupportedError(
      "ALPN is not supported on this platform"));
}


void FUNCTION_NAME(X509_Subject)(Dart_NativeArguments args) {
  SecCertificateRef certificate = GetX509Certificate(args);
  CFStringRef cfsubject = SecCertificateCopySubjectSummary(certificate);
  if (cfsubject != NULL) {
    char* csubject = CFStringRefToCString(cfsubject);
    CFRelease(cfsubject);
    Dart_SetReturnValue(args, Dart_NewStringFromCString(csubject));
  } else {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "X509.subject failed to find subject's common name."));
  }
}


void FUNCTION_NAME(X509_Issuer)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartUnsupportedError(
      "X509Certificate.issuer is not supported on this platform."));
}


void FUNCTION_NAME(X509_StartValidity)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartUnsupportedError(
      "X509Certificate.startValidity is not supported on this platform."));
}


void FUNCTION_NAME(X509_EndValidity)(Dart_NativeArguments args) {
  Dart_ThrowException(DartUtils::NewDartUnsupportedError(
      "X509Certificate.endValidity is not supported on this platform."));
}


// Pushes data through the SSL filter, reading and writing from circular
// buffers shared with Dart. Called from the IOService thread.
//
// The Dart _SecureFilterImpl class contains 4 ExternalByteArrays used to
// pass encrypted and plaintext data to and from the C++ SSLFilter object.
//
// ProcessFilter is called with a CObject array containing the pointer to
// the SSLFilter, encoded as an int, and the start and end positions of the
// valid data in the four circular buffers.  The function only reads from
// the valid data area of the input buffers, and only writes to the free
// area of the output buffers.  The function returns the new start and end
// positions in the buffers, but it only updates start for input buffers, and
// end for output buffers.  Therefore, the Dart thread can simultaneously
// write to the free space and end pointer of input buffers, and read from
// the data space of output buffers, and modify the start pointer.
//
// When ProcessFilter returns, the Dart thread is responsible for combining
// the updated pointers from Dart and C++, to make the new valid state of
// the circular buffer.
CObject* SSLFilter::ProcessFilterRequest(const CObjectArray& request) {
  CObjectIntptr filter_object(request[0]);
  SSLFilter* filter = reinterpret_cast<SSLFilter*>(filter_object.Value());
  RefCntReleaseScope<SSLFilter> rs(filter);

  bool in_handshake = CObjectBool(request[1]).Value();
  intptr_t starts[SSLFilter::kNumBuffers];
  intptr_t ends[SSLFilter::kNumBuffers];
  for (intptr_t i = 0; i < SSLFilter::kNumBuffers; ++i) {
    starts[i] = CObjectInt32(request[2 * i + 2]).Value();
    ends[i] = CObjectInt32(request[2 * i + 3]).Value();
  }

  OSStatus status = filter->ProcessAllBuffers(starts, ends, in_handshake);
  if (status == noErr) {
    CObjectArray* result =
        new CObjectArray(CObject::NewArray(SSLFilter::kNumBuffers * 2));
    for (intptr_t i = 0; i < SSLFilter::kNumBuffers; ++i) {
      result->SetAt(2 * i, new CObjectInt32(CObject::NewInt32(starts[i])));
      result->SetAt(2 * i + 1, new CObjectInt32(CObject::NewInt32(ends[i])));
    }
    return result;
  } else {
    TextBuffer status_message(SSL_ERROR_MESSAGE_BUFFER_SIZE);
    status_message.Printf("OSStatus = %ld: https://www.osstatus.com",
                          static_cast<intptr_t>(status));
    CObjectArray* result = new CObjectArray(CObject::NewArray(2));
    result->SetAt(0, new CObjectInt32(CObject::NewInt32(status)));
    result->SetAt(1,
                  new CObjectString(CObject::NewString(status_message.buf())));
    return result;
  }
}


// Usually buffer_starts_ and buffer_ends_ are populated by ProcessAllBuffers,
// called from ProcessFilterRequest, called from the IOService thread.
// However, the first call to SSLHandshake comes from the Dart thread, and so
// doesn't go through there. This results in calls to SSLReadCallback and
// SSLWriteCallback in which buffer_starts_ and buffer_ends_ haven't been set
// up. In that case, since we're coming from Dart anyway, we can access the
// fieds directly from the Dart objects.
intptr_t SSLFilter::GetBufferStart(intptr_t idx) const {
  if (buffer_starts_[idx] != NULL) {
    return *buffer_starts_[idx];
  }
  Dart_Handle buffer_handle =
      ThrowIfError(Dart_HandleFromPersistent(dart_buffer_objects_[idx]));
  Dart_Handle start_handle =
      ThrowIfError(Dart_GetField(buffer_handle, DartUtils::NewString("start")));
  int64_t start = DartUtils::GetIntegerValue(start_handle);
  return static_cast<intptr_t>(start);
}


intptr_t SSLFilter::GetBufferEnd(intptr_t idx) const {
  if (buffer_ends_[idx] != NULL) {
    return *buffer_ends_[idx];
  }
  Dart_Handle buffer_handle =
      ThrowIfError(Dart_HandleFromPersistent(dart_buffer_objects_[idx]));
  Dart_Handle end_handle =
      ThrowIfError(Dart_GetField(buffer_handle, DartUtils::NewString("end")));
  int64_t end = DartUtils::GetIntegerValue(end_handle);
  return static_cast<intptr_t>(end);
}


void SSLFilter::SetBufferStart(intptr_t idx, intptr_t value) {
  if (buffer_starts_[idx] != NULL) {
    *buffer_starts_[idx] = value;
    return;
  }
  Dart_Handle buffer_handle =
      ThrowIfError(Dart_HandleFromPersistent(dart_buffer_objects_[idx]));
  ThrowIfError(DartUtils::SetIntegerField(buffer_handle, "start",
                                          static_cast<int64_t>(value)));
}


void SSLFilter::SetBufferEnd(intptr_t idx, intptr_t value) {
  if (buffer_ends_[idx] != NULL) {
    *buffer_ends_[idx] = value;
    return;
  }
  Dart_Handle buffer_handle =
      ThrowIfError(Dart_HandleFromPersistent(dart_buffer_objects_[idx]));
  ThrowIfError(DartUtils::SetIntegerField(buffer_handle, "end",
                                          static_cast<int64_t>(value)));
}


OSStatus SSLFilter::ProcessAllBuffers(intptr_t starts[kNumBuffers],
                                      intptr_t ends[kNumBuffers],
                                      bool in_handshake) {
  for (intptr_t i = 0; i < kNumBuffers; ++i) {
    buffer_starts_[i] = &starts[i];
    buffer_ends_[i] = &ends[i];
  }

  if (in_handshake) {
    OSStatus status = Handshake();
    if (status != noErr) {
      return status;
    }
  } else {
    for (intptr_t i = 0; i < kNumBuffers; ++i) {
      intptr_t start = starts[i];
      intptr_t end = ends[i];
      intptr_t size =
          isBufferEncrypted(i) ? encrypted_buffer_size_ : buffer_size_;
      if (start < 0 || end < 0 || start >= size || end >= size) {
        FATAL("Out-of-bounds internal buffer access in dart:io SecureSocket");
      }
      switch (i) {
        case kReadPlaintext:
          // Write data to the circular buffer's free space.  If the buffer
          // is full, neither if statement is executed and nothing happens.
          if (start <= end) {
            // If the free space may be split into two segments,
            // then the first is [end, size), unless start == 0.
            // Then, since the last free byte is at position start - 2,
            // the interval is [end, size - 1).
            intptr_t buffer_end = (start == 0) ? size - 1 : size;
            intptr_t bytes = 0;
            OSStatus status =
                ProcessReadPlaintextBuffer(end, buffer_end, &bytes);
            if ((status != noErr) && (status != errSSLWouldBlock)) {
              return status;
            }
            end += bytes;
            ASSERT(end <= size);
            if (end == size) {
              end = 0;
            }
          }
          if (start > end + 1) {
            intptr_t bytes = 0;
            OSStatus status =
                ProcessReadPlaintextBuffer(end, start - 1, &bytes);
            if ((status != noErr) && (status != errSSLWouldBlock)) {
              return status;
            }
            end += bytes;
            ASSERT(end < start);
          }
          ends[i] = end;
          break;
        case kWritePlaintext:
          // Read/Write data from circular buffer.  If the buffer is empty,
          // neither if statement's condition is true.
          if (end < start) {
            // Data may be split into two segments.  In this case,
            // the first is [start, size).
            intptr_t bytes = 0;
            OSStatus status = ProcessWritePlaintextBuffer(start, size, &bytes);
            if ((status != noErr) && (status != errSSLWouldBlock)) {
              return status;
            }
            start += bytes;
            ASSERT(start <= size);
            if (start == size) {
              start = 0;
            }
          }
          if (start < end) {
            intptr_t bytes = 0;
            OSStatus status = ProcessWritePlaintextBuffer(start, end, &bytes);
            if ((status != noErr) && (status != errSSLWouldBlock)) {
              return status;
            }
            start += bytes;
            ASSERT(start <= end);
          }
          starts[i] = start;
          break;
        case kReadEncrypted:
        case kWriteEncrypted:
          // These buffers are advanced through SSLReadCallback and
          // SSLWriteCallback, which are called from SSLRead, SSLWrite, and
          // SSLHandshake.
          break;
        default:
          UNREACHABLE();
      }
    }
  }

  for (intptr_t i = 0; i < kNumBuffers; ++i) {
    buffer_starts_[i] = NULL;
    buffer_ends_[i] = NULL;
  }
  return noErr;
}


Dart_Handle SSLFilter::Init(Dart_Handle dart_this) {
  ASSERT(string_start_ == NULL);
  string_start_ = Dart_NewPersistentHandle(DartUtils::NewString("start"));
  ASSERT(string_start_ != NULL);
  ASSERT(string_length_ == NULL);
  string_length_ = Dart_NewPersistentHandle(DartUtils::NewString("length"));
  ASSERT(string_length_ != NULL);
  ASSERT(bad_certificate_callback_ == NULL);
  bad_certificate_callback_ = Dart_NewPersistentHandle(Dart_Null());
  ASSERT(bad_certificate_callback_ != NULL);

  // Caller handles cleanup on an error.
  return InitializeBuffers(dart_this);
}


Dart_Handle SSLFilter::InitializeBuffers(Dart_Handle dart_this) {
  // Create SSLFilter buffers as ExternalUint8Array objects.
  Dart_Handle buffers_string = DartUtils::NewString("buffers");
  RETURN_IF_ERROR(buffers_string);
  Dart_Handle dart_buffers_object = Dart_GetField(dart_this, buffers_string);
  RETURN_IF_ERROR(dart_buffers_object);
  Dart_Handle secure_filter_impl_type = Dart_InstanceGetType(dart_this);
  RETURN_IF_ERROR(secure_filter_impl_type);
  Dart_Handle size_string = DartUtils::NewString("SIZE");
  RETURN_IF_ERROR(size_string);
  Dart_Handle dart_buffer_size =
      Dart_GetField(secure_filter_impl_type, size_string);
  RETURN_IF_ERROR(dart_buffer_size);

  int64_t buffer_size = 0;
  Dart_Handle err = Dart_IntegerToInt64(dart_buffer_size, &buffer_size);
  RETURN_IF_ERROR(err);

  Dart_Handle encrypted_size_string = DartUtils::NewString("ENCRYPTED_SIZE");
  RETURN_IF_ERROR(encrypted_size_string);

  Dart_Handle dart_encrypted_buffer_size =
      Dart_GetField(secure_filter_impl_type, encrypted_size_string);
  RETURN_IF_ERROR(dart_encrypted_buffer_size);

  int64_t encrypted_buffer_size = 0;
  err = Dart_IntegerToInt64(dart_encrypted_buffer_size, &encrypted_buffer_size);
  RETURN_IF_ERROR(err);

  if (buffer_size <= 0 || buffer_size > 1 * MB) {
    FATAL("Invalid buffer size in _ExternalBuffer");
  }
  if (encrypted_buffer_size <= 0 || encrypted_buffer_size > 1 * MB) {
    FATAL("Invalid encrypted buffer size in _ExternalBuffer");
  }
  buffer_size_ = static_cast<intptr_t>(buffer_size);
  encrypted_buffer_size_ = static_cast<intptr_t>(encrypted_buffer_size);

  Dart_Handle data_identifier = DartUtils::NewString("data");
  RETURN_IF_ERROR(data_identifier);

  for (int i = 0; i < kNumBuffers; i++) {
    int size = isBufferEncrypted(i) ? encrypted_buffer_size_ : buffer_size_;
    buffers_[i] = new uint8_t[size];
    ASSERT(buffers_[i] != NULL);
    buffer_starts_[i] = NULL;
    buffer_ends_[i] = NULL;
    dart_buffer_objects_[i] = NULL;
  }

  Dart_Handle result = Dart_Null();
  for (int i = 0; i < kNumBuffers; ++i) {
    int size = isBufferEncrypted(i) ? encrypted_buffer_size_ : buffer_size_;
    result = Dart_ListGetAt(dart_buffers_object, i);
    if (Dart_IsError(result)) {
      break;
    }

    dart_buffer_objects_[i] = Dart_NewPersistentHandle(result);
    ASSERT(dart_buffer_objects_[i] != NULL);
    Dart_Handle data =
        Dart_NewExternalTypedData(Dart_TypedData_kUint8, buffers_[i], size);
    if (Dart_IsError(data)) {
      result = data;
      break;
    }
    result = Dart_HandleFromPersistent(dart_buffer_objects_[i]);
    if (Dart_IsError(result)) {
      break;
    }
    result = Dart_SetField(result, data_identifier, data);
    if (Dart_IsError(result)) {
      break;
    }
  }

  // Caller handles cleanup on an error.
  return result;
}


void SSLFilter::RegisterHandshakeCompleteCallback(Dart_Handle complete) {
  ASSERT(NULL == handshake_complete_);
  handshake_complete_ = Dart_NewPersistentHandle(complete);
  ASSERT(handshake_complete_ != NULL);
}


void SSLFilter::RegisterBadCertificateCallback(Dart_Handle callback) {
  ASSERT(bad_certificate_callback_ != NULL);
  Dart_DeletePersistentHandle(bad_certificate_callback_);
  bad_certificate_callback_ = Dart_NewPersistentHandle(callback);
  ASSERT(bad_certificate_callback_ != NULL);
}


Dart_Handle SSLFilter::PeerCertificate() {
  if (peer_certs_ == NULL) {
    return Dart_Null();
  }

  CFTypeRef item = CFArrayGetValueAtIndex(peer_certs_, 0);
  ASSERT(CFGetTypeID(item) == SecCertificateGetTypeID());
  SecCertificateRef cert =
      reinterpret_cast<SecCertificateRef>(const_cast<void*>(item));
  if (cert == NULL) {
    return Dart_Null();
  }

  return WrappedX509Certificate(cert);
}


void SSLFilter::Connect(Dart_Handle dart_this,
                        const char* hostname,
                        SSLCertContext* context,
                        bool is_server,
                        bool request_client_certificate,
                        bool require_client_certificate) {
  if (in_handshake_) {
    FATAL("Connect called twice on the same _SecureFilter.");
  }

  // Create the underlying context
  SSLContextRef ssl_context = SSLCreateContext(
      NULL, is_server ? kSSLServerSide : kSSLClientSide, kSSLStreamType);

  // Configure the context.
  OSStatus status;
  status = SSLSetPeerDomainName(ssl_context, hostname, strlen(hostname));
  CheckStatus(status, "TlsException", "Failed to set peer domain name");

  status = SSLSetIOFuncs(ssl_context, SSLFilter::SSLReadCallback,
                         SSLFilter::SSLWriteCallback);
  CheckStatus(status, "TlsException", "Failed to set IO Callbacks");

  status =
      SSLSetConnection(ssl_context, reinterpret_cast<SSLConnectionRef>(this));
  CheckStatus(status, "TlsException", "Failed to set connection object");

  // Always evaluate the certs manually so that we can cache the peer
  // certificates in the context for calls to peerCertificate.
  status = SSLSetSessionOption(ssl_context, kSSLSessionOptionBreakOnServerAuth,
                               true);
  CheckStatus(status, "TlsException", "Failed to set BreakOnServerAuth option");

  status = SSLSetProtocolVersionMin(ssl_context, kTLSProtocol1);
  CheckStatus(status, "TlsException",
              "Failed to set minimum protocol version to kTLSProtocol1");

  // If the context has an identity pass it to SSLSetCertificate().
  if (context->identity() != NULL) {
    CFMutableArrayRef chain =
        CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    CFArrayAppendValue(chain, context->identity());

    // Append the certificate chain if there is one.
    if (context->cert_chain() != NULL) {
      // Skip the first one, it's already included in the identity.
      CFIndex chain_length = CFArrayGetCount(context->cert_chain());
      if (chain_length > 1) {
        CFArrayAppendArray(chain, context->cert_chain(),
                           CFRangeMake(1, chain_length));
      }
    }

    status = SSLSetCertificate(ssl_context, chain);
    CFRelease(chain);
    CheckStatus(status, "TlsException", "SSLSetCertificate failed");
  }

  if (is_server) {
    SSLAuthenticate auth =
        require_client_certificate
            ? kAlwaysAuthenticate
            : (request_client_certificate ? kTryAuthenticate
                                          : kNeverAuthenticate);
    status = SSLSetClientSideAuthenticate(ssl_context, auth);
    CheckStatus(status, "TlsException",
                "Failed to set client authentication mode");

    // If we're at least trying client authentication, then break handshake
    // for client authentication.
    if (auth != kNeverAuthenticate) {
      status = SSLSetSessionOption(ssl_context,
                                   kSSLSessionOptionBreakOnClientAuth, true);
      CheckStatus(status, "TlsException",
                  "Failed to set client authentication mode");
    }
  }

  // Add the contexts to our wrapper.
  cert_context_.set(context);
  ssl_context_ = ssl_context;
  is_server_ = is_server;

  // Kick-off the handshake. Expect the handshake to need more data.
  // SSLHandshake calls our SSLReadCallback and SSLWriteCallback.
  status = SSLHandshake(ssl_context);
  ASSERT(status != noErr);
  if (status == errSSLWouldBlock) {
    status = noErr;
    in_handshake_ = true;
  }
  CheckStatus(status, "HandshakeException", is_server_
                                                ? "Handshake error in server"
                                                : "Handshake error in client");
}


OSStatus SSLFilter::EvaluatePeerTrust() {
  OSStatus status = noErr;

  if (SSL_LOG_STATUS) {
    Log::PrintErr("Handshake evaluating trust.\n");
  }
  SecTrustRef peer_trust = NULL;
  status = SSLCopyPeerTrust(ssl_context_, &peer_trust);
  if (status != noErr) {
    if (is_server_ && (status == errSSLBadCert)) {
      // A client certificate was requested, but not required, and wasn't sent.
      return noErr;
    }
    if (SSL_LOG_STATUS) {
      Log::PrintErr("Handshake error from SSLCopyPeerTrust(): %ld.\n",
                    static_cast<intptr_t>(status));
    }
    return status;
  }

  CFArrayRef trusted_certs = NULL;
  if (cert_context_.get()->trusted_certs() != NULL) {
    trusted_certs =
        CFArrayCreateCopy(NULL, cert_context_.get()->trusted_certs());
  } else {
    trusted_certs = CFArrayCreate(NULL, NULL, 0, &kCFTypeArrayCallBacks);
  }

  status = SecTrustSetAnchorCertificates(peer_trust, trusted_certs);
  if (status != noErr) {
    if (SSL_LOG_STATUS) {
      Log::PrintErr("Handshake error from SecTrustSetAnchorCertificates: %ld\n",
                    static_cast<intptr_t>(status));
    }
    CFRelease(trusted_certs);
    CFRelease(peer_trust);
    return status;
  }

  if (SSL_LOG_STATUS) {
    Log::PrintErr(
        "Handshake %s built in root certs\n",
        cert_context_.get()->trust_builtin() ? "trusting" : "not trusting");
  }

  status = SecTrustSetAnchorCertificatesOnly(
      peer_trust, !cert_context_.get()->trust_builtin());
  if (status != noErr) {
    CFRelease(trusted_certs);
    CFRelease(peer_trust);
    return status;
  }

  SecTrustResultType trust_result;
  status = SecTrustEvaluate(peer_trust, &trust_result);
  if (status != noErr) {
    CFRelease(trusted_certs);
    CFRelease(peer_trust);
    return status;
  }

  // Grab the peer's certificate chain.
  CFIndex peer_chain_length = SecTrustGetCertificateCount(peer_trust);
  CFMutableArrayRef peer_certs =
      CFArrayCreateMutable(NULL, peer_chain_length, &kCFTypeArrayCallBacks);
  for (CFIndex i = 0; i < peer_chain_length; ++i) {
    CFArrayAppendValue(peer_certs,
                       SecTrustGetCertificateAtIndex(peer_trust, i));
  }
  peer_certs_ = peer_certs;

  CFRelease(trusted_certs);
  CFRelease(peer_trust);

  if ((trust_result == kSecTrustResultProceed) ||
      (trust_result == kSecTrustResultUnspecified)) {
    // Trusted.
    return noErr;
  } else {
    if (SSL_LOG_STATUS) {
      Log::PrintErr("Trust eval failed: trust_result = %d\n", trust_result);
    }
    bad_cert_ = true;
    return errSSLBadCert;
  }
}


OSStatus SSLFilter::Handshake() {
  ASSERT(cert_context_.get() != NULL);
  ASSERT(ssl_context_ != NULL);
  // Try and push handshake along.
  if (SSL_LOG_STATUS) {
    Log::PrintErr("Doing SSLHandshake\n");
  }
  OSStatus status = SSLHandshake(ssl_context_);
  if (SSL_LOG_STATUS) {
    Log::PrintErr("SSLHandshake returned %ld\n", static_cast<intptr_t>(status));
  }

  if ((status == errSSLServerAuthCompleted) ||
      (status == errSSLClientAuthCompleted)) {
    status = EvaluatePeerTrust();
    if (status == errSSLBadCert) {
      // Need to invoke the bad certificate callback.
      return noErr;
    } else if (status != noErr) {
      return status;
    }
    // When trust evaluation succeeds, we can call SSLHandshake again
    // immediately.
    status = SSLHandshake(ssl_context_);
  }

  if (status == errSSLWouldBlock) {
    in_handshake_ = true;
    return noErr;
  }

  // Handshake succeeded.
  if ((in_handshake_) && (status == noErr)) {
    if (SSL_LOG_STATUS) {
      Log::PrintErr("Finished with the Handshake\n");
    }
    connected_ = true;
  }
  return status;
}


// Returns false if Handshake should fail, and true if Handshake should
// proceed.
Dart_Handle SSLFilter::InvokeBadCertCallback(SecCertificateRef peer_cert) {
  Dart_Handle callback = bad_certificate_callback_;
  if (Dart_IsNull(callback)) {
    return callback;
  }
  Dart_Handle args[1];
  args[0] = WrappedX509Certificate(peer_cert);
  if (Dart_IsError(args[0])) {
    return args[0];
  }
  Dart_Handle result = Dart_InvokeClosure(callback, 1, args);
  if (!Dart_IsError(result) && !Dart_IsBoolean(result)) {
    result = Dart_NewUnhandledExceptionError(DartUtils::NewDartIOException(
        "HandshakeException",
        "BadCertificateCallback returned a value that was not a boolean",
        Dart_Null()));
  }
  return result;
}


OSStatus SSLFilter::CheckHandshake() {
  if (bad_cert_ && in_handshake_) {
    if (SSL_LOG_STATUS) {
      Log::PrintErr("Invoking bad certificate callback\n");
    }
    ASSERT(peer_certs_ != NULL);
    CFIndex peer_certs_len = CFArrayGetCount(peer_certs_);
    ASSERT(peer_certs_len > 0);
    CFTypeRef item = CFArrayGetValueAtIndex(peer_certs_, peer_certs_len - 1);
    ASSERT(item != NULL);
    ASSERT(CFGetTypeID(item) == SecCertificateGetTypeID());
    SecCertificateRef peer_cert =
        reinterpret_cast<SecCertificateRef>(const_cast<void*>(item));
    Dart_Handle result = InvokeBadCertCallback(peer_cert);
    ThrowIfError(result);
    if (Dart_IsNull(result)) {
      return errSSLBadCert;
    } else {
      bool good_cert = DartUtils::GetBooleanValue(result);
      bad_cert_ = !good_cert;
      return good_cert ? noErr : errSSLBadCert;
    }
  }

  if (connected_ && in_handshake_) {
    if (SSL_LOG_STATUS) {
      Log::PrintErr("Invoking handshake complete callback\n");
    }
    ThrowIfError(Dart_InvokeClosure(
        Dart_HandleFromPersistent(handshake_complete_), 0, NULL));
    in_handshake_ = false;
  }
  return noErr;
}


void SSLFilter::Renegotiate(bool use_session_cache,
                            bool request_client_certificate,
                            bool require_client_certificate) {
  // The SSL_REQUIRE_CERTIFICATE option only takes effect if the
  // SSL_REQUEST_CERTIFICATE option is also set, so set it.
  request_client_certificate =
      request_client_certificate || require_client_certificate;
  // TODO(24070, 24069): Implement setting the client certificate parameters,
  //   and triggering rehandshake.
}


SSLFilter::~SSLFilter() {
  if (ssl_context_ != NULL) {
    CFRelease(ssl_context_);
    ssl_context_ = NULL;
  }
  if (peer_certs_ != NULL) {
    CFRelease(peer_certs_);
    peer_certs_ = NULL;
  }
  if (hostname_ != NULL) {
    free(hostname_);
    hostname_ = NULL;
  }
  for (int i = 0; i < kNumBuffers; ++i) {
    if (buffers_[i] != NULL) {
      delete[] buffers_[i];
      buffers_[i] = NULL;
    }
  }
}


void SSLFilter::Destroy() {
  if (ssl_context_ != NULL) {
    SSLClose(ssl_context_);
  }
  for (int i = 0; i < kNumBuffers; ++i) {
    if (dart_buffer_objects_[i] != NULL) {
      Dart_DeletePersistentHandle(dart_buffer_objects_[i]);
      dart_buffer_objects_[i] = NULL;
    }
  }
  if (string_start_ != NULL) {
    Dart_DeletePersistentHandle(string_start_);
    string_start_ = NULL;
  }
  if (string_length_ != NULL) {
    Dart_DeletePersistentHandle(string_length_);
    string_length_ = NULL;
  }
  if (handshake_complete_ != NULL) {
    Dart_DeletePersistentHandle(handshake_complete_);
    handshake_complete_ = NULL;
  }
  if (bad_certificate_callback_ != NULL) {
    Dart_DeletePersistentHandle(bad_certificate_callback_);
    bad_certificate_callback_ = NULL;
  }
}


OSStatus SSLFilter::SSLReadCallback(SSLConnectionRef connection,
                                    void* data,
                                    size_t* data_requested) {
  // Copy at most `data_requested` bytes from `buffers_[kReadEncrypted]` into
  // `data`
  ASSERT(connection != NULL);
  ASSERT(data != NULL);
  ASSERT(data_requested != NULL);

  SSLFilter* filter =
      const_cast<SSLFilter*>(reinterpret_cast<const SSLFilter*>(connection));
  uint8_t* datap = reinterpret_cast<uint8_t*>(data);
  uint8_t* buffer = filter->buffers_[kReadEncrypted];
  intptr_t start = filter->GetBufferStart(kReadEncrypted);
  intptr_t end = filter->GetBufferEnd(kReadEncrypted);
  intptr_t size = filter->encrypted_buffer_size_;
  intptr_t requested = static_cast<intptr_t>(*data_requested);
  intptr_t data_read = 0;

  if (end < start) {
    // Data may be split into two segments.  In this case,
    // the first is [start, size).
    intptr_t buffer_end = (start == 0) ? size - 1 : size;
    intptr_t available = buffer_end - start;
    intptr_t bytes = requested < available ? requested : available;
    memmove(datap, &buffer[start], bytes);
    start += bytes;
    datap += bytes;
    data_read += bytes;
    requested -= bytes;
    ASSERT(start <= size);
    if (start == size) {
      start = 0;
    }
  }
  if ((requested > 0) && (start < end)) {
    intptr_t available = end - start;
    intptr_t bytes = requested < available ? requested : available;
    memmove(datap, &buffer[start], bytes);
    start += bytes;
    datap += bytes;
    data_read += bytes;
    requested -= bytes;
    ASSERT(start <= end);
  }

  if (SSL_LOG_DATA) {
    Log::PrintErr("SSLReadCallback: requested: %ld, read %ld bytes\n",
                  *data_requested, data_read);
  }

  filter->SetBufferStart(kReadEncrypted, start);
  bool short_read = data_read < static_cast<intptr_t>(*data_requested);
  *data_requested = data_read;
  return short_read ? errSSLWouldBlock : noErr;
}


// Read decrypted data from the filter to the circular buffer.
OSStatus SSLFilter::ProcessReadPlaintextBuffer(intptr_t start,
                                               intptr_t end,
                                               intptr_t* bytes_processed) {
  ASSERT(bytes_processed != NULL);
  intptr_t length = end - start;
  OSStatus status = noErr;
  size_t bytes = 0;
  if (length > 0) {
    status =
        SSLRead(ssl_context_,
                reinterpret_cast<void*>((buffers_[kReadPlaintext] + start)),
                length, &bytes);
    if (SSL_LOG_STATUS) {
      Log::PrintErr("SSLRead: status = %ld\n", static_cast<intptr_t>(status));
    }
    if ((status != noErr) && (status != errSSLWouldBlock)) {
      *bytes_processed = 0;
      return status;
    }
  }
  if (SSL_LOG_DATA) {
    Log::PrintErr(
        "ProcessReadPlaintextBuffer: requested: %ld, read %ld bytes\n", length,
        bytes);
  }
  *bytes_processed = static_cast<intptr_t>(bytes);
  return status;
}


OSStatus SSLFilter::SSLWriteCallback(SSLConnectionRef connection,
                                     const void* data,
                                     size_t* data_provided) {
  // Copy at most `data_provided` bytes from data into
  // `buffers_[kWriteEncrypted]`.
  ASSERT(connection != NULL);
  ASSERT(data != NULL);
  ASSERT(data_provided != NULL);

  SSLFilter* filter =
      const_cast<SSLFilter*>(reinterpret_cast<const SSLFilter*>(connection));
  const uint8_t* datap = reinterpret_cast<const uint8_t*>(data);
  uint8_t* buffer = filter->buffers_[kWriteEncrypted];
  intptr_t start = filter->GetBufferStart(kWriteEncrypted);
  intptr_t end = filter->GetBufferEnd(kWriteEncrypted);
  intptr_t size = filter->encrypted_buffer_size_;
  intptr_t provided = static_cast<intptr_t>(*data_provided);
  intptr_t data_written = 0;

  // is full, neither if statement is executed and nothing happens.
  if (start <= end) {
    // If the free space may be split into two segments,
    // then the first is [end, size), unless start == 0.
    // Then, since the last free byte is at position start - 2,
    // the interval is [end, size - 1).
    intptr_t buffer_end = (start == 0) ? size - 1 : size;
    intptr_t available = buffer_end - end;
    intptr_t bytes = provided < available ? provided : available;
    memmove(&buffer[end], datap, bytes);
    end += bytes;
    datap += bytes;
    data_written += bytes;
    provided -= bytes;
    ASSERT(end <= size);
    if (end == size) {
      end = 0;
    }
  }
  if ((provided > 0) && (start > end + 1)) {
    intptr_t available = (start - 1) - end;
    intptr_t bytes = provided < available ? provided : available;
    memmove(&buffer[end], datap, bytes);
    end += bytes;
    datap += bytes;
    data_written += bytes;
    provided -= bytes;
    ASSERT(end < start);
  }

  if (SSL_LOG_DATA) {
    Log::PrintErr("SSLWriteCallback: provided: %ld, written %ld bytes\n",
                  *data_provided, data_written);
  }

  filter->SetBufferEnd(kWriteEncrypted, end);
  *data_provided = data_written;
  return (data_written == 0) ? errSSLWouldBlock : noErr;
}


OSStatus SSLFilter::ProcessWritePlaintextBuffer(intptr_t start,
                                                intptr_t end,
                                                intptr_t* bytes_processed) {
  ASSERT(bytes_processed != NULL);
  intptr_t length = end - start;
  OSStatus status = noErr;
  size_t bytes = 0;
  if (length > 0) {
    status =
        SSLWrite(ssl_context_,
                 reinterpret_cast<void*>(buffers_[kWritePlaintext] + start),
                 length, &bytes);
    if (SSL_LOG_STATUS) {
      Log::PrintErr("SSLWrite: status = %ld\n", static_cast<intptr_t>(status));
    }
    if ((status != noErr) && (status != errSSLWouldBlock)) {
      *bytes_processed = 0;
      return status;
    }
  }
  if (SSL_LOG_DATA) {
    Log::PrintErr("ProcessWritePlaintextBuffer: requested: %ld, written: %ld\n",
                  length, bytes);
  }
  *bytes_processed = static_cast<intptr_t>(bytes);
  return status;
}

}  // namespace bin
}  // namespace dart

#endif  // TARGET_OS_IOS

#endif  // !defined(DART_IO_SECURE_SOCKET_DISABLED)
