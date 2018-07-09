import ballerina/io;
import ballerina/log;function close(io:CharacterChannel characterChannel) {
    characterChannel.close() but {
        error e =>
        log:printError("Error occurred while closing character stream",
            err = e)
    };
}function write(json content, string path) {
    io:ByteChannel byteChannel = io:openFile(path, io:WRITE);
    io:CharacterChannel ch = new io:CharacterChannel(byteChannel, "UTF8");
    match ch.writeJson(content) {
        error err => {
            close(ch);
            throw err;
        }
        () => {
            close(ch);
            io:println("Content written successfully");
        }
    }
}function read(string path) returns json {
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
}function main(string... args) {
    string filePath = "./files/store.json";
    json j1 = { "Store": {
        "id": "AST",
        "name": "Anne",
        "address": {
            "street": "Main",
            "city": "94"
        },
        "codes": ["4", "8"]
    }
    };
    io:println("Preparing to write json file");
    write(, filePath);
    io:println("Preparing to read the content written");
    json content = read(filePath);
    io:println(content);
}
