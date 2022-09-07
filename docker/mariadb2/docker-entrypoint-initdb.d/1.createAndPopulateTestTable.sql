USE proxysql_db;

CREATE TABLE test_db2_only (
    id INT NOT NULL,
    value VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,

    PRIMARY KEY (id)
) ENGINE=InnoDB;

INSERT INTO test_db2_only (id, value)
VALUES
    (101, 'Test row 1 (DB2 only)'),
    (102, 'Test row 2 (DB2 only)')
;

ALTER TABLE test_db2_only MODIFY COLUMN id INT auto_increment;

CREATE TABLE test_both (
    id INT NOT NULL,
    value VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,

    PRIMARY KEY (id)
) ENGINE=InnoDB;

INSERT INTO test_both (id, value)
VALUES
    (101, 'Test row 1 (DB2 instance)'),
    (102, 'Test row 2 (DB2 instance)')
;

ALTER TABLE test_both MODIFY COLUMN id INT auto_increment;
