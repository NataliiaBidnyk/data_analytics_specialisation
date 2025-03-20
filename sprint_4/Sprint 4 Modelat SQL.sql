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

CREATE TABLE IF NOT EXISTS product (
id INT AUTO_INCREMENT PRIMARY KEY,
product_name  VARCHAR(300), 
price DECIMAL(10,2), 
colour VARCHAR(10), 
weight DECIMAL(6,2),
warehouse_id VARCHAR(10)
);

-- insert data to product
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\uploads\\products.csv'
INTO TABLE product
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, product_name, price, colour, weight, warehouse_id)
SET price = REPLACE(price, '$', '') + 0;

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

SELECT t.user_id,
       COUNT(t.user_id) AS transactions_count
FROM user u
       JOIN transaction t
         ON u.id = t.user_id
GROUP BY t.user_id
HAVING transactions_count > 30
ORDER BY transactions_count ASC;

SELECT 
	t.company_id,
	t.credit_card_id,
	c.company_name,
	cc.iban,
	ROUND(AVG(t.amount),2) AS avg_amount
FROM company c
		JOIN transaction t
			ON c.company_id = t.company_id
			AND c.company_name = "Donec Ltd"
		JOIN credit_card cc
			ON cc.id = t.credit_card_id
GROUP  BY t.company_id,
          t.credit_card_id,
          cc.iban; 

CREATE TABLE credit_card_status2
  (
     credit_card_id VARCHAR(15) PRIMARY KEY,
     card_status    ENUM('Active', 'Inactive') NOT NULL,
     FOREIGN KEY (credit_card_id) REFERENCES credit_card(id) ON DELETE CASCADE
  );
  
INSERT INTO credit_card_status (credit_card_id, card_status)
WITH ranked_transactions AS (
SELECT 
	credit_card_id,
	declined,
	RANK() OVER(PARTITION BY credit_card_id ORDER BY timestamp DESC) AS transaction_rank
FROM transaction
),
transaction_card_status AS (
SELECT
credit_card_id,
CASE WHEN SUM(declined) = 3 THEN "Inactive" ELSE "Active" END AS status
FROM ranked_transactions
WHERE transaction_rank <= 3
GROUP BY credit_card_id
)
SELECT
	cc.id,
	COALESCE(tsc.status, 'Active') AS status
FROM credit_card cc
LEFT JOIN transaction_card_status tsc
		ON cc.id = tsc.credit_card_id;

SELECT *
FROM credit_card_status
LIMIT 10;

SELECT 
	product_id, 
    COUNT(transaction_id) AS total_sales
FROM transaction_product
GROUP BY product_id;



