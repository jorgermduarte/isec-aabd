DECLARE
	numTelefone NVARCHAR2(255);
	normalizado NVARCHAR2(255);
BEGIN
	numTelefone := '00351 239 123 456 ';
	normalizado := e_numero_normalizado(numTelefone);
    DBMS_OUTPUT.PUT_LINE('original: ' || numTelefone || '  -> ' || normalizado);
END;
