/*
 * Implement J-PAKE, as described in
 * http://grouper.ieee.org/groups/1363/Research/contributions/hao-ryan-2008.pdf
 *
 * With hints from http://www.cl.cam.ac.uk/~fh240/software/JPAKE2.java.
 */

#ifndef HEADER_JPAKE_H
# define HEADER_JPAKE_H

# include <openssl/opensslconf.h>

# ifdef OPENSSL_NO_JPAKE
#  error JPAKE is disabled.
# endif

#ifdef  __cplusplus
extern "C" {
#endif

# include <openssl/bn.h>
# include <openssl/sha.h>

typedef struct JPAKE_CTX JPAKE_CTX;

/* Note that "g" in the ZKPs is not necessarily the J-PAKE g. */
typedef struct {
    BIGNUM *gr;                 /* g^r (r random) */
    BIGNUM *b;                  /* b = r - x*h, h=hash(g, g^r, g^x, name) */
} JPAKE_ZKP;

typedef struct {
    BIGNUM *gx;                 /* g^x in step 1, g^(xa + xc + xd) * xb * s
                                 * in step 2 */
    JPAKE_ZKP zkpx;             /* ZKP(x) or ZKP(xb * s) */
} JPAKE_STEP_PART;

typedef struct {
    JPAKE_STEP_PART p1;         /* g^x3, ZKP(x3) or g^x1, ZKP(x1) */
    JPAKE_STEP_PART p2;         /* g^x4, ZKP(x4) or g^x2, ZKP(x2) */
} JPAKE_STEP1;

typedef JPAKE_STEP_PART JPAKE_STEP2;

typedef struct {
    unsigned char hhk[SHA_DIGEST_LENGTH];
} JPAKE_STEP3A;

typedef struct {
    unsigned char hk[SHA_DIGEST_LENGTH];
} JPAKE_STEP3B;

/* Parameters are copied */
JPAKE_CTX *JPAKE_CTX_new(const char *name, const char *peer_name,
                         const BIGNUM *p, const BIGNUM *g, const BIGNUM *q,
                         const BIGNUM *secret);
void JPAKE_CTX_free(JPAKE_CTX *ctx);

/*
 * Note that JPAKE_STEP1 can be used multiple times before release
 * without another init.
 */
void JPAKE_STEP1_init(JPAKE_STEP1 *s1);
int JPAKE_STEP1_generate(JPAKE_STEP1 *send, JPAKE_CTX *ctx);
int JPAKE_STEP1_process(JPAKE_CTX *ctx, const JPAKE_STEP1 *received);
void JPAKE_STEP1_release(JPAKE_STEP1 *s1);

/*
 * Note that JPAKE_STEP2 can be used multiple times before release
 * without another init.
 */
void JPAKE_STEP2_init(JPAKE_STEP2 *s2);
int JPAKE_STEP2_generate(JPAKE_STEP2 *send, JPAKE_CTX *ctx);
int JPAKE_STEP2_process(JPAKE_CTX *ctx, const JPAKE_STEP2 *received);
void JPAKE_STEP2_release(JPAKE_STEP2 *s2);

/*
 * Optionally verify the shared key. If the shared secrets do not
 * match, the two ends will disagree about the shared key, but
 * otherwise the protocol will succeed.
 */
void JPAKE_STEP3A_init(JPAKE_STEP3A *s3a);
int JPAKE_STEP3A_generate(JPAKE_STEP3A *send, JPAKE_CTX *ctx);
int JPAKE_STEP3A_process(JPAKE_CTX *ctx, const JPAKE_STEP3A *received);
void JPAKE_STEP3A_release(JPAKE_STEP3A *s3a);

void JPAKE_STEP3B_init(JPAKE_STEP3B *s3b);
int JPAKE_STEP3B_generate(JPAKE_STEP3B *send, JPAKE_CTX *ctx);
int JPAKE_STEP3B_process(JPAKE_CTX *ctx, const JPAKE_STEP3B *received);
void JPAKE_STEP3B_release(JPAKE_STEP3B *s3b);

/*
 * the return value belongs to the library and will be released when
 * ctx is released, and will change when a new handshake is performed.
 */
const BIGNUM *JPAKE_get_shared_key(JPAKE_CTX *ctx);

/* BEGIN ERROR CODES */
/*
 * The following lines are auto generated by the script mkerr.pl. Any changes
 * made after this point may be overwritten when the script is next run.
 */
void ERR_load_JPAKE_strings(void);

/* Error codes for the JPAKE functions. */

/* Function codes. */
# define JPAKE_F_JPAKE_STEP1_PROCESS                      101
# define JPAKE_F_JPAKE_STEP2_PROCESS                      102
# define JPAKE_F_JPAKE_STEP3A_PROCESS                     103
# define JPAKE_F_JPAKE_STEP3B_PROCESS                     104
# define JPAKE_F_VERIFY_ZKP                               100

/* Reason codes. */
# define JPAKE_R_G_TO_THE_X3_IS_NOT_LEGAL                 108
# define JPAKE_R_G_TO_THE_X4_IS_NOT_LEGAL                 109
# define JPAKE_R_G_TO_THE_X4_IS_ONE                       105
# define JPAKE_R_HASH_OF_HASH_OF_KEY_MISMATCH             106
# define JPAKE_R_HASH_OF_KEY_MISMATCH                     107
# define JPAKE_R_VERIFY_B_FAILED                          102
# define JPAKE_R_VERIFY_X3_FAILED                         103
# define JPAKE_R_VERIFY_X4_FAILED                         104
# define JPAKE_R_ZKP_VERIFY_FAILED                        100

#ifdef  __cplusplus
}
#endif
#endif
