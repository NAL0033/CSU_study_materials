CREATE DATABASE TPCC;
USE TPCC;
CREATE TABLE Warehouse (
    w_id INT PRIMARY KEY,
    w_name VARCHAR(20),
    w_street_1 VARCHAR(20),
    w_street_2 VARCHAR(20),
    w_city VARCHAR(20),
    w_state CHAR(2),
    w_zip CHAR(9),
    w_tax DECIMAL(4,4),
    w_ytd DECIMAL(12,2)
);

CREATE TABLE District (
    d_id INT,
    d_w_id INT,
    d_name VARCHAR(20),
    d_street_1 VARCHAR(20),
    d_street_2 VARCHAR(20),
    d_city VARCHAR(20),
    d_state CHAR(2),
    d_zip CHAR(9),
    d_tax DECIMAL(4,4),
    d_ytd DECIMAL(12,2),
    d_next_o_id INT,
    PRIMARY KEY (d_w_id, d_id),
    FOREIGN KEY (d_w_id) REFERENCES Warehouse(w_id)
);

CREATE TABLE Customer (
    c_id INT,
    c_d_id INT,
    c_w_id INT,
    c_first VARCHAR(20),
    c_middle CHAR(2),
    c_last VARCHAR(20),
    c_street_1 VARCHAR(20),
    c_street_2 VARCHAR(20),
    c_city VARCHAR(20),
    c_state CHAR(2),
    c_zip CHAR(9),
    c_phone CHAR(16),
    c_since DATETIME,
    c_credit CHAR(2),
    c_credit_lim DECIMAL(12,2),
    c_discount DECIMAL(4,4),
    c_balance DECIMAL(12,2),
    c_ytd_payment DECIMAL(12,2),
    c_payment_cnt INT,
    c_delivery_cnt INT,
    c_data VARCHAR(500),
    PRIMARY KEY (c_w_id, c_d_id, c_id),
    FOREIGN KEY (c_w_id, c_d_id) REFERENCES District(d_w_id, d_id)
);

CREATE TABLE Item (
    i_id INT PRIMARY KEY,
    i_im_id INT,
    i_name VARCHAR(24),
    i_price DECIMAL(5,2),
    i_data VARCHAR(50)
);

CREATE TABLE Stock (
    s_i_id INT,
    s_w_id INT,
    s_quantity INT,
    s_ytd INT,
    s_order_cnt INT,
    s_remote_cnt INT,
    s_data VARCHAR(50),
    PRIMARY KEY (s_w_id, s_i_id),
    FOREIGN KEY (s_w_id) REFERENCES Warehouse(w_id),
    FOREIGN KEY (s_i_id) REFERENCES Item(i_id)
);

CREATE TABLE Orders (
    o_id INT,
    o_d_id INT,
    o_w_id INT,
    o_c_id INT,
    o_entry_d DATETIME,
    o_carrier_id INT,
    o_ol_cnt INT,
    o_all_local INT,
    PRIMARY KEY (o_w_id, o_d_id, o_id),
    FOREIGN KEY (o_w_id, o_d_id, o_c_id) REFERENCES Customer(c_w_id, c_d_id, c_id)
);

CREATE TABLE OrderLine (
    ol_o_id INT,
    ol_d_id INT,
    ol_w_id INT,
    ol_number INT,
    ol_i_id INT,
    ol_supply_w_id INT,
    ol_delivery_d DATETIME,
    ol_quantity INT,
    ol_amount DECIMAL(6,2),
    ol_dist_info CHAR(24),
    PRIMARY KEY (ol_w_id, ol_d_id, ol_o_id, ol_number),
    FOREIGN KEY (ol_w_id, ol_d_id, ol_o_id) REFERENCES Orders(o_w_id, o_d_id, o_id),
    FOREIGN KEY (ol_i_id) REFERENCES Item(i_id)
);