-- 1. CHECKING IF SETUP IS WORKING

-- Primary Server should have a walsender process
SELECT *
FROM pg_catalog.pg_stat_activity 
WHERE backend_type = 'walsender'

-- Standby Server should have a walreceiver process
SELECT *
FROM pg_catalog.pg_stat_activity 
WHERE backend_type = 'walreceiver'

-- Finally the standby server should contain the same data of the primary server
SELECT *
FROM authors

-- 2. STREAMING REPLICATION IN ACTION

-- movies table doesn't exist on standby server
SELECT *
FROM movies

-- Create movies table with foreign key on primary server and insert some rows
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

-- Data should have been replicated on the standby server
SELECT *
FROM movies

-- 3. READONLY STANDBY AND WRITING QUERIES

-- Although only read queries can be performed on standby, write queries can still run on the standby as result of replication
-- Open a transaction in standby server
BEGIN;
SELECT * FROM movies;

-- Add new column on movies table in primary server
ALTER TABLE movies ADD COLUMN rating int;

-- Open a new connection to the standby. The following query won't run because the ALTER TABLE statement queued, which has priority, is blocked by the opened transaction.
SELECT * FROM movies;

-- Unblock the recently opened connection by running END; on standby
-- If you don't do it a mechanism provided by postgresql, and active by default, will forcibly cancel the standby query that conflict with to-be-applied WAL records. The delay, before the query get cancelled, can be controlled via the max_standby_streaming_delay parameter (30s by default).
-- This error will be then showed to the client in the stanby:

-- SQL Error [40001]: FATAL: terminating connection due to conflict with recovery
--  Detail: User was holding a relation lock for too long.
--  Hint: In a moment you should be able to reconnect to the database and repeat your command.

-- The problem doesn't happen if the opened transaction is on the primary, since the statement are sent after commit

-- Primary server connection 1
BEGIN;
SELECT * FROM movies;

-- Primary server connection 2
ALTER TABLE movies ADD COLUMN budget float;

-- At this point SELECT * FROM movies; on primary server will wait. However it will run on the standby.