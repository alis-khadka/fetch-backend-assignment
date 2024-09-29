# Wallet API
  
Welcome to **Wallet API**. 
  
## Setup
  
 - Clone the repo and cd into the root directory.  
 `cd path/to/fetch-backend-assignment`  
 - Build the docker image from a terminal. This will setup the database (PostgreSQL) and server (rails application).  
 `docker-compose up --build`  
 - [Optional] You can attach the server in a separate terminal for better readability of the console logs.  
 `docker attach fetch-backend`  
 - Now, to setup the database in development environment, open another terminal and run the following commands in order. This has to be done only once.  
 `docker-compose run fetch-backend rails db:create`  
 `docker-compose run fetch-backend rails db:migrate`  
 `docker-compose run fetch-backend rails db:seed`  
 - After the server is ready, you can visit your browser. The server runs in port 8000.  
 `localhost:8000`  
  
## Running Test Files
  
- Open another terminal and run the following commands in order. This has to be done only once.  
 `docker-compose run fetch-test rails db:create`  
 `docker-compose run fetch-test rails db:migrate`  
 `docker-compose run fetch-test rails db:seed`  
- To run all test cases.  
 `docker-compose run fetch-test rails test`  
- To run a specific test file.  
 `docker-compose run fetch-test rails test path/to/file`  

## Explanation  
  
**Wallet API** has 3 different API endpoints.  

 1.  POST /add  
		Sample request body:   
		`{ "payer": "HARRY", "points": 500, "timestamp" : "2020-11-02T14:00:00Z" }`  
 2.  POST /spend  
		 Sample request body:  
		 `{ "points": 5000 }`  
 3.  GET /balance  
		 No request body required.  

## Note
  
- A file titled `fetch-backend.postman_collection.json` can be found in the root directory of the project. This is  a postman collection of the different api requests for this **Wallet API**.  
- A file `summary.txt` can be found in the root directory of the project with some QnAs.  

