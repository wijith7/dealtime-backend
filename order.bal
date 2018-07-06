import ballerina/io;
import ballerina/log;

    function read(string path) returns json {
    io:ByteChannel byteChannel = io:openFile(path, io:READ);
    io:CharacterChannel ch = new io:CharacterChannel(byteChannel, "UTF8");
    match ch.readJson() {
        json result => {

            return result;
        }
        error err => {

            throw err;
        }
    }
}



function main(string... args) {

   string filePath = "./files/sample.json";

    json data =read(filePath) ;


   io:println(data);


}
