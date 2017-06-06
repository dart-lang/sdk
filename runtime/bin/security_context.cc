// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED) && !defined(DART_IO_SECURE_SOCKET_DISABLED)

#include "bin/security_context.h"

#include <openssl/bio.h>
#include <openssl/err.h>
#include <openssl/pkcs12.h>
#include <openssl/ssl.h>
#include <openssl/x509.h>

#include "platform/globals.h"

#include "bin/directory.h"
#include "bin/file.h"
#include "bin/log.h"
#include "bin/secure_socket_filter.h"
#include "bin/secure_socket_utils.h"

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

int SSLCertContext::CertificateCallback(int preverify_ok,
                                        X509_STORE_CTX* store_ctx) {
  if (preverify_ok == 1) {
    return 1;
  }
  Dart_Isolate isolate = Dart_CurrentIsolate();
  if (isolate == NULL) {
    FATAL("CertificateCallback called with no current isolate\n");
  }
  X509* certificate = X509_STORE_CTX_get_current_cert(store_ctx);
  int ssl_index = SSL_get_ex_data_X509_STORE_CTX_idx();
  SSL* ssl =
      static_cast<SSL*>(X509_STORE_CTX_get_ex_data(store_ctx, ssl_index));
  SSLFilter* filter = static_cast<SSLFilter*>(
      SSL_get_ex_data(ssl, SSLFilter::filter_ssl_index));
  Dart_Handle callback = filter->bad_certificate_callback();
  if (Dart_IsNull(callback)) {
    return 0;
  }

  // Upref since the Dart X509 object may outlive the SecurityContext.
  if (certificate != NULL) {
    X509_up_ref(certificate);
  }
  Dart_Handle args[1];
  args[0] = X509Helper::WrappedX509Certificate(certificate);
  if (Dart_IsError(args[0])) {
    filter->callback_error = args[0];
    return 0;
  }
  Dart_Handle result = Dart_InvokeClosure(callback, 1, args);
  if (!Dart_IsError(result) && !Dart_IsBoolean(result)) {
    result = Dart_NewUnhandledExceptionError(DartUtils::NewDartIOException(
        "HandshakeException",
        "BadCertificateCallback returned a value that was not a boolean",
        Dart_Null()));
  }
  if (Dart_IsError(result)) {
    filter->callback_error = result;
    return 0;
  }
  return DartUtils::GetBooleanValue(result);
}


SSLCertContext* SSLCertContext::GetSecurityContext(Dart_NativeArguments args) {
  SSLCertContext* context;
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  ASSERT(Dart_IsInstance(dart_this));
  ThrowIfError(Dart_GetNativeInstanceField(
      dart_this, SSLCertContext::kSecurityContextNativeFieldIndex,
      reinterpret_cast<intptr_t*>(&context)));
  return context;
}


static void DeleteSecurityContext(void* isolate_data,
                                  Dart_WeakPersistentHandle handle,
                                  void* context_pointer) {
  SSLCertContext* context = static_cast<SSLCertContext*>(context_pointer);
  context->Release();
}


static Dart_Handle SetSecurityContext(Dart_NativeArguments args,
                                      SSLCertContext* context) {
  Dart_Handle dart_this = Dart_GetNativeArgument(args, 0);
  RETURN_IF_ERROR(dart_this);
  ASSERT(Dart_IsInstance(dart_this));
  Dart_Handle err = Dart_SetNativeInstanceField(
      dart_this, SSLCertContext::kSecurityContextNativeFieldIndex,
      reinterpret_cast<intptr_t>(context));
  RETURN_IF_ERROR(err);
  Dart_NewWeakPersistentHandle(dart_this, context,
                               SSLCertContext::kApproximateSize,
                               DeleteSecurityContext);
  return Dart_Null();
}


static void ReleaseCertificate(void* isolate_data,
                               Dart_WeakPersistentHandle handle,
                               void* context_pointer) {
  X509* cert = reinterpret_cast<X509*>(context_pointer);
  X509_free(cert);
}


static intptr_t EstimateX509Size(X509* certificate) {
  intptr_t length = i2d_X509(certificate, NULL);
  return length > 0 ? length : 0;
}


// Returns the handle for a Dart object wrapping the X509 certificate object.
// The caller should own a reference to the X509 object whose reference count
// won't drop to zero before the ReleaseCertificate finalizer runs.
Dart_Handle X509Helper::WrappedX509Certificate(X509* certificate) {
  if (certificate == NULL) {
    return Dart_Null();
  }
  Dart_Handle x509_type =
      DartUtils::GetDartType(DartUtils::kIOLibURL, "X509Certificate");
  if (Dart_IsError(x509_type)) {
    X509_free(certificate);
    return x509_type;
  }
  Dart_Handle arguments[] = {NULL};
  Dart_Handle result =
      Dart_New(x509_type, DartUtils::NewString("_"), 0, arguments);
  if (Dart_IsError(result)) {
    X509_free(certificate);
    return result;
  }
  ASSERT(Dart_IsInstance(result));
  Dart_Handle status =
      Dart_SetNativeInstanceField(result, SSLCertContext::kX509NativeFieldIndex,
                                  reinterpret_cast<intptr_t>(certificate));
  if (Dart_IsError(status)) {
    X509_free(certificate);
    return status;
  }
  const intptr_t approximate_size_of_certificate =
      sizeof(*certificate) + EstimateX509Size(certificate);
  ASSERT(approximate_size_of_certificate > 0);
  Dart_NewWeakPersistentHandle(result, reinterpret_cast<void*>(certificate),
                               approximate_size_of_certificate,
                               ReleaseCertificate);
  return result;
}


static int SetTrustedCertificatesBytesPKCS12(SSL_CTX* context,
                                             BIO* bio,
                                             const char* password) {
  ScopedPKCS12 p12(d2i_PKCS12_bio(bio, NULL));
  if (p12.get() == NULL) {
    return 0;
  }

  EVP_PKEY* key = NULL;
  X509* cert = NULL;
  STACK_OF(X509)* ca_certs = NULL;
  int status = PKCS12_parse(p12.get(), password, &key, &cert, &ca_certs);
  if (status == 0) {
    return status;
  }

  ScopedX509Stack cert_stack(ca_certs);
  X509_STORE* store = SSL_CTX_get_cert_store(context);
  status = X509_STORE_add_cert(store, cert);
  // X509_STORE_add_cert increments the reference count of cert on success.
  X509_free(cert);
  if (status == 0) {
    return status;
  }

  X509* ca;
  while ((ca = sk_X509_shift(cert_stack.get())) != NULL) {
    status = X509_STORE_add_cert(store, ca);
    // X509_STORE_add_cert increments the reference count of cert on success.
    X509_free(ca);
    if (status == 0) {
      return status;
    }
  }

  return status;
}


static int SetTrustedCertificatesBytesPEM(SSL_CTX* context, BIO* bio) {
  X509_STORE* store = SSL_CTX_get_cert_store(context);

  int status = 0;
  X509* cert = NULL;
  while ((cert = PEM_read_bio_X509(bio, NULL, NULL, NULL)) != NULL) {
    status = X509_STORE_add_cert(store, cert);
    // X509_STORE_add_cert increments the reference count of cert on success.
    X509_free(cert);
    if (status == 0) {
      return status;
    }
  }

  // If no PEM start line is found, it means that we read to the end of the
  // file, or that the file isn't PEM. In the first case, status will be
  // non-zero indicating success. In the second case, status will be 0,
  // indicating that we should try to read as PKCS12. If there is some other
  // error, we return it up to the caller.
  return SecureSocketUtils::NoPEMStartLine() ? status : 0;
}


void SSLCertContext::SetTrustedCertificatesBytes(Dart_Handle cert_bytes,
                                                 const char* password) {
  ScopedMemBIO bio(cert_bytes);
  int status = SetTrustedCertificatesBytesPEM(context(), bio.bio());
  if (status == 0) {
    if (SecureSocketUtils::NoPEMStartLine()) {
      ERR_clear_error();
      BIO_reset(bio.bio());
      status =
          SetTrustedCertificatesBytesPKCS12(context(), bio.bio(), password);
    }
  } else {
    // The PEM file was successfully parsed.
    ERR_clear_error();
  }

  SecureSocketUtils::CheckStatus(status, "TlsException",
                                 "Failure trusting builtin roots");
}


static int SetClientAuthoritiesPKCS12(SSL_CTX* context,
                                      BIO* bio,
                                      const char* password) {
  ScopedPKCS12 p12(d2i_PKCS12_bio(bio, NULL));
  if (p12.get() == NULL) {
    return 0;
  }

  EVP_PKEY* key = NULL;
  X509* cert = NULL;
  STACK_OF(X509)* ca_certs = NULL;
  int status = PKCS12_parse(p12.get(), password, &key, &cert, &ca_certs);
  if (status == 0) {
    return status;
  }

  ScopedX509Stack cert_stack(ca_certs);
  status = SSL_CTX_add_client_CA(context, cert);
  // SSL_CTX_add_client_CA increments the reference count of cert on success.
  X509_free(cert);
  if (status == 0) {
    return status;
  }

  X509* ca;
  while ((ca = sk_X509_shift(cert_stack.get())) != NULL) {
    status = SSL_CTX_add_client_CA(context, ca);
    // SSL_CTX_add_client_CA increments the reference count of ca on success.
    X509_free(ca);  // The name has been extracted.
    if (status == 0) {
      return status;
    }
  }

  return status;
}


static int SetClientAuthoritiesPEM(SSL_CTX* context, BIO* bio) {
  int status = 0;
  X509* cert = NULL;
  while ((cert = PEM_read_bio_X509(bio, NULL, NULL, NULL)) != NULL) {
    status = SSL_CTX_add_client_CA(context, cert);
    X509_free(cert);  // The name has been extracted.
    if (status == 0) {
      return status;
    }
  }
  return SecureSocketUtils::NoPEMStartLine() ? status : 0;
}


static int SetClientAuthorities(SSL_CTX* context,
                                BIO* bio,
                                const char* password) {
  int status = SetClientAuthoritiesPEM(context, bio);
  if (status == 0) {
    if (SecureSocketUtils::NoPEMStartLine()) {
      ERR_clear_error();
      BIO_reset(bio);
      status = SetClientAuthoritiesPKCS12(context, bio, password);
    }
  } else {
    // The PEM file was successfully parsed.
    ERR_clear_error();
  }
  return status;
}


void SSLCertContext::SetClientAuthoritiesBytes(
    Dart_Handle client_authorities_bytes,
    const char* password) {
  int status;
  {
    ScopedMemBIO bio(client_authorities_bytes);
    status = SetClientAuthorities(context(), bio.bio(), password);
  }

  SecureSocketUtils::CheckStatus(status, "TlsException",
                                 "Failure in setClientAuthoritiesBytes");
}

void SSLCertContext::LoadRootCertFile(const char* file) {
  if (SSL_LOG_STATUS) {
    Log::Print("Looking for trusted roots in %s\n", file);
  }
  if (!File::Exists(file)) {
    SecureSocketUtils::ThrowIOException(-1, "TlsException",
                                        "Failed to find root cert file", NULL);
  }
  int status = SSL_CTX_load_verify_locations(context(), file, NULL);
  SecureSocketUtils::CheckStatus(status, "TlsException",
                                 "Failure trusting builtin roots");
  if (SSL_LOG_STATUS) {
    Log::Print("Trusting roots from: %s\n", file);
  }
}


void SSLCertContext::AddCompiledInCerts() {
  if (root_certificates_pem == NULL) {
    if (SSL_LOG_STATUS) {
      Log::Print("Missing compiled-in roots\n");
    }
    return;
  }
  X509_STORE* store = SSL_CTX_get_cert_store(context());
  BIO* roots_bio =
      BIO_new_mem_buf(const_cast<unsigned char*>(root_certificates_pem),
                      root_certificates_pem_length);
  X509* root_cert;
  // PEM_read_bio_X509 reads PEM-encoded certificates from a bio (in our case,
  // backed by a memory buffer), and returns X509 objects, one by one.
  // When the end of the bio is reached, it returns null.
  while ((root_cert = PEM_read_bio_X509(roots_bio, NULL, NULL, NULL)) != NULL) {
    int status = X509_STORE_add_cert(store, root_cert);
    // X509_STORE_add_cert increments the reference count of cert on success.
    X509_free(root_cert);
    if (status == 0) {
      break;
    }
  }
  BIO_free(roots_bio);
  // If there is an error here, it must be the error indicating that we are done
  // reading PEM certificates.
  ASSERT((ERR_peek_error() == 0) || SecureSocketUtils::NoPEMStartLine());
  ERR_clear_error();
}


void SSLCertContext::LoadRootCertCache(const char* cache) {
  if (SSL_LOG_STATUS) {
    Log::Print("Looking for trusted roots in %s\n", cache);
  }
  if (Directory::Exists(cache) != Directory::EXISTS) {
    SecureSocketUtils::ThrowIOException(-1, "TlsException",
                                        "Failed to find root cert cache", NULL);
  }
  int status = SSL_CTX_load_verify_locations(context(), NULL, cache);
  SecureSocketUtils::CheckStatus(status, "TlsException",
                                 "Failure trusting builtin roots");
  if (SSL_LOG_STATUS) {
    Log::Print("Trusting roots from: %s\n", cache);
  }
}


int PasswordCallback(char* buf, int size, int rwflag, void* userdata) {
  char* password = static_cast<char*>(userdata);
  ASSERT(size == PEM_BUFSIZE);
  strncpy(buf, password, size);
  return strlen(password);
}


static EVP_PKEY* GetPrivateKeyPKCS12(BIO* bio, const char* password) {
  ScopedPKCS12 p12(d2i_PKCS12_bio(bio, NULL));
  if (p12.get() == NULL) {
    return NULL;
  }

  EVP_PKEY* key = NULL;
  X509* cert = NULL;
  STACK_OF(X509)* ca_certs = NULL;
  int status = PKCS12_parse(p12.get(), password, &key, &cert, &ca_certs);
  if (status == 0) {
    return NULL;
  }

  // We only care about the private key.
  ScopedX509 delete_cert(cert);
  ScopedX509Stack delete_ca_certs(ca_certs);
  return key;
}


static EVP_PKEY* GetPrivateKey(BIO* bio, const char* password) {
  EVP_PKEY* key = PEM_read_bio_PrivateKey(bio, NULL, PasswordCallback,
                                          const_cast<char*>(password));
  if (key == NULL) {
    // We try reading data as PKCS12 only if reading as PEM was unsuccessful and
    // if there is no indication that the data is malformed PEM. We assume the
    // data is malformed PEM if it contains the start line, i.e. a line
    // with ----- BEGIN.
    if (SecureSocketUtils::NoPEMStartLine()) {
      // Reset the bio, and clear the error from trying to read as PEM.
      ERR_clear_error();
      BIO_reset(bio);

      // Try to decode as PKCS12.
      key = GetPrivateKeyPKCS12(bio, password);
    }
  }
  return key;
}


const char* SSLCertContext::GetPasswordArgument(Dart_NativeArguments args,
                                                intptr_t index) {
  Dart_Handle password_object =
      ThrowIfError(Dart_GetNativeArgument(args, index));
  const char* password = NULL;
  if (Dart_IsString(password_object)) {
    ThrowIfError(Dart_StringToCString(password_object, &password));
    if (strlen(password) > PEM_BUFSIZE - 1) {
      Dart_ThrowException(DartUtils::NewDartArgumentError(
          "Password length is greater than 1023 (PEM_BUFSIZE)"));
    }
  } else if (Dart_IsNull(password_object)) {
    password = "";
  } else {
    Dart_ThrowException(
        DartUtils::NewDartArgumentError("Password is not a String or null"));
  }
  return password;
}


int AlpnCallback(SSL* ssl,
                 const uint8_t** out,
                 uint8_t* outlen,
                 const uint8_t* in,
                 unsigned int inlen,
                 void* arg) {
  // 'in' and 'arg' are sequences of (length, data) strings with 1-byte lengths.
  // 'arg' is 0-terminated. Finds the first string in 'arg' that is in 'in'.
  uint8_t* server_list = static_cast<uint8_t*>(arg);
  while (*server_list != 0) {
    uint8_t protocol_length = *server_list++;
    const uint8_t* client_list = in;
    while (client_list < in + inlen) {
      uint8_t client_protocol_length = *client_list++;
      if (client_protocol_length == protocol_length) {
        if (0 == memcmp(server_list, client_list, protocol_length)) {
          *out = client_list;
          *outlen = client_protocol_length;
          return SSL_TLSEXT_ERR_OK;  // Success
        }
      }
      client_list += client_protocol_length;
    }
    server_list += protocol_length;
  }
  // TODO(23580): Make failure send a fatal alert instead of ignoring ALPN.
  return SSL_TLSEXT_ERR_NOACK;
}


// Sets the protocol list for ALPN on a SSL object or a context.
void SSLCertContext::SetAlpnProtocolList(Dart_Handle protocols_handle,
                                         SSL* ssl,
                                         SSLCertContext* context,
                                         bool is_server) {
  // Enable ALPN (application layer protocol negotiation) if the caller provides
  // a valid list of supported protocols.
  Dart_TypedData_Type protocols_type;
  uint8_t* protocol_string = NULL;
  uint8_t* protocol_string_copy = NULL;
  intptr_t protocol_string_len = 0;
  int status;

  Dart_Handle result = Dart_TypedDataAcquireData(
      protocols_handle, &protocols_type,
      reinterpret_cast<void**>(&protocol_string), &protocol_string_len);
  if (Dart_IsError(result)) {
    Dart_PropagateError(result);
  }

  if (protocols_type != Dart_TypedData_kUint8) {
    Dart_TypedDataReleaseData(protocols_handle);
    Dart_PropagateError(Dart_NewApiError(
        "Unexpected type for protocols (expected valid Uint8List)."));
  }

  if (protocol_string_len > 0) {
    if (is_server) {
      // ALPN on server connections must be set on an SSL_CTX object,
      // not on the SSL object of the individual connection.
      ASSERT(context != NULL);
      ASSERT(ssl == NULL);
      // Because it must be passed as a single void*, terminate
      // the list of (length, data) strings with a length 0 string.
      protocol_string_copy =
          static_cast<uint8_t*>(malloc(protocol_string_len + 1));
      memmove(protocol_string_copy, protocol_string, protocol_string_len);
      protocol_string_copy[protocol_string_len] = '\0';
      SSL_CTX_set_alpn_select_cb(context->context(), AlpnCallback,
                                 protocol_string_copy);
      context->set_alpn_protocol_string(protocol_string_copy);
    } else {
      // The function makes a local copy of protocol_string, which it owns.
      if (ssl != NULL) {
        ASSERT(context == NULL);
        status = SSL_set_alpn_protos(ssl, protocol_string, protocol_string_len);
      } else {
        ASSERT(context != NULL);
        ASSERT(ssl == NULL);
        status = SSL_CTX_set_alpn_protos(context->context(), protocol_string,
                                         protocol_string_len);
      }
      ASSERT(status == 0);  // The function returns a non-standard status.
    }
  }
  Dart_TypedDataReleaseData(protocols_handle);
}


static int UseChainBytesPKCS12(SSL_CTX* context,
                               BIO* bio,
                               const char* password) {
  ScopedPKCS12 p12(d2i_PKCS12_bio(bio, NULL));
  if (p12.get() == NULL) {
    return 0;
  }

  EVP_PKEY* key = NULL;
  X509* cert = NULL;
  STACK_OF(X509)* ca_certs = NULL;
  int status = PKCS12_parse(p12.get(), password, &key, &cert, &ca_certs);
  if (status == 0) {
    return status;
  }

  ScopedX509 x509(cert);
  ScopedX509Stack certs(ca_certs);
  status = SSL_CTX_use_certificate(context, x509.get());
  if (ERR_peek_error() != 0) {
    // Key/certificate mismatch doesn't imply status is 0.
    status = 0;
  }
  if (status == 0) {
    return status;
  }

  SSL_CTX_clear_chain_certs(context);

  X509* ca;
  while ((ca = sk_X509_shift(certs.get())) != NULL) {
    status = SSL_CTX_add0_chain_cert(context, ca);
    // SSL_CTX_add0_chain_cert does not inc ref count, so don't free unless the
    // call fails.
    if (status == 0) {
      X509_free(ca);
      return status;
    }
  }

  return status;
}


static int UseChainBytesPEM(SSL_CTX* context, BIO* bio) {
  int status = 0;
  ScopedX509 x509(PEM_read_bio_X509_AUX(bio, NULL, NULL, NULL));
  if (x509.get() == NULL) {
    return 0;
  }

  status = SSL_CTX_use_certificate(context, x509.get());
  if (ERR_peek_error() != 0) {
    // Key/certificate mismatch doesn't imply status is 0.
    status = 0;
  }
  if (status == 0) {
    return status;
  }

  SSL_CTX_clear_chain_certs(context);

  X509* ca;
  while ((ca = PEM_read_bio_X509(bio, NULL, NULL, NULL)) != NULL) {
    status = SSL_CTX_add0_chain_cert(context, ca);
    // SSL_CTX_add0_chain_cert does not inc ref count, so don't free unless the
    // call fails.
    if (status == 0) {
      X509_free(ca);
      return status;
    }
    // Note that we must not free `ca` if it was successfully added to the
    // chain. We must free the main certificate x509, though since its reference
    // count is increased by SSL_CTX_use_certificate.
  }

  return SecureSocketUtils::NoPEMStartLine() ? status : 0;
}


static int UseChainBytes(SSL_CTX* context, BIO* bio, const char* password) {
  int status = UseChainBytesPEM(context, bio);
  if (status == 0) {
    if (SecureSocketUtils::NoPEMStartLine()) {
      ERR_clear_error();
      BIO_reset(bio);
      status = UseChainBytesPKCS12(context, bio, password);
    }
  } else {
    // The PEM file was successfully read.
    ERR_clear_error();
  }
  return status;
}


int SSLCertContext::UseCertificateChainBytes(Dart_Handle cert_chain_bytes,
                                             const char* password) {
  ScopedMemBIO bio(cert_chain_bytes);
  return UseChainBytes(context(), bio.bio(), password);
}


static X509* GetX509Certificate(Dart_NativeArguments args) {
  X509* certificate = NULL;
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  ASSERT(Dart_IsInstance(dart_this));
  ThrowIfError(Dart_GetNativeInstanceField(
      dart_this, SSLCertContext::kX509NativeFieldIndex,
      reinterpret_cast<intptr_t*>(&certificate)));
  return certificate;
}


Dart_Handle X509Helper::GetSubject(Dart_NativeArguments args) {
  X509* certificate = GetX509Certificate(args);
  X509_NAME* subject = X509_get_subject_name(certificate);
  char* subject_string = X509_NAME_oneline(subject, NULL, 0);
  if (subject_string == NULL) {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "X509.subject failed to find subject's common name."));
  }
  Dart_Handle subject_handle = Dart_NewStringFromCString(subject_string);
  OPENSSL_free(subject_string);
  return subject_handle;
}


Dart_Handle X509Helper::GetIssuer(Dart_NativeArguments args) {
  fprintf(stdout, "Getting issuer!\n");
  X509* certificate = GetX509Certificate(args);
  X509_NAME* issuer = X509_get_issuer_name(certificate);
  char* issuer_string = X509_NAME_oneline(issuer, NULL, 0);
  if (issuer_string == NULL) {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "X509.issuer failed to find issuer's common name."));
  }
  Dart_Handle issuer_handle = Dart_NewStringFromCString(issuer_string);
  OPENSSL_free(issuer_string);
  return issuer_handle;
}


static Dart_Handle ASN1TimeToMilliseconds(ASN1_TIME* aTime) {
  ASN1_UTCTIME* epoch_start = M_ASN1_UTCTIME_new();
  ASN1_UTCTIME_set_string(epoch_start, "700101000000Z");
  int days;
  int seconds;
  int result = ASN1_TIME_diff(&days, &seconds, epoch_start, aTime);
  M_ASN1_UTCTIME_free(epoch_start);
  if (result != 1) {
    // TODO(whesse): Propagate an error to Dart.
    Log::PrintErr("ASN1Time error %d\n", result);
  }
  return Dart_NewInteger((86400LL * days + seconds) * 1000LL);
}


Dart_Handle X509Helper::GetStartValidity(Dart_NativeArguments args) {
  X509* certificate = GetX509Certificate(args);
  ASN1_TIME* not_before = X509_get_notBefore(certificate);
  return ASN1TimeToMilliseconds(not_before);
}


Dart_Handle X509Helper::GetEndValidity(Dart_NativeArguments args) {
  X509* certificate = GetX509Certificate(args);
  ASN1_TIME* not_after = X509_get_notAfter(certificate);
  return ASN1TimeToMilliseconds(not_after);
}

void FUNCTION_NAME(SecurityContext_UsePrivateKeyBytes)(
    Dart_NativeArguments args) {
  SSLCertContext* context = SSLCertContext::GetSecurityContext(args);
  const char* password = SSLCertContext::GetPasswordArgument(args, 2);

  int status;
  {
    ScopedMemBIO bio(ThrowIfError(Dart_GetNativeArgument(args, 1)));
    EVP_PKEY* key = GetPrivateKey(bio.bio(), password);
    status = SSL_CTX_use_PrivateKey(context->context(), key);
    // SSL_CTX_use_PrivateKey increments the reference count of key on success,
    // so we have to call EVP_PKEY_free on both success and failure.
    EVP_PKEY_free(key);
  }

  // TODO(24184): Handle different expected errors here - file missing,
  // incorrect password, file not a PEM, and throw exceptions.
  // SecureSocketUtils::CheckStatus should also throw an exception in uncaught
  // cases.
  SecureSocketUtils::CheckStatus(status, "TlsException",
                                 "Failure in usePrivateKeyBytes");
}


void FUNCTION_NAME(SecurityContext_Allocate)(Dart_NativeArguments args) {
  SSLFilter::InitializeLibrary();
  SSL_CTX* ctx = SSL_CTX_new(TLS_method());
  SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER, SSLCertContext::CertificateCallback);
  SSL_CTX_set_min_proto_version(ctx, TLS1_VERSION);
  SSL_CTX_set_cipher_list(ctx, "HIGH:MEDIUM");
  SSLCertContext* context = new SSLCertContext(ctx);
  Dart_Handle err = SetSecurityContext(args, context);
  if (Dart_IsError(err)) {
    delete context;
    Dart_PropagateError(err);
  }
}


void FUNCTION_NAME(SecurityContext_SetTrustedCertificatesBytes)(
    Dart_NativeArguments args) {
  SSLCertContext* context = SSLCertContext::GetSecurityContext(args);
  Dart_Handle cert_bytes = ThrowIfError(Dart_GetNativeArgument(args, 1));
  const char* password = SSLCertContext::GetPasswordArgument(args, 2);

  ASSERT(context != NULL);
  ASSERT(password != NULL);
  context->SetTrustedCertificatesBytes(cert_bytes, password);
}


void FUNCTION_NAME(SecurityContext_SetClientAuthoritiesBytes)(
    Dart_NativeArguments args) {
  SSLCertContext* context = SSLCertContext::GetSecurityContext(args);
  Dart_Handle client_authorities_bytes =
      ThrowIfError(Dart_GetNativeArgument(args, 1));
  const char* password = SSLCertContext::GetPasswordArgument(args, 2);

  ASSERT(context != NULL);
  ASSERT(password != NULL);

  context->SetClientAuthoritiesBytes(client_authorities_bytes, password);
}


void FUNCTION_NAME(SecurityContext_UseCertificateChainBytes)(
    Dart_NativeArguments args) {
  SSLCertContext* context = SSLCertContext::GetSecurityContext(args);
  Dart_Handle cert_chain_bytes = ThrowIfError(Dart_GetNativeArgument(args, 1));
  const char* password = SSLCertContext::GetPasswordArgument(args, 2);

  ASSERT(context != NULL);
  ASSERT(password != NULL);

  int status = context->UseCertificateChainBytes(cert_chain_bytes, password);

  SecureSocketUtils::CheckStatus(status, "TlsException",
                                 "Failure in useCertificateChainBytes");
}


void FUNCTION_NAME(SecurityContext_AlpnSupported)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, Dart_NewBoolean(true));
}


void FUNCTION_NAME(SecurityContext_TrustBuiltinRoots)(
    Dart_NativeArguments args) {
  SSLCertContext* context = SSLCertContext::GetSecurityContext(args);

  ASSERT(context != NULL);

  context->TrustBuiltinRoots();
}


void FUNCTION_NAME(X509_Subject)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, X509Helper::GetSubject(args));
}


void FUNCTION_NAME(X509_Issuer)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, X509Helper::GetIssuer(args));
}


void FUNCTION_NAME(X509_StartValidity)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, X509Helper::GetStartValidity(args));
}


void FUNCTION_NAME(X509_EndValidity)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, X509Helper::GetEndValidity(args));
}


void FUNCTION_NAME(SecurityContext_SetAlpnProtocols)(
    Dart_NativeArguments args) {
  SSLCertContext* context = SSLCertContext::GetSecurityContext(args);
  Dart_Handle protocols_handle = ThrowIfError(Dart_GetNativeArgument(args, 1));
  Dart_Handle is_server_handle = ThrowIfError(Dart_GetNativeArgument(args, 2));
  if (Dart_IsBoolean(is_server_handle)) {
    bool is_server = DartUtils::GetBooleanValue(is_server_handle);
    SSLCertContext::SetAlpnProtocolList(protocols_handle, NULL, context,
                                        is_server);
  } else {
    Dart_ThrowException(DartUtils::NewDartArgumentError(
        "Non-boolean is_server argument passed to SetAlpnProtocols"));
  }
}

}  // namespace bin
}  // namespace dart

#endif  // !defined(DART_IO_DISABLED) &&
        // !defined(DART_IO_SECURE_SOCKET_DISABLED)
