# Requirements

A recent version of docker installed on your machine

# Run the demo

Run 

`docker compose up --build -d --renew-anon-volumes --force-recreate`

This will start two databases locally. You can now connect to them at http://localhost:5432 (primary) and http://localhost:5430 (replica) and follow the instructions in [demo.sql](./demo.sql).

