default	rel
%define XMMWORD
%define YMMWORD
%define ZMMWORD
section	.text code align=64


EXTERN	OPENSSL_ia32cap_P

global	rsaz_512_sqr

ALIGN	32
rsaz_512_sqr:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_rsaz_512_sqr:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]


	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15

	sub	rsp,128+24
$L$sqr_body:
	mov	rbp,rdx
	mov	rdx,QWORD[rsi]
	mov	rax,QWORD[8+rsi]
	mov	QWORD[128+rsp],rcx
	jmp	NEAR $L$oop_sqr

ALIGN	32
$L$oop_sqr:
	mov	DWORD[((128+8))+rsp],r8d

	mov	rbx,rdx
	mul	rdx
	mov	r8,rax
	mov	rax,QWORD[16+rsi]
	mov	r9,rdx

	mul	rbx
	add	r9,rax
	mov	rax,QWORD[24+rsi]
	mov	r10,rdx
	adc	r10,0

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[32+rsi]
	mov	r11,rdx
	adc	r11,0

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[40+rsi]
	mov	r12,rdx
	adc	r12,0

	mul	rbx
	add	r12,rax
	mov	rax,QWORD[48+rsi]
	mov	r13,rdx
	adc	r13,0

	mul	rbx
	add	r13,rax
	mov	rax,QWORD[56+rsi]
	mov	r14,rdx
	adc	r14,0

	mul	rbx
	add	r14,rax
	mov	rax,rbx
	mov	r15,rdx
	adc	r15,0

	add	r8,r8
	mov	rcx,r9
	adc	r9,r9

	mul	rax
	mov	QWORD[rsp],rax
	add	r8,rdx
	adc	r9,0

	mov	QWORD[8+rsp],r8
	shr	rcx,63


	mov	r8,QWORD[8+rsi]
	mov	rax,QWORD[16+rsi]
	mul	r8
	add	r10,rax
	mov	rax,QWORD[24+rsi]
	mov	rbx,rdx
	adc	rbx,0

	mul	r8
	add	r11,rax
	mov	rax,QWORD[32+rsi]
	adc	rdx,0
	add	r11,rbx
	mov	rbx,rdx
	adc	rbx,0

	mul	r8
	add	r12,rax
	mov	rax,QWORD[40+rsi]
	adc	rdx,0
	add	r12,rbx
	mov	rbx,rdx
	adc	rbx,0

	mul	r8
	add	r13,rax
	mov	rax,QWORD[48+rsi]
	adc	rdx,0
	add	r13,rbx
	mov	rbx,rdx
	adc	rbx,0

	mul	r8
	add	r14,rax
	mov	rax,QWORD[56+rsi]
	adc	rdx,0
	add	r14,rbx
	mov	rbx,rdx
	adc	rbx,0

	mul	r8
	add	r15,rax
	mov	rax,r8
	adc	rdx,0
	add	r15,rbx
	mov	r8,rdx
	mov	rdx,r10
	adc	r8,0

	add	rdx,rdx
	lea	r10,[r10*2+rcx]
	mov	rbx,r11
	adc	r11,r11

	mul	rax
	add	r9,rax
	adc	r10,rdx
	adc	r11,0

	mov	QWORD[16+rsp],r9
	mov	QWORD[24+rsp],r10
	shr	rbx,63


	mov	r9,QWORD[16+rsi]
	mov	rax,QWORD[24+rsi]
	mul	r9
	add	r12,rax
	mov	rax,QWORD[32+rsi]
	mov	rcx,rdx
	adc	rcx,0

	mul	r9
	add	r13,rax
	mov	rax,QWORD[40+rsi]
	adc	rdx,0
	add	r13,rcx
	mov	rcx,rdx
	adc	rcx,0

	mul	r9
	add	r14,rax
	mov	rax,QWORD[48+rsi]
	adc	rdx,0
	add	r14,rcx
	mov	rcx,rdx
	adc	rcx,0

	mul	r9
	mov	r10,r12
	lea	r12,[r12*2+rbx]
	add	r15,rax
	mov	rax,QWORD[56+rsi]
	adc	rdx,0
	add	r15,rcx
	mov	rcx,rdx
	adc	rcx,0

	mul	r9
	shr	r10,63
	add	r8,rax
	mov	rax,r9
	adc	rdx,0
	add	r8,rcx
	mov	r9,rdx
	adc	r9,0

	mov	rcx,r13
	lea	r13,[r13*2+r10]

	mul	rax
	add	r11,rax
	adc	r12,rdx
	adc	r13,0

	mov	QWORD[32+rsp],r11
	mov	QWORD[40+rsp],r12
	shr	rcx,63


	mov	r10,QWORD[24+rsi]
	mov	rax,QWORD[32+rsi]
	mul	r10
	add	r14,rax
	mov	rax,QWORD[40+rsi]
	mov	rbx,rdx
	adc	rbx,0

	mul	r10
	add	r15,rax
	mov	rax,QWORD[48+rsi]
	adc	rdx,0
	add	r15,rbx
	mov	rbx,rdx
	adc	rbx,0

	mul	r10
	mov	r12,r14
	lea	r14,[r14*2+rcx]
	add	r8,rax
	mov	rax,QWORD[56+rsi]
	adc	rdx,0
	add	r8,rbx
	mov	rbx,rdx
	adc	rbx,0

	mul	r10
	shr	r12,63
	add	r9,rax
	mov	rax,r10
	adc	rdx,0
	add	r9,rbx
	mov	r10,rdx
	adc	r10,0

	mov	rbx,r15
	lea	r15,[r15*2+r12]

	mul	rax
	add	r13,rax
	adc	r14,rdx
	adc	r15,0

	mov	QWORD[48+rsp],r13
	mov	QWORD[56+rsp],r14
	shr	rbx,63


	mov	r11,QWORD[32+rsi]
	mov	rax,QWORD[40+rsi]
	mul	r11
	add	r8,rax
	mov	rax,QWORD[48+rsi]
	mov	rcx,rdx
	adc	rcx,0

	mul	r11
	add	r9,rax
	mov	rax,QWORD[56+rsi]
	adc	rdx,0
	mov	r12,r8
	lea	r8,[r8*2+rbx]
	add	r9,rcx
	mov	rcx,rdx
	adc	rcx,0

	mul	r11
	shr	r12,63
	add	r10,rax
	mov	rax,r11
	adc	rdx,0
	add	r10,rcx
	mov	r11,rdx
	adc	r11,0

	mov	rcx,r9
	lea	r9,[r9*2+r12]

	mul	rax
	add	r15,rax
	adc	r8,rdx
	adc	r9,0

	mov	QWORD[64+rsp],r15
	mov	QWORD[72+rsp],r8
	shr	rcx,63


	mov	r12,QWORD[40+rsi]
	mov	rax,QWORD[48+rsi]
	mul	r12
	add	r10,rax
	mov	rax,QWORD[56+rsi]
	mov	rbx,rdx
	adc	rbx,0

	mul	r12
	add	r11,rax
	mov	rax,r12
	mov	r15,r10
	lea	r10,[r10*2+rcx]
	adc	rdx,0
	shr	r15,63
	add	r11,rbx
	mov	r12,rdx
	adc	r12,0

	mov	rbx,r11
	lea	r11,[r11*2+r15]

	mul	rax
	add	r9,rax
	adc	r10,rdx
	adc	r11,0

	mov	QWORD[80+rsp],r9
	mov	QWORD[88+rsp],r10


	mov	r13,QWORD[48+rsi]
	mov	rax,QWORD[56+rsi]
	mul	r13
	add	r12,rax
	mov	rax,r13
	mov	r13,rdx
	adc	r13,0

	xor	r14,r14
	shl	rbx,1
	adc	r12,r12
	adc	r13,r13
	adc	r14,r14

	mul	rax
	add	r11,rax
	adc	r12,rdx
	adc	r13,0

	mov	QWORD[96+rsp],r11
	mov	QWORD[104+rsp],r12


	mov	rax,QWORD[56+rsi]
	mul	rax
	add	r13,rax
	adc	rdx,0

	add	r14,rdx

	mov	QWORD[112+rsp],r13
	mov	QWORD[120+rsp],r14

	mov	r8,QWORD[rsp]
	mov	r9,QWORD[8+rsp]
	mov	r10,QWORD[16+rsp]
	mov	r11,QWORD[24+rsp]
	mov	r12,QWORD[32+rsp]
	mov	r13,QWORD[40+rsp]
	mov	r14,QWORD[48+rsp]
	mov	r15,QWORD[56+rsp]

	call	__rsaz_512_reduce

	add	r8,QWORD[64+rsp]
	adc	r9,QWORD[72+rsp]
	adc	r10,QWORD[80+rsp]
	adc	r11,QWORD[88+rsp]
	adc	r12,QWORD[96+rsp]
	adc	r13,QWORD[104+rsp]
	adc	r14,QWORD[112+rsp]
	adc	r15,QWORD[120+rsp]
	sbb	rcx,rcx

	call	__rsaz_512_subtract

	mov	rdx,r8
	mov	rax,r9
	mov	r8d,DWORD[((128+8))+rsp]
	mov	rsi,rdi

	dec	r8d
	jnz	NEAR $L$oop_sqr

	lea	rax,[((128+24+48))+rsp]
	mov	r15,QWORD[((-48))+rax]
	mov	r14,QWORD[((-40))+rax]
	mov	r13,QWORD[((-32))+rax]
	mov	r12,QWORD[((-24))+rax]
	mov	rbp,QWORD[((-16))+rax]
	mov	rbx,QWORD[((-8))+rax]
	lea	rsp,[rax]
$L$sqr_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_rsaz_512_sqr:
global	rsaz_512_mul

ALIGN	32
rsaz_512_mul:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_rsaz_512_mul:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]


	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15

	sub	rsp,128+24
$L$mul_body:
DB	102,72,15,110,199
DB	102,72,15,110,201
	mov	QWORD[128+rsp],r8
	mov	rbx,QWORD[rdx]
	mov	rbp,rdx
	call	__rsaz_512_mul

DB	102,72,15,126,199
DB	102,72,15,126,205

	mov	r8,QWORD[rsp]
	mov	r9,QWORD[8+rsp]
	mov	r10,QWORD[16+rsp]
	mov	r11,QWORD[24+rsp]
	mov	r12,QWORD[32+rsp]
	mov	r13,QWORD[40+rsp]
	mov	r14,QWORD[48+rsp]
	mov	r15,QWORD[56+rsp]

	call	__rsaz_512_reduce
	add	r8,QWORD[64+rsp]
	adc	r9,QWORD[72+rsp]
	adc	r10,QWORD[80+rsp]
	adc	r11,QWORD[88+rsp]
	adc	r12,QWORD[96+rsp]
	adc	r13,QWORD[104+rsp]
	adc	r14,QWORD[112+rsp]
	adc	r15,QWORD[120+rsp]
	sbb	rcx,rcx

	call	__rsaz_512_subtract

	lea	rax,[((128+24+48))+rsp]
	mov	r15,QWORD[((-48))+rax]
	mov	r14,QWORD[((-40))+rax]
	mov	r13,QWORD[((-32))+rax]
	mov	r12,QWORD[((-24))+rax]
	mov	rbp,QWORD[((-16))+rax]
	mov	rbx,QWORD[((-8))+rax]
	lea	rsp,[rax]
$L$mul_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_rsaz_512_mul:
global	rsaz_512_mul_gather4

ALIGN	32
rsaz_512_mul_gather4:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_rsaz_512_mul_gather4:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]
	mov	r9,QWORD[48+rsp]


	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15

	sub	rsp,328
	movaps	XMMWORD[160+rsp],xmm6
	movaps	XMMWORD[176+rsp],xmm7
	movaps	XMMWORD[192+rsp],xmm8
	movaps	XMMWORD[208+rsp],xmm9
	movaps	XMMWORD[224+rsp],xmm10
	movaps	XMMWORD[240+rsp],xmm11
	movaps	XMMWORD[256+rsp],xmm12
	movaps	XMMWORD[272+rsp],xmm13
	movaps	XMMWORD[288+rsp],xmm14
	movaps	XMMWORD[304+rsp],xmm15
$L$mul_gather4_body:
	movd	xmm8,r9d
	movdqa	xmm1,XMMWORD[(($L$inc+16))]
	movdqa	xmm0,XMMWORD[$L$inc]

	pshufd	xmm8,xmm8,0
	movdqa	xmm7,xmm1
	movdqa	xmm2,xmm1
	paddd	xmm1,xmm0
	pcmpeqd	xmm0,xmm8
	movdqa	xmm3,xmm7
	paddd	xmm2,xmm1
	pcmpeqd	xmm1,xmm8
	movdqa	xmm4,xmm7
	paddd	xmm3,xmm2
	pcmpeqd	xmm2,xmm8
	movdqa	xmm5,xmm7
	paddd	xmm4,xmm3
	pcmpeqd	xmm3,xmm8
	movdqa	xmm6,xmm7
	paddd	xmm5,xmm4
	pcmpeqd	xmm4,xmm8
	paddd	xmm6,xmm5
	pcmpeqd	xmm5,xmm8
	paddd	xmm7,xmm6
	pcmpeqd	xmm6,xmm8
	pcmpeqd	xmm7,xmm8

	movdqa	xmm8,XMMWORD[rdx]
	movdqa	xmm9,XMMWORD[16+rdx]
	movdqa	xmm10,XMMWORD[32+rdx]
	movdqa	xmm11,XMMWORD[48+rdx]
	pand	xmm8,xmm0
	movdqa	xmm12,XMMWORD[64+rdx]
	pand	xmm9,xmm1
	movdqa	xmm13,XMMWORD[80+rdx]
	pand	xmm10,xmm2
	movdqa	xmm14,XMMWORD[96+rdx]
	pand	xmm11,xmm3
	movdqa	xmm15,XMMWORD[112+rdx]
	lea	rbp,[128+rdx]
	pand	xmm12,xmm4
	pand	xmm13,xmm5
	pand	xmm14,xmm6
	pand	xmm15,xmm7
	por	xmm8,xmm10
	por	xmm9,xmm11
	por	xmm8,xmm12
	por	xmm9,xmm13
	por	xmm8,xmm14
	por	xmm9,xmm15

	por	xmm8,xmm9
	pshufd	xmm9,xmm8,0x4e
	por	xmm8,xmm9
DB	102,76,15,126,195

	mov	QWORD[128+rsp],r8
	mov	QWORD[((128+8))+rsp],rdi
	mov	QWORD[((128+16))+rsp],rcx

	mov	rax,QWORD[rsi]
	mov	rcx,QWORD[8+rsi]
	mul	rbx
	mov	QWORD[rsp],rax
	mov	rax,rcx
	mov	r8,rdx

	mul	rbx
	add	r8,rax
	mov	rax,QWORD[16+rsi]
	mov	r9,rdx
	adc	r9,0

	mul	rbx
	add	r9,rax
	mov	rax,QWORD[24+rsi]
	mov	r10,rdx
	adc	r10,0

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[32+rsi]
	mov	r11,rdx
	adc	r11,0

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[40+rsi]
	mov	r12,rdx
	adc	r12,0

	mul	rbx
	add	r12,rax
	mov	rax,QWORD[48+rsi]
	mov	r13,rdx
	adc	r13,0

	mul	rbx
	add	r13,rax
	mov	rax,QWORD[56+rsi]
	mov	r14,rdx
	adc	r14,0

	mul	rbx
	add	r14,rax
	mov	rax,QWORD[rsi]
	mov	r15,rdx
	adc	r15,0

	lea	rdi,[8+rsp]
	mov	ecx,7
	jmp	NEAR $L$oop_mul_gather

ALIGN	32
$L$oop_mul_gather:
	movdqa	xmm8,XMMWORD[rbp]
	movdqa	xmm9,XMMWORD[16+rbp]
	movdqa	xmm10,XMMWORD[32+rbp]
	movdqa	xmm11,XMMWORD[48+rbp]
	pand	xmm8,xmm0
	movdqa	xmm12,XMMWORD[64+rbp]
	pand	xmm9,xmm1
	movdqa	xmm13,XMMWORD[80+rbp]
	pand	xmm10,xmm2
	movdqa	xmm14,XMMWORD[96+rbp]
	pand	xmm11,xmm3
	movdqa	xmm15,XMMWORD[112+rbp]
	lea	rbp,[128+rbp]
	pand	xmm12,xmm4
	pand	xmm13,xmm5
	pand	xmm14,xmm6
	pand	xmm15,xmm7
	por	xmm8,xmm10
	por	xmm9,xmm11
	por	xmm8,xmm12
	por	xmm9,xmm13
	por	xmm8,xmm14
	por	xmm9,xmm15

	por	xmm8,xmm9
	pshufd	xmm9,xmm8,0x4e
	por	xmm8,xmm9
DB	102,76,15,126,195

	mul	rbx
	add	r8,rax
	mov	rax,QWORD[8+rsi]
	mov	QWORD[rdi],r8
	mov	r8,rdx
	adc	r8,0

	mul	rbx
	add	r9,rax
	mov	rax,QWORD[16+rsi]
	adc	rdx,0
	add	r8,r9
	mov	r9,rdx
	adc	r9,0

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[24+rsi]
	adc	rdx,0
	add	r9,r10
	mov	r10,rdx
	adc	r10,0

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[32+rsi]
	adc	rdx,0
	add	r10,r11
	mov	r11,rdx
	adc	r11,0

	mul	rbx
	add	r12,rax
	mov	rax,QWORD[40+rsi]
	adc	rdx,0
	add	r11,r12
	mov	r12,rdx
	adc	r12,0

	mul	rbx
	add	r13,rax
	mov	rax,QWORD[48+rsi]
	adc	rdx,0
	add	r12,r13
	mov	r13,rdx
	adc	r13,0

	mul	rbx
	add	r14,rax
	mov	rax,QWORD[56+rsi]
	adc	rdx,0
	add	r13,r14
	mov	r14,rdx
	adc	r14,0

	mul	rbx
	add	r15,rax
	mov	rax,QWORD[rsi]
	adc	rdx,0
	add	r14,r15
	mov	r15,rdx
	adc	r15,0

	lea	rdi,[8+rdi]

	dec	ecx
	jnz	NEAR $L$oop_mul_gather

	mov	QWORD[rdi],r8
	mov	QWORD[8+rdi],r9
	mov	QWORD[16+rdi],r10
	mov	QWORD[24+rdi],r11
	mov	QWORD[32+rdi],r12
	mov	QWORD[40+rdi],r13
	mov	QWORD[48+rdi],r14
	mov	QWORD[56+rdi],r15

	mov	rdi,QWORD[((128+8))+rsp]
	mov	rbp,QWORD[((128+16))+rsp]

	mov	r8,QWORD[rsp]
	mov	r9,QWORD[8+rsp]
	mov	r10,QWORD[16+rsp]
	mov	r11,QWORD[24+rsp]
	mov	r12,QWORD[32+rsp]
	mov	r13,QWORD[40+rsp]
	mov	r14,QWORD[48+rsp]
	mov	r15,QWORD[56+rsp]

	call	__rsaz_512_reduce
	add	r8,QWORD[64+rsp]
	adc	r9,QWORD[72+rsp]
	adc	r10,QWORD[80+rsp]
	adc	r11,QWORD[88+rsp]
	adc	r12,QWORD[96+rsp]
	adc	r13,QWORD[104+rsp]
	adc	r14,QWORD[112+rsp]
	adc	r15,QWORD[120+rsp]
	sbb	rcx,rcx

	call	__rsaz_512_subtract

	lea	rax,[((128+24+48))+rsp]
	movaps	xmm6,XMMWORD[((160-200))+rax]
	movaps	xmm7,XMMWORD[((176-200))+rax]
	movaps	xmm8,XMMWORD[((192-200))+rax]
	movaps	xmm9,XMMWORD[((208-200))+rax]
	movaps	xmm10,XMMWORD[((224-200))+rax]
	movaps	xmm11,XMMWORD[((240-200))+rax]
	movaps	xmm12,XMMWORD[((256-200))+rax]
	movaps	xmm13,XMMWORD[((272-200))+rax]
	movaps	xmm14,XMMWORD[((288-200))+rax]
	movaps	xmm15,XMMWORD[((304-200))+rax]
	lea	rax,[176+rax]
	mov	r15,QWORD[((-48))+rax]
	mov	r14,QWORD[((-40))+rax]
	mov	r13,QWORD[((-32))+rax]
	mov	r12,QWORD[((-24))+rax]
	mov	rbp,QWORD[((-16))+rax]
	mov	rbx,QWORD[((-8))+rax]
	lea	rsp,[rax]
$L$mul_gather4_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_rsaz_512_mul_gather4:
global	rsaz_512_mul_scatter4

ALIGN	32
rsaz_512_mul_scatter4:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_rsaz_512_mul_scatter4:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9
	mov	r8,QWORD[40+rsp]
	mov	r9,QWORD[48+rsp]


	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15

	mov	r9d,r9d
	sub	rsp,128+24
$L$mul_scatter4_body:
	lea	r8,[r9*8+r8]
DB	102,72,15,110,199
DB	102,72,15,110,202
DB	102,73,15,110,208
	mov	QWORD[128+rsp],rcx

	mov	rbp,rdi
	mov	rbx,QWORD[rdi]
	call	__rsaz_512_mul

DB	102,72,15,126,199
DB	102,72,15,126,205

	mov	r8,QWORD[rsp]
	mov	r9,QWORD[8+rsp]
	mov	r10,QWORD[16+rsp]
	mov	r11,QWORD[24+rsp]
	mov	r12,QWORD[32+rsp]
	mov	r13,QWORD[40+rsp]
	mov	r14,QWORD[48+rsp]
	mov	r15,QWORD[56+rsp]

	call	__rsaz_512_reduce
	add	r8,QWORD[64+rsp]
	adc	r9,QWORD[72+rsp]
	adc	r10,QWORD[80+rsp]
	adc	r11,QWORD[88+rsp]
	adc	r12,QWORD[96+rsp]
	adc	r13,QWORD[104+rsp]
	adc	r14,QWORD[112+rsp]
	adc	r15,QWORD[120+rsp]
DB	102,72,15,126,214
	sbb	rcx,rcx

	call	__rsaz_512_subtract

	mov	QWORD[rsi],r8
	mov	QWORD[128+rsi],r9
	mov	QWORD[256+rsi],r10
	mov	QWORD[384+rsi],r11
	mov	QWORD[512+rsi],r12
	mov	QWORD[640+rsi],r13
	mov	QWORD[768+rsi],r14
	mov	QWORD[896+rsi],r15

	lea	rax,[((128+24+48))+rsp]
	mov	r15,QWORD[((-48))+rax]
	mov	r14,QWORD[((-40))+rax]
	mov	r13,QWORD[((-32))+rax]
	mov	r12,QWORD[((-24))+rax]
	mov	rbp,QWORD[((-16))+rax]
	mov	rbx,QWORD[((-8))+rax]
	lea	rsp,[rax]
$L$mul_scatter4_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_rsaz_512_mul_scatter4:
global	rsaz_512_mul_by_one

ALIGN	32
rsaz_512_mul_by_one:
	mov	QWORD[8+rsp],rdi	;WIN64 prologue
	mov	QWORD[16+rsp],rsi
	mov	rax,rsp
$L$SEH_begin_rsaz_512_mul_by_one:
	mov	rdi,rcx
	mov	rsi,rdx
	mov	rdx,r8
	mov	rcx,r9


	push	rbx
	push	rbp
	push	r12
	push	r13
	push	r14
	push	r15

	sub	rsp,128+24
$L$mul_by_one_body:
	mov	rbp,rdx
	mov	QWORD[128+rsp],rcx

	mov	r8,QWORD[rsi]
	pxor	xmm0,xmm0
	mov	r9,QWORD[8+rsi]
	mov	r10,QWORD[16+rsi]
	mov	r11,QWORD[24+rsi]
	mov	r12,QWORD[32+rsi]
	mov	r13,QWORD[40+rsi]
	mov	r14,QWORD[48+rsi]
	mov	r15,QWORD[56+rsi]

	movdqa	XMMWORD[rsp],xmm0
	movdqa	XMMWORD[16+rsp],xmm0
	movdqa	XMMWORD[32+rsp],xmm0
	movdqa	XMMWORD[48+rsp],xmm0
	movdqa	XMMWORD[64+rsp],xmm0
	movdqa	XMMWORD[80+rsp],xmm0
	movdqa	XMMWORD[96+rsp],xmm0
	call	__rsaz_512_reduce
	mov	QWORD[rdi],r8
	mov	QWORD[8+rdi],r9
	mov	QWORD[16+rdi],r10
	mov	QWORD[24+rdi],r11
	mov	QWORD[32+rdi],r12
	mov	QWORD[40+rdi],r13
	mov	QWORD[48+rdi],r14
	mov	QWORD[56+rdi],r15

	lea	rax,[((128+24+48))+rsp]
	mov	r15,QWORD[((-48))+rax]
	mov	r14,QWORD[((-40))+rax]
	mov	r13,QWORD[((-32))+rax]
	mov	r12,QWORD[((-24))+rax]
	mov	rbp,QWORD[((-16))+rax]
	mov	rbx,QWORD[((-8))+rax]
	lea	rsp,[rax]
$L$mul_by_one_epilogue:
	mov	rdi,QWORD[8+rsp]	;WIN64 epilogue
	mov	rsi,QWORD[16+rsp]
	DB	0F3h,0C3h		;repret
$L$SEH_end_rsaz_512_mul_by_one:

ALIGN	32
__rsaz_512_reduce:
	mov	rbx,r8
	imul	rbx,QWORD[((128+8))+rsp]
	mov	rax,QWORD[rbp]
	mov	ecx,8
	jmp	NEAR $L$reduction_loop

ALIGN	32
$L$reduction_loop:
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
	mov	rsi,QWORD[((128+8))+rsp]


	adc	rdx,0
	mov	r11,rdx

	mul	rbx
	add	r12,rax
	mov	rax,QWORD[40+rbp]
	adc	rdx,0
	imul	rsi,r8
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
	jne	NEAR $L$reduction_loop

	DB	0F3h,0C3h		;repret


ALIGN	32
__rsaz_512_subtract:
	mov	QWORD[rdi],r8
	mov	QWORD[8+rdi],r9
	mov	QWORD[16+rdi],r10
	mov	QWORD[24+rdi],r11
	mov	QWORD[32+rdi],r12
	mov	QWORD[40+rdi],r13
	mov	QWORD[48+rdi],r14
	mov	QWORD[56+rdi],r15

	mov	r8,QWORD[rbp]
	mov	r9,QWORD[8+rbp]
	neg	r8
	not	r9
	and	r8,rcx
	mov	r10,QWORD[16+rbp]
	and	r9,rcx
	not	r10
	mov	r11,QWORD[24+rbp]
	and	r10,rcx
	not	r11
	mov	r12,QWORD[32+rbp]
	and	r11,rcx
	not	r12
	mov	r13,QWORD[40+rbp]
	and	r12,rcx
	not	r13
	mov	r14,QWORD[48+rbp]
	and	r13,rcx
	not	r14
	mov	r15,QWORD[56+rbp]
	and	r14,rcx
	not	r15
	and	r15,rcx

	add	r8,QWORD[rdi]
	adc	r9,QWORD[8+rdi]
	adc	r10,QWORD[16+rdi]
	adc	r11,QWORD[24+rdi]
	adc	r12,QWORD[32+rdi]
	adc	r13,QWORD[40+rdi]
	adc	r14,QWORD[48+rdi]
	adc	r15,QWORD[56+rdi]

	mov	QWORD[rdi],r8
	mov	QWORD[8+rdi],r9
	mov	QWORD[16+rdi],r10
	mov	QWORD[24+rdi],r11
	mov	QWORD[32+rdi],r12
	mov	QWORD[40+rdi],r13
	mov	QWORD[48+rdi],r14
	mov	QWORD[56+rdi],r15

	DB	0F3h,0C3h		;repret


ALIGN	32
__rsaz_512_mul:
	lea	rdi,[8+rsp]

	mov	rax,QWORD[rsi]
	mul	rbx
	mov	QWORD[rdi],rax
	mov	rax,QWORD[8+rsi]
	mov	r8,rdx

	mul	rbx
	add	r8,rax
	mov	rax,QWORD[16+rsi]
	mov	r9,rdx
	adc	r9,0

	mul	rbx
	add	r9,rax
	mov	rax,QWORD[24+rsi]
	mov	r10,rdx
	adc	r10,0

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[32+rsi]
	mov	r11,rdx
	adc	r11,0

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[40+rsi]
	mov	r12,rdx
	adc	r12,0

	mul	rbx
	add	r12,rax
	mov	rax,QWORD[48+rsi]
	mov	r13,rdx
	adc	r13,0

	mul	rbx
	add	r13,rax
	mov	rax,QWORD[56+rsi]
	mov	r14,rdx
	adc	r14,0

	mul	rbx
	add	r14,rax
	mov	rax,QWORD[rsi]
	mov	r15,rdx
	adc	r15,0

	lea	rbp,[8+rbp]
	lea	rdi,[8+rdi]

	mov	ecx,7
	jmp	NEAR $L$oop_mul

ALIGN	32
$L$oop_mul:
	mov	rbx,QWORD[rbp]
	mul	rbx
	add	r8,rax
	mov	rax,QWORD[8+rsi]
	mov	QWORD[rdi],r8
	mov	r8,rdx
	adc	r8,0

	mul	rbx
	add	r9,rax
	mov	rax,QWORD[16+rsi]
	adc	rdx,0
	add	r8,r9
	mov	r9,rdx
	adc	r9,0

	mul	rbx
	add	r10,rax
	mov	rax,QWORD[24+rsi]
	adc	rdx,0
	add	r9,r10
	mov	r10,rdx
	adc	r10,0

	mul	rbx
	add	r11,rax
	mov	rax,QWORD[32+rsi]
	adc	rdx,0
	add	r10,r11
	mov	r11,rdx
	adc	r11,0

	mul	rbx
	add	r12,rax
	mov	rax,QWORD[40+rsi]
	adc	rdx,0
	add	r11,r12
	mov	r12,rdx
	adc	r12,0

	mul	rbx
	add	r13,rax
	mov	rax,QWORD[48+rsi]
	adc	rdx,0
	add	r12,r13
	mov	r13,rdx
	adc	r13,0

	mul	rbx
	add	r14,rax
	mov	rax,QWORD[56+rsi]
	adc	rdx,0
	add	r13,r14
	mov	r14,rdx
	lea	rbp,[8+rbp]
	adc	r14,0

	mul	rbx
	add	r15,rax
	mov	rax,QWORD[rsi]
	adc	rdx,0
	add	r14,r15
	mov	r15,rdx
	adc	r15,0

	lea	rdi,[8+rdi]

	dec	ecx
	jnz	NEAR $L$oop_mul

	mov	QWORD[rdi],r8
	mov	QWORD[8+rdi],r9
	mov	QWORD[16+rdi],r10
	mov	QWORD[24+rdi],r11
	mov	QWORD[32+rdi],r12
	mov	QWORD[40+rdi],r13
	mov	QWORD[48+rdi],r14
	mov	QWORD[56+rdi],r15

	DB	0F3h,0C3h		;repret

global	rsaz_512_scatter4

ALIGN	16
rsaz_512_scatter4:
	lea	rcx,[r8*8+rcx]
	mov	r9d,8
	jmp	NEAR $L$oop_scatter
ALIGN	16
$L$oop_scatter:
	mov	rax,QWORD[rdx]
	lea	rdx,[8+rdx]
	mov	QWORD[rcx],rax
	lea	rcx,[128+rcx]
	dec	r9d
	jnz	NEAR $L$oop_scatter
	DB	0F3h,0C3h		;repret


global	rsaz_512_gather4

ALIGN	16
rsaz_512_gather4:
$L$SEH_begin_rsaz_512_gather4:
DB	0x48,0x81,0xec,0xa8,0x00,0x00,0x00
DB	0x0f,0x29,0x34,0x24
DB	0x0f,0x29,0x7c,0x24,0x10
DB	0x44,0x0f,0x29,0x44,0x24,0x20
DB	0x44,0x0f,0x29,0x4c,0x24,0x30
DB	0x44,0x0f,0x29,0x54,0x24,0x40
DB	0x44,0x0f,0x29,0x5c,0x24,0x50
DB	0x44,0x0f,0x29,0x64,0x24,0x60
DB	0x44,0x0f,0x29,0x6c,0x24,0x70
DB	0x44,0x0f,0x29,0xb4,0x24,0x80,0,0,0
DB	0x44,0x0f,0x29,0xbc,0x24,0x90,0,0,0
	movd	xmm8,r8d
	movdqa	xmm1,XMMWORD[(($L$inc+16))]
	movdqa	xmm0,XMMWORD[$L$inc]

	pshufd	xmm8,xmm8,0
	movdqa	xmm7,xmm1
	movdqa	xmm2,xmm1
	paddd	xmm1,xmm0
	pcmpeqd	xmm0,xmm8
	movdqa	xmm3,xmm7
	paddd	xmm2,xmm1
	pcmpeqd	xmm1,xmm8
	movdqa	xmm4,xmm7
	paddd	xmm3,xmm2
	pcmpeqd	xmm2,xmm8
	movdqa	xmm5,xmm7
	paddd	xmm4,xmm3
	pcmpeqd	xmm3,xmm8
	movdqa	xmm6,xmm7
	paddd	xmm5,xmm4
	pcmpeqd	xmm4,xmm8
	paddd	xmm6,xmm5
	pcmpeqd	xmm5,xmm8
	paddd	xmm7,xmm6
	pcmpeqd	xmm6,xmm8
	pcmpeqd	xmm7,xmm8
	mov	r9d,8
	jmp	NEAR $L$oop_gather
ALIGN	16
$L$oop_gather:
	movdqa	xmm8,XMMWORD[rdx]
	movdqa	xmm9,XMMWORD[16+rdx]
	movdqa	xmm10,XMMWORD[32+rdx]
	movdqa	xmm11,XMMWORD[48+rdx]
	pand	xmm8,xmm0
	movdqa	xmm12,XMMWORD[64+rdx]
	pand	xmm9,xmm1
	movdqa	xmm13,XMMWORD[80+rdx]
	pand	xmm10,xmm2
	movdqa	xmm14,XMMWORD[96+rdx]
	pand	xmm11,xmm3
	movdqa	xmm15,XMMWORD[112+rdx]
	lea	rdx,[128+rdx]
	pand	xmm12,xmm4
	pand	xmm13,xmm5
	pand	xmm14,xmm6
	pand	xmm15,xmm7
	por	xmm8,xmm10
	por	xmm9,xmm11
	por	xmm8,xmm12
	por	xmm9,xmm13
	por	xmm8,xmm14
	por	xmm9,xmm15

	por	xmm8,xmm9
	pshufd	xmm9,xmm8,0x4e
	por	xmm8,xmm9
	movq	QWORD[rcx],xmm8
	lea	rcx,[8+rcx]
	dec	r9d
	jnz	NEAR $L$oop_gather
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
	add	rsp,0xa8
	DB	0F3h,0C3h		;repret
$L$SEH_end_rsaz_512_gather4:


ALIGN	64
$L$inc:
	DD	0,0,1,1
	DD	2,2,2,2
EXTERN	__imp_RtlVirtualUnwind

ALIGN	16
se_handler:
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

	lea	rax,[((128+24+48))+rax]

	lea	rbx,[$L$mul_gather4_epilogue]
	cmp	rbx,r10
	jne	NEAR $L$se_not_in_mul_gather4

	lea	rax,[176+rax]

	lea	rsi,[((-48-168))+rax]
	lea	rdi,[512+r8]
	mov	ecx,20
	DD	0xa548f3fc

$L$se_not_in_mul_gather4:
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
	DD	$L$SEH_begin_rsaz_512_sqr wrt ..imagebase
	DD	$L$SEH_end_rsaz_512_sqr wrt ..imagebase
	DD	$L$SEH_info_rsaz_512_sqr wrt ..imagebase

	DD	$L$SEH_begin_rsaz_512_mul wrt ..imagebase
	DD	$L$SEH_end_rsaz_512_mul wrt ..imagebase
	DD	$L$SEH_info_rsaz_512_mul wrt ..imagebase

	DD	$L$SEH_begin_rsaz_512_mul_gather4 wrt ..imagebase
	DD	$L$SEH_end_rsaz_512_mul_gather4 wrt ..imagebase
	DD	$L$SEH_info_rsaz_512_mul_gather4 wrt ..imagebase

	DD	$L$SEH_begin_rsaz_512_mul_scatter4 wrt ..imagebase
	DD	$L$SEH_end_rsaz_512_mul_scatter4 wrt ..imagebase
	DD	$L$SEH_info_rsaz_512_mul_scatter4 wrt ..imagebase

	DD	$L$SEH_begin_rsaz_512_mul_by_one wrt ..imagebase
	DD	$L$SEH_end_rsaz_512_mul_by_one wrt ..imagebase
	DD	$L$SEH_info_rsaz_512_mul_by_one wrt ..imagebase

	DD	$L$SEH_begin_rsaz_512_gather4 wrt ..imagebase
	DD	$L$SEH_end_rsaz_512_gather4 wrt ..imagebase
	DD	$L$SEH_info_rsaz_512_gather4 wrt ..imagebase

section	.xdata rdata align=8
ALIGN	8
$L$SEH_info_rsaz_512_sqr:
DB	9,0,0,0
	DD	se_handler wrt ..imagebase
	DD	$L$sqr_body wrt ..imagebase,$L$sqr_epilogue wrt ..imagebase
$L$SEH_info_rsaz_512_mul:
DB	9,0,0,0
	DD	se_handler wrt ..imagebase
	DD	$L$mul_body wrt ..imagebase,$L$mul_epilogue wrt ..imagebase
$L$SEH_info_rsaz_512_mul_gather4:
DB	9,0,0,0
	DD	se_handler wrt ..imagebase
	DD	$L$mul_gather4_body wrt ..imagebase,$L$mul_gather4_epilogue wrt ..imagebase
$L$SEH_info_rsaz_512_mul_scatter4:
DB	9,0,0,0
	DD	se_handler wrt ..imagebase
	DD	$L$mul_scatter4_body wrt ..imagebase,$L$mul_scatter4_epilogue wrt ..imagebase
$L$SEH_info_rsaz_512_mul_by_one:
DB	9,0,0,0
	DD	se_handler wrt ..imagebase
	DD	$L$mul_by_one_body wrt ..imagebase,$L$mul_by_one_epilogue wrt ..imagebase
$L$SEH_info_rsaz_512_gather4:
DB	0x01,0x46,0x16,0x00
DB	0x46,0xf8,0x09,0x00
DB	0x3d,0xe8,0x08,0x00
DB	0x34,0xd8,0x07,0x00
DB	0x2e,0xc8,0x06,0x00
DB	0x28,0xb8,0x05,0x00
DB	0x22,0xa8,0x04,0x00
DB	0x1c,0x98,0x03,0x00
DB	0x16,0x88,0x02,0x00
DB	0x10,0x78,0x01,0x00
DB	0x0b,0x68,0x00,0x00
DB	0x07,0x01,0x15,0x00
