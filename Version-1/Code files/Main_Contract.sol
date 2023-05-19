// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Utils.sol";

contract main_contract
{
  // Flight status values are selected from these options only.
  enum FlightStatus 
  {
    ON_TIME, // 0
    DELAYED, // 1
    CANCELLED, // 2
    COMPLETED, // 3
    NOT_UPDATED // 4
  }
  // Flight details are added in this structure format.
  struct Flight 
  {
    uint flight_id;
    string flight_name;
    string origin;
    string destination;
    uint flight_timestamp;
    uint price;
    uint seats_available;
    uint seats_booked;
    FlightStatus status;
    bool delay_flag;
    bool late_status_update;
    }
  
  struct flightTicket
  {
    uint ticket_ID; // Ticket number
    uint flight_ID; // Flight ID
    address payable customer;
    uint price; // Total ticket price as pre-defined by airlines
    string flightStatus; // 0 - On time, 1 - Delayed, 2 - Cancelled, 3 - Completed, 4 - Not updated
    bool ticketStatus; // True - Booked, False - Cancelled
    bool refund_claim; // True - Refund claimed, False - Refund not claimed
    }
  
  // ----- Declaring & initializing multiple variables ----- //
  utils utility;
  address payable internal airline_owner_1;
  address payable internal customer;
  address payable [] my_customer_list;

  uint current_timestamp;
  uint num_flights;  // Total no. of flights;
  uint flight_id_num; // Added flights are assigned with this Flight ID.
  uint delay_time = 2 hours;
  uint status_update_timestamp;
  uint internal ticket_cancellation_penalty = 2; // 2 wei
  uint internal delay_refund = 2; // 2 wei
  uint internal bookedTickets;  
  uint internal total_price;
  uint internal moneyReturned;
  uint internal moneyRefund;

  string [] list_flights; // Stores list of flight details in proper readabale format.
  string [] internal response_data;
  string [] internal ticket_list;
  string [][] internal store_data;

  mapping(uint => Flight) internal flights; // For storing, managing & accessing flight details.
  mapping(address => uint) internal seatsBooked; // For checking customer address on booked seats.
  mapping(uint =>  flightTicket) internal BookedTicket;

  event customer_added (address);
  event showing_customers (address payable []);
  event output (string);
  event ticket_booked(string, string, string, string [][]);
  event ticket_cancelled(string [], string, string);

  // ------------------------ Done -------------------------- //
  
  constructor(address _utils_address)
  { 
    require(_utils_address != address(0), "Please deploy 'utils.sol' contract first & enter its address.");
    utility = utils(_utils_address);
    airline_owner_1 = payable(msg.sender);
  }

  modifier onlyAirline() 
  {
    require(msg.sender == airline_owner_1, "You are not the owner.");
    _;
  }

  modifier onlyCustomer()
  {
    bool flag = utility.checkCust(payable(msg.sender), my_customer_list);   
    require (flag, "You are not an authorized customer.");   
    _;
  }

  /* For use by airline */
  function _addFlight(string memory _flightName, string memory _origin,string memory _destination, 
                    uint _price, uint _totalSeats) public onlyAirline // returns (string memory)
  {
    num_flights++;
    flight_id_num = num_flights * 100;
    current_timestamp = block.timestamp;
    uint _flight_timestamp = current_timestamp + 48 hours;
    flights[flight_id_num] = 
    Flight( flight_id_num,
            _flightName,
            _origin,
            _destination,
            _flight_timestamp,
            _price,
            _totalSeats,
            0,
            FlightStatus.NOT_UPDATED,
            false,
            false );

    // flights[flight_id_num].status = FlightStatus.NOT_UPDATED;

    string memory flight_date_time = utility.getStringDateTimeFromTimestamp(_flight_timestamp);
    
    addToFlightList(flight_id_num, _flightName, _origin, _destination, flight_date_time, _price, _totalSeats);
    
    //return ("Flight added");
    emit output ("Flight added");
  }

  /* For use by airline */
  function _addCustomer(address payable _cust) public onlyAirline //returns (string memory)
  {
    my_customer_list.push(_cust);
    emit customer_added(_cust);
    //return ("Customer added successfully ");
  }

  /* For use by airline */ 
  function _updateFlightStatus(uint flight_id, uint new_status, uint _date_DDMMYYYY, uint _time_hhmmss) public onlyAirline //returns (string memory)
  {
    /* new_status = 0 for on-time, 1 for delayed, 2 for cancelled, 3 for completed and 4 for not-updated */
    require(flights[flight_id].status != FlightStatus.CANCELLED, "Flight is already cancelled");
    require(flights[flight_id].status != FlightStatus.COMPLETED, "Journey is already completed");
    require(new_status != 3, "Use 'Complete Journey' option" );

    status_update_timestamp = utility.getTimestampFromUint(_date_DDMMYYYY, _time_hhmmss);
    require(flights[flight_id].flight_timestamp > status_update_timestamp,"Can't update after flight time");

    if (flights[flight_id].flight_timestamp - status_update_timestamp < 24 hours)
    {
      flights[flight_id].late_status_update = true;
    }

    string memory info;
    
    if (new_status == 0){ flights[flight_id].status = FlightStatus.ON_TIME; info = "On time";}
    else if (new_status == 1) { flights[flight_id].status = FlightStatus.DELAYED; flights[flight_id].delay_flag = true; info = "Delayed";}
    else if (new_status == 2) { flights[flight_id].status = FlightStatus.CANCELLED; info = "Cancelled";}
    else if (new_status == 4) { flights[flight_id].status = FlightStatus.NOT_UPDATED; info = "Not updated";}
    
    emit output (info);
    //return info;
  }

  /* For use by airline */ 
  function _completeJourney(uint flight_id) public payable onlyAirline //returns (string memory)
  {
      uint money4airline;
      flights[flight_id].status = FlightStatus.COMPLETED;
            
      if (flights[flight_id].delay_flag == true)
      {
        money4airline = flights[flight_id].seats_booked * (flights[flight_id].price - 2); // 2 wei will be refunded to each customer for delay;
      }
      else
      {
        money4airline = flights[flight_id].seats_booked * flights[flight_id].price ;
      }
      airline_owner_1.transfer(money4airline);
      emit output ("Journey completed");
      //return ("Journey completed");
  }

  /* For use by customer */
  function getEmptySeats(uint flight_id) public view returns(uint)
  {
    return flights[flight_id].seats_available; 
  }

  /* For use by customer */
  function bookTicket(uint flight_id, uint num_tickets) public payable onlyCustomer //returns (string memory, string memory, string memory, string [][] memory)
  {  
    require (flights[flight_id].status != FlightStatus.COMPLETED, "Journey already completed");
    require (flights[flight_id].status != FlightStatus.CANCELLED, "Flight is cancelled");
    require(msg.value >= num_tickets*(flights[flight_id].price), "Insufficient funds");
    require(num_tickets>0, "No. of tickets should be more than 0");
    require(num_tickets <= flights[flight_id].seats_available, "Enough seats not available");

    total_price = 0;
    moneyReturned = 0;
    delete store_data;
    customer = payable(msg.sender);
    string memory fl_status = currentFlightStatus(flight_id);
    string memory info = "Booking Successful!";


    total_price = num_tickets*flights[flight_id].price;
    moneyReturned = msg.value - total_price;
    if (moneyReturned > 0) 
    {
      customer.transfer(moneyReturned);
    }

    (string memory paid, string memory returned, string memory total_tickets) = utility.getPaymentString(msg.value, moneyReturned, num_tickets);
    //string memory paid = string(abi.encodePacked(bytes(" Money paid = "), utility.uint2str(msg.value), bytes(" Wei ") ));
    //string memory returned = string(abi.encodePacked(bytes(" Money returned = "), utility.uint2str(moneyReturned), bytes(" Wei ") ));
    //string memory total_tickets = string(abi.encodePacked(bytes(" Booked tickets = "), utility.uint2str(num_tickets)));

    for (uint i=0; i<num_tickets; i++)
    {
      bookedTickets ++;
      BookedTicket[bookedTickets] = flightTicket(
      bookedTickets,
      flight_id,
      customer,
      total_price,
      fl_status, 
      true, // Ticket is not cancelled by customer
      false // No refunds have been claimed by customer
      );
      
      add2TicketsList(bookedTickets, flight_id, customer);
      string [] memory temp_data = generateResponse(info, bookedTickets, flight_id, customer, fl_status);
      store_data.push(temp_data);
    }

    seatsBooked[msg.sender] = seatsBooked[msg.sender] + num_tickets;
    flights[flight_id].seats_available = flights[flight_id].seats_available - num_tickets;
    flights[flight_id].seats_booked = flights[flight_id].seats_booked + num_tickets;
    seatsBooked[customer] = seatsBooked[customer] + num_tickets;

    emit ticket_booked(paid, returned, total_tickets, store_data);
    //return (paid, returned, total_tickets, store_data);

  }

  /* For use by customer */
  function cancelTicket(uint ticket_id, uint flight_id, uint _date_DDMMYYYY, uint _time_hhmmss) public payable onlyCustomer returns (string memory)
  {  
    /* Cancellation usercases --  

    Case - 1 : Flight cancellation by Airline -- Covered.
    Case - 2 : Flight Delay by airline & then cancellation -- Since customer can claim refund only 24hrs after flight departure time, 
               by then the flight status will be changed to "Cancelled" and this case will be covered under Case-1
    Case - 3 : Flight Delay by airline & then journey completed -- Covered by checking airline.getDelayFlag in "getRefund", 
               this refunds 2 wei to customer account and rest of the money is credited to airline account after flight status is updated as "Journey Completed"
    Case - 4 : Flight Delay by airline & cancellation by customer -- 
               If flight is delayed by airline, customer can cancel his ticket and get full refund.
               Customer will have to cancel his ticket before flight departure, for this case to hold true.
               If he chooses to continue journey on delayed flight, then Case-3 holds true.
    Case - 5 : Flight cancelled by airline & then customer cancelled his ticket -- Same effect as Case-1, covered
    Case - 6 : Flight status not updated by airline within 24 hrs of flight time -- Same as Case-1

    */

        // Date should be in DDMMYYYY format & time should be in hhmmss format (24-hour-clock)
        require(payable(msg.sender) == BookedTicket[ticket_id].customer, "Only ticket owner can cancel tickets");
        require (flights[flight_id].status != FlightStatus.COMPLETED, "Journey already completed");

        uint cancellation_timestamp = utility.getTimestampFromUint(_date_DDMMYYYY, _time_hhmmss);
        uint flight_timestamp = flights[flight_id].flight_timestamp;
        bool penalty_applicable;

        require (flight_timestamp > cancellation_timestamp, "Ticket can only be cancelled before 2 hours of flight departure time. Try refund option.");
        require (flight_timestamp - cancellation_timestamp >= 2 hours, "Cannot cancel tickets within 2 hours of flight time.");

        if (flights[flight_id].status == FlightStatus.CANCELLED || // If airline cancels flight
            flights[flight_id].late_status_update == true || // If flight status not updated within 24hrs of flight time
            flights[flight_id].delay_flag == true) // If flight is delayed by airline
        {
                moneyRefund = flights[flight_id].price;
                customer.transfer(moneyRefund);
                penalty_applicable = false;
        }

        // else if (cancellation_timestamp >= flight_timestamp && flights[flight_id].status == FlightStatus.NOT_UPDATED)  // If flight status not updated till flight time
        // {
        //         moneyRefund = flights[flight_id].price;
        //         customer.transfer(moneyRefund);
        //         penalty_applicable = false;
        // }

        else 
        {
            moneyRefund = flights[flight_id].price - ticket_cancellation_penalty;
            penalty_applicable = true;
            customer.transfer(moneyRefund);
            airline_owner_1.transfer(ticket_cancellation_penalty);
        }

        (string [] memory temp_data, string memory penalty, string memory refund) = processCancellation(ticket_id, flight_id, moneyRefund, penalty_applicable);

         emit ticket_cancelled(temp_data, penalty, refund);
         return(refund);
              
  }

  /* For use by customer */
  function getRefund(uint flight_id, uint ticket_id, uint _date_DDMMYYYY, uint _time_hhmmss) public //returns (string memory)
  {
        // Date should be in DDMMYYYY format & time should be in hhmmss format (24-hour-clock)
        require(payable(msg.sender) == BookedTicket[ticket_id].customer, "Only ticket owner can claim refund");
        require(BookedTicket[ticket_id].refund_claim == false, "This ticket is already refunded");

        uint cancellation_timestamp = utility.getTimestampFromUint(_date_DDMMYYYY, _time_hhmmss);
        uint flight_timestamp = flights[flight_id].flight_timestamp;

        require (cancellation_timestamp > flight_timestamp, "Cannot claim refund before flight time. ");
        require (cancellation_timestamp - flight_timestamp >= 24 hours, "You can only claim refund after 24 hours of flight time.");

        string memory info;

        // If airline cancels flight or does not update flight status within 24 hours of flight time, 
        // both will be treated as cancellation when customer claims refund.

        if (flights[flight_id].status == FlightStatus.NOT_UPDATED)
        {
         flights[flight_id].status = FlightStatus.CANCELLED; 
        }

        if (flights[flight_id].status == FlightStatus.CANCELLED || 
            flights[flight_id].late_status_update == true)
        {
            (info) = cancelTicket(ticket_id, flight_id, 25012023, 101010);
            BookedTicket[ticket_id].refund_claim = true;
            emit output(info);
            // return (info);
            
        }

        else if (flights[flight_id].delay_flag == true)
        {
            payable(msg.sender).transfer(delay_refund);
            BookedTicket[ticket_id].refund_claim = true;
            info = "Sorry for delay. 2 Wei refunded to your account.";
            emit output(info);
            // return (info);
        }

        else 
        {
            info = "Refund not applicable.";
            emit output(info);
            // return(info);
        }

  }

  /* Common use */
  function showCustomers() public view returns (address payable [] memory)
  {
    return (my_customer_list);
  }

  /* Common use */
  function showFlights() public view returns (string [] memory)
  {
    return list_flights;
  }

  /* Common use */
  function currentFlightStatus(uint flight_id) public view returns(string memory)
  {
      string memory current_status = printStatus(flight_id);
      return current_status;
  }

  /* Common use */
  function getAllTickets() public view returns (string [] memory)
  {
    return (ticket_list);
  }

  /* Internal use */
  function addToFlightList(uint flight_id, string memory _flightName, string memory _origin,string memory _destination, 
  string memory _date_time, uint _price, uint _totalSeats ) internal 
  {
    
    // string memory flightID = string(abi.encodePacked(bytes(" { Flight ID = "), utility.uint2str(flight_id)));
    // string memory flight_name = string(abi.encodePacked(bytes(" Flight Name = "), bytes(_flightName)));
    // string memory origin = string(abi.encodePacked(bytes(" Origin = "), bytes(_origin)));
    // string memory destination = string(abi.encodePacked(bytes(" Destination = "), bytes(_destination)));
    // string memory price = string(abi.encodePacked(bytes(" Ticket Price = "), utility.uint2str(_price)));
    // string memory seatsAvl = string(abi.encodePacked(bytes(" Total Seats = "), utility.uint2str(_totalSeats), bytes(" }")));

    (string memory flightID, string memory flight_name, string memory origin, string memory destination,
    string memory price, string memory seatsAvl) = utility.getFlightDataString(flight_id,_flightName,_origin,_destination, _price,_totalSeats);

    list_flights.push(flightID);
    list_flights.push(flight_name);
    list_flights.push(origin);
    list_flights.push(destination); 
    list_flights.push(_date_time);
    list_flights.push(price);
    list_flights.push(seatsAvl);
   }


  // /* Internal use */
  // function checkCust(address payable customerAddr, my_customer_list) internal view returns (bool) 
  // {
  //   bool flag = false;
  //   uint len = my_customer_list.length;
  //   for (uint i=0; i<len; i++ )
  //   {
  //     if (my_customer_list[i] == customerAddr)
  //     {
  //       flag = true; 
  //     }
  //   }
  //   return (flag);
  // }
  
  /* Internal use */
  function printStatus(uint flight_id) internal view returns (string memory) 
  {
    string memory _status = "";
    
    if (flights[flight_id].status == FlightStatus.ON_TIME) {_status = "On Time";}
    else if (flights[flight_id].status == FlightStatus.DELAYED) {_status = "Delayed";}
    else if (flights[flight_id].status == FlightStatus.CANCELLED) {_status = "Cancelled";}
    else if (flights[flight_id].status == FlightStatus.COMPLETED) {_status = "Journey Completed";}
    else if (flights[flight_id].status == FlightStatus.NOT_UPDATED) {_status = "Status not updated by airline";}
    return (_status);
  }

  /* Internal use */
  function add2TicketsList(uint _ticket_id, uint _flight_id, address payable _customer) internal 
  {
    // string memory ticket_id = string(abi.encodePacked(bytes(" { Ticket ID = "), utility.uint2str(_ticket_id)));
    // string memory flight_id = string(abi.encodePacked(bytes(" Flight ID = "), utility.uint2str(_flight_id)));
    // string memory customer_addr = string(abi.encodePacked(bytes(" Customer = "), utility.addr2str(_customer), bytes(" } ") ));

    (string memory ticket_id, string memory flight_id, string memory customer_addr) = utility.getTicketDataString (_ticket_id, _flight_id, _customer);

    ticket_list.push(ticket_id);
    ticket_list.push(flight_id);
    ticket_list.push(customer_addr);
  }

  /* Internal use */
  function delFromTicketsList(uint _ticket_id) internal 
  {
    string memory ticket_id = string(abi.encodePacked(bytes(" { Ticket ID = "), utility.uint2str(_ticket_id)));
    for (uint i; i < ticket_list.length; i++) 
    {
      if (keccak256(abi.encodePacked(ticket_list[i])) == keccak256(abi.encodePacked(ticket_id))) 
      {
        for (uint counter = 0; counter < 3; counter++)
        {
          for (uint j = i; j < ticket_list.length - 1; j++) 
          {
            ticket_list[j] = ticket_list[j + 1];
          }
          ticket_list.pop();
        }
      }
    }
  }

  /* Internal use */
  function generateResponse(string memory _info, uint ticket_ID, uint flight_ID, address payable _customer, 
                            string memory current_flight_status) internal returns (string [] memory)
  {
        delete response_data;

        // string memory _ticket_info = string(abi.encodePacked(bytes(" { "), _info));
        // string memory _ticket_id = string(abi.encodePacked(bytes(" Ticket ID = "), utility.uint2str(ticket_ID)));
        // string memory _flight_id = string(abi.encodePacked(bytes(" Flight ID = "), utility.uint2str(flight_ID)));
        // string memory _customer_addr = string(abi.encodePacked(bytes(" Customer = "), utility.addr2str(_customer)));
        // //string memory _num_tickets = string(abi.encodePacked(bytes(" No. of tickets = "), utility.uint2str(num_tickets)));
        // string memory _fl_status = string(abi.encodePacked(bytes(" Flight Status = "), bytes(current_flight_status), bytes(" }")));
        
        (string memory _ticket_info, string memory _ticket_id, string memory _flight_id, string memory _customer_addr, string memory _fl_status) 
        = utility.getResponseString(_info, ticket_ID, flight_ID, _customer, current_flight_status);
        
        response_data.push(_ticket_info);
        response_data.push(_ticket_id);
        response_data.push(_flight_id);
        response_data.push(_customer_addr);
        response_data.push(_fl_status);

        return (response_data);

  }

  /* Internal use */
  function processCancellation(uint ticket_id, uint flight_id, uint _moneyRefund, bool penalty_applicable) internal returns (string [] memory, string memory, string memory)
  {
        string [] memory temp_data;
        string memory penalty;
        moneyRefund = 0;
        customer = payable(msg.sender);
        
        BookedTicket[ticket_id].ticketStatus = false;
        seatsBooked[msg.sender] = seatsBooked[msg.sender] - 1;
        flights[flight_id].seats_available = flights[flight_id].seats_available + 1;
        flights[flight_id].seats_booked = flights[flight_id].seats_booked - 1;
        seatsBooked[customer] = seatsBooked[customer] - 1;

        if (penalty_applicable == true)
        {
            penalty = string(abi.encodePacked(bytes(" Cancellation penalty = "), utility.uint2str(ticket_cancellation_penalty), bytes(" Wei is deducted ") ));
        }

        else
        {
            penalty = string(abi.encodePacked(bytes(" Penalty = Not applicable ")));
        }

        string memory info = "Successful!";
        string memory fl_status = currentFlightStatus(flight_id);
        string memory refund = string(abi.encodePacked(bytes(" Money refunded = "), utility.uint2str(_moneyRefund), bytes(" Wei ") ));

        temp_data = generateResponse(info, ticket_id, flight_id, customer, fl_status);
        delFromTicketsList(ticket_id);

        return(temp_data, penalty, refund);
  }







  





}