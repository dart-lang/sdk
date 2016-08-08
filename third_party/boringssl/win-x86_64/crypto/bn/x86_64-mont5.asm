default	rel
%define XMMWORD
%define YMMWORD
%define ZMMWORD
section	.text code align=64


EXTERN	OPENSSL_ia32cap_P

global	bn_mul_mont_gather5

ALIGN	64
bn_mul_mont_gather5:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_bn_mul_mont_gather5:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]
	mov	r9,QWORD[48+rsp]


	test	r9d,7
	jnz	NEAR $L$mul_enter
	jmp	NEAR $L$mul4x_enter

ALIGN	16
$L$mul_enter:
	mov	r9d,r9d
	mov	rax,rsp
	movd	xmm5,DWORD[56+rsp]
	lea	r10,[$L$inc]
	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15

	lea	r11,[2+r9]
	neg	r11
	lea	rsp,[((-264))+r11*8+rsp]
	and	rsp,-1024

	mov	QWORD[8+r9*8+rsp],rax
$L$mul_body:
	lea	r12,[128+rdx]
	movdqa	xmm0,XMMWORD[r10]
	movdqa	xmm1,XMMWORD[16+r10]
	lea	r10,[((24-112))+r9*8+rsp]
	and	r10,-16

	pshufd	xmm5,xmm5,0
	movdqa	xmm4,xmm1
	movdqa	xmm2,xmm1
	paddd	xmm1,xmm0
	pcmpeqd	xmm0,xmm5
DB	0x67
	movdqa	xmm3,xmm4
	paddd	xmm2,xmm1
	pcmpeqd	xmm1,xmm5
	movdqa	XMMWORD[112+r10],xmm0
	movdqa	xmm0,xmm4

	paddd	xmm3,xmm2
	pcmpeqd	xmm2,xmm5
	movdqa	XMMWORD[128+r10],xmm1
	movdqa	xmm1,xmm4

	paddd	xmm0,xmm3
	pcmpeqd	xmm3,xmm5
	movdqa	XMMWORD[144+r10],xmm2
	movdqa	xmm2,xmm4

	paddd	xmm1,xmm0
	pcmpeqd	xmm0,xmm5
	movdqa	XMMWORD[160+r10],xmm3
	movdqa	xmm3,xmm4
	paddd	xmm2,xmm1
	pcmpeqd	xmm1,xmm5
	movdqa	XMMWORD[176+r10],xmm0
	movdqa	xmm0,xmm4

	paddd	xmm3,xmm2
	pcmpeqd	xmm2,xmm5
	movdqa	XMMWORD[192+r10],xmm1
	movdqa	xmm1,xmm4

	paddd	xmm0,xmm3
	pcmpeqd	xmm3,xmm5
	movdqa	XMMWORD[208+r10],xmm2
	movdqa	xmm2,xmm4

	paddd	xmm1,xmm0
	pcmpeqd	xmm0,xmm5
	movdqa	XMMWORD[224+r10],xmm3
	movdqa	xmm3,xmm4
	paddd	xmm2,xmm1
	pcmpeqd	xmm1,xmm5
	movdqa	XMMWORD[240+r10],xmm0
	movdqa	xmm0,xmm4

	paddd	xmm3,xmm2
	pcmpeqd	xmm2,xmm5
	movdqa	XMMWORD[256+r10],xmm1
	movdqa	xmm1,xmm4

	paddd	xmm0,xmm3
	pcmpeqd	xmm3,xmm5
	movdqa	XMMWORD[272+r10],xmm2
	movdqa	xmm2,xmm4

	paddd	xmm1,xmm0
	pcmpeqd	xmm0,xmm5
	movdqa	XMMWORD[288+r10],xmm3
	movdqa	xmm3,xmm4
	paddd	xmm2,xmm1
	pcmpeqd	xmm1,xmm5
	movdqa	XMMWORD[304+r10],xmm0

	paddd	xmm3,xmm2
DB	0x67
	pcmpeqd	xmm2,xmm5
	movdqa	XMMWORD[320+r10],xmm1

	pcmpeqd	xmm3,xmm5
	movdqa	XMMWORD[336+r10],xmm2
	pand	xmm0,XMMWORD[64+r12]

	pand	xmm1,XMMWORD[80+r12]
	pand	xmm2,XMMWORD[96+r12]
	movdqa	XMMWORD[352+r10],xmm3
	pand	xmm3,XMMWORD[112+r12]
	por	xmm0,xmm2
	por	xmm1,xmm3
	movdqa	xmm4,XMMWORD[((-128))+r12]
	movdqa	xmm5,XMMWORD[((-112))+r12]
	movdqa	xmm2,XMMWORD[((-96))+r12]
	pand	xmm4,XMMWORD[112+r10]
	movdqa	xmm3,XMMWORD[((-80))+r12]
	pand	xmm5,XMMWORD[128+r10]
	por	xmm0,xmm4
	pand	xmm2,XMMWORD[144+r10]
	por	xmm1,xmm5
	pand	xmm3,XMMWORD[160+r10]
	por	xmm0,xmm2
	por	xmm1,xmm3
	movdqa	xmm4,XMMWORD[((-64))+r12]
	movdqa	xmm5,XMMWORD[((-48))+r12]
	movdqa	xmm2,XMMWORD[((-32))+r12]
	pand	xmm4,XMMWORD[176+r10]
	movdqa	xmm3,XMMWORD[((-16))+r12]
	pand	xmm5,XMMWORD[192+r10]
	por	xmm0,xmm4
	pand	xmm2,XMMWORD[208+r10]
	por	xmm1,xmm5
	pand	xmm3,XMMWORD[224+r10]
	por	xmm0,xmm2
	por	xmm1,xmm3
	movdqa	xmm4,XMMWORD[r12]
	movdqa	xmm5,XMMWORD[16+r12]
	movdqa	xmm2,XMMWORD[32+r12]
	pand	xmm4,XMMWORD[240+r10]
	movdqa	xmm3,XMMWORD[48+r12]
	pand	xmm5,XMMWORD[256+r10]
	por	xmm0,xmm4
	pand	xmm2,XMMWORD[272+r10]
	por	xmm1,xmm5
	pand	xmm3,XMMWORD[288+r10]
	por	xmm0,xmm2
	por	xmm1,xmm3
	por	xmm0,xmm1
	pshufd	xmm1,xmm0,0x4e
	por	xmm0,xmm1
	lea	r12,[256+r12]
DB	102,72,15,126,195

	mov	r8,QWORD[r8]
	mov	rax,QWORD[rsi]

	xor	r14,r14
	xor	r15,r15

	mov	rbp,r8
	mul	rbx
	mov	r10,rax
	mov	rax,QWORD[rcx]

	imul	rbp,r10
	mov	r11,rdx

	mul	rbp
	add	r10,rax
	mov	rax,QWORD[8+rsi]
	adc	rdx,0
	mov	r13,rdx

	lea	r15,[1+r15]
	jmp	NEAR $L$1st_enter

ALIGN	16
$L$1st:
	add	r13,rax
	mov	rax,QWORD[r15*8+rsi]
	adc	rdx,0
	add	r13,r11
	mov	r11,r10
	adc	rdx,0
	mov	QWORD[((-16))+r15*8+rsp],r13
	mov	r13,rdx

$L$1st_enter:
	mul	rbx
	add	r11,rax
	mov	rax,QWORD[r15*8+rcx]
	adc	rdx,0
	lea	r15,[1+r15]
	mov	r10,rdx

	mul	rbp
	cmp	r15,r9
	jne	NEAR $L$1st


	add	r13,rax
	adc	rdx,0
	add	r13,r11
	adc	rdx,0
	mov	QWORD[((-16))+r9*8+rsp],r13
	mov	r13,rdx
	mov	r11,r10

	xor	rdx,rdx
	add	r13,r11
	adc	rdx,0
	mov	QWORD[((-8))+r9*8+rsp],r13
	mov	QWORD[r9*8+rsp],rdx

	lea	r14,[1+r14]
	jmp	NEAR $L$outer
ALIGN	16
$L$outer:
	lea	rdx,[((24+128))+r9*8+rsp]
	and	rdx,-16
	pxor	xmm4,xmm4
	pxor	xmm5,xmm5
	movdqa	xmm0,XMMWORD[((-128))+r12]
	movdqa	xmm1,XMMWORD[((-112))+r12]
	movdqa	xmm2,XMMWORD[((-96))+r12]
	movdqa	xmm3,XMMWORD[((-80))+r12]
	pand	xmm0,XMMWORD[((-128))+rdx]
	pand	xmm1,XMMWORD[((-112))+rdx]
	por	xmm4,xmm0
	pand	xmm2,XMMWORD[((-96))+rdx]
	por	xmm5,xmm1
	pand	xmm3,XMMWORD[((-80))+rdx]
	por	xmm4,xmm2
	por	xmm5,xmm3
	movdqa	xmm0,XMMWORD[((-64))+r12]
	movdqa	xmm1,XMMWORD[((-48))+r12]
	movdqa	xmm2,XMMWORD[((-32))+r12]
	movdqa	xmm3,XMMWORD[((-16))+r12]
	pand	xmm0,XMMWORD[((-64))+rdx]
	pand	xmm1,XMMWORD[((-48))+rdx]
	por	xmm4,xmm0
	pand	xmm2,XMMWORD[((-32))+rdx]
	por	xmm5,xmm1
	pand	xmm3,XMMWORD[((-16))+rdx]
	por	xmm4,xmm2
	por	xmm5,xmm3
	movdqa	xmm0,XMMWORD[r12]
	movdqa	xmm1,XMMWORD[16+r12]
	movdqa	xmm2,XMMWORD[32+r12]
	movdqa	xmm3,XMMWORD[48+r12]
	pand	xmm0,XMMWORD[rdx]
	pand	xmm1,XMMWORD[16+rdx]
	por	xmm4,xmm0
	pand	xmm2,XMMWORD[32+rdx]
	por	xmm5,xmm1
	pand	xmm3,XMMWORD[48+rdx]
	por	xmm4,xmm2
	por	xmm5,xmm3
	movdqa	xmm0,XMMWORD[64+r12]
	movdqa	xmm1,XMMWORD[80+r12]
	movdqa	xmm2,XMMWORD[96+r12]
	movdqa	xmm3,XMMWORD[112+r12]
	pand	xmm0,XMMWORD[64+rdx]
	pand	xmm1,XMMWORD[80+rdx]
	por	xmm4,xmm0
	pand	xmm2,XMMWORD[96+rdx]
	por	xmm5,xmm1
	pand	xmm3,XMMWORD[112+rdx]
	por	xmm4,xmm2
	por	xmm5,xmm3
	por	xmm4,xmm5
	pshufd	xmm0,xmm4,0x4e
	por	xmm0,xmm4
	lea	r12,[256+r12]

	mov	rax,QWORD[rsi]
DB	102,72,15,126,195

	xor	r15,r15
	mov	rbp,r8
	mov	r10,QWORD[rsp]

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[rcx]
	adc	rdx,0

	imul	rbp,r10
	mov	r11,rdx

	mul	rbp
	add	r10,rax
	mov	rax,QWORD[8+rsi]
	adc	rdx,0
	mov	r10,QWORD[8+rsp]
	mov	r13,rdx

	lea	r15,[1+r15]
	jmp	NEAR $L$inner_enter

ALIGN	16
$L$inner:
	add	r13,rax
	mov	rax,QWORD[r15*8+rsi]
	adc	rdx,0
	add	r13,r10
	mov	r10,QWORD[r15*8+rsp]
	adc	rdx,0
	mov	QWORD[((-16))+r15*8+rsp],r13
	mov	r13,rdx

$L$inner_enter:
	mul	rbx
	add	r11,rax
	mov	rax,QWORD[r15*8+rcx]
	adc	rdx,0
	add	r10,r11
	mov	r11,rdx
	adc	r11,0
	lea	r15,[1+r15]

	mul	rbp
	cmp	r15,r9
	jne	NEAR $L$inner

	add	r13,rax
	adc	rdx,0
	add	r13,r10
	mov	r10,QWORD[r9*8+rsp]
	adc	rdx,0
	mov	QWORD[((-16))+r9*8+rsp],r13
	mov	r13,rdx

	xor	rdx,rdx
	add	r13,r11
	adc	rdx,0
	add	r13,r10
	adc	rdx,0
	mov	QWORD[((-8))+r9*8+rsp],r13
	mov	QWORD[r9*8+rsp],rdx

	lea	r14,[1+r14]
	cmp	r14,r9
	jb	NEAR $L$outer

	xor	r14,r14
	mov	rax,QWORD[rsp]
	lea	rsi,[rsp]
	mov	r15,r9
	jmp	NEAR $L$sub
ALIGN	16
$L$sub:	sbb	rax,QWORD[r14*8+rcx]
	mov	QWORD[r14*8+rdi],rax
	mov	rax,QWORD[8+r14*8+rsi]
	lea	r14,[1+r14]
	dec	r15
	jnz	NEAR $L$sub

	sbb	rax,0
	xor	r14,r14
	mov	r15,r9
ALIGN	16
$L$copy:
	mov	rsi,QWORD[r14*8+rsp]
	mov	rcx,QWORD[r14*8+rdi]
	xor	rsi,rcx
	and	rsi,rax
	xor	rsi,rcx
	mov	QWORD[r14*8+rsp],r14
	mov	QWORD[r14*8+rdi],rsi
	lea	r14,[1+r14]
	sub	r15,1
	jnz	NEAR $L$copy

	mov	rsi,QWORD[8+r9*8+rsp]
	mov	rax,1

	mov	r15,QWORD[((-48))+rsi]
	mov	r14,QWORD[((-40))+rsi]
	mov	r13,QWORD[((-32))+rsi]
	mov	r12,QWORD[((-24))+rsi]
	mov	rbp,QWORD[((-16))+rsi]
	mov	rbx,QWORD[((-8))+rsi]
	lea	rsp,[rsi]
$L$mul_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_bn_mul_mont_gather5:

ALIGN	32
bn_mul4x_mont_gather5:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_bn_mul4x_mont_gather5:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]
	mov	r9,QWORD[48+rsp]


$L$mul4x_enter:
DB	0x67
	mov	rax,rsp
	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15

DB	0x67
	shl	r9d,3
	lea	r10,[r9*2+r9]
	neg	r9










	lea	r11,[((-320))+r9*2+rsp]
	sub	r11,rdi
	and	r11,4095
	cmp	r10,r11
	jb	NEAR $L$mul4xsp_alt
	sub	rsp,r11
	lea	rsp,[((-320))+r9*2+rsp]
	jmp	NEAR $L$mul4xsp_done

ALIGN	32
$L$mul4xsp_alt:
	lea	r10,[((4096-320))+r9*2]
	lea	rsp,[((-320))+r9*2+rsp]
	sub	r11,r10
	mov	r10,0
	cmovc	r11,r10
	sub	rsp,r11
$L$mul4xsp_done:
	and	rsp,-64
	neg	r9

	mov	QWORD[40+rsp],rax
$L$mul4x_body:

	call	mul4x_internal

	mov	rsi,QWORD[40+rsp]
	mov	rax,1

	mov	r15,QWORD[((-48))+rsi]
	mov	r14,QWORD[((-40))+rsi]
	mov	r13,QWORD[((-32))+rsi]
	mov	r12,QWORD[((-24))+rsi]
	mov	rbp,QWORD[((-16))+rsi]
	mov	rbx,QWORD[((-8))+rsi]
	lea	rsp,[rsi]
$L$mul4x_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_bn_mul4x_mont_gather5:


ALIGN	32
mul4x_internal:
	shl	r9,5
	movd	xmm5,DWORD[56+rax]
	lea	rax,[$L$inc]
	lea	r13,[128+r9*1+rdx]
	shr	r9,5
	movdqa	xmm0,XMMWORD[rax]
	movdqa	xmm1,XMMWORD[16+rax]
	lea	r10,[((88-112))+r9*1+rsp]
	lea	r12,[128+rdx]

	pshufd	xmm5,xmm5,0
	movdqa	xmm4,xmm1
DB	0x67,0x67
	movdqa	xmm2,xmm1
	paddd	xmm1,xmm0
	pcmpeqd	xmm0,xmm5
DB	0x67
	movdqa	xmm3,xmm4
	paddd	xmm2,xmm1
	pcmpeqd	xmm1,xmm5
	movdqa	XMMWORD[112+r10],xmm0
	movdqa	xmm0,xmm4

	paddd	xmm3,xmm2
	pcmpeqd	xmm2,xmm5
	movdqa	XMMWORD[128+r10],xmm1
	movdqa	xmm1,xmm4

	paddd	xmm0,xmm3
	pcmpeqd	xmm3,xmm5
	movdqa	XMMWORD[144+r10],xmm2
	movdqa	xmm2,xmm4

	paddd	xmm1,xmm0
	pcmpeqd	xmm0,xmm5
	movdqa	XMMWORD[160+r10],xmm3
	movdqa	xmm3,xmm4
	paddd	xmm2,xmm1
	pcmpeqd	xmm1,xmm5
	movdqa	XMMWORD[176+r10],xmm0
	movdqa	xmm0,xmm4

	paddd	xmm3,xmm2
	pcmpeqd	xmm2,xmm5
	movdqa	XMMWORD[192+r10],xmm1
	movdqa	xmm1,xmm4

	paddd	xmm0,xmm3
	pcmpeqd	xmm3,xmm5
	movdqa	XMMWORD[208+r10],xmm2
	movdqa	xmm2,xmm4

	paddd	xmm1,xmm0
	pcmpeqd	xmm0,xmm5
	movdqa	XMMWORD[224+r10],xmm3
	movdqa	xmm3,xmm4
	paddd	xmm2,xmm1
	pcmpeqd	xmm1,xmm5
	movdqa	XMMWORD[240+r10],xmm0
	movdqa	xmm0,xmm4

	paddd	xmm3,xmm2
	pcmpeqd	xmm2,xmm5
	movdqa	XMMWORD[256+r10],xmm1
	movdqa	xmm1,xmm4

	paddd	xmm0,xmm3
	pcmpeqd	xmm3,xmm5
	movdqa	XMMWORD[272+r10],xmm2
	movdqa	xmm2,xmm4

	paddd	xmm1,xmm0
	pcmpeqd	xmm0,xmm5
	movdqa	XMMWORD[288+r10],xmm3
	movdqa	xmm3,xmm4
	paddd	xmm2,xmm1
	pcmpeqd	xmm1,xmm5
	movdqa	XMMWORD[304+r10],xmm0

	paddd	xmm3,xmm2
DB	0x67
	pcmpeqd	xmm2,xmm5
	movdqa	XMMWORD[320+r10],xmm1

	pcmpeqd	xmm3,xmm5
	movdqa	XMMWORD[336+r10],xmm2
	pand	xmm0,XMMWORD[64+r12]

	pand	xmm1,XMMWORD[80+r12]
	pand	xmm2,XMMWORD[96+r12]
	movdqa	XMMWORD[352+r10],xmm3
	pand	xmm3,XMMWORD[112+r12]
	por	xmm0,xmm2
	por	xmm1,xmm3
	movdqa	xmm4,XMMWORD[((-128))+r12]
	movdqa	xmm5,XMMWORD[((-112))+r12]
	movdqa	xmm2,XMMWORD[((-96))+r12]
	pand	xmm4,XMMWORD[112+r10]
	movdqa	xmm3,XMMWORD[((-80))+r12]
	pand	xmm5,XMMWORD[128+r10]
	por	xmm0,xmm4
	pand	xmm2,XMMWORD[144+r10]
	por	xmm1,xmm5
	pand	xmm3,XMMWORD[160+r10]
	por	xmm0,xmm2
	por	xmm1,xmm3
	movdqa	xmm4,XMMWORD[((-64))+r12]
	movdqa	xmm5,XMMWORD[((-48))+r12]
	movdqa	xmm2,XMMWORD[((-32))+r12]
	pand	xmm4,XMMWORD[176+r10]
	movdqa	xmm3,XMMWORD[((-16))+r12]
	pand	xmm5,XMMWORD[192+r10]
	por	xmm0,xmm4
	pand	xmm2,XMMWORD[208+r10]
	por	xmm1,xmm5
	pand	xmm3,XMMWORD[224+r10]
	por	xmm0,xmm2
	por	xmm1,xmm3
	movdqa	xmm4,XMMWORD[r12]
	movdqa	xmm5,XMMWORD[16+r12]
	movdqa	xmm2,XMMWORD[32+r12]
	pand	xmm4,XMMWORD[240+r10]
	movdqa	xmm3,XMMWORD[48+r12]
	pand	xmm5,XMMWORD[256+r10]
	por	xmm0,xmm4
	pand	xmm2,XMMWORD[272+r10]
	por	xmm1,xmm5
	pand	xmm3,XMMWORD[288+r10]
	por	xmm0,xmm2
	por	xmm1,xmm3
	por	xmm0,xmm1
	pshufd	xmm1,xmm0,0x4e
	por	xmm0,xmm1
	lea	r12,[256+r12]
DB	102,72,15,126,195

	mov	QWORD[((16+8))+rsp],r13
	mov	QWORD[((56+8))+rsp],rdi

	mov	r8,QWORD[r8]
	mov	rax,QWORD[rsi]
	lea	rsi,[r9*1+rsi]
	neg	r9

	mov	rbp,r8
	mul	rbx
	mov	r10,rax
	mov	rax,QWORD[rcx]

	imul	rbp,r10
	lea	r14,[((64+8))+rsp]
	mov	r11,rdx

	mul	rbp
	add	r10,rax
	mov	rax,QWORD[8+r9*1+rsi]
	adc	rdx,0
	mov	rdi,rdx

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[8+rcx]
	adc	rdx,0
	mov	r10,rdx

	mul	rbp
	add	rdi,rax
	mov	rax,QWORD[16+r9*1+rsi]
	adc	rdx,0
	add	rdi,r11
	lea	r15,[32+r9]
	lea	rcx,[32+rcx]
	adc	rdx,0
	mov	QWORD[r14],rdi
	mov	r13,rdx
	jmp	NEAR $L$1st4x

ALIGN	32
$L$1st4x:
	mul	rbx
	add	r10,rax
	mov	rax,QWORD[((-16))+rcx]
	lea	r14,[32+r14]
	adc	rdx,0
	mov	r11,rdx

	mul	rbp
	add	r13,rax
	mov	rax,QWORD[((-8))+r15*1+rsi]
	adc	rdx,0
	add	r13,r10
	adc	rdx,0
	mov	QWORD[((-24))+r14],r13
	mov	rdi,rdx

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[((-8))+rcx]
	adc	rdx,0
	mov	r10,rdx

	mul	rbp
	add	rdi,rax
	mov	rax,QWORD[r15*1+rsi]
	adc	rdx,0
	add	rdi,r11
	adc	rdx,0
	mov	QWORD[((-16))+r14],rdi
	mov	r13,rdx

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[rcx]
	adc	rdx,0
	mov	r11,rdx

	mul	rbp
	add	r13,rax
	mov	rax,QWORD[8+r15*1+rsi]
	adc	rdx,0
	add	r13,r10
	adc	rdx,0
	mov	QWORD[((-8))+r14],r13
	mov	rdi,rdx

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[8+rcx]
	adc	rdx,0
	mov	r10,rdx

	mul	rbp
	add	rdi,rax
	mov	rax,QWORD[16+r15*1+rsi]
	adc	rdx,0
	add	rdi,r11
	lea	rcx,[32+rcx]
	adc	rdx,0
	mov	QWORD[r14],rdi
	mov	r13,rdx

	add	r15,32
	jnz	NEAR $L$1st4x

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[((-16))+rcx]
	lea	r14,[32+r14]
	adc	rdx,0
	mov	r11,rdx

	mul	rbp
	add	r13,rax
	mov	rax,QWORD[((-8))+rsi]
	adc	rdx,0
	add	r13,r10
	adc	rdx,0
	mov	QWORD[((-24))+r14],r13
	mov	rdi,rdx

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[((-8))+rcx]
	adc	rdx,0
	mov	r10,rdx

	mul	rbp
	add	rdi,rax
	mov	rax,QWORD[r9*1+rsi]
	adc	rdx,0
	add	rdi,r11
	adc	rdx,0
	mov	QWORD[((-16))+r14],rdi
	mov	r13,rdx

	lea	rcx,[r9*1+rcx]

	xor	rdi,rdi
	add	r13,r10
	adc	rdi,0
	mov	QWORD[((-8))+r14],r13

	jmp	NEAR $L$outer4x

ALIGN	32
$L$outer4x:
	lea	rdx,[((16+128))+r14]
	pxor	xmm4,xmm4
	pxor	xmm5,xmm5
	movdqa	xmm0,XMMWORD[((-128))+r12]
	movdqa	xmm1,XMMWORD[((-112))+r12]
	movdqa	xmm2,XMMWORD[((-96))+r12]
	movdqa	xmm3,XMMWORD[((-80))+r12]
	pand	xmm0,XMMWORD[((-128))+rdx]
	pand	xmm1,XMMWORD[((-112))+rdx]
	por	xmm4,xmm0
	pand	xmm2,XMMWORD[((-96))+rdx]
	por	xmm5,xmm1
	pand	xmm3,XMMWORD[((-80))+rdx]
	por	xmm4,xmm2
	por	xmm5,xmm3
	movdqa	xmm0,XMMWORD[((-64))+r12]
	movdqa	xmm1,XMMWORD[((-48))+r12]
	movdqa	xmm2,XMMWORD[((-32))+r12]
	movdqa	xmm3,XMMWORD[((-16))+r12]
	pand	xmm0,XMMWORD[((-64))+rdx]
	pand	xmm1,XMMWORD[((-48))+rdx]
	por	xmm4,xmm0
	pand	xmm2,XMMWORD[((-32))+rdx]
	por	xmm5,xmm1
	pand	xmm3,XMMWORD[((-16))+rdx]
	por	xmm4,xmm2
	por	xmm5,xmm3
	movdqa	xmm0,XMMWORD[r12]
	movdqa	xmm1,XMMWORD[16+r12]
	movdqa	xmm2,XMMWORD[32+r12]
	movdqa	xmm3,XMMWORD[48+r12]
	pand	xmm0,XMMWORD[rdx]
	pand	xmm1,XMMWORD[16+rdx]
	por	xmm4,xmm0
	pand	xmm2,XMMWORD[32+rdx]
	por	xmm5,xmm1
	pand	xmm3,XMMWORD[48+rdx]
	por	xmm4,xmm2
	por	xmm5,xmm3
	movdqa	xmm0,XMMWORD[64+r12]
	movdqa	xmm1,XMMWORD[80+r12]
	movdqa	xmm2,XMMWORD[96+r12]
	movdqa	xmm3,XMMWORD[112+r12]
	pand	xmm0,XMMWORD[64+rdx]
	pand	xmm1,XMMWORD[80+rdx]
	por	xmm4,xmm0
	pand	xmm2,XMMWORD[96+rdx]
	por	xmm5,xmm1
	pand	xmm3,XMMWORD[112+rdx]
	por	xmm4,xmm2
	por	xmm5,xmm3
	por	xmm4,xmm5
	pshufd	xmm0,xmm4,0x4e
	por	xmm0,xmm4
	lea	r12,[256+r12]
DB	102,72,15,126,195

	mov	r10,QWORD[r9*1+r14]
	mov	rbp,r8
	mul	rbx
	add	r10,rax
	mov	rax,QWORD[rcx]
	adc	rdx,0

	imul	rbp,r10
	mov	r11,rdx
	mov	QWORD[r14],rdi

	lea	r14,[r9*1+r14]

	mul	rbp
	add	r10,rax
	mov	rax,QWORD[8+r9*1+rsi]
	adc	rdx,0
	mov	rdi,rdx

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[8+rcx]
	adc	rdx,0
	add	r11,QWORD[8+r14]
	adc	rdx,0
	mov	r10,rdx

	mul	rbp
	add	rdi,rax
	mov	rax,QWORD[16+r9*1+rsi]
	adc	rdx,0
	add	rdi,r11
	lea	r15,[32+r9]
	lea	rcx,[32+rcx]
	adc	rdx,0
	mov	r13,rdx
	jmp	NEAR $L$inner4x

ALIGN	32
$L$inner4x:
	mul	rbx
	add	r10,rax
	mov	rax,QWORD[((-16))+rcx]
	adc	rdx,0
	add	r10,QWORD[16+r14]
	lea	r14,[32+r14]
	adc	rdx,0
	mov	r11,rdx

	mul	rbp
	add	r13,rax
	mov	rax,QWORD[((-8))+r15*1+rsi]
	adc	rdx,0
	add	r13,r10
	adc	rdx,0
	mov	QWORD[((-32))+r14],rdi
	mov	rdi,rdx

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[((-8))+rcx]
	adc	rdx,0
	add	r11,QWORD[((-8))+r14]
	adc	rdx,0
	mov	r10,rdx

	mul	rbp
	add	rdi,rax
	mov	rax,QWORD[r15*1+rsi]
	adc	rdx,0
	add	rdi,r11
	adc	rdx,0
	mov	QWORD[((-24))+r14],r13
	mov	r13,rdx

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[rcx]
	adc	rdx,0
	add	r10,QWORD[r14]
	adc	rdx,0
	mov	r11,rdx

	mul	rbp
	add	r13,rax
	mov	rax,QWORD[8+r15*1+rsi]
	adc	rdx,0
	add	r13,r10
	adc	rdx,0
	mov	QWORD[((-16))+r14],rdi
	mov	rdi,rdx

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[8+rcx]
	adc	rdx,0
	add	r11,QWORD[8+r14]
	adc	rdx,0
	mov	r10,rdx

	mul	rbp
	add	rdi,rax
	mov	rax,QWORD[16+r15*1+rsi]
	adc	rdx,0
	add	rdi,r11
	lea	rcx,[32+rcx]
	adc	rdx,0
	mov	QWORD[((-8))+r14],r13
	mov	r13,rdx

	add	r15,32
	jnz	NEAR $L$inner4x

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[((-16))+rcx]
	adc	rdx,0
	add	r10,QWORD[16+r14]
	lea	r14,[32+r14]
	adc	rdx,0
	mov	r11,rdx

	mul	rbp
	add	r13,rax
	mov	rax,QWORD[((-8))+rsi]
	adc	rdx,0
	add	r13,r10
	adc	rdx,0
	mov	QWORD[((-32))+r14],rdi
	mov	rdi,rdx

	mul	rbx
	add	r11,rax
	mov	rax,rbp
	mov	rbp,QWORD[((-8))+rcx]
	adc	rdx,0
	add	r11,QWORD[((-8))+r14]
	adc	rdx,0
	mov	r10,rdx

	mul	rbp
	add	rdi,rax
	mov	rax,QWORD[r9*1+rsi]
	adc	rdx,0
	add	rdi,r11
	adc	rdx,0
	mov	QWORD[((-24))+r14],r13
	mov	r13,rdx

	mov	QWORD[((-16))+r14],rdi
	lea	rcx,[r9*1+rcx]

	xor	rdi,rdi
	add	r13,r10
	adc	rdi,0
	add	r13,QWORD[r14]
	adc	rdi,0
	mov	QWORD[((-8))+r14],r13

	cmp	r12,QWORD[((16+8))+rsp]
	jb	NEAR $L$outer4x
	xor	rax,rax
	sub	rbp,r13
	adc	r15,r15
	or	rdi,r15
	sub	rax,rdi
	lea	rbx,[r9*1+r14]
	mov	r12,QWORD[rcx]
	lea	rbp,[rcx]
	mov	rcx,r9
	sar	rcx,3+2
	mov	rdi,QWORD[((56+8))+rsp]
	dec	r12
	xor	r10,r10
	mov	r13,QWORD[8+rbp]
	mov	r14,QWORD[16+rbp]
	mov	r15,QWORD[24+rbp]
	jmp	NEAR $L$sqr4x_sub_entry

global	bn_power5

ALIGN	32
bn_power5:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_bn_power5:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]
	mov	r9,QWORD[48+rsp]


	mov	rax,rsp
	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15

	shl	r9d,3
	lea	r10d,[r9*2+r9]
	neg	r9
	mov	r8,QWORD[r8]








	lea	r11,[((-320))+r9*2+rsp]
	sub	r11,rdi
	and	r11,4095
	cmp	r10,r11
	jb	NEAR $L$pwr_sp_alt
	sub	rsp,r11
	lea	rsp,[((-320))+r9*2+rsp]
	jmp	NEAR $L$pwr_sp_done

ALIGN	32
$L$pwr_sp_alt:
	lea	r10,[((4096-320))+r9*2]
	lea	rsp,[((-320))+r9*2+rsp]
	sub	r11,r10
	mov	r10,0
	cmovc	r11,r10
	sub	rsp,r11
$L$pwr_sp_done:
	and	rsp,-64
	mov	r10,r9
	neg	r9










	mov	QWORD[32+rsp],r8
	mov	QWORD[40+rsp],rax
$L$power5_body:
DB	102,72,15,110,207
DB	102,72,15,110,209
DB	102,73,15,110,218
DB	102,72,15,110,226

	call	__bn_sqr8x_internal
	call	__bn_post4x_internal
	call	__bn_sqr8x_internal
	call	__bn_post4x_internal
	call	__bn_sqr8x_internal
	call	__bn_post4x_internal
	call	__bn_sqr8x_internal
	call	__bn_post4x_internal
	call	__bn_sqr8x_internal
	call	__bn_post4x_internal

DB	102,72,15,126,209
DB	102,72,15,126,226
	mov	rdi,rsi
	mov	rax,QWORD[40+rsp]
	lea	r8,[32+rsp]

	call	mul4x_internal

	mov	rsi,QWORD[40+rsp]
	mov	rax,1
	mov	r15,QWORD[((-48))+rsi]
	mov	r14,QWORD[((-40))+rsi]
	mov	r13,QWORD[((-32))+rsi]
	mov	r12,QWORD[((-24))+rsi]
	mov	rbp,QWORD[((-16))+rsi]
	mov	rbx,QWORD[((-8))+rsi]
	lea	rsp,[rsi]
$L$power5_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_bn_power5:

global	bn_sqr8x_internal


ALIGN	32
bn_sqr8x_internal:
__bn_sqr8x_internal:









































































	lea	rbp,[32+r10]
	lea	rsi,[r9*1+rsi]

	mov	rcx,r9


	mov	r14,QWORD[((-32))+rbp*1+rsi]
	lea	rdi,[((48+8))+r9*2+rsp]
	mov	rax,QWORD[((-24))+rbp*1+rsi]
	lea	rdi,[((-32))+rbp*1+rdi]
	mov	rbx,QWORD[((-16))+rbp*1+rsi]
	mov	r15,rax

	mul	r14
	mov	r10,rax
	mov	rax,rbx
	mov	r11,rdx
	mov	QWORD[((-24))+rbp*1+rdi],r10

	mul	r14
	add	r11,rax
	mov	rax,rbx
	adc	rdx,0
	mov	QWORD[((-16))+rbp*1+rdi],r11
	mov	r10,rdx


	mov	rbx,QWORD[((-8))+rbp*1+rsi]
	mul	r15
	mov	r12,rax
	mov	rax,rbx
	mov	r13,rdx

	lea	rcx,[rbp]
	mul	r14
	add	r10,rax
	mov	rax,rbx
	mov	r11,rdx
	adc	r11,0
	add	r10,r12
	adc	r11,0
	mov	QWORD[((-8))+rcx*1+rdi],r10
	jmp	NEAR $L$sqr4x_1st

ALIGN	32
$L$sqr4x_1st:
	mov	rbx,QWORD[rcx*1+rsi]
	mul	r15
	add	r13,rax
	mov	rax,rbx
	mov	r12,rdx
	adc	r12,0

	mul	r14
	add	r11,rax
	mov	rax,rbx
	mov	rbx,QWORD[8+rcx*1+rsi]
	mov	r10,rdx
	adc	r10,0
	add	r11,r13
	adc	r10,0


	mul	r15
	add	r12,rax
	mov	rax,rbx
	mov	QWORD[rcx*1+rdi],r11
	mov	r13,rdx
	adc	r13,0

	mul	r14
	add	r10,rax
	mov	rax,rbx
	mov	rbx,QWORD[16+rcx*1+rsi]
	mov	r11,rdx
	adc	r11,0
	add	r10,r12
	adc	r11,0

	mul	r15
	add	r13,rax
	mov	rax,rbx
	mov	QWORD[8+rcx*1+rdi],r10
	mov	r12,rdx
	adc	r12,0

	mul	r14
	add	r11,rax
	mov	rax,rbx
	mov	rbx,QWORD[24+rcx*1+rsi]
	mov	r10,rdx
	adc	r10,0
	add	r11,r13
	adc	r10,0


	mul	r15
	add	r12,rax
	mov	rax,rbx
	mov	QWORD[16+rcx*1+rdi],r11
	mov	r13,rdx
	adc	r13,0
	lea	rcx,[32+rcx]

	mul	r14
	add	r10,rax
	mov	rax,rbx
	mov	r11,rdx
	adc	r11,0
	add	r10,r12
	adc	r11,0
	mov	QWORD[((-8))+rcx*1+rdi],r10

	cmp	rcx,0
	jne	NEAR $L$sqr4x_1st

	mul	r15
	add	r13,rax
	lea	rbp,[16+rbp]
	adc	rdx,0
	add	r13,r11
	adc	rdx,0

	mov	QWORD[rdi],r13
	mov	r12,rdx
	mov	QWORD[8+rdi],rdx
	jmp	NEAR $L$sqr4x_outer

ALIGN	32
$L$sqr4x_outer:
	mov	r14,QWORD[((-32))+rbp*1+rsi]
	lea	rdi,[((48+8))+r9*2+rsp]
	mov	rax,QWORD[((-24))+rbp*1+rsi]
	lea	rdi,[((-32))+rbp*1+rdi]
	mov	rbx,QWORD[((-16))+rbp*1+rsi]
	mov	r15,rax

	mul	r14
	mov	r10,QWORD[((-24))+rbp*1+rdi]
	add	r10,rax
	mov	rax,rbx
	adc	rdx,0
	mov	QWORD[((-24))+rbp*1+rdi],r10
	mov	r11,rdx

	mul	r14
	add	r11,rax
	mov	rax,rbx
	adc	rdx,0
	add	r11,QWORD[((-16))+rbp*1+rdi]
	mov	r10,rdx
	adc	r10,0
	mov	QWORD[((-16))+rbp*1+rdi],r11

	xor	r12,r12

	mov	rbx,QWORD[((-8))+rbp*1+rsi]
	mul	r15
	add	r12,rax
	mov	rax,rbx
	adc	rdx,0
	add	r12,QWORD[((-8))+rbp*1+rdi]
	mov	r13,rdx
	adc	r13,0

	mul	r14
	add	r10,rax
	mov	rax,rbx
	adc	rdx,0
	add	r10,r12
	mov	r11,rdx
	adc	r11,0
	mov	QWORD[((-8))+rbp*1+rdi],r10

	lea	rcx,[rbp]
	jmp	NEAR $L$sqr4x_inner

ALIGN	32
$L$sqr4x_inner:
	mov	rbx,QWORD[rcx*1+rsi]
	mul	r15
	add	r13,rax
	mov	rax,rbx
	mov	r12,rdx
	adc	r12,0
	add	r13,QWORD[rcx*1+rdi]
	adc	r12,0

DB	0x67
	mul	r14
	add	r11,rax
	mov	rax,rbx
	mov	rbx,QWORD[8+rcx*1+rsi]
	mov	r10,rdx
	adc	r10,0
	add	r11,r13
	adc	r10,0

	mul	r15
	add	r12,rax
	mov	QWORD[rcx*1+rdi],r11
	mov	rax,rbx
	mov	r13,rdx
	adc	r13,0
	add	r12,QWORD[8+rcx*1+rdi]
	lea	rcx,[16+rcx]
	adc	r13,0

	mul	r14
	add	r10,rax
	mov	rax,rbx
	adc	rdx,0
	add	r10,r12
	mov	r11,rdx
	adc	r11,0
	mov	QWORD[((-8))+rcx*1+rdi],r10

	cmp	rcx,0
	jne	NEAR $L$sqr4x_inner

DB	0x67
	mul	r15
	add	r13,rax
	adc	rdx,0
	add	r13,r11
	adc	rdx,0

	mov	QWORD[rdi],r13
	mov	r12,rdx
	mov	QWORD[8+rdi],rdx

	add	rbp,16
	jnz	NEAR $L$sqr4x_outer


	mov	r14,QWORD[((-32))+rsi]
	lea	rdi,[((48+8))+r9*2+rsp]
	mov	rax,QWORD[((-24))+rsi]
	lea	rdi,[((-32))+rbp*1+rdi]
	mov	rbx,QWORD[((-16))+rsi]
	mov	r15,rax

	mul	r14
	add	r10,rax
	mov	rax,rbx
	mov	r11,rdx
	adc	r11,0

	mul	r14
	add	r11,rax
	mov	rax,rbx
	mov	QWORD[((-24))+rdi],r10
	mov	r10,rdx
	adc	r10,0
	add	r11,r13
	mov	rbx,QWORD[((-8))+rsi]
	adc	r10,0

	mul	r15
	add	r12,rax
	mov	rax,rbx
	mov	QWORD[((-16))+rdi],r11
	mov	r13,rdx
	adc	r13,0

	mul	r14
	add	r10,rax
	mov	rax,rbx
	mov	r11,rdx
	adc	r11,0
	add	r10,r12
	adc	r11,0
	mov	QWORD[((-8))+rdi],r10

	mul	r15
	add	r13,rax
	mov	rax,QWORD[((-16))+rsi]
	adc	rdx,0
	add	r13,r11
	adc	rdx,0

	mov	QWORD[rdi],r13
	mov	r12,rdx
	mov	QWORD[8+rdi],rdx

	mul	rbx
	add	rbp,16
	xor	r14,r14
	sub	rbp,r9
	xor	r15,r15

	add	rax,r12
	adc	rdx,0
	mov	QWORD[8+rdi],rax
	mov	QWORD[16+rdi],rdx
	mov	QWORD[24+rdi],r15

	mov	rax,QWORD[((-16))+rbp*1+rsi]
	lea	rdi,[((48+8))+rsp]
	xor	r10,r10
	mov	r11,QWORD[8+rdi]

	lea	r12,[r10*2+r14]
	shr	r10,63
	lea	r13,[r11*2+rcx]
	shr	r11,63
	or	r13,r10
	mov	r10,QWORD[16+rdi]
	mov	r14,r11
	mul	rax
	neg	r15
	mov	r11,QWORD[24+rdi]
	adc	r12,rax
	mov	rax,QWORD[((-8))+rbp*1+rsi]
	mov	QWORD[rdi],r12
	adc	r13,rdx

	lea	rbx,[r10*2+r14]
	mov	QWORD[8+rdi],r13
	sbb	r15,r15
	shr	r10,63
	lea	r8,[r11*2+rcx]
	shr	r11,63
	or	r8,r10
	mov	r10,QWORD[32+rdi]
	mov	r14,r11
	mul	rax
	neg	r15
	mov	r11,QWORD[40+rdi]
	adc	rbx,rax
	mov	rax,QWORD[rbp*1+rsi]
	mov	QWORD[16+rdi],rbx
	adc	r8,rdx
	lea	rbp,[16+rbp]
	mov	QWORD[24+rdi],r8
	sbb	r15,r15
	lea	rdi,[64+rdi]
	jmp	NEAR $L$sqr4x_shift_n_add

ALIGN	32
$L$sqr4x_shift_n_add:
	lea	r12,[r10*2+r14]
	shr	r10,63
	lea	r13,[r11*2+rcx]
	shr	r11,63
	or	r13,r10
	mov	r10,QWORD[((-16))+rdi]
	mov	r14,r11
	mul	rax
	neg	r15
	mov	r11,QWORD[((-8))+rdi]
	adc	r12,rax
	mov	rax,QWORD[((-8))+rbp*1+rsi]
	mov	QWORD[((-32))+rdi],r12
	adc	r13,rdx

	lea	rbx,[r10*2+r14]
	mov	QWORD[((-24))+rdi],r13
	sbb	r15,r15
	shr	r10,63
	lea	r8,[r11*2+rcx]
	shr	r11,63
	or	r8,r10
	mov	r10,QWORD[rdi]
	mov	r14,r11
	mul	rax
	neg	r15
	mov	r11,QWORD[8+rdi]
	adc	rbx,rax
	mov	rax,QWORD[rbp*1+rsi]
	mov	QWORD[((-16))+rdi],rbx
	adc	r8,rdx

	lea	r12,[r10*2+r14]
	mov	QWORD[((-8))+rdi],r8
	sbb	r15,r15
	shr	r10,63
	lea	r13,[r11*2+rcx]
	shr	r11,63
	or	r13,r10
	mov	r10,QWORD[16+rdi]
	mov	r14,r11
	mul	rax
	neg	r15
	mov	r11,QWORD[24+rdi]
	adc	r12,rax
	mov	rax,QWORD[8+rbp*1+rsi]
	mov	QWORD[rdi],r12
	adc	r13,rdx

	lea	rbx,[r10*2+r14]
	mov	QWORD[8+rdi],r13
	sbb	r15,r15
	shr	r10,63
	lea	r8,[r11*2+rcx]
	shr	r11,63
	or	r8,r10
	mov	r10,QWORD[32+rdi]
	mov	r14,r11
	mul	rax
	neg	r15
	mov	r11,QWORD[40+rdi]
	adc	rbx,rax
	mov	rax,QWORD[16+rbp*1+rsi]
	mov	QWORD[16+rdi],rbx
	adc	r8,rdx
	mov	QWORD[24+rdi],r8
	sbb	r15,r15
	lea	rdi,[64+rdi]
	add	rbp,32
	jnz	NEAR $L$sqr4x_shift_n_add

	lea	r12,[r10*2+r14]
DB	0x67
	shr	r10,63
	lea	r13,[r11*2+rcx]
	shr	r11,63
	or	r13,r10
	mov	r10,QWORD[((-16))+rdi]
	mov	r14,r11
	mul	rax
	neg	r15
	mov	r11,QWORD[((-8))+rdi]
	adc	r12,rax
	mov	rax,QWORD[((-8))+rsi]
	mov	QWORD[((-32))+rdi],r12
	adc	r13,rdx

	lea	rbx,[r10*2+r14]
	mov	QWORD[((-24))+rdi],r13
	sbb	r15,r15
	shr	r10,63
	lea	r8,[r11*2+rcx]
	shr	r11,63
	or	r8,r10
	mul	rax
	neg	r15
	adc	rbx,rax
	adc	r8,rdx
	mov	QWORD[((-16))+rdi],rbx
	mov	QWORD[((-8))+rdi],r8
DB	102,72,15,126,213
__bn_sqr8x_reduction:
	xor	rax,rax
	lea	rcx,[rbp*1+r9]
	lea	rdx,[((48+8))+r9*2+rsp]
	mov	QWORD[((0+8))+rsp],rcx
	lea	rdi,[((48+8))+r9*1+rsp]
	mov	QWORD[((8+8))+rsp],rdx
	neg	r9
	jmp	NEAR $L$8x_reduction_loop

ALIGN	32
$L$8x_reduction_loop:
	lea	rdi,[r9*1+rdi]
DB	0x66
	mov	rbx,QWORD[rdi]
	mov	r9,QWORD[8+rdi]
	mov	r10,QWORD[16+rdi]
	mov	r11,QWORD[24+rdi]
	mov	r12,QWORD[32+rdi]
	mov	r13,QWORD[40+rdi]
	mov	r14,QWORD[48+rdi]
	mov	r15,QWORD[56+rdi]
	mov	QWORD[rdx],rax
	lea	rdi,[64+rdi]

DB	0x67
	mov	r8,rbx
	imul	rbx,QWORD[((32+8))+rsp]
	mov	rax,QWORD[rbp]
	mov	ecx,8
	jmp	NEAR $L$8x_reduce

ALIGN	32
$L$8x_reduce:
	mul	rbx
	mov	rax,QWORD[8+rbp]
	neg	r8
	mov	r8,rdx
	adc	r8,0

	mul	rbx
	add	r9,rax
	mov	rax,QWORD[16+rbp]
	adc	rdx,0
	add	r8,r9
	mov	QWORD[((48-8+8))+rcx*8+rsp],rbx
	mov	r9,rdx
	adc	r9,0

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[24+rbp]
	adc	rdx,0
	add	r9,r10
	mov	rsi,QWORD[((32+8))+rsp]
	mov	r10,rdx
	adc	r10,0

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[32+rbp]
	adc	rdx,0
	imul	rsi,r8
	add	r10,r11
	mov	r11,rdx
	adc	r11,0

	mul	rbx
	add	r12,rax
	mov	rax,QWORD[40+rbp]
	adc	rdx,0
	add	r11,r12
	mov	r12,rdx
	adc	r12,0

	mul	rbx
	add	r13,rax
	mov	rax,QWORD[48+rbp]
	adc	rdx,0
	add	r12,r13
	mov	r13,rdx
	adc	r13,0

	mul	rbx
	add	r14,rax
	mov	rax,QWORD[56+rbp]
	adc	rdx,0
	add	r13,r14
	mov	r14,rdx
	adc	r14,0

	mul	rbx
	mov	rbx,rsi
	add	r15,rax
	mov	rax,QWORD[rbp]
	adc	rdx,0
	add	r14,r15
	mov	r15,rdx
	adc	r15,0

	dec	ecx
	jnz	NEAR $L$8x_reduce

	lea	rbp,[64+rbp]
	xor	rax,rax
	mov	rdx,QWORD[((8+8))+rsp]
	cmp	rbp,QWORD[((0+8))+rsp]
	jae	NEAR $L$8x_no_tail

DB	0x66
	add	r8,QWORD[rdi]
	adc	r9,QWORD[8+rdi]
	adc	r10,QWORD[16+rdi]
	adc	r11,QWORD[24+rdi]
	adc	r12,QWORD[32+rdi]
	adc	r13,QWORD[40+rdi]
	adc	r14,QWORD[48+rdi]
	adc	r15,QWORD[56+rdi]
	sbb	rsi,rsi

	mov	rbx,QWORD[((48+56+8))+rsp]
	mov	ecx,8
	mov	rax,QWORD[rbp]
	jmp	NEAR $L$8x_tail

ALIGN	32
$L$8x_tail:
	mul	rbx
	add	r8,rax
	mov	rax,QWORD[8+rbp]
	mov	QWORD[rdi],r8
	mov	r8,rdx
	adc	r8,0

	mul	rbx
	add	r9,rax
	mov	rax,QWORD[16+rbp]
	adc	rdx,0
	add	r8,r9
	lea	rdi,[8+rdi]
	mov	r9,rdx
	adc	r9,0

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[24+rbp]
	adc	rdx,0
	add	r9,r10
	mov	r10,rdx
	adc	r10,0

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[32+rbp]
	adc	rdx,0
	add	r10,r11
	mov	r11,rdx
	adc	r11,0

	mul	rbx
	add	r12,rax
	mov	rax,QWORD[40+rbp]
	adc	rdx,0
	add	r11,r12
	mov	r12,rdx
	adc	r12,0

	mul	rbx
	add	r13,rax
	mov	rax,QWORD[48+rbp]
	adc	rdx,0
	add	r12,r13
	mov	r13,rdx
	adc	r13,0

	mul	rbx
	add	r14,rax
	mov	rax,QWORD[56+rbp]
	adc	rdx,0
	add	r13,r14
	mov	r14,rdx
	adc	r14,0

	mul	rbx
	mov	rbx,QWORD[((48-16+8))+rcx*8+rsp]
	add	r15,rax
	adc	rdx,0
	add	r14,r15
	mov	rax,QWORD[rbp]
	mov	r15,rdx
	adc	r15,0

	dec	ecx
	jnz	NEAR $L$8x_tail

	lea	rbp,[64+rbp]
	mov	rdx,QWORD[((8+8))+rsp]
	cmp	rbp,QWORD[((0+8))+rsp]
	jae	NEAR $L$8x_tail_done

	mov	rbx,QWORD[((48+56+8))+rsp]
	neg	rsi
	mov	rax,QWORD[rbp]
	adc	r8,QWORD[rdi]
	adc	r9,QWORD[8+rdi]
	adc	r10,QWORD[16+rdi]
	adc	r11,QWORD[24+rdi]
	adc	r12,QWORD[32+rdi]
	adc	r13,QWORD[40+rdi]
	adc	r14,QWORD[48+rdi]
	adc	r15,QWORD[56+rdi]
	sbb	rsi,rsi

	mov	ecx,8
	jmp	NEAR $L$8x_tail

ALIGN	32
$L$8x_tail_done:
	add	r8,QWORD[rdx]
	adc	r9,0
	adc	r10,0
	adc	r11,0
	adc	r12,0
	adc	r13,0
	adc	r14,0
	adc	r15,0


	xor	rax,rax

	neg	rsi
$L$8x_no_tail:
	adc	r8,QWORD[rdi]
	adc	r9,QWORD[8+rdi]
	adc	r10,QWORD[16+rdi]
	adc	r11,QWORD[24+rdi]
	adc	r12,QWORD[32+rdi]
	adc	r13,QWORD[40+rdi]
	adc	r14,QWORD[48+rdi]
	adc	r15,QWORD[56+rdi]
	adc	rax,0
	mov	rcx,QWORD[((-8))+rbp]
	xor	rsi,rsi

DB	102,72,15,126,213

	mov	QWORD[rdi],r8
	mov	QWORD[8+rdi],r9
DB	102,73,15,126,217
	mov	QWORD[16+rdi],r10
	mov	QWORD[24+rdi],r11
	mov	QWORD[32+rdi],r12
	mov	QWORD[40+rdi],r13
	mov	QWORD[48+rdi],r14
	mov	QWORD[56+rdi],r15
	lea	rdi,[64+rdi]

	cmp	rdi,rdx
	jb	NEAR $L$8x_reduction_loop
	DB	0F3h,0C3h		;repret


ALIGN	32
__bn_post4x_internal:
	mov	r12,QWORD[rbp]
	lea	rbx,[r9*1+rdi]
	mov	rcx,r9
DB	102,72,15,126,207
	neg	rax
DB	102,72,15,126,206
	sar	rcx,3+2
	dec	r12
	xor	r10,r10
	mov	r13,QWORD[8+rbp]
	mov	r14,QWORD[16+rbp]
	mov	r15,QWORD[24+rbp]
	jmp	NEAR $L$sqr4x_sub_entry

ALIGN	16
$L$sqr4x_sub:
	mov	r12,QWORD[rbp]
	mov	r13,QWORD[8+rbp]
	mov	r14,QWORD[16+rbp]
	mov	r15,QWORD[24+rbp]
$L$sqr4x_sub_entry:
	lea	rbp,[32+rbp]
	not	r12
	not	r13
	not	r14
	not	r15
	and	r12,rax
	and	r13,rax
	and	r14,rax
	and	r15,rax

	neg	r10
	adc	r12,QWORD[rbx]
	adc	r13,QWORD[8+rbx]
	adc	r14,QWORD[16+rbx]
	adc	r15,QWORD[24+rbx]
	mov	QWORD[rdi],r12
	lea	rbx,[32+rbx]
	mov	QWORD[8+rdi],r13
	sbb	r10,r10
	mov	QWORD[16+rdi],r14
	mov	QWORD[24+rdi],r15
	lea	rdi,[32+rdi]

	inc	rcx
	jnz	NEAR $L$sqr4x_sub

	mov	r10,r9
	neg	r9
	DB	0F3h,0C3h		;repret

global	bn_from_montgomery

ALIGN	32
bn_from_montgomery:
	test	DWORD[48+rsp],7
	jz	NEAR bn_from_mont8x
	xor	eax,eax
	DB	0F3h,0C3h		;repret



ALIGN	32
bn_from_mont8x:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_bn_from_mont8x:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]
	mov	r9,QWORD[48+rsp]


DB	0x67
	mov	rax,rsp
	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15

	shl	r9d,3
	lea	r10,[r9*2+r9]
	neg	r9
	mov	r8,QWORD[r8]








	lea	r11,[((-320))+r9*2+rsp]
	sub	r11,rdi
	and	r11,4095
	cmp	r10,r11
	jb	NEAR $L$from_sp_alt
	sub	rsp,r11
	lea	rsp,[((-320))+r9*2+rsp]
	jmp	NEAR $L$from_sp_done

ALIGN	32
$L$from_sp_alt:
	lea	r10,[((4096-320))+r9*2]
	lea	rsp,[((-320))+r9*2+rsp]
	sub	r11,r10
	mov	r10,0
	cmovc	r11,r10
	sub	rsp,r11
$L$from_sp_done:
	and	rsp,-64
	mov	r10,r9
	neg	r9










	mov	QWORD[32+rsp],r8
	mov	QWORD[40+rsp],rax
$L$from_body:
	mov	r11,r9
	lea	rax,[48+rsp]
	pxor	xmm0,xmm0
	jmp	NEAR $L$mul_by_1

ALIGN	32
$L$mul_by_1:
	movdqu	xmm1,XMMWORD[rsi]
	movdqu	xmm2,XMMWORD[16+rsi]
	movdqu	xmm3,XMMWORD[32+rsi]
	movdqa	XMMWORD[r9*1+rax],xmm0
	movdqu	xmm4,XMMWORD[48+rsi]
	movdqa	XMMWORD[16+r9*1+rax],xmm0
DB	0x48,0x8d,0xb6,0x40,0x00,0x00,0x00
	movdqa	XMMWORD[rax],xmm1
	movdqa	XMMWORD[32+r9*1+rax],xmm0
	movdqa	XMMWORD[16+rax],xmm2
	movdqa	XMMWORD[48+r9*1+rax],xmm0
	movdqa	XMMWORD[32+rax],xmm3
	movdqa	XMMWORD[48+rax],xmm4
	lea	rax,[64+rax]
	sub	r11,64
	jnz	NEAR $L$mul_by_1

DB	102,72,15,110,207
DB	102,72,15,110,209
DB	0x67
	mov	rbp,rcx
DB	102,73,15,110,218
	call	__bn_sqr8x_reduction
	call	__bn_post4x_internal

	pxor	xmm0,xmm0
	lea	rax,[48+rsp]
	mov	rsi,QWORD[40+rsp]
	jmp	NEAR $L$from_mont_zero

ALIGN	32
$L$from_mont_zero:
	movdqa	XMMWORD[rax],xmm0
	movdqa	XMMWORD[16+rax],xmm0
	movdqa	XMMWORD[32+rax],xmm0
	movdqa	XMMWORD[48+rax],xmm0
	lea	rax,[64+rax]
	sub	r9,32
	jnz	NEAR $L$from_mont_zero

	mov	rax,1
	mov	r15,QWORD[((-48))+rsi]
	mov	r14,QWORD[((-40))+rsi]
	mov	r13,QWORD[((-32))+rsi]
	mov	r12,QWORD[((-24))+rsi]
	mov	rbp,QWORD[((-16))+rsi]
	mov	rbx,QWORD[((-8))+rsi]
	lea	rsp,[rsi]
$L$from_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_bn_from_mont8x:
global	bn_scatter5

ALIGN	16
bn_scatter5:
	cmp	edx,0
	jz	NEAR $L$scatter_epilogue
	lea	r8,[r9*8+r8]
$L$scatter:
	mov	rax,QWORD[rcx]
	lea	rcx,[8+rcx]
	mov	QWORD[r8],rax
	lea	r8,[256+r8]
	sub	edx,1
	jnz	NEAR $L$scatter
$L$scatter_epilogue:
	DB	0F3h,0C3h		;repret


global	bn_gather5

ALIGN	32
bn_gather5:
$L$SEH_begin_bn_gather5:

DB	0x4c,0x8d,0x14,0x24
DB	0x48,0x81,0xec,0x08,0x01,0x00,0x00
	lea	rax,[$L$inc]
	and	rsp,-16

	movd	xmm5,r9d
	movdqa	xmm0,XMMWORD[rax]
	movdqa	xmm1,XMMWORD[16+rax]
	lea	r11,[128+r8]
	lea	rax,[128+rsp]

	pshufd	xmm5,xmm5,0
	movdqa	xmm4,xmm1
	movdqa	xmm2,xmm1
	paddd	xmm1,xmm0
	pcmpeqd	xmm0,xmm5
	movdqa	xmm3,xmm4

	paddd	xmm2,xmm1
	pcmpeqd	xmm1,xmm5
	movdqa	XMMWORD[(-128)+rax],xmm0
	movdqa	xmm0,xmm4

	paddd	xmm3,xmm2
	pcmpeqd	xmm2,xmm5
	movdqa	XMMWORD[(-112)+rax],xmm1
	movdqa	xmm1,xmm4

	paddd	xmm0,xmm3
	pcmpeqd	xmm3,xmm5
	movdqa	XMMWORD[(-96)+rax],xmm2
	movdqa	xmm2,xmm4
	paddd	xmm1,xmm0
	pcmpeqd	xmm0,xmm5
	movdqa	XMMWORD[(-80)+rax],xmm3
	movdqa	xmm3,xmm4

	paddd	xmm2,xmm1
	pcmpeqd	xmm1,xmm5
	movdqa	XMMWORD[(-64)+rax],xmm0
	movdqa	xmm0,xmm4

	paddd	xmm3,xmm2
	pcmpeqd	xmm2,xmm5
	movdqa	XMMWORD[(-48)+rax],xmm1
	movdqa	xmm1,xmm4

	paddd	xmm0,xmm3
	pcmpeqd	xmm3,xmm5
	movdqa	XMMWORD[(-32)+rax],xmm2
	movdqa	xmm2,xmm4
	paddd	xmm1,xmm0
	pcmpeqd	xmm0,xmm5
	movdqa	XMMWORD[(-16)+rax],xmm3
	movdqa	xmm3,xmm4

	paddd	xmm2,xmm1
	pcmpeqd	xmm1,xmm5
	movdqa	XMMWORD[rax],xmm0
	movdqa	xmm0,xmm4

	paddd	xmm3,xmm2
	pcmpeqd	xmm2,xmm5
	movdqa	XMMWORD[16+rax],xmm1
	movdqa	xmm1,xmm4

	paddd	xmm0,xmm3
	pcmpeqd	xmm3,xmm5
	movdqa	XMMWORD[32+rax],xmm2
	movdqa	xmm2,xmm4
	paddd	xmm1,xmm0
	pcmpeqd	xmm0,xmm5
	movdqa	XMMWORD[48+rax],xmm3
	movdqa	xmm3,xmm4

	paddd	xmm2,xmm1
	pcmpeqd	xmm1,xmm5
	movdqa	XMMWORD[64+rax],xmm0
	movdqa	xmm0,xmm4

	paddd	xmm3,xmm2
	pcmpeqd	xmm2,xmm5
	movdqa	XMMWORD[80+rax],xmm1
	movdqa	xmm1,xmm4

	paddd	xmm0,xmm3
	pcmpeqd	xmm3,xmm5
	movdqa	XMMWORD[96+rax],xmm2
	movdqa	xmm2,xmm4
	movdqa	XMMWORD[112+rax],xmm3
	jmp	NEAR $L$gather

ALIGN	32
$L$gather:
	pxor	xmm4,xmm4
	pxor	xmm5,xmm5
	movdqa	xmm0,XMMWORD[((-128))+r11]
	movdqa	xmm1,XMMWORD[((-112))+r11]
	movdqa	xmm2,XMMWORD[((-96))+r11]
	pand	xmm0,XMMWORD[((-128))+rax]
	movdqa	xmm3,XMMWORD[((-80))+r11]
	pand	xmm1,XMMWORD[((-112))+rax]
	por	xmm4,xmm0
	pand	xmm2,XMMWORD[((-96))+rax]
	por	xmm5,xmm1
	pand	xmm3,XMMWORD[((-80))+rax]
	por	xmm4,xmm2
	por	xmm5,xmm3
	movdqa	xmm0,XMMWORD[((-64))+r11]
	movdqa	xmm1,XMMWORD[((-48))+r11]
	movdqa	xmm2,XMMWORD[((-32))+r11]
	pand	xmm0,XMMWORD[((-64))+rax]
	movdqa	xmm3,XMMWORD[((-16))+r11]
	pand	xmm1,XMMWORD[((-48))+rax]
	por	xmm4,xmm0
	pand	xmm2,XMMWORD[((-32))+rax]
	por	xmm5,xmm1
	pand	xmm3,XMMWORD[((-16))+rax]
	por	xmm4,xmm2
	por	xmm5,xmm3
	movdqa	xmm0,XMMWORD[r11]
	movdqa	xmm1,XMMWORD[16+r11]
	movdqa	xmm2,XMMWORD[32+r11]
	pand	xmm0,XMMWORD[rax]
	movdqa	xmm3,XMMWORD[48+r11]
	pand	xmm1,XMMWORD[16+rax]
	por	xmm4,xmm0
	pand	xmm2,XMMWORD[32+rax]
	por	xmm5,xmm1
	pand	xmm3,XMMWORD[48+rax]
	por	xmm4,xmm2
	por	xmm5,xmm3
	movdqa	xmm0,XMMWORD[64+r11]
	movdqa	xmm1,XMMWORD[80+r11]
	movdqa	xmm2,XMMWORD[96+r11]
	pand	xmm0,XMMWORD[64+rax]
	movdqa	xmm3,XMMWORD[112+r11]
	pand	xmm1,XMMWORD[80+rax]
	por	xmm4,xmm0
	pand	xmm2,XMMWORD[96+rax]
	por	xmm5,xmm1
	pand	xmm3,XMMWORD[112+rax]
	por	xmm4,xmm2
	por	xmm5,xmm3
	por	xmm4,xmm5
	lea	r11,[256+r11]
	pshufd	xmm0,xmm4,0x4e
	por	xmm0,xmm4
	movq	QWORD[rcx],xmm0
	lea	rcx,[8+rcx]
	sub	edx,1
	jnz	NEAR $L$gather

	lea	rsp,[r10]
	DB	0F3h,0C3h		;repret
$L$SEH_end_bn_gather5:

ALIGN	64
$L$inc:
	DD	0,0,1,1
	DD	2,2,2,2
DB	77,111,110,116,103,111,109,101,114,121,32,77,117,108,116,105
DB	112,108,105,99,97,116,105,111,110,32,119,105,116,104,32,115
DB	99,97,116,116,101,114,47,103,97,116,104,101,114,32,102,111
DB	114,32,120,56,54,95,54,52,44,32,67,82,89,80,84,79
DB	71,65,77,83,32,98,121,32,60,97,112,112,114,111,64,111
DB	112,101,110,115,115,108,46,111,114,103,62,0
EXTERN	__imp_RtlVirtualUnwind

ALIGN	16
mul_handler:
	push	rsi
	push	rdi
	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15
	pushfq
	sub	rsp,64

	mov	rax,QWORD[120+r8]
	mov	rbx,QWORD[248+r8]

	mov	rsi,QWORD[8+r9]
	mov	r11,QWORD[56+r9]

	mov	r10d,DWORD[r11]
	lea	r10,[r10*1+rsi]
	cmp	rbx,r10
	jb	NEAR $L$common_seh_tail

	mov	rax,QWORD[152+r8]

	mov	r10d,DWORD[4+r11]
	lea	r10,[r10*1+rsi]
	cmp	rbx,r10
	jae	NEAR $L$common_seh_tail

	lea	r10,[$L$mul_epilogue]
	cmp	rbx,r10
	ja	NEAR $L$body_40

	mov	r10,QWORD[192+r8]
	mov	rax,QWORD[8+r10*8+rax]

	jmp	NEAR $L$body_proceed

$L$body_40:
	mov	rax,QWORD[40+rax]
$L$body_proceed:
	mov	rbx,QWORD[((-8))+rax]
	mov	rbp,QWORD[((-16))+rax]
	mov	r12,QWORD[((-24))+rax]
	mov	r13,QWORD[((-32))+rax]
	mov	r14,QWORD[((-40))+rax]
	mov	r15,QWORD[((-48))+rax]
	mov	QWORD[144+r8],rbx
	mov	QWORD[160+r8],rbp
	mov	QWORD[216+r8],r12
	mov	QWORD[224+r8],r13
	mov	QWORD[232+r8],r14
	mov	QWORD[240+r8],r15

$L$common_seh_tail:
	mov	rdi,QWORD[8+rax]
	mov	rsi,QWORD[16+rax]
	mov	QWORD[152+r8],rax
	mov	QWORD[168+r8],rsi
	mov	QWORD[176+r8],rdi

	mov	rdi,QWORD[40+r9]
	mov	rsi,r8
	mov	ecx,154
	DD	0xa548f3fc

	mov	rsi,r9
	xor	rcx,rcx
	mov	rdx,QWORD[8+rsi]
	mov	r8,QWORD[rsi]
	mov	r9,QWORD[16+rsi]
	mov	r10,QWORD[40+rsi]
	lea	r11,[56+rsi]
	lea	r12,[24+rsi]
	mov	QWORD[32+rsp],r10
	mov	QWORD[40+rsp],r11
	mov	QWORD[48+rsp],r12
	mov	QWORD[56+rsp],rcx
	call	QWORD[__imp_RtlVirtualUnwind]

	mov	eax,1
	add	rsp,64
	popfq
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	rbp
	pop	rbx
	pop	rdi
	pop	rsi
	DB	0F3h,0C3h		;repret


section	.pdata rdata align=4
ALIGN	4
	DD	$L$SEH_begin_bn_mul_mont_gather5 wrt ..imagebase
	DD	$L$SEH_end_bn_mul_mont_gather5 wrt ..imagebase
	DD	$L$SEH_info_bn_mul_mont_gather5 wrt ..imagebase

	DD	$L$SEH_begin_bn_mul4x_mont_gather5 wrt ..imagebase
	DD	$L$SEH_end_bn_mul4x_mont_gather5 wrt ..imagebase
	DD	$L$SEH_info_bn_mul4x_mont_gather5 wrt ..imagebase

	DD	$L$SEH_begin_bn_power5 wrt ..imagebase
	DD	$L$SEH_end_bn_power5 wrt ..imagebase
	DD	$L$SEH_info_bn_power5 wrt ..imagebase

	DD	$L$SEH_begin_bn_from_mont8x wrt ..imagebase
	DD	$L$SEH_end_bn_from_mont8x wrt ..imagebase
	DD	$L$SEH_info_bn_from_mont8x wrt ..imagebase
	DD	$L$SEH_begin_bn_gather5 wrt ..imagebase
	DD	$L$SEH_end_bn_gather5 wrt ..imagebase
	DD	$L$SEH_info_bn_gather5 wrt ..imagebase

section	.xdata rdata align=8
ALIGN	8
$L$SEH_info_bn_mul_mont_gather5:
DB	9,0,0,0
	DD	mul_handler wrt ..imagebase
	DD	$L$mul_body wrt ..imagebase,$L$mul_epilogue wrt ..imagebase
ALIGN	8
$L$SEH_info_bn_mul4x_mont_gather5:
DB	9,0,0,0
	DD	mul_handler wrt ..imagebase
	DD	$L$mul4x_body wrt ..imagebase,$L$mul4x_epilogue wrt ..imagebase
ALIGN	8
$L$SEH_info_bn_power5:
DB	9,0,0,0
	DD	mul_handler wrt ..imagebase
	DD	$L$power5_body wrt ..imagebase,$L$power5_epilogue wrt ..imagebase
ALIGN	8
$L$SEH_info_bn_from_mont8x:
DB	9,0,0,0
	DD	mul_handler wrt ..imagebase
	DD	$L$from_body wrt ..imagebase,$L$from_epilogue wrt ..imagebase
ALIGN	8
$L$SEH_info_bn_gather5:
DB	0x01,0x0b,0x03,0x0a
DB	0x0b,0x01,0x21,0x00
DB	0x04,0xa3,0x00,0x00
ALIGN	8
