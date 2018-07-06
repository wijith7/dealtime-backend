 //Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 //WSO2 Inc. licenses this file to you under the Apache License,
 //Version 2.0 (the "License"); you may not use this file except
 //in compliance with the License.
 //You may obtain a copy of the License at
 //
 //http://www.apache.org/licenses/LICENSE-2.0
 //
 //Unless required by applicable law or agreed to in writing,
 //software distributed under the License is distributed on an
 //"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 //KIND, either express or implied.  See the License for the
 //specific language governing permissions and limitations
 //under the License.


import ballerina/http;
import ballerina/io;
import ballerina/log;


string filePath = "./files/sample.json";    //file path that order items are hard coded.

map<json> ordersMap;                        // Order management is done using an in memory map.


//close the character channel when done

function close(io:CharacterChannel characterChannel) {
    characterChannel.close() but {
        error e =>
        log:printError("Error occurred while closing character stream",
            err = e)
    };
}


//read the json that are hard coded.

function read(string path) returns json {
    io:ByteChannel byteChannel = io:openFile(path, io:READ);
    io:CharacterChannel ch = new io:CharacterChannel(byteChannel, "UTF8");
    match ch.readJson() {
        json result => {
            io:println(result);
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
    // order using path '/orders/<orderID>

    @http:ResourceConfig {

        methods: ["GET"],
        path: "/order/{orderId}"
    }

    findOrder(endpoint client, http:Request req, string orderId) {

        // Find the requested order from the map and retrieve it in JSON format.

        json? payload = read(filePath);

        json jsonArr = payload.orderArray;

        if(orderId=="all"){

            payload = jsonArr;

        }
        int i=0;

        while(i < lengthof jsonArr) {
            if( jsonArr[i].ID.toString().equalsIgnoreCase(orderId)){

                payload = jsonArr[i];
            }

            i++;


        }

        //io:println(payload.orderArray[0].ID.toString().equalsIgnoreCase(orderId));

        http:Response response;

        if (payload == null) {

            payload = "Order : " + orderId + " cannot be found.";
        }

        // Set the JSON payload in the outgoing response message.

        response.setJsonPayload(payload);

        // Send response to the client.

        _ = client->respond(response);
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
        response.setJsonPayload(payload);

        // Set 201 Created status code in the response message.

        response.statusCode = 201;

        // Set 'Location' header in the response message.
        // This can be used by the client to locate the newly added order.
        //response.setHeader("Location", "http://localhost:9090/ordermgt/order/" +
        //        orderId);

        response.setHeader("Location", "http://localhost:9090/ordermgt/order/" +
                orderId);

        // Send response to the client.

        _ = client->respond(response);
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
            existingOrder.Order.Name = updatedOrder.Order.Name;
            existingOrder.Order.Description = updatedOrder.Order.Description;
            ordersMap[orderId] = existingOrder;

        } else {
            existingOrder = "Order : " + orderId + " cannot be found.";
        }

        http:Response response;

        // Set the JSON payload to the outgoing response message to the client.

        response.setJsonPayload(existingOrder);

        // Send response to the client.

        _ = client->respond(response);
    }

    // Resource that handles the HTTP DELETE requests, which are directed to the path
    // '/orders/<orderId>' to delete an existing Order.

    @http:ResourceConfig {

        methods: ["DELETE"],
        path: "/order/{orderId}"
    }

    cancelOrder(endpoint client, http:Request req, string orderId) {

        http:Response response;
        // Remove the requested order from the map.
        _ = ordersMap.remove(orderId);

        json payload = "Order : " + orderId + " removed.";

        // Set a generated payload with order status.

        response.setJsonPayload(payload);

        // Send response to the client.

        _ = client->respond(response);
    }
}