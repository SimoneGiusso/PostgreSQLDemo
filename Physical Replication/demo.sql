-- 1. MAKING SURE EVERYTHING'S UP AND RUNNING

-- Primary Server: Checking for the presence of a walsender process
SELECT *
FROM pg_catalog.pg_stat_activity
WHERE backend_type = 'walsender'

-- Standby Server: Verifying the existence of a walreceiver process
SELECT *
FROM pg_catalog.pg_stat_activity
WHERE backend_type = 'walreceiver'

-- Ensuring the standby server mirrors the primary server's data
SELECT *
FROM authors

-- 2. WATCHING REPLICATION IN ACTION

-- Standby Server: Confirming absence of the 'movies' table
SELECT *
FROM movies

-- Setting up 'movies' table with foreign key on the primary server and inserting data
CREATE TABLE movies (
    movie_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    release_year INT,
    director VARCHAR(255),
    genre VARCHAR(100),
    author_id INT,
    FOREIGN KEY (author_id) REFERENCES authors(author_id)
);
INSERT INTO movies (title, release_year, director, genre, author_id) VALUES
    ('The Shawshank Redemption', 1994, 'Frank Darabont', 'Drama', 1),
    ('The Godfather', 1972, 'Francis Ford Coppola', 'Crime', 2),
    ('The Dark Knight', 2008, 'Christopher Nolan', 'Action', 3);

-- Verifying data replication on the standby server
SELECT *
FROM movies

-- 3. STANDBY FOR READS, BUT WRITES?

-- Although standby allows only read queries, writes can still occur due to replication
-- Initiating a transaction on the standby server
BEGIN;
SELECT * FROM movies;

-- Adding a new column to the 'movies' table on the primary server
ALTER TABLE movies ADD COLUMN rating int;

-- Attempting a query on the standby server. However, it's blocked due to the queued ALTER TABLE statement.
SELECT * FROM movies;

-- Resuming the blocked connection on standby by running END;
-- Without this, PostgreSQL's default mechanism forcibly cancels conflicting standby queries with to-be-applied WAL records.
-- The client on standby receives an error:

-- SQL Error [40001]: FATAL: terminating connection due to conflict with recovery
-- Detail: User was holding a relation lock for too long.
-- Hint: You should be able to reconnect soon and retry your command.

-- Total conflicts can be monitored with SELECT * FROM pg_stat_database_conflicts on standby

-- No such issue occurs if the transaction is initiated on the primary server, as statements are sent post-commit.

-- Primary Server Connection 1
BEGIN;
SELECT * FROM movies;

-- Primary Server Connection 2
ALTER TABLE movies ADD COLUMN budget float;

-- At this point, SELECT * FROM movies; on primary server will wait, while it executes on standby.