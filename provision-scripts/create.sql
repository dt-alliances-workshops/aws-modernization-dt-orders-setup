create database catalog;

use catalog;

CREATE TABLE IF NOT EXISTS catalog (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

insert into catalog(name,price) values("iPod", 20.00);
insert into catalog(name,price) values("iPod touch", 10.00);
insert into catalog(name,price) values("iPad", 400.00);
insert into catalog(name,price) values("iPhone 42", 50000.00);
insert into catalog(name,price) values("iPhone 7", 200.00);
insert into catalog(name,price) values("iPhone 8", 225.00);
insert into catalog(name,price) values("iPhone 9", 250.00);
insert into catalog(name,price) values("iPhone X", 300.00);
insert into catalog(name,price) values("iPhone XR", 350.00);
insert into catalog(name,price) values("iPhone 11", 400.00);
insert into catalog(name,price) values("iPad Pro", 1200.00);
insert into catalog(name,price) values("iPad Air", 700.00);
insert into catalog(name,price) values("iPad Mini", 200.00);
insert into catalog(name,price) values("Macbook Air", 1200.00);
insert into catalog(name,price) values("Macbook Pro", 2000.00);