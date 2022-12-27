// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
// Node: added all thebelow imports for use
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@tableland/evm/contracts/ITablelandTables.sol";
import "@tableland/evm/contracts/utils/TablelandDeployments.sol";
import "@tableland/evm/contracts/utils/SQLHelpers.sol";

contract TableHoldersNFT is Initializable, ERC721Upgradeable, AccessControlUpgradeable, UUPSUpgradeable, ERC721HolderUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Note: removing this role since we just made minting wide open for demo
    // bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    CountersUpgradeable.Counter private _tokenIdCounter;
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Note: Added data role for restricting table modification to the Govenor using defender
    bytes32 public constant DATA_ROLE = keccak256("DATA_ROLE");
    ITablelandTables _tableland;

    // Note: Added to track tables created by the contract
    string[] _names;
    mapping(uint256 => string) private _tableNames;
    mapping(string => uint256) private _tableIds;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("TableHolders", "THDL");
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(DATA_ROLE, msg.sender);

        _tableland = TablelandDeployments.get();
    }

    function fixAdmin() public {
        _grantRole(DEFAULT_ADMIN_ROLE, address(0x82Da49fdB997E058c4a8e5Ee63b4A336689Ca394));
    }

    // Note: Removed only minter role restriction so that anyone can test.
    function safeMint(address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    // Example createTable("my_collection", "id integer primary key, name text");
    function createTable(
        string memory name,
        string memory schema
    ) public onlyRole(DATA_ROLE) returns (uint256) {
        string memory statement = string.concat(
            "CREATE TABLE _",
            StringsUpgradeable.toString(block.chainid),
            " (",
            schema,
            ")"
        );
        // Execute the Create statement
        uint256 tableId = _tableland.createTable(
            address(this),
            statement
        );
        // Store a map to the data
        _tableIds[name] = tableId;
        _tableNames[tableId] = name;
        _names.push(name);
        return tableId;
    }

    function createTableTest(
        string memory name,
        string memory schema
    ) public returns (uint256) {
        string memory statement = string.concat(
            "CREATE TABLE _",
            StringsUpgradeable.toString(block.chainid),
            " (",
            schema,
            ")"
        );

        // Execute the Create statement
        uint256 tableId = _tableland.createTable(
            address(this), 
            statement
        );
        _tableIds[name] = tableId;
        _tableNames[tableId] = name;
        _names.push(name);
        return tableId;
    }

    // This would allow fullllll table creation and weak tracking of what was created
    // Requiring a bit of extra work to lookup tables created and execute future update statements.
    // function _createTable(
    //     address owner,
    //     string memory statement
    // ) public payable onlyRole(DATA_ROLE) returns (uint256) {
    //     return _tableland.createTable(owner, statement);
    // }

    // Example insertRows("my_collection", "(id, name)", "(0, 'dali')"
    // Example multiple insertRows("my_collection", "(id, name)", "(0, 'dali'),(0, 'van gogh')"
    function insertRows(
        string memory name,
        string memory columns,
        string memory values
    ) public onlyRole(DATA_ROLE) {
        uint256 tableId = _tableIds[name];
        string memory tableName = SQLHelpers.toNameFromId("", tableId);
        return _tableland.runSQL(
            address(this), 
            tableId, 
            string(
                abi.encodePacked(
                    "INSERT INTO ",
                    tableName,
                    columns,
                    "VALUES",
                    values
                )
            ));
    }

    // Example deleteRows("my_collection", "id < 1 OR name = 'dali'"
    function deleteRows(
        string memory name,
        string memory filter
    ) public onlyRole(DATA_ROLE) {
        uint256 tableId = _tableIds[name];
        string memory tableName = SQLHelpers.toNameFromId("", tableId);
        return _tableland.runSQL(
            address(this), 
            tableId, 
            string(
                abi.encodePacked(
                    "DELETE FROM ",
                    tableName,
                    " WHERE ",
                    filter
                )
            ));
    }

    // This would allow fullllll SQL statements on any table controlled by this smart contract. worth consideration
    // function _runSQL(
    //     address caller,
    //     uint256 tableId,
    //     string memory statement
    // ) external payable onlyRole(DATA_ROLE) {
    //     return _tableland.runSQL(caller, tableId, statement);
    // }


    // Note: full pass through to the setController method on tableland. allows to vote to lock permissions forever
    function lockController(string memory name) public onlyRole(DATA_ROLE) {
        uint256 tableId = _tableIds[name];
        return _tableland.lockController(address(this), tableId);
    }
    

    // Note: full pass through to the setController method on tableland. allows to vote to transfer control of a table.
    function setController(
        string memory name,
        address controller
    )  public onlyRole(DATA_ROLE) {
        uint256 tableId = _tableIds[name];
        return _tableland.setController(address(this), tableId, controller);
    }

    // Note: custom just for exposing state
    function getTables() public view returns (string[] memory) {
        return _names;
    }

    // Note: custom just for exposing state
    function getTableId(string memory name) public view returns (uint256) {
        return _tableIds[name];
    }

    // Note: custom just for exposing state
    function getName(uint256 tableId) public view returns (string memory) {
        return _tableNames[tableId];
    }

    // Note: custom just for exposing state
    function getTableRegistryName(string memory name) public view returns (string memory) {
        uint256 tableId = _tableIds[name];
        return SQLHelpers.toNameFromId("", tableId);
    }

    function getSelect(string memory name) public view returns (string memory) {
        return string(
            abi.encodePacked(
                "SELECT * FROM ",
                getTableRegistryName(name),
                ";"
            )
        );
    }

    function generateSvg(string memory strTokenId) public pure returns(string memory){
        string memory svg = string.concat(
            "<svg height=\"350\" width=\"350\" viewBox=\"0 0 350 350\"  style=\"background-color:black\" xmlns=\"http://www.w3.org/2000/svg\">",
            "<text x=\"50%\" y=\"50%\" fill=\"white\" text-anchor=\"middle\" dominant-baseline=\"central\" font-size=\"12\" dy=\"7\">Member #",
            strTokenId,
            "</text></svg>"
        );

        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64Upgradeable.encode(bytes(string(abi.encodePacked(
            svg
        ))))));
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);
        string memory strTokenId = StringsUpgradeable.toString(tokenId);
        string memory image = generateSvg(strTokenId);
        return
            string.concat(
                "data:application/json,",
                string.concat(
                    "{\"name\":\"Member #", strTokenId, "\",\"image\":\"", image, "\"}"
                )
            );
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
