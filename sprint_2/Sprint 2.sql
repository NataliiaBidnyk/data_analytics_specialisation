USE transactions;

/* Nivell 1 Exercici 2 Utilitzant JOIN realitzaràs les següents consultes:
 Llistat dels països que estan fent compres.
 List of countries making purchases */
SELECT DISTINCT company.country
FROM company
INNER JOIN transaction ON company.id = transaction.company_id
-- excluded declined transactions
WHERE transaction.declined  = FALSE
ORDER BY company.country ASC;

/* Des de quants països es realitzen les compres.
 From how many countries the purchases are made. */
SELECT COUNT(DISTINCT company.country) AS purchase_country_count
FROM company
INNER JOIN transaction ON company.id = transaction.company_id
-- exclude declined transactions
WHERE transaction.declined  = FALSE;

-- Identifica la companyia amb la mitjana més gran de vendes
-- Identify the company with the highest average sales
SELECT company.id, company.company_name, avg(transaction.amount) AS average_sales
FROM company
INNER JOIN transaction ON company.id = transaction.company_id
-- excluded declined transactions
WHERE transaction.declined  = FALSE
GROUP BY company.id, company.company_name
ORDER BY avg(transaction.amount) DESC
LIMIT 1;

/* Exercici 3
Mostra totes les transaccions realitzades per empreses d'Alemanya
Show all transactions made from Germany */ 

/* Retrieves distinct country names that contain the substring 'Ger'. 
This query verifies that 'Germany' appears only once and is spelled correctly. */
SELECT DISTINCT country
FROM company
WHERE country LIKE '%GER%';

-- Select all transactions made from Germany
SELECT *
FROM transaction
-- excluded declined transactions
WHERE declined IS FALSE
-- include only company_id that has corresponging country "Germany"
AND company_id IN (SELECT DISTINCT id
FROM company
WHERE country = "Germany");

/*
Llista les empreses que han realitzat transaccions per un amount superior a la mitjana de totes les transaccions.
List the companies that have made transactions for an amount greater than the average of all transactions.*/
SELECT 
t.company_id AS company_id,
(SELECT company_name FROM company WHERE company_id = id) AS company_name,
t.company_transactions_total,
t.avg_all_transactions
FROM
(SELECT
company_id,
-- calculate amount of the transactions by company 
SUM(amount) AS company_transactions_total, 
-- calculate the average of all transactions
(SELECT ROUND(AVG(amount),2) FROM transaction WHERE declined is FALSE) AS avg_all_transactions
FROM transaction
WHERE declined is FALSE
GROUP BY company_id) AS t
-- condition select companies that have made transactions for an amount greater than the average of all transactions.
HAVING t.company_transactions_total > t.avg_all_transactions
ORDER BY t.company_transactions_total DESC;

/* Eliminaran del sistema les empreses que no tenen transaccions registrades, entrega el llistat d'aquestes empreses. 
Remove from the system the companies that do not have any recorded transactions, and provide the list of these companies.*/

SELECT DISTINCT company_name
FROM company
WHERE id NOT IN 
-- find all companies that have transactions
(SELECT DISTINCT company_id
FROM transaction
-- excluded declined transactions
WHERE transaction.declined  = 0);

SELECT DISTINCT c.company_name
FROM company c
WHERE NOT EXISTS (
    SELECT t.company_id
    FROM transaction t
    WHERE t.company_id = c.id
      AND t.declined = 0
);


/* Nivell 2
Exercici 1
Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes. 
Mostra la data de cada transacció juntament amb el total de les vendes.

Identify the five days on which the company generated the highest sales revenue.
Display the date of each transaction along with the total sales.
*/

SELECT DATE(timestamp) as day, SUM(amount) as toatal_sales
FROM transaction
-- excluded declined transactions
WHERE declined = FALSE
GROUP BY day
ORDER BY toatal_sales desc
LIMIT 5;

/* Exercici 2
Quina és la mitjana de vendes per país? Presenta els resultats ordenats de major a menor mitjà.
What is the average sales per country? Present the results ordered from highest to lowest average. */

SELECT c.country, ROUND(AVG(t.amount),2) AS avg_sales
FROM company c
INNER JOIN transaction t ON c.id = t.company_id
-- excluded declined transactions
WHERE t.declined  = 0
GROUP BY c.country
ORDER BY avg_sales DESC;

 /* Exercici 3
En la teva empresa, es planteja un nou projecte per a llançar algunes campanyes publicitàries per a fer competència a la companyia "Non Institute". 
Per a això, et demanen la llista de totes les transaccions realitzades per empreses que estan situades en el mateix país que aquesta companyia.
Mostra el llistat aplicant JOIN i subconsultes.
Mostra el llistat aplicant solament subconsultes.

In your company, a new project is being considered to launch some advertising campaigns to compete with the company "Non Institute." 
For this, you are asked for the list of all transactions made by companies located in the same country as that company.
Display the list using JOIN and subqueries.
Display the list using only subqueries.
*/

-- Mostra el llistat aplicant JOIN i subconsultes
-- Las transacciones rechazadas no han sido excluidas
SELECT DISTINCT country, transaction.id AS transaction_ID
FROM company
INNER JOIN transaction ON company.id = transaction.company_id
-- exclude "Non Institute" from the result
WHERE company_name != "Non Institute"
AND company.country IN 
-- country where "Non Institute" is located
(SELECT country
FROM company
WHERE company_name = "Non Institute");

-- Mostra el llistat aplicant solament subconsultes.
-- Las transacciones rechazadas no han sido excluidas

SELECT DISTINCT transaction.id AS transaction_id
FROM transaction
WHERE company_id IN
-- Find the IDs of companies that are in the same country as 'Non Institute' but are not 'Non Institute' itself
(SELECT id
FROM company
WHERE company_name != "Non Institute"
AND country IN 
(SELECT country
FROM company
WHERE company_name = "Non Institute"));


 /* Nivell 3
Exercici 1
Presenta el nom, telèfon, país, data i amount, d'aquelles empreses que van realitzar transaccions amb un valor comprès entre 100 i 200 euros 
i en alguna d'aquestes dates: 29 d'abril del 2021, 20 de juliol del 2021 i 13 de març del 2022. Ordena els resultats de major a menor quantitat.

Display the name, phone number, country, date, and amount of companies that made transactions
with a value between 100 and 200 euros on any of the following dates: April 29, 2021, July 20, 2021, and March 13, 2022.
Sort the results in descending order by amount (from highest to lowest)
 */

SELECT c.company_name, c.phone, c.country, t.timestamp, t.amount
FROM company c
INNER JOIN transaction t ON c.id = t.company_id
WHERE t.amount BETWEEN 100 AND 200
AND DATE(t.timestamp) IN ("2021-04-29", "2021-07-20" , "2022-03-13")
-- exclude declined transactions
AND t.declined = 0
ORDER BY t.amount DESC;

 /* Exercici 2
Necessitem optimitzar l'assignació dels recursos i dependrà de la capacitat operativa que es requereixi, per la qual cosa et demanen la informació sobre la quantitat
de transaccions que realitzen les empreses, però el departament de recursos humans és exigent i vol un llistat de les empreses on especifiquis si tenen més 
de 4 transaccions o menys.  

We need to optimize resource allocation, which will depend on the operational capacity required. 
Therefore, you are asked to provide information on the number of transactions made by companies.
However, the human resources department is strict and wants a list of companies specifying whether they have made more than 4 transactions or fewer.
*/

SELECT c.id , c.company_name, count(*) AS tranasctions_number, 
CASE 
WHEN count(*) > 4 THEN "> 4"
ELSE  "≤ 4"
END AS count_transactions_not_declined

FROM company c
LEFT JOIN transaction t ON c.id = t.company_id
-- exclude declined transactions
WHERE t.declined = FALSE
GROUP BY c.id
ORDER BY tranasctions_number DESC;

-- check mumber of all compnies to see if all of them are returned in the previous query
SELECT DISTINCT company_id
FROM transaction;
