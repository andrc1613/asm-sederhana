section .data
    title db 'Rock-Paper-Scissors!', 0xa
    lenTitle equ $ - title
    
    mode db '[1] Quick Play (FT2)', 0xa, '[2] Competitive (FT3)', 0xa, '[3] Tournament (FT5)', 0xa
    lenMode equ $ - mode

    askMode db 'Select mode to play: '
    lenAskMode equ $ - askMode

    howtoplay db 'How to play:', 0xa, 'Input R(Rock), P(Paper), or S(Scissors) every round.', 0xa, 'The first person to reach the goal point is the winner.',0xa
    lenhtp equ $ - howtoplay

    round db 'Round '
    lenround equ $ - round

    pick db 'Pick your champion: '
    lenpick equ $ - pick

    winmsg db 'You win!', 10
    lenwinmsg equ $ - winmsg

    losemsg db 'You lose!', 10
    lenlosemsg equ $ - losemsg

    drawmsg db 'Draw!', 10
    lendrawmsg equ $ - drawmsg

    wonmsg db 'Congrats! You won the battle!', 10
    lenwonmsg equ $ - wonmsg

    lostmsg db 'Too bad! Better luck next time!', 10
    lenlostmsg equ $ - lostmsg

    finalscoremsg db 'Final Score: '
    lenfinalscoremsg equ $ - finalscoremsg

    invalid db 'Duar! Instruksi bad.', 10
    leninvalid equ $ - invalid

    sds db ' - '
    lensds equ $ - sds

    space5 db '     '
    nl db 10
    rng db 0

section .text
    global _start


;main program
_start:
    push ebp
    mov ebp, esp
    sub esp, 1

    call menuOutput         ; print menu
    
    mov eax, 3              ; syscall input mode
    mov ebx, 1
    lea ecx, [ebp-1]
    mov edx, 2
    int 0x80

    cmp byte [ebp-1], 49    ; validate input
    jl bad_instruction
    cmp byte [ebp-1], 51
    jg bad_instruction

    call howToPlayOutput    ; print how to play

    xor edx, edx
    mov dl, byte [ebp-1]
    call battle            ; move to battle screen

    mov eax, 1              ; syscall exit
    int 0x80

battle:
    push ebp
    mov ebp, esp
    sub esp, 19
    ;[ebp-19] = enemypick
    ;[ebp-18] = yourpick
    ;[ebp-16] = enemyscore
    ;[ebp-12] = yourscore
    ;[ebp-8] = round
    ;[ebp-4] = goalscore

    cmp dl, 49                  ; validate goalscore
    je quickplay
    cmp dl, 50
    je competitive
    mov dword [ebp-4], 5        ; tournament goalscore
    jmp initbattle
    quickplay:
        mov dword [ebp-4], 2    ; quickplay goalscore
        jmp initbattle
    competitive:
        mov dword [ebp-4], 3    ; competitive goalscore
    initbattle:
        mov dword [ebp-16], 0   ; init enemyscore
        mov dword [ebp-12], 0   ; init yourscore
        mov dword [ebp-8], 1    ; init round

    battleloop:
        roundstart:
            mov eax, 4                  ; print round
            mov ebx, 1
            mov ecx, round
            mov edx, lenround
            int 0x80

            mov eax, dword [ebp-8]
            push eax
            call printNum

            mov eax, 4
            mov ebx, 1
            mov ecx, space5
            mov edx, 5
            int 0x80

            mov eax, dword [ebp-12]     ; print yourscore
            push eax
            call printNum

            call spacedashspace

            mov eax, dword [ebp-16]     ; print enemyscore
            push eax
            call printNum
            call _nl

        enemypick:
            call randInt               ; create random number from 0-9
            cmp al, 3
            jle enemypickrock           ; 0-3 = rock
            cmp al, 6
            jle enemypickpaper          ; 4-6 = paper
            mov byte [ebp-19], 83       ; 7-9 = scissors
            jmp yourpick
            enemypickrock:
                mov byte [ebp-19], 82
                jmp yourpick
            enemypickpaper:
                mov byte [ebp-19], 80

        yourpick:
            mov eax, 4
            mov ebx, 1
            mov ecx, pick
            mov edx, lenpick
            int 0x80
            
            mov eax, 3              ; syscall input pick
            mov ebx, 1
            lea ecx, [ebp-18]
            mov edx, 2
            int 0x80

            cmp byte [ebp-18], 80   ; validate pick input
            je printpicks
            cmp byte [ebp-18], 82
            je printpicks
            cmp byte [ebp-18], 83
            je printpicks
            jmp bad_instruction
        
        printpicks:
            mov eax, 4              ; print your pick
            mov ebx, 1
            lea ecx, [ebp-18]
            mov edx, 1
            int 0x80
            
            call spacedashspace

            mov eax, 4              ; print enemy pick
            mov ebx, 1
            lea ecx, [ebp-19]
            mov edx, 1
            int 0x80
            call _nl

        verdict:
            mov al, byte [ebp-18]
            mov bl, byte [ebp-19]
            cmp al, bl              ; if same pick, draw occurs
            je draw
            cmp al, 80              ; yourpick = paper
            je papervs
            cmp al, 82              ; yourpick = rock
            je rockvs
            cmp bl, 82              ; if enemy pick rock, you lose. else, you win
            je youlose
            jmp youwin
            
            draw:
                mov eax, 4
                mov ebx, 1
                mov ecx, drawmsg
                mov edx, lendrawmsg
                int 0x80    
                jmp roundend
                
            papervs:
                cmp bl, 83          ; if enemy pick scissors, you lose. else, you win
                je youlose
                jmp youwin
            
            rockvs:
                cmp bl, 80          ; if enemy pick paper, you lose. else, you win
                je youlose
            
            youwin:
                xor eax, eax
                mov eax, dword [ebp-12] ; yourscore++
                inc eax
                mov dword [ebp-12], eax

                mov eax, 4
                mov ebx, 1
                mov ecx, winmsg
                mov edx, lenwinmsg
                int 0x80

                jmp roundend
            
            youlose:
                xor eax, eax
                mov eax, dword [ebp-16] ; enemyscore++
                inc eax
                mov dword [ebp-16], eax
                
                cmp dword [ebp-16], 1
                mov eax, 4
                mov ebx, 1
                mov ecx, losemsg
                mov edx, lenlosemsg
                int 0x80

        roundend:
            mov eax, dword [ebp-8]  ; round++
            inc eax
            mov dword [ebp-8], eax
            call _nl
            mov eax, dword [ebp-12] 
            mov ebx, dword [ebp-4]
            cmp eax, ebx            ; check if yourscore has reached the goalscore
            je results
            mov eax, dword [ebp-16]
            mov ebx, dword [ebp-4]
            cmp eax, ebx            ; check if enemyscore has reached the goalscore
            je results
            jmp battleloop
    
    results:
        mov eax, 4
        mov ebx, 1
        mov ecx, finalscoremsg
        mov edx, lenfinalscoremsg
        int 0x80

        mov eax, dword [ebp-12]     ; print final score
        push eax
        call printNum

        call spacedashspace

        mov eax, dword [ebp-16]
        push eax
        call printNum
        call _nl

        mov eax, dword [ebp-12]
        mov ebx, dword [ebp-4]
        cmp eax, ebx                ; you won the game
        je youwon
        mov ecx, lostmsg            ; you lost the game
        mov edx, lenlostmsg
        mov eax, 4
        mov ebx, 1
        int 0x80

        jmp end
        youwon:
            mov ecx, wonmsg
            mov edx, lenwonmsg
            mov eax, 4
            mov ebx, 1
            int 0x80
    end:
        leave
        ret

; prints a new line
_nl:
    push ebp
    mov ebp, esp

    mov eax, 4
    mov ebx, 1
    mov ecx, nl
    mov edx, 1
    int 0x80
    
    leave
    ret

; menu output handler
menuOutput:
    push ebp
    mov ebp, esp
    
    ; print title
    mov eax, 4
    mov ebx, 1
    mov ecx, title
    mov edx, lenTitle
    int 0x80
    
    ; print mode
    mov eax, 4
    mov ebx, 1
    mov ecx, mode
    mov edx, lenMode
    int 0x80

    ; ask mode
    mov eax, 4
    mov ebx, 1
    mov ecx, askMode
    mov edx, lenAskMode
    int 0x80    

    leave
    ret

; how to play handler
howToPlayOutput:
    push ebp
    mov ebp, esp

    mov eax, 4
    mov ebx, 1
    mov ecx, howtoplay
    mov edx, lenhtp
    int 0x80 

    leave
    ret

;instruksi tidak sesuai
bad_instruction:
    push ebp
    mov ebp, esp
    mov eax, 4
    mov ebx, 1
    mov ecx, invalid
    mov edx, leninvalid
    int 0x80

    mov eax, 1
    int 0x80

    leave
    ret

; print number (taken from reference)
printNum:
	push ebp
	mov ebp, esp

	sub esp, 8
	mov dword [ebp-4], 0
	mov dword [ebp-8], 0		; char s[8]

	xor ecx, ecx				; i = 0

	xor eax, eax				; eax = 0
	mov eax, [ebp+8]			; eax = num

	printnumloop:
		xor edx, edx 			; d = 0

		mov ebx, 10
		div ebx					; edx = eax % 10
								; eax = eax / 10

		add edx, 48 			; d = eax%10+'0'
		lea ebx, [ebp-1]
		sub ebx, ecx 			; b = *s+4-i
		mov [ebx], dl 			; s[b] = d
		inc ecx 				; i++

		cmp eax, 0 				; if num!=0
		jne printnumloop 		; loop

	lea	edx,[ecx+1]				; write length
	lea ecx, [ebp]				; string to write
	sub ecx, edx
	mov	ebx, 1
	mov	eax, 4
	int	0x80 

	mov eax, [ebp+8]

	leave
	ret

; space dash space
spacedashspace:
    push ebp
    mov ebp, esp

    mov eax, 4
    mov ebx, 1
    mov ecx, sds
    mov edx, lensds
    int 0x80

    leave
    ret

; generate a random integer (taken from reference)
randInt:
    push ebp
    mov ebp, esp
    sub esp, 4

    mov dword [ebp-4], 0
    lea ebx, [ebp-4]
    mov eax, 13
    int 0x80

    mov eax, ebx
    add eax, [rng]
    mov ebx, 347
    mul ebx
    add eax, 71
    inc dword [rng]

    and eax, 0xff
    leave
    ret