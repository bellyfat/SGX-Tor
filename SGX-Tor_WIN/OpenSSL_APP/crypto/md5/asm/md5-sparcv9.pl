#!/usr/bin/env perl

# ====================================================================
# Written by Andy Polyakov <appro@openssl.org> for the OpenSSL
# project. The module is, however, dual licensed under OpenSSL and
# CRYPTOGAMS licenses depending on where you obtain it. For further
# details see http://www.openssl.org/~appro/cryptogams/.
#
# Hardware SPARC T4 support by David S. Miller <davem@davemloft.net>.
# ====================================================================

# MD5 for SPARCv9, 6.9 cycles per byte on UltraSPARC, >40% faster than
# code generated by Sun C 5.2.

# SPARC T4 MD5 hardware achieves 3.20 cycles per byte, which is 2.1x
# faster than software. Multi-process benchmark saturates at 12x
# single-process result on 8-core processor, or ~11GBps per 2.85GHz
# socket.

$output=shift;
open STDOUT,">$output";

use integer;

($ctx,$inp,$len)=("%i0","%i1","%i2");	# input arguments

# 64-bit values
@X=("%o0","%o1","%o2","%o3","%o4","%o5","%o7","%g1","%g2");
$tx="%g3";
($AB,$CD)=("%g4","%g5");

# 32-bit values
@V=($A,$B,$C,$D)=map("%l$_",(0..3));
($t1,$t2,$t3,$saved_asi)=map("%l$_",(4..7));
($shr,$shl1,$shl2)=("%i3","%i4","%i5");

my @K=(	0xd76aa478,0xe8c7b756,0x242070db,0xc1bdceee,
	0xf57c0faf,0x4787c62a,0xa8304613,0xfd469501,
	0x698098d8,0x8b44f7af,0xffff5bb1,0x895cd7be,
	0x6b901122,0xfd987193,0xa679438e,0x49b40821,

	0xf61e2562,0xc040b340,0x265e5a51,0xe9b6c7aa,
	0xd62f105d,0x02441453,0xd8a1e681,0xe7d3fbc8,
	0x21e1cde6,0xc33707d6,0xf4d50d87,0x455a14ed,
	0xa9e3e905,0xfcefa3f8,0x676f02d9,0x8d2a4c8a,

	0xfffa3942,0x8771f681,0x6d9d6122,0xfde5380c,
	0xa4beea44,0x4bdecfa9,0xf6bb4b60,0xbebfbc70,
	0x289b7ec6,0xeaa127fa,0xd4ef3085,0x04881d05,
	0xd9d4d039,0xe6db99e5,0x1fa27cf8,0xc4ac5665,

	0xf4292244,0x432aff97,0xab9423a7,0xfc93a039,
	0x655b59c3,0x8f0ccc92,0xffeff47d,0x85845dd1,
	0x6fa87e4f,0xfe2ce6e0,0xa3014314,0x4e0811a1,
	0xf7537e82,0xbd3af235,0x2ad7d2bb,0xeb86d391, 0	);

sub R0 {
  my ($i,$a,$b,$c,$d) = @_;
  my $rot = (7,12,17,22)[$i%4];
  my $j   = ($i+1)/2;

  if ($i&1) {
    $code.=<<___;
	 srlx	@X[$j],$shr,@X[$j]	! align X[`$i+1`]
	and	$b,$t1,$t1		! round $i
	 sllx	@X[$j+1],$shl1,$tx
	add	$t2,$a,$a
	 sllx	$tx,$shl2,$tx
	xor	$d,$t1,$t1
	 or	$tx,@X[$j],@X[$j]
	 sethi	%hi(@K[$i+1]),$t2
	add	$t1,$a,$a
	 or	$t2,%lo(@K[$i+1]),$t2
	sll	$a,$rot,$t3
	 add	@X[$j],$t2,$t2		! X[`$i+1`]+K[`$i+1`]
	srl	$a,32-$rot,$a
	add	$b,$t3,$t3
	 xor	 $b,$c,$t1
	add	$t3,$a,$a
___
  } else {
    $code.=<<___;
	 srlx	@X[$j],32,$tx		! extract X[`2*$j+1`]
	and	$b,$t1,$t1		! round $i
	add	$t2,$a,$a
	xor	$d,$t1,$t1
	 sethi	%hi(@K[$i+1]),$t2
	add	$t1,$a,$a
	 or	$t2,%lo(@K[$i+1]),$t2
	sll	$a,$rot,$t3
	 add	$tx,$t2,$t2		! X[`2*$j+1`]+K[`$i+1`]
	srl	$a,32-$rot,$a
	add	$b,$t3,$t3
	 xor	 $b,$c,$t1
	add	$t3,$a,$a
___
  }
}

sub R0_1 {
  my ($i,$a,$b,$c,$d) = @_;
  my $rot = (7,12,17,22)[$i%4];

$code.=<<___;
	 srlx	@X[0],32,$tx		! extract X[1]
	and	$b,$t1,$t1		! round $i
	add	$t2,$a,$a
	xor	$d,$t1,$t1
	 sethi	%hi(@K[$i+1]),$t2
	add	$t1,$a,$a
	 or	$t2,%lo(@K[$i+1]),$t2
	sll	$a,$rot,$t3
	 add	$tx,$t2,$t2		! X[1]+K[`$i+1`]
	srl	$a,32-$rot,$a
	add	$b,$t3,$t3
	 andn	 $b,$c,$t1
	add	$t3,$a,$a
___
}

sub R1 {
  my ($i,$a,$b,$c,$d) = @_;
  my $rot = (5,9,14,20)[$i%4];
  my $j   = $i<31 ? (1+5*($i+1))%16 : (5+3*($i+1))%16;
  my $xi  = @X[$j/2];

$code.=<<___ if ($j&1 && ($xi=$tx));
	 srlx	@X[$j/2],32,$xi		! extract X[$j]
___
$code.=<<___;
	and	$b,$d,$t3		! round $i
	add	$t2,$a,$a
	or	$t3,$t1,$t1
	 sethi	%hi(@K[$i+1]),$t2
	add	$t1,$a,$a
	 or	$t2,%lo(@K[$i+1]),$t2
	sll	$a,$rot,$t3
	 add	$xi,$t2,$t2		! X[$j]+K[`$i+1`]
	srl	$a,32-$rot,$a
	add	$b,$t3,$t3
	 `$i<31?"andn":"xor"`	 $b,$c,$t1
	add	$t3,$a,$a
___
}

sub R2 {
  my ($i,$a,$b,$c,$d) = @_;
  my $rot = (4,11,16,23)[$i%4];
  my $j   = $i<47 ? (5+3*($i+1))%16 : (0+7*($i+1))%16;
  my $xi  = @X[$j/2];

$code.=<<___ if ($j&1 && ($xi=$tx));
	 srlx	@X[$j/2],32,$xi		! extract X[$j]
___
$code.=<<___;
	add	$t2,$a,$a		! round $i
	xor	$b,$t1,$t1
	 sethi	%hi(@K[$i+1]),$t2
	add	$t1,$a,$a
	 or	$t2,%lo(@K[$i+1]),$t2
	sll	$a,$rot,$t3
	 add	$xi,$t2,$t2		! X[$j]+K[`$i+1`]
	srl	$a,32-$rot,$a
	add	$b,$t3,$t3
	 xor	 $b,$c,$t1
	add	$t3,$a,$a
___
}

sub R3 {
  my ($i,$a,$b,$c,$d) = @_;
  my $rot = (6,10,15,21)[$i%4];
  my $j   = (0+7*($i+1))%16;
  my $xi  = @X[$j/2];

$code.=<<___;
	add	$t2,$a,$a		! round $i
___
$code.=<<___ if ($j&1 && ($xi=$tx));
	 srlx	@X[$j/2],32,$xi		! extract X[$j]
___
$code.=<<___;
	orn	$b,$d,$t1
	 sethi	%hi(@K[$i+1]),$t2
	xor	$c,$t1,$t1
	 or	$t2,%lo(@K[$i+1]),$t2
	add	$t1,$a,$a
	sll	$a,$rot,$t3
	 add	$xi,$t2,$t2		! X[$j]+K[`$i+1`]
	srl	$a,32-$rot,$a
	add	$b,$t3,$t3
	add	$t3,$a,$a
___
}

$code.=<<___;
#include "sparc_arch.h"

#ifdef __arch64__
.register	%g2,#scratch
.register	%g3,#scratch
#endif

.section	".text",#alloc,#execinstr

#ifdef __PIC__
SPARC_PIC_THUNK(%g1)
#endif

.globl	md5_block_asm_data_order
.align	32
md5_block_asm_data_order:
	SPARC_LOAD_ADDRESS_LEAF(OPENSSL_sparcv9cap_P,%g1,%g5)
	ld	[%g1+4],%g1		! OPENSSL_sparcv9cap_P[1]

	andcc	%g1, CFR_MD5, %g0
	be	.Lsoftware
	nop

	mov	4, %g1
	andcc	%o1, 0x7, %g0
	lda	[%o0 + %g0]0x88, %f0		! load context
	lda	[%o0 + %g1]0x88, %f1
	add	%o0, 8, %o0
	lda	[%o0 + %g0]0x88, %f2
	lda	[%o0 + %g1]0x88, %f3
	bne,pn	%icc, .Lhwunaligned
	sub	%o0, 8, %o0

.Lhw_loop:
	ldd	[%o1 + 0x00], %f8
	ldd	[%o1 + 0x08], %f10
	ldd	[%o1 + 0x10], %f12
	ldd	[%o1 + 0x18], %f14
	ldd	[%o1 + 0x20], %f16
	ldd	[%o1 + 0x28], %f18
	ldd	[%o1 + 0x30], %f20
	subcc	%o2, 1, %o2		! done yet? 
	ldd	[%o1 + 0x38], %f22
	add	%o1, 0x40, %o1
	prefetch [%o1 + 63], 20

	.word	0x81b02800		! MD5

	bne,pt	SIZE_T_CC, .Lhw_loop
	nop

.Lhwfinish:
	sta	%f0, [%o0 + %g0]0x88	! store context
	sta	%f1, [%o0 + %g1]0x88
	add	%o0, 8, %o0
	sta	%f2, [%o0 + %g0]0x88
	sta	%f3, [%o0 + %g1]0x88
	retl
	nop

.align	8
.Lhwunaligned:
	alignaddr %o1, %g0, %o1

	ldd	[%o1 + 0x00], %f10
.Lhwunaligned_loop:
	ldd	[%o1 + 0x08], %f12
	ldd	[%o1 + 0x10], %f14
	ldd	[%o1 + 0x18], %f16
	ldd	[%o1 + 0x20], %f18
	ldd	[%o1 + 0x28], %f20
	ldd	[%o1 + 0x30], %f22
	ldd	[%o1 + 0x38], %f24
	subcc	%o2, 1, %o2		! done yet?
	ldd	[%o1 + 0x40], %f26
	add	%o1, 0x40, %o1
	prefetch [%o1 + 63], 20

	faligndata %f10, %f12, %f8
	faligndata %f12, %f14, %f10
	faligndata %f14, %f16, %f12
	faligndata %f16, %f18, %f14
	faligndata %f18, %f20, %f16
	faligndata %f20, %f22, %f18
	faligndata %f22, %f24, %f20
	faligndata %f24, %f26, %f22

	.word	0x81b02800		! MD5

	bne,pt	SIZE_T_CC, .Lhwunaligned_loop
	for	%f26, %f26, %f10	! %f10=%f26

	ba	.Lhwfinish
	nop

.align	16
.Lsoftware:
	save	%sp,-STACK_FRAME,%sp

	rd	%asi,$saved_asi
	wr	%g0,0x88,%asi		! ASI_PRIMARY_LITTLE
	and	$inp,7,$shr
	andn	$inp,7,$inp

	sll	$shr,3,$shr		! *=8
	mov	56,$shl2
	ld	[$ctx+0],$A
	sub	$shl2,$shr,$shl2
	ld	[$ctx+4],$B
	and	$shl2,32,$shl1
	add	$shl2,8,$shl2
	ld	[$ctx+8],$C
	sub	$shl2,$shl1,$shl2	! shr+shl1+shl2==64
	ld	[$ctx+12],$D
	nop

.Loop:
	 cmp	$shr,0			! was inp aligned?
	ldxa	[$inp+0]%asi,@X[0]	! load little-endian input
	ldxa	[$inp+8]%asi,@X[1]
	ldxa	[$inp+16]%asi,@X[2]
	ldxa	[$inp+24]%asi,@X[3]
	ldxa	[$inp+32]%asi,@X[4]
	 sllx	$A,32,$AB		! pack A,B
	ldxa	[$inp+40]%asi,@X[5]
	 sllx	$C,32,$CD		! pack C,D
	ldxa	[$inp+48]%asi,@X[6]
	 or	$B,$AB,$AB
	ldxa	[$inp+56]%asi,@X[7]
	 or	$D,$CD,$CD
	bnz,a,pn	%icc,.+8
	ldxa	[$inp+64]%asi,@X[8]

	srlx	@X[0],$shr,@X[0]	! align X[0]
	sllx	@X[1],$shl1,$tx
	 sethi	%hi(@K[0]),$t2
	sllx	$tx,$shl2,$tx
	 or	$t2,%lo(@K[0]),$t2
	or	$tx,@X[0],@X[0]
	 xor	$C,$D,$t1
	 add	@X[0],$t2,$t2		! X[0]+K[0]
___
	for ($i=0;$i<15;$i++)	{ &R0($i,@V);	unshift(@V,pop(@V)); }
	for (;$i<16;$i++)	{ &R0_1($i,@V);	unshift(@V,pop(@V)); }
	for (;$i<32;$i++)	{ &R1($i,@V);	unshift(@V,pop(@V)); }
	for (;$i<48;$i++)	{ &R2($i,@V);	unshift(@V,pop(@V)); }
	for (;$i<64;$i++)	{ &R3($i,@V);	unshift(@V,pop(@V)); }
$code.=<<___;
	srlx	$AB,32,$t1		! unpack A,B,C,D and accumulate
	add	$inp,64,$inp		! advance inp
	srlx	$CD,32,$t2
	add	$t1,$A,$A
	subcc	$len,1,$len		! done yet?
	add	$AB,$B,$B
	add	$t2,$C,$C
	add	$CD,$D,$D
	srl	$B,0,$B			! clruw	$B
	bne	SIZE_T_CC,.Loop
	srl	$D,0,$D			! clruw	$D

	st	$A,[$ctx+0]		! write out ctx
	st	$B,[$ctx+4]
	st	$C,[$ctx+8]
	st	$D,[$ctx+12]

	wr	%g0,$saved_asi,%asi
	ret
	restore
.type	md5_block_asm_data_order,#function
.size	md5_block_asm_data_order,(.-md5_block_asm_data_order)

.asciz	"MD5 block transform for SPARCv9, CRYPTOGAMS by <appro\@openssl.org>"
.align	4
___

# Purpose of these subroutines is to explicitly encode VIS instructions,
# so that one can compile the module without having to specify VIS
# extensions on compiler command line, e.g. -xarch=v9 vs. -xarch=v9a.
# Idea is to reserve for option to produce "universal" binary and let
# programmer detect if current CPU is VIS capable at run-time.
sub unvis {
my ($mnemonic,$rs1,$rs2,$rd)=@_;
my $ref,$opf;
my %visopf = (	"faligndata"	=> 0x048,
		"for"		=> 0x07c	);

    $ref = "$mnemonic\t$rs1,$rs2,$rd";

    if ($opf=$visopf{$mnemonic}) {
	foreach ($rs1,$rs2,$rd) {
	    return $ref if (!/%f([0-9]{1,2})/);
	    $_=$1;
	    if ($1>=32) {
		return $ref if ($1&1);
		# re-encode for upper double register addressing
		$_=($1|$1>>5)&31;
	    }
	}

	return	sprintf ".word\t0x%08x !%s",
			0x81b00000|$rd<<25|$rs1<<14|$opf<<5|$rs2,
			$ref;
    } else {
	return $ref;
    }
}
sub unalignaddr {
my ($mnemonic,$rs1,$rs2,$rd)=@_;
my %bias = ( "g" => 0, "o" => 8, "l" => 16, "i" => 24 );
my $ref="$mnemonic\t$rs1,$rs2,$rd";

    foreach ($rs1,$rs2,$rd) {
	if (/%([goli])([0-7])/)	{ $_=$bias{$1}+$2; }
	else			{ return $ref; }
    }
    return  sprintf ".word\t0x%08x !%s",
		    0x81b00300|$rd<<25|$rs1<<14|$rs2,
		    $ref;
}

foreach (split("\n",$code)) {
	s/\`([^\`]*)\`/eval $1/ge;

	s/\b(f[^\s]*)\s+(%f[0-9]{1,2}),\s*(%f[0-9]{1,2}),\s*(%f[0-9]{1,2})/
		&unvis($1,$2,$3,$4)
	 /ge;
	s/\b(alignaddr)\s+(%[goli][0-7]),\s*(%[goli][0-7]),\s*(%[goli][0-7])/
		&unalignaddr($1,$2,$3,$4)
	 /ge;

	print $_,"\n";
}

close STDOUT;
