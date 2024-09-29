# Wallet API
  
Welcome to **Wallet API**. 
  
## Installation
  
 - Clone the repo and cd into the root directory.  
 `cd path/to/fetch-backend-assignment`  
 - Build the docker image from a terminal. This will setup the database (PostgreSQL) and server (rails application).  
 `docker-compose up`  
 - [Optional] You can attach the server in a separate terminal for better readability of the console logs.  
 `docker attach fetch-backend`  
 - After the server is ready, you can visit your browser. The server runs in port 8000.  
 `localhost:8000`  


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

