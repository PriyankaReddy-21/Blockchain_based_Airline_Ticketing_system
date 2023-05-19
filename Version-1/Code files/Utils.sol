// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract utils {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    function uint2str(uint256 _i) public pure returns (string memory str)
    {
        if (_i == 0) { return "0"; }
        uint256 j = _i;
        uint256 length;
        while (j != 0) 
        { 
            length++; 
            j /= 10; 
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0)
        {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    
    }

    function addr2str(address _address) public pure returns(string memory) 
    {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = '0';
        _string[1] = 'x';
        for(uint i = 0; i < 20; i++) 
        {
            _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    // function stringToUint(string memory s) public returns (uint result) {
    //     bytes memory b = bytes(s);
    //     uint i;
    //     result = 0;
    //     for (i = 0; i < b.length; i++) {
    //         uint c = uint(b[i]);
    //         if (c >= 48 && c <= 57) {
    //             result = result * 10 + (c - 48);
    //         }
    //     }
    // }

    
    

    function timestampToDateTime(uint timestamp) public pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) 
    {
        // Adding 19800 to timestamp to convert into GMT+5.30 (Indian Standard Time)
        (year, month, day) = _daysToDate((timestamp + 19800) / SECONDS_PER_DAY); 
        uint secs = (timestamp + 19800) % SECONDS_PER_DAY;
        hour = (secs / SECONDS_PER_HOUR);
        secs = secs % SECONDS_PER_HOUR;
        minute = (secs / SECONDS_PER_MINUTE);
        second = secs % SECONDS_PER_MINUTE;
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------

    function _daysToDate(uint _days) public pure returns (uint year, uint month, uint day) 
    {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) public pure returns (uint timestamp) 
    {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
        timestamp = timestamp - 19800; // Subtracting 19800 to timestamp to convert into GMT+5.30 (Indian Standard Time)
    }

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) 
    {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    function extractDatefromUint(uint _date_DDMMYYYY) public pure returns (uint, uint, uint)
    {
        
        // _date_DDMMYYYY = 2 4 0 9 2 0 2 1
        /*                                1
                                        1 0
                                      1 0 0
                                    1 0 0 0
                                  1 0 0 0 0
                                1 0 0 0 0 0
                              1 0 0 0 0 0 0
                            1 0 0 0 0 0 0 0
        */

        uint date = _date_DDMMYYYY;

        uint YY = date % 10000;

        uint MM = ((date - YY)/10000) % 100;

        uint DD = (date - (date % 1000000))/1000000;

        // This also works : uint DD = (date - ((MM * 10000) + YY))/1000000;

        return (DD, MM, YY);
    }


    function extractTimefromUint(uint _time_hhmmss) public pure returns (uint, uint, uint)
    {
        
        // _time_hhmmss = 0 8 1 0 2 0
        /*                          1
                                  1 0
                                1 0 0
                              1 0 0 0
                            1 0 0 0 0
                          1 0 0 0 0 0
        */

        uint time = _time_hhmmss;

        uint ss = time % 100;

        uint mm = ((time % 10000) - ss) / 100;

        uint hh = (time - (( mm * 100 ) + ss)) / 10000;

        return (hh, mm, ss);
    }

    function getTimestampFromUint(uint _date_DDMMYYYY, uint _time_hhmmss) public pure returns (uint)
    {
        (uint DD, uint MM, uint YYYY) = extractDatefromUint(_date_DDMMYYYY); // 29 04 2023
        (uint hh, uint mm, uint ss) = extractTimefromUint(_time_hhmmss); // 13 0 0

        uint timestamp = timestampFromDateTime(YYYY, MM, DD, hh, mm, ss); // 2023, 04, 29, 13, 0, 0
        return (timestamp);

    }

    function getStringDateTimeFromTimestamp(uint timestamp) public pure returns(string memory)
    {
        (uint Y, uint M, uint D, uint H, uint MI, uint S) = timestampToDateTime(timestamp);
    
        string memory date = string(abi.encodePacked(uint2str(D), bytes("-"), uint2str(M), bytes("-"), uint2str(Y)));
        string memory time = string(abi.encodePacked(uint2str(H), bytes(":"), uint2str(MI), bytes(":"), uint2str(S)));
        string memory date_time = string(abi.encodePacked(bytes(" Date = "), date, bytes(" Time = "), time));

        return (date_time);

    }

    function addr2uint(address _addr) public pure returns(uint)
    {
        return(uint256(uint160(_addr)));
    }

    function uint2addr(uint _uint) public pure returns(address)
    {
        return(address(uint160(uint256(_uint))));
    }

    /* Internal use */
  function getFlightDataString(uint flight_id, string memory _flightName, string memory _origin,string memory _destination, 
  /*string memory _date_time,*/ uint _price, uint _totalSeats ) public pure returns 
  (string memory, string memory, string memory, string memory, string memory, string memory)
  {
    
    string memory flightID = string(abi.encodePacked(bytes(" { Flight ID = "), uint2str(flight_id)));
    string memory flight_name = string(abi.encodePacked(bytes(" Flight Name = "), bytes(_flightName)));
    string memory origin = string(abi.encodePacked(bytes(" Origin = "), bytes(_origin)));
    string memory destination = string(abi.encodePacked(bytes(" Destination = "), bytes(_destination)));
    string memory price = string(abi.encodePacked(bytes(" Ticket Price = "), uint2str(_price)));
    string memory seatsAvl = string(abi.encodePacked(bytes(" Total Seats = "), uint2str(_totalSeats), bytes(" }")));

    return (flightID, flight_name, origin, destination, price, seatsAvl);
    // list_flights.push(flightID);
    // list_flights.push(flight_name);
    // list_flights.push(origin);
    // list_flights.push(destination); 
    // list_flights.push(_date_time);
    // list_flights.push(price);
    // list_flights.push(seatsAvl);
    
  }

  function getResponseString(string memory _info, uint ticket_ID, uint flight_ID, address payable _customer, 
  string memory current_flight_status) public pure returns (string memory, string memory, string memory, string memory, string memory )
  {
  
        string memory _ticket_info = string(abi.encodePacked(bytes(" { "), _info));
        string memory _ticket_id = string(abi.encodePacked(bytes(" Ticket ID = "), uint2str(ticket_ID)));
        string memory _flight_id = string(abi.encodePacked(bytes(" Flight ID = "), uint2str(flight_ID)));
        string memory _customer_addr = string(abi.encodePacked(bytes(" Customer = "), addr2str(_customer)));
        string memory _fl_status = string(abi.encodePacked(bytes(" Flight Status = "), bytes(current_flight_status), bytes(" }")));

        return (_ticket_info, _ticket_id, _flight_id, _customer_addr, _fl_status);
  }

  function getPaymentString(uint money_paid, uint money_returned, uint num_tickets) public pure returns 
  (string memory paid, string memory returned, string memory total_tickets)
  {
    paid = string(abi.encodePacked(bytes(" Money paid = "), uint2str(money_paid), bytes(" Wei ") ));
    returned = string(abi.encodePacked(bytes(" Money returned = "), uint2str(money_returned), bytes(" Wei ") ));
    total_tickets = string(abi.encodePacked(bytes(" Booked tickets = "), uint2str(num_tickets)));
  }

  /* Internal use */
  function checkCust(address payable customerAddr, address payable [] memory my_customer_list) public pure returns (bool) 
  {
    bool flag = false;
    uint len = my_customer_list.length;
    for (uint i=0; i<len; i++ )
    {
      if (my_customer_list[i] == customerAddr)
      {
        flag = true; 
      }
    }
    return (flag);
  }

  function getTicketDataString (uint _ticket_id, uint _flight_id, address payable _customer) public pure returns (string memory ticket_id, string memory flight_id, string memory customer_addr )
  {
    ticket_id = string(abi.encodePacked(bytes(" { Ticket ID = "), uint2str(_ticket_id)));
    flight_id = string(abi.encodePacked(bytes(" Flight ID = "), uint2str(_flight_id)));
    customer_addr = string(abi.encodePacked(bytes(" Customer = "), addr2str(_customer), bytes(" } ") ));
  }

}

