-- Roles used by the stand by server for replication
CREATE ROLE replica_role WITH LOGIN REPLICATION PASSWORD 'replica_password';

\c postgres; 

-- Create authors table
CREATE TABLE authors (
    author_id SERIAL PRIMARY KEY,
    author_name VARCHAR(255) NOT NULL,
    nationality VARCHAR(100),
    birth_year INT
);

-- Insert rows into authors table
INSERT INTO authors (author_name, nationality, birth_year) VALUES
    ('Stephen King', 'American', 1947),
    ('Mario Puzo', 'American', 1920),
    ('Christopher Nolan', 'British', 1970);