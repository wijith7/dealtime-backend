//Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//WSO2 Inc. licenses this file to you under the Apache License,
//Version 2.0 (the "License"); you may not use this file except
//in compliance with the License.
//You may obtain a copy of the License at
//http://www.apache.org/licenses/LICENSE-2.0
//Unless required by applicable law or agreed to in writing,
//software distributed under the License is distributed on an
//"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//KIND, either express or implied.  See the License for the
//specific language governing permissions and limitations
//under the License.

import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/jms;

//file path that order items are hard coded.
string filePath = "./files/sample.json";

//Order management is done using an in memory map.
map<json> ordersMap = initialGet();

documentation{
                By initialGet() function we initialy load json into ordersMap.
                we use this to load sample.json only one time
}

function initialGet() returns map<json> {

    map<json> initialOrdersMap;
    json? payload = readSampleJSON(filePath);
    json[] jsonArr = check <json[]>payload.orderArray;

    //put json objects in to map
    foreach id, jOrder in jsonArr {

        //converted in to string
        string a = jOrder.ID.toString(); //change a
        initialOrdersMap[a] = jOrder;

    }
        return initialOrdersMap;
}

//close the character channel when done
function close(io:CharacterChannel characterChannel) {

    characterChannel.close() but {

        error e =>
        log:printError("Error occurred while closing character stream", err = e)

    };
}

//read the json that are hard coded.
function readSampleJSON(string path) returns json {

    io:ByteChannel byteChannel = io:openFile(path, io:READ);
    io:CharacterChannel ch = new io:CharacterChannel(byteChannel, "UTF8");

    match ch.readJson() {

        json result => {

            close(ch);
            return result;

        }

        error err => {

            close(ch);
            throw err;

        }
    }
}


endpoint http:Listener listener {
    port: 9090
};


// RESTful service.
@http:ServiceConfig { basePath: "/ordermgt" }

service<http:Service> orderMgt bind listener {

         // Resource that handles the HTTP GET requests that are directed to a specific place
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/order/{orderId}"

    }

    findOrder(endpoint client, http:Request req, string orderId) {

        //paylode :this is the json that we store response
        json payload;
        json[] jsonArray;

        //send all the items
        if (orderId == "all"){

            payload = jsonArray;

        }

        // we can get object one by one
        foreach i, jsonObjectFromOrdersMap in ordersMap  {

            int a = check <int>i;
            jsonArray[a - 1] = jsonObjectFromOrdersMap;

        }

        http:Response response;

        if (payload == null) {

            payload = "Order : " + orderId + " cannot be found.";

        }

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(untaint payload );
        // Send response to the client.
        client->respond(response)but { error e => log:printError("Error sending response", err = e) };

    }

    // Resource that handles the HTTP POST requests that are directed to the path
    // '/orders' to create a new Order.

    @http:ResourceConfig {

        methods: ["POST"],
        path: "/order"

    }

    addOrder(endpoint client, http:Request req) {

        json orderReq = check req.getJsonPayload();
        string orderId = orderReq.Order.ID.toString();
        ordersMap[orderId] = orderReq;
        // Create response message.
        json payload = { status: "Order Created.", orderId: orderId };
        http:Response response;
        response.setJsonPayload(untaint payload);
        // Set 201 Created status code in the response message.
        response.statusCode = 201;
        // Set 'Location' header in the response message.
        // This can be used by the client to locate the newly added order.
        //response.setHeader("Location", "http://localhost:9090/ordermgt/order/" +
        //        orderId);
        response.setHeader("Location", "http://localhost:9090/ordermgt/order/" +
                orderId);
        // Send response to the client.
        client->respond(response) but { error e => log:printError("Error sending response", err = e) };

    }

    // Resource that handles the HTTP PUT requests that are directed to the path
    // '/orders' to update an existing Order.

    @http:ResourceConfig {

        methods: ["PUT"],
        path: "/order/{orderId}"
    }

    updateOrder(endpoint client, http:Request req, string orderId) {

        json updatedOrder = check req.getJsonPayload();
        // Find the order that needs to be updated and retrieve it in JSON format.
        json existingOrder = ordersMap[orderId];
        // Updating existing order with the attributes of the updated order.

        if (existingOrder != null) {

            existingOrder.stock = updatedOrder.stock;
            ordersMap[orderId] = existingOrder;

        } else {

            existingOrder = "Order : " + orderId + " cannot be found.";

        }

        http:Response response;
        // Set the JSON payload to the outgoing response message to the client.
        response.setJsonPayload(untaint existingOrder);
        // Send response to the client.
        client->respond(response) but { error e => log:printError("Error sending response", err = e) };
    }
}