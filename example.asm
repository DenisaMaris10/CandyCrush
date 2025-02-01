.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern rand: proc
extern srand:proc
includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Exemplu proiect desenare",0
area_width EQU 800
area_height EQU 600
area DD 0

counter DD 0 ; numara evenimentele de tip timer
stare_counter_start DD 0 ; valoarea counter-ului cand starea a devenit 1

; declararea matricii care sa ne spuna ce bomboane avem pe tabla 
matrix_width EQU 5						
matrix_height EQU 5
matrix DD matrix_width*matrix_height DUP(0) ; voi folosi matrix ca o matrice care pastreaza ce bomboane se afla pe fiecare pozitie, 
											; dar pe care am creat-o ca un sir mai lung 
area_matrix DD matrix_width*matrix_height

matrix_coordinate_x EQU 300
matrix_coordinate_y EQU 200
moves_left DD 15 ;numarul de mutari ramase

pictures_pointers DD offset var1_0, offset var2_0, offset var3_0, offset var4_0, offset var5_0

indice DD 0 
pointer_spre_inceputul_pozei DD 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

image_width EQU 40
image_height EQU 40
include Poze_40.txt

upper DD 4 ;avem maxim 5 bomboane din care putem alege
lower DD 0 

rez_rand DD 0

candy1_x DD 0
candy1_y DD 0
candy1_coordinare_1D DD 0
candy2_x DD 0
candy2_y DD 0
candy2_coordinare_1D DD 0

;;;; coordonate care sa ajute sa fie mai eficienta doborarea/eliminarea bomboanelor
coordinate_x_start_strike DD 0 
coordinate_y_start_strike DD 0
coordinate_x_end_strike DD 0
coordinate_y_end_strike DD 0

liniar_coordinate_start_strike DD 0
liniar_coordinate_end_strike DD 0
which_candy_in_strike DD 0 ; aici se va salva ce bomboana este in strike
number_candies_in_strike DD 0
if_strike DD 0 ; va fi 0 daca nu s-a gasit pana acuma strike sau 1 daca s-a gasit un strike

numar_bomboane_selectate DD 0

square_coordinate_x DD 0
square_coordinate_y DD 0

first_move_made DD 0
mutare_posibila DD 0
score DD 0
castigat DB 0
pierdut DB 0

win_text_coordinate_x DD 0
win_text_coordinate_y DD 0

scor_castig DD 50

culoare_fundal_mesaj DD 0 ; variabila asta o folosesc pentru a colora difetit fundalul fiecarui text

shuffle_switch DD 0 ; va fi 1 cand se cere din functia de shuffle sa se faca interchimbare si va fi 1 cand se va cere sa se faca interschimbare cabd se face o mutare 
shuffle_counter DD 0 ; va fi 0 cand nu s-a ales inca un numar random ( care reprezinta pozitia 

small_square_coordinate_x DD 0
small_square_coordinate_y DD 0

stare DD 0
ajutor_pt_timer DD 0

if_possible_move DD 0
liniar_position_start_possible_move DD 0
liniar_position_end_possible_move DD 0
which_candy_in_possible_move DD 0
number_candies_in_possible_move DD 0
position_in_matrix DD 0 ;;;;

coord_candy1_x DD 0
coord_candy2_x DD 0
coord_candy1_y DD 0
coord_candy2_y DD 0

.code

;;;;; functia asta e pentru a genera numere random intre 0 si 4 pt crea matricea cu bomboane
get_random_number proc 
	
	push ebp
	mov ebp, esp
	pusha
	
	call rand
	mov ebx, upper
	sub ebx, lower
	inc ebx
	div ebx
	add edx, lower
	mov eax, edx
	
	mov rez_rand, eax
	
	popa
	
	mov eax, rez_rand
	
	mov esp, ebp
	pop ebp
	ret
get_random_number endp

get_delay proc
	push ebp
	mov ebp, esp
	pusha 

	mov ecx, 1000
	delay:
		push ecx
		mov ecx, 1000
		delay_2:
			nop
		loop delay_2
		pop ecx
	loop delay
	mov stare, 0
	
	popa
	mov esp, ebp
	pop ebp
	ret
get_delay endp

;;;;; functie care amesteca bomboanele din matrice
shuffle proc
	push ebp
	mov ebp, esp
	pusha
	
	mov upper, matrix_width*matrix_height-1 ; pentru get_random_number, 25 de pozitii liniare
	mov shuffle_switch, 1
	mov ecx, 50 
	amesteca:
		call get_random_number
		mov edx, eax
		call get_random_number
		push edx
		push eax
		call switch_candies
		add esp, 8
	loop amesteca 
	
	mov shuffle_switch, 0
	
	popa
	mov esp, ebp
	pop ebp
	ret
shuffle endp

;;;; functie pentru a afla pozitia in functie de x si y a unui element din matrix 
position_2_D macro position_1_D ; eax<- x, edx<- y
	xor edx, edx
	mov eax, position_1_D
	mov ebx, matrix_width
	div ebx
	push eax
	mov eax, edx
	pop edx
endm

position_1_D_from_2_D macro x, y
	mov eax, matrix_width
	mul y ; eax = matrix_width*y 
	add eax, x ; eax = (matrix_width*y)+x
endm

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

;;;;; functia switch_candies primeste ca parametri indicii in sirul matrix a celor 2 bomboane care trebuie interschimbate
switch_candies proc 
	push ebp
	mov ebp, esp
	pusha
	
	interschimbare_shuffle:
	
	mov eax, [ebp+arg2]
	mov ebx, [ebp+arg1]
	
	cmp shuffle_switch, 1
	je inter
	
	cmp eax, ebx
	je mutare_imposibila
	position_2_D [ebp+arg1]
	mov coord_candy1_x, eax
	mov coord_candy1_y, edx
	position_2_D [ebp+arg2]
	mov coord_candy2_x, eax
	mov coord_candy2_y, edx
	
	mov eax, coord_candy1_x
	cmp eax, coord_candy2_x
	jne verificare_y
	mov eax, coord_candy1_y
	sub eax, coord_candy2_y
	cmp eax, 1
	je interschimbare
	cmp eax, -1 
	jne mutare_imposibila
	jmp interschimbare
	
	verificare_y:
	mov eax, coord_candy1_y
	cmp eax, coord_candy2_y
	jne mutare_imposibila
	mov eax, coord_candy1_x
	sub eax, coord_candy2_x
	cmp eax, 1
	je interschimbare
	cmp eax, -1
	jne mutare_imposibila
	; cmp eax, ebx 
	; jl mai_mic
	; mai_mare: ;;;; aici e zona in care se verifica daca mutarea e corecta si indicele bomboanei de la primul click de pe tabla e mai mare decat indicele bomboanei de la al 2-lea click de pe tabla 
	; sub eax, ebx
	; cmp eax, 1
	; je interschimbare
	; cmp eax, matrix_width 
	; jne mutare_imposibila
	; jmp interschimbare
	; mai_mic:
	; sub ebx, eax
	; cmp ebx, 1
	; je interschimbare
	; cmp ebx, matrix_width
	; jne mutare_imposibila
	; jmp interschimbare
	
	inter:
	cmp eax, ebx 
	je iesire
	jmp doar_schimbare
	
	interschimbare:
	
	make_text_macro ' ', area, 100, 300
	make_text_macro ' ', area, 110, 300
	make_text_macro ' ', area, 120, 300
	make_text_macro ' ', area, 130, 300
	make_text_macro ' ', area, 140, 300
	make_text_macro ' ', area, 150, 300
	
	make_text_macro ' ', area, 70, 330
	make_text_macro ' ', area, 80, 330
	make_text_macro ' ', area, 90, 330
	make_text_macro ' ', area, 100, 330
	make_text_macro ' ', area, 110, 330
	make_text_macro ' ', area, 120, 330
	make_text_macro ' ', area, 130, 330
	make_text_macro ' ', area, 140, 330
	make_text_macro ' ', area, 150, 330
	make_text_macro ' ', area, 160, 330
	
	doar_schimbare:
	mov edx, [ebp+arg2]
	mov ecx, [ebp+arg1]
	mov eax, matrix[4*edx]
	mov ebx, matrix[4*ecx]
	mov matrix[4*ecx], eax
	mov matrix[4*edx], ebx
	
	mov mutare_posibila, 1
	
	jmp iesire
	
	mutare_imposibila: 
	
	mov mutare_posibila, 0
	make_text_macro 'M', area, 100, 300
	make_text_macro 'U', area, 110, 300
	make_text_macro 'T', area, 120, 300
	make_text_macro 'A', area, 130, 300
	make_text_macro 'R', area, 140, 300
	make_text_macro 'E', area, 150, 300
	
	make_text_macro 'I', area, 70, 330
	make_text_macro 'M', area, 80, 330
	make_text_macro 'P', area, 90, 330
	make_text_macro 'O', area, 100, 330
	make_text_macro 'S', area, 110, 330
	make_text_macro 'I', area, 120, 330
	make_text_macro 'B', area, 130, 330
	make_text_macro 'I', area, 140, 330
	make_text_macro 'L', area, 150, 330
	make_text_macro 'A', area, 160, 330
	
	iesire:
	
	popa
	mov esp, ebp
	pop ebp
	ret
switch_candies endp

;;;;;; functie care elimina bomboanele care sunt cel putin 3 una langa alta
eliminate proc
	push ebp
	mov ebp, esp
	pusha
	
	mov upper, 4 ; pentru get_random_number, 5 tipuri de bomboane
	
	position_2_D liniar_coordinate_start_strike
	mov coordinate_x_start_strike, eax
	mov coordinate_y_start_strike, edx
	position_2_D liniar_coordinate_end_strike
	mov coordinate_x_end_strike, eax
	mov coordinate_y_end_strike, edx
	mov eax, coordinate_x_start_strike
	cmp eax, coordinate_x_end_strike
	jne strike_pe_linie
	
	strike_pe_coloana:  ;; daca e strike pe coloana, atunci, dupa ce se elimina bomboanele din strike, se vor adauga in locul lor (pe acea coloana)
						;"number_candies_in_strike" bomboane generate random, iar celelalte bomboane ramase pe acea coloana vor cadea
	mov ecx, number_candies_in_strike
	mov ebx, liniar_coordinate_end_strike
	parcurgere_linii:
		push ecx
		push ebx
		mov ecx, coordinate_y_end_strike
		coborare_bomboane_pe_coloane:
			sub ebx, matrix_width
			mov edx, matrix[ebx*4]
			add ebx, matrix_width
			mov matrix[ebx*4], edx
			sub ebx, matrix_width
		loop coborare_bomboane_pe_coloane
		adaugare_bomboane_random:
		mov ebx, coordinate_x_start_strike
		xor ecx, ecx
		position_1_D_from_2_D ebx, ecx
		mov ebx, eax
		call get_random_number
		mov matrix[ebx*4], eax
		pop ebx
		pop ecx
	loop parcurgere_linii
	jmp final_eliminare
	
	strike_pe_linie:    ;; daca e strike pe linie, atunci, dupa ce se elimina bomboanele din strike, se vor adauga in locul lor (adica pe prima linie)
						;"number_candies_in_strike" bomboane generate random, iar celelalte bomboane ramase pe acea coloana vor cadea 
	mov ecx, number_candies_in_strike
	mov ebx, liniar_coordinate_start_strike
	mov edx, coordinate_x_start_strike; coloana pe care scriu noua bomboana
	parcurgere_coloane:
		push ecx
		push ebx
		mov ecx, coordinate_y_end_strike
		cmp ecx, 0
		je adaugare_bomboane_random1
		coborare_bomboane_pe_linii:
			sub ebx, matrix_width
			mov esi, matrix[ebx*4]
			add ebx, matrix_width
			mov matrix[ebx*4], esi
			sub ebx, matrix_width
		loop coborare_bomboane_pe_linii
		adaugare_bomboane_random1:
		mov ebx, edx
		push edx
		xor edx, edx
		xor ecx, ecx
		position_1_D_from_2_D ebx, ecx
		mov ebx, eax
		call get_random_number
		mov matrix[ebx*4], eax
		pop edx
		inc edx
		pop ebx
		inc ebx
		pop ecx
	loop parcurgere_coloane
	
	final_eliminare:
	
	popa
	mov esp, ebp
	pop ebp
	ret
eliminate endp 

;;;;;; functie care verifica daca exista cel putin 3 bomboane de acelasi fel una langa alta
verify_3_or_more_candies proc 
	push ebp
	mov ebp, esp
	pusha
	
	mov if_strike, 0
	xor edx, edx
	mov ecx, matrix_height
	;verific pe fiecare linie daca sunt cel putin 3 bomboane una langa alta
	trecere_de_la_o_linie_la_alta:
		push ecx
		mov ecx, matrix_width
		dec ecx
		;cmp edx, 0
		;jne cautare_pe_linii
		mov eax, matrix[4*edx]
		mov which_candy_in_strike, eax
		mov liniar_coordinate_start_strike, edx
		mov number_candies_in_strike, 1
		;cmp edx, 0
		;jne cautare_pe_linii
		inc edx
		jmp cautare_pe_linii
		jump_intermediar:
		jmp trecere_de_la_o_linie_la_alta
		cautare_pe_linii:
			compare:
			mov eax, matrix[4*edx]
			cmp which_candy_in_strike, eax
			jne nu_sunt_egale
			inc number_candies_in_strike
			dec ecx
			inc edx
			cmp ecx, 0
			je nu_sunt_egale
			jmp compare
			nu_sunt_egale:
			cmp number_candies_in_strike, 3
			jl nu_e_strike
			dec edx
			mov liniar_coordinate_end_strike, edx
			inc edx ; nu cred ca am nevoie de asta
			mov if_strike, 1
			add esp, 4
			jmp final
			nu_e_strike:
			mov liniar_coordinate_start_strike, edx
			mov number_candies_in_strike, 1 ;;;;;cand ajunge la sfarsitul unei linii va creste edx de 2 ori si nu va mai compara ce trebuie + va merge in spatii de memorie de dupa matrice
			mov ebx, matrix[4*edx]
			mov which_candy_in_strike, ebx
			cmp ecx, 0
			je final_linie
			inc edx
		loop cautare_pe_linii
		final_linie:
		pop ecx
	loop jump_intermediar
	;verific pe fiecare coloana daca sunt cel putin 3 bomboane una langa alta
	mov ecx, matrix_width
	xor ebx, ebx
	xor edx, edx
	trecere_de_la_o_coloana_la_alta:
		push ecx
		mov edx, ebx
		push ebx
		mov ebx, matrix[4*edx]
		mov which_candy_in_strike, ebx
		mov liniar_coordinate_start_strike, edx
		mov number_candies_in_strike, 1
		add edx, matrix_width
		mov ecx, matrix_height
		dec ecx
		jmp cautare_pe_coloana
		jump_intermediar1:
		jmp trecere_de_la_o_coloana_la_alta
		cautare_pe_coloana:
			compare1:
			mov eax, matrix[4*edx]
			cmp which_candy_in_strike, eax
			jne nu_sunt_egale1
			inc number_candies_in_strike
			add edx, matrix_width
			dec ecx
			cmp ecx, 0
			je nu_sunt_egale1
			jmp compare1
			nu_sunt_egale1:
			cmp number_candies_in_strike, 3
			jl nu_e_strike1
			sub edx, matrix_width
			mov liniar_coordinate_end_strike, edx
			add edx, matrix_width
			mov if_strike, 1
			add esp, 8
			jmp final
			nu_e_strike1:
			mov number_candies_in_strike, 1
			mov liniar_coordinate_start_strike, edx
			mov ebx, matrix[4*edx]
			mov which_candy_in_strike, ebx
			add edx, matrix_width
			cmp ecx, 0
			je final_linie1
		loop cautare_pe_coloana
		final_linie1:
		pop ebx 
		inc ebx
		pop ecx
	loop jump_intermediar1
	final:
	
	popa
	mov esp, ebp
	pop ebp
	ret
verify_3_or_more_candies endp

;;;;; functie care sa verifice daca mai sunt mutari posibile
verify_possible_move proc
	push ebp
	mov ebp, esp
	pusha
	
	mov if_possible_move, 0
	mov ecx, matrix_height
	xor edx, edx
	;;;;; in momentul in care voi apela functia asta, nu ar trebui sa mai existe nicio grupare de mai mult de 3 bomboane 
	;;;;; voi merge prima data pe fiecare linie si in momentul in care voi gasi 2 bomboane una langa alta, voi verifica daca de la pozitia celor 2 bomboane +/- 2 sau la pozitia
	;;;;; bomboanei +/- (matrix_width+1) bomboana este de acelasi fel cu cele 2 gasite inainte
	cautare_mutare_pe_linii:
		push ecx
		mov liniar_position_start_possible_move, edx
		mov ebx, matrix[4*edx]
		mov which_candy_in_possible_move, ebx
		mov ecx, matrix_width - 1
		traversare_coloane:
			inc edx
			push edx
			dec ecx
			mov eax, matrix[4*edx]
			cmp eax, which_candy_in_possible_move
			jne nu_sunt_egale_move
			mov liniar_position_end_possible_move, edx
			
			comparare_coloana_dreapta:
			
			position_2_D liniar_position_end_possible_move
			cmp eax, matrix_width-2
			jge comparare_coloana_stanga
			mov ebx, liniar_position_end_possible_move
			add ebx, 2
			mov eax, matrix[4*ebx]
			cmp eax, which_candy_in_possible_move
			je final_verificare_mutare_posibila_linii

			
			comparare_coloana_stanga:
			position_2_d liniar_position_start_possible_move
			cmp eax, 1
			jle comparare_linie_jos_stanga
			mov ebx, liniar_position_end_possible_move
			sub ebx, 2
			mov eax, matrix[4*ebx]
			cmp eax, which_candy_in_possible_move
			je final_verificare_mutare_posibila_linii
			
			comparare_linie_jos_stanga:
			position_2_D liniar_position_start_possible_move
			cmp eax, 0
			je comparare_linie_jos_dreapta
			cmp edx, matrix_height-1
			je comparare_linie_jos_dreapta
			mov ebx, liniar_position_end_possible_move
			dec ebx
			add ebx, matrix_width
			mov eax, matrix[4*ebx]
			cmp eax, which_candy_in_possible_move
			je final_verificare_mutare_posibila_linii
			
			comparare_linie_jos_dreapta:
			position_2_D liniar_position_end_possible_move
			cmp eax, matrix_width-1
			je comparare_linie_sus_dreapta
			cmp edx, matrix_height-1
			je comparare_linie_sus_dreapta
			mov ebx, liniar_position_start_possible_move
			inc ebx
			add ebx, matrix_width
			mov eax, matrix[4*ebx]
			cmp eax, which_candy_in_possible_move
			je final_verificare_mutare_posibila_linii
			
			
			comparare_linie_sus_dreapta:
			position_2_D liniar_position_end_possible_move
			cmp eax, matrix_width-1
			je comparare_linie_sus_stanga
			cmp edx, 0
			je comparare_linie_sus_stanga
			mov ebx, liniar_position_end_possible_move
			inc ebx
			sub ebx, matrix_width
			mov eax, matrix[4*ebx]
			cmp eax, which_candy_in_possible_move
			je final_verificare_mutare_posibila_linii
			
			
			comparare_linie_sus_stanga:
			position_2_D liniar_position_start_possible_move
			cmp eax, 0
			je nu_sunt_egale_move
			cmp edx, 0
			je nu_sunt_egale_move
			mov ebx, liniar_position_start_possible_move
			dec ebx
			sub ebx, matrix_width
			mov eax, matrix[4*ebx]
			cmp eax, which_candy_in_possible_move
			je final_verificare_mutare_posibila_linii
			
			
			nu_sunt_egale_move:
			pop edx
			mov liniar_position_start_possible_move, edx
			mov eax, matrix[4*edx]
			mov which_candy_in_possible_move, eax
			cmp ecx, 0
			je final_linie_move
			
		dec ecx
		cmp ecx, 0
		jg traversare_coloane
		
		final_linie_move:
		pop ecx
	
	dec ecx
	cmp ecx, 0
	jg cautare_mutare_pe_linii
	
	;;;; cautam pe coloane
	mov ecx, matrix_width
	xor edx, edx
	xor ebx, ebx
	cautare_mutare_pe_coloane:
		push ecx
		mov edx, ebx
		push ebx
		mov ebx, matrix[4*edx]
		mov which_candy_in_possible_move, ebx 
		mov liniar_position_start_possible_move, edx
		mov ecx, matrix_height - 1
		
		traversare_linii:
			add edx, matrix_width
			mov eax, matrix[4*edx]
			push edx
			dec ecx
			cmp eax, which_candy_in_possible_move
			jne nu_sunt_egale_move1
			mov liniar_position_end_possible_move, edx
			
			comparare_coloana_jos:
			position_2_D liniar_position_end_possible_move
			cmp edx, matrix_height-2
			jge comparare_coloana_sus
			mov ebx, liniar_position_end_possible_move
			add ebx, 2*matrix_width
			mov eax, matrix[4*ebx]
			cmp eax, which_candy_in_possible_move
			je final_verificare_mutare_posibila_coloane
			
			comparare_coloana_sus:
			position_2_D liniar_position_start_possible_move
			cmp edx, 1
			jle comparare_linie_stanga_jos
			mov ebx, liniar_position_start_possible_move
			sub ebx, 2*matrix_width
			mov eax, matrix[4*ebx]
			cmp eax, which_candy_in_possible_move
			je final_verificare_mutare_posibila_coloane
		
			
			comparare_linie_stanga_jos:
			position_2_D liniar_position_end_possible_move
			cmp eax, 0
			je comparare_linie_dreapta_jos
			cmp edx, matrix_height-1
			je comparare_linie_dreapta_jos
			mov ebx, liniar_position_end_possible_move
			dec ebx
			add ebx, matrix_width
			mov eax, matrix[4*ebx]
			cmp eax, which_candy_in_possible_move
			je final_verificare_mutare_posibila_coloane
			
			
			comparare_linie_dreapta_jos:
			position_2_D liniar_position_end_possible_move
			cmp eax, matrix_width-1
			je comparare_linie_stanga_sus
			cmp edx, matrix_height-1
			je comparare_linie_stanga_sus
			mov ebx, liniar_coordinate_end_strike
			inc ebx
			add ebx, matrix_height
			mov eax, matrix[4*ebx]
			cmp eax, which_candy_in_possible_move
			je final_verificare_mutare_posibila_coloane
			
			comparare_linie_stanga_sus:
			position_2_D liniar_position_start_possible_move
			cmp eax, 0
			je comparare_linie_dreapta_sus
			cmp edx, 0
			je comparare_linie_dreapta_sus
			mov ebx, liniar_position_start_possible_move
			dec ebx
			sub ebx, matrix_width 
			mov eax, matrix[4*ebx]
			cmp eax, which_candy_in_possible_move
			je final_verificare_mutare_posibila_coloane
			
			
			comparare_linie_dreapta_sus:
			position_2_D liniar_position_start_possible_move
			cmp eax, matrix_width-1
			je nu_sunt_egale_move1
			cmp edx, 0
			je nu_sunt_egale_move1
			mov ebx, liniar_position_start_possible_move
			inc ebx
			sub ebx, matrix_width
			mov eax, matrix[4*ebx]
			cmp eax, which_candy_in_possible_move
			je final_verificare_mutare_posibila_coloane
			
			nu_sunt_egale_move1:
			pop edx
			mov liniar_position_start_possible_move, edx
			mov eax, matrix[4*edx]
			mov which_candy_in_possible_move, eax
			cmp ecx, 0
			je fin_coloana
		
		dec ecx
		cmp ecx, 0
		jg traversare_linii
		
		
		fin_coloana:
		pop ebx
		inc ebx
		pop ecx
		
	dec ecx
	cmp ecx, 0
	jg cautare_mutare_pe_coloane
	
	jmp final_fara_mutare
	
	final_verificare_mutare_posibila_coloane:
	add esp, 4 ; ebx is on the stack when checking columns
	final_verificare_mutare_posibila_linii:
	add esp, 8 ; ecx and edx are on the stack both when checking columns and lines
	mov if_possible_move, 1
	
	final_fara_mutare:
	
	popa
	mov esp, ebp
	pop ebp
	ret
verify_possible_move endp

;;;;; functie care calculeaza coordonatele x si y din matrixea de bomboane pentru coordonatele la care s-a facut click
position_from_pixels_matrix_to_matrix_if_candies proc 
	push ebp
	mov ebp, esp
	pusha
	
	xor eax, eax
	xor edx, edx
	mov eax, [ebp+arg1]
	sub eax, matrix_coordinate_x
	mov ebx, image_width
	div ebx
	mov [ebp+arg1], eax
	xor edx, edx
	mov eax, [ebp+arg2]
	sub eax, matrix_coordinate_y
	mov ebx, image_height
	div ebx
	mov [ebp+arg2], eax
	
	popa
	mov esp, ebp
	pop ebp
	ret
position_from_pixels_matrix_to_matrix_if_candies endp


;;;;; functie care calculeaza pozitia la care trebuie sa se deseneze o anumita bomboana din matrice
get_position proc ; aflam pozitia de unde sa inceapa sa se deseneze poza de la pozitia matrix[x][y] 
	push ebp
	mov ebp, esp
	pusha 
	
	; mov eax, image_width
	; mov ebx, matrix_width
	; mul ebx; eax = image_width * matrix_width
	
	; mov ebx, image_height
	; mul ebx; eax = image_width * matrix_width * image_height
	
	; mul dword ptr [ebp+arg2]; eax = image_width * matrix_width * image_height * y
	
	mov eax, area_width
	mov ebx, image_height
	mul ebx
	mul dword ptr [ebp+arg2]; eax = y * area_width * image_height
	
	push eax
	
	mov eax, [ebp+arg1]
	mov ebx, image_width
	
	mul ebx; eax = image_width * x
	
	pop ebx
	add eax, ebx
	
	shl eax, 2 ; eax=(y*matrix_width+x)*4

	add eax, area
	mov pointer_spre_inceputul_pozei, eax
	
	popa
	mov eax, pointer_spre_inceputul_pozei
	mov esp, ebp
	pop ebp
	ret
get_position endp



;;;;; aici se va crea matricea care reprezinta pe fiecare pozitie ce bomboane sa fie afisate
make_matrix proc 

	push ebp
	mov ebp, esp
	pusha
	
	mov upper, 4 ; pentru get_random_number, 5 tipuri de bomboane
	
	xor ebx, ebx
	mov ecx, area_matrix
	gen_nr_matrice:
		call get_random_number
		mov matrix[ebx], eax
		add ebx, 4
	loop gen_nr_matrice
	
	popa
	mov esp, ebp
	pop ebp
	ret
make_matrix endp

;;;;; functia care afiseaza toate bomboanele din matricea matrix
draw_matrix_of_candies proc
	push ebp
	mov ebp, esp
	pusha
	
	mov ecx, matrix_width*matrix_height
	xor ebx, ebx
	afisare_bomboane:
		push ecx
		mov indice, ebx
		position_2_D ebx
		push edx
		push eax
		call get_position
		add esp, 8
		push eax
		mov ebx, indice
		shl ebx, 2
		mov edx, matrix[ebx]
		push edx
		call draw_candy
		add esp, 8
		pop ecx
		mov ebx, indice
		inc ebx
	loop afisare_bomboane
	
	popa
	mov esp, ebp
	pop ebp
	ret
draw_matrix_of_candies endp



; un macro ca sa desenam bomboanele
make_image_macro macro drawArea, x, y, candy;, candy
	push candy
	push y
	push x
	push drawArea
	call make_image
	add esp, 16
endm

make_image proc
	push ebp
	mov ebp, esp
	pusha

	;lea esi, picture_pointer
	mov eax, [ebp+arg4] ; ce avem in eax sa il dam ca parametru pentru functie si reprezinta "numarul" bomboanei, adica felul ei
	shl eax, 2
	mov esi, [pictures_pointers+eax]
	
	mov ecx, image_height
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, image_height 
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, image_width ; store drawing width for drawing loop
	
	loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	
	; cmp ecx, 20
	; jg go
	; mov ecx, 1
; go:
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_image endp

draw_candy proc
	push ebp
	mov ebp, esp
	pusha

	mov edx, [ebp+arg1]
	;initialize window with white pixels
	; mov eax, area_width
	; mov ebx, area_height
	; mul ebx
	; shl eax, 2
	; push eax
	; push 255
	; push area
	; call memset
	; add esp, 12

	mov eax, [ebp+arg2]
	make_image_macro eax, matrix_coordinate_x, matrix_coordinate_y, edx 

	popa
	mov esp, ebp
	pop ebp
	ret
draw_candy endp

; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	cmp eax, ' '
	jg make_exclamation_point
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	jmp draw_text
make_exclamation_point:
	mov eax, 27 ; de la 0 pana la 25 sunt litere, 26 e space, 27 e semnul exclamarii
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp



line_horizontal macro x, y, len, color
local bucla_linie
	mov eax, y ; eax=y
	mov ebx, area_width
	mul ebx  ;eax=y*area_width
	add eax, x; eax=y*area_width+x
	shl eax, 2;
	add eax, area
	mov ecx, len
	bucla_linie:
		mov dword ptr[eax], color
		add eax, 4
	loop bucla_linie
endm

line_vertical macro x, y, len, color
local bucla_coloana
	mov eax, y ; eax=y
	mov ebx, area_width
	mul ebx  ;eax=y*area_width
	add eax, x; eax=y*area_width+x
	shl eax, 2;
	add eax, area
	mov ecx, len
	bucla_coloana:
		mov dword ptr[eax], color
		add eax, area_width*4
	loop bucla_coloana
endm

;;;;functie care mixeaza 2 culori
blend proc ; arg1 prima culoare, arg2 a doua culoare, returneaza in eax amestecul
	push ebp
	mov ebp, esp
	
	push 0
	pusha
	mov ecx, 4
	l:
		xor eax, eax
		xor ebx, ebx
		mov al, byte ptr [ebp+arg1+ecx-1] 
		mov bl, byte ptr [ebp+arg2+ecx-1]
		add ax, bx
		shr ax, 1
		mov byte ptr [ebp-4+ecx-1], al
	loop l
	
	popa
	pop eax;;;;pune in eax culoarea mixata
	mov esp, ebp
	pop ebp
	ret
blend endp


; functie care imi mixeaza cu alb fiecare pixel de pe matrice -> functia o apelez cand pierde sau cand castiga jucatorul
coloreaza_alb proc
	push ebp
	mov ebp, esp

	pusha
	
	; esi = y
	; edi = x
	
	; ecx = limit of y
	; edx = limit of x
	
	mov esi, matrix_coordinate_y
	mov ecx, matrix_coordinate_y + matrix_height*image_height
	
	mov edx, matrix_coordinate_x + matrix_width*image_width
	
	loop_y:
	cmp esi, ecx
	jg afara_y
	
		mov edi, matrix_coordinate_x
		
		loop_x:
		cmp edi, edx
		jg afara_x
		
			mov eax, esi
			mov ebx, area_width
			push edx
			mul ebx
			pop edx
			add eax, edi
			shl eax, 2
			add eax, area
			
			
			push eax
			push [eax]
			push 0ffffffffh
			call blend
			add esp, 8
			mov ebx, eax
			pop eax
			mov dword ptr[eax], ebx
		
		inc edi
		jmp loop_x
		
		afara_x:
		
	inc esi
	jmp loop_y
	
	afara_y:
	
	popa
	
	mov esp, ebp
	pop ebp
	ret
coloreaza_alb endp

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	;;;;;am facut pauza pentru a putea sa mai bine fiecare grup eliminat 
	cmp stare, 1
	jne peste_pauza
	inc counter
	mov eax, counter
	sub eax, stare_counter_start
	cmp eax, 5
	
	jl final_draw
	mov stare, 0 
	
	peste_pauza:
	
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	jmp afisare_litere

evt_click:
	;line_horizontal [ebp+arg2], [ebp+arg3], 30, 0FFh
	mov eax, [ebp+arg2]
	cmp eax, matrix_coordinate_x
	jl candy_chosen_fail ;;;; sa modific: jl verificare_buton_shuffle
	cmp eax, matrix_coordinate_x + matrix_width * image_width
	jg candy_chosen_fail
	mov eax, [ebp+arg3]
	cmp eax, matrix_coordinate_y
	jl candy_chosen_fail
	cmp eax, matrix_coordinate_y + matrix_height * image_height
	jg candy_chosen_fail
	
	cmp numar_bomboane_selectate, 0
	
	mov stare, 0 ;;;;;pentru stare
	
	jne a_doua_bomboana_selectata
	mov eax, [ebp+arg2]
	mov ebx, [ebp+arg3]
	push ebx
	push eax
	call position_from_pixels_matrix_to_matrix_if_candies
	pop ebx
	pop eax
	mov candy1_x, ebx
	mov candy1_y, eax
	position_1_D_from_2_D candy1_x, candy1_y
	mov candy1_coordinare_1D, eax
	inc numar_bomboane_selectate
	
	;;;; creare patrat pentru prima bomboana selectata de jucator
	mov eax, [ebp+arg2] 
	sub eax, matrix_coordinate_x
	mov ebx, image_width
	div ebx
	mov ebx, image_width
	mul ebx
	add eax, matrix_coordinate_x
	mov small_square_coordinate_x, eax
	
	mov eax, [ebp+arg3]
	sub eax, matrix_coordinate_y
	mov ebx, image_height
	div ebx
	mov ebx, image_height
	mul ebx
	add eax, matrix_coordinate_y
	mov small_square_coordinate_y, eax
	
	jmp continuare
	a_doua_bomboana_selectata:
	mov numar_bomboane_selectate, 0
	mov eax, [ebp+arg2]
	mov ebx, [ebp+arg3]
	push ebx
	push eax
	call position_from_pixels_matrix_to_matrix_if_candies
	pop ebx
	pop eax
	mov candy2_x, ebx
	mov candy2_y, eax
	position_1_D_from_2_D candy2_x, candy2_y
	mov candy2_coordinare_1D, eax
	mov eax, candy1_coordinare_1D
	mov ebx, candy2_coordinare_1D
	push eax
	push ebx 
	call switch_candies
	add esp, 8
	cmp mutare_posibila, 1
	jne continuare
	call verify_3_or_more_candies
	cmp if_strike, 1
	je continuare
	mov eax, candy1_coordinare_1D
	mov ebx, candy2_coordinare_1D
	push eax
	push ebx 
	call switch_candies
	add esp, 8
	
	
	
	continuare:
	
	cmp if_strike, 1
	jne continue
	mov first_move_made, 1
	dec moves_left
	cmp moves_left, 0 
	je ai_pierdut
	continue:
	make_text_macro ' ', area, 10, 300
	make_text_macro ' ', area, 20, 300

	make_text_macro ' ', area, 40, 300
	make_text_macro ' ', area, 50, 300
	make_text_macro ' ', area, 60, 300
	
	make_text_macro ' ', area, 80, 300
	make_text_macro ' ', area, 90, 300
	;make_text_macro ' ', area, 100, 300
	
	make_text_macro ' ', area, 20, 350
	make_text_macro ' ', area, 30, 350
	make_text_macro ' ', area, 40, 350
	make_text_macro ' ', area, 50, 350
	make_text_macro ' ', area, 60, 350
	
	make_text_macro ' ', area, 80, 350
	make_text_macro ' ', area, 90, 350
	make_text_macro ' ', area, 100, 350
	;; aici sa pun continuarea, adica trebuie sa fac sa astept pana primeste al doilea click si pe urma sa fac o functie in care sa verific daca interschimbandu-le pe 	
	;; cele doua bomboane se face un lant de cel putin 3 bomboane si dupa ce verific trebuie sa afisez daca se poate face, adica sa afisez cum arata matricea cu bomboanele 
	;; interschimbate ( cred ) si pe urma cum arata matricea dupa ce elimin bomboanele care sunt 3 de acelasi fel una langa alta 
	;; pe urma trebuie sa verific in continuare daca mai exista zone care pot fi eliminate + o functie care verifica daca mai sunt mutari posibile
	jmp afisare_litere
	
	candy_chosen_fail:
	mov numar_bomboane_selectate, 0
	; mov eax, [ebp+arg2]
	; mov ebx, [ebp+arg3]
	; cmp eax, 560 
	; jl continuare_afisare_mesaj ;;;; sa modific sa sara la verificare_buton_restart
	; cmp eax, 670 
	; jg continuare_afisare_mesaj
	; cmp ebx, 240
	; jl continuare_afisare_mesaj
	; cmp ebx, 290 
	; jg continuare_afisare_mesaj
	; call shuffle			;;;; in cazul in care jucatorul apasa pe butonul "SHUFFLE", se va crea o noua matrice, ca si cum s-ar amesteca elementele
	; jmp afisare_litere
	continuare_afisare_mesaj:
	make_text_macro 'N', area, 560, 330
	make_text_macro 'U', area, 570, 330

	make_text_macro 'A', area, 590, 330
	make_text_macro 'T', area, 600, 330
	make_text_macro 'I', area, 610, 330
	
	make_text_macro 'D', area, 630, 330
	make_text_macro 'A', area, 640, 330
	make_text_macro 'T', area, 650, 330
	
	make_text_macro 'C', area, 670, 330
	make_text_macro 'L', area, 680, 330
	make_text_macro 'I', area, 690, 330
	make_text_macro 'C', area, 700, 330
	make_text_macro 'K', area, 710, 330
	
	make_text_macro 'P', area, 730, 330
	make_text_macro 'E', area, 740, 330
	
	make_text_macro 'T', area, 630, 370
	make_text_macro 'A', area, 640, 370
	make_text_macro 'B', area, 650, 370
	make_text_macro 'L', area, 660, 370
	make_text_macro 'A', area, 670, 370
evt_timer:
	inc counter
	
afisare_litere: 
	;scriem un mesaj
	
	;;;; fac butonul pe care jucatorul sa apese in momentul in care nu mai sunt mutari posibile 
	; line_horizontal 560, 240, 110, 0
	; line_horizontal 560, 290, 110, 0
	; line_vertical 560, 240, 50, 0
	; line_vertical 670, 240, 50, 0
	; make_text_macro 'S', area, 580, 255
	; make_text_macro 'H', area, 590, 255
	; make_text_macro 'U', area, 600, 255
	; make_text_macro 'F', area, 610, 255
	; make_text_macro 'F', area, 620, 255
	; make_text_macro 'L', area, 630, 255
	; make_text_macro 'E', area, 640, 255
	
	; line_horizontal 560, 310, 110, 0
	; line_horizontal 560, 360, 110, 0
	; line_vertical 560, 310, 50, 0
	; line_vertical 670, 310, 50, 0
	; make_text_macro 'R', area, 580, 325
	; make_text_macro 'E', area, 590, 325
	; make_text_macro 'S', area, 600, 325
	; make_text_macro 'T', area, 610, 325
	; make_text_macro 'A', area, 620, 325
	; make_text_macro 'R', area, 630, 325
	; make_text_macro 'T', area, 640, 325
	
	
	
	;; cadranul matricii
	line_horizontal matrix_coordinate_x-1, matrix_coordinate_y-1, matrix_width*image_width+2, 0F79AC0h
	mov eax, matrix_height
	mov ebx, image_height
	mul ebx
	add eax, matrix_coordinate_y
	mov esi, eax
	line_horizontal matrix_coordinate_x-1, esi, matrix_width*image_width+2,  0F79AC0h
	line_vertical matrix_coordinate_x-1, matrix_coordinate_y-1, matrix_height*image_height+2, 0F79AC0h
	mov eax, matrix_width
	mov ebx, image_width
	mul ebx
	add eax, matrix_coordinate_x
	mov esi, eax
	line_vertical esi, matrix_coordinate_y-1, matrix_height*image_height+2, 0F79AC0h
	
	
	make_text_macro 'C', area, 300, 70
	make_text_macro 'A', area, 310, 70
	make_text_macro 'N', area, 320, 70
	make_text_macro 'D', area, 330, 70
	make_text_macro 'Y', area, 340, 70
	
	make_text_macro 'C', area, 360, 70
	make_text_macro 'R', area, 370, 70
	make_text_macro 'U', area, 380, 70
	make_text_macro 'S', area, 390, 70
	make_text_macro 'H', area, 400, 70
	
	make_text_macro 'S', area, 420, 70
	make_text_macro 'A', area, 430, 70
	make_text_macro 'G', area, 440, 70
	make_text_macro 'A', area, 450, 70
	
	;;;; afisez numarul de mutari ramase
	make_text_macro 'M', area, 110, 100
	make_text_macro '0', area, 120, 100
	make_text_macro 'V', area, 130, 100
	make_text_macro 'E', area, 140, 100
	make_text_macro 'S', area, 150, 100
	
	make_text_macro 'L', area, 170, 100
	make_text_macro 'E', area, 180, 100
	make_text_macro 'F', area, 190, 100
	make_text_macro 'T', area, 200, 100
	
	mov ebx, 10
	mov eax, moves_left
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 230, 100
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 220, 100
	make_text_macro arg1, area, 300, 100
	
	;;;; afisez scorul
	make_text_macro 'S', area, 400, 100 
	make_text_macro 'C', area, 410, 100
	make_text_macro 'O', area, 420, 100
	make_text_macro 'R', area, 430, 100
	make_text_macro 'E', area, 440, 100
	
	mov ebx, 10
	mov eax, score
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 480, 100
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 470, 100
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 460, 100
	
	;;;;; aici verifica tot timpul (adica se verifica si la initializarea matricei, cat si in timpul jocului daca exista vreun strike in matrice si in cazul in care exista tot elimina, pana in momentul in care nu mai 
	;;;;; exista niciunul
	verificare:
	call verify_3_or_more_candies
	cmp if_strike, 1 
	jne afisare_matrice
	mov eax, counter
	mov ajutor_pt_timer, eax
	cmp first_move_made, 1
	jne eliminare
	mov stare, 1     ;;;;;;stare
	mov eax, counter
	mov stare_counter_start, eax
	mov eax, number_candies_in_strike
	add score, eax ;;;;; dupa fiecare verificare daca exista strike in matrice, se adauga la scor numarul de bomboane din strike ( asta se intampla doar dupa ce jucatorul a facut prima mutare posibila)
	mov ebx, scor_castig
	cmp score, ebx ;;;;;; daca scorul este mai mare decat "scor_castig", jucatorul a castigat
	jg ai_castigat
	eliminare:
	call eliminate
	call draw_matrix_of_candies
	
	

	
	
	afisare_matrice:
	
	; verific daca sunt mutari posibile; daca nu fac shuffle
	call verify_possible_move
	cmp if_possible_move, 0
	jne peste_shuffle
	call shuffle
	
	peste_shuffle:
	
	call draw_matrix_of_candies
	cmp numar_bomboane_selectate, 1
	jne cnt
	;;;;creare patrat in jurul primei bomboane selectate
	line_horizontal small_square_coordinate_x, small_square_coordinate_y, image_width, 0A32CC4h
	mov eax, image_height
	add small_square_coordinate_y, image_height
	line_horizontal small_square_coordinate_x, small_square_coordinate_y, image_width, 0A32CC4h
	sub small_square_coordinate_y, image_height
	line_vertical small_square_coordinate_x, small_square_coordinate_y, image_height, 0A32CC4h
	add small_square_coordinate_x, image_width
	line_vertical small_square_coordinate_x, small_square_coordinate_y, image_height, 0A32CC4h
	sub small_square_coordinate_x, image_width
	cnt:
	cmp byte ptr castigat, 1
	jne vf_ai_pierdut
	
	call coloreaza_alb
	

	mov eax, image_width
	mov ebx, matrix_width
	mul ebx
	shr eax, 1
	add eax, matrix_coordinate_x
	sub eax, 30
	mov win_text_coordinate_x, eax
	
	
	
	mov eax, image_height
	mov ebx, matrix_height
	mul ebx
	shr eax, 1
	add eax, matrix_coordinate_y
	mov win_text_coordinate_y, eax
	
	
	make_text_macro 'Y', area, win_text_coordinate_x, win_text_coordinate_y
	add win_text_coordinate_x, 10
	make_text_macro '0', area, win_text_coordinate_x, win_text_coordinate_y
	add win_text_coordinate_x, 10
	make_text_macro 'U', area, win_text_coordinate_x, win_text_coordinate_y
	add win_text_coordinate_x, 10
	make_text_macro ' ', area, win_text_coordinate_x, win_text_coordinate_y
	add win_text_coordinate_x, 10
	make_text_macro 'W', area, win_text_coordinate_x, win_text_coordinate_y
	add win_text_coordinate_x, 10
	make_text_macro 'I', area, win_text_coordinate_x, win_text_coordinate_y
	add win_text_coordinate_x, 10
	make_text_macro 'N', area, win_text_coordinate_x, win_text_coordinate_y
	add win_text_coordinate_x, 10
	make_text_macro '!', area, win_text_coordinate_x, win_text_coordinate_y
	jmp final_draw
	
	vf_ai_pierdut:
	cmp byte ptr pierdut, 1
	jne final_draw
	
	call coloreaza_alb
	

	mov eax, image_width
	mov ebx, matrix_width
	mul ebx
	shr eax, 1
	add eax, matrix_coordinate_x
	sub eax, 30
	mov win_text_coordinate_x, eax
	
	
	
	mov eax, image_height
	mov ebx, matrix_height
	mul ebx
	shr eax, 1
	add eax, matrix_coordinate_y
	mov win_text_coordinate_y, eax
	
	
	make_text_macro 'Y', area, win_text_coordinate_x, win_text_coordinate_y
	add win_text_coordinate_x, 10
	make_text_macro '0', area, win_text_coordinate_x, win_text_coordinate_y
	add win_text_coordinate_x, 10
	make_text_macro 'U', area, win_text_coordinate_x, win_text_coordinate_y
	add win_text_coordinate_x, 10
	make_text_macro ' ', area, win_text_coordinate_x, win_text_coordinate_y
	add win_text_coordinate_x, 10
	make_text_macro 'L', area, win_text_coordinate_x, win_text_coordinate_y
	add win_text_coordinate_x, 10
	make_text_macro 'O', area, win_text_coordinate_x, win_text_coordinate_y
	add win_text_coordinate_x, 10
	make_text_macro 'S', area, win_text_coordinate_x, win_text_coordinate_y
	add win_text_coordinate_x, 10
	make_text_macro 'T', area, win_text_coordinate_x, win_text_coordinate_y
	add win_text_coordinate_x, 10
	make_text_macro '!', area, win_text_coordinate_x, win_text_coordinate_y
	jmp final_draw
	
	ai_castigat: ;;;;; daca jucatorul a castigat, atunci variabila "castigat" va lua 1 pt a se afisa matricea putin blurata si sa scrie deasupra "YOU WON"
				 ;;;;; if_strike devine 0 ca sa nu se mai adune la scor 
	mov byte ptr castigat, 1
	mov if_strike, 0
	mov first_move_made, 0
	
	ai_pierdut:
	mov byte ptr pierdut, 1
	mov if_strike, 0
	mov first_move_made, 0
	
	; mov eax, '0'
	; add eax, matrix[0]
	; make_text_macro eax, area, 200, 200
	; call draw_matrix_of_candies
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	; alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	; apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	
	;;;;; Reguli terminare joc: ori sa se opreasca pana nu mai sunt mutari posibile, ori atunci cand se sparg bomboanele care sunt cel putin 3 unele langa celelalte sa
	;;;;; cada alte bomboane random si poate sa pun noi task-uri pe care sa le indeplinim EXEMPLU: Sa selecteze cel putin 10 bomboane albastre sausa se sparga un anumit
	;;;;; numar de bomboane! in cazul in care nu mai exita mutari posibile sa se faca un fel de shuffle cu bomboanele (e ok daca generez o noua matrice?)
	;;;;; citire din fisier pentru nota 10!!!
	;;;;;; 2 stari: motion mode si moves mode : in momentul in care s-a facut vreo mutare posibila, sa nu se mai accepte click-uri si cand se face interschimbarea, sa se 
	;;;;;; duca bomboanele unele spre altele, ca sa se vada putin mai lent miscarea - bonus 
	;;;;;; sa fac si functia pentru verificare pentru bonus
	rdtsc
	push eax
	call srand
	
	call make_matrix
	

	; mov matrix[0], 0
	; mov matrix[4], 0
	; mov matrix[8], 2
	; mov matrix[12], 1
	; mov matrix[16], 5
	

	; mov matrix[20], 11
	; mov matrix[24], 12
	; mov matrix[28], 13
	; mov matrix[32], 14
	; mov matrix[36], 0
	
	
	; mov matrix[40], 21
	; mov matrix[44], 22	
	; mov matrix[48], 23
	; mov matrix[52], 24
	; mov matrix[56], 1
	
	
	; mov matrix[60], 31
	; mov matrix[64], 32
	; mov matrix[68], 33
	; mov matrix[72], 34
	; mov matrix[76], 35
	
	
	; mov matrix[80], 0
	; mov matrix[84], 0
	; mov matrix[88], 43
	; mov matrix[92], 0
	; mov matrix[96], 45
	
	; call verify_possible_move
	; mov eax, if_possible_move
	
	; my_l:
	; call verify_3_or_more_candies
	; mov eax, if_strike
	; call eliminate
	; cmp eax, 1
	; jne my_l
	; call eliminate
	; jmp my_l
	
	
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
