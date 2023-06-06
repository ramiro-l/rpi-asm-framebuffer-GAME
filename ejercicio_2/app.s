		.equ SCREEN_WIDTH,   640 //Ancho
		.equ SCREEN_HEIGH,   480 //Alto
		.equ BITS_PER_PIXEL, 32

		.equ GPIO_BASE,    0x3f200000
		.equ GPIO_GPFSEL0, 0x00
		.equ GPIO_GPLEV0,  0x34

		.equ DELEY_VALUE, 400

		.equ SEMILLA, 700

		.globl main


//------------------------------------ CODE HERE ------------------------------------//

/*
X0...X7   : argumentos/resultados
X8        : ...
X9...x15  : Temporales
X16       : IP0
X17       : IP1
X18       : ...
X19...X27 : Saved
X28       : SP
X29       : FP
X30       : LR
Xzr       : 0
*/


main: // x0 = direccion base del framebuffer
	
	/* Inicializacion */
	
	mov x27, x0 	// Guarda la dirección base del framebuffer en x20

	// Pintamos el fondo 
								// arg: x0 = direct base del frame buffer
	movz x1, 0x0E, lsl 16		
	movk x1, 0x0E0E, lsl 00		//Color del las estrellas
	bl pintarFondo // pre: {}  args: (in x0 = direccion base del framebuffer, x1 = color del fondo)


	// Configuracion GPIOS
	
	mov x26, GPIO_BASE
	str wzr, [x26, GPIO_GPFSEL0] // Setea gpios 0 - 9 como lectura

	//-------------------- CODE MAIN ---------------------------//
	
	            	// arg: x0 = direct base del frame buffer
	mov x7, xzr		// arg: semilla y
	bl fondoDinamico

	            	// x0 = direct base del frame buffer
	mov x1, 320 	// x
	mov x2, 320 	// y
	bl nave			// Dibuja la nave	

    //-------------------- Tecla W ---------------------------//
  InfLoop_TECLAS:
        bl nave
        mov x25, x1
        mov x1 , 13				// Setea el deley
	bl deley
	mov x1, x25
	ldr w10, [x26, GPIO_GPLEV0]
	lsr w11,w10, 1					// Tecla w
	and w11, w11,0b1				// Mascara para comparar solo el primer bit	
	cmp w11, 1
	b.eq w
	lsr w11,w10, 2					// Tecla a
	and w11, w11,1					// Mascara para comparar solo el primer bit	
	cmp w11, 1
	b.eq a
	lsr w11,w10, 3					// Tecla s
	and w11, w11,1					// Mascara para comparar solo el primer bit	
	cmp w11, 1
	b.eq s
	lsr w11,w10, 4					// Tecla d
	and w11, w11,1					// Mascara para comparar solo el primer bit	
	cmp w11, 1
	b.eq d			
	b  InfLoop_TECLAS    	 		// if (x11 != 1) -> InfLoop_W

    //-------------------- Tecla W ---------------------------//
	
	// MOVER LA NAVE
 w:	bl borrar_nave		// Borra la nave
 	mov x7, xzr		// arg: semilla y
	bl fondoDinamico
	sub x2, x2, 2	// y - 1
	bl nave				// Dibuja la nave avanzando dos pixeles
    mov x25, x1
	mov x1 , 13			// Setea el deley
	bl deley			// Ejecuta el deley
	mov x1, x25
	b InfLoop_TECLAS
 a:	bl borrar_nave		// Borra la nave
	mov x7, xzr		// arg: semilla y
	bl fondoDinamico

	sub x1, x1, 2		// x - 2
	bl nave				// Dibuja la nave avanzando dos pixeles
    mov x25, x1
	mov x1 , 13			// Setea el deley
	bl deley			// Ejecuta el deley
	mov x1, x25
	b InfLoop_TECLAS
 s:	bl borrar_nave		// Borra la nave
	mov x7, xzr		// arg: semilla y
	bl fondoDinamico

	add x2, x2, 2		// x + 2
	bl nave				// Dibuja la nave avanzando dos pixeles
    mov x25, x1
	mov x1 , 13			// Setea el deley
	bl deley			// Ejecuta el deley
	mov x1, x25
	b InfLoop_TECLAS
 d:	bl borrar_nave		// Borra la nave
 	mov x7, xzr		// arg: semilla y
	bl fondoDinamico

	add x1, x1, 2		// x - 2
	bl nave				// Dibuja la nave avanzando dos pixeles
    mov x25, x1
	mov x1 , 13			// Setea el deley
	bl deley			// Ejecuta el deley
	mov x1, x25
	b InfLoop_TECLAS
	//-------------------- END CODE MAIN -------------------------//


endMain:
	b endMain

// Herramientas basicas:

deley: // pre: {}    args: (in x1 = tamaño del deley)
	//-------------------- CODE ---------------------------//
	mov x9, DELEY_VALUE
	lsl x9, x9, x1
 deley_loop:   	
    sub x9, x9, #1
    cbnz x9, deley_loop
	//-------------------- END CODE -------------------------//
endDeley:	br lr 

p_pixel: // pre: { 0 <= x <= 480 && 0 <= y <= 640}    args: ( x0 = direccion base del framebufer, x1 = x,  x2 = y, x3 = color )
	sub sp, sp , 24
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur lr , [sp, #16]
	mov x19, x1
	mov x20, x2
	//-------------------- CODE ---------------------------//
	bl moduloWIDTH
	bl moduloHEIGH
	lsl x9, x1, 2 // x9 = x * 4
	lsl x10, x2, 2 // x10 = y * 4
	mov x11, SCREEN_WIDTH
	mul x10, x10, x11 // x10 = y * 4 * 640
	add x9, x9, x10 // x9 = x * 4 + y * 4 * 640
	add x9, x9 , x0 // x9 = direccion base del framebufer +  x * 4 + y * 4 * 640

	str w3, [x9,#0]
	//-------------------- END CODE -------------------------//
	mov x1, x19 
	mov x2, x20 
	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur lr , [sp, #16]
	add sp, sp , 24
end_p_pixel: br lr

moduloWIDTH: // pre: {}   args: (in/out x1 = eje x)
	//-------------------- CODE ---------------------------//
	cmp x1, 0					// if (x1 < 0) -> le sumo SCREEN_WIDTH
	b.ge noCambiaWIDTH	
 loopModuloWIDTH1:
	add x1, x1, SCREEN_WIDTH	//x1 = x1 + SCREEN_WIDTH
	cmp x1, 0
	b.lt loopModuloWIDTH1	
 noCambiaWIDTH:					// else 
	cmp x1, SCREEN_WIDTH		// if (x1 < SCREEN_WIDTH) -> termino
	b.lt endModuloWIDTH	
 loopModuloWIDTH2:				// else
	sub x1, x1, SCREEN_WIDTH	// x1 = x1 - SCREEN_WIDTH
	cmp x1, SCREEN_WIDTH		// if (x1 >= SCREEN_WIDTH ) -> itero
	b.ge loopModuloWIDTH2		// else -> termino
	//-------------------- END CODE -------------------------//
endModuloWIDTH: br lr

moduloHEIGH: // pre: {}   args: (in/out x2 = eje y)
	//-------------------- CODE ---------------------------//
	cmp x2, 0					// if (x2 < 0) -> le sumo SCREEN_HEIGH
	b.ge noCambiaHEIGH	
 loopModuloHEIGH1:
	add x2, x2, SCREEN_HEIGH	//x2 = x2 + SCREEN_HEIGH
	cmp x2, 0
	b.lt loopModuloHEIGH1	
 noCambiaHEIGH:				// else 
	cmp x2, SCREEN_HEIGH		// if (x2 < SCREEN_HEIGH) -> termino
	b.lt endModuloHEIGH	
 loopModuloHEIGH2:				// else
	sub x2, x2, SCREEN_HEIGH	// x2 = x2 - SCREEN_HEIGH
	cmp x2, SCREEN_HEIGH		// x2 (x2 >= SCREEN_HEIGH ) -> itero
	b.ge loopModuloHEIGH2			// else -> termino
	//-------------------- END CODE -------------------------//
endModuloHEIGH: br lr

// Formas basicas:

triangulo_punta_abajo:  // pre: {}    args: (in x0 = direccion base framebufer, x1 = x, x2 = y,  x3 = color,  x4 = alto)
	
	/* Inicializacion */
	
	sub sp, sp , 56
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur x21 , [sp, #16]
	stur x22 , [sp, #24]
	stur x26 , [sp, #32]
	stur x27 , [sp, #40]
	stur lr , [sp, #48]

	mov x21, x1 // x (cordenada)
	mov x22, x2 // y (cordenada)

    //-------------------- CODE ---------------------------//
	
	mov x19, x1 // x (cordenada)
	mov x20, x2 // y (cordenada)

	// Calculamos el inicio y final del triangulo:
	lsr x9, x4, 1             // Mitad del alto
	
	// Inicio:
	lsr x10, x4, 2             // Mitad de la mitad del alto
	sub x19, x1, x9            // x - mitad del alto
	
	sub x20, x2, x10           // y - mitad del alto
	
	// Final de x e y:
	add x26, x1, x9           	  // x26 = x + mitad del alto  
	add x27, x2, x10               // x27 = y + mitad del alto
	//add x27, x27, 1               // x27 = y + mitad del alto

	// Dibujamos: 
	mov x2, x20   	          // y
 tri_p_abajo_loop1:
	mov x1, x19               // x
 tri_p_abajo_loop2:	
	bl p_pixel                // args: ( x0 = direccion base del framebufer, x1 = x,  x2 = y, x3 = color )
	adds x1,x1, #1 	          // x + 1
	cmp x1 , x26     
	b.lt tri_p_abajo_loop2    // if (x < final_x ) -> tri_p_abajo_loop2
	add  x19, x19, 1          //  x + 1
	sub  x26, x26, 1		  // final_x - 1
	adds x2, x2, #1           // y + 1
	cmp x2 , x27 
	b.lt  tri_p_abajo_loop1   // if (y < final_y ) -> tri_p_abajo_loop1
	
	//-------------------- END CODE -------------------------//
	mov x1, x21
	mov x2, x22

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur x21 , [sp, #16]
	ldur x22 , [sp, #24]
	ldur x26 , [sp, #32]
	ldur x27 , [sp, #40]
	ldur lr , [sp, #48]
	add sp, sp , 56

end_triangulo_punta_abajo: br lr

triangulo_punta_arriba:  // pre: {}    args: (in x0 = direccion base framebufer, x1 = x, x2 = y,  x3 = color,  x4 = alto)
	
	/* Inicializacion */
	sub sp, sp , 56
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur x21 , [sp, #16]
	stur x22 , [sp, #24]
	stur x26 , [sp, #32]
	stur x27 , [sp, #40]
	stur lr , [sp, #48]

	mov x21, x1 // x (cordenada)
	mov x22, x2 // y (cordenada)

    //-------------------- CODE ---------------------------//
	mov x19, x1 // x (cordenada)
	mov x20, x2 // y (cordenada)
	// Calculamos el inicio y final del triangulo:
	lsr x9, x4, 1             // Mitad del alto
	
	// Inicio:
	lsr x10, x4, 2             // Mitad de la mitad del alto
	sub x19, x1, x9            // x - mitad del alto
	add x20, x2, x10           // y + mitad del alto
	
	// Final de x e y:
	add x26, x1, x9           	  // x26 = x + mitad del alto  
	sub x27, x2, x10               // x27 = y - mitad del alto
	//sub x27, x27, 1               // x27 = y - mitad del alto

	// Dibujamos: 
	mov x2, x20   	          // y
 tri_p_arriba_loop1:
	mov x1, x19               // x
 tri_p_arriba_loop2:	
	bl p_pixel                // args: ( x0 = direccion base del framebufer, x1 = x,  x2 = y, x3 = color )
	adds x1,x1, #1 	          // x + 1
	cmp x1 , x26     
	b.lt tri_p_arriba_loop2    // if (x < final_x ) -> tri_p_arriba_loop2
	add  x19, x19, 1          //  x + 1
	sub  x26, x26, 1		  // final_x - 1
	subs x2, x2, #1           // y + 1
	cmp x2 , x27 
	b.gt  tri_p_arriba_loop1   // if (y > final_y ) -> tri_p_arriba_loop1
	
	//-------------------- END CODE -------------------------//

	mov x1, x21
	mov x2, x22

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur x21 , [sp, #16]
	ldur x22 , [sp, #24]
	ldur x26 , [sp, #32]
	ldur x27 , [sp, #40]
	ldur lr , [sp, #48]
	add sp, sp , 56

end_triangulo_punta_arriba: br lr

rectangulo: // pre: {}    args: (in x0 = direccion base framebufer, x1 = x, x2 = y,  x3 = color, x4 = ancho, x5 = alto)

	/* Inicializacion */
	sub sp, sp , 56
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur x21 , [sp, #16]
	stur x22 , [sp, #24]
	stur x26 , [sp, #32]
	stur x27 , [sp, #40]
	stur lr , [sp, #48]
	
	mov x21, x1 // x (cordenada)
	mov x22, x2 // y (cordenada)

	
	//-------------------- CODE ---------------------------//

	mov x19, x1 // x (cordenada)
	mov x20, x2 // y (cordenada)
	
	// Calculamos el inicio y final del rectangulo:
	lsr x9, x4, 1    // Mitad del ancho
	lsr x10, x5, 1   // Mitad del alto
	
	// Inicio:
	sub x19, x1, x9  // x - mitad del ancho
	sub x19, x19, 1  // x - mitad del ancho - 1
	sub x20, x2, x10 // y - mitad del alto
	sub x20, x20, 1 // y - mitad del alto - 1
	
	// Final:
	add x26, x1, x9  // x + mitad del ancho
	sub x26, x26, 1  // x + mitad del ancho - 1
	add x27, x2, x10 // y + mitad del alto
	sub x27, x27, 1  // x + mitad del ancho - 1
	
	// Dibujamos: 
	mov x2, x20   	 // y
 rect_loop1:
	mov x1, x19  	 // x
	adds x2, x2, #1  // y + 1
 rect_loop2:	
	adds x1,x1, #1 	 // x + 1
	bl p_pixel       // args: ( x0 = direccion base del framebufer, x1 = x,  x2 = y, x3 = color )
	cmp x1 , x26     //
	b.lt rect_loop2  // if (x < ancho) -> rect_loop2
	cmp x2 , x27     // 
	b.lt rect_loop1  // if (y < alto) -> rect_loop1
	
	//-------------------- END CODE -------------------------//

	mov x1, x21 // x (cordenada)
	mov x2, x22 // y (cordenada)

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur x21 , [sp, #16]
	ldur x22 , [sp, #24]
	ldur x26 , [sp, #32]
	ldur x27 , [sp, #40]
	ldur lr , [sp, #48]
	add sp, sp , 56

endRectangulo:	br lr

circulo: // pre: {}    args: (in x0 = direccion base framebufer, x1 = x, x2 = y,  x3 = color,  x4 = radio)
	/* Inicializacion */
	sub sp, sp , 64
	stur x21 , [sp, #0]
	stur x22 , [sp, #8]
	stur x23 , [sp, #16]
	stur x24 , [sp, #24]
	stur x25, [sp, #32]
	stur x26 , [sp, #40]
	stur x27 , [sp, #48]
	stur lr , [sp, #56]
	
	//-------------------- CODE ---------------------------//
	mov x25, x1		// posicion del framebufer x
	mov x27, x2		// posicion del framebufer y
	mov x21, x4  	// x  distancia incial del eje x al punto 
	mov x22, x4  	// y  distancia inicial del eje y al punto
	mov x23, x4  	// radio
	mul x23, x23, x23   // radio*radio

 ciclo1: 
    sub x21, x21, 1
	add x1, x1, 1
    mul x24, x21, x21
	mul x26, x22, x22
	add x24, x24, x26 
    cmp x24, x23 
	b.gt ciclo1
    bl p_pixel
	cbnz x21, ciclo1  
 	mov x21, x4
	mov x1, x25
	add x2, x2, 1
	sub x22, x22, 1
	cbnz x22, ciclo1 
   	 
	lsl x9, x4, 1
	add x1, x25, x9		// x = x + 2 * radio
	mov x2, x27			// y = y
	mov x21, x4
	mov x22, x4

 ciclo2: 
    sub x21, x21, 1
	sub x1, x1, 1
    mul x24, x21, x21
	mul x26, x22, x22
	add x24, x24, x26 
    cmp x24, x23 
	b.gt ciclo2
    bl p_pixel
	cbnz x21, ciclo2
 	mov x21, x4
	lsl x9, x4, 1
	add x1, x25, x9		// x = x + 2 * radio
	add x2, x2, 1
	sub x22, x22, 1
	cbnz x22, ciclo2 

    
	mov x1, x25
	add x2, x2, x4
	sub x2, x2, 1	// y = y + radio -1
	mov x21, x4
	mov x22, x4

 ciclo3: 
    sub x21, x21, 1
	add x1, x1, 1
    mul x24, x21, x21
	mul x26, x22, x22
	add x24, x24, x26 
    cmp x24, x23 
	b.gt ciclo3
    bl p_pixel
	cbnz x21, ciclo3
 	mov x21, x4
	mov x1, x25			// = x
	sub x2, x2, 1
	sub x22, x22, 1
	cbnz x22, ciclo3 



    lsl x9, x4, 1
	add x1, x25, x9		// x = x + 2 * radio
	add x2, x2, x4
	mov x21, x4
	mov x22, x4

 ciclo4: 
    sub x21, x21, 1
	sub x1, x1, 1
    mul x24, x21, x21
	mul x26, x22, x22
	add x24, x24, x26 
    cmp x24, x23 
	b.gt ciclo4
    bl p_pixel
	cbnz x21, ciclo4
 	mov x21, x4
	lsl x9, x4, 1
	add x1, x25, x9		// x = x + 2 * radio
	sub x2, x2, 1
	sub x22, x22, 1
	cbnz x22, ciclo4

	//-------------------- END CODE -------------------------//
	mov x1, x25 	
	mov x2, x27 		
	mov x4, x23   	

	ldur x21 , [sp, #0]
	ldur x22 , [sp, #8]
	ldur x23 , [sp, #16]
	ldur x24 , [sp, #24]
	ldur x25, [sp, #32]
	ldur x26 , [sp, #40]
	ldur x27 , [sp, #48]
	ldur lr , [sp, #56]
	add sp, sp , 64

endCirculo: br lr


// Formas combinadas:

pintarFondo: // pre: {}  args: (in x0 = direccion base del framebuffer, x1 = color del fondo)

	/* Inicializacion */
	sub sp, sp , 48
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur x21 , [sp, #16]
	stur x22 , [sp, #24]
	stur x23 , [sp, #32]
	stur lr , [sp, #40]

	mov x19, x1
	mov x20, x2
	mov x21, x3
	mov x22, x4
	mov x23, x5
	//-------------------- CODE ---------------------------//

	mov x9, SCREEN_WIDTH  // x
	lsr x9, x9, 1		  // x
	mov x10, SCREEN_HEIGH // y
	lsr x10, x10, 1		  // y

	mov x1, x9            // arg: x
	mov x2, x10           // arg: y
	mov x3, x19 		  // arg: color
	mov x4, SCREEN_WIDTH  // arg: ancho
	mov x5, SCREEN_HEIGH  // arg: alto
	bl rectangulo 		  // construimos el rectangulo que ocupa toda la pantalla

	//-------------------- END CODE -------------------------//

	mov x1, x19
	mov x2, x20 
	mov x3, x21 
	mov x4, x22 
	mov x5, x23 

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur x21 , [sp, #16]
	ldur x22 , [sp, #24]
	ldur x23 , [sp, #32]
	ldur lr , [sp, #40]

	add sp, sp , 48
endPintarFondo:	br lr

estrella: // pre: {}    args: (in x0 = direccion base del framebuffer, x1 = x, x2 = y, x3 = color, x4 = ancho)

	sub sp, sp , 24
	stur x19 , [sp, #0]
	stur x20 , [sp, #8] // No hace falta guardar en el stack x3 y  x4  porque solo usamos las funciones de triangulos y no las modifican
	stur lr , [sp, #16]

	mov x19, x1
	mov x20, x2
    //-------------------- CODE ---------------------------//
	lsr x9, x4, 2
	sub x9, x20, x9 
	//Triangulo superior 
	           // x0 = arg: direccion base framebufer
	           // x1 = arg: x
	mov x2, x9 // arg: y
	           // x3 = arg: color
	           // x4 = arg: ancho
	bl triangulo_punta_arriba

	// Triangulo inferrior
	lsr x9, x4, 2
	add x9, x20, x9 

				// x0 = arg: direccion base framebufer
				// x1 = arg: x
	mov x2,  x9 // arg: y
	            // x3 = arg: color
	 		    // x4 = arg: ancho
	bl triangulo_punta_abajo
 //-------------------- END CODE ---------------------------//
	mov  x1, x19
	mov  x2, x20

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur lr , [sp, #16]
	add sp, sp , 24

endEstrella: br lr

nave: 		//  pre: {}  args: (in x0 = direccion base del framebuffer, x1 = x, x2 = y)         
	sub sp, sp , 80
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur x21 , [sp, #16]
	stur x22 , [sp, #24]
	stur x23 , [sp, #32]
	stur x24 , [sp, #40]
	stur x25 , [sp, #48]
	stur x26 , [sp, #56]
	stur x27 , [sp, #64]
	stur lr , [sp, #72]

	mov x19, x1
	mov x20, x2
	mov x25, x3
	mov x26, x4
	mov x27, x5

 //-------------------- CODE ---------------------------//

	movz x21, 0xDA, lsl 16		//BLANCO
	movk x21, 0xDADA, lsl 00	//BLANCO (#F5F5F5)

	movz x22, 0x1E, lsl 16		//AZUL
	movk x22, 0x86F5, lsl 00	//AZUL (#1E86F5)

	movz x23, 0xF1, lsl 16		//AMARILLO
	movk x23, 0xCE2D, lsl 00	//AMARILLO (#F1CE2D)

	movz x24, 0xF7, lsl 16		//ROJO
	movk x24, 0x3822, lsl 00	//ROJO (#F73822)

	//Rectangulo central blanco
						// arg: x0 = direccion base del framebuffer
	mov x1,	x19 		// arg: x
	mov x2,	x20			// arg: y
	mov x3, x21 		// arg: color
	mov x4, 24		    // arg: ancho
	mov x5, 56			// arg: alto
	bl rectangulo 

	//Rectangulo superior azul
	sub x9, x20, 30		// calculo: y - 30
	
					    // arg: x0 = direccion base del framebuffer
	mov x1,	x19		    // arg: x
	mov x2,	x9			// arg: y
	mov x3, x22  		// arg: color
	mov x4, 24			// arg: ancho
	mov x5, 6			// arg: alto
	bl rectangulo 

	//Triangulo Blanco superior
	sub x9, x20, 40  	// calculo: y - 36 - 12

						// arg: x0 = direccion base del framebuffer
						// arg: x1 = x
	mov x2,	x9			// arg: y    
	mov x3, x21         // arg: color
	mov x4, 24			// arg: ancho
	bl triangulo_punta_arriba 
 
	//Rectangulo central alargado
	movz x9, 0xab, lsl 16		// GRIS
	movk x9, 0xa3a2, lsl 00		// GRIS

						// arg: X0 = direccion base del framebuffer
	mov x1,	x19 		// arg: x
	mov x2,	x20			// arg: y
	mov x3, x9			// arg: color
	mov x4, 60			// arg: ancho
	mov x5, 6			// arg: alto
	bl rectangulo  
	
	movz x9, 0xab, lsl 16		// GRIS
	movk x9, 0xa3a2, lsl 00		// GRIS

						// arg: X0 = direccion base del framebuffer
	mov x1,	x19 		// arg: x
	mov x2,	x20			// arg: y
	mov x3, x21			// arg: color
	mov x4, 24			// arg: ancho
	mov x5, 6			// arg: alto
	bl rectangulo  

	//Rectangulo derecho
	add x9, x19, 30		// calculo: x + 30
	
						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 		    // arg: x
	mov x2,	x20			// arg: y
	mov x3, x21 		// arg: color
	mov x4, 6			// arg: ancho
	mov x5, 30			// arg: alto
	bl rectangulo 
   

	//Rectangulo izquierdo
	sub x9, x19, 30		// calculo: x - 30
	
						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x20			// arg: y
	mov x3, x21 		// arg: color
	mov x4, 6			// arg: ancho
	mov x5, 30			// arg: alto
	bl rectangulo 

 	//Rectangulo derecho mas chico
	add x9, x19, 18		// calculo: x + 18
	
						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x20			// arg: y
	mov x3, x21 		// arg: color
	mov x4, 4			// arg: ancho
	mov x5, 18		    // arg: alto
	bl rectangulo 
    
	//Rectangulo izquierdo mas chico
	sub x9, x19, 18		// calculo: x - 18

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x20			// arg: y
	bl rectangulo 

	//Rectangulo derecho mas chico rojo
	add x9, x19, 30		 // calculo: x + 30
	sub x10, x20, 10     // calculo y - 5

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
	mov x3, x24 		// arg: color
	mov x4, 6			// arg: ancho
	mov x5, 4		    // arg: alto
	bl rectangulo


	//Rectangulo izquierdo mas chico rojo
	sub x9, x19, 30		// calculo: x - 30
	sub x10, x20, 10     // calculo y - 5

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x4 = ancho
			 			// arg: x5 = alto
	bl rectangulo


	//Rectangulo derecho mas chico amarillo
	add x9, x19, 30		// calculo: x + 30
	add x10, x20, 15     // calculo y + 15

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
	mov x3, x23 		// arg: color
	mov x4, 6			// arg: ancho
	mov x5, 5			// arg: alto
	bl rectangulo
    

	//Rectangulo izquierdo mas chico amarillo
	sub x9, x19, 30		// calculo: x - 30
	add x10, x20, 15    // calculo y + 15

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x4 = ancho
			 			// arg: x5 = alto
	bl rectangulo

	//Rectangulo derecho mas chico naranja/rojo
	add x9, x19, 30		// calculo: x + 30
	add x10, x20, 20     // calculo y + 20

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
	mov x3, x24 			// arg: color
	mov x4, 6			// arg: ancho
	mov x5, 6			// arg: alto
	
	bl rectangulo
    
	//Rectangulo izquierdo mas chico naranja/rojo
	sub x9, x19, 30		// calculo: x - 30
	add x10, x20, 20     // calculo y + 20

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x4 = ancho
			 			// arg: x5 = alto
	bl rectangulo


	//Rectangulo abajo amarillo
	add x10, x20, 31    // calculo y + 31

						// arg: X0 = direccion base del framebuffer
	mov x1,	x19 		// arg: x
	mov x2,	x10			// arg: y
        mov x3, x23 		// arg: color
	mov x4, 22			// arg: ancho
	mov x15, 6			// arg: alto
	bl rectangulo
	

    //Rectangulo derecho mas chico azul
	add x9, x19, 18		// calculo: x + 18
	sub x10, x20, 7     // calculo y - 7
	
						// arg: direccion base del framebuffer
	mov x1, x9 		    // arg: x
	mov x2, x10			// arg: y
	mov x3, x22 		// arg: color
	mov x4, 4			// arg: ancho
	mov x5, 4		    // arg: alto
	bl rectangulo
    

	//Rectangulo izquierdo mas chico azul
	sub x9, x19, 18		// calculo: x - 18
	sub x10, x20, 7     // calculo y - 7 
	
						// arg: direccion base del framebuffer
	mov x1, x9 		    // arg: x
	mov x2, x10			// arg: y
			 			// arg: x4 = ancho
			 			// arg: x5 = alto
	bl rectangulo
       
    //Rectangulo abajo naranja/rojo             Esta es la parte del fuego

    add x10, x20, 38   // calculo y + 36

  					// arg: direccion base del framebuffer
	mov x1,	x19 		// arg: x
	mov x2,	x10			// arg: y
	mov x3, x24 		// arg: color
	mov x4, 20			// arg: ancho
	mov x5, 8			// arg: alto
	add x6, x6, 1
	bl rectangulo
	mov x27, x1
    mov x1 , 13				// Setea el deley
	bl deley
	mov x1, x27
	add x10, x20, 42
	mov x2,	x10 
	mov x5, 8
	movz x3, 0x0E, lsl 16			//NEGRO
	movk x3, 0x0E0E, lsl 00			//NEGRO (#0E0E0E)
	bl rectangulo                 // un pedazo de rectangulo negro del rectangulo rojo dibujado anteriormente 
	


 //-------------------- END CODE ---------------------------//

	mov  x1, x19
	mov  x2, x20
	mov  x3, x25 
	mov  x4, x26 
	mov  x5, x27 

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur x21 , [sp, #16]
	ldur x22 , [sp, #24]
	ldur x23 , [sp, #32]
	ldur x24 , [sp, #40]
	ldur x25 , [sp, #48]
	ldur x26 , [sp, #56]
	ldur x27 , [sp, #64]
	ldur lr , [sp, #72]
	add sp, sp , 80

endNave: br lr

borrar_nave: 		// pre: {}  args: (in x0 = direccion base del framebuffer, x1 = x, x2 = y)         
	sub sp, sp , 48
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur x25 , [sp, #16]
	stur x26 , [sp, #24]
	stur x27 , [sp, #32]
	stur lr ,  [sp, #40]

	mov x19, x1
	mov x20, x2
	mov x25, x3
	mov x26, x4
	mov x27, x5

 //-------------------- CODE ---------------------------//

	movz x3, 0x0E, lsl 16		//NEGRO
	movk x3, 0x0E0E, lsl 00		//NEGRO (#0E0E0E)

	//Rectangulo central blanco
						// arg: x0 = direccion base del framebuffer
	mov x1,	x19 		// arg: x
	mov x2,	x20			// arg: y
	             		// arg: x3 = color
	mov x4, 24		    // arg: ancho
	mov x5, 56			// arg: alto
	bl rectangulo 

	//Rectangulo superior azul
	sub x9, x20, 30		// calculo: y - 30
	
					    // arg: x0 = direccion base del framebuffer
	mov x1,	x19		    // arg: x
	mov x2,	x9			// arg: y
				  		// arg: x3 = color
	mov x4, 24			// arg: ancho
	mov x5, 6			// arg: alto
	bl rectangulo 

	//Triangulo Blanco superior
	sub x9, x20, 40  	// calculo: y - 36 - 12

						// arg: x0 = direccion base del framebuffer
						// arg: x1 = x
	mov x2,	x9			// arg: y    
				        // arg: x3 = x3 = color
	mov x4, 24			// arg: ancho
			 			// arg: x5 = alto
	bl triangulo_punta_arriba 
 
	//Rectangulo central alargado
	movz x9, 0xab, lsl 16		// GRIS
	movk x9, 0xa3a2, lsl 00		// GRIS

						// arg: X0 = direccion base del framebuffer
	mov x1,	x19 		// arg: x
	mov x2,	x20			// arg: y
						// arg: x3 = color
	mov x4, 60			// arg: ancho
	mov x5, 6			// arg: alto
	bl rectangulo  

	//Rectangulo derecho
	add x9, x19, 30		// calculo: x + 30
	
						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 		    // arg: x
	mov x2,	x20			// arg: y
						// arg: x3 = color
	mov x4, 6			// arg: ancho
	mov x5, 30			// arg: alto
	bl rectangulo 
   

	//Rectangulo izquierdo
	sub x9, x19, 30		// calculo: x - 30
	
						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x20			// arg: y
			 			// arg: x3 = color
	mov x4, 6			// arg: ancho
	mov x5, 30			// arg: alto
	bl rectangulo 

 	//Rectangulo derecho mas chico
	add x9, x19, 18		// calculo: x + 18
	
						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x20			// arg: y
			 			// arg: x3 = color
	mov x4, 4			// arg: ancho
	mov x5, 18		    // arg: alto
	bl rectangulo 
    
	//Rectangulo izquierdo mas chico
	sub x9, x19, 18		// calculo: x - 18

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x20			// arg: y
			 			// arg: x3 = color
			 			// arg: x4 = ancho
			 			// arg: x5 = alto
	bl rectangulo 


	//Rectangulo derecho mas chico amarillo
	add x9, x19, 30		// calculo: x + 30
	add x10, x20, 15     // calculo y + 15

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x3 = color
	mov x4, 6			// arg: ancho
	mov x5, 5			// arg: alto
	bl rectangulo
    

	//Rectangulo izquierdo mas chico amarillo
	sub x9, x19, 30		// calculo: x - 30
	add x10, x20, 15    // calculo y + 15

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x3 = color
			 			// arg: x4 = ancho
			 			// arg: x5 = alto
	bl rectangulo

	//Rectangulo derecho mas chico naranja/rojo
	add x9, x19, 30		// calculo: x + 30
	add x10, x20, 20     // calculo y + 20

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x3 = color
	mov x4, 6			// arg: ancho
	mov x5, 6			// arg: alto
	
	bl rectangulo
    
	//Rectangulo izquierdo mas chico naranja/rojo
	sub x9, x19, 30		// calculo: x - 30
	add x10, x20, 20     // calculo y + 20

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x3 = color
			 			// arg: x4 = ancho
			 			// arg: x5 = alto
	bl rectangulo

	//Rectangulo abajo amarillo
	add x10, x20, 31    // calculo y + 31

						// arg: X0 = direccion base del framebuffer
	mov x1,	x19 		// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x3 = color
	mov x4, 22			// arg: ancho
	mov x15, 6			// arg: alto
	bl rectangulo
	

	//Rectangulo abajo naranja/rojo
	add x10, x20, 40    // calculo y + 36

						// arg: direccion base del framebuffer
	mov x1,	x19 		// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x3 = color
	mov x4, 20			// arg: ancho
	mov x5, 20			// arg: alto
	bl rectangulo
    

 //-------------------- END CODE ---------------------------//

	mov  x1, x19
	mov  x2, x20
	mov  x3, x25 
	mov  x4, x26 
	mov  x5, x27 

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur x25 , [sp, #16]
	ldur x26 , [sp, #24]
	ldur x27 , [sp, #32]
	ldur lr , [sp, #40]
	add sp, sp , 48

endborrar_Nave: br lr

fondoPlanetas: // pre: {} args: (in x0 = direccion base del framebuffer)
	sub sp, sp , 32
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur x21 , [sp, #16]
	stur lr , [sp, #24]

	mov x19, x1 
	mov x20, x2
	mov x21, x3 
	//-------------------- CODE ---------------------------//
			    // arg: x0 = direc base del frame buffer
	mov x1, 50	// arg: x
	mov x2, 17	// arg: y
				// arg: x3 = color
	mov x4, 16	// arg: ancho

	mov x1, 100
	mov x2, 190
	movz x3, 0xc9, lsl 16		//AMARILLO
	movk x3, 0x9039, lsl 00
	mov x4, 40
	bl circulo

	mov x1, 530
	mov x2, 280	
	movz x3, 0x20, lsl 16		//ROSA
	movk x3, 0x8FAF, lsl 00
	mov x4, 20
	bl circulo

	mov x1, 325
	mov x2, 115
	movz x3, 0xc1, lsl 16		
	movk x3, 0x1212, lsl 00		//ROJO
	mov x4, 30
	bl circulo
	
	//-------------------- END CODE ---------------------------//

	mov x1, x19 
	mov x2, x20
	mov x3, x21 

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur x21 , [sp, #16]
	ldur lr , [sp, #24]
		
	add sp, sp , 32
endFondoPlanetas: br lr

// FIXME: poner que pase el color asi podemos cambiar entre blanco y negro para pintar y borrar
fondoEstrellado: // pre: {} args: (in x0 = direccion base del framebuffer, x1 = semilla x, x2 = semilla y, x3 = numero de estrellas, x4 = Desplazamiento vertical)
	sub sp, sp , 48
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur x21 , [sp, #16]
	stur x22 , [sp, #24]
	stur x23 , [sp, #32]
	stur lr ,  [sp, #40]
	
	// x0 no lo modificamos asi que no hace falta guardarlo
	mov x19, x1 // semilla x 
	mov x20, x2 // semilla y 
	mov x21, x3 // n de estrellas    
	mov x22, x5 // desplazamiento del eje y

 //-------------------- CODE ---------------------------//
	mov x23, x21 		// x23 sera donde guardaremos el contador de estrellas que quedan por dibujar

 // Estrellas //
 RecEstrellas:

	cbz x22, dibestrella // Saltamos a dibestrella si no debemos modificar el y
	
	// calculamos el desplazamiento vertical del eje y
	mov x9, x22 // desplazamiento del eje y
    aa:
 		add x2, x2, SCREEN_WIDTH
		sub x9, x9, 1
		cbnz x9, aa
 

	// dibujamos la estrella
    dibestrella: 
		        	// arg: x0 = direc base del frame buffer
    				// arg: x1 = x
					// arg: x2 = y
		movz x3, 0xF3, lsl 16		
	    movk x3, 0xF3F3, lsl 00	// arg: Color del las estrellas (0xF3F3F3)
		mov x4, 8	// arg: ancho
		bl estrella 


	// Calculamos x e y de la proxima estrella
	mov x9, 4 //contador
	lk:
	    sub x1, x1, x23
		add x2, x2, x1
		lsl x1, x1, x9
		add x1, x1, 13
		add x2, x23, x2
		add x1, x2, x1

		sub x9, x9, 1
		cbnz x9, lk
	
	bl moduloHEIGH
	bl moduloWIDTH

	sub x23, x23, 1 // numero de estrellas - 1

	// Dibujamos la proxima estrella

	        	// arg: x0 = direc base del frame buffer
				// arg: x1 = semilla x
				// arg: x2 = semilla y
				// arg: x23 = numero de estrellas
				// arg: x4 = numero de planetas
				// arg: x5 = Desplazamiento vertical
	cbnz x23, RecEstrellas 

 //-------------------- END CODE ---------------------------//
	mov x1, x19 
	mov x2, x20 
	mov x3, x21 
	mov x4, x22 

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur x21 , [sp, #16]
	ldur x22 , [sp, #24]
	ldur x23 , [sp, #32]
	ldur lr ,  [sp, #40]
	add sp, sp , 48
endFondoEstrellado: br lr

// FIXME: poner que pase el color asi podemos cambiar entre blanco y negro para pintar y borrar
fondoDinamico: // pre: {} args: (in x0 = direccion base del framebuffer, x7 = Desplazamiento vertical)
	sub sp, sp , 40
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur x21 , [sp, #16]
	stur x22 , [sp, #24]
	stur lr , [sp, #32]

	mov x19, x1 
	mov x20, x2
	mov x21, x3 
	mov x22, x4
	//-------------------- CODE -------------------------------//
	
	mov x9, SEMILLA
	lsr x9, x9, 1
		            	// arg: x0 = direct base del frame buffer
	add x1, x9, 89		// arg: semilla x
	add x2, x9, 34		// arg: semilla y
	mov x3, 50	    	// arg: numero de estrellas 
	mov x4, x7			// arg: Desplazamiento vertical
	bl fondoEstrellado

	mov x9, SEMILLA
	lsr x9, x9, 1
						// arg: x0 = direct base del frame buffer
	add x1, x9, 21		// arg: semilla x
	add x2, x9, 34		// arg: semilla y  
	mov x3, 50	    	// arg: numero de estrellas 
	add x4, x7, 71		// arg: Desplazamiento vertical
	bl fondoEstrellado

	bl fondoPlanetas	//Pintamos los planetas
	//-------------------- END CODE ---------------------------//
	mov x1, x19 
	mov x2, x20
	mov x3, x21 
	mov x4, x22

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur x21 , [sp, #16]
	ldur x22 , [sp, #24]
	ldur lr , [sp, #32]
		
	add sp, sp , 40
endFondoDinamico: br lr

Error: // Nunca se deberia ejecutar esto
		b Error
		