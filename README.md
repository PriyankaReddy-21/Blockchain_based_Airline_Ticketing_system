# Blockchain_based_Airline_Ticketing_system
Ethereum Blockchain based Airline ticketing system on AWS Cloud

<img width="1417" alt="Image" src="https://github.com/PriyankaReddy-21/Blockchain_based_Airline_Ticketing_system/assets/125461903/6ee12241-eb93-4b0f-959c-05a5a8938b38">

#### Introduction : 

1. We’ll be creating a unique blockchain based airline ticket management system to entice users with transparency, automated refunds and airline delay penalties. 
2. As the base platform, we’ll be creating a private Ethereum blockchain network, using geth, in the AWS Cloud. 
3. We will have the nodes running on multiple EC2 VM machines directly, on different ports.
4. We will be using Clique (Proof of Authority) for faster block creations. 
5. We’ll be developing a base contract code, in Solidity, which will be deployed every time a ticket is bought by a customer from airlines. 
6. The airlines will deploy the contract with customer address and simulated dummy flight details (flight number, ticket price, seats, flight datetime, etc.) 
7. The customer will then call a specific function to transfer the ticket money to the contract and receive a confirmation-id / ticket-id and flight details in response. 

#### Smart Contract Features: 

1. The customer should be able to trigger a cancellation anytime till 2 hours before the flight start time. This should refund money to the customer minus the percentage penalty predefined in the contract by the airlines. The penalty amount should be automatically sent to the airline account. 

2. Any cancellation triggered by the airline before or after departure time should result in a complete amount refund to the customer. 

3. The airline should update the status of the flight within 24 hours of the flight start time. It can be on-time start, cancelled or delayed. 

4. 24 hours after the flight departure time, the customer can trigger a claim function to demand a refund. 
      -   They should get a complete refund in case of cancellation by the airline.
      - In case of a delay, they should get a predefined percentage amount, and the rest should be sent to the airline.
      - If the airline hasn’t updated the status within 24 hours of the flight departure time, and a customer claim is made, it should be treated as an airline cancellation case by the contract. 

5. Randomness and call based simulation of various features like normal flights, cancellation by the airline, cancellation by the customer, and delayed flights. 

#### Contract deployment information : 

1. To run the code files as airline :
      - Log in via airline account
      - First compile and deploy utils.sol and  copy its contract address.
      - Next, compile and deploy main_contract.sol by entering the contract address of already deployed utils.sol
      - Now you can add customers and flight details for use by customers.

2. To use as a customer :
      - Log in via customer account
      - Copy the contract address of main_contract.sol which is already deployed by airline.
      - Paste it in “At Address” section of Remix and enter.
      - You will get access to all the customer related information and functionalities for airline ticket booking / cancellation / refund etc.

Thank You !

  
  
