import ballerina/io;
import ballerinax/amadeus.flightofferssearch as fos;
import ballerinax/amadeus.flightoffersprice as fop;
import ballerinax/amadeus.flightcreateorders as fco;

configurable string clientId = ?;
configurable string clientSecret = ?;

fos:OAuth2ClientCredentialsGrantConfig auth = {
    clientId,
    clientSecret
};

public function main() returns error? {

    // Step 1
    fos:Client fosClient = check new ({auth});
    fos:Success flightOffers = check fosClient->getFlightOffers("SYD", "BKK", "2022-11-01", adults = 1);
    // io:println(flightOffers.data);

    // Step 2
    fop:Client fopClient = check new ({auth});
    fop:GetPriceQuery fopQuery = {
        data: {
            'type: "flight-offers-pricing",
            flightOffers: [flightOffers.data[0]]
        }
    };
    // io:println(fopQuery);
    fop:SuccessPricing quoteAirOffers = check fopClient->quoteAirOffers("GET", fopQuery);
    // io:println(quoteAirOffers);

    // Step 3
    fco:Client fcoClient = check new ({auth});
    fco:FlightOrderQuery foq =
    {
        data: {
            'type: "flight-order",
            flightOffers: [quoteAirOffers.data.flightOffers[0]],
            travelers: [
                {
                    "id": "1",
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
                }
            ],
            // "remarks": {
            //     "general": [
            //         {
            //             "subType": "GENERAL_MISCELLANEOUS",
            //             "text": "ONLINE BOOKING FROM INCREIBLE VIAJES"
            //         }
            //     ]
            // },
            // "ticketingAgreement": {
            //     "option": "DELAY_TO_CANCEL",
            //     "delay": "6D"
            // },
            contacts: [
                {
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
                }
            ]
        }
    };
    fco:SuccessBooking flightOrder = check fcoClient->createFlightOrders(foq);
    io:println(flightOrder);
}

