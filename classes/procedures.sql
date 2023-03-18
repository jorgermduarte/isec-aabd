CREATE OR REPLACE PROCEDURE F03_EX10_2
(
	START_COD_AUTOR AUTORES.CODIGO_AUTOR%TYPE,
	END_COD_AUTOR AUTORES.CODIGO_AUTOR%TYPE
)
IS
	EX_AUTHOR_DOESNT_EXIST EXCEPTION;
	PRAGMA EXCEPTION_INIT(EX_AUTHOR_DOESNT_EXIST, -20302);
	EX_AUTHOR_NO_BOOKS EXCEPTION;
	PRAGMA EXCEPTION_INIT(EX_AUTHOR_NO_BOOKS, -20304);


BEGIN
	FOR i IN START_COD_AUTOR..END_COD_AUTOR LOOP
		BEGIN
			SELECT F03_EX09(i) INTO BCOUNT FROM LIVROS WHERE CODIGO_AUTOR = i;
			SELECT F04_EX08(i) INTO VNAME FROM AUTORES WHERE CODIGO_AUTOR = i;


			INSERT INTO TEMP (COL1,COL2,MESSAGE) VALUES(i,BCOUNT, VNAME);

			EXCEPTION WHEN
				EX_AUTHOR_DOESNT_EXIST THEN
				--dbms_output.put_line('THE AUTHOR DOES NOT EXIST');
				NULL;
				EX_AUTHOR_NO_BOOKS THEN
				--dbms_output.put_line('THE AUTHOR DOES NOT HAVE ANY BOOKS');
					NULL;
				others THEN
					 RAISE SMTHG_WENT_WRONG;
		END;
	END LOOP;

END F03_EX10_2;


CREATE OR REPLACE PROCEDURE F04_EX05
(
)
IS
	CURSOR c_generos_livros IS (SELECT DISTINCT l.GENERO  FROM LIVROS l);
	CURRENT_GENERO VARCHAR2;
	TOTAL_BOOKS_PRICE NUMBER;
	TOTAL_BOOKS_NUMBER NUMBER;
BEGIN
   OPEN c_generos_livros;
   LOOP
   FETCH c_generos_livros into CURRENT_GENERO;
      EXIT WHEN c_generos_livros%notfound;
     	BEGIN

     	SELECT SUM(L.PRECO_TABELA) INTO TOTAL_BOOKS_PRICE FROM LIVROS L WHERE L.GENERO = CURRENT_GENERO;
     	SELECT COUNT(L.CODIGO_LIVRO) INTO TOTAL_BOOKS_NUMBER FROM LIVROS L WHERE L.GENERO = CURRENT_GENERO;

     	INSERT INTO TEMP VALUES (TOTAL_BOOKS_PRICE, TOTAL_BOOKS_NUMBER, CURRENT_GENERO);

     	END;
   END LOOP;
   CLOSE c_generos_livros;

END;