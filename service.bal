import ballerinax/impala;
import ballerinax/amadeus.flightcreateorders;
import ballerinax/amadeus.flightoffersprice;
import ballerinax/amadeus.flightofferssearch;
import ballerina/http;

configurable string xApiKey = ?;
configurable string clientId = ?;
configurable string clientSecret = ?;

# The reservation service exposes resource functions to check flight availability, reserve a flight, and get hotels at the destination.
service /reservation on new http:Listener(9090) {

    # Check available flights and pricing
    #
    # + origin - Origin location code city/airport [IATA code].
    # + destination - Destination location code city/airport [IATA code].
    # + depart - The date on which the traveler will depart from the origin to go to the destination. Dates are specified in the ISO 8601 YYYY-MM-DD format, e.g. 2018-02-28
    # + passengers - The number of adult travelers (age 12 or older on date of departure).
    # + return - Available flights with the price.
    resource function get checkAvailability(string origin, string destination, string depart, int passengers) returns json|error? {

        flightofferssearch:Client flightofferssearchEndpoint = check new ({auth: {clientId: clientId, clientSecret: clientSecret}});
        flightofferssearch:Success getFlightOffersResponse = check flightofferssearchEndpoint->getFlightOffers(origin, destination, depart, passengers);

        if (getFlightOffersResponse.data.length() > 0) {
            flightoffersprice:Client flightofferspriceEndpoint = check new ({auth: {clientId: clientId, clientSecret: clientSecret}});
            // Max of six flight offers can be passed to find the prices. 
            // Here we are specifically setting the first flight offer to get the price.
            flightoffersprice:SuccessPricing quoteAirOffersResponse = check flightofferspriceEndpoint->quoteAirOffers("GET", {data: {'type: "flight-offers-pricing", flightOffers: [getFlightOffersResponse.data[0]]}});

            return quoteAirOffersResponse.data.flightOffers[0].toJson();
        }

        return {MESSAGE: "No Results Found."};
    }

    # Reserve a flight and get hotels around the destination
    #
    # + travelerId - Identifier of the traveler.
    # + destination - Destination location code city/airport [IATA code].  
    # + payload - List of element needed to book a flight.
    # + return - Booking status with hotels around the destination.
    resource function post bookAFlight(string travelerId, string destination, @http:Payload json payload) returns json|error? {

        flightcreateorders:Client flightcreateordersEndpoint = check new ({auth: {clientId: clientId, clientSecret: clientSecret}});
        // The JSON payload bind to FlightOffer record by `check payload.cloneWithType(flightcreateorders:FlightOffer)`
        flightcreateorders:SuccessBooking createFlightOrdersResponse = check flightcreateordersEndpoint->createFlightOrders({data: {'type: "flight-order", flightOffers: [check payload.cloneWithType(flightcreateorders:FlightOffer)], travelers: [findTravelerById(travelerId)], contacts: [findTravelerContactById(travelerId)]}});

        impala:Client impalaEndpoint = check new ({xApiKey: xApiKey}, {});
        impala:ListOfHotels listHotelsResponse = check impalaEndpoint->listHotels(countryEq = destination);

        // Return ticketingAgreement and associatedRecords after booking the flight
        // The list of hotels also included as an option to the user
        return {ticketingAgreement: createFlightOrdersResponse.data.ticketingAgreement.toJson(), associatedRecords: createFlightOrdersResponse.data.associatedRecords.toJson(), hotels: listHotelsResponse.data.toJson()};
    }

}

function findTravelerById(string travelerId) returns flightcreateorders:Traveler {
    return {
        "id": travelerId,
        "dateOfBirth": "1982-01-16",
        "name": {
            "firstName": "JORGE",
            "lastName": "GONZALES"
        },
        "gender": "MALE",
        "contact": {
            "emailAddress": "jorge.gonzales833@telefonica.es",
            "phones": [
                {
                    "deviceType": "MOBILE",
                    "countryCallingCode": "34",
                    "number": "480080076"
                }
            ]
        },
        "documents": [
            {
                "documentType": "PASSPORT",
                "birthPlace": "Madrid",
                "issuanceLocation": "Madrid",
                "issuanceDate": "2015-04-14",
                "number": "00000000",
                "expiryDate": "2025-04-14",
                "issuanceCountry": "ES",
                "validityCountry": "ES",
                "nationality": "ES",
                "holder": true
            }
        ]
    };
}

function findTravelerContactById(string travelerId) returns flightcreateorders:Contact {
    return {
        "addresseeName": {
            "firstName": "PABLO",
            "lastName": "RODRIGUEZ"
        },
        "companyName": "INCREIBLE VIAJES",
        "purpose": "STANDARD",
        "phones": [
            {
                "deviceType": "LANDLINE",
                "countryCallingCode": "34",
                "number": "480080071"
            },
            {
                "deviceType": "MOBILE",
                "countryCallingCode": "33",
                "number": "480080072"
            }
        ],
        "emailAddress": "support@increibleviajes.es",
        "address": {
            "lines": [
                "Calle Prado, 16"
            ],
            "postalCode": "28014",
            "cityName": "Madrid",
            "countryCode": "ES"
        }
    };
}