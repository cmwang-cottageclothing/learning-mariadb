# An error 1265 occurred

An error occurred when I was typing the code in Chapter 5 of Learning MySQL and MariaDB. The error message is:

_ERROR 1265 (01000): Data truncated for column 'endangered' at row 1_

To reproduce the error, use the following SQL code.

```SQL
CREATE DATABASE test;

USE DATABASE test;

CREATE TABLE birds(
    bird_id INT AUTO_INCREMENT PRIMARY KEY,
    scientific_name VARCHAR(255) UNIQUE,
    common_name VARCHAR(50),
    family_id INT,
    description TEXT
);

INSERT INTO birds (scientific_name, common_name)
VALUES ('Charadrius vociferus', 'Killdeer'),
('Gavia immer', 'Great Northern Loon'),
('Aix sponsa', 'Wood Duck'),
('Chordeiles minor', 'Common Nighthawk'),
('Sitta carolinensis', ' White-breasted Nuthatch'),
('Apteryx mantelli', 'North Island Brown Kiwi');

ALTER TABLE birds
ADD COLUMN body_id CHAR(2) AFTER wing_id,
ADD COLUMN bill_id CHAR(2) AFTER body_id,
ADD COLUMN endangered BIT DEFAULT b'1' AFTER bill_id,
CHANGE COLUMN common_name common_name VARCHAR(255);

UPDATE birds SET endangered = 0
WHERE bird_id IN(1, 2,4, 5);

ALTER TABLE birds_new
MODIFY COLUMN endangered
ENUM('Extinct',
'Extinct in Wild',
'Threatened - Critically Endangered',
'Threatened - Endangered',
'Threatened - Vulnerable',
'Lower Risk - Conservation Dependent',
'Lower Risk - Near Threatened',
'Lower Risk - Least Concern')
AFTER family_id;

```

When I was trying the `MODIFY COLUMN` command, MariaDB emitted the above error code.

I googled and found one possible solution. First I set the value of the column `endangered` to 1.

```SQL
UPDATE birds SET endangered = 1;
```

Then I tried the `MODIFY COLUMN` again. This time the command did not cause the error.

It should be mentioned here. In this circumstance, the **column endangered** originally stores data of type `BIT`. The `MODIFY COLUMN` command change the data type to `ENUM`. In the above SQL script, before `MODIFY COLUMN` command, the data stored in **column endangered** is of type `BIT`. The values of **column endangered** in rows 3 and 6 are `1`. Values in remaining rows are `0`.

I am not sure whether the `MODIFY COLUMN` will delete the data, but I observed that the **column endangered** store `Extinct` in all rows after the `MODIFY COLUMN`. The `MODIFY COLUMN` seems not to delete data.

Since no data is
