default	rel
%define XMMWORD
%define YMMWORD
%define ZMMWORD
section	.text code align=64

EXTERN	OPENSSL_ia32cap_P


ALIGN	64
$L$poly:
	DQ	0xffffffffffffffff,0x00000000ffffffff,0x0000000000000000,0xffffffff00000001

$L$One:
	DD	1,1,1,1,1,1,1,1
$L$Two:
	DD	2,2,2,2,2,2,2,2
$L$Three:
	DD	3,3,3,3,3,3,3,3
$L$ONE_mont:
	DQ	0x0000000000000001,0xffffffff00000000,0xffffffffffffffff,0x00000000fffffffe


ALIGN	64
ecp_nistz256_mul_by_2:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_ecp_nistz256_mul_by_2:
	mov	rdi,rcx
	mov	rsi,rdx


	push	r12
	push	r13

	mov	r8,QWORD[rsi]
	mov	r9,QWORD[8+rsi]
	add	r8,r8
	mov	r10,QWORD[16+rsi]
	adc	r9,r9
	mov	r11,QWORD[24+rsi]
	lea	rsi,[$L$poly]
	mov	rax,r8
	adc	r10,r10
	adc	r11,r11
	mov	rdx,r9
	sbb	r13,r13

	sub	r8,QWORD[rsi]
	mov	rcx,r10
	sbb	r9,QWORD[8+rsi]
	sbb	r10,QWORD[16+rsi]
	mov	r12,r11
	sbb	r11,QWORD[24+rsi]
	test	r13,r13

	cmovz	r8,rax
	cmovz	r9,rdx
	mov	QWORD[rdi],r8
	cmovz	r10,rcx
	mov	QWORD[8+rdi],r9
	cmovz	r11,r12
	mov	QWORD[16+rdi],r10
	mov	QWORD[24+rdi],r11

	pop	r13
	pop	r12
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_ecp_nistz256_mul_by_2:



global	ecp_nistz256_neg

ALIGN	32
ecp_nistz256_neg:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_ecp_nistz256_neg:
	mov	rdi,rcx
	mov	rsi,rdx


	push	r12
	push	r13

	xor	r8,r8
	xor	r9,r9
	xor	r10,r10
	xor	r11,r11
	xor	r13,r13

	sub	r8,QWORD[rsi]
	sbb	r9,QWORD[8+rsi]
	sbb	r10,QWORD[16+rsi]
	mov	rax,r8
	sbb	r11,QWORD[24+rsi]
	lea	rsi,[$L$poly]
	mov	rdx,r9
	sbb	r13,0

	add	r8,QWORD[rsi]
	mov	rcx,r10
	adc	r9,QWORD[8+rsi]
	adc	r10,QWORD[16+rsi]
	mov	r12,r11
	adc	r11,QWORD[24+rsi]
	test	r13,r13

	cmovz	r8,rax
	cmovz	r9,rdx
	mov	QWORD[rdi],r8
	cmovz	r10,rcx
	mov	QWORD[8+rdi],r9
	cmovz	r11,r12
	mov	QWORD[16+rdi],r10
	mov	QWORD[24+rdi],r11

	pop	r13
	pop	r12
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_ecp_nistz256_neg:






global	ecp_nistz256_mul_mont

ALIGN	32
ecp_nistz256_mul_mont:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_ecp_nistz256_mul_mont:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8


$L$mul_mont:
	push	rbp
	push	rbx
	push	r12
	push	r13
	push	r14
	push	r15
	mov	rbx,rdx
	mov	rax,QWORD[rdx]
	mov	r9,QWORD[rsi]
	mov	r10,QWORD[8+rsi]
	mov	r11,QWORD[16+rsi]
	mov	r12,QWORD[24+rsi]

	call	__ecp_nistz256_mul_montq
$L$mul_mont_done:
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	rbx
	pop	rbp
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_ecp_nistz256_mul_mont:


ALIGN	32
__ecp_nistz256_mul_montq:


	mov	rbp,rax
	mul	r9
	mov	r14,QWORD[(($L$poly+8))]
	mov	r8,rax
	mov	rax,rbp
	mov	r9,rdx

	mul	r10
	mov	r15,QWORD[(($L$poly+24))]
	add	r9,rax
	mov	rax,rbp
	adc	rdx,0
	mov	r10,rdx

	mul	r11
	add	r10,rax
	mov	rax,rbp
	adc	rdx,0
	mov	r11,rdx

	mul	r12
	add	r11,rax
	mov	rax,r8
	adc	rdx,0
	xor	r13,r13
	mov	r12,rdx










	mov	rbp,r8
	shl	r8,32
	mul	r15
	shr	rbp,32
	add	r9,r8
	adc	r10,rbp
	adc	r11,rax
	mov	rax,QWORD[8+rbx]
	adc	r12,rdx
	adc	r13,0
	xor	r8,r8



	mov	rbp,rax
	mul	QWORD[rsi]
	add	r9,rax
	mov	rax,rbp
	adc	rdx,0
	mov	rcx,rdx

	mul	QWORD[8+rsi]
	add	r10,rcx
	adc	rdx,0
	add	r10,rax
	mov	rax,rbp
	adc	rdx,0
	mov	rcx,rdx

	mul	QWORD[16+rsi]
	add	r11,rcx
	adc	rdx,0
	add	r11,rax
	mov	rax,rbp
	adc	rdx,0
	mov	rcx,rdx

	mul	QWORD[24+rsi]
	add	r12,rcx
	adc	rdx,0
	add	r12,rax
	mov	rax,r9
	adc	r13,rdx
	adc	r8,0



	mov	rbp,r9
	shl	r9,32
	mul	r15
	shr	rbp,32
	add	r10,r9
	adc	r11,rbp
	adc	r12,rax
	mov	rax,QWORD[16+rbx]
	adc	r13,rdx
	adc	r8,0
	xor	r9,r9



	mov	rbp,rax
	mul	QWORD[rsi]
	add	r10,rax
	mov	rax,rbp
	adc	rdx,0
	mov	rcx,rdx

	mul	QWORD[8+rsi]
	add	r11,rcx
	adc	rdx,0
	add	r11,rax
	mov	rax,rbp
	adc	rdx,0
	mov	rcx,rdx

	mul	QWORD[16+rsi]
	add	r12,rcx
	adc	rdx,0
	add	r12,rax
	mov	rax,rbp
	adc	rdx,0
	mov	rcx,rdx

	mul	QWORD[24+rsi]
	add	r13,rcx
	adc	rdx,0
	add	r13,rax
	mov	rax,r10
	adc	r8,rdx
	adc	r9,0



	mov	rbp,r10
	shl	r10,32
	mul	r15
	shr	rbp,32
	add	r11,r10
	adc	r12,rbp
	adc	r13,rax
	mov	rax,QWORD[24+rbx]
	adc	r8,rdx
	adc	r9,0
	xor	r10,r10



	mov	rbp,rax
	mul	QWORD[rsi]
	add	r11,rax
	mov	rax,rbp
	adc	rdx,0
	mov	rcx,rdx

	mul	QWORD[8+rsi]
	add	r12,rcx
	adc	rdx,0
	add	r12,rax
	mov	rax,rbp
	adc	rdx,0
	mov	rcx,rdx

	mul	QWORD[16+rsi]
	add	r13,rcx
	adc	rdx,0
	add	r13,rax
	mov	rax,rbp
	adc	rdx,0
	mov	rcx,rdx

	mul	QWORD[24+rsi]
	add	r8,rcx
	adc	rdx,0
	add	r8,rax
	mov	rax,r11
	adc	r9,rdx
	adc	r10,0



	mov	rbp,r11
	shl	r11,32
	mul	r15
	shr	rbp,32
	add	r12,r11
	adc	r13,rbp
	mov	rcx,r12
	adc	r8,rax
	adc	r9,rdx
	mov	rbp,r13
	adc	r10,0



	sub	r12,-1
	mov	rbx,r8
	sbb	r13,r14
	sbb	r8,0
	mov	rdx,r9
	sbb	r9,r15
	sbb	r10,0

	cmovc	r12,rcx
	cmovc	r13,rbp
	mov	QWORD[rdi],r12
	cmovc	r8,rbx
	mov	QWORD[8+rdi],r13
	cmovc	r9,rdx
	mov	QWORD[16+rdi],r8
	mov	QWORD[24+rdi],r9

	DB	0F3h,0C3h		;repret









global	ecp_nistz256_sqr_mont

ALIGN	32
ecp_nistz256_sqr_mont:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_ecp_nistz256_sqr_mont:
	mov	rdi,rcx
	mov	rsi,rdx


	push	rbp
	push	rbx
	push	r12
	push	r13
	push	r14
	push	r15
	mov	rax,QWORD[rsi]
	mov	r14,QWORD[8+rsi]
	mov	r15,QWORD[16+rsi]
	mov	r8,QWORD[24+rsi]

	call	__ecp_nistz256_sqr_montq
$L$sqr_mont_done:
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	rbx
	pop	rbp
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_ecp_nistz256_sqr_mont:


ALIGN	32
__ecp_nistz256_sqr_montq:
	mov	r13,rax
	mul	r14
	mov	r9,rax
	mov	rax,r15
	mov	r10,rdx

	mul	r13
	add	r10,rax
	mov	rax,r8
	adc	rdx,0
	mov	r11,rdx

	mul	r13
	add	r11,rax
	mov	rax,r15
	adc	rdx,0
	mov	r12,rdx


	mul	r14
	add	r11,rax
	mov	rax,r8
	adc	rdx,0
	mov	rbp,rdx

	mul	r14
	add	r12,rax
	mov	rax,r8
	adc	rdx,0
	add	r12,rbp
	mov	r13,rdx
	adc	r13,0


	mul	r15
	xor	r15,r15
	add	r13,rax
	mov	rax,QWORD[rsi]
	mov	r14,rdx
	adc	r14,0

	add	r9,r9
	adc	r10,r10
	adc	r11,r11
	adc	r12,r12
	adc	r13,r13
	adc	r14,r14
	adc	r15,0

	mul	rax
	mov	r8,rax
	mov	rax,QWORD[8+rsi]
	mov	rcx,rdx

	mul	rax
	add	r9,rcx
	adc	r10,rax
	mov	rax,QWORD[16+rsi]
	adc	rdx,0
	mov	rcx,rdx

	mul	rax
	add	r11,rcx
	adc	r12,rax
	mov	rax,QWORD[24+rsi]
	adc	rdx,0
	mov	rcx,rdx

	mul	rax
	add	r13,rcx
	adc	r14,rax
	mov	rax,r8
	adc	r15,rdx

	mov	rsi,QWORD[(($L$poly+8))]
	mov	rbp,QWORD[(($L$poly+24))]




	mov	rcx,r8
	shl	r8,32
	mul	rbp
	shr	rcx,32
	add	r9,r8
	adc	r10,rcx
	adc	r11,rax
	mov	rax,r9
	adc	rdx,0



	mov	rcx,r9
	shl	r9,32
	mov	r8,rdx
	mul	rbp
	shr	rcx,32
	add	r10,r9
	adc	r11,rcx
	adc	r8,rax
	mov	rax,r10
	adc	rdx,0



	mov	rcx,r10
	shl	r10,32
	mov	r9,rdx
	mul	rbp
	shr	rcx,32
	add	r11,r10
	adc	r8,rcx
	adc	r9,rax
	mov	rax,r11
	adc	rdx,0



	mov	rcx,r11
	shl	r11,32
	mov	r10,rdx
	mul	rbp
	shr	rcx,32
	add	r8,r11
	adc	r9,rcx
	adc	r10,rax
	adc	rdx,0
	xor	r11,r11



	add	r12,r8
	adc	r13,r9
	mov	r8,r12
	adc	r14,r10
	adc	r15,rdx
	mov	r9,r13
	adc	r11,0

	sub	r12,-1
	mov	r10,r14
	sbb	r13,rsi
	sbb	r14,0
	mov	rcx,r15
	sbb	r15,rbp
	sbb	r11,0

	cmovc	r12,r8
	cmovc	r13,r9
	mov	QWORD[rdi],r12
	cmovc	r14,r10
	mov	QWORD[8+rdi],r13
	cmovc	r15,rcx
	mov	QWORD[16+rdi],r14
	mov	QWORD[24+rdi],r15

	DB	0F3h,0C3h		;repret







global	ecp_nistz256_from_mont

ALIGN	32
ecp_nistz256_from_mont:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_ecp_nistz256_from_mont:
	mov	rdi,rcx
	mov	rsi,rdx


	push	r12
	push	r13

	mov	rax,QWORD[rsi]
	mov	r13,QWORD[(($L$poly+24))]
	mov	r9,QWORD[8+rsi]
	mov	r10,QWORD[16+rsi]
	mov	r11,QWORD[24+rsi]
	mov	r8,rax
	mov	r12,QWORD[(($L$poly+8))]



	mov	rcx,rax
	shl	r8,32
	mul	r13
	shr	rcx,32
	add	r9,r8
	adc	r10,rcx
	adc	r11,rax
	mov	rax,r9
	adc	rdx,0



	mov	rcx,r9
	shl	r9,32
	mov	r8,rdx
	mul	r13
	shr	rcx,32
	add	r10,r9
	adc	r11,rcx
	adc	r8,rax
	mov	rax,r10
	adc	rdx,0



	mov	rcx,r10
	shl	r10,32
	mov	r9,rdx
	mul	r13
	shr	rcx,32
	add	r11,r10
	adc	r8,rcx
	adc	r9,rax
	mov	rax,r11
	adc	rdx,0



	mov	rcx,r11
	shl	r11,32
	mov	r10,rdx
	mul	r13
	shr	rcx,32
	add	r8,r11
	adc	r9,rcx
	mov	rcx,r8
	adc	r10,rax
	mov	rsi,r9
	adc	rdx,0

	sub	r8,-1
	mov	rax,r10
	sbb	r9,r12
	sbb	r10,0
	mov	r11,rdx
	sbb	rdx,r13
	sbb	r13,r13

	cmovnz	r8,rcx
	cmovnz	r9,rsi
	mov	QWORD[rdi],r8
	cmovnz	r10,rax
	mov	QWORD[8+rdi],r9
	cmovz	r11,rdx
	mov	QWORD[16+rdi],r10
	mov	QWORD[24+rdi],r11

	pop	r13
	pop	r12
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_ecp_nistz256_from_mont:


global	ecp_nistz256_select_w5

ALIGN	32
ecp_nistz256_select_w5:
	lea	rax,[((-136))+rsp]
$L$SEH_begin_ecp_nistz256_select_w5:
DB	0x48,0x8d,0x60,0xe0
DB	0x0f,0x29,0x70,0xe0
DB	0x0f,0x29,0x78,0xf0
DB	0x44,0x0f,0x29,0x00
DB	0x44,0x0f,0x29,0x48,0x10
DB	0x44,0x0f,0x29,0x50,0x20
DB	0x44,0x0f,0x29,0x58,0x30
DB	0x44,0x0f,0x29,0x60,0x40
DB	0x44,0x0f,0x29,0x68,0x50
DB	0x44,0x0f,0x29,0x70,0x60
DB	0x44,0x0f,0x29,0x78,0x70
	movdqa	xmm0,XMMWORD[$L$One]
	movd	xmm1,r8d

	pxor	xmm2,xmm2
	pxor	xmm3,xmm3
	pxor	xmm4,xmm4
	pxor	xmm5,xmm5
	pxor	xmm6,xmm6
	pxor	xmm7,xmm7

	movdqa	xmm8,xmm0
	pshufd	xmm1,xmm1,0

	mov	rax,16
$L$select_loop_sse_w5:

	movdqa	xmm15,xmm8
	paddd	xmm8,xmm0
	pcmpeqd	xmm15,xmm1

	movdqa	xmm9,XMMWORD[rdx]
	movdqa	xmm10,XMMWORD[16+rdx]
	movdqa	xmm11,XMMWORD[32+rdx]
	movdqa	xmm12,XMMWORD[48+rdx]
	movdqa	xmm13,XMMWORD[64+rdx]
	movdqa	xmm14,XMMWORD[80+rdx]
	lea	rdx,[96+rdx]

	pand	xmm9,xmm15
	pand	xmm10,xmm15
	por	xmm2,xmm9
	pand	xmm11,xmm15
	por	xmm3,xmm10
	pand	xmm12,xmm15
	por	xmm4,xmm11
	pand	xmm13,xmm15
	por	xmm5,xmm12
	pand	xmm14,xmm15
	por	xmm6,xmm13
	por	xmm7,xmm14

	dec	rax
	jnz	NEAR $L$select_loop_sse_w5

	movdqu	XMMWORD[rcx],xmm2
	movdqu	XMMWORD[16+rcx],xmm3
	movdqu	XMMWORD[32+rcx],xmm4
	movdqu	XMMWORD[48+rcx],xmm5
	movdqu	XMMWORD[64+rcx],xmm6
	movdqu	XMMWORD[80+rcx],xmm7
	movaps	xmm6,XMMWORD[rsp]
	movaps	xmm7,XMMWORD[16+rsp]
	movaps	xmm8,XMMWORD[32+rsp]
	movaps	xmm9,XMMWORD[48+rsp]
	movaps	xmm10,XMMWORD[64+rsp]
	movaps	xmm11,XMMWORD[80+rsp]
	movaps	xmm12,XMMWORD[96+rsp]
	movaps	xmm13,XMMWORD[112+rsp]
	movaps	xmm14,XMMWORD[128+rsp]
	movaps	xmm15,XMMWORD[144+rsp]
	lea	rsp,[168+rsp]
$L$SEH_end_ecp_nistz256_select_w5:
	DB	0F3h,0C3h		;repret




global	ecp_nistz256_select_w7

ALIGN	32
ecp_nistz256_select_w7:
	lea	rax,[((-136))+rsp]
$L$SEH_begin_ecp_nistz256_select_w7:
DB	0x48,0x8d,0x60,0xe0
DB	0x0f,0x29,0x70,0xe0
DB	0x0f,0x29,0x78,0xf0
DB	0x44,0x0f,0x29,0x00
DB	0x44,0x0f,0x29,0x48,0x10
DB	0x44,0x0f,0x29,0x50,0x20
DB	0x44,0x0f,0x29,0x58,0x30
DB	0x44,0x0f,0x29,0x60,0x40
DB	0x44,0x0f,0x29,0x68,0x50
DB	0x44,0x0f,0x29,0x70,0x60
DB	0x44,0x0f,0x29,0x78,0x70
	movdqa	xmm8,XMMWORD[$L$One]
	movd	xmm1,r8d

	pxor	xmm2,xmm2
	pxor	xmm3,xmm3
	pxor	xmm4,xmm4
	pxor	xmm5,xmm5

	movdqa	xmm0,xmm8
	pshufd	xmm1,xmm1,0
	mov	rax,64

$L$select_loop_sse_w7:
	movdqa	xmm15,xmm8
	paddd	xmm8,xmm0
	movdqa	xmm9,XMMWORD[rdx]
	movdqa	xmm10,XMMWORD[16+rdx]
	pcmpeqd	xmm15,xmm1
	movdqa	xmm11,XMMWORD[32+rdx]
	movdqa	xmm12,XMMWORD[48+rdx]
	lea	rdx,[64+rdx]

	pand	xmm9,xmm15
	pand	xmm10,xmm15
	por	xmm2,xmm9
	pand	xmm11,xmm15
	por	xmm3,xmm10
	pand	xmm12,xmm15
	por	xmm4,xmm11
	prefetcht0	[255+rdx]
	por	xmm5,xmm12

	dec	rax
	jnz	NEAR $L$select_loop_sse_w7

	movdqu	XMMWORD[rcx],xmm2
	movdqu	XMMWORD[16+rcx],xmm3
	movdqu	XMMWORD[32+rcx],xmm4
	movdqu	XMMWORD[48+rcx],xmm5
	movaps	xmm6,XMMWORD[rsp]
	movaps	xmm7,XMMWORD[16+rsp]
	movaps	xmm8,XMMWORD[32+rsp]
	movaps	xmm9,XMMWORD[48+rsp]
	movaps	xmm10,XMMWORD[64+rsp]
	movaps	xmm11,XMMWORD[80+rsp]
	movaps	xmm12,XMMWORD[96+rsp]
	movaps	xmm13,XMMWORD[112+rsp]
	movaps	xmm14,XMMWORD[128+rsp]
	movaps	xmm15,XMMWORD[144+rsp]
	lea	rsp,[168+rsp]
$L$SEH_end_ecp_nistz256_select_w7:
	DB	0F3h,0C3h		;repret

global	ecp_nistz256_avx2_select_w7

ALIGN	32
ecp_nistz256_avx2_select_w7:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_ecp_nistz256_avx2_select_w7:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8


DB	0x0f,0x0b
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_ecp_nistz256_avx2_select_w7:

ALIGN	32
__ecp_nistz256_add_toq:
	add	r12,QWORD[rbx]
	adc	r13,QWORD[8+rbx]
	mov	rax,r12
	adc	r8,QWORD[16+rbx]
	adc	r9,QWORD[24+rbx]
	mov	rbp,r13
	sbb	r11,r11

	sub	r12,-1
	mov	rcx,r8
	sbb	r13,r14
	sbb	r8,0
	mov	r10,r9
	sbb	r9,r15
	test	r11,r11

	cmovz	r12,rax
	cmovz	r13,rbp
	mov	QWORD[rdi],r12
	cmovz	r8,rcx
	mov	QWORD[8+rdi],r13
	cmovz	r9,r10
	mov	QWORD[16+rdi],r8
	mov	QWORD[24+rdi],r9

	DB	0F3h,0C3h		;repret



ALIGN	32
__ecp_nistz256_sub_fromq:
	sub	r12,QWORD[rbx]
	sbb	r13,QWORD[8+rbx]
	mov	rax,r12
	sbb	r8,QWORD[16+rbx]
	sbb	r9,QWORD[24+rbx]
	mov	rbp,r13
	sbb	r11,r11

	add	r12,-1
	mov	rcx,r8
	adc	r13,r14
	adc	r8,0
	mov	r10,r9
	adc	r9,r15
	test	r11,r11

	cmovz	r12,rax
	cmovz	r13,rbp
	mov	QWORD[rdi],r12
	cmovz	r8,rcx
	mov	QWORD[8+rdi],r13
	cmovz	r9,r10
	mov	QWORD[16+rdi],r8
	mov	QWORD[24+rdi],r9

	DB	0F3h,0C3h		;repret



ALIGN	32
__ecp_nistz256_subq:
	sub	rax,r12
	sbb	rbp,r13
	mov	r12,rax
	sbb	rcx,r8
	sbb	r10,r9
	mov	r13,rbp
	sbb	r11,r11

	add	rax,-1
	mov	r8,rcx
	adc	rbp,r14
	adc	rcx,0
	mov	r9,r10
	adc	r10,r15
	test	r11,r11

	cmovnz	r12,rax
	cmovnz	r13,rbp
	cmovnz	r8,rcx
	cmovnz	r9,r10

	DB	0F3h,0C3h		;repret



ALIGN	32
__ecp_nistz256_mul_by_2q:
	add	r12,r12
	adc	r13,r13
	mov	rax,r12
	adc	r8,r8
	adc	r9,r9
	mov	rbp,r13
	sbb	r11,r11

	sub	r12,-1
	mov	rcx,r8
	sbb	r13,r14
	sbb	r8,0
	mov	r10,r9
	sbb	r9,r15
	test	r11,r11

	cmovz	r12,rax
	cmovz	r13,rbp
	mov	QWORD[rdi],r12
	cmovz	r8,rcx
	mov	QWORD[8+rdi],r13
	cmovz	r9,r10
	mov	QWORD[16+rdi],r8
	mov	QWORD[24+rdi],r9

	DB	0F3h,0C3h		;repret

global	ecp_nistz256_point_double

ALIGN	32
ecp_nistz256_point_double:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_ecp_nistz256_point_double:
	mov	rdi,rcx
	mov	rsi,rdx


	push	rbp
	push	rbx
	push	r12
	push	r13
	push	r14
	push	r15
	sub	rsp,32*5+8

$L$point_double_shortcutq:
	movdqu	xmm0,XMMWORD[rsi]
	mov	rbx,rsi
	movdqu	xmm1,XMMWORD[16+rsi]
	mov	r12,QWORD[((32+0))+rsi]
	mov	r13,QWORD[((32+8))+rsi]
	mov	r8,QWORD[((32+16))+rsi]
	mov	r9,QWORD[((32+24))+rsi]
	mov	r14,QWORD[(($L$poly+8))]
	mov	r15,QWORD[(($L$poly+24))]
	movdqa	XMMWORD[96+rsp],xmm0
	movdqa	XMMWORD[(96+16)+rsp],xmm1
	lea	r10,[32+rdi]
	lea	r11,[64+rdi]
DB	102,72,15,110,199
DB	102,73,15,110,202
DB	102,73,15,110,211

	lea	rdi,[rsp]
	call	__ecp_nistz256_mul_by_2q

	mov	rax,QWORD[((64+0))+rsi]
	mov	r14,QWORD[((64+8))+rsi]
	mov	r15,QWORD[((64+16))+rsi]
	mov	r8,QWORD[((64+24))+rsi]
	lea	rsi,[((64-0))+rsi]
	lea	rdi,[64+rsp]
	call	__ecp_nistz256_sqr_montq

	mov	rax,QWORD[((0+0))+rsp]
	mov	r14,QWORD[((8+0))+rsp]
	lea	rsi,[((0+0))+rsp]
	mov	r15,QWORD[((16+0))+rsp]
	mov	r8,QWORD[((24+0))+rsp]
	lea	rdi,[rsp]
	call	__ecp_nistz256_sqr_montq

	mov	rax,QWORD[32+rbx]
	mov	r9,QWORD[((64+0))+rbx]
	mov	r10,QWORD[((64+8))+rbx]
	mov	r11,QWORD[((64+16))+rbx]
	mov	r12,QWORD[((64+24))+rbx]
	lea	rsi,[((64-0))+rbx]
	lea	rbx,[32+rbx]
DB	102,72,15,126,215
	call	__ecp_nistz256_mul_montq
	call	__ecp_nistz256_mul_by_2q

	mov	r12,QWORD[((96+0))+rsp]
	mov	r13,QWORD[((96+8))+rsp]
	lea	rbx,[64+rsp]
	mov	r8,QWORD[((96+16))+rsp]
	mov	r9,QWORD[((96+24))+rsp]
	lea	rdi,[32+rsp]
	call	__ecp_nistz256_add_toq

	mov	r12,QWORD[((96+0))+rsp]
	mov	r13,QWORD[((96+8))+rsp]
	lea	rbx,[64+rsp]
	mov	r8,QWORD[((96+16))+rsp]
	mov	r9,QWORD[((96+24))+rsp]
	lea	rdi,[64+rsp]
	call	__ecp_nistz256_sub_fromq

	mov	rax,QWORD[((0+0))+rsp]
	mov	r14,QWORD[((8+0))+rsp]
	lea	rsi,[((0+0))+rsp]
	mov	r15,QWORD[((16+0))+rsp]
	mov	r8,QWORD[((24+0))+rsp]
DB	102,72,15,126,207
	call	__ecp_nistz256_sqr_montq
	xor	r9,r9
	mov	rax,r12
	add	r12,-1
	mov	r10,r13
	adc	r13,rsi
	mov	rcx,r14
	adc	r14,0
	mov	r8,r15
	adc	r15,rbp
	adc	r9,0
	xor	rsi,rsi
	test	rax,1

	cmovz	r12,rax
	cmovz	r13,r10
	cmovz	r14,rcx
	cmovz	r15,r8
	cmovz	r9,rsi

	mov	rax,r13
	shr	r12,1
	shl	rax,63
	mov	r10,r14
	shr	r13,1
	or	r12,rax
	shl	r10,63
	mov	rcx,r15
	shr	r14,1
	or	r13,r10
	shl	rcx,63
	mov	QWORD[rdi],r12
	shr	r15,1
	mov	QWORD[8+rdi],r13
	shl	r9,63
	or	r14,rcx
	or	r15,r9
	mov	QWORD[16+rdi],r14
	mov	QWORD[24+rdi],r15
	mov	rax,QWORD[64+rsp]
	lea	rbx,[64+rsp]
	mov	r9,QWORD[((0+32))+rsp]
	mov	r10,QWORD[((8+32))+rsp]
	lea	rsi,[((0+32))+rsp]
	mov	r11,QWORD[((16+32))+rsp]
	mov	r12,QWORD[((24+32))+rsp]
	lea	rdi,[32+rsp]
	call	__ecp_nistz256_mul_montq

	lea	rdi,[128+rsp]
	call	__ecp_nistz256_mul_by_2q

	lea	rbx,[32+rsp]
	lea	rdi,[32+rsp]
	call	__ecp_nistz256_add_toq

	mov	rax,QWORD[96+rsp]
	lea	rbx,[96+rsp]
	mov	r9,QWORD[((0+0))+rsp]
	mov	r10,QWORD[((8+0))+rsp]
	lea	rsi,[((0+0))+rsp]
	mov	r11,QWORD[((16+0))+rsp]
	mov	r12,QWORD[((24+0))+rsp]
	lea	rdi,[rsp]
	call	__ecp_nistz256_mul_montq

	lea	rdi,[128+rsp]
	call	__ecp_nistz256_mul_by_2q

	mov	rax,QWORD[((0+32))+rsp]
	mov	r14,QWORD[((8+32))+rsp]
	lea	rsi,[((0+32))+rsp]
	mov	r15,QWORD[((16+32))+rsp]
	mov	r8,QWORD[((24+32))+rsp]
DB	102,72,15,126,199
	call	__ecp_nistz256_sqr_montq

	lea	rbx,[128+rsp]
	mov	r8,r14
	mov	r9,r15
	mov	r14,rsi
	mov	r15,rbp
	call	__ecp_nistz256_sub_fromq

	mov	rax,QWORD[((0+0))+rsp]
	mov	rbp,QWORD[((0+8))+rsp]
	mov	rcx,QWORD[((0+16))+rsp]
	mov	r10,QWORD[((0+24))+rsp]
	lea	rdi,[rsp]
	call	__ecp_nistz256_subq

	mov	rax,QWORD[32+rsp]
	lea	rbx,[32+rsp]
	mov	r14,r12
	xor	ecx,ecx
	mov	QWORD[((0+0))+rsp],r12
	mov	r10,r13
	mov	QWORD[((0+8))+rsp],r13
	cmovz	r11,r8
	mov	QWORD[((0+16))+rsp],r8
	lea	rsi,[((0-0))+rsp]
	cmovz	r12,r9
	mov	QWORD[((0+24))+rsp],r9
	mov	r9,r14
	lea	rdi,[rsp]
	call	__ecp_nistz256_mul_montq

DB	102,72,15,126,203
DB	102,72,15,126,207
	call	__ecp_nistz256_sub_fromq

	add	rsp,32*5+8
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	rbx
	pop	rbp
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_ecp_nistz256_point_double:
global	ecp_nistz256_point_add

ALIGN	32
ecp_nistz256_point_add:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_ecp_nistz256_point_add:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8


	push	rbp
	push	rbx
	push	r12
	push	r13
	push	r14
	push	r15
	sub	rsp,32*18+8

	movdqu	xmm0,XMMWORD[rsi]
	movdqu	xmm1,XMMWORD[16+rsi]
	movdqu	xmm2,XMMWORD[32+rsi]
	movdqu	xmm3,XMMWORD[48+rsi]
	movdqu	xmm4,XMMWORD[64+rsi]
	movdqu	xmm5,XMMWORD[80+rsi]
	mov	rbx,rsi
	mov	rsi,rdx
	movdqa	XMMWORD[384+rsp],xmm0
	movdqa	XMMWORD[(384+16)+rsp],xmm1
	por	xmm1,xmm0
	movdqa	XMMWORD[416+rsp],xmm2
	movdqa	XMMWORD[(416+16)+rsp],xmm3
	por	xmm3,xmm2
	movdqa	XMMWORD[448+rsp],xmm4
	movdqa	XMMWORD[(448+16)+rsp],xmm5
	por	xmm3,xmm1

	movdqu	xmm0,XMMWORD[rsi]
	pshufd	xmm5,xmm3,0xb1
	movdqu	xmm1,XMMWORD[16+rsi]
	movdqu	xmm2,XMMWORD[32+rsi]
	por	xmm5,xmm3
	movdqu	xmm3,XMMWORD[48+rsi]
	mov	rax,QWORD[((64+0))+rsi]
	mov	r14,QWORD[((64+8))+rsi]
	mov	r15,QWORD[((64+16))+rsi]
	mov	r8,QWORD[((64+24))+rsi]
	movdqa	XMMWORD[480+rsp],xmm0
	pshufd	xmm4,xmm5,0x1e
	movdqa	XMMWORD[(480+16)+rsp],xmm1
	por	xmm1,xmm0
DB	102,72,15,110,199
	movdqa	XMMWORD[512+rsp],xmm2
	movdqa	XMMWORD[(512+16)+rsp],xmm3
	por	xmm3,xmm2
	por	xmm5,xmm4
	pxor	xmm4,xmm4
	por	xmm3,xmm1

	lea	rsi,[((64-0))+rsi]
	mov	QWORD[((544+0))+rsp],rax
	mov	QWORD[((544+8))+rsp],r14
	mov	QWORD[((544+16))+rsp],r15
	mov	QWORD[((544+24))+rsp],r8
	lea	rdi,[96+rsp]
	call	__ecp_nistz256_sqr_montq

	pcmpeqd	xmm5,xmm4
	pshufd	xmm4,xmm3,0xb1
	por	xmm4,xmm3
	pshufd	xmm5,xmm5,0
	pshufd	xmm3,xmm4,0x1e
	por	xmm4,xmm3
	pxor	xmm3,xmm3
	pcmpeqd	xmm4,xmm3
	pshufd	xmm4,xmm4,0
	mov	rax,QWORD[((64+0))+rbx]
	mov	r14,QWORD[((64+8))+rbx]
	mov	r15,QWORD[((64+16))+rbx]
	mov	r8,QWORD[((64+24))+rbx]
DB	102,72,15,110,203

	lea	rsi,[((64-0))+rbx]
	lea	rdi,[32+rsp]
	call	__ecp_nistz256_sqr_montq

	mov	rax,QWORD[544+rsp]
	lea	rbx,[544+rsp]
	mov	r9,QWORD[((0+96))+rsp]
	mov	r10,QWORD[((8+96))+rsp]
	lea	rsi,[((0+96))+rsp]
	mov	r11,QWORD[((16+96))+rsp]
	mov	r12,QWORD[((24+96))+rsp]
	lea	rdi,[224+rsp]
	call	__ecp_nistz256_mul_montq

	mov	rax,QWORD[448+rsp]
	lea	rbx,[448+rsp]
	mov	r9,QWORD[((0+32))+rsp]
	mov	r10,QWORD[((8+32))+rsp]
	lea	rsi,[((0+32))+rsp]
	mov	r11,QWORD[((16+32))+rsp]
	mov	r12,QWORD[((24+32))+rsp]
	lea	rdi,[256+rsp]
	call	__ecp_nistz256_mul_montq

	mov	rax,QWORD[416+rsp]
	lea	rbx,[416+rsp]
	mov	r9,QWORD[((0+224))+rsp]
	mov	r10,QWORD[((8+224))+rsp]
	lea	rsi,[((0+224))+rsp]
	mov	r11,QWORD[((16+224))+rsp]
	mov	r12,QWORD[((24+224))+rsp]
	lea	rdi,[224+rsp]
	call	__ecp_nistz256_mul_montq

	mov	rax,QWORD[512+rsp]
	lea	rbx,[512+rsp]
	mov	r9,QWORD[((0+256))+rsp]
	mov	r10,QWORD[((8+256))+rsp]
	lea	rsi,[((0+256))+rsp]
	mov	r11,QWORD[((16+256))+rsp]
	mov	r12,QWORD[((24+256))+rsp]
	lea	rdi,[256+rsp]
	call	__ecp_nistz256_mul_montq

	lea	rbx,[224+rsp]
	lea	rdi,[64+rsp]
	call	__ecp_nistz256_sub_fromq

	or	r12,r13
	movdqa	xmm2,xmm4
	or	r12,r8
	or	r12,r9
	por	xmm2,xmm5
DB	102,73,15,110,220

	mov	rax,QWORD[384+rsp]
	lea	rbx,[384+rsp]
	mov	r9,QWORD[((0+96))+rsp]
	mov	r10,QWORD[((8+96))+rsp]
	lea	rsi,[((0+96))+rsp]
	mov	r11,QWORD[((16+96))+rsp]
	mov	r12,QWORD[((24+96))+rsp]
	lea	rdi,[160+rsp]
	call	__ecp_nistz256_mul_montq

	mov	rax,QWORD[480+rsp]
	lea	rbx,[480+rsp]
	mov	r9,QWORD[((0+32))+rsp]
	mov	r10,QWORD[((8+32))+rsp]
	lea	rsi,[((0+32))+rsp]
	mov	r11,QWORD[((16+32))+rsp]
	mov	r12,QWORD[((24+32))+rsp]
	lea	rdi,[192+rsp]
	call	__ecp_nistz256_mul_montq

	lea	rbx,[160+rsp]
	lea	rdi,[rsp]
	call	__ecp_nistz256_sub_fromq

	or	r12,r13
	or	r12,r8
	or	r12,r9

DB	0x3e
	jnz	NEAR $L$add_proceedq
DB	102,73,15,126,208
DB	102,73,15,126,217
	test	r8,r8
	jnz	NEAR $L$add_proceedq
	test	r9,r9
	jz	NEAR $L$add_doubleq

DB	102,72,15,126,199
	pxor	xmm0,xmm0
	movdqu	XMMWORD[rdi],xmm0
	movdqu	XMMWORD[16+rdi],xmm0
	movdqu	XMMWORD[32+rdi],xmm0
	movdqu	XMMWORD[48+rdi],xmm0
	movdqu	XMMWORD[64+rdi],xmm0
	movdqu	XMMWORD[80+rdi],xmm0
	jmp	NEAR $L$add_doneq

ALIGN	32
$L$add_doubleq:
DB	102,72,15,126,206
DB	102,72,15,126,199
	add	rsp,416
	jmp	NEAR $L$point_double_shortcutq

ALIGN	32
$L$add_proceedq:
	mov	rax,QWORD[((0+64))+rsp]
	mov	r14,QWORD[((8+64))+rsp]
	lea	rsi,[((0+64))+rsp]
	mov	r15,QWORD[((16+64))+rsp]
	mov	r8,QWORD[((24+64))+rsp]
	lea	rdi,[96+rsp]
	call	__ecp_nistz256_sqr_montq

	mov	rax,QWORD[448+rsp]
	lea	rbx,[448+rsp]
	mov	r9,QWORD[((0+0))+rsp]
	mov	r10,QWORD[((8+0))+rsp]
	lea	rsi,[((0+0))+rsp]
	mov	r11,QWORD[((16+0))+rsp]
	mov	r12,QWORD[((24+0))+rsp]
	lea	rdi,[352+rsp]
	call	__ecp_nistz256_mul_montq

	mov	rax,QWORD[((0+0))+rsp]
	mov	r14,QWORD[((8+0))+rsp]
	lea	rsi,[((0+0))+rsp]
	mov	r15,QWORD[((16+0))+rsp]
	mov	r8,QWORD[((24+0))+rsp]
	lea	rdi,[32+rsp]
	call	__ecp_nistz256_sqr_montq

	mov	rax,QWORD[544+rsp]
	lea	rbx,[544+rsp]
	mov	r9,QWORD[((0+352))+rsp]
	mov	r10,QWORD[((8+352))+rsp]
	lea	rsi,[((0+352))+rsp]
	mov	r11,QWORD[((16+352))+rsp]
	mov	r12,QWORD[((24+352))+rsp]
	lea	rdi,[352+rsp]
	call	__ecp_nistz256_mul_montq

	mov	rax,QWORD[rsp]
	lea	rbx,[rsp]
	mov	r9,QWORD[((0+32))+rsp]
	mov	r10,QWORD[((8+32))+rsp]
	lea	rsi,[((0+32))+rsp]
	mov	r11,QWORD[((16+32))+rsp]
	mov	r12,QWORD[((24+32))+rsp]
	lea	rdi,[128+rsp]
	call	__ecp_nistz256_mul_montq

	mov	rax,QWORD[160+rsp]
	lea	rbx,[160+rsp]
	mov	r9,QWORD[((0+32))+rsp]
	mov	r10,QWORD[((8+32))+rsp]
	lea	rsi,[((0+32))+rsp]
	mov	r11,QWORD[((16+32))+rsp]
	mov	r12,QWORD[((24+32))+rsp]
	lea	rdi,[192+rsp]
	call	__ecp_nistz256_mul_montq




	add	r12,r12
	lea	rsi,[96+rsp]
	adc	r13,r13
	mov	rax,r12
	adc	r8,r8
	adc	r9,r9
	mov	rbp,r13
	sbb	r11,r11

	sub	r12,-1
	mov	rcx,r8
	sbb	r13,r14
	sbb	r8,0
	mov	r10,r9
	sbb	r9,r15
	test	r11,r11

	cmovz	r12,rax
	mov	rax,QWORD[rsi]
	cmovz	r13,rbp
	mov	rbp,QWORD[8+rsi]
	cmovz	r8,rcx
	mov	rcx,QWORD[16+rsi]
	cmovz	r9,r10
	mov	r10,QWORD[24+rsi]

	call	__ecp_nistz256_subq

	lea	rbx,[128+rsp]
	lea	rdi,[288+rsp]
	call	__ecp_nistz256_sub_fromq

	mov	rax,QWORD[((192+0))+rsp]
	mov	rbp,QWORD[((192+8))+rsp]
	mov	rcx,QWORD[((192+16))+rsp]
	mov	r10,QWORD[((192+24))+rsp]
	lea	rdi,[320+rsp]

	call	__ecp_nistz256_subq

	mov	QWORD[rdi],r12
	mov	QWORD[8+rdi],r13
	mov	QWORD[16+rdi],r8
	mov	QWORD[24+rdi],r9
	mov	rax,QWORD[128+rsp]
	lea	rbx,[128+rsp]
	mov	r9,QWORD[((0+224))+rsp]
	mov	r10,QWORD[((8+224))+rsp]
	lea	rsi,[((0+224))+rsp]
	mov	r11,QWORD[((16+224))+rsp]
	mov	r12,QWORD[((24+224))+rsp]
	lea	rdi,[256+rsp]
	call	__ecp_nistz256_mul_montq

	mov	rax,QWORD[320+rsp]
	lea	rbx,[320+rsp]
	mov	r9,QWORD[((0+64))+rsp]
	mov	r10,QWORD[((8+64))+rsp]
	lea	rsi,[((0+64))+rsp]
	mov	r11,QWORD[((16+64))+rsp]
	mov	r12,QWORD[((24+64))+rsp]
	lea	rdi,[320+rsp]
	call	__ecp_nistz256_mul_montq

	lea	rbx,[256+rsp]
	lea	rdi,[320+rsp]
	call	__ecp_nistz256_sub_fromq

DB	102,72,15,126,199

	movdqa	xmm0,xmm5
	movdqa	xmm1,xmm5
	pandn	xmm0,XMMWORD[352+rsp]
	movdqa	xmm2,xmm5
	pandn	xmm1,XMMWORD[((352+16))+rsp]
	movdqa	xmm3,xmm5
	pand	xmm2,XMMWORD[544+rsp]
	pand	xmm3,XMMWORD[((544+16))+rsp]
	por	xmm2,xmm0
	por	xmm3,xmm1

	movdqa	xmm0,xmm4
	movdqa	xmm1,xmm4
	pandn	xmm0,xmm2
	movdqa	xmm2,xmm4
	pandn	xmm1,xmm3
	movdqa	xmm3,xmm4
	pand	xmm2,XMMWORD[448+rsp]
	pand	xmm3,XMMWORD[((448+16))+rsp]
	por	xmm2,xmm0
	por	xmm3,xmm1
	movdqu	XMMWORD[64+rdi],xmm2
	movdqu	XMMWORD[80+rdi],xmm3

	movdqa	xmm0,xmm5
	movdqa	xmm1,xmm5
	pandn	xmm0,XMMWORD[288+rsp]
	movdqa	xmm2,xmm5
	pandn	xmm1,XMMWORD[((288+16))+rsp]
	movdqa	xmm3,xmm5
	pand	xmm2,XMMWORD[480+rsp]
	pand	xmm3,XMMWORD[((480+16))+rsp]
	por	xmm2,xmm0
	por	xmm3,xmm1

	movdqa	xmm0,xmm4
	movdqa	xmm1,xmm4
	pandn	xmm0,xmm2
	movdqa	xmm2,xmm4
	pandn	xmm1,xmm3
	movdqa	xmm3,xmm4
	pand	xmm2,XMMWORD[384+rsp]
	pand	xmm3,XMMWORD[((384+16))+rsp]
	por	xmm2,xmm0
	por	xmm3,xmm1
	movdqu	XMMWORD[rdi],xmm2
	movdqu	XMMWORD[16+rdi],xmm3

	movdqa	xmm0,xmm5
	movdqa	xmm1,xmm5
	pandn	xmm0,XMMWORD[320+rsp]
	movdqa	xmm2,xmm5
	pandn	xmm1,XMMWORD[((320+16))+rsp]
	movdqa	xmm3,xmm5
	pand	xmm2,XMMWORD[512+rsp]
	pand	xmm3,XMMWORD[((512+16))+rsp]
	por	xmm2,xmm0
	por	xmm3,xmm1

	movdqa	xmm0,xmm4
	movdqa	xmm1,xmm4
	pandn	xmm0,xmm2
	movdqa	xmm2,xmm4
	pandn	xmm1,xmm3
	movdqa	xmm3,xmm4
	pand	xmm2,XMMWORD[416+rsp]
	pand	xmm3,XMMWORD[((416+16))+rsp]
	por	xmm2,xmm0
	por	xmm3,xmm1
	movdqu	XMMWORD[32+rdi],xmm2
	movdqu	XMMWORD[48+rdi],xmm3

$L$add_doneq:
	add	rsp,32*18+8
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	rbx
	pop	rbp
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_ecp_nistz256_point_add:
global	ecp_nistz256_point_add_affine

ALIGN	32
ecp_nistz256_point_add_affine:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_ecp_nistz256_point_add_affine:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8


	push	rbp
	push	rbx
	push	r12
	push	r13
	push	r14
	push	r15
	sub	rsp,32*15+8

	movdqu	xmm0,XMMWORD[rsi]
	mov	rbx,rdx
	movdqu	xmm1,XMMWORD[16+rsi]
	movdqu	xmm2,XMMWORD[32+rsi]
	movdqu	xmm3,XMMWORD[48+rsi]
	movdqu	xmm4,XMMWORD[64+rsi]
	movdqu	xmm5,XMMWORD[80+rsi]
	mov	rax,QWORD[((64+0))+rsi]
	mov	r14,QWORD[((64+8))+rsi]
	mov	r15,QWORD[((64+16))+rsi]
	mov	r8,QWORD[((64+24))+rsi]
	movdqa	XMMWORD[320+rsp],xmm0
	movdqa	XMMWORD[(320+16)+rsp],xmm1
	por	xmm1,xmm0
	movdqa	XMMWORD[352+rsp],xmm2
	movdqa	XMMWORD[(352+16)+rsp],xmm3
	por	xmm3,xmm2
	movdqa	XMMWORD[384+rsp],xmm4
	movdqa	XMMWORD[(384+16)+rsp],xmm5
	por	xmm3,xmm1

	movdqu	xmm0,XMMWORD[rbx]
	pshufd	xmm5,xmm3,0xb1
	movdqu	xmm1,XMMWORD[16+rbx]
	movdqu	xmm2,XMMWORD[32+rbx]
	por	xmm5,xmm3
	movdqu	xmm3,XMMWORD[48+rbx]
	movdqa	XMMWORD[416+rsp],xmm0
	pshufd	xmm4,xmm5,0x1e
	movdqa	XMMWORD[(416+16)+rsp],xmm1
	por	xmm1,xmm0
DB	102,72,15,110,199
	movdqa	XMMWORD[448+rsp],xmm2
	movdqa	XMMWORD[(448+16)+rsp],xmm3
	por	xmm3,xmm2
	por	xmm5,xmm4
	pxor	xmm4,xmm4
	por	xmm3,xmm1

	lea	rsi,[((64-0))+rsi]
	lea	rdi,[32+rsp]
	call	__ecp_nistz256_sqr_montq

	pcmpeqd	xmm5,xmm4
	pshufd	xmm4,xmm3,0xb1
	mov	rax,QWORD[rbx]

	mov	r9,r12
	por	xmm4,xmm3
	pshufd	xmm5,xmm5,0
	pshufd	xmm3,xmm4,0x1e
	mov	r10,r13
	por	xmm4,xmm3
	pxor	xmm3,xmm3
	mov	r11,r14
	pcmpeqd	xmm4,xmm3
	pshufd	xmm4,xmm4,0

	lea	rsi,[((32-0))+rsp]
	mov	r12,r15
	lea	rdi,[rsp]
	call	__ecp_nistz256_mul_montq

	lea	rbx,[320+rsp]
	lea	rdi,[64+rsp]
	call	__ecp_nistz256_sub_fromq

	mov	rax,QWORD[384+rsp]
	lea	rbx,[384+rsp]
	mov	r9,QWORD[((0+32))+rsp]
	mov	r10,QWORD[((8+32))+rsp]
	lea	rsi,[((0+32))+rsp]
	mov	r11,QWORD[((16+32))+rsp]
	mov	r12,QWORD[((24+32))+rsp]
	lea	rdi,[32+rsp]
	call	__ecp_nistz256_mul_montq

	mov	rax,QWORD[384+rsp]
	lea	rbx,[384+rsp]
	mov	r9,QWORD[((0+64))+rsp]
	mov	r10,QWORD[((8+64))+rsp]
	lea	rsi,[((0+64))+rsp]
	mov	r11,QWORD[((16+64))+rsp]
	mov	r12,QWORD[((24+64))+rsp]
	lea	rdi,[288+rsp]
	call	__ecp_nistz256_mul_montq

	mov	rax,QWORD[448+rsp]
	lea	rbx,[448+rsp]
	mov	r9,QWORD[((0+32))+rsp]
	mov	r10,QWORD[((8+32))+rsp]
	lea	rsi,[((0+32))+rsp]
	mov	r11,QWORD[((16+32))+rsp]
	mov	r12,QWORD[((24+32))+rsp]
	lea	rdi,[32+rsp]
	call	__ecp_nistz256_mul_montq

	lea	rbx,[352+rsp]
	lea	rdi,[96+rsp]
	call	__ecp_nistz256_sub_fromq

	mov	rax,QWORD[((0+64))+rsp]
	mov	r14,QWORD[((8+64))+rsp]
	lea	rsi,[((0+64))+rsp]
	mov	r15,QWORD[((16+64))+rsp]
	mov	r8,QWORD[((24+64))+rsp]
	lea	rdi,[128+rsp]
	call	__ecp_nistz256_sqr_montq

	mov	rax,QWORD[((0+96))+rsp]
	mov	r14,QWORD[((8+96))+rsp]
	lea	rsi,[((0+96))+rsp]
	mov	r15,QWORD[((16+96))+rsp]
	mov	r8,QWORD[((24+96))+rsp]
	lea	rdi,[192+rsp]
	call	__ecp_nistz256_sqr_montq

	mov	rax,QWORD[128+rsp]
	lea	rbx,[128+rsp]
	mov	r9,QWORD[((0+64))+rsp]
	mov	r10,QWORD[((8+64))+rsp]
	lea	rsi,[((0+64))+rsp]
	mov	r11,QWORD[((16+64))+rsp]
	mov	r12,QWORD[((24+64))+rsp]
	lea	rdi,[160+rsp]
	call	__ecp_nistz256_mul_montq

	mov	rax,QWORD[320+rsp]
	lea	rbx,[320+rsp]
	mov	r9,QWORD[((0+128))+rsp]
	mov	r10,QWORD[((8+128))+rsp]
	lea	rsi,[((0+128))+rsp]
	mov	r11,QWORD[((16+128))+rsp]
	mov	r12,QWORD[((24+128))+rsp]
	lea	rdi,[rsp]
	call	__ecp_nistz256_mul_montq




	add	r12,r12
	lea	rsi,[192+rsp]
	adc	r13,r13
	mov	rax,r12
	adc	r8,r8
	adc	r9,r9
	mov	rbp,r13
	sbb	r11,r11

	sub	r12,-1
	mov	rcx,r8
	sbb	r13,r14
	sbb	r8,0
	mov	r10,r9
	sbb	r9,r15
	test	r11,r11

	cmovz	r12,rax
	mov	rax,QWORD[rsi]
	cmovz	r13,rbp
	mov	rbp,QWORD[8+rsi]
	cmovz	r8,rcx
	mov	rcx,QWORD[16+rsi]
	cmovz	r9,r10
	mov	r10,QWORD[24+rsi]

	call	__ecp_nistz256_subq

	lea	rbx,[160+rsp]
	lea	rdi,[224+rsp]
	call	__ecp_nistz256_sub_fromq

	mov	rax,QWORD[((0+0))+rsp]
	mov	rbp,QWORD[((0+8))+rsp]
	mov	rcx,QWORD[((0+16))+rsp]
	mov	r10,QWORD[((0+24))+rsp]
	lea	rdi,[64+rsp]

	call	__ecp_nistz256_subq

	mov	QWORD[rdi],r12
	mov	QWORD[8+rdi],r13
	mov	QWORD[16+rdi],r8
	mov	QWORD[24+rdi],r9
	mov	rax,QWORD[352+rsp]
	lea	rbx,[352+rsp]
	mov	r9,QWORD[((0+160))+rsp]
	mov	r10,QWORD[((8+160))+rsp]
	lea	rsi,[((0+160))+rsp]
	mov	r11,QWORD[((16+160))+rsp]
	mov	r12,QWORD[((24+160))+rsp]
	lea	rdi,[32+rsp]
	call	__ecp_nistz256_mul_montq

	mov	rax,QWORD[96+rsp]
	lea	rbx,[96+rsp]
	mov	r9,QWORD[((0+64))+rsp]
	mov	r10,QWORD[((8+64))+rsp]
	lea	rsi,[((0+64))+rsp]
	mov	r11,QWORD[((16+64))+rsp]
	mov	r12,QWORD[((24+64))+rsp]
	lea	rdi,[64+rsp]
	call	__ecp_nistz256_mul_montq

	lea	rbx,[32+rsp]
	lea	rdi,[256+rsp]
	call	__ecp_nistz256_sub_fromq

DB	102,72,15,126,199

	movdqa	xmm0,xmm5
	movdqa	xmm1,xmm5
	pandn	xmm0,XMMWORD[288+rsp]
	movdqa	xmm2,xmm5
	pandn	xmm1,XMMWORD[((288+16))+rsp]
	movdqa	xmm3,xmm5
	pand	xmm2,XMMWORD[$L$ONE_mont]
	pand	xmm3,XMMWORD[(($L$ONE_mont+16))]
	por	xmm2,xmm0
	por	xmm3,xmm1

	movdqa	xmm0,xmm4
	movdqa	xmm1,xmm4
	pandn	xmm0,xmm2
	movdqa	xmm2,xmm4
	pandn	xmm1,xmm3
	movdqa	xmm3,xmm4
	pand	xmm2,XMMWORD[384+rsp]
	pand	xmm3,XMMWORD[((384+16))+rsp]
	por	xmm2,xmm0
	por	xmm3,xmm1
	movdqu	XMMWORD[64+rdi],xmm2
	movdqu	XMMWORD[80+rdi],xmm3

	movdqa	xmm0,xmm5
	movdqa	xmm1,xmm5
	pandn	xmm0,XMMWORD[224+rsp]
	movdqa	xmm2,xmm5
	pandn	xmm1,XMMWORD[((224+16))+rsp]
	movdqa	xmm3,xmm5
	pand	xmm2,XMMWORD[416+rsp]
	pand	xmm3,XMMWORD[((416+16))+rsp]
	por	xmm2,xmm0
	por	xmm3,xmm1

	movdqa	xmm0,xmm4
	movdqa	xmm1,xmm4
	pandn	xmm0,xmm2
	movdqa	xmm2,xmm4
	pandn	xmm1,xmm3
	movdqa	xmm3,xmm4
	pand	xmm2,XMMWORD[320+rsp]
	pand	xmm3,XMMWORD[((320+16))+rsp]
	por	xmm2,xmm0
	por	xmm3,xmm1
	movdqu	XMMWORD[rdi],xmm2
	movdqu	XMMWORD[16+rdi],xmm3

	movdqa	xmm0,xmm5
	movdqa	xmm1,xmm5
	pandn	xmm0,XMMWORD[256+rsp]
	movdqa	xmm2,xmm5
	pandn	xmm1,XMMWORD[((256+16))+rsp]
	movdqa	xmm3,xmm5
	pand	xmm2,XMMWORD[448+rsp]
	pand	xmm3,XMMWORD[((448+16))+rsp]
	por	xmm2,xmm0
	por	xmm3,xmm1

	movdqa	xmm0,xmm4
	movdqa	xmm1,xmm4
	pandn	xmm0,xmm2
	movdqa	xmm2,xmm4
	pandn	xmm1,xmm3
	movdqa	xmm3,xmm4
	pand	xmm2,XMMWORD[352+rsp]
	pand	xmm3,XMMWORD[((352+16))+rsp]
	por	xmm2,xmm0
	por	xmm3,xmm1
	movdqu	XMMWORD[32+rdi],xmm2
	movdqu	XMMWORD[48+rdi],xmm3

	add	rsp,32*15+8
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	rbx
	pop	rbp
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_ecp_nistz256_point_add_affine:
