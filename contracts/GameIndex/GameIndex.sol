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

contract GameIndex is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20SnapshotUpgradeable, AccessControlUpgradeable, PausableUpgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable, UUPSUpgradeable, ERC721HolderUpgradeable {
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Note: Added data role for restricting table modification to the Govenor using defender
    bytes32 public constant TABLELAND_ROLE = keccak256("TABLELAND_ROLE");
    ITablelandTables _tableland;

    // Note: Added to track tables created by the contract
    string public gameIndexTable;
    uint256 public gameIndexTableId;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("GameIndex", "GID");
        __ERC20Burnable_init();
        __ERC20Snapshot_init();
        __AccessControl_init();
        __Pausable_init();
        __ERC20Permit_init("GameIndex");
        __ERC20Votes_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SNAPSHOT_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(TABLELAND_ROLE, msg.sender);

        _tableland = TablelandDeployments.get();
        createGameIndex();
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

    // Run one time on contract create
    function createGameIndex() private {
        string memory statement = string.concat(
            "CREATE TABLE game_index_",
            StringsUpgradeable.toString(block.chainid),
            " (id integer primary key, name text, image text, download text)"
        );
        // Execute the Create statement
        uint256 tableId = _tableland.createTable(
            address(this),
            statement
        );
        gameIndexTableId = tableId;
        gameIndexTable = string.concat("game_index_", StringsUpgradeable.toString(block.chainid), "_", StringsUpgradeable.toString(tableId));
    }

    // Used to vote on new games
    function addGame(
        string memory name,
        string memory image,
        string memory download
    ) public onlyRole(TABLELAND_ROLE) {
        return _tableland.runSQL(
            address(this), 
            gameIndexTableId, 
            string.concat(
                "INSERT INTO ",
                gameIndexTable,
                "(name,image,download)VALUES('",
                name,"','",
                image,"','",
                download,"')"
            ));
    }

    // Used to vote on removing games
    function deleteGame(uint256 id) public onlyRole(TABLELAND_ROLE) {
        return _tableland.runSQL(
            address(this), 
            gameIndexTableId, 
            string.concat(
                "DELETE FROM ",
                gameIndexTable,
                " WHERE id=", 
                StringsUpgradeable.toString(id)
            ));
    }

    function jsonURI() public view returns (string memory) {
        // Note: this will change to 'mainnets' very soon for tables minted on mainnets. 
        return string.concat(
            "https://testnets.tableland.network/query?s=SELECT%20*%20FROM%20"
            "gameIndexTable"
        );
    }
}
