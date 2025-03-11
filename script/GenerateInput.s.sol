// SPDX-License_Identifier: MIT

pragma solidity ^0.8.24;
import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";

contract GenerateInput is Script {
    uint256 amount = 25 * 1e18;
    string[] types = new string[](2);
    uint256 count;
    string[] whitelist = new string[](2);

    string private inputPath = "/script/target/input.json";

    function run() public {
        types[0] = "address";
        types[1] = "uint";
        whitelist[0] = "0x8e4AFA7AF752407783BcFCEB465D456E4179e79A";
        whitelist[1] = "0x0fC865feDd0e1b1D40607fbF774c90f1442Fd93d";

        count = whitelist.length;
        string memory input = _createJSON();
        vm.writeFile(string.concat(vm.projectRoot(), inputPath), input);

        console.log("DONE: the output is found at %s", inputPath);
    }

    function _createJSON() internal virtual returns (string memory){
        string memory countString = vm.toString(count);
        string memory amountString = vm.toString(amount);
        string memory json = string.concat('{"types": ["address", "uint"], "count":', countString, ',"values": {');
        for (uint256 i = 0; i < whitelist.length; i++){
            if(i == whitelist.length -1){
                json = string.concat(json, '"', vm.toString(i), '"', ': {"0":', '"',whitelist[i], '"', ', "1":', '"',amountString, '"', '}');
            }else{
                json = string.concat(json, '"', vm.toString(i), '"', ':{"0":', '"',whitelist[i],'"',', "1":', '"',amountString,'"', '},');
            }
        }
        json = string.concat(json, '} }');

    return json;
    }
}
