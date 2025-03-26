CREATE DATABASE IF NOT EXISTS sales;
USE sales;

CREATE TABLE IF NOT EXISTS company (
    company_id VARCHAR(15) PRIMARY KEY,
    company_name VARCHAR(255),
    phone VARCHAR(15),
    email VARCHAR(100),
    country VARCHAR(100),
    website VARCHAR(255)
);

SHOW VARIABLES LIKE 'secure_file_priv';

SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\uploads\\companies.csv'
INTO TABLE company
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT *
FROM company;

CREATE TABLE IF NOT EXISTS user (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    surname VARCHAR(100),
    phone VARCHAR(150),
    email VARCHAR(150),
    birth_date VARCHAR(100),
    country VARCHAR(150),
    city VARCHAR(150),
    postal_code VARCHAR(100),
    address VARCHAR(255)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\uploads\\users_usa.csv'
INTO TABLE user
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\uploads\\users_uk.csv'
INTO TABLE user
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\uploads\\users_ca.csv'
INTO TABLE user
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SELECT *
FROM user;

ALTER TABLE user MODIFY id INT NOT NULL AUTO_INCREMENT;

CREATE TABLE IF NOT EXISTS credit_card (
id VARCHAR(15) PRIMARY KEY,
user_id INT,
iban  VARCHAR(35), 
pan VARCHAR(20), 
pin INT, 
cvv INT,
track1 VARCHAR(255),
track2 VARCHAR(255),
expiring_date VARCHAR(8)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\uploads\\credit_cards.csv'
INTO TABLE credit_card
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT *
FROM credit_card;

CREATE TABLE IF NOT EXISTS transaction (
        id VARCHAR(255) PRIMARY KEY,
        credit_card_id VARCHAR(15),
        company_id VARCHAR(15),
        user_id INT,
        lat DECIMAL (12,10),
        longitude DECIMAL(13,10),
        timestamp TIMESTAMP,
        amount DECIMAL(10, 2),
        declined BOOLEAN,
        product_ids VARCHAR(100),
        FOREIGN KEY (credit_card_id) REFERENCES credit_card(id),
        FOREIGN KEY (company_id) REFERENCES company(company_id),
        FOREIGN KEY (user_id) REFERENCES user(id)
    );
    
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\uploads\\transactions.csv'
INTO TABLE transaction
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, credit_card_id, company_id, timestamp, amount, declined, product_ids, user_id, lat, longitude);

SELECT *
FROM transaction;

SELECT u.id, u.name, u.surname 
FROM user u
WHERE EXISTS (
    SELECT 1
    FROM transaction t
    WHERE t.user_id = u.id
    GROUP BY t.user_id
    HAVING COUNT(*) > 30
)
ORDER BY u.id;

SELECT 
	t.company_id,
	t.credit_card_id,
	c.company_name,
	cc.iban,
	ROUND(AVG(t.amount),2) AS avg_amount
FROM company c
JOIN transaction t ON c.company_id = t.company_id
JOIN credit_card cc ON cc.id = t.credit_card_id
WHERE c.company_name = "Donec Ltd"
GROUP  BY t.company_id, t.credit_card_id, cc.iban;

CREATE TABLE credit_card_status_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    credit_card_id VARCHAR(15) NOT NULL,
    card_status ENUM('Active', 'Inactive') NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    modified_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (credit_card_id) REFERENCES credit_card(id) ON DELETE CASCADE
);

INSERT INTO credit_card_status_history (credit_card_id, card_status)
WITH ranked_transactions AS (
SELECT credit_card_id, timestamp, declined, RANK() OVER(PARTITION BY credit_card_id ORDER BY timestamp DESC) AS transaction_rank
FROM transaction
)
SELECT
credit_card_id,
CASE WHEN SUM(declined) >= 3 THEN "Inactive" ELSE "Active" END AS status
FROM ranked_transactions
WHERE transaction_rank <= 3
GROUP BY credit_card_id;

SELECT *
FROM credit_card_status_history
LIMIT 10;

SELECT COUNT(*) as active_cards_count
FROM credit_card_status_history
WHERE card_status = "Active";

CREATE TABLE IF NOT EXISTS product (
id INT AUTO_INCREMENT PRIMARY KEY,
product_name  VARCHAR(300), 
price DECIMAL(10,2), 
colour VARCHAR(10), 
weight DECIMAL(6,2),
warehouse_id VARCHAR(10)
);

ALTER TABLE product MODIFY COLUMN price VARCHAR(50);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\uploads\\products.csv'
INTO TABLE product
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, product_name, price, colour, weight, warehouse_id)
SET price = REPLACE(price, '$', '') + 0;

ALTER TABLE product MODIFY COLUMN price DECIMAL(10,2);
ALTER TABLE product ADD COLUMN currency VARCHAR(3) DEFAULT 'USD';


CREATE TABLE IF NOT EXISTS transaction_product(
transaction_id VARCHAR(255),
product_id  INT,
PRIMARY KEY (transaction_id, product_id), -- composite PK
FOREIGN KEY (transaction_id) REFERENCES transaction(id),
FOREIGN KEY (product_id) REFERENCES product(id)
);

INSERT INTO transaction_product (transaction_id, product_id)
SELECT 
	t.id, 
    p.id
FROM transaction t
JOIN product p 
		ON FIND_IN_SET(p.id, REPLACE (t.product_ids,' ','' )) > 0;
        
SELECT 
	tp.product_id, 
   (SELECT p.product_name FROM product p WHERE tp.product_id = p.id) AS product_name,
    COUNT(tp.product_id) AS total_sales
FROM transaction_product tp
GROUP BY tp.product_id;





