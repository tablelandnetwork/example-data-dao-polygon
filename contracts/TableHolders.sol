// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// Node: added all thebelow imports for use
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@tableland/evm/contracts/ITablelandTables.sol";
import "@tableland/evm/contracts/utils/TablelandDeployments.sol";

contract TableHolders is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20SnapshotUpgradeable, AccessControlUpgradeable, PausableUpgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable, UUPSUpgradeable, ERC721HolderUpgradeable {
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Note: Added data role for restricting table modification to the Govenor using defender
    bytes32 public constant TABLELAND_ROLE = keccak256("TABLELAND_ROLE");
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
        __ERC20_init("TableHolders", "THEx");
        __ERC20Burnable_init();
        __ERC20Snapshot_init();
        __AccessControl_init();
        __Pausable_init();
        __ERC20Permit_init("TableHolders");
        __ERC20Votes_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SNAPSHOT_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(TABLELAND_ROLE, msg.sender);

        _tableland = TablelandDeployments.get();
    }

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20Upgradeable, ERC20SnapshotUpgradeable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._burn(account, amount);
    }

    // Example createTable("my_collection", "id integer primary key, name text");
    function createTable(
        string memory name,
        string memory schema
    ) public onlyRole(TABLELAND_ROLE) returns (uint256) {
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

    // This would allow fullllll table creation and weak tracking of what was created
    // Requiring a bit of extra work to lookup tables created and execute future update statements.
    // function _createTable(
    //     address owner,
    //     string memory statement
    // ) public payable onlyRole(TABLELAND_ROLE) returns (uint256) {
    //     return _tableland.createTable(owner, statement);
    // }

    // This is a more toned down version of insertRows
    // Example insertRows("my_collection", "id, name", "(0, 'dali')"
    // Example multiple insertRows("my_collection", "id, name", "(0, 'dali'),(0, 'van gogh')"
    function insertRows(
        string memory name,
        string memory columns,
        string memory values
    ) public onlyRole(TABLELAND_ROLE) {
        uint256 tableId = _tableIds[name];
        string memory tableName = _toNameFromId(tableId);
        return _tableland.runSQL(
            address(this), 
            tableId, 
            string.concat(
                "INSERT INTO ",
                tableName,
                "(",
                columns,
                ")VALUES",
                values
            ));
    }

    // Here is an example for deletingRows
    // Example deleteRows("my_collection", "id < 1 OR name = 'dali'"
    function deleteRows(
        string memory name,
        string memory filter
    ) public onlyRole(TABLELAND_ROLE) {
        uint256 tableId = _tableIds[name];
        string memory tableName = _toNameFromId(tableId);
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
    // ) external payable onlyRole(TABLELAND_ROLE) {
    //     return _tableland.runSQL(caller, tableId, statement);
    // }


    // Note: full pass through to the setController method on tableland. allows to vote to lock permissions forever
    function lockController(string memory name) public onlyRole(TABLELAND_ROLE) {
        uint256 tableId = _tableIds[name];
        return _tableland.lockController(address(this), tableId);
    }
    

    // Note: full pass through to the setController method on tableland. allows to vote to transfer control of a table.
    function setController(
        string memory name,
        address controller
    )  public onlyRole(TABLELAND_ROLE) {
        uint256 tableId = _tableIds[name];
        return _tableland.setController(address(this), tableId, controller);
    }

    function _toNameFromId(
        uint256 tableId
    ) internal view returns (string memory) {
        return
            string.concat(
                "_",
                StringsUpgradeable.toString(block.chainid),
                "_",
                StringsUpgradeable.toString(tableId)
            );
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
        return _toNameFromId(tableId);
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
}
