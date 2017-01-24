/*
 * Copyright (c) 2000-2007 Niels Provos <provos@citi.umich.edu>
 * Copyright (c) 2007-2012 Niels Provos and Nick Mathewson
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#ifndef _EVDNS_H_
#define _EVDNS_H_

/** @file evdns.h

  A dns subsystem for Libevent.

  The <evdns.h> header is deprecated in Libevent 2.0 and later; please
  use <event2/evdns.h> instead.  Depending on what functionality you
  need, you may also want to include more of the other <event2/...>
  headers.
 */

#include <event.h>
#include <event2/dns.h>
#include <event2/dns_compat.h>
#include <event2/dns_struct.h>

// SGX: We only use getnetworkparams to load nameservers!
/* 
extern unsigned long sgx_RegQueryValueEx(HKEY hkey, char *vname, unsigned long *reserved, unsigned long *type, void *data, unsigned long *data_len);
extern unsigned long sgx_RegOpenKeyEx(HKEY hkey, char *subkey, unsigned long opt, unsigned long sam, HKEY *result);
extern unsigned long sgx_RegCloseKey(HKEY hkey);
*/
extern int sgx_SHGetSpecialFolderPathA(HWND hwnd, char *path, int csidl, int fCreate);

#endif /* _EVDNS_H_ */
