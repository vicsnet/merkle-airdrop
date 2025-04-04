// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";
import {Merkle} from "murky/src/Merkle.sol";
import {ScriptHelper} from "murky/script/common/ScriptHelper.sol";

contract MakeMerkle is Script, ScriptHelper {
    using stdJson for string; //enable us to use json cheatcodes for strings

    Merkle private m = new Merkle(); // instance of the merkle contract from Murky to do shizz

    string private inputPath = "/script/target/input.json";
    string private outputPath = "/script/target/output.json";

    string private elements =
        vm.readFile(string.concat(vm.projectRoot(), inputPath)); // get the absolute path
    string[] private types = elements.readStringArray(".types"); // gets the merkle tree leaf types from using forge
    uint256 private count = elements.readUint(".count"); //get the number of leaf nnodes

    bytes32[] private leafs = new bytes32[](count);

    string[] private inputs = new string[](count);
    string[] private outputs = new string[](count);

    string private output;

   

    /// @dev Returns the JSON path of the input file
    //  output file output ".values.some-address.some-amount"
    function getValuesByIndex(
        uint256 i,
        uint256 j
    ) internal pure returns (string memory) {
        return string.concat(".values.", vm.toString(i), ".", vm.toString(j));
    }

    /// @dev Generate the JSON entries for the output file
    function generateJsonEntries(
        string memory _inputs,
        string memory _proof,
        string memory _root,
        string memory _leaf
    ) internal pure returns (string memory) {
        string memory result = string.concat(
            "{",
            '"inputs":',
            _inputs,
            ",",
            '"proof":',
            _proof,
            ",",
            '"root":"',
            _root,
            '",',
            '"leaf":"',
            _leaf,
            '"',
            "}"
        );

        return result;
    }

    /// @dev Read the input file and generate the Merkle proof, then write the output file
     function run() public {
        console.log("Generating Merkle Proof for %s", inputPath);

        for (uint256 i = 0; i < count; ++i){
            string[] memory input = new string[](types.length);
            bytes32[] memory data = new bytes32[](types.length);

            for (uint256 j = 0; j <types.length; ++j){
                if(compareStrings(types[j], "address")){
                    address value = elements.readAddress(getValuesByIndex(i, j));

                    // you cant immediately cast straight to 32 bytes as an address is 20 bytes 
                    data[j] = bytes32(uint256(uint160(value)));
                    input[j] = vm.toString(value);
                }else if(compareStrings(types[j], "uint")){
                    uint256 value = vm.parseUint(elements.readString(getValuesByIndex(i, j)));
                    data[j] = bytes32(value);
                    input[j] = vm.toString(value);
                }
            }

            // create the hash for the merkle tree leaf node
            // abi encode the data array(each element is a bytes32 representation for the address and the amount)
            // Helper from murky (ltrim64) Returns the bytes with the first 64 bytes removed
            // ltrim64 removes the offset and length from the encoded bytes. there is an offset because the array 
            // is declared in memory
            // hash the encoded address and the amount
            // bytes.concat turns from bytes32 to bytes
            // hash again because merkle stuff says so
            leafs[i] = keccak256(bytes.concat(keccak256(ltrim64(abi.encode(data)))));
            // COnverts a string array to a JSON array string
            //  store the corresponding inputs for each leaf node
            inputs[i] = stringArrayToString(input);


        }

        for (uint256 i = 0; i <count; i++){
            string memory proof = bytes32ArrayToString(m.getProof(leafs, i));

            // get the root hash and stringify
            string memory root = vm.toString(m.getRoot(leafs));
            // get the specific leaf working on
            string memory leaf = vm.toString(leafs[i]);
            // get the signified input(address, amount)
            string memory input = inputs[i];

            // generate the json output
            outputs[i] = generateJsonEntries(input, proof, root, leaf);

        }

        // stringify the array of strings to a single string
        output = stringArrayToArrayString(outputs);

    
        // write to the output file the stringified output json tree dumpus
        vm.writeFile(string.concat(vm.projectRoot(), outputPath), output);

        console.log("DONE: The output is found at %s", outputPath);
     }
}
