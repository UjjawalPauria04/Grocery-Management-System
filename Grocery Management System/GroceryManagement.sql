CREATE TABLE ACCOUNT (
    ACCOUNT_ID NUMBER PRIMARY KEY,
    CUSTOMER_NAME VARCHAR2(50),
    PHONE VARCHAR2(15),
    BALANCE NUMBER(10,2)
);
INSERT INTO ACCOUNT VALUES (101, 'Rahul', '9876543210', 5000);
INSERT INTO ACCOUNT VALUES (102, 'Amit', '9876543211', 8000);
INSERT INTO ACCOUNT VALUES (103, 'Priya', '9876543212', 6000);
INSERT INTO ACCOUNT VALUES (104, 'Neha', '9876543213', 10000);

COMMIT;
CREATE TABLE PRODUCT (
    PRODUCT_ID NUMBER PRIMARY KEY,
    PRODUCT_NAME VARCHAR2(50),
    PRICE NUMBER(10,2),
    STOCK NUMBER
);
INSERT INTO PRODUCT VALUES (1, 'Rice', 60, 100);
INSERT INTO PRODUCT VALUES (2, 'Sugar', 45, 30);
INSERT INTO PRODUCT VALUES (3, 'Flour', 50, 20);
INSERT INTO PRODUCT VALUES (4, 'Oil', 150, 10);
INSERT INTO PRODUCT VALUES (5, 'Biscuits', 30, 60);
INSERT INTO PRODUCT VALUES (6, 'Tea', 120, 15);

COMMIT;
SET SERVEROUTPUT ON;

DECLARE
    CURSOR low_stock_cursor IS
        SELECT PRODUCT_ID, PRODUCT_NAME, STOCK
        FROM PRODUCT
        WHERE STOCK < 20;

    v_id PRODUCT.PRODUCT_ID%TYPE;
    v_name PRODUCT.PRODUCT_NAME%TYPE;
    v_stock PRODUCT.STOCK%TYPE;

BEGIN
    OPEN low_stock_cursor;

    LOOP
        FETCH low_stock_cursor INTO v_id, v_name, v_stock;

        EXIT WHEN low_stock_cursor%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
            'Product ID: ' || v_id ||
            ', Product: ' || v_name ||
            ', Stock: ' || v_stock
        );
    END LOOP;

    CLOSE low_stock_cursor;
END;
/
CREATE OR REPLACE FUNCTION CALCULATE_DISCOUNT(
    P_AMOUNT NUMBER
)
RETURN NUMBER
IS
    V_DISCOUNT NUMBER;
BEGIN

    IF P_AMOUNT < 2000 THEN
        V_DISCOUNT := P_AMOUNT * 0.05;

    ELSIF P_AMOUNT < 5000 THEN
        V_DISCOUNT := P_AMOUNT * 0.10;

    ELSE
        V_DISCOUNT := P_AMOUNT * 0.15;
    END IF;

    RETURN V_DISCOUNT;
END;
/
CREATE TABLE CUSTOMER_ORDER (
    ORDER_ID NUMBER PRIMARY KEY,
    ACCOUNT_ID NUMBER,
    PRODUCT_ID NUMBER,
    QUANTITY NUMBER,
    ORDER_AMOUNT NUMBER(10,2),
    DISCOUNT NUMBER(10,2),
    FINAL_AMOUNT NUMBER(10,2),
    ORDER_DATE DATE,

    CONSTRAINT FK_ACCOUNT
        FOREIGN KEY (ACCOUNT_ID)
        REFERENCES ACCOUNT(ACCOUNT_ID),

    CONSTRAINT FK_PRODUCT
        FOREIGN KEY (PRODUCT_ID)
        REFERENCES PRODUCT(PRODUCT_ID)
);
CREATE OR REPLACE PROCEDURE PROCESS_ORDER(
    P_ORDER_ID   NUMBER,
    P_ACCOUNT_ID NUMBER,
    P_PRODUCT_ID NUMBER,
    P_QUANTITY   NUMBER
)
IS
    V_PRICE        PRODUCT.PRICE%TYPE;
    V_STOCK        PRODUCT.STOCK%TYPE;
    V_AMOUNT       NUMBER;
    V_DISCOUNT     NUMBER;
    V_FINAL_AMOUNT NUMBER;
    V_COUNT        NUMBER;
BEGIN

    -- Check customer
    SELECT COUNT(*)
    INTO V_COUNT
    FROM ACCOUNT
    WHERE ACCOUNT_ID = P_ACCOUNT_ID;

    IF V_COUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Customer account not found');
    END IF;


    -- Get product price and stock
    SELECT PRICE, STOCK
    INTO V_PRICE, V_STOCK
    FROM PRODUCT
    WHERE PRODUCT_ID = P_PRODUCT_ID;


    -- Check quantity
    IF P_QUANTITY <= 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Quantity must be greater than zero');
    END IF;


    -- Check stock
    IF V_STOCK < P_QUANTITY THEN
        RAISE_APPLICATION_ERROR(-20003, 'Insufficient stock');
    END IF;


    -- Calculate amount
    V_AMOUNT := V_PRICE * P_QUANTITY;

    -- Calculate discount
    V_DISCOUNT := CALCULATE_DISCOUNT(V_AMOUNT);

    -- Calculate final amount
    V_FINAL_AMOUNT := V_AMOUNT - V_DISCOUNT;


    -- Insert order
    INSERT INTO CUSTOMER_ORDER
    VALUES (
        P_ORDER_ID,
        P_ACCOUNT_ID,
        P_PRODUCT_ID,
        P_QUANTITY,
        V_AMOUNT,
        V_DISCOUNT,
        V_FINAL_AMOUNT,
        SYSDATE
    );


    -- Update stock
    UPDATE PRODUCT
    SET STOCK = STOCK - P_QUANTITY
    WHERE PRODUCT_ID = P_PRODUCT_ID;


    COMMIT;


    DBMS_OUTPUT.PUT_LINE('Order processed successfully');
    DBMS_OUTPUT.PUT_LINE('Order Amount : ' || V_AMOUNT);
    DBMS_OUTPUT.PUT_LINE('Discount     : ' || V_DISCOUNT);
    DBMS_OUTPUT.PUT_LINE('Final Amount : ' || V_FINAL_AMOUNT);
    DBMS_OUTPUT.PUT_LINE('Remaining Stock : ' || (V_STOCK - P_QUANTITY));

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Product not found');

    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/
BEGIN
    PROCESS_ORDER(1001, 101, 1, 5);
END;
/
SELECT *
FROM CUSTOMER_ORDER;
SELECT *
FROM PRODUCT;